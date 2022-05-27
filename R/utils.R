library(tidyverse)
library(surveillance)


# oc_zips -----------------------------------------------------------------
oc_zips <- c(
  90620L, 90621L, 90623L, 90630L, 90631L, 90680L, 90720L, 90740L, 90742L,
  92602L, 92603L, 92604L, 92606L, 92610L, 92612L, 92614L, 92617L, 92618L,
  92620L, 92624L, 92625L, 92626L, 92627L, 92629L, 92630L, 92637L, 92646L,
  92647L, 92648L, 92649L, 92651L, 92653L, 92655L, 92656L, 92657L, 92660L,
  92661L, 92662L, 92663L, 92672L, 92673L, 92675L, 92677L, 92679L, 92683L,
  92688L, 92691L, 92692L, 92694L, 92701L, 92703L, 92704L, 92705L, 92706L,
  92707L, 92708L, 92780L, 92782L, 92801L, 92802L, 92804L, 92805L, 92806L,
  92807L, 92808L, 92821L, 92823L, 92831L, 92832L, 92833L, 92835L, 92840L,
  92841L, 92843L, 92844L, 92845L, 92861L, 92865L, 92866L, 92867L, 92868L,
  92869L, 92870L, 92886L, 92887L
)

oc_zips_considered <- c(
  90620L, 90621L, 90623L, 90630L, 90631L, 90720L, 90740L, 92603L, 92606L,
  92610L, 92612L, 92614L, 92617L, 92618L, 92620L, 92625L, 92626L, 92627L,
  92629L, 92630L, 92637L, 92646L, 92647L, 92648L, 92649L, 92651L, 92653L,
  92656L, 92657L, 92660L, 92662L, 92663L, 92672L, 92673L, 92675L, 92677L,
  92679L, 92683L, 92688L, 92691L, 92692L, 92694L, 92701L, 92703L, 92704L,
  92705L, 92706L, 92707L, 92708L, 92780L, 92782L, 92801L, 92802L, 92804L,
  92805L, 92806L, 92807L, 92808L, 92821L, 92823L, 92831L, 92832L, 92833L,
  92835L, 92840L, 92841L, 92843L, 92844L, 92845L, 92865L, 92866L, 92867L,
  92868L, 92869L
)

#L, 2020 cases data OC -------------------------------------------------
clean_cases_data <- function() {
  # try out on our dataset
  oc_df <- read_csv(
    "data/oc_covid_data_zip_weekly.csv",
    show_col_types = FALSE
  )
  # look only at 2020
  oc_df <- oc_df %>%
    filter(end_date <= "2021-01-01" & start_date >= "2020-03-01")
  oc_df_long <- oc_df %>%
    select(-c(tests, deaths)) %>%
    pivot_wider(names_from = "zip", values_from = "cases")
  return(oc_df_long)
}

reduced_cases_data <- function() {
  # only complete zips
  df <- clean_cases_data() %>%
    select(-colnames(.)[
      !(colnames(.) %in% oc_zips_considered)
    ])
}


# load out visits data from files ------------------------------------------
PATH <- "outputs/out_by_zip"
load_data <- function(path) {
  files <- dir(path, pattern = "\\.csv", full.names = TRUE)
  zip_codes <- str_remove(files, pattern = "outputs/out_by_zip/")
  zip_codes <- str_remove(zip_codes, pattern = ".csv")
  tables <- lapply(files, read_csv, show_col_types = F)
  names(tables) <- zip_codes
  return(tables)
}

get_weights_row <- function(df) {
  row_weight <- df %>%
    group_by(origin_zip) %>%
    summarize(
      poi_zip = first(poi_zip),
      total_visits = sum(number_of_visits)
    ) %>%
    pivot_wider(
      names_from = "origin_zip",
      values_from = "total_visits"
    )
  return(row_weight)
}

## more helper functions to make the weights array matrix for time varying
# helper function to make array creation easier.
assign_week_number <- function(df){
  tmp <- df %>%
    group_by(origin_zip) %>%
    filter(
      (
        date_range_start < "2021-12-20") &
        (date_range_start > "2020-03-16")
    ) %>%
    mutate(
      week = match(date_range_start, unique(date_range_start))
    ) %>% 
    ungroup() %>% 
    filter(origin_zip %in% all_of(oc_zips_considered))
  return(tmp)
}

get_weights_mat <- function(df,i) {
  mat_weight <- df %>%
    filter(week==i)%>% 
    group_by(origin_zip) %>%
    summarize(
      poi_zip = first(poi_zip),
      total_visits = sum(number_of_visits)
    ) %>%
    pivot_wider(
      names_from = "origin_zip",
      values_from = "total_visits"
    )
  return(mat_weight)
}






# get census data polygons
# oc_census_data polygons
# @damonbayer's code
readRenviron("~/.Renviron")
options(tigris_use_cache = TRUE)

get_census_data <- function() {
  oc_census_data <- get_acs(
    geography = "zip code tabulation area",
    state = "06",
    variables = c(
      total_population = "DP05_0001P"
    ),
    output = "wide",
    geometry = T,
    year = 2016
  )
  oc_census_data <- 
    oc_census_data %>%
    mutate(GEOID = as.integer(GEOID)) %>%
    filter(GEOID %in% oc_zips_considered) %>%
    arrange(match(GEOID, oc_zips_considered))
  row.names(oc_census_data) <- oc_zips_considered
  return(oc_census_data)
}
