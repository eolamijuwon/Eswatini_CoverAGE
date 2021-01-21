


library(RCurl)
library(curl)
library(tidyverse)
library(showtext)
library (grid)
library(imager)

library(httr)
url <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv" 
deaths <- read.csv(url)


showtext_auto()
## Caption Text
if ("RobotoCondensed-Italic.ttf" %in% list.files("C:\\Windows\\Fonts")) {
  
  font_add("RobotoCondensed-Italic", "RobotoCondensed-Italic.ttf")
  caption_text <- "RobotoCondensed-Italic"
  
} else {
  
  font_add("ARIALNI", "ARIALNI.ttf")
  caption_text <- "ARIALNI"
  
}

## Graphics Title
if ("Montserrat-Regular.ttf" %in% list.files("C:\\Windows\\Fonts")) {
  
  font_add("Montserrat", "Montserrat-Regular.ttf")
  title_text <- "Montserrat"
  
} else {
  
  font_add("Candara", "Candara.ttf")
  title_text <- "Candara"
  
}





death_counts <- deaths %>% 
                select(Country.Region, X1.22.20:X1.20.21) %>%
                ## Reshape the data from wide format to long
                ## You can read more about pivot_longer or pivot_wider via the link below:
                ## https://tidyr.tidyverse.org/reference/#section-pivoting
                pivot_longer(cols = X1.22.20:X1.20.21, 
                             names_to = "Date", 
                             values_to = "total_deaths") %>%
                filter (Country.Region == "Eswatini") %>% 
                ## Replace "." between the dates with "/" and remove the starting "X"
                mutate (Date = str_replace_all(Date, "\\.", "/")) %>%
                mutate (Date = str_remove(Date, "X") %>% as.Date("%m/%d/%y")) %>%
                select(Date, total_deaths) %>%
                mutate(Date = as.character(Date)) %>% 
                mutate (Date = as.Date(Date)) %>% 
                arrange (Date) %>% 
                mutate(month_year = format(Date, "%b %Y")) %>% 
                mutate(month_year = factor(month_year, unique(month_year))) %>% 
                group_by (month_year) %>% 
                mutate (id = n():1) %>% 
                filter (id == 1) %>% 
                ungroup() %>% 
                mutate(new_deaths = total_deaths - lag(total_deaths)) %>% 
                mutate (new_deaths = replace_na(new_deaths, 0),
                        pos = total_deaths + 10,
                        label = ifelse((total_deaths > 0 & total_deaths < 300),
                                       total_deaths, NA))
        
total_deaths <- death_counts$total_deaths[13]
new_deaths <- death_counts$new_deaths[13]


eswatini_logo <- load.image("https://raw.githubusercontent.com/eolamijuwon/Eswatini_CoverAGE/main/Images/Eswatini_flag.png")

death_counts %>%  ggplot() +
                  geom_step(aes(y = new_deaths,
                                x = month_year),
                            group = 1, 
                            color = "#0B608A",
                            size = 1) +
                  geom_step (aes(y = total_deaths,
                                 x = month_year),
                             group = 1, 
                             color = "#806C1C",
                             size = 1) + 
                  geom_text (aes (x = month_year,
                                  y = pos,
                                  label = label,
                                  hjust = 1), size = 10) +
                  theme_bw(base_family = title_text,
                           base_size = 30) + 
                  theme (                      # Panel
                    panel.grid = element_line(colour = NULL),
                    panel.grid.major.y = element_line(colour = "#D2D2D2",
                                                      linetype = "dashed",
                                                      size = 0.3),
                    panel.grid.major.x = element_line(colour = "#D2D2D2",
                                                      linetype = "dashed",
                                                      size = 0.3),
                    panel.grid.minor = element_blank()
                  ) +
                  annotate("text", y = 150, angle = 90,
                           x = 13.2, color = "#0B608A", 
                           size = 11, label = paste0("New deaths = ", new_deaths)) +
                  annotate("text", y = 370, angle = 90,
                           x = 12.8, color = "#806C1C", 
                           size = 12, label = paste0("Total deaths = ", total_deaths)) +
                  annotation_custom(rasterGrob(eswatini_logo),
                                    ymin = 270, ymax = 350,
                                    xmin = 1, xmax = 3) +
                  annotate("text", y = 310, hjust = 0, vjust = 0.5, family = caption_text, 
                           x = 3.2, color = "#000000", lineheight = unit(0.2, "pt"),
                           size = 18, label = "A total of 222 new deaths from COVID-19 has been recorded in Eswatini 
                                            \nin the first 20 days of 2021. That's about 17 more deaths than the total 
                                            \nnumber of deaths from COVID19 complications in 2020 [Mar - Dec].") +
                  labs (y = "Counts of Deaths", x = "Month and Year")
  



ggsave(file="images/Death Counts - SZ.png", dpi=350, height= 6, width= 10)
