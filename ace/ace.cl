#{ ACE - Astronomical Cataloging Environment

nttools
msctools

package ace

#set	acedemo		= "acesrc$acedemo/"
#task	$acedemo	= acedemo$acedemo.cl

task	acecutouts	= acesrc$acecutouts.cl
task	acetvmark	= acesrc$acetvmark.cl

task	aceall,
	acecatalog,
	acecopy,
	acediff,
	aceevaluate,
	acefilter,
	acefocus,
	acegeomap,
	acematch,
	acesegment,
	acesetwcs	= acesrc$x_ace.e

task	acedisplay	= ace$x_mscdisplay.e
task	mimpars		= ace$mimpars.par
hidetask mimpars

set	aceproto	= "acesrc$aceproto/"
task	aceproto	= aceproto$aceproto.cl
hidetask aceproto

clbye
