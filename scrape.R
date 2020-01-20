### Joe The Corpus Rogan
### By Dan Turner

### WEB SCRAPING SCRIPT
# This file scrapes podscribe.app for its JRE transcripts.
# Along the way it collects some basic episode information, downloads podcasts for 
#     transcripts it can find, prepares the audio and transcripts for forced alignment and corpus anaylsis.
# Transcripts are stored to /t-raw/ and the podcast list is scrapelist.rds and jrelist.rds, in the root. Audio in /a-raw/.

### Updated 1-18-2020

###########
## Setup ##
###########

# Load packages
library(rvest) # Web scraping
library(stringr) # String handling
library(readr) # Nice reading and writing
library(feedeR) # RSS feed reading
library(RCurl) # Download files from the internet
library(tuneR) # For audio files

# WD
setwd("~/Git/joethecorpus")

# Problem children
skip = c(1284,)

############################################
## Get some basic info about each episode ##
############################################

# Read the JRE RSS feed
jre.feed = feed.extract("http://joeroganexp.joerogan.libsynpro.com/rss")

# Build a starting data frame
scribed <- data.frame("n" = parse_number(str_extract(jre.feed$items$title, "[\\#][0-9]+")), 
                      "title" = jre.feed$items$title, 
                      "date"  = jre.feed$items$date, 
                      "a.url" = jre.feed$items$link)

################################################
## Scrape and extract episode transcript URLs ##
################################################

# Exclude podcasts that have the following terms in the title
exclude = c("mma|fight|jrqe|from a car")

# Create flags to help us to filter unwanted podcast episodes
scribed$is.kw_exclude <- grepl(exclude, tolower(scribed$title))
scribed$is.multipart  <- grepl(" part ", tolower(scribed$title))
scribed$no.mp3        <- !grepl(".mp3", tolower(scribed$a.url), fixed = TRUE)

# Subset scribed to only include episodes from the main show with transcripts
scribed.all <- scribed # leaving open the possibility of expanding this database later
scribed <- subset(scribed, scribed$is.kw_exclude == FALSE & scribed$is.multipart == FALSE & scribed$n > 0 & scribed$no.mp3 == FALSE)

# Root url is the list of podcasts epidoes on podscribe.app
root.url = "https://podscribe.app/feeds/http-joeroganexpjoeroganlibsynprocom-rss"

# Scrape the list of podcast episodes
podcasts <- read_html( root.url )

# Get podcasts titles
titles <- podcasts %>%
  html_nodes(".font-weight-bold") %>%
  html_text()

# Extract episode numbers from the title
numbers = parse_number(str_extract(titles, "[\\#][0-9]+"))

# Get all URLs
t.urls <- podcasts %>%
  html_nodes(".font-weight-bold") %>%
  html_attr("href")

# Append the root url
t.urls <- paste0("https://podscribe.app", t.urls)

# Make a quick dataframe to help map from podcast number to transcript url
mapper = data.frame("n" = numbers, "t.url" = t.urls)

# Merge the data frames to add t.url to the main dataframe
scribed = merge.data.frame(scribed, mapper)

###################################
## Identify transcribed episodes ##
###################################

# Get all episodes as a list of HTML nodes to prep to detect the flag showing there is a transcription available
scribed.items <- as.list( html_nodes(podcasts, ".font-weight-bold") ) #extect those with i tag

# List of episodes that are transcribed
scribed.flagged <- list()

# Loop the list of episodes to catch those which have the text-primary class, meaning they're transcribed
for (ep in 1:length(scribed.items)){
  
  # The node
  node <- paste( scribed.items[ep][[1]] ) 
  
  # Check the node for flag
  if (grepl("text-primary", node)){

    # Episode number is the number following #
    ep.num <- parse_number(str_extract(node, "[\\#][0-9]+"))
    
    # Add it to a rolling list
    scribed.flagged = append(scribed.flagged, ep.num)
    
  } #/transciption conditional
  
} #/episode loop

##########################################
## Put the data into a nice shape for R ##
##########################################

# Mark in the data frame if there's a high quality transcript available
scribed$t.avail      <- FALSE

for (flagged in scribed.flagged){
  
  # Get which row in the data frame corresponds to this scribed.flagged item
  flag.row = which(scribed$n == flagged)
  
  # And for that row specify that there's a transcript available
  scribed$t.avail[flag.row] <- TRUE
}

## Garbage collection, leaving only the dataframe
rm(podcasts, scribed.flagged, scribed.items, ep, ep.num, flag.row, flagged, node, mapper, jre.feed, numbers, titles, t.urls, root.url, exclude)

######################################
## Scrape the available transcripts ##
######################################

# Subset scribed to only episodes which have been transcribed
scrapelist = subset( scribed, scribed$t.avail == TRUE )

# Collect the URLs for each episode that's transcribed
urls = scrapelist$t.url
numbers = scrapelist$n

# List podcasts already downloaded
scraped = as.double( sub(".txt", "", list.files("./t-raw")) )

# Loop the episodes, scraping transcripts as we go
for (ep in 1:length(urls)){
  
  # Skip transcripts we already have, or those that have known issues
  if (scrapelist$n[ep] %in% scraped) next
  if (scrapelist$n[ep] %in% skip) next
  
  # Convert the URL from a factor to a string
  page.url = paste0( urls[ep] )
  
  # Scrape the page
  the.page <- read_html( page.url )
  
  # Only extract the text
  the.text = html_text(the.page)
  
  # If this page doesn't have a time logged transcript, move on
  if ( !grepl("[0-9][0-9]:[0-9][0-9]:[0-9][0-9]", the.text) ) next
  
  # Find start and end of the transript
  t.start1 = regexpr("00:00:00", the.text)
  t.start2 = regexpr("[0-9], [0-9][0-9][0-9][0-9]", the.text) + 7
  t.end   = regexpr(" © 20", the.text)
  
  # Sometimes there is no initial time stamp. In these cases, we start the transcript after "Next Episode"
  t.start = max(t.start1, t.start2)
    
  # Get the transcirpt substring
  t = substr(the.text, t.start, t.end)
  
  # Generate ouput path
  t.path = paste0(getwd(), "/t-raw/", numbers[ep], ".txt")
  
  # Save the transcript text to t-raw
  write_lines(t, t.path)
  
  # Wait a second before scraping the next page, to be a friendly scraper
  Sys.sleep(1)
  
}

# Garbage collection
rm(the.page, ep, numbers, page.url, t, t.end, t.path, t.start1, t.start2, t.start, the.text, urls, scraped)


###############################
## Download podcast episodes ##
###############################

# Warning: this takes a long time [todo: write asynchronous download script]

# Kill rows that do not have a unique url
scrapelist = scrapelist[!duplicated(scrapelist$a.url),]

# Container for the local filepath of the podcasts episodes
scrapelist$a.path = paste0("a-raw/", scrapelist$n, ".mp3")

# List podcasts already downloaded
downloaded = as.double( sub(".mp3", "", list.files("./a-raw")) )
converted = as.double( sub(".wav", "", list.files("./a-raw")) )

# Loop all of the transcripts to download the podcast file for each one
for (i in seq_along(scrapelist$a.url) ) {
  
  # If it's been downloaded, skip the file
  if (scrapelist$n[i] %in% downloaded) next
  
  # If it's been converted, skip the file
  if (scrapelist$n[i] %in% converted) next
  
  # If there are known issues, skip
  if (scrapelist$n[ep] %in% skip) next
  
  # Download the file to /a-raw/ as the podcast number .mp3
  download.file(paste(scrapelist$a.url[i]), scrapelist$a.path[i], mode="wb")

} #/podcast download loop

##############################
## Convert podcasts to WAVs ##
##############################

# Warning: This also takes a lot of time.

# We are not quite done with the files. Praat doesn't like mp3's, so let's make companion WAV files

#
scrapelist$dur = 0

# Loop all the mp3 files, converting them to mono wav with downsampling
for (i in seq_along(scrapelist$a.url) ) {

  # If it's been converted, skip the file
  if (scrapelist$n[i] %in% converted) next
  
  # Generate the name of our WAV file
  wav.name = sub("mp3", "wav", scrapelist$a.path[i])

  # Read the mp3 file as audio
  audio = readMP3(scrapelist$a.path[i])

  # Convert to mono
  audio = mono(audio, which = "left")

  # Downsample to 16kHz (MFA's preference)
  audio = downsample(audio, 16000)

  # Get its duration
  scrapelist$dur[i] = round(length(audio@left)/(audio@samp.rate), 2)

  # Write it out as an WAV file
  writeWave(audio, wav.name, extensible=FALSE)
  
  # Delete the mp3 (not ideal but space problems)
  unlink(scrapelist$a.path[i])

  #break # for testing
  
  # Immediate garbage collection
  rm(audio)
  
}

# Now {root}/t-raw/ contains a .txt file with the transcript (and time stamps!) on one line. 
# Filename is episode number .txt

# Let's save the dataframe
saveRDS(scribed.all, "jrelist.rds")
saveRDS(scrapelist, "scrapelist.rds")

# Next: Trim the transcripts with trim.R
# Done

