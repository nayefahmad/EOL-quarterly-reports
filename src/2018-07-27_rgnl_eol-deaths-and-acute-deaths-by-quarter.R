

#*******************************************************
# IMPORT, CLEAN DEATHS DATA 
#*******************************************************


library("tidyverse")
library("here")
library("tidyr")
library("magrittr")
library("reshape2")


# rm(list = ls())

# todo: ----------------
# > fix x-axis of graphs p1, p2, p5, p6
# > fix order of labels in legend + capitalize "Measure" and "target" 
# > add data sources, key contacts as captions 
# > parametrize start year and quarter ==> will be passed to extract_ts( ) fn 
# > parametrize date of report preparation in caption of graphs 


# 1) read in data and functions: ----------------
source(here("src", 
            "extract_ts_function.R"))
source(here("src", 
            "stl_function.R"))

# deaths data: 
df1.deaths.data <- 
      read_csv(here("results", 
                    "output from src", 
                    "2018-07-27_rgnl_deaths-and-acute-deaths-data-all-communities.csv"))  

# measure targets: 
df2.targets <- 
      read_csv(here("data", 
                    "2018-07-31_rgnl_eol-acute-deaths-percentage-targets.csv"))

df3.los.targets <- 
      read_csv(here("data", 
                    "2018-08-02_rgnl_eol-acute-days-in-last-6-months-targets.csv"))



# 2) Group by CommunityRegion2 and nest: ---------------
df1.deaths.data %<>% 
      set_names(tolower(names(.))) %>% 
      rename(area = communityregion2, 
             quarter = deathfiscalquarter) %>%
      inner_join(df2.targets) %>%  # join on area and quarter to get targets 
      
      # calculate measure: 
      mutate(measure = round(acutedeaths/deaths, 2)) %>% 
      group_by(area) %>% 
      mutate(timeperiod = row_number()) %>% 
      nest()

# each entry of deaths.data$data is a dataframe, which is nested within the 
# deaths.data dataframe 

# examine data: 
df1.deaths.data$data  # all data
df1.deaths.data$data[[5]]  # Vancouver data





# 3) run STL decompositions: --------------
df1.deaths.data %<>% 
      # extract ts objects: 
      mutate(deaths.ts = map2(data,  # arg1
                              "deaths", # arg2
                              extract_ts),           # custom function for extracting deaths data as ts object 
             acutedeaths.ts = map2(data, 
                                   "acutedeaths", 
                                   extract_ts), 
             losdays.ts = map2(data, 
                               "adjlosdays", 
                               extract_ts)) %>%  # custom function for extracting deaths data as ts object 
      
      
      
      # run stl decompositions: 
      mutate(deaths.stl = map(deaths.ts, stl.fn),            # custom function for returning stl components as dataframe  
             acutedeaths.stl = map(acutedeaths.ts, stl.fn), 
             losdays.stl = map(losdays.ts, stl.fn))  # custom function for returning stl components as dataframe 

# result: 
df1.deaths.data$deaths.stl[[5]]
df1.deaths.data$acutedeaths.stl[[5]]
df1.deaths.data$losdays.stl[[5]]



# 4) Identify text for plots: ----------------------
# first identify breaks for x-axis (multiples of 4 until max num quarters): 
x.breaks <- 
      unnest(df1.deaths.data, acutedeaths.stl) %>% 
      select(timeperiod) %>%
      unique() %>%
      mutate(test = timeperiod %% 4) %>% 
      filter(test == 0) %>% 
      select(timeperiod) %>% 
      unname %>%
      unlist

quarter.labels <- unnest(df1.deaths.data, data) %>% select(quarter) %>% as.data.frame()
quarter.labels <- quarter.labels[c(1, x.breaks+1), ]
# slice of last quarter to prevent recycling: 
quarter.labels <- quarter.labels[1:length(quarter.labels) - 1]



# next find min and max quarter for subtitle: 
df3.quarters <- 
      unnest(df1.deaths.data, data) %>% select(quarter) %>% unique()

min.quarter <-  df3.quarters %>% filter(row_number() == 1) %>% as.character()
max.quarter <-  df3.quarters %>% filter(row_number() == nrow(df3.quarters)) %>% as.character()





