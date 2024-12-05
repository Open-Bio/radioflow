#! /opt/conda/bin/python

import click
from nnunet.inference.predict import predict_from_folder


@click.command()
@click.option("--model", required=True, type=str, help="模型路径")
@click.option("--input_folder", required=True, type=str, help="输入文件夹路径")
@click.option("--output_folder", required=True, type=str, help="输出文件夹路径")
def main(model, input_folder, output_folder):
    predict_from_folder(
        model=model,
        input_folder=input_folder,
        output_folder=output_folder,
        folds=(0, 1, 2, 3, 4),  # 使用全部5个模型
        save_npz=False,
        num_threads_preprocessing=6,
        num_threads_nifti_save=2,
        lowres_segmentations=None,  # 如果不是级联模型则为None
        part_id=0,
        num_parts=1,
        tta=True,
    )


if __name__ == "__main__":
    # 示例用法:
    # python nnunet_predict.py --model "/work/run/projects/fanxi/nextflow/biofree-radiomics/test/test_tools/nnUNet/3d_lowres/Task006_Lung/nnUNetTrainerV2__nnUNetPlansv2.1" --input_folder "/work/run/projects/fanxi/nextflow/biofree-radiomics/test/test_tools/nnUNet/3d_lowres/Task006_Lung/nnUNetTrainerV2__nnUNetPlansv2.1" --input_folder "/work/run/projects/fanxi/nextflow/biofree-radiomics/test/results/plastimatch" --output_folder "test"
    main()
