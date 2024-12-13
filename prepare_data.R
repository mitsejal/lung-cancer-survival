# Install the required packages if you don't have them installed
if (!requireNamespace("survival", quietly = TRUE)) install.packages("survival")
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
if (!requireNamespace("jsonlite", quietly = TRUE)) install.packages("jsonlite")

# Load the libraries
library(survival)
library(dplyr)
library(jsonlite)

# Load the lung dataset from the survival package
data(lung)

# Convert 'sex' to a readable factor
lung$sex <- factor(lung$sex, labels = c("Male", "Female"))

# Add age group based on the median age
lung <- lung %>%
  mutate(age_group = ifelse(age <= median(age, na.rm = TRUE), "Younger", "Older"))

# Fit Kaplan-Meier model for debugging
fit <- survfit(Surv(time, status) ~ sex, data = lung)
summary(fit)

table(lung$sex, lung$status)

lung <- lung %>% filter(!is.na(sex))

compute_km <- function(group_var) {
  # Fit Kaplan-Meier survival model
  fit <- survfit(Surv(time, status) ~ get(group_var), data = lung)
  surv_summary <- summary(fit)
  
  # Handle cases where there are no strata
  if (is.null(fit$strata)) {
    # Create a single group if no strata are present
    km_data <- data.frame(
      time = surv_summary$time,
      survival = surv_summary$surv,
      group = as.character(unique(lung[[group_var]]))  # Assign the single group name
    )
  } else {
    # Extract group names (strata) and repetitions
    strata_names <- names(fit$strata)
    strata_reps <- diff(c(0, surv_summary$strata))
    
    # Dynamically adjust repetitions to match strata names
    strata_reps <- strata_reps[1:length(strata_names)]  # Trim repetitions if too long
    if (length(strata_names) != length(strata_reps)) {
      stop("Mismatch between strata names and repetitions persists after adjustment.")
    }
    
    # Create the data frame with valid strata repetitions
    km_data <- data.frame(
      time = surv_summary$time,
      survival = surv_summary$surv,
      group = rep(strata_names, strata_reps)
    )
  }
  
  # Rename the group column to match the variable name
  km_data <- km_data %>% rename(!!group_var := group)
  return(km_data)
}

km_sex <- compute_km("sex")
head(km_sex)

# Compute Kaplan-Meier survival estimates for 'age_group' and 'ph.ecog'
km_age_group <- compute_km("age_group")
km_ecog <- compute_km("ph.ecog")

# Combine results into a single data frame
survival_data <- bind_rows(
  km_sex %>% mutate(variable = "sex"),
  km_age_group %>% mutate(variable = "age_group"),
  km_ecog %>% mutate(variable = "ph.ecog")
)

# Save the survival data as a JSON file
write_json(survival_data, "data/survival_data.json", pretty = TRUE)

# Print confirmation message
cat("Data has been saved to 'data/survival_data.json'.\n")



