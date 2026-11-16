#include <mpi.h>
#include <stdio.h>

int main(int argc, char **argv) {
    int rank, size, len;
    char host[MPI_MAX_PROCESSOR_NAME];
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Get_processor_name(host, &len);

    /* simple collective so we actually exercise the interconnect */
    long local = rank, total = 0;
    MPI_Allreduce(&local, &total, 1, MPI_LONG, MPI_SUM, MPI_COMM_WORLD);

    printf("rank %d/%d on %s (allreduce sum=%ld, expected=%ld)\n",
           rank, size, host, total, (long)size * (size - 1) / 2);
    MPI_Finalize();
    return 0;
}
