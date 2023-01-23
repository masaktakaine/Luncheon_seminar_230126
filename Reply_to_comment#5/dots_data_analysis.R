library(tidyverse)
library(readxl)     
library(openxlsx) 
library(readr)
library(ggpmisc)  ## 回帰直線に数式を表示するためのライブラリ
library(patchwork)

dots_data <- read_csv("results.csv")
dots_data <- dots_data %>% rename(dot_id = ...1)
typeof(dots_data$roi_numbers)
dots_data$roi_numbers <- as.factor(dots_data$roi_numbers)

# Calculate statistics of each dot parameters --------------------------------------------------------
dot_parm_stat <- dots_data %>% 
  dplyr::select(roi_numbers,raw_roi_means,foci_serial:foci_intdens) %>% 
  group_by(roi_numbers) %>% 
  summarise_all(list(mean=mean,sd=sd,max=max,min=min,sum=sum,N=~n()))

# analysis of dot_area ---------------------------------------------------
limits_areas <- aes(ymax = foci_areas_mean + foci_areas_sd, ymin = foci_areas_mean - foci_areas_sd)
p_areas <- dot_parm_stat %>% 
  ggplot(aes(x=roi_numbers, y=foci_areas_mean))+
  geom_bar(aes(fill=roi_numbers),stat="identity", color="black",width = 0.5, position = position_dodge(width = 0.6))+ 
  geom_errorbar(limits_areas, width = 0.2, position = position_dodge(width=0.6))+ 
  geom_jitter(dots_data,mapping=aes(x=roi_numbers, y=foci_areas), size = 1,
              alpha=0.8, width = 0.1, height = 0)+
  ylab("Area of dot") +   
  # xlab("")+                  
  # ylim(0,160)+                
  theme( axis.title.y = element_text(size=14), axis.text.y = element_text(size=14,color = "black"),
         axis.title.x = element_text(size=14), axis.text.x = element_text(size=14,color = "black")
         ,legend.position = "none" #凡例を消す
         ,panel.border = element_rect(fill = NA, size = 0.5)
         ,panel.background = element_blank())

# analysis of dot_meanints ----------------------------------------------------
limits_meanints <- aes(ymax = foci_meanints_mean + foci_meanints_sd, ymin = foci_meanints_mean - foci_meanints_sd)
p_meanints <- dot_parm_stat %>% 
  ggplot(aes(x=roi_numbers, y=foci_meanints_mean))+
  geom_bar(aes(fill=roi_numbers),stat="identity", color="black",width = 0.5, position = position_dodge(width = 0.6))+ 
  geom_errorbar(limits_meanints, width = 0.2, position = position_dodge(width=0.6))+ 
  geom_jitter(dots_data,mapping=aes(x=roi_numbers, y=foci_meanints), size = 1,
              alpha=0.8, width = 0.1, height = 0)+
  # ダイヤでバックグラウンド値を示す
  geom_point(data=dot_parm_stat,aes(x=roi_numbers, y= raw_roi_means_mean, fill=roi_numbers), color = "black",shape = 23, size=3)+
  ylab("Mean density of dot") +   ## y軸のラベル
  # xlab("")+                   ## x軸のラベル
  # ylim(0,160)+                  ## y軸のレンジ
  theme( axis.title.y = element_text(size=14), axis.text.y = element_text(size=14,color = "black"),
         axis.title.x = element_text(size=14), axis.text.x = element_text(size=14,color = "black")
         #axis.text.x = element_markdown(size = 16,colour = "black")  ## ggtextを使用する場合はelement_markdownで指定
         ,legend.position = "none" #凡例を消す
         ,panel.border = element_rect(fill = NA, size = 0.5)# パネルを枠で囲む
         ,panel.background = element_blank())#背景をシロにする

# analysis of dot_intdens ------------------------------------------------
limits_intdens <- aes(ymax = foci_intdens_mean + foci_intdens_sd, ymin = foci_intdens_mean - foci_intdens_sd) 
p_intdens <- dot_parm_stat %>% 
  ggplot(aes(x=roi_numbers, y=foci_intdens_mean))+
  geom_bar(aes(fill=roi_numbers),stat="identity", color="black",width = 0.5, position = position_dodge(width = 0.6))+ 
  geom_errorbar(limits_intdens, width = 0.2, position = position_dodge(width=0.6))+ 
  geom_jitter(dots_data,mapping=aes(x=roi_numbers, y=foci_intdens), size = 1,
              alpha=0.8, width = 0.1, height = 0)+
  ylab("Integrated density of dot")+
  # xlab("")+                   ## x軸のラベル
  # ylim(0,160)+                  ## y軸のレンジ
  theme( axis.title.y = element_text(size=14), axis.text.y = element_text(size=14,color = "black"),
         axis.title.x = element_text(size=14), axis.text.x = element_text(size=14,color = "black")
         #axis.text.x = element_markdown(size = 16,colour = "black")  ## ggtextを使用する場合はelement_markdownで指定
         ,legend.position = "none" #凡例を消す
         ,panel.border = element_rect(fill = NA, size = 0.5)# パネルを枠で囲む
         ,panel.background = element_blank())#背景をシロにする


# correlation between area and meanints -----------------------------------
p_area_vs_meanints <- dots_data %>% 
  ggplot(aes(x=foci_areas, y=foci_meanints))+
           geom_point(aes(color=roi_numbers),size=1)+
  geom_smooth(method = lm, se = T)+
  stat_poly_eq(aes(label=paste(stat(eq.label), stat(rr.label), sep = "~~~")),parse = T,size=3)+ #チルダ~はスペースを表す
    ylab("Mean density of dot")+
    xlab("Area of dot")+
  theme( axis.title.y = element_text(size=14), axis.text.y = element_text(size=14,color = "black"),
         axis.title.x = element_text(size=14), axis.text.x = element_text(size=14,color = "black")
         #axis.text.x = element_markdown(size = 16,colour = "black")  ## ggtextを使用する場合はelement_markdownで指定
         # ,legend.position = "none" #凡例を消す
         ,panel.border = element_rect(fill = NA, size = 0.5)# パネルを枠で囲む
         ,panel.background = element_blank())#背景をシロにする

(p_areas + p_meanints) / (p_intdens + p_area_vs_meanints)
