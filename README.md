# the 'joe "the corpus" rogan' corpus
A corpus of speech built from the Joe Rogan Experience podcast consisting of 8.43 million words. It includes aligned text grids with phoneme and word level transcripts.

## Quick Look
* More than 8.42 million words
* More than 833 hours of speech
* Prepackaged ngram frequencies, overall and by month
* Prealigned TextGrids for advanced acoustic analysis

## Citation
If you use this corpus for your research, please consider citing it:

**Turner, D.R. (2020). The Joe The Corpus Rogan Corpus. https://github.com/turnerdan/joethecorpusrogan/**


## Story
It was a Friday night in January and it was too cold to leave the house and so I started working on my research project, by which I mean I started procrastinating on my research project. When I saw a JRE episode trending on YouTube, I realized how many episodes there were -- all with audio released for free online.

"That's so much speech, and from the same speakers in the same discourse context, and over the course of a decade," I thought to myself, "I wonder if I can do something with that."

But, I only gave myself the weekend to take on this crazy project. What I could get done in a couple of days is what you see here. I hope people find it interesting or useful.

### Disclaimer
Neither this corpus nor its creator (Dan Turner) are affiliated with Joe Rogan or this podcast in any way. This corpus is not an endorsement of the show, its host, or its guests. None of the words in the corpus are my own.

# Details
Half of the reason I built this corpus was to create a framework for making a larger podcast corpus, for which this is a model. As such, I want to take a moment to document the workflow of the scripts I created and tools I used.

1. `scrape.R` reads the official RSS feed for the podcast and parses it for basic info, like episode number, date, and mp3 url. It then tries to scrape the transcript from podscribe.app and, if one is available, it downloads it and the mp3 to the local machine. Lastly, it converts the mp3s to wav format.

2. `trim.R` extracts timestamp information from the scraped transcripts so we have better landmarks for aligning the sound and the text. It writes csv files that Praat (http://www.fon.hum.uva.nl/praat/) will use later to assign spans of text to spans of sound.

3. `podchunk.praat` takes the wav files and csv files and creates TextGrid files that will tell our forced aligner what text goes with what spans of sound.

4. `align.R` calls the *Montreal Forced Aligner* (https://montreal-forced-aligner.readthedocs.io/en/latest/) on each wav and TextGrid pair. The resulting TextGrid file stores the location and duration of every word, and every sound of every word, exactly as they occur in the audio. Of course it's not perfect, *but it's pretty good*. If you've never seen aligned TextGrids before, they look like this:
![Example TextGrid+WAV in Praat](https://github.com/turnerdan/joethecorpusrogan/blob/master/TextGrid_screenshot.png)

You may find the aligned TextGrids in `/aligned/`. This is as far as I took the "sound side" of the corpus, since many analyses can be carried out with the TextGrids alone. If you want to do something like an acoustic analysis of the formants or pitch, then `scrape.R` will prepare the files for you.

5. `ngram.R` takes the transcripts and generates some frequency information for the "text side" analysis. The output of this script has two main parts, one that considers the transcript as a whole and one that looks at frequency across time (at the level of month). I did this because I want to see how the linguistic patterns and topics of the show have changed over time.

6. You can find the unigram ("the"), bigram ("the tall"), and trigram ("the tall boy") frequencies for terms across all of the transcripts as a whole (see `jtcr_uni/bi/trigram.csv`) or by month/year (see `jtcr_uni/bi/tri/gram_mo.csv`). Note the trigram file was too big to upload to github as a whole, so it's split across two zip files and will need to be unpacked before use.

7. `describe.R` calculates type and token frequency across the corpus, adds up the duration of all the scraped episodes, and some other basic statistics.

If you would like to see my process in more detail, it is all published here in the scripts mentioned above. I took time to write readable code with lots of helpful comments. So, if you want to launch a project like this, let my scripts be your starting point.
