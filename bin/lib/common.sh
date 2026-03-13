#!/usr/bin/env bash
# Shared functions for Java LSP plugin scripts.
# Source this file — do not execute directly.
#
# After sourcing, the following functions and variables are available:
#   resolve_java       - Sets JAVA and JAVA_VERSION; returns 1 if not found or < 21
#   find_jdtls         - Sets JDTLS_HOME from env or known paths; returns 1 if not found
#   download_jdtls     - Downloads latest JDTLS, sets JDTLS_HOME; returns 1 on failure
#   find_launcher_jar  - Sets LAUNCHER_JAR; returns 1 if not found
#   detect_config_dir  - Sets CONFIG_DIR for the current platform; returns 1 if not found

JDTLS_INSTALL_DIR="$HOME/.local/share/jdtls"
JDTLS_MILESTONES_URL="https://download.eclipse.org/jdtls/milestones"

resolve_java() {
  JAVA=""
  JAVA_VERSION=""

  if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    JAVA="$JAVA_HOME/bin/java"
  else
    JAVA="$(command -v java 2>/dev/null || true)"
  fi

  if [ -z "$JAVA" ] || [ ! -x "$JAVA" ]; then
    return 1
  fi

  JAVA_VERSION=$("$JAVA" -version 2>&1 | head -1 | sed -E 's/.*"([0-9]+).*/\1/')
  if [ "$JAVA_VERSION" -lt 21 ] 2>/dev/null; then
    return 1
  fi

  return 0
}

find_jdtls() {
  if [ -n "${JDTLS_HOME:-}" ] && [ -d "$JDTLS_HOME/plugins" ]; then
    return 0
  fi

  local CANDIDATES=(
    "$JDTLS_INSTALL_DIR"                     # Auto-downloaded location
    "/opt/homebrew/opt/jdtls/libexec"        # Homebrew on Apple Silicon
    "/usr/local/opt/jdtls/libexec"           # Homebrew on Intel Mac
    "/usr/share/java/jdtls"                  # Linux package manager
    "/opt/jdtls"                             # Manual install
    "$HOME/jdtls"                            # Simple user install
  )
  for candidate in "${CANDIDATES[@]}"; do
    if [ -d "$candidate/plugins" ]; then
      JDTLS_HOME="$candidate"
      return 0
    fi
  done
  return 1
}

download_jdtls() {
  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required for auto-download." >&2
    return 1
  fi

  local LATEST_VERSION
  LATEST_VERSION=$(curl -fsSL "$JDTLS_MILESTONES_URL/" 2>/dev/null \
    | grep -oE '1\.[0-9]+\.[0-9]+' \
    | sort -t. -k1,1n -k2,2n -k3,3n \
    | tail -1)

  if [ -z "$LATEST_VERSION" ]; then
    echo "Error: Could not determine the latest JDTLS version." >&2
    return 1
  fi
  echo "Latest version: $LATEST_VERSION" >&2

  local FILENAME
  FILENAME=$(curl -fsSL "$JDTLS_MILESTONES_URL/$LATEST_VERSION/latest.txt" 2>/dev/null | tr -d '[:space:]')
  if [ -z "$FILENAME" ]; then
    echo "Error: Could not determine the download filename for JDTLS $LATEST_VERSION." >&2
    return 1
  fi

  local DOWNLOAD_URL="$JDTLS_MILESTONES_URL/$LATEST_VERSION/$FILENAME"
  echo "Downloading from: $DOWNLOAD_URL" >&2

  mkdir -p "$JDTLS_INSTALL_DIR"
  if curl -fSL --progress-bar "$DOWNLOAD_URL" 2>&2 | tar xz -C "$JDTLS_INSTALL_DIR"; then
    echo "Eclipse JDTLS $LATEST_VERSION installed to $JDTLS_INSTALL_DIR" >&2
    JDTLS_HOME="$JDTLS_INSTALL_DIR"
    return 0
  else
    rm -rf "$JDTLS_INSTALL_DIR"
    echo "Error: Download or extraction failed." >&2
    return 1
  fi
}

find_launcher_jar() {
  LAUNCHER_JAR=""
  if [ -z "${JDTLS_HOME:-}" ] || [ ! -d "$JDTLS_HOME/plugins" ]; then
    return 1
  fi
  LAUNCHER_JAR=$(find "$JDTLS_HOME/plugins" -name 'org.eclipse.equinox.launcher_*.jar' -print -quit 2>/dev/null)
  [ -n "$LAUNCHER_JAR" ]
}

detect_config_dir() {
  CONFIG_DIR=""
  if [ -z "${JDTLS_HOME:-}" ]; then
    return 1
  fi

  local OS_TYPE
  OS_TYPE="$(uname -s)"
  case "$OS_TYPE" in
    Linux*)  CONFIG_DIR="$JDTLS_HOME/config_linux" ;;
    Darwin*) CONFIG_DIR="$JDTLS_HOME/config_mac" ;;
    *)       return 1 ;;
  esac

  [ -d "$CONFIG_DIR" ]
}
