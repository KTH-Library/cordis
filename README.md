
<!-- README.md is generated from README.Rmd. Please edit that file -->

# cordis

<!-- badges: start -->

<!-- badges: end -->

The goal of `cordis` is to provide data from CORDIS. CORDIS is an
acronym for the Community Research and Development Information Service.
It is the European Commission’s primary source of results from the
projects funded by the EU’s framework programmes for research and
innovation. This includes programmes from FP1 to Horizon 2020.

## Data preparation

CORDIS makes data about European research projects available at various
locations, such as
<https://data.europa.eu/euodp/en/data/dataset/cordisH2020projects>.

In [`data-raw`](data-raw) there are data preparation scripts which
download data from these locations into a local cache directory
(`~/.cache/cordis`). A [duckdb](https://duckdb.org) database is built
from these files and installed locally in the same directory.

The package then provides functions for making a connection to the
database (allowing arbitrary data processing with tidyverse tools for
example), and for inspecting the database schema / finding table and
field names.

There is also a function for exporting the entire database in Parquet
format, which allows moving the data to a Minio server, where it an be
accessed by other data integration tools like Apache Spark.

## Installation

You can install the released version of `cordis` from
[GitHub](https://github.com/KTH-Library/cordis) with:

``` r
devtools::install_github("KTH-Library/cordis")
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
#>  2 projectPublications           161524
#>  3 organizations                 150287
#>  4 projectDeliverables            84323
#>  5 projects                       32161
#>  6 reports                        19295
#>  7 pi                              7525
#>  8 FP7programmes                   6233
#>  9 fp7subprogrammes                6096
#> 10 h2020topics                     3878
#> 11 FP6programmes                   2027
#> 12 countries                       1503
#> 13 h2020programmes                  909
#> 14 sicCode                          426
#> 15 projectFundingSchemeCategory     187
#> 16 organizationActivityType           5

# database schema
cordis_schema() %>%
  head(20)
#>           tablename cid       name    type notnull dflt_value    pk
#> 1     FP6programmes   0        rcn  DOUBLE   FALSE       <NA> FALSE
#> 2     FP6programmes   1       code VARCHAR   FALSE       <NA> FALSE
#> 3     FP6programmes   2      title VARCHAR   FALSE       <NA> FALSE
#> 4     FP6programmes   3 shortTitle VARCHAR   FALSE       <NA> FALSE
#> 5     FP6programmes   4   language VARCHAR   FALSE       <NA> FALSE
#> 6     FP7programmes   0        RCN  DOUBLE   FALSE       <NA> FALSE
#> 7     FP7programmes   1       Code VARCHAR   FALSE       <NA> FALSE
#> 8     FP7programmes   2      Title VARCHAR   FALSE       <NA> FALSE
#> 9     FP7programmes   3 ShortTitle VARCHAR   FALSE       <NA> FALSE
#> 10    FP7programmes   4   Language VARCHAR   FALSE       <NA> FALSE
#> 11        countries   0     euCode VARCHAR   FALSE       <NA> FALSE
#> 12        countries   1    isoCode VARCHAR   FALSE       <NA> FALSE
#> 13        countries   2       name VARCHAR   FALSE       <NA> FALSE
#> 14        countries   3   language VARCHAR   FALSE       <NA> FALSE
#> 15 fp7subprogrammes   0       col1 VARCHAR   FALSE       <NA> FALSE
#> 16 fp7subprogrammes   1       col2 VARCHAR   FALSE       <NA> FALSE
#> 17 fp7subprogrammes   2       col3 VARCHAR   FALSE       <NA> FALSE
#> 18 fp7subprogrammes   3       col4 VARCHAR   FALSE       <NA> FALSE
#> 19 fp7subprogrammes   4       col5 VARCHAR   FALSE       <NA> FALSE
#> 20 fp7subprogrammes   5       col6 VARCHAR   FALSE       <NA> FALSE

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
#> $ startDate            <date> 2015-06-01
#> $ endDate              <date> 2015-11-30
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
con %>% tbl("projectPublications") %>% 
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
