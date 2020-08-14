library(DistributedLMM)
# USER INPUTS
#=======================
# Specify where the temporary files (used by the ff package) will be created:
options(andromedaTempFolder = "location with space to save big data")

# The folder where the study intermediate and result files will be written:
outputFolder <- "./DLMM"

# Details for connecting to the server:
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
        useFluCohort = T,
        extractData = extractData,
        packageResults = packageResults,
        minCellCount = minCellCount,
        verbosity = "INFO",
        cdmVersion = 5)
