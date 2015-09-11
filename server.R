rm(list = ls())

library(shiny)
library(leaflet)
library(DT)
library(stringr)
library(zoo)
options(shiny.maxRequestSize=30*1024^2) 

TAG_COL <- 1
TIME_COL <- 2
DATE_COL <- 3
ACTION_COL <- 4

HEADFIX_STR <- 'reward0'

shinyServer(function(input, output, clientData, session) {
  
  inFile<-reactive({
    input$file1
    if(is.null(input$file1)){
      return(NULL)
    }
    else{
      inF<-read.csv(input$file1$datapath, header=input$header, sep=input$sep, quote=input$quote) 
      inF
    }
  })
  
    observe({ 
      if(!is.null(inFile)){
        updateSelectizeInput(session, "tagChooser",
                             'Choose Tags to plot',
                             choices = unique(inFile()[[TAG_COL]]))
      }
    })
  
  # Subset between start and end with bin column and selected mice
  subsetTable<-reactive({
    subsetMice<-inFile()[inFile()[,TAG_COL]%in%input$tagChooser,]
    
    abs_start <- strptime(input$abs_start,"%Y-%m-%d %H:%M:%S",tz='US/Pacific')
    abs_end <- strptime(input$abs_end,"%Y-%m-%d %H:%M:%S",tz='US/Pacific')
    
    if(is.null(subsetMice)||nrow(subsetMice)<=0){
      return()
    }
    
    # subset between abs_start and abs_end 
    convertedDates<-strptime(as.character(subsetMice[,DATE_COL]),"%Y-%m-%d %H:%M:%S",tz='US/Pacific')
    inF<-subsetMice[convertedDates>abs_start&convertedDates<abs_end,]
    convertedDates<-convertedDates[convertedDates>abs_start&convertedDates<abs_end]
    
    bins<-seq(abs_start,abs_end,by=as.integer(input$binning))
    bin_no<-length(bins)
    
    bin_nos<-c(NULL)
    bin_starts<-c(NULL)
    for(i in 1:length(convertedDates)){
     for(j in 1:length(bins)){
        # Check if at right bin
        if(!is.na(bins[j+1])){
          if(bins[j]<=convertedDates[i]&&convertedDates[i]<bins[j+1]){
            bin_nos[i] <- j
            bin_starts[i] <- bins[j]
            break
          }
        }
       else{
         stopifnot(bins[j]<=convertedDates[i])
         bin_nos[i] <- j
         bin_starts[i] <- bins[j]
       }
      }
    }
    browser()
    cbind(inF,bin_starts,bin_nos) 
    })
  
#   output$subsettingTable <- DT::renderDataTable(
#     subsetTable()[,drop=FALSE], filter = 'top', server = TRUE, 
#       options = list(pageLength = 5, autoWidth = TRUE))
  
  

    
  # Plot histrogram of times between headfixes 
  # TODO: assumes all mice in same cage. Fix to make it work for a selection of mice from seperate cages
  output$plotHist<-renderPlot({
    input$goButton
    if(input$goButton==0){
      return()
    }
    isolate({
      subsetTable()
      hist()
      
      # Subset to get headfixes
      subsetHeadfixes<-subsetTable()[subsetTable()[,ACTION_COL]==HEADFIX_STR]
      
      # Get the 
      strptime(subsetHeadfixes[,DATE_COL],"%Y-%m-%d %H:%M:%S",tz='US/Pacific')
      
      # Fill list with times between subsequent headfixes
      times_between<-c(NULL)
      
      for(a_row in subsetTable()){
        if(a_row[ACTION_COL]==HEADFIX_STR){
          
        }
      }
    
     
      
      HEADFIX_STR
      
      #[timesbetweens, timesbetweens_cutoff] = hists_for_selected_mice('reward0', 'check+', 20, cfg.TAGS, 600)
  
    })
  })
  
  output$plotLine<-renderPlot({
    
  })
  
})
  

  
# theChosenDates<-reactive({
#   # Convert to dates dates
#   browser()
#   zoo(inFile()[,TIME_COL], structure(inFile()[,TIME_COL], class = c("POSIXt", "POSIXct")))
#   browser()
# })  
#   
# 
# # Add column specifying the bin number a line belongs to    
# binnedDates<-reactive({
#     theChosenSeconds<- as.numeric(theChosenDates())
#     
#     # aggregate POSIXct seconds data every input$control_rate seconds
#     # http://stackoverflow.com/questions/5624140/binning-dates-in-r <== Thank you Dirk you are a God-genius of stack overflow and I worship your sexy manliness
#     tt <- seq(min(theChosenRows()[,TIME_COL]),max(theChosenRows()[,TIME_COL]), as.integer(input$control_rate))
#     x <- zoo(tt, structure(tt, class = c("POSIXt", "POSIXct")))
#     
#     browser()
#     
#     aggregate(x, time(x) - as.numeric(time(x)) %% 600, mean)
# })
#   
#   

  

  





































#   observe({ 
#     if(!is.null(inFile)){
#       updateSelectizeInput(session, "tagChooser",
#                            'Choose Tags to plot',
#                            choices = unique(inFile()[[1]]))
#     }
#   })



# theChosenDates<-reactive({
#   # Convert to dates dates
#   zoo(theChosenRows()[,2], structure(theChosenRows()[,2], class = c("POSIXt", "POSIXct")))
# })  
# 
# 
# theChosenRows<-reactive({
#   # Subset and select only particular tags
#   theChosen<-inFile()[inFile()[,1]%in%input$tagChooser,]
#   # Order will show you The Way ChosenRows
#   theChosen[order(theChosen[,2]),]
# })


# actFreqs<-reactive({
#   binnedSeconds<-as.numeric(binnedDates())
#   theChosenSeconds<- as.numeric(theChosenDates())
#   
#   # My fail going nowhere but still potentially useful so still here attempt
#   # cut(theChosenRows[,2], right = FALSE, breaks = seq(0,max(theChosenRows[,2]), by=3600))
#   uniqueActs<-unique(theChosenRows()[,4])
#   noOfCounts<-(length(binnedSeconds)-1)
#   # Create a lists for each act that is to contain all the counts over time
#   actFreqs<-rep( list(list(rep(0,noOfCounts))),length(uniqueActs)) 
#   names(actFreqs)<-uniqueActs
#   # Now let's get a count of all the happy actions inbetween the bins
#   for(actInd in 1:length(uniqueActs)){
#     j <- 1
#     for(i in 1:length(binnedSeconds)){
#       j<-j+1
#       # Do not attempt to check for a bin beyond the last value
#       if(j<length(binnedSeconds))
#       {
#         # Find which indices are between the two binnedSeconds values
# 
#         inds<-(theChosenSeconds>=binnedSeconds[i]&theChosenSeconds<binnedSeconds[j])
#         if(TRUE %in% inds){
#           # Find how many values there are for each action at those inds
#           actionTable<-table(theChosenRows()[[4]][inds])
#           # Retrieve the number between the bins of the particular action currently being looked at in the loop
#           actCount<-actionTable[names(actionTable)==uniqueActs[actInd]]
#           # Add to list of lists (counts for each action)
#           if(length(actCount)!=0){
#             actFreqs[actInd][[1]][[1]][i]<-actCount
#           }
#         }
#       }
#     }
#   }
#   actFreqs
# })
# 
# output$plot1<-renderPlot({
#   if(input$go>0){
#     isolate({
#       if(!is.null(inFile())&&input$tagChooser!="data not loaded")
#         {
#         # http://stackoverflow.com/questions/8967079/r-zoo-show-a-tick-every-year-on-x-axis
#         #del binnedDates()(-1)
#         # Remove the last date so that x and y axis's have the same number of elements
#         binnedDates<-binnedDates()[1:length(binnedDates())-1]
#         ind <- seq(1, length(binnedDates),by=as.integer(length(binnedDates/12)))
#         plot(binnedDates,actFreqs()$entry[[1]],type="l",xaxt="n",cex=input$opt.cex, cex.lab=input$opt.cexaxis)
#         axis(1,time(binnedDates[ind], format(time(binnedDates[ind]), las=2, cex.axis=0.5)))
#         #axis(1, at=seq(min(binnedDates),max(binnedDates),by="day"), format="%m-%d-%Y %H:%M:%S")
#         }
#     })
#   }
# }) 



  
  
  
