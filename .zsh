# SoundCloud downloader helpers
# Dependencies: yt-dlp, ffmpeg, ffprobe
# Usage examples:
#   dw https://soundcloud.com/...                 # download -> MP3 320kbps
#   dw -w https://soundcloud.com/...              # download -> WAV
#   dw -c ./cookies.txt https://soundcloud.com/...# use cookies (for private/age-gated tracks)
#   dw -o ./music https://soundcloud.com/...      # output directory
#   dwa https://soundcloud.com/.../sets/...       # quick playlist to MP3 (no art)
#   bitrate *.mp3                                  # show bitrate(s)

# ---- common helpers ----
_sc_require() {
  for bin in "$@"; do
    command -v "$bin" >/dev/null 2>&1 || {
      echo "Missing dependency: $bin" >&2
      return 127
    }
  done
}

_sc_clean_on_exit() {
  local dir="$1"
  trap 'rm -rf "'"$dir"'"' EXIT
}

_sc_find_thumb() {
  # find a thumbnail with same basename but any common image ext
  local base="${1%.*}"
  for ext in jpg jpeg png webp; do
    [ -f "$base.$ext" ] && { echo "$base.$ext"; return 0; }
  done
  return 1
}

# ---- dw: download one URL (track or playlist), convert to mp3 320k by default ----
dw() {
  _sc_require yt-dlp ffmpeg ffprobe || return $?

  local output_format="mp3"   # default final format
  local bitrate="320k"        # mp3 bitrate
  local cookies_file=""       # optional
  local outdir="."            # where final files go
  local sc_url=""             # url arg

  # parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -w) output_format="wav"; shift ;;
      -c|--cookies) cookies_file="$2"; shift 2 ;;
      -o|--outdir)  outdir="$2"; shift 2 ;;
      -b|--bitrate) bitrate="$2"; shift 2 ;;
      --) shift; break ;;
      -h|--help)
        cat <<EOF
Usage: dw [-w] [-c cookies.txt] [-o outdir] [-b 320k] <soundcloud_url>
  -w                 Output WAV instead of MP3
  -c, --cookies      Path to exported cookies file (optional)
  -o, --outdir       Output directory (default: .)
  -b, --bitrate      MP3 bitrate when output is MP3 (default: 320k)
EOF
        return 0
        ;;
      *) sc_url="$1"; shift ;;
    esac
  done

  if [ -z "$sc_url" ]; then
    echo "Usage: dw [-w] [-c cookies.txt] [-o outdir] [-b 320k] <soundcloud_url>"
    return 1
  fi

  mkdir -p "$outdir" || return $?
  local tmpdir
  tmpdir="$(mktemp -d)" || return $?
  _sc_clean_on_exit "$tmpdir"

  # Build yt-dlp args
  local ytdlp_args=( -x --audio-format wav --add-metadata --write-thumbnail --convert-thumbnails jpg
                     -o "$tmpdir/%(uploader)s - %(title)s.%(ext)s" )
  if [ -n "$cookies_file" ]; then
    ytdlp_args=( --cookies "$cookies_file" "${ytdlp_args[@]}" )
  fi

  yt-dlp "${ytdlp_args[@]}" "$sc_url" || return $?

  if [[ "$output_format" == "wav" ]]; then
    # deliver WAVs as-is
    shopt -s nullglob
    for wav in "$tmpdir"/*.wav; do
      mv -f "$wav" "$outdir"/
    done
    echo "Downloaded WAV files to: $outdir"
    return 0
  fi

  # Convert to MP3 320k with embedded metadata and cover art (if available)
  shopt -s nullglob
  for wav in "$tmpdir"/*.wav; do
    # extract tags (falling back uploader->artist if needed)
    title="$(ffprobe -v error -show_entries format_tags=title  -of default=noprint_wrappers=1:nokey=1 "$wav")"
    artist="$(ffprobe -v error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$wav")"
    uploader="$(ffprobe -v error -show_entries format_tags=uploader -of default=noprint_wrappers=1:nokey=1 "$wav")"
    [ -z "$artist" ] && artist="$uploader"

    out_mp3="$outdir/$(basename "${wav%.wav}.mp3")"

    if thumb="$(_sc_find_thumb "$wav")"; then
      ffmpeg -y -i "$wav" -i "$thumb" \
        -map 0:a:0 -map 1:v:0 -c:a libmp3lame -b:a "$bitrate" -c:v copy \
        -metadata title="$title" -metadata artist="$artist" \
        -id3v2_version 3 "$out_mp3"
    else
      ffmpeg -y -i "$wav" \
        -c:a libmp3lame -b:a "$bitrate" \
        -metadata title="$title" -metadata artist="$artist" \
        -id3v2_version 3 "$out_mp3"
    fi
  done

  echo "Converted MP3 files saved to: $outdir"

  # Optional: verify bitrate
  shopt -s nullglob
  for mp3 in "$outdir"/*.mp3; do
    br="$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate \
          -of default=noprint_wrappers=1:nokey=1 "$mp3")"
    [ -n "$br" ] && echo "File: $(basename "$mp3")  Bitrate: $((br/1000)) kbps"
  done
}

# ---- dwa: quick “download & convert all” to MP3 (no art embedding) ----
dwa() {
  _sc_require yt-dlp ffmpeg ffprobe || return $?

  local sc_url="$1"
  if [ -z "$sc_url" ]; then
    echo "Usage: dwa <soundcloud_url>"
    return 1
  fi

  local tmpdir
  tmpdir="$(mktemp -d)" || return $?
  _sc_clean_on_exit "$tmpdir"

  yt-dlp -x --audio-format wav --add-metadata \
    -o "$tmpdir/%(uploader)s - %(title)s.%(ext)s" "$sc_url" || return $?

  shopt -s nullglob
  for wav in "$tmpdir"/*.wav; do
    title="$(ffprobe -v error -show_entries format_tags=title  -of default=noprint_wrappers=1:nokey=1 "$wav")"
    artist="$(ffprobe -v error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$wav")"
    uploader="$(ffprobe -v error -show_entries format_tags=uploader -of default=noprint_wrappers=1:nokey=1 "$wav")"
    [ -z "$artist" ] && artist="$uploader"

    ffmpeg -y -i "$wav" -c:a libmp3lame -b:a 320k \
      -metadata title="$title" -metadata artist="$artist" \
      -id3v2_version 3 "${wav%.wav}.mp3"
  done

  mv -f "$tmpdir"/*.mp3 . 2>/dev/null || true

  # verify bitrates
  for mp3 in ./*.mp3; do
    [ -f "$mp3" ] || continue
    br="$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate \
          -of default=noprint_wrappers=1:nokey=1 "$mp3")"
    [ -n "$br" ] && echo "File: $(basename "$mp3")  Bitrate: $((br/1000)) kbps"
  done
}

# ---- bitrate: show audio bitrate(s) for any file list ----
bitrate() {
  _sc_require ffprobe || return $?
  if [ $# -eq 0 ]; then
    echo "Usage: bitrate <file1> [file2 ...]"
    return 1
  fi
  for file in "$@"; do
    if [ -f "$file" ]; then
      br="$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate \
            -of default=noprint_wrappers=1:nokey=1 "$file")"
      if [ -n "$br" ]; then
        echo "File: $file  Bitrate: $((br/1000)) kbps"
      else
        echo "File: $file  Bitrate: (unknown)"
      fi
    else
      echo "File not found: $file"
    fi
  done
}
