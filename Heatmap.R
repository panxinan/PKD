# 清除当前环境中的所有数据
rm(list = ls())

# 设置工作路径为代码文件所在的路径
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# 加载必要的包
library(tidyverse)
library(ggplot2)
library(readxl)

# 定义纵坐标顺序（从下到上）
desired_order <- c("Remaining", "South Asian", "Middle Eastern", "European", "East Asian",
                   "American", "African", "All")

# 获取当前目录下所有xlsx文件
txt_files <- list.files(pattern = "\\.xlsx$")

# 处理每个xlsx文件
for (file in txt_files) {
  # 读取数据
  data <- read_excel(file)
  
  # 转换为长格式并保持列顺序
  long_data <- data %>% 
    pivot_longer(-location, names_to = "category", values_to = "value") %>% 
    mutate(
      # 设置纵坐标因子顺序
      location = factor(location, levels = desired_order),
      # 保持原有列顺序
      category = factor(category, levels = colnames(data)[-1]),
      # 直接使用连续的x坐标，取消间隔
      x_pos = as.numeric(category)
    )
  
  # 创建热图
  p <- ggplot(long_data, aes(x = x_pos, y = location, fill = value)) +
    geom_tile(color = "white", linewidth = 0.5, width = 1.0) +
    geom_text(aes(label = sprintf("%.2e", value)), size = 4, color = "black") +
    scale_fill_gradient(low = "#fff0f0",        # 低值：白色
                        high = "#c11b1b",     # 高值：深红色
                        labels = function(x) sprintf("%.2e", x)) +
    scale_x_continuous(
      breaks = unique(long_data$x_pos),
      labels = levels(long_data$category),
      expand = c(0, 0.6)
    ) +
    labs(x = NULL, 
         y = "Population",
         title = "Estimated Carrier Frequencies of PKD") +##Estimated Prevalence of PKD, Allele Frequency of PKD-associated Variants
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, face = "bold", size = 12),
      axis.text.y = element_text(face = "bold", size = 12),
      axis.title.x = element_text(face = "bold", size = 14),
      axis.title.y = element_text(face = "bold", size = 14),
      plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
      legend.text = element_text(face = "bold", size = 12),
      legend.title = element_text(face = "bold", size = 14),
      panel.grid = element_blank(),
      axis.line = element_line(color = "black"),
      panel.border = element_blank(),
      # 添加坐标轴刻度线
      axis.ticks = element_line(color = "black", linewidth = 0.2),
      axis.ticks.length = unit(0.15, "cm")
    ) +
    coord_fixed(ratio = 0.6)
  
  # 生成输出文件名（将输入文件的.xlsx替换为.pdf）
  output_file <- sub("\\.xlsx$", ".pdf", file)
  
  # 保存PDF
  ggsave(output_file, plot = p, width = 8, height = 6, dpi = 300)
  
  # 打印处理进度
  message(sprintf("已处理文件: %s -> 输出: %s", file, output_file))
}

message("所有文件处理完成！")