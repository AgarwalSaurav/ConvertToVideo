#!/bin/python
#
# Author: Saurav Agarwal
# License: GPL3 license
#
# Requires: Linux system with ffmpeg and imagemagick
# Command: python3 slides2video.py sample_slides.pdf slides_timings sample_output.mp4
# Input:    slide PDF file
#           video timings file
#           final video filename

import sys
import os

def main():
    output_dir = "temp/"
    input_dir = "input/"

    slide_filename = input_dir + sys.argv[1]
    video_timings_filename = input_dir + sys.argv[2]

    videofile = output_dir + sys.argv[3]
    temp_video_dir = output_dir + "video_files/"
    slide_image_dir = output_dir + "pdf_images/"

    os.system("mkdir -p " + temp_video_dir)
    os.system("mkdir -p " + slide_image_dir)

    if not os.path.isfile(video_timings_filename):
        print("File path {} does not exist. Exiting".format(video_timings_filename))
        sys.exit()
    video_list_filename = temp_video_dir + "/video_list.txt";
    video_list = open(video_list_filename, "w")

    with open(video_timings_filename) as fp:
        cnt = 0
        for line in fp:
            slide_number, duration = line.strip().split(' ')
            print(slide_number)
            if "." in slide_number:
                video_name, file_ext = slide_number.split('.')
                video_file_name = slide_number
                os.system("cp input/" + video_file_name + " " + temp_video_dir + video_file_name)
            else:
                convert_command = "convert -density 1200 " + slide_filename + "[" + slide_number + "] " + slide_image_dir + "slide_" + slide_number + ".png"
                os.system(convert_command)
                video_file_name = "slide_" + str(slide_number) + ".mp4"
            write_string = "file \'" + video_file_name + "\'\n"
            video_list.write(write_string)
            if "." in slide_number:
                continue
            slide_image = slide_image_dir + "slide_" + str(slide_number) + ".png"
            video_command = "ffmpeg -framerate 1/" + str(duration) + " -i " + slide_image + " -c:v libx264 -profile:v high -crf 12  -vf \"fps=30,format=yuv420p\" -s 1920x1080 " +  str(temp_video_dir + video_file_name)
            os.system(video_command)
    video_list.close()
    video_concat_command = "ffmpeg -f concat -safe 0 -i " + video_list_filename + "  -c copy " + videofile
    os.system(video_concat_command)

if __name__ == '__main__':
    main()
