#!/usr/bin/env bash
set -euo pipefail

INSTALLED_CONFIG="installed.yaml"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -h, --help          Show this help message"
      echo ""
      echo "The script will:"
      echo "  1. Use installed.yaml (created by setup.sh)"
      echo "  2. Uninstall only what was installed by this dev-env-setup"
      echo "  3. Clean up installed.yaml when done"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Check for installed.yaml
if [[ ! -f "$INSTALLED_CONFIG" ]]; then
  echo "❌ No installed.yaml found. Run setup.sh first."
  exit 1
fi

echo "📦 Using installed config: $INSTALLED_CONFIG"

# --- Uninstall packages ---
echo "🗑 Uninstalling packages..."

# Get all packages that were installed
PACKAGES=$(yq e '.packages[]' "$INSTALLED_CONFIG")

if [[ -n "$PACKAGES" ]]; then
  echo "🗑 Uninstalling packages: $PACKAGES"
  
  # Uninstall packages using Homebrew
  for package in $PACKAGES; do
    echo "  Uninstalling: $package"
    if [[ "$package" =~ ^(iterm2|visual-studio-code|slack|zoom|microsoft-teams|docker)$ ]]; then
      # Uninstall as cask (GUI applications)
      brew uninstall --cask "$package" || echo "  ⚠️ Failed to uninstall $package (cask)"
    else
      # Uninstall as formula (command line tools)
      brew uninstall "$package" || echo "  ⚠️ Failed to uninstall $package (formula)"
    fi
  done
else
  echo "ℹ️ No packages to uninstall"
fi

# --- Reset git config ---
echo "⚙️ Resetting git config"
GIT_NAME=$(yq e '.git.user.name // ""' "$INSTALLED_CONFIG")
GIT_EMAIL=$(yq e '.git.user.email // ""' "$INSTALLED_CONFIG")

if [[ -n "$GIT_NAME" && -n "$GIT_EMAIL" ]]; then
  echo "🔄 Resetting git user.name and user.email"
  git config --global --unset user.name || true
  git config --global --unset user.email || true
else
  echo "ℹ️ No git config to reset (wasn't configured during setup)"
fi

# --- Clean up installed.yaml ---
echo "🧹 Cleaning up installed.yaml"
rm -f "$INSTALLED_CONFIG"

echo "✅ Teardown complete!"
