#!/bin/bash

# Script to convert one or multiple *.MP4 files created by Canon G50 camcorder to srt file
# containing date/time subtitles for each minute of the merged video.

# The merged SRT file can be loaded into Kdenlive video editor, along with all the video clips, 
# for joint editing/exporting.

# Program ffprobe should be on your $PATH . E.g. it comes with kdenlive, and under Windows you can
# add the following to your .bashrc file:

#  export PATH=/cygdrive/c/Program\ Files/kdenlive/bin:$PATH

# The script is also using two standard Linux commands (present in cygwin) date and awk.

# Frame rate:
FPS=29.97

# Number of seconds bewteen each subtitle change
L=60

# The output file name is merged.srt
OUT=merged.srt

if test $# -eq 0
  then
  echo "Syntax:"
  echo
  echo "$0 clip1.mp4 clip2.mp4 ..."
  exit
  fi


\rm $OUT

i=0  # Subtitle counter
t1=0  # Cumulative time in seconds, 0 at the very start

function seconds_to_HMS 
{
  # time in milliseconds:
  local tms=$(echo $1 | awk '{printf "%04d", $1*1000}')
  # the seconds part:
  local tsec=${tms:0:$((${#tms}-3))}
  # the fractional seconds part:
  local tfrac=${tms: -3}
  local sec=$(($tsec % 60))
  local mintot=$(($tsec / 60))
  local min=$(($mintot % 60))
  local hr=$(($mintot / 60))  
  HMS=$(printf "%02d:%02d:%02d,%03d" $(( 10#$hr )) $(( 10#$min )) $(( 10#$sec )) $(( 10#$tfrac )))
}

function write_subtitle
# Three input parameters - t1 and t2 times (in seconds), dt (in minutes)
{
  i=$(($i + 1))  # Subtitle counter
  local tt1=$1
  local tt2=$2
  local dtt=$dt
  if (($i > 1))
	then
	if (($dt == 0))
	  then
	  # Shifting initial SRT time at the start of each clip by 5 milliseconds to avoid overlaps:
   	  tt1=$(echo $tt1 | awk '{printf "%.6f", $1+0.005}')
	  else
	  # Shifting initial SRT time in each subtitle by 1 millisecond:
   	  tt1=$(echo $tt1 | awk '{printf "%.6f", $1+0.001}')
	  fi
	fi
  # Properly formatted date/time string for the srt file, for the initial moment:
  local SUBTITLE=`date -d "$DATE1 $TIME $dtt minutes" +'%a %Y-%m-%d %H:%M'`
  seconds_to_HMS $tt1
  local HMS1=$HMS
  seconds_to_HMS $tt2
  local HMS2=$HMS
  
  echo $i >> $OUT
  echo "$HMS1 --> $HMS2" >> $OUT
  echo "$SUBTITLE" >> $OUT
  echo >> $OUT
}


for file in $*
  do  
  echo "Processing $file"
  dt=0
  # Number of frames in the clip (reading metadata value with ffprobe):
  N_FRAMES=$(ffprobe -loglevel 0  -show_streams -select_streams v:0 $file | grep nb_frames | cut -d= -f2)
  # If the metadata number of frames is missing, you can use this method (much slower):
  #  N_FRAMES=$(ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -of csv=p=0 $file| grep nb_frames | cut -d= -f2)
  # Or you can use MediaInfo CLI program:
  #  N_FRAMES=$(/cygdrive/c/Program\ Files/MediaInfo_CLI/MediaInfo.exe --Output="Video;%FrameCount%" $file)
  # Starting date/time of the clip (in local time; readingh from MP4 metadata):
  DATE=$(date -d $( ffprobe -loglevel 0  -show_streams -select_streams v:0 $file | grep creation_time | cut -d= -f2) +'%Y-%m-%d %H:%M:%S')
  #Starting date (YYY-MM-DD):
  DATE1=`echo $DATE |cut -d" " -f1`
  #Starting time (hrs:min):
  TIME=`echo $DATE |cut -d" " -f2 | cut -d: -f1-2`
  # Starting seconds:
  SEC=`echo $DATE |cut -d: -f5`
  # Time left until the next minute change (seconds):
  LEFT=$(($L - 10#$SEC))
  # Time in seconds for the end of the current clip (counting from the beginning of the first clip):
  t_end=$(echo $t1 $N_FRAMES | awk -v FPS=$FPS '{printf "%.6f", $1+$2/FPS}')
  t2=$(echo $t1 $LEFT | awk '{printf "%.6f", $1+$2}')
  LEFT=$L
  # The loop to generate a subtitle every minute inside the current clip:
  while (($(echo $t2 $t_end | awk '{if ($1<$2) print 1; else print 0}') == 1))
	do
	write_subtitle $t1 $t2 $dt
	t1=$t2
    t2=$(echo $t1 $LEFT | awk '{printf "%.6f", $1+$2}')
	dt=$(($dt + 1)) # Every time we update t1, we are plus 1 minute for the subtitle
	done
  
  t2=$t_end # we reached the end of the clip
  # Writing the final subtitle for the current clip:
  write_subtitle $t1 $t2 $dt
  
  t1=$t2 # end of the last clip time becomes start of the next clip time
  done
  