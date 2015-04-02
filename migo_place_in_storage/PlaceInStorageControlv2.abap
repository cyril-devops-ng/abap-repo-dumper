*&---------------------------------------------------------------------*
*&  Include           ZXMBCU02
*&---------------------------------------------------------------------*

 select MAX( mblnr ) from MSEG into ZINPUTDOCOLD where mblnr like '49%'. "fetch the current max mat doc num

   fieldvals-FIELDNAME = 'GODYNPRO-MAT_DOC'.
  append fieldvals.

  BUTTONCLICK = sy-ucomm.

  case BUTTONCLICK.
    WHEN 'OK_POST1' or 'OK_CHECK' or 'OK_POST'.

      CALL FUNCTION 'DYNP_VALUES_READ'
        EXPORTING
          DYNAME
          ='SAPLMIGO' ""sy-CPROG ""'SAPLMIGO'
          DYNUMB
          ='2010' ""sy-DYNNR ""'2010'
*         TRANSLATE_TO_UPPER             = ' '
*         REQUEST                        = ' '
*         PERFORM_CONVERSION_EXITS       = ' '
*         PERFORM_INPUT_CONVERSION       = ' '
*         DETERMINE_LOOP_INDEX           = ' '
*         START_SEARCH_IN_CURRENT_SCREEN = ' '
*         START_SEARCH_IN_MAIN_SCREEN    = ' '
*         START_SEARCH_IN_STACKED_SCREEN = ' '
*         START_SEARCH_ON_SCR_STACKPOS   = ' '
*         SEARCH_OWN_SUBSCREENS_FIRST    = ' '
*         SEARCHPATH_OF_SUBSCREEN_AREAS  = ' '
        TABLES
          DYNPFIELDS                     = fieldvals
        EXCEPTIONS
          INVALID_ABAPWORKAREA           = 1
          INVALID_DYNPROFIELD            = 2
          INVALID_DYNPRONAME             = 3
          INVALID_DYNPRONUMMER           = 4
          INVALID_REQUEST                = 5
          NO_FIELDDESCRIPTION            = 6
          INVALID_PARAMETER              = 7
          UNDEFIND_ERROR                 = 8
          DOUBLE_CONVERSION              = 9
          STEPL_NOT_FOUND                = 10
          OTHERS                         = 11.
      IF SY-SUBRC <> 0.
* Implement suitable error handling here
      ENDIF.


*SAPLMIGO 0001
      data found type i.
      found = 0 .
      LOOP AT FIELDVALS.
        if ( fieldvals-FIELDNAME = 'GODYNPRO-MAT_DOC' ).
          ZINPUTDOC = fieldvals-FIELDVALUE.
          ZINPUTDOCLINE = 1 + ( i_mseg-line_id - 1 ) * 2 .
        endif.
      ENDLOOP.
      "movement for PIS
      if ( i_mseg-BWART = '315' or i_mseg-BWART = '305'  ).
      SELECT * FROM ZPCHK.
        if ( ZPCHK-MBLNR  = zinputdoc AND ZPCHK-ZEILE = zinputdocline ).
          MESSAGE E001(ZMSG2) WITH ZPCHK-UNAME ZPCHK-DATEPOSTED ZPCHK-TIMEPOSTED.
          found  = 1 .
        endif.
      ENDSELECT.
      endif.


  ENDCASE.


if ( i_mseg-BWART = '315' or i_mseg-BWART = '305'  ).

  CASE BUTTONCLICK.
    WHEN 'OK_POST1' OR 'OK_POST'.
      zpchk_wa-MANDT = sy-mandt.
      zpchk_wa-MBLNR = ZINPUTDOC.
      zpchk_wa-ZEILE = ZINPUTDOCLINE.
      zpchk_wa-POSTED = 'X'.
      ZPCHK_WA-DATEPOSTED = SY-DATUM.
      ZPCHK_WA-TIMEPOSTED = SY-UZEIT.
      ZPCHK_wa-UNAME =  SY-UNAME.
      zpchk_wa-new_mblnr = i_mseg-mblnr.
     zpchk_wa-menge = i_mseg-menge.
     zpchk_wa-meins = i_mseg-meins.
*    append zpchk_wa.
      if ( found = 0 ). "if it does not exist in check table then add it to check table
        "check to ensure that a material document has been generated

        "assuming all the quantity in the removed in storage document is posted
        wait up to 1 SECONDS.
        if ( zinputdoc >= zinputdocold ).
        zinputdocnew = zinputdoc + 1. "new document is always +1 of old  document.
        else.
          zinputdocnew = zinputdocold + 1.
          endif.

        select single * from MSEG where mblnr = zinputdocnew.
*        if ( sy-subrc = 0 ). ""if a new document has been created then
          insert into ZPCHK_TEMP values zpchk_wa.
*        else.
*        endif.
      endif.

  ENDCASE.
endif.

if ( i_mseg-BWART = '306' or i_mseg-BWART = '316').
*  for cancellation
   delete from ZPCHK WHERE NEW_MBLNR = ZINPUTDOC AND ZEILE = ZINPUTDOCLINE.

  endif.