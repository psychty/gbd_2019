library(easypackages)

options(scipen = 999)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", 'jsonlite'))

compare_df <- read_csv('./gbd_2019/Source_files/rate_compare_level_2_by_sex.csv') %>% 
  rename(Area = location,
         Lower_estimate = lower,
         Upper_estimate = upper,
         Rate_estimate = val,
         Year = year,
         Cause = cause,
         Measure = measure,
         Sex = sex,
         Age = age) %>%
  filter(metric == 'Rate') %>% 
  filter(Sex == 'Both') %>% 
  select(Area, Cause, Measure, Age, Year, Rate_estimate, Lower_estimate, Upper_estimate)

compare_df_number <- read_csv('./gbd_2019/Source_files/rate_compare_level_2_by_sex.csv') %>% 
  rename(Area = location,
         Lower_estimate = lower,
         Upper_estimate = upper,
         Number_estimate = val,
         Year = year,
         Cause = cause,
         Measure = measure,
         Sex = sex,
         Age = age) %>%
  filter(metric == 'Number') %>% 
  filter(Sex == 'Both') %>% 
  select(Area, Cause, Measure, Age, Year, Number_estimate)

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
  left_join(south_east_df, by = c('Cause', 'Measure', 'Year', 'Age')) %>% 
  left_join(eng_df, by = c('Cause', 'Measure', 'Year', 'Age')) %>%
  mutate(Compare_SE = ifelse(Lower_estimate > SE_upper, 'higher', ifelse(Upper_estimate < SE_lower, 'lower', 'similar'))) %>% 
  mutate(Compare_Eng = ifelse(Lower_estimate > Eng_upper, 'higher', ifelse(Upper_estimate < Eng_lower, 'lower', 'similar'))) %>%
  bind_rows(subset(compare_df, Area %in% c('South East England', 'England'))) %>% 
  left_join(compare_df_number, by = c('Area','Cause', 'Measure', 'Year', 'Age')) %>% 
  mutate(label = paste0(format(round(Rate_estimate, 1), big.mark = ',', trim = TRUE), ' (', format(round(Lower_estimate,1),big.mark = ',', trim = TRUE), '-', format(round(Upper_estimate,1),big.mark = ',', trim = TRUE), ')')) %>% 
  select(Area, Age, Cause, Measure, Year, Rate_estimate, Number_estimate, Lower_estimate, Upper_estimate, Compare_SE, Compare_Eng, label) %>% 
  bind_rows(data.frame(Area = rep(c('West Sussex', 'England', 'South East England'), 11), Cause = rep("Sense organ diseases", 11 * 3), Year = rep(seq(2009, 2019, 1), 3), Rate_estimate = 0, label = 'No estimate', Measure = 'Deaths', Age = 'All ages')) %>% 
  bind_rows(data.frame(Area = rep(c('West Sussex', 'England', 'South East England'), 11), Cause = rep("Sense organ diseases", 11 * 3), Year = rep(seq(2009, 2019, 1), 3), Rate_estimate = 0, label = 'No estimate', Measure = 'YLLs (Years of Life Lost)', Age = 'All ages')) %>% 
  bind_rows(data.frame(Area = rep(c('West Sussex', 'England', 'South East England'), 11), Cause = rep("Sense organ diseases", 11 * 3), Year = rep(seq(2009, 2019, 1), 3), Rate_estimate = 0, label = 'No estimate', Measure = 'Deaths', Age = 'Age-standardized')) %>% 
  bind_rows(data.frame(Area = rep(c('West Sussex', 'England', 'South East England'), 11), Cause = rep("Sense organ diseases", 11 * 3), Year = rep(seq(2009, 2019, 1), 3), Rate_estimate = 0, label = 'No estimate', Measure = 'YLLs (Years of Life Lost)', Age = 'Age-standardized')) %>% 
  mutate(Age = ifelse(Age == 'Age-standardized', 'Age standardised', Age)) %>% 
  arrange(Area, Cause, Measure, Age, Year)

wsx_df %>% 
  toJSON() %>% 
  write_lines('./gbd_2019/Outputs/rate_compare_timeseries.json')
