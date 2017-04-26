#{ ODI -- ODI Reduction Package

# Load dependent packages.
msctools
ace

package	odi 

set	odidat		= "odi$odidat/"

task	_odiproc	= "odi$x_proctool.e"

task	zproc		= "odi$zproc.cl"
task	dproc		= "odi$dproc.cl"
task	fproc		= "odi$fproc.cl"
task	oproc		= "odi$oproc.cl"
task	odiproc		= "odi$odiproc.cl"

task	 combine	= "odi$x_combine.e"
hidetask combine

task	zcombine	= "odi$zcombine.cl"
task	dcombine	= "odi$dcombine.cl"
task	fcombine	= "odi$fcombine.cl"
task	ocombine	= "odi$ocombine.cl"

task	odimerge	= "odi$odimerge.cl"
task	odisetwcs	= "odi$odisetwcs.cl"

task	odireformat	= "odi$odireformat.cl"
task	mkpodimef	= "odi$mkpodimef.cl"

# Simulations
task	mkota		= "odi$mkota.cl"

# Misc.
task	setbpm		= "odi$setbpm.cl"
task	convertbpm	= "odi$convertbpm.cl"
task	chskywcs	= "odi$chskywcs.cl"

clbye
