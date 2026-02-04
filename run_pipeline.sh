#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Load host-side variables (.env)
# ============================================================

if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

# ============================================================
# Load container-side path config (container.env)
# ============================================================

if [[ -f container.env ]]; then
  set -a
  source container.env
  set +a
fi

# ============================================================
# CONFIG
# ============================================================

ENVIRONMENT="${ENV:-prod}"

PATHCOV_SERVICE="pathcov"
JDART_SERVICE="jdart"

PATHCOV_SCRIPT="${CONTAINER_SCRIPTS_DIR}/run_pathcov_pipeline.sh"
SUT_CONFIG="${CONTAINER_CONFIGS_DIR}/sut.config"
JDART_JPF_CONFIG="${CONTAINER_CONFIGS_DIR}/sut.jpf"

DATA_DIR="${CONTAINER_DATA_DIR}"

# ============================================================
# LOGGING
# ============================================================

log() {
  echo "[INFO] $*"
}

# ============================================================
# Compose file stack builder
# ============================================================

compose_up() {
  FILES="-f docker-compose.yml"

  # Only include override in NON-dev environments
  if [[ "$ENVIRONMENT" != "dev" && -f docker-compose.override.yml ]]; then
    FILES="$FILES -f docker-compose.override.yml"
  fi

  [[ -f docker-compose.sut.yml ]] && FILES="$FILES -f docker-compose.sut.yml"
  [[ -f docker-compose.deps.yml ]] && FILES="$FILES -f docker-compose.deps.yml"

  docker compose --env-file container.env $FILES up -d
}

compose_exec() {
  FILES="-f docker-compose.yml"

  # Only include override in NON-dev environments
  if [[ "$ENVIRONMENT" != "dev" && -f docker-compose.override.yml ]]; then
    FILES="$FILES -f docker-compose.override.yml"
  fi

  [[ -f docker-compose.sut.yml ]] && FILES="$FILES -f docker-compose.sut.yml"
  [[ -f docker-compose.deps.yml ]] && FILES="$FILES -f docker-compose.deps.yml"

  docker compose --env-file container.env $FILES exec "$@"
}


# ============================================================
# MAIN
# ============================================================

main() {
  log "⚙️ Environment: $ENVIRONMENT"

  log "⚙️ Generating tool-specific configs from sut.yml"
  python3 scripts/generate_sut_configs.py

  log "⚙️ Generating docker-compose.sut.yml for SUT"
  python3 scripts/generate_sut_compose.py

  if [[ "$ENVIRONMENT" == "dev" ]]; then
    mkdir -p ./development/data
  fi

  log "⚙️ Starting containers"
  compose_up

  log "⚙️ Running pathcov stage"
  compose_exec "$PATHCOV_SERVICE" "$PATHCOV_SCRIPT" "$SUT_CONFIG" "$DATA_DIR"

  log "⚙️ Running JDart / JPF stage"
  compose_exec "$JDART_SERVICE" /jdart-project/jpf-core/bin/jpf "$JDART_JPF_CONFIG"

  log "✅ Pipeline completed successfully"
}

main "$@"
