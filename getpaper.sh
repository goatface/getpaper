#!/bin/bash
# getpaper
VERSION=1.50
# Copyright 2010-2018  daid kahl
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

# TODO: 
#	'file' version only does the first line...not used this in years
# 	GUI mode is mostly broken since it is not mirroring the methods really
#	debugging mode (outputs various URLs to STDOUT/ERR, does not put bibtex or paper into library, etc)
#	make sensible things like LYNXFLAGS and cat onto that rather than lots of different calls
#	break up long lines for readability
#	more sane, accurate, and relevant command line output for normal people
#	ctrl+c sig int catch to clean up
#	"Downloading PDF from  ..." should say something about lynx or give the URL?  It uses $ADSURL
#	after the apshack, it should tell the user it's submitting the requested link number w/ Einstein and downloading the result
#	[ -z "$Xflag" ] for unset variables
#	Oflag or others can be set default as on in the rc?
#	can understand j v p order w/o flags -j -v -p
#	redirect lynx stderr because it is annoying to see:
#		Warning: User-Agent string does not contain "Lynx" or "L_y_n_x"!
#	give user the bibcode and download location etc nicely at the end
#	need to suppress output
#	distinguish save points for multiple-return query.  Can test via getpaper -j pasa -v 25 -p 1 -O
#	recognizes the situation with only bibtex and no download, but does not resolve
#       Zenity calls need updating: Gtk-Message: GtkDialog mapped without a transient parent. This is discouraged.
#       Need a check if lynx was built with --enable-externs or APS captcha stuff will blindly crash

# code from crabat to mimic
#control_c () { # if we get a Ctrl+C, kill.  If running loop, kill all child run
#  echo
#  echo "Received kill signal..."
#  [ ! $Lflag ] && exit
#  echo "killing child run processes..."
#  [ -e .looptmp ] && rm .looptmp
#  kill -1 $PIDS 2> /dev/null # redirect error since many PIDs won't exist
#  exit
#}
## trap keyboard interrupt 
#trap control_c SIGINT

# Initialize variables
# Read in or create .getpaperrc
# concept to check for and create default config file from
# https://github.com/matt-lowe/ProfanityFE
function InitVariables () {
	AGENT="Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.10 Safari/537.36" # 05 Mar 2017 01:00:10 
	#AGENT="Links (2.8; Linux 3.14.1-gentoo i686; GNU C 4.8.2; text)" # new 08 Feb 2017 15:57:58 
	CONFIG_FILE=$HOME/.getpaperrc
	PWD=$(pwd)
	# find the full path of getpaper
	# see http://unix.stackexchange.com/questions/9541/find-absolute-path-from-a-script
	GETPAPERPATH=$(cd ${0%/*} && echo $PWD/${0##*/})
	# Check for configuration file
	if [ ! -e $CONFIG_FILE ];then
	# If no config file, generate a default one as follows:
printf "# getpaper config file
# USER DEFINED VARIABLES
# Program to open PDF files
PDFVIEWER=/usr/bin/evince 
#PDFVIEWER=/usr/bin/acroread
#PDFVIEWER=/usr/bin/okular
#PDFVIEWER=/usr/bin/epdfview
# Mac OS X
#PDFVIEWER=/usr/bin/open 
# Default printer to use
PRINTER=
PRINTCOMMAND=\"/usr/bin/lpr -P \$PRINTER -o Duplex=DuplexNoTumble\" 
# Information for ssh, if you have a default server
#USER=
#HOST=
# Library path for getpaper
# Normal GNU/Linux style
LIBPATH=\$HOME/library 
# Mac OS X
#LIBPATH=\$HOME/Documents/library 
# Bibliography file for getpaper
BIBFILE=\$LIBPATH/library.bib # normal for all cases
# temporary directory to use during execution
TMP=/tmp
# INTERNAL TEMPORARY FILES -- MAY CHANGE BUT NOT NECESSARY
TMPBIBCODE=\$TMP/.getpaper_bibcode
TMPBIBTEX=\$TMP/.getpaper_bibtex
TMPBIBCODELIST=\$TMP/.getpaper_bibcodelist
TMPFILENAME=\$TMP/.getpaper_filename
TMPURL=\$TMP/.getpaper_url
TMPAPSDUMP=\$TMP/getpaper_aps_dump.html
ERRORFILE=\$TMP/.getpaper_error
LYNXCMD=\$TMP/.getpaper_lynxcmd
LYNXCFG=\$TMP/.getpaper_lynx.cfg
# temporary storage for input information...whereever you want
INPUT=\$TMP/.getpaper_refinput.txt" > $CONFIG_FILE
	echo "Created new config file at $CONFIG_FILE"
	echo "Please check the settings, and re-run $GETPAPERPATH"
	exit
	fi
	# Get user inputs
	source $CONFIG_FILE
	# internal variables -- do not change!
	ERROR=0
}

# Tell a user how to invoke this script
# TODO: why is copyright years, my name, etc here and at the top?  consolidate
function Usage()
{
cat <<-ENDOFMESSAGE
getpaper version $VERSION
Download, add bibtex, query bibtex, strip propaganda, print, and/or open papers based on reference!
Copyright 2010-2018 daid kahl - www.goatface.org

Usage: 
  $0: [-h] [-q] [-b] [-f file] [-j journal] [-v volume] [-p page] [-c "comments"] [-P] [-O] [-R [user@host]]

options:
  --help   
  -h		: display this message
  --file <file>
  -f <file>	: getpaper reads data from <file> where each line corresponds to an article as:
  			Principle:
  				JOURNAL	VOLUME	PAGE	COMMENTS
  			Example:
  				prl	99	052502	12C+alpha 16N RIB
  			(Comments are used in the bibtex for the user's need.)
  --query
  -q 		: query (no downloads nor bibtex modification)
  		  Will inform if the reference is valid, check if you have the bibtex, paper
		  Can open and/or print if called with those options
  --bibtex
  -b 		: bibtex only (no downloads)
  --journal <string>
  -j <string>	: <string> is the journal title abbreviation
   		: If <string> is 'help' or 'list', output journal list and codes.
  --volume <int>
  -v <int>	: <int> is the journal volume number
  --page <int>
  -p <int>	: <int> is the article first page
  --comment
  -c "<string>": <string> is any comments, in quotes, including spaces
  --print
  -P 		: Printing is turned on
  --open
  -O 		: Open the paper(s) for digital viewing
  --remote <user@host>
  -R <user@host>: Remote download through ssh to <user@host>
  		  <user@host> can be omitted if USER and HOST are defined in .getpaperrc
  (NOTE: -f option supersedes the -j -v -p options.)
  
  Internal options: DO NOT INVOKE DIRECTLY!
  
  --apscaptcha	: Used by getpaper to dynamically download the images for user selection
  --retry	: Used by getpaper to attempt a second condition for several journals

If zenity is installed, getpaper will enter GUI mode if no options are passed

ENDOFMESSAGE
  exit 1
}

# Fuck off and...
function Die()
{
  echo "$*"
  exit 1
}

# Parse and set relevant options
function GetOpts() {
# basic style from http://stackoverflow.com/questions/17016007/bash-getopts-optional-arguments
# dislike the builtin getopts
# TODO: Make all these 0 and change if checks rather than asking if these are empty...what a hack
  FLAGS="$@"
  bflag=""
  qflag=""
  jflag=""
  vflag=""
  pflag=""
  cflag=""
  fflag=""
  bflag=""
  Pflag=""
  Oflag=""
  Rflag=""
  APSflag=""
  RETRYflag=""
  argv=()
  while [ $# -gt 0 ]
  do
    opt=$1
    shift
    case ${opt} in
      -b|--bibtex)
      bflag=1
        ;;
      -q|--query)
      qflag=1
        ;;
      -P|--print)
      Pflag=1
        ;;
      -O|--open)
      Oflag=1
        ;;
      -h|--help)
        Usage;;
      -c|--comment)
        if [ $# -eq 0 -o "${1:0:1}" = "-" ]; then
          Die "The ${opt} option requires an argument."
        fi
        cval="$1"
      cflag=1
        shift
        ;;
      -f|--file)
        if [ $# -eq 0 -o "${1:0:1}" = "-" ]; then
          Die "The ${opt} option requires an argument."
        fi
        fval="$1"
      fflag=1
        shift
        ;;
      -j|--journal)
        if [ $# -eq 0 -o "${1:0:1}" = "-" ]; then
          Die "The ${opt} option requires an argument."
        fi
        jval="$1"
      jflag=1
      shift
        ;;
      -v|--volume)
        if [ $# -eq 0 -o "${1:0:1}" = "-" ]; then
          Die "The ${opt} option requires an argument."
        fi
        vval="$1"
      vflag=1
        shift
        ;;
      -p|--page)
        if [ $# -eq 0 -o "${1:0:1}" = "-" ]; then
          Die "The ${opt} option requires an argument."
        fi
        pval="$1"
      pflag=1
        shift
        ;;
      -R|--remote)
        # This is a case where getopts builtin will fail
        if [ $# -eq 0 -o "${1:0:1}" = "-" ] && [ ! "$HOST" -o ! "$USER" ] ; then
        Die "The ${opt} option requires an argument."
        fi
        Rval="$1"
        Rflag=1
        if [ ! "$USER" ]; then 
      	  USER=`echo $Rval | sed 's/@.*//'`
        fi
        if [ ! "$HOST" ]; then
      	  HOST=`echo $Rval | sed 's/.*@//'`
        fi
        printf "User is $USER, Host is $HOST for ssh Remote download\n"
          shift
          ;;
      --apscaptcha)
      APSflag=1
        ;;
      --retry)
      RETRYflag=1
        ;;
      *)
        if [ "${opt:0:1}" = "-" ]; then
            Die "${opt}: unknown option."
        fi
        argv+=(${opt});;
    esac
  done 
}

# Check the dependencies to ensure getpaper can run
function CheckDeps () {
# TODO: make array to track [program][url]
  DEPCHECK=0
  which lynx &>/dev/null || { printf "getpaper requires lynx but it's not in your PATH or not installed.\n\t(see https://lynx.browser.org/)\n" >> $ERRORFILE; ERROR=1; }
  which wget &>/dev/null || { printf "getpaper requires wget but it's not in your PATH or not installed.\n\t(see https://www.gnu.org/software/wget/)\n" >> $ERRORFILE; ERROR=1; }
  which pdfinfo &>/dev/null || { printf "getpaper requires pdfinfo but it's not in your PATH or not installed.\n\t(see http://poppler.freedesktop.org/)\n" >> $ERRORFILE; ERROR=1;}
  which pdftk &>/dev/null || { printf "getpaper requires pdftk but it's not in your PATH or not installed.\n\t(see https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/)\n" >> $ERRORFILE; ERROR=1; }
  which grep &>/dev/null || { printf "getpaper requires grep but it's not in your PATH or not installed.\n\t(see https://www.gnu.org/software/grep/)\n" >> $ERRORFILE; ERROR=1; }
  which sed &>/dev/null || { printf "getpaper requires sed but it's not in your PATH or not installed.\n\t(see https://www.gnu.org/software/sed/)\n" >> $ERRORFILE; ERROR=1;}
  which awk &>/dev/null || { printf "getpaper requires awk but it's not in your PATH or not installed.\n\t(see https://www.gnu.org/software/gawk/)\n" >> $ERRORFILE; ERROR=1;}
  which convert &>/dev/null || { printf "getpaper requires convert which is a part of ImageMagick but it's not in your PATH or not installed.\n\t(see https://www.imagemagick.org)\n" >> $ERRORFILE; ERROR=1;}
  which zenity &>/dev/null || { printf "getpaper requires zenity but it's not in your PATH or not installed.\n\t(see https://help.gnome.org/users/zenity/stable/)\n" >> $ERRORFILE; ERROR=1;}
  if [ $ERROR -eq 1 ];then
  	printf "Aborting.\n" >> $ERRORFILE
        cat $ERRORFILE
  	exit 1
  fi
  #if [ $Rflag ];then
   #ssh "$USER@$HOST" which wget &>/dev/null || { printf "getpaper requires wget but it's not in the PATH or not installed on your remote server.\n\t(see http://www.gnu.org/software/wget/)\nAborting.\n" >&2; exit 1; }
   # fix me (remote lynx is done by alias so not in PATH but it works...arrr)
   #ssh "$USER@$HOST" type -t lynx &>/dev/null || { printf "getpaper requires lynx but it's not in the PATH or not installed on your remote server.\n\t(see http://lynx.browser.org/)\nAborting.\n" >&2; exit 1; }
  #fi
}

# Track any and all failures for reporting
function Error () {
  ERROR=1
  printf "$JOURNAL\t$VOLUME\t$PAGE\n" >> $ERRORFILE
}

# Present journal database
function JournalList() {
  printf "Journals in database:\nCODE\tNAME\n"
  printf "aa\tAstronomy & Astrophysics\n"
  printf "aipc\tAmerican Institute of Physics (Conference Proceedings)\n"
  printf "aj\tThe Astronomical Journal\n"
  printf "astl\tAstronomy Letters\n"
  printf "anap\tAnnales d'Astrophysique\n" # none of these are online vi ADS
  printf "apj\tThe Astrophysical Journal\n"
  printf "apjl\tThe Astrophysical Journal (Letters)\n"
  printf "apjs\tThe Astrophysical Journal (Supplement Series)\n"
  printf "arnps\tAnnual Review of Nuclear and Particle Science\n"
  printf "aujph\tAustralian Journal of Physics\n"
  printf "baas\tBulletin of the American Astronomical Society\n"
  printf "bsrsl\tBulletin de la Societe Royale des Sciences de Liege\n"
  printf "epja\tEuropean Physical Journal A\n"
  printf "epjas\tEuropean Physical Journal A Supplement\n"
  printf "epjb\tEuropean Physical Journal B\n"
  printf "epjc\tEuropean Physical Journal C\n"
  printf "epjd\tEuropean Physical Journal D\n"
  printf "epje\tEuropean Physical Journal E\n"
  printf "epjst\tEuropean Physical Journal ST\n"
  printf "epjh\tEuropean Physical Journal H\n"
  printf "epjwc\tEuropean Physical Journal Web of Conferences\n"
  printf "gecoa\tGeochimica et Cosmochimica Acta\n"
  printf "jphcs\tConference Series\n"
  printf "jphg\tJournal of Physics G: Nuclear and Particle Physics\n"
  printf "jpsj\tJournal of the Physical Society of Japan\n"
  printf "mnras\tMonthly Notices of the Royal Astronomical Society\n"
  printf "msrsl\tMemoires of the Societe Royale des Sciences de Liege\n"
  printf "metro\tMetrologia\n"
  printf "natur\tNature\n"
  printf "natph\tNature Physics\n"
  printf "newar\tNew Astronomy Reviews\n"
  printf "nucim\tNuclear Instruments and Methods (1983 and earlier)\n"
  printf "nimpa\tNuclear Instruments and Methods in Physics Research A\n"
  printf "nimpb\tNuclear Instruments and Methods in Physics Research B\n"
  printf "nupha\tNuclear Physics A\n"
  printf "nuphb\tNuclear Physics B\n"
  printf "nuphs\tNuclear Physics Supplement\n"
  printf "obs\tThe Observatory\n"
  printf "paphs\tProceedings of the American Philosophical Society\n" # none online via ADS
  printf "pasa\tPublications of the Astronomical Society of Australia\n" # none online via ADS
  printf "pce\tPhysics and Chemsitry of the Earth\n"
  printf "phrv\tPhysical Review\n"
  printf "pmag\tPhilosophical Magazine\n"
  printf "ppsa\tProceedings of the Physical Society A\n"
  printf "ppsb\tProceedings of the Physical Society B\n"
  printf "pos\tProceedings of Science\n"
  printf "pra\tPhysical Review A\n"
  printf "prb\tPhysical Review B\n"
  printf "prc\tPhysical Review C\n"
  printf "prd\tPhysical Review D\n"
  printf "pre\tPhysical Review E\n"
  printf "phlb\tPhysics Letters B\n"
  printf "pasj\tPublications of the Astronomical Society of Japan\n"
  printf "pasp\tPublications of the Astronomical Society of the Pacific\n"
  printf "prl\tPhysical Review Letters\n"
  printf "prpnp\tProgress in Particle and Nuclear Physics\n"
  printf "pthph\tProgress of Theoretical Physics\n"
  printf "pthps\tProgress of Theoretical Physics Supplement\n"
  printf "rsci\tReview of Scientific Instruments\n"
  printf "rvmp\tReviews of Modern Physics\n"
  printf "science\tScience\n"
  printf "scoa\tSmithsonian Contributions to Astrophysics\n"
  printf "va\tVistas in Astronomy\n"
  printf "zphy\tZeitschrift fur Physik\n"
  printf "zphya\tZeitschrift fur Physik A\n"
}

# Set the proper variables so getpaper can determine what to do
function SetJournal() {	# JOURNAL DEFINITIONS -- may want to improve this list, but be sure to understand and test the meaning of the variables
  # varibales used:
  # 		JCODE : ADS journal code (case insensitive); see http://adsabs.harvard.edu/abs_doc/journal_abbr.html but be careful with things like "A&A"
  #		LTYPE : ADS system variable; EJOURNAL is externally hosted; ARTICLE is locally hosted
  # 		HREFTYPE : Specifies locality of the href
  #				0 : full paths given for href
  #				1 : domain absent from href
  #				2 : local file name given for href
  # TODO: Put these inits somewhere else?
  LYNX= 
  APS= 
  SD= 
  PROPAGANDA=0 
  NATURE=0 
  FALSEPAGE=("jphg" "jphcs") # journals where the first two pages need to be stripped sometimes
  FALSEPAGE=$(echo ${FALSEPAGE[@]}|tr " " "|")
  # TODO: Make less of a nightmare.  External config file?!?
  case "$JOURNAL" in
    aa  | AA ) HREFTYPE=1; JCODE="a%26a"; LTYPE="ARTICLE" ;;
    aipc | LYNXC )  LYNX=1; HREFTYPE=1; JCODE="aipc"; LTYPE="EJOURNAL" ; PROPAGANDA=1 ;;
    aj |AJ )  HREFTYPE=1; JCODE="aj"; LTYPE="ARTICLE" ;;
    astl | AstL )  HREFTYPE=1; JCODE="astl"; LTYPE="EJOURNAL" ;;
    anap |AnAp )  HREFTYPE=1; JCODE="anap"; LTYPE="ARTICLE" ;;
    apj |APJ )  HREFTYPE=1; JCODE="apj"; LTYPE="ARTICLE" ;;
    apjl | APJL )  HREFTYPE=1; JCODE="apjl"; LTYPE="ARTICLE" ;;
    apjs | APJS )  HREFTYPE=1; JCODE="apjs"; LTYPE="ARTICLE" ;;
    arnps  | ARNPS ) HREFTYPE=1; JCODE="arnps"; LTYPE="ARTICLE" ;;
    aujph | AuJPh )  HREFTYPE=1; JCODE="aujph"; LTYPE="ARTICLE" ;;
    baas | BAAS  )   HREFTYPE=1; JCODE="baas"; LTYPE="ARTICLE" ;;
    bsrsl | BSRSL  )   HREFTYPE=2; JCODE="bsrsl"; LTYPE="EJOURNAL" ;;
    cajph | CAJPH | CaJPh ) LYNX=1; HREFTYPE=1; JCODE="cajph"; LTYPE="EJOURNAL" ;;
    epja | EPJA )  LYNX=1;HREFTYPE=1; JCODE="epja"; LTYPE="EJOURNAL" ;;
    epjas | EPJAS )  LYNX=1;HREFTYPE=1; JCODE="epjas"; LTYPE="EJOURNAL" ;;
    epjb | EPJB )  LYNX=1;HREFTYPE=1; JCODE="epjb"; LTYPE="EJOURNAL" ;;
    epjc | EPJC )  LYNX=1;HREFTYPE=1; JCODE="epjc"; LTYPE="EJOURNAL" ;;
    epjd | EPJD )  LYNX=1;HREFTYPE=1; JCODE="epjd"; LTYPE="EJOURNAL" ;;
    epje | EPJE )  LYNX=1;HREFTYPE=1; JCODE="epje"; LTYPE="EJOURNAL" ;;
    epjst | EPJST )  LYNX=1;HREFTYPE=1; JCODE="epjst"; LTYPE="EJOURNAL" ;;
    epjh | EPJH )  LYNX=1;HREFTYPE=1; JCODE="epjh"; LTYPE="EJOURNAL" ;;
    epjwc | EPJWC )  LYNX=1;HREFTYPE=1; JCODE="epjwc"; LTYPE="EJOURNAL" ;;
    gecoa | GeCoA | GECOA )   if [ "$RETRYflag" ];then LYNX=1; fi;  SD=1;HREFTYPE=0;JCODE="gecoa";LTYPE="EJOURNAL" ;;
    jphcs | JPhCS | jphycs | JPhyCS )  LYNX=1;HREFTYPE=1; JCODE="jphcs"; LTYPE="EJOURNAL" ;PROPAGANDA=1;;
    jphg | JPhG | jphyg | JPhyG )  LYNX=1;HREFTYPE=1; JCODE="jphg"; LTYPE="EJOURNAL" ;PROPAGANDA=1;;
    jpsj | JPSJ  )  HREFTYPE=1; JCODE="jpsj"; LTYPE="EJOURNAL" ;;
    mnras | MNRAS ) HREFTYPE=1; JCODE="mnras"; LTYPE="ARTICLE" ;;
    msrsl | MSRSL  )   HREFTYPE=1; JCODE="msrsl"; LTYPE="ARTICLE" ;;
    metro | Metro )  HREFTYPE=1; JCODE="metro"; LTYPE="EJOURNAL" ;;
    natur | nature | Nature | Natur ) NATURE=1; HREFTYPE=1; JCODE="natur"; LTYPE="EJOURNAL" ;;
    natph | NatPh )  LYNX=1; HREFTYPE=1; JCODE="natph"; LTYPE="EJOURNAL" ;;
    newar | NewAR | NEWAR )   if [ "$RETRYflag" ];then LYNX=1; fi;  SD=1;HREFTYPE=0;JCODE="newar";LTYPE="EJOURNAL" ;;
    nim | nucim | NIM | NucIM)  if [ "$RETRYflag" ];then LYNX=1; fi; SD=1 ;HREFTYPE=0; JCODE="nucim"; LTYPE="EJOURNAL" ;;
    nimpa | nima | NIMPA | NIMA) if [ "$RETRYflag" ];then LYNX=1; fi; SD=1 ;HREFTYPE=0; JCODE="nimpa"; LTYPE="EJOURNAL" ;;
    nimpb | nimb | NIMPB | NIMB)  if [ "$RETRYflag" ];then LYNX=1; fi; SD=1 ;HREFTYPE=0; JCODE="nimpb"; LTYPE="EJOURNAL" ;;
    nupha | npa | NPA | nucphysa )  if [ "$RETRYflag" ];then LYNX=1; fi;  SD=1; HREFTYPE=0; JCODE="nupha"; LTYPE="EJOURNAL" ;;
    nuphb | npb | NPB | nucphysb )  if [ "$RETRYflag" ];then LYNX=1; fi; SD=1;HREFTYPE=0; JCODE="nuphb"; LTYPE="EJOURNAL" ;;
    nuphs | nps | NPS | nucphyss )  if [ "$RETRYflag" ];then LYNX=1; fi; SD=1;HREFTYPE=0; JCODE="nuphs"; LTYPE="EJOURNAL" ;;
    obs | OBS )  HREFTYPE=1; JCODE="obs"; LTYPE="ARTICLE" ;;
    paphs | PAPhS | PAPHS )   HREFTYPE=1; JCODE="paphs"; LTYPE="EJOURNAL" ;;
    pasa |PASA )  HREFTYPE=1; JCODE="pasa"; LTYPE="ARTICLE" ;;
    pasj | PASJ )   HREFTYPE=1; JCODE="pasj"; LTYPE="ARTICLE" ;;
    pasp | PASP )   HREFTYPE=1; JCODE="pasp"; LTYPE="ARTICLE" ;;
    pce | PCE )  if [ "$RETRYflag" ];then LYNX=1; fi; SD=1;HREFTYPE=0; JCODE="pce"; LTYPE="EJOURNAL" ;;
    phrv | pr | PhRv | PHRV )   APS=1;LYNX=1; HREFTYPE=1; JCODE="phrv"; LTYPE="EJOURNAL" ;;
    pmag | PMag | PMAG )   HREFTYPE=1; JCODE="pmag"; LTYPE="EJOURNAL" ;;
    ppsa | PPSA  )   HREFTYPE=1; JCODE="ppsa"; LTYPE="EJOURNAL" ;;
    ppsb | PPSB  )   HREFTYPE=1;JCODE="ppsb";LTYPE="EJOURNAL" ;;
    pos | POS | PoS )  HREFTYPE=1; JCODE="pos"; LTYPE="ARTICLE" ;;
    pra | phrva | PRA )   APS=1;LYNX=1;HREFTYPE=1;JCODE="phrva";LTYPE="EJOURNAL" ;;
    prb | phrvb | PRB )   APS=1;LYNX=1;HREFTYPE=1;JCODE="phrvb";LTYPE="EJOURNAL" ;;
    prc | phrvc | PRC )   APS=1;LYNX=1;HREFTYPE=1;JCODE="phrvc";LTYPE="EJOURNAL" ;;
    prd | phrvd | PRD )   APS=1;LYNX=1;HREFTYPE=1;JCODE="phrvd";LTYPE="EJOURNAL" ;;
    pre | phrve | PRE )   APS=1;LYNX=1;HREFTYPE=1;JCODE="phrve";LTYPE="EJOURNAL" ;;
    prl | phrvl | PRL )   APS=1;LYNX=1;HREFTYPE=1;JCODE="phrvl";LTYPE="EJOURNAL" ;;
    phlb | physlb | PhLB )   if [ "$RETRYflag" ];then LYNX=1; fi;  SD=1;HREFTYPE=0;JCODE="phlb";LTYPE="EJOURNAL" ;;
    prpnp | PrPNP | ppnp | PPNP)  if [ "$RETRYflag" ];then LYNX=1; fi; SD=1;HREFTYPE=0; JCODE="prpnp"; LTYPE="EJOURNAL" ;;
    pthph | PThPh | PTHPH )   HREFTYPE=1;JCODE="pthph";LTYPE="EJOURNAL";LYNX=1 ;;
    pthps | PThPS | PTHPS )   HREFTYPE=1;JCODE="pthps";LTYPE="EJOURNAL" ;;
    rsci | RScI )  HREFTYPE=0; JCODE="rsci"; LTYPE="EJOURNAL" ;;
    rvmp | RvMP | RVMP ) APS=1; LYNX=1;HREFTYPE=1;JCODE="rvmp";LTYPE="EJOURNAL" ;;
    science | SCIENCE ) HREFTYPE=1;JCODE="science";LTYPE="ARTICLE" ;;
    scoa | SCoA| SCOA )  HREFTYPE=1;JCODE="scoa";LTYPE="ARTICLE" ;;
    va | VA | ViA | via)  if [ "$RETRYflag" ];then LYNX=1; fi; SD=1;HREFTYPE=0; JCODE="va"; LTYPE="EJOURNAL" ;;
    zphy | ZPhy| ZPHY )  LYNX=1;HREFTYPE=1;JCODE="zphy";LTYPE="EJOURNAL" ;;
    zphya | ZPhyA| ZPHYA )  LYNX=1;HREFTYPE=1;JCODE="zphya";LTYPE="EJOURNAL" ;;
    * ) 
      printf "ERROR: Journal code $JOURNAL not in database, skipping...\n"
      Error
      JournalList
      continue
      ;;
    esac
}

# Delete any and all temporary files
# TODO: Array
function TmpCleanUp () {
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
  if [ -e $TMPFILENAME ];then
    rm "$TMPFILENAME"
  fi
  if [ -e $ERRORFILE ];then
    rm "$ERRORFILE"
  fi
  if [ -e $LYNXCMD ];then
    rm "$LYNXCMD"
  fi
  if [ -e $LYNXCFG ];then
    rm "$LYNXCFG"
  fi
}

# TODO: Broken?  Check it and fix if so
function ParseJVP () { # Parse the Journal/Volume/Page of submission
  JOURNAL=`printf "$inline"|awk '{printf $1}'`
  VOLUME=`printf "$inline"|awk '{printf $2}'`
  PAGE=`printf "$inline"|awk '{printf $3}'`
  # FIX ME 15 Aug 2012 13:59:17 
  if [ "$fflag" ];then
    COMMENTS=$(printf "$inline" | awk '{
  	                    for (i=1;i<=NF;i++)
  	                       {
  	                       if ( i > 3 )
  	                          printf("%s ",$i)
  	                       }
  	                    }')
  else # TODO: broken for now!  It uses inline instead of user input...how to fix it?
    COMMENTS="$cval"
  fi
  if [ "$Pflag" ]; then
    COMMENTS="Printed: $COMMENTS"
  else
    COMMENTS="Unprinted: $COMMENTS"
  fi
  printf "Processing: JOURNAL $JOURNAL VOLUME $VOLUME PAGE $PAGE\n"
}

# Download the Bibtex from Harvard's wonderful ADS
function FetchBibtex() { 
  CHOICE=0
  if ( echo "$JOURNAL" | grep -qE "$FALSEPAGE" && [[ $RETRYflag -eq 1 ]] ); then
    printf "Changing PAGE from $PAGE "
    PAGE=$(echo "$PAGE" | sed 's/[0-9][0-9]//')
    printf "to $PAGE.\n"
  fi
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
    SELECTED=`grep "Total number selected" $TMPBIBCODE | sed 's/.*selected://' | sed 's/\ <strong>//' | sed 's$</strong>.*$$'`
    echo "Found $SELECTED entries that match query..."
  else
    SELECTED=1
  fi
  i="1"
  while [ $i -le $SELECTED  ]
  do
    ADSURL="http://adsabs.harvard.edu/cgi-bin/nph-abs_connect?version=1&warnings=YES&partial_bibcd=YES&sort=BIBCODE&db_key=ALL&bibstem=$JCODE&volume=$VOLUME&page=$PAGE&nr_to_return=1&start_nr=$i"
    echo "Getting BIBCODE from $ADSURL"
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
      ZENCMD='zenity  --title "getpaper" --list  --text "Multiple hits.  The following matching entires were found:" --radiolist  --column "" --column "Key" --column "Paper Title"'
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
  # 28 Nov 2016 20:28:59 the first new run often complains here without the if
  if [ -e $TMPBIBCODELIST ];then
  # TODO: why are we doing this?
    rm $TMPBIBCODELIST
  fi
  echo "Processing $BIBCODE..."
  if [ -z $BIBCODE ];then
    printf "No BIBCODE could be found!\n"
    Error
    return #continue
  else
    echo "$JOURNAL $VOLUME $PAGE is a valid reference"
  fi
  YEAR=`echo "$BIBCODE" | head -c 4`
  if ( grep "$BIBCODE" "$BIBFILE" > /dev/null ); then
    echo "The article $BIBCODE is in your library!"
    if [ ! "$qflag" ];then
      echo "$BIBFILE"
      echo "Skipping..."
      # return either a filename or the end of the entry '}' whichever is first
      FILENAME=$(grep -A 50 "$BIBCODE" "$BIBFILE" | grep -i -E -m 1 "File|^}$" | sed 's/.*{://' | sed 's/:PDF.*//')
      if [ "$Oflag" ]; then
      	if ( echo $FILENAME | grep -i "pdf" ); then
      		Open
      	else
      		echo "Digital version is not in your library or not a pdf...cannot open!"
      	fi
      fi
      return 1 # continue
    fi
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
    return #continue
  fi
}

# Creation of a script for lynx
# This is a workaround for any hosts that attempt to deny wget
function MakeLynxCmd () {
  if [ -e $LYNXCMD ];then
  	rm "$LYNXCMD"
  fi
  # this enters lynx search mode
  echo "key /" >> "$LYNXCMD"  
  # search for 'PDF'
  echo "key P" >> "$LYNXCMD"  
  echo "key D" >> "$LYNXCMD"  
  echo "key F" >> "$LYNXCMD"  
  echo "key ^J" >> "$LYNXCMD" 
  if [[ $SD -eq 1 ]];then
    echo "key ^J" >> "$LYNXCMD"
  fi
  # hack for APS because clicking Einstein is bullshit
  if [[ $APS -eq 1 && $RETRYflag -eq 1 ]];then
    echo "key ^J" >> "$LYNXCMD" 
    # run a command defined in /etc/lynx.cfg!
    echo "key ," >> "$LYNXCMD"
  else
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
  fi	  
}

# This function deals with the requirement of APS to click on Einstein's picture
# The user will still need to fulfill the condition of recognizing Einstein
# This function allows the user to do that
# It has lynx use a customized configuration file which enables a command for lynx
#   to call an external program (it will re-invoke getpaper --apscaptcha)
# getpaper --apscaptcha 
#   modifies LYNXCMD on-the-fly while lynx is open to download all 8 pictures
#   Uses ImageMagick's convert tool to put all 8 images into one, with numbers
#   Gets the user's input via zenity to tell which number was Einstein
#   Then getpaper can operate normally, by selecting the correct link to download
function APSTmpCleanUp () {
  # TODO: please improve this one 28 Nov 2016 17:59:39 
  for i in $( ls "$TMP"/getpaper*.jpg ); do
    if [ -e $i ];then
      rm -f $i
    fi  
  done
}

function APSHack (){
  sleep 1
  APSTmpCleanUp
  LYNXTMPDIR=$(ls -dat /tmp/*/ | grep lynx | head -n 1)
  # TODO: Don't start grepping my motherfucking home directory...
  # make sure LYNXTMPDIR isn't empty
  LYNXTMPFILE=$(grep -l "Verification Required" $LYNXTMPDIR*)
  APSIMGNUM=0
  cat "$LYNXTMPFILE" | sed 's/>/>\n/g' | grep captcha | sed 's/.*src="//' | sed 's/".*//' | grep captcha | sed 's$/captcha$http://journals.aps.org/captcha$' | while read line; do let "APSIMGNUM += 1"; wget -O $TMP/getpaper"$APSIMGNUM".jpg "$line"; done
  
  # see the ImageMagick solution for some of my inspiration here:
  # http://codegolf.stackexchange.com/questions/98968/go-out-and-vote
  convert $TMP/getpaper1.jpg $TMP/getpaper2.jpg $TMP/getpaper3.jpg $TMP/getpaper4.jpg $TMP/getpaper5.jpg $TMP/getpaper6.jpg $TMP/getpaper7.jpg $TMP/getpaper8.jpg +append \
    canvas:white[873x40!] -append \
    -fill white -pointsize 80 -draw 'text 10,80   " 1   2   3   4   5   6   7   8"' \
    -fill black -pointsize 80 -draw 'text 8,78   " 1   2   3   4   5   6   7   8"' \
    -fill black  -pointsize 20 -draw 'text 40,130   "Note to yourself which number is Einstein or Curie and press Esc or close the window."' \
    show:
    EINSTEIN=$(zenity --entry --title="getpaper APS hack" --text="Which number was the physicist?")
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
  let EINSTEIN=EINSTEIN-1
  if [[ $EINSTEIN -ne 0 ]];then
    COUNTER=0
    while [  $COUNTER -lt $EINSTEIN ]; do
      let COUNTER=COUNTER+1
      echo "key Down Arrow" >> "$LYNXCMD"
    done
  fi
  
  FILENAME=$(cat $TMPFILENAME)
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
  APSTmpCleanUp
}

# Download the paper
# This is a major work of the script
# Different databases have different formats
# Many of them don't like scripting even if it in no way violates the TOS
# I apologize for all the cludges and exceptions required for smooth operation
function DownloadPdf () {
  if [ -e $FILEPATH/$FILENAME ];then
    echo "The paper is already downloaded!"
    echo "$FILEPATH/$FILENAME"
    if [ "$Oflag" ]; then
      Open
    fi
    echo "Skipping..."
    return 1 #continue
  fi
  ADSLINK="http://adsabs.harvard.edu/cgi-bin/nph-data_query?bibcode=$BIBCODE&link_type=$LTYPE&db_key=ALL"
  echo "$ADSLINK"
  printf "Determining URL path for PDF...\n"
  if [ $LTYPE = "ARTICLE" ]; then
    FULLPATH="$ADSLINK" 
  elif [ $LTYPE = "EJOURNAL" ]; then
    if [ -e $TMPURL ];then
      rm "$TMPURL"
    fi
    #	#read_timeout is a newer feature many systems don't seem to have...added to lynx 2.8.7 2009.7.5
    
    #	They use JavaScript to generate a redirect, since command-line browsers cannot do JS
    #	Once we get the source from ADS, we can nab the redirect URL from a lynx source dump
    #       Then, magically, a slight hack on the original way works again
    lynx -source -connect_timeout=20 -useragent="$AGENT" "$ADSLINK" > $TMPURL
    # holy fuck I hate SD sOooOooOooooooooOOOOOOO much 13 Jan 2016 15:13:17 
    if   [ "$SD" ];then
      # SD tries again to use javascript redirect which borks lynx..eat this hack you fucksi
      ADSLINK=$(grep 'name="redirectURL"' $TMPURL | sed 's/.*value="//' | sed 's/".*//' | sed 's$%3A$:$g' | sed 's$%2F$/$g'| sed 's$%3F.*$$')
      echo "Rebasing $TMPURL for SD JavaScript redirect..."
      lynx -source -connect_timeout=20 -useragent="$AGENT" "$ADSLINK" > $TMPURL
    fi
    if [[ $HREFTYPE -eq 0 ]];then
    ##if [[ $HREFTYPE -eq 0 && $SD -eq 0 ]];then
      #full paths given for href
      BASEURL=""
      #2g in BSD sed gives: sed: more than one number or 'g' in substitute flags
      #LOCALPDF=`grep PDF $TMPURL | sed 's/[Hh][Rr][Ee][Ff]//2g' | sed  's/.*[Hh][Rr][Ee][Ff]=\"//' | sed 's/\".*//' | head -n 1`
      #emulate 2g as sed, where goat is regex: sed ':a;s/\([^ ]*goat.*[^\\]\)goat\(.*\)/\1replace\2/;ta'
      LOCALPDF=$(grep -A 1 "article-download-switch" $TMPURL | \
        tail -n 1 | sed  's/.*[Hh][Rr][Ee][Ff]=\"//' | \
        sed 's/\".*//' | sed 's/%0D//' | head -n 1 | sed 's$//$http://$' )
      LOCALPDF=`grep pdfurl $TMPURL | \
        head -n 1 | sed 's/.*pdfurl=\"//' | sed 's/\".*//'`
      if [ "$LOCALPDF" == "" ];then # previous command did not grab a URL, try another way (this was for AIP but now SD)
      # last bit was for non-conforming url beginning //www e.g. it is a HREF 0.5 level (includes base url but not http but has //
      # LOCALPDF=`grep "Download PDF" $TMPURL |  \
      # LOCALPDF=`grep "Download full text in PDF" $TMPURL |  \
        #LOCALPDF=`grep "Download [full text in PDF|PDF]" $TMPURL |  \
        #sed ':a;s/\([^ ]*[Hh][Rr][Ee][Ff].*[^\\]\)[Hh][Rr][Ee][Ff]\(.*\)/\1\2/;ta' | \
        #sed  's/.*[Hh][Rr][Ee][Ff]=\"//' | sed 's/\".*//' | sed 's/%0D//' | head -n 1`
	LOCALPDF=$(grep "citation_pdf_url" $TMPURL | sed 's/.*content="//' | sed 's/".*//' | sed 's/\&amp;/\&/g' )
	if ( echo "$LOCALPDF" | grep -q "www" );then
          touch $TMPURL # useless
        else
        #hacks
          LOCALPDF="www.sciencedirect.com""$LOCALPDF"
        fi
        echo "Rebasing $LOCALPDF for SD JavaScript redirect..."
        lynx -source -connect_timeout=20 -useragent="$AGENT" "$LOCALPDF" > $TMPURL
	LOCALPDF=$(grep "Refresh" $TMPURL | sed 's/.*URL=//' | sed 's/".*//')
      fi
    fi
    if [[ $HREFTYPE -eq 1 && $LYNX -eq 0 ]];then # we should really make a flag for if wget is used...we don't need this if we use lynx
      #domain omitted for href
      BASEURL=`head -n 1 $TMPURL | sed 's/.*X-URL:\ //'|  sed 's,\(http://[^/]*\)/.*,\1,' | sed 's/\r$//'`
      if [ $NATURE -eq 1 ];then
        BASEURL="http://www.nature.com"
      fi
      LOCALPDF=`grep PDF $TMPURL | \
        sed ':a;s/\([^ ]*[Hh][Rr][Ee][Ff].*[^\\]\)[Hh][Rr][Ee][Ff]\(.*\)/\1\2/;ta' | \
          sed  's/.*[Hh][Rr][Ee][Ff]=\"//' | sed 's/\".*//'| sed 's/\r$//' | head -n 1`
    fi
    if [ $HREFTYPE -eq 2 ];then
      #totally local href
      BASEURL=`head -n 1 $TMPURL | sed 's/.*X-URL:\ //'|  sed 's/\(.*\)\/.*/\1\//'`
      LOCALPDF=`grep PDF $TMPURL | \
        sed ':a;s/\([^ ]*[Hh][Rr][Ee][Ff].*[^\\]\)[Hh][Rr][Ee][Ff]\(.*\)/\1\2/;ta' | \
        sed  's/.*[Hh][Rr][Ee][Ff]=\"//' | sed 's/\".*//' | head -n 1`
    fi
    FULLPATH="$BASEURL$LOCALPDF"
  fi
  # TODO: if not lynx, do this.  if lynx, let them know we are using lynx on some URL and please wait
  printf "Downloading PDF from $FULLPATH ...\n"
  if [ $GUI -eq 1 ];then
    if [ "$Rflag" ];then # Remote flag is on
      if [ $NATURE -eq 0 ];then
        ssh "$USER@$HOST" wget -U "$AGENT" --progress=bar:force "$FULLPATH" -O"$TMP/$FILENAME" 2>&1 | (zenity --title "getpaper" --text "Downloading..." --progress --auto-close --auto-kill)
      elif [ $NATURE -eq 1 ];then
        ssh "$USER@$HOST" wget --header='Accept-Language: en-us,en' --progress=bar:force "$FULLPATH" -O"$TMP/$FILENAME" 2>&1 | (zenity --title "getpaper" --text "Downloading..." --progress --auto-close --auto-kill)
      fi
      # Remote flag is off
      if [ $NATURE -eq 0 ];then
        wget -U "$AGENT" --progress=bar:force "$FULLPATH" -O"$TMP/$FILENAME" 2>&1 | (zenity --title "getpaper" --text "Downloading..." --progress --auto-close --auto-kill)
      elif [ $NATURE -eq 1 ];then
        wget --header='Accept-Language: en-us,en' --progress=bar:force "$FULLPATH" -O"$TMP/$FILENAME" 2>&1 | (zenity --title "getpaper" --text "Downloading..." --progress --auto-close --auto-kill)
      fi
    fi
  else
    if [ "$Rflag" ]; then # Remote flag is on
      # the remote shell will be confused by & in a URL, so we need to make it a literal
      FULLPATH=`echo $FULLPATH | sed 's/\&/\\\&/g'`
      if [[ "$LYNX" ]]; then
        MakeLynxCmd
        echo "Copying lynx command to the ssh host..."
        scp "$LYNXCMD" "$USER@$HOST:$LYNXCMD"
        ADSLINK=`echo $ADSLINK | sed 's/\&/\\\&/g'`
        echo "$ADSLINK"
        ssh "$USER@$HOST" lynx -accept_all_cookies -cmd_script="$LYNXCMD" "$ADSLINK"
      else
        if [ $NATURE -eq 0 ];then
          ssh "$USER@$HOST" wget -U "$AGENT" -O "$TMP/$FILENAME" "$FULLPATH" # works
        elif [ $NATURE -eq 1 ];then
          #500 Internal Server Error avoided
          ssh "$USER@$HOST" wget --header='Accept-Language: en-us,en' -O "$TMP/$FILENAME" "$FULLPATH" # works
        fi
      fi
    else # Remote flag is off
      if [[ "$LYNX" ]]; then 
        MakeLynxCmd
        if [[ "$APS" && "$RETRYflag" ]];then
          printf ".h1 Internal Behavior\n.h2 SOURCE_CACHE\nSOURCE_CACHE:FILE\n.h1 External Programs\n.h2 EXTERNAL\nEXTERNAL:http:$GETPAPERPATH --apscaptcha:TRUE" > "$LYNXCFG"
          lynx -accept_all_cookies -cmd_script="$LYNXCMD" -cfg="$LYNXCFG" "$ADSLINK" > /dev/null
        else
          lynx -useragent="$AGENT" -accept_all_cookies -cmd_script="$LYNXCMD" "$ADSLINK" > /dev/null
        fi
      else
        if [ $NATURE -eq 0 ];then
          wget --header='Accept-Language: en-us,en' -U "$AGENT" -O"$TMP/$FILENAME" "$FULLPATH"
        elif [ $NATURE -eq 1 ];then
          wget --header='Accept-Language: en-us,en' -U "$AGENT" -O"$TMP/$FILENAME" $FULLPATH
        fi
      fi
    fi
  fi
}

# Add a bibtex entry to the local library
function AddBibtex () {
  while read -r line
  do
    if ( echo $line | grep "adsurl = " > /dev/null );then
      echo "$line" >> "$BIBFILE"
      if [ -z $bflag ];then # Only do these things without the c(heck) flag and b(ibtex) flag
      	echo "file = {:$LIBPATH/$PAPERTYPE/$YEAR/$FILENAME:PDF}," >> "$BIBFILE"
      fi
      echo "comment = {$COMMENTS}," >> "$BIBFILE"				    
    else
      echo "$line" >> "$BIBFILE"
    fi
  done < $TMPBIBTEX
}

# Check the directory structure where we will keep the paper 
# If it does not exist, recursively make the directories
function CheckDir () { 
  if [ ! -d "$LIBPATH/$PAPERTYPE" ];then
    mkdir "$LIBPATH/$PAPERTYPE"
    printf "Made directory $LIBPATH/$PAPERTYPE\n"
  fi
  if [ ! -d "$LIBPATH/$PAPERTYPE/$YEAR" ];then
    mkdir "$LIBPATH/$PAPERTYPE/$YEAR"
    printf "Made directory $LIBPATH/$PAPERTYPE/$YEAR\n" 
  fi
}

# Some journals attach a header page with journal information, IP address etc
# This is propaganda and not the academic content of interest
# The function will strip the first page from the PDF file
function StripPropaganda () { 
  echo "Stripping propaganda and IP information from pdf file..."
  cp -v "$TMP/$FILENAME" "$TMP/.getpaper_pdftk_in.pdf"
  pdftk "$TMP/.getpaper_pdftk_in.pdf" cat 2-end output "$TMP/.getpaper_pdftk_out.pdf"
  cp -v "$TMP/.getpaper_pdftk_out.pdf" "$TMP/$FILENAME"
}

# Merely open a PDF file
function Open () {
  $PDFVIEWER $FILEPATH/$FILENAME &
}

# Simply spool the PDF file to a printer
# TODO: we should make some check on the number of pages to confirm.  20 is probably reasonable
function Print () {
  printf "Printing...\n"
  $PRINTCOMMAND $FILEPATH/$FILENAME
}

# Report any and all errors in download
function ErrorReport() { 
  if [ $ERROR -eq 1 ];then
    printf "***********************************************\n"
    printf "The following submission(s) failed to download:\n"
    printf "JOURNAL\tVOLUME\tPAGE\n"
    cat $ERRORFILE
    printf "***********************************************\n"
    if [[ $RETRYflag -eq 0 ]];then
      #if ( (echo "$JOURNAL" | grep -qE "$FALSEPAGE" )  );then
      if ( ( [[ $SD -eq 1 || $APS -eq 1 ]] || echo "$JOURNAL" | grep -qE "$FALSEPAGE" ) && [[ $RETRYflag -eq 0 ]] );then
      #if ( echo "$JOURNAL" | grep -q "$FALSEPAGE" && [[ $RETRYflag -eq 1 ]] ); then
      printf "\nI see there was a problem, but let me try something else.\n"
      #	NIM A&B (and other SD as well?) need LYNX=1 for older articles, but not LYNX for newer
      #		1996 -> 'old' ; 2002 -> 'new'
      #		old one is usually scanned and not very good quality as well
      # As to APS, some are open access journals, so we don't need the captcha in those cases
      if [[ $SD -eq 1 ]]; then
        printf "\nThis is ScienceDirect and an older article so attempting via lynx...\n\n"
      fi
      if [[ $APS -eq 1 ]]; then
        printf "\nThis is APS, so it must not be an open access article.  I'll try again and give you the captcha...\n\n"
      fi
      if ( echo "$JOURNAL" | grep -qE "$FALSEPAGE" ); then
        printf "\nThis is $JOURNAL and sometimes the two preceeding numbers of the page are not used by ADS.  I'll try again by modifying that...\n\n"
      fi
      echo "Calling $0 $FLAGS --retry"
      $0 $FLAGS --retry
      fi
    fi
  fi
}

# Confirm downloaded item is in fact a PDF
function IsPdfValid () { 
  printf "Checking if PDF appears to be valid...\n"
  if ( pdfinfo $TMP/"$FILENAME" 2>&1 | grep "Error: May not be a PDF file\|Syntax Warning: May not be a PDF file (continuing anyway)\|No such file or directory" > /dev/null );then
    printf "Error in downloading the PDF\nMaybe you do not have access\nTerminating...\n"
    printf "If you confirm the citation information, and the paper is also in ADS, check for a new version of getpaper:\n"
    printf "\thttps://github.com/goatface/getpaper\n"
    printf "\t(Many repositories are frequently changing their link structure.)\n"
    rm -vf $TMP/$FILENAME
    Error
    return #continue
  fi
}

# A primative GUI in alpha testing mode
function GUI () {
  jval=$(zenity  --width=400  --height=703 --title "getpaper" --list  --text "Choose a journal" --radiolist  --column "" --column "Code" --column "Publication Title"  \
    FALSE aa "Astronomy & Astrophysics" \
    FALSE aipc "American Institute of Physics (Conference Proceedings)" \
    FALSE aj "The Astronomical Journal" \
    FALSE astl "Astronomy Letters" \
    FALSE anap "Annales d Astrophysique" \
    FALSE apj "The Astrophysical Journal" \
    FALSE apjl "The Astrophysical Journal (Letters)" \
    FALSE apjs "The Astrophysical Journal (Supplement Series)" \
    FALSE arnps "Annual Review of Nuclear and Particle Science" \
    FALSE aujph "Australian Journal of Physics" \
    FALSE baas "Bulletin of the American Astronomical Society" \
    FALSE bsrsl "Bulletin de la Societe Royale des Sciences de Liege" \
    FALSE epja "European Physical Journal A" \
    FALSE epjas "European Physical Journal A Supplement" \
    FALSE epjb "European Physical Journal B" \
    FALSE epjc "European Physical Journal C" \
    FALSE epjd "European Physical Journal D" \
    FALSE epje "European Physical Journal E" \
    FALSE epjst "European Physical Journal ST" \
    FALSE epjh "European Physical Journal H" \
    FALSE epjwc "European Physical Journal Web of Conferences" \
    FALSE gecoa "Geochimica et Cosmochimica Acta" \
    FALSE jphcs "Journal of Physics Conference Series" \
    FALSE jphg "Journal of Physics G: Nuclear and Particle Physics" \
    FALSE jpsj "Journal of the Physical Society of Japan" \
    FALSE mnras "Monthly Notices of the Royal Astronomical Society" \
    FALSE msrsl "Memoires of the Societe Royale des Sciences de Liege" \
    FALSE metro "Metrologia" \
    FALSE natur "Nature" \
    FALSE natph "Nature Physics" \
    FALSE newar "New Astronomy Reviews" \
    FALSE nimpa "Nuclear Instruments and Methods (1983 and earlier)" \
    FALSE nimpa "Nuclear Instruments and Methods in Physics Research A" \
    FALSE nimpb "Nuclear Instruments and Methods in Physics Research B" \
    FALSE nupha "Nuclear Physics A" \
    FALSE nuphb "Nuclear Physics B" \
    FALSE nuphs "Nuclear Physics Supplement" \
    FALSE obs "The Observatory" \
    FALSE paphs "Proceedings of the American Philosophical Society" \
    FALSE pasa "Publications of the Astronomical Society of Australia" \
    FALSE pasj "Publications of the Astronomical Society of Japan" \
    FALSE pasp "Publications of the Astronomical Society of the Pacific" \
    FALSE phrv "Physical Review" \
    FALSE pce "Physics and Chemistry of the Earth" \
    FALSE pmag "Philosophical Magazine" \
    FALSE ppsa "Proceedings of the Physical Society A" \
    FALSE ppsb "Proceedings of the Physical Society B" \
    FALSE pos "Proceedings of Science" \
    FALSE pra "Physical Review A" \
    FALSE prb "Physical Review B" \
    FALSE prc "Physical Review C" \
    FALSE prd "Physical Review D" \
    FALSE pre "Physical Review E" \
    FALSE phlb "Physics Letters B" \
    FALSE prl "Physical Review Letters" \
    FALSE prpnp "Progress in Particle and Nuclear Physics" \
    FALSE pthph "Progress of Theoretical Physics" \
    FALSE pthps "Progress of Theoretical Physics Supplement" \
    FALSE rsci "Review of Scientific Instruments" \
    FALSE rvmp "Reviews of Modern Physics" \
    FALSE science "Science" \
    FALSE scoa "Smithsonian Contributions to Astrophysics" \
    FALSE va "Vistas in Astronomy" \
    FALSE zphy "Zeitschrift fur Physik" \
    FALSE zphya "Zeitschrift fur Physik A" \
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
# Main 
InitVariables
GetOpts $*
CheckDeps
if [[ "$APSflag" ]] ; then
  APSHack
  exit
fi
TmpCleanUp
if [ -z $1 ];then
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
    VOLUME="$vval"
  else
    printf "No volume given!\nSkipping...\n"
    Error
    exit 1
  fi
  if [ "$pflag" ] ; then
    PAGE="$pval"
  else
    printf "No page given!\nSkipping...\n"
    Error
    exit 1
  fi
  printf "$JOURNAL\t$VOLUME\t$PAGE\n" > "$INPUT"
fi

# Basic execution of the script
exec 3<&0 # stdin redirect for use in while read 
while read inline
do
  ParseJVP
  SetJournal
  FetchBibtex
  STATUS="$?"
  if [[ $ERROR -eq 1 || $STATUS -eq 1 ]];then 
    continue
  fi
  # TODO: Should get these dynamically from existing bibtex, in the case of --query...
  FILEPATH="$LIBPATH/$PAPERTYPE/$YEAR"
  FILENAME="$JOURNAL.$VOLUME.$PAGE.pdf"
  #if [[ $CHOICE -eq 0 ]];then
  #  FILENAME="$JOURNAL.$VOLUME.$PAGE.pdf"
  #else
  #  FILENAME="$JOURNAL.$VOLUME.$PAGE"_"$CHOICE.pdf"
  #fi
  echo "$FILENAME" > $TMPFILENAME
  if [[ -z $qflag  && -z $bflag ]];then # Only do these things without the q(uery) flag and b(ibtex) flag
    DownloadPdf
    STATUS="$?"
    if [[ $ERROR -eq 1 || $STATUS -eq 1 ]];then 
      continue
    fi
    if [ "$Rval" ];then
      printf "scp'ing downloaded PDF from temporary location on remote server: "
      scp "$USER@$HOST:/$TMP/$FILENAME" "$TMP/$FILENAME"
      echo "Removing the tmp file on the ssh host..."
      ssh "$USER@$HOST" rm -v "$TMP/$FILENAME"
    fi
    IsPdfValid 
    if [ $ERROR -eq 1 ];then
      continue
    fi
    CheckDir
    if [ $PROPAGANDA -eq 1 ];then
      StripPropaganda
    fi
    printf "Moving downloaded PDF from temporary location: "
    mv -v "$TMP/$FILENAME" "$FILEPATH/$FILENAME"
  fi
  if [ -z $qflag ];then # Only do these things without the q(uery) flag
    AddBibtex
  fi
  if [ -z $bflag ];then # Only do these things without the b(ibtex) flag
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
  fi
done < "$INPUT"
ErrorReport
TmpCleanUp
