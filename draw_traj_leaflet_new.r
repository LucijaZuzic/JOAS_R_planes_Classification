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

# Including the leaflet library to display the OpenStreetMap (OSM) tiles

library(leaflet)

# Including the mapview library to store the map

library(mapview)

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

# Fetching the names of all files combining trajectories and meteorological data

dir_for_trajs <- "weather_trajs_new"

data_fr <- data.frame(read.csv("features_traj_new.csv"))
filenames_for_trajs <- data_fr$filenames_for_trajs_new

lon <- c()
lat <- c()

data_frame_coords_y <- data.frame(matrix(ncol = 2, nrow = 0))
names(data_frame_coords_y) <- c("lon", "lat")

data_frame_coords_n <- data.frame(matrix(ncol = 2, nrow = 0))
names(data_frame_coords_n) <- c("lon", "lat")

# Storing the minimum and maximum longitude and latitude

mini_traj_long <- 10000000
maxi_traj_long <- -10000000
mini_traj_lat <- 10000000
maxi_traj_lat <- -10000000

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

  cord_dec <- SpatialPoints(cbind(file_for_traj$lon, file_for_traj$lat),
    proj4string = CRS("+proj=longlat")
  )
  cord_utm <- spTransform(cord_dec, CRS("+init=epsg:3765"))

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

  # Storing the longitude and latitude for the smoothed trajectory

  cord_utm_new <- SpatialPoints(cbind(smoothed$x, smoothed$y),
    proj4string = CRS("+init=epsg:3765")
  )

  cord_dec_new <- SpatialPoints(spTransform(cord_utm_new, CRS("+proj=longlat")),
    proj4string = CRS("+proj=longlat")
  )

  # Storing the minimum and maximum longitude and latitude

  mini_traj_long <- min(
    cord_dec_new$coords.x1[3:length(cord_dec_new$coords.x1)],
    mini_traj_long
  )
  maxi_traj_long <- max(
    cord_dec_new$coords.x1[3:length(cord_dec_new$coords.x1)],
    maxi_traj_long
  )
  mini_traj_lat <- min(
    cord_dec_new$coords.x2[3:length(cord_dec_new$coords.x2)],
    mini_traj_lat
  )
  maxi_traj_lat <- max(
    cord_dec_new$coords.x2[3:length(cord_dec_new$coords.x2)],
    maxi_traj_lat
  )
}

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

  cord_dec <- SpatialPoints(cbind(file_for_traj$lon, file_for_traj$lat),
    proj4string = CRS("+proj=longlat")
  )
  cord_utm <- spTransform(cord_dec, CRS("+init=epsg:3765"))

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

  # Storing the longitude and latitude for the smoothed trajectory

  cord_utm_new <- SpatialPoints(cbind(smoothed$x, smoothed$y),
    proj4string = CRS("+init=epsg:3765")
  )

  cord_dec_new <- SpatialPoints(spTransform(cord_utm_new, CRS("+proj=longlat")),
    proj4string = CRS("+proj=longlat")
  )

  data_frame_new <- data.frame(
    cord_dec_new$coords.x1[3:length(cord_dec_new$coords.x1)],
    cord_dec_new$coords.x2[3:length(cord_dec_new$coords.x2)]
  )

  names(data_frame_new) <- c("lon", "lat")

  # If the third point of the smoothed trajectory is east or north 
  # of the observed area midpoint, the trajectory is green,
  # otherwise it is red

  condition_use <- cord_dec_new$coords.x1[3] > meta_airport$longitude ||
    cord_dec_new$coords.x2[3] > meta_airport$latitude

  if (condition_use) {
    data_frame_coords_y <- rbind(data_frame_coords_y, data_frame_new)
  } else {
    data_frame_coords_n <- rbind(data_frame_coords_n, data_frame_new)
  }
}

# Defining the line representing class division

up_line_long <- c()
up_line_lat <- c()
right_line_long <- c()
right_line_lat <- c()

seq_val <- 1000

for (lat_val in seq(mini_traj_lat, maxi_traj_lat, length.out = seq_val)) {
  up_line_long <- c(up_line_long, meta_airport$longitude)
  up_line_lat <- c(up_line_lat, lat_val)
}

for (lon_val in seq(mini_traj_long, maxi_traj_long, length.out = seq_val)) {
  right_line_long <- c(right_line_long, lon_val)
  right_line_lat <- c(right_line_lat, meta_airport$latitude)
}

# Displaying the data on the OpenStreetMap (OSM) background

m <- leaflet() %>%
  addTiles() %>%
  addPolylines(
    lng = up_line_long,
    lat = up_line_lat,
    weight = 1,
    dashArray = "2, 2",
    col = "blue"
  ) %>%
  addPolylines(
    lng = right_line_long,
    lat = right_line_lat,
    weight = 1,
    dashArray = "2, 2",
    col = "blue"
  ) %>%
  addPolylines(
    lng = data_frame_coords_n$lon,
    lat = data_frame_coords_n$lat,
    weight = 2,
    col = "red"
  ) %>%
  addPolylines(
    lng = data_frame_coords_y$lon,
    lat = data_frame_coords_y$lat,
    weight = 2,
    col = "green"
  ) %>%
  print(m)
m

# Storing the map using the mapshot function

mapshot(m, file = "all_2D_leaflet_new.pdf")
