Live demo of the script + Kdenlive: https://youtu.be/pnSd9zTQcPE

I created this bash script to add date/time subtitles to my home videos created with Canon G50 camcorder (MP4 format). The newest version also allows a mixture of MP4 files produced by different camcorders, cell phones etc. The clips can have different frames per second, pixel sizes and codecs. The only requirement is that the "ffprobe" command should be able to recover the "duration" MP4 tag in every clip.

The bash script can be used under Linux, and under Windows (using either Cygwin, or Windows Subsystem for Linux environment). It requires the program ffprobe (part of FFMPEG package; e.g. comes with open source video editor Kdenlive) to be on your $PATH. Ffprobe is used to get two important parameters for each video clip - stream creation date/time (which is not the same as the file creation time), and the clip duration. The script also uses standard utilities "date" and "awk" (included with cygwin).

This is how I use the script.

 - Using bash shell, go inside the directory containing the MP4 clips, and execute this command (make sure the script MP4toSRT.sh is on your $PATH):

$ MP4toSRT.sh *.MP4 

If you have a mixture of clips produced by different cameras, you can enforce any ordering of the clips by saving the names of the clips in a file (one name per line) in the desired order, and then running my script as follows:

$ MP4toSRT.sh \`cat list.txt\`

It is pretty fast (one minute to process 100 4K clips under WSL). This will produce a single SRT file for the whole sequence of the clips - merged.srt .

 - Open the video editor Kdenlive (available for Windows and Linux), switch to the target profile (e.g. 4k/29.97 fps)
 
 - Load all the MP4 clips, wait until all get processed, copy them to the timeline (using the same ordering as when creating the srt file)
 
 - Load the merged.srt file (Project > Subtitles > Import Subtitle File ). This will create  a separate subtitles stream
 
 - Edit the video (with video/audio and subtitle streams edited - cut/moved/deleted etc - together)
 
 - Export the subtitle file (Project > Subtitles > Export Subtitle File )
 
 - IMPORTANT: hide the subtitle stream (click on the eye symbol) - otherwise it'll get burnt into the video!
 
 - Encode the video (I use x265 CPU-based encoder with CRF=16, medium speed; results in ~90 Mbit/s for my 4K videos)
 
 As long as the final video and the srt file have the same root name and are located in the same directory, most media players would let you display the subtitles (date/time) while watching the video.
 
If you prefer GUI-based tools, you can instead consider TimeDateSRTCreator  (https://www.videohelp.com/software/TimeDateSRTCreator ). I tried it first, but it had some limitations, hence me writing this script. Here are the issues with TimeDateSRTCreator:

 - It is less accurate (probably has some round-off error accumulation). For a 50 minutes video consisting of 100 clips, the lag between subtitles and video reached 1.5s at the end of the video, which is quite noticeable. My script had an error of one video frame (0.03s) at the end - not noticeable.
 
 - It doesn't memorize your settings, so every time you use it you have to do quite a bit of clicking, pasting and copying. My script is better if you have a fixed workflow.
 
 - It doesn't produce minute-long subtitles (only second-long), or perhaps I just couldn't figure it out, so one still has to do some script processing to get what I needed (date/time subtitle for every minute change).
 