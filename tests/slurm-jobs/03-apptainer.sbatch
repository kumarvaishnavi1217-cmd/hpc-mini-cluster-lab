#!/bin/bash
#SBATCH --job-name=apptainer
#SBATCH --partition=debug
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:10:00
#SBATCH --output=%x-%j.out
# Runs an OCI image via Apptainer on two nodes; the SIF lives on CephFS /home,
# so it is built once and reused by every node.
set -euo pipefail
SIF="$HOME/containers/python-3.12.sif"
mkdir -p "$(dirname "$SIF")"
[[ -f "$SIF" ]] || apptainer pull "$SIF" docker://python:3.12-slim
srun apptainer exec "$SIF" python3 -c \
  "import platform, socket; print(socket.gethostname(), platform.python_version())"
