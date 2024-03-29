% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cordis.R
\name{cordis_import}
\alias{cordis_import}
\title{Import CORDIS database}
\usage{
cordis_import(
  repo_slug = "kth-library/cordis-data",
  refresh = FALSE,
  verbose = TRUE,
  version = "v0.2.1"
)
}
\arguments{
\item{repo_slug}{the repo slug for the GitHub repo with a release containing
an export made using this package, Default: 'kth-library/cordis-data'}

\item{refresh}{logical indicating whether to reimport overwriting existing data, Default: FALSE}

\item{verbose}{logical whether to display messages, Default: TRUE}

\item{version}{release version for data to use}
}
\value{
invisible TRUE on success
}
\description{
Imports the CORDIS database extract from parquet files, needs
to run at least once after package installation
}
\examples{
\dontrun{
if(interactive()){
 cordis_import()
 }
}
}
