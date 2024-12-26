# Including the dplyr library for filtering the data frame columns

library(dplyr)

# Including the openSkies library to retrieve the
# longitude and latitude of the Zagreb Pleso airport

library(openSkies)

# Including the sp library to transform the
# longitude and latitude of the Zagreb Pleso airport
# into meters using cartographic projections

library(sp)

# Including the trajr library to process trajectories

library(trajr)

# Including the tidyr library to exclude rows
# with missing values

library(tidyr)

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

# Setting the boundaries of the observed area
# to 0.4 degrees of longitude and latitude
# around the Zagreb Pleso airport

start_airport <- "LDZA"
meta_airport <- getAirportMetadata(start_airport)

mini_long <- meta_airport$longitude - 0.4
maxi_long <- meta_airport$longitude + 0.4
mini_lat <- meta_airport$latitude - 0.4
maxi_lat <- meta_airport$latitude + 0.4

# Defining a function to draw the selected pair of axes for all trajectories

plot_2d <- function(first_dim, second_dim) {

  # Setting the plot directory

  dir_for_plot <- paste(first_dim, second_dim, "plots_new", sep = "_")

  if (!dir.exists(dir_for_plot)) {
    dir.create(dir_for_plot)
  }

  # Fetching the names of all files combining trajectories and meteorological data

  dir_for_trajs <- "weather_trajs_new"

  data_fr <- data.frame(read.csv("features_traj_new.csv"))
  filenames_for_trajs <- data_fr$filenames_for_trajs_new

  for (filename_for_traj in filenames_for_trajs) {

    # Opening the file with the trajectory state vectors

    filepath_for_traj <- paste(dir_for_trajs, filename_for_traj, sep = "//")

    file_for_traj <- data.frame(read.csv(filepath_for_traj))

    # Excluding the rows with missing longitude, latitude, or altitude values

    file_for_traj <- file_for_traj %>% drop_na(lat)
    file_for_traj <- file_for_traj %>% drop_na(lon)
    file_for_traj <- file_for_traj %>% drop_na(geoaltitude)

    # Filtering rows using the observed area boundaries

    file_for_traj <- filter(file_for_traj, lat >= mini_lat)
    file_for_traj <- filter(file_for_traj, lat <= maxi_lat)
    file_for_traj <- filter(file_for_traj, lon >= mini_long)
    file_for_traj <- filter(file_for_traj, lon <= maxi_long)

    # Transforming the coordinates of the airplane position
    # from degrees of longitude and latitude to meters
    # using the EPSG 3765 projection that is valid for Zagreb

    cord_dec <- SpatialPoints(
      cbind(
        file_for_traj$lon, file_for_traj$lat
      ),
      proj4string = CRS("+proj=longlat")
    )
    cord_utm <- spTransform(cord_dec, CRS("+init=epsg:3765"))

    # Creating a three-dimensional trajectory

    new_cols <- data.frame(
      cord_utm$coords.x1,
      cord_utm$coords.x2,
      file_for_traj$geoaltitude,
      file_for_traj$time
    )
    trj <- Traj3DFromCoords(
      track = new_cols,
      xCol = 1,
      yCol = 2,
      zCol = 3,
      timeCol = 4
    )

    # Resampling the trajectory with a constant time step
    # of ten seconds between records

    resampled <- Traj3DResampleTime(trj, 10)

    # Smoothing the trajectory using the Savitzky-Golay filter
    # with a window size of 11 and a polynomial degree of 3

    smoothed <- Traj3DSmoothSG(resampled, p = 3, n = 11)

    # Separating each axis from the original and smoothed trajectory

    if (first_dim == "x") {
      first_coord_vals <- smoothed$x
      first_coord_vals_original <- trj$x
    }

    if (first_dim == "y") {
      first_coord_vals <- smoothed$y
      first_coord_vals_original <- trj$y
    }

    if (second_dim == "y") {
      second_coord_vals <- smoothed$y
      second_coord_vals_original <- trj$y
    }

    if (second_dim == "z") {
      second_coord_vals <- smoothed$z
      second_coord_vals_original <- trj$z
    }

    # Separating the filename into the callsign, ICA024
    # identifier, date, and time to form the plot title
    
    split_name <- unlist(
      strsplit(
        gsub(
          "weather_", "",
          gsub(".csv", "", filename_for_traj)
        ),
        "_"
      )
    )
    callsign <- split_name[1]
    icao24 <- split_name[2]
    date_first <- format(
      as.POSIXct(
        as.numeric(split_name[3]),
        origin = "1970-01-01",
        tz = "Europe/Zagreb"
      ),
      format = "%d.%m.%Y %H:%M:%S"
    )
    date_last <- format(
      as.POSIXct(
        as.numeric(split_name[4]),
        origin = "1970-01-01",
        tz = "Europe/Zagreb"
      ),
      format = "%d.%m.%Y %H:%M:%S"
    )

    new_name <- paste(
      "Callsign:",
      callsign,
      "ICAO24:",
      icao24,
      "\n",
      date_first,
      "-",
      date_last
    )

    # Drawing the original, and smoothed trajectory

    plot(
      first_coord_vals_original,
      second_coord_vals_original,
      lty = 2,
      asp = 1,
      main = new_name,
      type = "l",
      xlab = paste(first_dim, "(m)"),
      ylab = paste(second_dim, "(m)"),
      col = "blue",
      cex.lab = 1.5, cex.main = 1.7, cex.axis = 1.5
    )
    lines(first_coord_vals, second_coord_vals, lwd = 2, col = "red")

    # The legend is drawn down, and to the right if the 
    # trajectory starts down, and to the left, and the
    # reverse also applies

    dist_from_min <- first_coord_vals_original[1] -
      min(first_coord_vals_original)
    dist_from_max <- max(first_coord_vals_original) -
      first_coord_vals_original[1]

    poslegend <- "bottomleft"

    if (dist_from_min < dist_from_max) {
      poslegend <- "bottomright"
    }

    # Adding the legend

    legend(
      poslegend,
      cex = 1.7, text.width = strwidth("Original") * 2,
      legend = c("Original", "Smooth"),
      col = c("blue", "red"),
      lty = c(2, 1),
      lwd = c(1, 2)
    )

    # Saving the plot

    dev.copy(pdf,
      paste(dir_for_plot, gsub(
        "csv", "pdf",
        gsub(
          "weather",
          paste(first_dim, second_dim, sep = "_"),
          filename_for_traj
        )
        ),
        sep = "//"
      )
    )

    # Closing the plot

    if (length(dev.list()) > 0) {
      for (dev_sth_open in dev.list()[1]:dev.list()[length(dev.list())]) {
        dev.off()
      }
    }
  }
}

plot_2d("x", "y")
plot_2d("x", "z")
plot_2d("y", "z")
