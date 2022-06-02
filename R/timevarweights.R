### TO DO:
### FIGURE OUT ARRAY
### COEFFICIENTS INTERPRETATION


library(tidyverse)
library(surveillance)
source("R/utils.R")

ZIP_COUNT <- length(oc_zips_considered)
WEEKS_COUNT <-40

oc_df_long <- clean_cases_data()

# weights matrix
weights_dfs <- load_data(PATH)
weights_dfs <- weights_dfs[
  names(weights_dfs) %in% oc_zips_considered
]

weights_dfs <- lapply(weights_dfs, FUN= assign_week_number)

# For time-varying weights, hhh4 takes as argument 
# an array of dimensions c(units, units, period_counts)

weights_array <- array(NA,dim(ZIPS_COUNT,ZIPS_COUNT,WEEKS_COUNT))
for(i in 1:WEEKS_COUNT){
  weights_rows <- lapply(weights_dfs, FUN = get_weights_mat,i)
  weekly_matrix <- as.matrix(
    bind_rows(weights_rows) %>%
      column_to_rownames(., var = "poi_zip") %>%
      replace(is.na(.), 0)
  )
  weights_array[,,i] <- weekly_matrix
}


oc_red_matrix <- oc_df_long %>%
  select(-colnames(.)[
    !(colnames(.) %in% oc_zips_considered)
  ])


# Creating map object
oc_census_data <- get_census_data()
sp_census_data <- sf::as_Spatial(oc_census_data)

#oc_nb <- poly2nb(oc_census_data)
#binary_matrix <- nb2mat(neighbours = oc_nb, style = "B")
#row.names(binary_matrix) <- colnames(binary_matrix) <- oc_zips_considered

# sts object with time-varying weights
oc_zip_covid <-
  sts(
    observed = oc_red_matrix,
    start = c(2020, 3 / 15),
    epoch = oc_df_long$start_date,
    frequency = 52,
    neighbourhood = weights_array,
    map = sp_census_data
  )

# NOTE: sts object class does not take an array as an object for neighbourhood. Therefore,
# the weighs array needs to be passed separately in the model as an stand-alone object.

hhh4_timeweights_nb <- surveillance::hhh4(
  oc_zip_covid,
  control = list(
    ar = list(f = ~1),
    f = ~1,
    ne = list(f = ~ 1,weights = weights_array),
    family = "NegBin1"
  )
)
summary(hhh4_timeweights_nb)
