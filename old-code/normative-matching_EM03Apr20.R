#### LOAD LIBRARIES ####
library(tidyverse)
library(readxl)


path <- "~/Parent-Directory/"
setwd(path)

#### FUNCTIONS ####
# Function to change the GL2 changes in the raw data
gl2.rename <- function(data) {
  data %>%
    mutate(group_level2 =
             ifelse(group_level1=="Other Soil Properties" & 
                      (group_level3=="Aggregate size"|group_level3=="Aggregate stability"|
                         group_level3=="Air-filled pore space"|group_level3=="Air-filled pores"|
                         group_level3=="Total pore space"|group_level3=="Water-filled pore space"), 
                    "Soil Structure",
                    group_level2)
    ) %>%
    mutate(group_level2 = 
             ifelse(group_level1=="Other Soil Properties" & 
                      group_level3=="Decomposition rate of surface residue",
                    "Biotic Factors",
                    group_level2)) %>%
    mutate(group_level2 = 
             ifelse(group_level1=="Other Soil Properties" & group_level3=="Soil organic matter content",
                    "Chemical Properties",
                    group_level2))
}
# Function to generate two separate columns
# based on GLs and NEs
grouping <- function(data) {
  data %>%
    mutate(grouping=
             ifelse(is.na(group_level1_alt), 
                    paste(group_level1,"|",group_level2,"|",group_level3),
                    paste(group_level1,"|",group_level2,"|",group_level3,";",
                          group_level1_alt,"|",group_level2_alt,"|",group_level3)
             ),
           normative_effect=
             ifelse(is.na(group_level1_alt),
                    paste(norm_interp2,"|",norm_interp3),
                    paste(norm_interp2,"|",norm_interp3,";",
                          norm_interp2_alt,"|",norm_interp3_alt)
             )
    )
}


#### READ DATA ####
# Normative effects files
ne <- read_excel("data/Normative_effects_groups.xlsx")
ne_mod <- read_excel("data/Normative_effects_groups_modified.xlsx")
ne_mod_2 <- read_excel("data/Normative_effects_groups_modified_2.xlsx")
ne_mod_3 <- read_excel("data/10Mar20_Normative_effects_groups_modified_2.xlsx")

# Data files
cc <- read_excel("data/Covercrops_AgEvidence.xlsx", sheet = "Results")
nm <- read_excel("data/NutrientMgmt_AgEvidence.xlsx", sheet = "Results")
pm <- read_excel("data/PestMgmt_AgEvidence.xlsx", sheet = "Results")
till <- read_excel("data/Tillage_AgEvidence.xlsx", sheet = "Results")

# Create lists for filtering out
filtered_rv_units <- c("^#$", "(arcsine)", "log10")
filtered_finelevel_group <- c("knife_knife",
                              "unfertilized_plant",
                              "unfertilized_split",
                              "variable_variable",
                              "band_injection",
                              "injection_injection",
                              "placement_pointinjection_knifeinjection",
                              "surfaceband_belowsurface",
                              "split_preplantV6_plant_V6")

# Filter data files before data checking

cc <- cc  %>%
  filter(!rv_units %in% filtered_rv_units)

nm <- nm  %>%
  filter(!rv_units %in% filtered_rv_units) %>%
  filter(!finelevel_group %in% filtered_finelevel_group)

till <- till %>%
  filter(!rv_units %in% filtered_rv_units)

pm <- pm %>%
  filter(!rv_units %in% filtered_rv_units)

# #### DATA CHECKING ####
# # Check which grouping vars differ among files
# setdiff(ne_mod_2 %>% select(group_level2) %>% unique() %>% arrange(group_level2),
#         ne_mod %>% select(group_level2) %>% unique() %>% arrange(group_level2)  
# )
# 
# setdiff(ne_mod_2 %>% select(group_level3) %>% unique() %>% arrange(group_level3),
#         ne_mod %>% select(group_level3) %>% unique() %>% arrange(group_level3)  
# )
rm(ne); rm(ne_mod); rm(ne_mod_2)

#### GL2 RENAMING ####
cc <- gl2.rename(cc) 
till <- gl2.rename(till)
nm <- gl2.rename(nm)
pm <- gl2.rename(pm)

#### GENERATE NEW COLUMNS FOR GL AND NE ####
# Combine the two spellings of the cover crop review categories
ne_mod_3 <- ne_mod_3 %>%
  mutate(Review=
           ifelse(Review=="Cover Crops",
                  "Cover crop",
                  Review))

# Create new columns by calling grouping() function
cc <- cc %>% 
  full_join(ne_mod_3 %>%
              filter(Review =="Cover crop")) %>%
  select(-NOTES,-Review) %>%
  mutate(per_change = ifelse(grepl("%", rv_units), 
                             (trt2_value-trt1_value), 
                             (trt2_value-trt1_value)/(trt1_value)*100)) %>%
  mutate(per_change = round(per_change, digits = 2)) %>%
  grouping()

till <- till %>% 
  full_join(ne_mod_3 %>%
              filter(Review=="Tillage")) %>%
  select(-NOTES,-Review) %>%
  mutate(per_change = ifelse(grepl("%", rv_units), 
                             (trt2_value-trt1_value), 
                             (trt2_value-trt1_value)/(trt1_value)*100)) %>%
  mutate(per_change = round(per_change, digits = 2)) %>%
  grouping()

nm <- nm %>% 
  full_join(ne_mod_3 %>%
              filter(Review=="Nutrient Management")) %>%
  select(-NOTES,-Review) %>%
  mutate(per_change = ifelse(grepl("%", rv_units), 
                             (trt2_value-trt1_value), 
                             (trt2_value-trt1_value)/(trt1_value)*100)) %>%
  mutate(per_change = round(per_change, digits = 2)) %>%
  grouping()

pm <- pm %>% 
  full_join(ne_mod_3 %>%
              filter(Review=="Early Season Pest Management")) %>%
  select(-NOTES,-Review) %>%
  mutate(per_change = ifelse(grepl("%", rv_units), 
                             (trt2_value-trt1_value), 
                             (trt2_value-trt1_value)/(trt1_value)*100)) %>%
  mutate(per_change = round(per_change, digits = 2)) %>%
  grouping()

write.csv(cc, paste0("filtered-data/Covercrops_AgEvidence_EMscript_",Sys.Date(),".csv"))
write.csv(till, paste0("filtered-data/Tillage_AgEvidence_EMscript_",Sys.Date(),".csv"))
write.csv(nm, paste0("filtered-data/NutrientMgmt_AgEvidence_EMscript_",Sys.Date(),".csv"))
write.csv(pm, paste0("filtered-data/PestMgmt_AgEvidence_EMscript_",Sys.Date(),".csv"))

rm(list=ls())
