process NNUNET_SEGMENTATION {
    input:
    path input_dir
    path output_dir

    output:
    path "${output_dir}"

    script:
    """
    docker run --rm \\
      --gpus all \\
      -v \$(pwd)/plastimatch:/app/data/input \\
      -v ${output_dir}:/app/data/output \\
      --name radiomics_task \\
      radiomics_gpu:2.0 \\
      -i /app/data/input \\
      -o /app/data/output \\
      -t Task006_Lung \\
      -m 3d_fullres
    """
}

workflow {
    input_dir = "${launchDir}/results/plastimatch"
    output_dir = "${launchDir}/results/output"

    radiomics_task(input_dir, output_dir)
}
