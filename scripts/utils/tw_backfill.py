#!/usr/bin/env python3
"""
tw_backfill.py — Importa a Taskwarrior las tareas del checkpoint que no tienen tw_uuid.

Uso: python3 tw_backfill.py [--dry-run]

Genera un JSON de tareas y las importa de golpe con `task import`.
Luego actualiza el checkpoint con los UUIDs asignados.
"""

import json
import uuid
import subprocess
import sys
import argparse
from pathlib import Path
from datetime import datetime, timezone

REPO_DIR    = Path(__file__).resolve().parents[2]
CONFIG_FILE = REPO_DIR / "config.json"

with open(CONFIG_FILE) as f:
    cfg = json.load(f)

VAULT_DIR   = Path(cfg["vault"]["path"]).expanduser()
CHECKPOINT  = Path(cfg["tasks"]["checkpoint_file"]).expanduser()
TW_BIN      = cfg["tasks"].get("taskwarrior_bin", "task")


def tw_project(md_file: str) -> str:
    try:
        rel = Path(md_file).relative_to(VAULT_DIR)
        parts = rel.parts
        if len(parts) >= 2 and parts[0] == "Spaces":
            return parts[1].lower().replace(" ", "-")
        return parts[0].lower().replace(" ", "-")
    except ValueError:
        return "notas"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", "-n", action="store_true")
    args = parser.parse_args()

    if not CHECKPOINT.exists():
        print("No existe checkpoint.")
        sys.exit(1)

    with open(CHECKPOINT) as f:
        checkpoint = json.load(f)

    # Filtrar los que no tienen tw_uuid
    pending = {k: v for k, v in checkpoint.items()
               if not v.get("tw_uuid") and v.get("status") not in ("HECHO", "CANCELADO")}

    print(f"Tareas sin tw_uuid: {len(pending)} / {len(checkpoint)} total")

    if not pending:
        print("Todo ya tiene uuid. Nada que hacer.")
        return

    # Construir lista JSON para task import
    tasks_json = []
    uuid_map = {}  # task_id → uuid asignado

    for task_id, entry in pending.items():
        task_uuid = str(uuid.uuid4())
        uuid_map[task_id] = task_uuid
        tag = f"md_{task_id[:8]}"
        project = tw_project(entry.get("md_file", ""))
        created_str = entry.get("created", datetime.now().isoformat())
        # task import espera formato ISO8601 sin microsegundos
        try:
            created_dt = datetime.fromisoformat(created_str)
        except Exception:
            created_dt = datetime.now()
        entry_time = created_dt.strftime("%Y%m%dT%H%M%SZ")

        tasks_json.append({
            "uuid":        task_uuid,
            "description": entry["text"],
            "status":      "pending",
            "project":     project,
            "tags":        ["md", tag],
            "entry":       entry_time,
        })

    if args.dry_run:
        print(f"DRY-RUN: importaría {len(tasks_json)} tareas")
        print("Ejemplo:", json.dumps(tasks_json[0], indent=2))
        return

    # Importar en lote
    import_data = json.dumps(tasks_json, ensure_ascii=False)
    tmp_file = Path("/tmp/tw_import.json")
    tmp_file.write_text(import_data)

    result = subprocess.run(
        [TW_BIN, "import", str(tmp_file)],
        capture_output=True, text=True
    )

    if result.returncode != 0:
        print("ERROR en task import:")
        print(result.stderr)
        sys.exit(1)

    print(f"Importadas {len(tasks_json)} tareas.")

    # Actualizar checkpoint con UUIDs
    for task_id, new_uuid in uuid_map.items():
        checkpoint[task_id]["tw_uuid"] = new_uuid

    with open(CHECKPOINT, "w") as f:
        json.dump(checkpoint, f, indent=2, ensure_ascii=False)

    print("Checkpoint actualizado con UUIDs.")
    tmp_file.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
