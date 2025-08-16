# SoundCloud Downloader (mp3/wav) — simple bash helpers

Download tracks or playlists from SoundCloud as **MP3 (320 kbps)** or **WAV**, with metadata and cover art when available.  
No coding required — just follow the steps below.

> ⚠️ **Important:** Only download audio you have the right to download. Respect SoundCloud’s Terms of Service and your local laws.

---

## What you get

- `dw` – download a SoundCloud URL → **MP3 (320k)** by default, or **WAV** with `-w`
- `dwa` – quick “download all to MP3” (no cover art embedding)
- `bitrate` – check the bitrate of audio files

Examples:

```bash
dw https://soundcloud.com/artist/track
dw -w https://soundcloud.com/artist/track           # WAV instead of MP3
dw -c ./cookies.txt https://soundcloud.com/…        # use cookies when needed
dw -o ./music -b 192k https://soundcloud.com/…      # choose output folder/bitrate
dwa https://soundcloud.com/artist/sets/playlist
bitrate *.mp3
```

## 1 Install the required tools

You need yt-dlp, ffmpeg, and ffprobe (ffprobe comes with ffmpeg).

macOS (Homebrew)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install yt-dlp ffmpeg
```

To verify:

```bash
yt-dlp --version
ffmpeg -version
ffprobe -version
```

### 2 Add the script functions

1.Open your shell config file:

- macOS/Linux zsh: nano ~/.zshrc
- macOS/Linux bash: nano ~/.bashrc
  2.Paste the contents of scripts.sh from this repo at the bottom of that file.

3. Save and reload your terminal, or run:

```bash
source ~/.zshrc   # or: source ~/.bashrc
```

### 3 (Optional) Using cookies for private/age-gated tracks

Some tracks/playlists need your SoundCloud login session. You can export your browser cookies and pass them to the script.

Export cookies from your browser to a Netscape format file (e.g., cookies.txt).

Many browser extensions can do this (search “export cookies Netscape format”).

Put the file somewhere handy, like your Music folder.

Use the -c flag:

dw -c ./cookies.txt https://soundcloud.com/artist/track

### 4 Quick start (copy & paste)

Download as MP3 (320k):

dw https://soundcloud.com/artist/track

Download entire playlist as MP3:

dwa https://soundcloud.com/artist/sets/my-playlist

Download as WAV:

dw -w https://soundcloud.com/artist/track

Choose output folder and bitrate:

```bash
dw -o ./Downloads/Music -b 192k https://soundcloud.com/artist/track
```

Use cookies:

```bash
dw -c ./cookies.txt https://soundcloud.com/artist/track
```

Command reference

```bash
dw — main downloader
dw [-w] [-c cookies.txt] [-o outdir] [-b 320k] <soundcloud_url>

-w                Output WAV instead of MP3
-c, --cookies     Path to cookies file (Netscape format)
-o, --outdir      Output directory (default: current folder)
-b, --bitrate     MP3 bitrate if output is MP3 (default: 320k)

dwa — quick playlist/URL → MP3 (no cover art embedding)
dwa <soundcloud_url>

bitrate — print bitrate for files
bitrate <file1> [file2 ...]
```
