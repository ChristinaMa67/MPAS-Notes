program io_fortran_check
  use mpi
  use netcdf, only: nf90_create, nf90_def_dim, nf90_def_var, nf90_enddef, &
       nf90_put_var, nf90_close, nf90_open, nf90_inq_varid, nf90_get_var, &
       NF90_CLOBBER, NF90_NOWRITE, NF90_INT
  use pnetcdf, only: nf90mpi_create, nf90mpi_def_dim, nf90mpi_def_var, &
       nf90mpi_enddef, nf90mpi_put_var_all, nf90mpi_close, nf90mpi_open, &
       nf90mpi_inq_varid, nf90mpi_get_var_all
  use pio, only: iosystem_desc_t, PIO_init, PIO_finalize, PIO_rearr_subset
  implicit none
  integer :: ierr, rank, nprocs, total, ncid, dimid, varid
  integer :: written(1), received(1)
  integer(kind=MPI_OFFSET_KIND) :: starts(1), counts(1)
  type(iosystem_desc_t) :: iosystem

  call MPI_Init(ierr)
  call check(ierr, 'MPI_Init')
  call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
  call check(ierr, 'MPI_Comm_rank')
  call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
  call check(ierr, 'MPI_Comm_size')
  call MPI_Allreduce(rank, total, 1, MPI_INTEGER, MPI_SUM, MPI_COMM_WORLD, ierr)
  call check(ierr, 'MPI_Allreduce')
  if (nprocs < 2 .or. total /= nprocs * (nprocs - 1) / 2) then
    call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
    stop 1
  end if
  if (rank == 0) print *, 'PASS: Fortran MPI communication'

  ! Check the serial NetCDF-Fortran API and a file write/read round trip.
  if (rank == 0) then
    call check(nf90_create('serial.nc', NF90_CLOBBER, ncid), 'NetCDF create')
    call check(nf90_def_dim(ncid, 'sample', 1, dimid), 'NetCDF dimension')
    call check(nf90_def_var(ncid, 'value', NF90_INT, (/dimid/), varid), 'NetCDF variable')
    call check(nf90_enddef(ncid), 'NetCDF enddef')
    written = 42
    call check(nf90_put_var(ncid, varid, written), 'NetCDF write')
    call check(nf90_close(ncid), 'NetCDF close after write')
    call check(nf90_open('serial.nc', NF90_NOWRITE, ncid), 'NetCDF reopen')
    call check(nf90_inq_varid(ncid, 'value', varid), 'NetCDF variable lookup')
    received = -1
    call check(nf90_get_var(ncid, varid, received), 'NetCDF read')
    call check(nf90_close(ncid), 'NetCDF close after read')
    if (any(received /= written)) then
      call MPI_Abort(MPI_COMM_WORLD, 2, ierr)
      stop 2
    end if
    print *, 'PASS: NetCDF-Fortran file write/read'
  end if
  call MPI_Barrier(MPI_COMM_WORLD, ierr)
  call check(ierr, 'MPI_Barrier')

  ! Every rank writes and reads one element of a shared classic NetCDF file.
  call check(nf90mpi_create(MPI_COMM_WORLD, 'parallel.nc', NF90_CLOBBER, &
       MPI_INFO_NULL, ncid), 'PnetCDF create')
  call check(nf90mpi_def_dim(ncid, 'rank', int(nprocs, MPI_OFFSET_KIND), dimid), 'PnetCDF dimension')
  call check(nf90mpi_def_var(ncid, 'value', NF90_INT, (/dimid/), varid), 'PnetCDF variable')
  call check(nf90mpi_enddef(ncid), 'PnetCDF enddef')
  starts = int(rank + 1, MPI_OFFSET_KIND)
  counts = 1_MPI_OFFSET_KIND
  written = rank
  call check(nf90mpi_put_var_all(ncid, varid, written, starts, counts), 'PnetCDF collective write')
  call check(nf90mpi_close(ncid), 'PnetCDF close after write')
  call check(nf90mpi_open(MPI_COMM_WORLD, 'parallel.nc', NF90_NOWRITE, &
       MPI_INFO_NULL, ncid), 'PnetCDF reopen')
  call check(nf90mpi_inq_varid(ncid, 'value', varid), 'PnetCDF variable lookup')
  received = -1
  call check(nf90mpi_get_var_all(ncid, varid, received, starts, counts), 'PnetCDF collective read')
  call check(nf90mpi_close(ncid), 'PnetCDF close after read')
  if (any(received /= written)) then
    call MPI_Abort(MPI_COMM_WORLD, 3, ierr)
    stop 3
  end if
  if (rank == 0) print *, 'PASS: PnetCDF collective file write/read'

  ! Exercise the PIO 2 Fortran interface, its initialization and finalization.
  call PIO_init(rank, MPI_COMM_WORLD, 1, 0, 1, PIO_rearr_subset, iosystem)
  call PIO_finalize(iosystem, ierr)
  call check(ierr, 'PIO_finalize')
  if (rank == 0) print *, 'PASS: PIO 2 initialization/finalization'
  call MPI_Finalize(ierr)
  if (ierr /= MPI_SUCCESS) stop 4

contains
  subroutine check(status, operation)
    integer, intent(in) :: status
    character(len=*), intent(in) :: operation
    integer :: abort_status
    if (status /= 0) then
      print *, 'FAIL: ', operation, ' status=', status
      call MPI_Abort(MPI_COMM_WORLD, 5, abort_status)
      stop 5
    end if
  end subroutine check
end program io_fortran_check
