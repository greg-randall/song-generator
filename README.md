# song-generator

This will create a hotdog (or something else) themed song fully automatically using Ai.

## Setup:

1. Clone the repo.

2. Make a copy of the 'blank-config.sh' file and rename it to 'config.sh'.

3. Get an api key from https://beta.openai.com/account/api-keys, add your api key to the config.sh file.

4. Edit the 'song_contents' variable in the config.sh file to set the theme of the song. This should be short, but something that isn't generic, 'homestead', 'camera', 'hotdog', 'semi-truck' etc. 

5. Edit the 'key_word' variable in the config.sh file to make sure that keyword is in the final song. Typically the keyword will be the same as the 'song_contents', but could be a subset of the word -- ie if 'song_contents' is 'hotdog', the keyword might be 'dog'. It is possible to use a keyword that is different than the 'song_contents', but the program will fail to generate a song most of the time. You can leave 'key_word' blank if you don't care about making sure the is in the final song.

---

If you need more specific song, for example you want 'homestead farm' songs, you'll get much better results setting 'song_contents' to 'homestead farm' and 'key_word' to 'farm'.


## You'll probably need to install:
* jq - https://stedolan.github.io/jq/
* gtts-cli - https://manpages.ubuntu.com/manpages/bionic/man1/gtts-cli.1.html 
* ffmpeg - https://ffmpeg.org/ 
* sox - https://linux.die.net/man/1/sox

