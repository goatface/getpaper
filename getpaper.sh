#!/bin/bash
# getpaper v 0.86
# Copyright 2010, 2011 daid kahl
#
# (http://www.goatface.org/hack/getpaper.html)
#
# getpaper is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# getpaper is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with getpaper.  If not, see <http://www.gnu.org/licenses/>.
InitVariables () {
	# USER DEFINED VARIABLES
	PDFVIEWER=/usr/bin/xpdf # popular alternatives: /usr/bin/acroread /usr/bin/evince /usr/bin/okular
	#PDFVIEWER=/usr/bin/open # Mac OS
	PRINTCOMMAND="/usr/bin/lpr -P CNS205 -o Duplex=DuplexNoTumble" # you can attempt to simply replace CNS205 with your printer name
	LIBPATH=/home/`whoami`/library
	#LIBPATH=/Users/`whoami`/Documents/library # Mac OS
	BIBFILE=$LIBPATH/library.bib
	TMP=/tmp
	# INTERNAL TEMPORARY FILES -- MAY CHANGE BUT NOT NECESSARY
	TMPBIBCODE=$TMP/.getpaper_bibcode
	TMPBIBTEX=$TMP/.getpaper_bibtex
	TMPBIBCODELIST=$TMP/.getpaper_bibcodelist
	TMPURL=$TMP/.getpaper_url
	ERRORFILE=$TMP/.getpaper_error
	# temporary storage for input information...whereever you want
	INPUT=$TMP/refinput.txt

	# internal variables -- do not change!
	ERROR=0
}

Usage () {
	printf "getpaper version 0.86\nDownload, bibtex, print, and/or open papers based on reference!\n"
	printf "Copyright 2010 daid - www.goatface.org\n"
	printf "Usage: %s: [-f file] [-j journal] [-v volume] [-p page] [-P] [-O]\n" $0
	printf "Description of options:\n"
	printf "  -f <file>\t: getpaper reads data from <file> where each line corresponds to an article as:\n"
	printf "\t\t\tPrinciple:\n\t\t\t\tJOURANL\tVOLUME\tPAGE\tCOMMENTS\n"
	printf "\t\t\tExample:\n\t\t\t\tprl\t99\t052502\t12C+alpha 16N RIB\n"
	printf "\t\t\t(Comments are used in the bibtex for the user's need.)\n"
	printf "  -j <string>\t: <string> is the journal title abbreviation\n"
	printf "  -j help\t: Output a list of available journals and abbreviations.\n"
	printf "  -v <int>\t: <int> is the journal volume number\n"
	printf "  -p <int>\t: <int> is the article first page\n"
	printf "  -P \t\t: Turn on printing\n"
	printf "  -O \t\t: Open the paper(s) for digital viewing\n"
	printf "(Note: -f option supersedes the -j -v -p options.)\n"
	printf "\nIf zenity is installed, getpaper will enter GUI mode if no options are passed\n"
	exit 1
}

CheckDeps () { # dependency checking
	type -P lynx &>/dev/null || { printf "getpaper requires lynx but it's not in your PATH or not installed.\n\t(see http://lynx.isc.org/)\nAborting.\n" >&2; exit 1; }
	type -P wget &>/dev/null || { printf "getpaper requires wget but it's not in your PATH or not installed.\n\t(see http://www.gnu.org/software/wget/)\nAborting.\n" >&2; exit 1; }
	type -P pdfinfo &>/dev/null || { printf "getpaper requires pdfinfo but it's not in your PATH or not installed.\n\t(see http://poppler.freedesktop.org/)\nAborting.\n" >&2; exit 1; }
	type -P grep &>/dev/null || { printf "getpaper requires grep but it's not in your PATH or not installed.\n\t(see http://www.gnu.org/software/grep/)\nAborting.\n" >&2; exit 1; }
	type -P sed &>/dev/null || { printf "getpaper requires sed but it's not in your PATH or not installed.\n\t(see http://www.gnu.org/software/sed/)\nAborting.\n" >&2; exit 1; }
	type -P awk &>/dev/null || { printf "getpaper requires awk but it's not in your PATH or not installed.\n\t(see http://www.gnu.org/software/gawk/)\nAborting.\n" >&2; exit 1; }

}

Error () { # keep track of any failures
	ERROR=1
	printf "$JOURNAL\t$VOLUME\t$PAGE\n" >> $ERRORFILE
}

JournalList() {
	printf "Journals in database:\nCODE\tNAME\n"
	printf "aa\tAstronomy & Astrophysics\n"
	printf "aipc\tAmerican Institute of Physics (Conference Proceedings)\n"
	printf "aj\tThe Astronomical Journal\n"
	printf "anap\tAnnales d'Astrophysique\n" # none of these are online vi ADS
	printf "apj\tThe Astrophysical Journal\n"
	printf "apjl\tThe Astrophysical Journal (Letters)\n"
	printf "apjs\tThe Astrophysical Journal (Supplement Series)\n"
	printf "aujph\tAustralian Journal of Physics\n"
	printf "bsrsl\tBulletin de la Societe Royale des Sciences de Liege\n"
	printf "epjh\tEuropean Physical Journal H\n"
	printf "mnras\tMonthly Notices of the Royal Astronomical Society\n"
	printf "msrsl\tMemoires of the Societe Royale des Sciences de Liege\n"
	printf "natph\tNature Physics\n"
	printf "nucim\tNuclear Instruments and Methods (1983 and earlier)\n"
	printf "nimpa\tNuclear Instruments and Methods in Physics Research A\n"
	printf "nimpb\tNuclear Instruments and Methods in Physics Research B\n"
	printf "nupha\tNuclear Physics A\n"
	printf "nuphb\tNuclear Physics B\n"
	printf "obs\tThe Observatory\n"
	printf "paphs\tProceedings of the American Philosophical Society\n" # none online via ADS
	printf "pce\tPhysics and Chemsitry of the Earth\n"
	printf "phrv\tPhysical Review\n"
	printf "pmag\tPhilosophical Magazine\n"
	printf "ppsa\tProceedings of the Physical Society A\n"
	printf "ppsb\tProceedings of the Physical Society B\n"
	printf "pra\tPhysical Review A\n"
	printf "prb\tPhysical Review B\n"
	printf "prc\tPhysical Review C\n"
	printf "prd\tPhysical Review D\n"
	printf "pre\tPhysical Review E\n"
	printf "pasp\tPublications of the Astronomical Society of the Pacific\n"
	printf "prl\tPhysical Review Letters\n"
	printf "pthph\tProgress of Theoretical Physics\n"
	printf "rvmp\tReviews of Modern Physics\n"
	printf "science\tScience\n"
	printf "scoa\tSmithsonian Contributions to Astrophysics\n"
	printf "zphy\tZeitschrift fur Physik\n"
}

SetJournal() {	# JOURNAL DEFINITIONS -- may want to improve this list, but be sure to understand and test the meaning of the variables
	# varibales used:
	# 		JCODE : ADS journal code (case insensitive); see http://adsabs.harvard.edu/abs_doc/journal_abbr.html but be careful with things like "A&A"
	#		LTYPE : ADS system variable; EJOURNAL is externally hosted; ARTICLE is locally hosted
	# 		HREFTYPE : Specifies locality of the href
	#				0 : full paths given for href
	#				1 : domain absent from href
	#				2 : local file name given for href
	case "$JOURNAL" in
	aa  | AA ) HREFTYPE=1; JCODE="a%26a"; LTYPE="ARTICLE" ;;
	aipc | AIPC )  HREFTYPE=1; JCODE="aipc"; LTYPE="EJOURNAL" ;;
	aj |AJ )  HREFTYPE=1; JCODE="aj"; LTYPE="ARTICLE" ;;
	anap |AnAp )  HREFTYPE=1; JCODE="anap"; LTYPE="ARTICLE" ;;
	apj |APJ )  HREFTYPE=1; JCODE="apj"; LTYPE="ARTICLE" ;;
	apjl | APJL )  HREFTYPE=1; JCODE="apjl"; LTYPE="ARTICLE" ;;
	apjs | APJS )  HREFTYPE=1; JCODE="apjs"; LTYPE="ARTICLE" ;;
	aujph | AuJPh )  HREFTYPE=1; JCODE="aujph"; LTYPE="ARTICLE" ;;
	bsrsl | BSRSL  )   HREFTYPE=2; JCODE="bsrsl"; LTYPE="EJOURNAL" ;;
	epjh | EPJH )  HREFTYPE=1; JCODE="epjh"; LTYPE="EJOURNAL" ;;
	mnras | MNRAS ) HREFTYPE=1; JCODE="mnras"; LTYPE="ARTICLE" ;;
	msrsl | MSRSL  )   HREFTYPE=1; JCODE="msrsl"; LTYPE="ARTICLE" ;;
	natph | NatPh )  HREFTYPE=1; JCODE="natph"; LTYPE="EJOURNAL" ;;
	nim | nucim | NIM | NucIM) HREFTYPE=0; JCODE="nucim"; LTYPE="EJOURNAL" ;;
	nimpa | nima | NIMPA | NIMA) HREFTYPE=0; JCODE="nimpa"; LTYPE="EJOURNAL" ;;
	nimpb | nimb | NIMPB | NIMB) HREFTYPE=0; JCODE="nimpb"; LTYPE="EJOURNAL" ;;
	nupha | npa | NPA | nucphysa ) HREFTYPE=0; JCODE="nupha"; LTYPE="EJOURNAL" ;;
	nuphb | npb | NPB | nucphysb ) HREFTYPE=0; JCODE="nuphb"; LTYPE="EJOURNAL" ;;
	obs | OBS )  HREFTYPE=1; JCODE="obs"; LTYPE="ARTICLE" ;;
	paphs | PAPhS | PAPHS )   HREFTYPE=1; JCODE="paphs"; LTYPE="EJOURNAL" ;;
	pasp | PASP )   HREFTYPE=1; JCODE="pasp"; LTYPE="ARTICLE" ;;
	pce | PCE ) HREFTYPE=0; JCODE="pce"; LTYPE="EJOURNAL" ;;
	phrv | pr | PhRv | PHRV )   HREFTYPE=1; JCODE="phrv"; LTYPE="EJOURNAL" ;;
	pmag | PMag | PMAG )   HREFTYPE=1; JCODE="pmag"; LTYPE="EJOURNAL" ;;
	ppsa | PPSA  )   HREFTYPE=1; JCODE="ppsa"; LTYPE="EJOURNAL" ;;
	ppsb | PPSB  )   HREFTYPE=1;JCODE="ppsb";LTYPE="EJOURNAL" ;;
	pra | phrva | PRA )   HREFTYPE=1;JCODE="phrva";LTYPE="EJOURNAL" ;;
	prb | phrvb | PRB )   HREFTYPE=1;JCODE="phrvb";LTYPE="EJOURNAL" ;;
	prc | phrvc | PRC )   HREFTYPE=1;JCODE="phrvc";LTYPE="EJOURNAL" ;;
	prd | phrvd | PRD )   HREFTYPE=1;JCODE="phrvd";LTYPE="EJOURNAL" ;;
	pre | phrve | PRE )   HREFTYPE=1;JCODE="phrve";LTYPE="EJOURNAL" ;;
	prl | phrvl | PRL )   HREFTYPE=1;JCODE="phrvl";LTYPE="EJOURNAL" ;;
	pthph | PThPh | PTHPH )   HREFTYPE=1;JCODE="pthph";LTYPE="EJOURNAL" ;;
	rvmp | RvMP | RVMP ) HREFTYPE=1;JCODE="rvmp";LTYPE="EJOURNAL" ;;
	science | SCIENCE ) HREFTYPE=1;JCODE="science";LTYPE="ARTICLE" ;;
	scoa | SCoA| SCOA )  HREFTYPE=1;JCODE="scoa";LTYPE="ARTICLE" ;;
	zphy | ZPhy| ZPHY )  HREFTYPE=1;JCODE="zphy";LTYPE="EJOURNAL" ;;
	* ) 
	        printf "ERROR: Journal code $JOURNAL not in database, skipping...\n"
		Error
		JournalList
		continue
		;;
	esac
}


TmpCleanUp () {
	#tmp cleanup
	if [ -e $INPUT ];then
		rm "$INPUT"
	fi
	if [ -e $TMPBIBCODE ];then
		rm "$TMPBIBCODE"
	fi
	if [ -e $TMPBIBCODELIST ];then
		rm "$TMPBIBCODELIST"
	fi
	if [ -e $TMPBIBTEX ];then
		rm "$TMPBIBTEX"
	fi
	if [ -e $TMPURL ];then
		rm "$TMPURL"
	fi
	if [ -e $ERRORFILE ];then
		rm "$ERRORFILE"
	fi
}

ParseJVP () { # Parse the Journal/Volume/Page of submission
	JOURNAL=`printf "$inline"|awk '{printf $1}'`
	VOLUME=`printf "$inline"|awk '{printf $2}'`
	PAGE=`printf "$inline"|awk '{printf $3}'`
	if [ "$fflag" ];then
		COMMENTS=`printf "$inline" | awk '{
		                    for (i=1;i<=NF;i++)
		                       {
		                       if ( i > 3 )
		                          printf("%s ",$i)
		                       }
		                    }'`
	#else # broken for now!  It uses inline instead of user input...how to fix it?
		#printf "Input comment for BibTex:"
		#readline COMMENTS
	fi
	if [ "$Pflag" ]; then
		COMMENTS="Printed: $COMMENTS"
	else
		COMMENTS="Unprinted: $COMMENTS"
	fi
	printf "Processing: JOURNAL $JOURNAL VOLUME $VOLUME PAGE $PAGE\n"
}

FetchBibtex() { # USING ADS TO GET THE BIBTEX
	if [ ! -d $LIBPATH ]; then
		printf "$LIBPATH does not exist!\nCreating your library directory.\n"
		mkdir $LIBPATH
	fi
	if [ ! -e $BIBFILE ]; then
		printf "$BIBFILE does not exist!\nCreating blank .bib file.\n"
		touch "$BIBFILE"
	fi
	ADSURL="http://adsabs.harvard.edu/cgi-bin/nph-abs_connect?version=1&warnings=YES&partial_bibcd=YES&sort=BIBCODE&db_key=ALL&bibstem=$JCODE&volume=$VOLUME&page=$PAGE&nr_to_return=1&start_nr=1"
	lynx -source "$ADSURL" > $TMPBIBCODE
	if ( grep -q "Total number selected" $TMPBIBCODE ); then
		#format looks like:
		#Total number selected: <strong>2</strong>
		SELECTED=`grep "Total number selected" $TMPBIBCODE | sed 's/.*selected://' | sed 's/\ <strong>//' | sed 's$</strong>.*$$'`
		echo "Found $SELECTED entries that match query..."
	else
		SELECTED=1
	fi
	i="1"
	while [ $i -le $SELECTED  ]
	do
		ADSURL="http://adsabs.harvard.edu/cgi-bin/nph-abs_connect?version=1&warnings=YES&partial_bibcd=YES&sort=BIBCODE&db_key=ALL&bibstem=$JCODE&volume=$VOLUME&page=$PAGE&nr_to_return=1&start_nr=$i"
		lynx -source "$ADSURL" > $TMPBIBCODE
		BIBCODE=`grep bibcode= $TMPBIBCODE | head -n 1 | sed 's/.*bibcode=//'|sed 's/&.*//'`
		if [ -z $BIBCODE ];then
			printf "No BIBCODE could be found!\n"
			break
		else
			printf "BIBCODE is $BIBCODE\n"
		fi
		ADSBIBTEX="http://adsabs.harvard.edu/cgi-bin/nph-bib_query?bibcode=$BIBCODE&data_type=BIBTEXPLUS&db_key=ALL&nocookieset=1"
		printf "Fetching bibtex file from ADS ($ADSBIBTEX)\n"
		lynx -source "$ADSBIBTEX" | awk 'NR>5' >$TMPBIBTEX
		TITLE=$(grep "title = " $TMPBIBTEX | sed 's/\ \ \ \ title\ =\ \"{/\"/' | sed 's/}\",/\"/')
		echo "$BIBCODE $TITLE" >> $TMPBIBCODELIST
		i=$[$i+1]
	done
	if [ $SELECTED -gt 1 ];then
		if [ $GUI -eq 1 ];then
		# this zenity call looks strange because we need it to properly interpret the different single values
			ZENCMD='zenity  --title "getpaper" --list  --text "Multiple hits.  Choose the paper you want:" --radiolist  --column "" --column "Key" --column "Paper Title"'
			ZENARG=""
			while read line
			do
				p1=`echo $line | awk '{print $1 }'`
				p2=`echo $line | awk '{$1="";print}' | sed 's/\ //'`
				ZENARG="$ZENARG FALSE $p1 $p2"
			done < $TMPBIBCODELIST
			ZENCMD="$ZENCMD $ZENARG"
			BIBCODE=`echo $ZENCMD | bash`
		else
			echo "Multiple hits.  Choose the paper you want:"
			i=1
			while read line
			do
				echo "$i) $line"
				i=$[$i+1]
			done < $TMPBIBCODELIST
			echo "Select paper number to download:"
			read CHOICE <&3 # reading from the stdin redirect defined
			BIBCODE=`cat $TMPBIBCODELIST | awk 'NR==v1' v1=$CHOICE | awk '{printf $1}'`
		fi
		ADSBIBTEX="http://adsabs.harvard.edu/cgi-bin/nph-bib_query?bibcode=$BIBCODE&data_type=BIBTEXPLUS&db_key=ALL&nocookieset=1"
		printf "Fetching bibtex file from ADS ($ADSBIBTEX)\n"
		lynx -source "$ADSBIBTEX" | awk 'NR>5' >$TMPBIBTEX
	fi
	rm $TMPBIBCODELIST
	echo "Processing $BIBCODE..."

	if [ -z $BIBCODE ];then
		printf "No BIBCODE could be found!\n"
		Error
		continue
	fi
	YEAR=`echo "$BIBCODE" | head -c 4`
	if ( grep "$BIBCODE" "$BIBFILE" > /dev/null ); then
		echo "The article $BIBCODE is already in your library!"
		echo "$BIBFILE"
		echo "Skipping..."
		continue
	fi
	
	# may add more papertypes here
	if ( grep ARTICLE $TMPBIBTEX > /dev/null );then
		PAPERTYPE="articles"
	fi
	if ( grep INPROCEEDINGS $TMPBIBTEX > /dev/null  );then
		PAPERTYPE="proceedings"
	fi
	
	if [ -z $PAPERTYPE ];then
		printf "No Papertype found.  Please determine it and modify the script!\n"
		Error
		continue
	fi
}

DownloadPdf () {
	FILEPATH="$LIBPATH/$PAPERTYPE/$YEAR"
	FILENAME="$JOURNAL.$VOLUME.$PAGE.pdf"
	if [ -e $FILEPATH/$FILENAME ];then
		echo "The paper is already downloaded!"
		echo "$FILEPATH/$FILENAME"
		echo "Skipping..."
		continue
	fi
	
	ADSLINK="http://adsabs.harvard.edu/cgi-bin/nph-data_query?bibcode=$BIBCODE&link_type=$LTYPE&db_key=ALL"
	printf "Determining URL path for PDF...\n"
	if [ $LTYPE = "ARTICLE" ]; then
		FULLPATH=$ADSLINK
	elif [ $LTYPE = "EJOURNAL" ]; then
		if [ -e $TMPURL ];then
			rm "$TMPURL"
		fi
		lynx -base -source -connect_timeout=20 "$ADSLINK" > $TMPURL 
		#read_timeout is a newer feature many systems don't seem to have...added to lynx 2.8.7 2009.7.5
		#lynx -base -source -read_timeout=20 "$ADSLINK" >$TMPURL 
		if [ $HREFTYPE -eq 0 ];then
			#full paths given for href
			# at present just for ScienceDirect (from the grep origin=search part)
			BASEURL=""
			#2g in BSD sed gives: sed: more than one number or 'g' in substitute flags
			#LOCALPDF=`grep PDF $TMPURL | sed 's/[Hh][Rr][Ee][Ff]//2g' | sed  's/.*[Hh][Rr][Ee][Ff]=\"//' | sed 's/\".*//' | head -n 1`
			#emulate 2g as sed, where goat is regex: sed ':a;s/\([^ ]*goat.*[^\\]\)goat\(.*\)/\1replace\2/;ta'
			LOCALPDF=`grep PDF $TMPURL | sed ':a;s/\([^ ]*[Hh][Rr][Ee][Ff].*[^\\]\)[Hh][Rr][Ee][Ff]\(.*\)/\1\2/;ta' | sed  's/.*[Hh][Rr][Ee][Ff]=\"//' | sed 's/\".*//' | grep "origin=search" | head -n 1`
		fi
		if [ $HREFTYPE -eq 1 ];then
			#domain omitted for href
			BASEURL=`head -n 1 $TMPURL | sed 's/.*X-URL:\ //'|  sed 's,\(http://[^/]*\)/.*,\1,'`
			LOCALPDF=`grep PDF $TMPURL | \
				sed ':a;s/\([^ ]*[Hh][Rr][Ee][Ff].*[^\\]\)[Hh][Rr][Ee][Ff]\(.*\)/\1\2/;ta' | \
				sed  's/.*[Hh][Rr][Ee][Ff]=\"//' | sed 's/\".*//' | head -n 1`
		fi
		if [ $HREFTYPE -eq 2 ];then
			#totally local href
			BASEURL=`head -n 1 $TMPURL | sed 's/.*X-URL:\ //'|  sed 's/\(.*\)\/.*/\1\//'`
			LOCALPDF=`grep PDF $TMPURL | \
				sed ':a;s/\([^ ]*[Hh][Rr][Ee][Ff].*[^\\]\)[Hh][Rr][Ee][Ff]\(.*\)/\1\2/;ta' | \
				sed  's/.*[Hh][Rr][Ee][Ff]=\"//' | sed 's/\".*//' | head -n 1`
		fi
		#cat $TMPURL |grep PDF | sed ':a;s/\([^ ]*[Hh][Rr][Ee][Ff].*[^\\]\)[Hh][Rr][Ee][Ff]\(.*\)/\1\2/;ta' | sed  's/.*[Hh][Rr][Ee][Ff]=\"//' | sed 's/\".*//    ' | grep "origin=search" |head -n 1 ;exit # debug new journal
		FULLPATH="$BASEURL$LOCALPDF"
	fi
	printf "Downloading PDF from $FULLPATH...\n"
	# we need to mask as Firefox or wget is denied access by error 403 sometimes
	if [ $GUI -eq 1 ];then
		wget -U 'Mozilla/5.0' --progress=bar:force "$FULLPATH" -O"$TMP/$FILENAME" 2>&1 | (zenity --title "getpaper" --text "Downloading..." --progress --auto-close --auto-kill)
	else
		wget -U 'Mozilla/5.0' "$FULLPATH" -O"$TMP/$FILENAME"
	fi
}

AddBibtex () {
	while read -r line
	do
		if ( echo $line | grep "adsurl = " > /dev/null );then
			echo "$line" >> "$BIBFILE"
			echo "file = {:$LIBPATH/$PAPERTYPE/$YEAR/$FILENAME:PDF}," >> "$BIBFILE"
		        echo "comment = {$COMMENTS}," >> "$BIBFILE"				    
			#printf "$line\n" >> "$BIBFILE"
			#printf "file = {:$LIBPATH/$PAPERTYPE/$YEAR/$FILENAME:PDF},\n" >> "$BIBFILE"
		        #printf "comment = {$COMMENTS},\n" >> "$BIBFILE"				    
		else
			#printf "$line\n" >> "$BIBFILE" # maybe gives errors if % is parsed
			echo "$line" >> "$BIBFILE"
		fi
	done < $TMPBIBTEX
}

CheckDir () { # check the directory structure where we will keep the paper -- otherwise make the directories
	if [ ! -d "$LIBPATH/$PAPERTYPE" ];then
		mkdir "$LIBPATH/$PAPERTYPE"
		printf "Made directory $LIBPATH/$PAPERTYPE\n"
	fi
	if [ ! -d "$LIBPATH/$PAPERTYPE/$YEAR" ];then
		mkdir "$LIBPATH/$PAPERTYPE/$YEAR"
		printf "Made directory $LIBPATH/$PAPERTYPE/$YEAR\n" 
	fi
}

Open () { # open a PDF
	$PDFVIEWER $FILEPATH/$FILENAME &
}

Print () { # print a PDF
	printf "Printing...\n"
	$PRINTCOMMAND $FILEPATH/$FILENAME
}


ErrorReport() { # report failures at the end, as lynx may induce screen scroll
	if [ $ERROR -eq 1 ];then
		printf "***********************************************\n"
		printf "The following submission(s) failed to download:\n"
		printf "JOURNAL\tVOLUME\tPAGE\n"
		cat $ERRORFILE
		printf "***********************************************\n"
	fi
}

IsPdfValid () { # check if we downloaded a basically valid PDF
	if ( pdfinfo $TMP/$FILENAME 2>&1 | grep "Error: May not be a PDF file" > /dev/null );then
		printf "Error in downloading the PDF\nMaybe you do not have access\nTerminating...\n"
		rm -vf $TMP/$FILENAME
		Error
		continue
	fi
}

GUI () {

jval=$(zenity  --width=400  --height=703 --title "getpaper" --list  --text "Choose a journal" --radiolist  --column "" --column "Code" --column "Publication Title"  \
	FALSE aa "Astronomy & Astrophysics" \
	FALSE aipc "American Institute of Physics (Conference Proceedings)" \
	FALSE aj "The Astronomical Journal" \
	FALSE anap "Annales d Astrophysique" \
	FALSE apj "The Astrophysical Journal" \
	FALSE apjl "The Astrophysical Journal (Letters)" \
	FALSE apjs "The Astrophysical Journal (Supplement Series)" \
	FALSE aujph "Australian Journal of Physics" \
	FALSE bsrsl "Bulletin de la Societe Royale des Sciences de Liege" \
	FALSE epjh "European Physical Journal" \
	FALSE mnras "Monthly Notices of the Royal Astronomical Society" \
	FALSE msrsl "Memoires of the Societe Royale des Sciences de Liege" \
	FALSE natph "Nature Physics" \
	FALSE nimpa "Nuclear Instruments and Methods (1983 and earlier)" \
	FALSE nimpa "Nuclear Instruments and Methods in Physics Research A" \
	FALSE nimpb "Nuclear Instruments and Methods in Physics Research B" \
	FALSE nupha "Nuclear Physics A" \
	FALSE nuphb "Nuclear Physics B" \
	FALSE obs "The Observatory" \
	FALSE paphs "Proceedings of the American Philosophical Society" \
	FALSE pasp "Publications of the Astronomical Society of the Pacific" \
	FALSE phrv "Physical Review" \
	FALSE pce "Physics and Chemistry of the Earth" \
	FALSE pmag "Philosophical Magazine" \
	FALSE ppsa "Proceedings of the Physical Society A" \
	FALSE ppsb "Proceedings of the Physical Society B" \
	FALSE pra "Physical Review A" \
	FALSE prb "Physical Review B" \
	FALSE prc "Physical Review C" \
	FALSE prd "Physical Review D" \
	FALSE pre "Physical Review E" \
	FALSE prl "Physical Review Letters" \
	FALSE pthph "Progress of Theoretical Physics" \
	FALSE rvmp "Reviews of Modern Physics" \
	FALSE science "Science" \
	FALSE scoa "Smithsonian Contributions to Astrophysics" \
	FALSE zphy "Zeitschrift fur Physik" \
)
if [ ! -z $jval ];then
	jflag=1
fi

vval=$(zenity --entry --title "getpaper" --text "Volume:")
if [ ! -z $vval ];then
	vflag=1
fi

pval=$(zenity --entry --title "getpaper" --text "Page:")
if [ ! -z $pval ];then
	pflag=1
fi

}




CheckDeps
InitVariables
TmpCleanUp

# FLAG READING FOR INPUT
jflag=
vflag=
pflag=
fflag=
Pflag=
Oflag=
while getopts j:v:p:f:PO OPTION
do
    case $OPTION in
    f) 	  fflag=1
    	  fval="$OPTARG";;
    j)    jflag=1
          jval="$OPTARG";;
    v)    vflag=1
          vval="$OPTARG";;
    p)    pflag=1
          pval="$OPTARG";;
    P)    Pflag=1;;
    O)    Oflag=1;;
    ? | *) Usage;;  
    esac
done
if [ -z $1 ];then
	type -P zenity &>/dev/null || { Usage; }
	GUI=1
	GUI
else
	GUI=0
fi
# FLAG SETTING FOR INPUT
if [ "$fflag" ]; then
	INPUTFILE="$fval"
	if [ ! -e "$INPUTFILE" ];then
		printf "The input file $INPUTFILE could not be found!\nTerminating..."
		exit 1
	fi
	cp "$INPUTFILE" "$INPUT"
else
	if [ "$jflag" ] ; then
	# journal name flag
		JOURNAL="$jval"
		if [ $jval == "list" ] || [ $jval == "help" ];then
			JournalList
			exit 1
		fi
	else
		printf "No journal given!\nSkipping...\n"
		Error
		exit 1
	fi
	
	if [ "$vflag" ] ; then
	# volume number flag
		VOLUME="$vval"
	else
		printf "No volume given!\nSkipping...\n"
		Error
		exit 1
	fi
	
	if [ "$pflag" ] ; then
	# page number flag
		PAGE="$pval"
	else
		printf "No page given!\nSkipping...\n"
		Error
		exit 1
	fi
	printf "$JOURNAL\t$VOLUME\t$PAGE\n" > "$INPUT"
fi

# The main part of the script
exec 3<&0 # stdin redirect for use in while read 
while read inline
do
	ParseJVP
	SetJournal
	FetchBibtex	
	DownloadPdf
        IsPdfValid 
	CheckDir

	printf "Moving downloaded PDF from temporary location: "
	mv -v "$TMP/$FILENAME" "$FILEPATH/$FILENAME"

	AddBibtex

	if [ $GUI -eq 1 ];then
		ans=$(zenity  --list  --title "getpaper" --text "Finished!" --checklist  --column "" --column "Do you want to:" FALSE "Open the pdf" FALSE "Print the pdf" --separator=":"); echo $ans
	fi

	if (echo $ans | grep "Open" > /dev/null);then
		Oflag=1
	fi
	if (echo $ans | grep "Print" /dev/null);then
		Pflag=1
	fi

	if [ "$Oflag" ]; then
		Open
	fi
	if [ "$Pflag" ]; then
		Print
	fi
done < "$INPUT"

ErrorReport
TmpCleanUp
