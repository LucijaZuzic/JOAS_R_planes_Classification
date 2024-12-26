# Classification of departure flight trajectory segments from the Zagreb Pleso airport

## Python and $R$ scripts for preprocessing

![Python and $R$ scripts for preprocessing](/joas-preprocessing.drawio.png "Python and $R$ scripts for preprocessing")

### $download.py$

The Python script $download.py$ automatically downloads data from the state vector data set from OpenSkyNetwork (https://opensky-network.org/datasets/#states/) and stores it in the $.csv$ files in the directory $states\\_new$. The data is available to everyone free of charge and contains state vectors for each full hour on Mondays between 05.06.2017. and 27.6.2022. The values of latitude, longitude, and altitude in meters were used to build the trajectories in this experiment. Due to the large file size, and since it is already available from OpenSkyNetwork, this data is not reuploaded. Flights for which the state vectors need to be downloaded are defined in the file $usable\\_flights\\_new/usable\\_flights\\_new\\_\\{ICAO24\\_start\\}\\_\\{ICAO24\\\\_end\\\\}.csv$ created by the $R$ script $get\\_flights\\_new.R$, where the ICAO24 identifier of the origin, and destination airport is supplied to complete the file path.

### $extract\\_rp5.py$

The Python script $extract\\_rp5.py$ extracts data for a single day from the file $LDZA.05.06.2017.27.06.2022.1.0.0.en.utf8.00000000.csv$, which contains merged data for all days from 05.06.2017. to 27.06.2022. The publicly available meteorological data was obtained from METAR reports from the $rp5.ru$ website (https://rp5.ru/Weather\\_in\\_Zagreb,\\_Pleso\\_(airport)). Meteorological data for a single day is stored in $.csv$ files in the directory $rp5\\_new$.

### $get\\_flights\\_new.R$

The $R$ script $get\\_flights\\_new.R$ fetches the ICAO24 identifier, callsign, and seconds elapsed since the epoch time (00:00:00, 01.01.1970, UTC) when the flight begins (first seen), and ends (last seen) for all flights with a specified date range, and origin, and destination airport. In this case, the ICAO24 identifier for the origin airport, Zagreb Pleso airport (LDZA), and the destination airport, London Heathrow (EGLL), are listed. A username and password for an OpenSkyNetwork account are specified when making these database queries. Replace the placeholder values in the commented line defining the arguments for the $getAirportDepartures$ function with the username and password for OpenSkyNetwork created using the online form (https://opensky-network.org/index.php?option=com\\_users&view=registration). The data is saved into the file $usable\\_flights\\_new/usable\\_flights\\_new\\_\\{ICAO24\\_start\\}\\_\\{ICAO24\\_end\\}.csv$, where the ICAO24 identifier of the origin, and destination airport is supplied to complete the file path.

### $merge\\_flights\\_new.R$

The $R$ script $merge\\_flights\\_new.R$ saves all the state vectors for a flight into a single file based on the ICAO24 identifier, callsign, date, and time. State vectors merged for a single flight are stored in the $.csv$ files in the directory $usable\\_trajs\\_new$. Flights are defined in the file $usable\\_flights\\_new/usable\\_flights\\_new\\_\\{ICAO24\\_start\\}\\_\\{ICAO24\\_end\\}.csv$ created by the $R$ script $get\\_flights\\_new.R$, where the ICAO24 identifier of the origin, and destination airport is supplied to complete the file path. This preprocessing step is necessary since downloaded data in the $.csv$ files in the directory $states\\_new$ was originally stored hourly and merged for all flights. The state vector data set from OpenSkyNetwork (https://opensky-network.org/datasets/#states/) is free of charge and contains state vectors for each full hour on Mondays between 05.06.2017. and 27.6.2022. The values of latitude, longitude, and altitude in meters were used to build the trajectories in this experiment. Due to the large file size, and since it is already available from OpenSkyNetwork, this data is not reuploaded.

### $weather\\_flight\\_new.R$

The $R$ script $weather\\_flight\\_new.R$ adds publicly available meteorological data, obtained from METAR reports from the $rp5.ru$ website (https://rp5.ru/Weather\\_in\\_Zagreb,\\_Pleso\\_(airport)), to aircraft trajectory features. Measurements of meteorological features are added every half hour or every full hour in the analyzed $.csv$ files in the directory $rp5\\_new$, and state vectors for aircraft are stored every ten seconds in the $.csv$ files in the directory $usable\\_trajs\\_new$ obtained from OpenSkyNetwork data. The value from the meteorological report with the smallest time gap is added to each aircraft state vector, and the results are stored in the $.csv$ files in the directory $weather\\_trajs\\_new$.

### $bbox\\_flight\\_new.R$

The $R$ script $bbox\\_flight\\_new.R$ calculates trajectory features using the $trajr$ library. An observation area of $0.4$ degrees longitude and latitude around the Zagreb Pleso airport was selected to construct trajectories, approximately equal to $44.4$ $km$ at the latitude and longitude of this airport. The observed area is limited to the initial phase of the flight near the airport, and only this part of each trajectory is used in further processing. The arithmetic mean of all trajectory and meteorological features for state vectors within the observation radius and contained in the $.csv$ files in the directory $weather\\_trajs\\_new$ is then calculated to classify a trajectory, and saved into the file $features\\_traj\\_new.csv$.

## $R$ scripts for trajectory illustration

![$R$ scripts for trajectory illustration](/joas-trajectory.drawio.png "$R$ scripts for trajectory illustration")

### $draw\\_traj\\_new.R$

The $R$ script $draw\\_traj\\_new.R$ draws a visualisation of trajectory labelling stored in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$. All trajectories contained in the $.csv$ files in the directory $weather\\_trajs\\_new$ in which the third point was east of the latitude of $16.0688$ degrees $\\mathrm{E}$ or north of the longitude of $45.7429$ degrees $\\mathrm{N}$ representing the Zagreb Pleso airport are marked as class $1$ and shown in green. Other trajectories that satisfied none of the two specified conditions are marked as class $-1$ and shown in red, as visible in the file $all\\_2D\\_new.pdf$. Trajectories were smoothed and resampled to a constant time interval of $10$ $s$ between points before labelling. The third point was used because the first and second points were too close to the airport to distinguish between classes based on their coordinates.

### $draw\\_traj\\_leaflet\\_new.R$

The $R$ script $draw\\_traj\\_leaflet\\_new.R$ draws a visualisation of trajectory labelling stored in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$. The illustrations use the $leaflet$ library to show OpenStreetMap (OSM) data in the background. All trajectories contained in the $.csv$ files in the directory $weather\\_trajs\\_new$ in which the third point was east of the latitude of $16.0688$ degrees $\\mathrm{E}$ or north of the longitude of $45.7429$ degrees $\\mathrm{N}$ representing the Zagreb Pleso airport are marked as class $1$ and shown in green. Other trajectories that satisfied none of the two specified conditions are marked as class $-1$ and shown in red, as visible in the file $all\\_2D\\_leaflet\\_new.pdf$. Trajectories were smoothed and resampled to a constant time interval of $10$ $s$ between points before labelling. The third point was used because the first and second points were too close to the airport to distinguish between classes based on their coordinates.

### $draw\\_traj\\_map\\_new.R$

The $R$ script $draw\\_traj\\_leaflet\\_new.R$ draws a visualisation of trajectory labelling stored in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$. The illustrations use the $rworldmap$ library to show world map data in the background. All trajectories contained in the $.csv$ files in the directory $weather\\_trajs\\_new$ in which the third point was east of the latitude of $16.0688$ degrees $\\mathrm{E}$ or north of the longitude of $45.7429$ degrees $\\mathrm{N}$ representing the Zagreb Pleso airport are marked as class $1$ and shown in green. Other trajectories that satisfied none of the two specified conditions are marked as class $-1$ and shown in red, as visible in the file $all\\_2D\\_map\\_new.pdf$. Trajectories were smoothed and resampled to a constant time interval of $10$ $s$ between points before labelling. The third point was used because the first and second points were too close to the airport to distinguish between classes based on their coordinates.

### $x\\_y\\_trajs\\_new.R$

The $R$ script $xy\\_trajs\\_new.R$ draws a visualisation of trajectory labelling stored in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$. All trajectories contained in the $.csv$ files in the directory $weather\\_trajs\\_new$ in which the third point was east of the latitude of $16.0688$ degrees $\\mathrm{E}$ or north of the longitude of $45.7429$ degrees $\\mathrm{N}$ representing the Zagreb Pleso airport are marked as class $1$ and shown in green. Other trajectories that satisfied none of the two specified conditions are marked as class $-1$ and shown in red, as visible in the $.pdf$ files in the directories $x\\_y\\_plots\\_new$, $x\\_z\\_plots\\_new$, and $y\\_z\\_plots\\_new$ for each trajectory. Trajectories were smoothed and resampled to a constant time interval of $10$ $s$ between points before labelling. The third point was used because the first and second points were too close to the airport to distinguish between classes based on their coordinates.

### $x\\_y\\_trajs\\_leaflet\\_new.R$

The $R$ script $draw\\_traj\\_leaflet\\_new.R$ draws a visualisation of trajectory labelling stored in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$. The illustrations use the $leaflet$ library to show OpenStreetMap (OSM) data in the background. All trajectories contained in the $.csv$ files in the directory $weather\\_trajs\\_new$ in which the third point was east of the latitude of $16.0688$ degrees $\\mathrm{E}$ or north of the longitude of $45.7429$ degrees $\\mathrm{N}$ representing the Zagreb Pleso airport are marked as class $1$ and shown in green. Other trajectories that satisfied none of the two specified conditions are marked as class $-1$ and shown in red, as visible in the $.pdf$ files in the directory $x\\_y\\_leaflet\\_new$ for each trajectory. Trajectories were smoothed and resampled to a constant time interval of $10$ $s$ between points before labelling. The third point was used because the first and second points were too close to the airport to distinguish between classes based on their coordinates.

### $x\\_y\\_trajs\\_map\\_new.R$

The $R$ script $draw\\_traj\\_leaflet\\_new.R$ draws a visualisation of trajectory labelling stored in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$. The illustrations use the $rworldmap$ library to show world map data in the background. All trajectories contained in the $.csv$ files in the directory $weather\\_trajs\\_new$ in which the third point was east of the latitude of $16.0688$ degrees $\\mathrm{E}$ or north of the longitude of $45.7429$ degrees $\\mathrm{N}$ representing the Zagreb Pleso airport are marked as class $1$ and shown in green. Other trajectories that satisfied none of the two specified conditions are marked as class $-1$ and shown in red, as visible in the $.pdf$ files in the directory $x\\_y\\_maps\\_new$ for each trajectory. Trajectories were smoothed and resampled to a constant time interval of $10$ $s$ between points before labelling. The third point was used because the first and second points were too close to the airport to distinguish between classes based on their coordinates.

### $3D\\_traj\\_all.R$

The $R$ script $3D\\_traj\\_all.R$ draws a three-dimensional visualisation of trajectory labelling stored in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$. The illustrations use the $rgl$ library to show three-dimensional plots. All trajectories contained in the $.csv$ files in the directory $weather\\_trajs\\_new$ in which the third point was east of the latitude of $16.0688$ degrees $\\mathrm{E}$ or north of the longitude of $45.7429$ degrees $\\mathrm{N}$ representing the Zagreb Pleso airport are marked as class $1$ and shown in green. Other trajectories that satisfied none of the two specified conditions are marked as class $-1$ and shown in red, as visible in the file $all\\_3D\\_new.png$. Trajectories were smoothed and resampled to a constant time interval of $10$ $s$ between points before labelling. The third point was used because the first and second points were too close to the airport to distinguish between classes based on their coordinates.

### $3D\\_traj.R$

The $R$ script $3D\\_traj.R$ draws a three-dimensional visualisation of trajectory labelling stored in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$. The illustrations use the $rgl$ library to show three-dimensional plots. All trajectories contained in the $.csv$ files in the directory $weather\\_trajs\\_new$ in which the third point was east of the latitude of $16.0688$ degrees $\\mathrm{E}$ or north of the longitude of $45.7429$ degrees $\\mathrm{N}$ representing the Zagreb Pleso airport are marked as class $1$ and shown in green. Other trajectories that satisfied none of the two specified conditions are marked as class $-1$ and shown in red, as visible in the $png$ files in the directory $3D\\_plots$ for each trajectory. Trajectories were smoothed and resampled to a constant time interval of $10$ $s$ between points before labelling. The third point was used because the first and second points were too close to the airport to distinguish between classes based on their coordinates.

### $fractal\\_dim\\_traj.R$

The $R$ script $fractal\\_dim\\_traj.R$ creates illustrations of fractal dimension calculation showing path length depending on step size for trajectories stored in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$. The range of step sizes used to calculate the fractal dimension must be predefined. The function $TrajLogSequence$ returns a specified number of points in a given range that can be used as step sizes, and the points are uniformly spaced if viewed on a logarithmic axis. A thousand values uniformly spaced between one and two kilometers on the logarithmic axis were used to estimate the fractal dimension of the aircraft's trajectory. An empirical assessment of the minimum and maximum aircraft speed and distance traveled in one ten-second step determines the lower and upper range boundaries. A test using the function $TrajFractalDimensionValues$ returns the trajectory lengths calculated for a range of step sizes. If the relationship between step size and trajectory length is linear, then the trajectory is a fractal curve for a given range of step sizes. The direction in which the trajectory length is linearly dependent on the step size was estimated by linear regression using the $lm$ function from the $stats$ library. The results of this test are stored in the $pdf$ files in the directory $fractal\\_dim\\_vals$ for each trajectory.

## $R$ and Python scripts for variable analysis

![$R$ and Python scripts for variable analysis](/joas-variable.drawio.png "$R$ and Python scripts for variable analysis")

### $variable\\_analysis\\_new.R$

The $R$ script $variable\\_analysis\\_new.R$ performs normal distribution analysis on the trajectory and meteorological features in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$. The minimum, $1^{st}$ quartile, median, arithmetic mean, standard deviation, $3^{rd}$ quartile, and maximum values for all variables in the training and testing data are saved into the file $quantile\\_new.csv$. Histograms, boxplots, and probability density plots for individual variables are stored as $.pdf$ files in the $hist\\_new$, $boxplot\\_new$, and $density\\_new$ directories respectively. Q-Q plots for individual variables in the negative, positive, and all classes are stored as $.pdf$ files in the $qq\\_neg\\_new$, $qq\\_pos\\_new$, and $qq\\_new$ directories respectively.

### $correlation\\_new.R$

The $R$ script $correlation\\_flight\\_new.R$ performs correlation analysis on the trajectory and meteorological features in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$. Correlation analysis results on the training and testing data are saved into the file $corr.csv$.

### $format\\_quantile\\_table.py$

The Python script $format\\_quantile\\_table.py$ reads the minimum, $1^{st}$ quartile, median, arithmetic mean, standard deviation, $3^{rd}$ quartile, and maximum values for all variables in the training and testing data that are saved into the file $quantile\\_new.csv$ by the $R$ script $variable\\_analysis\\_new.R$, and formatting it into a Latex table that is then printed into standard output. The variable normality analysis is performed on all the data defined in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$.

### $corrtest.py$

The Python script $corrtest.py$ reads the results of the correlation analysis on the training and testing data that are saved into the file $corr.csv$ by the $R$ script $correlation\\_new.R$. The data is saved in $.png$, $.pdf$, and $.svg$ format in files named $corrplot$. The correlation analysis is performed on the data defined in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$.

### $multiplot.py$

The Python script $multiplot.py$ draws boxplots, and histograms representing the class-dependent distribution for the trajectory and meteorological features. The data is saved in $.png$, $.pdf$, and $.svg$ format in files named $boxplot$, and $hist$ to match the plot type. The plot utilises all the data defined in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$.

## $R$ scripts for model training

![$R$ scripts for model training](/joas-training.drawio.png "$R$ and Python scripts for variable analysis")

### $classify\\_flight\\_new.R$

The $R$ script $classify\\_flight\\_new.R$ performs model training on the data in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$.

Classification methods included the following algorithms:

<ul>
  <li>k-Nearest Neighbours (k-NN)</li>
  <li>Gaussian Process (GP)</li>
  <li>Decision Tree (DT)</li>
  <li>Random Forest (RF)</li>
  <li>Multilayer Perceptron (MLP)</li>
  <li>Naive Bayes (NB)</li>
  <li>Quadratic Discriminant Analysis (QDA)</li>
  <li>AdaBoost (AB)</li>
  <li>Linear Support Vector Machine (SVM)</li>
  <li>Radial Basis Function (RBF) Support Vector Machine (SVM)</li>
</ul>

Research results are presented with eleven trajectory-derived predictors:

<ul>
  <li>diffusion distance</li>
  <li>trajectory length</li>
  <li>trajectory duration</li>
  <li>speed</li>
  <li>acceleration</li>
  <li>straightness</li>
  <li>sinuosity</li>
  <li>maximum expected displacement</li>
  <li>the arithmetic average of direction change</li>
  <li>the standard deviation of direction change</li>
  <li>the fractal dimension</li>
</ul>

The following six meteorological features were also included:

<ul>
  <li>temperature</li>
  <li>air pressure at sea level</li>
  <li>air pressure at the measuring station</li>
  <li>relative humidity</li>
  <li>wind speed</li>
  <li>dew point</li>
</ul>

Candidate models have been developed using:

<ol>
  <li>trajectory and meteorological features</li>
  <li>exclusively trajectory features</li>
  <li>exclusively meteorological features</li>
  <li>exclusively diffusion distance and the arithmetic average of direction change</li>
</ol>

Classification results on the training data are saved into the file $predictions\\_train\\_new.csv$. Classification results on the testing data are saved into the file $predictions\\_test\\_new.csv$. Classification results on the testing data are saved into the file $predictions\\_test\\_new.csv$. A visualisation for the Decision tree method is saved into files named $trees\\_new/all\\_{model\\_name}\\_tree.pdf$, where the model name is supplied to complete the file path.

### $classify\\_flight\\_new\\_time.R$

The $R$ script $classify\\_flight\\_new\\_time.R$ calculates execution time for performing training and testing using the evaluated models on the data in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$. The execution time is saved into the file $time.txt$.

### $visualise\\_class\\_new\\_time.R$

The $R$ script $visualise\\_class\\_new\\_time.R$ generates illustrations of classification on a two-dimensional decision surface when using diffusion distance and the arithmetic average of direction change as predictors from the data stored in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$. The $.pdf$ files showing classification using the training, testing and all data are in the directory $trees\\_new/all\\_{model\\_name}\\_tree.pdf$, where the model name is supplied to complete the file path. The positive class is shown in green, and the negative class is shown in red. Testing data points are triangles, and training data points are squares. The shade of the data points represents their ground truth labels, while the background represents the class assigned by the model classification predictions.

## Python scripts for postprocessing

### $confmatr.py$

The Python script $confmatr.py$ calculates confusion matrix performance indicators for classification results on the testing data that are saved into the file $predictions\\_test\\_new.csv$ by the $R$ script $classify\\_flight\\_new.R$. Confusion matrix performance indicators are formatted into a Latex table that is then printed into standard output.

### $mcnemar.py$

The Python script $mcnemar.py$ calculates the results of McNemar's test for classification results on the testing data that are saved into the file $predictions\\_test\\_new.csv$ by the $R$ script $classify\\_flight\\_new.R$. The data is saved in $.png$, $.pdf$, and $.svg$ format in files named $mcnemarplot$.

### $read\\_ex\\_time.py$

The Python script $read\\_ex\\_time.py$ reads execution time for performing training and testing using the evaluated models that was saved into the file $time.txt$ by the $R$ script $classify\\_flight\\_new\\_time.R$, and formatting it into a Latex table that is then printed into standard output. The execution time is computed by training on the training data and performing classification on the testing data defined in the file $features\\_traj\\_new.csv$ created by the $R$ script $bbox\\_flight\\_new.R$.

## $R$ scripts containing helper function definitions

### $transform\\_feature.R$

The $R$ script $transform\\_feature.R$ defines a function named $transform\\_feat$ that converts variable name abbreviations into full names and measuring units for drawing plots and saving tables. This function is utilized in model training and testing by the $R$ scripts $variable\\_analysis\\_new.R$, and $visualise\\_class\\_new.R$.

### $preprocess\\_for\\_training.R$

The $R$ script $preprocess\\_for\\_training.R$ defines a function named $preprocesing\\_function$ that performs preprocessing and splits the data into the training and testing dataset with a random seed of $42$ for reproducibility across function calls $294$ original trajectories are used for training and testing. The samples are divided into training and testing datasets as close as possible to a ratio of $70\\%$ for training and $30\\%$ for testing. The division was stratified so that an approximately equal ratio of classes was present in both the training and testing data. This function is utilized in model training and testing by the $R$ scripts $classify\\_flight\\_new.R$ and $classify\\_flight\\_new\\_time.R$.

### $use\\_model.R$

The $R$ script $use\\_model.R$ defines a function named model\\_use that performs model training with the specified dataset for the specified model name, method, training data, testing data, training labels, and testing labels. If the method used is a Decision Tree, a visualisation of the tree is plotted and saved with the specified file path. This function is utilized in model training and testing by the $R$ scripts $classify\\_flight\\_new.R$ and $classify\\_flight\\_new\\_time.R$.

## System requirements

The study was conducted on the $Windows$ 11 operating system with $R Studio$ version 2024.04.2+764 and $R$ version 4.4.1, the AMD Radeon RX 6600 Graphics Processing Unit (GPU), $16$ GB of Random Access Memory (RAM), running the AMD Ryzen 5 PRO 4650G Central Processing Unit (CPU) with $6$ cores.

### Python packages

The experiment was run using Python 3.11.7, and required packages are numpy (version 1.26.4) pandas (version 2.1.4), scipy (version 1.11.4), seaborn (version 0.12.2), matplotlib (version 3.8.0), scikit-learn (version 1.2.2), and requests version (2.31.0). More detailed requirements are listed in the file $requirements.yml$, and can be installed using a package manager like $conda$.

### $R$ packages from $sessionInfo()$

attached base packages:

<ul>
  <li>grid</li>
  <li>stats</li>
  <li>graphics</li>
  <li>grDevices</li>
  <li>utils</li>
  <li>datasets</li>
  <li>methods</li>
  <li>base</li>
</ul>

other attached packages:

<ul>
  <li>rgl_1.3.14</li>
  <li>rworldmap_1.3-8</li>
  <li>mapview_2.11.2</li>
  <li>leaflet_2.2.2</li>
  <li>trajr_1.5.1</li>
  <li>sp_2.1-4</li>
  <li>openSkies_1.2.1</li>
  <li>JOUSBoost_2.1.0</li>
  <li>MASS_7.3-60.2</li>
  <li>class_7.3-22</li>
  <li>caret_6.0-94</li>
  <li>lattice_0.22-6</li>
  <li>nnet_7.3-19</li>
  <li>fdm2id_0.9.9</li>
  <li>FactoMineR_2.11</li>
  <li>arulesViz_1.5.3</li>
  <li>arules_1.7-8</li>
  <li>Matrix_1.7-0</li>
  <li>naivebayes_1.0.0</li>
  <li>randomForest_4.7-1.2</li>
  <li>rpart.plot_3.1.2</li>
  <li>rpart_4.1.23</li>
  <li>kernlab_0.9-33</li>
  <li>e1071_1.7-14</li>
  <li>lubridate_1.9.3</li>
  <li>forcats_1.0.0</li>
  <li>stringr_1.5.1</li>
  <li>purrr_1.0.2</li>
  <li>readr_2.1.5</li>
  <li>tidyr_1.3.1</li>
  <li>tibble_3.2.1</li>
  <li>ggplot2_3.5.1</li>
  <li>tidyverse_2.0.0</li>
  <li>dplyr_1.1.4</li>
</ul>

loaded via a namespace (and not attached):

<ul>
  <li>splines_4.4.1</li>
  <li>fields_16.3</li>
  <li>bitops_1.0-8</li>
  <li>polyclip_1.10-7</li>
  <li>hardhat_1.4.0</li>
  <li>pROC_1.18.5</li>
  <li>lifecycle_1.0.4</li>
  <li>sf_1.0-19</li>
  <li>processx_3.8.4</li>
  <li>globals_0.16.3</li>
  <li>credentials_2.0.2</li>
  <li>flashClust_1.01-2</li>
  <li>crosstalk_1.2.1</li>
  <li>magrittr_2.0.3</li>
  <li>rmarkdown_2.28</li>
  <li>jquerylib_0.1.4</li>
  <li>yaml_2.3.10</li>
  <li>spam_2.11-0</li>
  <li>askpass_1.2.0</li>
  <li>DBI_1.2.3</li>
  <li>maps_3.4.2.1</li>
  <li>ggraph_2.2.1</li>
  <li>tweenr_2.0.3</li>
  <li>ipred_0.9-15</li>
  <li>satellite_1.0.5</li>
  <li>lava_1.8.0</li>
  <li>ggrepel_0.9.6</li>
  <li>listenv_0.9.1</li>
  <li>terra_1.7-83</li>
  <li>units_0.8-5</li>
  <li>parallelly_1.38.0</li>
  <li>codetools_0.2-20</li>
  <li>DT_0.33</li>
  <li>xml2_1.3.6</li>
  <li>ggforce_0.4.2</li>
  <li>tidyselect_1.2.1</li>
  <li>raster_3.6-30</li>
  <li>farver_2.1.2</li>
  <li>viridis_0.6.5</li>
  <li>stats4_4.4.1</li>
  <li>base64enc_0.1-3</li>
  <li>webshot_0.5.5</li>
  <li>jsonlite_1.8.8</li>
  <li>tidygraph_1.3.1</li>
  <li>survival_3.6-4</li>
  <li>iterators_1.0.14</li>
  <li>emmeans_1.10.5</li>
  <li>signal_1.8-1</li>
  <li>foreach_1.5.2</li>
  <li>dbscan_1.2-0</li>
  <li>tools_4.4.1</li>
  <li>progress_1.2.3</li>
  <li>Rcpp_1.0.13</li>
  <li>glue_1.7.0</li>
  <li>prodlim_2024.06.25</li>
  <li>gridExtra_2.3</li>
  <li>xfun_0.49</li>
  <li>withr_3.0.1</li>
  <li>fastmap_1.2.0</li>
  <li>fansi_1.0.6</li>
  <li>openssl_2.2.1</li>
  <li>callr_3.7.6</li>
  <li>digest_0.6.37</li>
  <li>timechange_0.3.0</li>
  <li>R6_2.5.1</li>
  <li>estimability_1.5.1</li>
  <li>colorspace_2.1-1</li>
  <li>jpeg_0.1-10</li>
  <li>utf8_1.2.4</li>
  <li>generics_0.1.3</li>
  <li>pls_2.8-4</li>
  <li>data.table_1.16.0</li>
  <li>recipes_1.1.0</li>
  <li>prettyunits_1.2.0</li>
  <li>graphlayouts_1.2.0</li>
  <li>httr_1.4.7</li>
  <li>htmlwidgets_1.6.4</li>
  <li>scatterplot3d_0.3-44</li>
  <li>ModelMetrics_1.2.2.2</li>
  <li>pkgconfig_2.0.3</li>
  <li>gtable_0.3.5</li>
  <li>timeDate_4032.109</li>
  <li>sys_3.4.2</li>
  <li>htmltools_0.5.8.1</li>
  <li>dotCall64_1.2</li>
  <li>multcompView_0.1-10</li>
  <li>scales_1.3.0</li>
  <li>leaps_3.2</li>
  <li>png_0.1-8</li>
  <li>RPresto_1.4.6</li>
  <li>gower_1.0.1</li>
  <li>knitr_1.48</li>
  <li>rstudioapi_0.16.0</li>
  <li>tzdb_0.4.0</li>
  <li>reshape2_1.4.4</li>
  <li>nlme_3.1-164v
  <li>curl_5.2.2</li>
  <li>proxy_0.4-27</li>
  <li>cachem_1.1.0</li>
  <li>KernSmooth_2.23-24</li>
  <li>parallel_4.4.1</li>
  <li>pillar_1.9.0</li>
  <li>vctrs_0.6.5</li>
  <li>dbplyr_2.5.0</li>
  <li>xtable_1.8-4</li>
  <li>cluster_2.1.6</li>
  <li>evaluate_0.24.0</li>
  <li>magick_2.8.5</li>
  <li>mvtnorm_1.3-1</li>
  <li>cli_3.6.3</li>
  <li>compiler_4.4.1</li>
  <li>rlang_1.1.4</li>
  <li>crayon_1.5.3</li>
  <li>future.apply_1.11.2</li>
  <li>ggmap_4.0.0</li>
  <li>mclust_6.1.1</li>
  <li>classInt_0.4-10</li>
  <li>ps_1.7.7</li>
  <li>plyr_1.8.9</li>
  <li>stringi_1.8.4</li>
  <li>viridisLite_0.4.2</li>
  <li>munsell_0.5.1</li>
  <li>hms_1.1.3</li>
  <li>leafem_0.2.3</li>
  <li>future_1.34.0</li>
  <li>ssh_0.9.3</li>
  <li>igraph_2.0.3</li>
  <li>memoise_2.0.1
</ul>
