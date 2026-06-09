#!/usr/bin/env python3
"""
Auto-tagger para notas del second brain.
Asigna 3-7 tags basándose en ruta + contenido de cada archivo .md.
Lee listas de rutas desde archivos batch o procesa directorios completos.
"""

import os
import re
import sys
import argparse
from pathlib import Path


# ── Taxonomía de tags ───────────────────────────────────────────────────────

# Mapas path → tags (aplicados si el fragmento aparece en la ruta)
PATH_TAG_RULES = [
    # Secciones grandes
    (r"Spaces/Wiki/Linux/alpine",       ["linux", "alpine"]),
    (r"Spaces/Wiki/Linux/nix",          ["linux", "nix", "nixos"]),
    (r"Spaces/Wiki/Linux/comandos",     ["linux", "comandos", "referencia"]),
    (r"Spaces/Wiki/Linux/tutoriales",   ["linux", "tutorial"]),
    (r"Spaces/Wiki/Linux/Apps",         ["linux", "apps"]),
    (r"Spaces/Wiki/Linux",              ["linux"]),
    (r"Spaces/Wiki/Markor",             ["personal", "markor", "movil"]),
    (r"Spaces/Wiki/python",             ["python", "programacion"]),
    (r"Spaces/Wiki/notas",              ["notas", "personal"]),
    (r"Spaces/Wiki",                    ["wiki"]),
    # Blogs - music-fuzzy (es documentación de un proyecto)
    (r"Spaces/Blogs/snipets.*music-fuzzy/scripts", ["music-fuzzy", "python", "snippet", "scripts"]),
    (r"Spaces/Blogs/snipets.*music-fuzzy/creacion base de datos", ["music-fuzzy", "base-de-datos", "referencia"]),
    (r"Spaces/Blogs/snipets.*music-fuzzy/credenciales", ["music-fuzzy", "credenciales", "apis"]),
    (r"Spaces/Blogs/snipets.*music-fuzzy/modulos", ["music-fuzzy", "documentacion", "modulos"]),
    (r"Spaces/Blogs/snipets.*music-fuzzy/instalacion", ["music-fuzzy", "instalacion", "configuracion"]),
    (r"Spaces/Blogs/snipets.*music-fuzzy", ["music-fuzzy", "música"]),
    (r"Spaces/Blogs/snipets",           ["snippet", "scripts"]),
    (r"Spaces/Blogs/ongoing_history_of_music", ["música", "ensayo", "podcast", "historia-musical"]),
    (r"Spaces/Blogs/tumtumpa",          ["música", "tumtumpa", "recomendacion", "blog"]),
    (r"Spaces/Blogs",                   ["blog"]),
    # Recortes
    (r"Recortes/Kindle",                ["libro", "kindle", "lectura"]),
    (r"Recortes",                       ["recorte", "web", "articulo"]),
    # Journals
    (r"Journals",                       ["journal", "diario"]),
]

# Palabras clave en contenido → tags adicionales
CONTENT_KEYWORD_RULES = [
    # Tecnología
    (r"\bdocker\b",           "docker"),
    (r"\bansible\b",          "ansible"),
    (r"\bsystemd\b",          "systemd"),
    (r"\bnginx\b",            "nginx"),
    (r"\bproxmox\b",          "proxmox"),
    (r"\bssh\b",              "ssh"),
    (r"\bgit\b",              "git"),
    (r"\bpython\b",           "python"),
    (r"\bbash\b|\bsh\b",      "bash"),
    (r"\bnix\b|\bnixos\b",    "nix"),
    (r"\bpihole\b",           "pihole"),
    (r"\bhomeassistant\b",    "homeassistant"),
    (r"\bsyncthing\b",        "syncthing"),
    (r"\bpipewire\b|\bpulseaudio\b", "audio"),
    (r"\bawesomewm\b",        "awesomewm"),
    (r"\bzsh\b|\bbash\b",     "terminal"),
    (r"\bhelix\b|\bvim\b|\bneovim\b", "editor"),
    (r"\bemacs\b",            "emacs"),
    (r"\bzellij\b|\btmux\b",  "terminal"),
    (r"\bsqlite\b|\bpostgres\b|\bmysql\b", "base-de-datos"),
    (r"\blastfm\b",           "lastfm"),
    (r"\bmusicbrainz\b",      "musicbrainz"),
    (r"\bdiscogs\b",          "discogs"),
    (r"\bspotify\b",          "spotify"),
    (r"\byoutube\b",          "youtube"),
    (r"\bhugo\b",             "hugo"),
    (r"\blua\b",              "lua"),
    (r"\brust\b",             "rust"),
    (r"\bjavascript\b|\bjs\b", "javascript"),
    (r"\bwireguard\b|\bvpn\b", "networking"),
    (r"\bssl\b|\bhttps\b|\bcertificat", "seguridad"),
    (r"\bgpg\b|\bencrypt",     "seguridad"),
    (r"\bfail2ban\b|\bcrowdsec\b", "seguridad"),
    (r"\bbackup\b|\bkopia\b|\brsync\b", "backups"),
    (r"\bradicale\b|\bcaldav\b", "caldav"),
    (r"\btaskwarrior\b",       "taskwarrior"),
    # Tipos de nota
    (r"^```|^\s{4}\w",        "snippet"),
    (r"#+\s+Paso \d|##\s+\d+\.", "tutorial"),
    # Música
    (r"\brock\b",             "rock"),
    (r"\bjazz\b",             "jazz"),
    (r"\belectronic\b|\belectrónic", "electronica"),
    (r"\bpunk\b",             "punk"),
    (r"\bmetal\b",            "metal"),
    (r"\bclásic\b|\bclásica\b", "clasica"),
    (r"\bhip.?hop\b|\brap\b", "hiphop"),
    # Libros/temática
    (r"\bdrogas\b|\bnarco",   "drogas"),
    (r"\bfilosof",            "filosofia"),
    (r"\bciencia\b",          "ciencia"),
    (r"\bpolíti\b|\bpolit",   "politica"),
    (r"\bhistoria\b",         "historia"),
    (r"\bfísic\b|\bquímic",   "ciencia"),
]

# Tags de tipo de nota según contenido
NOTE_TYPE_RULES = [
    (r"^---\n.*\n---",                                 "frontmatter"),
    (r"```\w+",                                        "snippet"),
    (r"^#+\s.+\n+.*\n+#{2,3}\s",                      "tutorial"),
    (r"highlight|Subrayado|kindle",                    "kindle"),
    (r"\[\[|\]\]",                                     "wiki-link"),
]


def extract_frontmatter(content: str) -> tuple[dict, str, str]:
    """Devuelve (meta_dict, yaml_block, body). meta_dict vacío si no hay FM."""
    if not content.startswith("---"):
        return {}, "", content
    end = content.find("\n---", 3)
    if end == -1:
        return {}, "", content
    yaml_block = content[3:end].strip()
    body = content[end + 4:].lstrip("\n")
    meta = {}
    for line in yaml_block.splitlines():
        if ":" in line:
            k, _, v = line.partition(":")
            meta[k.strip()] = v.strip()
    return meta, yaml_block, body


def get_existing_tags(meta: dict) -> list[str]:
    raw = meta.get("tags", "")
    if not raw:
        return []
    raw = raw.strip("[]")
    return [t.strip().strip('"\'') for t in raw.split(",") if t.strip()]


def determine_tags(filepath: str, content: str) -> list[str]:
    tags = set()
    path_lower = filepath.replace("\\", "/")

    # 1. Tags por ruta
    for pattern, ptags in PATH_TAG_RULES:
        if re.search(pattern, path_lower, re.IGNORECASE):
            tags.update(ptags)
            break  # solo la primera regla que coincida (más específica primero)

    # Adicionalmente añadir tags por subdirectorio relevante del nombre
    filename = Path(filepath).stem.lower()
    # Artistas en ensayos musicales → tag con su nombre
    if "ongoing_history_of_music" in path_lower or "tumtumpa" in path_lower:
        # El nombre del archivo suele ser el artista/álbum
        artist_name = re.sub(r"[_\-]+", "-", filename).strip("-")
        if len(artist_name) > 3 and artist_name not in tags:
            tags.add(artist_name)

    # Libros Kindle: autor-título en el nombre
    if "Kindle" in filepath or "kindle" in filepath:
        parts = filename.split("-", 1)
        if len(parts) == 2:
            autor = re.sub(r"\s+", "-", parts[0].strip()).lower()
            if len(autor) > 3:
                tags.add(autor)

    # 2. Tags por contenido (primeras 100 líneas para velocidad)
    sample = "\n".join(content.splitlines()[:100]).lower()
    for pattern, tag in CONTENT_KEYWORD_RULES:
        if re.search(pattern, sample, re.IGNORECASE):
            tags.add(tag)

    # 3. Tipo de nota
    for pattern, tag in NOTE_TYPE_RULES:
        if re.search(pattern, content[:500], re.MULTILINE | re.IGNORECASE):
            tags.add(tag)
            break

    # Limpiar y limitar
    tags.discard("frontmatter")  # ruido
    tags.discard("wiki-link")    # demasiado genérico
    tags_list = sorted(tags)

    # Mínimo 3, máximo 7
    return tags_list[:7] if len(tags_list) >= 3 else tags_list


def build_frontmatter(meta: dict, new_tags: list[str]) -> str:
    lines = ["---"]
    # Mantener campos existentes excepto tags
    for k, v in meta.items():
        if k.lower() == "tags":
            continue
        lines.append(f"{k}: {v}")
    # Tags
    tag_str = ", ".join(new_tags)
    lines.append(f"tags: [{tag_str}]")
    lines.append("---")
    return "\n".join(lines)


def tag_file(filepath: str, dry_run: bool = False) -> tuple[bool, str]:
    """Aplica tags a un archivo. Devuelve (modificado, mensaje)."""
    try:
        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
    except Exception as e:
        return False, f"ERROR leyendo: {e}"

    if len(content.strip()) < 10:
        return False, "vacío o muy corto, omitido"

    meta, yaml_block, body = extract_frontmatter(content)
    existing_tags = get_existing_tags(meta)
    new_tags = determine_tags(filepath, content)

    # Si ya tiene suficientes tags buenos, no sobrescribir
    if len(existing_tags) >= 3:
        return False, f"ya tiene tags: {existing_tags}"

    if not new_tags:
        new_tags = ["sin-clasificar"]

    if dry_run:
        return True, f"DRY-RUN → tags: {new_tags}"

    new_fm = build_frontmatter(meta, new_tags)
    new_content = new_fm + "\n\n" + body if body else new_fm + "\n"

    try:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(new_content)
        return True, f"tags: {new_tags}"
    except Exception as e:
        return False, f"ERROR escribiendo: {e}"


def process_batch_file(batch_path: str, dry_run: bool = False):
    """Lee un archivo con rutas (una por línea) y procesa cada una."""
    with open(batch_path, "r") as f:
        paths = [l.strip() for l in f if l.strip() and not l.startswith("#")]

    total = len(paths)
    modified = 0
    skipped = 0
    errors = 0

    for i, fpath in enumerate(paths, 1):
        if not os.path.exists(fpath):
            print(f"[{i}/{total}] NO EXISTE: {fpath}")
            errors += 1
            continue
        changed, msg = tag_file(fpath, dry_run)
        status = "✓" if changed else "·"
        print(f"[{i}/{total}] {status} {Path(fpath).name} — {msg}")
        if changed:
            modified += 1
        else:
            skipped += 1

    print(f"\nTotal: {total} | Modificados: {modified} | Omitidos: {skipped} | Errores: {errors}")


def process_directory(dirpath: str, dry_run: bool = False):
    """Procesa todos los .md en un directorio recursivamente."""
    paths = sorted(Path(dirpath).rglob("*.md"))
    total = len(paths)
    modified = 0
    skipped = 0

    for i, p in enumerate(paths, 1):
        changed, msg = tag_file(str(p), dry_run)
        status = "✓" if changed else "·"
        if changed or (i % 50 == 0):
            print(f"[{i}/{total}] {status} {p.name} — {msg}")
        if changed:
            modified += 1
        else:
            skipped += 1

    print(f"\nTotal: {total} | Modificados: {modified} | Omitidos: {skipped}")


def main():
    parser = argparse.ArgumentParser(description="Auto-tagger de notas .md")
    parser.add_argument("--batch", "-b", help="Archivo con lista de rutas (una por línea)")
    parser.add_argument("--dir", "-d", help="Directorio a procesar recursivamente")
    parser.add_argument("--file", "-f", help="Archivo individual")
    parser.add_argument("--dry-run", "-n", action="store_true", help="Simular sin escribir")
    args = parser.parse_args()

    if args.batch:
        process_batch_file(args.batch, args.dry_run)
    elif args.dir:
        process_directory(args.dir, args.dry_run)
    elif args.file:
        changed, msg = tag_file(args.file, args.dry_run)
        print(f"{'✓' if changed else '·'} {args.file} — {msg}")
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
