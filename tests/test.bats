#!/usr/bin/env bats

# Bats is a testing framework for Bash.
# Documentation: https://bats-core.readthedocs.io/en/stable/

setup() {
  set -eu -o pipefail

  export GITHUB_REPO=ptmkenny/ddev-codex

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH:-}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  mkdir -p "${HOME}/tmp"
  export TESTDIR="$(mktemp -d "${HOME}/tmp/${PROJNAME}.XXXXXX")"
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site
  assert_success
  run ddev start -y
  assert_success
}

restart_project() {
  run ddev restart -y
  if [ "${status}" -ne 0 ]; then
    printf '%s\n' "${output}" >&3
    ddev logs --service web >&3 2>&1 || true
  fi
  assert_success
}

health_checks() {
  run ddev codex --version
  assert_success
  assert_output --regexp 'codex-cli [0-9]+'

  run ddev codex --help
  assert_success
  assert_output --partial "Codex CLI"

  run ddev exec --service codex command -v codex
  assert_success
  assert_output --partial "/usr/local/bin/codex"

  run ddev exec --service codex command -v bwrap
  assert_success

  run ddev exec --service codex python3 -c 'from PIL import Image; assert Image'
  assert_success

  run ddev exec --service codex 'test "${CODEX_HOME}" = /mnt/codex-config && test -w "${CODEX_HOME}"'
  assert_success

  run ddev exec --service codex bwrap --unshare-user --uid 0 --gid 0 --ro-bind / / --proc /proc --dev /dev true
  assert_success

  run ddev exec --service codex 'getent hosts web >/dev/null && getent hosts db >/dev/null'
  assert_success

  run ddev exec --service codex 'test ! -S /var/run/docker.sock && test ! -S /home/.ssh-agent/socket'
  assert_success

  run docker inspect --format '{{json .HostConfig.SecurityOpt}}' "ddev-${PROJNAME}-codex"
  assert_success
  assert_output --partial "no-new-privileges:true"
  assert_output --partial "seccomp=unconfined"

  run docker inspect --format '{{json .HostConfig.CapDrop}}' "ddev-${PROJNAME}-codex"
  assert_success
  assert_output --partial 'ALL'

  run docker inspect --format '{{json .HostConfig.SecurityOpt}}' "ddev-${PROJNAME}-web"
  assert_success
  refute_output --partial "seccomp=unconfined"

  web_image="$(docker inspect --format '{{.Config.Image}}' "ddev-${PROJNAME}-web")"
  codex_image="$(docker inspect --format '{{.Config.Image}}' "ddev-${PROJNAME}-codex")"
  assert_equal "${codex_image}" "${web_image}"

  web_project_mount="$(docker inspect --format '{{range .Mounts}}{{if or (eq .Destination "/var/www") (eq .Destination "/var/www/html")}}{{.Source}}{{end}}{{end}}' "ddev-${PROJNAME}-web")"
  codex_project_mount="$(docker inspect --format '{{range .Mounts}}{{if or (eq .Destination "/var/www") (eq .Destination "/var/www/html")}}{{.Source}}{{end}}{{end}}' "ddev-${PROJNAME}-codex")"
  assert_equal "${codex_project_mount}" "${web_project_mount}"

  # DDEV treats empty files as safe to remove, so use nonempty state here.
  run ddev exec --service codex 'printf "%s\n" persistent-state > /mnt/codex-config/test-sentinel'
  assert_success
  restart_project
  assert_file_exists "${TESTDIR}/.ddev/codex/test-sentinel"

  run ddev add-on remove codex
  assert_success
  assert_file_exists "${TESTDIR}/.ddev/codex/test-sentinel"
  assert_file_exists "${TESTDIR}/.ddev/codex/.gitignore"
  assert_file_not_exists "${TESTDIR}/.ddev/docker-compose.codex-project.yaml"
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  if [ -n "${GITHUB_ENV:-}" ]; then
    [ -e "${GITHUB_ENV:-}" ] && echo "TESTDIR=${HOME}/tmp/${PROJNAME}" >> "${GITHUB_ENV}"
  else
    [ "${TESTDIR}" != "" ] && rm -rf "${TESTDIR}"
  fi
}

@test "install from directory" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  restart_project
  health_checks
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  restart_project
  health_checks
}
