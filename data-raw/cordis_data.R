library(dplyr)
library(purrr)
library(duckdb)

files <- readr::read_lines("cordisref-countries.csv
cordisref-FP6programmes.csv
cordisref-FP7programmes.csv
cordisref-fp7subprogrammes.txt
cordisref-projectFundingSchemeCategory.csv
cordisref-h2020programmes.csv
cordisref-h2020topics.csv
cordisref-organizationActivityType.csv
cordisref-sicCode.csv
")


urls <- sprintf("http://cordis.europa.eu/data/reference/%s", files)

name_tbl <- function(x) gsub("cordisref-(.*?)\\..*$", "\\1", x)
tbls <- name_tbl(files)
cachedir <- rappdirs::user_cache_dir("cordis")
dl <- function(url, destfile) curl::curl_download(url, destfile, quiet = FALSE)

# download these datasets
tibble(tbls, url = urls) %>%
  mutate(destfile = file.path(cachedir, paste0(tbls, ".csv"))) %>%
  select(url, destfile) %>%
  purrr::pmap_chr(dl)


# parse datatypes etc for tables
cordis <-
  file.path(cachedir, paste0(tbls, ".csv")) %>%
  purrr::map(function(x) readr::read_csv2(x, guess_max = 5e4))

cordis <- setNames(cordis, name_tbl(tbls))

# depth determined by ....
# fp7subs %>% summarise(across(.fns = function(x) sum(is.na(x))))
fp7subs <-
  file.path(cachedir, paste0("fp7subprogrammes", ".csv")) %>%
  readr::read_csv2(col_names = sprintf("col%d", 1:10), guess_max = 5e5, )

cordis$fp7subprogrammes <- fp7subs

# write tables to duckdb
dbpath <- file.path(cachedir, "cordisdb")
con <- duckdb::dbConnect(duckdb::duckdb(dbpath))
purrr::map2(names(cordis), cordis, function(x, y) duckdb::dbWriteTable(con, x, y))
duckdb::dbDisconnect(con)

