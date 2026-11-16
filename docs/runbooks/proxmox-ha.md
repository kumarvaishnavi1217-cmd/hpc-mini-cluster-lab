# Runbook: Proxmox HA & live migration

## Check state
```bash
pvecm status          # quorum, members
ha-manager status     # resource placement
pvesr status          # replication job health (must be OK for failover)
```

## Planned maintenance on a hypervisor
```bash
ha-manager crm-command node-maintenance enable pve01   # HA VMs migrate away
# patch / reboot pve01
ha-manager crm-command node-maintenance disable pve01
```

## Live migration
`ha-manager migrate vm:201 pve02`. Because the disks are replicated with ZFS, only the delta since the last replication is copied.

## Failover behaviour
If a node is fenced, the HA manager restarts its resources on a surviving node from the latest replica. Data written after the last replication (at most 15 minutes) is lost. That is acceptable for slurmctld because `StateSaveLocation` is checkpointed and running jobs keep going on the compute nodes. If you need RPO=0, move management-plane disks to Ceph RBD.

## Corosync troubleshooting
- Corosync runs on VLAN 50 only. Check it with `corosync-cfgtool -s`.
- If a node lost quorum, never run `pvecm expected 1` while the other nodes are up.
