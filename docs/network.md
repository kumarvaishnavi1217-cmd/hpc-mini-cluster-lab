# Network

## Physical, per hypervisor
```
             ┌──────────── managed switch ────────────┐
 eno1 ───────┤ access VLAN 10                         │
 enp1s0f0 ─┐ │ LACP port-channel, trunk 20,30,31,50   │
 enp1s0f1 ─┴─┤ MTU 9216                               │
             └────────────────────────────────────────┘
```
- `vmbr0` is a bridge on `eno1` that carries the management network, untagged.
- `bond0` is 802.3ad (LACP) with `layer3+4` hashing, fast LACP rate and MTU 9000.
- `vmbr1` is a VLAN-aware bridge on `bond0`. VMs get tagged NICs on it.
- `vmbr1.50` is the corosync link. Keeping it on its own VLAN stops Ceph backfill from causing cluster fencing.
- `vmbr1.30` gives each hypervisor an address on the Ceph public network.

## VM NIC mapping (generated in `roles/proxmox_vms`)
| NIC | Bridge / tag | Present on | Purpose |
|---|---|---|---|
| net0 | vmbr0 | all | mgmt (VLAN 10), default gateway |
| net1 | vmbr1 tag 20 | hosts with `compute_ip` | Slurm / MPI |
| net2 | vmbr1 tag 30 | hosts with `ceph_public_ip` | Ceph public / CephFS / S3 |
| net3 | vmbr1 tag 31 | hosts with `ceph_cluster_ip` | Ceph replication |

## Switch configuration (example, Cisco-style)
```
interface Port-channel1
 switchport mode trunk
 switchport trunk allowed vlan 20,30,31,50
 mtu 9216
interface range Gi1/0/1-2
 channel-group 1 mode active
```

## Firewall policy (nftables)
- Input policy is **drop**. Established and related traffic, loopback and ICMP are allowed.
- SSH is allowed from VLAN 10 and the WireGuard subnet only. Login nodes also accept rate-limited SSH from users.
- Each role opens only its own ports, and only from the VLAN that needs them. For example, Ceph OSD replication on ports 6800-7300 is accepted only from 10.10.31.0/24. The full matrix is `nft_rules_by_group` in `roles/nftables/defaults/main.yml`.
- Every ruleset is validated with `nft -c` before it is installed.

## WireGuard
- The hub is `login01` (`wg0`, 10.200.0.1/24, port 51820/udp).
- VPN clients can reach VLAN 10 and VLAN 20 only. That rule lives in the forward chain, with masquerade NAT.
- To add a peer, append to `wireguard_peers` and run `make security`. A client template is in `docs/examples/wg-client.conf.example`.
