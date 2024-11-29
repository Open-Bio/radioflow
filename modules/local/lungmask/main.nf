process LUNG_SEGMENTATION {
    // 1. 进程标识和资源管理
    tag "${meta.id}"
    label 'process_medium'

    // 2. 环境和容器管理
    // conda "${moduleDir}/environment.yml"

    // // 使用 Singularity 且不直接拉取 Docker 镜像时，需要使用 docker:// 前缀
    container "${
        workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://august777/radiomics-lungmask:1.0.1' :
        'august777/radiomics-lungmask:1.0.1'
    }"
    publishDir "${params.outdir}/lung_segment" , mode: 'copy'

    input:
    tuple val(meta), path(image_file)

    output:
    tuple val(meta), path("*_lung_seg.nii.gz"), emit: lung_seg_nii

    script:
    """
    lungmask "${image_file}"  "${meta.id}_lung_seg.nii.gz" --modelpath "${moduleDir}/unet_r231-d5d2fc3d.pth"
    """

    // 8. 桩测试
    stub:
    def output_filename = "${meta.id}_lung_seg.nii.gz"
    """
    # 生成占位符文件
    touch ${output_filename}
    """
}
