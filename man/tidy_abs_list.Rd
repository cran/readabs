% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tidy_abs_list.R
\name{tidy_abs_list}
\alias{tidy_abs_list}
\title{Tidy multiple dataframes of ABS time series data contained in a list.}
\usage{
tidy_abs_list(list_of_dfs, metadata = TRUE)
}
\arguments{
\item{list_of_dfs}{A list of dataframes containing extracted
ABS time series data.}

\item{metadata}{logical. If \code{TRUE} (the default), a tidy data frame including
ABS metadata (series name, table name, etc.) is included in the output. If
\code{FALSE}, metadata is dropped.}
}
\description{
Tidy multiple dataframes of ABS time series data contained in a list.
}
