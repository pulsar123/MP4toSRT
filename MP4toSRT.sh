#!/bin/bash

# Script to convert one or multiple *.MP4 files to srt file
# containing date/time subtitles for each minute of the merged video.

# The script was initially designed to work with Canon G50 camcorder clips but now should work
# with any combination of mp4 video files - as long as the files have a "duration" MP4 tag.
# The clips can have different frame rates, codecs etc.

# The merged SRT file can be imported into Kdenlive video editor, along with all the video clips, 
# for joint editing/exporting.

# Live demo of the script + Kdenlive: https://youtu.be/pnSd9zTQcPE

# Program ffprobe should be on your $PATH . E.g. it comes with kdenlive, and under Windows (cygwin) you can
# add the following to your .bashrc file:
#  export PATH=/cygdrive/c/Program\ Files/kdenlive/bin:$PATH

# Under Windows Subsystem for Linux, it will look like:
#  export PATH=/mnt/c/Program\ Files/kdenlive/bin:$PATH

# The script is also using two standard Linux commands (present in cygwin and WSL): date and awk.

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

# Checking if ffprobe is on the $PATH (both Windows and Linux spelling):
if which ffprobe.exe &>/dev/null
  then
  FFPROBE=ffprobe.exe
  elif which ffprobe &>/dev/null
  then
  FFPROBE=ffprobe
  else
  echo "** ffprobe command is not on your PATH; exiting..."
  exit 1
  fi

\rm $OUT  &>/dev/null

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
  if ! $FFPROBE $file &>/dev/null
    then
    echo "** File $file does not seem to be a video file; exiting..."
    exit 1
    fi
  dt=0
  # Duration of the clip in seconds (reading metadata value with ffprobe):
  DURATION=$($FFPROBE  -loglevel 0  -show_streams -select_streams v:0 $file | grep duration= | cut -d= -f2)
  if test -z "$DURATION"
     then
	 echo "** File $file does not provide the clip duration; exiting"
	 exit 1
	 fi
  # Starting date/time of the clip (in local time; reading from MP4 metadata):
  DATE=$(date -d $( $FFPROBE -loglevel 0  -show_streams -select_streams v:0 $file | grep creation_time | cut -d= -f2) +'%Y-%m-%d %H:%M:%S')
  if test $? -ne 0
     then
	 echo "** File $file does not provide the creation_date tag; exiting"
	 exit 1
	 fi
  #Starting date (YYY-MM-DD):
  DATE1=`echo $DATE |cut -d" " -f1`
  #Starting time (hrs:min):
  TIME=`echo $DATE |cut -d" " -f2 | cut -d: -f1-2`
  # Starting seconds:
  SEC=`echo $DATE |cut -d: -f5`
  # Time left until the next minute change (seconds):
  LEFT=$(($L - 10#$SEC))
  # Time in seconds for the end of the current clip (counting from the beginning of the first clip):
  t_end=$(echo $t1 $DURATION | awk '{printf "%.6f", $1+$2}')  
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
  
