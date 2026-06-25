#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

COMMAND=${1:-up}
NAME=${OPENALICE_CONTAINER_NAME:-openalice}
IMAGE=${OPENALICE_IMAGE:-openalice:local}
VOLUME=${OPENALICE_VOLUME:-openalice-data}
HOST_IP=${OPENALICE_HOST_IP:-127.0.0.1}
HOST_PORT=${OPENALICE_HOST_PORT:-47331}
BUILD_MEMORY=${OPENALICE_BUILD_MEMORY:-6G}
BUILD_CPUS=${OPENALICE_BUILD_CPUS:-4}

usage() {
  cat <<'EOF'
Usage: scripts/run-container.sh [up|down|reset|logs|status|auth-claude|auth-codex|help]

Environment:
  OPENALICE_RUNTIME=auto|container-compose|container|docker
                                           Runtime selector. Default: auto.
  OPENALICE_CONTAINER_NAME=openalice       Container name for manual Apple container.
  OPENALICE_IMAGE=openalice:local          Image name.
  OPENALICE_VOLUME=openalice-data          Persistent volume name.
  OPENALICE_HOST_IP=127.0.0.1              Host bind IP for manual Apple container.
  OPENALICE_HOST_PORT=47331                Host web port for manual Apple container.
  OPENALICE_BUILD_MEMORY=6G                Apple container builder memory.
  OPENALICE_BUILD_CPUS=4                   Apple container builder CPUs.
EOF
}

have() {
  command -v "$1" >/dev/null 2>&1
}

is_macos() {
  [ "$(uname -s)" = "Darwin" ]
}

has_container_compose() {
  have container || return 1
  container compose --help >/dev/null 2>&1
}

select_runtime() {
  case "${OPENALICE_RUNTIME:-auto}" in
    container-compose) echo container-compose ;;
    container) echo container ;;
    docker) echo docker ;;
    auto)
      if is_macos && has_container_compose; then
        echo container-compose
      elif is_macos && have container; then
        echo container
      else
        echo docker
      fi
      ;;
    *)
      echo "Unknown OPENALICE_RUNTIME=${OPENALICE_RUNTIME}" >&2
      exit 2
      ;;
  esac
}

container_exists() {
  container inspect "$NAME" >/dev/null 2>&1
}

run_container_up() {
  have container || { echo "Apple container CLI not found" >&2; exit 1; }
  container system start >/dev/null 2>&1 || true
  container build --memory "$BUILD_MEMORY" --cpus "$BUILD_CPUS" -t "$IMAGE" .
  if container_exists; then
    container stop "$NAME" >/dev/null 2>&1 || true
    container delete "$NAME" >/dev/null 2>&1 || true
  fi
  container volume create "$VOLUME" >/dev/null 2>&1 || true
  container run -d \
    --name "$NAME" \
    -p "${HOST_IP}:${HOST_PORT}:47331" \
    -v "${VOLUME}:/data" \
    "$IMAGE"
  echo "OpenAlice: http://${HOST_IP}:${HOST_PORT}"
}

run_container_down() {
  have container || { echo "Apple container CLI not found" >&2; exit 1; }
  container stop "$NAME" >/dev/null 2>&1 || true
  container delete "$NAME" >/dev/null 2>&1 || true
}

run_container_reset() {
  run_container_down
  container volume delete "$VOLUME" >/dev/null 2>&1 || true
}

run_container_logs() {
  container logs --follow "$NAME"
}

run_container_status() {
  container list --all
}

run_container_exec() {
  container exec -i -t --user node "$NAME" "$@"
}

run_docker_compose() {
  have docker || { echo "Docker CLI not found" >&2; exit 1; }
  docker compose "$@"
}

run_container_compose() {
  have container || { echo "Apple container CLI not found" >&2; exit 1; }
  container system start >/dev/null 2>&1 || true
  container compose "$@"
}

runtime=$(select_runtime)

case "$COMMAND:$runtime" in
  help:*|-h:*|--help:*) usage ;;
  up:container-compose) run_container_compose up -d --build ;;
  down:container-compose) run_container_compose down ;;
  reset:container-compose) run_container_compose down -v ;;
  logs:container-compose) run_container_compose logs -f openalice ;;
  status:container-compose) run_container_compose ps ;;
  auth-claude:container-compose) run_container_compose exec --user node openalice claude ;;
  auth-codex:container-compose) run_container_compose exec --user node openalice codex login ;;
  up:container) run_container_up ;;
  down:container) run_container_down ;;
  reset:container) run_container_reset ;;
  logs:container) run_container_logs ;;
  status:container) run_container_status ;;
  auth-claude:container) run_container_exec claude ;;
  auth-codex:container) run_container_exec codex login ;;
  up:docker) run_docker_compose up -d --build ;;
  down:docker) run_docker_compose down ;;
  reset:docker) run_docker_compose down -v ;;
  logs:docker) run_docker_compose logs -f openalice ;;
  status:docker) run_docker_compose ps ;;
  auth-claude:docker) run_docker_compose exec --user node openalice claude ;;
  auth-codex:docker) run_docker_compose exec --user node openalice codex login ;;
  *)
    usage >&2
    exit 2
    ;;
esac
