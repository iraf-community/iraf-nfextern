# { DIMSUM -- Package definition script for the DIMSUM IR array imaging
# reduction package.

# Load necessary packages.

# Currently artdata is only required for the demos task. It is not required
# for the main dimsum package.

artdata

# Crutil is required by the new experiment cosmic ray zapping task xnzap.

imred
crutil

package dimsum

# Main DIMSUM tasks

task badpixupdate 	= "dimsrc$/badpixupdate.cl"
task iterstat		= "dimsrc$/iterstat.cl"
task miterstat		= "dimsrc$/miterstat.cl"
task maskdereg		= "dimsrc$/maskdereg.cl"
task maskfix		= "dimsrc$/maskfix.cl"
task maskstat		= "dimsrc$/maskstat.cl"
task mkmask		= "dimsrc$/mkmask.cl"
task orient		= "dimsrc$/orient.cl"
task sigmanorm		= "dimsrc$/sigmanorm.cl"
task xdshifts		= "dimsrc$/xdshifts.cl"
task xfirstpass		= "dimsrc$/xfirstpass.cl"
task xfshifts		= "dimsrc$/xfshifts.cl"
task xlist		= "dimsrc$/xlist.cl"
task xmaskpass		= "dimsrc$/xmaskpass.cl"
task xmskcombine	= "dimsrc$/xmskcombine.cl"
task xmosaic		= "dimsrc$/xmosaic.cl"
task xmshifts		= "dimsrc$/xmshifts.cl"
task xnregistar		= "dimsrc$/xnregistar.cl"
task xnslm		= "dimsrc$/xnslm.cl"
task xnzap		= "dimsrc$/xnzap.cl"
task xrshifts		= "dimsrc$/xrshifts.cl"
task xslm		= "dimsrc$/xslm.cl"
task xzap		= "dimsrc$/xzap.cl"

# Additional hidden DIMSUM tasks required by the main DIMSUM tasks.

task addcomment		= "dimsrc$/addcomment.cl"
task avshift		= "dimsrc$/x_dimsum.e"
task fileroot		= "dimsrc$/fileroot.cl"
task makemask		= "dimsrc$/makemask.cl"
task maskinterp 	= "dimsrc$/x_dimsum.e"
task minv		= "dimsrc$/minv.cl"
task xaddmask		= "dimsrc$/xaddmask.cl"

hidetask addcomment avshift fileroot maskinterp minv xaddmask


# Demos

set	demos	= "dimsrc$demos/"
task	demos	= "demos$demos.cl"

# Cache task parameters to avoid background execution problems. May need
# to go through and eventually replace some of these calls, e.g. replace
# imgets with hselect, etc.

cache sections fileroot imgets minmax iterstat miterstat maskstat xaddmask

clbye()
