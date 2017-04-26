include	"par.h"
include	"prc.h"
include	"ost.h"
include	"pi.h"


# PRC_STEPS -- Set the processing steps and order.

procedure prc_steps (prc, pi, steps, imsteps, imdone, maxchar)

pointer	prc				#I Processing structure
pointer	pi				#I Image
char	steps[ARB]			#I Desired steps
char	imsteps[ARB]			#O Steps to be performed on image
char	imdone[ARB]			#O Steps already performed on image
int	maxchar				#I Maximum chars in steps

char	flag[1]
int	i, j
pointer	par, stp, ost

int	stridx()
pointer	stfind()
errchk	prc_exprs

begin
	par = PRC_PAR(prc)
	stp = PAR_OST(par)

	if (pi == NULL)
	    call error (1, "No input image for defining processing steps")

	# Select processing order string and evaluate expression if needed.
	call strcpy (steps, imsteps, maxchar)
	call prc_exprs (prc, pi, imsteps, imsteps, maxchar)

	# Get steps already done.
	iferr (call imgstr (PI_IM(pi), "PROCDONE", imdone, maxchar))
	    imdone[1] = EOS

	# Create order string excluding those already done and not selected.
	flag[2] = EOS
	j = 0
	for (i=1; imsteps[i]!=EOS; i=i+1) {
	    flag[1] = imsteps[i]
	    if (PAR_OVERRIDE(par) == NO && stridx(flag,imdone) > 0)
		next
	    ost = stfind (stp, flag)
	    if (ost == NULL)
	        next
	    if (OST_FLAG(ost) == NO)
	        next
	    if (OST_PRCTYPE(ost) == PI_PRCTYPE(pi))
	        next
	    j = j + 1
	    imsteps[j] = imsteps[i]
	}
	imsteps[j+1] = EOS
end
