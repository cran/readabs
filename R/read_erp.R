#' Download a tidy tibble containing the Estimated Residential Population from the ABS
#'
#' \code{read_erp()} uses the \code{read_abs()} function to download, import,
#' and tidy the Estimated Residential Population from the ABS. It allows the user
#' to specify age, sex and states/territories of interest. It returns a tibble
#' containing five columns: the date, the age range, sex and states that the ERP
#' corresponds to. This makes joining the ERP to another dataframe easy.
#'
#' @param age_range numeric; default is "0:100". A vector containing ages in single
#' years for which an ERP is sought. The ABS top-code ages at 100.
#'
#' @param sex character; default is "Persons". Other values are "Male" and
#' "Female". Multiple values allowed.
#'
#' @param states character; default is "Australia". Other values are the full
#' or abbreviated names of the states and self-governing territories. Multiple
#' values allowed.
#'
#' @param path character; default is "data/ABS". Only used if
#' retain_files is set to TRUE. Local directory in which to save
#' downloaded ABS time series spreadsheets.
#'
#' @param show_progress_bars logical; TRUE by default. If set to FALSE, progress
#' bars will not be shown when ABS spreadsheets are downloading.
#'
#' @param check_local logical; FALSE by default. See \code{?read_abs}.
#'
#' @param retain_files logical; FALSE by default. When TRUE, the spreadsheets
#' downloaded from the ABS website will be saved in the
#' directory specified with 'path'.
#'
#' @examples
#' \donttest{
#' # Create a tibble called 'erp' that contains the ERP index
#' # numbers for 30 June each year for Australia.
#'
#' erp <- read_erp()
#' }
#'
#' @importFrom dplyr filter select tibble mutate group_by summarise arrange
#' @importFrom tools toTitleCase
#'
#' @export

read_erp <- function(age_range = 0:100,
                     sex = "Persons",
                     states = c(
                       "Australia", "New South Wales", "Victoria", "Queensland",
                       "South Australia", "Western Australia", "Tasmania",
                       "Northern Territory", "Australian Capital Territory"
                     ),
                     path = Sys.getenv("R_READABS_PATH", unset = tempdir()),
                     show_progress_bars = TRUE,
                     check_local = FALSE,
                     retain_files = FALSE) {
  if (!is.numeric(age_range)) {
    stop("The age_range argument must be a numeric vector.")
  }

  # Check if all elements are integers
  if (any(age_range != as.integer(age_range))) {
    stop("All elements in age_range must be integers.")
  }

  # Check if all elements are between 0 and 100
  if (any(age_range < 0 | age_range > 100)) {
    stop("All elements in age_range must be between 0 and 100.")
  }

  # Restrict the 'sex' argument to the valid choices
  sex <- match.arg(sex,
    c("Persons", "Male", "Female"),
    several.ok = TRUE
  )

  # Restrict the states argument to valid choices but include abbreviations
  # Always return the full name if an abbreviation has been used.
  stes <- purrr::map_chr(states, validate_state_erp)

  if (!is.logical(retain_files)) {
    stop("`retain_files` must be either `TRUE` or `FALSE`.")
  }

  if (!is.logical(show_progress_bars)) {
    stop("`show_progress_bars` must be either `TRUE` or `FALSE`")
  }

  if (retain_files == TRUE & !is.character(path)) {
    stop(
      "If `retain_files` is `TRUE`,",
      " you must specify a valid file path in `path`."
    )
  }

  state_lookup <- erp_state_lookup()
  ste_tbls <- state_lookup$tbl_n[state_lookup$full_name %in% stes]

  erp_raw <- read_abs(
    cat_no = "3101.0",
    tables = ste_tbls,
    retain_files = retain_files,
    check_local = check_local,
    show_progress_bars = show_progress_bars,
    path = path
  )

  x <- tidy_erp(
    erp_raw,
    age_range,
    sex
  )

  x
}

#' @keywords internal
# Tidy a table of ERP data downloaded with read_abs(cat_no = "3101.0")
# x <- read_abs(cat_no = "3101.0")
# tidy_erp(x)
tidy_erp <- function(erp_raw,
                     age_range,
                     sex) {
  erp_raw %>%
    dplyr::mutate(
      age = gsub("[^0-9]", "", .data$series),
      age = as.integer(.data$age),
      series_sex = gsub(".*;\\s*(Male|Female|Persons)\\s*;.*", "\\1", .data$series),
      state = trimws(gsub(".*,(\\s*[^,]+)$", "\\1", .data$table_title))
    ) %>%
    dplyr::filter(
      .data$age %in% age_range,
      .data$series_sex %in% sex
    ) %>%
    dplyr::group_by(.data$date, .data$series_sex, .data$state, .data$age) %>%
    dplyr::summarise(erp = sum(.data$value)) %>%
    dplyr::ungroup() %>%
    dplyr::arrange(.data$state, .data$series_sex, .data$age, .data$date) %>%
    dplyr::select("date", "state",
      sex = "series_sex",
      "erp", "age"
    )
}

#' @keywords internal
#' @noRd
erp_state_lookup <- function() {
  # Lookup table of state/territory names, abbreviations and ABS ERP table numbers
  state_lookup <- tibble(
    full_name = c(
      "Australia", "New South Wales", "Victoria", "Queensland",
      "South Australia", "Western Australia", "Tasmania",
      "Northern Territory", "Australian Capital Territory"
    ),
    abbrev = c("Aus", "NSW", "Vic", "Qld", "SA", "WA", "Tas", "NT", "ACT"),
    tbl_n = c(59, 51:58)
  )
}

# Ensure that user specified state/territory names are acceptable. Allow full
# names or abbreviations. Throw an error if they are incorrect.
# Always return the full name.
#' @keywords internal
#' @noRd
#'

validate_state_erp <- function(state) {
  state_lookup <- erp_state_lookup()

  # Define valid states and their abbreviations
  valid_states <- state_lookup$full_name
  valid_abbreviations <- state_lookup$abbrev

  # Allow trailing periods in abbreviations
  valid_abbreviations_with_period <- paste0(valid_abbreviations, ".")

  # Combine all valid inputs
  all_valid_inputs <- c(
    valid_states,
    valid_abbreviations,
    valid_abbreviations_with_period,
    toupper(valid_abbreviations),
    tolower(valid_abbreviations)
  )

  # Create a lookup table (map all variants to full state names)
  state_map <- stats::setNames(
    rep(valid_states, times = 5),
    all_valid_inputs
  )

  # Standardize input to lowercase and remove trailing periods in case
  # people do things like "Vic." or "Tas."
  state_cleaned <- gsub("\\.$", "", state) # Remove trailing period
  state_cleaned <- tolower(state_cleaned) # Convert to lowercase

  # Create a cleaned version of the map for case-insensitive matching
  names(state_map) <- tolower(names(state_map))

  # Check if the input matches a valid state or abbreviation
  if (!state_cleaned %in% names(state_map)) {
    stop("Invalid state. Please use a valid state name or abbreviation.")
  }

  # Return the standard full state name
  return(unname(tools::toTitleCase(state_map[state_cleaned])))
}
