library(readr)
library(readxl)

# H2020 projects
# https://data.europa.eu/euodp/en/data/dataset/cordisH2020projects


tbls <- readr::read_lines(
  "organizations
projectDeliverables
projectPublications
projects
reports
")

url <-
  "https://cordis.europa.eu/data/cordis-h2020%s.csv" %>%
  sprintf(tblname)

dl <- function(url, destfile) {
  curl::curl_download(url, destfile, quiet = FALSE)
}

filez <-
  tibble(tbls, url) %>%
  mutate(destfile = file.path(tempdir(), paste0(tbls, ".csv"))) %>%
  select(url, destfile) %>%
  purrr::pmap_chr(dl)

cachedir <- rappdirs::user_cache_dir("cordis")

if (!dir.exists(cachedir)) dir.create(cachedir, recursive = TRUE)

destz <- file.path(cachedir, purrr::map_chr(filez, basename))

file.copy(from = filez, to = destz, overwrite = TRUE)

destz

readr::read_delim(destz[1], delim = ";")

ft <- tempfile(fileext = "xlsx")

"https://cordis.europa.eu/data/cordis-h2020-erc-pi.xlsx" %>%
  download.file(destfile = ft)

pis <- readxl::read_excel(ft)
readr::write_delim(pis, file.path(cachedir, "pi.csv"), delim = ";")

ft2 <- tempfile(fileext = "csv.zip")

"http://digital-agenda-data.eu/download/digital-agenda-scoreboard-key-indicators.csv.zip" %>%
  download.file(ft2)

scoreboard <- readr::read_csv(
  unz(ft2, filename = unzip(ft2, list = TRUE)$Name
  ),
  col_types = "ccccccccc"
)

readr::write_delim(scoreboard,  file.path(cachedir, "scoreboard.csv"), delim = ";")

library(purrr)
library(dplyr)

read_h2020 <- function(url) {
  res <- readr::read_csv2(url, progress = TRUE, guess_max = 100000)
  if (nrow(problems(res)) > 0) message("Reading ", url, " gave ", problems(res))
  return(res)
}

filez <- dir(cachedir, full.names = TRUE, pattern = "*.csv")
h2020 <- filez %>% map(read_h2020)

# write tables to duckdb
name_filez <- function(x) gsub(".*?/(.*?)\\.csv$", "\\1", x)
dbpath <- normalizePath(file.path(cachedir, "cordisdb"))
unlink(dbpath)
con <- duckdb::dbConnect(duckdb::duckdb(dbpath))
purrr::map2(name_filez(filez), h2020, function(x, y) duckdb::dbWriteTable(con, x, y))
duckdb::dbDisconnect(con, shutdown = TRUE)

con <- duckdb::dbConnect(duckdb::duckdb(dbpath))

