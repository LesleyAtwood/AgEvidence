#### SET WORKING DIRECTORY ####
require(funr)
setwd(funr::get_script_path())

#### LOAD LIBRARIES ####
library(tidyverse)
library(readxl)
source('processing-functions.R')

#### READ DATA ####
# Normative effects file
ne <- read_excel("data/normative-effects-Kenya.xlsx")

# Data files
cc <- read_excel("data/ContinuousCover_Kenya.xlsx", sheet = "Results")
nm <- read_excel("data/NutrientMgmt_Kenya.xlsx", sheet = "Results")
till <- read_excel("data/Tillage_Kenya.xlsx", sheet = "Results")

#### MANIPULATE DATA ####
# Create lists for filtering out
filtered_rv_units <- c("^#$", "(arcsine)", "log10")


# Filter data files before data checking
cc <- cc  %>%
  filter(!rv_units %in% filtered_rv_units)

nm <- nm  %>%
  filter(!rv_units %in% filtered_rv_units)

till <- till %>%
  filter(!rv_units %in% filtered_rv_units)


#### NE RENAMING ####
ne <- ne.mods(ne) 
  
#### GL1 RENAMING ####
cc <- cc %>%
  mutate(review="Continuous Cover")

#till <- till %>%
 # mutate(
  #  group_level1 =
   #   ifelse(rv == "soil methane oxidation (CH4-C) in in April" | rv == "soil methane oxidation (CH4-C) in in August" |
    #           rv == "water extractable organic carbon (0-5 cm)" | rv == "water extractable organic carbon (5-20 cm)" |
     #          rv == "active carbon concentration" | rv == "maximum mineralizable soil carbon (Michaelis-Menten equation)" |
      #         rv == "mineralizable soil carbon" | rv == "natural abundance of 13-C in soil (delta 13-C)" | 
       #        rv == "delta 13 C in soil" | rv == "eroded soil organic carbon stock (C3-C) in topsoil",
        #     "Other Soil Properties",
         #    group_level1)
#  )

cc <- cc %>%
  mutate(
  group_level1 =
    ifelse(rv == "water extractable organic carbon (0-5 cm)" | rv == "water extractable organic carbon (5-20 cm)" |
             rv == "active carbon concentration" | rv == "maximum mineralizable soil carbon (Michaelis-Menten equation)" |
           rv == "mineralizable soil carbon" | rv == "natural abudance of 13-C in soil (delta 13-C)" | rv == "delta 13 C in soil",
           "Other Soil Properties",
           group_level1)
)
  

#### GL2 RENAMING ####
cc <- gl2.rename(cc) 
till <- gl2.rename(till)
nm <- gl2.rename(nm)


#### GL3 RENAMING ####
cc <- gl3.rename(cc) 
till <- gl3.rename(till)
nm <- gl3.rename(nm)


#### MARKDOWN FOR MEASURED VARIABLE AND UNITS ####
cc <- mkdown(cc) 
till <- mkdown(till)
nm <- mkdown(nm)


#### GENERATE NEW COLUMNS FOR GL AND NE ####
# Create new columns by calling grouping() function
cc <- cc %>% 
  full_join(ne %>%
              filter(Review =="Continuous Cover")) %>%
  select(-NOTES,-Review) %>%
  mutate(per_change = ifelse(grepl("%", rv_units), 
                             (trt2_value-trt1_value), 
                             (trt2_value-trt1_value)/(trt1_value)*100)) %>%
  mutate(per_change = round(per_change, digits = 2)) %>%
  grouping()

till <- till %>% 
  full_join(ne) %>%
              #filter(Review=="TillageK")) %>%
  select(-Review) %>%
  mutate(per_change = ifelse(grepl("%", rv_units), 
                             (trt2_value-trt1_value), 
                             (trt2_value-trt1_value)/(trt1_value)*100)) %>%
  mutate(per_change = round(per_change, digits = 2)) %>%
  grouping()

nm <- nm %>% 
  full_join(ne %>%
              filter(Review=="Nutrient Management")) %>%
  select(-NOTES,-Review) %>%
  mutate(per_change = ifelse(grepl("%", rv_units), 
                             (trt2_value-trt1_value), 
                             (trt2_value-trt1_value)/(trt1_value)*100)) %>%
  mutate(per_change = round(per_change, digits = 2)) %>%
  grouping()



#### CONVERT RATES OF CHANGE
# Avoid problems where negative rates of change create positive results
cc <- sign.correction(cc)
till <- sign.correction(till)
nm <- sign.correction(nm)


#### REMOVE OBSERVATIONS
# Remove observations from studies that have rates of change between negative and positive
# Calculation % change between negative and positive creates counterintuitive results
RV <- c("rate of soil organic carbon change in corn-corn-soybean rotation",
        "rate of soil organic carbon change in corn-soybean rotation",
        "annual rate of soil organic carbon change across three crop rotations",
        "rate of soil organic carbon change across three crop rotations")

cc <- cc %>% filter(!rv %in% RV)
till <- till %>% filter(!rv %in% RV)
nm <- nm %>% filter(!rv %in% RV)
pm <- pm %>% filter(!rv %in% RV)


#### WRITE FILES
write.csv(cc, paste0("filtered-data/Covercrops_Kenya_",Sys.Date(),".csv"))
write.csv(till, paste0("filtered-data/Tillage_Kenya_",Sys.Date(),".csv"))
write.csv(nm, paste0("filtered-data/NutrientMgmt_Kenya_",Sys.Date(),".csv"))


