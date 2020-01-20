# the 'joe "the corpus" rogan' corpus
A corpus of speech built from the Joe Rogan Experience podcast consisting of 8.43 million words. It includes aligned text grids with phoneme and word level transcripts.

## Quick Stats
* About 8.42 million words (w/ 67,819 unique types)
* About 833 hours of speech

## Basically
It was a Friday night in January and it was too cold to leave the house and so I started working on my research project, by which I mean I started procrastinating on my research project. When I saw a JRE episode trending on YouTube, I realized how many episodes there were -- all with audio released for free online.

"That's so much speech, and from the same speakers in the same discourse context, and over the course of a decade," I thought to myself, "I wonder if I can do something with that."

But, I only gave myself the weekend to take on this crazy project. What I could get done in a couple of days is what you see here. I hope people find it interesting or useful.

## Disclaimer
I am not affiliated with the Joe Rogan Experience in any way. This corpus is not my personal endorsement of any messages of the show or its guests. None of the words in the corpus are my own.

# The Details

Half of the reason I built this corpus was to create a framework for making a larger podcast corpus, for which this is a model. As such, I want to take a moment to document the workflow of the scripts I created and tools I used.

* scrape.R reads the official RSS feed for the podcast and parses it for basic info, like episode number, date, and mp3 url. It then tries to scrape the transcript from podscribe.app and, if one is available, it downloads it and the mp3 to the local machine. Lastly, it converts the mp3s to wav format.

* trim.R extracts timestamp information from the scraped transcripts so we have better landmarks for aligning the sound and the text. It writes csv files that Praat will use later to assign spans of text to spans of sound.

* podchunk.praat takes the wav files and csv files and creates TextGrid files that will tell our forced aligner what text goes with what spans of sound.

* At this point, I used the Montreal Forced Aligner (https://montreal-forced-aligner.readthedocs.io/en/latest/) to automatically transcribe each word into the phonetic alphabet. If you've never seen aligned TextGrids before, they look like this:

[screenshot]

This is as far as I took the "sound side" of the corpus, since many analyses can be carried out with the TextGrids alone. If you want to do something like an acoustic analysis of the speech, the scrape.R will download the files for you.

* ngram.R takes the transcripts and generates some frequency information for the "text side" analysis. The output of this script has two main parts, one that considers the transcript as a whole and one that looks at frequency across time (at the level of month). I did this because I want to see how the linguistic patterns and topics of the show have changed over time. 

* You can find the unigram ("the"), bigram ("the tall"), and trigram ("the tall boy") frequencies for terms across all of the transcripts as a whole (see jtcr_unigram.csv) or by month/year (see jtcr_unigram_mo.csv). 

* describe.R calculates type and token frequency across the corpus, adds up the duration of all the scraped episodes, and some other basic statistics.

If you would like to see my process in more detail, it is all published here in the scripts mentioned above. I took time to write readable code with lots of helpful comments. So, if you want to launch a project like this, let my scripts be your starting point.
