library(tidyverse)
source("R/utils.R")

oc_df_long <- clean_cases_data()
# weights matrix 
PATH = "outputs/out_by_zip"

load_data <- function(path) { 
  files <- dir(path, pattern = '\\.csv', full.names = TRUE)
  zip_codes <- str_remove(files, pattern = "outputs/out_by_zip/")
  zip_codes <- str_remove(zip_codes, pattern = ".csv")
  tables <- lapply(files, read_csv, show_col_types=F)
  names(tables) <- zip_codes
  return(tables)
}

get_weights_row <- function(df){
  row_weight <- df %>%
    group_by(origin_zip) %>%
    summarize(
      poi_zip=first(poi_zip),
      total_visits = sum(number_of_visits)
    ) %>%
    pivot_wider(
      names_from = "origin_zip",
      values_from="total_visits"
    )
  return(row_weight)
}

weights_dfs <- load_data(PATH)
weights_rows <- lapply(weights_dfs, FUN=get_weights_row)

# from rows that don't have a column and from 
# the zip code list below
remove_from_weights <- c("92870","92886","92887","92604")
overall_weights <- as.matrix(
  bind_rows(weights_rows) %>%
    select(-`11111`) %>% 
    column_to_rownames(., var = "poi_zip") %>% 
    replace(is.na(.),0) %>% 
    select(-remove_from_weights) %>% 
    filter(!(row.names(.) %in% remove_from_weights)) %>% 
    filter(row.names(.) %in% colnames(.))
)

# there are some ZIP codes that are not in 
# one dataset and are in the other or viceversa.
# for first pass I will make them both equal

remove_from_cases <- c(
  "90680","90742","92602","92624","92655","92661" ,"92861"
)

oc_red_matrix <- oc_df_long %>%
  select(-colnames(.)[
    !(colnames(.) %in% colnames(overall_weights))])

overall_weights <- overall_weights[,colnames(oc_df_long_red)]

# sts object with no weights
oc_zip_covid <- 
  sts(observed = oc_red_matrix,
      start = c(2020,3/15),
      epoch = oc_df_long$start_date,
      frequency = 52,
      neighbourhood = overall_weights
      )

oc_hhh4_sum_weights <- surveillance::hhh4(
  oc_zip_covid,
  control=list(
    weights=neighbourhood(oc_zip_covid))
)
plot(oc_hhh4_sum_weights)
summary(oc_hhh4_sum_weights)
saveRDS(oc_hhh4,"outputs/hhh4_models/sumweights.RDS")


predict(
  oc_hhh4_sum_weights,
  oc_hhh4_sum_weights$control$subset
)
        

oc_hhh4_sum_weights_nb <- surveillance::hhh4(
  oc_zip_covid,
  control=list(
    weights=neighbourhood(oc_zip_covid),
    family="NegBin1",
    normalize=TRUE
  )
)
summary(oc_hhh4_sum_weights_nb)


oc_hhh4_sum_weights_ne <- surveillance::hhh4(
  oc_zip_covid,
  control=list(
    ne=list(f=~1,weights=neighbourhood(oc_zip_covid)),
    weights=neighbourhood(oc_zip_covid),
    family="NegBin1",
    normalize=TRUE
  )
)
summary(oc_hhh4_sum_weights_ne)



#Time-varying weights are possible by specifying an array
#of dim() c(nUnits,nUnits,nTime), where nUnits=ncol(stsObj)
#and nTime=nrow(stsObj).

