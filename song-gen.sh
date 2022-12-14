source config.sh

if [ ! -f "popular.txt" ]; then
    echo "Downloading Dictonary File; Only happens once!"
    curl --silent https://raw.githubusercontent.com/dolph/dictionary/master/popular.txt > popular.txt
fi

seed_word=$( shuf -n 1 popular.txt )
prompt="Write Hotdog verse about $seed_word"

echo $prompt
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
jq . | \
grep -i '"text"' | \
perl -pe   's/"text":\s"//; \
            s/\s*",$//; \
            s/\\n\\n//; \
            s/^\s+//; \
            s/\\n/\n/g' | \
gtts-cli - --output verse.wav

#casio beat taken from https://audiokitpro.com/free-toy-casio-loops/
output="song-$seed_word-$( date +%s ).mp3"
ffmpeg -hide_banner -loglevel error -i verse.wav -i beat_long.mp3 -filter_complex amix=inputs=2:duration=shortest -b:a 160k $output
rm verse.wav
echo "Done: $output"