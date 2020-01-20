### Joe The Corpus Rogan
### By Dan Turner

### NGRAM FILE GENERATION SCRIPT
# This file performs some basic summarization of the ngram frequency in the transcripts.
# It reads transcripts from /t-raw/ and uses scrapelist.rds to generate ngram frequencies.
# The output goes in /ngram/

### Updated 1-19-2020

###########
## Setup ##
###########

# Load packages
library(rvest) # Web scraping
library(stringr) # String handling
library(readr) # Nice reading and writing
library(ngram)
library(lubridate)
library(tm)

# WD
setwd("~/Git/joethecorpus")

# Episodes dataframe
eps <- readRDS("~/Git/joethecorpus/scrapelist.rds")

# We only care about the ones with transcripts
eps <- subset(eps, eps$t.avail == TRUE)

#############################
## Load and clean the text ##
#############################

# First let's see what episodes we have transcripts for (filename sans .txt)
t.list <- list.files(path = "./t-raw", recursive = TRUE,
                            pattern = "\\.txt$", 
                            full.names = TRUE)

# Same as above, but just the numbers
t.list.n = as.double( sub(".txt", "", list.files("./t-raw")) )

# Read every transcript at once line by line
lines = lapply(t.list, readLines) 

# Combine the above with the episode number list
lines = data.frame("n" = t.list.n, "txt" = unlist(lines))

# Combine the above with the episode list
eps = merge.data.frame(lines, eps, by.x = "n", by.y = "n")

# Garbage collection
rm(lines, t.list, t.list.n)

# Clean the text
eps$txt = str_remove_all(eps$txt, "[0-9][0-9]:[0-9][0-9]:[0-9][0-9]") # Remove timestamps
eps$txt = gsub("►", "", eps$txt) # Remove play arrows
eps$txt = gsub("[^[:alnum:][:space:]']", "", eps$txt) # Remove punctuation except "< ' >
eps$txt = str_squish(eps$txt) # Remove extra whitespace

##################################################
## Identify common terms across all transcripts ##
##################################################

# Extract the most frequent n tokens
cutoff = 1000

# Let's get 'cutoff' number of most frequent tokens across all transcripts
all.txt = paste(eps$txt, sep="", collapse="")

# Remove nonalphabetical characters, retain spaces
#all.txt = str_squish( gsub("[^[:alnum:][:space:]]", "", all.txt) )

# Filter out stopwords here if desired
#stopwords(kind = "en")

# Generate 1- 2- and 3- grams for all transcripts
all.gram1 = ngram(all.txt, n = 1, sep = " ")
all.gram2 = ngram(all.txt, n = 2, sep = " ")
all.gram3 = ngram(all.txt, n = 3, sep = " ")

# Frequency table generation
all.gram1 = get.phrasetable(all.gram1)
all.gram2 = get.phrasetable(all.gram2)
all.gram3 = get.phrasetable(all.gram3)

# Trim the frequnecy tables to the cutoff
#     Have to unlist them and unname them for easier matching later
#     Squish out unwanted white space (this is necessary after each tokenization)

top.gram1 = str_squish( unname(unlist(head(all.gram1, cutoff))) )
top.gram2 = str_squish( unname(unlist(head(all.gram2, cutoff))) )
top.gram3 = str_squish( unname(unlist(head(all.gram3, cutoff))) )

# After squishing we have dupliacates, because a space made some ngrams unique
top.gram1 = unique(top.gram1)
top.gram2 = unique(top.gram2)
top.gram3 = unique(top.gram3)

# Write the all.gram data
write_csv(all.gram1, "jtcr_unigram.csv")
write_csv(all.gram2, "jtcr_bigram.csv")
write_csv(all.gram3, "jtcr_trigram.csv")
write_lines(all.txt, "jtcr_oneline.txt")

# Garbage collection
rm(all.gram1, all.gram2, all.gram3, all.txt)

###################################################################
## Calculate 1-, 2-, and 3-gram term frequencies by month > year ##
###################################################################

# Prepare the ngram dataframes
gram1 = data.frame(matrix(ncol=(3 + length(top.gram1)), nrow=0, dimnames=list(NULL, c("year", "month", "eplist", top.gram1))))
gram2 = data.frame(matrix(ncol=(3 + length(top.gram2)), nrow=0, dimnames=list(NULL, c("year", "month", "eplist", top.gram2))))
gram3 = data.frame(matrix(ncol=(3 + length(top.gram3)), nrow=0, dimnames=list(NULL, c("year", "month", "eplist", top.gram3))))

# Extract the month and year for each episode and write to a new column
eps$date_year = year(eps$date)
eps$date_month = month(eps$date)

# # FOR TESTING
# month = 1
# year = 2019

# Set up a month > year dataframe
for (year in unique( year(eps$date) ) ){
  for (month in 1:12){
    
    # Get all the podcasts in this month and year
    mo.set = subset(subset(eps, date_year == year), date_month == month)
    
    # If there's no podcast for this month and year, skip
    if (nrow(mo.set) < 1) next
  
    # Collect the transcripts for these episodes
    mo.txt = paste(mo.set$txt, sep="", collapse="")
    
    # Tokenization
    mo.gram1 = ngram(mo.txt, n = 1, sep = " ")
    mo.gram2 = ngram(mo.txt, n = 2, sep = " ")
    mo.gram3 = ngram(mo.txt, n = 3, sep = " ")
    
    # Don't need the text anymore
    rm(mo.txt)
  
    # Frequency table generation
    mo.gram1 = get.phrasetable(mo.gram1)
    mo.gram2 = get.phrasetable(mo.gram2)
    mo.gram3 = get.phrasetable(mo.gram3)
    
    # Clean the monthly grams of extra whitespace
    mo.gram1$ngrams = str_squish( mo.gram1$ngrams)
    mo.gram2$ngrams = str_squish( mo.gram2$ngrams)
    mo.gram3$ngrams = str_squish( mo.gram3$ngrams)
    
    
    ##################################################
    ## Write out the monthly ngram phrasetable data ##
    ##################################################
    
    # New rows for gramNs
    bottom1 = nrow(gram1) + 1
    bottom2 = nrow(gram2) + 1
    bottom3 = nrow(gram3) + 1
    
    # Prepare the new row in the gram dataframes
    gram1[bottom1,]       <- rep(0, ncol(gram1))
    gram1$year[bottom1]   <- year
    gram1$month[bottom1]  <- month
    gram1$eplist[bottom1] <- list(mo.set$n)
    
    # Prepare the new row in the gram dataframes
    gram1[bottom2,]       <- rep(0, ncol(gram2))
    gram1$year[bottom2]   <- year
    gram1$month[bottom2]  <- month
    gram1$eplist[bottom2] <- list(mo.set$n)
    
    # Prepare the new row in the gram dataframes
    gram1[bottom3,]       <- rep(0, ncol(gram3))
    gram1$year[bottom3]   <- year
    gram1$month[bottom3]  <- month
    gram1$eplist[bottom3] <- list(mo.set$n)
    
    # Stage the loops for each gramN: what grams are available?
    stage.gram1 = intersect(mo.gram1$ngrams, top.gram1)
    stage.gram2 = intersect(mo.gram2$ngrams, top.gram2)
    stage.gram3 = intersect(mo.gram3$ngrams, top.gram3)
    
    # Populate gram1
    for (g in stage.gram1){
      gram1[bottom1, g] <- mo.gram1$freq[ mo.gram1$ngrams == g ]
    }
    # Garbage collection
    rm(stage.gram1, bottom1, mo.gram1)
    
    # Populate gram2
    for (g in stage.gram2){
      gram2[bottom2, g] <- mo.gram2$freq[ mo.gram2$ngrams == g ]
    }
    # Garbage collection
    rm(stage.gram2, bottom2, mo.gram2)
    
    # Populate gram3
    for (g in stage.gram3){
      gram3[bottom3, g] <- mo.gram3$freq[ mo.gram3$ngrams == g ]
    }
    # Garbage collection
    rm(stage.gram3, bottom3, mo.gram3)
    
  } # /month loop

} # /year loop

# Note: this takes quite long. I could rewrite the for loops into something faster, but I'm only going to run this once ever, so I don't mind waiting and writing a long comment instead of splitting up the loop into parallelized foreach calls or something like that -- but YOU could do something like this if it's interesting to you. Also note there's a couple places I split off the data flow so you can handle the text in a way more tailored for your application, such as filtering out stopwords if that's a priority for you. I did not do this because some words that are 'stopwords' are imporant in a multigram context. For example, in Joe The Corpus Rogan, 'the' is not the same gram as in 'this is the end of the comment'.

# Write the mo.gram data
write_csv(as.data.frame(gram1), "jtcr_unigram_mo.csv")
write_csv(gram2, "jtcr_bigram_mo.csv")
write_csv(gram3, "jtcr_trigram_mo.csv")


# Garbage collection
rm(top.gram1, top.gram2, top.gram3, g, cutoff, year, month, mo.set)

# That's all! Now have have the building blocks for basic text analysis, and some advanced stuff.

# Done
