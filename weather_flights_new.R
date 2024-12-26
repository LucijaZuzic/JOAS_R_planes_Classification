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

# Setting the directory for meteorological reports,
# trajectories, and trajectories merged with meteorological reports

dir_for_weather <- "rp5_new"
dir_for_trajs <- "usable_trajs_new"
dir_for_weather_trajs <- "weather_trajs_new"

if (!dir.exists(dir_for_weather_trajs)) {
  dir.create(dir_for_weather_trajs)
}

# Defining the filename format for meteorological report files

start_airport <- "LDZA"

end_of_pattern <- "1.0.0.en.utf8.00000000.csv"

# Iterating over all files with flight state vectors

filenames_for_trajs <- list.files(dir_for_trajs)

for (filename_for_traj in filenames_for_trajs) {

  # Opening a file with the state vectors for the given flight

  filepath_for_traj <- paste(dir_for_trajs, filename_for_traj, sep = "//")

  file_for_traj <- data.frame(read.csv(filepath_for_traj))

  # Creating a data frame for trajectories merged with meteorological reports

  weather_add_data <- data.frame()

  # Defining the filename format for trajectories 
  # merged with meteorological reports

  filepath_for_weather_traj <- paste(dir_for_weather_trajs,
    paste("weather", filename_for_traj, sep = "_"),
    sep = "//"
  )

  if (!file.exists(filepath_for_weather_traj)) {

    # Iterating over all the state vectors for the given flight

    for (i in 1:nrow(file_for_traj)) {

      # Extracting the time from a state vector

      date_time_value <- as.POSIXct(file_for_traj[i, 1],
        origin = "1970-01-01", tz = "Europe/Zagreb"
      )

      date_string_value <- format(date_time_value, format = "%d.%m.%Y")

      # Defining the filename for meteorological report files for the given date

      filename_weather <- paste(start_airport, date_string_value, sep = ".")
      filename_weather <- paste(filename_weather, date_string_value, sep = ".")
      filename_weather <- paste(filename_weather, end_of_pattern, sep = ".")

      filepath_weather <- paste(dir_for_weather, filename_weather, sep = "//")

      # Opening the meteorological report files for the given date, if it exist

      if (file.exists(filepath_weather)) {

        # Renaming the date and time column from the meteorological report files

        weather_file <- data.frame(read.csv(filepath_weather, sep = ";"))

        colnames(weather_file)[1] <- "time_METER"

        # Finding the record from the meteorological report with the smallest time gap
        # relative to the state vector

        min_time_diff <- as.POSIXct(
          "2022-06-28 00:00:00",
          tz = "Europe/Zagreb"
        ) -
          as.POSIXct(
            "2022-06-27 00:00:00",
            tz = "Europe/Zagreb"
          )
        min_row_index <- 0

        for (j in 1:nrow(weather_file)) {
          row_time <- as.POSIXct(weather_file[j, 1],
            format = "%d.%m.%Y %H:%M", tz = "Europe/Zagreb"
          )

          offset_time <- abs(row_time - date_time_value)

          # If we have found the record from the meteorological report
          # with the smallest time gap relative to the state vector,
          # we can stop iteration, as the meteorological report file
          # is sorted in ascending order by date and time

          if (offset_time < min_time_diff) {
            min_time_diff <- offset_time
            min_row_index <- j
          } else {
            break
          }
        }

        # Adding meteorological data to the data frame

        weather_add_data <- rbind(
          weather_add_data,
          weather_file[min_row_index, ]
        )
      }
    }

    # Saving the trajectories merged with meteorological reports

    file_for_traj <- cbind(file_for_traj, weather_add_data)

    print(filepath_for_weather_traj)

    write.csv(file_for_traj, filepath_for_weather_traj, row.names = FALSE)
    
  }
  
}