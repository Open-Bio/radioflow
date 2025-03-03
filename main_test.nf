// 引入外部模块：从本地的 'plastimatch' 模块中导入 PLASTIMATCH_CONVERT 转换工具
include { PLASTIMATCH_CONVERT   } from './modules/local/plastimatch'
include { LUNG_SEGMENTATION     } from './modules/local/lungmask'
include { RESAMPLE              } from './modules/local/resample'
include { NNUNET_PREDICT        } from './modules/local/nnunet'
include { PYRADIOMICS as FEATURES_CT } from './modules/local/pyradiomics'
include { MERGE_FEATURES } from './modules/local/pyradiomics'

include { VISUAL_SLICE } from './modules/local/visualization'
// 数据通道创建和处理阶段

samples_ch = Channel
    // 从指定路径读取 CSV 文件（通过 params.input 参数定义）
    .fromPath(params.input)
    .ifEmpty { exit 1, "未找到输入 CSV 文件" }
    // 将 CSV 文件按行拆分，识别表头
    // sample,path
    // SAMPLE_1,/path/to/data/SAMPLE_1/CT
    // SAMPLE_2,/path/to/data/SAMPLE_2/CT
    // SAMPLE_3,/path/to/data/SAMPLE_3/CT
    .splitCsv(header: true)
    // 对每一行记录进行数据转换和元数据构建
    .map { row ->
        // 创建元数据对象，使用 sample 列作为唯一标识符
        def meta = [
            id: row.sample,
            patient_id: row.patient_id ?: row.sample
        ]
        // 将路径转换为文件对象
        def input_dir = file(row.path)
        // 返回元组：(元数据, 输入目录)
        tuple(meta, input_dir)
    }

// 定义主工作流程
workflow {
    // 转换数据通道中的每个样本
    PLASTIMATCH_CONVERT(samples_ch)

    // 对图像进行重采样
    RESAMPLE(PLASTIMATCH_CONVERT.out.converted_image)

    // 进行肺部分割
    LUNG_SEGMENTATION(RESAMPLE.out.resample_nii)

    // 使用nnUNet进行预测
    // 使用collect()收集所有分割结果，然后传递给NNUNET_PREDICT
    NNUNET_PREDICT(RESAMPLE.out.resample_nii
        .map { meta, file -> file }
        .collect(), file(params.model_dir))

    predict_ch = NNUNET_PREDICT.out.predicted_images.flatten()
            .map { predicted_image ->
                def predicted_name = predicted_image.toString().split('/').last().replace('_resample.nii.gz', '')
                // 修改这部分，确保从 input 目录获取文件
                def input_file_path = predicted_image.toString()
                    .replace('/output/', '/input/')  // 替换目录
                    .replace('_resample.nii.gz', '_resample_0000.nii.gz')  // 替换文件名
                def input_file = file(input_file_path)
                def common_id = predicted_name
                def meta = [id: common_id]
                tuple(meta, input_file, predicted_image)
            }
        // 提取影像特征
    FEATURES_CT(predict_ch)

    FEATURES_CT.out.features
    .map { meta, features_csv ->
        features_csv
    }
    .collect()
    .set { features_to_merge }

    MERGE_FEATURES(features_to_merge)
    VISUAL_SLICE(predict_ch)
}
