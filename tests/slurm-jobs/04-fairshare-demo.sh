#!/bin/bash
# Demonstrates fair-share: submit identical job floods as two users from
# different accounts and watch priorities diverge as usage accrues.
#   run as root on login01
set -euo pipefail
for u in alice bob; do
  for _ in $(seq 1 10); do
    sudo -u "$u" sbatch -p batch -n 4 --time=5 --wrap="sleep 120" >/dev/null
  done
done
sleep 10
echo "== sshare (fair-share factors) =="
sshare -a -o Account,User,RawShares,NormShares,RawUsage,EffectvUsage,FairShare
echo "== sprio (pending job priorities) =="
sprio -l | head -25
