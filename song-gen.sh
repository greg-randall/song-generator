#!/bin/bash

#get variables from config
source config.sh

#check for the ddictonary file, if it doesn't exist, grab it
if [ ! -f "popular.txt" ]; then
    echo "Downloading Dictonary File; Only happens once!"
    curl --silent https://raw.githubusercontent.com/dolph/dictionary/master/popular.txt > popular.txt
fi

#grab the seed word from the dictonary & trim to make sure it's just letters
seed_word=$( shuf -n 1 popular.txt | perl -pe 's/[^\w]//')

#grab the genre from the list & trim to make sure it's just letters
#https://www.musicgenreslist.com/
genre_word=$( shuf -n 1 genres.txt | perl -pe 's/[^\w]//')

#build the prmpt for openai
prompt="Write short rhyming $genre_word music lyrics about $song_contents and $seed_word."
echo -e "$prompt\n"

#get timestamp, to not clobber other files
time=$( date +%s )

#generate output filename
output="song-$seed_word-$time"


loop=1
while true 
do
  #send out the prompt to openai and then beautify the json output with jq
  curl --silent https://api.openai.com/v1/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $apikey" \
    -d '{
          "model": "text-davinci-003",
          "prompt": "'"$prompt"'",
          "temperature": 1,
          "max_tokens": 250,
          "top_p": 1,
          "frequency_penalty": 0.0,
          "presence_penalty": 0.6,
          "stop": [" Human:", " AI:"]
        }' | jq . > temp_$time.txt

  #get just the response line from the json
  grep -i '"text"' temp_$time.txt | \

  #replace the literal "\n"s with tildes
  awk '{gsub(/\\n/, "~")} 1' | \

  #remove leading space & 'text' from the json
  perl -pe 's/^\s*"text":\s"\s*//' | \

  #remove the trailing spaces and quote from json
  perl -pe 's/\s*",$//' | \

  #replace tildies with actual linebreaks, removing excess whitespace
  perl -pe 's/\s*~+\s*/\n/g' | \

  #remove leading linebreaks
  perl -pe 's/^\n*//g' | \

  #sometimes there's a single word on the first line, this removes that. 
  perl -pe 's/^\w+\n//g' | \

  #sometimes the first line is really short, this removes that. 
  perl -pe 's/^.{0,15}\n//g' | \

  #sometimes there are escaped quotes. 
  perl -pe 's/\\"//g' | \

  #sometimes there are doublespaces 
  perl -pe 's/\s+/ /' | \

  #somtimes openai outputs a line like "verse 1:", we'll remoove those
  grep -iv "verse" | \
  grep -iv "chorus" | \
  grep -iv "bridge" > $output.txt

  #sometimes the openai output doesn't actually contain the key concept of the song
  #so we count the number of times that the word appears
  if [ ${#key_word} -ge 1 ]; then
    keyword_count=$( grep -i $key_word "$output.txt" | wc -l )
  else
    keyword_count=1
  fi

  seedword_count=$( grep -i $seed_word "$output.txt" | wc -l )



  #if the keyword & seedword appears, we break out of the loop
  if [ $keyword_count -ge 1 ] && [ $seedword_count -ge 1 ]; then
    break
  else
    #if the keyword & seedword doesn't exist, increment loop counter and try again
    loop=$(( loop + 1 ))
    echo -e "Error: Didn't find keywords, try $loop\n"

    #if we try to get a string with the keyword & seedword ten times, and fail, break the loop
    if [ $loop -ge 10 ]; then
      echo -e "Error: Exiting Loop after 10 tries\n"
      exit=true
      break
    fi
  fi
done

#make sure we actually got a successful string with the keyword & seedword
if [ ! $exit ]; then

  #print the verse out for viewers
  cat $output.txt

  #generate the text to speech track, and then back it with the casio loop song
  #casio beat taken from https://audiokitpro.com/free-toy-casio-loops/
  gtts-cli --lang en --nocheck -f $output.txt | ffmpeg -hide_banner -loglevel error -f mp3 -i - -i beat_long.mp3 -filter_complex amix=inputs=2:duration=shortest temp_$time.wav
  
  sox temp_$time.wav temp_$time-2.wav reverb 10 10 30

  ffmpeg -hide_banner -loglevel error -i temp_$time-2.wav -b:a 160k $output.mp3
  
  echo -e "\nDone: $output.mp3"

  rm temp_$time.wav
  rm temp_$time-2.wav
  rm temp_$time.txt
fi