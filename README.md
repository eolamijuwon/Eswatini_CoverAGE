---
VISUALIZING AGE-SEX COMPOSITION OF CONFIRMED CORONAVIRUS CASES IN ESWATINI SINCE MARCH 2020
---


<img align="centre" src="Images/Eswatini_CoVID_Pyramid.gif>



## Introduction 😎

Why visualize the age-sex composition of confirmed coronavirus cases? Demographers have been consistently highlighting the importance of age-sex structure of the population and confirmed cases in shaping fatality rates in countries *(see these articles*📰 *published in [**PNAS**](https://www.pnas.org/content/117/18/9696) and [**PlosONE**](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0238904) for details)*. My colleagues and I also wrote a [**commentary**](https://theconversation.com/flaws-in-the-collection-of-african-population-statistics-block-covid-19-insights-142669)😊highlighting the importance of age-sex disaggregated counts of confirmed cases and deaths in African countries.

This animation presents one of the many benefits of the data, including highlight trends in the age distribution of confirmed cases in Eswatini since March 2020. It is worthy of note that Eswatini is about the only African country😑that still publishes daily counts of confirmed coronavirus cases and deaths disaggregated by age-sex since March 2020.

In this tutorial, I demonstrate step-by-step how to replicate the animation. While I focus on visualizing the age-sex composition of confirmed cases and deaths in Eswatini, the tutorial can be fully adapted to other relevant social and demographic issues, including visualizing changes in population structure over time, among many others.

We'll use several libraries, the purpose of which is indicated in the comments. Please note that you may have first to install the packages using `install.packages ("packageName")` if you do not have them already installed.

```{r}
library (gganimate)   # for animating images:: transition_manual(), animate(), 
                        # enter_fade(), exit_fade(), ease_aes()

library (grid)        # Render a raster image::rasterGrob()

library (gsheet)      # Downloading googleSheets: gsheet2tbl()

library (imager)      # Read images [PNG, JPEG, BMP] into R:: load.image()

library (mosaic)      # Creating new variables:: derivedFactor()

library (RCurl)       # Download a URL:: getURL()

library (showtext)    # Importing fonts:: showtext_auto()

library (tidyverse)   # Data wrangling:: 
                        # dplyr::select(), filter(), mutate, arrange(), 
                        # dplyr::ungroup(), arrange(), left_join()
                        # stringr::str_replace_all(), str_remove(), 
                        # tidyr::pivot_longer(), pivot_longer()
```

We will also need to import all the relevant fonts for the graphics using `showtext`📦. For this animation, I used *Decima+ Light.otf* for texts, Montserrat for the graphic title, and *RobotoCondensed-LightItalic.ttf* for the caption. I have bundled all of these fonts for you in a [**GitHub repository**](https://github.com/eolamijuwon/Eswatini_CoverAGE/tree/main/Fonts). You will need to download, 📥 and install each of the fonts for this to work properly. In the lines of code below, each font is nested in an if-else statement so that an alternative font *ARIALN.ttf* is used if R is unable to find the corresponding font in the fonts directory of your laptop. You may also need to edit/adjust the command to point to the relevant directory if you are a macOS user.

```{r}
    showtext_auto()
    if ("Decima+ Light.otf" %in% list.files("C:\\Windows\\Fonts")) {
      
      font_add("Decima", "Decima+ Light.otf")
      axis_text <- "Decima"
      
    } else {
      
      font_add("ARIALN", "ARIALN.ttf")
      axis_text <- "ARIALN"
    
    }

    ## Caption Text
    if ("RobotoCondensed-LightItalic.ttf" %in% list.files("C:\\Windows\\Fonts")) {
      
      font_add("RobotoCondensed-LightItalic", "RobotoCondensed-LightItalic.ttf")
      caption_text <- "RobotoCondensed-LightItalic"
      
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
```

## Data Import 💾

We will import all the relevant data files for this project. More importantly, you need to import:

-   The age-sex composition 👨‍👩‍👧‍👦 of COVID-19 cases for your country of interest. Here I used data for [Eswatini](https://www.thekingdomofeswatini.com/) - the smallest landlocked country in the Southern African region. The data are reported by the Government of Eswatini and curated by the CoverAge-DB team. You can find additional information about the country and data on its [**website**](http://www.gov.sz/index.php/covid-19-corona-virus/covid-19-press-statements-2020). To retrieve the data directly from COVERAGE, we will use the [covidAgeData](https://github.com/eshom/covid-age-data) 📦 by [Erez Shomron](https://github.com/eshom). The covidAgeData package will retreive the data directly from the OSF framework and we will subset the data for Eswatini - our country of interest.

```{r}

install.packages("devtools")
library(devtools)

devtools::install_github("eshom/covid-age-data")
library(covidAgeData)

Eswatini_coverAge <-  download_covid() %>% 
                      filter (Country == "Eswatini") 

```

-   Daily totals📈 of confirmed COVID19 cases and deaths. The data are reported by the country's department of health and curated by the Center for Systems Science and Engineering (CSSE) at Johns Hopkins University [**(CSSE)**](https://github.com/CSSEGISandData/COVID-19).

```{r}

cases <- read.csv(text=getURL("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv"), header=T) 

```

-   We will also overlay the visualization with the country's flag, as earlier mentioned. To do this, we will download the image directly from GitHub to R using the `imager` package.

```{r warning=FALSE}
eswatini_logo <- load.image("https://raw.githubusercontent.com/eolamijuwon/Eswatini_CoverAGE/main/Images/Eswatini_flag.png")
```

## Data Wrangling 👨‍💻

The following code block involves:

-   reshaping the data (from wide to long, and vice versa);

-   subsetting the data for country and periods of interest;

-   creating new variables, re-defining factor levels, among others.

Line-by-line comments are also provided to explain each line of code.

```{r warning=FALSE}
cases   <-    cases %>% filter(Country.Region == "Eswatini") %>% 
              ## Subset the data by selecting the country and date columns.
              ## You could also adjust the dates to cover more days 
                 ## depending on what's available on CoverAge-DB.
              select(Country.Region, X1.22.20:X12.30.20) %>%
              ## Reshape the data from wide format to long
              ## You can read more about pivot_longer or pivot_wider via the link below:
              ## https://tidyr.tidyverse.org/reference/#section-pivoting
              pivot_longer(cols = X1.22.20:X12.30.20, 
                           names_to = "Date", 
                           values_to = "total_cases") %>% 
              ## Replace "." between the dates with "/" and remove the starting "X"
              mutate (Date = str_replace_all(Date, "\\.", "/")) %>%
              mutate (Date = str_remove(Date, "X") %>% as.Date("%m/%d/%y")) %>%
              select(Date, total_cases) %>%
              mutate(Date = as.character(Date))



total_cases <-  cases %>%
                filter(Date == "2020-12-30") %>%
                select(total_cases) %>%
                as.numeric() %>% print()


clean_SZ  <- Eswatini_coverAge %>% 
             ## Exclude observations in which the age group is unknown
             ## and the gender is "both" since data is needed 
             ## for male/female individually
             filter(Age != "UNK" & Sex != "b") %>%
             ## Redefine factor levels
             mutate(age_grp = derivedFactor("0-9" = (Age == "0" | Age == "5"),
                                            "10-19" = (Age == "10" | Age == "15"),
                                            "20-29" = (Age == "20" | Age == "25"),
                                            "30-39" = (Age == "30" | Age == "35"),
                                            "40-49" = (Age == "40" | Age == "45"),
                                            "50-59" = (Age == "50" | Age == "55"),
                                            "60-69" = (Age == "60" | Age == "65"),
                                            "70-79" = (Age == "70" | Age == "75"),
                                            "80+" = (Age == "80" | Age == "85"),
                                            .default = NA)) %>% 
             ## Group the data by Date, Sex, Age group and Measure (Cases/Death).
             ## Grouping the data is primarily because some dates have data 
             ## in 5-years and others in 10 years. Grouping lumps the data into 10-years.
             mutate (Date = str_replace_all(Date, "\\.", "/") %>% as.Date("%d/%m/%Y")) %>%
             group_by(Date, Sex, age_grp, Measure) %>%
             ## Estimate the totals number of cases/deaths for all the
             ##  age groups and keep distinct values of age groups.
             mutate(pop = sum(Value)) %>% distinct(age_grp, .keep_all = TRUE) %>% 
             ## Ungroup the data and calculate the proportion of cases/deaths 
             ## based on the cumulative number of confirmed cases at the max date.
             ungroup() %>% mutate (prop = ((pop/total_cases) * 100) %>% round(2)) %>% 
             ## Filter for observations before December 01, 2020 
             filter(Date <= "2020-12-30") %>% 
             mutate(Gender = ifelse(Sex == "m", "Male", "Female")) %>% 
             select(-c(Code, Region, Metric, AgeInt, Value, pop, Sex)) %>%
             ## Reshape the data from long to wide so that 
             ## cases and deaths have different columns
             pivot_wider(id_cols = c(Date, Gender, age_grp), 
                         names_from = "Measure", 
                         values_from = "prop") %>%
             mutate(Date = as.character(Date)) %>% 
             ## Merge the age-sex data with total case counts from the CSSE data
             left_join(., cases, by = "Date") %>% 
             mutate(Date = as.Date(Date)) %>% 
             mutate(day_month = format(Date, "%d %B")) %>%
             ## Arrange data by age group, gender and date
             ## Also convert day and month vector to factor.
             arrange(age_grp, Gender, Date) %>%
             mutate(day_month = factor(day_month, unique(day_month))) %>% 
             mutate (Gender = factor(Gender, levels = c("Male", "Female")))

```

## Data Visualization 📊

The first block of code involves plotting the bar graph and setting a fixed axis from -16 to 16. Subsequently, we will add texts to label each side of the plot (male vs. female) and the total number of confirmed cases. We will also overlay the plot with the flag of Eswatini using the `annotation_custom` function.

```{r}
SZ_plot   <-    clean_SZ %>%  
  
                ggplot(aes(y = age_grp)) +
                ## Create bars for COVID-19 cases
                geom_bar(aes(x = ifelse(test = Gender == "Male",
                                        yes = -Cases, no = Cases),
                             fill = Gender),
                         stat = "identity",
                         ## Alpha sets the transparency level for the bars
                         alpha = 0.75) +
                scale_fill_manual(values = c("#ffb612", "#3A5DAE")) +
                ## Create bars for COVID-19 deaths
                geom_bar(aes(y = age_grp,
                             x = ifelse(test = Gender == "Male",
                                        yes = -Deaths, no = Deaths)),
                         stat = "identity",
                         fill = "red") +
                ## `scale_x_continuous` sets the axis labels to their 
                ## absolute values (so that they are not printed as negative numbers),
                ## and fixes the limits on both sides to 16%.
                scale_x_continuous(breaks=seq(-16, 16, 4),
                                   limits=c(-16, 16),
                                   labels=seq(-16, 16, 4) %>%
                                            abs %>% as.character() %>%
                                     paste0(., "%"))

SZ_plot   <-    SZ_plot +
                ## geom_text will add a title for the Male/Female side of the pyramid
                geom_text(x = -5, y = 9, 
                          aes(label = "Males"), hjust = 1,
                          family = axis_text, color = "#3A5DAE",
                          size = 11) + 
                geom_text(x = 5, y = 9, 
                          aes(label = "Females"), hjust = 0,
                          family = axis_text, color = "#ffb612",
                          size = 11) +
                geom_text(x = -11, y = 8, 
                          aes(label = paste0("Total No. of \nCases: ",
                                             total_cases)),
                          family = axis_text, 
                          size = 11) +
                ## Add a white line to the pyramid to differentiate between
                ## COVID-19 deaths for males and females
                annotate("segment", y=0, yend = 10,
                         x=0, xend =0,
                         color = "white",
                         size = 1.5) +
  
                ## Overlay the graph with the flag of Eswatini 
                ## You need to have imported `eswatini_logo`
                ## Otherwise you should remove the line of code
                annotation_custom(rasterGrob(eswatini_logo),
                                  ymin = 7, ymax = 9,
                                  xmin = 10, xmax = 16)

```

In the next lines of code, we will customize the plot. This includes setting the style and size of fonts used in the visualization, the legend position, the grid lines, and short descriptions for the plot title, subtitle, and caption. You can play around with the texts and examine the changes.

```{r}
SZ_graph   <-   SZ_plot +
                theme_bw(base_family = axis_text,
                         base_size = 35) + 
                      ## No axis title for the y-axis
                theme(axis.title.y = element_blank(),
                      ## Set margin and alignment for y-axis
                      axis.title.x = element_text(hjust = 0.5,
                                                  margin = margin(1.5,0,1.5,0,
                                                                  unit = "cm")),
                      ## Set legend position to none
                      legend.position = "none",
                      # legend.text = element_text(lineheight = unit(0.4, "pt")),
                      # legend.key = element_rect(unit(0.4, "pt")),
                      
                      ## Set plot background to empty
                      plot.background = element_blank(),
                      
                      plot.margin = unit(c(2.5, 5.5, 2.5, 5.5),
                                           "cm"),
                      
                      ## Set margin, alignment, line height, color and size for plot title
                      plot.title = element_text(lineheight = unit(0.8, "pt"),
                                                hjust = 0.5, color = "#073A5C",
                                                size = 50,
                                                margin = margin(0.5,0.5,2.5,0.5,
                                                                unit = "cm"),
                                                family = title_text),
                      ## Set alignment, color and size for plot subtitle
                      plot.subtitle = element_text(hjust = 0.5, face = "bold",
                                                   size = 35,
                                                   color = "#9E1111"),
                      ## Set alignment, color and size for plot caption
                      plot.caption = element_text(family = caption_text,
                                                  face = "italic", size = 25,
                                                  hjust = 1, color = "#787878",
                                                  lineheight = unit(0.8, "pt")),
                      
                      # Panel
                      panel.grid = element_line(colour = NULL),
                      panel.grid.major.y = element_line(colour = "#D2D2D2",
                                                        linetype = "dashed",
                                                        size = 0.3),
                      panel.grid.major.x = element_line(colour = "#D2D2D2",
                                                        linetype = "dashed",
                                                        size = 0.3),
                      panel.border = element_blank(),
                      # panel.grid.major.x = element_blank(),
                      panel.grid.minor = element_blank(),
                      panel.background = element_blank()) +
  
                  labs(title = "Age-sex structure of COVID-19 cases and deaths
                                \nin Eswatini (13 Mar - 30 December, 2020)",
                       subtitle = '{current_frame}',
                       x = "\n\nPercent of all confirmed cases (30 December, 2020)",
                       caption = 'Visualization:   @eOlamijuwon (Twitter) 
                                  \nData Source: Eswatini Government @EswatiniGovern1 (Twitter) 
                                  \nData Curator: #CoverAGE-DB (https://osf.io/mpwjq/)')

```

Next, we will use the `gganimate` 📦 to visualize and export the graph. We set the animation transition to change every day for which there's data. I used day and month since that uniquely identifies the date and the visualization focuses on just one year. We might have to include the year if we consider visualizing the data for periods covering March 2020 to April 2021.

We also set the animation parameters in `animate.` This includes the animation speed *(duration = 60s)*, and the size of the animation *(width = 2000, height = 1800)*. The start_pause and end_pause freeze-frame also makes it easy to have a closer look at the final distribution of confirmed cases of coronavirus in the country before the loop begins afresh

You may also need to disable your Anti-Virus for the animation to be saved on your computer. You can also read more about other possibilities with the📦 on the [**package website**](https://gganimate.com/articles/gganimate.html).

```{r}
SZ_animation <-   SZ_graph +
                  transition_manual(frames = day_month) +
                  enter_fade() +
                  exit_fade() + 
                  ease_aes('cubic-in-out')


                                     
animate(
  SZ_animation,
  fps = 6,
  duration = 65,
  width = 2000,
  height = 1800,
  start_pause = 2,
  end_pause = 90,
  renderer = gifski_renderer("Images/Eswatini_CoVID_Pyramid.gif"))

```

## Contact ✉️

I hope you found the tutorial useful. Like I mentioned in the introduction, the tutorial can be adapted to visualize other relevant social and demographic issues, including visualizing changes in population structure over time, among many others. If you have any suggestions for improving the tutorial or experience any difficulty with the codes in the tutorial,😞 please use the [**Contact Form**](http://e.olamijuwon.com/#contacts) to send me an email or reach me via Twitter: [**\@eOlamijuwon**](https://twitter.com/eolamijuwon). You can as well leave a comment.
