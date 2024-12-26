# Including the corrplot library to compute a correlation matrix

library(corrplot)

# Including the tidyverse library for use in the function
# that identifies the directory where the script is located

library(tidyverse)

# Clearing the workspace

rm(list = ls())

# Setting the working directory to the directory where the script is located

get_current_file_location <- function() {
  this_file <- commandArgs() %>%
    tibble::enframe(name = NULL) %>%
    tidyr::separate(
      col = value,
      into = c("key", "value"),
      sep = "=",
      fill = "right"
    ) %>%
    dplyr::filter(key == "--file") %>%
    dplyr::pull(value)
  if (length(this_file) == 0) {
    this_file <- rstudioapi::getSourceEditorContext()$path
  }
  return(dirname(this_file))
}

setwd(get_current_file_location())

data_fr <- data.frame(read.csv("features_traj_new.csv"))
data_fr <- subset(data_fr, select = -c(filenames_for_trajs_new))

# Compute a correlation matrix

corr <- cor(data_fr)
write.csv(corr, "corr.csv", row.names = FALSE)