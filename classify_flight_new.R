# Including the dplyr library for filtering the data frame columns

library(dplyr)

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

source("preprocess_for_training.R")

source("use_model.R")

data_fr <- data.frame(read.csv("features_traj_new.csv"))
data_fr <- subset(data_fr, select = -c(filenames_for_trajs_new))
data_fr_no_metar <- subset(data_fr,
  select = -c(metar_t, metar_p, metar_p0, metar_u, metar_ff, metar_td)
)
data_fr_metar <- subset(data_fr,
  select = c(label_col, metar_t, metar_p, metar_p0, metar_u, metar_ff, metar_td)
)
data_fr_traj_distance_traj_dc <- subset(data_fr,
  select = c(label_col, traj_distance, traj_dc)
)

data_fr_list <- preprocesing_function(data_fr)
data_fr_no_metar_list <- preprocesing_function(data_fr_no_metar)
data_fr_metar_list <- preprocesing_function(data_fr_metar)
data_fr_traj_distance_traj_dc_list <- preprocesing_function(data_fr_traj_distance_traj_dc)

model_list <- c(
  "k-NN",
  "Linear SVM",
  "RBF SVM",
  "Gaussian Process",
  "Decision Tree",
  "Random Forest",
  "Naive Bayes",
  "Multilayer Perceptron",
  "AdaBoost",
  "Quadratic Discriminant Analysis"
)

if (!dir.exists("trees_new")) {
  dir.create("trees_new")
}

df_predictions_test <- data.frame(c(data_fr_list$test_label))
names(df_predictions_test) <- c("test_label")

df_predictions_train <- data.frame(c(data_fr_list$train_label))
names(df_predictions_train) <- c("train_label")

for (model_name in model_list) {
  model_used_list <- model_use(
    model_name, data_fr_list$train_data,
    data_fr_list$test_data, data_fr_list$train_label, data_fr_list$test_label,
    tree_name = "trees_new/all_tree.pdf"
  )
  model_no_metar_used_list <- model_use(
    model_name, data_fr_no_metar_list$train_data,
    data_fr_no_metar_list$test_data, data_fr_no_metar_list$train_label,
    data_fr_no_metar_list$test_label,
    tree_name = "trees_new/all_no_metar_tree.pdf"
  )
  model_metar_used_list <- model_use(
    model_name, data_fr_metar_list$train_data,
    data_fr_metar_list$test_data, data_fr_metar_list$train_label,
    data_fr_metar_list$test_label,
    tree_name = "trees_new/all_metar_tree.pdf"
  )
  model_traj_distance_traj_dc_used_list <- model_use(
    model_name, data_fr_traj_distance_traj_dc_list$train_data,
    data_fr_traj_distance_traj_dc_list$test_data, data_fr_traj_distance_traj_dc_list$train_label,
    data_fr_traj_distance_traj_dc_list$test_label,
    tree_name = "trees_new/all_traj_distance_traj_dc_tree.pdf"
  )

  print(model_name)

  colname_model <- paste(model_name, "all", sep = "_")
  colname_no_metar_model <- paste(model_name, "no", "METAR", sep = "_")
  colname_metar_model <- paste(model_name, "METAR", sep = "_")
  colname_traj_distance_traj_dc_model <- paste(model_name, "traj_distance_traj_dc", sep = "_")

  if (model_name == "k-NN") {
    print(paste("k =", model_used_list$k_val))
    colname_model <- paste(colname_model, model_used_list$k_val, sep = "_")
  }

  print("All")

  print("Test")
  print(table(model_used_list$test_predicted, data_fr_list$test_label))
  df_predictions_test[[colname_model]] <- model_used_list$test_predicted
  print("Train")
  print(table(model_used_list$train_predicted, data_fr_list$train_label))
  df_predictions_train[[colname_model]] <- model_used_list$train_predicted

  print("No METAR")

  if (model_name == "k-NN") {
    print(paste("k =", model_no_metar_used_list$k_val))
    colname_no_metar_model <- paste(colname_no_metar_model,
      model_no_metar_used_list$k_val,
      sep = "_"
    )
  }

  print("Test")
  print(table(
    model_no_metar_used_list$test_predicted,
    data_fr_no_metar_list$test_label
  ))
  df_predictions_test[[colname_no_metar_model]] <-
    model_no_metar_used_list$test_predicted
  print("Train")
  print(table(
    model_no_metar_used_list$train_predicted,
    data_fr_no_metar_list$train_label
  ))
  df_predictions_train[[colname_no_metar_model]] <-
    model_no_metar_used_list$train_predicted

  print("METAR")

  if (model_name == "k-NN") {
    print(paste("k =", model_metar_used_list$k_val))
    colname_metar_model <- paste(colname_metar_model,
      model_metar_used_list$k_val,
      sep = "_"
    )
  }

  print("Test")
  print(table(
    model_metar_used_list$test_predicted,
    data_fr_metar_list$test_label
  ))
  df_predictions_test[[colname_metar_model]] <-
    model_metar_used_list$test_predicted
  print("Train")
  print(table(
    model_metar_used_list$train_predicted,
    data_fr_metar_list$train_label
  ))
  df_predictions_train[[colname_metar_model]] <-
    model_metar_used_list$train_predicted
  
  print("traj_distance_traj_dc")

  if (model_name == "k-NN") {
    print(paste("k =", model_traj_distance_traj_dc_used_list$k_val))
    colname_traj_distance_traj_dc_model <- paste(colname_traj_distance_traj_dc_model,
      model_traj_distance_traj_dc_used_list$k_val,
      sep = "_"
    )
  }

  print("Test")
  print(table(
    model_traj_distance_traj_dc_used_list$test_predicted,
    data_fr_traj_distance_traj_dc_list$test_label
  ))
  df_predictions_test[[colname_traj_distance_traj_dc_model]] <-
    model_traj_distance_traj_dc_used_list$test_predicted
  print("Train")
  print(table(
    model_traj_distance_traj_dc_used_list$train_predicted,
    data_fr_traj_distance_traj_dc_list$train_label
  ))
  df_predictions_train[[colname_traj_distance_traj_dc_model]] <-
    model_traj_distance_traj_dc_used_list$train_predicted

}

write.csv(df_predictions_test, "predictions_test_new.csv", row.names = FALSE)
write.csv(df_predictions_train, "predictions_train_new.csv", row.names = FALSE)