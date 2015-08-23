#Project Practical ML Coursera Arvind WOrk
library(caret)
# Set workspace. Chnage for Your machine
WorkingDir="I:/Users/Arvind/Downloads/MOOC/MAchineLearning/Class_Practical ML/Exercises/Project"
# Read data in
setwd(WorkingDir)
pml.training <- read.csv("pml-training.csv") # 19622 rows of 160 columns
pml.testing <- read.csv("pml-testing.csv") # 20 rows of 160 Variables
#drop uneseccary bookkeeping  colums
pml.training<-pml.training[-c(1:5,7)] # 154 columns
pml.testing<-pml.testing[-c(1:5,7)] #154 columns

# Exploratory work shows use 52 columns with No NA values

# # get Numeric columns 
num<-sapply(pml.training, is.numeric)
X.num<-pml.training[num] #119Vars numericonly
X.nonum<-pml.training[num==FALSE]# 35 vars non numeric 


# Find columnn with NA and remove them
na_count <-sapply(pml.training, function(y) sum(length(which(is.na(y)))))
na_count <- data.frame(na_count)
na_col<-subset(na_count,na_count==0)# 87 predictors only!!
X.noNAN<-pml.training[names(pml.training) %in% rownames(na_col)]#87 variables no NAN but Factors also
X.noNAN<-cbind(X.noNAN,pml.training$classe)
# Rename Column 
names(X.noNAN)[names(X.noNAN)=="pml.training$classe"] <- "classe" # Not NA but FActor also

# Non NUmeric and No NAN Data
X.noNANnum<-X.num[names(X.num) %in% rownames(na_col)]# 52 Vars numeric and no NA in rows
X.noNANnum<-cbind(X.noNANnum,pml.training$classe)
# Rename Column 
names(X.noNANnum)[names(X.noNANnum)=="pml.training$classe"] <- "classe"
#use Non numeric, non NA predictors

X.train<-X.noNANnum # Final Run 19,622 obs of 52 variables +Outcme classe

#
inTrain = createDataPartition(X.train$classe, p = 0.6)[[1]]
TrainData = X.train[ inTrain,]
TestData = X.train[-inTrain,]


# Final-----------------------------------------------------------------

library(caret)



# Final Random FOrest over 52 No NA variables gve over 99% accuracy-------------------------------------------------------------------
set.seed(1234)
library(parallel)
cl<-makeCluster(2)

#Defaut Randon Forest Train takes too much time change it
customGrid <- data.frame(mtry=c(5,9,15))# Do not want 75 forest and 10,000 trees
cctrl3 <- trainControl(method = "cv", number = 3,allowParallel = TRUE)
ModFit<-train(classe~.,data=TrainData,method="rf",trControl=cctrl3,prox=TRUE,
              returnData=FALSE, returnResamp="none", savePredictions=FALSE,
              #           tuneGrid=customGrid, 
              ntree=101)
ModFit$time$everything[3]/60  #Time takeninmInutes
ModFit
tic<-proc.time()
Predict<-predict(ModFit,newdata=TestData)  
(proc.time()-tic)[[3]]/60 # predict time in Minutes
#
stopCluster(cl)
#
CM<-confusionMatrix(Predict,TestData$classe)
CM
accu<-CM$overall[1]#99.46%

#Important vars
varlist<-(varImp(ModFit))
VarImp<-rowSums(varlist$importance,dim=1)/4
sort(VarImp,decreasing=TRUE)# roll_belt,pitch_forearm,yaw_belt,magnet_dumbbell_z

# Visualizing results
#AUC Not Usefull
#FPR ACCURACY etc
#Classwise Accuracy
#Tree Dedogram
#Variable Error, models
# Confusion Accuracy , FPR 
CM

# MOdel accuracy vs Variables
plot(ModFit,main="Accuracy vs Variables") # Accuracy vs Variable used st line


TopVars<-c('roll_belt','pitch_forearm','yaw_belt','magnet_dumbbell_z')
# First Plot
featurePlot(x = TestData[, TopVars],
            y = TestData$classe,
            plot = "density",
            ## Add a key at the top
            auto.key = list(columns = 5))
#Second Plot Scatter
featurePlot(x = TestData[, TopVars],
            y = TestData$classe,
            plot = "pairs",
            ## Add a key at the top
            auto.key = list(columns = 5))

# featurePlot(x = TestData[, TopVars],
#             y = TestData$classe,
#             plot = "box",
#             ## Add a key at the top
#             auto.key = list(columns = 5))
plot(ModFit$finalModel,main="classification tree per CLass A:E") # Error vs trees shrinking curves
# Unable to do Tree or dendogram 
#text(ModFit$finalModel)# Error Dendogram
# library(rattle)
# fancyRpartPlot(ModFit$finalModel)# Error Dendogram
# prp(ModFit$finalModel)

#USe Rpart directly to viualize tree
library(rpart)
library(rpart.plot)
form<- as.formula(classe ~ .)
tree.2 <- rpart(form,TrainData)			# A more reasonable tree
prp(tree.2,main="Rpart visulaization of Tree") # A fast plot											
#fancyRpartPlot(tree.2,under=TRUE,uniform=FALSE) # Does not fit, unreadable
# Getting a single tree
#getTree(ModFit$finalModel, k=3,labelVar = TRUE)

#Plot ROC Curves
#convert Class to long format
library(reshape)
A<-TestData[ c("roll_belt","classe")]
A$ID<-rownames(A)# need to count occurance 
A$Count<-1 # Dummy for counting 
B<-reshape(A,timevar="classe",idvar=c('ID',"roll_belt"),direction="wide")
B[is.na(B)]<-0
names(B)[names(B)=="Count.A"] <- "A"
names(B)[names(B)=="Count.B"] <- "B"
names(B)[names(B)=="Count.C"] <- "C"
names(B)[names(B)=="Count.D"] <- "D"
names(B)[names(B)=="Count.E"] <- "E"
SelCol<-c("A","B","C","D","E")
B<-B[SelCol]# Only keep classes count
library(ROCR)
Predict.ROC<-predict(ModFit,newdata=TestData,type='prob')
Predict.Pred<-prediction(Predict.ROC,B)# MultiClass
Predict.Perf<-performance(Predict.Pred, measure = 'tpr', x.measure = 'fpr')
plot(Predict.Perf, col=1:5,main="ROC for Each Class A:E")
abline(a=0, b= 1)

