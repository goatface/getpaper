##getpaper
For a complete description, see [my hompage](http://www.cns.s.u-tokyo.ac.jp/~daid/hack/getpaper.html).

Download, add bibtex, query bibtex, strip propaganda, print, and/or open papers based on reference!

Here, _papers_ are academic journal articles, usually somehow related to nuclear astrophysics, which is my interest.  It mainly relies on the [SAO/NASA Astrophysics Data System (ADS)](http://adsabs.harvard.edu/) and would typically take queries following the Journal/Volume/Page format.  In a full blown operation, here is what happens: 
* You feed `getpaper` some options, including a journal name, a volume, and a page number
* `getpaper` checks if ADS has a matching query (and if there are multiple returns, prompts you to choose one)
* `getpaper` checks if you have a matching bibkey in your library.bib file, so as not to duplicate
* `getpaper` checks the expected output PDF file name, so as not to download for no reason
* If it was instructed to open the paper, it would open the paper you already had but forgot you downloaded
* Finding that you do not have this paper, it will generate a full bibtex entry, including the abstract
* `getpaper` will download the paper (if you have subscription access)
* `getpaper` will ensure that what was downloaded looks like a legitimate PDF and not rubbish
* `getpaper` will strip the first page of the PDF if it's nonsense about the online journal with your IP address
* `getpaper` will link the downloaded location of the paper into the bibtex entry
* `getpaper` will create a sensible directory structure like articles/2013 to place the paper if needed
* `getpaper` will open the paper if you asked it to 
* `getpaper` will print the paper if you asked it to 

If you didn't have subscription access, perhaps because you are at home or travelling...
* `getpaper` can accept an SSH user and host to a machine at your work, and use that server to transparently download and transfer the paper to your local machine (though you should set up passwordless SSH and ensure your work machine has the right tools).

**And it will do all that, with a simple, single command.**  That could save you at least sixty seconds doing it yourself!

What it will **not** do:
* Harvest papers blindly.  You need to feed it the relevant Journal/Volume/Page information yourself.  This is to comply with the online journals' TOS.  It keeps you from clicking the mouse, not from never connecting to the internet ever again by downloading the Library of Alexandria.

You probably want to be using [JabRef](http://jabref.sourceforge.net/) to manage your library.bib file.  It's awesome...

For APS hacks, we need to edit lynx.cfg for the comma commmand (apshacks.sh) and SOURCE_CACHE to be FILE

##Other notes

Full port of project from http://www.cns.s.u-tokyo.ac.jp/~daid/hack/getpaper.html including version history.

