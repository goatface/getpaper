#!/bin/bash
# getpaper v 0.6
# Copyright 2010 daid kahl
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
	PDFVIEWER=/usr/bin/xpdf
	PRINTCOMMAND="/usr/bin/lpr -P CNS205 -o Duplex=DuplexNoTumble"
	LIBPATH=/home/`whoami`/library
	BIBFILE=$LIBPATH/library.bib
	TMP=/tmp
	# INTERNAL TEMPORARY FILES -- MAY CHANGE BUT NOT NECESSARY
	TMPBIBCODE=$TMP/.getpaper_bibcode
	TMPBIBTEX=$TMP/.getpaper_bibtex
	TMPURL=$TMP/.getpaper_url
	ERRORFILE=$TMP/.getpaper_error
	# temporary storage for input information...whereever you want
	INPUT=$TMP/refinput.txt

	# internal variables -- do not change!
	ERROR=0
}

Usage () {
	printf "getpaper version 0.6\nDownload, bibtex, print, and/or open papers based on reference!\n"
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
	printf "apj\tThe Astrophysical Journal\n"
	printf "apjl\tThe Astrophysical Journal (Letters)\n"
	printf "apjs\tThe Astrophysical Journal (Supplement Series)\n"
	printf "mnras\tMonthly Notices of the Royal Astronomical Society\n"
	printf "nimpa\tNuclear Instruments and Methods (1983 and earlier)\n"
	printf "nimpa\tNuclear Instruments and Methods in Physics Research A\n"
	printf "nimpb\tNuclear Instruments and Methods in Physics Research B\n"
	printf "nupha\tNuclear Physics A\n"
	printf "prc\tPhysical Review C\n"
	printf "prl\tPhysical Review Letters\n"
	printf "science\tScience\n"
}

SetJournal() {	# JOURNAL DEFINITIONS -- may want to improve this list, but be sure to understand and test the meaning of the variables
	# varibales used:
	# 		JCODE : ADS journal code (case insensitive); see http://adsabs.harvard.edu/abs_doc/journal_abbr.html but be careful with things like "A&A"
	#		LTYPE : ADS system variable; EJOURNAL is externally hosted; ARTICLE is locally hosted
	# 		LOCALHTML : presently used for ScienceDirect page style -- bad variable name
	case "$JOURNAL" in
	aa  | AA )
		LOCALHTML=1
		JCODE="a%26a"
		LTYPE="ARTICLE"
		;;
	aipc | AIPC )  LOCALHTML=1
		JCODE="aipc"
		LTYPE="EJOURNAL"
		;;
	apj |APJ )  LOCALHTML=1
		JCODE="apj"
		LTYPE="ARTICLE"
		;;
	apjl | APJL )  LOCALHTML=1
		JCODE="apjl"
		LTYPE="ARTICLE"
		;;
	apjs | APJS )  LOCALHTML=1
		JCODE="apjs"
		LTYPE="ARTICLE"
		;;
	mnras | MNRAS )
		LOCALHTML=1
		JCODE="mnras"
		LTYPE="ARTICLE"
		;;
	nim | nucim | NIM | NucIM) 
		LOCALHTML=0
		JCODE="nucim"
		LTYPE="EJOURNAL"
		;;
	nimpa | nima | NIMPA | NIMA) 
		LOCALHTML=0
		JCODE="nimpa"
		LTYPE="EJOURNAL"
		;;
	nimpb | nimb | NIMPB | NIMB) 
		LOCALHTML=0
		JCODE="nimpb"
		LTYPE="EJOURNAL"
		;;
	nupha | npa | NPA | nucphysa ) 
		LOCALHTML=0
		JCODE="nupha"
		LTYPE="EJOURNAL"
		;;
	prc | phrvc | PRC )   LOCALHTML=1
		JCODE="phrvc"
		LTYPE="EJOURNAL"
		;;
	prl | phrvl | PRL )   LOCALHTML=1
		JCODE="phrvl"
		LTYPE="EJOURNAL"
		;;
	science | SCIENCE )
		LOCALHTML=1
		JCODE="science"
		LTYPE="ARTICLE"
		;;
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
	BIBCODE=`grep bibcode= $TMPBIBCODE | head -n 1 | sed 's/.*bibcode=//'|sed 's/&.*//'`
	if [ -z $BIBCODE ];then
		printf "No BIBCODE could be found!\n"
		Error
		continue
	else
		printf "BIBCODE is $BIBCODE\n"
	fi
	
	YEAR=`echo "$BIBCODE" | head -c 4`
	if ( grep "$BIBCODE" "$BIBFILE" > /dev/null ); then
		echo "The article $BIBCODE is already in your library!"
		echo "$BIBFILE"
		echo "Skipping..."
		continue
	fi
	ADSBIBTEX="http://adsabs.harvard.edu/cgi-bin/nph-bib_query?bibcode=$BIBCODE&data_type=BIBTEXPLUS&db_key=ALL&nocookieset=1"
	printf "Fetching bibtex file from ADS ($ADSBIBTEX)\n"
	lynx -source "$ADSBIBTEX" | awk 'NR>5' >$TMPBIBTEX
	
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

		lynx -base -source -read_timeout=20 "$ADSLINK" >$TMPURL 
		if [ $LOCALHTML -eq 1 ];then
			BASEURL=`head -n 1 $TMPURL | sed 's/.*X-URL:\ //'|  sed 's,\(http://[^/]*\)/.*,\1,'`
			LOCALPDF=`grep PDF $TMPURL |sed  's/.*href=\"//i' | sed 's/\".*//' | head -n 1`
		else
			BASEURL=""
			LOCALPDF=`grep PDF $TMPURL |sed  's/.*href=\"//i' | sed 's/\".*//' | grep "origin=search" | head -n 1`
		fi
		FULLPATH="$BASEURL$LOCALPDF"
	fi
	printf "Downloading PDF from $FULLPATH...\n"
	wget -U 'Mozilla/5.0' "$FULLPATH" -O"$TMP/$FILENAME" # we need to mask as Firefox or wget is denied access by error 403 sometimes
}

AddBibtex () {
	while read line
	do
		if ( echo $line | grep "doi = " > /dev/null );then
			printf "$line\n" >> "$BIBFILE"
			printf "file = {:$LIBPATH/$PAPERTYPE/$YEAR/$FILENAME:PDF},\n" >> "$BIBFILE"
		        printf "comment = {$COMMENTS},\n" >> "$BIBFILE"				    
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
	Usage
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

	if [ "$Oflag" ]; then
		Open
	fi
	if [ "$Pflag" ]; then
		Print
	fi
done < "$INPUT"

ErrorReport
TmpCleanUp
