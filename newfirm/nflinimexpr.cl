# NFLINEARIZE -- Linearize an input array

procedure nflinearize (input, output)

file	input			{prompt="Input image"}
file	output			{prompt="Output image"}

real	coeff = -5e-6		{prompt="Linearity coefficient"}
file	exprdb = "nfdat$linearity.db" {prompt="Expression database"}

begin
	file	in, out
	struct	line

	in = input
	out = output

	# Apply the nonlinearity correction using the linearity
	# imexpression database

	imexpr ("lc3(a,b)", out, in, coeff, exprdb=exprdb, outtype="real")
	printf ("Linearized: coefficient=%10.4e\n", coeff) | scan (line)
	hedit (out, "LINEAR", line, add+, ver-, update+, show+)
end
