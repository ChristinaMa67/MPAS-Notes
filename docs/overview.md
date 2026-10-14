# Overview and Official Resources

This page is used for collecting information and resources related to MPAS with some brief introduction on MPAS model.

## Official Resources

| resources | purposes |
| --- | --- |
| [MPAS Official Website](https://mpas-dev.github.io/) | Model Entry |
| [MPAS-Atmosphere Official Website](https://www2.mmm.ucar.edu/projects/mpas/site/index.html) | 大气模型的文档、数据和相关资源 |
| [模型概览 / Overview](https://www2.mmm.ucar.edu/projects/mpas/site/documentation/mpas_overview.html) | 了解网格、动力框架和物理过程 |
| [用户手册 / User Guide](https://www2.mmm.ucar.edu/projects/mpas/site/documentation/users_guide.html) | 查询编译、初始化、运行、namelist 和 streams |
| [官方教程 / Tutorial](https://www2.mmm.ucar.edu/projects/mpas/tutorial/) | 按练习步骤学习模型的实际使用 |
| [官方源码 / Source Code](https://github.com/MPAS-Dev/MPAS-Model) | 阅读代码、查看提交和版本标签 |
| [版本与下载 / Releases and Downloads](https://mpas-dev.github.io/atmosphere/atmosphere_download.html) | 查找发布说明、网格、静态地理数据和示例输入 |
| [网格规范 / Mesh Specification](https://www2.mmm.ucar.edu/projects/mpas/mpas_website_linked_files/mpas_meshspec.pdf) | 理解网格文件中的维度、变量和连接关系 |
| [官方支持论坛 / Support Forum](https://forum.mmm.ucar.edu/) | 搜索编译、运行、物理和后处理问题 |
| [相关论文 / Publications](https://www2.mmm.ucar.edu/projects/mpas/site/publications.html) | 查找模型方法及应用研究 || [MPAS 项目主页](https://mpas-dev.github.io/) | 项目的总体入口 |
| [MPAS-Atmosphere 官方网站](https://www2.mmm.ucar.edu/projects/mpas/site/index.html) | 大气模型的文档、数据和相关资源 |
| [模型概览 / Overview](https://www2.mmm.ucar.edu/projects/mpas/site/documentation/mpas_overview.html) | 了解网格、动力框架和物理过程 |
| [用户手册 / User Guide](https://www2.mmm.ucar.edu/projects/mpas/site/documentation/users_guide.html) | 查询编译、初始化、运行、namelist 和 streams |
| [官方教程 / Tutorial](https://www2.mmm.ucar.edu/projects/mpas/tutorial/) | 按练习步骤学习模型的实际使用 |
| [官方源码 / Source Code](https://github.com/MPAS-Dev/MPAS-Model) | 阅读代码、查看提交和版本标签 |
| [版本与下载 / Releases and Downloads](https://mpas-dev.github.io/atmosphere/atmosphere_download.html) | 查找发布说明、网格、静态地理数据和示例输入 |
| [网格规范 / Mesh Specification](https://www2.mmm.ucar.edu/projects/mpas/mpas_website_linked_files/mpas_meshspec.pdf) | 理解网格文件中的维度、变量和连接关系 |
| [官方支持论坛 / Support Forum](https://forum.mmm.ucar.edu/) | 搜索编译、运行、物理和后处理问题 |
| [相关论文 / Publications](https://www2.mmm.ucar.edu/projects/mpas/site/publications.html) | 查找模型方法及应用研究 |

## What is MPAS

MPAS - Model for Prediction Across Scales
它包含共享的软件框架，以及大气、海洋、海冰和陆冰等模型组件。
共享框架提供并行通信、输入输出、数据结构和模型驱动等功能。
这个笔记主要是学习一下如何使用MPAS-Atmosphere(MPAS-A)以及基于MPAS-A开发的MPAS-Urban，目前MPAS-Urban只做了SLUCM的接入

参考：[官方源码仓库介绍](https://github.com/MPAS-Dev/MPAS-Model)。
MPAS-Urban：DOI: 10.22541/essoar.15007108/v1

## MPAS-Atmosphere 的基本特点

### 非静力大气模型 / Nonhydrostatic Model

MPAS-A 求解全可压缩、非静力的大气运动方程。
它可以用于全球模拟，也支持有限区域模拟。

### 非结构化网格 / Unstructured Mesh

水平网格采用质心 Voronoi 网格。

网格可以具有近似均匀的分辨率，也可以让不同区域具有不同的
网格间距，并在粗细网格之间平滑过渡。

在全球变分辨率模拟中，可以在同一张网格内对关注区域加密。

### 动力与物理 / Dynamics and Physics

- **动力框架**：计算大气运动以及相关的输送和时间演化。
- **物理参数化**：表示辐射、云微物理、边界层、陆面等过程。

具体可用的方案和配置应结合所使用的模型版本查阅。

参考：[官方模型概览](https://www2.mmm.ucar.edu/projects/mpas/site/documentation/mpas_overview.html)。

## 一次模拟的基本流程

1. 准备编译环境，生成模型可执行文件。
2. 准备网格、静态地理数据和所需气象输入。
3. 配置 namelist 与 streams 文件。
4. 使用 `init_atmosphere_model` 生成初始条件。
5. 使用 `atmosphere_model` 进行时间积分。
6. 对输出进行可视化、分析和验证。

其中：

- `namelist` 主要控制模型运行选项和参数。
- `streams` 主要控制输入输出的数据流。

参考：[官方 Quick Start Guide](https://www2.mmm.ucar.edu/projects/mpas/site/documentation/users_guide/quick_start.html)。
