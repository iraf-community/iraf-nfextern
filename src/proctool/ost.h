# Operand symbol table structure.
# The structure consists of a common base and operand type specific extensions.

define	OST_LENSTR	199			# Length of strings in OST
define	OST_LENOSTR	19			# Length of order string in OST
define	OST_LENEXPR	3999			# Length of strings in OST

# Common base operand elements.
define	OST_LEN		3216
define	OST_FLAG	Memi[$1]		# Operation selected?
define	OST_EXPRDB	Memi[$1+1]		# Allow expression db?
define	OST_PI		Memi[$1+2]		# Operand data structure
define	OST_PRCTYPE	Memi[$1+3]		# Processing type
define	OST_OPEN	Memi[$1+4]		# Open operand method
define	OST_CLOSE	Memi[$1+5]		# Close operand method
define	OST_NAME	Memc[P2C($1+6)]		# Expression name
define	OST_EXPRP	P2C($1+106)		# Expression pointer
define	OST_EXPR	Memc[P2C($1+106)]	# Expression
define	OST_EXPRP1	P2C($1+1106)		# Expression pointer
define	OST_EXPR1	Memc[P2C($1+1106)]	# Expression
define	OST_ORDER	Memc[P2C($1+2106)+$2-1]	# Processing order
define	OST_STRP	P2C($1+2116)		# Working string pointer
define	OST_STR		Memc[P2C($1+2116)]	# Working string

# Image operand elements.
define	OST_ILEN	(OST_LEN+803)		# Image operand length
# (Inherit base operand elements)
define	OST_LIST	Memi[$1+OST_LEN]		# Image list
define	OST_READ	Memi[$1+OST_LEN+1]		# Image list read?
define	OST_SRT		Memi[$1+OST_LEN+2]		# Sort flag
define	OST_IEXPR	Memc[P2C($1+OST_LEN+3)]		# Image expression
define	OST_INTYPE	Memc[P2C($1+OST_LEN+103)]	# Input type selection
define	OST_SUBTYPE	Memc[P2C($1+OST_LEN+203)]	# List type selection
define	OST_SORTVAL	Memc[P2C($1+OST_LEN+303)]	# Sort value
define	OST_EXPTIME	Memc[P2C($1+OST_LEN+403)]	# Exposure time
define	OST_IMAGEID	Memc[P2C($1+OST_LEN+503)]	# Image ID
define	OST_FILTER	Memc[P2C($1+OST_LEN+603)]	# Filter
define	OST_MATCH	Memc[P2C($1+OST_LEN+703)]	# Matching expression

# Sky operand elements.
define	OST_SLEN	(OST_LEN+OST_ILEN+101)		# Sky operand length
# (Inherit the base operand elements)
# (Inherit the image operand elements)
define	OST_SKYMODE	Memc[P2C($1+OST_ILEN)]		# Sky mode
define	OST_SKY		Memi[$1+OST_ILEN+100]		# Sky structure

# Sky operand elements.
define	OST_PLEN	(OST_LEN+OST_ILEN+101)		# Per operand length
# (Inherit the base operand elements)
# (Inherit the image operand elements)
define	OST_PERWIN	Memc[P2C($1+OST_ILEN)]		# Persistence window
define	OST_PER		Memi[$1+OST_ILEN+1]		# Persistence structure

# Bias operand elements.
define	OST_BLEN	(OST_LEN+1000)			# Bias operand length
# (Inherit the base operand elements)
define	OST_BIASSEC	Memc[P2C($1+OST_LEN)] 		# Bias section expr
define	OST_BTYPE	Memc[P2C($1+OST_LEN+100)]	# Bias type code
define	OST_BFUNC	Memc[P2C($1+OST_LEN+200)]	# Bias function
define	OST_BORDER	Memc[P2C($1+OST_LEN+300)]	# Bias order
define	OST_BSAMP	Memc[P2C($1+OST_LEN+400)]	# Bias sample
define	OST_BNAV	Memc[P2C($1+OST_LEN+500)]	# Bias average/median
define	OST_BNIT	Memc[P2C($1+OST_LEN+600)]	# Bias rejn iterations
define	OST_BHREJ	Memc[P2C($1+OST_LEN+700)]	# Bias high rejn
define	OST_BLREJ	Memc[P2C($1+OST_LEN+800)]	# Bias low rejn
define	OST_BGROW	Memc[P2C($1+OST_LEN+900)]	# Bias grow rejn radius

# The sort options.
define	SRT		"|nearest|before|after|"
define	SRT_NONE	0
define	SRT_NEAREST	1
define	SRT_BEFORE	2
define	SRT_AFTER	3
define	SRT_LIST	4

# The bias type options.
define	BTYPES		"|fit|ifit|mean|median|minmax|"
define	BTYPE_FIT	1
define	BTYPE_IFIT	2
define	BTYPE_MEAN	3
define	BTYPE_MEDIAN	4
define	BTYPE_MINMAX	5

# The bias function options.
define	BFUNCS		"|legendre|chebyshev|spline1|spline3|"
define	BFUNC_LEGENDRE	1
define	BFUNC_CHEBYSHEV	2
define	BFUNC_SPLINE1	3
define	BFUNC_SPLINE3	4
