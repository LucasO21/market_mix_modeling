# MARKET MIX MODELING: CASSANDRA TUTORIAL
# ROBYN SETUP SCRIPT:
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

# *****************************************************************************
# **** ----
# CREATE VIRTUAL ENV ----
# *****************************************************************************

# Setup Option 1: Directions on github ----
# conda_create("r_reticulate_mmm_cassandra")
# py_install("nevergrad", pip = TRUE)

# Setup Option 2: Using Terminal ----
# Run the code below in terminal
# python3 -m venv ~/.virtualenvs/r_reticulate_mmm_cassandra
# source ~/.virtualenvs/r_reticulate_mmm_cassandra/bin/activate
# pip list; to check packages installed

use_virtualenv("r_reticulate_mmm_cassandra", required = TRUE)




# *****************************************************************************
# **** ----
# SECTION NAME ----
# *****************************************************************************
# *****************************************************************************
# **** ----
# SECTION NAME ----
# *****************************************************************************
# *****************************************************************************
# **** ----
# SECTION NAME ----
# *****************************************************************************
