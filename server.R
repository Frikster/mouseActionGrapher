rm(list = ls())

library(shiny)
library(DT)
library(rPython)
library(rsconnect)
library(RJSONIO)
library(matlab)
library(reshape)
options(shiny.maxRequestSize=30*1024^2) 

TAG_COL <- 1
TIME_COL <- 2
DATE_COL <- 3
ACTION_COL <- 4
TEXT_LOC_COL <- 5

shinyServer(function(input, output, clientData, session) {
  
  inFile<-reactive({
    input$file1
    if(is.null(input$file1)){
      if(input$preprocessButton==0){
        return(NULL)
      }
      else{ 
        python.load("Python-scripts/PreprocessTextfiles.py")
        python.call("PreprocessTextfiles",input$abs_start,input$abs_end,input$DIR_WITH_TEXTFILES,input$FOLDERS_TO_IGNORE,input$OUTPUT_LOC)
      }
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
    
    output$subsettingTable <- DT::renderDataTable(
      subsetTable(), filter = 'top', server = FALSE, 
      options = list(pageLength = 5, autoWidth = TRUE))
    
  # Subset between start and end with bin column and selected mice
  subsetTable<-reactive({
    subsetMice<-inFile()[inFile()[,TAG_COL]%in%input$tagChooser,]
    
    abs_start <- strptime(input$abs_start,"%Y-%m-%d %H:%M:%S",tz='US/Pacific')
    abs_end <- strptime(input$abs_end,"%Y-%m-%d %H:%M:%S",tz='US/Pacific')
    
    if(is.null(subsetMice)||nrow(subsetMice)<=0){
      return(NULL)
    }
    
    # subset between abs_start and abs_end 
    convertedDates<-strptime(as.character(subsetMice[,DATE_COL]),"%Y-%m-%d %H:%M:%S",tz='US/Pacific')
    inF<-subsetMice[convertedDates>abs_start&convertedDates<abs_end,]
    convertedDates<-convertedDates[convertedDates>abs_start&convertedDates<abs_end]
    
    # Compute bins
    bin_nos<-as.numeric(difftime(convertedDates, abs_start, units = "secs")) %/% as.numeric(input$binning)
    bin_nos<-bin_nos+1
    cbind(inF,bin_nos) 
    })
  
  # Set the subset for URP based on the subsetting tab
  subsetToPlot<-reactive({
    if(is.null(input$subsettingTable_rows_all)){
      subsetTable()
    }
    else{
      subsetTable()[input$subsettingTable_rows_all,]
    }
  })
  
  observe({ 
    if(!is.null(input$subsettingTable_rows_all)){
      updateSelectizeInput(session, "firstAction",
                           'Choose first action(s)',
                           choices = levels(subsetToPlot()[[ACTION_COL]]))
      updateSelectizeInput(session, "secondAction",
                           'Choose second action(s)',
                           choices = levels(subsetToPlot()[[ACTION_COL]]))
    }
  })
  
  # download the filtered data
  output$downloadSubset = downloadHandler('filtered.csv', content = function(file) {
    write.csv(subsetToPlot(), file)
  })
  
  # Plot histrogram of times between headfixes 
  # TODO: assumes all mice in same cage. Fix to make it work for a selection of mice from seperate cages
  output$plotHist<-renderPlot({
    input$goButton
    if(input$goButton==0){
      return()
    }
    isolate({
      subsetTable<-subsetToPlot()
      # Subset to get only rows with
      subsetTable<-subsetTable[subsetTable[,ACTION_COL]==input$firstAction|subsetTable[,ACTION_COL]==input$secondAction,]
      
      # Get the differences in time between each
      subsetTable_times<-strptime(subsetTable[,DATE_COL],"%Y-%m-%d %H:%M:%S",tz='US/Pacific')
      
      # Fill list with times between subsequent headfixes
      times_between<-c(NULL)
      for(i in 1:length(subsetTable_times)){
        if(i < length(subsetTable_times)){
          dif<-difftime(subsetTable_times[i+1],subsetTable_times[i],units="secs")
          if(dif < as.integer(input$cutOff) && subsetTable[i,ACTION_COL]==input$firstAction && subsetTable[i+1,ACTION_COL]==input$secondAction){
           times_between = append(times_between,dif)
          }
        }
      } 
      hist(times_between,breaks=input$histBreaks)
    })
  })
  
  plotHistData <- reactive({
    input$goButton
    if(input$goButton==0){
      return()
    }
    isolate({
    subsetTable<-subsetToPlot()
    # Subset to get only rows with one of the two actions
    subsetTable<-subsetTable[subsetTable[,ACTION_COL]==input$firstAction|subsetTable[,ACTION_COL]==input$secondAction,]
    
    # Get the differences in time between each
    subsetTable_times<-strptime(subsetTable[,DATE_COL],"%Y-%m-%d %H:%M:%S",tz='US/Pacific')
    
    # Fill list with times between subsequent headfixes
    times_between<-c(NULL)
    # Fill these lists with the tags, dates and textfile locs corresponding to action1 
    tags<-c(NULL)
    dates<-c(NULL)
    textFile_locs<-c(NULL)
    for(i in 1:length(subsetTable_times)){
      if(i < length(subsetTable_times)){
        dif<-difftime(subsetTable_times[i+1],subsetTable_times[i],units="secs")
        # Only add if we are below the cutOff, where the first action is before the second and where both actions are performed by the same mouse
        # NOTE and TODO: a limitation here is that only i and i+1 are checked. will need to make a O(N^2) loop to get them all that you'll need to speed up
        if(dif < as.integer(input$cutOff) && subsetTable[i,ACTION_COL]==input$firstAction && subsetTable[i+1,ACTION_COL]==input$secondAction && subsetTable[i,TAG_COL]==subsetTable[i+1,TAG_COL]){
          tag_col<-subsetTable[i,TAG_COL]
          date_col<-subsetTable[i,DATE_COL]
          text_loc_col<-subsetTable[i,TEXT_LOC_COL]
          # Drop levels from any factors
          if(class(tag_col)=='factor'){tag_col<-levels(droplevels(tag_col))}
          if(class(date_col)=='factor'){date_col<-levels(droplevels(date_col))}
          if(class(text_loc_col)=='factor'){text_loc_col<-levels(droplevels(text_loc_col))}
          times_between <- append(times_between,dif)
          tags<-append(tags,tag_col)
          dates<-append(dates,date_col)
          textFile_locs<-append(textFile_locs,text_loc_col)
        }
      }
    } 
    as.data.frame(cbind(times_between,tags,dates,textFile_locs))
    })
  })
  
  output$histTable <- DT::renderDataTable(
    plotHistData(), filter = 'top', server = FALSE, 
    options = list(pageLength = 5, autoWidth = TRUE))
  
  # download the filtered data
  output$downloadHistTable = downloadHandler('HistTable.csv', content = function(file) {
    write.csv(plotHistData(), file)
  })
  
  # plot the count of an action within bins for selected mice
  output$plotLine<-renderPlot({
    input$goButton
    if(input$goButton[1]==0){
      return(NULL)
    }
    isolate({
      # Fetch only the data that has been subsetted on in the subsetting tab
      subsetTable<-subsetToPlot()
      # Count number of items in each bin and display
      plot(table(subsetTable$bin_nos))
    })
  })
  
  output$plotLineTable <- DT::renderDataTable(
    rename(as.data.frame(table(subsetToPlot()$bin_nos)),c("Var1"="Bin")), filter = 'top', server = FALSE, 
    options = list(pageLength = 5, autoWidth = TRUE))
  
  # download the filtered data
  output$downloadPlotLineTable = downloadHandler('LinePlotTable.csv', content = function(file) {
    subsetTable<-subsetToPlot()
    write.csv(as.data.frame(table(subsetTable$bin_nos)), file)
  })
  
  output$lineTable <- DT::renderDataTable(
    subsetToPlot(), filter = 'top', server = FALSE, 
    options = list(pageLength = 5, autoWidth = TRUE))
  
  # download the filtered data
  output$downloadLineTable = downloadHandler('LineTable.csv', content = function(file) {
    write.csv(subsetToPlot(), file)
  })
  
  output$plotSDMap<-renderPlot({
    input$plotSDMapButton
    if(input$plotSDMapButton==0){
      return()
    }
    isolate({
      python.load("Python-scripts/TestScript.py")
      print("Fetching frames")
      start.time<-Sys.time()
      frames_raw<-python.call("get_frames",input$rawVid,256,256)
      end.time<-Sys.time()
      time.taken.get_frames <- end.time - start.time
      print(time.taken.get_frames)
      print("Computing standard deviation map")
      start.time<-Sys.time()
      frames_raw<-python.call("standard_deviation",frames_raw)
      end.time<-Sys.time()
      time.taken.standard_deviation <- end.time - start.time
      print(time.taken.standard_deviation)
      
      frame_processed<-zeros(length(frames_raw),length(frames_raw[[1]]))
      for(mCol in 1:length(frames_raw[[1]])){
        for(mRow in 1:length(frames_raw)){
          frame_processed[mRow,mCol]<-frames_raw[[mRow]][mCol]
        }
      }
      imagesc(frame_processed)
    })
  })
  
  output$plotAVGMap<-renderPlot({
    input$plotSDMapButton
    if(input$plotSDMapButton==0){
      return()
    }
    isolate({
      python.load("Python-scripts/TestScript.py")
      print("Fetching frames")
      start.time<-Sys.time()
      frames_raw<-python.call("get_frames",input$rawVid,256,256)
      end.time<-Sys.time()
      time.taken.get_frames <- end.time - start.time
      print(time.taken.get_frames)
      print("Computing mean map")
      start.time<-Sys.time()
      frames_raw<-python.call("calculate_avg",frames_raw)
      end.time<-Sys.time()
      time.taken.calculate_avg <- end.time - start.time
      print(time.taken.calculate_avg)
      
      frame_processed<-zeros(length(frames_raw),length(frames_raw[[1]]))
      for(mCol in 1:length(frames_raw[[1]])){
        for(mRow in 1:length(frames_raw)){
          frame_processed[mRow,mCol]<-frames_raw[[mRow]][mCol]
        }
      }
      imagesc(frame_processed)
    })
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



  
  
  
