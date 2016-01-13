#!/bin/bash
#echo "#!/bin/bash" > tmpscript.sh
#chmod +x tmpscript.sh
#cat prl.113.032502.txt | sed 's/>/>\n/g' | grep captcha | sed 's/.*src="//' | sed 's/".*//' | grep captcha | sed 's$/captcha$wget\ http://journals.aps.org/captcha$' | xargs wget 
#cat prl.113.032502.txt | sed 's/>/>\n/g' | grep captcha | sed 's/.*src="//' | sed 's/".*//' | grep captcha | sed 's$/captcha$http://journals.aps.org/captcha$' | xargs wget

CONFIG_FILE=$HOME/.getpaperrc
# Check for configuration file
if [ ! -e $CONFIG_FILE ];then
	zenity --info --text "getpaper config file missing!" --title="getpaper APS hack" 
	exit
fi
source $CONFIG_FILE

function TmpCleanUp () {
	# todo: make removing the images a loop for fuck's sake
        if [ -e $TMP/getpaper1.jpg ];then
                rm "$TMP"/getpaper1.jpg
        fi
        if [ -e $TMP/getpaper2.jpg ];then
                rm "$TMP"/getpaper2.jpg
        fi
        if [ -e $TMP/getpaper3.jpg ];then
                rm "$TMP"/getpaper3.jpg
        fi
        if [ -e $TMP/getpaper4.jpg ];then
                rm "$TMP"/getpaper4.jpg
        fi
        if [ -e $TMP/getpaper5.jpg ];then
                rm "$TMP"/getpaper5.jpg
        fi
        if [ -e $TMP/getpaper6.jpg ];then
                rm "$TMP"/getpaper6.jpg
        fi
        if [ -e $TMP/getpaper7.jpg ];then
                rm "$TMP"/getpaper7.jpg
        fi
        if [ -e $TMP/getpaper7.jpg ];then
                rm "$TMP"/getpaper7.jpg
        fi
        if [ -e $TMP/getpaper8.jpg ];then
                rm "$TMP"/getpaper8.jpg
        fi
        if [ -e "$APSIMGCHOOSE" ];then
                rm "$APSIMGCHOOSE"
        fi
        if [ -e "$APSIMGSUM" ];then
                rm "$APSIMGSUM"
        fi
}


#ls $(ls -dat /tmp/*/ | grep lynx | head -n 1)

LYNXTMPDIR=$(ls -dat /tmp/*/ | grep lynx | head -n 1)
LYNXTMPFILE=$(grep -l "Verification Required" $LYNXTMPDIR*)
#LYNXTMPFILE=$LYNXTMPDIR/$(ls -r "$LYNXTMPDIR" | head -n 1)

APSIMGNUM=0
# todo: put $TMP variable instead of /tmp
APSIMGSUM="/tmp/.getpaper_aps_imgs.jpg"
APSIMGCHOOSE="/tmp/.getpaper_aps_choose.jpg"
TmpCleanUp
cat "$LYNXTMPFILE" | sed 's/>/>\n/g' | grep captcha | sed 's/.*src="//' | sed 's/".*//' | grep captcha | sed 's$/captcha$http://journals.aps.org/captcha$' | while read line; do let "APSIMGNUM += 1"; wget -O $TMP/getpaper"$APSIMGNUM".jpg "$line"; done
convert $TMP/getpaper1.jpg $TMP/getpaper2.jpg $TMP/getpaper3.jpg $TMP/getpaper4.jpg $TMP/getpaper5.jpg $TMP/getpaper6.jpg $TMP/getpaper7.jpg $TMP/getpaper8.jpg +append "$APSIMGSUM"
convert "$APSIMGSUM" $HOME/.getpaper_aps_nums.jpg -append "$APSIMGCHOOSE"
feh "$APSIMGCHOOSE"
EINSTEIN=$(zenity --entry --title="getpaper APS hack" --text="Which number was Einstein?")

          # search for Einstein
          echo "key /" >> "$LYNXCMD"
          echo "key E" >> "$LYNXCMD"
          echo "key i" >> "$LYNXCMD"
          echo "key n" >> "$LYNXCMD"
          echo "key s" >> "$LYNXCMD"
          echo "key t" >> "$LYNXCMD"
          echo "key e" >> "$LYNXCMD"
          echo "key i" >> "$LYNXCMD"
          echo "key n" >> "$LYNXCMD"
          # send return command to lynx (will perform the search)
          echo "key ^J" >> "$LYNXCMD"

# todo: make if for user daid
cp $TMP/getpaper"$EINSTEIN".jpg $HOME/getpaper/"$RANDOM"einstein.jpg

let EINSTEIN=EINSTEIN-1 
if [[ $EINSTEIN -ne 0 ]];then
  COUNTER=0
  while [  $COUNTER -lt $EINSTEIN ]; do
      let COUNTER=COUNTER+1 
      echo "key Down Arrow" >> "$LYNXCMD"
      #sed -i '0,/#key/s//key/' "$LYNXCMD"
  done
fi

FILENAME=$(cat $TMPFILENAME)

          # fill in a lot of commented arrow keys
          # the user selection in the hack script will tell us how many to uncomment
      #    echo "#key Down Arrow" >> "$LYNXCMD"
      #    echo "#key Down Arrow" >> "$LYNXCMD"
      #    echo "#key Down Arrow" >> "$LYNXCMD"
      #    echo "#key Down Arrow" >> "$LYNXCMD"
      #    echo "#key Down Arrow" >> "$LYNXCMD"
      #    echo "#key Down Arrow" >> "$LYNXCMD"
      #    echo "#key Down Arrow" >> "$LYNXCMD"
#         echo "key Q" >> "$LYNXCMD"
          #echo "key ^Z" >> "$LYNXCMD"
        # tell lynx to download the link
        echo "key d" >> "$LYNXCMD"
        # this enters lynx search mode
        echo "key /" >> "$LYNXCMD"
        # search for 'Save' (some older lynx required that...)
        echo "key S" >> "$LYNXCMD"
        echo "key a" >> "$LYNXCMD"
        echo "key v" >> "$LYNXCMD"
        echo "key e" >> "$LYNXCMD"
        echo "key ^J" >> "$LYNXCMD"
        # send return command to lynx (will 'Save to disk')
        echo "key ^J" >> "$LYNXCMD"
        # erase the line of default contents (suggested filename)
        echo "key ^U" >> "$LYNXCMD"
        # now we make a new file name out of our file name
        #make a line for each character in the download destination path, for single key entry
        echo "$TMP/$FILENAME" | awk 'BEGIN{FS=""}{for(i=1;i<=NF;i++)print "key "$i}' >> "$LYNXCMD"
        # send return command to lynx (pass Save To location from above and download)
        echo "key ^J" >> "$LYNXCMD"
        # send quit command to lynx
        echo "key q" >> "$LYNXCMD"
        # confirm quit
        echo "key y" >> "$LYNXCMD"



#sed -i '0,/COMMENTS/s//goats/' /tmp/.getpaper_lynxcmd



#cat prl.txt| sed 's/>/>\n/g' | grep captcha | sed 's/.*src="//' | sed 's/".*//' | grep captcha | sed 's$/captcha$wget\ http://journals.aps.org/captcha$' >> tmpscript.sh

TmpCleanUp
