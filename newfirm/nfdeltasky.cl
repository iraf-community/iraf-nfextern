procedure	nfdeltasky(inlist, outlist)

# Uses mscskysub to fit low order surfaces to the sky for quadrants from
# a NEWFIRM MEF image, in order to remove residual sky and gradients after
# processing with nfskysub.  Most of the parameters for mscskysub can be
# set explicitly here.
#
# MED 29 May 2009

string	inlist		{prompt="Input image(s)"}
string	outlist		{prompt="Output image(s)"}
int	xorder		{2, prompt="Order of mscskysub function in x"}
int	yorder		{2, prompt="Order of mscskysub function in x"}
string	function 	{"legendre", prompt="Function to be fit (legendre,chebyshev,spline3)"}
bool	cross_terms 	{yes, prompt="Include cross-terms for polynomials?"}
int	xmedian 	{100, prompt="X length of median box"}
int	ymedian 	{100, prompt="Y length of median box"}
int	median_percent 	{50, prompt="Minimum fraction of pixels in median box"}
real	lower 		{INDEF, prompt="Lower limit for residuals"}
real	upper 		{INDEF, prompt="Upper limit for residuals"}
int	ngrow 		{0, prompt="Radius of region growing circle"}
int	niter 		{0, prompt="Maximum number of rejection cycles"}
string	regions 	{"mask", prompt="Good regions (all,rows,columns,border,sections,circle,invcircle,mask)"}
string	rows 		{"*", prompt="Rows to be fit"}
string	columns 	{"*", prompt="Columns to be fit"}
int	border 		{50, prompt="Width of border to be fit"}
string	section 	{"", prompt="File name for sections list"}
string	circle 		{"", prompt="Circle specifications"}
string	mask 		{"BPM", prompt="Mask"}
real	div_min 	{INDEF, prompt="Division minimum for response output"}
bool	verbose		{no, prompt="Verbose output?"}
struct	*inimglist
struct	*outimglist

begin

	string	inim, outim
	string	intmp, outtmp
	string	inimg, outimg
	int	nin, nout
	int	i
	string	extn, extn1, cmd
	real	keyval

# Get query parameters

	inim	= inlist
	outim	= outlist

# Expand into temporary file lists

	intmp = mktemp("tmp$nfdeltaskysub")
	sections (inim,option="fullname", >intmp)
	nin = sections.nimages
	outtmp = mktemp("tmp$nfdeltaskysub")
	sections (outim,option="fullname", >outtmp)
	nout = sections.nimages
	if (nin != nout) error (0, "Numbers of input and output images do not match.")

	inimglist  = intmp
	outimglist = outtmp

# Loop through images 

	while (fscan(inimglist, inimg) != EOF) {

		if (fscan(outimglist, outimg) == EOF) 
			error (0,"Problem reading output image list.")

		imcopy (inimg//"[0]", outimg//"[0]", ver-)

		# mscskysub only works on one MEF extension at a time.
		# Run it on all four extensions.

		for (i=1; i<=4; i+=1) {
 			extn = "[im"//i//"]"
			extn1 = "[im"//i//",overwrite]"
			if (verbose) {
				print ("nfdeltasky ",inimg//extn, " ", outimg//extn)
			}

			mscskysub (inimg//extn, outimg//extn, xorder, yorder, type_output="residual",
			  function=function, cross_terms=cross_terms, xmedian=xmedian, ymedian=ymedian,
			  median_percent=median_percent, lower=lower, upper=upper, ngrow=ngrow, niter=niter,
			  regions=regions, rows=rows, columns=columns, border=border, sections=section,
			  circle=circle, mask=mask, div_min=div_min)

		# Subtract the constant value that mscskysub records in the SKYMEAN header keyword

			hselect (outimg//extn, "SKYMEAN", yes) | scan (keyval)
			imarith (outimg//extn, "-", keyval, outimg//extn1)
		}


	}

# Clean up

	delete (intmp, ver-)
	delete (outtmp, ver-)
	inimglist = ""
	outimglist = ""

end
