#{ NEWFIRM -- NEWFIRM Reduction Package

# Load dependent packages.
msctools
ace

package	newfirm 

set	nfdat		= "newfirm$nfdat_ctio/"

task	nfproc,
	_nfproc		= "newfirm$x_proctool.e"
task	cgroup,
	combine,
	dcombine,
	fcombine	= "newfirm$x_combine.e"

task	nflist		= "newfirm$nflist.cl"
task	nfdproc		= "newfirm$nfdproc.cl"
task	nffproc		= "newfirm$nffproc.cl"
task	nfoproc		= "newfirm$nfoproc.cl"
task	nflinearize	= "newfirm$nflinearize.cl"
task	nfmask		= "newfirm$nfmask.cl"
task	nfskysub	= "newfirm$nfskysub.cl"
task	nfsetsky	= "newfirm$nfsetsky.cl"
task	nfwcs		= "newfirm$nfwcs.cl"
task	nftwomass	= "newfirm$nftwomass.cl"
task	nfgroup		= "newfirm$nfgroup.cl"

task	nffocus		= newfirm$nffocus.cl

clbye
