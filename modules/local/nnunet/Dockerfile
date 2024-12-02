FROM mambaorg/micromamba:cuda12.6.2-ubuntu24.04

# 安装必要的系统依赖和工具
RUN  micromamba install nnunet click -y -c conda-forge \
    && micromamba clean -a -y

USER root
ENV PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"
