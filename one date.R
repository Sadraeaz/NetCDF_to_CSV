# ============================================================
# Extract SWI (Soil Water Index) values at fixed sites from a NetCDF file (1 image == 1 date) over northern Italy
# ============================================================

# --- Libraries ------------------------------------------------
library(ncdf4)
library(tidyverse)
library(RANN)   # Nearest-neighbour search

# --- Site coordinates ----------------------------------------
sites <- tibble(
  site = c("Sanpietro", "Ceregnano", "Legnaro", "Landriano"), # 4 northern Italy sites, as an example
  lon  = c(11.623616, 11.851802, 11.952149, 9.267466),
  lat  = c(44.65368, 45.05828, 45.34737, 45.32167)
)

points_of_interest <- sites %>%
  select(lon, lat)

# --- NetCDF input --------------------------------------------
nc_path <- "path/to/your/file.nc"   # <-- set your file path here
nc <- nc_open(nc_path)

# --- Read dimensions -----------------------------------------
lon  <- ncvar_get(nc, "lon")
lat  <- ncvar_get(nc, "lat")
time <- ncvar_get(nc, "time")

time_units <- ncatt_get(nc, "time", "units")
dates <- as.Date(time, origin = "1970-01-01")

# --- Read variable -------------------------------------------
swi <- ncvar_get(nc, "SWI_002")   # change variable name if needed
nc_close(nc)

# --- Convert to long format ----------------------------------
grid <- expand.grid(lon = lon, lat = lat)

swi_df <- tibble(
  lon   = grid$lon,
  lat   = grid$lat,
  value = as.vector(swi)
) %>%
  drop_na() %>%
  mutate(
    value = as.numeric(value),
    value = ifelse(value > 200, NA, value),
    value = value * 0.5
  ) %>%
  drop_na()

# --- Nearest neighbour extraction -----------------------------
nn <- nn2(
  data  = swi_df[, c("lon", "lat")],
  query = points_of_interest,
  k = 1
)

extracted_values <- swi_df$value[nn$nn.idx]

# --- Final data frame ----------------------------------------
output_df <- tibble(
  Date = dates
) %>%
  bind_cols(as_tibble(t(extracted_values))) %>%
  setNames(c("Date", sites$site))

# --- Export ---------------------------------------------------
output_file <- paste0(format(dates, "%Y-%m-%d"), ".csv")
write.csv(output_df, output_file, row.names = FALSE)
