process RESAMPLE {
    // 1. 进程标识和资源管理
    tag "${meta.id}"
    label 'process_medium'

    // 2. 环境和容器管理
    // conda "${moduleDir}/environment.yml"
    conda "fire SimpleITK"

    // // 使用 Singularity 且不直接拉取 Docker 镜像时，需要使用 docker:// 前缀
    container "${
        workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'community.wave.seqera.io/library/fire_simpleitk:b83798408e975594' :
        'community.wave.seqera.io/library/fire_simpleitk:b83798408e975594'
    }"
    publishDir "${params.outdir}/resample" , mode: 'copy'

    input:
    tuple val(meta), path(image_file)

    output:
    tuple val(meta), path("*_resample.nii.gz"), emit: resample_nii
    // TODO: 后续可暴露new_spacing参数
    script:
    """
    resample.py "${image_file}"  "${meta.id}_resample.nii.gz"
    """

    // 8. 桩测试
    stub:
    def output_filename = "${meta.id}_resample.nii.gz"
    """
    # 生成占位符文件
    touch ${output_filename}
    """
}
