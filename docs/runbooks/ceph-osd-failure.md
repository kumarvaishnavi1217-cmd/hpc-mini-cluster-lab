# Runbook: Ceph OSD failure

## Symptoms
The `CephOSDDown` alert fires, or `ceph -s` shows `HEALTH_WARN … osds down` / `degraded`.

## Triage
```bash
ceph -s
ceph health detail
ceph osd tree                 # which host and OSD
ceph orch ps --daemon-type osd
```

## Recovery
1. **Transient failure (daemon crashed):** run `ceph orch daemon restart osd.N`.
2. **Disk failed:**
   ```bash
   ceph osd out N                                  # start backfill now instead of waiting 10 min
   ceph orch osd rm N --replace                    # keeps the OSD id for the new disk
   # replace the disk (in the lab: detach and re-add the virtual disk in Proxmox)
   ceph orch device zap <host> /dev/sdX --force    # if the device has old LVM on it
   # the OSD spec (data_devices: all) recreates the OSD automatically
   ```
3. Watch recovery with `watch ceph -s`. Wait until it reports `HEALTH_OK` and all PGs are `active+clean`.

## Planned maintenance (avoid unnecessary backfill)
```bash
ceph osd set noout
# reboot / patch the host
ceph osd unset noout
```

## Drill
`scripts/ceph-osd-failure-drill.sh osd.0` automates the failure, the degraded-I/O check, recovery timing and the checksum check. Log your results in `docs/validation.md`.
