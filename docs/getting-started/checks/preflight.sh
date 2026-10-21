#!/usr/bin/env bash
# Check a Linux MPI + NetCDF-C/Fortran + PnetCDF + PIO 2 installation.
# Run with bash; this script never installs packages or changes shell settings.
set -euo pipefail

mode=${1:-run}
if [[ $# -gt 1 || ( "$mode" != run && "$mode" != --compile-only ) ]]; then
    printf 'Usage: bash preflight.sh [--compile-only]\n' >&2
    exit 2
fi

: "${NETCDF:?Set NETCDF to the NetCDF-C installation prefix}"
: "${PNETCDF:?Set PNETCDF to the PnetCDF installation prefix}"
: "${PIO:?This check is for external PIO 2; set PIO to its installation prefix}"
mpas_mpicc=${MPICC:-mpicc}
mpas_mpifc=${MPIFC:-mpif90}
mpas_mpiexec=${MPIEXEC:-mpiexec}
mpas_nflag=${MPIEXEC_NFLAG:--n}
mpas_ranks=${MPAS_CHECK_RANKS:-2}
mpas_nc_config=${NC_CONFIG:-$NETCDF/bin/nc-config}
mpas_nf_config=${NF_CONFIG:-${NETCDFF:-$NETCDF}/bin/nf-config}
mpas_pnc_config=$PNETCDF/bin/pnetcdf-config

for tool in "$mpas_mpicc" "$mpas_mpifc" "$mpas_nc_config" "$mpas_nf_config" "$mpas_pnc_config"; do
    command -v "$tool" >/dev/null || { printf 'Missing command: %s\n' "$tool" >&2; exit 1; }
done
if [[ "$mode" == run ]]; then
    command -v "$mpas_mpiexec" >/dev/null
    if [[ ! "$mpas_ranks" =~ ^[0-9]+$ ]] || (( mpas_ranks < 2 )); then
        printf 'MPAS_CHECK_RANKS must be an integer >= 2\n' >&2
        exit 2
    fi
fi

library_dir() {
    local root=$1 name=$2 candidate
    for candidate in "$root/lib" "$root/lib64"; do
        if compgen -G "$candidate/lib$name.a" >/dev/null ||
           compgen -G "$candidate/lib$name.so*" >/dev/null; then
            printf '%s\n' "$candidate"
            return
        fi
    done
    printf 'Cannot find lib%s under %s/lib or %s/lib64\n' "$name" "$root" "$root" >&2
    return 1
}
mpas_pnc_lib=$(library_dir "$PNETCDF" pnetcdf)
mpas_pio_lib=$(library_dir "$PIO" piof)
library_dir "$PIO" pioc >/dev/null
mpas_sources=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
mpas_check_dir=$(mktemp -d "${MPAS_CHECK_ROOT:-${TMPDIR:-/tmp}}/mpas-env.XXXXXX")
printf 'Check directory: %s\n' "$mpas_check_dir"
cd "$mpas_check_dir"

"$mpas_nc_config" --version
"$mpas_nf_config" --version
"$mpas_pnc_config" --version
# Config utilities emit whitespace-separated flags; installation paths must
# not contain whitespace. Extra link flags can be supplied for static stacks.
read -r -a mpas_cflags <<< "$("$mpas_nc_config" --cflags)"
read -r -a mpas_clibs <<< "$("$mpas_nc_config" --libs)"
read -r -a mpas_fflags <<< "$("$mpas_nf_config" --fflags)"
read -r -a mpas_flibs <<< "$("$mpas_nf_config" --flibs)"
read -r -a mpas_extra <<< "${MPAS_CHECK_EXTRA_LIBS:-}"

"$mpas_mpicc" "${mpas_cflags[@]}" "$mpas_sources/mpi_c_check.c" \
    "${mpas_clibs[@]}" "${mpas_extra[@]}" -o mpi_c_check
printf 'PASS: C MPI and NetCDF-C compile/link\n'
"$mpas_mpifc" "${mpas_fflags[@]}" -I"$PNETCDF/include" -I"$PIO/include" \
    "$mpas_sources/io_fortran_check.f90" -L"$mpas_pio_lib" -lpiof -lpioc \
    -L"$mpas_pnc_lib" -lpnetcdf "${mpas_flibs[@]}" "${mpas_clibs[@]}" "${mpas_extra[@]}" \
    -o io_fortran_check
printf 'PASS: Fortran MPI, NetCDF, PnetCDF and PIO 2 compile/link\n'

# Check discovery and prefixes: a found library can still be the wrong library.
for binary in mpi_c_check io_fortran_check; do
    ldd "./$binary" > "$binary.ldd.txt" 2>&1 || true
    if grep -q 'not found' "$binary.ldd.txt"; then
        cat "$binary.ldd.txt"
        printf 'FAIL: unresolved shared libraries for %s\n' "$binary" >&2
        exit 1
    fi
    while read -r name arrow resolved rest; do
        [[ "$arrow" == '=>' && "$resolved" == /* ]] || continue
        expected=
        case "$name" in
            libnetcdf.so*) expected=$NETCDF ;;
            libnetcdff.so*) expected=${NETCDFF:-$NETCDF} ;;
            libpnetcdf.so*) expected=$PNETCDF ;;
            libhdf5*.so*) expected=${HDF5:-} ;;
        esac
        [[ -n "$expected" ]] || continue
        expected=$(readlink -f "$expected")
        resolved=$(readlink -f "$resolved")
        if [[ "$resolved" != "$expected/"* ]]; then
            printf 'FAIL: %s resolves outside its selected prefix\nActual: %s\nExpected prefix: %s\n' \
                "$name" "$resolved" "$expected" >&2
            exit 1
        fi
    done < "$binary.ldd.txt"
done
printf 'PASS: shared libraries found and I/O prefixes match\n'
if [[ "$mode" == --compile-only ]]; then
    printf 'Compile/link checks passed; MPI execution and I/O have NOT been tested.\n'
    exit 0
fi

"$mpas_mpiexec" "$mpas_nflag" "$mpas_ranks" ./mpi_c_check
"$mpas_mpiexec" "$mpas_nflag" "$mpas_ranks" ./io_fortran_check
printf 'PASS: all preflight checks completed; results kept in %s\n' "$mpas_check_dir"
