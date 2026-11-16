# Runbook: Slurm operations

## Health
```bash
sinfo -N -l                     # node states
scontrol ping                   # controller
sdiag                           # scheduler stats
sshare -a                       # fair-share tree
sprio -l                        # why is my job waiting?
```

## Node lifecycle
```bash
scontrol update nodename=compute02 state=drain reason="disk"   # stop new jobs
scontrol update nodename=compute02 state=resume
```
For fleet-wide patching, use `make rolling`. It works through canary → 50% → the rest, drains each node, waits for its jobs to finish, updates and reboots it, checks it, then resumes it.

## Add a compute node
1. Add the host to `inventories/lab/hosts.yml` under `compute_cpu` with an IP and VMID.
2. Run `make vms` to clone and start it.
3. Run `ansible-playbook playbooks/site.yml --limit computeNN,slurm_controller,slurm_login,monitoring`. This updates `slurm.conf` everywhere, the Prometheus targets and `/etc/hosts`.
4. Run `scontrol reconfigure`. The handler does this automatically.

## Accounts, QoS and users
Add the user to `hpc_users` in `group_vars/all/main.yml`, then run `make slurm`. The role creates the Linux account (same UID on every node, home on CephFS) and the slurmdbd association.

## Common problems
| Symptom | Cause | Fix |
|---|---|---|
| Node `DOWN*`, `Not responding` | slurmd down, or munge clocks/keys differ | `systemctl status slurmd munge`, `chronyc tracking`, `munge -n \| ssh node unmunge` |
| `Invalid account or account/partition combination` | no association | add the user to `hpc_users` and run `make slurm` |
| GPU job pending `(Resources)` | GRES mismatch | `scontrol show node gpu01` and compare with `gres.conf` and `nvidia-smi` |
| `srun: error: ... Connection refused` from login | nftables srun port range | `SrunPortRange` must match `60001-63000` in nftables |
