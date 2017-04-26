include	<error.h>
include	"par.h"
include	"prc.h"
include	"ost.h"

# T_PROCTOOL -- Entry point for processing pipeline.
#
# This entry point simply sets up the parameters.

procedure t_proctool ()

pointer	par			# Parameters

int	i
char	key[1]
pointer	stp, ost
pointer	sp, ost1, str

bool	clgetb()
int	clgwrd(), btoi(), locpr(), errget(), nowhite(), strdic()
pointer	imtopen(), clpopnu(), stenter(), stfind()
errchk	setexpr
extern	ost_iopen, ost_iclose, ost_bopen, ost_bclose
extern	ost_sopen, ost_sclose, ost_popen, ost_pclose
errchk	stenter

begin
	call smark (sp)
	call salloc (ost1, OST_ILEN, TY_STRUCT)
	call salloc (str, max(SZ_LINE, OST_LENEXPR), TY_CHAR)

	# Allocate parameter structure.
	call par_alloc (par)
	stp = PAR_OST(par)

	# Set error action.
	PAR_ERRACT(par) = clgwrd ("erraction", Memc[str], SZ_LINE, PAR_EA)

	iferr {
	    # Open expression database if defined.
	    call clgstr ("exprdb", Memc[str], SZ_LINE)
	    if (nowhite (Memc[str], Memc[str], SZ_LINE) > 0)
		call setexpr ("open", Memc[str], SZ_LINE)

	    # Operation symbol table.
	    
	    call setexpr ("imageid", OST_IMAGEID(ost1), OST_LENSTR)
	    call setexpr ("filter",  OST_FILTER(ost1),  OST_LENSTR)
	    call setexpr ("sortval", OST_SORTVAL(ost1), OST_LENSTR)
	    call setexpr ("exptime", OST_EXPTIME(ost1), OST_LENSTR)

	    # Input images.
	    key[1] = 'I'
	    ost = stenter (stp, key, OST_ILEN)
	    call aclri (Memi[ost], OST_ILEN)
	    OST_EXPRDB(ost) = NO
	    OST_PRCTYPE(ost) = PRC_INPUT
	    call strcpy ("input", OST_NAME(ost), OST_LENSTR)
	    call setexpr ("input", OST_IEXPR(ost), OST_LENSTR)
	    if (OST_IEXPR(ost) != '(')
		OST_LIST(ost) = imtopen (OST_IEXPR(ost))
	    call setexpr ("intype", Memc[str], SZ_LINE)
	    if (Memc[str] != EOS)
		call strcpy (Memc[str], OST_INTYPE(ost), OST_LENSTR)
	    call strcpy (OST_IMAGEID(ost1), OST_IMAGEID(ost), OST_LENSTR)
	    call strcpy (OST_SORTVAL(ost1), OST_SORTVAL(ost), OST_LENSTR)
	    call strcpy (OST_FILTER(ost1), OST_FILTER(ost), OST_LENSTR)
	    call strcpy (OST_EXPTIME(ost1), OST_EXPTIME(ost), OST_LENSTR)
	    call setexpr ("order", OST_ORDER(ost,1), OST_LENOSTR)

	    # Input bad pixel mask.
	    key[1] = 'M'
	    ost = stenter (stp, key, OST_ILEN)
	    call aclri (Memi[ost], OST_ILEN)
	    OST_EXPRDB(ost) = NO
	    OST_PRCTYPE(ost) = PRC_BPM
	    call strcpy ("bad pixel mask", OST_NAME(ost), OST_LENSTR)
	    call setexpr ("bpm", OST_IEXPR(ost), OST_LENSTR)
	    if (OST_IEXPR(ost) != EOS && OST_IEXPR(ost) != '(')
		OST_LIST(ost) = imtopen (OST_IEXPR(ost))
	    OST_OPEN(ost) = locpr (ost_iopen)
	    OST_CLOSE(ost) = locpr (ost_iclose)

	    # Input object mask.
	    key[1] = 'O'
	    ost = stenter (stp, key, OST_ILEN)
	    call aclri (Memi[ost], OST_ILEN)
	    OST_EXPRDB(ost) = NO
	    OST_PRCTYPE(ost) = PRC_OBM
	    call strcpy ("object mask", OST_NAME(ost), OST_LENSTR)
	    call setexpr ("obm", OST_IEXPR(ost), OST_LENSTR)
	    if (OST_IEXPR(ost) != EOS && OST_IEXPR(ost) != '(')
		OST_LIST(ost) = imtopen (OST_IEXPR(ost))
	    OST_OPEN(ost) = locpr (ost_iopen)
	    OST_CLOSE(ost) = locpr (ost_iclose)

	    # Output.
	    call clgstr ("outtype", Memc[str], SZ_LINE)
	    call sscan (Memc[str])
	    call gargwrd (Memc[str], SZ_LINE)
	    call gargwrd (PAR_MASKKEY(par), 8)
	    if (Memc[str] != EOS) {
		PAR_OUTTYPE(par) = strdic (Memc[str], Memc[str], SZ_LINE,
		    PAR_OUTTYPES)
		if (PAR_OUTTYPE(par) == 0)
		    call error (1, "Bad output type parameter")
	    } else
	        PAR_OUTTYPE(par) = PAR_OUTIMG
	    ost = stenter (stp, "output", OST_ILEN)
	    call aclri (Memi[ost], OST_ILEN)
	    OST_EXPRDB(ost) = NO
	    OST_PRCTYPE(ost) = PRC_OUTPUT
	    call strcpy ("output", OST_NAME(ost), OST_LENSTR)
	    if (PAR_OUTTYPE(par)==PAR_OUTLST || PAR_OUTTYPE(par)==PAR_OUTVLST)
	        call strcpy ("+LIST+", OST_IEXPR(ost), OST_LENSTR)
	    else
		call setexpr ("output", OST_IEXPR(ost), OST_LENSTR)
	    if (OST_IEXPR(ost) != '(')
		OST_LIST(ost) = imtopen (OST_IEXPR(ost))

	    # Calibration types and parameters.
	    key[1] = 'B'
	    ost = stenter (stp, key, OST_BLEN)
	    call aclri (Memi[ost], OST_BLEN)
	    OST_EXPRDB(ost) = YES
	    OST_FLAG(ost) = btoi (clgetb("biascor"))
	    OST_PRCTYPE(ost) = PRC_BIAS
	    OST_OPEN(ost) = locpr (ost_bopen)
	    OST_CLOSE(ost) = locpr (ost_bclose)
	    call strcpy ("bias correction", OST_NAME(ost), OST_LENSTR)
	    call strcpy ("($I-$B)", OST_EXPR(ost), OST_LENEXPR)
	    call setexpr ("biassec",   OST_BIASSEC(ost), OST_LENSTR)
	    call setexpr ("btype",     OST_BTYPE(ost),   OST_LENSTR)
	    call setexpr ("bfunction", OST_BFUNC(ost),   OST_LENSTR)
	    call setexpr ("border",    OST_BORDER(ost),  OST_LENSTR)
	    call setexpr ("bsample",   OST_BSAMP(ost),   OST_LENSTR)
	    call setexpr ("bnaverage", OST_BNAV(ost),    OST_LENSTR)
	    call setexpr ("bniterate", OST_BNIT(ost),    OST_LENSTR)
	    call setexpr ("blreject",  OST_BHREJ(ost),   OST_LENSTR)
	    call setexpr ("bhreject",  OST_BLREJ(ost),   OST_LENSTR)
	    call setexpr ("bgrow",     OST_BGROW(ost),   OST_LENSTR)

	    key[1] = 'Z'
	    ost = stenter (stp, key, OST_ILEN)
	    call aclri (Memi[ost], OST_ILEN)
	    OST_EXPRDB(ost) = YES
	    OST_FLAG(ost) = btoi (clgetb("zerocor"))
	    OST_PRCTYPE(ost) = PRC_ZERO
	    OST_OPEN(ost) = locpr (ost_iopen)
	    OST_CLOSE(ost) = locpr (ost_iclose)
	    call strcpy ("zero calibration", OST_NAME(ost), OST_LENSTR)
	    call strcpy ("($I-$Z)", OST_EXPR(ost), OST_LENEXPR)
	    call setexpr ("zeros", OST_IEXPR(ost), OST_LENSTR)
	    if (OST_IEXPR(ost) != EOS && OST_IEXPR(ost) != '(')
		OST_LIST(ost) = imtopen (OST_IEXPR(ost))
	    OST_SRT(ost) = SRT_NEAREST
	    call setexpr ("ztype", Memc[str], SZ_LINE)
	    if (Memc[str] != EOS)
		call strcpy (Memc[str], OST_INTYPE(ost), OST_LENSTR)
	    call strcpy (OST_IMAGEID(ost1), OST_IMAGEID(ost), OST_LENSTR)
	    call strcpy (OST_SORTVAL(ost1), OST_SORTVAL(ost), OST_LENSTR)
	    call setexpr ("zorder", OST_ORDER(ost,1), OST_LENOSTR)

	    key[1] = 'D'
	    ost = stenter (stp, key, OST_ILEN)
	    call aclri (Memi[ost], OST_ILEN)
	    OST_EXPRDB(ost) = YES
	    OST_FLAG(ost) = btoi (clgetb("darkcor"))
	    OST_PRCTYPE(ost) = PRC_DARK
	    OST_OPEN(ost) = locpr (ost_iopen)
	    OST_CLOSE(ost) = locpr (ost_iclose)
	    call strcpy ("dark calibration", OST_NAME(ost), OST_LENSTR)
	    call strcpy ("($I-$D)", OST_EXPR(ost), OST_LENEXPR)
	    call setexpr ("darks", OST_IEXPR(ost), OST_LENSTR)
	    if (OST_IEXPR(ost) != EOS && OST_IEXPR(ost) != '(')
		OST_LIST(ost) = imtopen (OST_IEXPR(ost))
	    OST_SRT(ost) = SRT_NEAREST * 10 + SRT_NEAREST
	    call setexpr ("dtype", Memc[str], SZ_LINE)
	    if (Memc[str] != EOS)
		call strcpy (Memc[str], OST_INTYPE(ost), OST_LENSTR)
	    call strcpy (OST_IMAGEID(ost1), OST_IMAGEID(ost), OST_LENSTR)
	    call strcpy (OST_SORTVAL(ost1), OST_SORTVAL(ost), OST_LENSTR)
	    call strcpy (OST_EXPTIME(ost1), OST_EXPTIME(ost), OST_LENSTR)
	    call setexpr ("dorder", OST_ORDER(ost,1), OST_LENOSTR)

	    key[1] = 'F'
	    ost = stenter (stp, key, OST_ILEN)
	    call aclri (Memi[ost], OST_ILEN)
	    OST_EXPRDB(ost) = YES
	    OST_FLAG(ost) = btoi (clgetb("flatcor"))
	    OST_PRCTYPE(ost) = PRC_FFLAT
	    OST_OPEN(ost) = locpr (ost_iopen)
	    OST_CLOSE(ost) = locpr (ost_iclose)
	    call strcpy ("flat calibration", OST_NAME(ost), OST_LENSTR)
	    call strcpy ("($I/$F)", OST_EXPR(ost), OST_LENEXPR)
	    call setexpr ("flats", OST_IEXPR(ost), OST_LENSTR)
	    if (OST_IEXPR(ost) != EOS && OST_IEXPR(ost) != '(')
		OST_LIST(ost) = imtopen (OST_IEXPR(ost))
	    OST_SRT(ost) = SRT_NEAREST
	    call setexpr ("ftype", Memc[str], SZ_LINE)
	    if (Memc[str] != EOS)
		call strcpy (Memc[str], OST_INTYPE(ost), OST_LENSTR)
	    call strcpy (OST_IMAGEID(ost1), OST_IMAGEID(ost), OST_LENSTR)
	    call strcpy (OST_SORTVAL(ost1), OST_SORTVAL(ost), OST_LENSTR)
	    call strcpy (OST_EXPTIME(ost1), OST_EXPTIME(ost), OST_LENSTR)
	    call strcpy (OST_FILTER(ost1), OST_FILTER(ost), OST_LENSTR)
	    call setexpr ("forder", OST_ORDER(ost,1), OST_LENOSTR)

	    key[1] = 'G'
	    ost = stenter (stp, key, OST_ILEN)
	    call aclri (Memi[ost], OST_ILEN)
	    OST_EXPRDB(ost) = YES
	    OST_FLAG(ost) = btoi (clgetb("flatcor"))
	    OST_PRCTYPE(ost) = PRC_GFLAT
	    OST_OPEN(ost) = locpr (ost_iopen)
	    OST_CLOSE(ost) = locpr (ost_iclose)
	    call strcpy ("flat calibration", OST_NAME(ost), OST_LENSTR)
	    call strcpy ("($I/$G)", OST_EXPR(ost), OST_LENEXPR)
	    #call setexpr ("gflats", OST_IEXPR(ost), OST_LENSTR)
	    #if (OST_IEXPR(ost) != EOS && OST_IEXPR(ost) != '(')
	    #    OST_LIST(ost) = imtopen (OST_IEXPR(ost))
	    OST_SRT(ost) = SRT_NEAREST
	    call setexpr ("gtype", Memc[str], SZ_LINE)
	    if (Memc[str] != EOS)
		call strcpy (Memc[str], OST_INTYPE(ost), OST_LENSTR)
	    else
		call strcpy ("(no)", OST_INTYPE(ost), OST_LENSTR)
	    call strcpy (OST_IMAGEID(ost1), OST_IMAGEID(ost), OST_LENSTR)
	    call strcpy (OST_SORTVAL(ost1), OST_SORTVAL(ost), OST_LENSTR)
	    call strcpy (OST_EXPTIME(ost1), OST_EXPTIME(ost), OST_LENSTR)
	    call strcpy (OST_FILTER(ost1), OST_FILTER(ost), OST_LENSTR)
	    call setexpr ("forder", OST_ORDER(ost,1), OST_LENOSTR)

	    key[1] = 'S'
	    ost = stenter (stp, key, OST_SLEN)
	    call aclri (Memi[ost], OST_SLEN)
	    OST_EXPRDB(ost) = YES
	    OST_FLAG(ost) = btoi (clgetb("skysub"))
	    OST_PRCTYPE(ost) = PRC_SKY
	    OST_OPEN(ost) = locpr (ost_sopen)
	    OST_CLOSE(ost) = locpr (ost_sclose)
	    call strcpy ("sky subtraction", OST_NAME(ost), OST_LENSTR)
	    call strcpy ("($I-$S)", OST_EXPR(ost), OST_LENEXPR)
	    call setexpr ("skies", OST_IEXPR(ost), OST_LENSTR)
	    if (OST_IEXPR(ost) != EOS && OST_IEXPR(ost) != '(')
		OST_LIST(ost) = imtopen (OST_IEXPR(ost))
	    OST_SRT(ost) = SRT_NEAREST
	    call setexpr ("stype", Memc[str], SZ_LINE)
	    if (Memc[str] != EOS)
		call strcpy (Memc[str], OST_INTYPE(ost), OST_LENSTR)
	    call setexpr ("skymatch", Memc[str], SZ_LINE)
	    if (Memc[str] != EOS)
		call strcpy (Memc[str], OST_MATCH(ost), OST_LENSTR)
	    call strcpy (OST_IMAGEID(ost1), OST_IMAGEID(ost), OST_LENSTR)
	    call strcpy (OST_SORTVAL(ost1), OST_SORTVAL(ost), OST_LENSTR)
	    call strcpy (OST_EXPTIME(ost1), OST_EXPTIME(ost), OST_LENSTR)
	    call strcpy (OST_FILTER(ost1), OST_FILTER(ost), OST_LENSTR)
	    call setexpr ("skymode", OST_SKYMODE(ost), OST_LENSTR)
	    call setexpr ("order", OST_ORDER(ost,1), OST_LENOSTR)

	    key[1] = 'P'
	    ost = stenter (stp, key, OST_PLEN)
	    call aclri (Memi[ost], OST_PLEN)
	    OST_EXPRDB(ost) = YES
	    OST_FLAG(ost) = btoi (clgetb("permask"))
	    OST_PRCTYPE(ost) = PRC_PER
	    OST_OPEN(ost) = locpr (ost_popen)
	    OST_CLOSE(ost) = locpr (ost_pclose)
	    call strcpy ("persistence", OST_NAME(ost), OST_LENSTR)
	    call strcpy ("($P)", OST_EXPR(ost), OST_LENEXPR)
	    OST_SRT(ost) = SRT_NEAREST
	    call strcpy (OST_IMAGEID(ost1), OST_IMAGEID(ost), OST_LENSTR)
	    call strcpy (OST_SORTVAL(ost1), OST_SORTVAL(ost), OST_LENSTR)
	    call setexpr ("perwindow", OST_PERWIN(ost), OST_LENSTR)

	    key[1] = 'L'
	    ost = stenter (stp, key, OST_ILEN)
	    call aclri (Memi[ost], OST_ILEN)
	    OST_EXPRDB(ost) = YES
	    OST_FLAG(ost) = btoi (clgetb("lincor"))
	    OST_PRCTYPE(ost) = PRC_LIN
	    OST_OPEN(ost) = locpr (ost_iopen)
	    OST_CLOSE(ost) = locpr (ost_iclose)
	    call strcpy ("linearity correction", OST_NAME(ost), OST_LENSTR)
	    call setexpr ("linimage", OST_IEXPR(ost), OST_LENSTR)
	    if (OST_IEXPR(ost) != EOS && OST_IEXPR(ost) != '(')
		OST_LIST(ost) = imtopen (OST_IEXPR(ost))
	    OST_SRT(ost) = SRT_NEAREST
	    call strcpy (OST_IMAGEID(ost1), OST_IMAGEID(ost),
		OST_LENSTR)

	    key[1] = 'H'
	    ost = stenter (stp, key, OST_ILEN)
	    call aclri (Memi[ost], OST_ILEN)
	    OST_EXPRDB(ost) = YES
	    OST_FLAG(ost) = btoi (clgetb("saturation"))
	    OST_PRCTYPE(ost) = PRC_SAT
	    OST_OPEN(ost) = locpr (ost_iopen)
	    OST_CLOSE(ost) = locpr (ost_iclose)
	    call strcpy ("saturation", OST_NAME(ost), OST_LENSTR)
	    call strcpy ("($I<saturate?0: 1))", OST_EXPR(ost), OST_LENEXPR)
	    call setexpr ("satimage", OST_IEXPR(ost), OST_LENSTR)
	    if (OST_IEXPR(ost) != EOS && OST_IEXPR(ost) != '(')
		OST_LIST(ost) = imtopen (OST_IEXPR(ost))
	    OST_SRT(ost) = SRT_NEAREST
	    call strcpy (OST_IMAGEID(ost1), OST_IMAGEID(ost),
		OST_LENSTR)

	    key[1] = 'R'
	    ost = stenter (stp, key, OST_ILEN)
	    call aclri (Memi[ost], OST_ILEN)
	    OST_EXPRDB(ost) = YES
	    OST_FLAG(ost) = btoi (clgetb("replace"))
	    OST_PRCTYPE(ost) = PRC_REP
	    OST_OPEN(ost) = locpr (ost_iopen)
	    OST_CLOSE(ost) = locpr (ost_iclose)
	    call strcpy ("replacement", OST_NAME(ost), OST_LENSTR)
	    call strcpy ("(min($I,saturate))", OST_EXPR(ost), OST_LENEXPR)
	    call setexpr ("repimage", OST_IEXPR(ost), OST_LENSTR)
	    if (OST_IEXPR(ost) != EOS && OST_IEXPR(ost) != '(')
		OST_LIST(ost) = imtopen (OST_IEXPR(ost))
	    OST_SRT(ost) = SRT_NEAREST
	    call strcpy (OST_IMAGEID(ost1), OST_IMAGEID(ost),
		OST_LENSTR)

	    key[1] = 'N'
	    ost = stenter (stp, key, OST_ILEN)
	    call aclri (Memi[ost], OST_ILEN)
	    OST_EXPRDB(ost) = YES
	    OST_FLAG(ost) = btoi (clgetb("normalize"))
	    OST_PRCTYPE(ost) = PRC_NORM
	    OST_OPEN(ost) = locpr (ost_iopen)
	    OST_CLOSE(ost) = locpr (ost_iclose)
	    call strcpy ("normalize", OST_NAME(ost), OST_LENSTR)
	    call strcpy ("(max(0.1,$I/max(1.0,procmean)))", OST_EXPR(ost), OST_LENEXPR)

	    key[1] = 'X'
	    ost = stenter (stp, key, OST_LEN)
	    call aclri (Memi[ost], OST_LEN)
	    OST_EXPRDB(ost) = NO
	    OST_FLAG(ost) = btoi (clgetb("fixpix"))
	    OST_PRCTYPE(ost) = PRC_FIXPIX
	    call strcpy ("fixpix", OST_NAME(ost), OST_LENSTR)

	    key[1] = 'T'
	    ost = stenter (stp, key, OST_LEN)
	    call aclri (Memi[ost], OST_LEN)
	    OST_EXPRDB(ost) = NO
	    OST_FLAG(ost) = btoi (clgetb("trim"))
	    OST_PRCTYPE(ost) = PRC_TRIM
	    call strcpy ("trim", OST_NAME(ost), OST_LENSTR)
	    if (OST_FLAG(ost) == YES)
		call setexpr ("trimsec", PAR_TSEC(par), PAR_SZSTR)

	    # Other parameters.
	    PAR_OLLIST(par) = clpopnu ("logfiles")
	    PAR_OVERRIDE(par) = btoi(clgetb ("override"))
	    PAR_COPY(par) = btoi(clgetb ("copy"))
	    PAR_LISTIM(par) = YES

	    # Graphics parameters.
	    call clgstr ("gdevice", PAR_GDEV(par), PAR_SZSTR)
	    call clgstr ("gcursor", PAR_GCUR(par), PAR_SZSTR)

	    # Override or add user expressions.
	    call clgstr ("opdb", Memc[str], SZ_LINE)
	    iferr (call exprdb (stp, Memc[str]))
	        call erract (EA_WARN)
	    call setexpr ("flatexpr", Memc[str], SZ_LINE)
	    if (Memc[str] != EOS) {
		ost = stfind (stp, "F")
		call strcpy (Memc[str], OST_EXPR(ost), OST_LENEXPR)
	    }
	    call setexpr ("linexpr", Memc[str], SZ_LINE)
	    if (Memc[str] != EOS) {
		ost = stfind (stp, "L")
		call strcpy (Memc[str], OST_EXPR(ost), OST_LENEXPR)
	    }
	    call setexpr ("persist", Memc[str], SZ_LINE)
	    if (Memc[str] != EOS) {
		ost = stfind (stp, "P")
		call strcpy (Memc[str], OST_EXPR(ost), OST_LENEXPR)
	    }
	    call setexpr ("satexpr", Memc[str], SZ_LINE)
	    if (Memc[str] != EOS) {
		ost = stfind (stp, "H")
		call strcpy (Memc[str], OST_EXPR(ost), OST_LENEXPR)
	    }
	    call setexpr ("repexpr", Memc[str], SZ_LINE)
	    if (Memc[str] != EOS) {
		ost = stfind (stp, "R")
		call strcpy (Memc[str], OST_EXPR(ost), OST_LENEXPR)
	    }

	    # Now adjust things based on the selected operations.
	    # This does not check the order parameters.
	    #
	    # For the running operations (persistence and sky subtraction)
	    # the sorting is such that each extension (imageid) is done
	    # completely before going on the next.  This is done for
	    # efficiency though it may not seem intuitive to users.
	    #
	    # For persistence we also exclude sorting by prctype and
	    # filter since the operation is dependent only on the order
	    # in which the exposures were taken.
	    #
	    # For the others we sort by prctype, filter, and sort value.
	    # The prctype sorting also causes the operations to be done
	    # over all exposures of each type before going on to the next.

	    if (OST_FLAG(stfind (stp, "P")) == YES ||
	        OST_FLAG(stfind (stp, "H")) == YES) {
		call strcpy ("IS", Memc[PAR_SRTORDER(par)], 9)
		ost = stfind (stp, "I")
		call strcpy ("PH", OST_ORDER(ost,1), OST_LENOSTR)
	    } else if (OST_FLAG(stfind (stp, "S")) == YES)
		call strcpy ("PFIS", Memc[PAR_SRTORDER(par)], 9)
	    else
		call strcpy ("PFSI", Memc[PAR_SRTORDER(par)], 9)

	    # Call processing tool.
	    call clgstr ("taskname", Memc[str], SZ_LINE)
	    call proctool (par, Memc[str])
	} then {
	    switch (PAR_ERRACT(par)) {
	    case PAR_EAWARN:
		call erract (EA_WARN)
	    case PAR_EAERROR:
		call erract (EA_ERROR)
	    case PAR_EAQUIT:
		i = errget (Memc[str], SZ_LINE)
	        call eprintf ("QUIT: %s\n")
		    call pargstr (Memc[str])
	    }
	}

	# Finish up.
	call setexpr ("close", Memc[str], SZ_LINE)
	call par_free (par)
	call sfree (sp)
end
