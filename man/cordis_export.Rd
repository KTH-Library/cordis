% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cordis.R
\name{cordis_export}
\alias{cordis_export}
\title{Export CORDIS database}
\usage{
cordis_export(destdir, overwrite = FALSE)
}
\arguments{
\item{destdir}{the directory where the parquet files should be written}

\item{overwrite}{boolean to indicate overwriting existing dir, default FALSE}
}
\value{
invisible TRUE on success
}
\description{
Export in parquet format to a destination directory
}
\details{
also takes care of shutting down the connection
}
\examples{
\dontrun{
cordis_export("~/mycordisexport")
}
}
