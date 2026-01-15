# NetCDF_to_CSV
Converting NetCDF soil moisture image(s) to CSV.

## Extract SWI at Fixed Sites from NetCDF

This script extracts SWI values from a NetCDF file(s) at predefined sites
locations using nearest-neighbour matching.

### Requirements
- R
- ncdf4
- tidyverse
- RANN

### Usage
1. Set the NetCDF file path in `nc_path`
2. Run `one date.R`
3. Output CSV is created per time step

