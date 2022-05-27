source("R/utils.R")

library(spdep)
library(tidyverse)
library(surveillance)

oc_df_long <- clean_cases_data()
oc_cases <- reduced_cases_data()

# Create Binary Weight Matrix
oc_census_data <- get_census_data()
oc_nb <- poly2nb(oc_census_data)
binary_matrix <- nb2mat(neighbours = oc_nb, style = "B")
row.names(binary_matrix) <- colnames(binary_matrix) <- oc_zips_considered

# For mapping purposes
sp_census_data <- sf::as_Spatial(oc_census_data)

# Create the STS object with binary weights
oc_zip_covid <-
  sts(
    observed = oc_cases,
    start = c(2020, 3 / 15),
    epoch = oc_df_long$start_date,
    frequency = 52,
    map= sp_census_data,
    neighbourhood = binary_matrix
  )

# Negative Binomial
hhh4_binweights_nb <- surveillance::hhh4(
  oc_zip_covid,
  control = list(
    ar = list(f = ~1),
    ne = list(
      f = ~ 1,
      weights = neighbourhood(oc_zip_covid),
      family = "NegBin1",
      normalize = TRUE
    )
  )
)

plot(hhh4_binweights_nb)
summary(hhh4_binweights_nb)
plot(hhh4_binweights_nb, type = "maps")



# Poisson
hhh4_binweights_poi <- surveillance::hhh4(
  oc_zip_covid,
  control = list(
    ne = list(
      ar = list(f = ~1),
      f = ~ 1,
      weights = neighbourhood(oc_zip_covid),
      family = "Poisson",
      normalize = TRUE
    )
  )
)

plot(hhh4_binweights_poi)
summary(hhh4_binweights_poi)
plot(hhh4_binweights_nb, type = "maps")

saveRDS(hhh4_binweights_poi, "outputs/hhh4_models/binweights_poisson.RDS")
saveRDS(hhh4_binweights_nb, "outputs/hhh4_models/binweights_nb.RDS")