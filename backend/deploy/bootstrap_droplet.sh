#!/usr/bin/env bash
set -euo pipefail

DEPLOY_USER="${DEPLOY_USER:-deploy}"
APP_DIR="${APP_DIR:-/srv/syntrak-application}"
ENABLE_UFW="${ENABLE_UFW:-true}"

export DEBIAN_FRONTEND=noninteractive

log() {
  printf '[bootstrap] %s\n' "$1"
}

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "This script must run as root."
    exit 1
  fi
}

install_docker() {
  log "Installing Docker Engine and Compose plugin"
  apt-get update
  apt-get install -y --no-install-recommends ca-certificates curl gnupg git ufw

  install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
    local codename
    codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable" \
      > /etc/apt/sources.list.d/docker.list
  fi

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
}

install_caddy() {
  log "Installing Caddy"
  if ! command -v caddy >/dev/null 2>&1; then
    apt-get install -y caddy
  fi
  systemctl enable --now caddy
}

configure_user() {
  log "Creating deploy user and app directory"
  if ! id "$DEPLOY_USER" >/dev/null 2>&1; then
    adduser --disabled-password --gecos "" "$DEPLOY_USER"
  fi

  usermod -aG docker "$DEPLOY_USER"
  mkdir -p "$APP_DIR"
  chown -R "$DEPLOY_USER:$DEPLOY_USER" "$APP_DIR"
}

configure_firewall() {
  if [[ "$ENABLE_UFW" != "true" ]]; then
    log "Skipping UFW configuration"
    return
  fi

  log "Configuring UFW"
  ufw allow OpenSSH
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable
}

main() {
  require_root
  install_docker
  install_caddy
  configure_user
  configure_firewall

  log "Bootstrap complete"
  log "Next: copy backend/deploy/Caddyfile.example to /etc/caddy/Caddyfile and configure DNS"
}

main "$@"