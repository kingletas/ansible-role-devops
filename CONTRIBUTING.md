# Contributing

Thanks for looking.

## The gate

```bash
pip install -r requirements-dev.txt
make collections
make check
```

`make check` is everything a commit has to pass. It runs `yamllint`, `ansible-lint` at the production profile, and a syntax check of both example playbooks. CI runs the same command.

If you changed a task, also run the role for real in a container:

```bash
make converge
```

That needs Docker. It converges the role, runs it a second time to prove nothing changes, then checks the installed tools actually run. CI runs it on Ubuntu 24.04, Debian 12 and Rocky Linux 9.

## What a change should look like

- One concern per pull request, with the reasoning in the description.
- `make check` green.
- For a new tool or a changed install, a line in `molecule/default/verify.yml` that fails before your change and passes after it.
- An entry in `CHANGELOG.md` under `## [Unreleased]`, saying what changed for someone using the role rather than what the diff did.
- Comments say what the code does or what it guards against, in a sentence or two. History belongs in the commit message and the changelog.

## Security

Don't open a public issue for a vulnerability. [SECURITY.md](SECURITY.md) has the reporting route.
