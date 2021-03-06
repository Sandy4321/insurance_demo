library(shiny)
library(ggplot2)
library(randomForest)

shinyServer(function(input, output) {

  dataset <- reactive({
    print("creating dataset...")
    subset <- ticcompl[sample(nrow(ticcompl), input$sampleSize),]
  })
  
  traindataset <- reactive({
    subset <- ticcompl[sample(nrow(ticcompl), input$sampleSize),]
  })
  
  output$plotall <- renderPlot({
    
    p <- ggplot(dataset(), aes_string(x=input$x, y=input$y)) + theme(axis.text.x = element_text(angle = 40,hjust=1))

    p <- p + xlab(col_dict[names(ticcompl) == input$x]) + ylab(col_dict[names(ticcompl) == input$y])
    
    if (input$color != 'None') {
      p <- p + aes_string(color=input$color)
    }
    
    if (input$jitterStrength > 0) {
      width_strength <- ifelse(is.factor(ticcompl[[input$x]]),
                               nlevels(ticcompl[[input$x]]),
                               diff(range(ticcompl[[input$x]]))) * 0.01 * input$jitterStrength
      height_strength <- ifelse(is.factor(ticcompl[[input$y]]),
                               nlevels(ticcompl[[input$y]]),
                               diff(range(ticcompl[[input$y]]))) * 0.01 * input$jitterStrength
      p <- p + geom_jitter(position=position_jitter(width=width_strength,height=height_strength),alpha=input$alphaStrength)
    } else {
      p <- p + geom_point(alpha=input$alphaStrength)
    }
    
    print(p)
  })
  
  output$plotmarketing <- renderPlot({
    plotData <- selectedData()
    
    plotData$comb_range <- ifelse(plotData$comb_range,'black','Predict No Buy')
    plotData$comb_range <- ifelse(plotData$comb_range == 'black',
                                  ifelse(plotData$CARAVAN == 1,'Correctly Predicted Buy','Incorrectly Predicted Buy'),
                                  plotData$comb_range)
    
    plotData$comb_range <- factor(plotData$comb_range)
        
    p <- ggplot(plotData, aes_string(x=input$x, y=input$y)) + theme(axis.text.x = element_text(angle = 40, hjust = 1))
    
    p <- p + xlab(col_dict[names(ticcompl) == input$x]) + ylab(col_dict[names(ticcompl) == input$y])

    if (input$color != 'None')
      p <- p + aes_string(color=input$color)
    
    if (input$jitterStrength > 0) {
      width_strength <- ifelse(is.factor(ticcompl[[input$x]]),
                               nlevels(ticcompl[[input$x]]),
                               diff(range(ticcompl[[input$x]]))) * 0.01 * input$jitterStrength
      height_strength <- ifelse(is.factor(ticcompl[[input$y]]),
                                nlevels(ticcompl[[input$y]]),
                                diff(range(ticcompl[[input$y]]))) * 0.01 * input$jitterStrength
      p <- p + geom_jitter(position=position_jitter(width=width_strength,height=height_strength),alpha=input$alphaStrength)
    } else {
      p <- p + geom_point(alpha=input$alphaStrength)
    }
    
    p <- p + aes_string(color='comb_range') + scale_colour_manual(values = colorpalette)
    
    print(p)
    
  })
  
  output$mktconfusionMatrix <- renderTable({
    plotData <- selectedData()
    
    plotData$comb_range <- ifelse(plotData$comb_range,"Predict Buy","Predict No Buy")
    plotData$CARAVAN <- ifelse(plotData$CARAVAN == 0,"Actual No Buy","Actual Buy")
        
    table(plotData$CARAVAN,plotData$comb_range)
  })
  
  output$mktCostAnalysis <- renderTable({
    values <- tradTargeting()
    values[c(3,6,7)] <- paste(round(values[c(3,6,7)],digits=2),'%')
    
    data.frame(row.names=descriptions,Traditional.Targeting=values)
  })
  
  tradTargeting <- reactive({
    print("in tradTargeting...")
    plotData <- selectedData()
    print("data generated...")
    
    succSpend <- length(which(plotData$comb_range & plotData$CARAVAN == 1))/length(which(plotData$comb_range))*100
    realPot <- length(which(plotData$comb_range & plotData$CARAVAN == 1))/length(which(plotData$CARAVAN == 1))*100
    roi <- ((length(which(plotData$comb_range & plotData$CARAVAN == 1))*as.numeric(input$mktReturn))/
              (length(which(plotData$comb_range))*as.numeric(input$mktCost)))*100-100
    
    values <- c(length(which(plotData$comb_range))*as.numeric(input$mktCost),
                length(which(plotData$comb_range & plotData$CARAVAN == 1))*as.numeric(input$mktCost),
                succSpend,
                length(which(plotData$CARAVAN == 1))*as.numeric(input$mktReturn),
                length(which(plotData$comb_range & plotData$CARAVAN == 1))*as.numeric(input$mktReturn),
                realPot,
                roi)
    
    return(values)
  })
  
#   output$plotdatascience <- renderPlot({
#     plotData <- dataset()
# 
#     plotData$predictions <- eval(call(input$predictFcnName))
# 
#     p <- ggplot(plotData, aes_string(x=input$x, y=input$y))
#     
#     p <- p + xlab(col_dict[names(ticcompl) == input$x]) + ylab(col_dict[names(ticcompl) == input$y])
#     
#     if (input$color != 'None')
#       p <- p + aes_string(color=input$color)
#     
#     if (input$jitterStrength > 0) {
#       width_strength <- ifelse(is.factor(ticcompl[[input$x]]),
#                                nlevels(ticcompl[[input$x]]),
#                                diff(range(ticcompl[[input$x]]))) * 0.01 * input$jitterStrength
#       height_strength <- ifelse(is.factor(ticcompl[[input$y]]),
#                                 nlevels(ticcompl[[input$y]]),
#                                 diff(range(ticcompl[[input$y]]))) * 0.01 * input$jitterStrength
#       p <- p + geom_jitter(position=position_jitter(width=width_strength,height=height_strength),alpha=input$alphaStrength)
#     } else {
#       p <- p + geom_point(alpha=input$alphaStrength)
#     }
#     
#     p <- p + aes_string(color='predictions')
#         
#     print(p)
#   })
  
  output$plotdatascienceclassification <- renderPlot({
    print("predicting with randomForest...")
    plotData <- dataset()
    
    print("predicting with randomForest...")
    plotData$predictions <- eval(call(input$predictFcnName))[[1]]
    
    print("assigning predictions...")
    
    plotData$predictions <- ifelse(plotData$predictions,'black','Predict No Buy')
    plotData$predictions <- ifelse(plotData$predictions == 'black',
                                   ifelse(plotData$CARAVAN == 1,'Correctly Predicted Buy','Incorrectly Predicted Buy'),
                                   plotData$predictions)
    
    p <- ggplot(plotData, aes_string(x=input$x, y=input$y)) + theme(axis.text.x = element_text(angle = 40, hjust = 1))
    
    p <- p + xlab(col_dict[names(ticcompl) == input$x]) + ylab(col_dict[names(ticcompl) == input$y])
    
    if (input$color != 'None')
      p <- p + aes_string(color=input$color)
    
    if (input$jitterStrength > 0) {
      width_strength <- ifelse(is.factor(ticcompl[[input$x]]),
                               nlevels(ticcompl[[input$x]]),
                               diff(range(ticcompl[[input$x]]))) * 0.01 * input$jitterStrength
      height_strength <- ifelse(is.factor(ticcompl[[input$y]]),
                                nlevels(ticcompl[[input$y]]),
                                diff(range(ticcompl[[input$y]]))) * 0.01 * input$jitterStrength
      p <- p + geom_jitter(position=position_jitter(width=width_strength,height=height_strength),alpha=input$alphaStrength)
    } else {
      p <- p + geom_point(alpha=input$alphaStrength)
    }
    
    p <- p + aes_string(color='predictions') + scale_colour_manual(values = colorpalette)
    
    print(p)
  })
  
#   output$plotperfcurve <- renderPlot({
#     plotData <- dataset()
#     
#     i <- 1
#     fscore <- c()
#     xval <- seq(0,0.3,0.005)
#     for (cutoff in xval) {
#       plotData$predictions <- eval(call(input$predictFcnName))
#       plotData$predictions <- ifelse(plotData$predictions < cutoff,FALSE,TRUE)
#       
#       true_pos <- length(which(plotData$predictions & plotData$CARAVAN == 1))
#       true_neg <- length(which(!plotData$predictions & plotData$CARAVAN == 0))
#       false_pos <- length(which(plotData$predictions & plotData$CARAVAN == 0))
#       false_neg <- length(which(!plotData$predictions & plotData$CARAVAN == 1))
#       
#       prec <- true_pos/(true_pos+false_pos)
#       recall <- true_pos/(true_pos+false_neg)
#       
#       fscore[i] <- 2 * (prec*recall)/(prec+recall)
#       i <- i + 1
#     }
#     perfData <- data.frame(fscore=fscore,cutoff=xval)
#     
#     p <- ggplot(perfData, aes_string(x='cutoff', y='fscore')) + geom_line()
# 
#     print(p)
#   })

  output$dsconfusionMatrix <- renderTable({
    plotData <- dataset()
    
    plotData$predictions <- eval(call(input$predictFcnName))[[1]]
    
    plotData$predictions <- ifelse(plotData$predictions,"Predict Buy","Predict No Buy")
    plotData$CARAVAN <- ifelse(plotData$CARAVAN == 0,"Actual No Buy","Actual Buy")
    
    table(plotData$CARAVAN,plotData$predictions)
  })
  
  output$dsCostAnalysis <- renderTable({
    plotData <- dataset()
    
    plotData$predictions <- eval(call(input$predictFcnName))[[1]]
    
    nPredictions <- length(which(plotData$predictions))
    nSuccPredictions <- length(which(plotData$predictions & plotData$CARAVAN == 1))
    nInsurances <- length(which(plotData$CARAVAN == 1))
    
    succSpend <- nSuccPredictions/nPredictions*100
    realPot <- nSuccPredictions/nInsurances*100
    roi <- (nSuccPredictions*as.numeric(input$mktReturn)*100)/(nPredictions*as.numeric(input$mktCost))-100
    
    values <- c(nPredictions*as.numeric(input$mktCost),
                nSuccPredictions*as.numeric(input$mktCost),
                succSpend,
                nInsurances*as.numeric(input$mktReturn),
                nSuccPredictions*as.numeric(input$mktReturn),
                realPot,
                roi)
    
    # Traditional Targeting
    valuesTrad <- tradTargeting()
    
    ratio <- values/valuesTrad
    ratio <- round(ratio,digits=2)
    values[c(3,6,7)] <- paste(round(values[c(3,6,7)],digits=2),'%')
    valuesTrad[c(3,6,7)] <- paste(round(valuesTrad[c(3,6,7)],digits=2),'%')

    data.frame(row.names=descriptions,Model.Targeting=values,Traditional.Targeting=valuesTrad, Ratio=ratio)
  })
  
#   output$selectXcontrols <- renderUI({
#     
#     if (is.factor(dataset()[[input$x]]))
#       choices <- levels(dataset()[[input$x]])
#     else
#       choices <- sort(unique(dataset()[[input$x]]))
#     
#     checkboxGroupInput("selectedX", "Select X Values", choices, selected = choices)
#   })
#   
#   output$selectYcontrols <- renderUI({
#     if (is.factor(dataset()[[input$y]]))
#       choices <- levels(dataset()[[input$y]])
#     else
#       choices <- sort(unique(dataset()[[input$y]]))
# 
#     checkboxGroupInput("selectedY", "Select Y Values", choices, selected = choices)
#   })
  
  output$selectDim1controls <- renderUI({
    if (input$dim1 != '') {
      if (is.factor(dataset()[[input$dim1]]))
        choices <- levels(dataset()[[input$dim1]])
      else
        choices <- sort(unique(dataset()[[input$dim1]]))
      
      checkboxGroupInput("selectedDim1", "Select Variable 1 Values", choices, selected = choices)
    } else {
      NULL
    }
  })
  
  output$selectDim2controls <- renderUI({
    if (input$dim2 != '') {
      if (is.factor(dataset()[[input$dim2]]))
        choices <- levels(dataset()[[input$dim2]])
      else
        choices <- sort(unique(dataset()[[input$dim2]]))
      
      checkboxGroupInput("selectedDim2", "Select Variable 2 Values", choices, selected = choices)
    } else {
      NULL
    }
  })
  
  output$selectDim3controls <- renderUI({
    if (input$dim3 != '') {
      if (is.factor(dataset()[[input$dim3]]))
        choices <- levels(dataset()[[input$dim3]])
      else
        choices <- sort(unique(dataset()[[input$dim3]]))
      
      checkboxGroupInput("selectedDim3", "Select Variable 3 Values", choices, selected = choices)
    } else {
      NULL
    }
  })
  
  output$selectDim4controls <- renderUI({
    if (input$dim4 != '') {
      if (is.factor(dataset()[[input$dim4]]))
        choices <- levels(dataset()[[input$dim4]])
      else
        choices <- sort(unique(dataset()[[input$dim4]]))
      
      checkboxGroupInput("selectedDim4", "Select Variable 4 Values", choices, selected = choices)
    } else {
      NULL
    }
  })
  
  output$selectDim5controls <- renderUI({
    if (input$dim5 != '') {
      if (is.factor(dataset()[[input$dim5]]))
        choices <- levels(dataset()[[input$dim5]])
      else
        choices <- sort(unique(dataset()[[input$dim5]]))
      
      checkboxGroupInput("selectedDim5", "Select Variable 5 Values", choices, selected = choices)
    } else {
      NULL
    }
  })
  
#   output$selectDim6controls <- renderUI({
#     if (is.factor(dataset()[[input$dim6]]))
#       choices <- levels(dataset()[[input$dim6]])
#     else
#       choices <- sort(unique(dataset()[[input$dim6]]))
#     
#     checkboxGroupInput("selectedDim6", "Select Variable 6 Values", choices, selected = choices)
#   })
#   
#   output$selectDim7controls <- renderUI({
#     if (is.factor(dataset()[[input$dim7]]))
#       choices <- levels(dataset()[[input$dim7]])
#     else
#       choices <- sort(unique(dataset()[[input$dim7]]))
#     
#     checkboxGroupInput("selectedDim7", "Select Variable 7 Values", choices, selected = choices)
#   })
#   
#   output$selectDim8controls <- renderUI({
#     if (is.factor(dataset()[[input$dim8]]))
#       choices <- levels(dataset()[[input$dim8]])
#     else
#       choices <- sort(unique(dataset()[[input$dim8]]))
#     
#     checkboxGroupInput("selectedDim8", "Select Variable 8 Values", choices, selected = choices)
#   })
#   
#   output$selectDim9controls <- renderUI({
#     if (is.factor(dataset()[[input$dim9]]))
#       choices <- levels(dataset()[[input$dim9]])
#     else
#       choices <- sort(unique(dataset()[[input$dim9]]))
#     
#     checkboxGroupInput("selectedDim9", "Select Variable 9 Values", choices, selected = choices)
#   })
#   
#   output$selectDim10controls <- renderUI({
#     if (is.factor(dataset()[[input$dim10]]))
#       choices <- levels(dataset()[[input$dim10]])
#     else
#       choices <- sort(unique(dataset()[[input$dim10]]))
#     
#     checkboxGroupInput("selectedDim10", "Select Variable 10 Values", choices, selected = choices)
#   })
  
  predictRandomForest <- reactive({
    print("training random Forest")
    rf <- trainRandomForest()
    print(rf)
    
    predictions <- predict(rf,dataset()[,2:85],type='prob')[,2]
    predictions <- ifelse(predictions < input$classCutoff^2,FALSE,TRUE)
        
    return(list(predictions,rf))
  })
  
  trainRandomForest <- reactive({
    print("loading randomForest library...")
    trainData <- traindataset()
    print("loaded library + dataset...")
    #trainData[,86] <- factor(trainData[,86])
    
    
    posPrior <- length(which(trainData$CARAVAN == 1))/length(trainData$CARAVAN)
    negPrior <- length(which(trainData$CARAVAN == 0))/length(trainData$CARAVAN)
    
    print("training RF model...")
    
    rf <- randomForest(trainData[,2:85],trainData[,86],classwt=c(negPrior,posPrior),ntree=300,do.trace=T)
    
    return(rf)
  })
  
  predictLogisticRegression <- reactive({
    glmmodel <- trainLogisticRegression()
    Xtest <- model.matrix(CARAVAN ~ . , data=dataset())
    predictions <- predict(glmmodel,Xtest,type='response')
    predictions <- as.vector(predictions)
    predictions <- ifelse(predictions < input$classCutoffLR,FALSE,TRUE)
    
    return(list(predictions,glmmodel))
  })
  
  trainLogisticRegression <- reactive({
    library("glmnet")
    trainData <- traindataset()
    #trainData[,86] <- factor(trainData[,86])
    
    posPrior <- length(which(trainData$CARAVAN == 1))/length(trainData$CARAVAN)
    negPrior <- length(which(trainData$CARAVAN == 0))/length(trainData$CARAVAN)
    weightvec <- ifelse(trainData[,86] == 0,posPrior,negPrior)
    
    X <- model.matrix(CARAVAN ~ . , data=trainData)
    glmmodel <- cv.glmnet(x=X,y=trainData[,86],family="binomial",nfolds=3,weights=weightvec)
    
    return(glmmodel)
  })
  
  selectedData <- reactive({
    plotData <- dataset()
    
    if (input$dim1 == '') 
      plotData$dim1range <- T
    else
      plotData$dim1range <- plotData[[input$dim1]] %in% input$selectedDim1
    
    if (input$dim2 == '') 
      plotData$dim2range <- T
    else
      plotData$dim2range <- plotData[[input$dim2]] %in% input$selectedDim2
    
    if (input$dim3 == '') 
      plotData$dim3range <- T
    else
      plotData$dim3range <- plotData[[input$dim3]] %in% input$selectedDim3
    
    if (input$dim4 == '') 
      plotData$dim4range <- T
    else
      plotData$dim4range <- plotData[[input$dim4]] %in% input$selectedDim4
    
    if (input$dim5 == '') 
      plotData$dim5range <- T
    else
      plotData$dim5range <- plotData[[input$dim5]] %in% input$selectedDim5
    
#     if (input$dim6 == '') 
#       plotData$dim6range <- T
#     else
#       plotData$dim6range <- plotData[[input$dim6]] %in% input$selectedDim6
#     
#     if (input$dim7 == '') 
#       plotData$dim7range <- T
#     else
#       plotData$dim7range <- plotData[[input$dim7]] %in% input$selectedDim7
#     
#     if (input$dim8 == '') 
#       plotData$dim8range <- T
#     else
#       plotData$dim8range <- plotData[[input$dim8]] %in% input$selectedDim8
#     
#     if (input$dim9 == '') 
#       plotData$dim9range <- T
#     else
#       plotData$dim9range <- plotData[[input$dim9]] %in% input$selectedDim9
#     
#     if (input$dim10 == '') 
#       plotData$dim10range <- T
#     else
#       plotData$dim10range <- plotData[[input$dim10]] %in% input$selectedDim10
    
    plotData$comb_range <- plotData$dim1range & plotData$dim2range & plotData$dim3range & plotData$dim4range & plotData$dim5range
        # & plotData$dim6range & plotData$dim7range & plotData$dim8range & plotData$dim9range & plotData$dim10range
    
    return(plotData)
  })
  
  output$randomForestVarImp <- renderTable({
    if (input$predictFcnName == "predictRandomForest") {
      rf <- eval(call(input$predictFcnName))[[2]]
      impVars <- importance(rf)[order(importance(rf),decreasing=T)[1:10],]
      
      impVarNames <- sapply(names(impVars),function(name) col_dict[which(names(dataset()) == name)])
      
      data.frame(row.names=impVarNames,Importance=impVars)
    } else {
      data.frame()
    }
  })
  
#   output$logisticRegressionCoeff <- renderTable({
#     if (input$predictFcnName == "predictLogisticRegression") {
#       logreg <- eval(call(input$predictFcnName))[[2]]
#       browser()
#       data.frame(row.names=impVarNames,Importance=impVars)
#     } else {
#       data.frame()
#     }
#   })
  
})
