
library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "png", "tidyverse", "reshape2", "scales", "viridis", "rgdal", "officer", "flextable", "tmaptools", "lemon", "fingertipsR", "jsonlite"))

data_directory <- './Source_files/Raw'

meta_directory <- './Source_files'

# download.file('http://ghdx.healthdata.org/sites/default/files/ihme_query_tool/IHME_GBD_2019_CODEBOOK.zip', destfile = paste0(meta_directory, '/codebook.zip'), mode = 'wb')
# unzip(paste0(meta_directory, '/codebook.zip'), exdir = meta_directory)

list.files('./Source_files')









# impairment data

if(!(file.exists("~/GBD data downloads/IHME-GBD_2017_DATA-0f178e33-34.csv"))){
impairment_files = 34

for(i in 1:impairment_files){
download.file(paste0("http://s3.healthdata.org/gbd-api-2017-public/0f178e33785a9f50c01c9def1c03dfb9_files/IHME-GBD_2017_DATA-0f178e33-", i , ".zip"), paste0("~/GBD data downloads/impairment_file_",i,".zip"), mode = "wb")
  unzip(paste0("~/GBD data downloads/impairment_file_",i,".zip"), exdir = "~/GBD data downloads")
  file.remove(paste0("~/GBD data downloads/impairment_file_",i,".zip"))
}

}

# impairment_df <- unique(list.files("~/GBD data downloads")[grepl("0f178e33", list.files("~/GBD data downloads/")) == TRUE]) %>%
#  map_df(~read_csv(paste0("~/GBD data downloads/",.)))

if(!(file.exists("~/GBD data downloads/IHME-GBD_2017_DATA-e004c73d-11.csv"))){
mortality_files = 11 

for(i in 1:mortality_files){
  download.file(paste0("http://s3.healthdata.org/gbd-api-2017-public/e004c73d48d84b69fc85d6d3955a93e1_files/IHME-GBD_2017_DATA-e004c73d-", i , ".zip"), paste0("~/GBD data downloads/mortality_file_",i,".zip"), mode = "wb")
  unzip(paste0("~/GBD data downloads/mortality_file_",i,".zip"), exdir = "~/GBD data downloads")
  file.remove(paste0("~/GBD data downloads/mortality_file_",i,".zip"))
}
}

# mortality_df <- unique(list.files("~/GBD data downloads")[grepl("dce9e906", list.files("~/GBD data downloads/")) == TRUE]) %>% 
#   map_df(~read_csv(paste0("~/GBD data downloads/",.)))
http://s3.healthdata.org/gbd-api-2017-public/dce9e9067631bf55f9745237627df9c8_files/IHME-GBD_2017_DATA-dce9e906-


# if(!(file.exists("~/GBD data downloads/IHME-GBD_2017_DATA-dce9e906-10.csv"))){
#   mortality_wsx_files = 10
# for(i in 3:mortality_wsx_files){
#   download.file(paste0("http://s3.healthdata.org/gbd-api-2017-public/dce9e9067631bf55f9745237627df9c8_files/IHME-GBD_2017_DATA-dce9e906-", i , ".zip"), paste0("~/GBD data downloads/mortality_wsx_files",i,".zip"), mode = "wb")
#   unzip(paste0("~/GBD data downloads/mortality_wsx_files",i,".zip"), exdir = "~/GBD data downloads")
#   file.remove(paste0("~/GBD data downloads/mortality_wsx_files",i,".zip"))
# }
# }

# mortality_wsx_df <- unique(list.files("~/GBD data downloads")[grepl("dce9e906", list.files("~/GBD data downloads/")) == TRUE]) %>% 
#   map_df(~read_csv(paste0("~/GBD data downloads/",.)))

# if(!(file.exists("~/GBD data downloads/IHME-GBD_2017_DATA-0f1da8e2-231.csv"))){
#   mortality_files_all_age = 231   
# for(i in 88:mortality_files_all_age){
#   download.file(paste0("http://s3.healthdata.org/gbd-api-2017-public/0f1da8e2f4a06cae620ed9b9feb55600_files/IHME-GBD_2017_DATA-0f1da8e2-", i , ".zip"), paste0("~/GBD data downloads/mortality_files_all_age",i,".zip"), mode = "wb")
#   unzip(paste0("~/GBD data downloads/mortality_files_all_age",i,".zip"), exdir = "~/GBD data downloads")
#   file.remove(paste0("~/GBD data downloads/mortality_files_all_age",i,".zip"))
# }
# }

# mortality_df <- unique(list.files("~/GBD data downloads")[grepl("0f1da8e2", list.files("~/GBD data downloads/")) == TRUE]) %>% 
#   map_df(~read_csv(paste0("~/GBD data downloads/",.)))

if(!(file.exists("./GBD data downloads/IHME-GBD_2017_DATA-b475904c-22.csv"))){
risk_files = 22
for(i in 1:risk_files){
  download.file(paste0("http://s3.healthdata.org/gbd-api-2017-public/b475904cadeca9cccc4b12c1a7a72197_files/IHME-GBD_2017_DATA-b475904c-", i , ".zip"), paste0("~/GBD data downloads/risk_files",i,".zip"), mode = "wb")
  unzip(paste0("./GBD data downloads/risk_files",i,".zip"), exdir = "./GBD data downloads")
  file.remove(paste0("./GBD data downloads/risk_files",i,".zip"))
}
}

# risk_df <- unique(list.files("~/GBD data downloads")[grepl("b475904c", list.files("~/GBD data downloads/")) == TRUE]) %>% 
#   map_df(~read_csv(paste0("~/GBD data downloads/",.)))


if(!(file.exists("~/GBD data downloads/IHME-GBD_2017_DATA-d07dcbe7-19.csv"))){
  risk_files = 19
  for(i in 1:risk_files){
    download.file(paste0("http://s3.healthdata.org/gbd-api-2017-public/d07dcbe7dd7b0fc33d6ccc179360edad_files/IHME-GBD_2017_DATA-d07dcbe7-", i , ".zip"), paste0("~/GBD data downloads/risk_files",i,".zip"), mode = "wb")
    unzip(paste0("~/GBD data downloads/risk_files",i,".zip"), exdir = "~/GBD data downloads")
    file.remove(paste0("~/GBD data downloads/risk_files",i,".zip"))
  }
}

# risk_wsx_df <- unique(list.files("~/GBD data downloads")[grepl("d07dcbe7", list.files("~/GBD data downloads/")) == TRUE]) %>%
#   map_df(~read_csv(paste0("~/GBD data downloads/",.)))

# Create a GBD directory ####


