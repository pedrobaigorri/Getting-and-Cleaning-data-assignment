##############################################################################
## File: run_analysis.R
##
## Description: Peer-graded Assignment: Getting and Cleaning Data Course Project
##
## Author: Pedro A. Alonso Baigorri
##############################################################################
#setwd("D://Pedro//TID//BI4TD//DATA SCIENCE//COURSERA//Code//Data Cleaning")

# Load required libraries
library(dplyr)
library(stringr)


# Getting the data
{

    if (!file.exists("./data/UCI.zip"))
    {
        fileURL <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
        if (!file.exists("./data")){dir.create("./data")}
        download.file(fileURL, "./data/UCI.zip")
        
        unzip("./data/UCI.zip", exdir = "./data")    
    }
}
    
##############################################################################
# Step 1: Merges the training and the test sets to create one data set.
##############################################################################
{
    #loading training and test datasets
    trainFile <- "./data/UCI HAR Dataset/train/X_train.txt"
    train <- read.table(trainFile)
    head(train)
    dim(train) # 7352 X 561
    
    testFile <- "./data/UCI HAR Dataset/test/X_test.txt"
    test <- read.table(testFile)
    head(test)
    dim(test) # 2947 x 561
    
    # merging datasets
    train_test <- rbind(train, test)
    
    # checking
    dim(train_test) # 10299 x 561
    dim(test)[1] + dim(train)[1] # 10299
    
    # loading labels for both datasets
    labelTrainFile <- "./data/UCI HAR Dataset/train/y_train.txt"
    labelTrain <- read.table(labelTrainFile)
    head(labelTrain)
    dim(labelTrain) # 7352 x 1
    
    labelTestFile <- "./data/UCI HAR Dataset/test/y_test.txt"
    labelTest <- read.table(labelTestFile)
    head(labelTest)
    dim(labelTest) # 2947 x 1
    
    # merging datasets
    label_train_test <- rbind(labelTrain, labelTest)
    
    # checking
    dim(label_train_test) # 10299 x 1
    dim(labelTest)[1] + dim(labelTrain)[1] #10299
    
    # adding a index as reference to avoid problems of moving rows with data manipulation
    train_test$index <- seq(1:nrow(train_test))
    label_train_test$index <- seq(1:nrow(label_train_test))
    
    head(train_test)
    head(label_train_test)
    
    # repeating the process for the subject_train and subject_test datasets
    subjectTrainFile <- "./data/UCI HAR Dataset/train/subject_train.txt"
    subjectTrain <- read.table(subjectTrainFile)
    head(subjectTrain)
    dim(subjectTrain) # 7352 X 1
    
    subjectTestFile <- "./data/UCI HAR Dataset/test/subject_test.txt"
    subjectTest <- read.table(subjectTestFile)
    head(subjectTest)
    dim(subjectTest) # 2947 x 1
    
    subject_train_test <- rbind(subjectTrain, subjectTest)
    
    dim(subject_train_test) # 10299 x 1
    dim(subjectTest)[1] + dim(subjectTrain)[1] # 10299
    
    subject_train_test$index <- seq(1:nrow(subject_train_test))
    head(subject_train_test)
}

#################################################################################################
# Step 2: Extracts only the measurements on the mean and standard deviation for each measurement.
#################################################################################################
{
    #loading the features dataset with the name of the variables
    featuresFile <- "./data/UCI HAR Dataset/features.txt"
    features <- read.table(featuresFile)
    head(features)
    dim(features) # 561 x 2
    
    
    # getting the variables of interest
    mean_std_variables <- grepl("mean[(]|std()", features[,2])
    mean_std_variables[562] <- TRUE #index variable
    table(mean_std_variables)
    
    # subsetting the dataset with the desired variables
    train_test <- train_test[, mean_std_variables]
    dim(train_test) #10299 x 67
    
    #subsetting features dataset with the names required for step 4
    features <- features[mean_std_variables[1:nrow(features)], 2]
    
}

#################################################################################################
# Step 3: Uses descriptive activity names to name the activities in the data set.
#################################################################################################
{
    # loading activity file    
    activityFile <- "./data/UCI HAR Dataset/activity_labels.txt"
    labels <- read.table(activityFile)
    head(labels)
    dim(labels) # 6 x 2
    
    # merging with label dataset
    label_train_test <- merge(label_train_test, labels)
    
    #removing column V1
    label_train_test <- select(label_train_test, -V1)
    
    # setting colname
    colnames(label_train_test)[2] <- "activity"
    
    # merging to train_test dataset
    train_test <- merge(train_test, label_train_test, by.x = "index", by.y = "index")
    head(train_test)
    dim(train_test) # 10299 x 68
    
    # merging also subjects dataset
    colnames(subject_train_test)[1] <- "subject"
    train_test <- merge(train_test, subject_train_test, by.x = "index", by.y = "index")
    head(train_test)
    dim(train_test) # 10299 x 69
}
    
#################################################################################################
# Step 4: Appropriately labels the data set with descriptive variable names.
#################################################################################################
{
    #subject and labels variable names already set
    #only measurement labels are missing loaded in features
    
    # adapting the names of the variables to make them more clear
    features <- sub("\\()", "", features)
    features <- sub("^f", "frequency", features)
    features <- sub("^t", "time", features)
    features <- sub("Acc", "Accelerometer", features)
    features <- sub("Gyro", "Gyroscope", features)
    features <- sub("Mag", "Magnitude", features)
    
    # dropping the index column as now is not required
    train_test <- select(train_test, -index)
    dim(train_test) # 10299 x 68
    
    
    # setting the colnames of the dataset
    colnames(train_test)[1:66] <- features
    
}

#################################################################################################
# Step 5: From the data set in step 4, creates a second, independent tidy data set with the 
# average of each variable for each activity and each subject.   
#################################################################################################
{
    agg_train_test <- aggregate(train_test, list(train_test$subject, train_test$activity), FUN= mean)
    
    # remove the replicated variables subject & list
    agg_train_test <- select(agg_train_test, -activity)
    agg_train_test <- select(agg_train_test, -subject)
    
    #rename grouping variables to subject & activity
    colnames(agg_train_test)[1] <- "subject"
    colnames(agg_train_test)[2] <- "activity"

    head(agg_train_test)
    dim(agg_train_test) # 180 x 68
     
     # writing it to a file
     write.table(agg_train_test, "./data/tidy_dataset.txt", row.names = F)

}


