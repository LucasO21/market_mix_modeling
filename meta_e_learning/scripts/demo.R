# MARKET MIX MODELING: CASSANDRA TUTORIAL
# ROBYN DEMO SCRIPT:
# *** ----

# *****************************************************************************
# SETUP ----
# *****************************************************************************

# * Set Working Dir ----
setwd(here::here("meta_e_learning", "scripts"))

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
    "meta_e_learning/artifacts/"
)


# *****************************************************************************
# **** ----
# LOAD DATA ----
# *****************************************************************************

# * Weekly Data ----
data("dt_simulated_weekly")
dt_simulated_weekly <- dt_simulated_weekly

# * Prophet Holidays ----
data("dt_prophet_holidays")
dt_prophet_holidays <- dt_prophet_holidays


# *****************************************************************************
# **** ----
# MODEL SPECIFICATION ----
# *****************************************************************************

# * Step 2a: For first time user: Model specification in 4 steps ----


# ** 2a-1: First, specify input variables ----
"https://github.com/facebookexperimental/Robyn/blob/9ec40e3a50b48cf2d6904544f0f
24ef470515d2f/demo/demo.R#L60"

## All sign control are now automatically provided: "positive" for media & organic
## variables and "default" for all others. User can still customize signs if necessary.
## Documentation is available, access it anytime by running: ?robyn_inputs
InputCollect <- robyn_inputs(
    dt_input          = dt_simulated_weekly,
    dt_holidays       = dt_prophet_holidays,
    
    date_var          = "DATE", # date format must be "2020-01-01"
    dep_var           = "revenue", # there should be only one dependent variable
    dep_var_type      = "revenue", # "revenue" (ROI) or "conversion" (CPA)
    
    prophet_vars      = c("trend", "season", "holiday"), # "trend","season", "weekday" & "holiday"
    prophet_country   = "US", # input country code. Check: dt_prophet_holidays
    
    context_vars      = c("competitor_sales_B", "events"), # e.g. competitors, discount, unemployment etc
    
    paid_media_spends = c("tv_S", "ooh_S", "print_S", "facebook_S", "search_S"), # mandatory input
    paid_media_vars   = c("tv_S", "ooh_S", "print_S", "facebook_I", "search_clicks_P"), # mandatory.
    # paid_media_vars must have same order as paid_media_spends. Use media exposure metrics like
    # impressions, GRP etc. If not applicable, use spend instead.
    
    organic_vars      = "newsletter", # marketing activity without media spend
    # factor_vars = c("events"), # force variables in context_vars or organic_vars to be categorical
    
    window_start      = "2016-01-01",
    window_end        = "2018-12-31",
    
    adstock           = "geometric", # geometric, weibull_cdf or weibull_pdf.
    
    intercept_sign    = "non_negative",
    nevergrad_algo    = "TwoPointsDE",
    trials            = 5,
    cores             = 4
)

min(dt_simulated_weekly$DATE)
max(dt_simulated_weekly$DATE)


# ** 2a-2: Second, define and add hyper-parameters ----
"https://github.com/facebookexperimental/Robyn/blob/9ec40e3a50b48cf2d6904544f0f
24ef470515d2f/demo/demo.R#L86"

# - Set plot = TRUE to create example plots for adstock & saturation
plot_adstock(plot = TRUE)
plot_saturation(plot = TRUE)

hyperparameters <- list(
    facebook_S_alphas = c(0.5, 3),
    facebook_S_gammas = c(0.3, 1),
    facebook_S_thetas = c(0, 0.3),
    
    print_S_alphas    = c(0.5, 3),
    print_S_gammas    = c(0.3, 1),
    print_S_thetas    = c(0.1, 0.4),
    
    tv_S_alphas       = c(0.5, 3),
    tv_S_gammas       = c(0.3, 1),
    tv_S_thetas       = c(0.3, 0.8),
    
    search_S_alphas   = c(0.5, 3),
    search_S_gammas   = c(0.3, 1),
    search_S_thetas   = c(0, 0.3),
    
    ooh_S_alphas      = c(0.5, 3),
    ooh_S_gammas      = c(0.3, 1),
    ooh_S_thetas      = c(0.1, 0.4),
    
    newsletter_alphas = c(0.5, 3),
    newsletter_gammas = c(0.3, 1),
    newsletter_thetas = c(0.1, 0.4),
    
    train_size        = c(0.5, 0.8)
)


# ** 2a-3: Third, add hyperparameters into robyn_inputs() ----

InputCollect <- robyn_inputs(
    InputCollect    = InputCollect, 
    hyperparameters = hyperparameters
)

InputCollect


# ** 2a-4: Fourth (optional), model calibration / add experimental input ----
"https://github.com/facebookexperimental/Robyn/blob/9ec40e3a50b48cf2d6904544f0f
24ef470515d2f/demo/demo.R#L208C1-L208C73"

# channel name must in paid_media_vars
# liftStartDate must be within input data range
# liftEndDate must be within input data range
# liftAbs value must be tested on same campaign level in model and same metric as dep_var_type
# spend within experiment: should match within a 10% error your spend on date range for each channel from dt_input
# confidence: if frequentist experiment, you may use 1 - pvalue
# kpi measured: must match your dep_var
# either "immediate" or "total". For experimental inputs like Facebook Lift, "immediate" is recommended.


calibration_input <- data.frame(
  
  channel           = c("facebook_S", "tv_S", "facebook_S+search_S", "newsletter"),
  liftStartDate     = as.Date(c("2018-05-01", "2018-04-03", "2018-07-01", "2017-12-01")),
  liftEndDate       = as.Date(c("2018-06-10", "2018-06-03", "2018-07-20", "2017-12-31")),
  liftAbs           = c(400000, 300000, 700000, 200),
  spend             = c(421000, 7100, 350000, 0),
  confidence        = c(0.85, 0.8, 0.99, 0.95),
  metric            = c("revenue", "revenue", "revenue", "revenue"),
  calibration_scope = c("immediate", "immediate", "immediate", "immediate")
  
)

# ** 2a-4: Fourth, add calibration input into robyn_inputs() ----
InputCollect <- robyn_inputs(
    InputCollect      = InputCollect, 
    calibration_input = calibration_input
)

# ** 2a-5: Check spend exposure fit if available ----
if (length(InputCollect$exposure_vars) > 0) {
    lapply(InputCollect$modNLS$plots, plot)
}


# *****************************************************************************
# **** ----
#  MODEL BUILDING ----
# *****************************************************************************

# * Step 3: Build initial model ----

## Run all trials and iterations. Use ?robyn_run to check parameter definition
OutputModels <- robyn_run(
    InputCollect       = InputCollect, # feed in all model specification
    cores              = 4, # NULL defaults to (max available - 1)
    iterations         = 2000, # 2000 recommended for the dummy dataset with no calibration
    trials             = 5, # 5 recommended for the dummy dataset
    ts_validation      = TRUE, # 3-way-split time series for NRMSE validation.
    add_penalty_factor = FALSE # Experimental feature. Use with caution.
)

## Check MOO (multi-objective optimization) convergence plots
# Read more about convergence rules: ?robyn_converge
OutputModels$convergence$moo_distrb_plot
OutputModels$convergence$
    
## Check time-series validation plot (when ts_validation == TRUE)
# Read more and replicate results: ?ts_validation
if (OutputModels$ts_validation) OutputModels$ts_validation_plot

## Calculate Pareto fronts, cluster and export results and plots. See ?robyn_outputs
OutputCollect <- robyn_outputs(
    InputCollect, OutputModels,
    pareto_fronts = "auto", # automatically pick how many pareto-fronts to fill min_candidates (100)
    # min_candidates = 100, # top pareto models for clustering. Default to 100
    # calibration_constraint = 0.1, # range c(0.01, 0.1) & default at 0.1
    csv_out       = "pareto", # "pareto", "all", or NULL (for none)
    clusters      = TRUE, # Set to TRUE to cluster similar models by ROAS. See ?robyn_clusters
    export        = create_files, # this will create files locally
    plot_folder   = robyn_directory, # path for plots exports and files creation
    plot_pareto   = create_files # Set to FALSE to deactivate plotting and saving model one-pagers
)

# *****************************************************************************
# **** ----
#  ----
# *****************************************************************************


# *****************************************************************************
# **** ----
#  ----
# *****************************************************************************


# *****************************************************************************
# **** ----
#  ----
# *****************************************************************************

