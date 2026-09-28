# anro_minio v2

Production-oriented Ansible role for installing MinIO Community Edition and `mc` from **source-built, vendored binaries**. Managed hosts never download MinIO and do not require Go or Internet access.

> **Upstream status:** MinIO Community Edition and `mc` are archived public GitHub projects. Review the AGPLv3 obligations and your organization's support/security requirements before production use. This role does not convert archived software into a supported product.

## Security model

* No default root credentials. Credentials must be supplied explicitly and should come from Ansible Vault or a secret manager.
* Source builds are pinned to immutable 40-character Git commit IDs.
* Managed hosts receive binaries through `ansible.builtin.copy`; runtime downloads are forbidden by design.
* SHA-256 values are generated during the trusted build and enforced by the role.
* MinIO runs as an unprivileged system account.
* The credential-bearing environment file is `0640 root:minio` and templating uses `no_log`.
* TLS private keys are `0600`.
* systemd sandboxing includes `NoNewPrivileges`, `ProtectSystem=strict`, kernel/control-group protections, and explicit writable storage paths.
* Destructive storage wipe requires two independent boolean confirmations.
* Molecule performs functional S3-style create/upload/download/compare/delete verification with `mc`.

## Important: pin the archived source commits

Edit `build/versions.env` and replace both placeholders with **verified full commit IDs** from the official public archives:

```text
anro_minio_COMMIT=<40-character commit>
MC_COMMIT=<40-character commit>
```

Do not use `master`, `latest`, a floating tag, or a shortened hash for release builds. The build fails unless both values are full SHA-1 Git object IDs and verifies the checked-out `HEAD` exactly.

## Build and vendor binaries

Requirements on the build workstation/CI runner:

* Docker with BuildKit
* Python 3
* Internet access to the official GitHub archives during the controlled build

Run:

```bash
make binaries
sha256sum --check SHA256SUMS
```

The build creates:

```text
files/bin/amd64/minio
files/bin/amd64/mc
files/bin/arm64/minio
files/bin/arm64/mc
SHA256SUMS
vars/binary_checksums.yml
```

Commit these artifacts together with the pinned `build/versions.env`. This intentionally makes the role repository itself the deployment artifact. Binary changes therefore require a normal code-review path.

### Why binaries are not built on managed hosts

Compiling on a managed host expands the production attack surface, requires Go/Git/network access, slows convergence, and makes deployments less reproducible. Build once in controlled CI, review checksums/provenance, then deploy offline.

## Use

```yaml
---
- name: Configure MinIO
  hosts: minio
  become: true
  roles:
    - role: anro_minio
      vars:
        anro_minio_root_user: "{{ vault_anro_minio_root_user }}"
        anro_minio_root_password: "{{ vault_anro_minio_root_password }}"
        anro_minio_server_datadirs:
          - /srv/minio/data
```

The role supports `x86_64` and `aarch64` and maps them to the vendored `amd64` and `arm64` binaries.

## TLS

```yaml
anro_minio_tls_enabled: true
anro_minio_tls_cert_src: files/minio.example.com.crt
anro_minio_tls_key_src: files/minio.example.com.key
```

The certificate and key are copied from the Ansible controller. Protect source private keys with appropriate repository/Vault controls.

## Distributed mode

For distributed MinIO, populate `anro_minio_server_cluster_nodes`. The role joins entries into `anro_minio_VOLUMES`. All nodes must use consistent cluster configuration and credentials. Validate your topology against the archived upstream documentation before production deployment.

## Destructive wipe

Data wiping is intentionally difficult to enable:

```yaml
anro_minio_wipe_all_drives: true
anro_minio_wipe_all_drives_confirm: true
```

Both must be true. This removes every path in `anro_minio_server_datadirs`. Never set these values as persistent inventory defaults.

## Molecule / Docker

The default scenario uses a privileged Debian 12 systemd container because this role manages a native systemd service. Docker is a test substrate, not the production deployment model.

Install test dependencies, build the vendored binaries, and run:

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install 'ansible-core==2.17.*' ansible-lint molecule 'molecule-plugins[docker]' docker
ansible-galaxy collection install -r molecule/default/requirements.yml
make binaries
ansible-lint .
molecule test
```

The Molecule sequence includes syntax, converge, **idempotence**, and end-to-end verify.

### End-to-end verify coverage

`molecule/default/verify.yml` verifies:

1. systemd service is enabled and running;
2. installed binaries are executable and SHA-256-identical to vendored artifacts;
3. credential environment file ownership/mode;
4. `/minio/health/ready` returns HTTP 200;
5. systemd sandbox properties are active;
6. `mc` authenticates using an isolated temporary config;
7. bucket creation;
8. object upload;
9. object download;
10. byte-for-byte content validation;
11. object deletion;
12. bucket deletion;
13. cleanup of temporary client credentials.

The test credentials exist only in Molecule inventory. Production defaults remain empty.

## CI

`.github/workflows/test.yml` runs `ansible-lint` and Molecule. `.github/workflows/build-binaries.yml` is manual and builds the pinned sources, validates checksums, and uploads artifacts for review. A recommended release process is:

1. review upstream archived source commit;
2. update the pinned commit;
3. run the binary build workflow;
4. inspect build output and `SHA256SUMS`;
5. commit the four binaries, manifest, generated Ansible checksum file, and pin change in one reviewed commit;
6. run Molecule;
7. tag the role release.

## Validation

```bash
ansible-lint .
ansible-playbook --syntax-check molecule/default/converge.yml
molecule test
```

## License and upstream source

This role's automation code retains the repository's role licensing choice. The vendored MinIO and `mc` binaries are derivative build artifacts of their upstream projects and remain subject to the upstream AGPLv3 license and notices. Preserve upstream license/source availability and obtain legal guidance for your distribution/use case where appropriate.
