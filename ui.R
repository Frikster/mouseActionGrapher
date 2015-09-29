rm(list = ls())
# Immediately enter the browser/some function when an error occurs
# options(error = some funcion)

library(shiny)
library(DT)


shinyUI(fluidPage(
  titlePanel("MurphyLab"),
  sidebarLayout(
    sidebarPanel(
        fileInput('file1', 'Choose CSV File',
                  accept=c('text/csv', 
                           'text/comma-separated-values,text/plain', 
                           '.csv')),
        checkboxInput('header', 'Header', TRUE),
        radioButtons('sep', 'Separator',
                     c(Comma=',',
                       Semicolon=';',
                       Tab='\t'),
                     ','),
        radioButtons('quote', 'Quote',
                     c(None='',
                       'Double Quote'='"',
                       'Single Quote'="'"),
                     '"'),
        selectizeInput('tagChooser', 'Choose Tags to plot', choices = c("data not loaded"), multiple = TRUE),
        textInput("abs_start","Insert start date and time. Format: %Y-%m-%d %H:%M:%S",value="2015-06-25 01:00:00"),
        textInput("abs_end","Insert end date and time. Format: %Y-%m-%d %H:%M:%S",value="2015-06-30 01:00:00"),
        textInput("binning", "Binning in seconds",value = 86400),
        actionButton("goButton", "Plot")
      ),
      
    
    mainPanel(
      tabsetPanel(
        id = 'tab',
        tabPanel('Subsetting',       
                 hr(),
                 DT::dataTableOutput("subsettingTable"),
                 downloadButton('downloadSubset', 'Download Subset'),
                 actionButton("setSubsetToURP", "Use filtered subset (not yet available. Instead download the subset you want, rename it to whatever you want and upload it and then go to the URP tab)")
        ),   
        tabPanel('Histrogram', 
                 sliderInput("histBreaks", label = "Adjust break number", min = 2, max = 500, value = 10),
                 plotOutput("plotHist")),
        tabPanel('Line',
                 plotOutput("plotLine", inline = TRUE,width='auto',height='auto'))
      )
    )
    )
  )
)