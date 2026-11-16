#!/usr/bin/env bash
# Proxmox Backup Server restore test. Run on a Proxmox node.
#   Restores the latest backup of a VM to a NEW vmid (never overwrites prod),
#   boots it with networking disabled, checks the guest agent answers, then cleans up.
set -euo pipefail
SRC_VMID="${1:?usage: $0 <source-vmid> [test-vmid]}"
TEST_VMID="${2:-9$SRC_VMID}"
STORAGE_PBS="${STORAGE_PBS:-pbs-lab}"
TARGET_STORAGE="${TARGET_STORAGE:-local-zfs}"

latest=$(pvesm list "$STORAGE_PBS" --vmid "$SRC_VMID" | awk 'NR>1{print $1}' | sort | tail -1)
[[ -n "$latest" ]] || { echo "no backup for $SRC_VMID"; exit 1; }
echo "Restoring $latest -> vmid $TEST_VMID"
start=$(date +%s)
qmrestore "$latest" "$TEST_VMID" --storage "$TARGET_STORAGE" --unique 1
for n in $(qm config "$TEST_VMID" | awk -F: '/^net[0-9]+:/{print $1}'); do
  qm set "$TEST_VMID" --"$n" "$(qm config "$TEST_VMID" | awk -F': ' -v k="$n" '$1==k{print $2}'),link_down=1"
done
qm start "$TEST_VMID"
until qm agent "$TEST_VMID" ping 2>/dev/null; do sleep 5; done
echo "PASS: restored VM boots and guest agent responds ($(( $(date +%s) - start ))s RTO)"
qm agent "$TEST_VMID" get-osinfo | jq -r '.["pretty-name"]'
qm stop "$TEST_VMID" && qm destroy "$TEST_VMID" --purge
