#remotes::install_github("ropensci/piggyback")
library(piggyback)
library(purrr)
library(dplyr)

# add GITHUB_TOKEN, first create one at GitHub with repo permissions
#file.edit("~/.Renviron")
#readRenviron("~/.Renviron")

# dump the data
cordis::cordis_save_parquet(destdir = "~/mycordisexport")

filez <- dir("~/mycordisexport", pattern = ".parquet", full.names = TRUE)

# TODO: fix this, see , do it manually for now...
#piggyback::pb_new_release(repo = "KTH-Library/cordis-data", tag = "v0.1.0")

# upload to github releases
pbu <- function(x)
  pb_upload(file = x, repo = "KTH-Library/cordis-data", dir = "~/mycordisexport")

filez %>% map(pbu)


