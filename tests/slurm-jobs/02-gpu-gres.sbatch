#!/bin/bash
#SBATCH --job-name=gpu-gres
#SBATCH --partition=gpu
#SBATCH --qos=gpu
#SBATCH --gres=gpu:rtx4000:1
#SBATCH --cpus-per-task=4
#SBATCH --time=00:05:00
#SBATCH --output=%x-%j.out
# Verifies GRES scheduling + cgroup device isolation: the job must see exactly 1 GPU.
set -euo pipefail
echo "CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES"
nvidia-smi -L
test "$(nvidia-smi -L | wc -l)" -eq 1 && echo "PASS: exactly one GPU visible"
