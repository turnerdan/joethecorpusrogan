### Joe The Corpus Rogan
### By Dan Turner

### FORCE ALIGNING SUPERVISOR
# The files in the corpus are too big for a normal application of the Montreal Forced Aligner, so I wrote this R script to spawn and supervise a constrained process.

# For every pair of .WAV and .TextGrid files, it creates a new directory and copies the pair of files there, then it calls the aligner on that directory. Because MFA clears the directory on each run, it copies the output (an aligned TextGrid) to a backup directory, which is the defacto output directory.

# This is especially useful, since the corpus is large (~80GB).

### Updated 1-20-2020

###########
## Setup ##
###########

# Path to audio files and text grids
inpath = "/Volumes/Seagate 8TB HDD/Joe The Corpus Rogan/a-raw/"

# Path for the aligned text grids
outpath = "/Users/dt/Git/joethecorpus/aligned/"
backuppath = "/Users/dt/Git/joethecorpus/aligned-backup"

# Path for scratch folder
scratch = "~/Git/joethecorpus/scratch"

# List the text grids that need aligning
setwd(inpath) # on my external drive
textgrids = list.files(pattern = ".*.TextGrid")

# List text grids that we've already aligned
setwd(backuppath)
aligned = list.files(pattern = ".*.TextGrid")

# Loop the text grid files to create a directory for each grid-wav pair to align

# Do we need to break the loop after this iteration?
breakit = FALSE

for (tg in textgrids){
  
  # If it's been aligned, skip it
  if (tg %in% aligned) next
  
  # Print a message
  print(paste("STARTING", tg))
  
  # Create temporary directory
  try(unlink(scratch, recursive=TRUE))
  dir.create(scratch)
  
  # Copy the text grid and wav to the temporary directory /tmp/
  file.copy(paste0(inpath, tg), scratch) # TextGrid
  file.copy(paste0(inpath, sub(".TextGrid", ".wav", tg)), scratch) # WAV
  
  ########################
  ## Alignment with MFA ##
  ########################
  
  # Set the Working Directory to MFA
  setwd("/Applications/MontrealForcedAligner")

  # Write the call to MFA
  dictpath = "/Applications/MontrealForcedAligner/pretrained_models/englishdict.txt"
  mfaflags = "--verbose --quiet --speaker_characters 2"
  
  # Put it together
  call = paste("bin/mfa_align", scratch, dictpath, "english", outpath, mfaflags)
  
  # Make the call to MFA for this pair
  system(call)
  
  # Copy aligned textgrid to /aligned/backup
  # The de facto output directory, as the outpath gets overwritten. 
  file.copy(paste0(outpath, tg), backuppath)
  
  # Delete scratch
  try(unlink(scratch, recursive=TRUE))

  # Print a message
  print(paste("FINISHING", tg))
  
  # If we need to break the loop
  if (breakit) break
  
}
# Bleep
beep()




