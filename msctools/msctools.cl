#{ MSCTOOLS -- Mosaic Tools Package

# Load dependent packages.
tv
utilities
proto
nproto
astutil
digiphot
apphot
photcal
astcat

# This package requires FITS image type and various kernel parameters.
reset imtype = "fits"
if (defvar ("fkinit"))
    set fkinit = envget ("fkinit") // ",append,padlines=10,cachesize=60"
else
    set fkinit = "append,padlines=10,cachesize=60"


package msctools

# Tasks.

task	mscextract	= mscsrc$mscextract.cl
task	mscmedian	= mscsrc$mscmedian.cl
task	msctmp1		= mscsrc$msctmp1.cl
task	mscfindgain	= mscsrc$mscfindgain.cl
task	mscsplit	= mscsrc$mscsplit.cl
task	mscjoin		= mscsrc$mscjoin.cl
task	mscwfits	= mscsrc$mscwfits.cl
task	mscrfits	= mscsrc$mscrfits.cl
task	msctoshort	= mscsrc$msctoshort.cl
task	dispsnap	= mscsrc$dispsnap.cl

task	mscgetcatalog	= mscsrc$mscgetcatalog.cl
task	mscagetcat	= mscsrc$mscagetcat.cl
task	mscsetwcs	= mscsrc$mscsetwcs.cl
task	msczero		= mscsrc$msczero.cl
task	mscxreg		= mscsrc$mscxreg.cl
task	mscimage	= mscsrc$mscimage.cl
task	mscoimage	= mscsrc$mscoimage.cl
task	msccmd		= mscsrc$msccmd.cl
task	mscedit		= mscsrc$mscedit.cl
task	mscselect	= mscsrc$mscselect.cl
task	mscheader	= mscsrc$mscheader.cl
task	mscarith	= mscsrc$mscarith.cl
task	mscstat		= mscsrc$mscstat.cl
task	mscblkavg	= mscsrc$mscblkavg.cl
task	mscpixarea	= mscsrc$mscpixarea.cl
task	mscpixscale	= mscsrc$mscpixscale.cl
task	mscqphot	= mscsrc$mscqphot.cl
task	msccntr		= mscsrc$msccntr.cl
task	mscshutcor	= mscsrc$mscshutcor.cl

task	addkey,
	fitscopy,
	getcatalog,
	joinlists,
	mkmsc,
	msccmatch,
	mscctran,
	mscextensions,
	mscgmask,
	mscimatch,
	mscpmask,
	mscskysub,
	msctemplate,
	mscwtemplate,
	mscwcs,
	mscuniq,
	patfit,
	pixarea,
	pixscale,
	toshort,
	ximstat,
	xlog		= mscsrc$x_msctools.e

task	aimexpr,
	mskmerge	= "nfextern$src/proctool/x_proctool.e"

# Photometry parameters.
#task	msccpars	= mscsrc$msccpars.par
#task	mscdpars	= mscsrc$mscdpars.par
#task	mscppars	= mscsrc$mscppars.par
#task	mscspars	= mscsrc$mscspars.par

hidetask ximstat, joinlists, mscoimage, msccntr
hidetask addkey, fitscopy, getcatalog
hidetask mscgmask, mscpmask, msctemplate, mscwtemplate
hidetask mscxreg, mscuniq
hidetask patfit, toshort, xlog
#hidetask msccpars, mscdpars, mscppars, mscspars
hidetask dispsnap, mscqphot, pixscale, pixarea, msctmp1

# Special version of utilities.curfit
task	msccurfit	= "mscsrc$curfit/x_msctools.e"
hidetask msccurfit

# Display stuff.

#task	newdisplay = "mscsrc$display/x_display.e"

task	msctvmark	= "mscsrc$msctvmark.cl"
task	mscztvmark	= "mscsrc$mscztvmark.cl"

set	mscdisplay	= "mscsrc$mscdisplay/"
set	mosexam		= "mscdisplay$src/imexam/"
set	starfocus	= "mscdisplay$src/starfocus/"

task	mscstarfocus	= starfocus$x_mscdisplay.e; hidetask mscstarfocus
task	mscfocus	= starfocus$mscfocus.cl

task	mscdisplay,
	mscrtdisplay	= mscdisplay$x_mscdisplay.e
task	mimpars		= mscdisplay$mimpars.par

hidetask mscrtdisplay, mscztvmark

task    mscexamine    = "mosexam$x_mscexam.e"

task    cimexam2 = mosexam$cimexam2.par;    hidetask cimexam2
task    eimexam2 = mosexam$eimexam2.par;    hidetask eimexam2
task    himexam2 = mosexam$himexam2.par;    hidetask himexam2
task    jimexam2 = mosexam$jimexam2.par;    hidetask jimexam2
task    limexam2 = mosexam$limexam2.par;    hidetask limexam2
task    rimexam2 = mosexam$rimexam2.par;    hidetask rimexam2
task    simexam2 = mosexam$simexam2.par;    hidetask simexam2
task    vimexam2 = mosexam$vimexam2.par;    hidetask vimexam2

task	mscstack	= combine$x_combine.e
task	_mstkhide	= combine$_mstkhide.par

# Subpackages

set	mscfinder	= "mscsrc$mscfinder/"
task	$mscfinder	= mscfinder$mscfinder.cl

set	mscmisc		= "mscsrc$mscmisc/"
#task	$mscmisc	= msctools$mscmisc.cl

clbye()
