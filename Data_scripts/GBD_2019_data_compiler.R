
library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "png", "tidyverse", "reshape2", "scales", "viridis", "rgdal", "officer", "flextable", "tmaptools", "lemon", "fingertipsR", "jsonlite"))

setwd('~/GitHub/gbd_2019/')

data_directory <- './Source_files/Raw'
output_directory <- './Outputs'
meta_directory <- './Source_files'

# download.file('http://ghdx.healthdata.org/sites/default/files/ihme_query_tool/IHME_GBD_2019_CODEBOOK.zip', destfile = paste0(meta_directory, '/codebook.zip'), mode = 'wb')
# unzip(paste0(meta_directory, '/codebook.zip'), exdir = meta_directory)

list.files('./Source_files')

codebook <- read_csv(paste0(meta_directory,'/IHME_GBD_2019_CODEBOOK_Y2020M11D25.csv'))

cause_hierarchy <- read_excel(paste0(meta_directory, '/IHME_GBD_2019_CAUSE_HIERARCHY_Y2020M11D25.xlsx'))

cause_hierarchy %>% 
  filter(Level == 3) %>% 
  view()

wsx_ranks_compare <- fromJSON(paste0(output_directory, '/wsx_ranks_df.json')) %>% 
  filter(sex == 'Both',
         metric == 'Number')

wsx_df <- unique(list.files("~/gbd_data")[grepl("Cause_", list.files("~/gbd_data")) == TRUE]) %>%
  map_df(~read_csv(paste0("~/gbd_data/",.)))

wsx_yll <- wsx_df %>% 
  filter(measure_name == 'YLLs (Years of Life Lost)')

wsx_daly <- wsx_df %>% 
  filter(measure_name == 'DALYs (Disability-Adjusted Life Years)')

wsx_yld <- wsx_df %>% 
  filter(measure_name == 'YLDs (Years Lived with Disability)')

wsx_deaths <- wsx_df %>% 
  filter(measure_name == 'Deaths')

wsx_incidence <- wsx_df %>% 
  filter(measure_name == 'Incidence')

wsx_prevalence <- wsx_df %>% 
  filter(measure_name == 'Prevalence')

nrow(wsx_yll) + nrow(wsx_daly) + nrow(wsx_yld) + nrow(wsx_deaths) + nrow(wsx_incidence) + nrow(wsx_prevalence)

wsx_df %>% 
  select(measure_name, location_name, sex_name, age_name, cause_id, cause_name, metric_name, year, val) %>%
  rename(Name = location_name,
         Sex = sex_name,
         Age = age_name,
         Cause = cause_name,
         Year = year,
         Measure = measure_name) %>% 
  left_join(cause_hierarchy[c('Cause ID', 'Level')], by = c('cause_id' = 'Cause ID')) %>% 
  filter(Level == 2) %>% 
  filter(Age == 'All Ages') %>% 
  pivot_wider(names_from = 'metric_name',
              values_from = 'val') %>% 
  group_by(Measure, Name, Sex, Age, Year) %>% 
  mutate(Number_rank = rank(desc(Number))) %>% 
  filter(Number_rank <= 10) %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory, '/top_ten_wsx.json'))

# Life expectancy
le_raw <- read_csv('https://raw.githubusercontent.com/psychty/gbd_2019/ecd33659ad73f41d90e9296cc3d55da3555e420d/Source_files/Raw/Life_expectancy_SE_2019.csv')
hale_raw <- read_csv('https://raw.githubusercontent.com/psychty/gbd_2019/ecd33659ad73f41d90e9296cc3d55da3555e420d/Source_files/Raw/Health_Adjusted_Life_expectancy_SE_2019.csv')

le_raw %>% 
  filter(location == 'South East England') %>% 
  filter(year %in% c(1990, 2019)) %>% 
  filter(sex != 'Both') %>% 
  filter(age == '<1 year') %>% 
  select(sex, year, val) %>% 
  pivot_wider(values_from = val,
              names_from = year)

le_wsx <- le_raw %>% 
  filter(location == 'West Sussex') %>% 
  filter(age == '<1 year') %>% 
  select(location, sex, year, val) %>% 
  rename(Name = location,
         Sex = sex,
         Year = year,
         LE = val)

hale_wsx <- hale_raw %>% 
  filter(location == 'West Sussex') %>% 
  filter(age == '<1 year') %>% 
  select(location, sex, year, val) %>% 
  rename(Name = location,
         Sex = sex,
         Year = year,
         HALE = val)

le_wsx %>% 
  left_join(hale_wsx, by = c('Name', 'Sex', 'Year')) %>% 
  mutate(Sub_optimal_health = LE - HALE) %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory, '/le_wsx.json'))

# Population ####

population_df <- unique(list.files("~/gbd_data/Population")) %>%
  map_df(~read_csv(paste0("~/gbd_data/Population/",.))) %>% 
  select(location_name, sex_name, age_group_name, year_id, val, upper, lower) %>% 
  filter(location_name == 'West Sussex') %>% 
  filter(age_group_name %in% c('Early Neonatal', 'Late Neonatal', 'Post Neonatal', '1 to 4', '5 to 9', "10 to 14","15 to 19","20 to 24", "25 to 29","30 to 34","35 to 39","40 to 44", "45 to 49", "50 to 54", "55 to 59", "60 to 64", "65 to 69", "70 to 74", "75 to 79", "80 plus",'All Ages'))

All_age_pop <- population_df %>% 
  filter(age_group_name == 'All Ages') %>% 
  select(location_name, sex_name, age_group_name, year_id, val) %>% 
  pivot_wider(names_from = 'sex_name',
              values_from = 'val')

All_age_pop %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory, '/wsx_population.json'))

# comparisons ####

comparison_label_df_1 <- unique(list.files("~/gbd_data")[grepl("Comparison", list.files("~/gbd_data")) == TRUE]) %>%
  map_df(~read_csv(paste0("~/gbd_data/",.))) %>% 
  select(measure, location, sex, cause, metric, year, val) %>% 
  mutate(val = ifelse(metric == 'Percent', paste0(ifelse(val * 100 < 0.01, '<0.01', ifelse(val * 100 < 0.1, '<0.1', round(val * 100, 1))), '%'), paste0(ifelse(val == 0, 0, ifelse(val < 0.01, '<0.01', ifelse(val < 0.05, '<0.05', format(round(val, 1), big.mark = ',', trim = TRUE))))))) %>% 
  pivot_wider(names_from = 'metric',
              values_from = 'val')

comparison_rate_label_df_2 <- unique(list.files("~/gbd_data")[grepl("Comparison", list.files("~/gbd_data")) == TRUE]) %>%
  map_df(~read_csv(paste0("~/gbd_data/",.))) %>% 
  filter(metric == 'Rate') %>% 
  mutate(rate_label = paste0(ifelse(val == 0, 0, ifelse(val < 0.01, '<0.01', ifelse(val < 0.05, '<0.05', format(round(val, 1), big.mark = ',', trim = TRUE)))), ' (', ifelse(lower == 0, 0, ifelse(lower < 0.01, '<0.01', ifelse(lower < 0.05, '<0.05', format(round(lower, 1), big.mark = ',', trim = TRUE)))), '-', ifelse(upper == 0, 0, ifelse(upper < 0.01, '<0.01', ifelse(upper < 0.05, '<0.05', format(round(upper, 1), big.mark = ',', trim = TRUE)))), ')')) %>% 
  select(measure, location, sex, cause, year, rate_label)

comparison_label_df_3 <- unique(list.files("~/gbd_data")[grepl("Comparison", list.files("~/gbd_data")) == TRUE]) %>%
  map_df(~read_csv(paste0("~/gbd_data/",.))) %>% 
  left_join(cause_hierarchy[c('Cause Name', 'Level')], by = c('cause' = 'Cause Name')) %>% 
  select(measure, location, sex, cause, metric, year, Level, val) %>% 
  group_by(measure, location, sex, metric, year, Level) %>% 
  mutate(Rank = rank(desc(val))) 

ranks_df_1 <- comparison_label_df_3 %>% 
  filter(Level == 2) %>% 
  filter(year %in% c(2019)) %>% 
  filter(metric != 'Percent') %>% 
  filter(location == 'West Sussex') %>% 
  mutate(measure = paste0(measure, '_rank')) %>% 
  select(measure, location, sex, cause, metric, year, Level, Rank) %>% 
  pivot_wider(names_from = 'measure',
              values_from = 'Rank') 

ranks_df_2 <- comparison_label_df_3 %>% 
  filter(Level == 2) %>% 
  filter(year %in% c(2019)) %>% 
  filter(metric != 'Percent') %>% 
  filter(location == 'West Sussex') %>% 
  mutate(measure = paste0(measure, '_value')) %>% 
  select(measure, location, sex, cause, metric, year, Level, val) %>% 
  pivot_wider(names_from = 'measure',
              values_from = 'val') 

ranks_df <- ranks_df_1 %>% 
  left_join(ranks_df_2, by = c('location', 'sex', 'cause', 'metric', 'year', 'Level'))

ranks_df %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory, '/wsx_ranks_df.json'))

comparison_label_df <- comparison_label_df_1 %>% 
  left_join(comparison_rate_label_df_2, by = c('measure', 'location', 'sex', 'cause', 'year'))

comparison_df <- unique(list.files("~/gbd_data")[grepl("Comparison", list.files("~/gbd_data")) == TRUE]) %>%
  map_df(~read_csv(paste0("~/gbd_data/",.))) %>% 
  filter(metric == 'Rate') %>% 
  pivot_longer(cols = c('lower', 'upper'),
               names_to = 'Bounds') %>% 
  mutate(Bounds = paste(gsub(' ', '_', location), Bounds, sep = '_')) %>% 
  select(!c(val, location)) %>% 
  pivot_wider(names_from = 'Bounds',
              values_from = 'value') %>% 
  mutate(West_Sussex_SE_significance = ifelse(West_Sussex_lower > South_East_England_upper, 'Significantly higher', ifelse(West_Sussex_upper < South_East_England_lower, 'Significantly lower', 'Similar'))) %>% 
  mutate(West_Sussex_Eng_significance = ifelse(West_Sussex_lower > England_upper, 'Significantly higher', ifelse(West_Sussex_upper < England_lower, 'Significantly lower', 'Similar')))


final_comparison_df <- comparison_label_df %>% 
  filter(location == 'West Sussex') %>% 
  left_join(comparison_df[c('measure', 'sex', 'cause', 'year', 'West_Sussex_SE_significance', 'West_Sussex_Eng_significance')], by = c('measure', 'sex', 'cause', 'year')) %>% 
  mutate(Age = 'All ages') %>% 
  rename(Sex = sex,
         Cause = cause,
         Year = year,
         Area = location,
         Measure = measure)

final_comparison_df %>% 
  left_join(cause_hierarchy[c('Cause Name', 'Level')], by = c('Cause' = 'Cause Name')) %>% 
  filter(Year %in% seq(2009, 2019, 1)) %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory, '/wsx_compare_df.json'))


# change over time ####

change_over_time_df_1 <- wsx_df %>% 
  filter(year %in% c(2009, 2019)) %>% 
  filter(metric_name == 'Rate') %>% 
  left_join(cause_hierarchy[c('Cause Name', 'Level')], by = c('cause_name' = 'Cause Name')) %>% 
  filter(Level == 2) %>% 
  filter(age_name == 'All Ages') %>% 
  filter(sex_name == 'Both') %>% 
  filter(measure_name %in% c('Deaths', 'YLLs (Years of Life Lost)', 'YLDs (Years Lived with Disability)', 'DALYs (Disability-Adjusted Life Years)')) %>% 
  select(measure_name, year, cause_name, val, lower, upper) %>% 
  pivot_longer(cols = c(lower, val, upper), 
               names_to = 'component',
               values_to = 'value') %>%
  mutate(component_year = paste0(component, '_', year)) %>% 
  select(!c(component, year)) %>% 
  pivot_wider(names_from = component_year,
              values_from = value) %>% 
  mutate(Rate_change_significance = ifelse(lower_2019 > upper_2009, 'Significantly higher', ifelse(upper_2019 < lower_2009, 'Significantly lower', 'Similar'))) %>% 
  mutate(Rate_change_direction = ifelse(val_2019 > val_2009, 'Increase', ifelse(val_2019 < val_2009, 'Decrease', 'No change'))) %>% 
  mutate(Percentage_change_on_rate = (val_2019 - val_2009) / val_2009) %>% 
  mutate(rate_label = paste0(ifelse(val_2019 == 0, 0, ifelse(val_2019 < 0.01, '<0.01', ifelse(val_2019 < 0.05, '<0.05', format(round(val_2019, 1), big.mark = ',', trim = TRUE)))), ' (', ifelse(lower_2019 == 0, 0, ifelse(lower_2019 < 0.01, '<0.01', ifelse(lower_2019 < 0.05, '<0.05', format(round(lower_2019, 1), big.mark = ',', trim = TRUE)))), '-', ifelse(upper_2019 == 0, 0, ifelse(upper_2019 < 0.01, '<0.01', ifelse(upper_2019 < 0.05, '<0.05', format(round(upper_2019, 1), big.mark = ',', trim = TRUE)))), ')')) %>% 
  select(measure_name, cause_name, rate_label, Rate_change_direction, Rate_change_significance, val_2009, val_2019, Percentage_change_on_rate)

change_over_time_df_2 <- wsx_df %>% 
  filter(year %in% c(2009, 2019)) %>% 
  filter(metric_name == 'Number') %>% 
  left_join(cause_hierarchy[c('Cause Name', 'Level')], by = c('cause_name' = 'Cause Name')) %>% 
  filter(Level == 2) %>% 
  filter(age_name == 'All Ages') %>% 
  filter(sex_name == 'Both') %>% 
  filter(measure_name %in% c('Deaths', 'YLLs (Years of Life Lost)', 'YLDs (Years Lived with Disability)', 'DALYs (Disability-Adjusted Life Years)')) %>% 
  select(measure_name, year, cause_name, val) %>% 
  pivot_wider(names_from = year,
              values_from = val) %>% 
  mutate(Count_direction = ifelse(`2019` > `2009`, 'Increase', ifelse(`2019` < `2009`, 'Decrease', 'No change'))) %>% 
  mutate(Percentage_change_on_numbers = (`2019` - `2009`) / `2009`) %>% 
  select(measure_name, cause_name, Count_direction, `2009`, `2019`, Percentage_change_on_numbers) %>% 
  rename(Count_2009 = `2009`,
         Count_2019 = `2019`)

change_over_time_df <- change_over_time_df_2 %>% 
  left_join(change_over_time_df_1, by = c('measure_name', 'cause_name'))

change_over_time_df %>% 
  mutate(cause_name = factor(cause_name, levels = c('HIV/AIDS and sexually transmitted infections', 'Respiratory infections and tuberculosis', 'Enteric infections', 'Neglected tropical diseases and malaria', 'Other infectious diseases', 'Maternal and neonatal disorders', 'Nutritional deficiencies', 'Neoplasms', 'Cardiovascular diseases', 'Chronic respiratory diseases', 'Digestive diseases', 'Neurological disorders', 'Mental disorders', 'Substance use disorders', 'Diabetes and kidney diseases', 'Skin and subcutaneous diseases', 'Sense organ diseases', 'Musculoskeletal disorders', 'Other non-communicable diseases', 'Transport injuries', 'Unintentional injuries', 'Self-harm and interpersonal violence'))) %>% 
  arrange(cause_name) %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory, '/change_over_time_df_wsx.json'))




# Mortality ####
# wsx_deaths %>% 
#   select(measure_name, location_name, sex_name, age_name, cause_id, cause_name, metric_name, year, val, upper, lower) %>% 
#   left_join(cause_hierarchy[c('Cause ID', 'Level')], by = c('cause_id' = 'Cause ID')) %>% 
#   filter(Level == 2) %>% 
#   view()
#   write_rds(., paste0(data_directory, '/wsx_level_2_deaths.rds'))

top_ten <- wsx_deaths %>% 
  select(measure_name, location_name, sex_name, age_name, cause_id, cause_name, metric_name, year, val) %>%
  rename(Name = location_name,
         Sex = sex_name,
         Age = age_name,
         Cause = cause_name,
         Year = year) %>% 
  left_join(cause_hierarchy[c('Cause ID', 'Level')], by = c('cause_id' = 'Cause ID')) %>% 
  filter(Level == 2) %>% 
  filter(Age == 'All Ages') %>% 
  pivot_wider(names_from = 'metric_name',
              values_from = 'val') %>% 
  group_by(Name, Sex, Age, Year) %>% 
  mutate(Number_rank = rank(desc(Number))) %>% 
  filter(Number_rank <= 10)

top_ten %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory, '/top_ten_mortality_wsx.json'))

# top_ten_cause_two_overall_burden ####

top_ten_cause_two_overall_burden <- wsx_df %>% 
  filter(year %in% c(2019)) %>% 
  filter(metric_name == 'Number') %>% 
  filter(location_name == 'West Sussex') %>% 
  left_join(cause_hierarchy[c('Cause Name', 'Level')], by = c('cause_name' = 'Cause Name')) %>% 
  filter(Level == 2) %>% 
  filter(age_name == 'All Ages') %>% 
  filter(measure_name %in% c('Deaths', 'YLLs (Years of Life Lost)', 'YLDs (Years Lived with Disability)', 'DALYs (Disability-Adjusted Life Years)')) %>% 
  select(measure_name, sex_name, cause_name, val) %>% 
  group_by(sex_name, measure_name) %>% 
  mutate(Rank = rank(desc(val))) %>% 
  filter(Rank <= 10) %>% 
  mutate(label = paste0(Rank, ') ', cause_name, ' (', format(round(val,0), big.mark = ',', trim = TRUE), ')')) %>%
  ungroup() %>% 
  select(sex_name, Rank, measure_name, label) %>% 
  pivot_wider(names_from = measure_name,
              values_from = label) %>% 
  arrange(sex_name, Rank)
  
top_ten_cause_two_overall_burden %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory, '/top_ten_cause_two_overall_burden.json'))

# level 3 bubbles
level_three_df <- wsx_df %>% 
  filter(year %in% c(2019)) %>% 
  filter(metric_name == 'Number') %>% 
  filter(location_name == 'West Sussex') %>% 
  left_join(cause_hierarchy[c('Cause Name', 'Level', 'Parent Name')], by = c('cause_name' = 'Cause Name')) %>% 
  filter(Level == 3) %>% 
  filter(age_name == 'All Ages') %>% 
  filter(measure_name %in% c('Deaths', 'YLLs (Years of Life Lost)', 'YLDs (Years Lived with Disability)', 'DALYs (Disability-Adjusted Life Years)')) %>% 
  rename(parent_cause = 'Parent Name') %>% 
  select(measure_name, sex_name, parent_cause, cause_name, val) %>% 
  filter(val > 0)
  

level_three_df %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory, '/level_three_df_cause.json'))
