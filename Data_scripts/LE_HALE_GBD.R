
library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", "reshape2", "scales", "PHEindicatormethods", "xlsx", "janitor", "lubridate"))

LE <- read_csv('C:/Users/rtbp8900/Downloads/GBD_2017_LE.csv') %>% 
  rename('Area' = 'location',
         'Sex' = 'sex',
         'Year' = 'year') %>% 
  select(-c(metric))

LE_stacked <- read_csv('C:/Users/rtbp8900/Downloads/GBD_2017_LE.csv') %>% 
  rename('Area' = 'location',
         'Sex' = 'sex',
         'Year' = 'year') %>% 
  select(-c(metric, upper, lower)) %>% 
  group_by(Area, Sex, Year) %>% 
  spread(measure, val) %>% 
  mutate(Difference = `Life expectancy` - `HALE (Healthy life expectancy)`)

LE_change <- read_csv('C:/Users/rtbp8900/Downloads/GBD_2017_LE.csv') %>% 
  rename('Area' = 'location',
         'Sex' = 'sex',
         'Year' = 'year') %>% 
  filter(Year %in% c('2017', '2012', '2007', '2002','1997')) %>% 
  select(-c(metric, upper, lower)) %>% 
  group_by(Area, Sex, Year, measure) %>% 
  spread(Year, val) %>% 
  mutate(Change_9717 = `2017` - `1997`,
         Perc_change_9717 = (`2017` - `1997`) / `1997` *100,
         Direction_9717 = ifelse(Change_9717 > 0, 'Increase', ifelse(Change_9717 < 0, 'Decrease', 'Stayed the same')),
         Change_0717 = `2017` - `2007`,
         Perc_change_0717 = (`2017` - `2007`) / `2007` *100,
         Direction_0717 = ifelse(Change_0717 > 0, 'Increase', ifelse(Change_0717 < 0, 'Decrease', 'Stayed the same')),
         Change_1217 = `2017` - `2012`,
         Perc_change_1217 = (`2017` - `2012`) / `2012` *100,
         Direction_1217 = ifelse(Change_1217 > 0, 'Increase', ifelse(Change_1217 < 0, 'Decrease', 'Stayed the same'))) %>% 
  select(Area, Sex, measure, `1997`,  Change_9717, Perc_change_9717, Direction_9717, `2002`, `2007`, Change_0717, Perc_change_0717, Direction_0717, `2012`, Change_1217, Perc_change_1217, Direction_1217, `2017`)

write.csv(LE, './LE_GBD_timeseries.csv', row.names = FALSE)
write.csv(LE_stacked, './LE_GBD_timeseries_stacked.csv', row.names = FALSE)
write.csv(LE_change, './LE_GBD_change.csv', row.names = FALSE)


LE_change_difference <- LE_stacked %>% 
  select(Area, Sex, Year, Difference) %>% 
  filter(Year %in% c('2017', '2012', '2007', '2002','1997')) %>% 
  group_by(Area, Sex, Year) %>% 
  spread(Year, Difference) %>% 
  mutate(Change_9717 = `2017` - `1997`,
         Perc_change_9717 = (`2017` - `1997`) / `1997` *100,
         Direction_9717 = ifelse(Change_9717 > 0, 'Increase', ifelse(Change_9717 < 0, 'Decrease', 'Stayed the same')),
         Change_0717 = `2017` - `2007`,
         Perc_change_0717 = (`2017` - `2007`) / `2007` *100,
         Direction_0717 = ifelse(Change_0717 > 0, 'Increase', ifelse(Change_0717 < 0, 'Decrease', 'Stayed the same')),
         Change_1217 = `2017` - `2012`,
         Perc_change_1217 = (`2017` - `2012`) / `2012` *100,
         Direction_1217 = ifelse(Change_1217 > 0, 'Increase', ifelse(Change_1217 < 0, 'Decrease', 'Stayed the same'))) %>% 
  select(Area, Sex, `1997`,  Change_9717, Perc_change_9717, Direction_9717, `2002`, `2007`, Change_0717, Perc_change_0717, Direction_0717, `2012`, Change_1217, Perc_change_1217, Direction_1217, `2017`)

write.csv(LE_change_difference, './LE_GBD_change_difference.csv', row.names = FALSE)
