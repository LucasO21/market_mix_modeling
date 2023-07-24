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

# * Create Files ----
create_files <- TRUE

# * Robyn Directory ----
robyn_directory <- paste0(
    "~/Desktop/School/2023_projects/market_mix_modeling/",
    "cassandra_tutorials/artifacts/artifacts.RDS"
    
)

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

# * Step 1: Specify Input Variables ----
## - All sign control are now automatically provided: "positive" for media & organic
## - variables and "default" for all others. User can still customize signs if necessary.
## - Documentation is available, access it anytime by running: ?robyn_inputs
InputCollect <- robyn_inputs(
    dt_input          = dt_simulated_weekly,
    dt_holidays       = dt_prophet_holidays,
    
    date_var          = "date", # date format must be "2020-01-01"
    dep_var           = "revenue", # there should be only one dependent variable
    dep_var_type      = "revenue", # "revenue" (ROI) or "conversion" (CPA)
    
    prophet_vars      = c("trend", "season", "holiday"), # "trend","season", "weekday" & "holiday"
    prophet_signs     = c("default", "default", "positive"), 
    prophet_country   = "US", # input country code. Check: dt_prophet_holidays
    
    context_vars      = c("competitor_sales_b", "events"), # e.g. competitors, discount, unemployment etc
    context_signs     = c("default", "default"), 
    
    paid_media_spends = c("tv_s", "ooh_s", "print_s", "facebook_s", "search_s"), # mandatory input
    paid_media_vars   = c("tv_s", "ooh_s", "print_s", "facebook_i", "search_clicks_p"), # mandatory.
    paid_media_signs  = c("positive", "positive", "positive", "positive", "positive"), 
    # Paid_media_vars must have same order as paid_media_spends. 
    # Use media exposure metrics like impressions, GRP etc. 
    # If not applicable, use spend instead.
    
    organic_vars      = c("newsletter"), # marketing activity without media spend
    organic_signs     = c("positive"), 
    
    factor_vars       = c("events"), # force variables in context_vars or organic_vars to be categorical
    
    window_start      = "2016-01-01",
    window_end        = "2018-12-31",
    adstock           = "geometric", # geometric, weibull_cdf or weibull_pdf.
    
    iterations        = 1000,
    # - 2000 suggested for geometric
    # - 4000 for weibull_cdf 
    # - 6000 for weibul_pdf
    
    intercept_sign    = "non_negative", # options include "non_negative" or "unconstrained"
    nevergrad_algo    = "TwoPointsDE",
    trials            = 3,
    
    cores             = 4
)


# * Step 2: Define Hyper-Parameters ----
plot_adstock(plot = FALSE)
plot_saturation(plot = FALSE)

hyper_names(adstock = InputCollect$adstock, all_media = InputCollect$all_media)

hyper_limits() # Run hyper_limits() to check maximum upper and lower bounds by range

hyperparameters <- list(
    
    facebook_s_alphas = c(0.5, 3),
    facebook_s_gammas = c(0.3, 1),
    facebook_s_thetas = c(0, 0.3),
    
    print_s_alphas    = c(0.5, 3),
    print_s_gammas    = c(0.3, 1),
    print_s_thetas    = c(0.1, 0.4),
    
    tv_s_alphas       = c(0.5, 3),
    tv_s_gammas       = c(0.3, 1),
    tv_s_thetas       = c(0.3, 0.8),
    
    search_s_alphas   = c(0.5, 3),
    search_s_gammas   = c(0.3, 1),
    search_s_thetas   = c(0, 0.3),
    
    ooh_s_alphas      = c(0.5, 3),
    ooh_s_gammas      = c(0.3, 1),
    ooh_s_thetas      = c(0.1, 0.4),
    
    newsletter_alphas = c(0.5, 3),
    newsletter_gammas = c(0.3, 1),
    newsletter_thetas = c(0.1, 0.4),
    train_size        = c(0.5, 0.8)
    
)

# ** Notes ----
# - Do not give negative hyper-parameter range for positive variables

# * Step 3: Add Hyper-Parameters into robyn_inputs()

InputCollect <- robyn_inputs(
    InputCollect    = InputCollect, 
    hyperparameters = hyperparameters
)


# * Step 4: Build Initial Model ----
OutputModels <- robyn_run(
    InputCollect       = InputCollect, # feed in all model specification
    # cores              = 4, # NULL defaults to (max available - 1)
    # iterations         = 1000, # 2000 recommended for the dummy dataset with no calibration
    # trials             = 3, # 5 recommended for the dummy dataset
    # ts_validation      = TRUE, # 3-way-split time series for NRMSE validation.
    # add_penalty_factor = FALSE, # Experimental feature. Use with caution.
    outputs            = FALSE
)

# * Step 5: Collect Output ----
OutputCollect <- robyn_outputs(
    InputCollect, OutputModels,
    pareto_fronts = 1, # automatically pick how many pareto-fronts to fill min_candidates (100)
    # min_candidates = 100, # top pareto models for clustering. Default to 100
    # calibration_constraint = 0.1, # range c(0.01, 0.1) & default at 0.1
    csv_out      = "pareto", # "pareto", "all", or NULL (for none)
    clusters     = TRUE, # Set to TRUE to cluster similar models by ROAS. See ?robyn_clusters
    # export      = create_files, # this will create files locally
    plot_folder  = robyn_directory, # path for plots exports and files creation
    plot_pareto  = create_files # Set to FALSE to deactivate plotting and saving model one-pagers
)

# * Show All Models
OutputCollect$allSolutions

# * Step 6: Save Best Model ----
select_model_id <- "5_652_3"
model_object    <- "../artifacts/model_5_652_3.RDS"

robyn_save(
    robyn_object  = model_object,
    select_model  = select_model_id,
    InputCollect  = InputCollect,
    OutputCollect = OutputCollect
)

# * Model Information
# OutputCollect$xDecompAgg[(
#     solID == select_model_id & !is.na(mean_spend),
#     .(rn, coef, mean_spend, mean_response, roi_mean, total_spend,
#       total_response = xDecompAgg, roi_total, solID)
# )]


# *****************************************************************************
# **** ----
# BUDGET ALLOCATION ----
# *****************************************************************************

# * Tutorial Scenario ----
AllocatorCollect <- robyn_allocator(
    InputCollect       = InputCollect,
    OutputCollect      = OutputCollect,
    select_model       = select_model,
    scenario           = "max_historical_response",
    channel_constr_low = c(0.8, 0.7, 0.7, 0.7, 0.7),
    channel_constr_up  = c(1.2, 1.5, 1.5, 1.5, 1.5),
)

# * Scenario 1 ----
# - Scenario "max_response": "What's the max. return given certain spend?"
# - Example 1: max_response default setting: maximize response for latest month
# AllocatorCollect1 <- robyn_allocator(
#     InputCollect       = InputCollect,
#     OutputCollect      = OutputCollect,
#     select_model       = select_model,
#     channel_constr_low = c(0.7, 0.7, 0.7, 0.7),
#     channel_constr_up  = c(1.2, 1.5, 1.5, 1.5, 1.5),
#     scenario           = "max_response",
#     export             = create_files
#     # date_range = NULL, # Default last month as initial period
#     # total_budget = NULL, # When NULL, default is total spend in date_range
#     # channel_constr_multiplier = 3,
#    
# )

# * Scenario 2 ----
# - Maximize response for latest 10 periods with given spend
# AllocatorCollect2 <- robyn_allocator(
#     InputCollect              = InputCollect,
#     OutputCollect             = OutputCollect,
#     select_model              = select_model,
#     date_range                = "last_10", # Last 10 periods, same as c("2018-10-22", "2018-12-31")
#     total_budget              = 5000000, # Total budget for date_range period simulation
#     channel_constr_low        = c(0.8, 0.7, 0.7, 0.7, 0.7),
#     channel_constr_up         = c(1.2, 1.5, 1.5, 1.5, 1.5),
#     channel_constr_multiplier = 5, # Customize bound extension for wider insights
#     scenario                  = "max_response",
#     export                    = create_files
# )



# *****************************************************************************
# **** ----
# MODEL REFRESH
# *****************************************************************************

# * JSON FILE ----
json_file <- "../artifacts/Robyn_202307231613_init/RobynModel-5_652_3.json"

RobynRefresh <- robyn_refresh(
    json_file      = json_file,
    dt_input       = dt_simulated_weekly,
    dt_holidays    = dt_prophet_holidays,
    refresh_steps  = 13,
    refresh_iters  = 1000, # 1k is an estimation
    refresh_trials = 1
)

# *****************************************************************************
# **** ----
# 
# *****************************************************************************

# *****************************************************************************
# **** ----
# 
# *****************************************************************************

# *****************************************************************************
# **** ----
# 
# *****************************************************************************

# *****************************************************************************
# **** ----
# 
# *****************************************************************************
