library(ggplot2)
library(dplyr)
library(writexl)
library(RColorBrewer)
library(ggimage)
library(rsvg)
library(cowplot)

# ---------------------------------------------------------------------------
# Species-to-SVG and species-to-colour defaults
# ---------------------------------------------------------------------------

SPECIES_SVG_MAP <- c(
  Bos   = "cattle.svg",
  Capra = "goat.svg",
  Ovis  = "sheep.svg",
  Sus   = "pig.svg",
  Canis = "dog.svg"
)

SPECIES_COLORS <- c(
  Bos   = "#F8766D",
  Capra = "#7CAE00",
  Ovis  = "#00BFC4",
  Sus   = "#C77CFF",
  Canis = "#E68A00"
)

DIET_GROUPS <- list(
  pigs        = "Sus",
  cattle      = "Bos",
  ovicaprines = c("Capra", "Ovis"),
  dogs        = "Canis"
)

# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------

detect_delimiter <- function(csv_path) {
  first_line <- readLines(csv_path, n = 1, warn = FALSE)
  counts <- c(
    ";" = nchar(gsub("[^;]", "", first_line)),
    "," = nchar(gsub("[^,]", "", first_line)),
    "\t" = nchar(gsub("[^\t]", "", first_line))
  )
  best <- names(which.max(counts))
  if (counts[best] == 0) best <- ";"
  label <- c(";" = "semicolon", "," = "comma", "\t" = "tab")
  message("  Detected delimiter: ", label[best], " (", best, ")")
  best
}

load_collagen_data <- function(csv_path) {
  if (!file.exists(csv_path)) {
    stop("File not found: ", csv_path)
  }

  sep <- detect_delimiter(csv_path)
  df  <- read.csv(csv_path, sep = sep, header = TRUE,
                   stringsAsFactors = FALSE, strip.white = TRUE)

  names(df) <- trimws(names(df))

  required <- c("Identifier", "Species", "d15N", "d13C")
  missing  <- setdiff(required, names(df))
  if (length(missing) > 0) {
    stop("CSV is missing required columns: ", paste(missing, collapse = ", "),
         "\n  Columns found: ", paste(names(df), collapse = ", "),
         "\n  Hint: check that your file uses a supported delimiter ",
         "(semicolon, comma, or tab) and that column names are spelled ",
         "exactly: Identifier, Species, d15N, d13C")
  }

  df$Species <- trimws(df$Species)

  blank_rows <- which(trimws(df$Identifier) == "" &
                      trimws(df$Species) == "" &
                      trimws(as.character(df$d15N)) %in% c("", "NA") &
                      trimws(as.character(df$d13C)) %in% c("", "NA"))
  if (length(blank_rows) > 0) {
    df <- df[-blank_rows, ]
    message("  Dropped ", length(blank_rows), " completely empty row(s).")
  }

  original_d15N <- df$d15N
  original_d13C <- df$d13C
  df$d15N <- suppressWarnings(as.numeric(df$d15N))
  df$d13C <- suppressWarnings(as.numeric(df$d13C))

  bad_d15N <- sum(is.na(df$d15N) & !is.na(original_d15N) &
                  trimws(as.character(original_d15N)) != "")
  bad_d13C <- sum(is.na(df$d13C) & !is.na(original_d13C) &
                  trimws(as.character(original_d13C)) != "")
  if (bad_d15N > 0)
    warning("  ", bad_d15N, " d15N value(s) could not be converted to numbers ",
            "and were set to NA.", call. = FALSE)
  if (bad_d13C > 0)
    warning("  ", bad_d13C, " d13C value(s) could not be converted to numbers ",
            "and were set to NA.", call. = FALSE)

  incomplete <- is.na(df$d15N) | is.na(df$d13C)
  n_dropped  <- sum(incomplete)
  if (n_dropped > 0) {
    df <- df[!incomplete, ]
    message("  Dropped ", n_dropped, " row(s) with missing isotope values ",
            "(both d15N and d13C are required for plotting).")
  }

  if (nrow(df) == 0) {
    stop("No usable rows remain after cleaning. ",
         "Check that your d15N and d13C columns contain numeric values.")
  }

  message("  Loaded ", nrow(df), " rows across ",
          length(unique(df$Species)), " species: ",
          paste(unique(df$Species), collapse = ", "))
  df
}

# ---------------------------------------------------------------------------
# Descriptive statistics
# ---------------------------------------------------------------------------

compute_summary <- function(df) {
  df %>%
    group_by(Species) %>%
    summarise(
      count      = n(),
      mean_d15N  = mean(d15N, na.rm = TRUE),
      mean_d13C  = mean(d13C, na.rm = TRUE),
      sd_d15N    = sd(d15N, na.rm = TRUE),
      sd_d13C    = sd(d13C, na.rm = TRUE),
      range_d15N = paste0(min(d15N, na.rm = TRUE), " to ",
                          max(d15N, na.rm = TRUE)),
      range_d13C = paste0(min(d13C, na.rm = TRUE), " to ",
                          max(d13C, na.rm = TRUE)),
      .groups = "drop"
    )
}

# ---------------------------------------------------------------------------
# Plot 1 — species scatter
# ---------------------------------------------------------------------------

plot_species_scatter <- function(df, title, subtitle) {
  n_species <- length(unique(df$Species))
  shapes    <- c(15, 16, 17, 25, 18, 8, 3, 4)[seq_len(n_species)]

  ggplot(df, aes(x = d13C, y = d15N)) +
    geom_point(aes(colour = Species, shape = Species), size = 5) +
    scale_color_brewer(palette = "Dark2") +
    scale_shape_manual(values = shapes) +
    theme_bw(base_size = 10, base_family = "serif") +
    xlab(expression(delta^13 * C ~ "(\u2030)")) +
    ylab(expression(delta^15 * N ~ "(\u2030)")) +
    labs(title = title, subtitle = subtitle) +
    theme(
      legend.position = "right",
      legend.title    = element_text(),
      axis.title      = element_text(family = "sans", face = "bold", size = 15),
      axis.text       = element_text(family = "sans", size = 12)
    )
}

# ---------------------------------------------------------------------------
# Plot 2 — diet-category scatter
# ---------------------------------------------------------------------------

add_diet_categories <- function(df, groups = DIET_GROUPS) {
  species_to_cat <- character()
  for (cat_name in names(groups)) {
    for (sp in groups[[cat_name]]) {
      species_to_cat[sp] <- cat_name
    }
  }
  df %>% mutate(categories = ifelse(
    Species %in% names(species_to_cat),
    species_to_cat[Species],
    "unestimated"
  ))
}

plot_diet_scatter <- function(df, title, subtitle, groups = DIET_GROUPS) {
  df_cat     <- add_diet_categories(df, groups)
  n_cats     <- length(unique(df_cat$categories))
  shapes     <- c(15, 16, 17, 25, 18, 8, 3, 4)[seq_len(n_cats)]

  ggplot(df_cat, aes(x = d13C, y = d15N)) +
    geom_point(aes(colour = categories, shape = categories), size = 5) +
    scale_color_brewer(palette = "Dark2") +
    scale_shape_manual(values = shapes) +
    theme_bw(base_size = 10, base_family = "sans") +
    xlab(expression(delta^13 * C ~ "(\u2030)")) +
    ylab(expression(delta^15 * N ~ "(\u2030)")) +
    labs(title = title, subtitle = subtitle) +
    theme(
      legend.position = "right",
      legend.title    = element_text(),
      axis.title      = element_text(family = "sans", face = "bold", size = 15),
      axis.text       = element_text(family = "sans", size = 12)
    )
}

# ---------------------------------------------------------------------------
# Plot 3 — pictogram scatter with custom silhouette legend
# ---------------------------------------------------------------------------

plot_pictogram <- function(df, title, assets_dir,
                           svg_map = SPECIES_SVG_MAP,
                           colors  = SPECIES_COLORS) {
  available <- svg_map[file.exists(file.path(assets_dir, svg_map))]
  matched   <- intersect(names(available), unique(df$Species))
  if (length(matched) == 0) return(NULL)

  img_paths <- setNames(
    file.path(assets_dir, available[matched]),
    matched
  )
  colors <- colors[matched]

  df_img <- df %>%
    filter(Species %in% matched) %>%
    mutate(image = img_paths[Species])

  p_main <- ggplot(df_img, aes(x = d13C, y = d15N)) +
    ggimage::geom_image(aes(image = image, colour = Species), size = 0.05) +
    scale_colour_manual(values = colors) +
    ggtitle(title) +
    xlab(expression(delta^13 * C ~ "(\u2030)")) +
    ylab(expression(delta^15 * N ~ "(\u2030)")) +
    theme_bw(base_size = 14, base_family = "sans") +
    theme(
      legend.position = "none",
      plot.title      = element_text(face = "bold", size = 16),
      axis.title      = element_text(face = "bold", size = 14),
      axis.text       = element_text(size = 12),
      plot.margin     = margin(10, 5, 10, 10)
    )

  n        <- length(matched)
  y_vals   <- seq(4, by = -0.5, length.out = n)
  legend_df <- data.frame(
    Species = factor(matched, levels = matched),
    x       = rep(0, n),
    y       = y_vals,
    image   = unname(img_paths[matched]),
    stringsAsFactors = FALSE
  )

  p_legend <- ggplot(legend_df, aes(x = x, y = y)) +
    ggimage::geom_image(aes(image = image, colour = Species), size = 0.06) +
    scale_colour_manual(values = colors)

  for (i in seq_len(n)) {
    p_legend <- p_legend +
      annotate("text", x = 0.20, y = y_vals[i], label = matched[i],
               hjust = 0, fontface = "italic", family = "sans", size = 3.8)
  }

  y_top <- max(y_vals) + 0.30
  y_bot <- min(y_vals) - 0.40

  p_legend <- p_legend +
    annotate("text", x = -0.18, y = y_top, label = "Species",
             hjust = 0, fontface = "bold", family = "sans", size = 4) +
    coord_cartesian(xlim = c(-0.3, 0.7), ylim = c(y_bot, y_top + 0.20)) +
    theme_void() +
    theme(
      legend.position  = "none",
      panel.background = element_rect(fill = "white", colour = NA),
      plot.background  = element_rect(fill = "white", colour = NA)
    )

  cowplot::plot_grid(p_main, p_legend, nrow = 1, rel_widths = c(5.5, 0.8))
}

# ---------------------------------------------------------------------------
# Saving outputs
# ---------------------------------------------------------------------------

save_outputs <- function(summary_df, plots, output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  writexl::write_xlsx(summary_df, file.path(output_dir, "summary.xlsx"))
  write.csv(summary_df, file.path(output_dir, "summary.csv"), row.names = FALSE)

  for (name in names(plots)) {
    p <- plots[[name]]
    if (is.null(p)) next
    width  <- if (name == "pictogram_scatter") 12 else 10
    ggsave(file.path(output_dir, paste0(name, ".png")),
           plot = p, width = width, height = 8, dpi = 300)
    ggsave(file.path(output_dir, paste0(name, ".svg")),
           plot = p, width = width, height = 8, dpi = 300)
  }
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

derive_site_name <- function(csv_path) {
  base <- tools::file_path_sans_ext(basename(csv_path))
  parts <- strsplit(base, "_")[[1]]
  year_idx <- grep("^[0-9]{4}$", parts)
  if (length(year_idx) > 0) {
    after_year <- parts[seq(max(year_idx) + 1, length(parts))]
    paste(tools::toTitleCase(after_year), collapse = " ")
  } else {
    tools::toTitleCase(gsub("_", " ", base))
  }
}
