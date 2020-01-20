### Joe The Corpus Rogan
### By Dan Turner

### TRANSCRIPT & AUDIO PAIRING SCRIPT
# This file takes transcripts with inline timestamps and trims audio files to match, for aligning purposes.
# Transcripts are in /t-raw/, the podcast dataframe is scrapelist.rds in the root, the trimmed transcripts are 
#     in /podchunks/ as text files.

### Updated 1-18-2020

###########
## Setup ##
###########

# Load packages
library(rvest) # Web scraping
library(stringr) # String handling
library(readr) # Nice reading and writing
library(lubridate) # Time interval calculator

# Working dir
setwd("~/Git/joethecorpus")

# Episodes dataframe
eps <- readRDS("~/Git/joethecorpus/scrapelist.rds")

# We only care about the ones with transcripts
eps <- subset(eps, eps$t.avail == TRUE)

########################################
## Extract timestamps and transcripts ##
########################################

# Columns for the timestamps in the transcripts, and the text itself
eps$t.span <- list(NA)
eps$t.txt <- ""

# First let's see what episodes we have transcripts for (filename sans .txt)
t.list = list.files(path = "./t-raw/")
t.list.n = as.double(gsub(".txt", "", t.list))

# Report
if (length( setdiff(eps$n, t.list.n) ) > 0){
  print("Warning: Missing transcripts.")
}else{
  print("All available transcripts scraped.")
}

# Extract the timestamps by looping the transcripts
for (tr in 1:length(t.list)){
  
  # What is the corresponding row in eps for this podcast?
  tr.ep = which(eps$n == t.list.n[tr])
  
  # Read the file in
  file = read_file( paste0("t-raw/", t.list[tr]) )
  
  # Look for the time stamps
  stamps.i = gregexpr("[0-9][0-9]:[0-9][0-9]:[0-9][0-9]", file)
  stamps.i = as.numeric(stamps.i[[1]])
  
  # Write all the timestamps to stamps, using their span in the file
  stamps = substring(file, first = stamps.i, last = (stamps.i + 7))
  
  # Write the stamps to the data frame
  eps$t.span[tr.ep] <- list(stamps)
  
  # Clean the transcript a bit, while it's in memory
  #file = str_remove_all(file, "[0-9][0-9]:[0-9][0-9]:[0-9][0-9]") # Remove timestamps
  
  # Split the file up by the play symbols
  t.split = strsplit(file, "[0-9][0-9]:[0-9][0-9]:[0-9][0-9]")

  # Save the transcript to the data frame
  eps$t.txt[tr.ep] <- t.split
    
}

#############################################
## Trim transcripts to timestamp intervals ##
#############################################

# Loop the transcripts and intervals to save all intervals to /labs/
for (transcript in 1:nrow(eps)){
  
  # Load the transcript text and number
  transcript.text   = eps$t.txt[transcript][[1]]
  transcript.n = eps$n[transcript]
  transcript.cnt = length(eps$t.txt[transcript][[1]])
  
  # Get the start and end of each transcript interval in HMS
  transcript.start = eps$t.span[transcript][[1]]
  transcript.end = transcript.start[2:transcript.cnt]
  #transcript.end[transcript.cnt] <- NA
  
  # Convert times to seconds
  transcript.start = period_to_seconds(hms(transcript.start))
  transcript.end = period_to_seconds(hms(transcript.end))
  
  # Clean the transcript of non-alphanumeric characters and spaces
  transcript.text = gsub("[^[:alnum:][:space:]]","", transcript.text)
  
  # Make it all lowercase
  transcript.text = tolower(transcript.text)
  
  # Create a temporary data frame with our interval number, its text, and its bounds for Praat
  trim.frame = data.frame("interval" = 1:(transcript.cnt -1), 
                          "text" = transcript.text[2:transcript.cnt],
                          "leftbound" = transcript.start, 
                          "rightbound" = transcript.end
                          )
  
  # Peg the last time stamp at the end of the episode
  trim.frame$rightbound[nrow(trim.frame)] <- eps$dur[transcript]
  
  # Write the result to /podchunks/
  write_csv(trim.frame, paste0("podchunks/", transcript.n, ".csv"))
  
} #/transcript loop

# Done

# Next: Create TextGrids with the attached Praatscript
# Then we will force align using montreal forced aligner

