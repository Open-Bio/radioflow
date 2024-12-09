include { ARIA2 } from "./modules/nf-core/aria2/main.nf"

// TODO 如果下载解压后的是文件夹？后续流程取其中的子文件夹
workflow{
    ARIA2(   [
            [:],
            "https://zenodo.org/record/4003545/files/Task006_Lung.zip"
        ])
}
