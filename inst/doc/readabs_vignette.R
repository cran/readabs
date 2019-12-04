## ----setup, echo = FALSE, message = FALSE-------------------------------------
library(knitr)
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.path = "VIGNETTE-")

set.seed(42)


## ----out.width = "100%", echo = FALSE-----------------------------------------
include_graphics("VIGNETTE-spreadsheet-screenshot.png")

## ----read-wpi-all-------------------------------------------------------------
library(readabs)

wpi <- read_abs("6345.0")

## ----glimpse-wpi--------------------------------------------------------------
library(dplyr)

glimpse(wpi)

## ----read-lfs-1---------------------------------------------------------------

lfs_1 <- read_abs("6202.0", tables = 1)

glimpse(lfs_1)


## ----read-lfs-1-5-------------------------------------------------------------

lfs_1_5 <- read_abs("6202.0", tables = c(1, 5))

glimpse(lfs_1_5)


## ----examine-lfs--------------------------------------------------------------
unique(lfs_1$series)

## ----separate-series----------------------------------------------------------
lfs_1_sep <- lfs_1 %>% 
  separate_series()

lfs_1_sep


## ----create-unemp-df----------------------------------------------------------

unemp <- lfs_1_sep %>%
  filter(series_1 == "Unemployment rate")

unique(unemp$series_1)

unique(unemp$series_2)


## ----filter-male-female-------------------------------------------------------

unemp <- unemp %>%
  filter(series_2 %in% c("Males", "Females"))

unique(unemp$series_2)

## ----graph-unemp, dpi = 200---------------------------------------------------
library(ggplot2)

unemp %>%
  filter(series_type == "Seasonally Adjusted") %>%
  mutate(sex = series_2) %>%
  ggplot(aes(x = date, y = value, col = sex)) +
  geom_line() +
  theme_minimal() +
  theme(legend.position = "bottom",
        axis.title = element_blank(),
        legend.title = element_blank(),
        text = element_text(size = 5)) +
  labs(title = "The male and female unemployment rates have converged",
       subtitle = "Unemployment rates for Australian men and women (aged 15+), 1978-2018 (per cent)",
       caption = "Source: ABS 6202.0")

## ----read-abs-seriesid--------------------------------------------------------

employed <- read_abs(series_id = "A84423127L")

glimpse(employed)

unique(employed$series)

## ----out.width = "100%", echo = FALSE-----------------------------------------
include_graphics("VIGNETTE-6202-screenshot.png")

## ----current_path-------------------------------------------------------------
current_path <- Sys.getenv("R_READABS_PATH")
if (!nzchar(current_path)) {
  current_path <- tempdir()
}

## ----read-lfs-local-catno-----------------------------------------------------
lfs_local_1 <- read_abs_local("6202.0")

## ----read-lfs-local-----------------------------------------------------------
lfs_local_2 <- read_abs_local(filenames = c("6202001.xls", "6202005.xls"),
                              path = file.path(current_path, "6202.0"))

