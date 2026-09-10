# Changelog

Every change someone using this role would notice goes here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions are git tags of the form `v1.2.3`.

## [Unreleased]

### Changed

- **The role is a breaking rewrite of the 2021 version.** Every variable is now prefixed `devops_`, a profile (`workstation`, `server` or `container`) picks the component set, and `meta/argument_specs.yml` validates every run before the first task. The README's *Upgrading from the 2021 role* section maps the old variables to the new ones.
- Terraform, Packer, Vault, Vagrant, Docker, kubectl, k6, ngrok, `gh` and Grafana install from their vendor repositories, so there are no version pins to go stale. Helm, Go, k9s and the AWS CLI resolve their latest release at run time.
- Supported platforms are Ubuntu 22.04 and 24.04, Debian 12 and 13, Fedora, and RHEL 9 derivatives, on `amd64` and `arm64`. `ansible-core` 2.15 or newer is required.
- The example git identity in the README and `playbooks/workstation.yml` is a placeholder, `Your Name`.
- The role metadata names Luis Tineo as its author.

### Added

- `make check` runs `yamllint`, `ansible-lint` and a syntax check of both example playbooks, and CI runs it on every push and pull request.
- `requirements-dev.txt` pins the linter and Molecule versions CI installs.
- `make converge` runs the Molecule scenario, and CI runs it on Ubuntu 24.04, Debian 12 and Rocky Linux 9 after `make check` passes.
- `make check` and `make converge` find the role as `devops` whatever the clone is called. Running the example playbooks by hand still needs the clone to be named `devops`, as the README says.
- A release workflow that publishes a GitHub Release from this file when a `v*` tag is pushed.

### Fixed

- **The server profile crashed when the target account did not exist yet**, which is the case it is for. A missing account now reaches the role's own message, or is created when `devops_create_user` is true.
- `devops_user` reads `SUDO_USER` from `ansible_facts.env`, so it keeps working after `ansible-core` 2.24 removes the injected `ansible_env` variable.
- `docs/from-nothing.md`, a step-by-step guide from a clean machine to a provisioned one.

### Removed

- Travis CI, the private repository clones, the cache warmer, the Flood/Element harness and the `sitespeedio` service account.
