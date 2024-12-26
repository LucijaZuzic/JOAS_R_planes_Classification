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

path_to_state_vectors <- paste(get_current_file_location(), "states_new",  sep = "//")

# Fetching all flight from the .csv file with a defined
# origin and destination airport

start_airport <- "LDZA"
end_airport <- "EGLL"

result_name <- paste("usable_flights_new/usable_flights_new_",
  start_airport, "_", end_airport, ".csv",
  sep = ""
)

usable_flights <- data.frame(read.csv(result_name))
usable_flights_dest <- filter(usable_flights, arrival_airport == end_airport)

for (i in 1:nrow(usable_flights_dest)) {

  # Defining the range of hours for the duration of the flight

  date_first <- as.POSIXct(usable_flights_dest[i, 5],
    origin = "1970-01-01", tz = "Europe/Zagreb"
  ) - 2 * 3600
  date_last <- as.POSIXct(usable_flights_dest[i, 6],
    origin = "1970-01-01", tz = "Europe/Zagreb"
  ) - 2 * 3600

  date_first_round <- as.POSIXct(
    format(date_first,
      format = "%Y-%m-%d %H:00:00"
    ),
    tz = "Europe/Zagreb"
  )
  date_last_round <- as.POSIXct(
    format(date_last,
      format = "%Y-%m-%d %H:00:00"
    ),
    tz = "Europe/Zagreb"
  )

  date_current <- date_first_round

  # Padding the callsign to a length of eight characters

  my_callsign <- usable_flights_dest[i, 2]

  while (nchar(my_callsign) < 8) {
    my_callsign <- paste(my_callsign, "")
  }

  # Creating a directory to store the flight state vectors

  if (!dir.exists("usable_trajs_new")) {
    dir.create("usable_trajs_new")
  }

  result_name <- paste("usable_trajs_new", my_callsign, sep = "//")
  result_name <- paste(result_name,
    usable_flights_dest[i, 1], as.character(usable_flights_dest[i, 5]),
    as.character(usable_flights_dest[i, 6]),
    sep = "_"
  )

  result_name <- paste(result_name, ".csv", sep = "")

  if (!file.exists(result_name)) {

    data_frame_states <- data.frame()

    while (date_current <= date_last_round) {

      # Fetching the state vector file containing state vectors
      # for all flights for the given hour

      date_string <- strftime(date_current, format = "%Y-%m-%d")
      hour_string <- strftime(date_current, format = "%H")

      directory_path <- paste(path_to_state_vectors,
        date_string, hour_string,
        sep = "//"
      )

      date_hour_string <- strftime(date_current, format = "%Y-%m-%d-%H")

      states_filename <- paste("states_", date_hour_string, ".csv", sep = "")

      states_filepath <- paste(directory_path, states_filename, sep = "//")

      print(states_filepath)

      # Filtering the state vectors according to the ICAO24
      # identifier, time and callsign

      if (file.exists(states_filepath)) {
        states_file <- data.frame(read.csv(states_filepath))

        states_file <- filter(states_file, icao24 == usable_flights_dest[i, 1])
        states_file <- filter(states_file, time >= usable_flights_dest[i, 5])
        states_file <- filter(states_file, time <= usable_flights_dest[i, 6])
        states_file <- filter(states_file, callsign == my_callsign)

        data_frame_states <- rbind(data_frame_states, states_file)
      }

      # A time shift of one hour

      date_current <- date_current + 3600

    }

    # Storing all the state vectors into a data frame if at
    # least one state vector matching the flight was found

    if (nrow(data_frame_states) > 0) {
      write.csv(data_frame_states, result_name, row.names = FALSE)
    }

  }

}