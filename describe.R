### Joe The Corpus Rogan
### By Dan Turner

### SUMMARIZATION SCRIPT
# This file tell us about the corpus itself.

### Updated 1-20-2020

###########
## Setup ##
###########

# Libraries
library(readr)
library(tuneR)

# WD
setwd("~/Git/joethecorpus")

################
## Basic info ##
################

### CORPUS ###

# Load, clean, and split the corpus
oneline = read_file("jtcr_oneline.txt")
oneline = tolower(oneline)
oneline = gsub("[^[:alnum:][:space:]']", "", oneline)
oneline = strsplit(oneline, " ")

# Token and frequency across all of the transcripts
token_freq = length(oneline[[1]])
type_freq  = length(unique(oneline[[1]]))

rm(oneline)

### PODCASTS ###

# List podcasts which were scraped
scraped = as.double( sub(".txt", "", list.files("./t-raw")) )
podcast_count = length(scraped)

# Get total duration of scraped podcasts
setwd("/Volumes/Seagate 8TB HDD/Joe The Corpus Rogan/a-raw") # on my external drive
wavs = list.files(pattern = ".*.wav")

# Containter for running total
s = 0

# Read the headers of all the WAV files to find their duration in seconds
for (wav in wavs){
  audio<-readWave(wav, header=TRUE)
  s = s + round(audio$samples / audio$sample.rate, 2)
}

# Convert the seconds to hours
h = s/3600







