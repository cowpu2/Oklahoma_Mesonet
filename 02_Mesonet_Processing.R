## ===============  Mesonet Data Compiling and Conversions ===============
##
## CodeMonkey:  Mike Proctor
##
## Compile Mesonet data, convert temp and wind columns to F and MPH, and
## PPT to inches - also calculates FWI
## ======================================================================

source("Setup.R")
##  Packages ----
library(okmesonet)   ##  Interface for Oklahoma mesonet
library(tictoc)
#library(readr)       ##  "Import dataset" uses this


# 2019-12-04 13:19:56 ------------------------------mdp
# 2020-06-24 12:06:39 ------------------------------mdp
# 2025-02-22 20:59:43.531405 ------------------------------mdp


##  Get a list of files  ----------
fnames <- list.files(dat_path, pattern = "*.dat", full.names = TRUE)

##  Read all files and generate a large list then bind_rows to one df -----------
tic()
meso <-lapply(fnames, read_csv, guess_max = 3500)  %>% 
  bind_rows() # type conversion error in some columns with NA - 2013 SRAD is NA till 2970 rows - guess_max gets around it
toc()

tic()
##  Unit conversion of some fields  --------
meso <- meso %>% mutate("Temp"            = TAIR * 1.8 + 32           ## Bare soil Temp in F
                        #"Soil_Veg_10cm"   = TS10 * 1.8 + 32,           ## Temperature Under Native Vegetation at 10cm in F
                        #"Soil_Bare_10cm"  = TB10 * 1.8 + 32,           ## Temperature Under Bare Soil at 10cm in F
                        #"Wind"            = WSPD * 2.237,             ## 5-minute averaged wind speed at 10m in MPH
                        #"Wind_2m"         = WS2M * 2.237,             ## 2m Wind Speed in MPH
                        #"WindMax"         = WMAX * 2.237,             ## Highest 3-second wind speed at 10m sample in MPH
                        #"PPT_in"          = round(RAIN / 25.4,2),     ## PPT in inches
                        #"FWI"             = (3.96-TR05)/(3.96-1.38)   ## Fractional Water Index - unitless
)                                                                      ## http://www.mesonet.org/files/instruments/Illstonetal2008.pdf

                        toc()




##  Write out file with filename generated from max and min dates in dataset  ----------------
B_date <- paste0(year(min(meso$TIME)),"_", month(min(meso$TIME)), "_", day(min(meso$TIME)))
E_date <- paste0(year(max(meso$TIME)),"_", month(max(meso$TIME)), "_", day(max(meso$TIME)))
fid <- paste0(B_date,"_", E_date)
write_csv(meso, paste0(dat_path, "Mesonet_", fid, ".dat"))






