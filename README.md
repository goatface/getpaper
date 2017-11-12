# getpaper
For a complete description, see [my hompage](http://www.cns.s.u-tokyo.ac.jp/~daid/hack/getpaper.html).  However, the code hosted here is significantly improved.

## Functionality

Download, add bibtex, query bibtex, strip propaganda, print, and/or open papers based on reference!

Here, _papers_ are academic journal articles, usually somehow related to nuclear astrophysics, which is my interest.  It mainly relies on the [SAO/NASA Astrophysics Data System (ADS)](http://adsabs.harvard.edu/) and would typically take queries following the Journal/Volume/Page format.  In a full blown operation, here is what happens: 
* You feed `getpaper` some options, including a journal name, a volume, and a page number
* `getpaper` checks if ADS has a matching query (and if there are multiple returns, prompts you to choose one)
* `getpaper` checks if you have a matching bibkey in your library.bib file, so as not to duplicate
* `getpaper` checks the expected output PDF file name, so as not to download for no reason
* If it was instructed to open the paper, it would open the paper you already had but forgot you downloaded
* Finding that you do not have this paper, it will generate a full bibtex entry, including the abstract
* `getpaper` will download the paper (if you have subscription access)
* `getpaper` can let you handle captchas at APS
* `getpaper` will ensure that what was downloaded looks like a legitimate PDF and not rubbish
* `getpaper` will strip the first page of the PDF if it's nonsense about the online journal with your IP address
* `getpaper` will link the downloaded location of the paper into the bibtex entry
* `getpaper` will create a sensible directory structure like articles/2013 to place the paper if needed
* `getpaper` will open the paper if you asked it to
* `getpaper` will print the paper if you asked it to (please have an idea of the page length first!)

If you didn't have subscription access, perhaps because you are at home or travelling...
* `getpaper` can accept an SSH user and host to a machine at your work, and use that server to transparently download and transfer the paper to your local machine (though you should set up passwordless SSH and ensure your work machine has the right tools).  However, I have been unable to test or bugcheck this option for several years owing to firewalls.  Thus you can expect particularly APS journals would not work at the very least.

**And it will do all that, with a simple, single command.**  That could save you at least sixty seconds doing it yourself!

What it will **not** do:
* Harvest papers blindly.  You need to feed it the relevant Journal/Volume/Page information yourself.  This is to comply with the online journals' TOS.  It keeps you from clicking the mouse, not from never connecting to the internet ever again by downloading the Library of Alexandria.

You probably want to be using [JabRef](http://jabref.sourceforge.net/) to manage your library.bib file.  It's awesome...

## How to 'install'

`getpaper` is just a single shell script.  While it needs a run configuration file, it will initialize one for you the first time you run it.  Many of the features are possible owing to lovely free software.  Although `getpaper` checks for the dependencies it requires itself, here is a list with a brief description:

* [lynx](https://lynx.browser.org/): A scriptable, command-line driven web browser.
* [wget](http://www.gnu.org/software/wget/): A non-interactive downloading tool.
* [pdfinfo](https://poppler.freedesktop.org/): Part of poppler or xpdf, `getpaper` uses this to validate a download as being a pdf.
* [pdftk](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/): 
* [imagemagick](https://www.imagemagick.org): A versatile image tool, it is used for the APS Captcha rendering.
* [zenity](https://help.gnome.org/users/zenity/stable/): A pop-up tool handy for simple GUIs in shell scripts.

It also requires the common system tools: [grep](https://www.gnu.org/software/grep/), [sed](https://www.gnu.org/software/grep/), and [awk](https://www.gnu.org/software/gawk/).
