#!/bin/bash
#echo "#!/bin/bash" > tmpscript.sh
#chmod +x tmpscript.sh
#cat prl.113.032502.txt | sed 's/>/>\n/g' | grep captcha | sed 's/.*src="//' | sed 's/".*//' | grep captcha | sed 's$/captcha$wget\ http://journals.aps.org/captcha$' | xargs wget 
#cat prl.113.032502.txt | sed 's/>/>\n/g' | grep captcha | sed 's/.*src="//' | sed 's/".*//' | grep captcha | sed 's$/captcha$http://journals.aps.org/captcha$' | xargs wget


APSIMGNUM=0
APSIMGSUM="/tmp/.getpaper_aps_imgs.jpg"
APSIMGCHOOSE="/tmp/.getpaper_aps_choose.jpg"
cat /tmp/.getpaper_aps_dump.html | sed 's/>/>\n/g' | grep captcha | sed 's/.*src="//' | sed 's/".*//' | grep captcha | sed 's$/captcha$http://journals.aps.org/captcha$' | while read line; do let "APSIMGNUM += 1"; wget -O "$APSIMGNUM".jpg "$line"; done
convert 1.jpg 2.jpg 3.jpg 4.jpg 5.jpg 6.jpg 7.jpg 8.jpg +append "$APSIMGSUM"
convert "$APSIMGSUM" ~/.getpaper_aps_nums.jpg -append "$APSIMGCHOOSE"
feh "$APSIMGCHOOSE"
EINSTEIN=$(zenity --entry --title="getpaper APS hack" --text="Which number was Einstein?")

let EINSTEIN=EINSTEIN-1 
if [[ $EINSTEIN -ne 0 ]];then
  COUNTER=0
  while [  $COUNTER -lt $EINSTEIN ]; do
      let COUNTER=COUNTER+1 
      sed -i '0,/#key/s//key/' /tmp/.getpaper_lynxcmd
  done
fi




#sed -i '0,/COMMENTS/s//goats/' /tmp/.getpaper_lynxcmd



#cat prl.txt| sed 's/>/>\n/g' | grep captcha | sed 's/.*src="//' | sed 's/".*//' | grep captcha | sed 's$/captcha$wget\ http://journals.aps.org/captcha$' >> tmpscript.sh

