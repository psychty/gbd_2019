library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "png", "tidyverse", "reshape2", "scales", "viridis", "rgdal", "officer", "flextable", "tmaptools", "lemon", "fingertipsR", "PHEindicatormethods", "jsonlite"))

options(scipen = 999)

GBD_2017_rei_hierarchy <- read_excel("~/Documents/GBD_data_download/IHME_GBD_2017_REI_HIERARCHY_Y2018M11D18.xlsx", col_types = c("text", "text", "text", "text", "text", "numeric"))

# This is 1.2 million records
GBD_risk_data_wsx <- unique(list.files("~/Documents/GBD_data_download/Risk/")[grepl("efaea572", list.files("~/Documents/GBD_data_download/Risk/")) == TRUE]) %>% 
  map_df(~read_csv(paste0("~/Documents/GBD_data_download/Risk/",.), col_types = cols(age = col_character(), cause = col_character(), location = col_character(), lower = col_double(), measure = col_character(), metric = col_character(), sex = col_character(), upper = col_double(), val = col_double(), year = col_number()))) %>% 
  rename(Area = location,
         Lower_estimate = lower,
         Upper_estimate = upper,
         Estimate = val,
         Year = year,
         Sex = sex,
         Age = age,
         rei_name = rei,
         Cause_name = cause) %>% 
  mutate(metric = ifelse(metric == "Rate", "Rate per 100,000 population", ifelse(metric == "Percent", "Proportion of total burden caused by this condition", metric))) %>% 
  left_join(GBD_2017_rei_hierarchy[c('rei_name', 'parent_id', 'level')], by = 'rei_name') %>% 
  rename(Risk = rei_name,
         Risk_level = level) %>% 
  left_join(GBD_2017_rei_hierarchy[c('rei_id', 'rei_name')], by = c('parent_id' = 'rei_id')) %>%
  select(-parent_id) %>% 
  rename(`Risk group` = rei_name) %>% 
  left_join(GBD_2017_cause_hierarchy[c('Cause_name', 'Parent_id', 'Level')], by = 'Cause_name') %>% 
  rename(Cause = Cause_name) %>% 
  left_join(GBD_2017_cause_hierarchy[c('Cause_id', 'Cause_name')], by = c('Parent_id' = 'Cause_id')) %>% 
  rename(`Cause group` = Cause_name,
         Cause_level = Level) %>% 
  select(Area, Sex, Age, Year, Cause, `Cause group`, Cause_level, Risk, `Risk group`, Risk_level, measure, metric, Estimate, Lower_estimate, Upper_estimate)

GBD_risk_data_all_cause_NN <- unique(list.files("~/Documents/GBD_data_download/Risk/")[grepl("defcbaed", list.files("~/Documents/GBD_data_download/Risk/")) == TRUE]) %>% 
  map_df(~read_csv(paste0("~/Documents/GBD_data_download/Risk/",.), col_types = cols(age = col_character(), cause = col_character(), location = col_character(), lower = col_double(), measure = col_character(), metric = col_character(), sex = col_character(), upper = col_double(), val = col_double(), year = col_number()))) %>% 
  rename(Area = location,
         Lower_estimate = lower,
         Upper_estimate = upper,
         Estimate = val,
         Year = year,
         Sex = sex,
         Age = age,
         rei_name = rei,
         Cause = cause) %>% 
  mutate(metric = ifelse(metric == "Rate", "Rate per 100,000 population", ifelse(metric == "Percent", "Proportion of total burden caused by this condition", metric))) %>% 
  left_join(GBD_2017_rei_hierarchy[c('rei_name', 'parent_id', 'level')], by = 'rei_name') %>% 
  rename(Risk = rei_name,
         Risk_level = level) %>% 
  left_join(GBD_2017_rei_hierarchy[c('rei_id', 'rei_name')], by = c('parent_id' = 'rei_id')) %>%
  rename(`Risk group` = rei_name) %>% 
  select(Area, Sex, Age, Year, Cause, Risk, `Risk group`, Risk_level, measure, metric, Estimate, Lower_estimate, Upper_estimate)

level_1_risk_summary <- GBD_risk_data_all_cause_NN %>% 
  filter(Area == Area_x) %>% 
  filter(Year == 2017) %>% 
  filter(Risk_level == 1) %>% 
  filter(metric == 'Number') %>% 
  filter(Sex == 'Both')


ischemic_hd <- GBD_risk_data_wsx %>% 
  filter(Cause == 'Ischemic heart disease') %>% 
  filter(Area == Area_x) %>% 
  filter(Year == 2017) %>% 
  filter(Sex == 'Both')


Top_risks_2017_all_cause <- GBD_risk_data_all_cause_NN %>% 
  filter(Year == 2017) %>% 
  filter(Area == Area_x) %>% 
  filter((Age == 'Age-standardized') | (Age == 'All Ages' & metric == 'Number')) %>% 
  mutate(metric = ifelse(metric == 'Rate per 100,000 population', 'Age-standardised rate per 100,000', ifelse(metric == 'Number', 'Number (all ages)', NA)))

Risk_all_cause <- GBD_risk_data_all_cause_NN %>% 
  filter(Year == 2017)



Ischemic_risk_data_wsx <- unique(list.files("~/Documents/GBD_data_download/Risk/")[grepl("2fef4760", list.files("~/Documents/GBD_data_download/Risk/")) == TRUE]) %>% 
  map_df(~read_csv(paste0("~/Documents/GBD_data_download/Risk/",.), col_types = cols(age = col_character(), cause = col_character(), location = col_character(), lower = col_double(), measure = col_character(), metric = col_character(), sex = col_character(), upper = col_double(), val = col_double(), year = col_number()))) %>% 
  rename(Area = location,
         Lower_estimate = lower,
         Upper_estimate = upper,
         Estimate = val,
         Year = year,
         Sex = sex,
         Age = age,
         rei_name = rei,
         Cause = cause) %>% 
  left_join(GBD_2017_rei_hierarchy[c('rei_name', 'parent_id', 'level')], by = 'rei_name') %>% 
  rename(Risk = rei_name,
         Risk_level = level) %>% 
  left_join(GBD_2017_rei_hierarchy[c('rei_id', 'rei_name')], by = c('parent_id' = 'rei_id')) %>%
  rename(`Risk group` = rei_name) %>% 
  select(Area, Sex, Age, Year, Cause, Risk, `Risk group`, Risk_level, measure, metric, Estimate, Lower_estimate, Upper_estimate)


lv1_isch <- Ischemic_risk_data_wsx %>% 
  filter(Risk_level == 1)

lv1_isch <- 




