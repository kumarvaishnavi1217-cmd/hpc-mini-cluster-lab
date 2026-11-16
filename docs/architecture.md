# Architecture

## Design goals
1. **Everything reproducible.** The inventory (`inventories/lab/hosts.yml`) is the single source of truth. VM NICs, cloud-init IPs, `/etc/hosts`, `slurm.conf` node lines, Prometheus targets and firewall rules are all generated from it.
2. **The management plane survives a hypervisor loss.** slurmctld, slurmdbd, the login node and monitoring run as Proxmox HA resources. Their disks are on local ZFS and replicated to the other two nodes every 15 minutes, so the HA manager can restart them elsewhere without shared storage.
3. **Storage is independent of compute.** Ceph runs on dedicated VMs with their own virtual disks. Compute nodes are disposable: you can destroy one, re-clone it and run `make site --limit computeNN`.
4. **Changes are safe to roll out.** Lint, then check/diff, then canary, then the full fleet. Compute patching is drain-aware.

## Components

| Host | Role | Key services |
|---|---|---|
| pve01-03 | Hypervisors | pve-cluster/corosync, pve-ha-crm/lrm, pvesr |
| pbs01 | Backup | Proxmox Backup Server datastore `lab-backups` |
| slurmctl01 | Scheduler | slurmctld, slurmdbd, MariaDB, munge, prometheus-slurm-exporter |
| login01 | User entry | Slurm clients, compilers/OpenMPI/Lmod, Apptainer, WireGuard hub |
| monitor01 | Observability | Prometheus, Alertmanager, Grafana (Podman + systemd) |
| ceph01-03 | Storage | MON×3, MGR×2, OSD×6 (2 per host), MDS×2 (active/standby), RGW×2 |
| compute01-03 | CPU nodes | slurmd, Apptainer, CephFS client |
| gpu01 | GPU node | slurmd with GRES `gpu:rtx4000:1`, NVIDIA open driver, PCI passthrough |

## Slurm design
- **Selection:** `select/cons_tres` with `CR_Core_Memory`. Cores, memory and GPUs are all consumable.
- **Isolation:** cgroup v2 constrains cores, RAM, swap and devices. A job asking for `--gres=gpu:1` cannot see any other GPU.
- **Partitions:** `debug` (default, 30 min, higher PriorityTier), `batch` (2 days), `gpu` (gpu01 only, requires QoS `gpu` or `normal`).
- **Priority:** `priority/multifactor` with `FAIR_TREE`. The weights are fair-share 100000, QoS 10000, age 1000, job size 500, and usage decays with a 7-day half-life.
- **Accounting:** slurmdbd stores data in MariaDB. Enforcement is `associations,limits,qos,safe`, so a user without an association cannot submit. GPU usage is tracked as a TRES (`AccountingStorageTRES=gres/gpu`).
- **Accounts and QoS:** see `roles/slurmdbd/defaults/main.yml` and `hpc_users` in `group_vars/all/main.yml`.

## Ceph design
- Deployed by `cephadm bootstrap` followed by a single declarative service spec (`roles/ceph_cephadm/templates/cluster-spec.yml.j2`).
- Public network: VLAN 30. Cluster (replication) network: VLAN 31. Both run on the 2×10G LACP bond with MTU 9000.
- Pools are replicated with size 3 and min_size 2. The cluster stays writable with one host down.
- **CephFS** is mounted with the kernel client as `/home` on login, controller and compute nodes. Before the first mount, existing local homes are rsynced into CephFS so the `ansible` user's SSH keys survive.
- **RGW** listens on port 7480 and gives jobs S3-compatible object storage for datasets and checkpoints.
- The mgr `prometheus` module exposes metrics on port 9283.

## Monitoring design
- Scrape targets are generated from inventory groups and labelled with `role`.
- Alert groups: `nodes` (down, disk, memory), `slurm` (exporter down, nodes down or drained, queue backlog), `ceph` (HEALTH_ERR/WARN, OSD down).
- Alertmanager sends criticals to a webhook every hour and inhibits warnings for an instance that already has a critical alert.
- Grafana is provisioned from files. The dashboards in `roles/monitoring_stack/files/dashboards/` are version-controlled.
