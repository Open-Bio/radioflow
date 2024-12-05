//
// 用 aria2 下载并在需要时解压数据
//

// 引入 UNTAR 模块，用于解压 tar 文件
include { UNTAR  } from '../../modules/nf-core/untar/main'
// 引入 GUNZIP 模块，用于解压 gz 文件
include { GUNZIP } from '../../modules/nf-core/gunzip/main'
// 引入 ARIA2 模块，用于通过 URL 下载文件
include { ARIA2  } from '../../modules/nf-core/aria2/main'
// 引入 UNZIP 模块，用于解压 zip 文件
include { UNZIP  } from '../../modules/nf-core/unzip/main'

// 定义一个名为 ARIA2_UNCOMPRESS 的工作流
workflow ARIA2_UNCOMPRESS {
    // 定义 take 部分，用于接收输入参数
    take:
    source_url // 输入参数：文件的 URL

    // 定义 main 部分，主要的处理逻辑
    main:
    // 使用 ARIA2 模块通过 source_url 下载文件
    ARIA2 (
        [
            [:], // 占位符，表示空的配置选项
            source_url // 下载 URL
        ]
    )
    // 创建一个空的通道 ch_db
    // 为了在后续的代码中根据不同的文件类型动态地赋值给它
    ch_db = Channel.empty()

    // 判断下载的文件类型，根据文件后缀名选择解压方式
    if (source_url.toString().endsWith('.tar') || source_url.toString().endsWith('.tar.gz')) {
        // 如果文件是 tar 或 tar.gz 格式，用 UNTAR 模块解压
        ch_db = UNTAR ( ARIA2.out.downloaded_file ).untar.map{ it[1] }
    } else if (source_url.toString().endsWith('.gz')) {
        // 如果文件是 gz 格式，用 GUNZIP 模块解压
        ch_db = GUNZIP ( ARIA2.out.downloaded_file ).gunzip.map { it[1] }
    } else if (source_url.toString().endsWith('.zip')) {
        // 如果文件是 zip 格式，用 UNZIP 模块解压
        ch_db = UNZIP ( ARIA2.out.downloaded_file ).unzipped_archive.map { it[1] }
    } else {
        // 如果文件不需要解压，直接使用下载的文件
        ch_db = ARIA2.out.downloaded_file
    }

    // 定义 emit 部分，输出结果
    emit:
    db       = ch_db              // 输出解压后的文件通道，命名为 db
    versions = ARIA2.out.versions // 输出下载过程中的版本信息通道，命名为 versions
}
// TODO 如果下载解压后的是文件夹？后续流程取其中的子文件夹
workflow{
    //"https://zenodo.org/record/4003545/files/Task006_Lung.zip
    ARIA2_UNCOMPRESS("https://zenodo.org/record/4003545/files/Task006_Lung.zip?download=1")
}
