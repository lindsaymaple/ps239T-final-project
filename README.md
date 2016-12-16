# ps239T-final-project
PS239T Final Project
Short Description

This project merged two very large datasets with the goal of cleaning them in order to produce GeoSpatial maps of spending on school infrastructure in California by county. The main R packages that were used required specific data frames in order to create the narrow maps that I was looking to produce. 

Using R for merging the data and creating the maps along with Stata for some of the data cleaning – particularly because all of the data was provided to me in Stata .do files – enabled me to explore new visualization and mapping packages that I had never used before. In particular, I mostly used ChoroplethR and Leaflet to make my ultimate maps, although I took a lot of roundabout ways to figure out that these would be the most helpful. 


Dependencies

List what software your code depends on, as well as version numbers, like so:

R, version 3.1
Stata, version 12 or newer 

Files

List all other files contained in the repo, along with a brief description of each one, like so:

Data

01_PS239T_Data_Cleaning: The original .do file, used to clean one dataset made up of current spending by county
02_alldata12.dta: The dataset that came from the data cleaning file, merged eventually in my code
03_CA_counties: the shapefile for California, and other required files
04_MasterData_LM: The master data file including all school data by county, collected throughout Fall 2016

Code

05_PS239_PPT_Project.RMD: The R Markdown script of my final project
06_PS239_PPT_Project.HTML: The slides created from my R Markdown to be used in presenting my maps to the Center for Cities + Schools

Results
07_PS239T_Final_Project_Paper: My final paper reflecting on the project, and including many of the findings from this project
