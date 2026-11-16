#!/usr/bin/env bash
# Live migration + HA failover checks. Run on a Proxmox node.
set -euo pipefail
VMID="${1:-201}"          # slurmctl01
TARGET="${2:-pve02}"
echo "== Live-migrating vm $VMID to $TARGET (replicated ZFS disk) =="
start=$(date +%s)
ha-manager migrate "vm:$VMID" "$TARGET"
until ha-manager status | grep -q "vm:$VMID ($TARGET, started)"; do sleep 3; done
echo "migrated in $(( $(date +%s) - start ))s"
echo
echo "HA failover test (manual, destructive): power off the node hosting vm $VMID"
echo "and watch: watch -n2 ha-manager status   (expect relocation within ~2-3 min)"
