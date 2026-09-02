[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/ptmkenny/ddev-codex/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/ptmkenny/ddev-codex/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/ptmkenny/ddev-codex)](https://github.com/ptmkenny/ddev-codex/commits)
[![release](https://img.shields.io/github/v/release/ptmkenny/ddev-codex)](https://github.com/ptmkenny/ddev-codex/releases/latest)

# DDEV Codex

This add-on installs the [OpenAI Codex CLI](https://learn.chatgpt.com/docs/codex/cli)
in your DDEV project's web container. It supports AMD64 and ARM64 hosts.

## Installation

```bash
ddev add-on get ptmkenny/ddev-codex
ddev restart
```

Commit the generated files under `.ddev`, including `.ddev/codex/.gitignore`.
Codex state and credentials within `.ddev/codex/` will be ignored.

## Authentication

If you have a ChatGPT subscription, enable device code authorization in your
ChatGPT security settings and run:

```bash
ddev codex login --device-auth
```

Open the displayed URL in a browser and enter the one-time code. Codex stores
the resulting credentials in `.ddev/codex/`, where they persist across DDEV
restarts.

To use an API key instead, pipe it to Codex from your host environment:

```bash
printf '%s' "$OPENAI_API_KEY" | ddev codex login --with-api-key
```

Treat `.ddev/codex/auth.json` as a secret. Do not commit or share it.

## Usage

```bash
# Start an interactive session in the project root.
ddev codex

# Show CLI help or the installed version.
ddev codex --help
ddev codex --version

# Run a prompt directly.
ddev codex "explain this project"
```

The add-on also installs Bubblewrap and Python Pillow. Pillow supports Codex
image-generation helper scripts that need the `PIL` Python package.

## Codex version

The latest Codex release is installed by default. To pin a release, create
`.ddev/.env.codex`:

```dotenv
CODEX_VERSION=0.152.1
```

Then rebuild the web image without its Docker cache:

```bash
ddev restart --no-cache
```

Use the same command to update a project that follows `latest`.

## Linux sandbox inside DDEV

Codex's Linux sandbox uses Bubblewrap and user namespaces. Some Docker and DDEV
environments block the namespace operations Bubblewrap needs. This add-on does
not grant `SYS_ADMIN` or disable Docker's seccomp or AppArmor protections.

If Codex reports that Bubblewrap cannot create a namespace, you can treat the
DDEV web container as the outer sandbox:

```bash
ddev codex --dangerously-bypass-approvals-and-sandbox
```

This flag disables both Codex approvals and its sandbox. Use it only when you
accept the DDEV container as the security boundary.

## Removal

```bash
ddev add-on remove codex
```

DDEV preserves `.ddev/codex/` when it contains Codex state. Remove that
directory manually if you also want to delete the stored credentials and
configuration.

## Credits

This add-on was inspired by
[`Gonzalo2683/ddev-codex`](https://github.com/Gonzalo2683/ddev-codex).
Patrick Kenny maintains this implementation at
[`ptmkenny/ddev-codex`](https://github.com/ptmkenny/ddev-codex).

## License

Apache License 2.0. See [LICENSE](LICENSE).
