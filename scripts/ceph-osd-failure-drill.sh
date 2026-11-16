#!/usr/bin/env bash
# Ceph OSD failure & recovery drill. Run on a Ceph admin node (ceph01).
#   1. write test data   2. stop one OSD   3. confirm I/O continues (size=3,min_size=2)
#   4. mark it out -> watch backfill  5. bring it back -> HEALTH_OK  6. verify checksums
set -euo pipefail
OSD="${1:-osd.0}"
POOL="${POOL:-rbd}"
log(){ printf '\n[%s] %s\n' "$(date +%T)" "$*"; }

log "Baseline"; ceph -s
log "Writing 200 test objects to pool $POOL"
tmp=$(mktemp -d)
for i in $(seq 1 200); do head -c 1M /dev/urandom > "$tmp/obj$i"; rados -p "$POOL" put "drill-$i" "$tmp/obj$i"; done
(cd "$tmp" && sha256sum obj* > sums)

host=$(ceph osd find "${OSD#osd.}" -f json | jq -r .host)
log "Stopping $OSD on $host"
ceph orch daemon stop "$OSD"
sleep 15; ceph -s

log "I/O while degraded (must succeed)"
rados -p "$POOL" put drill-degraded "$tmp/obj1" && echo "write OK while degraded"

log "Marking $OSD out to trigger backfill"
ceph osd out "${OSD#osd.}"
start=$(date +%s)
until ceph health | grep -qE 'HEALTH_OK|HEALTH_WARN.*noout' && ! ceph pg stat | grep -qE 'degraded|backfill|recover'; do
  ceph pg stat; sleep 10
done
log "Recovered in $(( $(date +%s) - start ))s"

log "Restoring $OSD"
ceph orch daemon start "$OSD"
ceph osd in "${OSD#osd.}"
until ceph health | grep -q HEALTH_OK; do sleep 10; done

log "Verifying data integrity"
for i in $(seq 1 200); do rados -p "$POOL" get "drill-$i" "$tmp/obj$i"; done
(cd "$tmp" && sha256sum -c --quiet sums) && echo "PASS: all checksums match"

rados -p "$POOL" ls | grep '^drill-' | xargs -r -n1 rados -p "$POOL" rm
rm -rf "$tmp"
ceph -s
