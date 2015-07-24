rm(list = ls())
# Immediately enter the browser/some function when an error occurs
#options(error = some funcion)

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
        selectizeInput('actionsTracked', 'Choose Actions to plot', choices = c("data not loaded"), multiple = TRUE),
        textInput("control_rate",
                  "Rate in seconds",
                  value = 3600),
        actionButton("go", "Plot")
      ),
      
    
    mainPanel(
      sliderInput(inputId = "opt.cex",
                  label = "Point Size (cex)",                            
                  min = 0, max = 2, step = 0.25, value = 1),
      sliderInput(inputId = "opt.cexaxis",
                  label = "Axis Text Size (cex.axis)",                            
                  min = 0, max = 2, step = 0.25, value = 1), 
               plotOutput("plot1"),
               DT::dataTableOutput("plotTable"),
               downloadButton('downloadSubset', 'Download Subset (coming soon)')
    )
    )
  )
)