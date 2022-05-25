library(tidyverse)
library(surveillance)
source("R/utils.R")


# try out on our dataset
oc_red_matrix <- reduced_cases_data()
# Creating map object
oc_census_data <- get_census_data()
sp_census_data <- sf::as_Spatial(oc_census_data)

# sts object with no weights
oc_zip_covid <- 
  sts(
    observed = oc_red_matrix,
    start = c(2020, 3 / 15),
    frequency = 52,
    map = sp_census_data
)
oc_hhh4 <-
  surveillance::hhh4(oc_zip_covid)

plot(oc_hhh4)
plot(oc_hhh4, "map")
summary(oc_hhh4)
saveRDS(oc_hhh4, "outputs/hhh4_models/noweights.RDS")
