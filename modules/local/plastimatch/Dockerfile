FROM ubuntu

# 切换apt源为中国的镜像源
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y plastimatch procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
