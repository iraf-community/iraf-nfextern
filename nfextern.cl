#{ NFEXTERN

# For now force only old templates.
reset use_new_imt = no

images
noao
artdata
nproto

cl < "nfextern$lib/zzsetenv.def"
package	nfextern, bin = nfebin$

set	ace		= "nfextern$ace/"
task	ace.pkg		= "ace$ace.cl"

set	msctools	= "nfextern$msctools/"
task	msctools.pkg	= "msctools$msctools.cl"

set	newfirm		= "nfextern$newfirm/"
task	newfirm.pkg	= "newfirm$newfirm.cl"

set	odi		= "nfextern$odi/"
task	odi.pkg		= "odi$odi.cl"

task	xtalk.pkg	= "xtsrc$xtalk.cl"
hidetask	xtalk

# Special package for local installation.
#set	nfndwfs		= "nfextern$nfndwfs/"
#task	$nfndwfs.pkg	= "nfndwfs$nfndwfs.cl"

clbye()
