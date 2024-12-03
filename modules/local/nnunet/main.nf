// nnUNet预测进程
process NNUNET_PREDICT {
    tag "NNUNET_PREDICT"      // 设置任务标签，方便跟踪
    label 'process_gpu'       // 指定任务标签为 'process_gpu'，用于资源配置

    // 结果发布配置，将输出文件复制到指定目录
    // publishDir "${params.outdir}", mode: 'copy',pattern: "**.nii.gz"

    // 指定Conda环境和容器，确保运行环境的一致性
    // conda "${moduleDir}/environment.yml"
    container "${
        workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://august777/radiomics-nnunet:1.0.1' :
        'august777/radiomics-nnunet:1.0.1'
    }"

    // 资源配置（可根据需求调整）
    // memory = '16 GB'         // 设置内存限制
    // time = '24h'             // 设置最大运行时间
    // errorStrategy = 'retry'  // 设置错误策略为重试
    maxRetries = 3             // 设置最大重试次数



    input:
    path input_files, stageAs: 'input/*'  // 输入文件（# TODO 仅匹配 .nii.gz 格式），并指定在容器内的路径
    path model_dir                         // TODO 模型目录,定义在参数中才会自动挂载到容器内

    output:
    path "*.nii.gz", emit: predicted_images   // 输出预测的图像文件
    path "versions.yml", emit: versions              // 输出版本信息文件

    script:
    """
    # 重命名输入文件，在文件名末尾添加0000
    for file in input/*.nii.gz; do
        filename=\$(basename "\$file")
        base=\${filename%.nii.gz}
        mv "\$file" "input/\${base}_0000.nii.gz"
    done

    # 运行 nnUNet 预测，指定模型目录、输入和输出文件夹
    nnunet_predict.py \\
        --model "${model_dir}" \\
        --input_folder "input" \\
        --output_folder "nnunet"

    mv nnunet/*.nii.gz .

    # 收集版本信息，保存到 versions.yml 文件
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nnunet: 1.7.0
    END_VERSIONS
    """
    stub:
    """
    # 生成占位符文件
    touch hhhh.nii.gz
    nvidia-smi >> hhhh.nii.gz
    touch versions.yml
    """

}
