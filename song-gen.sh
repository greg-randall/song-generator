source config.sh

if [ ! -f "popular.txt" ]; then
    echo "Downloading Dictonary File; Only happens once!"
    curl --silent https://raw.githubusercontent.com/dolph/dictionary/master/popular.txt > popular.txt
fi

seed_word=$( shuf -n 1 popular.txt | perl -pe 's/[^\w]//')
prompt="Write $song_contents verse about $seed_word"
time=$( date +%s )
output="song-$seed_word-$time"

echo -e "$prompt\n"

loop=1

while true 
do
  curl --silent https://api.openai.com/v1/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $apikey" \
    -d '{
          "model": "text-davinci-003",
          "prompt": "'"$prompt"'",
          "temperature": 1,
          "max_tokens": 150,
          "top_p": 1,
          "frequency_penalty": 0.0,
          "presence_penalty": 0.6,
          "stop": [" Human:", " AI:"]
        }' | \
  jq . > temp.txt

  grep -i '"text"' temp.txt | \
  awk '{gsub(/\\n/, "~")} 1' | \
  perl -pe 's/^\s*"text":\s"//g' | \
  perl -pe 's/\s*",$//g' | \
  perl -pe 's/^\s*\w*~~",$//g' | \
  perl -pe 's/\s*~\s*/\n/g' | \
  perl -pe 's/\n+/\n/g' | \
  perl -pe 's/^\n//g' | \
  grep -iv "verse" | grep -iv "chorus" | grep -iv "bridge" > $output.txt

  keyword_count=$( grep -i $key_word "$output.txt" | wc -l)
  if [ $keyword_count -ge 1 ]; then
    break
  else
    loop=$(( loop + 1 ))
    echo -e "Error: Didn't find keyword, retrying $loop\n"
  fi
  if [ $loop -ge 10 ]; then
    echo -e "Error: Exiting Loop after 10 tries\n"
    exit=true
    break
  fi
done

if [ ! $exit ]; then
  cat $output.txt

  gtts-cli -f $output.txt | ffmpeg -hide_banner -loglevel error -f mp3 -i - -i beat_long.mp3 -filter_complex amix=inputs=2:duration=shortest -b:a 160k $output.mp3
  #casio beat taken from https://audiokitpro.com/free-toy-casio-loops/

  echo -e "\nDone: $output.mp3"
fi