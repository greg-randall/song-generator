source config.sh
curl https://api.openai.com/v1/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $apikey" \
  -d '{
        "model": "text-davinci-003",
        "prompt": "Write Hotdog verse about buns",
        "temperature": 0.9,
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
gtts-cli - --output test.wav

ffmpeg -i test.wav -i beat_long.mp3 -filter_complex amix=inputs=2:duration=shortest -b:a 160k output5.mp3

