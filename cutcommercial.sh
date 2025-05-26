#!/bin/bash

input_file="$1"  # .ts file passed in
input_base=$(basename "$input_file" .ts)
input_dir=$(dirname "$input_file")
edl_file="$input_dir/$input_base.edl"
output_mkv="$input_dir/$input_base.mkv"
temp_output_file="$input_dir/${input_base}_clean.ts"

# Exit if EDL doesn't exist
if [[ ! -f "$edl_file" ]]; then
  echo "Missing EDL: $edl_file"
  exit 1
fi

echo "Processing EDL: $edl_file"
echo "Input video: $input_file"
echo "Output (clean TS): $temp_output_file"
echo "Final Output (MKV): $output_mkv"

# Prepare parts directory
parts_dir="$input_dir/parts"
mkdir -p "$parts_dir"
rm -f "$parts_dir/"*.ts "$parts_dir/concat_list.txt"

# Read EDL and convert cut list to keep list
keep_starts=()
keep_ends=()
prev_end=0

while IFS= read -r line; do
  cut_start=$(echo "$line" | awk '{print $1}')
  cut_end=$(echo "$line" | awk '{print $2}')

  if [[ $(echo "$cut_start > $prev_end" | bc) -eq 1 ]]; then
    keep_starts+=("$prev_end")
    keep_ends+=("$cut_start")
  fi

  prev_end="$cut_end"
done < "$edl_file"

# Keep tail segment if any
duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$input_file")
if [[ $(echo "$prev_end < $duration" | bc) -eq 1 ]]; then
  keep_starts+=("$prev_end")
  keep_ends+=("$duration")
fi

# Extract keep segments
for i in "${!keep_starts[@]}"; do
  start="${keep_starts[$i]}"
  end="${keep_ends[$i]}"
  part_file="$parts_dir/part_$(printf "%02d" "$((i+1))").ts"
  echo "Keeping: $start to $end → $part_file"
  ffmpeg -loglevel error -stats -y -ss "$start" -to "$end" -i "$input_file" -c copy "$part_file"
  echo "file '$(basename "$part_file")'" >> "$parts_dir/concat_list.txt"
done

# Concatenate parts
echo "Concatenating parts..."
ffmpeg -loglevel error -stats -y -f concat -safe 0 -i "$parts_dir/concat_list.txt" -c copy "$temp_output_file"

# Convert to MKV using libx264
echo "Converting to MKV..."
ffmpeg -loglevel error -stats -y -i "$temp_output_file" -c:v libx264 -crf 24 -preset fast -c:a copy "$output_mkv"

# Cleanup
rm -f "$input_file"
rm -f "$temp_output_file"
rm -rf "$parts_dir"

echo "Done: $output_mkv"
