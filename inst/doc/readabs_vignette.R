## ----setup, echo = FALSE, message = FALSE-------------------------------------
library(knitr)
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.path = "VIGNETTE-"
)

set.seed(42)

## ----out.width = "100%", echo = FALSE-----------------------------------------
include_graphics("VIGNETTE-ts-example.png")

## ----out.width = "100%", echo = FALSE-----------------------------------------
include_graphics("VIGNETTE-spreadsheet-screenshot.png")

## ----library, message=FALSE---------------------------------------------------
library(readabs)
library(dplyr)
library(ggplot2)

## ----read-wpi-all, eval = FALSE-----------------------------------------------
# wpi <- read_abs("6345.0")

## ----create-local-wpi, include=FALSE, eval=FALSE------------------------------
# wpi <- read_abs("6345.0")
# wpi <- head(wpi)
# saveRDS(wpi, "wpi.rds")

## ----load-local-wpi, include = FALSE------------------------------------------
wpi <- readRDS("wpi.rds")

## ----glimpse-wpi--------------------------------------------------------------
head(wpi)

## ----create-local-lfs, include=FALSE, eval=FALSE------------------------------
# lfs_1 <- read_abs("6202.0", tables = 1)
# lfs_1 <- head(lfs_1)
# saveRDS(lfs_1, "lfs_1.rds")
# 
# lfs_5 <- read_abs("6202.0", tables = 5)
# # lfs_5 <- head(lfs_5)
# saveRDS(lfs_5, "lfs_5.rds")

## ----read-local-lfs_1, include=FALSE------------------------------------------
lfs_1 <- readRDS("lfs_1.rds")

## ----read-lfs-1, eval = FALSE-------------------------------------------------
# lfs_1 <- read_abs("6202.0", tables = 1)

## ----glimpse_lfs_1------------------------------------------------------------
head(lfs_1)

## ----read-local-lfs_1_t, include=FALSE----------------------------------------
lfs_5 <- readRDS("lfs_5.rds")
lfs_1_5 <- bind_rows(lfs_1, lfs_5)

## ----read-lfs-1-5, eval=FALSE-------------------------------------------------
# lfs_1_5 <- read_abs("6202.0", tables = c(1, 5))

## ----glimpse_lfs_1_5----------------------------------------------------------
head(lfs_1_5)

## ----create-local-seriesid, eval=FALSE, include=FALSE-------------------------
# employed <- read_abs(series_id = "A84423127L")
# employed <- head(employed)
# saveRDS(employed, "employed.rds")

## ----read-local-seriesid, include = FALSE-------------------------------------
employed <- readRDS("employed.rds")

## ----read-abs-seriesid, eval = FALSE------------------------------------------
# employed <- read_abs(series_id = "A84423127L")

## ----glimpse-seriesid---------------------------------------------------------
head(employed)

unique(employed$series)

## ----examine-lfs--------------------------------------------------------------
unique(lfs_1$series)

## ----separate-series----------------------------------------------------------
lfs_1_sep <- lfs_1 %>%
  separate_series()

lfs_1_sep %>%
  group_by(series_1, series_2) %>%
  summarise()

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
unemp %>%
  filter(series_type == "Seasonally Adjusted") %>%
  mutate(sex = series_2) %>%
  ggplot(aes(x = date, y = value, col = sex)) +
  geom_line() +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    axis.title = element_blank(),
    legend.title = element_blank(),
    text = element_text(size = 5)
  ) +
  labs(
    title = "The male and female unemployment rates have converged",
    subtitle = "Unemployment rates for Australian men and women (aged 15+), 1978-2018 (per cent)",
    caption = "Source: ABS 6202.0"
  )

## ----read-lfs-local-catno, eval = FALSE---------------------------------------
# lfs_local_1 <- read_abs_local("6202.0")

## ----eval = FALSE-------------------------------------------------------------
# search_catalogues("labour force")

## ----eval = FALSE, include = FALSE--------------------------------------------
# cats <- search_catalogues("labour force")
# saveRDS(cats, "cats.rds")

## ----echo = FALSE-------------------------------------------------------------
readRDS("cats.rds")

## ----eval = FALSE-------------------------------------------------------------
# search_files("GM1", "labour-force-australia")

## ----echo = FALSE-------------------------------------------------------------
x <- "GM1.xlsx"
x

## ----eval=FALSE---------------------------------------------------------------
# gm1_path <- download_abs_data_cube("labour-force-australia", "GM1")
# 
# print(gm1_path)

## ----include=FALSE------------------------------------------------------------
print("/var/folders/_4/ngvkm2811nbd8b_v66wytw1r0000gn/T//RtmpZT2ffU/GM1.xlsx")

## ----eval=FALSE, include=FALSE------------------------------------------------
# gf <- read_lfs_grossflows()
# gf <- head(gf)
# saveRDS(gf, "gf.rds")

## ----include=FALSE------------------------------------------------------------
gf <- readRDS("gf.rds")

## ----eval=FALSE---------------------------------------------------------------
# gf <- read_lfs_grossflows()

## -----------------------------------------------------------------------------
head(gf)

## ----eval=FALSE, include=FALSE------------------------------------------------
# payrolls <- read_payrolls("sa3_jobs")
# payrolls <- head(payrolls)
# saveRDS(payrolls, "payrolls.rds")

## ----include=FALSE------------------------------------------------------------
payrolls <- readRDS("payrolls.rds")

## ----eval=FALSE---------------------------------------------------------------
# payrolls <- read_payrolls()

## -----------------------------------------------------------------------------
head(payrolls)

