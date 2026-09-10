# ansible-role-devops

Provisions a machine with DevOps tooling — and sets up a new computer while it
is at it. One role, two entry points: a **workstation** profile that configures
the account you already log in as, and a **server** profile that creates and
hardens a dedicated automation account.

Supported platforms: Ubuntu 22.04/24.04, Debian 12/13, Fedora and RHEL 9
derivatives, on `amd64` and `arm64`.

## Requirements

* `ansible-core` 2.15 or newer (the role uses `deb822_repository`)
* `python3-debian` on Debian-family targets — the role installs it itself
* `community.general`: `ansible-galaxy collection install -r requirements.yml`
* Root via `become` on the target host

## How it is organised

A **profile** picks a component set; `devops_components` overrides individual
components on top of it. Nothing else needs to change to add or drop a tool:

```yaml
- role: devops
  vars:
    devops_profile: workstation
    devops_components:
      go: true          # not in the workstation preset
      kubernetes: false # do not want it on this box
```

| Profile | What it is for |
| --- | --- |
| `workstation` | A personal machine: configures the existing login user, installs the full dev + cloud toolchain. |
| `server` | A VM or EC2 instance: creates the `devops` account, skips desktop tooling. |
| `container` | A build/CI image: no systemd services, no nested Docker, no shell sugar. |

| Component | Installs |
| --- | --- |
| `base` | Distro baseline packages (`ripgrep`, `fd`, `jq`, `fzf`, build tools, …), the GitHub CLI, plus the managed shell environment fragment |
| `user` | Account, supplementary groups, SSH key, optional NOPASSWD sudo |
| `ssh` | `~/.ssh/config.d/50-devops.conf` from `devops_ssh_hosts` |
| `files` | Credentials and other files listed in `devops_provision_files` |
| `shell` | oh-my-zsh, starship, byobu, login shell |
| `git` | Global identity/config and repository clones |
| `python` | pipx-installed CLIs and an optional shared virtualenv |
| `ansible` | `ansible` via pipx, plus Galaxy collections and roles |
| `nodejs` | Node.js from NodeSource, sudo-free global npm prefix |
| `go` | Go toolchain from go.dev |
| `docker` | Engine, buildx and compose v2 from the vendor repo |
| `hashicorp` | Terraform, Packer, Vault CLI, Vagrant, Consul, Nomad from the vendor repo |
| `kubernetes` | kubectl from pkgs.k8s.io, Helm, optional k9s |
| `cloud` | AWS CLI v2, optional gcloud and Azure CLI |
| `php` | PHP + Composer, the Magento coding standard and the shared analyser configs |
| `warden` | [Warden](https://github.com/wardenenv/warden) development environment |
| `ngrok` | ngrok agent from the vendor repo |
| `k6`, `locust`, `sitespeed` | Load and performance tooling |
| `vault_server`, `semaphore`, `grafana` | Server components, off unless you ask for them |

Every component also has a tag, so a single tool can be re-run:

```bash
ansible-playbook playbooks/workstation.yml --tags docker
```

## Usage

New to Ansible, or setting up a machine from scratch? [docs/from-nothing.md](docs/from-nothing.md) walks through every step, from installing Ansible to checking the tools run.

Clone the repository as `devops`. The example playbooks ask for the role by that name, and Ansible finds a role by its directory name:

```bash
git clone https://github.com/kingletas/ansible-role-devops.git devops
cd devops
```

New computer, configuring the account you are sitting at:

```bash
ansible-galaxy collection install -r requirements.yml
ansible-playbook playbooks/workstation.yml -K
```

A remote build host:

```bash
ansible-playbook -i inventory playbooks/server.yml
```

Minimal inline example:

```yaml
- hosts: all
  become: true
  roles:
    - role: devops
      vars:
        devops_profile: workstation
        devops_git_user_name: Your Name
        devops_git_user_email: you@example.com
        devops_shell_default: /usr/bin/zsh
        devops_hashicorp_packages:
          terraform: true
          packer: true
          vault: true
          vagrant: false
```

## Variables

The full contract — types, choices and defaults — is
[`meta/argument_specs.yml`](meta/argument_specs.yml), validated on every run, so
a typo fails before the first task instead of halfway through a provision.
[`defaults/main.yml`](defaults/main.yml) carries the commented defaults. The
ones worth knowing:

| Variable | Default | Meaning |
| --- | --- | --- |
| `devops_profile` | `workstation` | Component preset |
| `devops_components` | `{}` | Per-component overrides |
| `devops_user` | invoking user | Account being configured |
| `devops_create_user` | `false` | Create it instead of expecting it |
| `devops_user_sudo` | `false` | NOPASSWD sudoers drop-in |
| `devops_shell_default` | `""` | Login shell to switch to |
| `devops_provision_files` | `[]` | Files/credentials to place (`no_log` by default) |
| `devops_git_repositories` | `[]` | Repositories to clone |
| `devops_hashicorp_packages` | terraform, packer | Which HashiCorp products to install |
| `devops_kubernetes_minor` | `latest` | pkgs.k8s.io channel, e.g. `v1.31` |
| `devops_pipx_packages` | ansible-lint, molecule, yamllint, bpytop | pipx-managed CLIs |

### Shell environment

Instead of scattering `blockinfile` markers across `.bashrc`, the role renders
a single `~/.config/devops/env.sh` and sources it from one managed block. PATH
entries for npm, Go, Composer and Warden, plus terraform completion and
starship, all live there and are re-rendered — never appended to — on each run.

## Testing

Install the pinned tools first:

```bash
pip install -r requirements-dev.txt
make collections
```

Then:

```bash
make check      # yamllint, ansible-lint and a syntax check of both playbooks
make converge   # run the role for real in a Docker container, with Molecule
```

`make converge` converges the role, runs it again to prove nothing changes, then checks that the installed tools exist and run. It uses Ubuntu 24.04 unless you pick another image:

```bash
MOLECULE_DISTRO=geerlingguy/docker-debian12-ansible:latest make converge
MOLECULE_DISTRO=rockylinux:9 MOLECULE_DOCKER_COMMAND="sleep infinity" make converge
```

CI runs `make check` on every push and pull request, then `make converge` on Ubuntu 24.04, Debian 12 and Rocky Linux 9.

Notes for the RedHat family: the role enables EPEL on RHEL derivatives (most of
the baseline CLI tools live there), skips `curl` because EL9 ships
`curl-minimal`, and leaves `direnv` to Fedora, which is the only one that
packages it. Binaries installed under `/usr/local/bin` — Helm, the AWS CLI —
are addressed by absolute path in the role, since `sudo`'s `secure_path` on EL
does not include that directory.

## Upgrading from the 2021 role

This is a breaking rewrite. The highlights:

* **Every variable is now prefixed `devops_`.** `system.user` → `devops_user`,
  `software.terraform.version` → gone (vendor repos, see below), `tools.install`
  → `devops_components.php` / `devops_php_scripts`, and so on.
* **Vendor repositories replace pinned archive downloads.** Terraform, Packer,
  Vault, Vagrant, Docker, kubectl, k6, ngrok and Grafana now come from their
  APT/DNF repositories, so `apt upgrade` keeps them current and no version
  variable goes stale. Only Helm, Go, k9s and the AWS CLI are still archives,
  and those resolve "latest" at run time.
* **`apt_key` is gone**; keys land in `/etc/apt/keyrings` and are referenced by
  `Signed-By` through `deb822_repository`.
* **`pip install` as root is gone** — PEP 668 forbids it on current distros.
  CLI tools go through `pipx`, libraries into an explicit virtualenv.
* **`include:` → `include_tasks`**, all modules use their FQCN, and `raw:` is
  only used where no module exists.
* **Docker Compose v1 → the `docker-compose-plugin`** (`docker compose`).
* Employer-specific content (private repository clones, the cache warmer, the
  Flood/Element harness, the `sitespeedio` service account) has been removed;
  the Magento analyser configuration survives as templates with the vendor
  namespaces exposed as `devops_php_code_namespaces`.

## License

MIT — see [LICENSE](LICENSE).

## Contact

Open an issue on GitHub, or email code@kingletas.com. Report a security problem privately, as [SECURITY.md](SECURITY.md) describes.
