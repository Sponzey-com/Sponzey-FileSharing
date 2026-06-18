#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
ROOT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")/.." && pwd)"
cd "${ROOT_DIR}"

version_from_pubspec() {
  sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -n 1
}

APP_VERSION="${SPONZEY_APP_VERSION:-$(version_from_pubspec)}"
if [[ -z "${APP_VERSION}" ]]; then
  echo "Unable to determine app version. Set SPONZEY_APP_VERSION before running the release gate."
  exit 1
fi

echo "Sponzey FileSharing release gate"
echo "appVersion=${APP_VERSION}"

run_step() {
  local name="$1"
  shift
  echo ""
  echo "==> ${name}"
  "$@"
}

run_step "Flutter version" flutter --version
run_step "Resolve dependencies" flutter pub get
run_step "Analyze" flutter analyze
run_step "Test" flutter test --concurrency=1 --reporter expanded

case "$(uname -s)" in
  Darwin)
    run_step "Enable macOS desktop" flutter config --enable-macos-desktop
    run_step "Build macOS release" flutter build macos --release "--dart-define=SPONZEY_APP_VERSION=${APP_VERSION}"
    ;;
  Linux)
    run_step "Enable Linux desktop" flutter config --enable-linux-desktop
    run_step "Build Linux release" flutter build linux --release "--dart-define=SPONZEY_APP_VERSION=${APP_VERSION}"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    echo ""
    echo "Windows detected from a Unix-like shell. Use scripts\\build_windows.ps1 -AppVersion ${APP_VERSION} for the Windows build smoke."
    ;;
  *)
    echo ""
    echo "Unknown OS. Automated build smoke skipped; run the matching platform build manually."
    ;;
esac

cat <<'EOF'

Manual release gate still required:
- macOS host <-> macOS second instance discovery/auth/transfer/digest
- macOS host -> Parallels Windows VM discovery/auth/transfer/digest
- Parallels Windows VM -> macOS host discovery/auth/transfer/digest
- macOS host -> Ubuntu 22.04 discovery/auth/transfer/digest
- Ubuntu 22.04 -> macOS host discovery/auth/transfer/digest
- same UID one peer product UI check for every scenario
- TCP data session stability check for every transfer
- TCP data session last close reason review for failed transfers
- diagnostics export redaction review for every scenario
- 100 MB benchmark record in .tasks/release_runs/<tag>.md

CI success and this script alone do not approve a final release.
EOF
