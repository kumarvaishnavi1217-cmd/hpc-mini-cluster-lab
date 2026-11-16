# Validation log

Fill this in from **your own runs** on the lab hardware. Each test links to the script that produces the numbers.

| Date | Test | Command | Result | Notes |
|---|---|---|---|---|
| | Ansible idempotency (2nd run 0 changed) | `make site` twice | | |
| | Multi-node MPI | `sbatch tests/slurm-jobs/01-hello-mpi.sbatch` | | |
| | GPU GRES isolation | `sbatch tests/slurm-jobs/02-gpu-gres.sbatch` | | |
| | Apptainer multi-node | `sbatch tests/slurm-jobs/03-apptainer.sbatch` | | |
| | Fair-share divergence | `tests/slurm-jobs/04-fairshare-demo.sh` | | |
| | Ceph OSD failure: I/O while degraded | `scripts/ceph-osd-failure-drill.sh` | | |
| | Ceph backfill time | same | | |
| | Ceph data integrity after recovery | same | | |
| | PBS restore RTO | `scripts/backup-restore-test.sh 201` | | |
| | Live migration time (slurmctl01) | `scripts/proxmox-ha-test.sh` | | |
| | HA failover (node power-off) | manual | | |
| | RGW S3 round-trip | `scripts/s3-smoke-test.sh` | | |
| | Rolling update, no job killed | `make rolling` during a running job | | |
| | Alert fires on OSD down | Alertmanager UI | | |
