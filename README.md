# Race Comparison: Animated GPS Plots from Garmin `.fit` Files

This project plots animated GPS coordinates from Garmin `.fit` files to compare activities or races on the same route using R.

---

## 📁 Project Structure

| Folder                  | Description                                  |
|--------------------------|----------------------------------------------|
| `R/`                    | Custom R functions                           |
| `config/`               | Input parameters (e.g., YAML)                |
| `scripts/`              | Main analysis scripts                        |
| `reports/`              | Knitted `.html` or `.Rmd` reports            |
| `figures/`              | Plotting logic                               |
| `data/raw/`             | Raw `.fit` files (not tracked by Git)        |
| `data/processed/`       | Cleaned and processed GPS data               |
| `data/plots_rds/`       | Saved `ggplot` objects for reuse             |
| `Output/final_figures/` | Final publication-ready plots (e.g., PNGs)   |
| `Output/temp/`          | Temporary plots (ignored via `.gitignore`)   |
| `renv/`                 | Environment metadata (auto-managed)          |

---

##️ Setup Instructions

1. Clone the repository.
2. Open the R project in RStudio.
3. If `renv` is not installed, run:
   ```r
   install.packages("renv")
   ```
4. Restore the exact package versions used:
   ```r
   renv::restore()
   ```
5. Add your [Mapbox](https://www.mapbox.com/) token to your `.Renviron` or R session:
   ```r
   Sys.setenv(MAPBOX_TOKEN = "your_token_here")
   ```

---

## How to Run

1. Go to the [Garmin Connect website](https://connect.garmin.com/).
2. Select an activity > click the ⚙️ gear icon > choose **Export as `.fit`**.
3. Unzip and move the `.fit` file(s) into `data/raw/`.
4. Open and configure the YAML file in `config/` to select activities to compare.
5. Run the main pipeline script:
   ```r
   source("scripts/race_comp_pipeline_v3.R")
   ```

### To Create GIFs from Screen Recordings

Use a screen recording tool, then upload the video to:
[https://ezgif.com/video-to-gif](https://ezgif.com/video-to-gif)

---

## Script Version History

- **v1**: Initial setup
- **v2**:
  - YAML-based configuration
  - Supports >2 `.fit` files
- **v3**:
  - Modularized functions moved to `R/`
  - Code cleaned and reorganized

---

## Requirements

- Mapbox account (free tier is sufficient)
- Internet connection for tile rendering
- Garmin `.fit` file exports

---

## Notes

- Raw data is **not tracked in Git**. Place `.fit` files into `data/raw/`.
- Final plots are generated in `Output/final_figures/`
