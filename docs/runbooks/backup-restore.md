# Runbook: backup & restore (Proxmox Backup Server)

## What is backed up
The `lab-nightly` cluster backup job (created by `roles/proxmox_cluster`) backs up **all VMs** at 02:00 in snapshot mode to the `pbs-lab` datastore, keeping 7 daily and 4 weekly backups. PBS deduplicates them and can verify them on a schedule. Enable a verify job in the PBS UI.

Ceph data (CephFS `/home`, RGW buckets) is **not** covered by VM backups of the Ceph nodes. Protect it separately:
- CephFS: `ceph fs snap-schedule add / 1d` with retention `ceph fs snap-schedule retention add / d 7`
- RGW: bucket versioning, or `rclone sync` to an external S3 target

## Restore a VM
```bash
pvesm list pbs-lab --vmid 201                        # choose a snapshot
qmrestore pbs-lab:backup/vm/201/<timestamp> 201 --force --storage local-zfs
```
For a non-destructive test, restore to a new VMID: `scripts/backup-restore-test.sh 201`.

## Restore slurmdbd data only
```bash
# on slurmctl01 (keep a logical dump as well as the VM backup)
mysqldump --single-transaction slurm_acct_db > /root/slurm_acct_db.sql
systemctl stop slurmdbd && mysql slurm_acct_db < /root/slurm_acct_db.sql && systemctl start slurmdbd
```

## Restore a file from CephFS snapshots
```bash
ls /home/.snap/
cp -a /home/.snap/scheduled-<date>/alice/project ~alice/project.restored
```
