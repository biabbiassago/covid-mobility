library(tidyverse)
library(surveillance)
source("R/utils.R")

oc_df_long <- clean_cases_data()

# weights matrix
weights_dfs <- load_data(PATH)
weights_rows <- lapply(weights_dfs, FUN = get_weights_row)

# from rows that don't have a column and from
# the zip code list below
remove_from_weights <- c(
  "92870", "92886", "92887", "92604"
)

overall_weights <- as.matrix(
  bind_rows(weights_rows) %>%
    select(-`11111`) %>%
    column_to_rownames(., var = "poi_zip") %>%
    replace(is.na(.), 0) %>%
    select(-remove_from_weights) %>%
    filter(!(row.names(.) %in% all_of(remove_from_weights))) %>%
    filter(row.names(.) %in% colnames(.))
)

# there are some ZIP codes that are not in
# one dataset and are in the other or viceversa.
# for first pass I will make them both equal

oc_red_matrix <- oc_df_long %>%
  select(-colnames(.)[
    !(colnames(.) %in% oc_zips_considered)
  ])

overall_weights <- overall_weights[, colnames(oc_red_matrix)]

# Creating map object
oc_census_data <- get_census_data()
sp_census_data <- sf::as_Spatial(oc_census_data)

# sts object with overall weights
oc_zip_covid <-
  sts(
    observed = oc_red_matrix,
    start = c(2020, 3 / 15),
    epoch = oc_df_long$start_date,
    frequency = 52,
    neighbourhood = overall_weights,
    map = sp_census_data
  )


## Fitting the HHH4 Model POISSON FAMILY

hhh4_sumweights_poi <- surveillance::hhh4(
  oc_zip_covid,
  control = list(
    ar = list(f = ~1),
    f = ~1,
    ne = list(weights = neighbourhood(oc_zip_covid)),
    family = "Poisson"
  )
)
plot(hhh4_sumweights_poi)
summary(hhh4_sumweights_poi)
plotHHH4_fitted(hhh4_sumweights_poi)

# Predict on control Subset
predict(
  hhh4_sumweights_poi,
  hhh4_sumweights_poi$control$subset
)

hhh4_sumweights_nb <- surveillance::hhh4(
  oc_zip_covid,
  control = list(
    ar = list(f = ~1),
    ne = list(
      f = ~1,
      weights = neighbourhood(oc_zip_covid),
      family = "NegBin1",
      normalize = TRUE
    )
  )
)
summary(hhh4_sumweights_nb)

plotHHH4_fitted(hhh4_sumweights_nb)
plotHHH4_neweights(hhh4_sumweights_nb)
plot(hhh4_sumweights_nb, type = "maps")

saveRDS(hhh4_sumweights_poi, "outputs/hhh4_models/sumweights_poisson.RDS")
saveRDS(hhh4_sumweights_nb, "outputs/hhh4_models/sumweights_nb.RDS")

# Time-varying weights are possible by specifying an array
# of dim() c(nUnits,nUnits,nTime), where nUnits=ncol(stsObj)
# and nTime=nrow(stsObj).
