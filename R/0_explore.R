library(tidyverse)
library(surveillance)

#example from the package documentation
data("measlesWeserEms")
plot(measlesWeserEms)


clean_cases_data <- function(){
  #try out on our dataset
  oc_df <- read_csv("data/oc_covid_data_zip_weekly.csv")
  # look only at 30
  oc_df <- oc_df %>%
    filter(end_date <= "2021-01-01" & start_date >= "2020-03-01") 
  oc_df_long <- oc_df %>%
    select(-c(tests,deaths)) %>% 
    pivot_wider(names_from = "zip",values_from="cases")
  return(oc_df_long)
}


#try out on our dataset
oc_df <- read_csv("data/oc_covid_data_zip_weekly.csv")
# look only at 30
oc_df <- oc_df %>%
  filter(end_date <= "2021-01-01" & start_date >= "2020-03-01") 


# make sts object
# no spatial dependency
oc_covid <- with(
  oc_df,
  sts(observed = oc_df$cases,
      epoch = start_date,
      frequency = 52)
)

plot(oc_covid)
autoplot(oc_covid) + theme_bw()
 

# two time series
oc_covid_test <- with(
  oc_df,
  sts(observed = matrix(c(cases=oc_df$cases,oc_df$deaths),ncol=2),
      start = c(2020, 3/15),
      epoch = start_date,
      frequency = 52)
)
# no weights model
oc_overall <- surveillance::hhh4(oc_covid)
summary(oc_overall)
plot(oc_overall)


# actually split by zip code:

oc_df_long <- oc_df %>%
  select(-c(tests,deaths)) %>% 
  pivot_wider(names_from = "zip",values_from="cases")
  

# create the sts object by zip code

oc_zip_covid <- with(
  oc_df_long,
  sts(observed = oc_df_long[,c(4:85)],
      epoch = start_date,
      frequency = 52)
)
plot(oc_zip_covid)

autoplot(oc_zip_covid)

autoplot(oc_zip_covid, as.one=TRUE) + theme_bw()
stsplot_time(oc_zip_covid, as.one=TRUE)


oc_hhh4 <- surveillance::hhh4(oc_zip_covid)
plot(oc_hhh4)
summary(oc_hhh4)





