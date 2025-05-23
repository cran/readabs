#' Download, extract, and tidy ABS time series spreadsheets
#' @description
#' `r lifecycle::badge("stable")`
#'
#' \code{read_abs()} downloads ABS time series spreadsheets,
#' then extracts the data from those spreadsheets,
#' then tidies the data. The result is a single
#' data frame (tibble) containing tidied data.
#'
#' @param cat_no ABS catalogue number, as a string, including the extension.
#' For example, "6202.0".
#'
#' @param tables numeric. Time series tables in `cat_no`` to download and
#' extract. Default is "all", which will read all time series in `cat_no`.
#' Specify `tables` to download and import specific tables(s) -
#' eg. `tables = 1` or `tables = c(1, 5)`.
#'
#' @param series_id (optional) character. Supply an ABS unique time series
#' identifier (such as "A2325807L") to get only that series.
#' This is an alternative to specifying `cat_no`.
#'
#' @param path Local directory in which downloaded ABS time series
#' spreadsheets should be stored. By default, `path` takes the value set in the
#' environment variable "R_READABS_PATH". If this variable is not set,
#' any files downloaded by read_abs()  will be stored in a temporary directory
#' (\code{tempdir()}). See \code{Details} below for
#' more information.
#'
#' @param metadata logical. If `TRUE` (the default), a tidy data frame including
#' ABS metadata (series name, table name, etc.) is included in the output. If
#' `FALSE`, metadata is dropped.
#'
#' @param show_progress_bars TRUE by default. If set to FALSE, progress bars
#' will not be shown when ABS spreadsheets are downloading.
#'
#' @param retain_files when TRUE (the default), the spreadsheets downloaded
#' from the ABS website will be saved in the directory specified with `path`.
#' If set to `FALSE`, the files will be stored in a temporary directory.
#'
#' @param ... Arguments to `read_abs_series()` are passed to `read_abs()`.
#'
#' @param check_local If `TRUE`, the default, local `fst` files are used,
#' if present.
#'
#' @param release_date Either `"latest"` or a string coercible to a date, such as
#' `"2022-02-01"`. If `"latest"`, the latest release of the requested data will
#' be returned. If a date, (eg. `"2022-02-01"`) `read_abs()` will
#' attempt to download the data from that month's release. Note that this only
#' works consistently as expected for monthly data. See `Details`.
#'
#' @return A data frame (tibble) containing the tidied data from the ABS time
#' series table(s).
#'
#' @details
#' `read_abs_series()` is a wrapper around `read_abs()`, with `series_id` as
#' the first argument.
#'
#' `read_abs()` downloads spreadsheet(s) from the ABS containing time
#' series data. These files need to be saved somewhere on your disk.
#' This local directory can be controlled using the `path` argument to
#' `read_abs()`. If the `path` argument is not set, `read_abs()` will store
#' the files in a directory set in the "R_READABS_PATH" environment variable.
#' If this variable isn't set, files will be saved in a temporary directory.
#'
#' To check the value of the "R_READABS_PATH" variable, run
#' \code{Sys.getenv("R_READABS_PATH")}. You can set the value of this variable
#' for a single session using \code{Sys.setenv(R_READABS_PATH = <path>)}.
#' If you would like to change this variable for all future R sessions, edit
#' your `.Renviron` file and add \code{R_READABS_PATH = <path>} line.
#' The easiest way to edit this file is using \code{usethis::edit_r_environ()}.
#'
#' Certain corporate networks restrict your ability to download files in an R
#' session. On some of these networks, the `"wininet"` method must be used when
#' downloading files. Users can now specify the method that will be used to
#' download files by setting the `"R_READABS_DL_METHOD"` environment variable.
#'
#' For example, the following code sets the environment variable for your
#' current session: s`Sys.setenv("R_READABS_DL_METHOD" = "wininet")`
#' You can add `R_READABS_DL_METHOD = "wininet"` to your .Renviron to have
#' this persist across sessions.
#'
#' The `release_date` argument allows you to download table(s) other than the
#' latest release. This is useful for examining revisions to time series, or
#' for obtaining the version of series that were available on a given date.
#' Note that you cannot supply more than one date to `release_date`. Note also
#' that any dates prior to mid-2019 (the exact date varies by series) will fail.
#' Specifying `release_date` only reliably works for monthly, and some
#' quarterly, data. It does not work for annual data.
#'
#' @rdname read_abs
#' @examples
#'
#' # Download and tidy all time series spreadsheets
#' # from the Wage Price Index (6345.0)
#' \dontrun{
#' wpi <- read_abs("6345.0")
#' }
#'
#' # Download table 1 from the Wage Price Index
#' \dontrun{
#' wpi_t1 <- read_abs("6345.0", tables = "1")
#' }
#'
#' # Or table 1 as in the Sep 2019 release of the WPI:
#' \dontrun{
#' wpi_t1_sep2019 <- read_abs("6345.0", tables = "1", release_date = "2019-09-01")
#' }
#'
#' # Or tables 1 and 2a from the WPI
#' \dontrun{
#' wpi_t1_t2a <- read_abs("6345.0", tables = c("1", "2a"))
#' }
#'
#'
#' # Get two specific time series, based on their time series IDs
#' \dontrun{
#' cpi <- read_abs(series_id = c("A2325806K", "A2325807L"))
#' }
#'
#' # Get series IDs using the `read_abs_series()` wrapper function
#' \dontrun{
#' cpi <- read_abs_series(c("A2325806K", "A2325807L"))
#' }

#' @importFrom purrr walk walk2 map map_dfr map2
#' @importFrom dplyr group_by filter
#' @name read_abs
#' @export

read_abs <- function(cat_no = NULL,
                     tables = "all",
                     series_id = NULL,
                     path = Sys.getenv("R_READABS_PATH", unset = tempdir()),
                     metadata = TRUE,
                     show_progress_bars = TRUE,
                     retain_files = TRUE,
                     check_local = TRUE,
                     release_date = "latest") {
  if (isTRUE(check_local) &&
    fst_available(cat_no = cat_no, path = path)) {
    if (!identical(tables, "all")) {
      warning(
        "`tables` was provided",
        "yet `check_local = TRUE` and fst files are available ",
        "so `tables` will be ignored."
      )
    }
    out <- fst::read_fst(path = catno2fst(cat_no = cat_no, path = path))
    out <- dplyr::as_tibble(out)
    if (is.null(series_id)) {
      return(out)
    }
    if (series_id %in% out[["series_id"]]) {
      users_series_id <- series_id
      out <- dplyr::filter(out, series_id %in% users_series_id)
    } else {
      warning(
        "`series_id` was provided,",
        "but was not present in the local table and will be ignored."
      )
    }
    return(out)
  }

  if (!is.logical(retain_files)) {
    stop("The `retain_files` argument to `read_abs()` must be TRUE or FALSE.")
  }

  if (is.null(cat_no) & is.null(series_id)) {
    stop(
      "read_abs() requires either an ABS catalogue number,",
      "such as '6202.0' or '6401.0',",
      "or an ABS time series ID like 'A84423127L'."
    )
  }

  if (!is.null(cat_no) & !is.null(series_id)) {
    stop("Please specify either the cat_no OR the series_id, not both.")
  }

  if (!is.null(cat_no)) {
    if (nchar(cat_no) < 6) {
      message(paste0(
        "Please ensure you include the cat_no extension.\n",
        "`read_abs()` will assume you meant \"", cat_no,
        ".0\"", " rather than ", cat_no
      ))
      cat_no <- paste0(cat_no, ".0")
    }
  }

  if (!is.null(cat_no) & is.null(tables)) {
    message(paste0(
      "`tables` not specified;",
      "attempting to fetch all tables from ",
      cat_no
    ))
    tables <- "all"
  }

  if (!is.logical(metadata)) {
    stop("`metadata` argument must be either TRUE or FALSE")
  }

  if (length(release_date) != 1) {
    stop("`release_date` argument must be length 1.")
  }

  # satisfy CRAN
  ProductReleaseDate <- SeriesID <- NULL

  # create a subdirectory of 'path' corresponding to the catalogue number
  # if specified
  if (retain_files && !is.null(cat_no)) {
    .path <- file.path(path, cat_no)
  } else {
    # create temp directory to temporarily store
    # spreadsheets if retain_files == FALSE
    if (!retain_files) {
      .path <- tempdir()
    } else {
      .path <- path
    }
  }

  # check that R has access to the internet
  check_abs_connection()

  # Create URLs to query the ABS Time Series Directory
  xml_urls <- form_abs_tsd_url(
    cat_no = cat_no,
    tables = tables,
    series_id = series_id
  )

  # find spreadsheet URLs from cat_no in the Time Series Directory
  download_message <- ifelse(!is.null(cat_no),
    paste0("catalogue ", cat_no),
    paste0("series ID", series_id)
  )

  message(paste0(
    "Finding URLs for tables corresponding to ABS ",
    download_message
  ))

  xml_dfs <- purrr::map_dfr(xml_urls,
    .f = get_abs_xml_metadata,
    .progress = TRUE
  )

  # Ensure we're not getting spurious matches of table numbers
  if (tables[1] != "all" && is.null(series_id)) {
    xml_dfs <- xml_dfs[match_tables(xml_dfs$TableTitle, tables), ]
  }

  # the same Series ID can appear in multiple spreadsheets;
  # we just want one (the latest)
  if (!is.null(series_id)) {
    xml_dfs <- xml_dfs %>%
      dplyr::group_by(SeriesID) %>%
      dplyr::filter(ProductReleaseDate == max(ProductReleaseDate)) %>%
      dplyr::filter(row_number() == 1) %>%
      dplyr::ungroup()
  } else {
    xml_dfs <- xml_dfs %>%
      dplyr::group_by(.data$TableURL) %>%
      dplyr::filter(.data$ProductReleaseDate == max(.data$ProductReleaseDate)) %>%
      dplyr::filter(.data$ProductReleaseDate == max(.data$ProductReleaseDate)) %>%
      dplyr::ungroup()
  }

  urls <- unique(xml_dfs$TableURL)
  # Remove spaces from URLs
  urls <- gsub(" ", "+", urls)

  if (as.character(release_date) != "latest") {
    requested_date <- format(as.Date(release_date), "%b-%Y")
    urls <- gsub(
      "latest-release",
      tolower(requested_date),
      urls
    )
  }

  table_titles <- unique(xml_dfs$TableTitle)

  # download tables corresponding to URLs
  message(paste0(
    "Attempting to download files from ", download_message,
    ", ", xml_dfs$ProductTitle[1]
  ))

  dl_result <- safely_download_abs(
    urls = urls,
    path = .path,
    show_progress_bars = show_progress_bars
  )

  if (is.null(dl_result$result)) {
    urls <- gsub(".xlsx", ".xls", urls)
    dl_result_xls <- safely_download_abs(
      urls = urls,
      path = .path,
      show_progress_bars = show_progress_bars
    )

    if (!is.null(dl_result_xls$error)) {
      stop("URL ", url, " does not appear to be valid.")
    }
  }

  # extract the sheets to a list
  filenames <- base::basename(urls)
  message("Extracting data from downloaded spreadsheets")
  sheets <- purrr::map2(filenames, table_titles,
    .f = extract_abs_sheets, path = .path,
    .progress = TRUE
  )

  # remove one 'layer' of the list,
  # so that each sheet is its own element in the list
  sheets <- unlist(sheets, recursive = FALSE)

  # tidy the sheets
  sheet <- tidy_abs_list(sheets, metadata = metadata)

  # remove spreadsheets from disk if `retain_files` == FALSE
  if (!retain_files) {
    # delete downloaded files
    file.remove(file.path(.path, filenames))
  }

  # if series_id is specified, remove all other series_ids

  if (!is.null(series_id)) {
    users_series_id <- series_id

    sheet <- sheet %>%
      dplyr::filter(series_id %in% users_series_id)
  }

  # if fst is available, and what has been requested is the full data,
  #  write the result to the <path>/fst/ file
  if (retain_files &&
    is.null(series_id) &&
    identical(tables, "all") &&
    requireNamespace("fst", quietly = TRUE)) {
    fst::write_fst(
      sheet,
      catno2fst(
        cat_no = cat_no,
        path = path
      )
    )
  }

  # return a data frame
  sheet
}

#' @rdname read_abs
#' @export

read_abs_series <- function(series_id, ...) {
  read_abs(
    series_id = series_id,
    ...
  )
}

match_tables <- function(table_list, requested_tables) {
  requested <- paste0(requested_tables, collapse = "|")
  # Looking for table number preceded by a space or a 0, and
  # followed my a full stop or a space
  regex_pattern <- paste0(
    "(?<=\\s|0)",
    "(", requested, ")",
    "(?=\\.|\\s|\\:)"
  )

  predot_matches <- regexpr(".*\\.|.*\\:", table_list)
  table_list_predot <- regmatches(table_list, m = predot_matches)

  grepl(regex_pattern, table_list_predot, perl = TRUE, ignore.case = TRUE)
}
