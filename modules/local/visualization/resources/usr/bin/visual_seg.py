#! /usr/bin/env python

from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Tuple

import click
import matplotlib.animation as animation
import matplotlib.pyplot as plt
import numpy as np
import SimpleITK as sitk
from matplotlib.patches import Patch
from numpy.typing import NDArray


@dataclass
class ImageData:
    """存储图像数据的数据类"""

    sitk_image: sitk.Image
    array: NDArray

    @classmethod
    def from_file(cls, path: Path) -> "ImageData":
        """从文件创建ImageData实例"""
        sitk_image = sitk.ReadImage(str(path))
        return cls(sitk_image=sitk_image, array=sitk.GetArrayFromImage(sitk_image))


class MedicalImageVisualizer:
    """医学图像可视化工具类"""

    def __init__(self, image_path: str, seg_path: Optional[str] = None):
        """
        初始化医学图像可视化器

        Args:
            image_path: 原始图像路径
            seg_path: 分割掩码路径(可选)
        """
        self.image = ImageData.from_file(Path(image_path))
        self.seg: Optional[ImageData] = None

        if seg_path and Path(seg_path).exists():
            self.seg = ImageData.from_file(Path(seg_path))

    def _get_segmentation_range(self) -> Tuple[Optional[int], Optional[int]]:
        """获取分割标注的起止层面"""
        if self.seg is None:
            return None, None

        # 计算每个切片中的分割像素数
        pixels_per_slice = np.sum(self.seg.array > 0, axis=(1, 2))
        seg_slices = np.nonzero(pixels_per_slice)[0]

        return (seg_slices[0], seg_slices[-1]) if len(seg_slices) > 0 else (None, None)

    def _create_overlay_mask(self, slice_idx: int) -> NDArray:
        """为指定切片创建分割遮罩"""
        overlay = np.zeros_like(self.image.array[slice_idx])
        if self.seg is not None:
            mask = self.seg.array[slice_idx] > 0
            overlay[mask] = 1
        return overlay

    def _add_segmentation_overlay(
        self, ax: plt.Axes, slice_idx: int
    ) -> Optional[plt.Artist]:
        """在指定axes上添加分割遮罩"""
        if self.seg is None:
            return None

        overlay = self._create_overlay_mask(slice_idx)
        overlay_im = ax.imshow(overlay, cmap="Reds", alpha=overlay / 2)

        # 添加图例
        legend_elements = [Patch(facecolor="red", alpha=0.3, label="Seg")]
        ax.legend(handles=legend_elements, loc="upper right")

        return overlay_im

    def show_slice(
        self,
        slice_idx: Optional[int] = None,
        output_path: Optional[str] = None,
        dpi: int = 600,
    ) -> None:
        """
        显示单个切片

        Args:
            slice_idx: 要显示的切片索引，如未指定则自动选择
            output_path: 保存图像的路径（可选）
            dpi: 分辨率，默认600ppi
        """
        # 自动选择切片
        if slice_idx is None:
            if self.seg is not None:
                start, end = self._get_segmentation_range()
                slice_idx = (
                    (start + end) // 2
                    if start is not None
                    else self.image.array.shape[0] // 2
                )
            else:
                slice_idx = self.image.array.shape[0] // 2

        # 创建显示
        fig, ax = plt.subplots(figsize=(5, 5))
        ax.imshow(self.image.array[slice_idx], cmap="gray")
        self._add_segmentation_overlay(ax, slice_idx)

        # 设置图像属性
        ax.set_title(f"Slice {slice_idx}")
        ax.axis("off")
        plt.tight_layout()

        if output_path:
            plt.savefig(output_path, dpi=dpi)
            plt.close()
        else:
            plt.show()

    def create_animation(
        self,
        output_path: str,
        start_idx: Optional[int] = None,
        end_idx: Optional[int] = None,
        interval: int = 20,
        dpi: int = 600,
    ) -> None:
        """
        创建切片动画并保存为GIF

        Args:
            output_path: GIF输出路径
            start_idx: 起始切片索引（可选）
            end_idx: 结束切片索引（可选）
            interval: 帧间隔，单位为毫秒
            dpi: 分辨率，默认600ppi
        """
        # 确定切片范围
        # if start_idx is None or end_idx is None:
        #     if self.seg is not None:
        #         start, end = self._get_segmentation_range()
        #         start_idx = start if start_idx is None else start_idx
        #         end_idx = end if end_idx is None else end_idx

        start_idx = start_idx or 0
        end_idx = end_idx or (self.image.array.shape[0] - 1)

        # 创建图像
        fig, ax = plt.subplots(figsize=(5, 5))
        ax.axis("off")

        # 初始显示
        im = ax.imshow(self.image.array[start_idx], cmap="gray")
        overlay_im = self._add_segmentation_overlay(ax, start_idx)

        def update(frame):
            # 更新图像数据
            im.set_array(self.image.array[frame])
            if overlay_im is not None:
                overlay = self._create_overlay_mask(frame)
                overlay_im.set_array(overlay)
            ax.set_title(f"Slice {frame}")
            return [im, overlay_im] if overlay_im else [im]

        # 创建动画
        frames = range(start_idx, end_idx + 1)
        anim = animation.FuncAnimation(
            fig, update, frames=frames, interval=interval, blit=True
        )

        # 保存为GIF
        anim.save(output_path, writer="pillow", dpi=dpi)
        plt.close()


@click.command()
@click.argument("image_path")
@click.argument("seg_path")
@click.option(
    "--output_type",
    type=click.Choice(["slice", "animation"]),
    default="slice",
    help="选择保存切片或动画，默认为切片",
)
@click.option("--output_path", default=None, help="输出路径，默认不保存")
@click.option("--interval", default=20, help="帧率控制，单位为毫秒")
@click.option("--dpi", default=600, help="分辨率控制，默认600ppi")
def main(image_path, seg_path, output_type, output_path, interval, dpi):
    # 创建可视化器实例
    visualizer = MedicalImageVisualizer(image_path, seg_path)

    if output_type == "slice":
        # 显示中间切片
        visualizer.show_slice(output_path=output_path, dpi=dpi)
    elif output_type == "animation":
        # 创建动画
        visualizer.create_animation(output_path=output_path, interval=interval, dpi=dpi)
    else:
        pass


if __name__ == "__main__":
    main()
