getData <- function(connectionDetails,
                    cdmDatabaseSchema,
                    cohortDatabaseSchema,
                    cohortTable,
                    useFluCohort = useFluCohort,
                    oracleTempSchema,
                    endDay,
                    sampleSize,
                    cdmVersion,
                    studyStartDate,
                    studyEndDate){
  
  
  # age/gender
  standardCovariates <- FeatureExtraction::createCovariateSettings(useDemographicsGender = T, # exclude female
                                                                   useDemographicsRace = T, #exclude all but european/white
                                                                   excludedCovariateConceptIds = c(8532,
                                                                                                   8557,44814660,38003572,38003574,38003578,38003597,44814659,38003577,38003589,38003596,38003600,38003602,44814655,38003613,8552,8516,38003580,38003593,38003604,38003598,38003615,38003599,44814656,38003605,8657,38003586,38003576,38003584,38003609,38003575,38003603,38003592,38003594,44814657,38003616,9178,8522,38003583,38003591,38003612,38003587,38003582,44814654,38003607,38003590,38003595,38003611,38003585,8515,38003573,38003606,38003579,38003581,38003588,38003601,38003608,38003610) )
  
  pathToCustom <- system.file("settings", 'CustomCovariates.csv', package = "DistributedLMM")
  cohortVarsToCreate <- utils::read.csv(pathToCustom)
  covSets <- list()
  length(covSets) <- nrow(cohortVarsToCreate)+1
  covSets[[1]] <- standardCovariates
  
  for(i in 1:nrow(cohortVarsToCreate)){
    covSets[[1+i]] <- createCohortCovariateSettings(covariateName = as.character(cohortVarsToCreate$cohortName[i]),
                                                      covariateId = cohortVarsToCreate$cohortId[i]*1000+456,
                                                      cohortDatabaseSchema = cohortDatabaseSchema,
                                                      cohortTable = cohortTable,
                                                      cohortId = cohortVarsToCreate$atlasId[i],
                                                      startDay=cohortVarsToCreate$startDay[i], 
                                                      endDay=endDay,
                                                      count= as.character(cohortVarsToCreate$count[i]), 
                                                      ageInteraction = as.character(cohortVarsToCreate$ageInteraction[i]))
  }
  
  
  result <- tryCatch({PatientLevelPrediction::getPlpData(connectionDetails = connectionDetails,
                                     cdmDatabaseSchema = cdmDatabaseSchema,
                                     oracleTempSchema = oracleTempSchema, 
                                     cohortId = ifelse(useFluCohort, 18041, 18133), 
                                     outcomeIds = -999, 
                                     cohortDatabaseSchema = cohortDatabaseSchema, 
                                     outcomeDatabaseSchema = cohortDatabaseSchema, 
                                     cohortTable = cohortTable, 
                                     outcomeTable = cohortTable, 
                                     cdmVersion = cdmVersion, 
                                     firstExposureOnly = F, 
                                     sampleSize =  sampleSize, 
                                     covariateSettings = covSets,
                                     studyStartDate = studyStartDate,
                                     studyEndDate = studyEndDate)},
                     error = function(e) {
                       ParallelLogger::logError(e)
                       return(NULL)
                     })
  
  charlson <- FeatureExtraction::createCovariateSettings(useCharlsonIndex = T )
  charlson <- tryCatch({PatientLevelPrediction::getPlpData(connectionDetails = connectionDetails,
                                                         cdmDatabaseSchema = cdmDatabaseSchema,
                                                         oracleTempSchema = oracleTempSchema, 
                                                         cohortId = ifelse(useFluCohort, 18041, 18133), 
                                                         outcomeIds = -999, 
                                                         cohortDatabaseSchema = cohortDatabaseSchema, 
                                                         outcomeDatabaseSchema = cohortDatabaseSchema, 
                                                         cohortTable = cohortTable, 
                                                         outcomeTable = cohortTable, 
                                                         cdmVersion = cdmVersion, 
                                                         firstExposureOnly = F, 
                                                         sampleSize =  sampleSize, 
                                                         covariateSettings = charlson,
                                                         studyStartDate = studyStartDate,
                                                         studyEndDate = studyEndDate)},
                     error = function(e) {
                       ParallelLogger::logError(e)
                       return(NULL)
                     })
  
  result <- createComponents(result,charlson)
  
  return(result)
  
}



createComponents <- function(plpData, charlson){
  
  # create charlson feature 0-1, 2-4, and ≥5
  charlson2to5 <- rep(0, nrow(plpData$cohorts))
  ids <- charlson$covariateData$covariates %>% dplyr::filter(.data$covariateValue < 5 & .data$covariateValue >=2 ) %>% dplyr::select(.data$rowId)
  ids <- as.data.frame(ids)$rowId
  charlson2to5[ids] <- 1
  charlson5plus <- rep(0, nrow(plpData$cohorts))
  ids <- charlson$covariateData$covariates %>% dplyr::filter(.data$covariateValue >= 5 ) %>% dplyr::select(.data$rowId)
  ids <- as.data.frame(ids)$rowId
  charlson5plus[ids] <- 1
  extraX <- rbind(charlson2to5,charlson5plus)
  
  # create age 65 to <80, >=80
  age65to80 <- rep(0, nrow(plpData$cohorts))
  ids <- plpData$cohorts %>% dplyr::filter(.data$ageYear < 80 & .data$ageYear >= 65 ) %>% dplyr::select(.data$rowId)
  ids <- as.data.frame(ids)$rowId
  age65to80[ids] <- 1
  extraX <- rbind(extraX,age65to80)
  age80plus <- rep(0, nrow(plpData$cohorts))
  ids <- plpData$cohorts %>% dplyr::filter(.data$ageYear >= 80 ) %>% dplyr::select(.data$rowId)
  ids <- as.data.frame(ids)$rowId
  age80plus[ids] <- 1
  extraX <- rbind(extraX,age80plus)
  
  # convert to matrix
  X <- PatientLevelPrediction::toSparseM(plpData = plpData, population = plpData$cohorts)
  features <- X$map
  covariateRef <- X$covariateRef
  
  covNames <- merge(features, covariateRef, by.x = 'oldCovariateId', by.y = 'covariateId')[,c('newCovariateId','covariateName')]
  colnames(covNames) <- c('columnNumber','name')
  covNames <- rbind(covNames, data.frame(columnNumber = nrow(covNames)+(1:4),
                                         name = c('Charlson:[2,5)','Charlson:>=5','age:[65,80)','age:>=80')))
  

  X <- as.matrix(X$data)
  extraX <- t(extraX)
  X <- cbind(X,extraX)
  
  # adding names
  colnames(X) <- covNames$name[order(covNames$columnNumber)]
  
  # ad missing variables (if any)
  allVars <- c(' hypertension   days before: -9999 days after: -1',
               ' heartDisease   days before: -9999 days after: -1',
               ' kidneyDisease   days before: -9999 days after: -1',
               ' diabetes   days before: -9999 days after: -1',
               ' hyperlipidemia   days before: -9999 days after: -1',
               ' COPD   days before: -9999 days after: -1',
               ' cancer   days before: -9999 days after: -1',
               ' obesity   days before: -9999 days after: -1',
               'gender = MALE',
               'race = White')
  missing <- allVars[!allVars%in%colnames(X)]
  if(length(missing)>0){
    writeLines(paste0('adding variable ', missing))
    for(i in 1:length(missing)){
      X <- cbind(X, new = rep(0, nrow(X)))
      colnames(X)[colnames(X)=='new'] <- missing[i]
      covNames <- rbind(covNames, 
                        c(columnNumber = ncol(X),	name = missing[i])
                        )
    }
  }
  
  
  XX <- t(X)%*%X # gives feat x feat
  
  # must make cohort end the visit end
  y <- plpData$cohorts$daysToCohortEnd[order(plpData$cohorts$rowId)]
    
  Xy <- t(X)%*%y
  
  yy <- t(y)%*%y
  
  N <- nrow(plpData$cohorts)
  
  
  result <- list(XX = XX,
                 Xy = Xy,
                 yy = yy,
                 N = N,
                 covNames = covNames,
                 missing = missing
         )
  
  return(result)
  
}

