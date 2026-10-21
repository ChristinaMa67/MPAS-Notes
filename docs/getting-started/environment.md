# Environment

本页整理 MPAS 环境文件中需要配置的内容：每项有什么用、值从哪里来、应该怎样填写。
正文以 bashrc 设置需要的内容为主，具体一些操作上的细节包括查找编译器、识别 MPI、准备依赖和验证环境的步骤放在 Appendix方便查阅～

示例适用于 Linux、GNU Make，以及基于 MPAS-A v8.2.2 修改的 HKUST-MPAS（MPAS-Urban），
采用外部 PIO 2。其他版本和 I/O 方式需要按实际源码调整，暂未验证其适配情况。

```{contents} On This Page
:local:
:depth: 2
```

(env-bashrc)=
## Bashrc Setup

这里的“bashrc 配置”是保存已经确认有效的加载命令和安装路径。
本页将模型配置单独保存为 `~/.bashrc_mpas`；也可以采用其他文件名，之后source相应文件即可。

尚不知道机器上有什么软件，先查 {ref}`env-appendix-compilers` 和 {ref}`env-appendix-mpi`；
不知道依赖装在哪里，先查 {ref}`env-appendix-dependencies`。
填写时，每个命令和路径都应该能对应到实际的软件安装。

(env-initialization)=
### Compiler and MPI Initialization

**用途：**让当前终端能找到所选的编译器和 MPI，并加载它们需要的环境。

将自己已经确认有效的加载命令写在环境文件最前面：

| Installation method | What to put in bashrc |
| --- | --- |
| 集群 module | 实际使用的 `module load` 命令及模块名称 |
| 厂商提供初始化脚本 | `source` 加该安装脚本的实际路径 |

例如，本机已有 Intel 安装提供的脚本：

```bash
source /usr/local/intel-oneapi/setvars.sh
```

`setvars.sh` 随 Intel 安装提供；`~/.bashrc_mpas` 则由用户编写，里面保存加载该脚本的命令。

(env-compiler-vars)=
### Compiler Variables

**用途：**给采用这些变量的依赖构建程序或配套脚本指定编译命令。

先确定工具链，再填写命令名。

| Variable | Purpose | Intel Classic example | When to set it |
| --- | --- | --- | --- |
| `CC` | C 编译器 | `icc` | 构建过程读取此变量时 |
| `CXX` | C++ 编译器 | `icpc` | 构建过程需要 C++ 时 |
| `FC` | Fortran 编译器 | `ifort` | 构建过程读取此变量时 |
| `F77`、`F90` | 部分配置程序使用的 Fortran 编译器变量 | `ifort` | 相应依赖需要时 |
| `I_MPI_CC`、`I_MPI_CXX`、`I_MPI_FC`、`I_MPI_F90` | 选择 Intel MPI 包装命令调用的编译器 | `icc`、`icpc`、`ifort` | 使用支持这些选项的 Intel MPI 时 |
| `MPICC`、`MPIFC`、`MPIEXEC` | 指定本页检查脚本使用的 MPI 命令 | `mpicc`、`mpif90`、`mpiexec` | 需要明确指定检查脚本命令时 |
| `MPAS_BUILD_TARGET` | 保存以后要在 make 命令中填写的配置名 | `ifort` | 可选的便利变量 |

这些变量并非全部都是 MPAS 的必需环境变量。
例如 `MPAS_BUILD_TARGET` 只是本页采用的便利名称，需要在构建命令中显式引用才有作用。
MPAS 自身采用的编译配置在 [Installation](installation.md) 中指定。

(env-dependency-paths)=
### Dependency Installation Paths

本节采用**所有依赖共用一个安装前缀**的方式，
按“下载 → 解压源码 → 编译安装 → 检查关键文件 → 填写 bashrc”的顺序整理。
下面假定编译器和 MPI 已按前节加载；详细查询方法见 Appendix A/B。

export MPAS_STACK="/pathway/mpas-lib/"

可以规定一下路径，然后把这些下载的dependency放在同一个 `lib/`，头文件和 Fortran 模块安装到`include/`，工具安装到 `bin/`。

**这里展示的是从头安装的统一布局。**目录名称可以自己选择；

(env-dependency-downloads)=
#### Step 1: Download and Extract the Sources

下面列出各依赖的用途和官方下载链接。

| Dependency | Purpose in this setup | Official source download | Installation directory used below |
| --- | --- | --- | --- |
| zlib | 压缩支持 | [zlib downloads](https://zlib.net/) | `$MPAS_STACK` |
| HDF5 | NetCDF-4 的存储支持；本例包含高层接口 | [HDF5 releases](https://github.com/HDFGroup/hdf5/releases) | `$MPAS_STACK` |
| NetCDF-C | NetCDF C 接口与基础库 | [NetCDF-C downloads](https://downloads.unidata.ucar.edu/netcdf-c/) | `$MPAS_STACK` |
| NetCDF-Fortran | NetCDF Fortran 接口 | [NetCDF-Fortran downloads](https://downloads.unidata.ucar.edu/netcdf-fortran/) | `$MPAS_STACK` |
| PnetCDF | 基于 MPI-IO 的经典 NetCDF 并行读写 | [PnetCDF downloads](https://parallel-netcdf.github.io/wiki/Download.html) | `$MPAS_STACK` |
| ParallelIO / PIO 2 | 组织计算进程与 I/O 进程之间的数据读写 | [NCAR ParallelIO releases](https://github.com/NCAR/ParallelIO/releases) | `$MPAS_STACK` |

MPI 的下载与加载方法在 Appendix B。上表采用外部 PIO 2 路径；
选择其他 I/O 后端时，先查 Appendix C 中的要求。

各依赖的 `tar`、配置、编译及安装命令集中放在 {ref}`env-appendix-dependencies`。

(env-dependency-install)=
#### Step 2: Build and Install the Libraries

本例的依赖顺序是：

```text
已加载的 C / C++ / Fortran 编译器和 MPI
    ├── zlib → HDF5 → NetCDF-C → NetCDF-Fortran
    └── PnetCDF
                 ↓
        两条分支准备好后构建 PIO 2
```

**所有依赖都指定同一个安装前缀 `$MPAS_STACK`，不再添加 `/zlib`、`/netcdf` 等子目录。**
使用 configure 的软件，在各自配置命令中指定 `--prefix="$MPAS_STACK"`；
使用 CMake 的软件，指定 `-DCMAKE_INSTALL_PREFIX="$MPAS_STACK"`。
其他编译选项仍按各软件的构建说明填写。

后构建的依赖需要通过搜索路径找到先前安装的库；
相关设置和各依赖的具体命令见 {ref}`env-appendix-dependencies`。
确认安装及检查结果后，再把最终路径保存到 bashrc。

(env-dependency-files)=
#### Step 3: Check the Installed Directory and Key Files

**按上述共用前缀完成安装后**，`$MPAS_STACK` 下会形成类似下面的结构。
这里仅列用于定位头文件、Fortran 接口、链接库和配置工具的关键文件，不是完整安装清单。

下面大多数库以共享库 `.so` 为例，PIO 2 以本机安装的静态库 `.a` 为例。
实际安装也可能采用另一种形式；`.so` 与 `.a` 不要求同时存在。
有些安装使用 `lib64/`，应按实际目录处理。

```text
$HOME/software/mpas/intel-classic-intelmpi/
├── bin/
│   ├── nc-config
│   ├── nf-config
│   └── pnetcdf-config
├── include/
│   ├── zlib.h
│   ├── zconf.h
│   ├── hdf5.h
│   ├── netcdf.h
│   ├── netcdf.mod
│   ├── pnetcdf.h
│   ├── pnetcdf.mod
│   └── pio.mod
└── lib/
    ├── libz.so
    ├── libhdf5.so
    ├── libhdf5_hl.so
    ├── libnetcdf.so
    ├── libnetcdff.so
    ├── libpnetcdf.so
    ├── libpioc.a
    └── libpiof.a
```
实际编译、链接和运行仍按 Appendix D 验证。

(env-dependency-bashrc)=
#### Step 4: Put the Installation Prefixes in Bashrc

按照本节的共用前缀安装后，bashrc 中的依赖路径统一写为：

```bash
export MPAS_STACK="/pathway/mpas-lib/"
export ZLIB="$MPAS_STACK"
export HDF5="$MPAS_STACK"
export NETCDF="$MPAS_STACK"
export PNETCDF="$MPAS_STACK"
export PIO="$MPAS_STACK"
```

这些变量的值相同，因为各依赖的文件位于同一个安装前缀下。

变量指向树中的**共用安装前缀**，不指向 `lib/`、`include/` 或源码目录。

| Bashrc setting | Important files found beneath it |
| --- | --- |
| `NETCDF="$MPAS_STACK"` | `include/netcdf.h`、`include/netcdf.mod`、`lib/libnetcdf.*`、`lib/libnetcdff.*` |
| `PNETCDF="$MPAS_STACK"` | `include/pnetcdf.mod`、`lib/libpnetcdf.*` |
| `PIO="$MPAS_STACK"` | `include/pio.mod`、`lib/libpioc.*`、`lib/libpiof.*` |

本例 NetCDF-C 与 NetCDF-Fortran 也共用此前缀，无需另外设置 `NETCDFF`。

接着把对应的 `bin/` 加入 `PATH`，
把实际的 `lib/` 或 `lib64/` 加入 `LD_LIBRARY_PATH`；
包括编译器/MPI 初始化在内的完整写法见 {ref}`env-bashrc-example`。

(env-search-paths)=
### Executable and Library Search Paths

| Variable | Purpose | Where its entries come from |
| --- | --- | --- |
| `PATH` | 查找编译器、MPI 和配置工具等命令 | 软件初始化命令，以及相关安装前缀下的 `bin/` |
| `LD_LIBRARY_PATH` | Linux 运行时查找共享库 | 所选依赖实际使用的 `lib/`、`lib64/`；也可由正确的 RPATH 或系统配置解决 |
| `CMAKE_PREFIX_PATH` | 帮助 CMake 查找依赖 | 相应库的安装前缀；需要时设置 |
| `CPPFLAGS`、`LDFLAGS` | 部分依赖配置时使用的头文件和链接参数 | 对应依赖的构建说明；按具体构建设置 |

顺序会影响实际找到哪一套工具和库。下面的写法把所选目录放在原有搜索路径前面，
让它们优先被找到，同时保留原来的路径。

(env-bashrc-example)=
### Complete Bashrc Example

以下是一份 **Intel Classic + Intel MPI + 外部 PIO 2** 的环境文件示例。
它展示各项设置如何放在一起，不会安装软件。

填写前，替换两类内容：

1. **初始化命令**：确认 Intel 脚本的实际路径；使用 module 时，以已验证的 module 加载命令替换。
2. **依赖路径**：把 `MPAS_STACK` 改成安装时选用的共用前缀。
   以下写法适用于所有依赖共用一个安装目录；分散安装时，库变量和搜索路径都需填写各自的位置。

```bash
# ~/.bashrc_mpas
# Intel Classic + Intel MPI example. Confirm this vendor script in Appendix A/B.
source /usr/local/intel-oneapi/setvars.sh

export CC=icc
export CXX=icpc
export FC=ifort
export F77=ifort
export F90=ifort
export I_MPI_CC=icc
export I_MPI_CXX=icpc
export I_MPI_FC=ifort
export I_MPI_F90=ifort

export MPICC=mpicc
export MPIFC=mpif90
export MPIEXEC=mpiexec
# Convenience variable for an explicit make "$MPAS_BUILD_TARGET" command.
export MPAS_BUILD_TARGET=ifort

# Replace this prefix with the location chosen when installing the libraries.
export MPAS_STACK="/pathway/mpas-lib/"
export ZLIB="$MPAS_STACK"
export HDF5="$MPAS_STACK"
export NETCDF="$MPAS_STACK"
export PNETCDF="$MPAS_STACK"
export PIO="$MPAS_STACK"

# 让终端找到 nc-config、nf-config 等工具。
export PATH="$MPAS_STACK/bin:$PATH"

# 让程序运行时找到 libnetcdf.so 等共享库。
export LD_LIBRARY_PATH="$MPAS_STACK/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# 让 CMake 从这个安装目录中查找头文件和库。
export CMAKE_PREFIX_PATH="$MPAS_STACK${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
```

`export` 将变量传给随后启动的编译工具和程序。路径之间用 `:` 分隔，
上面的写法把新路径放在前面、原有路径保留在后面。
`${变量名:+:$变量名}` 表示“原变量有内容时，再追加冒号和原内容”，避免产生空路径项。

这里假设库文件位于 `lib/`；如果实际装在 `lib64/`，把对应路径改为 `lib64/`。
如果两处都有需要的库，就将两处都加入 `LD_LIBRARY_PATH`，用冒号隔开。
重复加载会重复添加路径，因此修改后可在新终端中加载。

示例中的 `MPAS_STACK` 应替换为自己的实际安装目录。
GNU 或其他编译器环境应填写相应的命令名，并去掉不适用的 Intel MPI 专用设置。

(env-load)=
### Load the Environment

将填写好的内容保存为 `~/.bashrc_mpas`。如果还没有这个文件，可以用编辑器创建：

```bash
nano ~/.bashrc_mpas
```

保存后，在当前终端执行：

```bash
source ~/.bashrc_mpas
```

`source` 会在当前 shell 中执行文件里的命令，使其设置生效。
它不会自动生成文件内容，也不会安装文件中提到的软件。
如果采用其他文件名，就加载那个文件。

可在已有的 `~/.bashrc` 中增加一个便利别名：

```bash
alias mpasenv='source "$HOME/.bashrc_mpas"'
```

新终端中执行 `mpasenv` 即可加载。
计算作业脚本也应按集群要求显式加载同一套环境。

修改配置后，在新终端重新加载，并按 {ref}`env-appendix-checks` 检查。
保存和加载成功，只说明文件可以执行；确认可以开始构建模型，还要看最终检查结果。

(env-appendix)=
## Appendix

正文解释 bashrc 中如何填写；下面提供获取这些值所需的查询、准备和验证步骤。

(env-appendix-compilers)=
### A. Find Available Compilers

这里从尚未创建自定义 bashrc 的情况开始：先查询已有软件，加载或安装后再确认版本。
下面的操作结果用于填写正文中的初始化命令和编译器变量。

#### Discover Available Software

先在终端里查询，不需要预先创建任何 MPAS 环境文件：

```bash
# GNU compiler commands
command -v gcc g++ gfortran

# Intel oneAPI compiler commands
command -v icx icpx ifx

# Intel Classic compiler commands
command -v icc icpc ifort
```

`command -v` 的用途是查找“当前终端能找到的程序”，不是安装或运行编译。

- 打印路径：这个命令当前可以找到，例如 `/usr/bin/gfortran`。
- 某个名字没有打印路径：当前终端找不到它。
- 找不到不一定表示机器没安装，也可能需要先加载软件。
- 不需要让上面所有名字都存在；后面只选择其中一套配套软件。

还可以检查集群是否提供软件模块系统：

```bash
type module
```

如果能找到 `module`，继续查看：

```bash
module avail
```

它列出管理员提供的可加载软件模块。查找编译器和 MPI 的名字，
例如 GCC/Intel、Open MPI/MPICH/Intel MPI；模块的准确名称和配套关系以本集群说明为准。

#### Load or Install the Software

根据上面的查询结果，选择下面的一种情况处理。

| Situation | Next action | What counts as success |
| --- | --- | --- |
| 所需编译器和 MPI 已能找到 | 查看版本并记录 | 命令能运行，并能识别所属软件 |
| 集群提供相应模块 | 按集群文档用 `module load` 加载配套模块 | 加载后相关命令可以找到 |
| 软件已经安装，但通过厂商脚本初始化 | 加载该安装提供的初始化脚本 | 加载后相关命令可以找到 |
| 确认没有所需软件 | 先通过管理员、系统包管理器或官方安装方式准备软件 | 安装并加载后，相关命令可用 |

`module load` 后面填写 `module avail` 中实际列出的模块名，不能凭空猜版本。
`module` 找不到时，可以查看集群的软件说明或询问管理员安装位置；不需要自己杜撰一个初始化文件。
参见 [Environment Modules documentation](https://modules.readthedocs.io/en/latest/module.html)。

例如，**本机已经安装 Intel 软件，并存在厂商提供的初始化脚本**：

```bash
ls -l /usr/local/intel-oneapi/setvars.sh
```

确认这个文件存在、且要使用这套 Intel 安装后，可以执行：

```bash
source /usr/local/intel-oneapi/setvars.sh
```

这里的 `setvars.sh` 是 Intel 安装提供的脚本，内容由安装决定；
它与用户自己编写的 `~/.bashrc` 是两回事。这条路径是本机实例，其他机器必须使用自己的安装位置。

如果确实需要从零安装，官方入口如下：

| Software | Official installation source |
| --- | --- |
| GNU C/C++/Fortran | [GCC installation guide](https://gcc.gnu.org/install/)；系统包管理器通常将 Fortran 作为独立包提供 |
| Intel Fortran and C/C++ | [Intel compiler downloads](https://www.intel.com/content/www/us/en/developer/tools/oneapi/fortran-compiler.html)；确认安装包含所需语言编译器 |

共享集群优先采用管理员提供的组合。具体安装命令取决于系统、权限和软件版本；
确认编译器后，再按 Appendix B 准备配套 MPI。

#### Identify the Compiler Family

现在根据找到或加载的程序，查看对应的一组版本命令：

| Available commands | Version commands | Compiler family |
| --- | --- | --- |
| `gcc`、`g++`、`gfortran` | `gcc --version`、`g++ --version`、`gfortran --version` | GNU |
| `icc`、`icpc`、`ifort` | `icc --version`、`icpc --version`、`ifort --version` | Intel Classic |
| `icx`、`icpx`、`ifx` | `icx --version`、`icpx --version`、`ifx --version` | Intel oneAPI LLVM |

只执行自己找到并准备使用的那一组。本页按实际可用的工具链选择，具体 MPAS 配置以对应版本源码为准。

例如，命令输出中出现 `ifort (IFORT) 2021.7.1`，才据此记录“Intel Classic Fortran 2021.7.1”。
**不是先假定使用 Intel，再要求所有输出都变成 Intel。**
如果安装了多套编译器，选择一套用于这次 MPAS 和依赖构建，并记录它的实际路径及版本。

(env-appendix-mpi)=
### B. Identify and Check MPI

先准备好 Appendix A 中选择的编译器，再加载或安装与之配套的 MPI。
MPI 安装需要包含模型及依赖使用的 Fortran 接口。

| MPI implementation | Official source |
| --- | --- |
| Open MPI | [Downloads](https://www.open-mpi.org/software/ompi/)、[installation guide](https://docs.open-mpi.org/en/v5.0.x/installing-open-mpi/quickstart.html) |
| MPICH | [Downloads](https://www.mpich.org/downloads/) |
| Intel MPI | [Intel MPI Library](https://www.intel.com/content/www/us/en/developer/tools/oneapi/mpi-library.html) |

#### Check MPI and Its Compilers

执行：

```bash
command -v mpicc mpicxx mpifort mpif90 mpiexec
mpiexec --version
```

MPI 的版本输出用于判断实现及版本；命令路径用于确认加载了哪套安装。
`mpifort` 与 `mpif90` 不要求在所有环境中同时存在，所选 MPAS 构建配置实际用到的名字必须可用。

然后检查 MPI 调用哪个编译器：

| MPI implementation identified above | Commands to inspect its compilers |
| --- | --- |
| Open MPI | `mpicc --showme:command`、`mpicxx --showme:command`、`mpifort --showme:command` |
| MPICH / Intel MPI | `mpicc -show`、`mpicxx -show`、`mpifort -show`（包装命令叫 `mpif90` 时用 `mpif90 -show`） |

这些输出可能很长。当前只看它显示要调用的编译器命令，其余参数可以先不逐项分析。

**通过标准是：MPI 调用的编译器与 Appendix A 中选择的那套一致。**

| Chosen compiler family | Expected C / C++ / Fortran compiler behind MPI |
| --- | --- |
| GNU | `gcc` / `g++` / `gfortran` |
| Intel Classic | `icc` / `icpc` / `ifort` |
| Intel oneAPI LLVM | `icx` / `icpx` / `ifx` |

如果不一致，先核对加载的模块或安装，使用配套的 MPI。
只有确认使用 **Intel MPI** 时，才按该安装支持的方式设置 `I_MPI_CC` 等选择变量；
不能把这些变量当成对所有 MPI 通用的修复方式。
参见 [Intel MPI compiler selection](https://www.intel.com/content/www/us/en/docs/mpi-library/developer-reference-linux/2021-16/compilation-environment-variables.html)。

#### Record the Toolchain

根据上述实际检查结果填写：

```text
Compiler loading command:
C compiler path and version:
C++ compiler path and version:
Fortran compiler path and version:
MPI loading command:
MPI implementation and version:
MPI command paths:
Compilers selected by MPI:
MPAS build target:
```

build target 是后面 `make` 后面填写的配置名称。
例如，本地 HKUST-MPAS 的 GNU 配置可选 `gnu`/`gfortran`，Intel Classic 配置可选 `ifort`。
这一步按确认的工具链选择，无需先编辑 Makefile 内部变量。

将加载命令和编译器选择填回正文；再按 Appendix C 准备依赖，记录它们的安装前缀。
这些实际信息就是自己编写 bashrc 的依据。

> 不过这种最好最好还是交给codex来做吧

(env-appendix-dependencies)=
### C. Prepare the Dependencies

本节只集中列出下载后的构建命令，所有依赖共用 `$MPAS_STACK`。
用途和下载链接见 {ref}`env-dependency-downloads`，安装后的关键文件见 {ref}`env-dependency-files`。
下面是源码构建模板；`<version>`、压缩包后缀和解压出的目录名需替换为实际值。
HDF5 的 configure 示例针对 1.10.x；PIO 示例针对 2.5.4。

#### Before Building

先加载选定的编译器和 MPI，并设置对应的 `CC`、`CXX`、`FC`；
`mpicc`、`mpicxx`、`mpif90` 必须来自这套 MPI。
在同一个终端中设置工作目录和搜索路径，然后按下列顺序构建：

```bash
export MPAS_DEPS_ROOT="$HOME/software/mpas"
export MPAS_STACK="$MPAS_DEPS_ROOT/intel-classic-intelmpi"
mkdir -p "$MPAS_DEPS_ROOT/src" "$MPAS_DEPS_ROOT/build" "$MPAS_STACK"

export PATH="$MPAS_STACK/bin:$PATH"
export CPPFLAGS="-I$MPAS_STACK/include"
export LDFLAGS="-L$MPAS_STACK/lib -L$MPAS_STACK/lib64"
export LD_LIBRARY_PATH="$MPAS_STACK/lib:$MPAS_STACK/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CMAKE_PREFIX_PATH="$MPAS_STACK${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
export PKG_CONFIG_PATH="$MPAS_STACK/lib/pkgconfig:$MPAS_STACK/lib64/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
```

压缩包预先放在 `$MPAS_DEPS_ROOT/downloads/`。
每一步成功后再执行下一步；测试如需启动 MPI，在允许运行 MPI 作业的环境中执行。

#### zlib

```bash
tar -xf "$MPAS_DEPS_ROOT/downloads/zlib-<version>.tar.gz" -C "$MPAS_DEPS_ROOT/src"
cd "$MPAS_DEPS_ROOT/src/zlib-<version>"
./configure --prefix="$MPAS_STACK"
make -j4
make test
make install
```

#### HDF5

这里构建带高层接口和 zlib 支持的串行 HDF5，供 NetCDF-4 使用；
MPI 并行 I/O 通过后面的 PnetCDF 提供。

```bash
tar -xf "$MPAS_DEPS_ROOT/downloads/hdf5-<version>.tar.gz" -C "$MPAS_DEPS_ROOT/src"
cd "$MPAS_DEPS_ROOT/src/hdf5-<version>"
./configure --prefix="$MPAS_STACK" --enable-shared --enable-hl \
    --disable-fortran --with-zlib="$MPAS_STACK"
make -j4
make check
make install
```

#### NetCDF-C

先完成 HDF5 安装。此模板关闭远程 DAP 访问；
其他版本新增的可选依赖及开关按该发行包的构建说明处理。

```bash
tar -xf "$MPAS_DEPS_ROOT/downloads/netcdf-c-<version>.tar.gz" -C "$MPAS_DEPS_ROOT/src"
cd "$MPAS_DEPS_ROOT/src/netcdf-c-<version>"
./configure --prefix="$MPAS_STACK" --enable-shared --disable-dap
make -j4
make check
make install
```

#### NetCDF-Fortran

必须在 NetCDF-C 安装成功后执行，两者使用同一个前缀。
参见 [Unidata Fortran build guide](https://docs.unidata.ucar.edu/netcdf-c/current/building_netcdf_fortran.html)。

```bash
tar -xf "$MPAS_DEPS_ROOT/downloads/netcdf-fortran-<version>.tar.gz" -C "$MPAS_DEPS_ROOT/src"
cd "$MPAS_DEPS_ROOT/src/netcdf-fortran-<version>"
./configure --prefix="$MPAS_STACK" --enable-shared
make -j4
make check
make install
```

#### PnetCDF

```bash
tar -xf "$MPAS_DEPS_ROOT/downloads/pnetcdf-<version>.tar.gz" -C "$MPAS_DEPS_ROOT/src"
cd "$MPAS_DEPS_ROOT/src/pnetcdf-<version>"
./configure --prefix="$MPAS_STACK" --enable-shared \
    CC=mpicc CXX=mpicxx FC=mpif90 F77=mpif90
make -j4
make check
make install
```

#### PIO 2

先完成 NetCDF-C、NetCDF-Fortran 和 PnetCDF 的安装。
下面以 `pio-2.5.4.tar.gz` 为例；GitHub 下载包的文件名或顶层目录不同则相应修改。
PIO 2.5.4 使用 CMake 配置，安装前缀仍是 `$MPAS_STACK`。

```bash
tar -xf "$MPAS_DEPS_ROOT/downloads/pio-2.5.4.tar.gz" -C "$MPAS_DEPS_ROOT/src"
cmake -S "$MPAS_DEPS_ROOT/src/pio-2.5.4" -B "$MPAS_DEPS_ROOT/build/pio-2.5.4" \
    -DCMAKE_INSTALL_PREFIX="$MPAS_STACK" \
    -DCMAKE_C_COMPILER=mpicc \
    -DCMAKE_Fortran_COMPILER=mpif90 \
    -DNetCDF_PATH="$MPAS_STACK" \
    -DNetCDF_Fortran_PATH="$MPAS_STACK" \
    -DPnetCDF_PATH="$MPAS_STACK" \
    -DPIO_ENABLE_FORTRAN=ON \
    -DPIO_ENABLE_TIMING=OFF \
    -DPIO_ENABLE_TESTS=OFF
cmake --build "$MPAS_DEPS_ROOT/build/pio-2.5.4" --parallel 4
cmake --install "$MPAS_DEPS_ROOT/build/pio-2.5.4"
```

此模板关闭 PIO 的 GPTL timing 和上游测试；安装后继续按 Appendix D 验证环境。
PIO 配置选项以所用发行版为准，参考 [NCAR ParallelIO](https://github.com/NCAR/ParallelIO)。

本页选择外部 PIO 2。本地 HKUST-MPAS Makefile 在 `PIO` 非空时使用外部 PIO，
为空时使用内置 SMIOL；当前会自动检测 PIO 接口版本。
其他分支或旧版本可能不同，应按所用 MPAS 源码确认。

(env-appendix-checks)=
### D. Verify the Environment

在已经填写并加载环境文件后执行这些检查。
若自定义文件名不是 `~/.bashrc_mpas`，使用实际文件名替换示例。

#### Check Commands, Prefixes and Build Metadata

加载自己的 MPAS 环境后执行：

```bash
command -v make cmake mpicc mpif90 mpiexec
make --version
cmake --version
printf 'NETCDF=%s\nPNETCDF=%s\nPIO=%s\n' "$NETCDF" "$PNETCDF" "$PIO"

"$NETCDF/bin/nc-config" --all
"${NETCDFF:-$NETCDF}/bin/nf-config" --all
"$PNETCDF/bin/pnetcdf-config" --all
```

`--all` 可核对安装前缀、构建所用编译器和功能。
例如 Fortran 接口应可用、PnetCDF 应包含所需的 Fortran 支持。
然后检查相关头文件、模块和库：

```bash
ls "$NETCDF/include/netcdf.h"
ls "${NETCDFF:-$NETCDF}/include/netcdf.mod"
ls "$PNETCDF/include/pnetcdf.h" "$PNETCDF/include/pnetcdf.mod"
ls "$PIO/include/pio.mod"

find "$NETCDF" "${NETCDFF:-$NETCDF}" "$PNETCDF" "$PIO" \
  -maxdepth 2 \( -name 'libnetcdf.*' -o -name 'libnetcdff.*' \
  -o -name 'libpnetcdf.*' -o -name 'libpiof.*' -o -name 'libpioc.*' \) -print
```

某些编译器的模块大小写或安装布局不同，应结合对应安装记录调整。
PIO 2 通常有 `libpiof` 和 `libpioc`；不要因为没找到 PIO 1 风格的 `libpio.a` 就判断安装失败。
可查看 `$PIO/lib/libpio.settings`，若使用 `lib64` 则查看相应目录。

#### Compile, Link and Run a Small Check

文件存在仅代表安装目录里有产物。还要用当前 MPI wrappers 实际编译、链接，
并运行小程序来检查通信和 I/O。

本仓库提供了三个配套文件，均位于 `docs/getting-started/checks/`：

- {download}`preflight.sh <checks/preflight.sh>`：检查和启动脚本。
- {download}`mpi_c_check.c <checks/mpi_c_check.c>`：C MPI 通信及 NetCDF-C 链接检查。
- {download}`io_fortran_check.f90 <checks/io_fortran_check.f90>`：Fortran/MPI、文件读写及 PIO 2 接口检查。

从网站下载时把三个文件保存到同一目录；下面命令则假设在 **MPAS-Notes 仓库根目录**。
脚本使用当前已经加载的环境，不安装库、不修改 bashrc，也不构建完整模型。

先运行不启动 MPI 作业的检查：

```bash
source ~/.bashrc_mpas
bash docs/getting-started/checks/preflight.sh --compile-only
```

它会分别编译 C 和 Fortran 程序，并通过 Linux `ldd` 检查动态库是否缺失，
以及找到的 NetCDF/PnetCDF/HDF5 共享库是否来自所选前缀。**没有 `not found` 不等于没有混库。**
NetCDF 链接参数同时取自 `nf-config --flibs` 和 `nc-config --libs`，因为某些安装的
`nf-config` 只列出 `-lnetcdff`，并不包含 PIO 还需要的 `-lnetcdf`。
更复杂的静态库安装可以通过 `MPAS_CHECK_EXTRA_LIBS` 补充实际需要的依赖参数。

然后在允许运行 MPI 的位置，用两个进程完成运行检查：

```bash
bash docs/getting-started/checks/preflight.sh
```

如果包装命令叫 `mpifort`，可以针对这次调用指定：

```bash
MPIFC=mpifort bash docs/getting-started/checks/preflight.sh
```

默认使用 `mpiexec -n 2`。应在集群允许的位置/作业分配内运行，并确认该 launcher
是当前 MPI 对应的启动器。默认临时目录适合单节点检查；多节点时要使用所有进程都可见的共享目录，
例如先创建一个工作目录，再设置 `MPAS_CHECK_ROOT` 指向它。

完整检查应得到以下结果：

| Check | Expected result |
| --- | --- |
| C / Fortran compilation and linking | 编译器能读取头文件与 `.mod`，链接器能找到接口实现 |
| Shared-library resolution | `ldd` 没有 `not found`，I/O 库路径也与所选前缀一致 |
| C MPI / Fortran MPI communication | 两个进程的集合通信结果正确 |
| NetCDF-Fortran I/O | 写入、关闭、重新打开、读回的整数一致 |
| PnetCDF I/O | 各进程共同写入文件，并正确读回自己的数据 |
| PIO 2 interface | `PIO_init` / `PIO_finalize` 正常完成 |

脚本会打印并保留独立的临时检查目录，其中有程序、动态库检查记录和运行产生的文件。
`--compile-only` 成功只说明编译/链接与库发现通过，不能当作 MPI/I/O 运行已验证。
测试使用经典 NetCDF 文件；不覆盖 NetCDF-4 压缩、PIO 完整场读写、多节点互联或完整模型模拟。

#### Diagnose Common Failures

| Message or symptom | What to inspect |
| --- | --- |
| `command not found` | 初始化脚本是否执行；PATH 和 module 是否正确 |
| `mpi.mod` / `netcdf.mod` / `pio.mod` 不存在或无法读取 | include 路径、Fortran 接口、生成模块的编译器是否兼容 |
| `undefined reference` / `DSO missing from command line` | 是否缺少库、链接顺序、C/Fortran 接口及静态依赖 |
| `lib...so: cannot open shared object file` | LD_LIBRARY_PATH、RPATH、链接到的实际版本 |
| `ldd` 有库但来自另一目录；或出现 `illegal instruction` | 实际加载的库版本与路径、编译时 CPU 指令选项、当前节点 CPU；不能只看文件名判断原因 |
| 命令位置或 `-show` 结果与预期不一致 | Conda、module、多个 MPI 安装造成的路径覆盖 |
| MPI 启动失败或挂起 | 作业分配、launcher、节点环境、MPI 运行时和互联配置 |
| PnetCDF 文件创建/读写失败 | 所有进程的路径是否一致可见、权限、MPI-IO 和文件系统支持 |

不要通过随意复制 `.mod`、为不兼容库改名或混用另一套 MPI 来消除报错。
应从编译器 → MPI → 依赖库逐层定位。

#### Ready to Build MPAS

在进入 [Installation](installation.md) 之前确认：

- 已记录模型版本、编译器和 MPI，实现与 make target 对得上。
- 已选定 PIO/SMIOL 路径，并准备好对应依赖。
- 库的实际安装前缀、Fortran 接口和运行时路径一致。
- 针对所选路径的小程序编译/链接检查通过；MPI 与 I/O 运行检查已在合适节点完成。
- 构建工具齐全，源码及构建目录可写，已记录依赖构建和测试结果。

这些检查通过后，可以开始编译 MPAS；它们不能保证任意修改分支都没有源码或构建选项问题。
后续仍需检查模型构建结果，并运行小个例验证可执行文件。
