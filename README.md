# USI Minio role

Install and Configure Minio S3 Object-Storage.

This role allows you to deploy Minio as single-node, as well as highly available distributed multi-node setup.

It is recommended to deploy a load balancer such as HAProxy when setting up Minio in distributed mode with multiple nodes.

## Requirements

A Debian-based managed node. Package installations utilize APT.

## Dependencies

None

## Use the role

Add a `requirements.yaml` into your playbook repository and add this repository as a role source.

```yaml
roles:
  - name: anro_minio
    src: https://github.com/jmcnab006/anro_minio.git
    version: main
    scm: git
```

Use the role name specified in the `requirements.yaml` to utilize the play in a playbook.

```yaml
- hosts: 
  - minio01 
  - minio02
  - minio03
  - minio04
  roles:
    - role: anro_minio
      vars:
        minio_server_datadirs:
          - /data/disk1
          - /data/disk2
        minio_server_cluster_nodes:
          - http://minio0{1...4}.example.com:9000/data/disk{1...2}
        minio_root_user: usiadmin
        minio_root_password: "{{ vault_minio_password }}"
        minio_server_env_extra:
          - name: MINIO_BROWSER_REDIRECT_URL
            value: "https://minio.example.com"

```

## Role variables

Available variables are listed below, along with default values. See also `defaults/main.yaml`.
##### `minio_server_bin: "/usr/local/bin/minio"`

Sets the binary filename and path for the minio server when downloading the latest release.

##### `minio_client_bin: "/usr/local/bin/mc"`

Sets the binary filename and path for the minio client when downloading the latest release.

##### `minio_server_release: ""`

Sets the server release .deb package to download and install using the [Minio server downloads archive](https://dl.minio.io/server/minio/release/linux-amd64/archive/). Should be a string value (i.e "20250117232550.0.0"). Defaults to empty string to download the most recent binary file and saves it to the `minio_server_bin` path. 

##### `minio_client_release: ""`

Sets the client release .deb package to download and install using the [Minio client downloads archive](https://dl.minio.io/client/mc/release/linux-amd64/archive/). Should be a string value (i.e "20250117232550.0.0"). Defaults to empty string to download the most recent binary file and saves it to the `minio_client_bin` path. Typically these versions should be similar to the server versions.

##### `minio_server_datadirs: ['/var/lib/minio']`

Sets the default data directories for minio installation. As an array each mounted disk path should be added. Drives should be formatted xfs with a drive label and mounted in the fstab using label based mounting. [Minio checklist storage](https://min.io/docs/minio/linux/operations/checklists/hardware.html#storage)


##### `minio_server_cluster_nodes: []`

Sets the cluster definition string (i.e. "https://minio-0{1...5}.example.com:9000/mnt/minio-disk{1...2}"). This string example can be obtained from the [Minio Erasure Code Calculator](https://min.io/product/erasure-code-calculator). Each element is in the array is a [Minio Server Pool](https://blog.min.io/server-pools-streamline-storage-operations/). A Minio cluster can be composed of one or more Server Pools. 

The following example would define a cluster of 3 pools of 5 nodes `minio-01` - `minio-05`, `minio-11` - `minio-15` and `minio-21` - `minio-25` each having 2 disks mounted on `/mnt/minio-disk1` and `/mnt/minio-disk2` :

```yaml
minio_server_cluster_nodes:
  - "https://minio-0{1...5}.example.com:9000/mnt/minio-disk{1...2}"
  - "https://minio-1{1...5}.example.com:9000/mnt/minio-disk{1...2}"
  - "https://minio-2{1...5}.example.com:9000/mnt/minio-disk{1...2}"

```

##### `minio_server_env_extra: []`

Additional environment variables to be set in minio server environment. Environment variables are defined on [Minio Server Environment Variables](https://min.io/docs/minio/linux/reference/minio-server/settings.html)

Examples: 
```yaml
minio_server_env_extra:
  - name: MINIO_BROWSER_REDIRECT_URL
    value: "https://minio.example.com"
  - name: MINIO_STORAGE_CLASS_STANDARD
    value: "EC:3"
  - name: MINIO_PROMETHEUS_URL
    value: "http://prometheus.example.com:9090"
  - name: MINIO_PROMETHEUS_JOB_ID
    value: "minio-job"
  - name: MINIO_PROMETHEUS_AUTH_TYPE
    value: "public"
  - name: MINIO_ERASURE_SET_DRIVE_COUNT 
    value: 4
```

##### `minio_install_server: true`

Enable or disable installing minio server.

##### `minio_install_client: true`

Enable or disable installing minio client.

##### `minio_configure_server: true`

Enable or disable configuring minio server.

##### `minio_root_user: "admin"`

Default admin user for console login. 

##### `minio_root_password: "admin"`

Default admin password for console login. This should be overwritten in the role variables. 

##### `minio_wipe_all_drives: false`

Wipes all data from all data drives specified in `minio_server_datadirs`. Use with **_EXTREME CAUTION THE DATA IS UNRECOVERABLE_**.
