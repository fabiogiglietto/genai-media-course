# ============================================
# UNIVERSITÀ DEGLI STUDI DI URBINO CARLO BO
# R Color Palette and ggplot2 Theme
# Based on Brand Manual 2024-2026
# ============================================

# Load required packages
library(ggplot2)

# ============================================
# PRIMARY COLOR PALETTE - ATENEO
# ============================================

uniurb_colors <- list(
  # Blue palette
  blue_dark   = "#294973",
  blue_medium = "#49668C",
  blue_light  = "#7289A6",
  blue_pale   = "#A4B0BF",
  gray_light  = "#F2F2F2",
  
  # Gold palette
  gold_dark    = "#7A621D",
  gold_light   = "#FADB87",
  gold_primary = "#FAC73C",
  gold_muted   = "#7A6F51",
  gold_medium  = "#C79F30"
)

# ============================================
# DEPARTMENT COLOR PALETTES
# ============================================

# DESP - Economia, Società, Politica
uniurb_desp <- c("#DCB145", "#D96704", "#D99862", "#F2CDAC", "#F2F2F2")

# DIGIUR - Giurisprudenza
uniurb_digiur <- c("#839BC2", "#768BA6", "#9FADBF", "#C5CED9", "#F2F2F2")

# DISB - Scienze Biomolecolari
uniurb_disb <- c("#D92B04", "#F24535", "#F26F63", "#F2A7A0", "#F2F2F2")

# DISCUI - Scienze della Comunicazione
uniurb_discui <- c("#E06029", "#F68B5F", "#F56D65", "#F2A7A0", "#F2F2F2")

# DISPEA - Scienze Pure e Applicate
uniurb_dispea <- c("#027368", "#168C80", "#6AA6A0", "#BAD9D3", "#F2F2F2")

# DISTUM - Studi Umanistici
uniurb_distum <- c("#8C1B59", "#A83E7D", "#BF7EA2", "#D9B0C6", "#F2F2F2")

# ============================================
# COLOR PALETTE FUNCTIONS
# ============================================

#' Get Uniurb Ateneo palette
#' @param n Number of colors needed
#' @param type "blue", "gold", or "mixed"
#' @return Character vector of hex colors
uniurb_palette <- function(n = 5, type = "blue") {
  
  if (type == "blue") {
    colors <- c("#294973", "#49668C", "#7289A6", "#A4B0BF", "#F2F2F2")
  } else if (type == "gold") {
    colors <- c("#7A621D", "#C79F30", "#FAC73C", "#FADB87", "#F2F2F2")
  } else if (type == "mixed") {
    colors <- c("#294973", "#49668C", "#FAC73C", "#C79F30", "#7289A6")
  } else {
    stop("Type must be 'blue', 'gold', or 'mixed'")
  }
  
  if (n > length(colors)) {
    warning("n is greater than palette length. Recycling colors.")
    colors <- rep(colors, ceiling(n / length(colors)))
  }
  
  return(colors[1:n])
}

#' Get department palette
#' @param dept Department code: "desp", "digiur", "disb", "discui", "dispea", "distum"
#' @param n Number of colors needed
#' @return Character vector of hex colors
uniurb_dept_palette <- function(dept, n = 5) {
  
  palettes <- list(
    desp    = uniurb_desp,
    digiur  = uniurb_digiur,
    disb    = uniurb_disb,
    discui  = uniurb_discui,
    dispea  = uniurb_dispea,
    distum  = uniurb_distum
  )
  
  dept <- tolower(dept)
  
  if (!dept %in% names(palettes)) {
    stop("Department not found. Use: desp, digiur, disb, discui, dispea, distum")
  }
  
  colors <- palettes[[dept]]
  
  if (n > length(colors)) {
    warning("n is greater than palette length. Recycling colors.")
    colors <- rep(colors, ceiling(n / length(colors)))
  }
  
  return(colors[1:n])
}

# ============================================
# GGPLOT2 SCALE FUNCTIONS
# ============================================

#' Discrete color scale using Uniurb palette
#' @param type "blue", "gold", or "mixed"
#' @param ... Additional arguments passed to discrete_scale
scale_color_uniurb <- function(type = "blue", ...) {
  ggplot2::discrete_scale(
    aesthetics = "colour",
    scale_name = "uniurb",
    palette = function(n) uniurb_palette(n, type),
    ...
  )
}

#' Discrete fill scale using Uniurb palette
#' @param type "blue", "gold", or "mixed"
#' @param ... Additional arguments passed to discrete_scale
scale_fill_uniurb <- function(type = "blue", ...) {
  ggplot2::discrete_scale(
    aesthetics = "fill",
    scale_name = "uniurb",
    palette = function(n) uniurb_palette(n, type),
    ...
  )
}

#' Discrete color scale using department palette
#' @param dept Department code
#' @param ... Additional arguments passed to discrete_scale
scale_color_uniurb_dept <- function(dept, ...) {
  ggplot2::discrete_scale(
    aesthetics = "colour",
    scale_name = "uniurb_dept",
    palette = function(n) uniurb_dept_palette(dept, n),
    ...
  )
}

#' Discrete fill scale using department palette
#' @param dept Department code
#' @param ... Additional arguments passed to discrete_scale
scale_fill_uniurb_dept <- function(dept, ...) {
  ggplot2::discrete_scale(
    aesthetics = "fill",
    scale_name = "uniurb_dept",
    palette = function(n) uniurb_dept_palette(dept, n),
    ...
  )
}

# ============================================
# GGPLOT2 THEME
# ============================================

#' Uniurb ggplot2 theme
#' @param base_size Base font size
#' @param base_family Base font family
#' @return ggplot2 theme object
theme_uniurb <- function(base_size = 14, base_family = "") {
  
  # Try to use Atkinson Hyperlegible if available
  if (base_family == "") {
    # Check if font is available
    if ("Atkinson Hyperlegible" %in% sysfonts::font_families()) {
      base_family <- "Atkinson Hyperlegible"
    } else {
      base_family <- "sans"
    }
  }
  
  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      # Plot title and subtitle
      plot.title = element_text(
        color = uniurb_colors$blue_dark,
        face = "bold",
        size = rel(1.3),
        hjust = 0,
        margin = margin(b = 10)
      ),
      plot.subtitle = element_text(
        color = uniurb_colors$blue_medium,
        size = rel(1.0),
        hjust = 0,
        margin = margin(b = 15)
      ),
      plot.caption = element_text(
        color = uniurb_colors$blue_light,
        size = rel(0.8),
        hjust = 1,
        margin = margin(t = 10)
      ),
      
      # Axis
      axis.title = element_text(
        color = uniurb_colors$blue_dark,
        size = rel(0.95)
      ),
      axis.text = element_text(
        color = uniurb_colors$blue_medium,
        size = rel(0.85)
      ),
      axis.line = element_line(
        color = uniurb_colors$blue_pale,
        linewidth = 0.5
      ),
      
      # Grid
      panel.grid.major = element_line(
        color = uniurb_colors$blue_pale,
        linewidth = 0.3
      ),
      panel.grid.minor = element_blank(),
      
      # Background
      plot.background = element_rect(
        fill = "white",
        color = NA
      ),
      panel.background = element_rect(
        fill = "white",
        color = NA
      ),
      
      # Legend
      legend.title = element_text(
        color = uniurb_colors$blue_dark,
        face = "bold",
        size = rel(0.9)
      ),
      legend.text = element_text(
        color = uniurb_colors$blue_medium,
        size = rel(0.85)
      ),
      legend.background = element_rect(
        fill = "white",
        color = NA
      ),
      legend.key = element_rect(
        fill = "white",
        color = NA
      ),
      
      # Facets
      strip.background = element_rect(
        fill = uniurb_colors$blue_dark,
        color = NA
      ),
      strip.text = element_text(
        color = "white",
        face = "bold",
        size = rel(0.9)
      ),
      
      # Plot margin
      plot.margin = margin(20, 20, 20, 20)
    )
}

# ============================================
# EXAMPLE USAGE
# ============================================

# Example 1: Basic scatter plot with Uniurb theme
# ggplot(mtcars, aes(x = wt, y = mpg)) +
#   geom_point(color = uniurb_colors$blue_dark, size = 3) +
#   geom_smooth(method = "lm", color = uniurb_colors$gold_primary, se = FALSE) +
#   labs(title = "Esempio di Grafico", subtitle = "Con tema Uniurb") +
#   theme_uniurb()

# Example 2: Bar plot with Uniurb color scale
# ggplot(mpg, aes(x = class, fill = class)) +
#   geom_bar() +
#   scale_fill_uniurb(type = "mixed") +
#   labs(title = "Distribuzione per Classe") +
#   theme_uniurb()

# Example 3: Using department colors
# ggplot(iris, aes(x = Sepal.Length, y = Sepal.Width, color = Species)) +
#   geom_point(size = 3) +
#   scale_color_uniurb_dept("dispea") +
#   labs(title = "Iris Dataset", subtitle = "Colori DISPEA") +
#   theme_uniurb()

# Print confirmation
cat("Uniurb R color palette and theme loaded successfully!\n")
cat("Available functions:\n")
cat("  - uniurb_palette(n, type)\n")
cat("  - uniurb_dept_palette(dept, n)\n")
cat("  - scale_color_uniurb(type)\n")
cat("  - scale_fill_uniurb(type)\n")
cat("  - scale_color_uniurb_dept(dept)\n")
cat("  - scale_fill_uniurb_dept(dept)\n")
cat("  - theme_uniurb(base_size, base_family)\n")
