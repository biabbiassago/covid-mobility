library(tidyverse)
library(surveillance)


clean_cases_data <- function(){
  #try out on our dataset
  oc_df <- read_csv(
    "data/oc_covid_data_zip_weekly.csv",
    show_col_types = FALSE
  )
  # look only at 2020
  oc_df <- oc_df %>%
    filter(end_date <= "2021-01-01" & start_date >= "2020-03-01") 
  oc_df_long <- oc_df %>%
    select(-c(tests,deaths)) %>% 
    pivot_wider(names_from = "zip",values_from="cases")
  return(oc_df_long)
}

