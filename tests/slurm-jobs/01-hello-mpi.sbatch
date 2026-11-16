#!/bin/bash
#SBATCH --job-name=hello-mpi
#SBATCH --partition=batch
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=4
#SBATCH --time=00:05:00
#SBATCH --output=%x-%j.out
# Multi-node MPI job across all CPU compute nodes. Launched with srun + PMIx.
set -euo pipefail
module load mpi/openmpi-x86_64
cd "$SLURM_SUBMIT_DIR"
[[ -x hello_mpi ]] || mpicc -O2 -o hello_mpi hello_mpi.c   # submit from tests/slurm-jobs/
srun --mpi=pmix ./hello_mpi
