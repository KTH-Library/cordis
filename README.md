
<!-- README.md is generated from README.Rmd. Please edit that file -->

# cordis

<!-- badges: start -->

[![R-CMD-check](https://github.com/KTH-Library/cordis/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/KTH-Library/cordis/actions/workflows/R-CMD-check.yaml)
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
installed locally by regular package users by running “cordis_import()”,
a function for importing the data from the data repository. This needs
to be done once. The download and upload rate is good.

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
cordis_tables() |>
  arrange(desc(n_row)) |>
  print(n = 50)
#> Connecting to /home/markus/.cache/cordis/cordisdb
#> # A tibble: 31 × 2
#>    table                          n_row
#>    <chr>                          <dbl>
#>  1 h2020_scoreboard             1048576
#>  2 h2020_projectPublications     318740
#>  3 h2020_organization            177078
#>  4 h2020_webLink                 162178
#>  5 h2020_projectDeliverables     137319
#>  6 h2020_euroSciVoc              122551
#>  7 h2020_legalBasis               65784
#>  8 he_organization                36680
#>  9 h2020_project                  35382
#> 10 h2020_topics                   35382
#> 11 h2020_reportSummaries          27082
#> 12 he_euroSciVoc                  15810
#> 13 h2020_pi                        8043
#> 14 he_legalBasis                   7657
#> 15 fp7programmes                   6233
#> 16 fp7subprogrammes                6096
#> 17 he_project                      5250
#> 18 he_topics                       5250
#> 19 h2020programmes                 3905
#> 20 h2020topics                     3905
#> 21 h2020topicKeywords              2562
#> 22 projectIrps_h2020               2324
#> 23 horizontopics                   2047
#> 24 fp6programmes                   2027
#> 25 countries                       1503
#> 26 he_webLink                       241
#> 27 he_projectDeliverables           205
#> 28 projectfundingschemecategory     187
#> 29 horizonprogrammes                123
#> 30 h2020_webItem                      9
#> 31 organizationactivitytype           5

# database schema
cordis_schema() %>%
  head(20)
#> Connecting to /home/markus/.cache/cordis/cordisdb
#> # A tibble: 20 × 7
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
#> 15 fp7subprogrammes     0 id         INTEGER FALSE   <NA>       FALSE
#> 16 fp7subprogrammes     1 cat_1      VARCHAR FALSE   <NA>       FALSE
#> 17 fp7subprogrammes     2 cat_2      VARCHAR FALSE   <NA>       FALSE
#> 18 fp7subprogrammes     3 cat_3      VARCHAR FALSE   <NA>       FALSE
#> 19 fp7subprogrammes     4 cat_4      VARCHAR FALSE   <NA>       FALSE
#> 20 fp7subprogrammes     5 cat_5      VARCHAR FALSE   <NA>       FALSE

# get a connection
con <- cordis_con()
#> Connecting to /home/markus/.cache/cordis/cordisdb
# remember to disconnect when done:
# cordis_disconnect(con)

# display first five rows with PI data
con %>% tbl("h2020_pi") %>% 
  head(5) %>% 
  knitr::kable()
```

| projectId | projectAcronym      | fundingScheme | title | firstName | lastName        | organisationId |
|----------:|:--------------------|:--------------|:------|:----------|:----------------|---------------:|
|    633152 | GEOFLUIDS           | ERC-STG       | DR    | Alberto   | Enciso Carrasco |      999991722 |
|    633428 | EngineeringPercepts | ERC-STG       | DR    | Marcel    | Oberlaender     |      974952433 |
|    633509 | EXTPRO              | ERC-STG       | PROF  | Asaf      | Shapira         |      999901609 |
|    633818 | dasQ                | ERC-STG       | DR    | Sebastian | Loth            |      999990267 |
|    633888 | SPENmr              | ERC-POC       | PROF  | Lucio     | Frydman         |      999979306 |

``` r

# display first row of projects info
con %>% tbl("he_project") %>% 
  head(1) %>% 
  glimpse()
#> Rows: ??
#> Columns: 20
#> Database: DuckDB 0.6.2-dev1166 [unknown@Linux 5.4.0-137-generic:R 4.2.2//home/markus/.cache/cordis/cordisdb]
#> $ id                 <dbl> 101043356
#> $ acronym            <chr> "PROGRESS"
#> $ status             <chr> "SIGNED"
#> $ title              <chr> "Reading provenance from ubiquitous quartz:  unders…
#> $ startDate          <date> 2023-01-01
#> $ endDate            <date> 2027-12-31
#> $ totalCost          <dbl> 2657500
#> $ ecMaxContribution  <dbl> 2657500
#> $ legalBasis         <chr> "HORIZON.1.1"
#> $ topics             <chr> "ERC-2021-COG"
#> $ ecSignatureDate    <date> 2022-09-21
#> $ frameworkProgramme <chr> "HORIZON"
#> $ masterCall         <chr> "ERC-2021-COG"
#> $ subCall            <chr> "ERC-2021-COG"
#> $ fundingScheme      <chr> "ERC"
#> $ nature             <lgl> NA
#> $ objective          <chr> "Quantitative provenance analysis studies are instr…
#> $ contentUpdateDate  <dttm> 2022-09-28 12:21:14
#> $ rcn                <dbl> 242239
#> $ grantDoi           <chr> "10.3030/101043356"

# display first row with publications data
con %>% tbl("h2020_projectpublications") %>% 
  head(1) %>% 
  select(-starts_with("X")) %>% 
  glimpse()
#> Rows: ??
#> Columns: 16
#> Database: DuckDB 0.6.2-dev1166 [unknown@Linux 5.4.0-137-generic:R 4.2.2//home/markus/.cache/cordis/cordisdb]
#> $ id                <chr> "771635_675336_PUBLI"
#> $ title             <chr> "Debating the EU's Raison d'�tre: On the Relation be…
#> $ isPublishedAs     <chr> "Peer reviewed articles"
#> $ authors           <chr> "Andrea Sangiovanni"
#> $ journalTitle      <chr> "JCMS: Journal of Common Market Studies"
#> $ journalNumber     <chr> "57/1"
#> $ publishedYear     <dbl> 2018
#> $ publishedPages    <chr> "13-27"
#> $ issn              <chr> "0021-9886"
#> $ isbn              <chr> NA
#> $ doi               <chr> "10.1111/jcms.12819"
#> $ projectID         <dbl> 771635
#> $ projectAcronym    <chr> "EUSOL"
#> $ collection        <chr> "Project publication"
#> $ contentUpdateDate <dttm> 2020-09-10 12:26:01
#> $ rcn               <dbl> 621019

cordis_disconnect(con)
```
