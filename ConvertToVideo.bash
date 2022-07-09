#!/bin/bash
input_dir='./'
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")"/"
convert_density=1800
video_res=1920x1080
fps=30
ffmpeg_quiet="ffmpeg -hide_banner -loglevel error -nostdin"

print_usage() {
	printf "bash $0 input_file [-d input_dir] output_file\n"
}

input_file=$1; shift

while getopts 'd:t:' flag; do
	case "${flag}" in
		d) input_dir="${OPTARG}"
			if [[ ${input_dir: -1} != "/" ]]
			then
				input_dir="${input_dir}/"
			fi
			;;
		t) tmp_dir="${OPTARG}"
			if [[ ${tmp_dir: -1} != "/" ]]
			then
				tmp_dir="${tmp_dir}/"
			fi
			;;
		*) print_usage
			exit 1 ;;
	esac
done

if [ ! -f "${input_file}" ]; then
	echo "${input_file} does not exist."
	exit 1;
fi

echo "Input directory: " $input_dir
echo "Temporary directory: " $tmp_dir

tmp_video_dir="${tmp_dir}video_files/"
tmp_image_dir="${tmp_dir}pdf_images/"

mkdir -p $tmp_video_dir
mkdir -p $tmp_image_dir

video_list_filename="${tmp_video_dir}video_list.txt"
if [[ -f ${video_list_filename} ]]; then rm ${video_list_filename}; fi

GenerateVideo () {
	${ffmpeg_quiet} -framerate 1/${2} -i "${1}" -c:v libx264 -profile:v high -crf 12  -vf "fps=${fps},format=yuv420p" -s ${video_res} ${3}
}

trap "exit" INT
while IFS= read -r line;do
	echo ${line}
	fields=($(printf "%s" "$line"|cut -d',' --output-delimiter=' ' -f1-))
	file_name="${input_dir}${fields[1]}"
	case "${fields[0]}" in
		s) if [[ ${#fields[@]} != 4 ]]; then >&2 echo "Invalid input file: check field \"${line}\""; exit 1; fi
			if [[ ! -f "${file_name}" ]]; then >&2 echo "${file_name} does not exist: check field \"${line}\""; exit 1; fi
			slide_name=$(basename -- "${file_name%.*}")
			base_file_name=${slide_name}_${fields[2]}
			image_file_name="${tmp_image_dir}${base_file_name}.png"
			video_file_name="${tmp_video_dir}${base_file_name}.mp4"
			convert -density ${convert_density} "${file_name}[${fields[2]}]" "${image_file_name}"
			mogrify -thumbnail ${video_res} -background black -gravity center -extent ${video_res} ${image_file_name}
			GenerateVideo ${image_file_name} ${fields[3]} ${video_file_name}
			printf "file \'${base_file_name}.mp4\'\n" >> ${video_list_filename}
			;;
		i) if [[ ${#fields[@]} != 3 ]]; then >&2 echo "Invalid input file: check field \"${line}\""; exit 1; fi
			base_file_name="${fields[1]%.*}.mp4"
			video_file_name="${tmp_video_dir}${base_file_name}"
			GenerateVideo ${file_name} ${fields[2]} ${video_file_name}
			printf "file \'${base_file_name}\'\n" >> ${video_list_filename}
			;;
		v)
			case "${#fields[@]}" in
				2) cp ${file_name} ${tmp_video_dir}${fields[1]}
					printf "file \'${fields[1]}\'\n" >> ${video_list_filename}
					;;
				3) ${ffmpeg_quiet} -ss ${fields[2]} -i ${file_name} ${tmp_video_dir}${fields[1]}
					printf "file \'${fields[1]}\'\n" >> ${video_list_filename}
					;;
				4) ${ffmpeg_quiet} -ss ${fields[2]} -i ${file_name} -to ${fields[3]} ${tmp_video_dir}${fields[1]}
					printf "file \'${fields[1]}\'\n" >> ${video_list_filename}
					;;
				*) >&2 echo "Invalid input file: check field \"${line}\""; exit 1
					;;
			esac ;;
		*) echo "Invalid input file: check field \"${line}\""
			exit 1 ;;
	esac
done < ${input_file}
${ffmpeg_quiet} -f concat -safe 0 -i ${video_list_filename} ${*: -1}
rm -r "$tmp_dir"
