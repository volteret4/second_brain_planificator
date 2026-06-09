#!/usr/bin/env python3
"""
md_to_org.py — Sincronización bidireccional de tareas entre .md, org-mode y Taskwarrior.

Flujo:
  .md  [ ] nuevo      → añade  * TODO en tareas.org  +  task add en Taskwarrior
  .md  [x] marcado    → marca  * HECHO en tareas.org  +  task done en Taskwarrior
  .org HECHO          → marca  [x] en el .md de origen (reverse sync)

org-caldav se encarga de  tareas.org ↔ Radicale (CalDAV).

Checkpoint: JSON en .task_checkpoint.json — guarda qué tareas ya están sincronizadas
para no duplicar. Clave = SHA256(ruta_relativa + "|" + texto_tarea).
"""

import os
import re
import sys
import json
import hashlib
import logging
import subprocess
from pathlib import Path
from datetime import datetime

# ── Secretos vía SOPS ────────────────────────────────────────────────────────
sys.path.insert(0, str(Path.home() / "Scripts" / "tools" / "sopsdotenv"))
try:
    from sopsdotenv import load_sops_env
    load_sops_env()
except Exception:
    pass

# ── Config ────────────────────────────────────────────────────────────────────
REPO_DIR      = Path(__file__).resolve().parents[2]
CONFIG_FILE   = REPO_DIR / "config.json"

with open(CONFIG_FILE) as f:
    _cfg = json.load(f)

VAULT_DIR      = Path(_cfg["vault"]["path"]).expanduser()
TAREAS_ORG     = VAULT_DIR / "tareas.org"
CHECKPOINT     = Path(_cfg["tasks"]["checkpoint_file"]).expanduser()
WATCH_DIRS     = [Path(p).expanduser() for p in _cfg["tasks"]["watch_dirs"]]
EXCLUDED_FILES = {Path(p).expanduser() for p in _cfg["tasks"].get("excluded_files", [])}
TW_BIN         = _cfg["tasks"].get("taskwarrior_bin", "task")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)

# ── Regex ─────────────────────────────────────────────────────────────────────
RE_OPEN   = re.compile(r"^(\s*)-\s+\[\s\]\s+(.+)$")
RE_DONE   = re.compile(r"^(\s*)-\s+\[x\]\s+(.+)$", re.IGNORECASE)
RE_MD_SRC = re.compile(r":MD_HASH:\s+(\S+)")


def _task_id(md_path: Path, text: str) -> str:
    raw = f"{md_path.as_posix()}|{text.strip()}"
    return hashlib.sha256(raw.encode()).hexdigest()[:16]


def _tw_project(md_path: Path) -> str:
    """Deriva un nombre de proyecto Taskwarrior del directorio del .md."""
    try:
        rel = md_path.relative_to(VAULT_DIR)
        parts = rel.parts
        # Usar segundo nivel si existe (ej: Spaces/Wiki → wiki, Important → important)
        if len(parts) >= 2 and parts[0] == "Spaces":
            return parts[1].lower().replace(" ", "-")
        return parts[0].lower().replace(" ", "-")
    except ValueError:
        return "notas"


def load_checkpoint() -> dict:
    if CHECKPOINT.exists():
        with open(CHECKPOINT) as f:
            return json.load(f)
    return {}


def save_checkpoint(data: dict) -> None:
    CHECKPOINT.parent.mkdir(parents=True, exist_ok=True)
    with open(CHECKPOINT, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


# ── Taskwarrior ───────────────────────────────────────────────────────────────
def tw_add(text: str, project: str, task_id: str) -> str | None:
    """Crea tarea en Taskwarrior. Devuelve UUID o None si falla."""
    tag = f"md_{task_id[:8]}"
    try:
        subprocess.run(
            [TW_BIN, "add", f"project:{project}", "+md", f"+{tag}", text],
            check=True, capture_output=True, text=True,
        )
        result = subprocess.run(
            [TW_BIN, f"tags.contains:{tag}", "export"],
            capture_output=True, text=True,
        )
        data = json.loads(result.stdout or "[]")
        if data:
            uuid = data[0]["uuid"]
            log.info("→ tw: [add] %s (uuid=%s)", text[:60], uuid[:8])
            return uuid
        log.warning("tw_add: tarea creada pero UUID no encontrado (tag=%s)", tag)
    except Exception as e:
        log.warning("tw_add falló: %s", e)
    return None


def tw_done(tw_uuid: str, text: str) -> None:
    """Marca tarea como done en Taskwarrior por UUID."""
    try:
        subprocess.run(
            [TW_BIN, tw_uuid, "done", "rc.confirmation=no"],
            check=True, capture_output=True, text=True,
        )
        log.info("→ tw: [done] %s", text[:60])
    except Exception as e:
        log.warning("tw_done falló para %s: %s", tw_uuid, e)


# ── Leer tareas.org ───────────────────────────────────────────────────────────
def read_org_tasks() -> dict[str, dict]:
    """Devuelve {md_hash: {status, org_heading}} para tareas con :MD_HASH:."""
    tasks = {}
    if not TAREAS_ORG.exists():
        return tasks
    with open(TAREAS_ORG) as f:
        lines = f.readlines()

    heading = None
    status  = None
    for line in lines:
        m = re.match(r"^\*+\s+(TODO|HOY|ESPERANDO|HECHO|CANCELADO)\s+(.+)", line.strip())
        if m:
            status  = m.group(1)
            heading = m.group(2).strip()
        mh = RE_MD_SRC.search(line)
        if mh and heading:
            tasks[mh.group(1)] = {"status": status, "heading": heading}
            heading = None
    return tasks


# ── Añadir tarea al .org ──────────────────────────────────────────────────────
def append_org_task(text: str, md_path: Path, task_id: str) -> None:
    entry = (
        f"\n* TODO {text.strip()}\n"
        f"  CREATED: [{datetime.now().strftime('%Y-%m-%d %a %H:%M')}]\n"
        f"  :PROPERTIES:\n"
        f"  :MD_FILE: {md_path.as_posix()}\n"
        f"  :MD_HASH: {task_id}\n"
        f"  :END:\n"
    )

    TAREAS_ORG.parent.mkdir(parents=True, exist_ok=True)
    if not TAREAS_ORG.exists():
        TAREAS_ORG.write_text("#+TITLE: Tareas\n#+FILETAGS: :tareas:\n\n* Inbox\n")

    content = TAREAS_ORG.read_text()
    if "* Inbox" in content:
        content = content.replace("* Inbox\n", f"* Inbox\n{entry}", 1)
    else:
        content += entry
    TAREAS_ORG.write_text(content)
    log.info("→ org: [TODO] %s", text.strip())


def mark_org_done(task_id: str) -> None:
    if not TAREAS_ORG.exists():
        return
    lines    = TAREAS_ORG.read_text().splitlines(keepends=True)
    modified = False
    stamp    = datetime.now().strftime("%Y-%m-%d %a %H:%M")

    for i, line in enumerate(lines):
        if RE_MD_SRC.search(line) and task_id in line:
            # Buscar el heading hacia atrás
            for j in range(i - 1, max(i - 10, -1), -1):
                m = re.match(r"^(\*+\s+)(TODO|HOY|ESPERANDO)(\s+.+)", lines[j])
                if m:
                    lines[j] = f"{m.group(1)}HECHO{m.group(3)}"
                    lines.insert(j + 1, f"  CLOSED: [{stamp}]\n")
                    modified = True
                    break
            if modified:
                break

    if modified:
        TAREAS_ORG.write_text("".join(lines))
        log.info("→ org: [HECHO] hash=%s", task_id)


# ── Marcar [x] en el .md de origen ───────────────────────────────────────────
def mark_md_done(md_path_str: str, task_id: str) -> None:
    md_path = Path(md_path_str)
    if not md_path.exists():
        log.warning("md no encontrado para reverse-sync: %s", md_path_str)
        return
    lines    = md_path.read_text().splitlines(keepends=True)
    modified = False
    for i, line in enumerate(lines):
        m = RE_OPEN.match(line)
        if m:
            tid = _task_id(md_path, m.group(2))
            if tid == task_id:
                lines[i] = line.replace("- [ ]", "- [x]", 1)
                modified  = True
                break
    if modified:
        md_path.write_text("".join(lines))
        log.info("→ md [x]: %s", md_path.name)


# ── Escanear .md ─────────────────────────────────────────────────────────────
def scan_md_files() -> list[tuple[Path, str, str, str]]:
    results = []
    for watch_dir in WATCH_DIRS:
        if not watch_dir.exists():
            continue
        for md in watch_dir.rglob("*.md"):
            if md in EXCLUDED_FILES:
                continue
            try:
                lines = md.read_text(errors="replace").splitlines()
            except Exception:
                continue
            for line in lines:
                m_open = RE_OPEN.match(line)
                m_done = RE_DONE.match(line)
                if m_open:
                    tid = _task_id(md, m_open.group(2))
                    results.append((md, tid, m_open.group(2).strip(), "open"))
                elif m_done:
                    tid = _task_id(md, m_done.group(2))
                    results.append((md, tid, m_done.group(2).strip(), "done"))
    return results


# ── Main ──────────────────────────────────────────────────────────────────────
def main() -> None:
    checkpoint = load_checkpoint()
    org_tasks  = read_org_tasks()
    changed    = False

    # ── FORWARD: .md → tareas.org + Taskwarrior ──────────────────────────────
    for md_path, task_id, text, status in scan_md_files():

        if status == "open":
            if task_id not in checkpoint:
                append_org_task(text, md_path, task_id)
                project = _tw_project(md_path)
                tw_uuid = tw_add(text, project, task_id)
                checkpoint[task_id] = {
                    "md_file":  md_path.as_posix(),
                    "text":     text,
                    "status":   "TODO",
                    "created":  datetime.now().isoformat(),
                    "tw_uuid":  tw_uuid,
                }
                changed = True

        elif status == "done":
            if task_id in checkpoint and checkpoint[task_id]["status"] != "HECHO":
                mark_org_done(task_id)
                tw_uuid = checkpoint[task_id].get("tw_uuid")
                if tw_uuid:
                    tw_done(tw_uuid, text)
                checkpoint[task_id]["status"] = "HECHO"
                changed = True

    # ── REVERSE: tareas.org HECHO → .md [x] ──────────────────────────────────
    for task_id, org_info in org_tasks.items():
        if org_info["status"] in ("HECHO", "CANCELADO"):
            if task_id in checkpoint and checkpoint[task_id]["status"] != "HECHO":
                mark_md_done(checkpoint[task_id]["md_file"], task_id)
                tw_uuid = checkpoint[task_id].get("tw_uuid")
                if tw_uuid:
                    tw_done(tw_uuid, org_info["heading"])
                checkpoint[task_id]["status"] = "HECHO"
                changed = True

    if changed:
        save_checkpoint(checkpoint)
        log.info("Checkpoint actualizado.")
    else:
        log.info("Sin cambios.")


if __name__ == "__main__":
    main()
