#!/usr/bin/env bash
set -euo pipefail

FINAL_CONFIG="final.config.yaml"

if [[ ! -f "$FINAL_CONFIG" ]]; then
  echo "❌ No final.config.yaml found. Run setup.sh first."
  exit 1
fi

# --- Uninstall apps ---
APPS=$(yq e '.apps[] | select(.required == true) | .name' "$FINAL_CONFIG")
if [[ -n "$APPS" ]]; then
  echo "🗑 Uninstalling apps: $APPS"
  brew uninstall --cask $APPS || true
fi

# --- Uninstall extra packages ---
brew uninstall yarn pnpm || true
brew uninstall nvm || true

# --- Reset git config ---
echo "⚙️ Resetting git config"
git config --global --unset user.name || true
git config --global --unset user.email || true

echo "🧹 Teardown complete!"
