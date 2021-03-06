#!/bin/bash

STREAM=$1
MAP=$2
VRATE=$3
ARATE=$4
XY=$5
HTTP_PATH=$6

SEGDUR=10		# Length of Segments produced (between 10 and 30)
SEGWIN=$7		# Amount of Segments to produce 
FFPATH=$8
SEGMENTERPATH=${9}
SESSION=${10}
FFMPEGLOG="ffmpeg.log"
FILES=${11}
ABIT=48000

if [ $# -eq 0 ]
then
echo "Format is : ./istream.sh source video_rate audio_rate audio_channels 480x320 httppath segments_number ffmpeg_path segmenter_path rec_files"
exit 1
fi

# Log
if [ -z "$FFMPEGLOG" ]
then
	FFMPEGLOG="/dev/null"
fi

#############################################################
# start dumping the TS via Streamdev into a pipe for ffmpeg
# and store baseline 3.0 mpegts to outputfile  
# sending it to the segmenter via a PIPE
##############################################################

# Check that the session dir exists
if [ ! -e $SESSION ]
then
	echo $SESSION not found!
	exit;
fi

cd $SESSION

# Create a fifo
2>/dev/null mkfifo ./fifo

if [ ! -z "$FILES" ]
then
	FFMPEGPREFIX="cat $FILES"
else
	FFMPEGPREFIX="cat /dev/null"
fi

# Start ffmpeg
(trap "rm -f ./ffmpeg.pid; rm -f ./fifo" EXIT HUP INT TERM ABRT; \
 $FFMPEGPREFIX | $FFPATH -i "$STREAM" -deinterlace $MAP -f mpegts -acodec libmp3lame -ab $ARATE -ar $ABIT -ac 2 -s $XY -vcodec libx264 -b $VRATE -flags +loop \
 -cmp \+chroma -partitions +parti4x4+partp8x8+partb8x8 -subq 5 -trellis 1 -refs 1 -coder 0 -me_range 16  -keyint_min 25 \
 -sc_threshold 40 -i_qfactor 0.71 -bt $VRATE -maxrate $VRATE -bufsize $VRATE -rc_eq 'blurCplx^(1-qComp)' -qcomp 0.6 \
 -qmin 10 -qmax 51 -qdiff 4 -level 30  -g 30 -async 1 -threads 4 - 2>$FFMPEGLOG >./fifo) &
 # -async 2 # async disabled since ffmpeg done error with it

# Store ffmpeg pid
PID=$!
if [ ! -z "$PID" ]
then
	2>/dev/null echo `\ps ax --format pid,ppid | grep "$PID$" | awk {'print $1'}` > ./ffmpeg.pid
fi

# Now start segmenter
(trap "rm -f ./segmenter.pid" EXIT HUP INT TERM ABRT; 2>/dev/null $SEGMENTERPATH ./fifo $SEGDUR stream stream.m3u8 $HTTP_PATH/ $SEGWIN) &

# Store segmenter pid
PID=$!
if [ ! -z "$PID" ]
then
	2>/dev/null echo `\ps ax --format pid,ppid | grep "$PID$" | awk {'print $1'}` > ./segmenter.pid
fi


