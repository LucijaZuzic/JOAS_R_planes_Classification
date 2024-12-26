# Including the openSkies library for fetching the flights from Zagreb Pleso airport

library(openSkies)

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

# A function to retrieve all flights with the origin
# and destination airport and storing into a .csv file

get_data <- function(start_airport, end_airport) {

  # Defining the variables to store flight data

  icao24 <- c()
  callsign <- c()
  departure_airport <- c()
  arrival_airport <- c()
  first_seen <- c()
  last_seen <- c()

  # The starting date is 5.6.2017., a the ending date is 27.6.2022.

  dt <- as.POSIXct("2017-06-05 00:00:00", tz = "Europe/Zagreb")
  dt_end <- as.POSIXct("2022-06-27 00:00:00", tz = "Europe/Zagreb")

  # Getting all flights in the date range

  while (dt <= dt_end) {
    
    repeating <- TRUE
    n_retries <- 0

    # Repeating the request if the server is not responding

    while (repeating && n_retries <= 10) {

      # Signing into the data base and making queries for flights
      # on a given date originating from a given airport

      # Replace the placeholder values in the commented line
      # defining the arguments for the getAirportDepartures function
      # with the username and password for OpenSkyNetwork created using
      # the form available on the link below:

      # https://opensky-network.org/index.php?option=com_users&view=registration

      data_res <- getAirportDepartures(start_airport, as.character(dt),
        as.character(dt + 24 * 3600),
        timeZone = "Europe/Zagreb", maxQueryAttempts = 1000000,
        # username = "someUsername", password = "somePassword"
      )

      repeating <- length(data_res) == 0

      for (flight in data_res) {

        # Storing data into the data frame
        # if the destination airport matches the requested one

        if (!is.null(flight$destination_airport) && flight$destination_airport == end_airport) {
          icao24 <- c(icao24, flight$ICAO24)
          callsign <- c(callsign, flight$call_sign)
          departure_airport <- c(departure_airport, flight$origin_airport)
          arrival_airport <- c(arrival_airport, flight$destination_airport)
          first_seen <- c(first_seen, flight$departure_time)
          last_seen <- c(last_seen, flight$arrival_time)

          # Storing the flight data frame

          if (!dir.exists("usable_flights_new")) {
            dir.create("usable_flights_new")
          }

          result_name <- paste("usable_flights_new/usable_flights_new_",
            start_airport, "_", end_airport, ".csv",
            sep = ""
          )

          data_frame_flights <- data.frame(icao24, callsign, departure_airport, arrival_airport, first_seen, last_seen)

          write.csv(data_frame_flights, result_name, row.names = FALSE)

        }

      }

      n_retries <- n_retries + 1
    }

    # A time shif of one week to get data for each Modnay

    dt <- dt + 7 * 24 * 3600
  }

}

get_data("LDZA", "EGLL")