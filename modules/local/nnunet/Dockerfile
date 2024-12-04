FROM mambaorg/micromamba:cuda12.6.2-ubuntu24.04


RUN micromamba install -y -n base -f /tmp/conda.yml \
    && micromamba install -y -n base  conda-forge::procps-ng \
    && micromamba env export --name base --explicit > environment.lock \
    && echo ">> CONDA_LOCK_START" \
    && cat environment.lock \
    && echo "<< CONDA_LOCK_END" \
    && micromamba clean -a -y

RUN pip install --no-cache-dir click nnunet
USER root
ENV PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"
