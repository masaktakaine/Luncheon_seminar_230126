library(tidyverse)
library(readxl)
library(stringr)

a_objects_data <- read.csv("ObjectsMeasuresResults-A.csv") # ImageAで検出されたオブジェクトの情報
b_objects_data <- read.csv("ObjectsMeasuresResults-B.csv") # ImageBで検出されたオブジェクトの情報
coloc_res <- read.csv("ColocResults.csv") # 共局在すると判定されたオブジェクトの組の情報

# 共局在の組を表す「Label」からオブジェクトA,Bのbasenameを抽出
coloc_res <- coloc_res %>%
  separate(col = "Label", c("Obj-A","Obj-B"), sep = "_", remove = F) %>% 
  mutate(`Obj-A` = str_remove(`Obj-A`, "obj")) %>% 
  mutate(`Obj-B` = str_remove(`Obj-B`, "obj")) %>% 
  rename(Label.coloc = Label)

# 同様にLabelからbasenameを抽出
a_objects_data <- a_objects_data %>% 
  mutate(basename = str_remove(str_remove(Label, "-"), "Obj")) %>% 
  select(basename, everything()) %>% 
  rename(Label.a = Label)
  
b_objects_data <- b_objects_data %>% 
  mutate(basename = str_remove(str_remove(Label, "-"), "Obj")) %>% 
  select(basename, everything()) %>% 
  rename(Label.b = Label)

# left_joinでbasenameが一致する行の情報をcoloc_resに追加
coloc_res <- coloc_res %>% 
  left_join(a_objects_data, by = c("Obj-A"="basename")) %>% 
  left_join(b_objects_data, by = c("Obj-B"="basename"), suffix =c(".a", ".b"))

# 面積比を計算
coloc_res <- coloc_res %>% 
  mutate(Vol.pixel.ratio.a_b = Volume..pixel..a/Volume..pixel..b, Vol.pixel.ratio.b_a = Volume..pixel..b/Volume..pixel..a)
