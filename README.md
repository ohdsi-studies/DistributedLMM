Applying the Lossless Distributed Linear Mixed Model to integrate heterogeneous COVID-19 hospitalization data across the OHDSI Network 
=============

<img src="https://img.shields.io/badge/Study%20Status-Repo%20Created-lightgray.svg" alt="Study Status: Repo Created">

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

