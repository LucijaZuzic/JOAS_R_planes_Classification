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

# Transforming the coordinates of the area boundaries
# from degrees of longitude and latitude to meters
# using the EPSG 3765 projection that is valid for Zagreb

cord_start_dec <- SpatialPoints(
  cbind(
    c(mini_long, maxi_long),
    c(mini_lat, maxi_lat)
  ),
  proj4string = CRS("+proj=longlat")
)
cord_start_utm <- spTransform(cord_start_dec, CRS("+init=epsg:3765"))

# Calculating the midpoint of the observed area

mid_x <- (cord_start_utm$coords.x1[1] + cord_start_utm$coords.x1[2]) / 2
mid_y <- (cord_start_utm$coords.x2[1] + cord_start_utm$coords.x2[2]) / 2

# Fetching the names of all files combining trajectories and meteorological data

dir_for_trajs <- "weather_trajs_new"

data_fr <- data.frame(read.csv("features_traj_new.csv"))
filenames_for_trajs <- data_fr$filenames_for_trajs_new

# Storing the minimum and maximum x and y coordinate in meters

mini_traj_x <- 10000000
maxi_traj_x <- -10000000
mini_traj_y <- 10000000
maxi_traj_y <- -10000000

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

  if (length(file_for_traj$lon) > 0) {
    cord_dec <- SpatialPoints(
      cbind(
        file_for_traj$lon,
        file_for_traj$lat
      ),
      proj4string = CRS("+proj=longlat")
    )
    cord_utm <- spTransform(cord_dec, CRS("+init=epsg:3765"))

    # Creating a three-dimensional trajectory

    new_cols <- data.frame(
      cord_utm$coords.x1,
      cord_utm$coords.x2, file_for_traj$geoaltitude,
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

    # Storing the minimum and maximum x and y coordinate

    mini_traj_x <- min(smoothed$x[3:length(smoothed$x)], mini_traj_x)
    maxi_traj_x <- max(smoothed$x[3:length(smoothed$x)], maxi_traj_x)
    mini_traj_y <- min(smoothed$y[3:length(smoothed$y)], mini_traj_y)
    maxi_traj_y <- max(smoothed$y[3:length(smoothed$y)], maxi_traj_y)

  }

}

first <- TRUE

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
      file_for_traj$lon,
      file_for_traj$lat
    ),
    proj4string = CRS("+proj=longlat")
  )
  cord_utm <- spTransform(
    cord_dec,
    CRS("+init=epsg:3765")
  )

  # Creating a three-dimensional trajectory

  new_cols <- data.frame(
    cord_utm$coords.x1, cord_utm$coords.x2,
    file_for_traj$geoaltitude, file_for_traj$time
  )
  trj <- Traj3DFromCoords(
    track = new_cols, xCol = 1,
    yCol = 2, zCol = 3, timeCol = 4
  )

  # Resampling the trajectory with a constant time step
  # of ten seconds between records

  resampled <- Traj3DResampleTime(trj, 10)

  # Smoothing the trajectory using the Savitzky-Golay filter
  # with a window size of 11 and a polynomial degree of 3

  smoothed <- Traj3DSmoothSG(resampled, p = 3, n = 11)

  color_use <- "red"

  # If the third point of the smoothed trajectory is east or north 
  # of the observed area midpoint, the trajectory label is $1$,
  # otherwise we assign a label of $-1$

  if (smoothed$x[3] > mid_x | smoothed$y[3] > mid_y) {
    color_use <- "green"
  }

  # We start a new plot if no trajectories were drawn before,
  # otherwise we add them to the existing plot

  if (!first) {
    lines(smoothed$x[3:length(smoothed$x)],
      smoothed$y[3:length(smoothed$y)],
      lwd = 2, col = color_use
    )
  } else {
    plot(smoothed$x[3:length(smoothed$x)], smoothed$y[3:length(smoothed$y)],
      main = "Classifying trajectories based on the third step", lwd = 2,
      asp = 1, col = color_use, type = "l", xlim = c(mini_traj_x, maxi_traj_x),
      ylim = c(mini_traj_y, maxi_traj_y), xlab = "x (m)", ylab = "y (m)",
      cex.lab = 1.5, cex.main = 1.7, cex.axis = 1.5
    )

    # Drawing the line representing class division

    abline(v = mid_x, lty = 2, col = "blue")
    abline(h = mid_y, lty = 2, col = "blue")

    # Adding the legend

    legend("bottomright", cex = 1.2, text.width = strwidth("Division line") * 2,
      legend = c("1", "-1", "Division line"),
      col = c("green", "red", "blue"),
      lty = c(1, 1, 2), lwd = c(2, 2, 1)
    )
  }

  first <- FALSE
}

# Storing the plot

dev.copy(pdf, "all_2D_new.pdf")

# Closing the plot

if (length(dev.list()) > 0) {
  for (dev_sth_open in dev.list()[1]:dev.list()[length(dev.list())]) {
    dev.off()
  }
}