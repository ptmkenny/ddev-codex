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

health_checks() {
  run ddev codex --version
  assert_success
  assert_output --regexp 'codex-cli [0-9]+'

  run ddev codex --help
  assert_success
  assert_output --partial "Codex CLI"

  run ddev exec command -v codex
  assert_success
  assert_output --partial "/usr/local/bin/codex"

  run ddev exec command -v bwrap
  assert_success

  run ddev exec python3 -c 'from PIL import Image; assert Image'
  assert_success

  run ddev exec 'test "${CODEX_HOME}" = /mnt/codex-config && test -w "${CODEX_HOME}"'
  assert_success

  run ddev exec touch /mnt/codex-config/test-sentinel
  assert_success
  run ddev restart -y
  assert_success
  assert_file_exists "${TESTDIR}/.ddev/codex/test-sentinel"

  run ddev add-on remove codex
  assert_success
  assert_file_exists "${TESTDIR}/.ddev/codex/test-sentinel"
  assert_file_exists "${TESTDIR}/.ddev/codex/.gitignore"
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
  run ddev restart -y
  assert_success
  health_checks
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}
