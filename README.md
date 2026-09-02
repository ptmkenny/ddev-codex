[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/ptmkenny/ddev-codex/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/ptmkenny/ddev-codex/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/ptmkenny/ddev-codex)](https://github.com/ptmkenny/ddev-codex/commits)
[![release](https://img.shields.io/github/v/release/ptmkenny/ddev-codex)](https://github.com/ptmkenny/ddev-codex/releases/latest)

# DDEV Codex

## Overview

This add-on integrates Codex into your [DDEV](https://ddev.com/) project.

## Installation

```bash
ddev add-on get ptmkenny/ddev-codex
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

## Usage

| Command | Description |
| ------- | ----------- |
| `ddev describe` | View service status and used ports for Codex |
| `ddev logs -s codex` | Check Codex logs |

## Advanced Customization

To change the Docker image:

```bash
ddev dotenv set .ddev/.env.codex --codex-docker-image="ddev/ddev-utilities:latest"
ddev add-on get ptmkenny/ddev-codex
ddev restart
```

Make sure to commit the `.ddev/.env.codex` file to version control.

All customization options (use with caution):

| Variable | Flag | Default |
| -------- | ---- | ------- |
| `CODEX_DOCKER_IMAGE` | `--codex-docker-image` | `ddev/ddev-utilities:latest` |

## Credits

**Contributed and maintained by [@ptmkenny](https://github.com/ptmkenny)**
