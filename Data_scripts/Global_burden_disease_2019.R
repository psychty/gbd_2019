
# This uses the easypackages package to load several libraries at once. Note: it should only be used when you are confident that all packages are installed as it will be more difficult to spot load errors compared to loading each one individually.
library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "png", "tidyverse", "reshape2", "scales", "viridis", "rgdal", "officer", "flextable", "tmaptools", "lemon", "fingertipsR", "PHEindicatormethods", "jsonlite"))

Area_x <- "West Sussex"
options(scipen = 999)

# Nearest neighbours
LAD <- read_csv(url("https://opendata.arcgis.com/datasets/a267b55f601a4319a9955b0197e3cb81_0.csv"), col_types = cols(LAD17CD = col_character(),LAD17NM = col_character(),  LAD17NMW = col_character(),  FID = col_integer()))

Counties <- read_csv(url("https://opendata.arcgis.com/datasets/7e6bfb3858454ba79f5ab3c7b9162ee7_0.csv"), col_types = cols(CTY17CD = col_character(),  CTY17NM = col_character(),  Column2 = col_character(),  Column3 = col_character(),  FID = col_integer()))

lookup <- read_csv(url("https://opendata.arcgis.com/datasets/41828627a5ae4f65961b0e741258d210_0.csv"), col_types = cols(LTLA17CD = col_character(),  LTLA17NM = col_character(),  UTLA17CD = col_character(),  UTLA17NM = col_character(),  FID = col_integer()))

# This is a lower tier LA to upper tier LA lookup
UA <- subset(lookup, LTLA17NM == UTLA17NM)

Region <- read_csv(url("https://opendata.arcgis.com/datasets/cec20f3a9a644a0fb40fbf0c70c3be5c_0.csv"), col_types = cols(RGN17CD = col_character(),  RGN17NM = col_character(),  RGN17NMW = col_character(),  FID = col_integer()))
colnames(Region) <- c("Area_Code", "Area_Name", "Area_Name_Welsh", "FID")

Region$Area_Type <- "Region"
Region <- Region[c("Area_Code", "Area_Name", "Area_Type")]

LAD <- subset(LAD, substr(LAD$LAD17CD, 1, 1) == "E")
LAD$Area_Type <- ifelse(LAD$LAD17NM %in% UA$LTLA17NM, "Unitary Authority", "District")
colnames(LAD) <- c("Area_Code", "Area_Name", "Area_Name_Welsh", "FID", "Area_Type")
LAD <- LAD[c("Area_Code", "Area_Name", "Area_Type")]

Counties$Area_type <- "County"
colnames(Counties) <- c("Area_Code", "Area_Name", "Col2", "Col3", "FID", "Area_Type")
Counties <- Counties[c("Area_Code", "Area_Name", "Area_Type")]

England <- data.frame(Area_Code = "E92000001", Area_Name = "England", Area_Type = "Country")

Areas <- rbind(LAD, Counties, Region, England)
rm(LAD, Counties, Region, England, UA)

WSx_NN <- data.frame(Area_Code = nearest_neighbours(AreaCode = "E10000032", AreaTypeID = "102", measure = "CIPFA")) %>%   
  mutate(Neighbour_rank = row_number()) %>% 
  left_join(Areas, by = "Area_Code") %>% 
  select(Area_Name, Neighbour_rank) 

Area_rank = data.frame(Area_Name = c('West Sussex','South East England',"England"), Neighbour_rank = c(0,1,2)) %>% 
  bind_rows(WSx_NN) %>% 
  mutate(Neighbour_rank = row_number()) %>% 
  rename(Area = Area_Name)

# http://ghdx.healthdata.org/gbd-results-tool
# http://www.healthdata.org/united-kingdom
# http://www.who.int/quantifying_ehimpacts/publications/en/9241546204chap3.pdf

# You need to download the Global Burden of Disease data manually - and the links expire after a time so it is impossible to automate the downloading (and I have tried a few ways).

# You cannot sum risk factor values across causes, but you can sum cause values across risk factors

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

# Life expectancy and HALE #### 
LE <- read_csv("~/Documents/GBD_data_download/LE_GBD_timeseries.csv") %>% 
  left_join(Area_rank, by = 'Area') %>% 
  rename(Estimate = val,
         Lower_estimate = lower,
         Upper_estimate = upper) %>% 
  filter(Area == 'West Sussex') %>% 
  filter(Sex != 'Both') %>% 
  select(measure, Sex, Year, Estimate) %>% 
  spread(Sex, Estimate) %>% 
  mutate(Gap = Female - Male)

ggplot(LE, aes(x = Year, y = Gap, group = measure, color = measure))+
  geom_line() +
  geom_point() +
  scale_y_continuous(limits = c(0,6),
                     breaks = seq(0,6,0.5)) +
  scale_x_continuous(breaks = seq(1990, 2017, 1)) +
  theme(axis.text.x = element_text(angle = 90))

ggplot(LE, aes(x = Year, y = Male, group = measure, color = measure))+
  geom_line() +
  geom_point() +
  geom_line(aes(x = Year, y = Female, group = measure, color = measure)) +
  scale_y_continuous(limits = c(65, 85),
                     breaks = seq(65,85,1)) +
  scale_x_continuous(breaks = seq(1990, 2017, 1)) +
  theme(axis.text.x = element_text(angle = 90))

read_csv("~/Documents/GBD_data_download/LE_GBD_timeseries.csv") %>% 
  left_join(Area_rank, by = 'Area') %>% 
  rename(Estimate = val,
         Lower_estimate = lower,
         Upper_estimate = upper) %>% 
  filter(Area == 'West Sussex') %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/LE_HALE_1990_2017.json'))

read_csv("~/Documents/GBD_data_download/LE_GBD_timeseries_stacked.csv") %>% 
  left_join(Area_rank, by = 'Area') %>% 
  rename(HALE = `HALE (Healthy life expectancy)`) %>% 
  filter(Area == 'West Sussex') %>% 
  mutate(label = paste0('<p>The overall life expectancy in ', Area, ' at birth in ', Year, ' ', ifelse(Sex == 'Both', '(for males and females combined)', paste0(' among ', tolower(Sex), 's')), ' was <font color = "#1e4b7a"><b>', round(`Life expectancy`,1), ' years</b></font>.</p><p>On average, a person born in this year could expect to live <font color = "#1e4b7a"><b>', round(HALE, 1), ' years in good health</b></font> but spend ', round(Difference, 1), ' years living with at least some level of disability or ill health.</p><p>This means living around <font color = "#1e4b7a"><b>', round(Difference/`Life expectancy` * 100, 1), '% of life with an illness or disability.</b></font></p>')) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/LE_HALE_stacked_ts_1990_2017.json'))

# read_csv("~/Documents/GBD_data_download/LE_GBD_change_difference.csv") %>% 
#   left_join(Area_rank, by = 'Area') %>% 
#   toJSON() %>% 
#   write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/LE_HALE_time_in_poor_health_1990_2017_.json'))

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
  # mutate(Cause = ifelse(nchar(Cause) < 40, Cause, sub('(.{1,40})(\\s|$)', '\\1\n', Cause))) %>%
  mutate(Cause = factor(Cause, levels =  unique(Cause))) %>% 
  select(Area, Sex, Year, Cause, Cause_outline, Cause_id, Level, Estimate, Lower_estimate, Upper_estimate, `Cause group`, Parent_id, measure, metric)

Cause_number <- All_ages_GBD_cause_data %>% 
  filter(metric == "Number") %>% 
  group_by(measure, Year, Area, Sex) %>%   
  select(-c(Lower_estimate, Upper_estimate)) %>% 
  spread(measure, Estimate) %>% 
  ungroup() 

level_3_top_cause <- Cause_number %>% 
  filter(Level == 3,
         Area == Area_x,
         Year == 2017) %>% 
  group_by(Sex) %>% 
  mutate(Rank = rank(-`YLDs (Years Lived with Disability)`)) %>% 
  filter(Rank <= 10)

level_0_top_cause <- Cause_number %>% 
  filter(Level == 0,
         Sex == 'Both',
         Area == Area_x,
         Year == 2017)

level_2_top_cause <- Cause_number %>% 
  filter(Level == 2,
      #   Sex == 'Both',
         Area == Area_x,
         Year == 2017)

# Percent is the proportion of the deaths in the given location for the given sex, year, and level.
Cause_perc <- All_ages_GBD_cause_data %>% 
  filter(metric == "Proportion of total burden caused by this condition") %>% 
  group_by(measure, Year, Area, Sex) %>%   
  select(-c(Lower_estimate, Upper_estimate)) %>% 
  spread(measure, Estimate) %>% 
  ungroup()

# Rate is per 100,000 population
# Number is the count of deaths

Area_x_cause_number <- Cause_number %>% 
  filter(Area == Area_x) %>% 
  arrange(Sex, Year, Cause_outline) 

Area_x_cause_perc <- Cause_perc %>% 
  filter(Area == Area_x) %>% 
  arrange(Sex, Year, Cause_outline)

# We need to remove the NAs and replace them with zeros (otherwise the JSON file we are about to export won't be read properly)
Area_x_cause <- Area_x_cause_number %>% 
  bind_rows(Area_x_cause_perc) %>% 
  mutate(Deaths = replace_na(Deaths, 0)) %>% 
  mutate(Incidence = replace_na(Incidence, 0)) %>% 
  mutate(Prevalence = replace_na(Prevalence, 0)) %>% 
  mutate(`YLDs (Years Lived with Disability)` = replace_na(`YLDs (Years Lived with Disability)`, 0)) %>% 
  mutate(`YLLs (Years of Life Lost)` = replace_na(`YLLs (Years of Life Lost)`, 0))

# This exports a JSON file of the total number of deaths and YLLs by sex in the most recent year for our chosen area
Area_x_cause %>% 
  filter(Level == 0) %>%
  filter(Year %in% c(max(Year))) %>% 
  filter(metric == "Number") %>% 
  select(Year, Sex, Cause, Deaths, `YLLs (Years of Life Lost)`) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Total_deaths_yll_2017_', gsub(" ", "_", tolower(Area_x)), '.json'))

Area_x_cause <- Area_x_cause %>% 
  select(-c(Area, Cause_outline, Cause_id, Parent_id))

# Change over time for deaths at all levels by sex ####
Area_deaths_2017 <- Area_x_cause %>% 
  filter(Level %in% c(2,3)) %>% 
  filter(Year == 2017) %>% 
  rename(Deaths_2017 = Deaths)

Area_deaths_2017_a <- Area_x_cause %>% 
  filter(Level %in% c(2,3)) %>% 
  filter(Year %in% c(1997, 2002, 2007, 2012, 2017)) %>% 
  select(Sex, Year, Cause, Level,`Cause group`, metric, Deaths) %>% 
  group_by(Sex, Level, metric) %>% 
  mutate(Rank = rank(-Deaths)) %>% 
  left_join(Area_deaths_2017[c('Sex', 'Cause', 'Cause group', 'Level', 'metric','Deaths_2017')], by = c('Sex', 'Cause', 'Cause group','metric', 'Level')) %>% 
  ungroup() %>% 
  mutate(Change_to_2017 = ifelse(metric == 'Number', ((Deaths_2017 - Deaths) / Deaths)*100, ifelse(metric == 'Proportion of total burden caused by this condition', Deaths_2017 - Deaths, NA))) %>%
  mutate(Change_label = paste0('Change since ', Year)) %>% 
  mutate(Rank_label = paste0('Rank in ', Year)) %>% 
  mutate(Death_label = paste0('Deaths in ', Year))
  
Area_deaths_2017_b <- Area_deaths_2017_a %>% 
  select(Sex, Cause, metric, Change_to_2017, Change_label) %>% 
  filter(Change_label != 'Change since 2017') %>% 
  spread(Change_label, Change_to_2017)

Area_deaths_2017_c <- Area_deaths_2017_a %>% 
  select(Sex, Cause, metric, Rank, Rank_label) %>% 
  spread(Rank_label, Rank)

Area_deaths_2017_d <- Area_deaths_2017_a %>% 
  select(Sex, Cause, metric, Deaths, Death_label) %>% 
  spread(Death_label, Deaths)

Area_deaths_2017 <- Area_deaths_2017 %>% 
  left_join(Area_deaths_2017_b, by = c('Sex', 'Cause', 'metric')) %>% 
  select(-c('DALYs (Disability-Adjusted Life Years)', "Incidence",'Prevalence','YLDs (Years Lived with Disability)', "YLLs (Years of Life Lost)")) %>% 
  left_join(Area_deaths_2017_c, by = c('Sex', 'Cause', 'metric')) %>% 
  left_join(Area_deaths_2017_d, by = c('Sex', 'Cause', 'metric')) %>% 
  select(-Deaths_2017) %>% 
  mutate(`Change since 1997` = replace_na(`Change since 1997`, 0)) %>% 
  mutate(`Change since 2002` = replace_na(`Change since 2002`, 0)) %>% 
  mutate(`Change since 2007` = replace_na(`Change since 2007`, 0)) %>% 
  mutate(`Change since 2012` = replace_na(`Change since 2012`, 0)) 

rm(Area_deaths_2017_a, Area_deaths_2017_b, Area_deaths_2017_c, Area_deaths_2017_d)

# This is the change over time for deaths at all levels by sex - show change in number and change in proportion
Area_deaths_2017 %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Number_proportion_cause_death_2017_', gsub(" ", "_", tolower(Area_x)), '.json'))

Deaths_10 <- Area_x_cause %>% 
  filter(Year == 2017,
         Level == 2,) %>%
  group_by(Sex) %>% 
  mutate(Rank = rank(-Deaths)) %>% 
  filter(Rank <= 10) %>% 
  rename(`Cause of death` = Cause) %>%
  select(Sex, Rank, `Cause of death`, Deaths) %>% 
  arrange(Sex,Rank)

YLL_10 <- Area_x_cause %>% 
  filter(Year == 2017,
         Level == 2,) %>%
  group_by(Sex) %>% 
  mutate(Rank = rank(-`YLLs (Years of Life Lost)`)) %>% 
  filter(Rank <= 10) %>% 
  rename(`Cause of years of life lost` = Cause) %>%
  select(Sex, Rank, `Cause of years of life lost`, `YLLs (Years of Life Lost)`) %>% 
  arrange(Sex,Rank)

YLD_10 <- Area_x_cause %>% 
  filter(Year == 2017,
         Level == 2,) %>%
  group_by(Sex) %>% 
  mutate(Rank = rank(-`YLDs (Years Lived with Disability)`)) %>% 
  filter(Rank <= 10) %>% 
  rename(`Cause of years lived with disability` = Cause) %>%
  select(Sex, Rank, `Cause of years lived with disability`, `YLDs (Years Lived with Disability)`) %>% 
  arrange(Sex, Rank)

DALY_10 <- Area_x_cause %>% 
  filter(Year == 2017,
         Level == 2,) %>%
  group_by(Sex) %>% 
  mutate(Rank = rank(-`DALYs (Disability-Adjusted Life Years)`)) %>% 
  filter(Rank <= 10) %>% 
  rename(`Cause of disability adjusted life years lost` = Cause) %>%
  select(Sex, Rank, `Cause of disability adjusted life years lost`, `DALYs (Disability-Adjusted Life Years)`) %>% 
  arrange(Sex, Rank)

WSx_top_10 <- Deaths_10 %>% 
  left_join(YLL_10, by = c('Sex', 'Rank')) %>% 
  left_join(YLD_10, by = c('Sex', 'Rank')) %>% 
  left_join(DALY_10, by = c('Sex', 'Rank')) %>% 
  mutate(Deaths = paste0(Rank, ') ', `Cause of death`, ' (', format(round(Deaths,0), big.mark = ',', trim = TRUE), ')')) %>% 
  mutate(`YLLs (Years of Life Lost)` = paste0(Rank, ') ', `Cause of years of life lost`, ' (', format(round(`YLLs (Years of Life Lost)`,0), big.mark = ',', trim = TRUE), ')')) %>% 
  mutate(`YLDs (Years Lived with Disability)` = paste0(Rank, ') ', `Cause of years lived with disability`, ' (', format(round(`YLDs (Years Lived with Disability)`,0), big.mark = ',', trim = TRUE), ')')) %>% 
  mutate(`DALYs (Disability-Adjusted Life Years)` = paste0(Rank, ') ', `Cause of disability adjusted life years lost`, ' (', format(round(`DALYs (Disability-Adjusted Life Years)`,0), big.mark = ',', trim = TRUE), ')')) %>% 
  select(Sex, Rank, Deaths, `YLLs (Years of Life Lost)`, `YLDs (Years Lived with Disability)`, `DALYs (Disability-Adjusted Life Years)`)

WSx_top_10 %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Top_10_YLL_YLD_DALY_2017_', gsub(" ", "_", tolower(Area_x)), '.json'))
  
# Explore the top ten causes of death (numbers), YLL (numbers), YLDs (numbers) and DALYs.

level_1_cause_df_a <- Area_x_cause %>% 
  filter(Level == 1,
         Year == 2017) %>%
  group_by(Sex, metric) %>% 
  mutate(Death_rank =  rank(-Deaths, ties.method = "first")) %>% # The - indicates descending order
  mutate(YLL_rank =  rank(-`YLLs (Years of Life Lost)`, ties.method = "first")) %>% 
  mutate(YLD_rank =  rank(-`YLDs (Years Lived with Disability)`, ties.method = "first")) %>% 
  mutate(DALY_rank =  rank(-`DALYs (Disability-Adjusted Life Years)`, ties.method = "first")) %>% 
  select(-c(Incidence, Prevalence)) %>% 
  ungroup()

level_1_cause_df_b <- level_1_cause_df_a %>% 
  filter(metric == 'Proportion of total burden caused by this condition') %>% 
  rename(DALY_proportion = `DALYs (Disability-Adjusted Life Years)`,
         Deaths_proportion = Deaths,
         YLD_proportion = `YLDs (Years Lived with Disability)`,
         YLL_proportion = `YLLs (Years of Life Lost)`) %>% 
  select(Sex, Cause, Deaths_proportion, YLL_proportion, YLD_proportion, DALY_proportion)

level_1_cause_df <- level_1_cause_df_a %>% 
  filter(metric == 'Number') %>% 
  rename(DALY_number = `DALYs (Disability-Adjusted Life Years)`,
         Deaths_number = Deaths,
         YLD_number = `YLDs (Years Lived with Disability)`,
         YLL_number = `YLLs (Years of Life Lost)`) %>% 
  left_join(level_1_cause_df_b, by = c('Sex', 'Cause')) %>% 
  select(Sex, Cause, Year, `Cause group`, Deaths_number, Deaths_proportion, Death_rank, YLL_number, YLL_proportion, YLL_rank, YLD_number, YLD_proportion, YLD_rank, DALY_number, DALY_proportion, DALY_rank)

rm(level_1_cause_df_a, level_1_cause_df_b)

level_1_cause_df %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Number_cause_level_1_2017_', gsub(" ", "_", tolower(Area_x)), '.json'))

level_1_summary <- level_1_cause_df %>% 
  filter(Sex == 'Both') %>% 
  mutate(deaths_label = paste0('This group of causes was estimated to be responsible for <font color = "#1e4b7a"><b>', format(round(Deaths_number,0), big.mark = ',', trim = TRUE), '</font></b> deaths which represents <b>', round(Deaths_proportion * 100,1), '% of all deaths</b> in ', Year, '.')) %>%
  mutate(yll_label = paste0('This group of causes was estimated to be responsible for <font color = "#1e4b7a"><b>', format(round(YLL_number,0), big.mark = ',', trim = TRUE), '</font></b> years of life lost which represents <b>', round(YLL_proportion * 100,1), '% of all YLLs</b> in ', Year, '.')) %>% 
  mutate(yld_label = paste0('This group of causes was estimated to be responsible for <font color = "#1e4b7a"><b>', format(round(YLD_number,0), big.mark = ',', trim = TRUE), '</font></b> years of life lived with disability which represents <b>', round(YLD_proportion * 100,1), '% of all YLDs</b> in ', Year, '.')) %>% 
  mutate(daly_label = paste0('This group of causes was estimated to be responsible for <font color = "#1e4b7a"><b>', format(round(DALY_number,0), big.mark = ',', trim = TRUE), '</font></b> disability adjusted life years lost which represents <b>', round(DALY_proportion * 100,1), '% of all DALYs</b> in ', Year, '.')) %>% 
  select(Cause, deaths_label, yll_label, yld_label, daly_label) %>% 
  mutate(Cause = factor(Cause, levels = c('Communicable, maternal, neonatal, and nutritional diseases', 'Non-communicable diseases', 'Injuries'))) %>% 
  arrange(Cause)

level_1_summary %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/level_1_2017_', gsub(" ", "_", tolower(Area_x)), '_summary.json'))

level_2_cause_df_a <- Area_x_cause %>% 
  filter(Level == 2,
         Year == 2017) %>%
  group_by(Sex, metric) %>% 
  mutate(Death_rank =  rank(-Deaths, ties.method = "first")) %>% # The - indicates descending order
  mutate(YLL_rank =  rank(-`YLLs (Years of Life Lost)`, ties.method = "first")) %>% 
  mutate(YLD_rank =  rank(-`YLDs (Years Lived with Disability)`, ties.method = "first")) %>% 
  mutate(DALY_rank =  rank(-`DALYs (Disability-Adjusted Life Years)`, ties.method = "first")) %>% 
  select(-c(Incidence, Prevalence)) %>% 
  ungroup()

level_2_cause_df_b <- level_2_cause_df_a %>% 
  filter(metric == 'Proportion of total burden caused by this condition') %>% 
  rename(DALY_proportion = `DALYs (Disability-Adjusted Life Years)`,
         Deaths_proportion = Deaths,
         YLD_proportion = `YLDs (Years Lived with Disability)`,
         YLL_proportion = `YLLs (Years of Life Lost)`) %>% 
  select(Sex, Cause, Deaths_proportion, YLL_proportion, YLD_proportion, DALY_proportion)

level_2_cause_df <- level_2_cause_df_a %>% 
  filter(metric == 'Number') %>% 
  rename(DALY_number = `DALYs (Disability-Adjusted Life Years)`,
         Deaths_number = Deaths,
         YLD_number = `YLDs (Years Lived with Disability)`,
         YLL_number = `YLLs (Years of Life Lost)`) %>% 
  left_join(level_2_cause_df_b, by = c('Sex', 'Cause')) %>% 
  select(Sex, Cause, Year, `Cause group`, Deaths_number, Deaths_proportion, Death_rank, YLL_number, YLL_proportion, YLL_rank, YLD_number, YLD_proportion, YLD_rank, DALY_number, DALY_proportion, DALY_rank) %>% 
  mutate(Death_rank = ifelse(Death_rank == 1, ' largest ', ifelse(Death_rank == 22, ' lowest ', paste0(ordinal_format()(Death_rank), ' highest ')))) %>% 
  mutate(YLL_rank = ifelse(YLL_rank == 1, ' largest ', ifelse(YLL_rank == 22, ' lowest ', paste0(ordinal_format()(YLL_rank), ' highest ')))) %>%   
  mutate(YLD_rank = ifelse(YLD_rank == 1, ' largest ', ifelse(YLD_rank == 22, ' lowest ', paste0(ordinal_format()(YLD_rank), ' highest ')))) %>%   
  mutate(DALY_rank = ifelse(DALY_rank == 1, ' largest ', ifelse(DALY_rank == 22, ' lowest ', paste0(ordinal_format()(DALY_rank), ' highest '))))
  
rm(level_2_cause_df_a, level_2_cause_df_b)

level_2_cause_df %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Number_cause_level_2_2017_', gsub(" ", "_", tolower(Area_x)), '.json'))

cause_description <- data.frame(Cause = c("HIV/AIDS and sexually transmitted infections", "Respiratory infections and tuberculosis", "Enteric infections", "Neglected tropical diseases and malaria", "Other infectious diseases", "Maternal and neonatal disorders", "Nutritional deficiencies", "Neoplasms", "Cardiovascular diseases", "Chronic respiratory diseases", "Digestive diseases", "Neurological disorders", "Mental disorders", "Substance use disorders", "Diabetes and kidney diseases", "Skin and subcutaneous diseases", "Sense organ diseases", "Musculoskeletal disorders", "Other non-communicable diseases", "Transport injuries", "Unintentional injuries", "Self-harm and interpersonal violence")) %>% 
  bind_cols(Description = c("This disease group includes HIV/AIDS and sexually transmitted infections such as Syphilis, Chlamydia and Gonorrhea.", "This disease group includes lower and upper respiratory infections, Otitis media (inflamatory diseases of the middle ear) and Tuberculosis.", "Enteric infections include Diarrheal diseases, Typhoid, Salmonella and other intestinal infectious diseases.", "This disease group includes Malaria, Leishmaniasis, Yellow fever, Rabies, Food-borne trematodiases, Leprosy, Ebola, Zika virus and other neglected tropical diseases.", "Other infectious disease include Meningitis, Encephalitis, Diphtheria, Whooping Cough, Tetanus, Measles, Acute hepatitis and other unspecified infectious diseases.", "Maternal and neonatal disorders include maternal hemorrhage, sepsis, hypertensive disorders, obstructed labor, abortion or miscariage, as well as Ectopic pregnancies, preterm birth, encephalopathy due to asphyxia and trauma during birth.", "Nutritional deficiencies include protein-energy malnutrition, as well as deficiencies in Iodine, Vitamin A, and dietary iron.", "Neoplasms (cancer) include all sites as well as malignant and non-melanoma cancers.", "Cardiovascular diseases include Ischemic heart disease, Stroke, Hypertensive heart disease, Atrial fibrillation, Aortic aneurysm, Peripheral Artery Disease and other circulatory diseases.", "Chronic respiratory diseases include Chronic Obstructive Pulmonary Disease (COPD), Pneumoconiosis (e.g. Silicosis and Asbestosis), Asthma, and Interstitial lung disease and pulmonary sarcoidosis.", "Digestive diseases include Cirrhosis and other chronic liver diseases, Appendicitis, Inflammatory bowel disease, Vascular intestinal disorders, Gallblader and biliary diseases, and Pancreatitis.", "Neurological disorders include Alzheimer's and other dementias, Parkinson's disease, Epilepsy, Multiple sclerosis, Motor neuron disease, Migraine and tension headaches and other neurological disorders.", "Mental disorders include Schizophrenia, Depressive, Bipolar, Anxiety, and Eating disorders as well as Autism Spectrum, Attention-deficit/hyperactivity, and Conduct disorders.", "Substance use disorders include Alcohol, Opioid, Cocaine, Amphetamine, Cannabis and other drug use disorders", "Diabetes and kidney diseases include both Type 1 and Type 2 Diabetes mellitus, Chronic Kidney Disease and Acute Glomerulonephritis.", "Skin and subcutaneous disease include Dermatitis, Psoriasis, Bacterial, Fungal and Viral skin diseases, Alopecia areata, and Acne.", "Sense organ disease include blindness and visual impairment caused by Glaucoma, Cataract, and Macular degeneration as well as hearing loss and other sense organ diseases.", "Musculoskeletal disorders include Rheumatoid arthritis, Osteoarthritis, Low back pain, Neck pain and Gout.", "Other non-communicable diseases include congenital birth defects, urinary diseases, male infertility and other gynecological diseases, as well as Endocrine, metabolic, blood, and immune disorders, Oral disorders and Sudden Infant Death Syndrome.", "Transport injuries include injuries on the road involving pedestrains, cyclists, motorcyclist and motor vehicle road injuries.", "Unintentional injuries include falls, drowning, poisonings, exposure to mechanical forces, fire, heat and hot substances as well as adverse effects of medical treatment, animal contact, foreign bodies or forces of nature.", "Self-harm and interpersonal violence includes conflict and terrorism, physical and sexual violence as well as self-harm and executions."))

level_2_summary <- level_2_cause_df %>% 
  filter(Sex == 'Both') %>% 
  mutate(deaths_label = paste0('This group of causes was estimated to be responsible for <font color = "#1e4b7a"><b>', format(round(Deaths_number,0), big.mark = ',', trim = TRUE), '</font></b> deaths which represents <b>', round(Deaths_proportion * 100,1), '% of all deaths</b> in ', Year, '. ', Cause, ' had the <b>', Death_rank , '</b>number of deaths out of the 22 cause groups.'))%>% 
  mutate(yll_label = paste0('This group of causes was estimated to be responsible for <font color = "#1e4b7a"><b>', format(round(YLL_number,0), big.mark = ',', trim = TRUE), '</font></b> years of life lost which represents <b>', round(YLL_proportion * 100,1), '% of all YLLs</b> in ', Year, '. ', Cause, ' had the <b>', YLL_rank, '</b>number of YLLs out of the 22 cause groups.')) %>% 
  mutate(yld_label = paste0('This group of causes was estimated to be responsible for <font color = "#1e4b7a"><b>', format(round(YLD_number,0), big.mark = ',', trim = TRUE), '</font></b> years of life lived with disability which represents <b>', round(YLD_proportion * 100,1), '% of all YLDs</b> in ', Year, '. ', Cause, ' had the <b>', YLD_rank, '</b>number of YLDs out of the 22 cause groups.')) %>% 
  mutate(daly_label = paste0('This group of causes was estimated to be responsible for <font color = "#1e4b7a"><b>', format(round(DALY_number,0), big.mark = ',', trim = TRUE), '</font></b> disability adjusted life years lost which represents <b>', round(DALY_proportion * 100,1), '% of all DALYs</b> in ', Year, '. ', Cause, ' had the <b>', DALY_rank, '</b>number of DALYs out of the 22 cause groups.')) %>% 
  mutate(Parent = paste0('This group is part of the ', `Cause group`, ' main group of causes.')) %>% 
  left_join(cause_description, by = 'Cause') %>% 
  select(Cause, Parent, Description, deaths_label, yll_label, yld_label, daly_label) %>% 
  mutate(Cause = factor(Cause, levels = c("HIV/AIDS and sexually transmitted infections", "Respiratory infections and tuberculosis", "Enteric infections", "Neglected tropical diseases and malaria", "Other infectious diseases", "Maternal and neonatal disorders", "Nutritional deficiencies", "Neoplasms", "Cardiovascular diseases", "Chronic respiratory diseases", "Digestive diseases", "Neurological disorders", "Mental disorders", "Substance use disorders", "Diabetes and kidney diseases", "Skin and subcutaneous diseases", "Sense organ diseases", "Musculoskeletal disorders", "Other non-communicable diseases", "Transport injuries", "Unintentional injuries", "Self-harm and interpersonal violence"))) %>% 
  arrange(Cause)

level_2_summary %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/level_2_2017_', gsub(" ", "_", tolower(Area_x)), '_summary.json'))
  
# Data for cause size bubbles 

# area, sex, year, measure, value - switch between deaths, yll, yld and daly - number
Area_x_cause %>% 
  filter(Level == 3,
         metric == 'Number',
         Year == max(Year)) %>% 
  select(-c(Prevalence, Incidence, metric, Level)) %>% 
  gather(`DALYs (Disability-Adjusted Life Years)`:`YLLs (Years of Life Lost)`, key = 'Measure', val = "Value") %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Number_bubbles_df_level_3_2017_', gsub(" ", "_", tolower(Area_x)), '.json'))

rm(Area_deaths_2017, Area_x_cause, Area_x_cause_number, Area_x_cause_perc, Cause_number, Cause_perc, level_2_cause_df, WSx_top_10, All_ages_GBD_cause_data)

# Over the lifecourse ####
lifecourse_wsx_df <- unique(list.files("~/Documents/GBD_data_download")[grepl("b328ae1f", list.files("~/Documents/GBD_data_download/")) == TRUE]) %>% 
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
  filter(Year == max(Year))

# http://www.healthdata.org/sites/default/files/files/infographics/Infographic_GBD2017-YLDs-Highlights_2018_Page_1.png
lifecourse_numbers <- lifecourse_wsx_df %>% 
  filter(Metric == 'Number')

ages_summary <- lifecourse_numbers %>% 
  filter(Level == 0) 

lifecourse_prop <- lifecourse_wsx_df %>% 
  filter(Metric == "Proportion of total burden caused by this condition")

lifecourse_age <- lifecourse_numbers %>% 
  filter(Level == 2,
         Sex == 'Both') %>% 
  select(Age, Cause, Measure, Estimate) %>% 
  mutate(Cause = factor(Cause, levels = c("HIV/AIDS and sexually transmitted infections", "Respiratory infections and tuberculosis", "Enteric infections", "Neglected tropical diseases and malaria", "Other infectious diseases", "Maternal and neonatal disorders", "Nutritional deficiencies", "Neoplasms", "Cardiovascular diseases", "Chronic respiratory diseases", "Digestive diseases", "Neurological disorders", "Mental disorders", "Substance use disorders", "Diabetes and kidney diseases", "Skin and subcutaneous diseases", "Sense organ diseases", "Musculoskeletal disorders", "Other non-communicable diseases", "Transport injuries", "Unintentional injuries", "Self-harm and interpersonal violence"))) %>%
  arrange(Cause) %>% 
  spread(Cause, Estimate) %>% 
  arrange(Measure, Age) %>% 
  mutate(`Neglected tropical diseases and malaria` = replace_na(`Neglected tropical diseases and malaria`, 0)) %>% 
  mutate(`Chronic respiratory diseases` = replace_na(`Chronic respiratory diseases`, 0)) %>% 
  mutate(`Digestive diseases` = replace_na(`Digestive diseases`, 0)) %>% 
  mutate(`Cardiovascular diseases` = replace_na(`Cardiovascular diseases`, 0)) %>% 
  mutate(`Nutritional deficiencies` = replace_na(`Nutritional deficiencies`, 0)) %>% 
  mutate(`Other non-communicable diseases` = replace_na(`Other non-communicable diseases`, 0)) %>% 
  mutate(`Skin and subcutaneous diseases` = replace_na(`Skin and subcutaneous diseases`, 0)) %>% 
  mutate(`Neurological disorders` = replace_na(`Neurological disorders`, 0)) %>% 
  mutate(`Transport injuries` = replace_na(`Transport injuries`, 0)) %>% 
  mutate(`Unintentional injuries` = replace_na(`Unintentional injuries`, 0)) %>% 
  mutate(`Mental disorders` = replace_na(`Mental disorders`, 0)) %>% 
  mutate(`Sense organ diseases` = replace_na(`Sense organ diseases`, 0)) %>% 
  mutate(`Musculoskeletal disorders` = replace_na(`Musculoskeletal disorders`, 0)) %>% 
  mutate(`Neoplasms` = replace_na(`Neoplasms`, 0)) %>% 
  mutate(`Self-harm and interpersonal violence` = replace_na(`Self-harm and interpersonal violence`, 0)) %>% 
  mutate(`HIV/AIDS and sexually transmitted infections` = replace_na(`HIV/AIDS and sexually transmitted infections`, 0)) %>% 
  mutate(`Respiratory infections and tuberculosis` = replace_na(`Respiratory infections and tuberculosis`, 0)) %>% 
  mutate(`Enteric infections` = replace_na(`Enteric infections`, 0)) %>% 
  mutate(`Other infectious diseases` = replace_na(`Other infectious diseases`, 0)) %>% 
  mutate(`Maternal and neonatal disorders` = replace_na(`Maternal and neonatal disorders`, 0)) %>% 
  mutate(`Substance use disorders` = replace_na(`Substance use disorders`, 0)) %>% 
  mutate(`Diabetes and kidney diseases` = replace_na(`Diabetes and kidney diseases`, 0)) 

lifecourse_numbers %>% 
  filter(Level == 2,
         Sex == 'Both') %>% 
  select(Age, Cause, Measure, Estimate) %>% 
  mutate(Cause = factor(Cause, levels = c("HIV/AIDS and sexually transmitted infections", "Respiratory infections and tuberculosis", "Enteric infections", "Neglected tropical diseases and malaria", "Other infectious diseases", "Maternal and neonatal disorders", "Nutritional deficiencies", "Neoplasms", "Cardiovascular diseases", "Chronic respiratory diseases", "Digestive diseases", "Neurological disorders", "Mental disorders", "Substance use disorders", "Diabetes and kidney diseases", "Skin and subcutaneous diseases", "Sense organ diseases", "Musculoskeletal disorders", "Other non-communicable diseases", "Transport injuries", "Unintentional injuries", "Self-harm and interpersonal violence"))) %>%
  arrange(Cause) %>% 
  group_by(Measure, Cause) %>% 
  filter(Estimate == max(Estimate)) %>% 
  mutate(Estimate_max = ifelse(Estimate < 50, 50, ifelse(Estimate < 100, 100, round_any(Estimate, 200, ceiling)))) %>% 
  select(Cause, Measure, Estimate_max) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Numbers_lifecourse_persons_level_2_2017_', gsub(" ", "_", tolower(Area_x)), '_stack_value_max.json'))

lifecourse_numbers %>% 
  filter(Level == 2,
         Sex == 'Both') %>% 
  select(Age, Cause, Measure, Estimate) %>% 
  arrange(Age) %>% 
  group_by(Measure, Age) %>% 
  filter(Estimate == max(Estimate)) %>% 
  mutate(Estimate_max = ifelse(Estimate < 50, 50, ifelse(Estimate < 100, 100, round_any(Estimate, 200, ceiling)))) %>% 
  select(Age, Measure, Estimate_max) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Numbers_lifecourse_persons_conditions_level_2_2017_', gsub(" ", "_", tolower(Area_x)), '_stack_value_max.json'))
  

#toJSON() %>% 
 # write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Numbers_lifecourse_persons_level_2_2017_', gsub(" ", "_", tolower(Area_x)), '.json'))

lifecourse_age %>% 
  mutate(Total_in_age = rowSums(.[3:ncol(.)])) %>% 
  select(Age, Measure, Total_in_age) %>% 
  group_by(Measure) %>% 
  filter(Total_in_age == max(Total_in_age)) %>% 
  select(-Age) %>% 
  mutate(rounded_Total_in_age = round_any(Total_in_age, 500, ceiling)) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Numbers_lifecourse_persons_level_2_2017_', gsub(" ", "_", tolower(Area_x)), '_max_value.json'))

lifecourse_condition <- lifecourse_numbers %>% 
  filter(Level == 2,
         Sex == 'Both') %>% 
  select(Age, Cause, Measure, Estimate) %>% 
  arrange(Age) %>% 
  spread(Age, Estimate) %>% 
  arrange(Measure, Cause) %>% 
  mutate(`Early Neonatal` = replace_na(`Early Neonatal`, 0)) %>% 
  mutate(`Late Neonatal` = replace_na(`Late Neonatal`, 0)) %>% 
  mutate(`Post Neonatal` = replace_na(`Post Neonatal`, 0)) %>% 
  mutate(`1 to 4` = replace_na(`1 to 4`, 0)) %>%  
  mutate(`5 to 9` = replace_na(`5 to 9`, 0)) %>%  
  mutate(`10 to 14` = replace_na(`10 to 14`, 0)) %>%  
  mutate(`15 to 19` = replace_na(`15 to 19`, 0)) %>%  
  mutate(`20 to 24` = replace_na(`20 to 24`, 0)) %>%  
  mutate(`25 to 29` = replace_na(`25 to 29`, 0)) %>%  
  mutate(`30 to 34` = replace_na(`30 to 34`, 0)) %>%  
  mutate(`35 to 39` = replace_na(`35 to 39`, 0)) %>%  
  mutate(`40 to 44` = replace_na(`40 to 44`, 0)) %>%  
  mutate(`45 to 49` = replace_na(`45 to 49`, 0)) %>%  
  mutate(`50 to 54` = replace_na(`50 to 54`, 0)) %>%  
  mutate(`55 to 59` = replace_na(`55 to 59`, 0)) %>%  
  mutate(`60 to 64` = replace_na(`60 to 64`, 0)) %>%  
  mutate(`65 to 69` = replace_na(`65 to 69`, 0)) %>%  
  mutate(`70 to 74` = replace_na(`70 to 74`, 0)) %>%  
  mutate(`75 to 79` = replace_na(`75 to 79`, 0)) %>%  
  mutate(`80 to 84` = replace_na(`80 to 84`, 0)) %>%  
  mutate(`85 to 89` = replace_na(`85 to 89`, 0)) %>%  
  mutate(`90 to 94` = replace_na(`90 to 94`, 0)) %>%  
  mutate(`95 plus` = replace_na(`95 plus`, 0)) %>% 
  mutate(Cause = factor(Cause, levels = c("HIV/AIDS and sexually transmitted infections", "Respiratory infections and tuberculosis", "Enteric infections", "Neglected tropical diseases and malaria", "Other infectious diseases", "Maternal and neonatal disorders", "Nutritional deficiencies", "Neoplasms", "Cardiovascular diseases", "Chronic respiratory diseases", "Digestive diseases", "Neurological disorders", "Mental disorders", "Substance use disorders", "Diabetes and kidney diseases", "Skin and subcutaneous diseases", "Sense organ diseases", "Musculoskeletal disorders", "Other non-communicable diseases", "Transport injuries", "Unintentional injuries", "Self-harm and interpersonal violence"))) %>%
  arrange(Cause)
  
lifecourse_condition %>% 
  mutate(Total_in_condition = rowSums(.[3:ncol(.)])) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Numbers_lifecourse_persons_by_condition_level_2_2017_', gsub(" ", "_", tolower(Area_x)), '.json'))

lifecourse_condition %>% 
  mutate(Total_in_condition = rowSums(.[3:ncol(.)])) %>% 
  select(Cause, Measure, Total_in_condition) %>% 
  group_by(Measure) %>% 
  filter(Total_in_condition == max(Total_in_condition)) %>% 
  select(-Cause) %>% 
  mutate(rounded_Total_in_condition = round_any(Total_in_condition, 500, ceiling))

lifecourse_condition_prop <- lifecourse_condition %>%
  mutate(Total_in_condition = rowSums(.[3:ncol(.)])) %>% 
  mutate(`Early Neonatal` = `Early Neonatal` / Total_in_condition * 100) %>% 
  mutate(`Late Neonatal` = `Late Neonatal` / Total_in_condition * 100) %>% 
  mutate(`Post Neonatal` = `Post Neonatal` / Total_in_condition * 100) %>% 
  mutate(`1 to 4` = `1 to 4` / Total_in_condition * 100) %>%  
  mutate(`5 to 9` = `5 to 9` / Total_in_condition * 100) %>%  
  mutate(`10 to 14` = `10 to 14` / Total_in_condition * 100) %>%  
  mutate(`15 to 19` = `15 to 19` / Total_in_condition * 100) %>%  
  mutate(`20 to 24` = `20 to 24` / Total_in_condition * 100) %>%  
  mutate(`25 to 29` = `25 to 29` / Total_in_condition * 100) %>%  
  mutate(`30 to 34` = `30 to 34` / Total_in_condition * 100) %>%  
  mutate(`35 to 39` = `35 to 39` / Total_in_condition * 100) %>%  
  mutate(`40 to 44` = `40 to 44` / Total_in_condition * 100) %>%  
  mutate(`45 to 49` = `45 to 49` / Total_in_condition * 100) %>%  
  mutate(`50 to 54` = `50 to 54` / Total_in_condition * 100) %>%  
  mutate(`55 to 59` = `55 to 59` / Total_in_condition * 100) %>%  
  mutate(`60 to 64` = `60 to 64` / Total_in_condition * 100) %>%  
  mutate(`65 to 69` = `65 to 69` / Total_in_condition * 100) %>%  
  mutate(`70 to 74` = `70 to 74` / Total_in_condition * 100) %>%  
  mutate(`75 to 79` = `75 to 79` / Total_in_condition * 100) %>%  
  mutate(`80 to 84` = `80 to 84` / Total_in_condition * 100) %>%  
  mutate(`85 to 89` = `85 to 89` / Total_in_condition * 100) %>%  
  mutate(`90 to 94` = `90 to 94` / Total_in_condition * 100) %>%  
  mutate(`95 plus` = `95 plus` / Total_in_condition * 100) %>% 
  select(-Total_in_condition) %>% 
  mutate(Cause = factor(Cause, levels = c("HIV/AIDS and sexually transmitted infections", "Respiratory infections and tuberculosis", "Enteric infections", "Neglected tropical diseases and malaria", "Other infectious diseases", "Maternal and neonatal disorders", "Nutritional deficiencies", "Neoplasms", "Cardiovascular diseases", "Chronic respiratory diseases", "Digestive diseases", "Neurological disorders", "Mental disorders", "Substance use disorders", "Diabetes and kidney diseases", "Skin and subcutaneous diseases", "Sense organ diseases", "Musculoskeletal disorders", "Other non-communicable diseases", "Transport injuries", "Unintentional injuries", "Self-harm and interpersonal violence"))) %>%
  arrange(Cause)

lifecourse_condition_prop %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Proportion_lifecourse_persons_by_condition_level_2_2017_', gsub(" ", "_", tolower(Area_x)), '.json'))

# Age standardising ####

# To compare over areas or time we could use age_standardised data

# top 10 slope chart

# line charts 

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

# There are no raw counts in the standardised set - only rates

# we will be comparing our area against the region and england, and our nearest neighbours. 

Age_standardised_NN_ts_data %>% 
  filter(Level == 0) %>% 
  filter(Sex == 'Both') %>% 
  filter(measure == 'Deaths') %>% 
  left_join(Area_rank, by = 'Area') %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Rate_deaths_1990_2017_NN.json'))

# Age_standardised_NN_ts_data %>% 
#   filter(Level == 2) %>% 
#   filter(Sex == 'Both') %>%
#   filter(Area %in% c(Area_x, 'England', 'South East England')) %>%
#   select(Area, Sex, Year, Cause,Estimate, Lower_estimate, Upper_estimate, measure) %>%
#   toJSON() %>% 
#   write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Rate_level_2_1990_2017_', gsub(" ", "_", tolower(Area_x)), '_region_england.json'))

Age_standardised_change_data <- unique(list.files("~/Documents/GBD_data_download/")[grepl("7d0121c1", list.files("~/Documents/GBD_data_download/")) == TRUE]) %>% 
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

# Change over time for deaths at all levels by sex ####
Change_over_time_latest <- Age_standardised_change_data %>% 
  filter(Year == 2017) %>% 
  rename(Estimate_2017 = Estimate) %>% 
  mutate(Label_2017 = paste0(format(round(Estimate_2017,0), big.mark = ',', trim = TRUE), ' (', format(round(Lower_estimate,0), big.mark = ',', trim = TRUE), '-', format(round(Upper_estimate,0), big.mark = ',', trim = TRUE), ')')) %>% 
  group_by(Area, Sex, Level, measure) %>% 
  mutate(`Rank_in_2017` = rank(-Estimate_2017))

Change_over_time_2007 <- Age_standardised_change_data %>% 
  filter(Year == 2007) %>% 
  rename(Estimate_2007 = Estimate) %>% 
  mutate(Label_2007 = paste0(format(round(Estimate_2007,0), big.mark = ',', trim = TRUE), ' (', format(round(Lower_estimate,0), big.mark = ',', trim = TRUE), '-', format(round(Upper_estimate,0), big.mark = ',', trim = TRUE), ')')) %>% 
  select(Area, Sex, Cause, measure, Label_2007) 

Change_over_time_a <- Age_standardised_change_data %>%
  filter(Year %in% c(1997, 2002, 2007, 2012)) %>% 
  select(Area, Sex, Year, Cause, Level, measure, Estimate) %>% 
  group_by(Area, Sex, Year, Level, measure) %>% 
  mutate(Rank = rank(-Estimate)) %>% 
  left_join(Change_over_time_latest[c('Area', 'Sex', 'Cause', 'measure','Estimate_2017', 'Label_2017')], by = c('Area','Sex', 'Cause', 'measure')) %>% 
  ungroup() %>% 
  mutate(Change_to_2017 = (Estimate_2017 - Estimate) / Estimate *100) %>%
  mutate(Change_label = paste0('Change_since_', Year)) %>% 
  mutate(Rank_label = paste0('Rank_in_', Year)) %>% 
  mutate(Estimate_label = paste0('Estimate_in_', Year))

Change_over_time_b <- Change_over_time_a %>% 
  select(Area, Sex, Cause, measure, Change_to_2017, Change_label) %>% 
  filter(Change_label != 'Change_since_2017') %>% 
  spread(Change_label, Change_to_2017)

Change_over_time_c <- Change_over_time_a %>% 
  select(Area, Sex, Cause, measure, Rank, Rank_label) %>% 
  spread(Rank_label, Rank)

Change_over_time_d <- Change_over_time_a %>% 
  select(Area, Sex, Cause, measure, Estimate, Estimate_label) %>% 
  spread(Estimate_label, Estimate)

Change_over_time <- Change_over_time_latest %>% 
  left_join(Change_over_time_b, by = c('Area','Sex', 'Cause', 'measure')) %>% 
  left_join(Change_over_time_c, by = c('Area','Sex', 'Cause', 'measure')) %>% 
  left_join(Change_over_time_d, by = c('Area','Sex', 'Cause', 'measure')) %>% 
  left_join(Change_over_time_2007, by = c('Area','Sex', 'Cause', 'measure')) %>% 
  select(-c(Year, Cause_id, Cause_outline, Parent_id, metric)) %>% 
  mutate(Change_since_1997 = replace_na(Change_since_1997, 0)) %>% 
  mutate(Change_since_2002 = replace_na(Change_since_2002, 0)) %>% 
  mutate(Change_since_2007 = replace_na(Change_since_2007, 0)) %>% 
  mutate(Change_since_2012 = replace_na(Change_since_2012, 0)) %>% 
  mutate(Rank_in_1997 = replace_na(Rank_in_1997, 0)) %>% 
  mutate(Rank_in_2002 = replace_na(Rank_in_2002, 0)) %>% 
  mutate(Rank_in_2007 = replace_na(Rank_in_2007, 0)) %>%  
  mutate(Rank_in_2012 = replace_na(Rank_in_2012, 0)) %>% 
  mutate(Estimate_in_1997 = replace_na(Estimate_in_1997, 0)) %>% 
  mutate(Estimate_in_2002 = replace_na(Estimate_in_2002, 0)) %>% 
  mutate(Estimate_in_2007 = replace_na(Estimate_in_2007, 0)) %>% 
  mutate(Estimate_in_2012 = replace_na(Estimate_in_2012, 0)) 

rm(Change_over_time_a, Change_over_time_b, Change_over_time_c, Change_over_time_d, Change_over_time_2007)

# Change_over_time %>% 
#   filter(Cause == 'Sense organ diseases') %>% 
#   View()
# 
# Change_over_time %>% 
#   filter(Area == 'West Sussex') %>%
#   filter(Level == 2) %>% 
#   mutate(Cause = factor(Cause, levels = c("HIV/AIDS and sexually transmitted infections", "Respiratory infections and tuberculosis", "Enteric infections", "Neglected tropical diseases and malaria", "Other infectious diseases", "Maternal and neonatal disorders", "Nutritional deficiencies", "Neoplasms", "Cardiovascular diseases", "Chronic respiratory diseases", "Digestive diseases", "Neurological disorders", "Mental disorders", "Substance use disorders", "Diabetes and kidney diseases", "Skin and subcutaneous diseases", "Sense organ diseases", "Musculoskeletal disorders", "Other non-communicable diseases", "Transport injuries", "Unintentional injuries", "Self-harm and interpersonal violence"))) %>%
#   arrange(Area, Sex, measure, Cause) %>% 
#   View()

# This is the change over time for deaths at all levels by sex - show change in number and change in proportion
Change_over_time %>% 
  filter(Rank_in_2017 <= 10 | Rank_in_2012 <= 10 | Rank_in_2007 <= 10 | Rank_in_2002 <= 10 | Rank_in_1997 <= 10) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Rate_change_over_time_levels_0_1_2_for_slope.json'))

Change_over_time %>% 
  filter(Area == 'West Sussex') %>%
  filter(Level == 2) %>% 
  mutate(Cause = factor(Cause, levels = c("HIV/AIDS and sexually transmitted infections", "Respiratory infections and tuberculosis", "Enteric infections", "Neglected tropical diseases and malaria", "Other infectious diseases", "Maternal and neonatal disorders", "Nutritional deficiencies", "Neoplasms", "Cardiovascular diseases", "Chronic respiratory diseases", "Digestive diseases", "Neurological disorders", "Mental disorders", "Substance use disorders", "Diabetes and kidney diseases", "Skin and subcutaneous diseases", "Sense organ diseases", "Musculoskeletal disorders", "Other non-communicable diseases", "Transport injuries", "Unintentional injuries", "Self-harm and interpersonal violence"))) %>%
  arrange(Area, Sex, measure, Cause) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Rate_change_over_time_level_2_', gsub(" ", "_", tolower(Area_x)), '.json'))

# Top ten causes (deaths, ylls, ylds, dalys) time series west sussex (NN - SE and England)

top_ten_wsx_level_2 <- Age_standardised_NN_ts_data %>% 
  filter(Level == 2) %>%
  filter(Area == 'West Sussex') %>% 
  filter(Year == 2017) %>% 
  filter(!(measure %in% c('Incidence', 'Prevalence'))) %>% 
  group_by(Sex, measure) %>% 
  mutate(Rank = rank(-Estimate)) %>% 
  filter(Rank <= 10) %>% 
  mutate(string_code = gsub(' ', '_', paste(Sex, Cause, measure, sep = '_')))

unique(top_ten_wsx_level_2$string_code)

top_ten_ts <- Age_standardised_NN_ts_data %>% 
  filter(Level == 2) %>% 
  mutate(Cause = factor(Cause, levels = c("HIV/AIDS and sexually transmitted infections", "Respiratory infections and tuberculosis", "Enteric infections", "Neglected tropical diseases and malaria", "Other infectious diseases", "Maternal and neonatal disorders", "Nutritional deficiencies", "Neoplasms", "Cardiovascular diseases", "Chronic respiratory diseases", "Digestive diseases", "Neurological disorders", "Mental disorders", "Substance use disorders", "Diabetes and kidney diseases", "Skin and subcutaneous diseases", "Sense organ diseases", "Musculoskeletal disorders", "Other non-communicable diseases", "Transport injuries", "Unintentional injuries", "Self-harm and interpersonal violence"))) %>% 
  mutate(string_code = gsub(' ', '_', paste(Sex, Cause, measure, sep = '_'))) %>% 
  filter(string_code %in% c(top_ten_wsx_level_2$string_code)) %>% 
  select(Area, Sex, Year, Cause, Estimate, Lower_estimate, Upper_estimate, measure)

top_ten_ts %>% 
  filter(Area %in% c(Area_x, 'South East England', 'England')) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Rate_top_ten_ts.json'))


# read_csv('https://gist.github.com/dianaow/0da76b59a7dffe24abcfa55d5b9e163e/raw/0892481142937672adbc801281ffb61466e612e7/coe-results.csv') %>% 
#   toJSON() %>% 
#   write_lines(paste0('/Users/richtyler/Documents/Repositories/testies/coe-results.json'))

# Condition focus ####

Condition_data <- unique(list.files("~/Documents/GBD_data_download/")[grepl("5f708e95", list.files("~/Documents/GBD_data_download/")) == TRUE]) %>% 
  map_df(~read_csv(paste0("~/Documents/GBD_data_download/",.), col_types = cols(age = col_character(), cause = col_character(), location = col_character(), lower = col_double(), measure = col_character(), metric = col_character(), sex = col_character(), upper = col_double(), val = col_double(), year = col_number()))) %>%
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
  filter((Age == 'Age-standardized') | (Age == 'All Ages' & metric == 'Number')) %>% 
  mutate(metric = ifelse(metric == 'Rate per 100,000 population', 'Age-standardised rate per 100,000', ifelse(metric == 'Number', 'Number (all ages)', NA))) %>% 
  select(Sex, metric, Year, Cause, `Cause group`,Estimate,Lower_estimate,Upper_estimate, measure)

Condition_table_part_a <- Condition_data %>% 
  filter(Year == 2017) %>% 
  mutate(Estimate = ifelse(Estimate == 0, 'None', ifelse(Estimate <0.1, round(Estimate, 2), ifelse(Estimate <1, round(Estimate,1), ifelse(metric == 'Age-standardised rate per 100,000', format(round(Estimate,1),big.mark = ',', trim = TRUE), ifelse(metric == 'Number (all ages)' & Estimate > 1, format(round(Estimate,0), big.mark = ',', trim = TRUE), NA)))))) %>% 
  mutate(Lower_estimate = ifelse(Lower_estimate == 0, 'None', ifelse(Lower_estimate <0.1, round(Lower_estimate, 2), ifelse(Lower_estimate <1, round(Lower_estimate,1), ifelse(metric == 'Age-standardised rate per 100,000', format(round(Lower_estimate,1), big.mark = ',', trim = TRUE), ifelse(metric == 'Number (all ages)'& Lower_estimate > 1, format(round(Lower_estimate,0), big.mark = ',', trim = TRUE), NA)))))) %>% 
  mutate(Upper_estimate = ifelse(Upper_estimate == 0, 'None', ifelse(Upper_estimate <0.1, round(Upper_estimate, 2), ifelse(Upper_estimate <1, round(Upper_estimate,1), ifelse(metric == 'Age-standardised rate per 100,000', format(round(Upper_estimate,1), big.mark = ',', trim = TRUE), ifelse(metric == 'Number (all ages)'& Upper_estimate > 1, format(round(Upper_estimate,0), big.mark = ',', trim = TRUE), NA)))))) %>% 
  mutate(Estimate = paste0(Estimate, ' (', Lower_estimate, ' - ', Upper_estimate, ')')) %>% 
  select(-c(Lower_estimate, Upper_estimate)) %>% 
  spread(metric, value = Estimate) %>% 
  select(-Year)

Condition_table_part_b <- Condition_data %>% 
  select(-c(Lower_estimate, Upper_estimate)) %>% 
  filter(Year == 2017) %>% 
  filter(metric == 'Number (all ages)') %>% 
  group_by(Sex, measure) %>% 
  mutate(Estimate = paste0(round(Estimate/sum(Estimate, na.rm = TRUE)*100,1),'%')) %>% 
  rename(`Proportion (based on number)` = Estimate) %>% 
  select(-c(Year,metric))
  
Condition_table_part_c <- Condition_data %>% 
  select(-c(Lower_estimate, Upper_estimate)) %>% 
  filter(metric == 'Number (all ages)') %>% 
  spread(Year, value = Estimate) %>% 
  mutate(`Percentage change 2012 - 2017 (based on number)` = paste0(ifelse((`2017`-`2012`)/`2012` > 0, '+', ''), round((`2017`-`2012`)/`2012`*100,1), '%')) %>% 
  mutate(`Percentage change 2012 - 2017 (based on number)` = gsub('NANaN%', 'No change', `Percentage change 2012 - 2017 (based on number)`)) %>% 
  select(-c(`2012`,`2017`,metric)) 

Condition_table_part_d <- Condition_data %>% 
  filter(Year == 2012) %>% 
  mutate(Estimate = ifelse(Estimate == 0, 'None', ifelse(Estimate <0.1, round(Estimate, 2), ifelse(Estimate <1, round(Estimate,1), ifelse(metric == 'Age-standardised rate per 100,000', format(round(Estimate,1),big.mark = ',', trim = TRUE), ifelse(metric == 'Number (all ages)' & Estimate > 1, format(round(Estimate,0), big.mark = ',', trim = TRUE), NA)))))) %>% 
  mutate(Lower_estimate = ifelse(Lower_estimate == 0, 'None', ifelse(Lower_estimate <0.1, round(Lower_estimate, 2), ifelse(Lower_estimate <1, round(Lower_estimate,1), ifelse(metric == 'Age-standardised rate per 100,000', format(round(Lower_estimate,1), big.mark = ',', trim = TRUE), ifelse(metric == 'Number (all ages)'& Lower_estimate > 1, format(round(Lower_estimate,0), big.mark = ',', trim = TRUE), NA)))))) %>% 
  mutate(Upper_estimate = ifelse(Upper_estimate == 0, 'None', ifelse(Upper_estimate <0.1, round(Upper_estimate, 2), ifelse(Upper_estimate <1, round(Upper_estimate,1), ifelse(metric == 'Age-standardised rate per 100,000', format(round(Upper_estimate,1), big.mark = ',', trim = TRUE), ifelse(metric == 'Number (all ages)'& Upper_estimate > 1, format(round(Upper_estimate,0), big.mark = ',', trim = TRUE), NA)))))) %>% 
  mutate(Estimate = paste0(Estimate, ' (', Lower_estimate, ' - ', Upper_estimate, ')')) %>% 
  select(-c(Lower_estimate, Upper_estimate)) %>% 
  spread(metric, value = Estimate) %>% 
  select(-c(Year, `Age-standardised rate per 100,000`)) %>%  
  rename(`Number (all ages) 2012` = `Number (all ages)`)

pre_table <- Condition_table_part_a %>% 
  left_join(Condition_table_part_b, by = c('Sex', 'Cause', 'Cause group', 'measure')) %>% 
  left_join(Condition_table_part_c, by = c('Sex', 'Cause', 'Cause group', 'measure')) %>%
  left_join(Condition_table_part_d, by = c('Sex', 'Cause', 'Cause group', 'measure')) %>%
  rename(`Number (all ages) 2017` = `Number (all ages)`) %>% 
  rename(`Age-standardised rate per 100,000 2017` = `Age-standardised rate per 100,000`) %>% 
  rename(`Proportion (based on number) 2017` = `Proportion (based on number)`) %>%
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Level_3_condition_focus_2017_', gsub(" ", "_", tolower(Area_x)), '.json'))

# Risk ####

GBD_2017_rei_hierarchy <- read_excel("~/Documents/GBD_data_download/IHME_GBD_2017_REI_HIERARCHY_Y2018M11D18.xlsx", col_types = c("text", "text", "text", "text", "text", "numeric"))

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

Total_burden <- level_1_cause_df %>% 
  filter(Sex == 'Both') %>% 
  summarise(Deaths_number = sum(Deaths_number, na.rm = TRUE),
            YLL_number = sum(YLL_number, na.rm = TRUE),
            YLD_number = sum(YLD_number, na.rm = TRUE),
            DALY_number = sum(DALY_number, na.rm = TRUE)) %>% 
  gather() %>% 
  mutate(measure = ifelse(key == 'Deaths_number', 'Deaths', ifelse(key == 'YLL_number', 'YLLs (Years of Life Lost)', ifelse(key == 'YLD_number', 'YLDs (Years Lived with Disability)', ifelse(key == 'DALY_number', 'DALYs (Disability-Adjusted Life Years)', NA))))) %>% 
  select(-key) %>% 
  rename(Total = value)

level_1_risk_summary <- GBD_risk_data_all_cause_NN %>% 
  filter(Area == Area_x) %>% 
  filter(Year == 2017) %>% 
  filter(Risk_level == 1) %>% 
  filter(metric == 'Number') %>% 
  filter(Sex == 'Both') %>% 
  select(-c(Upper_estimate, Lower_estimate)) %>% 
  left_join(Total_burden, by = 'measure') %>% 
  mutate(`Proportion burden explained by risk` = Estimate / Total) %>% 
  mutate(Measure = ifelse(measure == 'Deaths', 'deaths', ifelse(measure == 'YLLs (Years of Life Lost)', 'YLLs', ifelse(measure == 'YLDs (Years Lived with Disability)', 'YLDs', ifelse(measure == 'DALYs (Disability-Adjusted Life Years)', 'DALYs', NA))))) %>% 
  select(Risk, measure, Measure, Estimate, Total, `Proportion burden explained by risk`) %>% 
mutate(label = paste0('This group of risks was estimated to be responsible for <font color = "#1e4b7a"><b>', format(round(Estimate,0), big.mark = ',', trim = TRUE), '</font></b> ', Measure, ' which represents <b>', round(`Proportion burden explained by risk` * 100,1), '% of all ', Measure, '</b> in 2017 (', format(round(Total,0), big.mark = ',', trim = TRUE), ' ', Measure, ').')) %>% 
  select(Risk, measure, label) %>% 
  spread(measure, label) %>% 
  mutate(Description = ifelse(Risk == 'Environmental/occupational risks', 'Environmental/occupational risks include air pollution, unsafe water and sanitation (including handwashing) and occupational risks/exposures', ifelse(Risk == 'Behavioral risks', 'Behavioral risks include diet, substance use, malnutrition, physical activity and maltreatment including interpersonal violence.', ifelse(Risk == 'Metabolic risks', 'Metabolic risks include high blood pressure, body mass index, low-density lipoprotein, and impaired kidney function.', ifelse(Risk == 'Burden not attributable to GBD risk factors', 'The GBD study is not able to study every possible risk factor for each condition/impairment and as such there will always be some unexplained variation for some of the burden. Some conditions are well understood than others and it is useful to understand how much of the burden of a disease we think can be explained by known risk factors.', NA))))) %>% 
  mutate(Risk = factor(Risk, level = c('Environmental/occupational risks', 'Behavioral risks', 'Metabolic risks', 'Burden not attributable to GBD risk factors'))) %>% 
  arrange(Risk)

level_1_risk_summary %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/level_1_risk_2017_', gsub(" ", "_", tolower(Area_x)), '_summary.json'))

level_2_risk_summary <- GBD_risk_data_all_cause_NN %>% 
  filter(Area == Area_x) %>% 
  filter(Year == 2017) %>% 
  filter(Risk_level == 2) %>% 
  filter(metric == 'Number') %>% 
  filter(Sex == 'Both') %>% 
  select(-c(Upper_estimate, Lower_estimate)) %>% 
  left_join(Total_burden, by = 'measure') %>% 
  mutate(`Proportion burden explained by risk` = Estimate / Total) %>% 
  mutate(Measure = ifelse(measure == 'Deaths', 'deaths', ifelse(measure == 'YLLs (Years of Life Lost)', 'YLLs', ifelse(measure == 'YLDs (Years Lived with Disability)', 'YLDs', ifelse(measure == 'DALYs (Disability-Adjusted Life Years)', 'DALYs', NA))))) %>% 
  select(Risk, measure, Measure, Estimate, Total, `Proportion burden explained by risk`) %>% 
  mutate(label = paste0('This group of risks was estimated to be responsible for <font color = "#1e4b7a"><b>', format(round(Estimate,0), big.mark = ',', trim = TRUE), '</font></b> ', Measure, ' which represents <b>', round(`Proportion burden explained by risk` * 100,1), '% of all ', Measure, '</b> in 2017 (', format(round(Total,0), big.mark = ',', trim = TRUE), ' ', Measure, ').')) %>% 
  select(Risk, measure, label) %>% 
  spread(measure, label) %>% 
  mutate(Description = ifelse(Risk == 'Dietary risks', 'Dietary risks include low intake of whole grains, fruits and vegetables, nuts and seeds, fibre, calcium, and omega 3 as well as high intake of processed and red meat, sodium, trans fats and sugar.', ifelse(Risk == 'Tobacco use', 'Tobaaco use includes smoking tobacco as well as chewing tobacco and exposure to secondhand smoke.', ifelse(Risk == 'Air pollution', 'Air pollution is split into particulate matter exposure as well as ozone', ifelse(Risk == 'Occupational risks', 'Occupational risks include exposure to occupational carcinogens, particulates, asthmagens and noise as well as occupational injury.', ifelse(Risk == 'Malnutrition', 'Malnutrition includes iron, zinc and vitamin A deficiency, low birth weight and short gestation, as well as suboptimal breastfeeding.', ifelse(Risk == 'Other environmental risks', 'Other environmental risks include exposure to lead and radon.', NA))))))) %>% 
  mutate(Risk = factor(Risk, level = c("Air pollution", "Occupational risks", "Other environmental risks",  "Unsafe water, sanitation, and handwashing", "Alcohol use", "Childhood maltreatment", "Dietary risks", "Drug use", "Intimate partner violence", "Low physical activity", "Child and maternal malnutrition", "Tobacco", "Unsafe sex", "High systolic blood pressure", "High body-mass index", "High fasting plasma glucose", "High LDL cholesterol","Impaired kidney function", "Low bone mineral density"))) %>% 
  arrange(Risk)

level_2_risk_summary  %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/level_2_risk_2017_', gsub(" ", "_", tolower(Area_x)), '_summary.json'))

# Overlap

Overlap_df <- read_csv('/Users/richtyler/Documents/GBD_data_download/Risk/Risk_overlap_data.csv', col_types = cols(Location = col_character(),Year = col_double(),Age = col_character(),Sex = col_character(),`Cause of death or injury` = col_character(),  `Attributable to` = col_character(), Measure = col_character(),Value = col_double())) %>% 
  rename(Cause = `Cause of death or injury`,
         Risk = `Attributable to`)

Overlap_df %>% 
  filter(Risk %in% c('Burden attributable to GBD risk factors', 'Burden not attributable to GBD risk factors')) %>% 
  mutate(Type = ifelse(substr(Measure, 0, 7) == 'Percent', 'Proportion', 'Number')) %>%
  mutate(Measure = gsub('Percent of total ', '', Measure)) %>% 
  spread(Type, Value) %>% 
  group_by(Measure, Sex, Year, Cause) %>% 
  mutate(Total_burden = sum(Number, na.rm = TRUE)) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/level_2_risk_explained_burden_2017_', gsub(" ", "_", tolower(Area_x)), '.json'))

explained <- Overlap_df %>% 
  filter(Risk %in% c('Burden attributable to GBD risk factors', 'Burden not attributable to GBD risk factors')) %>% 
  mutate(Type = ifelse(substr(Measure, 0, 7) == 'Percent', 'Proportion', 'Number')) %>%
  mutate(Measure = gsub('Percent of total ', '', Measure)) %>% 
  spread(Type, Value) %>% 
  filter(Number != 0)

Overlap_df%>%
  filter(Risk  != 'Burden attributable to GBD risk factors') %>% 
  filter(!grepl('attributable to GBD risk factors', Measure)) %>%
  mutate(Risk = gsub('∩', '&', Risk)) %>% 
  mutate(Type = ifelse(substr(Measure, 0, 7) == 'Percent', 'Proportion', 'Number')) %>%
  mutate(Measure = gsub('Percent of total ', '', Measure)) %>% 
  spread(Type, Value) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/level_1_2_risk_2017_', gsub(" ", "_", tolower(Area_x)), '_overlap.json'))

Working_df <- Overlap_df%>%
  filter(Risk  != 'Burden attributable to GBD risk factors') %>% 
  filter(!grepl('attributable to GBD risk factors', Measure)) %>%
  mutate(Risk = gsub('∩', '&', Risk)) %>% 
  mutate(Type = ifelse(substr(Measure, 0, 7) == 'Percent', 'Proportion', 'Number')) %>%
  mutate(Measure = gsub('Percent of total ', '', Measure)) %>% 
  spread(Type, Value) %>% 
  filter(Cause == 'All causes') %>% 
  filter(Measure == 'Deaths')

Overall_overlap_a <- Working_df %>% 
  group_by(Cause, Measure) %>% 
  filter(grepl('Environment', Risk)) %>% 
  summarise(Number = sum(Number, na.rm = TRUE)) %>% 
  mutate(Risk = 'Environment/Occupational risks') %>% 
  select(Risk, Cause, Measure, Number) %>% 
  mutate(sets = '[0]')

Overall_overlap_b <- Working_df %>% 
  group_by(Cause, Measure) %>% 
  filter(grepl('Behavioral', Risk)) %>% 
  summarise(Number = sum(Number, na.rm = TRUE)) %>% 
  mutate(Risk = 'Behavioral risks') %>% 
  select(Risk, Cause, Measure, Number) %>% 
  mutate(sets = '[1]')

Overall_overlap_c <- Working_df %>% 
  group_by(Cause, Measure) %>% 
  filter(grepl('Metabolic', Risk)) %>% 
  summarise(Number = sum(Number, na.rm = TRUE))  %>% 
  mutate(Risk = 'Metabolic risks') %>% 
  select(Risk, Cause, Measure, Number) %>% 
  mutate(sets = '[2]')

Overall_overlap_d <- Working_df %>% 
  filter(Risk == 'Burden not attributable to GBD risk factors') %>% 
  select(Risk, Cause, Measure, Number) %>% 
  mutate(sets = '[3]')

Overall_overlap_e <- Working_df %>% 
  filter(Risk == 'Behavioral & Environmental')%>% 
  select(Risk, Cause, Measure, Number) %>% 
  mutate(sets = '[0,1]')
 
Overall_overlap_f <- Working_df %>% 
  filter(Risk == 'Environmental & Metabolic')%>% 
  select(Risk, Cause, Measure, Number) %>% 
  mutate(sets = '[0,2]')

Overall_overlap_g <- Working_df %>% 
  filter(Risk == 'Behavioral & Environmental & Metabolic')%>% 
  select(Risk, Cause, Measure, Number) %>% 
  mutate(sets = '[0,1,2]')

Overall_overlap_h <- Working_df %>% 
  filter(Risk == 'Behavioral & Metabolic')%>% 
  select(Risk, Cause, Measure, Number) %>% 
  mutate(sets = '[1,2]')

Overall_overlap <- Overall_overlap_a %>% 
  bind_rows(Overall_overlap_b) %>% 
  bind_rows(Overall_overlap_c) %>% 
  bind_rows(Overall_overlap_d) %>% 
  bind_rows(Overall_overlap_e) %>% 
  bind_rows(Overall_overlap_f) %>% 
  bind_rows(Overall_overlap_g) %>% 
  bind_rows(Overall_overlap_h) 

# Overall_overlap %>% 
#   toJSON() %>% 
#   write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/all_cause_risk_2017_', gsub(" ", "_", tolower(Area_x)), '_overlap.json'))

# Age standardised top 10.

top_ten <- GBD_risk_data_all_cause_NN %>% 
  filter(Year == 2017) %>% 
  # filter(Area == Area_x) %>%
  filter(Risk_level == 2) %>% 
  filter((Age == 'Age-standardized') | (Age == 'All Ages' & metric == 'Number')) %>% 
  mutate(metric = ifelse(metric == 'Rate per 100,000 population', 'Age-standardised rate per 100,000', ifelse(metric == 'Number', 'Number (all ages)', NA))) %>% 
  group_by(Area, Sex, Year, Cause, measure, metric) %>% 
  mutate(Rank = rank(-Estimate)) %>% 
  mutate(Estimate = ifelse(metric == 'Age-standardised rate per 100,000', format(round(Estimate,1),big.mark = ',', trim = TRUE), ifelse(metric == 'Number (all ages)', format(round(Estimate,0), big.mark = ',', trim = TRUE), NA))) %>% 
  mutate(Lower_estimate = ifelse(metric == 'Age-standardised rate per 100,000', format(round(Lower_estimate,1), big.mark = ',', trim = TRUE), ifelse(metric == 'Number (all ages)', format(round(Lower_estimate,0), big.mark = ',', trim = TRUE), NA))) %>% 
  mutate(Upper_estimate = ifelse(metric == 'Age-standardised rate per 100,000', format(round(Upper_estimate,1), big.mark = ',', trim = TRUE), ifelse(metric == 'Number (all ages)', format(round(Upper_estimate,0), big.mark = ',', trim = TRUE), NA))) %>% 
  mutate(Estimate_label = paste0(Estimate, ' (', Lower_estimate, '-', Upper_estimate, ')')) %>% 
  ungroup() %>%
  filter(metric == 'Age-standardised rate per 100,000') %>% 
  select(-c(Lower_estimate, Upper_estimate, Age, Year, Risk_level)) %>% 
  mutate(Estimate = as.numeric(gsub(',', '', Estimate))) %>% 
  mutate(Estimate = replace_na(Estimate, 0)) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/level_2_risk_all_cause_NN_2017.json'))

GBD_risk_data_wsx %>% 
  filter(Year == 2017) %>% 
  filter(Area == Area_x) %>% 
  filter(Cause_level %in% c(0,2)) %>% 
  filter((Age == 'Age-standardized') | (Age == 'All Ages' & metric == 'Number')) %>% 
  mutate(metric = ifelse(metric == 'Rate per 100,000 population', 'Age-standardised rate per 100,000', ifelse(metric == 'Number', 'Number (all ages)', NA))) %>% 
  group_by(Area, Sex, Risk_level, Year, Cause, measure, metric) %>% 
  filter(Estimate > 0) %>% 
  mutate(Rank = rank(-Estimate)) %>% 
  mutate(Estimate = ifelse(metric == 'Age-standardised rate per 100,000', format(round(Estimate,1),big.mark = ',', trim = TRUE), ifelse(metric == 'Number (all ages)', format(round(Estimate,0), big.mark = ',', trim = TRUE), NA))) %>% 
  mutate(Lower_estimate = ifelse(metric == 'Age-standardised rate per 100,000', format(round(Lower_estimate,1), big.mark = ',', trim = TRUE), ifelse(metric == 'Number (all ages)', format(round(Lower_estimate,0), big.mark = ',', trim = TRUE), NA))) %>% 
  mutate(Upper_estimate = ifelse(metric == 'Age-standardised rate per 100,000', format(round(Upper_estimate,1), big.mark = ',', trim = TRUE), ifelse(metric == 'Number (all ages)', format(round(Upper_estimate,0), big.mark = ',', trim = TRUE), NA))) %>% 
  mutate(Estimate_label = paste0(Estimate, ' (', Lower_estimate, '-', Upper_estimate, ')')) %>% 
  ungroup() %>%
  filter(metric == 'Age-standardised rate per 100,000') %>% 
  filter(Risk_level %in% c(2,3)) %>% 
  select(-c(Lower_estimate, Upper_estimate, Age, Cause_level, metric, Year)) %>% 
  mutate(Estimate = as.numeric(gsub(',', '', Estimate))) %>% 
  mutate(Rank_label = ifelse(Rank == 1, 'largest ', paste0(ordinal_format()(Rank), ' largest '))) %>%
  mutate(Risk_colour = ifelse(Risk_level == 2, Risk, ifelse(Risk_level == 3, `Risk group`, NA)))  %>% 
  group_by(Area, Sex, Cause, Risk_level, measure) %>% 
  mutate(Number_of_negative_risks = n())  %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/GBD/Risks_causes_NN_2017.json'))
