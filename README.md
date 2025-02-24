---
title: "Mesonet Downloads"
output:
  html_document:
    df_print: paged
bibliography: grateful-refs.bib
nocite: '@*'
---


## * Download data from Oklahoma Mesonet

+ Uses a really old package that hasn't been available on CRAN for years. It is available here: [Index of /src/contrib/Archive/okmesonet](https://cran.r-project.org/src/contrib/Archive/okmesonet/).  Download the tar and from within RStudio use |Install|Packages| - chose Install from Package Archive and select the file you downloaded.  This worked as of R 4.4.2.

+ Multiple years can be downloaded by modifying "annis"
+ Smaller periods can be downloaded using alternate script  

+ Totals for day are stored in next day @ 00:00 so get an extra day  

+ Uses year range and current time as timestamp in file name to prevent overwriting previous data.  

+ Writes a dat file for each year - this is a normal csv but excel will choke on opening it, which prevents excel from jacking up the date/time fields.  Can still be imported into excel as a text file - or just change the extension to csv  


+ When attempting to download several years of data there is a high likelihood of receiving an HTTP 500 error - this error comes from the server - there is no fixing it.  The script will throw an error while downloading a single day's data but will recover and continue.  Make a note of which years had issues, change "annis" to reflect those years and rerun script.  Depending on how many years are involved this may take several iterations. 
There may be files written to disk with partial data that represent those years.  Error message looks like this:  *cannot open URL 'http://www.mesonet.org/index.php/dataMdfMts/dataController/getFile/20110526burn/mts/TEXT/': HTTP status was '500 Internal Server Error'Error in file(file, "rt") : cannot open the connection*  The data from 20110526 didn't get retrieved.  Rerunning the script for 2011 is the solution - even then it might not work the first go around.

+ Check timezone to make sure it is right - high temps should occur around 1400 hrs or thereabouts  

***

```{r Libraries, message=FALSE, warning=FALSE, include=FALSE}

source("Setup.R")

library(tictoc)
library(okmesonet)##  Interface for Oklahoma Mesonet http://www.mesonet.org/
                  ##  https://cran.r-project.org/src/contrib/Archive/okmesonet/ - 20250222


# 2019-12-03 09:27:41 ------------------------------mdp
# 2021-01-07 15:22:48 ------------------------------mdp  converted to rmarkdown
# 2025-02-22 20:34:02 ------------------------------mdp

```
  
### List all Oklahoma Mesonet stations and locations.  
####   Only for looking up station id.
  
```{r StationCodes, echo=TRUE, paged.print=TRUE}
okstations
```


#### Display current conditions for all sites.  FYI only - not required
*Arrows to scroll columns are in column heading.*  
```{r echo=TRUE, paged.print=TRUE}
curobs <- okcurobs(localtime = TRUE) 
curobs
```

#### Enter station Identifier - all caps and with the quotes  

```{r}
station_code <- "MADI"
```

***  

###  Download multiple years  
####  Modify and run one of the lines below
If time span involves Dec 31,  the precipitation value for that date will be in Jan 1 of next year - Just get both years - code will adjust for current date.  You may have to delete some extra data on the end.  For current year, code subtracts 2 days from current date and uses that for end date - avoids trying to get data that doesn't exist.  As discussed above this is also where you would change values for years that don't download successfully.  

```{r}
#annis <- c(2011, 2012, 2019, 2020)
annis <- c(2011)  ##  years that don't complete on first go around
#annis <- c(2019:2020)  
#annis <- c(2020:2021)  
```

Theoretically, multiple stations could be run through a loop but wouldn't be likely to finish successfully anyway so I didn't attempt it.  Change stations manually.  

*Variables available and definitions are here:  http://www.mesonet.org/index.php/site/about/mdf_mts_files*  
Temperature, precipitation, and wind values are @ 5 minute intervals.  Other values like soil temps differ in frequency.  *There are additional variables available that are not included below.*

##### Change desired variables below  Limiting number of variables doesn't have much effect on speed.  I think the okkmesonet package still has to download the entire mts file for a particular day and discards other variables.

```{r}
# meso_variables <-  c("RAIN", "TAIR", "RELH", "WSPD", "WVEC",
#                     "WDIR", "SRAD", "WS2M", "TS05", "TS10",
#                     "TB10", "TR05", "WMAX", "PRES", "WDIR")

#meso_variables <-  c("RAIN", "TAIR", "TS05", "TS10")
meso_variables <-  c("TAIR")

```

### This block does the heavy lifting
The output represents the beginning and ending date for each year and the file name that data was written to, along with the time elapsed for processing each year and for all years.  Watch for missing years and rerun for those years.

```{r Multiple Years, echo=TRUE, paged.print=TRUE}
tic()  ##  This takes about 2 min/year with 5 sec wait between - single periods can be run below
for (i in annis) {
  
  b_gin <- ymd_hms(paste0(i, "-01-01 00:00:00"))  ## daily total ppt is stored in 
                                                  ## next day @ 00:00 so you may need
  b_end <- ymd_hms(paste0(i, "-12-31 00:00:00"))  ## one value from next month

  if (format(b_end, "%Y") == year(Sys.Date())) { ##  If year == current year, subtract 2 days 
                                                 ## from current date so we don't try to 
                                                 ## get values that don't exist yet
  b_end <- now() - ddays(2)                      ## Could not do this with if_else - wouldn't 
                                                 ## evaluate conditional
  }                                              ##  
print(b_gin)
tic()

try({##  Try lets script continue after error - you can go back and rerun what timed out
    ##  the first time by changing the values in annis above

    df <- okmts(begintime = b_gin,   ##   Retrieve specific fields
                        endtime         = b_end,
                        station         = station_code, ##  see okstations 
                        missingNA       = TRUE,
                        localtime       = TRUE,
                        variables       = meso_variables)

     write_csv(df, paste0(csv_path, station_code, "_Mesonet_", 
                          year(b_gin), "_", format(now(), "%Y%m%d_%H%M"), ".csv"))


  })
  
  print(b_end)
  print(head(df, 10))
  print(paste0(csv_path, station_code, "_Mesonet_", 
                          year(b_gin), "_", format(now(), "%Y%m%d_%H%M"), ".csv"))
  toc()
  Sys.sleep(5)
}
toc()
```


***

###  Download a single period  
Change begining (b_gin) and ending (b_end) dates for desired period.  Attempting to download periods longer than one year are likely to fail due to http 500 error mentioned above.   

```{r}
b_gin <- ymd_hms("2020-04-29 12:00:00")
b_end <- ymd_hms("2020-05-01 12:00:00")

```


#### Chose station identifier - see table above. Uncomment one of existing or modify for different location.  

```{r}
station_code <- "BURN"  
#station_code <- "ARD2" 

```

#### Edit variables - see url above for documentation  
If replacing missed periods caused by above server error there's no need to run this block unless file has been closed or session restarted. This is the same as code at line 105
```{r}
# meso_variables <-  c("RAIN", "TAIR", "RELH", "WSPD", "WVEC",
#                      "WDIR", "SRAD", "WS2M", "TS05", "TS10", 
#                      "TB10", "TR05", "WMAX", "PRES", "WDIR")

meso_variables <-  c("RAIN", "TAIR") # This can be assigned in code block in previous section as well

```
#### Download data and write file.  Output at bottom is start and end date as well as name and path of generated file.  

```{r Single period, echo=TRUE}
tic()
df <- okmts(begintime = b_gin,    
                   endtime   = b_end,
                   station   = station_code,  ##  Pick station ID
                   missingNA = TRUE,
                   localtime = TRUE,
                   variables = meso_variables)
write_csv(df, paste0(csv_path, station_code, "_Mesonet_", year(b_gin),"_", 
                                                          month(b_gin),"_", 
                                                          format(now(), "%Y%m%d_%H%M"), ".csv"))

toc()
```

```{r eval=FALSE, include=FALSE}
print(paste0("Start date = ",  b_gin))
print(paste0("End date   = ",  b_end))
print(paste0(dat_path, station_code, "_Mesonet_", year(b_gin),"_", 
                                                          month(b_gin),"_", 
                                                          format(now(), "%Y%m%d_%H%M"), ".dat"))


```


***

#### *Mesonet_Processing.R* can be used to compile resulting files into one and do some unit / formula conversion depending on what fields were downloaded  Soil_Temps.Rmd compiles data and creates some graphs of soil temperatures under vegetation and bare ground using data derived from these files.

```{r grateful, echo=FALSE}

library(grateful)

##cites
#  Run this once whenever packages are changed to generate the bibtex file
#  
#cite_packages(cite.tidyverse = TRUE, output = "paragraph", out.dir = ".")

```
