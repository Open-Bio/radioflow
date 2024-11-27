// 引入外部模块：从本地的 'plastimatch' 模块中导入 PLASTIMATCH_CONVERT 转换工具
include { PLASTIMATCH_CONVERT } from './modules/local/plastimatch/main.nf'

// 数据通道创建和处理阶段
samples_ch = Channel
    // 从指定路径读取 CSV 文件（通过 params.input 参数定义）
    .fromPath(params.input)
    // 读取的 CSV 文件格式如下：
    // sample,path
    // SAMPLE_1,/path/to/data/SAMPLE_1/CT
    // SAMPLE_2,/path/to/data/SAMPLE_2/CT
    // SAMPLE_3,/path/to/data/SAMPLE_3/CT


    // 将 CSV 文件按行拆分，识别表头
    .splitCsv(header: true)

    // 对每一行记录进行数据转换和元数据构建
    .map { record ->
        // 创建元数据对象，使用 sample 列作为唯一标识符
        def meta = [id: record.sample]

        // 将路径转换为文件对象
        def input_dir = file(record.path)

        // 返回元组：(元数据, 输入目录)
        tuple(meta, input_dir)
    }

// 定义主工作流程
workflow {
    // 将处理好的数据通道直接传递给 PLASTIMATCH_CONVERT 模块进行转换
    samples_ch
        | PLASTIMATCH_CONVERT
}
