# NFLINEARIZE -- Linearity correction.

procedure nflinearize (input, output)

file	input			{prompt="List of input NEWFIRM files"}
file	output			{prompt="List of linearized files"}

string	coeffs = "image"	{prompt="Coefficients (parameter|exprdb|keyword|image)",
				    enum="parameter|exprdb|keyword|image"}
real	lin1 = -6.123E-6	{prompt="Linearity coefficient for im1"}
real	lin2 = -7.037E-6	{prompt="Linearity coefficient for im2"}
real	lin3 = -5.404E-6	{prompt="Linearity coefficient for im3"}
real	lin4 = -5.952E-6	{prompt="Linearity coefficient for im4"}
string	linimage = "nfdat$nflincoeffs"	{prompt="List of linearity coefficient images"}

file	exprdb = "nfdat$exprdb.dat" {prompt="Expression database"}
bool	list = no		{prompt="List only?"}
string	logfiles = "STDOUT,logfile"	{prompt="Log files"}

begin
	string	linval, outtype
	struct	expr

	# Set parameters.
	if (exprdb == "")
	    error (2, "Must specify expression database")
	if (coeffs == "parameter")
	    linval = "nflinearize.lin\I"
	else if (coeffs == "exprdb")
	    linval = "L\I"
	else if (coeffs == "keyword")
	    linval = "lincoeff"
	else if (coeffs == "image")
	    linval = "$L"
	else
	    error (1, "Unknown coefficient type")

	# Set expression.
	printf ("%%(lin(%s))\n", linval) | scan (expr)

	# Set output type.
	if (list)
	    outtype = "vlist"
	else
	    outtype = "image"
	
	# Compute linearity or list the expressions.
	_nfproc (input, output, outtype=outtype, logfiles=logfiles,
	    lincor=yes, linexpr=expr, linimage=linimage,
	    exprdb=exprdb, taskname="nflinearize")
end
