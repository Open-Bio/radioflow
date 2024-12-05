process PYRADIOMICS {
    // 1. 进程标识和资源管理
    tag "${meta.id}"
    label 'process_medium'

    // 2. 环境和容器管理
    // conda "${moduleDir}/environment.yml"

    // // 使用 Singularity 且不直接拉取 Docker 镜像时，需要使用 docker:// 前缀
    // container "${
    //     workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'docker://community.wave.seqera.io/library/pip_pyradiomics:7e206760333f217a' :
    //     'radiomics/pyradiomics:CLI'
    // }"
    // publishDir "${params.outdir}" , mode: 'copy'

    input:
    tuple val(meta), path(input_file), path(predicted_image)

    output:
    tuple val(meta), path("*_features.csv"), emit: features  // 修改输出，包含 meta 信息

    script:
    """
    pyradiomics "${input_file}" "${predicted_image}" \
        --format csv \
        --param "${moduleDir}/params.yaml" \
        --out ${meta.id}_features.csv
    """

    // 8. 桩测试
    stub:
    """
    # 生成占位符文件
    touch ${meta.id}_features.csv
    """
}


process MERGE_FEATURES {
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path features_csv

    output:
    path "features_all.csv"

    script:
    """
    # 确保输入文件存在且不为空
    for f in *.csv; do
        if [ ! -s "\$f" ]; then
            echo "Error: File \$f is empty or does not exist" >&2
            exit 1
        fi
    done

    # 首先获取并输出表头
    head -n 1 \$(ls *.csv | head -n 1) > features_all.csv.tmp

    # 处理数据行
    awk -v OFS="," 'FNR>1 {
        sample=FILENAME
        sub(/_.+\$/, "", sample)
        print sample, \$0
    }' *.csv | sort -t',' -k1,1 >> features_all.csv.tmp

    # 重命名临时文件
    mv features_all.csv.tmp features_all.csv

    # 验证输出文件
    if [ ! -s features_all.csv ]; then
        echo "Error: Output file is empty" >&2
        exit 1
    fi

    echo "Successfully created features_all.csv"
    """

    stub:
    """
    # 生成占位符文件
    touch features_all.csv
    """
}
