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

# Including the function for fetching feature names and measuring units

source("transform_feature.R")

# Fetching the names of all files combining trajectories and meteorological data

dir_for_trajs <- "weather_trajs_new"

# Setting the directory for the histograms

dir_for_hist <- paste("hist_new", sep = "_")

if (!dir.exists(dir_for_hist)) {
  dir.create(dir_for_hist)
}

# Setting the directory for the boxplots

dir_for_boxplot <- paste("boxplot_new", sep = "_")

if (!dir.exists(dir_for_boxplot)) {
  dir.create(dir_for_boxplot)
}

# Setting directory for the probability density plots

dir_for_density <- paste("density_new", sep = "_")

if (!dir.exists(dir_for_density)) {
  dir.create(dir_for_density)
}

# Setting the directory for the Q-Q plots for all trajectories

dir_for_qq <- paste("qq_new", sep = "_")

if (!dir.exists(dir_for_qq)) {
  dir.create(dir_for_qq)
}

# Setting the directory for the Q-Q plots for class -1

dir_for_qq_neg <- paste("qq_neg_new", sep = "_")

if (!dir.exists(dir_for_qq_neg)) {
  dir.create(dir_for_qq_neg)
}

# Setting the directory for the Q-Q plots for class 1

dir_for_qq_pos <- paste("qq_pos_new", sep = "_")

if (!dir.exists(dir_for_qq_pos)) {
  dir.create(dir_for_qq_pos)
}

# Opening the file with trajectory labels, features, 
# and meteorological features

df_clus <- data.frame(read.csv("features_traj_new.csv"))
df_clus <- subset(df_clus, select = -c(filenames_for_trajs_new))

# Filtering trajectories by label

df_clus_yes <- filter(df_clus, label_col == 1)
df_clus_no <- filter(df_clus, label_col == -1)

# Removing trajectory labels

df_clus_yes <- subset(df_clus_yes, select = -c(label_col))
df_clus_no <- subset(df_clus_no, select = -c(label_col))

# Saving the output

sink("quantile_new.txt")

save_pdf <- TRUE

for (i in 1:length(names(df_clus_yes))) {

  # Fetching feature names and measuring units

  original_name <- names(df_clus_yes)[i]
  new_lab <- transform_feat(original_name)

  # Finding the variable minimum and maximum

  mini_yes <- min(df_clus_yes[, i])
  mini_no <- min(df_clus_no[, i])
  mini_all <- min(mini_yes, mini_no)

  maxi_yes <- max(df_clus_yes[, i])
  maxi_no <- max(df_clus_no[, i])
  maxi_all <- max(maxi_yes, maxi_no)

  # Defining histogram axis labels

  xrange_use <- seq(mini_all, maxi_all, length.out = 20)

  # The number of elements in each segment for the histogram

  hv_yes <- hist(df_clus_yes[, i], breaks = xrange_use, plot = FALSE)$counts
  hv_no <- hist(df_clus_no[, i], breaks = xrange_use, plot = FALSE)$counts

  # Separating the title without the measuring unit

  new_name <- unlist(strsplit(as.character(new_lab), " "))
  new_new_name <- ""
  for (nn in new_name) {
    condi <- substr(nn, 1, 1) == "(" &&
      substr(nn, str_length(nn), str_length(nn)) == ")" &&
      nn != "(prosjek)"
    if (!condi && substr(nn, 1, 1) != "~") {
      new_new_name <- paste(new_new_name, nn, sep = " ")
    }
  }
  new_name <- substr(new_new_name, 2, nchar(new_new_name))

  # Drawing the histograms

  total <- sum(hv_yes, hv_no)

  barplot(rbind(hv_yes / total, hv_no / total),
    col = c("green", "red"),
    main = paste("Histogram", new_name, sep = "\n"),
    space = 0,
    xlab = new_lab, ylab = "Probability",
    cex.lab = 1.5, cex.main = 1.7
  )

  # Adding axis labels

  new_data_x <- c()

  for (val in xrange_use) {
    new_data_x <- c(new_data_x, round(val, 3))
  }

  axis(1, at = 0:19, labels = new_data_x, cex = 1.4)

  # Adding the legend

  poslegend <- "topright"

  ifcond <- original_name == "traj_distance" ||
    original_name == "traj_acceleration" ||
    original_name == "metar_td"

  if (ifcond) {
    poslegend <- "topleft"
  }

  legend(poslegend,
    legend = c("1", "-1"), cex = 1.4, text.width = strwidth("-1") * 2,
    col = c("green", "red"), lty = c(1, 1), lwd = c(2, 2)
  )

  # Saving the histograms

  if (save_pdf) {
    dev.copy(pdf, paste(paste(dir_for_hist, original_name, sep = "//"), "pdf", sep = "."))
  }

  # Closing the histograms

  if (length(dev.list()) > 0) {
    for (dev_sth_open in dev.list()[1]:dev.list()[length(dev.list())]) {
      dev.off()
    }
  }

  # Drawing the boxplot

  boxdata <- data.frame(df_clus[, 1], df_clus[, i + 1])
  names(boxdata) <- c("lab", "feat")

  boxplot(feat ~ lab,
    data = boxdata,
    col = c("red", "green"),
    main = paste("Box plot", new_name, sep = "\n"),
    ylab = "Class", xlab = new_lab, horizontal = TRUE,
    cex.lab = 1.5, cex.main = 1.7, cex.axis = 1.5
  )
  
  # Saving the boxplot

  if (save_pdf) {
    dev.copy(pdf, paste(paste(dir_for_boxplot, original_name, sep = "//"), "pdf", sep = "."))
  }

  # Closing the boxplot

  if (length(dev.list()) > 0) {
    for (dev_sth_open in dev.list()[1]:dev.list()[length(dev.list())]) {
      dev.off()
    }
  }

  # Drawing the probability density plot

  density_a <- density(df_clus[, i + 1],
    from = min(df_clus[, i + 1]),
    to = max(df_clus[, i + 1])
  )

  density_y <- density(df_clus_yes[, i],
    from = min(df_clus_yes[, i]),
    to = max(df_clus_yes[, i])
  )

  density_n <- density(df_clus_no[, i],
    from = min(df_clus_no[, i]),
    to = max(df_clus_no[, i])
  )

  plot(density_a,
    col = "blue", lwd = 2,
    ylim = c(
      min(min(density_a$y), min(min(density_n$y), min(density_y$y))),
      max(max(density_a$y), max(max(density_n$y), max(density_y$y)))
    ),
    xlim = c(
      min(min(density_n$x), min(density_y$x)),
      max(max(density_n$x), max(density_y$x))
    ),
    main = paste("Probability density", new_name, sep = "\n"),
    xlab = new_lab, ylab = "Probability density",
    cex.lab = 1.5, cex.main = 1.7, cex.axis = 1.5
  )
  lines(density_n, col = "red", lwd = 2)
  lines(density_y, col = "green", lwd = 2)

  # Adding the legend

  poslegend <- "topright"

  if (original_name == "traj_acceleration") {
    poslegend <- "topleft"
  }

  legend(poslegend,
    legend = c("All", "-1", "1"), cex = 1.3, text.width = strwidth("All") * 2,
    col = c("blue", "red", "green"), lty = c(1, 1, 1), lwd = c(2, 2, 2)
  )

  # Saving the probability density plot

  if (save_pdf) {
    dev.copy(pdf, paste(paste(dir_for_density, original_name, sep = "//"), "pdf", sep = "."))
  }

  # Closing the probability density plot

  if (length(dev.list()) > 0) {
    for (dev_sth_open in dev.list()[1]:dev.list()[length(dev.list())]) {
      dev.off()
    }
  }

  # Printing the variable quantiles, mean, and standard deviation

  print(new_name)
  print("All")
  print(quantile(df_clus[, i + 1]))
  print(mean(df_clus[, i + 1]))
  print(sd(df_clus[, i + 1]))
  print(-1)
  print(quantile(df_clus_no[, i]))
  print(mean(df_clus_no[, i]))
  print(sd(df_clus_no[, i]))
  print(1)
  print(quantile(df_clus_yes[, i]))
  print(mean(df_clus_yes[, i]))
  print(sd(df_clus_yes[, i]))

  # Printing the Mann–Whitney U test Printing the 

  df_wilcox <- data.frame(df_clus[, 1], df_clus[, i + 1])
  names(df_wilcox) <- c("lab", "val")

  print(wilcox.test(val ~ lab,
    data = df_wilcox,
    exact = FALSE
  ))

  # Printing the Welch t-test results

  print(t.test(val ~ lab,
    data = df_wilcox,
    exact = FALSE
  ))

  # Printing the Shapiro-Wilk test results

  print(shapiro.test(df_clus[, i + 1]))
  print(shapiro.test(df_clus_no[, i]))
  print(shapiro.test(df_clus_yes[, i]))

  # Printing the Kolmogorov-Smirnov test results

  print(ks.test(df_clus[, i + 1], "pnorm", mean = mean(df_clus[, i + 1]), sd = sd(df_clus[, i + 1])))
  print(ks.test(df_clus_no[, i], "pnorm", mean = mean(df_clus_no[, i]), sd = sd(df_clus_no[, i])))
  print(ks.test(df_clus_yes[, i], "pnorm", mean = mean(df_clus_yes[, i]), sd = sd(df_clus_yes[, i])))

  # Drawing the Q-Q plot for all trajectories

  qqnorm(df_clus[, i + 1],
    main = paste("Q-Q plot for all trajectories", new_name, sep = "\n"),
    xlab = "Theoretical quantiles",
    ylab = "Sample quantiles",
    col = "blue",
    cex.lab = 1.5, cex.main = 1.7, cex.axis = 1.5
  )

  qqline(df_clus[, i + 1], col = "red")

  # Saving the Q-Q plot for all trajectories

  if (save_pdf) {
    dev.copy(pdf, paste(paste(dir_for_qq, original_name, sep = "//"), "pdf", sep = "."))
  }

  # Closing the Q-Q plot for all trajectories

  if (length(dev.list()) > 0) {
    for (dev_sth_open in dev.list()[1]:dev.list()[length(dev.list())]) {
      dev.off()
    }
  }

  # Drawing Q-Q plot for class -1

  qqnorm(df_clus_no[, i],
    main = paste("Q-Q plot (class -1)", new_name, sep = "\n"),
    xlab = "Theoretical quantiles",
    ylab = "Sample quantiles",
    col = "blue",
    cex.lab = 1.5, cex.main = 1.7, cex.axis = 1.5
  )

  qqline(df_clus_no[, i], col = "red")

  # Saving the Q-Q plot for class -1

  if (save_pdf) {
    dev.copy(pdf, paste(paste(dir_for_qq_neg, original_name, sep = "//"), "pdf", sep = "."))
  }

  # Closing the Q-Q plot for class -1

  if (length(dev.list()) > 0) {
    for (dev_sth_open in dev.list()[1]:dev.list()[length(dev.list())]) {
      dev.off()
    }
  }

  # Drawing Q-Q plot for class 1

  qqnorm(df_clus_yes[, i],
    main = paste("Q-Q plot (class 1)", new_name, sep = "\n"),
    xlab = "Theoretical quantiles",
    ylab = "Sample quantiles",
    col = "blue",
    cex.lab = 1.5, cex.main = 1.7, cex.axis = 1.5
  )

  qqline(df_clus_yes[, i], col = "red")

  # Saving the Q-Q plot for class 1

  if (save_pdf) {
    dev.copy(pdf, paste(paste(dir_for_qq_pos, original_name, sep = "//"), "pdf", sep = "."))
  }

  # Closing the Q-Q plot for class 1

  if (length(dev.list()) > 0) {
    for (dev_sth_open in dev.list()[1]:dev.list()[length(dev.list())]) {
      dev.off()
    }
  }
}

sink()