#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${MANIFEST:-$ROOT_DIR/config/resource_manifest.tsv}"
TARGET_DIR="${TARGET_DIR:-$ROOT_DIR/external}"
ENGINE_FILTER="all"
CATEGORY_FILTER=""
DEPTH="1"
DRY_RUN="0"
STRICT="0"
INCLUDE_PRIVATE="0"

usage() {
  cat <<'EOF'
Usage:
  resource_sync.sh <command> [options]

Commands:
  list      Print filtered resources from manifest
  verify    Check resource availability (git ls-remote or HTTP HEAD)
  clone     Clone filtered git resources into external directory
  status    Show whether filtered git resources are already cloned

Options:
  --engine <all|godot|unity|unreal|cross|pc|xbox>
  --category <name>
  --manifest <path>
  --target <path>
  --depth <n>
  --dry-run
  --strict         Exit non-zero if any verify check fails
  --include-private
                Include likely access-restricted repositories (for example EpicGames org)

Manifest format (TSV):
  id  category  engine  priority  type  url  local_dir  description
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

COMMAND="$1"
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --engine)
      ENGINE_FILTER="$2"
      shift 2
      ;;
    --category)
      CATEGORY_FILTER="$2"
      shift 2
      ;;
    --manifest)
      MANIFEST="$2"
      shift 2
      ;;
    --target)
      TARGET_DIR="$2"
      shift 2
      ;;
    --depth)
      DEPTH="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="1"
      shift
      ;;
    --strict)
      STRICT="1"
      shift
      ;;
    --include-private)
      INCLUDE_PRIVATE="1"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ! -f "$MANIFEST" ]]; then
  echo "error: manifest not found: $MANIFEST" >&2
  exit 1
fi

matches_filter() {
  local row_engine="$1"
  local row_category="$2"

  if [[ -n "$CATEGORY_FILTER" && "$row_category" != "$CATEGORY_FILTER" ]]; then
    return 1
  fi

  if [[ "$ENGINE_FILTER" == "all" ]]; then
    return 0
  fi

  if [[ "$row_engine" == "$ENGINE_FILTER" || "$row_engine" == "cross" ]]; then
    return 0
  fi

  return 1
}

list_rows() {
  while IFS=$'\t' read -r id category engine priority type url local_dir description; do
    [[ -z "$id" || "${id:0:1}" == "#" ]] && continue
    if matches_filter "$engine" "$category"; then
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$id" "$category" "$engine" "$priority" "$type" "$url" "$local_dir" "$description"
    fi
  done < "$MANIFEST"
}

is_private_candidate() {
  local url="$1"
  [[ "$url" == *"github.com/EpicGames/"* ]]
}

case "$COMMAND" in
  list)
    echo -e "id\tcategory\tengine\tpriority\ttype\turl\tlocal_dir\tdescription"
    list_rows
    ;;

  verify)
    failures=0
    while IFS=$'\t' read -r id category engine priority type url local_dir description; do
      if [[ "$type" == "git" ]]; then
        if is_private_candidate "$url" && [[ "$INCLUDE_PRIVATE" != "1" ]]; then
          echo "SKIP [$id] private candidate (use --include-private)"
          continue
        fi
        if git ls-remote --heads "$url" >/dev/null 2>&1; then
          echo "OK   [$id] $url"
        else
          echo "FAIL [$id] $url"
          failures=$((failures + 1))
        fi
      elif [[ "$type" == "web" ]]; then
        if curl -fsLI "$url" >/dev/null 2>&1; then
          echo "OK   [$id] $url"
        else
          echo "FAIL [$id] $url"
          failures=$((failures + 1))
        fi
      else
        echo "FAIL [$id] unknown type: $type"
        failures=$((failures + 1))
      fi
    done < <(list_rows)

    if [[ "$failures" -gt 0 ]]; then
      echo "verify completed with $failures failure(s)."
      if [[ "$STRICT" == "1" ]]; then
        exit 1
      fi
    else
      echo "verify completed successfully."
    fi
    ;;

  clone)
    mkdir -p "$TARGET_DIR"
    while IFS=$'\t' read -r id category engine priority type url local_dir description; do
      if [[ "$type" != "git" ]]; then
        echo "SKIP [$id] non-git resource"
        continue
      fi
      if is_private_candidate "$url" && [[ "$INCLUDE_PRIVATE" != "1" ]]; then
        echo "SKIP [$id] private candidate (use --include-private)"
        continue
      fi
      if [[ "$local_dir" == "-" || -z "$local_dir" ]]; then
        echo "SKIP [$id] local_dir is not set"
        continue
      fi

      dest="$TARGET_DIR/$local_dir"
      if [[ -d "$dest/.git" ]]; then
        echo "HAVE [$id] $dest"
        continue
      fi

      echo "CLONE [$id] $url -> $dest"
      if [[ "$DRY_RUN" == "1" ]]; then
        continue
      fi
      mkdir -p "$(dirname "$dest")"
      git clone --depth "$DEPTH" "$url" "$dest"
    done < <(list_rows)
    ;;

  status)
    while IFS=$'\t' read -r id category engine priority type url local_dir description; do
      if [[ "$type" != "git" ]]; then
        echo "N/A  [$id] non-git resource"
        continue
      fi
      dest="$TARGET_DIR/$local_dir"
      if [[ -d "$dest/.git" ]]; then
        echo "HAVE [$id] $dest"
      else
        echo "MISS [$id] $dest"
      fi
    done < <(list_rows)
    ;;

  *)
    echo "error: unknown command: $COMMAND" >&2
    usage
    exit 1
    ;;
esac
