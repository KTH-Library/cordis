cachedir <- function() {
  mydir <- rappdirs::user_cache_dir("cordis")
  if (!dir.exists(mydir)) dir.create(mydir, recursive = TRUE)
  mydir
}

dbfile <- function() {
  myfile <- file.path(cachedir(), "cordisdb")
  if (!file.exists(myfile))
    stop("No file at ", myfile, ", please download data")
  myfile
}

get_sql <- function(con, sql)
  con %>% DBI::dbGetQuery(sql)

exec_sql <- function(con, sql)
  !is.na(con %>% DBI::dbExecute(sql))

cordis_meta <- function() {

  con <- cordis_con()
  on.exit(cordis_disconnect(con))
  tbls <- DBI::dbListTables(con)

  counts <-
    sprintf('select count(*) as n from \"%s\";', tbls) %>%
    purrr::map_df(function(x) get_sql(con, x))

  n <-
    dplyr::tibble(table = tbls, n_row = counts$n)

  schema <-
    sprintf("PRAGMA table_info('%s');", tbls) %>%
    purrr::map(function(x) get_sql(con, x)) %>%
    stats::setNames(nm = tbls) %>%
    purrr::map_dfr(.f = dplyr::bind_rows, .id = "tablename") %>%
    dplyr::as_tibble()

  list(tables = n, schema = schema)

}

#' @title Connection to CORDIS database
#' @description This function returns a connection to the CORDIS database
#' @return a database connection
#' @details the database location is at the cachedir/cordisdb
#' @examples
#' \dontrun{
#' library(dplyr)
#' con <- cordis_con()
#' con %>% tbl("projectPublications")
#' }
#' @export
#' @import duckdb
cordis_con <- function() {
  dbfile <- normalizePath(file.path(cachedir(), "cordisdb"), NA) |> suppressWarnings()
  #message("Connecting to ", dbfile)
  dbConnect(duckdb(dbdir = dbfile))
}

#' @title CORDIS tables
#' @description Enumeration of tables present in CORDIS database
#' @return a dataframe with table names and row counts
#' @examples
#' \dontrun{
#' cordis_tables()
#' }
#' @export
cordis_tables <- function() {
  cs <- cordis_meta()
  cs$tables
}

#' @title CORDIS schema
#' @description Description of all tables, their fields and data types
#' @return a dataframe with database schema metadata
#' @examples
#' \dontrun{
#' cordis_schema()
#' }
#' @export
cordis_schema <- function() {
  cs <- cordis_meta()
  cs$schema
}

#' @title Close and shutdown CORDIS database connection
#' @description This function closes a connection to the CORDIS database
#' @param con database connection to duckdb database
#' @return invisible TRUE on success
#' @details also takes care of shutting down the connection
#' @examples
#' \dontrun{
#' con <- cordis_con()
#' cordis_disconnect(con)
#' }
#' @export
#' @importFrom duckdb dbDisconnect
cordis_disconnect <- function(con) {
  duckdb::dbDisconnect(con, shutdown = TRUE)
}

#' @title Export CORDIS database
#' @description Export in parquet format to a destination directory
#' @param destdir the directory where the parquet files should be written
#' @param overwrite boolean to indicate overwriting existing dir, default FALSE
#' @return invisible TRUE on success
#' @details also takes care of shutting down the connection
#' @examples
#' \dontrun{
#' cordis_export("~/mycordisexport")
#' }
#' @export
cordis_export <- function(destdir, overwrite = FALSE) {

  if (dir.exists(destdir) && overwrite != TRUE)
    stop("The destination ", destdir, " already exists; pls use overwrite = TRUE")

  outdir <- path.expand(destdir)
  con <- cordis_con()
  on.exit(cordis_disconnect(con))

  invisible(exec_sql(con, sprintf("export database '%s' (format parquet);", outdir)))
}

#' @title Import CORDIS database
#' @description Imports the CORDIS database extract from parquet files, needs
#' to run at least once after package installation
#' @param repo_slug the repo slug for the GitHub repo with a release containing
#' an export made using this package, Default: 'kth-library/cordis-data'
#' @param refresh logical indicating whether to reimport overwriting existing data, Default: FALSE
#' @param verbose logical whether to display messages, Default: TRUE
#' @param version release version for data to use
#' @return invisible TRUE on success
#' @examples
#' \dontrun{
#' if(interactive()){
#'  cordis_import()
#'  }
#' }
#' @export
#' @importFrom piggyback pb_download pb_download_url
#' @importFrom purrr map
#' @importFrom DBI dbExecute
cordis_import <- function(repo_slug = "kth-library/cordis-data",
                          refresh = FALSE, verbose = TRUE, version = "v0.2.1") {

  dldir <- normalizePath(file.path(cachedir(), "temp"))

  if (dir.exists(dldir) && !refresh) {
    message("Directory ", dldir, " already exits, for fresh data download, retry with refresh=TRUE")
  }

  if (refresh) unlink(dldir, recursive = TRUE)
  if (!dir.exists(dldir)) dir.create(dldir, recursive = TRUE)

  repo <- repo_slug

  if (refresh) {
    piggyback::pb_download(show_progress = TRUE, file = NULL,
      repo = repo, dest = dldir, tag = version)
    # urlz <- piggyback::pb_download_url(repo = repo, tag = version)
  }

  message("Parquet files are in ", dldir, ", populating database ...")

  sql <- sprintf(
    "CREATE TABLE IF NOT EXISTS %s AS SELECT * FROM parquet_scan('%s');",
    gsub("(.*?)\\.parquet$", "\\1", dir(dldir)),
    dir(dldir, full.names = TRUE)
  )

  con <- cordis_con()
  on.exit(cordis_disconnect(con))
  res <- sql %>% purrr::map(function(x) DBI::dbExecute(con, x))

  if (verbose)
    message("Imported ", length(res), " parquet files into duckdb")

  return(invisible(length(res) > 0))
}

cordis_dropdb <- function(confirm = FALSE) {
  stopifnot(confirm)
  unlink(dbfile())
}
