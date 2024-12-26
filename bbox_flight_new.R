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

filenames_for_trajs <- list.files(dir_for_trajs)
filenames_for_trajs_new <- c()

# Defining the range of step sizes for calculating the fractal dimension

fractal_steps <- TrajLogSequence(1000, 2000, 1000)

# Defining the variables to store the meteorological features

metar_t <- c()
metar_p0 <- c()
metar_p <- c()
metar_u <- c()
metar_ff <- c()
metar_td <- c()

# Defining the variables to store the trajectory features

traj_distance <- c()
traj_length <- c()
traj_duration <- c()
traj_speed <- c()
traj_acceleration <- c()
traj_straightness <- c()
traj_sinuosity2 <- c()
traj_emax <- c()
traj_dc <- c()
traj_sddc <- c()
traj_fractal_dimension <- c()

# Defining the variables to store the trajectory labels

label_col <- c()

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
    filenames_for_trajs_new <- c(filenames_for_trajs_new, filename_for_traj)
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

    label_val <- -1

    # If the third point of the smoothed trajectory is east or north 
    # of the observed area midpoint, the trajectory label is $1$,
    # otherwise we assign a label of $-1$

    if (smoothed$x[3] > mid_x || smoothed$y[3] > mid_y) {
      label_val <- 1
    }

    label_col <- c(label_col, label_val)

    derivs <- TrajDerivatives(smoothed)

    # Storing the meteorological features

    metar_t <- c(metar_t, mean(file_for_traj$T))
    metar_p0 <- c(metar_p0, mean(file_for_traj$P0))
    metar_p <- c(metar_p, mean(file_for_traj$P))
    metar_u <- c(metar_u, mean(file_for_traj$U))
    metar_ff <- c(metar_ff, mean(file_for_traj$Ff))
    metar_td <- c(metar_td, mean(file_for_traj$Td))

    # Storing the trajectory features

    traj_distance <- c(traj_distance, Traj3DDistance(smoothed))
    traj_length <- c(traj_length, Traj3DLength(smoothed))
    traj_duration <- c(traj_duration, TrajDuration(smoothed))
    traj_speed <- c(traj_speed, mean(derivs$speed))
    traj_acceleration <- c(traj_acceleration, mean(derivs$acceleration))
    traj_straightness <- c(traj_straightness, Traj3DStraightness(smoothed))
    traj_sinuosity2 <- c(traj_sinuosity2, TrajSinuosity2(smoothed))
    traj_emax <- c(traj_emax, TrajEmax(smoothed))
    traj_dc <- c(traj_dc, mean(TrajDirectionalChange(smoothed)))
    traj_sddc <- c(traj_sddc, sd(TrajDirectionalChange(smoothed)))
    traj_fractal_dimension <- c(
      traj_fractal_dimension,
      TrajFractalDimension(smoothed, fractal_steps)
    )

  }

  # Storing the trajectory labels and features,
  # and meteorological data into a common data frame

  df_clus <- data.frame(
    filenames_for_trajs_new,
    label_col,
    traj_distance,
    traj_length,
    traj_duration,
    traj_speed,
    traj_acceleration,
    traj_straightness,
    traj_sinuosity2,
    traj_emax,
    traj_dc,
    traj_sddc,
    traj_fractal_dimension,
    metar_t,
    metar_p,
    metar_p0,
    metar_u,
    metar_ff,
    metar_td
  )

  write.csv(df_clus, "features_traj_new.csv", row.names = FALSE)

}