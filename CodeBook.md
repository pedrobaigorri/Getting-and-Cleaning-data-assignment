# CodeBook for the tidy_dataset

This is the codebook of the final dataset created for the final assigment of the Getting-and-Cleaning data course.

## Introduction

The origin data is the result of the project performed by the UCI for monitoring the Human Activity through the use of Smartphones. Complete information about the project can be obtained in their website: 

http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones

## Origin dataset

The origin dataset contained the following information:

- 'features_info.txt': Shows information about the variables used on the feature vector.
- 'features.txt': List of all features.
- 'activity_labels.txt': Links the class labels with their activity name.
- 'train/X_train.txt': Training set.
- 'train/y_train.txt': Training labels.
- 'test/X_test.txt': Test set.
- 'test/y_test.txt': Test labels.

The following files are available for the train and test data. Their descriptions are equivalent. 

- 'train/subject_train.txt': Each row identifies the subject who performed the activity for each window sample. Its range is from 1 to 30. 
- 'train/Inertial Signals/total_acc_x_train.txt': The acceleration signal from the smartphone accelerometer X axis in standard gravity units 'g'. Every row shows a 128 element vector. The same description applies for the 'total_acc_x_train.txt' and 'total_acc_z_train.txt' files for the Y and Z axis. 
- 'train/Inertial Signals/body_acc_x_train.txt': The body acceleration signal obtained by subtracting the gravity from the total acceleration. 
- 'train/Inertial Signals/body_gyro_x_train.txt': The angular velocity vector measured by the gyroscope for each window sample. The units are radians/second. 

## Transformations performed

Following the requirements of the final assignment the transformations performed on the dataset have been the following:

### Step 1 - Merges the training and the test sets to create one data set.

After loading the files into R, I used the functions rbind to join the datasets of train and tests.

I performed this operation for the datasets the labels and also the subjects data.

The result was the creation of three datasets with the following dimensions:

```
    train_test <- rbind(train, test)
    dim(train_test) # 10299 x 561
    dim(test)[1] + dim(train)[1] # 10299
    
    label_train_test <- rbind(labelTrain, labelTest)
    dim(label_train_test) # 10299 x 1

    subject_train_test <- rbind(subjectTrain, subjectTest)
    dim(subject_train_test) # 10299 x 1
```

In addition I added to all datasets two columns of index, to ensure that the position of the rows can be stored during the rest of transformation processes. The creation of this indexes columns was done with the following code:

```
  train_test$index <- seq(1:nrow(train_test))
  label_train_test$index <- seq(1:nrow(label_train_test))
  subject_train_test$index <- seq(1:nrow(subject_train_test))
```
### Step 2 - Extracts only the measurements on the mean and standard deviation for each measurement

I read the name of the variables from the features.txt file. Then selected the only the variables that has the word "mean" followed of '(' or the "std" in the name of the variable. And then subset the dataset according to this. 

The code that performs this part is the following:

```
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
```
### Step 3 - Uses descriptive activity names to name the activities in the data set

After loading the activity names from activity_file.txt, I added the activity name to the label_train_test dataset using the the function merge where the key varible to perform the merge is the V1.

Then I used again the function merge to join this the labels to the core dataset by using as key the index variable to ensure that I mantain the order of the rows properly. I do the same with the subjects_dataset.

The code that performs this operation is the following:

```
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
```
### Step 4 - Appropriately labels the data set with descriptive variable names

First modified a little bit the names of the variables to make them more understandables, and then assign this names to the colnames of the dataset.

```
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
```

### Step 5 - From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject. 

I use the function agreggate to calculate the avg of each of the columns per each activity and subject. The code that performs this operation is:

```
    agg_train_test <- aggregate(train_test, list(train_test$subject, train_test$activity), FUN= mean)
    
    # remove the replicated variables subject & list
    agg_train_test <- select(agg_train_test, -activity)
    agg_train_test <- select(agg_train_test, -subject)
    
    #rename grouping variables to subject & activity
    colnames(agg_train_test)[1] <- "subject"
    colnames(agg_train_test)[2] <- "activity"

    head(agg_train_test)
    dim(agg_train_test) # 180 x 68
```

Finally I wrote the dataset to the final file:

``` 
write.table(agg_train_test, "tidy_dataset.txt", row.names = F)
```

## Description of final tidy dataset

The final tidy dataset has 180 rows and 68 columns. Each row is the result of the combinations of unique activities (6) and unique subjects (30), (30 x 6 = 180).

And each measure is the average of all the selected variables including mean and std for each of that combinations. The final summary of the variables are:

- subject: " subject identification"
- activity: "activity description"

Measurements:

```
 $ timeBodyAccelerometer-mean-X                    : num  0.222 0.281 0.276 0.264 0.278 ...
 $ timeBodyAccelerometer-mean-Y                    : num  -0.0405 -0.0182 -0.019 -0.015 -0.0183 ...
 $ timeBodyAccelerometer-mean-Z                    : num  -0.113 -0.107 -0.101 -0.111 -0.108 ...
 $ timeBodyAccelerometer-std-X                     : num  -0.928 -0.974 -0.983 -0.954 -0.966 ...
 $ timeBodyAccelerometer-std-Y                     : num  -0.837 -0.98 -0.962 -0.942 -0.969 ...
 $ timeBodyAccelerometer-std-Z                     : num  -0.826 -0.984 -0.964 -0.963 -0.969 ...
 $ timeGravityAccelerometer-mean-X                 : num  -0.249 -0.51 -0.242 -0.421 -0.483 ...
 $ timeGravityAccelerometer-mean-Y                 : num  0.706 0.753 0.837 0.915 0.955 ...
 $ timeGravityAccelerometer-mean-Z                 : num  0.446 0.647 0.489 0.342 0.264 ...
 $ timeGravityAccelerometer-std-X                  : num  -0.897 -0.959 -0.983 -0.921 -0.946 ...
 $ timeGravityAccelerometer-std-Y                  : num  -0.908 -0.988 -0.981 -0.97 -0.986 ...
 $ timeGravityAccelerometer-std-Z                  : num  -0.852 -0.984 -0.965 -0.976 -0.977 ...
 $ timeBodyAccelerometerJerk-mean-X                : num  0.0811 0.0826 0.077 0.0934 0.0848 ...
 $ timeBodyAccelerometerJerk-mean-Y                : num  0.00384 0.01225 0.0138 0.00693 0.00747 ...
 $ timeBodyAccelerometerJerk-mean-Z                : num  0.01083 -0.0018 -0.00436 -0.00641 -0.00304 ...
 $ timeBodyAccelerometerJerk-std-X                 : num  -0.958 -0.986 -0.981 -0.978 -0.983 ...
 $ timeBodyAccelerometerJerk-std-Y                 : num  -0.924 -0.983 -0.969 -0.942 -0.965 ...
 $ timeBodyAccelerometerJerk-std-Z                 : num  -0.955 -0.988 -0.982 -0.979 -0.985 ...
 $ timeBodyGyroscope-mean-X                        : num  -0.01655 -0.01848 -0.02082 -0.00923 -0.02189 ...
 $ timeBodyGyroscope-mean-Y                        : num  -0.0645 -0.1118 -0.0719 -0.093 -0.0799 ...
 $ timeBodyGyroscope-mean-Z                        : num  0.149 0.145 0.138 0.17 0.16 ...
 $ timeBodyGyroscope-std-X                         : num  -0.874 -0.988 -0.975 -0.973 -0.979 ...
 $ timeBodyGyroscope-std-Y                         : num  -0.951 -0.982 -0.977 -0.961 -0.977 ...
 $ timeBodyGyroscope-std-Z                         : num  -0.908 -0.96 -0.964 -0.962 -0.961 ...
 $ timeBodyGyroscopeJerk-mean-X                    : num  -0.107 -0.102 -0.1 -0.105 -0.102 ...
 $ timeBodyGyroscopeJerk-mean-Y                    : num  -0.0415 -0.0359 -0.039 -0.0381 -0.0404 ...
 $ timeBodyGyroscopeJerk-mean-Z                    : num  -0.0741 -0.0702 -0.0687 -0.0712 -0.0708 ...
 $ timeBodyGyroscopeJerk-std-X                     : num  -0.919 -0.993 -0.98 -0.975 -0.983 ...
 $ timeBodyGyroscopeJerk-std-Y                     : num  -0.968 -0.99 -0.987 -0.987 -0.984 ...
 $ timeBodyGyroscopeJerk-std-Z                     : num  -0.958 -0.988 -0.983 -0.984 -0.99 ...
 $ timeBodyAccelerometerMagnitude-mean             : num  -0.842 -0.977 -0.973 -0.955 -0.967 ...
 $ timeBodyAccelerometerMagnitude-std              : num  -0.795 -0.973 -0.964 -0.931 -0.959 ...
 $ timeGravityAccelerometerMagnitude-mean          : num  -0.842 -0.977 -0.973 -0.955 -0.967 ...
 $ timeGravityAccelerometerMagnitude-std           : num  -0.795 -0.973 -0.964 -0.931 -0.959 ...
 $ timeBodyAccelerometerJerkMagnitude-mean         : num  -0.954 -0.988 -0.979 -0.97 -0.98 ...
 $ timeBodyAccelerometerJerkMagnitude-std          : num  -0.928 -0.986 -0.976 -0.961 -0.977 ...
 $ timeBodyGyroscopeMagnitude-mean                 : num  -0.875 -0.95 -0.952 -0.93 -0.947 ...
 $ timeBodyGyroscopeMagnitude-std                  : num  -0.819 -0.961 -0.954 -0.947 -0.958 ...
 $ timeBodyGyroscopeJerkMagnitude-mean             : num  -0.963 -0.992 -0.987 -0.985 -0.986 ...
 $ timeBodyGyroscopeJerkMagnitude-std              : num  -0.936 -0.99 -0.983 -0.983 -0.984 ...
 $ frequencyBodyAccelerometer-mean-X               : num  -0.939 -0.977 -0.981 -0.959 -0.969 ...
 $ frequencyBodyAccelerometer-mean-Y               : num  -0.867 -0.98 -0.961 -0.939 -0.965 ...
 $ frequencyBodyAccelerometer-mean-Z               : num  -0.883 -0.984 -0.968 -0.968 -0.977 ...
 $ frequencyBodyAccelerometer-std-X                : num  -0.924 -0.973 -0.984 -0.952 -0.965 ...
 $ frequencyBodyAccelerometer-std-Y                : num  -0.834 -0.981 -0.964 -0.946 -0.973 ...
 $ frequencyBodyAccelerometer-std-Z                : num  -0.813 -0.985 -0.963 -0.962 -0.966 ...
 $ frequencyBodyAccelerometerJerk-mean-X           : num  -0.957 -0.986 -0.981 -0.979 -0.983 ...
 $ frequencyBodyAccelerometerJerk-mean-Y           : num  -0.922 -0.983 -0.969 -0.944 -0.965 ...
 $ frequencyBodyAccelerometerJerk-mean-Z           : num  -0.948 -0.986 -0.979 -0.975 -0.983 ...
 $ frequencyBodyAccelerometerJerk-std-X            : num  -0.964 -0.987 -0.983 -0.98 -0.986 ...
 $ frequencyBodyAccelerometerJerk-std-Y            : num  -0.932 -0.985 -0.971 -0.944 -0.966 ...
 $ frequencyBodyAccelerometerJerk-std-Z            : num  -0.961 -0.989 -0.984 -0.98 -0.986 ...
 $ frequencyBodyGyroscope-mean-X                   : num  -0.85 -0.986 -0.97 -0.967 -0.976 ...
 $ frequencyBodyGyroscope-mean-Y                   : num  -0.952 -0.983 -0.978 -0.972 -0.978 ...
 $ frequencyBodyGyroscope-mean-Z                   : num  -0.909 -0.963 -0.962 -0.961 -0.963 ...
 $ frequencyBodyGyroscope-std-X                    : num  -0.882 -0.989 -0.976 -0.975 -0.981 ...
 $ frequencyBodyGyroscope-std-Y                    : num  -0.951 -0.982 -0.977 -0.956 -0.977 ...
 $ frequencyBodyGyroscope-std-Z                    : num  -0.917 -0.963 -0.967 -0.966 -0.963 ...
 $ frequencyBodyAccelerometerMagnitude-mean        : num  -0.862 -0.975 -0.966 -0.939 -0.962 ...
 $ frequencyBodyAccelerometerMagnitude-std         : num  -0.798 -0.975 -0.968 -0.937 -0.963 ...
 $ frequencyBodyBodyAccelerometerJerkMagnitude-mean: num  -0.933 -0.985 -0.976 -0.962 -0.977 ...
 $ frequencyBodyBodyAccelerometerJerkMagnitude-std : num  -0.922 -0.985 -0.975 -0.958 -0.976 ...
 $ frequencyBodyBodyGyroscopeMagnitude-mean        : num  -0.862 -0.972 -0.965 -0.962 -0.968 ...
 $ frequencyBodyBodyGyroscopeMagnitude-std         : num  -0.824 -0.961 -0.955 -0.947 -0.959 ...
 $ frequencyBodyBodyGyroscopeJerkMagnitude-mean    : num  -0.942 -0.99 -0.984 -0.984 -0.985 ...
 $ frequencyBodyBodyGyroscopeJerkMagnitude-std     : num  -0.933 -0.989 -0.983 -0.983 -0.983 ...
```

