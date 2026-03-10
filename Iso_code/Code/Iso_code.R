#load functions
install.packages("ggthemes")

library(ggthemes)
library(readxl)
library(dplyr)
library(ggplot2)
library(data.table)
library(purrr)
library(diptest)
library(mclust)
library(readr)


setwd("C:/plotting_M2_M3_together")

# 1) Ensure output directory exists
if (!dir.exists("./Iso_data")) {
  dir.create("./Iso_data", recursive = TRUE, showWarnings = FALSE)
}
###GRAPHS####

###Enamel data###
####C/O###
data <- Sheep_TB
data <- split(data, data[["Specimen"]])
for (name in names(data)) {
  assign(paste0("data_", name), data[[name]])}
#create csv files
for (name in names(data)) {
  write.csv(data[[name]], file = paste0( name, ".csv"), row.names = FALSE)
}



csv_files <- list.files(".", pattern = "\\.csv$", full.names = TRUE)
for (csv_file in csv_files) {
  data <- read.csv(csv_file)
  title_text <- tools::file_path_sans_ext(basename(csv_file))
  out_dir <- file.path("./Figures", csv_file)
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  data$d13C_scaled <- data$d13C + 29  # Transformation auf primäre Skala
  y_min <- min(c(data$d18O, data$d13C_scaled))
  y_max <- max(c(data$d18O, data$d13C_scaled))
g <- ggplot() +
  geom_line(data = data, aes(Dist, d13C_scaled )) +                        #d13C
  geom_point(data = data, aes(Dist, d13C_scaled), colour = "green") + #d13C
  geom_line(data = data, aes(Dist, d18O))   +                     #d18O
  geom_point(data = data, aes(Dist, d18O),colour = "darkblue")+   #d18O

  labs(
    title = title_text)+

  scale_y_continuous(
    name = "d18O",
    limits = c(y_min, y_max),
    breaks = seq(floor(y_min), ceiling(y_max), 1),
    sec.axis = sec_axis(~ . - 29, name = "d13C")
  ) +
  
  
#theme_classic()                                                            +
#theme_bw()                                                                  +
  theme_calc() +
 theme(axis.ticks.y.right = element_line(color = "green"),
        axis.text.y.right = element_text(color = "green"),
        axis.title.y.right = element_text(colour = "green"),
        axis.ticks.y.left = element_line(color = "darkblue"),
        axis.text.y.left = element_text(color = "darkblue"),
        axis.title.y.left = element_text(colour = "darkblue"))+
  
scale_x_reverse() +

facet_wrap(vars(Tooth))
print(g)
ggsave(file.path(out_dir, paste0("indiv_profile_", title_text, ".png")), g, width = 8, height = 6, dpi = 300)
}


  
  
  ###Sr/O####
  
# Create the ggplot
h <- ggplot() +
  # Plot Sr values (multiplied by -10) as red points
  geom_point(data = OPPPVG_enamel_SI, aes(x = ERJ, y = Sr * -100), 
             colour = "red", na.rm = TRUE) + 
  
  # Plot d18O values as a line and points in dark blue
  geom_line(data = OPPPVG_enamel_SI, aes(x = ERJ, y = O)) +
  geom_point(data = OPPPVG_enamel_SI, aes(x = ERJ, y = O), 
             colour = "darkblue") +
  
  # Primary and secondary y-axes
  scale_y_continuous(
    name = expression(delta^{18} * O),  # Label for primary y-axis
    breaks = seq(-12, 0, 2),          # Refine primary y-axis breaks
    limits = c(-12, 0),               # Set limits for the primary axis
    sec.axis = sec_axis(
      trans = ~ . / -100,               # Transformation for secondary axis
      name = "Sr",                     # Label for secondary y-axis
      breaks = seq(0.71, 0.72, 0.02)      # Refined breaks for secondary axis
    )
  ) +
  
  # Add faceting for "Tooth" variable
  facet_wrap(vars(Tooth)) +
  
  # Apply minimal theme and custom axis styling
  theme_minimal() +
  theme(
    # Styling for the secondary y-axis (right side)
    axis.ticks.y.right = element_line(color = "red"),
    axis.text.y.right = element_text(color = "red"),
    axis.title.y.right = element_text(color = "red"),
    
    # Styling for the primary y-axis (left side)
    axis.ticks.y.left = element_line(color = "darkblue"),
    axis.text.y.left = element_text(color = "darkblue"),
    axis.title.y.left = element_text(color = "darkblue")
  )
###Another way to add sec axis###
  
# Calculate dynamic scaling factor
primary_range <- range(OPPPVG_enamel_SI$O, na.rm = TRUE)  # Range of primary y-axis
secondary_range <- range(OPPPVG_enamel_SI$Sr, na.rm = TRUE)  # Range of secondary y-axis

# Choose a scaling factor to align ranges proportionally
scale_factor <- diff(primary_range) / diff(secondary_range)  # Multiply by 10 for emphasis

# Adjust y-axis limits for visibility
primary_limits <- c(min(OPPPVG_enamel_SI$O), 
                    max(OPPPVG_enamel_SI$O))
secondary_limits <- c(min(OPPPVG_enamel_SI$Sr) * scale_factor, 
                      max(OPPPVG_enamel_SI$Sr) * scale_factor)


# Create the ggplot
h <- ggplot() +
  # Plot Sr values (scaled for emphasis) as red points
  geom_point(data = OPPPVG_enamel_SI, aes(x = ERJ, y = Sr * -scale_factor), 
             colour = "red", na.rm = TRUE) + 
  
  # Plot d18O values as a line and points in dark blue
  geom_line(data = OPPPVG_enamel_SI, aes(x = ERJ, y = O)) +
  geom_point(data = OPPPVG_enamel_SI, aes(x = ERJ, y = O), 
             colour = "darkblue") +
  
  scale_y_continuous(
    name = expression(delta^{18} * O),  # Label for primary y-axis
    breaks = seq(-12, 0, 1),          # Refined primary y-axis breaks
    limits = primary_limits,           # Ensure primary axis accommodates secondary
    sec.axis = sec_axis(
      trans = ~ . / -scale_factor,      # Transformation for secondary axis
      name = "Sr",                     # Label for secondary y-axis
      breaks = seq(0.70, 0.73, 0.005)  # Smaller, detailed breaks for Sr
    )
  ) +
  
  # Primary and secondary y-axes
  scale_y_continuous(
    name = expression(delta^{18} * O),  # Label for primary y-axis
    breaks = seq(-12, 0, 2),          # Refine primary y-axis breaks
    limits = c(-12, 0),               # Set limits for the primary axis
    sec.axis = sec_axis(
      trans = ~ . / -2793.277,      # Transformation for secondary axis
      name = "Sr",                     # Label for secondary y-axis
      breaks = seq(0.70, 0.73, 0.005)  # Refined breaks for Sr
    )
  ) +
  
  # Add faceting for "Tooth" variable
  facet_wrap(vars(Tooth)) +
  
  # Apply minimal theme and custom axis styling
  theme_minimal() +
  theme(
    # Styling for the secondary y-axis (right side)
    axis.ticks.y.right = element_line(color = "red"),
    axis.text.y.right = element_text(color = "red"),
    axis.title.y.right = element_text(color = "red"),
    
    # Styling for the primary y-axis (left side)
    axis.ticks.y.left = element_line(color = "darkblue"),
    axis.text.y.left = element_text(color = "darkblue"),
    axis.title.y.left = element_text(color = "darkblue")
  )



# Calculate dynamic scaling factor
primary_range <- range(c(0, -12))  # Range of data1
secondary_range <- range(c(0.70, 7.19))  # Range of data2

# Dynamic scaling factor
scale_factor <- diff(primary_range) / diff(secondary_range) 

# Offset to align secondary axis with the primary axis range
offset <- mean(primary_range) - (mean(secondary_range) * scale_factor)

# Create the ggplot
ggplot() +
  # Plot data1 (O values) as a blue line and points
  geom_line(data = OPPPVG_enamel_SI, aes(x = ERJ, y = O)) +
  geom_point(data = OPPPVG_enamel_SI, aes(x = ERJ, y = O), 
             colour = "darkblue") +
  
  # Plot scaled data2 (Sr values) as red line and points
  geom_point(data = OPPPVG_enamel_SI, aes(x = ERJ, y = Sr * -scale_factor+ offset), 
             colour = "red", na.rm = TRUE) + 
  
  
  # Set up primary and secondary y-axes
  scale_y_continuous(
    name = "Primary Y-axis (O values)",  # Label for primary axis
    limits = c(-15, 0),                 # Expanded limits for clarity
    sec.axis = sec_axis(
      trans = ~ (. - offset) / scale_factor,  # Transformation for secondary axis
      name = "Secondary Y-axis (Sr values)", # Label for secondary axis
      breaks = seq(0.7, 7.2, 1)             # Refined breaks for Sr values
    )
  ) +
  
  # Add labels and minimal theme
  labs(title = "Comparison of d18O and Sr", x = "ERJ") +
  # Add faceting for "Tooth" variable
  facet_wrap(vars(Tooth)) +
  
  # Apply minimal theme and custom axis styling
  theme_minimal() +
  theme(
    # Styling for the secondary y-axis (right side)
    axis.ticks.y.right = element_line(color = "red"),
    axis.text.y.right = element_text(color = "red"),
    axis.title.y.right = element_text(color = "red"),
    
    # Styling for the primary y-axis (left side)
    axis.ticks.y.left = element_line(color = "darkblue"),
    axis.text.y.left = element_text(color = "darkblue"),
    axis.title.y.left = element_text(color = "darkblue")

  )


