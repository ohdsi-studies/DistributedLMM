# Copyright 2020 Observational Health Data Sciences and Informatics
#
# This file is part of distributedLMM
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Execute the Study
#'
#' @details
#' This function executes the DLMM Study.
#'
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the
#'                             \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                             DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param cdmDatabaseName      Shareable name of the database
#' @param cohortDatabaseSchema Schema name where the cohorts and covariates are created. You will need to have
#'                             write priviliges in this schema. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param cohortTable          The name of the table that will be created in the work database schema.
#'                             This table will hold the target, outcome and variable cohorts used in this study.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param sampleSize           How many patients to sample from the target population
#' @param studyStartDate       Restrict to certain time period
#' @param studyEndDate       Restrict to certain time period
#' @param endDay               The end day relative to index for the custom covariates (default is -1)
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#' @param createCohorts        Create the cohortTable table with the cohorts
#' @param useFluCohort         use to the test the package in flu data
#' @param extractData    Extract the data and create the components for the DLLM
#' @param packageResults       Should results be packaged for later sharing?
#' @param minCellCount         The minimum number of subjects contributing to a count before it can be included
#'                             in packaged results.
#' @param verbosity            Sets the level of the verbosity. If the log level is at or higher in priority than the logger threshold, a message will print. The levels are:
#'                                         \itemize{
#'                                         \item{DEBUG}{Highest verbosity showing all debug statements}
#'                                         \item{TRACE}{Showing information about start and end of steps}
#'                                         \item{INFO}{Show informative information (Default)}
#'                                         \item{WARN}{Show warning messages}
#'                                         \item{ERROR}{Show error messages}
#'                                         \item{FATAL}{Be silent except for fatal errors}
#'                                         }
#' @param cdmVersion           The version of the common data model
#'
#' @examples
#' \dontrun{
#' connectionDetails <- createConnectionDetails(dbms = "postgresql",
#'                                              user = "joe",
#'                                              password = "secret",
#'                                              server = "myserver")
#'
#' execute(connectionDetails,
#'         cdmDatabaseSchema = "cdm_data",
#'         cdmDatabaseName = 'shareable name of the database'
#'         cohortDatabaseSchema = "study_results",
#'         cohortTable = "cohort",
#'         oracleTempSchema = NULL,
#'         sampleSize = NULL
#'         studyStartDate,
#'         studyEndDate,
#'         endDay = -1,
#'         outputFolder = "c:/temp/study_results",
#'         createCohorts = T,
#'         useFluCohort = F,
#'         extractData = T,
#'         packageResults = T,
#'         minCellCount = 10,
#'         verbosity = "INFO",
#'         cdmVersion = 5)
#' }
#'
#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    cdmDatabaseName = 'friendly database name',
                    cohortDatabaseSchema = cdmDatabaseSchema,
                    cohortTable = "cohort",
                    oracleTempSchema = cohortDatabaseSchema,
                    sampleSize = NULL,
                    studyStartDate = "",
                    studyEndDate = "",
                    endDay = -1,
                    outputFolder,
                    createCohorts = T,
                    useFluCohort = F,
                    extractData = T,
                    packageResults = T,
					          minCellCount = 10,
                    verbosity = "INFO",
                    cdmVersion = 5) {


  if (!file.exists(file.path(outputFolder,cdmDatabaseName)))
    dir.create(file.path(outputFolder,cdmDatabaseName), recursive = TRUE)

  ParallelLogger::addDefaultFileLogger(file.path(outputFolder, cdmDatabaseName, "log.txt"))
  ParallelLogger::addDefaultErrorReportLogger(file.path(outputFolder, cdmDatabaseName, "errorReportR.txt"))
  on.exit(ParallelLogger::unregisterLogger("DEFAULT_FILE_LOGGER", silent = TRUE))
  on.exit(ParallelLogger::unregisterLogger("DEFAULT_ERRORREPORT_LOGGER", silent = TRUE), add = TRUE)

  if (createCohorts) {
    ParallelLogger::logInfo("Creating cohorts")
    createCohorts(connectionDetails = connectionDetails,
                  cdmDatabaseSchema = cdmDatabaseSchema,
                  cohortDatabaseSchema = cohortDatabaseSchema,
                  cohortTable = cohortTable,
                  useFluCohort = useFluCohort,
                  oracleTempSchema = oracleTempSchema,
                  outputFolder = file.path(outputFolder, cdmDatabaseName))
  }
  
  if(extractData){
    plpData <- getData(connectionDetails = connectionDetails,
                       cdmDatabaseSchema = cdmDatabaseSchema,
                       cohortDatabaseSchema = cohortDatabaseSchema,
                       cohortTable = cohortTable,
                       useFluCohort = useFluCohort,
                       oracleTempSchema = oracleTempSchema,
                       endDay = endDay,
                       sampleSize = sampleSize,
                       cdmVersion = cdmVersion,
                       studyStartDate = studyStartDate,
                       studyEndDate = studyEndDate)
    
    # save the data as csv files:
    saveLoc <- file.path(outputFolder,cdmDatabaseName)
    write.csv(plpData$missing, file.path(saveLoc,'missing.csv' ), row.names = F)
    write.csv(plpData$XX, file.path(saveLoc,'XX.csv' ), row.names = F)
    write.csv(plpData$Xy, file.path(saveLoc,'Xy.csv'), row.names= F)
    write.csv(plpData$yy, file.path(saveLoc,'yy.csv'), row.names= F)
    write.csv(plpData$N, file.path(saveLoc,'N.csv'),  row.names= F)
    write.csv(plpData$covNames, file.path(saveLoc,'covNames.csv'), row.names= F)
    
  }
  
  if (packageResults) {
    ParallelLogger::logInfo("Packaging results")
    packageResults(outputFolder = outputFolder,
                   cdmDatabaseName = cdmDatabaseName,
                   minCellCount = minCellCount)
  }

  return(TRUE)
}




