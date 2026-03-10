# N_C_Collagen_graphs

R toolkit for creating scatter plots of stable carbon (d13C) and nitrogen (d15N) isotope data from bone collagen of domestic animals. Drop any CSV into `data/` and the script generates species scatter plots, diet-category scatter plots, pictogram scatter plots (with animal silhouettes), and descriptive statistics — all in both PNG and SVG.

The bundled dataset is from Makarewicz et al. 2022 (Maidanetske, Ukraine) and contains 45 samples across four species: cattle (*Bos*), goat (*Capra*), sheep (*Ovis*), and pig (*Sus*).

## Repository Structure

| Path | Description |
|---|---|
| `R/run_analysis.R` | Entry point — discovers CSVs in `data/`, generates per-dataset output |
| `R/functions.R` | Reusable functions (data loading, statistics, plotting) |
| `data/` | Input datasets (CSVs with columns: Identifier, Species, d15N, d13C) |
| `assets/` | SVG silhouette images used as plot markers (see [`IMAGE_CREDITS.md`](assets/IMAGE_CREDITS.md)) |
| `output/` | Generated outputs, one subfolder per dataset (git-ignored) |
| `R Workshop.pptx` | Accompanying workshop presentation |

## Prerequisites

- **R** (version 4.0 or later recommended) — download from <https://cran.r-project.org/>
- **RStudio** (optional but recommended for beginners) — download from <https://posit.co/download/rstudio-desktop/>

### Required R Packages

You need to install a few additional R packages **once** before running the script for the first time. Open R or RStudio and paste the following command:

```r
install.packages(c("ggplot2", "dplyr", "writexl", "RColorBrewer",
                    "ggimage", "rsvg", "cowplot"))
```

You will see some download progress in the console. Once it finishes without errors, you are ready to go.

## How to Run

### Option A — Using RStudio (recommended for beginners)

1. **Open RStudio.**
2. Go to **File > Open Project...** (or **File > Open File...**) and navigate to the folder where you downloaded this repository. Open the file `R/run_analysis.R`.
3. Make sure RStudio's working directory is set to the repository root. You can check the current working directory in the console at the bottom. If it shows something else, type the following into the console and press Enter:

   ```r
   setwd("/path/to/N_C_Collagen_graphs")
   ```

   Replace `/path/to/N_C_Collagen_graphs` with the actual path on your computer. On **Windows** this might look like `setwd("C:/Users/YourName/Downloads/N_C_Collagen_graphs")`. On **macOS** it might be `setwd("/Users/YourName/Downloads/N_C_Collagen_graphs")`.

4. Click the **Source** button (top-right of the script editor) to run the entire script, or step through it line by line with **Ctrl+Enter** (Windows) / **Cmd+Enter** (macOS).
5. When the script finishes, look in the `output/` folder for your results.

### Option B — From the terminal / command line

A "terminal" is a text-based interface for running commands. Here is how to open one:

- **macOS:** Open **Terminal** (search for "Terminal" in Spotlight, or find it in Applications > Utilities).
- **Windows:** Open **Command Prompt** (search for "cmd" in the Start menu) or **PowerShell**.

Then type the following commands, pressing Enter after each line:

```bash
cd /path/to/N_C_Collagen_graphs
Rscript R/run_analysis.R
```

Replace `/path/to/N_C_Collagen_graphs` with the actual folder path. For example:

- **macOS:** `cd ~/Downloads/N_C_Collagen_graphs`
- **Windows:** `cd C:\Users\YourName\Downloads\N_C_Collagen_graphs`

The script will print progress messages for each CSV it processes. When it says "Finished", check the `output/` folder for results.

> **Tip:** If you see `Rscript: command not found`, R is either not installed or not on your system PATH. See the [Troubleshooting](#troubleshooting) section below.

## Adding a New Dataset

1. **Prepare your CSV file.** It must contain at least these four columns:

   | Column | Description | Example |
   |---|---|---|
   | `Identifier` | Sample ID (text or number) | `4935` |
   | `Species` | Taxon name (Latin genus) | `Bos`, `Capra`, `Ovis`, `Sus`, `Canis` |
   | `d15N` | delta-15-N isotope value (number) | `7.9` |
   | `d13C` | delta-13-C isotope value (number) | `-20.25` |

   - The column names must be spelled **exactly** as shown (case-sensitive).
   - The delimiter is auto-detected: **semicolons** (`;`), **commas** (`,`), and **tabs** all work.
   - Extra columns beyond these four are fine — they will simply be ignored.
   - Rows with missing or non-numeric isotope values are automatically dropped (the script will tell you how many).

2. **Place the file in the `data/` folder.** The filename will be used to name the output subfolder and derive the site name for plot titles, so something descriptive like `smith_et_al_2024_mysite.csv` works well.

3. **Run the script** (see [How to Run](#how-to-run)). A new subfolder in `output/` will be created automatically.

4. **Pictogram silhouettes:** The pictogram plot shows animal silhouettes for the following species: *Bos* (cattle), *Capra* (goat), *Ovis* (sheep), *Sus* (pig), and *Canis* (dog). Species that match one of these names get a silhouette marker; all other species still appear in the basic scatter plots (Plot 1 and Plot 2) but not in the pictogram. To add a silhouette for a new species, place an SVG file in `assets/` and add the mapping in `R/functions.R` (see `SPECIES_SVG_MAP` and `SPECIES_COLORS` at the top of that file).

## Output

For each CSV the script produces a subfolder under `output/`:

| File | Contents |
|---|---|
| `species_scatter.png` / `.svg` | Scatter plot colored and shaped by species |
| `diet_scatter.png` / `.svg` | Scatter plot grouped by dietary category |
| `pictogram_scatter.png` / `.svg` | Scatter plot with animal silhouettes as markers |
| `summary.csv` / `.xlsx` | Descriptive statistics (count, mean, sd, range per species) |

If a CSV contains species that have no matching SVG silhouette, the pictogram plot is still generated but only includes the species with silhouettes. If no species match at all, the pictogram plot is skipped.

## Troubleshooting

### "Rscript: command not found"

R is not installed, or the `Rscript` executable is not on your system PATH.

- **Install R** from <https://cran.r-project.org/>. On the download page, pick the installer for your operating system and follow the instructions.
- **macOS:** If you installed R but still get this error, try running it with the full path: `/usr/local/bin/Rscript R/run_analysis.R`. Alternatively, use RStudio instead (see [Option A](#option-a--using-rstudio-recommended-for-beginners)).
- **Windows:** The R installer usually adds R to your PATH automatically. If not, you can find `Rscript.exe` in a folder like `C:\Program Files\R\R-4.x.x\bin\` and either add that folder to your PATH or use RStudio.

### "there is no package called 'XYZ'"

One or more required R packages are not installed. Run the install command from the [Prerequisites](#required-r-packages) section:

```r
install.packages(c("ggplot2", "dplyr", "writexl", "RColorBrewer",
                    "ggimage", "rsvg", "cowplot"))
```

If a single package fails to install, try installing it individually: `install.packages("ggimage")`. On Linux, some packages (notably `rsvg`) require system libraries — check the error message for hints.

### "No CSV files found in data/"

The script looks for `.csv` files inside the `data/` folder. Make sure:

- Your file is saved with a `.csv` extension (not `.xlsx`, `.xls`, or `.txt`).
- The file is inside the `data/` folder, not in the repository root or another subfolder.
- You are running the script from the repository root directory. If you are in the wrong directory, the script cannot find `data/`. See the [How to Run](#how-to-run) section.

### "CSV is missing required columns: ..."

The script could not find one or more of the four required columns (`Identifier`, `Species`, `d15N`, `d13C`). Common causes:

- **Wrong delimiter:** The script auto-detects semicolons, commas, and tabs, but if your file uses an unusual separator (e.g., pipes `|`), the columns will not be parsed correctly.
- **Typos in column names:** The names are case-sensitive. `species` or `D15N` will not match. Check the very first line of your CSV.
- **File is not actually a CSV:** If you exported from Excel, make sure you chose "CSV (Comma delimited)" or "CSV UTF-8" as the format, not the default `.xlsx`.

The error message will also list the columns that *were* found, which can help you spot the issue.

### "No usable rows remain after cleaning"

Every row in the CSV had missing or non-numeric isotope values. Check that:

- The `d15N` and `d13C` columns actually contain numbers (not text like "n/a" or "pending").
- Decimal separators are periods (`.`), not commas (`,`). In some European locales, Excel exports `7,9` instead of `7.9` — this will fail. Re-export with period decimals or find-and-replace commas with periods in the numeric columns.
- The file is not completely empty apart from the header row.

### "cannot open the connection" / file not found errors

The script uses relative paths, so it **must** be run from the repository root folder. If you run it from a different directory, it will not find the `data/`, `assets/`, or `R/` folders.

- **In RStudio:** Check your working directory with `getwd()`. Change it with `setwd("/path/to/N_C_Collagen_graphs")`.
- **In the terminal:** Make sure you `cd` into the repository folder before running `Rscript R/run_analysis.R`.

### Plots look empty or have very few data points

The script drops rows where `d15N` or `d13C` is missing or non-numeric. When this happens, it prints a message like *"Dropped 12 row(s) with missing isotope values"*. Check the console output for these warnings.

If you expected more data points, open your CSV in a text editor and verify that the numeric columns contain actual numbers, not blanks or text.

### A species does not appear in the pictogram plot

The pictogram plot only shows species that have a matching SVG silhouette in `assets/`. Currently supported: *Bos*, *Capra*, *Ovis*, *Sus*, and *Canis*.

If your data uses a different species name (e.g., `Cattle` instead of `Bos`), either rename the values in your CSV to the Latin genus name, or add a new entry to the `SPECIES_SVG_MAP` in `R/functions.R`.

All species — regardless of whether they have a silhouette — always appear in the species scatter plot and diet scatter plot.

### Garbled characters or encoding problems

If species names or identifiers contain special characters (accents, umlauts, etc.) and they appear garbled in the output, your CSV may not be saved as UTF-8. Re-export it from your spreadsheet application and explicitly select **UTF-8** encoding. In Excel: *Save As > CSV UTF-8 (Comma delimited)*.

### "ERROR processing some_file.csv: ..."

If one CSV file has problems, the script will print an error message for that file and then continue with the remaining files. Check the error message for details (it usually includes one of the messages described above). Fix the problematic CSV and re-run.

## Credits

- **Data:** Makarewicz, C. A. et al. (2022) — Maidanetske collagen isotope dataset.
- **Animal silhouettes** (see [`assets/IMAGE_CREDITS.md`](assets/IMAGE_CREDITS.md) for full details):
  - *Cattle* — [PhyloPic](https://www.phylopic.org/images/8a2d5863-cd6c-4158-a164-d62e789c2210), CC0 1.0
  - *Sheep* — [OpenClipart](https://openclipart.org/detail/265718/detailed-sheep-silhouette), Public Domain
  - *Goat* — [PhyloPic](https://www.phylopic.org/images/c39a1d31-eb36-4b62-ba4d-32e29e0e5a8d) (Steven Traver), CC0 1.0
  - *Pig* — [OpenClipart / freesvg.org](https://freesvg.org/1548546245), Public Domain
  - *Dog* — [PhyloPic](https://www.phylopic.org/images/d149744f-8330-46df-8683-fcd4b385aa07) (An Ignorant Atheist), CC0 1.0
