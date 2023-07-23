# MARKET MIX MODELING: CASSANDRA TUTORIAL
# ROBYN DEMO SCRIPT:
# *** ----

# *****************************************************************************
# SETUP ----
# *****************************************************************************

# * Set Working Dir ----
setwd(here::here("cassandra_tutorials", "scripts"))

# * Libraries ----
library(tidyverse)
library(janitor)
library(reticulate)
library(Robyn)

# * Activate Virtual Env ----
use_virtualenv("r_reticulate_mmm_cassandra", required = TRUE)

# * Force Multicore Use ----
Sys.setenv(R_FUTURE_FORK_ENABLE = "true")
options(future.fork.enable = TRUE)

# Create Files ----
create_files <- TRUE

# Robyn Directory ----
robyn_directory <- "~/Desktop/School/2023_projects_"

# *****************************************************************************
# **** ----
# DATA IMPORT ----
# *****************************************************************************

# * Weekly Data ----
data("dt_simulated_weekly")

dt_simulated_weekly <- dt_simulated_weekly %>% 
    clean_names() %>% 
    as_tibble()

# * Holiday Data ----
data("dt_prophet_holidays")

dt_prophet_holidays <- dt_prophet_holidays %>% 
    clean_names() %>% 
    as_tibble()

dt_prophet_holidays %>% distinct(country) %>% print(n = 100)

# * Notes ----
# - date = date variable
# - revenue = revenue variable
# - variables ending with "_s" = spend variables
# - variables ending with "_i" = impressions. Impressions recommended over clicks
# - competitor_sales_be = competitor variables
# - events = events variables
# - newsletter = newsletter variable



# *****************************************************************************
# **** ----
# MODEL SPECIFICATION ----
# *****************************************************************************





# *****************************************************************************
# **** ----
# SECTION NAME ----
# *****************************************************************************
# *****************************************************************************
# **** ----
# SECTION NAME ----
# *****************************************************************************
