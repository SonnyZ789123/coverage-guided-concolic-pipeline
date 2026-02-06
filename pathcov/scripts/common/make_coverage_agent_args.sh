#!/usr/bin/env bash
set -Eeuo pipefail

# ------------------------------------------------------------
# Args
# ------------------------------------------------------------

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <coverage_report_path> <cg_classes_output_path> <output_config_args_path>" >&2
  exit 1
fi

INTELLIJ_COVERAGE_REPORT_PATH="$1"
CG_CLASSES_OUTPUT_PATH="$2"
INTELLIJ_COVERAGE_AGENT_CONFIG_PATH="$3"

# ------------------------------------------------------------
# Ensure output directory exists
# ------------------------------------------------------------

mkdir -p "$(dirname "$INTELLIJ_COVERAGE_AGENT_CONFIG_PATH")"

# ------------------------------------------------------------
# Generate config.args
# ------------------------------------------------------------

cat > "$INTELLIJ_COVERAGE_AGENT_CONFIG_PATH" <<EOF
${INTELLIJ_COVERAGE_REPORT_PATH}
false
false
false
false
$(cat "$CG_CLASSES_OUTPUT_PATH")
-exclude
EOF

echo "[OK] Generated IntelliJ coverage agent args:"
echo "  $INTELLIJ_COVERAGE_AGENT_CONFIG_PATH"
