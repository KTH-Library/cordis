library(dplyr)
library(purrr)
library(duckdb)
library(httr)
library(tidyr)
library(dplyr)
library(tibble)
library(readr)
library(readxl)

cachedir <- rappdirs::user_cache_dir("cordis")

dl <- function(url, destfile, ...)
  curl::curl_download(url, destfile, quiet = FALSE)

# -------------
# cordisref-data

# retrieve dl data from RSS for cordis ref-data
# NB: these files have been removed from cordisref
# organizationActivityType
# sicCode

rss_ref <-
  "https://data.europa.eu/api/hub/search/en/feeds/datasets/cordisref-data.rss" |>
  GET() |> content(as = "text", encoding = "UTF-8") |>
  strsplit(split = "\n") |> unlist() |> enframe(name = NULL, value = "rss") |>
  filter(grepl("csv|txt|xls", rss)) |>
  mutate(url = gsub(x = rss, ".*?(http.*?)\".*", "\\1")) |>
  mutate(filename = gsub(x = rss, ".*?(cordisref-.*?\\..{3})[\"]*.*$", "\\1", perl = TRUE)) |>
  mutate(is_xls = grepl("xls|xlsx", filename)) |>
  mutate(is_csv = grepl("csv", filename)) |>
  mutate(is_zip = grepl("zip", filename)) |>
  mutate(is_txt = grepl("txt", filename)) |>
  mutate(tbl = gsub(x = filename, "\\..{3}|-csv|-xlsx|cordisref-", "")) |>
  select(tbl, starts_with("is"), filename, url) |>
  mutate(destfile = file.path(cachedir, filename)) |>
  arrange(desc(tbl))

# rss_ref$tbl |> unique() |> paste(collapse = "\n") |> cat()

# download xlsx files (NB: xls is misleading)
files_xl <-
  rss_ref |> filter(is_xls, tbl == "h2020topicKeywords") |>
  pmap(dl) |> unlist() |>
  read_xlsx()

# download txt files
files_txt <-
  rss_ref |> filter(grepl("txt", destfile)) |>
  pmap(function(destfile, ...) read_lines(destfile)) |> unlist() |>
  strsplit(split = ";") |> enframe(name = "id", value = "cat") |>
  unnest_wider(cat, names_sep = "_")

# download CSV files
rss_ref |> filter(is_csv) |> pmap_chr(dl)

# NB: all zip files here contain only one CSV, no need to unpack these individually
# files_csvz <- rss_ref |> filter(is_zip, is_csv) |> pmap(lsz)

# read CSV files
files_csv <-
  rss_ref |> filter(is_csv) |>
  pmap(function(destfile, ...) readr::read_csv2(destfile, guess_max = 5e4, show_col_types = F))


# collect all data (CSV, excel, txt)
tbls_csv <-
  rss_ref |> filter(is_csv) |>
  mutate(tbl = paste0("ref_", tbl)) |>
  pull("tbl") |> tolower()

data_ref <- setNames(files_csv, tbls_csv)
data_ref$ref_h2020topicKeywords <- files_xl
data_ref$ref_fp7subprogrammes <- files_txt

#--------
#
# CORDIS - EU research projects under HORIZON EUROPE (2021-2027)

# https://data.europa.eu/data/datasets/cordis-eu-research-projects-under-horizon-europe-2021-2027?locale=en

# Some data is available, but not:
#   - HORIZON project IPRs (Intellectual Property Rights) - NOT YET AVAILABLE
#   - HORIZON project deliverables (meta-data and links to deliverables)
#   - HORIZON project publications (meta-data and links to publications) - NOT YET AVAILABLE
#   - HORIZON report summaries (periodic or final publishable summaries) - NOT YET AVAILABLE
#   - Principal Investigators in Horizon Europe ERC projects - NOT YET AVAILABLE

# get paths to available datasets for Horizon Europe (he)
rss_he <-
  paste0(
    "https://data.europa.eu/api/hub/search/en/feeds/datasets/",
    "cordis-eu-research-projects-under-horizon-europe-2021-2027.rss"
  ) |> readLines() |>
  grep(pattern = "csv\\.zip", value = TRUE) |>
  stringr::str_match(pattern = "https://.*csv\\.zip") |>
  as.character() |>
  enframe(name = NULL, value = "url") |>
  mutate(filename = gsub(x = url, ".*?(cordis-HORIZON.*?\\..{3}).*$", "\\1")) |>
  mutate(tbl = gsub(x = filename, "\\..{3}|-csv|cordis-HORIZON", "")) |>
  mutate(tbl = paste0("he_", tbl)) |>
  select(tbl, filename, url) |>
  mutate(destfile = file.path(cachedir, filename))

# download these datasets locally and read the data
rss_he |> pmap_chr(dl)

read_zip <- function(destfile, target, ...) {
  f <- unz(destfile, target)
  readr::read_delim(file = f, delim = ";", show_col_types = FALSE, guess_max = 2e4)
}

# list all csv files inside zip-file
lsz <- function(destfile, ...)
  zip::zip_list(destfile) |> getElement("filename")

csv_he <-
  rss_he |>
  pmap(lsz) |>
  setNames(nm = rss_he$destfile) |>
  stack() |> as_tibble() |>
  rename(target = "values", destfile = "ind") |>
  left_join(rss_he, by = "destfile") |>
  mutate(tbl_z = paste0("he_", gsub("csv/|\\.csv", "", target)))

data_he <-
  csv_he |> pmap(read_zip) |>
  setNames(nm = csv_he$tbl_z)

#------------
# H2020 projects
# https://data.europa.eu/euodp/en/data/dataset/cordisH2020projects
#
rss_h2020 <-
  "https://data.europa.eu/api/hub/search/en/feeds/datasets/cordish2020projects.rss" |>
  GET() |> content(as = "text", encoding = "UTF-8") |>
  strsplit(split = "\n") |> unlist() |> enframe(name = NULL, value = "rss") |>
  filter(grepl("csv|txt", rss)) |>
  mutate(url = gsub(x = rss, ".*?(http.*?)\".*", "\\1")) |>
  mutate(filename = gsub(x = url, ".*?([^/]*?\\..{3})$", "\\1", perl = TRUE)) |>
  mutate(is_zip = grepl("\\.zip", filename)) |>
  mutate(is_csv = grepl("\\.csv", filename)) |>
  # mutate(filename = gsub(x = rss, ".*?(cordis-h2020.*?\\..{3}).*$", "\\1")) |>
  # mutate(filename = gsub(x = filename, ".*?data/(.*?\\..{3}).*$", "\\1")) |>
  mutate(tbl = paste0("h2020_", gsub(x = filename, "\\..{3}|-csv|cordis-|_*h2020", ""))) |>
  select(tbl, starts_with("is"), filename, url) |>
  mutate(destfile = file.path(cachedir, filename))

# download these datasets locally and read the data
rss_h2020 |> pmap_chr(dl)

csvz_h2020 <-
  rss_h2020 |>
  filter(is_zip) |>
  pmap(lsz) |>
  setNames(nm = grep("\\.zip$", rss_h2020$destfile, value = TRUE)) |>
  stack() |> as_tibble() |>
  rename(target = "values", destfile = "ind") |>
  left_join(rss_h2020 |> filter(grepl("\\.zip$", destfile)), by = "destfile") |>
  mutate(tbl_z = paste0("h2020_", gsub("csv/|\\.csv", "", target)))

z_h2020 <-
  csvz_h2020 |> pmap(read_zip) |>
  setNames(nm = csvz_h2020$tbl_z)

#z_h2020 |> map(readr::problems)

iprs <-
  rss_h2020 |> filter(!is_zip) |>
  pmap(function(destfile, ...) read_csv(destfile, show_col_types = F)) |>
  setNames(nm = rss_h2020 |> filter(!is_zip) |> getElement("tbl"))


# download some "extra" H2020 files

"https://cordis.europa.eu/data/cordis-h2020-erc-pi.xlsx" |>
  download.file(destfile = file.path(cachedir, "pi.xlsx"))

pis <- file.path(cachedir, "pi.xlsx") |> readxl::read_excel()

fp_scoreboard <- file.path(cachedir, "scoreboard.csv.zip")

"http://digital-agenda-data.eu/download/digital-agenda-scoreboard-key-indicators.csv.zip" |>
  download.file(fp_scoreboard)

scoreboard <-
  readr::read_csv(fp_scoreboard, col_types = "ccccccccc") |> as_tibble()

data_h2020 <- c(z_h2020, iprs, list(h2020_pi = pis), list(h2020_scoreboard = scoreboard))

#names(data_h2020)



# -------------
# CORDIS FP 7 projects data
#
rss_fp7 <-
  "https://data.europa.eu/api/hub/search/en/feeds/datasets/cordisfp7projects.rss" |>
  GET() |> content(as = "text", encoding = "UTF-8") |>
  strsplit(split = "\n") |> unlist() |> enframe(name = NULL, value = "rss") |>
  filter(grepl("csv|txt", rss)) |>
  mutate(url = gsub(x = rss, ".*?(http.*?)\".*", "\\1")) |>
  mutate(filename = gsub(x = url, ".*?([^/]*?\\..{3})$", "\\1", perl = TRUE)) |>
  mutate(is_zip = grepl("zip", filename)) |>
  mutate(is_csv = grepl("csv", filename)) |>
  mutate(tbl = paste0("fp7_", tolower(gsub(x = filename, "\\..{3}|-csv|cordis-|FP7PC_|_fp7|fp7", "")))) |>
  select(tbl, is_zip, is_csv, filename, url) |>
  mutate(destfile = file.path(cachedir, filename)) |>
  arrange(desc(tbl))

# download the FP7 files
rss_fp7 |> pmap_chr(dl)

# unpack the zip files first
csvz_fp7 <-
  rss_fp7 |> filter(is_zip) |> pmap(lsz) |>
  setNames(nm = grep("\\.zip$", rss_fp7$destfile, value = TRUE)) |>
  stack() |> as_tibble() |>
  rename(target = "values", destfile = "ind") |>
  left_join(rss_fp7 |> filter(grepl("\\.zip$", destfile)), by = "destfile") |>
  mutate(tbl_z = paste0("fp7_", gsub("csv/|\\.csv", "", target)))  |>
  select(tbl_z, everything())

z_fp7 <-
  csvz_fp7 |> pmap(read_zip) |>
  setNames(nm = csvz_fp7$tbl_z)

#z_fp7 |> map(readr::problems)
#
# z_fp7$fp7_organization
# # A tibble: 2 × 5
#     row   col expected actual  file
#   <int> <int> <chr>    <chr>   <chr>
# 1 13598    18 a double xxxxxxx ""
# 2 13598    21 a number xxxxx   ""

csv_fp7 <-
  rss_fp7 |>
  filter(!is_zip) |>
  mutate(sep = ifelse(tbl == "fp7_projectirps", ",", ";")) |>
  pmap(function(destfile, sep, ...) readr::read_delim(destfile, delim = sep, guess_max = 5e4, show_col_types = F)) |>
  setNames(nm = rss_fp7 |> filter(!is_zip) |> getElement("tbl"))

# data_fp7 |> map(readr::problems)

data_fp7 <- c(csv_fp7, z_fp7)




#------------
# Write to database
#

# combine previous batches of data
d <- c(data_ref, data_he, data_h2020, data_fp7)

# reencode all strings for "invalid bytecode sequences"
res <-
  d |>
  map(function(x) x |> mutate(across(
    where(is.character),
    function(x) stringi::stri_encode(x, to = "UTF-8")
    ))
  )

# write tables to duckdb

write_duckdb <- function(data) {

  dbpath <- normalizePath(file.path(cachedir, "cordisdb"))

  if (!dir.exists(basename(dbpath)))
    dir.create(basename(dbpath), recursive = TRUE)

  if (file.exists(dbpath))
    unlink(dbpath, recursive = TRUE)

  con <- dbConnect(duckdb(dbdir = dbpath))
  on.exit(dbDisconnect(con, shutdown = TRUE))

  res <- map2(names(data), data, function(x, y) dbWriteTable(con, x, y))
  return(invisible(res))
}

res |> write_duckdb()

dump_parquet <- function(dir = "temp") {

  dbpath <- normalizePath(file.path(cachedir, "cordisdb"))
  con <- dbConnect(duckdb(dbdir = dbpath))
  on.exit(dbDisconnect(con, shutdown = TRUE))

  if (!dir.exists(file.path(cachedir, dir)))
    dir.create(file.path(cachedir, dir), recursive = TRUE)

  tbls <- con |> dbListTables()

  sql <- sprintf("copy %s to '%s.parquet';", tbls, file.path(cachedir, dir, tbls))

  message("Starting export of parquet files to ", file.path(cachedir, dir))
  parquets <- sql |> map(function(x) con |> dbExecute(x)) |> setNames(nm = tbls)
  message("Done.")

  parquets |>
    enframe(name = "table", value = "rows") |>
    unnest(rows) |>
    arrange(desc(rows)) |>
    print(n = 50)
}

# dump all the data into .parquet files
dump_parquet()


#--------
#
# Upload data to cordis-data repo using "piggyback"

#remotes::install_github("ropensci/piggyback")
library(piggyback)

# add GITHUB_TOKEN, first create one at GitHub with repo permissions
#file.edit("~/.Renviron")
#readRenviron("~/.Renviron")

dumpdir <- file.path(cachedir, "temp")
uploadz <- dir(dumpdir, pattern = ".parquet")

# list released datasets
"KTH-Library/cordis-data" |> pb_releases()

# NB: ONLY IF NEEDED, create new tag for new data
"KTH-Library/cordis-data" |> pb_new_release(tag = "v0.2.0")

# TODO: fix this, see , do it manually for now...
#piggyback::pb_new_release(repo = "KTH-Library/cordis-data", tag = "v0.1.1")



# upload to github releases
pbu <- function(x)
  pb_upload(file = x, tag = "v0.2.0", repo = "KTH-Library/cordis-data", dir = dumpdir)

uploadz %>% map(pbu)

pb_list(repo = "KTH-Library/cordis-data", tag = "v0.2.0")
