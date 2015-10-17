rm(list = ls())
# Immediately enter the browser/some function when an error occurs
# options(error = some funcion)

library(shiny)
library(DT)
library(rsconnect)
library(RJSONIO)
library(rPython)
library(matlab)


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
        textInput("abs_start","Insert start date and time. Format: %Y-%m-%d %H:%M:%S",value="1900-01-01 01:00:00"),
        textInput("abs_end","Insert end date and time. Format: %Y-%m-%d %H:%M:%S",value="2100-01-01 01:00:00"),
        actionButton("goButton", "Plot")
      ),
      
    
    mainPanel(
      tabsetPanel(
        id = 'tab',
        tabPanel('Preprocess',
                 p("WARNING: PREPROCESSING WILL CRASH THE APP WHEN WORKING ONLINE"),
                 p("But it should work offline"),
                 textInput("DIR_WITH_TEXTFILES","Enter full path to directory containing text files",value="/media/cornelis/DataCDH/Raw-data"),
                 textInput("FOLDERS_TO_IGNORE","Enter the names of any folders to ignore in this directory (seperate with commas)",value="Old and or nasty data goes here"),
                 textInput("OUTPUT_LOC","Enter the path to the directory to output to",value="/home/cornelis/Downloads/"),
                 actionButton("preprocessButton", "Preprocess Textfiles"),
                 p("Click to generate a spreadsheet of all data between the dates selected on the left")  
        ),
        tabPanel('Subsetting',       
                 hr(),
                 DT::dataTableOutput("subsettingTable"),
                 downloadButton('downloadSubset', 'Download Subset')
        ),   
        tabPanel('Histrogram', 
                 sliderInput("histBreaks", label = "Adjust break number", min = 2, max = 500, value = 10),
                 textInput("cutOff","Enter cut-off. Values above this will not be displayed",value = 1000000),
                 p("Histrogram shows times between occurence of first action and second action chosen below"),
                 p("The first and second action can be identical to get all the times between"),
                 p("Multiple first and second actions can also be chosen. All times between any in first and any in second will be plotted"),
                 selectizeInput('firstAction', 'Choose first action(s)', choices = c("data not loaded"), multiple = FALSE),
                 selectizeInput('secondAction', 'Choose second action(s)', choices = c("data not loaded"), multiple = FALSE),
                 plotOutput("plotHist"),
                 DT::dataTableOutput("histTable"),
                 downloadButton('downloadHistTable', 'Download Histrogram Table')
        ),
        tabPanel('Line',
                 textInput("binning", "Binning in seconds",value = 86400),
                 plotOutput("plotLine"),
                 DT::dataTableOutput("plotLineTable"),
                 downloadButton('downloadPlotLineTable', 'Download Line Table'),
                 DT::dataTableOutput("lineTable"),
                 downloadButton('downloadLineTable', 'Download Additional Graph Info')),
        tabPanel('Brain Imaging',
                 p("WARNING: NOTHING IN THIS TAB WORKS ONLINE AND WILL CRASH THE APP"),
                 textInput("rawVid", label = h3("Raw Video Input"), value = "/media/cornelis/DataCDH/Raw-data/Test Data/0910/EL_noled/Videos/M1312000377_1441918144.56571.raw"),
                 actionButton("plotSDMapButton", label = "Pray it works"),
                 p("Standard Deviation Map"),
                 plotOutput('plotSDMap'),
                 p("Average Map"),
                 plotOutput('plotAVGMap'))
      )
    )
    )
  )
)