
<!-- README.md is generated from README.Rmd. Please edit that file -->

# cordis

<!-- badges: start -->

[![R-CMD-check](https://github.com/KTH-Library/cordis/workflows/R-CMD-check/badge.svg)](https://github.com/KTH-Library/cordis/actions)
<!-- badges: end -->

The goal of `cordis` is to simplify data access to data from
[CORDIS](https://cordis.europa.eu/), which is an acronym for the
Community Research and Development Information Service. It is the
European Commission’s primary source of results from the projects funded
by the EU’s framework programmes for research and innovation. This
includes programmes from FP1 to Horizon 2020.

## Data preparation

CORDIS makes data about European research projects available at various
locations, such as
<https://data.europa.eu/euodp/en/data/dataset/cordisH2020projects>. The
download speed is rate limited when working directly against these
files, and file formats and compression are different. With some data
preparation, these datasets can be loaded into a database, providing
simplified and faster local access to the data.

In [`data-raw`](data-raw) there are data preparation scripts which
download data from these locations into a local cache directory
(`~/.cache/cordis`). A [duckdb](https://duckdb.org) database is built
from these files and uploaded using
[piggyback](https://github.com/ropensci/piggyback) to a GitHub repo at
<https://github.com/KTH-Library/cordis-data> as a versioned GitHub
Release.

There is also a function for exporting the entire database in Parquet
format, which allows moving the data for example to a
[Minio](https://min.io/) server, where it can be accessed by other data
integration tools like Apache Spark. Only package developers need to use
these functions when preparing and updating the data.

## Usage

The data in the “github releases” location mentioned above can be
installed locally by regular package users by running
“cordis\_import()”, a function for importing the data from the data
repository. This needs to be done once. The download and upload rate is
good.

Users can then make a connection to the database locally. This allows
arbitrary in-process data processing with tidyverse tools such as dplyr.

Convenience functions allows for inspecting the database schema /
finding table and field names.

## Installation

You can install the released version of `cordis` from
[GitHub](https://github.com/KTH-Library/cordis) with:

``` r
devtools::install_github("KTH-Library/cordis")
# run once to install local data
cordis_import()
```

## Example

This is a basic example which shows you how to work with the data:

``` r
library(cordis)
suppressPackageStartupMessages(library(dplyr))
library(knitr)

# tables in the database
cordis_tables() %>%
  arrange(desc(n_row))
#> # A tibble: 16 x 2
#>    table                          n_row
#>    <chr>                          <dbl>
#>  1 scoreboard                   1048576
#>  2 projectpublications           161524
#>  3 organizations                 150287
#>  4 projectdeliverables            84323
#>  5 projects                       32161
#>  6 reports                        19295
#>  7 pi                              7525
#>  8 fp7programmes                   6233
#>  9 fp7subprogrammes                6096
#> 10 h2020topics                     3878
#> 11 fp6programmes                   2027
#> 12 countries                       1503
#> 13 h2020programmes                  909
#> 14 siccode                          426
#> 15 projectfundingschemecategory     187
#> 16 organizationactivitytype           5

# database schema
cordis_schema() %>%
  head(20)
#> # A tibble: 20 x 7
#>    tablename          cid name       type    notnull dflt_value pk   
#>    <chr>            <int> <chr>      <chr>   <lgl>   <chr>      <lgl>
#>  1 countries            0 euCode     VARCHAR FALSE   <NA>       FALSE
#>  2 countries            1 isoCode    VARCHAR FALSE   <NA>       FALSE
#>  3 countries            2 name       VARCHAR FALSE   <NA>       FALSE
#>  4 countries            3 language   VARCHAR FALSE   <NA>       FALSE
#>  5 fp6programmes        0 rcn        DOUBLE  FALSE   <NA>       FALSE
#>  6 fp6programmes        1 code       VARCHAR FALSE   <NA>       FALSE
#>  7 fp6programmes        2 title      VARCHAR FALSE   <NA>       FALSE
#>  8 fp6programmes        3 shortTitle VARCHAR FALSE   <NA>       FALSE
#>  9 fp6programmes        4 language   VARCHAR FALSE   <NA>       FALSE
#> 10 fp7programmes        0 RCN        DOUBLE  FALSE   <NA>       FALSE
#> 11 fp7programmes        1 Code       VARCHAR FALSE   <NA>       FALSE
#> 12 fp7programmes        2 Title      VARCHAR FALSE   <NA>       FALSE
#> 13 fp7programmes        3 ShortTitle VARCHAR FALSE   <NA>       FALSE
#> 14 fp7programmes        4 Language   VARCHAR FALSE   <NA>       FALSE
#> 15 fp7subprogrammes     0 col1       VARCHAR FALSE   <NA>       FALSE
#> 16 fp7subprogrammes     1 col2       VARCHAR FALSE   <NA>       FALSE
#> 17 fp7subprogrammes     2 col3       VARCHAR FALSE   <NA>       FALSE
#> 18 fp7subprogrammes     3 col4       VARCHAR FALSE   <NA>       FALSE
#> 19 fp7subprogrammes     4 col5       VARCHAR FALSE   <NA>       FALSE
#> 20 fp7subprogrammes     5 col6       VARCHAR FALSE   <NA>       FALSE

# get a connection
con <- cordis_con()
# remember to disconnect when done:
# cordis_disconnect(con)

# display first five rows with PI data
con %>% tbl("pi") %>% 
  head(5) %>% 
  knitr::kable()
```

| projectId | projectAcronym      | fundingScheme | title | firstName | lastName        | organisationId |
| --------: | :------------------ | :------------ | :---- | :-------- | :-------------- | -------------: |
|    633152 | GEOFLUIDS           | ERC-STG       | DR    | Alberto   | Enciso Carrasco |      999991722 |
|    633428 | EngineeringPercepts | ERC-STG       | DR    | Marcel    | Oberlaender     |      974952433 |
|    633509 | EXTPRO              | ERC-STG       | PROF  | Asaf      | Shapira         |      999901609 |
|    633818 | dasQ                | ERC-STG       | DR    | Sebastian | Loth            |      999990267 |
|    633888 | SPENmr              | ERC-POC       | PROF  | Lucio     | Frydman         |      999979306 |

``` r

# display first row of projects info
con %>% tbl("projects") %>% 
  head(1) %>% 
  glimpse()
#> Rows: ??
#> Columns: 21
#> Database: duckdb_connection
#> $ rcn                  <dbl> 197163
#> $ id                   <dbl> 672890
#> $ acronym              <chr> "TailorFit"
#> $ status               <chr> "CLOSED"
#> $ programme            <chr> "H2020-EU.2.3.1.;H2020-EU.2.1.2."
#> $ topics               <chr> "NMP-25-2014-1"
#> $ frameworkProgramme   <chr> "H2020"
#> $ title                <chr> "TailorFit; The Integrated “made to measure” wor…
#> $ startDate            <dttm> 2015-06-01
#> $ endDate              <dttm> 2015-11-30
#> $ projectUrl           <chr> "http://www.creasolution.com"
#> $ objective            <chr> "'The project targets all luxury fashion firms t…
#> $ totalCost            <dbl> 71429
#> $ ecMaxContribution    <dbl> 50000
#> $ call                 <chr> "H2020-SMEINST-1-2014"
#> $ fundingScheme        <chr> "SME-1"
#> $ coordinator          <chr> "CREA SOLUTION SRL"
#> $ coordinatorCountry   <chr> "IT"
#> $ participants         <chr> NA
#> $ participantCountries <chr> NA
#> $ subjects             <lgl> NA

# display first row with publications data
con %>% tbl("projectpublications") %>% 
  head(1) %>% 
  select(-starts_with("X")) %>% 
  glimpse()
#> Rows: ??
#> Columns: 15
#> Database: duckdb_connection
#> $ rcn            <dbl> 485081
#> $ title          <chr> "Robustness of raman plasma amplifiers and their poten…
#> $ projectID      <chr> "633053"
#> $ projectAcronym <chr> "EUROfusion"
#> $ legalBasis     <chr> "H2020-Euratom"
#> $ topics         <chr> "EURATOM"
#> $ authors        <chr> "James D. Sadler, Marcin Sliwa, Thomas Miller, Muhamma…
#> $ journalTitle   <chr> "High Energy Density Physics"
#> $ publishedYear  <chr> "2017"
#> $ publishedPages <chr> "212-216"
#> $ issn           <chr> "1574-1818"
#> $ isbn           <chr> NA
#> $ doi            <chr> "10.1016/j.hedp.2017.05.007"
#> $ isPublishedAs  <chr> "PEER_REVIEWED_ARTICLE"
#> $ lastUpdateDate <chr> "2020-09-10 11:06:25"

cordis_disconnect(con)
```
