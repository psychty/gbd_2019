library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", 'jsonlite'))

compare_df <- read_csv('./gbd_2019/Source_files/rate_compare_level_2.csv') %>% 
  rename(Area = location_name,
         Lower_estimate = lower,
         Upper_estimate = upper,
         Rate_estimate = val,
         Year = year,
         Cause = cause_name,
         Measure = measure_name) %>%
  filter(metric_name == 'Rate') %>% 
  select(Area, Cause, Measure, Year, Rate_estimate, Lower_estimate, Upper_estimate)

eng_df <- compare_df %>% 
  filter(Area == 'England') %>% 
  rename(Eng_lower = Lower_estimate,
         Eng_upper = Upper_estimate) %>% 
  select(!c(Rate_estimate, Area))

south_east_df <- compare_df %>% 
  filter(Area == 'South East England') %>% 
  rename(SE_lower = Lower_estimate,
         SE_upper = Upper_estimate) %>% 
  select(!c(Rate_estimate, Area))

wsx_df <- compare_df %>% 
  filter(Area == 'West Sussex') %>% 
  left_join(south_east_df, by = c('Cause', 'Measure', 'Year')) %>% 
  left_join(eng_df, by = c('Cause', 'Measure', 'Year')) %>% 
  mutate(Compare_SE = ifelse(Lower_estimate > SE_upper, 'higher', ifelse(Upper_estimate < SE_lower, 'lower', 'similar'))) %>% 
  mutate(Compare_Eng = ifelse(Lower_estimate > Eng_upper, 'higher', ifelse(Upper_estimate < Eng_lower, 'lower', 'similar'))) %>%
  bind_rows(subset(compare_df, Area %in% c('South East England', 'England'))) %>% 
  mutate(label = paste0(round(Rate_estimate, 1), ' (', round(Lower_estimate,1), '-', round(Upper_estimate,1), ')')) %>% 
  select(Area, Cause, Measure, Year, Rate_estimate, Compare_SE, Compare_Eng, label)


wsx_df %>% 
  toJSON() %>% 
  write_lines('./gbd_2019/Outputs/rate_compare_timeseries.json')
