include	<acecat.h>
include	<aceobjs.h>
include	<aceobjs1.h>


procedure acefunc (cat, obj, id, type, val, otype)

pointer	cat			#I Catalog pointer
pointer	obj			#I Object pointer
int	id			#I Field ID
int	type			#O Data type
pointer	val			#O Pointer for return value
int	otype			#O Output data type

int	reclen1, id1, napr
real	a, b, theta, elong, ellip, r, cxx, cyy, cxy
real	aerr, berr, thetaerr, cxxerr, cyyerr, cxyerr
bool	doshape
pointer	obj1, objlast

begin
	if (obj == NULL)
	    return

	if (id <= 10000) {
	    val = obj + id
	    otype = type
	    return
	}

	reclen1 = CAT_RECLEN(cat) / CAT_NIM(cat)
	obj1 = obj + (id - 10001) / reclen1 * reclen1
	id1 = mod (id - 10001, reclen1) + 10001

	# Initialize for new object.
	if (obj1 != objlast) {
	    napr = 0
	    doshape = false
	}
	
	otype = TY_REAL
	switch (id1) {
	case ID_A, ID_B, ID_THETA, ID_ELONG, ID_ELLIP, ID_RR, ID_CXX,
	    ID_CYY, ID_CXY:
	    if (!doshape) {
		call catshape (obj1, a, b, theta, elong, ellip, r,
		    cxx, cyy, cxy, aerr, berr, thetaerr, cxxerr,
		    cyyerr, cxyerr)
		doshape = true
	    }
	    switch (id1) {
	    case ID_A:
		Memr[P2R(val)] = a
	    case ID_B:
		Memr[P2R(val)] = b
	    case ID_THETA:
		Memr[P2R(val)] = theta
	    case ID_ELONG:
		Memr[P2R(val)] = elong
	    case ID_ELLIP:
		Memr[P2R(val)] = ellip
	    case ID_RR:
		Memr[P2R(val)] = r
	    case ID_CXX:
		Memr[P2R(val)] = cxx
	    case ID_CYY:
		Memr[P2R(val)] = cyy
	    case ID_CXY:
		Memr[P2R(val)] = cxy
	    }
	case ID_FLUXERR, ID_XERR, ID_YERR:
	    switch (id1) {
	    case ID_FLUXERR:
		Memr[P2R(val)] = OBJ_FLUXVAR(obj1)
	    case ID_XERR:
		Memr[P2R(val)] = OBJ_XVAR(obj1)
	    case ID_YERR:
		Memr[P2R(val)] = OBJ_YVAR(obj1)
	    }
	    if (IS_INDEFR(Memr[P2R(val)]) || Memr[P2R(val)] < 0.)
		Memr[P2R(val)] = INDEFR
	    else
		Memr[P2R(val)] = sqrt (Memr[P2R(val)])
	case ID_AERR, ID_BERR, ID_THETAERR, ID_CXXERR, ID_CYYERR,
	    ID_CXYERR:
	    if (!doshape) {
		call catshape (obj1, a, b, theta, elong, ellip, r,
		    cxx, cyy, cxy, aerr, berr, thetaerr, cxxerr,
		    cyyerr, cxyerr)
		doshape = true
	    }
	    switch (id1) {
	    case ID_AERR:
		Memr[P2R(val)] = aerr
	    case ID_BERR:
		Memr[P2R(val)] = aerr
	    case ID_THETAERR:
		Memr[P2R(val)] = aerr
	    case ID_CXXERR:
		Memr[P2R(val)] = aerr
	    case ID_CYYERR:
		Memr[P2R(val)] = aerr
	    case ID_CXYERR:
		Memr[P2R(val)] = aerr
	    }
	}

	objlast = obj1
end
