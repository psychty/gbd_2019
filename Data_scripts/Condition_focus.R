# You need to download the Global Burden of Disease data manually - and the links expire after a time so it is impossible to automate the downloading (and I have tried a few ways).

options(scipen = 999)

# You cannot sum risk factor values across causes, but you can sum cause values across risk factors
library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "png", "tidyverse", "reshape2", "scales", "viridis", "rgdal", "officer", "flextable", "tmaptools", "lemon", "fingertipsR", "PHEindicatormethods", "jsonlite"))

Area_x = 'West Sussex'

read_csv('https://raw.githubusercontent.com/holtzy/D3-graph-gallery/master/DATA/data_connectedscatter.csv') %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/testies/line_point_ts.json'))

install.packages('sjmisc')
library(sjmisc)

dat <- data.frame(
  c1 = c(1, 2, 3, 1, 3, NA),
  c2 = c(3, 2, 1, 2, NA, 3),
  c3 = c(1, 1, 2, 1, 3, NA),
  c4 = c(1, 1, 3, 2, 1, 2),
  c5 = c('banana', 'dicks', 'soup', 'dicks', 'namam', 'banana'))

row_count(dat, count = 'dicks', append = FALSE)
row_count(dat, count = NA, append = FALSE)
row_count(dat, c1:c3, count = 2, append = TRUE)
# Incidence data published for 2017 - included in download
# Prevalence data published for 2017

GBD_2017_cause_hierarchy <- read_excel("~/Documents/GBD_data_download/IHME_GBD_2017_CAUSE_HIERARCHY_Y2018M11D18.xlsx", col_types = c("text", "text", "text", "text", "text", "numeric", "text", "text")) %>% 
  rename(Cause_name = cause_name,
         Cause_id = cause_id,
         Parent_id = parent_id,
         Cause_outline = cause_outline,
         Level = level)

Causes_in_each_level <- GBD_2017_cause_hierarchy %>% 
  select(Level) %>% 
  group_by(Level) %>% 
  summarise(n())

Condition_age <- unique(list.files("~/Documents/GBD_data_download")[grepl("b328ae1f", list.files("~/Documents/GBD_data_download/")) == TRUE]) %>% 
  map_df(~read_csv(paste0("~/Documents/GBD_data_download/",.), col_types = cols(measure = col_character(),location = col_character(),sex = col_character(),age = col_character(),cause = col_character(),metric = col_character(),year = col_double(),val = col_double(),upper = col_double(),lower = col_double()))) %>% 
  left_join(GBD_2017_cause_hierarchy[c("Cause_name", "Cause_outline", "Cause_id", "Parent_id", "Level")], by = c("cause" = "Cause_name")) %>% 
  left_join(GBD_2017_cause_hierarchy[c("Cause_name", "Cause_id")], by = c("Parent_id" = "Cause_id")) %>% 
  rename(`Cause group` = Cause_name,
         Area = location,
         Lower_estimate = lower,
         Upper_estimate = upper,
         Estimate = val,
         Year = year,
         Sex = sex,
         Age = age,
         Cause = cause,
         Measure = measure) %>% 
  mutate(Metric = ifelse(metric == "Rate", "Rate per 100,000 population", ifelse(metric == "Percent", "Proportion of total burden caused by this condition", metric))) %>% 
  mutate(Cause = factor(Cause, levels =  unique(Cause))) %>% 
  select(Area, Sex, Age, Year, Cause, Cause_outline, Cause_id, Level, Estimate, Lower_estimate, Upper_estimate, `Cause group`, Parent_id, Measure, Metric) %>% 
  filter(Age %in% c("Early Neonatal", "Late Neonatal",  "Post Neonatal",  "1 to 4", "5 to 9", "10 to 14", "15 to 19", "20 to 24", "25 to 29","30 to 34","35 to 39", "40 to 44","45 to 49","50 to 54","55 to 59","60 to 64","65 to 69","70 to 74","75 to 79", "80 to 84","85 to 89","90 to 94","95 plus")) %>%  
  mutate(Age = factor(Age, levels = c("Early Neonatal", "Late Neonatal",  "Post Neonatal",  "1 to 4", "5 to 9", "10 to 14", "15 to 19", "20 to 24", "25 to 29","30 to 34","35 to 39", "40 to 44","45 to 49","50 to 54","55 to 59","60 to 64","65 to 69","70 to 74","75 to 79", "80 to 84","85 to 89","90 to 94","95 plus"))) %>% 
  filter(Year %in% c(2007, 2012, 2017)) 

# Cause of mortality and morbidity ####
# This is 3.5 million records
All_ages_GBD_cause_data <- unique(list.files("~/Documents/GBD_data_download/")[grepl("e004c73d", list.files("~/Documents/GBD_data_download/")) == TRUE]) %>% 
  map_df(~read_csv(paste0("~/Documents/GBD_data_download/",.), col_types = cols(age = col_character(), cause = col_character(), location = col_character(), lower = col_double(), measure = col_character(), metric = col_character(), sex = col_character(), upper = col_double(), val = col_double(), year = col_number()))) %>% 
  filter(age != 'Age-standardized') %>% 
  rename(Area = location,
         Lower_estimate = lower,
         Upper_estimate = upper,
         Estimate = val,
         Year = year,
         Sex = sex,
         Age = age,
         Cause = cause) %>% 
  mutate(metric = ifelse(metric == "Rate", "Rate per 100,000 population", ifelse(metric == "Percent", "Proportion of total burden caused by this condition", metric))) %>% 
  left_join(GBD_2017_cause_hierarchy[c("Cause_name", "Cause_outline", "Cause_id", "Parent_id", "Level")], by = c("Cause" = "Cause_name")) %>% 
  left_join(GBD_2017_cause_hierarchy[c("Cause_name", "Cause_id")], by = c("Parent_id" = "Cause_id")) %>% 
  rename(`Cause group` = Cause_name) %>% 
  mutate(Cause = factor(Cause, levels =  unique(Cause))) %>% 
  select(Area, Sex, Year, Cause, Cause_outline, Cause_id, Level, Estimate, Lower_estimate, Upper_estimate, `Cause group`, Parent_id, measure, metric) %>% 
  filter(Area %in% c(Area_x, 'England')) %>% 
  filter(Level == 3) %>% 
  filter(!(measure %in% c('Incidence', 'Prevalence')))

Condition_number <- All_ages_GBD_cause_data %>% 
  filter(metric == "Number") %>% 
  filter(Year %in% c(2017, 2012, 2007)) %>% 
  group_by(measure, Year, Area, Sex) %>%   
  select(-c(Lower_estimate, Upper_estimate, Cause_outline, Cause_id, metric, Parent_id)) %>% 
  spread(measure, Estimate) %>% 
  ungroup() %>% 
  rename(YLL = `YLLs (Years of Life Lost)`) %>% 
  rename(YLD = `YLDs (Years Lived with Disability)`) %>% 
  rename(DALY = `DALYs (Disability-Adjusted Life Years)`) %>% 
  mutate(Deaths = replace_na(Deaths, 0)) %>% 
  mutate(YLL = replace_na(YLL, 0)) %>% 
  mutate(YLD = replace_na(YLD, 0)) %>% 
  mutate(DALY = replace_na(DALY, 0)) 

Condition_number <- All_ages_GBD_cause_data %>% 
  filter(metric == "Number") %>% 
  filter(Year %in% c(2017, 2012, 2007)) %>% 
  select(-c(Lower_estimate, Upper_estimate, Cause_outline, Cause_id, metric, Parent_id)) %>% 
  mutate(measure = ifelse(measure == 'YLLs (Years of Life Lost)', 'YLL', ifelse(measure == 'YLDs (Years Lived with Disability)', 'YLD', ifelse(measure == 'DALYs (Disability-Adjusted Life Years)', 'DALY', measure)))) %>% 
  mutate(Estimate = replace_na(Estimate, 0))
 
# level 3 condition infographic
# number deaths etc
Condition_a <- Condition_number %>% 
  select(Year, Sex, Cause, `Cause group`, measure, Estimate) %>% 
  group_by(measure, Cause) %>% 
  spread(Sex, Estimate) %>% 
  mutate(Male_prop = ifelse(Both == 0, 0, Male/ Both)) %>% 
  mutate(Female_prop = ifelse(Both == 0, 0, Female/Both)) %>% 
  rename(Male_number = Male,
         Female_number = Female,
         Total_number = Both) %>% 
  mutate(higher_sex = ifelse(Total_number == 0, 'No estimated burden', ifelse(Male_number > Female_number, 'Male', 'Female')))

# highest deaths age (can you get an average age of death by condition??)

# This is the 5 year age group with the highest burden in the year
Highest_age <- Condition_age %>% 
  filter(Metric == 'Number') %>% 
  select(Sex, Age, Year, Cause, Estimate, Measure) %>% 
  group_by(Sex, Year, Cause, Measure) %>% 
  mutate(Proportion =  Estimate / sum(Estimate)) %>% 
  filter(Estimate == max(Estimate)) %>% 
  mutate(Age = ifelse(Estimate == 0, 'No estimated burden', as.character(Age))) %>% 
  rename(Highest_age = Age) %>% 
  ungroup()

High <- Highest_age %>% 
  select(-Proportion) %>% 
  group_by(Year, Cause, Measure) %>% 
  spread(Sex, Estimate)

?spread()
# rate per 100,000 deaths, yll, yld daly
# rank of deaths DALYs
# compare DALY to England and SE
# change since 07 and 12
# number of level 3 risk factors associated to condition
# top 5 contributing risk factors (note overlap unknown)
# how much of the burden is not attributed to a risk factor

# cancer
cancer <- Condition_number %>% 
  filter(`Cause group` == 'Neoplasms')

unique(cancer$Cause)

# cvd
cvd <- Condition_number %>% 
  filter(`Cause group` == 'Cardiovascular diseases')

unique(cvd$Cause)

# msk
msk <- Condition_number %>% 
  filter(`Cause group` == 'Musculoskeletal disorders')

unique(msk$Cause)



# Rate is per 100,000 population
Age_standardised_NN_ts_data <- unique(list.files("~/Documents/GBD_data_download/")[grepl("85cc91d0", list.files("~/Documents/GBD_data_download/")) == TRUE]) %>% 
  map_df(~read_csv(paste0("~/Documents/GBD_data_download/",.), col_types = cols(age = col_character(), cause = col_character(), location = col_character(), lower = col_double(), measure = col_character(), metric = col_character(), sex = col_character(), upper = col_double(), val = col_double(), year = col_number()))) %>%
  filter(age == 'Age-standardized') %>%
  rename(Area = location,
         Lower_estimate = lower,
         Upper_estimate = upper,
         Estimate = val,
         Year = year,
         Sex = sex,
         Age = age,
         Cause = cause) %>%
  mutate(metric = ifelse(metric == "Rate", "Rate per 100,000 population", ifelse(metric == "Percent", "Proportion of total burden caused by this condition", metric))) %>% 
  left_join(GBD_2017_cause_hierarchy[c("Cause_name", "Cause_outline", "Cause_id", "Parent_id", "Level")], by = c("Cause" = "Cause_name")) %>% 
  left_join(GBD_2017_cause_hierarchy[c("Cause_name", "Cause_id")], by = c("Parent_id" = "Cause_id")) %>% 
  rename(`Cause group` = Cause_name) %>% 
  mutate(Cause = factor(Cause, levels =  unique(Cause))) %>% 
  select(Area, Sex, Year, Cause, Cause_outline, Cause_id, Level, Estimate, Lower_estimate, Upper_estimate, `Cause group`, Parent_id, measure, metric)


# Top ten causes (deaths, ylls, ylds, dalys) time series west sussex (NN - SE and England)

top_ten_wsx_level_2 <- Age_standardised_NN_ts_data %>% 
  filter(Level == 2) %>%
  filter(Area == 'West Sussex') %>% 
  filter(Year == 2017) %>% 
  filter(!(measure %in% c('Incidence', 'Prevalence'))) %>% 
  group_by(Sex, measure) %>% 
  mutate(Rank = rank(-Estimate)) %>% 
  filter(Rank <= 5) %>% 
  mutate(string_code = gsub(' ', '_', paste(Sex, Cause, measure, sep = '_')))

top_ten_ts <- Age_standardised_NN_ts_data %>% 
  filter(Level == 2) %>% 
  mutate(Cause = factor(Cause, levels = c("HIV/AIDS and sexually transmitted infections", "Respiratory infections and tuberculosis", "Enteric infections", "Neglected tropical diseases and malaria", "Other infectious diseases", "Maternal and neonatal disorders", "Nutritional deficiencies", "Neoplasms", "Cardiovascular diseases", "Chronic respiratory diseases", "Digestive diseases", "Neurological disorders", "Mental disorders", "Substance use disorders", "Diabetes and kidney diseases", "Skin and subcutaneous diseases", "Sense organ diseases", "Musculoskeletal disorders", "Other non-communicable diseases", "Transport injuries", "Unintentional injuries", "Self-harm and interpersonal violence"))) %>% 
  mutate(string_code = gsub(' ', '_', paste(Sex, Cause, measure, sep = '_'))) %>% 
  filter(string_code %in% c(top_ten_wsx_level_2$string_code)) %>% 
  select(Area, Sex, Year, Cause, Estimate, Lower_estimate, Upper_estimate, measure) %>% 
  mutate(string_code = gsub(' ', '_', paste(Sex, Cause, measure, Year, sep = '_'))) %>% 
  mutate(label_estimate = paste0(format(round(Estimate,0), big.mark = ',', trim = TRUE), ' (', format(round(Lower_estimate,0), big.mark = ',', trim = TRUE), '-', format(round(Upper_estimate,0), big.mark = ',', trim = TRUE), ')'))

se <- top_ten_ts %>% 
  filter(Area == 'South East England') %>% 
  rename(se_Estimate = Estimate,
         se_Lower_estimate = Lower_estimate,
         se_Upper_estimate = Upper_estimate,
         se_label = label_estimate)

eng <- top_ten_ts %>% 
  filter(Area == 'England') %>% 
  rename(eng_Estimate = Estimate,
         eng_Lower_estimate = Lower_estimate,
         eng_Upper_estimate = Upper_estimate,
         eng_label = label_estimate)

wsx <- top_ten_ts %>% 
  filter(Area == Area_x) %>% 
  left_join(se[c('string_code','se_Estimate','se_Lower_estimate', 'se_Upper_estimate', 'se_label')], by = 'string_code') %>% 
  left_join(eng[c('string_code','eng_Estimate','eng_Lower_estimate', 'eng_Upper_estimate', 'eng_label')], by = 'string_code') %>% 
  mutate(compare_se = ifelse(Lower_estimate > se_Upper_estimate, 'significantly higher than', ifelse(Upper_estimate < se_Lower_estimate, 'significantly lower than', 'statistically similar to'))) %>% 
  mutate(compare_eng = ifelse(Lower_estimate > eng_Upper_estimate, 'significantly higher than', ifelse(Upper_estimate < eng_Lower_estimate, 'significantly lower than', 'statistically similar to'))) %>% 
  mutate(label_1 = paste0('In West Sussex in ', Year, ' the age-standardised rate of ', ifelse(measure == 'Deaths', 'deaths', measure), ' caused by ', Cause, ' among ', ifelse(Sex == 'Both', 'both males and females', paste0(tolower(Sex), 's')), ' was ', label_estimate, ' per 100,000 population.')) %>% 
  mutate(label_2 = paste0('The rate of ', ifelse(measure == 'Deaths', 'deaths', measure), ' for this cause is ', compare_se, ' South East region (', se_label, ') and ', compare_eng, ' England ', eng_label, '')) %>% 
  select(Sex, Year, Cause, Estimate, measure, label_1, label_2)

wsx %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Rate_top_five_ts.json'))


