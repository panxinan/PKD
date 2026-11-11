# 清除当前环境中的所有数据
rm(list = ls())

# 设置工作路径为代码文件所在的路径
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(trackViewer)
library(grid)
library(ggplot2)

# ==================== 读取并处理第一个数据集 (top) ====================
# 加载 readxl 包（若未安装请先执行 install.packages("readxl")）
library(readxl)

# 读取 gnomad.xlsx 文件，默认第一行为列名，字符型不会被转为因子
data_top <- read_excel("gnomad.xlsx")

SNP_top <- data_top$Start
original_freq_top <- data_top$AF
clnsig_top <- data_top$CLNSIG
hgvs_names_top <- data_top$HGVS

sample.gr <- GRanges("chr1",
                     IRanges(SNP_top, width=1, names=hgvs_names_top))

# 使用对数变换放大差异
sample.gr$score <- log10(original_freq_top * 100000000)

# 节点标签设为 NA（不显示）
sample.gr$node.label <- NA

# 根据 CLNSIG 设置颜色
color_mapping <- c(
  "Missense_variant"   = "#4DBBD5",  # 蓝
  "Stop_gained"        = "#E64B35",  # 红
  "Synonymous_variant" = "#00A087",  # 绿
  "Splicing"           = "#3C5488",  # 深蓝
  "Frameshift"         = "#F39B7F",  # 橙
  "Intron_variant"     = "#8491B4",  # 灰蓝
  "Inframe_deletion"   = "#91D1C2"   # 青绿
)

sample.gr$color <- color_mapping[clnsig_top]

# 处理缺失颜色映射
if (any(is.na(sample.gr$color))) {
  warning("Some CLNSIG values are not in the color mapping. Using default color for those.")
  missing_values <- unique(clnsig_top[is.na(sample.gr$color)])
  cat("Missing CLNSIG values:", paste(missing_values, collapse = ", "), "\n")
  sample.gr$color[is.na(sample.gr$color)] <- "#888888"
}

# ***** 关键：将当前数据集分配到 top 轨道 *****
sample.gr$SNPsideID <- "top"

# ==================== 读取并处理第二个数据集 (bottom) ====================
data_bottom <- read_excel("allofus.xlsx")

SNP_bottom <- data_bottom$Start
original_freq_bottom <- data_bottom$AF
clnsig_bottom <- data_bottom$CLNSIG
hgvs_names_bottom <- data_bottom$HGVS

sample2.gr <- GRanges("chr1",
                      IRanges(SNP_bottom, width=1, names=hgvs_names_bottom))

# 使用对数变换放大差异
sample2.gr$score <- log10(original_freq_bottom * 100000000)

# 节点标签设为 NA
sample2.gr$node.label <- NA

# 根据 CLNSIG 设置颜色（使用相同的颜色映射）
sample2.gr$color <- color_mapping[clnsig_bottom]

# 处理缺失颜色映射
if (any(is.na(sample2.gr$color))) {
  warning("Some CLNSIG values are not in the color mapping. Using default color for those.")
  missing_values <- unique(clnsig_bottom[is.na(sample2.gr$color)])
  cat("Missing CLNSIG values:", paste(missing_values, collapse = ", "), "\n")
  sample2.gr$color[is.na(sample2.gr$color)] <- "#888888"
}

# ***** 关键：将当前数据集分配到 bottom 轨道 *****
sample2.gr$SNPsideID <- "bottom"

# ==================== 合并两个数据集 ====================
# 将两个 GRanges 对象合并为一个 GRangesList 或使用 c() 合并
# lolliplot 支持 GRangesList 或合并后的 GRanges
sample_combined <- c(sample.gr, sample2.gr)

# ==================== 设置特征区域（外显子） ====================
features <- GRanges("chr1", 
                    IRanges(start = c(155289293, 155291756, 155293177, 155293438, 155294235,
                                      155294482, 155295116, 155295437, 155295665, 155300098,
                                      155301296),
                            end   = c(155290678, 155291937, 155293343, 155293590, 155294385,
                                      155294752, 155295302, 155295568, 155295756, 155300280,
                                      155301438),
                            names = paste0("exon", 11:1)))

features$fill <- c(
  "#E64B35FF",  # exon11
  "#4DBBD5FF",  # exon10
  "#00A087FF",  # exon9
  "#3C5488FF",  # exon8
  "#F39B7FFF",  # exon7
  "#8491B4FF",  # exon6
  "#91D1C2FF",  # exon5
  "#DC0000FF",  # exon4
  "#7E6148FF",  # exon3
  "#B09C85FF",  # exon2
  "#FDB462FF"   # exon1
)
features$height <- c(0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05)

# ==================== 定义 X 轴刻度 ====================
xaxis <- c(155289293, 155290678, 155291756, 155291937,
           155293177, 155293343, 155293438, 155293590,
           155294235, 155294385, 155294482, 155294752,
           155295116, 155295302, 155295437, 155295568,
           155295665, 155295756, 155300098, 155300280,
           155301296, 155301438)
# ==================== 绘制图形 ====================
pdf("棒棒糖图-双轨乘以8.pdf", width = 12, height = 9.0)

# 绘制 lollipop 图，传入合并后的 GRanges 对象
lolliplot(sample_combined, features, xaxis = xaxis,
          cex = 0.8,
          xaxis.y = 1.6,
          xaxis.gp = gpar(cex = 0.8, col = "black"))

# 使用 grid 图形系统添加图例
grid::pushViewport(viewport(x = 0.85, y = 0.7, width = 0.3, height = 0.5))

legend_grob <- legendGrob(labels = names(color_mapping),
                          pch = 21,
                          gp = gpar(fill = color_mapping, col = "black"),
                          hgap = unit(2, "mm"),
                          vgap = unit(2, "mm"),
                          default.units = "npc")

grid.text("Variant Type",
          x = unit(0, "npc"), y = unit(1, "npc"),
          just = c("left", "top"),
          gp = gpar(fontface = "bold", cex = 0.9))

grid::pushViewport(viewport(y = 0.88, height = 0.88))
grid.draw(legend_grob)
grid::popViewport()

dev.off()