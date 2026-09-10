# From nothing to a provisioned machine

This guide takes you from a fresh Linux machine to one with Terraform, kubectl and Helm installed, git set up with your name, and a shell that finds all of it. Then it shows you how to turn on the rest of the toolchain.

## Contents

- [What this is](#what-this-is)
- [Before you start](#before-you-start)
- [Step 1: install git and Ansible](#step-1-install-git-and-ansible)
- [Step 2: get the role](#step-2-get-the-role)
- [Step 3: write a playbook](#step-3-write-a-playbook)
- [Step 4: run it](#step-4-run-it)
- [Step 5: check it worked](#step-5-check-it-worked)
- [Step 6: turn on the rest](#step-6-turn-on-the-rest)
- [If something goes wrong](#if-something-goes-wrong)

## What this is

Setting up a new computer for DevOps work means installing the same twenty tools every time, each from its own vendor repository, each with its own signing key. This role does that for you, and does it the same way on every machine.

It's an **Ansible role**. Ansible is a tool that reads a description of how a machine should look ("Terraform is installed", "git knows my name") and changes the machine until it matches. A role is a packaged set of those descriptions. A **playbook** is a short file that says which machine gets which role, with which settings.

Because Ansible describes the end state rather than a list of commands, you can run it again at any time. If nothing needs to change, it changes nothing.

## Before you start

You need:

- A machine running Ubuntu 22.04 or 24.04, Debian 12 or 13, Fedora, or a RHEL 9 derivative such as Rocky Linux.
- An account on it that can use `sudo`.
- An internet connection. The role downloads everything from the vendors' own servers.

Every command and output below was run on a fresh Ubuntu 24.04 container. The Fedora and RHEL commands are marked where they differ, and those weren't run for this guide.

**Want to try it without touching your own computer?** Start a throwaway Ubuntu container, give it a user with `sudo`, and follow the rest of the guide inside it. Everything disappears when you exit.

```bash
docker run --rm -it ubuntu:24.04 bash
```

Then, inside the container:

```bash
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y sudo tzdata
useradd -m -s /bin/bash -G sudo alex
echo 'alex ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/alex
su - alex
```

Installing `tzdata` here stops it asking for a time zone halfway through Step 1. The last line switches you to `alex`, a normal user who can use `sudo` without a password.

## Step 1: install git and Ansible

Install git and pipx from your distribution. pipx installs Python command-line tools into their own private environments, so they can't clash with the system's Python.

```bash
sudo apt-get update
sudo apt-get install -y git pipx
```

On Fedora or RHEL 9, use `sudo dnf install -y git pipx` instead (not run for this guide).

Now install Ansible, and let pipx add its folder to your `PATH`:

```bash
pipx install ansible-core
pipx ensurepath
```

`pipx ensurepath` only changes new shells. Open a new terminal, or start a fresh login shell:

```bash
exec bash -l
```

Check Ansible is there:

```bash
ansible --version
```

```text
ansible [core 2.21.4]
  config file = None
  configured module search path = ['/home/alex/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /home/alex/.local/share/pipx/venvs/ansible-core/lib/python3.12/site-packages/ansible
  ansible collection location = /home/alex/.ansible/collections:/usr/share/ansible/collections
  executable location = /home/alex/.local/bin/ansible
  python version = 3.12.3 (main, Aug 31 2026, 10:18:26) [GCC 13.3.0] (/home/alex/.local/share/pipx/venvs/ansible-core/bin/python)
  jinja version = 3.1.6
  pyyaml version = 6.0.3 (with libyaml v0.2.5)
```

The version must be 2.15 or newer. If the command isn't found, the new shell didn't pick up `~/.local/bin`; open another terminal and try again.

## Step 2: get the role

Clone the repository **into a folder called `devops`**:

```bash
git clone https://github.com/kingletas/ansible-role-devops.git devops
cd devops
```

The folder name matters. Ansible finds a role by the name of its folder, and the playbooks here ask for a role called `devops`. If you clone it under its full name, Ansible reports `The role 'devops' was not found`.

The role uses a few modules from the `community.general` collection. A collection is a bundle of extra Ansible modules; install it from the list in `requirements.yml`:

```bash
ansible-galaxy collection install -r requirements.yml
```

```text
Starting galaxy collection install process
Process install dependency map
Starting collection install process
Downloading https://galaxy.ansible.com/api/v3/plugin/ansible/content/published/collections/artifacts/community-general-13.4.0.tar.gz to /home/alex/.ansible/tmp/ansible-local-3388pyqw42ft/tmp8tl6sq3c/community-general-13.4.0-z873qzty
Installing 'community.general:13.4.0' to '/home/alex/.ansible/collections/ansible_collections/community/general'
community.general:13.4.0 was installed successfully
Downloading https://galaxy.ansible.com/api/v3/plugin/ansible/content/published/collections/artifacts/community-library_inventory_filtering_v1-1.1.5.tar.gz to /home/alex/.ansible/tmp/ansible-local-3388pyqw42ft/tmp8tl6sq3c/community-library_inventory_filtering_v1-1.1.5-9rzaiksb
Installing 'community.library_inventory_filtering_v1:1.1.5' to '/home/alex/.ansible/collections/ansible_collections/community/library_inventory_filtering_v1'
community.library_inventory_filtering_v1:1.1.5 was installed successfully
```

## Step 3: write a playbook

Start small. Create `my-machine.yml` in the `devops` folder, and change the name and email to your own:

```yaml
---
- name: Set up my machine
  hosts: localhost
  connection: local
  become: true

  roles:
    - role: devops
      vars:
        devops_profile: workstation
        devops_git_user_name: Alex Example
        devops_git_user_email: alex@example.com
        devops_components:
          shell: false
          python: false
          ansible: false
          nodejs: false
          docker: false
          cloud: false
        devops_hashicorp_packages:
          terraform: true
```

Here's what each part does:

- `hosts: localhost` and `connection: local` mean "this machine, the one I'm typing on".
- `become: true` lets Ansible use `sudo` for the steps that need it, such as installing packages.
- `devops_profile: workstation` picks the set of tools meant for a personal machine, and configures the account you're logged in as.
- `devops_components` switches individual tools off (or on) on top of that profile. This first run leaves out the shell setup, Python tools, Node.js, Docker and the cloud CLIs, so it finishes in a few minutes.
- `devops_hashicorp_packages` picks which HashiCorp tools to install. Here it's only Terraform.

## Step 4: run it

```bash
ansible-playbook my-machine.yml -K
```

`-K` makes Ansible ask for your `sudo` password before it starts. It calls it the `BECOME password`. If your account doesn't need a password for `sudo`, just press Enter.

Ansible prints each step as it goes. Here's the start and the end of a real run, with the eighty steps in between cut out:

```text
BECOME password:
[WARNING]: No inventory was parsed, only implicit localhost is available
[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'

PLAY [Set up my machine] *******************************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

...

TASK [devops : Grafana] ********************************************************
skipping: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=50   changed=23   unreachable=0    failed=0    skipped=34   rescued=0    ignored=0
```

`failed=0` is what you're looking for. `changed` counts the steps that actually changed something, and `skipped` counts the steps for tools you switched off.

The two warnings at the top are normal. They mean you didn't give Ansible a list of other machines, which is right: you're setting up this one. With ansible-core 2.21 you'll also see a `DEPRECATION WARNING` about `INJECT_FACTS_AS_VARS`. It doesn't stop anything working.

## Step 5: check it worked

The role puts its settings in `~/.config/devops/env.sh` and loads that file from your `~/.bashrc`. Open a new terminal, or start a fresh login shell, so it takes effect:

```bash
exec bash -l
```

Then ask each tool for its version:

```bash
terraform version
kubectl version --client
helm version --short
git config --global user.name
```

```text
Terraform v1.16.2
on linux_amd64
Client Version: v1.37.0
Kustomize Version: v5.8.1
v4.2.4+g3900f43
Alex Example
```

Your version numbers will be newer. The role installs the current release of each tool, so there's no version for you to keep up to date.

Now run the playbook a second time:

```bash
ansible-playbook my-machine.yml -K
```

```text
PLAY RECAP *********************************************************************
localhost                  : ok=43   changed=0    unreachable=0    failed=0    skipped=41   rescued=0    ignored=0
```

`changed=0` means the machine already matched the playbook, so Ansible left it alone. You can run it whenever you like.

## Step 6: turn on the rest

When you're happy with the small run, delete the `devops_components` and `devops_hashicorp_packages` blocks from `my-machine.yml`. The workstation profile then installs everything it's meant to: the shell setup, Python and Ansible tools, Node.js, Docker, Terraform and Packer, kubectl and Helm, and the AWS CLI. Run the playbook again the same way. That full run wasn't done for this guide.

The [README](../README.md) lists every component and every setting, and [`playbooks/workstation.yml`](../playbooks/workstation.yml) is a fuller example to copy from.

To re-run just one tool later, use its tag. This runs only the Kubernetes steps:

```bash
ansible-playbook my-machine.yml -K --tags kubernetes
```

## If something goes wrong

- **`The role 'devops' was not found`**: the repository isn't in a folder called `devops`. Rename the folder, or clone it again as Step 2 shows.
- **`sudo: a password is required`**: you left out `-K`. Add it and run again.
- **`couldn't resolve module/action 'community.general.…'`**: the collection isn't installed. Run the `ansible-galaxy` command from Step 2.
- **A tool isn't found after a successful run**: your shell started before the role ran. Open a new terminal.
