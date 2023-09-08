
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

CORDIS makes open data about European research projects available at
various locations, such as:

- [Horizon Europe,
  2021-2027](https://data.europa.eu/data/datasets/cordis-eu-research-projects-under-horizon-europe-2021-2027?locale=en)
- [Horizon 2020,
  2014-2020](https://data.europa.eu/88u/dataset/cordisH2020projects)
- [FP7, 2007-2013](https://data.europa.eu/88u/dataset/cordisfp7projects)
- [CORDIS reference
  data](http://data.europa.eu/data/datasets/cordisref-data)

The download speed is rate limited when working directly against these
files, and file formats and compression are different. With some data
preparation, these datasets can be loaded into a database, providing
simplified and faster local access to the data.

In [`data-raw`](data-raw) there are data preparation scripts which
download data from these locations into a local cache directory
(`~/.cache/cordis`). A [duckdb](https://duckdb.org) database is built
from these files and uploaded using
[piggyback](https://github.com/ropensci/piggyback) to a [cordis-data
GitHub repo](https://github.com/KTH-Library/cordis-data) as a versioned
GitHub Release.

There is also a function for exporting the entire database in Parquet
format, which allows moving the data for example to a
[Minio](https://min.io/) server, where it can be accessed by other data
integration tools like duckdb, Arrow, Apache Spark etc. Only package
developers need to use these functions when preparing and updating the
data.

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

This is a basic example which shows you how to work with the data.

### Schema and available tables

Goal: show how to list the available tables and schema

``` r
library(cordis)
suppressPackageStartupMessages(library(dplyr))
library(knitr)

# tables in the database, prefixed with ....
# "ref" (reference data from CORDIS)
# "he" (Horizon Europe)
# "fp7" (FP7)
# "h2020" (Horizon 2020).

cordis_tables() |>
  arrange(desc(n_row)) |>
  print(n = 50)
#> # A tibble: 43 × 2
#>    table                              n_row
#>    <chr>                              <dbl>
#>  1 h2020_scoreboard                 1048576
#>  2 h2020_projectPublications         355710
#>  3 fp7_dm_proj_publications          305549
#>  4 h2020_webLink                     178131
#>  5 h2020_organization                177834
#>  6 h2020_projectDeliverables         148106
#>  7 fp7_organization                  140008
#>  8 h2020_euroSciVoc                  120020
#>  9 fp7_euroSciVoc                     68017
#> 10 h2020_legalBasis                   65792
#> 11 he_organization                    52918
#> 12 h2020_project                      35386
#> 13 h2020_topics                       35386
#> 14 h2020_reportSummaries              29613
#> 15 he_euroSciVoc                      26158
#> 16 fp7_topics                         26153
#> 17 fp7_legalBasis                     25785
#> 18 fp7_project                        25785
#> 19 fp7_reportSummaries                21606
#> 20 fp7_webItem                        11764
#> 21 he_legalBasis                      11531
#> 22 he_project                          8442
#> 23 he_topics                           8442
#> 24 fp7_webLink                         8160
#> 25 h2020_pi                            8043
#> 26 ref_fp7programmes                   6233
#> 27 ref_fp7subprogrammes                6096
#> 28 fp7_projectirps                     5293
#> 29 ref_h2020topics                     3910
#> 30 ref_h2020topicKeywords              2562
#> 31 h2020_projectIrps                   2324
#> 32 ref_horizontopics                   2211
#> 33 ref_fp6programmes                   2027
#> 34 ref_countries                       1503
#> 35 he_webLink                          1376
#> 36 he_projectDeliverables              1180
#> 37 ref_h2020programmes                  769
#> 38 ref_projectfundingschemecategory     298
#> 39 he_reportSummaries                   134
#> 40 ref_horizonprogrammes                123
#> 41 h2020_webItem                          9
#> 42 ref_organizationactivitytype           5
#> 43 he_webItem                             1

# database schema
cordis_schema() %>%
  head(20)
#> # A tibble: 20 × 7
#>    tablename                  cid name            type  notnull dflt_value pk   
#>    <chr>                    <int> <chr>           <chr> <lgl>   <chr>      <lgl>
#>  1 fp7_dm_proj_publications     0 PROJECT_ID      DOUB… FALSE   <NA>       FALSE
#>  2 fp7_dm_proj_publications     1 TITLE           VARC… FALSE   <NA>       FALSE
#>  3 fp7_dm_proj_publications     2 AUTHOR          VARC… FALSE   <NA>       FALSE
#>  4 fp7_dm_proj_publications     3 DOI             VARC… FALSE   <NA>       FALSE
#>  5 fp7_dm_proj_publications     4 PUBLICATION_TY… VARC… FALSE   <NA>       FALSE
#>  6 fp7_dm_proj_publications     5 REPOSITORY_URL  VARC… FALSE   <NA>       FALSE
#>  7 fp7_dm_proj_publications     6 JOURNAL_TITLE   VARC… FALSE   <NA>       FALSE
#>  8 fp7_dm_proj_publications     7 PUBLISHER       VARC… FALSE   <NA>       FALSE
#>  9 fp7_dm_proj_publications     8 VOLUME          VARC… FALSE   <NA>       FALSE
#> 10 fp7_dm_proj_publications     9 PAGES           VARC… FALSE   <NA>       FALSE
#> 11 fp7_dm_proj_publications    10 QA_PROCESSED_D… VARC… FALSE   <NA>       FALSE
#> 12 fp7_dm_proj_publications    11 RECORD_ID       VARC… FALSE   <NA>       FALSE
#> 13 fp7_euroSciVoc               0 projectID       DOUB… FALSE   <NA>       FALSE
#> 14 fp7_euroSciVoc               1 euroSciVocCode  VARC… FALSE   <NA>       FALSE
#> 15 fp7_euroSciVoc               2 euroSciVocPath  VARC… FALSE   <NA>       FALSE
#> 16 fp7_euroSciVoc               3 euroSciVocTitle VARC… FALSE   <NA>       FALSE
#> 17 fp7_euroSciVoc               4 euroSciVocDesc… BOOL… FALSE   <NA>       FALSE
#> 18 fp7_legalBasis               0 projectID       DOUB… FALSE   <NA>       FALSE
#> 19 fp7_legalBasis               1 legalBasis      VARC… FALSE   <NA>       FALSE
#> 20 fp7_legalBasis               2 title           VARC… FALSE   <NA>       FALSE
```

### Data from CORDIS projects

Goal: To show how to work with data for Horizon Europe projects.

``` r
# get a connection
con <- cordis_con()

# remember to disconnect when done:
# cordis_disconnect(con)

# these tables are of primary interest
cordis_tables() |>
  filter(grepl("^he_", table))
#> # A tibble: 9 × 2
#>   table                  n_row
#>   <chr>                  <dbl>
#> 1 he_euroSciVoc          26158
#> 2 he_legalBasis          11531
#> 3 he_organization        52918
#> 4 he_project              8442
#> 5 he_projectDeliverables  1180
#> 6 he_reportSummaries       134
#> 7 he_topics               8442
#> 8 he_webItem                 1
#> 9 he_webLink              1376

# display first row of projects info
con |> tbl("he_project") |> head(1) |> glimpse()
#> Rows: ??
#> Columns: 20
#> Database: DuckDB 0.8.1 [unknown@Linux 5.15.0-83-generic:R 4.3.1//home/markus/.cache/cordis/cordisdb]
#> $ id                 <dbl> 101103474
#> $ acronym            <chr> "NEOPLASTICS"
#> $ status             <chr> "SIGNED"
#> $ title              <chr> "Natural deep Eutectic sOlvents for sustainable bio…
#> $ startDate          <date> 2024-06-01
#> $ endDate            <date> 2026-05-31
#> $ totalCost          <dbl> 0
#> $ ecMaxContribution  <dbl> 181153
#> $ legalBasis         <chr> "HORIZON.1.2"
#> $ topics             <chr> "HORIZON-MSCA-2022-PF-01-01"
#> $ ecSignatureDate    <date> 2023-07-13
#> $ frameworkProgramme <chr> "HORIZON"
#> $ masterCall         <chr> "HORIZON-MSCA-2022-PF-01"
#> $ subCall            <chr> "HORIZON-MSCA-2022-PF-01"
#> $ fundingScheme      <chr> "HORIZON-TMA-MSCA-PF-EF"
#> $ nature             <lgl> NA
#> $ objective          <chr> "Petroleum-derived plastics produce greenhouse gas …
#> $ contentUpdateDate  <dttm> 2023-07-24 11:31:51
#> $ rcn                <dbl> 254572
#> $ grantDoi           <chr> "10.3030/101103474"

# display first five rows with PI data, exclude title and objective
con |> tbl("he_project") |> 
  select(-c("objective", "title")) |> 
  head(5) |> knitr::kable()
```

|        id | acronym     | status | startDate  | endDate    | totalCost | ecMaxContribution | legalBasis  | topics                                 | ecSignatureDate | frameworkProgramme | masterCall                          | subCall                             | fundingScheme          | nature | contentUpdateDate   |    rcn | grantDoi          |
|----------:|:------------|:-------|:-----------|:-----------|----------:|------------------:|:------------|:---------------------------------------|:----------------|:-------------------|:------------------------------------|:------------------------------------|:-----------------------|:-------|:--------------------|-------:|:------------------|
| 101103474 | NEOPLASTICS | SIGNED | 2024-06-01 | 2026-05-31 |         0 |            181153 | HORIZON.1.2 | HORIZON-MSCA-2022-PF-01-01             | 2023-07-13      | HORIZON            | HORIZON-MSCA-2022-PF-01             | HORIZON-MSCA-2022-PF-01             | HORIZON-TMA-MSCA-PF-EF | NA     | 2023-07-24 11:31:51 | 254572 | 10.3030/101103474 |
| 101091623 | BILASURF    | SIGNED | 2023-01-01 | 2025-12-31 |   5601669 |           5601669 | HORIZON.2.4 | HORIZON-CL4-2022-TWIN-TRANSITION-01-02 | 2022-11-23      | HORIZON            | HORIZON-CL4-2022-TWIN-TRANSITION-01 | HORIZON-CL4-2022-TWIN-TRANSITION-01 | RIA                    | NA     | 2022-11-28 13:29:41 | 243310 | 10.3030/101091623 |
| 101091687 | MatCHMaker  | SIGNED | 2022-12-01 | 2026-05-31 |   4700234 |           4700234 | HORIZON.2.4 | HORIZON-CL4-2022-RESILIENCE-01-19      | 2022-11-18      | HORIZON            | HORIZON-CL4-2022-RESILIENCE-01      | HORIZON-CL4-2022-RESILIENCE-01      | RIA                    | NA     | 2022-11-25 10:10:39 | 243192 | 10.3030/101091687 |
| 101111996 | CUBIC       | SIGNED | 2023-09-01 | 2027-02-28 |   4683365 |           4683365 | HORIZON.2.6 | HORIZON-JU-CBE-2022-R-03               | 2023-05-12      | HORIZON            | HORIZON-JU-CBE-2022                 | HORIZON-JU-CBE-2022                 | HORIZON-JU-RIA         | NA     | 2023-06-21 09:34:12 | 249379 | 10.3030/101111996 |
| 101092153 | H2GLASS     | SIGNED | 2023-01-01 | 2026-12-31 |  31862996 |          23267442 | HORIZON.2.4 | HORIZON-CL4-2022-TWIN-TRANSITION-01-17 | 2022-11-24      | HORIZON            | HORIZON-CL4-2022-TWIN-TRANSITION-01 | HORIZON-CL4-2022-TWIN-TRANSITION-01 | IA                     | NA     | 2022-11-28 13:29:18 | 243300 | 10.3030/101092153 |

``` r

# display first row with publications data
con |> tbl("he_projectDeliverables") |> 
  head(1) |>
  select(-starts_with("X")) |>
  glimpse()
#> Rows: ??
#> Columns: 10
#> Database: DuckDB 0.8.1 [unknown@Linux 5.15.0-83-generic:R 4.3.1//home/markus/.cache/cordis/cordisdb]
#> $ id                <chr> "101091852_26_DELIVHORIZON"
#> $ title             <chr> "Communication basics (project logo, website, brochu…
#> $ deliverableType   <chr> "Websites, patent fillings, videos etc."
#> $ description       <chr> "Communication basics project logo website brochure …
#> $ projectID         <dbl> 101091852
#> $ projectAcronym    <chr> "REBORN"
#> $ url               <chr> "https://ec.europa.eu/research/participants/document…
#> $ collection        <chr> "Project deliverable"
#> $ contentUpdateDate <dttm> 2023-04-21 15:10:37
#> $ rcn               <dbl> 929520

cordis_disconnect(con)
```

Tables for Horizon 2020, FP7 etc are also available, as well as
“reference data”.

### Data from CORDIS reference data

These datasets provide “reference data” for FP6, FP7, Horizon 2020
projects, see this
[source](https://data.europa.eu/api/hub/search/en/feeds/datasets/cordisref-data.rss)

Goal: Show how to work with reference data related to Horizon 2020
projects

``` r
# get a connection
con <- cordis_con()

# remember to disconnect when done:
# cordis_disconnect(con)

# use any of these tables
cordis_tables() |> filter(grepl("^ref_", table))
#> # A tibble: 11 × 2
#>    table                            n_row
#>    <chr>                            <dbl>
#>  1 ref_countries                     1503
#>  2 ref_fp6programmes                 2027
#>  3 ref_fp7programmes                 6233
#>  4 ref_fp7subprogrammes              6096
#>  5 ref_h2020programmes                769
#>  6 ref_h2020topicKeywords            2562
#>  7 ref_h2020topics                   3910
#>  8 ref_horizonprogrammes              123
#>  9 ref_horizontopics                 2211
#> 10 ref_organizationactivitytype         5
#> 11 ref_projectfundingschemecategory   298

# display first five rows with PI data
con |> tbl("h2020_pi") |> head(5) |> knitr::kable()
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
con |> tbl("h2020_project") |> head(1) |> glimpse()
#> Rows: ??
#> Columns: 20
#> Database: DuckDB 0.8.1 [unknown@Linux 5.15.0-83-generic:R 4.3.1//home/markus/.cache/cordis/cordisdb]
#> $ id                 <dbl> 879926
#> $ acronym            <chr> "EEN SACHSEN"
#> $ status             <chr> "CLOSED"
#> $ title              <chr> "Specific activities in the context of innovation s…
#> $ startDate          <date> 2020-01-01
#> $ endDate            <date> 2021-12-31
#> $ totalCost          <dbl> 125560
#> $ ecMaxContribution  <dbl> 125559
#> $ legalBasis         <chr> "H2020-EU.2.3."
#> $ topics             <chr> "H2020-EEN-SGA4"
#> $ ecSignatureDate    <date> 2019-12-06
#> $ frameworkProgramme <chr> "H2020"
#> $ masterCall         <chr> "H2020-EEN-SGA4-2020-2021"
#> $ subCall            <chr> "H2020-EEN-SGA4-2020-2021"
#> $ fundingScheme      <chr> "CSA"
#> $ nature             <chr> NA
#> $ objective          <chr> "The aim of the present proposal is to contribute t…
#> $ contentUpdateDate  <dttm> 2022-10-28 14:07:26
#> $ rcn                <dbl> 226577
#> $ grantDoi           <chr> "10.3030/879926"

# display first row with publications data
con |> tbl("h2020_projectPublications") |> 
  head(1) |>
  glimpse()
#> Rows: ??
#> Columns: 16
#> Database: DuckDB 0.8.1 [unknown@Linux 5.15.0-83-generic:R 4.3.1//home/markus/.cache/cordis/cordisdb]
#> $ id                <chr> "754510_1752052_PUBLI"
#> $ title             <chr> "Effect of Mechanochemical Recrystallization on the …
#> $ isPublishedAs     <chr> "Peer reviewed articles"
#> $ authors           <chr> "Nieto-Castro D; Garcés-Pineda FA; Moneo-Corcuera A;…
#> $ journalTitle      <chr> "Inorganic Chemistry."
#> $ journalNumber     <chr> "59 (12):"
#> $ publishedYear     <dbl> 2020
#> $ publishedPages    <chr> "7953-7959"
#> $ issn              <chr> "0020-1669"
#> $ isbn              <chr> NA
#> $ doi               <chr> "10.1021/acs.inorgchem.9b03284"
#> $ projectID         <dbl> 754510
#> $ projectAcronym    <chr> "PROBIST"
#> $ collection        <chr> "Project publication"
#> $ contentUpdateDate <dttm> 2023-07-27 22:51:51
#> $ rcn               <dbl> 961574

cordis_disconnect(con)
```
