#needed packages, if they are already installed skip the first step and move on to step 2
#Step 1: install packages
#install.packages("writexl")
#install.packages("ggplot2")
#install.packages("dplyr")
#install.packages("RColorBrewer")
#install.packages("ggimage")
#install.packages("png")

#Step 2: load packages
library(ggplot2)
library(dplyr)
library(writexl)
library(RColorBrewer)
library(ggimage)
library(png)
library(dplyr)

#set working directory
setwd("C:/N_C_Collagen_graphs")

##create output folders for figures and csv/excel files
if (!dir.exists("./Figures")) {
  dir.create("./Figures", recursive = TRUE, showWarnings = FALSE)
}
figure_output_dir <- file.path("./Figures")

#creating a folder for csv/excel files that will be generated
if(!dir.exists("./tables")) {
  dir.create("./tables", recursive = TRUE, showWarnings = FALSE)
}
tab_output_dir <- file.path("./tables")
tab_output_dir <- "tables"

##load your data, there are different ways to load them, chose one
#load files via code
df <- read.csv("./data/makarewicz_et_al_2022_maidanetske.csv", sep = ";", header = TRUE)
#load files from environment, for that you have to click on "Import Dataset" in the Environment
# df <- R_Tabelle

##check your data
#check if you have missing values
is.na.data.frame(df)
#and exclude them
df <- df %>%
  filter(if_any(c(d15N, d13C), ~ !is.na(.)))

#check if your values are numeric
sapply(df, is.numeric)
#if not do
df$d15N <- as.numeric(df$d15N)

#if you want to change column from numeric to character
#df$Identifier <- as.character(df$Identifier)

## describtive statistics
summary_df <- df %>%
  group_by(Species) %>%
  summarise(
    count      = n(),
    mean_d15N  = mean(d15N, na.rm = TRUE),
    mean_d13C  = mean(d13C, na.rm = TRUE),
    sd_d15N    = sd(d15N, na.rm = TRUE),
    sd_d13C    = sd(d13C, na.rm = TRUE),
    range_d15N = paste0(min(d15N, na.rm = TRUE), " to ", max(d15N, na.rm = TRUE)),
    range_d13C = paste0(min(d13C, na.rm = TRUE), " to ", max(d13C, na.rm = TRUE))
  )
#export of the summary table
#we take the defined output direction "tab_output_dir" from above and give the summary_df the output name
full_path <- file.path(tab_output_dir, "Collagen_Results_Maidanetske.xlsx")

#writing the summary "Collagen_Results_Maidanetske" data frame in an excel file
writexl::write_xlsx(summary_df, full_path)

#the same can be done for csv
full_path_csv <- file.path(tab_output_dir, "Collagen_Results_Maidanetske.csv")
write.csv(summary_df, full_path_csv)

#the function "write.csv(summary_df, file = "Collagen_Results_Maidanetske.csv")" 
#will  put the file in your current working directory 
#write.csv(summary_df, file = "Collagen_summary.csv")

##Creating the first scatterplot
#this plot (p1) is a basis scatterplot, each Species will have its own shape and colour
p1 <- ggplot(df, aes(x = d13C, y = d15N)) + #df is the dataframe you use, x = (column for x-values, y = column for y-values)
 geom_point(aes(colour = Species, shape = Species), size = 5)+ #geom_point is the instruction for creating a scatterplot,
  #can be changed (geom_bar for example would create a bar chart)
  #size changes the size of the points in the scatterplot
  scale_color_brewer(palette = "Dark2") + #this is the instruction for the colour palette you use
  scale_shape_manual(values = c(15, 16, 17, 25)) + #this defines the shape, for overview of possible shapes search for "scale_shape" in Help
  theme_bw(base_size = 10, base_family = "serif") + #this size changes the whole size of every element in the diagram (points, labels, etc.),
  #base family defines the fond family for the whole plot
  xlab(expression(delta^13*C ~ "(\u2030)")) +  # Δ^13C mit ‰ Symbol
  ylab(expression(delta^15*N ~ "(\u2030)")) +
  labs(title = "Carbon and Nitrogen values of domestic animals", subtitle = "from Maidanetske")+
  theme(legend.position = "right",
        legend.title = element_text(),
        axis.title = element_text(family = "sans", face = "bold", size = 15),
        axis.text = element_text(family = "sans", size = 12)) #
p1 #the solely command p1 shows you the plotted diagram, alternatively you can also type p1 in your console

#save plot in your output directory as svg file
ggsave(file.path(figure_output_dir, "Maidanetske_Collagen_Species.svg"), plot = p1, width = 10, height = 8, dpi = 300)

##Group plot
#the following part and plot (p2) shows how new columns can be added to the data
#first we will define categories, we use the values of the column "Species" in this case and define new values
#in this case after diet: omnivor, carnivor, herbivor
omnivor <- c("Sus")
herbivor <- c("Bos", "Capra", "Ovis")

#adds a column to your data frame, based on the defined groups
df <- df %>%
  mutate(diet = case_when(
    Species %in% omnivor ~ "omnivor",
    Species %in% herbivor ~ "herbivor",
    TRUE ~ "carnivor"  # TRUE ~ "carnivor" would write "carnivor" in the column for every species which cannot be found in the groups omnivor and herbivor defined above
  ))

#you can filter and create new data frames with only a part of the original data
#in the following line we create a new data frame "df_herbivor" only with all rows which contain the value "herbivor" in the column "diet"
df_herbivor <- df %>% filter(diet == "herbivor")

#next to adding column, it is also possible to delete a column
df$diet <- NULL

#create new groups 
pigs <- c("Sus")
cattle <- c("Bos")
ovicaprines <- c("Ovis", "Capra")

#create a new column "categories" with the above defined groups
df <- df %>%
  mutate(categories = case_when(
    Species %in% pigs ~ "pigs",
    Species %in% cattle ~ "cattle",
    Species %in% ovicaprines ~ "ovicaprines",
    TRUE ~ "unestimated"
  ))

#now plot the data with the categories
p2 <- ggplot(df, aes(x = d13C, y = d15N)) + #df is the dataframe you use, x = (column for x-values, y = column for y-values)
  # Einzelpunkte
  geom_point(aes(colour = categories, shape = categories), size = 5)+ #geom_point is the instruction for creating a scatterplot,
  #can be changed (geom_bar for example would create a bar chart)
  #size changes the size of the points in the scatterplot
  scale_color_brewer(palette = "Dark2") + #this is the instruction for the colour palette you use
  scale_shape_manual(values = c(15, 16, 17, 25)) + #this defines the shape, for overview of possible shapes search for "scale_shape" in Help
  theme_bw(base_size = 10, base_family = "sans") + #this size changes the whole size of every element in the diagram (points, labels, etc.),
  #base family defines the fond family for the whole plot
  xlab(expression(delta^13*C ~ "(\u2030)")) +  # Δ^13C mit ‰ Symbol
  ylab(expression(delta^15*N ~ "(\u2030)")) +
  labs(title = "Carbon and Nitrogen values of domestic animals", subtitle = "from Maidanetske")+
  theme(legend.position = "right",
        legend.title = element_text(),
        axis.title = element_text(family = "sans", face = "bold", size = 15),
        axis.text = element_text(family = "sans", size = 12)) #
p2
#save plot p2 in the figure_output_dir
#svg can be changed to .png 
ggsave(file.path(figure_output_dir, "Maidanetske_Collagen_Categories.svg"), plot = p2, width = 10, height = 8, dpi = 300)

##create a plot with the silhouettes of the animals, instead of points
#credits to J. Goebel for the Code section

#first define silhouettes from the svg-files in the folder "assets"
SPECIES_SVG_MAP <- c(
  Bos   = "cattle.svg",
  Capra = "goat.svg",
  Ovis  = "sheep.svg",
  Sus   = "pig.svg",
  Canis = "dog.svg"
)
#define colours
SPECIES_COLORS_PICTO <- c(
  Bos   = "#F8766D",
  Capra = "#7CAE00",
  Ovis  = "#00BFC4",
  Sus   = "#C77CFF",
  Canis = "#E68A00"
)

assets_dir <- "assets" 

plot_pictogram <- function(df, title, assets_dir,
                           svg_map = SPECIES_SVG_MAP,
                           colors  = SPECIES_COLORS_PICTO) {
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
    xlab(expression(delta^13*C ~ "(\u2030)")) +
    ylab(expression(delta^15*N ~ "(\u2030)")) +
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

#save pictogram-plot
plot_pictogram_result <- plot_pictogram(df, title = "d13C vs d15N by species (pictogram)", assets_dir = assets_dir)
if (!is.null(plot_pictogram_result)) {
  ggsave(file.path(figure_output_dir,"pictogram_scatter.svg"), plot = plot_pictogram_result, width = 12, height = 8, dpi = 300)
  ggsave(file.path(figure_output_dir,"pictogram_scatter.png"), plot = plot_pictogram_result, width = 12, height = 8, dpi = 300)
}





