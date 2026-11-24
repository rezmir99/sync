#!/usr/bin/env bash
#
# git-backup.sh - backup and restore git configs (global + per-repository)
#
# Usage:
#   git-backup.sh -b [repo1 repo2 ...]   backup global config and the given repos
#   git-backup.sh -r [repo1 repo2 ...]   restore global config and the given repos
#
# Backup location: $HOME/ProgramData/git-backup
#
# What is saved:
#   Global : ~/.gitconfig, ~/.config/git/{config,ignore,attributes},
#            the file referenced by core.excludesfile (if any)
#   Repo   : .git/config, .git/info/*, .git/hooks/* (excluding *.sample)
#
# Not saved: ~/.git-credentials (secrets) and tracked files (.gitignore etc.),
# which already live in the repository itself.

set -euo pipefail

BACKUP_ROOT="${HOME}/ProgramData/git"
GLOBAL_DIR="${BACKUP_ROOT}/global"
REPOS_DIR="${BACKUP_ROOT}/repos"
STAMP="$(date +%Y%m%d-%H%M%S)"

usage() {
  cat <<EOF
Usage: $(basename "$0") -b|-r [repo ...]

  -b    backup global git config and the given repositories
  -r    restore global git config and the given repositories
  -h    show this help

Backups are stored in: ${BACKUP_ROOT}
EOF
}

log()  { printf '[*] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }
die()  { printf '[x] %s\n' "$*" >&2; exit 1; }

# Copy a file, saving any existing destination as <dest>.bak.<timestamp>
safe_copy() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" ]] && ! cmp -s "$src" "$dest"; then
    cp -p "$dest" "${dest}.bak.${STAMP}"
  fi
  cp -p "$src" "$dest"
}

# Per-repo key: just the repo folder name
repo_key() {
  basename "$1"
}

resolve_repo() {
  local p="$1"
  [[ -d "$p" ]] || die "Not a directory: $p"
  (cd "$p" && git rev-parse --show-toplevel 2>/dev/null) || die "Not a git repository: $p"
}

# ---------------------------------------------------------------- global ---

backup_global() {
  log "Backing up global git config -> ${GLOBAL_DIR}"
  mkdir -p "$GLOBAL_DIR"

  [[ -f "$HOME/.gitconfig" ]] && safe_copy "$HOME/.gitconfig" "$GLOBAL_DIR/gitconfig"

  local f
  for f in config ignore attributes; do
    [[ -f "$HOME/.config/git/$f" ]] && safe_copy "$HOME/.config/git/$f" "$GLOBAL_DIR/xdg/$f"
  done

  # Global excludes file (core.excludesfile), may live anywhere
  local ex
  ex="$(git config --global --get core.excludesfile 2>/dev/null || true)"
  if [[ -n "$ex" ]]; then
    ex="${ex/#\~/$HOME}"
    if [[ -f "$ex" ]]; then
      safe_copy "$ex" "$GLOBAL_DIR/excludesfile"
      printf '%s\n' "$ex" > "$GLOBAL_DIR/excludesfile.path"
    fi
  fi

  return 0
}

restore_global() {
  [[ -d "$GLOBAL_DIR" ]] || { warn "No global backup found in ${GLOBAL_DIR}"; return 0; }
  log "Restoring global git config"

  [[ -f "$GLOBAL_DIR/gitconfig" ]] && safe_copy "$GLOBAL_DIR/gitconfig" "$HOME/.gitconfig"

  local f
  for f in config ignore attributes; do
    [[ -f "$GLOBAL_DIR/xdg/$f" ]] && safe_copy "$GLOBAL_DIR/xdg/$f" "$HOME/.config/git/$f"
  done

  if [[ -f "$GLOBAL_DIR/excludesfile" && -f "$GLOBAL_DIR/excludesfile.path" ]]; then
    safe_copy "$GLOBAL_DIR/excludesfile" "$(cat "$GLOBAL_DIR/excludesfile.path")"
  fi

  return 0
}

# ------------------------------------------------------------------ repo ---

backup_repo() {
  local abs gitdir key dest
  abs="$(resolve_repo "$1")"
  gitdir="$(cd "$abs" && git rev-parse --absolute-git-dir)"
  key="$(repo_key "$abs")"
  dest="${REPOS_DIR}/${key}"

  # Guard against two different repos sharing the same folder name
  if [[ -f "$dest/path" && "$(cat "$dest/path")" != "$abs" ]]; then
    warn "Skipping ${abs}: backup name '${key}' already belongs to $(cat "$dest/path")"
    return 0
  fi

  log "Backing up repo: ${abs}"
  mkdir -p "$dest"
  printf '%s\n' "$abs" > "$dest/path"

  [[ -f "$gitdir/config" ]] && safe_copy "$gitdir/config" "$dest/config"

  local f
  if [[ -d "$gitdir/info" ]]; then
    for f in "$gitdir"/info/*; do
      if [[ -f "$f" ]]; then
        safe_copy "$f" "$dest/info/$(basename "$f")"
      fi
    done
  fi

  if [[ -d "$gitdir/hooks" ]]; then
    for f in "$gitdir"/hooks/*; do
      if [[ -f "$f" && "$f" != *.sample ]]; then
        safe_copy "$f" "$dest/hooks/$(basename "$f")"
      fi
    done
  fi

  return 0
}

restore_repo() {
  local abs gitdir key src
  abs="$(resolve_repo "$1")"
  gitdir="$(cd "$abs" && git rev-parse --absolute-git-dir)"
  key="$(repo_key "$abs")"
  src="${REPOS_DIR}/${key}"

  [[ -d "$src" ]] || { warn "No backup for repo: ${abs}"; return 0; }
  if [[ -f "$src/path" && "$(cat "$src/path")" != "$abs" ]]; then
    warn "Skipping ${abs}: backup '${key}' was made from $(cat "$src/path")"
    return 0
  fi
  log "Restoring repo: ${abs}"

  [[ -f "$src/config" ]] && safe_copy "$src/config" "$gitdir/config"

  local f
  if [[ -d "$src/info" ]]; then
    for f in "$src"/info/*; do
      if [[ -f "$f" ]]; then
        safe_copy "$f" "$gitdir/info/$(basename "$f")"
      fi
    done
  fi

  if [[ -d "$src/hooks" ]]; then
    for f in "$src"/hooks/*; do
      if [[ -f "$f" ]]; then
        safe_copy "$f" "$gitdir/hooks/$(basename "$f")"
        chmod +x "$gitdir/hooks/$(basename "$f")"
      fi
    done
  fi

  return 0
}

# ------------------------------------------------------------------ main ---

command -v git >/dev/null 2>&1 || die "git is not installed"

MODE=""
while getopts ":brh" opt; do
  case "$opt" in
    b) [[ -z "$MODE" ]] || die "Use only one of -b or -r"; MODE="backup" ;;
    r) [[ -z "$MODE" ]] || die "Use only one of -b or -r"; MODE="restore" ;;
    h) usage; exit 0 ;;
    \?) usage; die "Unknown option: -$OPTARG" ;;
  esac
done
shift $((OPTIND - 1))

[[ -n "$MODE" ]] || { usage; exit 1; }

case "$MODE" in
  backup)
    mkdir -p "$BACKUP_ROOT"
    backup_global
    for repo in "$@"; do backup_repo "$repo"; done
    log "Backup complete: ${BACKUP_ROOT}"
    ;;
  restore)
    [[ -d "$BACKUP_ROOT" ]] || die "Backup directory not found: ${BACKUP_ROOT}"
    restore_global
    for repo in "$@"; do restore_repo "$repo"; done
    log "Restore complete"
    ;;
esac