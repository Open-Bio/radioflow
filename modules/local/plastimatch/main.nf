process PLASTIMATCH_CONVERT {
    // 1. 进程标识和资源管理
    tag "${meta.id}"
    label 'process_medium'

    // 2. 环境和容器管理
    // conda "${moduleDir}/environment.yml" plastimatch 暂时无法使用conda安装
    container "${
        workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://lfabriko/plastimatch:latest' :
        'lfabriko/plastimatch:latest'
    }"

    // 3. 进程输入定义
    input:
    // 元数据 + 输入目录
    tuple val(meta), path(input_dir)

    // 4. 进程输出定义
    output:
    // 转换后的图像文件
    tuple val(meta), path("${meta.id}_0000.nii.gz"), emit: converted_image

    // 日志和版本输出
    // TODO: 日志和版本不知道如何使用
    path("plastimatch_convert.log")          , emit: log
    path("versions.yml")                     , emit: versions

    // 5. 执行条件控制
    when:
    task.ext.when == null || task.ext.when

    // 6. 错误处理策略
    errorStrategy 'retry'
    maxRetries 2

    // 7. 主执行脚本
    script:
    // 处理可选参数
    def additional_args = task.ext.args ?: ''
    def output_filename = "${meta.id}_0000.nii.gz"

    """
    # 开始转换日志
    echo "开始Plastimatch转换: ${meta.id}" > plastimatch_convert.log

    # 执行Plastimatch转换
    plastimatch convert \\
        --input "${input_dir}" \\
        --output-img "${output_filename}" \\
        ${additional_args} \\
        2>> plastimatch_convert.log

    # 验证转换是否成功
    if [ ! -f "${output_filename}" ]; then
        echo "转换失败：未生成输出文件" >&2
        exit 1
    fi

    # 记录Plastimatch版本
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plastimatch: \$(plastimatch | grep -oP '(?<=version ).*')
    END_VERSIONS

    # TODO: 日志最终只保留最后的，需要改进
    # 完成日志
    echo "Plastimatch转换完成: ${meta.id}" >> plastimatch_convert.log
    """

    // 8. 桩测试
    stub:
    def output_filename = "${meta.id}_0000.nii.gz"
    """
    # 生成占位符文件
    touch ${output_filename}
    touch plastimatch_convert.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plastimatch: "stub-version"
    END_VERSIONS
    """

}
