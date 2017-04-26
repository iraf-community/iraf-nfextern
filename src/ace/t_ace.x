include	<clset.h>
include	"ace.h"
include	"acedetect.h"
include	"filter.h"


# T_ACESEGMENT -- Segment images.

procedure t_acesegment ()

pointer	par			# Parameters

pointer	sp, str

bool	show
int	clgeti(), clgwrd(), afn_cl(), locpr(), syshost()
errchk	aceall, afn_cl, syshost, ace_show_catdef
extern	p_acesegment()

begin
	call smark (sp)
	call salloc (par, PAR_LEN, TY_STRUCT)
	call salloc (str, SZ_LINE, TY_CHAR)
	call aclri (Memi[par], PAR_LEN)

	call strcpy ("acesegment", PAR_TASK(par), 19)

	# Setup host callable files and parameters.
	# Show the parameter file or the default catalog definition file.
	call sprintf (Memc[str], SZ_LINE, "proc:%d")
	    call pargi (locpr(p_acesegment))
	if (syshost("acesegment.dat","",Memc[str],"show_pset",show)==PR_HOST) {
	    if (!show)
	        call ace_show_catdef (show)
	    if (show) {
		call sfree (sp)
		return
	    }
	}

	# Get list parameters.
	PAR_IMLIST(par,1) = afn_cl ("images", "images", NULL)
	PAR_BPMLIST(par,1) = afn_cl ("masks", "images", PAR_IMLIST(par,1))
	PAR_SKYLIST(par,1) = afn_cl ("skies", "images", PAR_IMLIST(par,1))
	PAR_SIGLIST(par,1) = afn_cl ("sigmas", "images", PAR_IMLIST(par,1))
	PAR_EXPLIST(par,1) = afn_cl ("exps", "images", PAR_IMLIST(par,1))
	PAR_GAINLIST(par,1) = afn_cl ("", "images", PAR_IMLIST(par,1))
	PAR_SCALELIST(par,1) = afn_cl ("", "files", PAR_IMLIST(par,1))
	PAR_SPTLLIST(par,1) = afn_cl ("", "images", PAR_IMLIST(par,1))

	PAR_IMLIST(par,2) = afn_cl ("", "images", NULL)
	PAR_BPMLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_SKYLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_SIGLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_EXPLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_GAINLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_SCALELIST(par,2) = afn_cl ("", "files", PAR_IMLIST(par,2))
	PAR_SPTLLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))

	PAR_OUTOMLIST(par) = afn_cl ("objmasks", "images", PAR_IMLIST(par,1))
	PAR_OMTYPE(par) = clgwrd ("omtype", Memc[str], SZ_LINE, OM_TYPES)
	PAR_INCATLIST(par) = afn_cl ("", "images", PAR_IMLIST(par,1))
	PAR_OUTCATLIST(par) = afn_cl ("", "images", PAR_IMLIST(par,1))
	PAR_CATDEFLIST(par) = afn_cl ("", "files", PAR_IMLIST(par,1))
	PAR_LOGLIST(par) = afn_cl ("logfiles", "files", PAR_IMLIST(par,1))

	PAR_OUTSKYLIST(par) = afn_cl ("skyimages", "images", PAR_IMLIST(par,1))
	PAR_OUTSIGLIST(par) = afn_cl ("sigimages", "images", PAR_IMLIST(par,1))

	PAR_NMAXREC(par) = INDEFI
	PAR_VERBOSE(par) = clgeti ("verbose")

	call clgstr ("extnames", PAR_EXTNAMES(par), PAR_SZSTR)
	PAR_UPDATE(par) = YES

	# Get other parameters.
	call sky_pars ("all", "", PAR_SKY(par))
	call det_pars ("open", "", PAR_DET(par))
	call spt_pars ("open", "", PAR_SPT(par))
	call grw_pars ("open", "", PAR_GRW(par))
	#call evl_pars ("open", "", PAR_EVL(par))

	# Do the detection.
	call aceall (par)

	# Finish up.
	call sky_pars ("close", "", PAR_SKY(par))
	call det_pars ("close", "", PAR_DET(par))
	call spt_pars ("close", "", PAR_SPT(par))
	call grw_pars ("close", "", PAR_GRW(par))
	#call evl_pars ("close", "", PAR_EVL(par))

	call afn_cls (PAR_OUTSIGLIST(par))
	call afn_cls (PAR_OUTSKYLIST(par))

	call afn_cls (PAR_LOGLIST(par))
	call afn_cls (PAR_OUTOMLIST(par))
	call afn_cls (PAR_CATDEFLIST(par))
	call afn_cls (PAR_OUTCATLIST(par))
	call afn_cls (PAR_INCATLIST(par))

	call afn_cls (PAR_SPTLLIST(par,2))
	call afn_cls (PAR_SCALELIST(par,2))
	call afn_cls (PAR_GAINLIST(par,2))
	call afn_cls (PAR_EXPLIST(par,2))
	call afn_cls (PAR_SIGLIST(par,2))
	call afn_cls (PAR_SKYLIST(par,2))
	call afn_cls (PAR_BPMLIST(par,2))
	call afn_cls (PAR_IMLIST(par,2))

	call afn_cls (PAR_SPTLLIST(par,1))
	call afn_cls (PAR_SCALELIST(par,1))
	call afn_cls (PAR_GAINLIST(par,1))
	call afn_cls (PAR_EXPLIST(par,1))
	call afn_cls (PAR_SIGLIST(par,1))
	call afn_cls (PAR_SKYLIST(par,1))
	call afn_cls (PAR_BPMLIST(par,1))
	call afn_cls (PAR_IMLIST(par,1))

	call sfree (sp)
end


# T_ACECATALOG -- Catalog sources in single images.

procedure t_acecatalog ()

pointer	par			# Parameters

pointer	sp, str

bool	show
int	clgeti(), clgwrd(), afn_cl(), locpr(), syshost()
errchk	aceall, afn_cl, syshost, ace_show_catdef
extern	p_acecatalog()

begin
	call smark (sp)
	call salloc (par, PAR_LEN, TY_STRUCT)
	call salloc (str, SZ_LINE, TY_CHAR)
	call aclri (Memi[par], PAR_LEN)

	call strcpy ("acecatalog", PAR_TASK(par), 19)

	# Setup host callable files and parameters.
	# Show the parameter file or the default catalog definition file.
	call sprintf (Memc[str], SZ_LINE, "proc:%d")
	    call pargi (locpr(p_acecatalog))
	if (syshost("acecatalog.dat","",Memc[str],"show_pset",show)==PR_HOST) {
	    if (!show)
	        call ace_show_catdef (show)
	    if (show) {
		call sfree (sp)
		return
	    }
	}

	# Get list parameters.
	PAR_IMLIST(par,1) = afn_cl ("images", "images", NULL)
	PAR_BPMLIST(par,1) = afn_cl ("masks", "images", PAR_IMLIST(par,1))
	PAR_SKYLIST(par,1) = afn_cl ("skies", "images", PAR_IMLIST(par,1))
	PAR_SIGLIST(par,1) = afn_cl ("sigmas", "images", PAR_IMLIST(par,1))
	PAR_EXPLIST(par,1) = afn_cl ("exps", "images", PAR_IMLIST(par,1))
	PAR_GAINLIST(par,1) = afn_cl ("gains", "images", PAR_IMLIST(par,1))
	PAR_SCALELIST(par,1) = afn_cl ("", "files", PAR_IMLIST(par,1))
	#PAR_SPTLLIST(par,1) = afn_cl ("", "images", PAR_IMLIST(par,1))
	PAR_SPTLLIST(par,1) = afn_cl ("spatialvar", "images", PAR_IMLIST(par,1))

	PAR_IMLIST(par,2) = afn_cl ("", "images", NULL)
	PAR_BPMLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_SKYLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_SIGLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_EXPLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_GAINLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_SCALELIST(par,2) = afn_cl ("", "files", PAR_IMLIST(par,2))
	PAR_SPTLLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))

	PAR_OUTOMLIST(par) = afn_cl ("objmasks", "images", PAR_IMLIST(par,1))
	PAR_OMTYPE(par) = clgwrd ("omtype", Memc[str], SZ_LINE, OM_TYPES)
	PAR_INCATLIST(par) = afn_cl ("", "images", PAR_IMLIST(par,1))
	PAR_OUTCATLIST(par) = afn_cl ("catalogs", "images", PAR_IMLIST(par,1))
	PAR_CATDEFLIST(par) = afn_cl ("catdefs", "files", PAR_IMLIST(par,1))
	PAR_LOGLIST(par) = afn_cl ("logfiles", "files", PAR_IMLIST(par,1))

	PAR_OUTSKYLIST(par) = afn_cl ("", "images", PAR_IMLIST(par,1))
	PAR_OUTSIGLIST(par) = afn_cl ("", "images", PAR_IMLIST(par,1))

	PAR_NMAXREC(par) = clgeti ("nmaxrec")
	PAR_VERBOSE(par) = clgeti ("verbose")

	call clgstr ("extnames", PAR_EXTNAMES(par), PAR_SZSTR)
	PAR_UPDATE(par) = YES

	# Get other parameters.
	# The parameter structures flag whether an operation is requested.
	call sky_pars ("open", "", PAR_SKY(par))
	call det_pars ("open", "", PAR_DET(par))
	call spt_pars ("open", "", PAR_SPT(par))
	call grw_pars ("open", "", PAR_GRW(par))
	call evl_pars ("open", "", PAR_EVL(par))
	call flt_pars ("open", "", PAR_FLT(par))

	# Do the detection.
	call aceall (par)

	# Finish up.
	call sky_pars ("close", "", PAR_SKY(par))
	call det_pars ("close", "", PAR_DET(par))
	call spt_pars ("close", "", PAR_SPT(par))
	call grw_pars ("close", "", PAR_GRW(par))
	call evl_pars ("close", "", PAR_EVL(par))
	call flt_pars ("close", "", PAR_FLT(par))

	call afn_cls (PAR_OUTSIGLIST(par))
	call afn_cls (PAR_OUTSKYLIST(par))

	call afn_cls (PAR_LOGLIST(par))
	call afn_cls (PAR_OUTOMLIST(par))
	call afn_cls (PAR_CATDEFLIST(par))
	call afn_cls (PAR_OUTCATLIST(par))
	call afn_cls (PAR_INCATLIST(par))

	call afn_cls (PAR_SPTLLIST(par,2))
	call afn_cls (PAR_SCALELIST(par,2))
	call afn_cls (PAR_GAINLIST(par,2))
	call afn_cls (PAR_EXPLIST(par,2))
	call afn_cls (PAR_SIGLIST(par,2))
	call afn_cls (PAR_SKYLIST(par,2))
	call afn_cls (PAR_BPMLIST(par,2))
	call afn_cls (PAR_IMLIST(par,2))

	call afn_cls (PAR_SPTLLIST(par,1))
	call afn_cls (PAR_SCALELIST(par,1))
	call afn_cls (PAR_GAINLIST(par,1))
	call afn_cls (PAR_EXPLIST(par,1))
	call afn_cls (PAR_SIGLIST(par,1))
	call afn_cls (PAR_SKYLIST(par,1))
	call afn_cls (PAR_BPMLIST(par,1))
	call afn_cls (PAR_IMLIST(par,1))

	call sfree (sp)
end


# T_ACEEVALUATE -- Evaluate objects relative to a reference catalog.

procedure t_aceevaluate ()

pointer	par			# Parameters

pointer	sp, str

bool	show
int	clgeti(), afn_cl(), locpr(), syshost()
errchk	aceall, afn_cl, syshost, ace_show_catdef
extern	p_aceevaluate()

begin
	call smark (sp)
	call salloc (par, PAR_LEN, TY_STRUCT)
	call salloc (str, SZ_LINE, TY_CHAR)
	call aclri (Memi[par], PAR_LEN)

	call strcpy ("aceevaluate", PAR_TASK(par), 19)

	# Setup host callable files and parameters.
	# Show the parameter file or the default catalog definition file.
	call sprintf (Memc[str], SZ_LINE, "proc:%d")
	    call pargi (locpr(p_aceevaluate))
	if (syshost("aceevaluate.dat","",Memc[str],"show_pset",show)==PR_HOST) {
	    if (!show)
	        call ace_show_catdef (show)
	    if (show) {
		call sfree (sp)
		return
	    }
	}

	# Get list parameters.
	PAR_IMLIST(par,1) = afn_cl ("images", "images", NULL)
	PAR_BPMLIST(par,1) = afn_cl ("", "images", PAR_IMLIST(par,1))
	PAR_SKYLIST(par,1) = afn_cl ("skies", "images", PAR_IMLIST(par,1))
	PAR_SIGLIST(par,1) = afn_cl ("sigmas", "images", PAR_IMLIST(par,1))
	PAR_EXPLIST(par,1) = afn_cl ("exps", "images", PAR_IMLIST(par,1))
	PAR_GAINLIST(par,1) = afn_cl ("gains", "images", PAR_IMLIST(par,1))
	PAR_SCALELIST(par,1) = afn_cl ("", "files", PAR_IMLIST(par,1))
	PAR_SPTLLIST(par,1) = afn_cl ("", "images", PAR_IMLIST(par,1))

	PAR_IMLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_BPMLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_SKYLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_SIGLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_EXPLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_GAINLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_SCALELIST(par,2) = afn_cl ("", "files", PAR_IMLIST(par,2))
	PAR_SPTLLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))

	PAR_OUTOMLIST(par) = afn_cl ("objmasks", "images", PAR_IMLIST(par,1))
	PAR_OMTYPE(par) = OM_ALL
	PAR_INCATLIST(par) = afn_cl ("rcatalogs", "images", PAR_IMLIST(par,1))
	PAR_OUTCATLIST(par) = afn_cl ("catalogs", "images", PAR_IMLIST(par,1))
	PAR_CATDEFLIST(par) = afn_cl ("catdefs", "files", PAR_IMLIST(par,1))
	PAR_LOGLIST(par) = afn_cl ("logfiles", "files", PAR_IMLIST(par,1))

	PAR_OUTSKYLIST(par) = afn_cl ("", "images", PAR_IMLIST(par,1))
	PAR_OUTSIGLIST(par) = afn_cl ("", "images", PAR_IMLIST(par,1))

	PAR_NMAXREC(par) = clgeti ("nmaxrec")
	PAR_VERBOSE(par) = clgeti ("verbose")

	PAR_UPDATE(par) = YES

	# Get other parameters.
	# The parameter structures flag whether an operation is requested.
	call sky_pars ("open", "", PAR_SKY(par))
	call evl_pars ("open", "", PAR_EVL(par))
	call flt_pars ("open", "", PAR_FLT(par))

	# Do the detection.
	call aceall (par)

	# Finish up.
	call sky_pars ("close", "", PAR_SKY(par))
	call evl_pars ("close", "", PAR_EVL(par))
	call flt_pars ("close", "", PAR_FLT(par))

	call afn_cls (PAR_OUTSIGLIST(par))
	call afn_cls (PAR_OUTSKYLIST(par))

	call afn_cls (PAR_LOGLIST(par))
	call afn_cls (PAR_OUTOMLIST(par))
	call afn_cls (PAR_CATDEFLIST(par))
	call afn_cls (PAR_INCATLIST(par))
	call afn_cls (PAR_OUTCATLIST(par))

	call afn_cls (PAR_SPTLLIST(par,2))
	call afn_cls (PAR_SCALELIST(par,2))
	call afn_cls (PAR_GAINLIST(par,2))
	call afn_cls (PAR_EXPLIST(par,2))
	call afn_cls (PAR_SIGLIST(par,2))
	call afn_cls (PAR_SKYLIST(par,2))
	call afn_cls (PAR_BPMLIST(par,2))
	call afn_cls (PAR_IMLIST(par,2))

	call afn_cls (PAR_SPTLLIST(par,1))
	call afn_cls (PAR_SCALELIST(par,1))
	call afn_cls (PAR_GAINLIST(par,1))
	call afn_cls (PAR_EXPLIST(par,1))
	call afn_cls (PAR_SIGLIST(par,1))
	call afn_cls (PAR_SKYLIST(par,1))
	call afn_cls (PAR_BPMLIST(par,1))
	call afn_cls (PAR_IMLIST(par,1))

	call sfree (sp)
end


# T_ACEDIFF -- Difference detection and cataloging.

procedure t_acediff ()

pointer	par			# Parameters

pointer	sp, str

bool	show
int	clgeti(), clgwrd(), afn_cl(), locpr(), syshost()
errchk	aceall, afn_cl, syshost, ace_show_catdef
extern	p_acediff()

begin
	call smark (sp)
	call salloc (par, PAR_LEN, TY_STRUCT)
	call salloc (str, SZ_LINE, TY_CHAR)
	call aclri (Memi[par], PAR_LEN)

	call strcpy ("acediff", PAR_TASK(par), 19)

	# Setup host callable files and parameters.
	# Show the parameter file or the default catalog definition file.
	call sprintf (Memc[str], SZ_LINE, "proc:%d")
	    call pargi (locpr(p_acediff))
	if (syshost("acediff.dat","",Memc[str],"show_pset",show)==PR_HOST) {
	    if (!show)
	        call ace_show_catdef (show)
	    if (show) {
		call sfree (sp)
		return
	    }
	}

	# Get list parameters.
	PAR_IMLIST(par,1) = afn_cl ("images", "images", NULL)
	PAR_BPMLIST(par,1) = afn_cl ("masks", "images", PAR_IMLIST(par,1))
	PAR_SKYLIST(par,1) = afn_cl ("skies", "images", PAR_IMLIST(par,1))
	PAR_SIGLIST(par,1) = afn_cl ("sigmas", "images", PAR_IMLIST(par,1))
	PAR_EXPLIST(par,1) = afn_cl ("exps", "images", PAR_IMLIST(par,1))
	PAR_GAINLIST(par,1) = afn_cl ("gains", "images", PAR_IMLIST(par,1))
	PAR_SCALELIST(par,1) = afn_cl ("scales", "files", PAR_IMLIST(par,1))
	PAR_SPTLLIST(par,1) = afn_cl ("", "images", PAR_IMLIST(par,1))

	PAR_IMLIST(par,2) = afn_cl ("rimages", "images", NULL)
	PAR_BPMLIST(par,2) = afn_cl ("rmasks", "images", PAR_IMLIST(par,2))
	PAR_SKYLIST(par,2) = afn_cl ("rskies", "images", PAR_IMLIST(par,2))
	PAR_SIGLIST(par,2) = afn_cl ("rsigmas", "images", PAR_IMLIST(par,2))
	PAR_EXPLIST(par,2) = afn_cl ("rexps", "images", PAR_IMLIST(par,2))
	PAR_GAINLIST(par,2) = afn_cl ("rgains", "images", PAR_IMLIST(par,2))
	PAR_SCALELIST(par,2) = afn_cl ("rscales", "files", PAR_IMLIST(par,2))
	PAR_SPTLLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))

	call clgstr ("roffset", PAR_OFFSET(par), PAR_SZSTR)

	PAR_OUTOMLIST(par) = afn_cl ("objmasks", "images", PAR_IMLIST(par,1))
	PAR_OMTYPE(par) = clgwrd ("omtype", Memc[str], SZ_LINE, OM_TYPES)
	PAR_INCATLIST(par) = afn_cl ("", "images", PAR_IMLIST(par,1))
	PAR_OUTCATLIST(par) = afn_cl ("catalogs", "images", PAR_IMLIST(par,1))
	PAR_CATDEFLIST(par) = afn_cl ("catdefs", "files", PAR_IMLIST(par,1))
	PAR_LOGLIST(par) = afn_cl ("logfiles", "files", PAR_IMLIST(par,1))

	PAR_OUTSKYLIST(par) = afn_cl ("", "images", PAR_IMLIST(par,1))
	PAR_OUTSIGLIST(par) = afn_cl ("", "images", PAR_IMLIST(par,1))

	PAR_NMAXREC(par) = clgeti ("nmaxrec")
	PAR_VERBOSE(par) = clgeti ("verbose")

	call clgstr ("extnames", PAR_EXTNAMES(par), PAR_SZSTR)

	# Get other parameters.
	# The parameter structures flag whether an operation is requested.
	call sky_pars ("open", "", PAR_SKY(par))
	call det_pars ("diff", "", PAR_DET(par))
	call spt_pars ("open", "", PAR_SPT(par))
	call grw_pars ("open", "", PAR_GRW(par))
	call evl_pars ("open", "", PAR_EVL(par))
	call flt_pars ("open", "", PAR_FLT(par))

	PAR_UPDATE(par) = YES

	# Do the detection.
	call aceall (par)

	# Finish up.
	call sky_pars ("close", "", PAR_SKY(par))
	call det_pars ("close", "", PAR_DET(par))
	call spt_pars ("close", "", PAR_SPT(par))
	call grw_pars ("close", "", PAR_GRW(par))
	call evl_pars ("close", "", PAR_EVL(par))
	call flt_pars ("close", "", PAR_FLT(par))

	call afn_cls (PAR_OUTSIGLIST(par))
	call afn_cls (PAR_OUTSKYLIST(par))

	call afn_cls (PAR_LOGLIST(par))
	call afn_cls (PAR_OUTOMLIST(par))
	call afn_cls (PAR_CATDEFLIST(par))
	call afn_cls (PAR_INCATLIST(par))
	call afn_cls (PAR_OUTCATLIST(par))

	call afn_cls (PAR_SPTLLIST(par,2))
	call afn_cls (PAR_SCALELIST(par,2))
	call afn_cls (PAR_GAINLIST(par,2))
	call afn_cls (PAR_EXPLIST(par,2))
	call afn_cls (PAR_SIGLIST(par,2))
	call afn_cls (PAR_SKYLIST(par,2))
	call afn_cls (PAR_BPMLIST(par,2))
	call afn_cls (PAR_IMLIST(par,2))

	call afn_cls (PAR_SPTLLIST(par,1))
	call afn_cls (PAR_SCALELIST(par,1))
	call afn_cls (PAR_GAINLIST(par,1))
	call afn_cls (PAR_EXPLIST(par,1))
	call afn_cls (PAR_SIGLIST(par,1))
	call afn_cls (PAR_SKYLIST(par,1))
	call afn_cls (PAR_BPMLIST(par,1))
	call afn_cls (PAR_IMLIST(par,1))

	call sfree (sp)
end


# T_ACEALL -- All parameters.

procedure t_aceall ()

pointer	par			# Parameters

pointer	sp, str

bool	show
int	clgeti(), clgwrd(), afn_cl(), locpr(), syshost()
errchk	aceall, afn_cl, syshost, ace_show_catdef
extern	p_aceall()

begin
	call smark (sp)
	call salloc (par, PAR_LEN, TY_STRUCT)
	call salloc (str, SZ_LINE, TY_CHAR)
	call aclri (Memi[par], PAR_LEN)

	call strcpy ("aceall", PAR_TASK(par), 19)

	# Setup host callable files and parameters.
	# Show the parameter file or the default catalog definition file.
	call sprintf (Memc[str], SZ_LINE, "proc:%d")
	    call pargi (locpr(p_aceall))
	if (syshost("aceall.dat","",Memc[str],"show_pset",show)==PR_HOST) {
	    if (!show)
	        call ace_show_catdef (show)
	    if (show) {
		call sfree (sp)
		return
	    }
	}

	# Get list parameters.
	PAR_IMLIST(par,1) = afn_cl ("images", "images", NULL)
	PAR_BPMLIST(par,1) = afn_cl ("masks", "images", PAR_IMLIST(par,1))
	PAR_SKYLIST(par,1) = afn_cl ("skies", "images", PAR_IMLIST(par,1))
	PAR_SIGLIST(par,1) = afn_cl ("sigmas", "images", PAR_IMLIST(par,1))
	PAR_EXPLIST(par,1) = afn_cl ("exps", "images", PAR_IMLIST(par,1))
	PAR_GAINLIST(par,1) = afn_cl ("gains", "images", PAR_IMLIST(par,1))
	PAR_SCALELIST(par,1) = afn_cl ("scales", "files", PAR_IMLIST(par,1))
	PAR_SPTLLIST(par,1) = afn_cl ("", "images", PAR_IMLIST(par,1))

	PAR_IMLIST(par,2) = afn_cl ("rimages", "images", NULL)
	PAR_BPMLIST(par,2) = afn_cl ("rmasks", "images", PAR_IMLIST(par,2))
	PAR_SKYLIST(par,2) = afn_cl ("rskies", "images", PAR_IMLIST(par,2))
	PAR_SIGLIST(par,2) = afn_cl ("rsigmas", "images", PAR_IMLIST(par,2))
	PAR_EXPLIST(par,2) = afn_cl ("rexps", "images", PAR_IMLIST(par,2))
	PAR_GAINLIST(par,2) = afn_cl ("rgains", "images", PAR_IMLIST(par,2))
	PAR_SCALELIST(par,2) = afn_cl ("rscales", "files", PAR_IMLIST(par,2))
	PAR_SPTLLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))

	call clgstr ("roffset", PAR_OFFSET(par), PAR_SZSTR)

	PAR_OUTOMLIST(par) = afn_cl ("objmasks", "images", PAR_IMLIST(par,1))
	PAR_OMTYPE(par) = clgwrd ("omtype", Memc[str], SZ_LINE, OM_TYPES)
	PAR_INCATLIST(par) = afn_cl ("rcatalogs", "images", PAR_IMLIST(par,1))
	PAR_OUTCATLIST(par) = afn_cl ("catalogs", "images", PAR_IMLIST(par,1))
	PAR_CATDEFLIST(par) = afn_cl ("catdefs", "files", PAR_IMLIST(par,1))
	PAR_LOGLIST(par) = afn_cl ("logfiles", "files", PAR_IMLIST(par,1))

	PAR_OUTSKYLIST(par) = afn_cl ("skyimages", "images", PAR_IMLIST(par,1))
	PAR_OUTSIGLIST(par) = afn_cl ("sigimages", "images", PAR_IMLIST(par,1))

	PAR_NMAXREC(par) = clgeti ("nmaxrec")
	PAR_VERBOSE(par) = clgeti ("verbose")

	call clgstr ("extnames", PAR_EXTNAMES(par), PAR_SZSTR)

	# Get other parameters.
	# The parameter structures flag whether an operation is requested.
	call sky_pars ("all", "", PAR_SKY(par))
	call det_pars ("all", "", PAR_DET(par))
	call spt_pars ("all", "", PAR_SPT(par))
	call grw_pars ("all", "", PAR_GRW(par))
	call evl_pars ("all", "", PAR_EVL(par))
	call flt_pars ("all", "", PAR_FLT(par))

	PAR_UPDATE(par) = YES

	# Do the detection.
	call aceall (par)

	# Finish up.
	call sky_pars ("close", "", PAR_SKY(par))
	call det_pars ("close", "", PAR_DET(par))
	call spt_pars ("close", "", PAR_SPT(par))
	call grw_pars ("close", "", PAR_GRW(par))
	call evl_pars ("close", "", PAR_EVL(par))
	call flt_pars ("close", "", PAR_FLT(par))

	call afn_cls (PAR_OUTSIGLIST(par))
	call afn_cls (PAR_OUTSKYLIST(par))

	call afn_cls (PAR_LOGLIST(par))
	call afn_cls (PAR_OUTOMLIST(par))
	call afn_cls (PAR_CATDEFLIST(par))
	call afn_cls (PAR_INCATLIST(par))
	call afn_cls (PAR_OUTCATLIST(par))

	call afn_cls (PAR_SPTLLIST(par,2))
	call afn_cls (PAR_SCALELIST(par,2))
	call afn_cls (PAR_GAINLIST(par,2))
	call afn_cls (PAR_EXPLIST(par,2))
	call afn_cls (PAR_SIGLIST(par,2))
	call afn_cls (PAR_SKYLIST(par,2))
	call afn_cls (PAR_BPMLIST(par,2))
	call afn_cls (PAR_IMLIST(par,2))

	call afn_cls (PAR_SPTLLIST(par,1))
	call afn_cls (PAR_SCALELIST(par,1))
	call afn_cls (PAR_GAINLIST(par,1))
	call afn_cls (PAR_EXPLIST(par,1))
	call afn_cls (PAR_SIGLIST(par,1))
	call afn_cls (PAR_SKYLIST(par,1))
	call afn_cls (PAR_BPMLIST(par,1))
	call afn_cls (PAR_IMLIST(par,1))

	call sfree (sp)
end


# T_ACEFILTER -- Filter catalogs and object masks.

procedure t_acefilter ()

pointer	par			# Parameters

pointer	sp, str

bool	clgetb()
int	clgeti(), afn_cl(), btoi()
errchk	aceall, afn_cl

begin
	call smark (sp)
	call salloc (par, PAR_LEN, TY_STRUCT)
	call salloc (str, SZ_LINE, TY_CHAR)
	call aclri (Memi[par], PAR_LEN)

	call strcpy ("acefilter", PAR_TASK(par), 19)

	# Get list parameters.
	PAR_IMLIST(par,1) = afn_cl ("images", "images", NULL)
	PAR_BPMLIST(par,1) = afn_cl ("", "images", PAR_IMLIST(par,1))
	PAR_SKYLIST(par,1) = afn_cl ("", "images", PAR_IMLIST(par,1))
	PAR_SIGLIST(par,1) = afn_cl ("", "images", PAR_IMLIST(par,1))
	PAR_EXPLIST(par,1) = afn_cl ("", "images", PAR_IMLIST(par,1))
	PAR_GAINLIST(par,1) = afn_cl ("", "images", PAR_IMLIST(par,1))
	PAR_SCALELIST(par,1) = afn_cl ("", "files", PAR_IMLIST(par,1))
	PAR_SPTLLIST(par,1) = afn_cl ("", "images", PAR_IMLIST(par,1))

	PAR_IMLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_BPMLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_SKYLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_SIGLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_EXPLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_GAINLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))
	PAR_SCALELIST(par,2) = afn_cl ("", "files", PAR_IMLIST(par,2))
	PAR_SPTLLIST(par,2) = afn_cl ("", "images", PAR_IMLIST(par,2))

	PAR_INOMLIST(par) = afn_cl ("iobjmasks", "images", PAR_IMLIST(par,1))
	PAR_OUTOMLIST(par) = afn_cl ("oobjmasks", "images", PAR_IMLIST(par,1))
	PAR_OMTYPE(par) = OM_ALL
	PAR_INCATLIST(par) = afn_cl ("icatalogs", "images", PAR_IMLIST(par,1))
	PAR_OUTCATLIST(par) = afn_cl ("ocatalogs", "images", PAR_IMLIST(par,1))
	PAR_CATDEFLIST(par) = afn_cl ("", "files", PAR_IMLIST(par,1))
	PAR_LOGLIST(par) = afn_cl ("logfiles", "files", PAR_IMLIST(par,1))

	PAR_OUTSKYLIST(par) = afn_cl ("", "images", PAR_IMLIST(par,1))
	PAR_OUTSIGLIST(par) = afn_cl ("", "images", PAR_IMLIST(par,1))

	PAR_NMAXREC(par) = clgeti ("nmaxrec")
	PAR_VERBOSE(par) = clgeti ("verbose")

	PAR_UPDATE(par) = btoi (clgetb ("update"))

	call flt_pars ("open", "", PAR_FLT(par))
	call clgstr ("catomid", FLT_NUM(PAR_FLT(par)), FLT_NUMLEN)

	# Do the detection.
	call aceall (par)

	call flt_pars ("close", "", PAR_FLT(par))

	call afn_cls (PAR_OUTSIGLIST(par))
	call afn_cls (PAR_OUTSKYLIST(par))

	call afn_cls (PAR_LOGLIST(par))
	call afn_cls (PAR_INOMLIST(par))
	call afn_cls (PAR_OUTOMLIST(par))
	call afn_cls (PAR_CATDEFLIST(par))
	call afn_cls (PAR_INCATLIST(par))
	call afn_cls (PAR_OUTCATLIST(par))

	call afn_cls (PAR_SPTLLIST(par,2))
	call afn_cls (PAR_SCALELIST(par,2))
	call afn_cls (PAR_GAINLIST(par,2))
	call afn_cls (PAR_EXPLIST(par,2))
	call afn_cls (PAR_SIGLIST(par,2))
	call afn_cls (PAR_SKYLIST(par,2))
	call afn_cls (PAR_BPMLIST(par,2))
	call afn_cls (PAR_IMLIST(par,2))

	call afn_cls (PAR_SPTLLIST(par,1))
	call afn_cls (PAR_SCALELIST(par,1))
	call afn_cls (PAR_GAINLIST(par,1))
	call afn_cls (PAR_EXPLIST(par,1))
	call afn_cls (PAR_SIGLIST(par,1))
	call afn_cls (PAR_SKYLIST(par,1))
	call afn_cls (PAR_BPMLIST(par,1))
	call afn_cls (PAR_IMLIST(par,1))

	call sfree (sp)
end


# ACE_SHOW_CATDEF -- Show default catalog definition file.
procedure ace_show_catdef (show)

bool	show			#O Was show_catdef requested?

int	fd, clc_find(), locpr(), xt_txtopen(), getline()
pointer	sp, str
bool	clgetb()
extern	f_catdef()
errchk	xt_txtopen

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	show = false
	if (clc_find ("show_catdef", Memc[str], SZ_LINE) > 0) 
	    show = clgetb ("show_catdef")
	    
	if (show) {
	    call sprintf (Memc[str], SZ_LINE, "proc:%d")
		call pargi (locpr(f_catdef))
	    fd = xt_txtopen (Memc[str])
	    while (getline (fd, Memc[str]) != EOF)
		call putline (STDOUT, Memc[str])
	    call xt_txtclose (fd)
	}
	call sfree (sp)
end
