*&---------------------------------------------------------------------*
*&  Include           ZXMBCU02
*&---------------------------------------------------------------------*
TABLES: MSEG,ZPCHK_temp,ZPCHK.

data zpchk_wa type ZPCHK.
data zinputdoc like ZPCHK-MBLNR.
data zinputdocline like ZPCHK-ZEILE.
data fieldvals type table of DYNPREAD with header line.
data buttonclick like sy-ucomm.



fieldvals-FIELDNAME = 'GODYNPRO-MAT_DOC'.
append fieldvals.

BUTTONCLICK = sy-ucomm.

case BUTTONCLICK.
  WHEN 'OK_POST1' or 'OK_CHECK' or 'OK_POST'.
if ( i_mseg-BWART = '315' ).
CALL FUNCTION 'DYNP_VALUES_READ'
  EXPORTING
    DYNAME                               ='SAPLMIGO' ""sy-CPROG ""'SAPLMIGO'
    DYNUMB                               ='2010' ""sy-DYNNR ""'2010'
*   TRANSLATE_TO_UPPER                   = ' '
*   REQUEST                              = ' '
*   PERFORM_CONVERSION_EXITS             = ' '
*   PERFORM_INPUT_CONVERSION             = ' '
*   DETERMINE_LOOP_INDEX                 = ' '
*   START_SEARCH_IN_CURRENT_SCREEN       = ' '
*   START_SEARCH_IN_MAIN_SCREEN          = ' '
*   START_SEARCH_IN_STACKED_SCREEN       = ' '
*   START_SEARCH_ON_SCR_STACKPOS         = ' '
*   SEARCH_OWN_SUBSCREENS_FIRST          = ' '
*   SEARCHPATH_OF_SUBSCREEN_AREAS        = ' '
  TABLES
    DYNPFIELDS                           = fieldvals
 EXCEPTIONS
   INVALID_ABAPWORKAREA                 = 1
   INVALID_DYNPROFIELD                  = 2
   INVALID_DYNPRONAME                   = 3
   INVALID_DYNPRONUMMER                 = 4
   INVALID_REQUEST                      = 5
   NO_FIELDDESCRIPTION                  = 6
   INVALID_PARAMETER                    = 7
   UNDEFIND_ERROR                       = 8
   DOUBLE_CONVERSION                    = 9
   STEPL_NOT_FOUND                      = 10
   OTHERS                               = 11
          .
IF SY-SUBRC <> 0.
* Implement suitable error handling here
ENDIF.

endif.
*SAPLMIGO 0001
data found type i.
found = 0 .
LOOP AT FIELDVALS.
  if ( fieldvals-FIELDNAME = 'GODYNPRO-MAT_DOC' ).
   ZINPUTDOC = fieldvals-FIELDVALUE.
   ZINPUTDOCLINE = 1 + ( i_mseg-line_id - 1 ) * 2 .
   endif.
  ENDLOOP.
if ( i_mseg-BWART = '315' ) . "movement for PIS

  SELECT * FROM ZPCHK.
      if ( ZPCHK-MBLNR  = zinputdoc AND ZPCHK-ZEILE = zinputdocline ).
          MESSAGE E001(ZMSG2) WITH ZPCHK-UNAME ZPCHK-DATEPOSTED ZPCHK-TIMEPOSTED.
          found  = 1 .
        endif.
    ENDSELECT.

endif.

ENDCASE.

CASE BUTTONCLICK.
  WHEN 'OK_POST1' OR 'OK_POST'.
    zpchk_wa-MANDT = sy-mandt.
    zpchk_wa-MBLNR = ZINPUTDOC.
    zpchk_wa-ZEILE = ZINPUTDOCLINE.
    zpchk_wa-POSTED = 'X'.
    ZPCHK_WA-DATEPOSTED = SY-DATUM.
    ZPCHK_WA-TIMEPOSTED = SY-UZEIT.
    ZPCHK_wa-UNAME =  SY-UNAME.

*    append zpchk_wa.
    if ( found = 0 ).
    insert into ZPCHK values zpchk_wa.
    endif.

    ENDCASE.