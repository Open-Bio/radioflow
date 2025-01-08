process VISUAL_SLICE {
    // 1. 进程标识和资源管理
    tag "${meta.id}"
    label 'process_medium'



    input:
    tuple val(meta), path(input_file), path(predicted_image)

    output:
    path "${meta.id}_slice.png"

    script:
    """
    visual_seg.py "${input_file}" "${predicted_image}" \
    --output_type "slice" \
    --output_path "${meta.id}_slice.png" \
    --interval 20 \
    --dpi 600
    """

    // 8. 桩测试
    stub:
    """
    # 生成占位符文件
    touch ${meta.id}_slice.png
    """
}

