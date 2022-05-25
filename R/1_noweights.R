library(tidyverse)
library(surveillance)
source("R/utils.R")


#try out on our dataset
oc_df_long <- clean_cases_data()

# sts object with no weights
oc_zip_covid <- with(
  oc_df_long,
  sts(observed = oc_df_long[,c(4:85)],
      start = c(2020,3/15),
      epoch = start_date,
      frequency = 52)
)


oc_hhh4 <- surveillance::hhh4(oc_zip_covid)
plot(oc_hhh4)
summary(oc_hhh4)
oc_hhh4$fitted.values


saveRDS(oc_hhh4,"outputs/hhh4_models/noweights.RDS")
