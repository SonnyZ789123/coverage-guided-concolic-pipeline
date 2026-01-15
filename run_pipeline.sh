#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Load .env if present (for shell scripts)
# ============================================================

if [[ -f .env ]]; then
  # Export all variables from .env
  set -a
  source .env
  set +a
fi


# ============================================================
# CONFIG
# ============================================================

ENVIRONMENT="${ENV:-prod}"

# Docker Compose services
PATHCOV_SERVICE="pathcov"
JDART_SERVICE="jdart"

# Scripts / configs inside containers
PATHCOV_SCRIPT="/scripts/generate_pathcov.sh"
SUT_CONFIG="/configs/sut.config"
JDART_JPF_CONFIG="/configs/sut.jpf"

# Optional arguments
DATA_DIR="/data"

# ============================================================
# LOGGING
# ============================================================

log() {
  echo "[INFO] $*"
}

# ============================================================
# MAIN
# ============================================================

main() {
  log "⚙️ Setting up environment for '$ENVIRONMENT'"

  log "⚙️ Generating tool-specific configs from sut.yml"
  python3 scripts/generate_sut_configs.py

  log "⚙️ Starting containers"

  if [[ "$ENVIRONMENT" == "prod" ]]; then
    docker compose -f docker-compose.yml up -d
  else
    docker compose up -d
  fi

  log "⚙️ Running pathcov stage"
  docker compose exec "$PATHCOV_SERVICE" "$PATHCOV_SCRIPT" "$SUT_CONFIG" "$DATA_DIR"

  log "⚙️ Running JDart / JPF stage"
  docker compose exec "$JDART_SERVICE" /jdart-project/jpf-core/bin/jpf "$JDART_JPF_CONFIG"

  log "✅ Pipeline completed successfully"
}

main "$@"
