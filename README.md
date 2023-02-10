
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
#> # A tibble: 41 × 2
#>    table                              n_row
#>    <chr>                              <dbl>
#>  1 h2020_scoreboard                 1048576
#>  2 h2020_projectPublications         318740
#>  3 fp7_dm_proj_publications          305549
#>  4 h2020_organization                177078
#>  5 h2020_webLink                     162178
#>  6 fp7_organization                  140055
#>  7 h2020_projectDeliverables         137319
#>  8 h2020_euroSciVoc                  122551
#>  9 fp7_euroSciVoc                     68651
#> 10 h2020_legalBasis                   65784
#> 11 he_organization                    36680
#> 12 h2020_project                      35382
#> 13 h2020_topics                       35382
#> 14 h2020_reportSummaries              27082
#> 15 fp7_topics                         26153
#> 16 fp7_legalBasis                     25785
#> 17 fp7_project                        25785
#> 18 fp7_reportSummaries                21606
#> 19 he_euroSciVoc                      15810
#> 20 fp7_webItem                        11767
#> 21 h2020_pi                            8043
#> 22 fp7_webLink                         7989
#> 23 he_legalBasis                       7657
#> 24 ref_fp7programmes                   6233
#> 25 ref_fp7subprogrammes                6096
#> 26 fp7_projectirps                     5293
#> 27 he_project                          5250
#> 28 he_topics                           5250
#> 29 ref_h2020programmes                 3905
#> 30 ref_h2020topics                     3905
#> 31 ref_h2020topicKeywords              2562
#> 32 h2020_projectIrps                   2324
#> 33 ref_horizontopics                   2047
#> 34 ref_fp6programmes                   2027
#> 35 ref_countries                       1503
#> 36 he_webLink                           241
#> 37 he_projectDeliverables               205
#> 38 ref_projectfundingschemecategory     187
#> 39 ref_horizonprogrammes                123
#> 40 h2020_webItem                          9
#> 41 ref_organizationactivitytype           5

# database schema
cordis_schema() %>%
  head(20)
#> # A tibble: 20 × 7
#>    tablename                  cid name               type  notnull dflt_…¹ pk   
#>    <chr>                    <int> <chr>              <chr> <lgl>   <chr>   <lgl>
#>  1 fp7_dm_proj_publications     0 PROJECT_ID         DOUB… FALSE   <NA>    FALSE
#>  2 fp7_dm_proj_publications     1 TITLE              VARC… FALSE   <NA>    FALSE
#>  3 fp7_dm_proj_publications     2 AUTHOR             VARC… FALSE   <NA>    FALSE
#>  4 fp7_dm_proj_publications     3 DOI                VARC… FALSE   <NA>    FALSE
#>  5 fp7_dm_proj_publications     4 PUBLICATION_TYPE   VARC… FALSE   <NA>    FALSE
#>  6 fp7_dm_proj_publications     5 REPOSITORY_URL     VARC… FALSE   <NA>    FALSE
#>  7 fp7_dm_proj_publications     6 JOURNAL_TITLE      VARC… FALSE   <NA>    FALSE
#>  8 fp7_dm_proj_publications     7 PUBLISHER          VARC… FALSE   <NA>    FALSE
#>  9 fp7_dm_proj_publications     8 VOLUME             VARC… FALSE   <NA>    FALSE
#> 10 fp7_dm_proj_publications     9 PAGES              VARC… FALSE   <NA>    FALSE
#> 11 fp7_dm_proj_publications    10 QA_PROCESSED_DOI   VARC… FALSE   <NA>    FALSE
#> 12 fp7_dm_proj_publications    11 RECORD_ID          VARC… FALSE   <NA>    FALSE
#> 13 fp7_euroSciVoc               0 projectID          DOUB… FALSE   <NA>    FALSE
#> 14 fp7_euroSciVoc               1 euroSciVocCode     VARC… FALSE   <NA>    FALSE
#> 15 fp7_euroSciVoc               2 euroSciVocPath     VARC… FALSE   <NA>    FALSE
#> 16 fp7_euroSciVoc               3 euroSciVocTitle    VARC… FALSE   <NA>    FALSE
#> 17 fp7_euroSciVoc               4 euroSciVocDescrip… BOOL… FALSE   <NA>    FALSE
#> 18 fp7_legalBasis               0 projectID          DOUB… FALSE   <NA>    FALSE
#> 19 fp7_legalBasis               1 legalBasis         VARC… FALSE   <NA>    FALSE
#> 20 fp7_legalBasis               2 title              VARC… FALSE   <NA>    FALSE
#> # … with abbreviated variable name ¹​dflt_value
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
#> # A tibble: 7 × 2
#>   table                  n_row
#>   <chr>                  <dbl>
#> 1 he_euroSciVoc          15810
#> 2 he_legalBasis           7657
#> 3 he_organization        36680
#> 4 he_project              5250
#> 5 he_projectDeliverables   205
#> 6 he_topics               5250
#> 7 he_webLink               241

# display first row of projects info
con |> tbl("he_project") |> head(1) |> glimpse()
#> Rows: ??
#> Columns: 20
#> Database: DuckDB 0.6.2-dev1166 [unknown@Linux 5.4.0-139-generic:R 4.2.2//home/markus/.cache/cordis/cordisdb]
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

# display first five rows with PI data, exclude title and objective
con |> tbl("he_project") |> 
  select(-c("objective", "title")) |> 
  head(5) |> knitr::kable()
```

|        id | acronym     | status | startDate  | endDate    | totalCost | ecMaxContribution | legalBasis  | topics                              | ecSignatureDate | frameworkProgramme | masterCall                      | subCall                         | fundingScheme | nature | contentUpdateDate   |    rcn | grantDoi          |
|----------:|:------------|:-------|:-----------|:-----------|----------:|------------------:|:------------|:------------------------------------|:----------------|:-------------------|:--------------------------------|:--------------------------------|:--------------|:-------|:--------------------|-------:|:------------------|
| 101043356 | PROGRESS    | SIGNED | 2023-01-01 | 2027-12-31 |   2657500 |           2657500 | HORIZON.1.1 | ERC-2021-COG                        | 2022-09-21      | HORIZON            | ERC-2021-COG                    | ERC-2021-COG                    | ERC           | NA     | 2022-09-28 12:21:14 | 242239 | 10.3030/101043356 |
| 101100999 | SCOPE       | SIGNED | 2022-09-01 | 2024-02-29 |         0 |            150000 | HORIZON.1.1 | ERC-2022-POC2                       | 2022-09-29      | HORIZON            | ERC-2022-POC2                   | ERC-2022-POC2                   | ERC-POC       | NA     | 2022-10-06 17:58:49 | 242302 | 10.3030/101100999 |
| 101057802 | e-IRGSP7    | SIGNED | 2022-04-01 | 2023-09-30 |    302260 |            302259 | HORIZON.1.3 | HORIZON-INFRA-2021-DEV-01-05        | 2022-03-28      | HORIZON            | HORIZON-INFRA-2021-DEV-01       | HORIZON-INFRA-2021-DEV-01       | CSA           | NA     | 2022-09-04 13:39:32 | 241435 | 10.3030/101057802 |
| 190100375 | EOinTime    | SIGNED | 2022-10-01 | 2024-03-31 |   2489000 |           1735300 | HORIZON.3.1 | HORIZON-EIC-2022-ACCELERATOROPEN-01 | 2022-09-20      | HORIZON            | HORIZON-EIC-2022-ACCELERATOR-01 | HORIZON-EIC-2022-ACCELERATOR-01 | HORIZON-AG    | NA     | 2022-09-27 17:17:17 | 242179 | 10.3030/190100375 |
| 101073222 | BosomShield | SIGNED | 2022-09-01 | 2026-08-31 |         0 |          25953552 | HORIZON.1.2 | HORIZON-MSCA-2021-DN-01-01          | 2022-07-06      | HORIZON            | HORIZON-MSCA-2021-DN-01         | HORIZON-MSCA-2021-DN-01         | HORIZON-AG-UN | NA     | 2022-09-12 16:42:49 | 241045 | 10.3030/101073222 |

``` r

# display first row with publications data
con |> tbl("he_projectDeliverables") |> 
  head(1) |>
  select(-starts_with("X")) |>
  glimpse()
#> Rows: ??
#> Columns: 10
#> Database: DuckDB 0.6.2-dev1166 [unknown@Linux 5.4.0-139-generic:R 4.2.2//home/markus/.cache/cordis/cordisdb]
#> $ id                <chr> "101069941_27_DELIVHORIZON"
#> $ title             <chr> "Project Website, Corporate identity and general tem…
#> $ deliverableType   <chr> "Websites, patent fillings, videos etc."
#> $ description       <chr> "Provision of the logo and the templates to be used …
#> $ projectID         <dbl> 101069941
#> $ projectAcronym    <chr> "PLOTO"
#> $ url               <chr> "https://ec.europa.eu/research/participants/document…
#> $ collection        <chr> "Project deliverable"
#> $ contentUpdateDate <dttm> 2022-12-26 19:05:16
#> $ rcn               <dbl> 902856

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
#>  5 ref_h2020programmes               3905
#>  6 ref_h2020topicKeywords            2562
#>  7 ref_h2020topics                   3905
#>  8 ref_horizonprogrammes              123
#>  9 ref_horizontopics                 2047
#> 10 ref_organizationactivitytype         5
#> 11 ref_projectfundingschemecategory   187

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
#> Database: DuckDB 0.6.2-dev1166 [unknown@Linux 5.4.0-139-generic:R 4.2.2//home/markus/.cache/cordis/cordisdb]
#> $ id                 <dbl> 800506
#> $ acronym            <chr> "IntegraSea"
#> $ status             <chr> "CLOSED"
#> $ title              <chr> "Integrated offshore cultivation of high value seaw…
#> $ startDate          <date> 2019-02-01
#> $ endDate            <date> 2021-01-31
#> $ totalCost          <dbl> 1486356
#> $ ecMaxContribution  <dbl> 1486356
#> $ legalBasis         <chr> "H2020-EU.1.3."
#> $ topics             <chr> "MSCA-IF-2017"
#> $ ecSignatureDate    <date> 2018-04-11
#> $ frameworkProgramme <chr> "H2020"
#> $ masterCall         <chr> "H2020-MSCA-IF-2017"
#> $ subCall            <chr> "H2020-MSCA-IF-2017"
#> $ fundingScheme      <chr> "MSCA-IF-EF-ST"
#> $ nature             <chr> NA
#> $ objective          <chr> "IntegraSea is in line with the EU Blue Growth Agen…
#> $ contentUpdateDate  <dttm> 2022-08-24 00:17:27
#> $ rcn                <dbl> 215814
#> $ grantDoi           <chr> "10.3030/800506"

# display first row with publications data
con |> tbl("h2020_projectPublications") |> 
  head(1) |>
  glimpse()
#> Rows: ??
#> Columns: 16
#> Database: DuckDB 0.6.2-dev1166 [unknown@Linux 5.4.0-139-generic:R 4.2.2//home/markus/.cache/cordis/cordisdb]
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
