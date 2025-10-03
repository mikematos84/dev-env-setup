#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE=""
BASE_CONFIG=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--config)
      CONFIG_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# Pick base config: config.base.yaml > config.yaml
if [[ -f "config.base.yaml" ]]; then
  BASE_CONFIG="config.base.yaml"
elif [[ -f "config.yaml" ]]; then
  BASE_CONFIG="config.yaml"
else
  echo "❌ No base config found (expected config.base.yaml or config.yaml)"
  exit 1
fi

echo "✅ Base config: $BASE_CONFIG"

# Final merged config
FINAL_CONFIG="final.config.yaml"

if [[ -n "$CONFIG_FILE" ]]; then
  echo "🔄 Merging with override: $CONFIG_FILE"
  # yq handles deep merge: override takes precedence
  yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$BASE_CONFIG" "$CONFIG_FILE" > "$FINAL_CONFIG"
else
  cp "$BASE_CONFIG" "$FINAL_CONFIG"
fi

echo "📦 Using merged config: $FINAL_CONFIG"

# --- Install Brew if missing ---
if ! command -v brew >/dev/null 2>&1; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# --- Install apps ---
APPS=$(yq e '.apps[] | select(.required == true) | .name' "$FINAL_CONFIG")
if [[ -n "$APPS" ]]; then
  echo "📦 Installing apps: $APPS"
  brew install --cask $APPS
fi

# --- Install NVM + latest Node ---
if ! command -v nvm >/dev/null 2>&1; then
  echo "⬇️ Installing NVM..."
  brew install nvm
  mkdir -p ~/.nvm
  export NVM_DIR="$HOME/.nvm"
  source "$(brew --prefix nvm)/nvm.sh"
fi

echo "⬇️ Installing latest Node.js..."
nvm install node
nvm alias default node

# --- Extra package managers ---
brew install yarn pnpm

# --- Git config ---
GIT_NAME=$(yq e '.git.user.name // ""' "$FINAL_CONFIG")
GIT_EMAIL=$(yq e '.git.user.email // ""' "$FINAL_CONFIG")

if [[ -n "$GIT_NAME" && -n "$GIT_EMAIL" ]]; then
  echo "⚙️ Setting git config"
  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
fi

echo "✅ Setup complete!"
