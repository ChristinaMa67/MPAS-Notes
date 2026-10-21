#include <mpi.h>
#include <netcdf.h>
#include <stdio.h>

int main(int argc, char **argv)
{
    int rank, size, total;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Allreduce(&rank, &total, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);
    if (size < 2 || total != size * (size - 1) / 2) {
        fprintf(stderr, "C MPI communication check failed on rank %d\n", rank);
        MPI_Abort(MPI_COMM_WORLD, 1);
        return 1;
    }
    if (rank == 0) {
        printf("PASS: C MPI communication with %d ranks\n", size);
        printf("NetCDF-C runtime: %s\n", nc_inq_libvers());
    }
    MPI_Finalize();
    return 0;
}
