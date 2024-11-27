process PLASTIMATCH_CONVERT {
    tag "plastimatch"
    input:
        path input_dir
    output:
        path "*.nii.gz"
    publishDir "./output", mode: 'copy'
    script:
    """
    plastimatch convert --input "${input_dir}" --output-img "xx.nii.gz"
    """
}

//路径过深导致失灵，换成容器试试

