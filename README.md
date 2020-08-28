Applying the Lossless Distributed Linear Mixed Model to integrate heterogeneous COVID-19 hospitalization data across the OHDSI Network 
=============

<img src="https://img.shields.io/badge/Study%20Status-Started-blue.svg" alt="Study Status: Started">

- Analytics use case(s): **Patient-Level Prediction**
- Study type: **Methods Research / Clinical Application**
- Tags: **-**
- Study lead: **-**
- Study lead forums tag: **[[Lead tag]](https://forums.ohdsi.org/u/[Lead tag])**
- Study start date: **Aug 12, 2020**
- Study end date: **Aug 30, 2020**
- Protocol: **-**
- Publications: **-**
- Results explorer: **-**

This study implements a distributed approach to calculating pooled effect estimates across heterogeneous data.  We are applying it to the outcome hospital length of stay for patients hospitalized due to COVID-19 across the OHDSI network.

## Background
Due to the novelty of COVID-19 many data sets only contain small quantities of COVID-19 specific data. The OHDSI network contains a large number of datasets with COVID-19 data and when combined the COVID-19 data are rather large.  However, due to privacy issues it is not possible to pool the datasets during multi-site collaboration. For example, sensitive individual patient data (IPD) including the patient's identity, diagnoses and treatments are usually not allowed under privacy regulation to be shared across networks.

In this study we propose implementing a novel algorithm, distributed linear mixed models (DLMMs), that is able to learn the coefficients across heterogeneous data and only requires extracting aggregated data from each data site in the network once. Linear mixed models (LMMs) are commonly used in many areas including epidemiology for analyzing multi-site data with heterogeneity. The model assumes site-specific random effects of the covariates (and intercept) on a continuous outcome. To the best of our knowledge, there is no existing approach for fitting LMMs in a distributed manner.

The aim of this study is to demonstrate the ability to perform a distributed methodology across the OHDSI network to estimate the effect of various predictors of severe COVID-19 infection. We will implement the DLMMs methodology across the COVID-19 datasets within the OHDSI network to estimate the effect of various predictors on length of hospitalization stay (a proxy for severity of COVID-19 infection) that were identified as predictors of severity during the OHDSI COVID-19 study-a-thon.

## Code to run:

Make sure you have R and Java installed as described [here](https://ohdsi.github.io/Hades/rSetup.html).

To install the package and its dependencies in R:

```r
# Install the latest version of renv:
install.packages("renv")

# Start a new project in RStudio (or when not using RStudio, create a new folder and 
# set it as the current working directory). When asked if you want to use renv with the 
# project, answer ‘no’.

# Download the lock file:
download.file("https://raw.githubusercontent.com/ohdsi-studies/DistributedLMM/master/renv.lock", "renv.lock")
  
# Build the local library:
renv::init()
  
# When not in RStudio, you'll need to restart R now

# And you’re done! The study package can now be loaded and used:
library(DistributedLMM)
```

Next, either download extras/codeToRun.R and fill in the connection details or run:


```r
# 2) Now run the package
library(DistributedLMM)
# USER INPUTS
#=======================
# Specify where the temporary files (used by the ff package) will be created:
options(andromedaTempFolder = "location with space to save big data")

# The folder where the study intermediate and result files will be written:
outputFolder <- "./DLMM"

# Details for connecting to the server (type '?DatabaseConnector::createConnectionDetails' for info):
dbms <- "you dbms"
user <- 'your username'
pw <- 'your password'
server <- 'your server'
port <- 'your port'

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)

# Add the database containing the OMOP CDM data
cdmDatabaseSchema <- 'cdm database schema'
# Add the name of database containing the OMOP CDM data
cdmDatabaseName <- 'cdm database name'

# Add a database with read/write access as this is where the cohorts will be generated
cohortDatabaseSchema <- 'work database schema'
oracleTempSchema <- NULL


# table name where the cohorts will be generated
cohortTable <- 'DLMM'

#============== Pick Study Parts To Run: ===========
createCohorts = TRUE
extractData = TRUE
packageResults = TRUE

minCellCount <- 5
sampleSize <- NULL


execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cdmDatabaseName = cdmDatabaseName,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        endDay = -1,
        sampleSize = sampleSize,
        outputFolder = outputFolder,
        createCohorts = createCohorts,
        useFluCohort = F,
        extractData = extractData,
        packageResults = packageResults,
        minCellCount = minCellCount,
        verbosity = "INFO",
        cdmVersion = 5)

```


## Output

After running the study, in [outputFolder], you will find a folder named [cdmDatabaseName].zip with all the results ready to export.  The unzipped version of this folder is the 'export' directory.  The files are: i) CohortCounts.csv (a csv with the number of patients in each cohort used as variables or the covid hospitalization cohort), ii) covNames.csv (a csv stating which column each variable was recorded in), iii) N.csv (a csv containing the number of patients in your covid hospitalization cohort), iv) XX.csv (a csv of the square matrix: t(X)X where X is the data matrix with rows representing patients and columns representing variables), v) Xy.csv (a csv containing a vector: t(X)y where y is the length of hospitalization vector) and vi) yy.csv (a csv containing an integer: t(y)y )