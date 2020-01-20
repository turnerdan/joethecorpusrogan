### Joe The Corpus Rogan
### By Dan Turner

### PODCAST CHUNKING SCRIPT
# This file takes a directory of WAV files and transcript trim files (written by the accompanying R script, trim.R) and it builds the transcript as an interval tier in a TextGrid file, which it saves to /podchunks/.

# WAV files are in /a-raw/ and transcript trim files are in /podchunks/.

### Updated 1-19-2020

###########
## Setup ##
###########

# Set the path to the joethecorpus directory
dir$ = "/Volumes/Seagate 8TB HDD/Joe The Corpus Rogan/"

###################################################
## Loop the transcript trim files in /podchunks/ ##
###################################################

# Extract all the names of the wav files in the /a-raw/ directory
Create Strings as file list: "wav_list", dir$ + "a-raw/*.wav"

# Get number of files
wav_list_len = Get number of strings

# Let's print helpful messages as we go
writeInfoLine: "Beginning podchunking..."

# Loop the podcasts
for wav to wav_list_len

	# Select the source list and get the file name 
    selectObject: "Strings wav_list"
    wav_path$ = Get string: wav
    
    # Extract the podcast number
    epN$ = wav_path$ - ".wav"

	# Read the podcast sound file
    Read from file: dir$ + "a-raw/" + wav_path$
    
    # Get the duration of the file
    dur = Get total duration
    
    # Create a blank TextGrid with one interval tier, "words"
    To TextGrid: "words", ""
    
    # Close the sound file (not needed anymore)
    selectObject: "Sound " + epN$
    Remove
    
    # Read the transcript trim file
    Read Table from comma-separated file: dir$ + "podchunks/" + epN$ + ".csv"
    
    # Get number of transcript parts / intervals in the trim file
	numberOfParts = Get number of rows
	
	# Begin dialog
	appendInfoLine: "Working on ep" + epN$
    
	#####################################
	## Write TextGrids for Transcripts ##
	#####################################

	# Loop the trim file row by row

	# Index start
	row = 0

	for xfile to numberOfParts

		# New row
		row = row + 1
		
		# Extract the data from the Table row
		selectObject: "Table " + epN$
		row_interval = Get value: row, "interval"
		row_text$ = Get value: row, "text"
		row_left = Get value: row, "leftbound"
		row_right = Get value: row, "rightbound"
		
		# Get ready to write to the TextGrid
		selectObject: "TextGrid " + epN$
		last_interval = Get number of intervals: 1
		
		## Condition tree
		# On last interval write to the end
		if row = numberOfParts
			
			Set interval text: 1, row_interval, row_text$
			
			appendInfoLine: "Writing ep" + epN$ + ": Success!"
		
		# Not the last interval
		else
		
			# Normal interval behavior
			if row_right < dur
				Insert boundary: 1, row_right
				Set interval text: 1, row_interval, row_text$
			
			# If for some reason the boundary is outside the range
			# Keep in mind, this isn't the last interval! Big problem.	
			else
			
				appendInfoLine: "Skipping ep" + epN$ + ": Fatal boundary error"
				
				# Break this loop
				xfile = numberOfParts
				
			# End normal behavior section
			endif
			
		# End the condition tree
		endif	

	# End the parts loop
	endfor
	
	# Write the TextGrid file to /a-raw/
	selectObject: "TextGrid " + epN$
	Save as text file: dir$ + "a-raw/" + epN$ + ".TextGrid"
	
	# Garbage Collection
	selectObject: "TextGrid " + epN$
	plusObject: "Table " + epN$
	Remove
	
# End the transcript loop
endfor

# Done