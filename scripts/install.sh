#!/usr/bin/env bash
# Installs mariadb-x-pma into ~/.local/bin and wires up convenience aliases.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$REPO_DIR/bin/mariadb-x-pma"
BIN_DIR="${HOME}/.local/bin"
ALIASES="${HOME}/.bash_aliases"

mkdir -p "$BIN_DIR"

# 1) Main CLI on PATH
ln -sf "$CLI" "$BIN_DIR/mariadb-x-pma"

# 2) `pma` wrapper so existing muscle memory keeps working
cat > "$BIN_DIR/pma" <<EOF
#!/usr/bin/env bash
exec "$CLI" pma "\$@"
EOF
chmod +x "$BIN_DIR/pma"

# 3) Convenience aliases (append once)
if ! grep -q '^alias mariadb-start=' "$ALIASES" 2>/dev/null; then
    cat >> "$ALIASES" <<'EOF'

# mariadb-x-pma
alias mariadb-start='mariadb-x-pma mariadb start'
alias mariadb-stop='mariadb-x-pma mariadb stop'
alias mariadb-status='mariadb-x-pma mariadb status'
alias mariadb-restart='mariadb-x-pma mariadb restart'
EOF
fi

echo "Installed."
echo "  CLI:        $BIN_DIR/mariadb-x-pma"
echo "  pma wrapper: $BIN_DIR/pma"
echo "  aliases:    appended to $ALIASES (run 'source $ALIASES' in current shells)"
echo
echo "Usage:"
echo "  mariadb-x-pma mariadb start|stop|status|restart"
echo "  mariadb-x-pma pma     start|stop|status|restart"
echo "  mariadb-x-pma serve   # start both"