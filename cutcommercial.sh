#!/bin/bash
set -e

# Check input
if [ -z "$1" ]; then
echo "❌ Usage: $0 <input_file.ts>"
exit 1
fi

input_file="$1"
filename_base="${input_file%.*}"
edl_file="${filename_base}.edl"
temp_output_file="${filename_base}_clean.ts"
mkv_output_file="${filename_base}.mkv"

# Ensure EDL file exists
if [ ! -f "$edl_file" ]; then
echo "❌ EDL file not found: $edl_file"
exit 1
fi

echo "Input video: $input_file"
echo "EDL file: $edl_file"
echo "Temporary output: $temp_output_file"
echo "Final MKV: $mkv_output_file"

mkdir -p parts
rm -f parts/part_*.ts parts/concat_list.txt

# Step 1: Get total duration of input video
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")
duration=$(printf "%.2f" "$duration")

# Step 2: Invert EDL into "keep" ranges
keep_starts=()
keep_ends=()

last_end=0

while read -r start end _; do
# Buffer commercial cut range by 1 second inward
start=$(echo "$start + 1" | bc)
end=$(echo "$end - 1" | bc)

if (( $(echo "$start > $last_end" | bc -l) )); then
keep_starts+=("$last_end")
keep_ends+=("$start")
fi
last_end="$end"
done < "$edl_file"

if (( $(echo "$last_end < $duration" | bc -l) )); then
keep_starts+=("$last_end")
keep_ends+=("$duration")
fi

# Step 3: Extract keep segments
for i in "${!keep_starts[@]}"; do
start="${keep_starts[$i]}"
end="${keep_ends[$i]}"
part_file=$(printf "parts/part_%02d.ts" "$((i+1))")
echo "Keeping: $start to $end → $part_file"
ffmpeg -loglevel error -stats -y -ss "$start" -to "$end" -i "$input_file" -c copy "$part_file"
echo "file '$(basename "$part_file")'" >> parts/concat_list.txt
done

# Step 4: Concatenate
pushd parts > /dev/null
ffmpeg -loglevel error -stats -y -f concat -safe 0 -i concat_list.txt -c copy "../$temp_output_file"
popd > /dev/null

# Step 5: Encode to MKV using libx265
echo "Converting to MKV..."
ffmpeg -loglevel error -stats -y -i "$temp_output_file" -c:v libx265 -c:a copy "$mkv_output_file"

# Step 6: Cleanup
echo "Cleaning up..."
rm -f "$input_file" "$temp_output_file"
rm -rf parts

echo "✅ Done. Final file: $mkv_output_file"

