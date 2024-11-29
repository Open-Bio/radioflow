#! /usr/bin/env python3
""" 对NIFTI图像进行重采样 """

import fire
import SimpleITK as sitk


def resample_nifti_image(
    image_dir, output_filename=None, new_spacing=(0.4, 0.4, 0.4), save=True
):
    """
    对NIFTI图像进行重采样

    参数:
    - image_dir: 输入图像路径
    - new_spacing: 新的像素间距，默认为(0.4, 0.4, 0.4)
    - output_filename: 输出文件名
    - save: 是否保存重采样图像

    返回:
    - 重采样后的图像
    """
    # 读取图像并转换为浮点类型
    sitk_img = sitk.ReadImage(str(image_dir), sitk.sitkFloat32)

    # 获取原始间距
    original_spacing = sitk_img.GetSpacing()

    # 创建重采样滤波器
    resample_filter = sitk.ResampleImageFilter()

    # 设置重采样参数
    resample_filter.SetDefaultPixelValue(0)
    resample_filter.SetOutputSpacing(new_spacing)

    # 动态计算新的图像大小
    resample_filter.SetSize(
        [
            int(round(osz * ospc / nspc))
            for osz, ospc, nspc in zip(
                sitk_img.GetSize(), original_spacing, new_spacing
            )
        ]
    )

    # 保留原始图像的方向和原点
    resample_filter.SetOutputDirection(sitk_img.GetDirection())
    resample_filter.SetOutputOrigin(sitk_img.GetOrigin())

    # 设置线性插值
    resample_filter.SetInterpolator(sitk.sitkLinear)

    # 执行重采样
    resampled_img = resample_filter.Execute(sitk_img)

    # 保存图像（如果需要）
    if save and output_filename is not None:
        sitk.WriteImage(resampled_img, output_filename, useCompression=True)

    # 打印间距信息（可选）
    print("Original Spacing:", sitk_img.GetSpacing())
    print("Resampled Spacing:", resampled_img.GetSpacing())

    return resampled_img


if __name__ == "__main__":
    fire.Fire(resample_nifti_image)
