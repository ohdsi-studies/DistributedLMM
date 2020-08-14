# Copyright 2020 Observational Health Data Sciences and Informatics
#
# This file is part of CovidSimpleModels
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

#' Package the results for sharing with OHDSI researchers
#'
#' @details
#' This function packages the results.
#'
#' @param outputFolder        Name of folder containing the study analysis results 
#'                            (/)
#' @param minCellCount        The minimum number of subjects contributing to a count before it can be included in the results.
#'
#' @export
packageResults <- function(outputFolder, 
                           cdmDatabaseName,
                           minCellCount = 5) {
  if(missing(outputFolder)){
    stop('Missing outputFolder...')
  }
  
  # copy the requested files...
  files <- dir(file.path(outputFolder,cdmDatabaseName), pattern = '.csv')
  
  
  #create export subfolder in workFolder
  exportFolder <- file.path(outputFolder,cdmDatabaseName, "export")
  dir.create(exportFolder, recursive = T)
  
  for(file in files){
    # loads analysis results
    file.copy(from = file.path(outputFolder,cdmDatabaseName, file), 
              to = file.path(exportFolder, file))
  }
  
  
  ### Add all to zip file ###
  zipName <- file.path(outputFolder,paste0(cdmDatabaseName, '.zip'))
  OhdsiSharing::compressFolder(exportFolder, zipName)
  # delete temp folder
  unlink(exportFolder, recursive = T)
  
  writeLines(paste("\nStudy results are compressed and ready for sharing at:", zipName))
  return(zipName)
}
