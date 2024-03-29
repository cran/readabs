% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read_payrolls.R
\name{download_previous_payrolls}
\alias{download_previous_payrolls}
\title{This function is temporarily necessary while the readabs maintainer
attempts to resolve an issue with the ABS. The ABS as at late March 2021
stopped including Table 5 of the Weekly Payrolls release with each new
release of the data. This function finds the link from the previous
release and attemps to download it. This function will no longer be required
if/when the ABS reverts to the previous release arrangements. The function
is internal and is called by \code{read_payrolls()}.}
\usage{
download_previous_payrolls(cube_name, path)
}
\arguments{
\item{cube_name}{eg. DO005 for table 5}

\item{path}{Directory in which to download payrolls cube}
}
\value{
A list containing two elements: \code{result} (will contain path + filename
to downloaded file if download was successful); and \code{error} (NULL if file
downloaded successfully; character otherwise).
}
\description{
This function is temporarily necessary while the readabs maintainer
attempts to resolve an issue with the ABS. The ABS as at late March 2021
stopped including Table 5 of the Weekly Payrolls release with each new
release of the data. This function finds the link from the previous
release and attemps to download it. This function will no longer be required
if/when the ABS reverts to the previous release arrangements. The function
is internal and is called by \code{read_payrolls()}.
}
\keyword{internal}
