*&---------------------------------------------------------------------*
*& Report  ZPROJECT_UPLOAD
*& Author: Cyril Sayeh ( Catalyst  ) 07066112584 08109255546
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT ZPROJECT_UPLOAD.
TYPE-POOLS: SLIS.
*Structure for project upload format
types: begin of proj_def.
        include structure BAPI_PROJECT_DEFINITION.
types: end of proj_def.

*administrator error
types: begin of admin_error,
  lights(1) TYPE c,
  error_flag type string,
  msgno type string,
  message(200) type c,
  end of  admin_error.
data l_err type i value 0.

DATA: gs_alv TYPE admin_error,
     gt_alv TYPE TABLE OF admin_error,
     gr_alv TYPE REF TO cl_salv_table,
     gr_columns TYPE REF TO cl_salv_columns_table.
data: status(1) type c,
      message(100) type c.

data: ad_error type table of admin_error,
      ad_str like line of ad_error.

*structure for wbs element upload format.
types: begin of wbs_def,
        proj_def type BAPI_BUS2001_NEW-PROJECT_DEFINITION.
        include structure BAPI_BUS2054_NEW.
types: end of wbs_def.

types: begin of net_header,
        legacyno like zps_leg_rec-legacy_number.
        include structure BAPI_BUS2002_NEW.
types: end of net_header.

types: begin of net_activity,
*  legacyno like zps_leg_rec-legacy_number,
  i_network like BAPI_NETWORK_LIST-NETWORK.
        include structure BAPI_BUS2002_ACT_NEW.
types: end of net_activity.

data error_flag type c.
*messages and structures for upload.
data:
      projmsgs type table of BAPI_METH_MESSAGE with header line,
      projret type BAPIRETURN1,
      nethret type table of BAPIRET2 with header line,
      preret type table of BAPIRET2 with header line,
      tranret type table of BAPIRET2 with header line,
      projstruc type bapi_project_definition,
      wbsstrc type  bapi_bus2054_new,
      wbsstruc type table of bapi_bus2054_new with header line,
      nethstruc type BAPI_BUS2002_NEW,
      actstruc type BAPI_BUS2002_ACT_NEW.

data tmp_activity type CN_VORNR.
data tmp_network like BAPI_NETWORK_LIST-NETWORK.
data tmp_network2 like BAPI_NETWORK_LIST-NETWORK.

DATA leg_rec type zps_leg_rec.

*Selection screen
selection-screen begin of block b1 with frame title text-000.
parameters:
papfname type ibipparms-path memory id a,
pawfname type ibipparms-path memory id b,
panhname type ibipparms-path memory id e,
panfname type ibipparms-path memory id c.
*paafname type ibipparms-path memory id d.

selection-screen end of block b1.
selection-screen begin of block b4 with frame title text-003.
parameters:
pa_leg type check.
selection-screen end of block b4.

selection-screen begin of block b2 with frame title text-001.
parameters:
  papchk type check,
  pawchk type check,
  panhchk type check,
  panchk type check.
*  paachk type check.
selection-screen end of block b2.

selection-screen begin of block b3 with frame title text-002.
parameters:
  pa_user like sy-UNAME default sy-UNAME,
  pa_date like sy-DATUM default sy-DATUM.
selection-screen end of block b3.




data: gr_table   type ref to cl_salv_table.


*data declaration
data:
      dtpfname type string,
      dtwfname type string,
      dtnhname type string,
      dtnfname type string,
      dtnfnam2 type RLGRAP-FILENAME,
      dtafname type string,
      dtpflen type i,
      dtwflen type i,
      dtnhlen type i,
      dtnflen type i,
      dtaflen type i.

data errstr like line of NETHRET.
*internal table for upload
data: projdef_tab type table of proj_def with header line,
      wbselem_tab type table of wbs_def with header line,
      nethead_tab type table of net_header with header line,
      netact_tab type table of net_activity with header line,
      act_tab type table of BAPI_BUS2002_ACT_NEW with header line.


* Process file upload
at selection-screen on value-request for papfname.
  CALL FUNCTION 'F4_FILENAME'
    IMPORTING
      FILE_NAME = papfname.

at selection-screen on value-request for pawfname.
  CALL FUNCTION 'F4_FILENAME'
    IMPORTING
      FILE_NAME = pawfname.

at selection-screen on value-request for panhname.
  CALL FUNCTION 'F4_FILENAME'
    IMPORTING
      FILE_NAME = panhname.

at selection-screen on value-request for panfname.
  CALL FUNCTION 'F4_FILENAME'
    IMPORTING
      FILE_NAME = panfname.

start-of-selection.


* after upload display in alv
*perform displayalv using PROJDEF_TAB[] 'PROJ_DEF'.

  if ( papchk = 'X' ).
    perform projects.

  endif.

  if ( PAWCHK = 'X' ).
    perform wbselements.
  endif.

  if ( panhchk = 'X' ).
    perform networkheaders.
  endif.
  if ( panchk = 'X' ).
    perform networkactivity.
  endif.

form displayalv using table type STANDARD TABLE tablename
      type SLIS_TABNAME.
  data: repid type sy-repid.



  repid = sy-repid.
  data int_fcat type SLIS_T_FIELDCAT_ALV.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      I_PROGRAM_NAME         = repid
      I_INTERNAL_TABNAME     = tablename"capital letters!
      I_INCLNAME             = repid
*     I_STRUCTURE_NAME       =  projdef_tab
    CHANGING
      CT_FIELDCAT            = int_fcat
    EXCEPTIONS
      INCONSISTENT_INTERFACE = 1
      PROGRAM_ERROR          = 2
      OTHERS                 = 3.

  CALL FUNCTION 'REUSE_ALV_LIST_DISPLAY'
    EXPORTING
      I_CALLBACK_PROGRAM = repid
      IT_FIELDCAT        = int_fcat
      I_SAVE             = 'A'
    TABLES
      T_OUTTAB           = table
    EXCEPTIONS
      PROGRAM_ERROR      = 1
      OTHERS             = 2.

endform.

form displayalv2 using table type standard table.

  try.
      cl_salv_table=>factory(
        importing
          r_salv_table = gr_table
        changing
          t_table      = table ).
    catch cx_salv_msg.                                  "#EC NO_HANDLER
  endtry.
  gr_table->display( ).
endform.

form uploadprojects.
  CLEAR AD_ERROR[].
  loop at PROJDEF_TAB.
    MOVE-CORRESPONDING PROJDEF_TAB to PROJSTRUC.


    CALL FUNCTION 'BAPI_PS_INITIALIZATION'
      .


    CALL FUNCTION 'BAPI_PROJECTDEF_CREATE'
      EXPORTING
        PROJECT_DEFINITION_STRU = projstruc
      IMPORTING
        RETURN                  = projret
      TABLES
        E_MESSAGE_TABLE         = projmsgs.

*    perform checkforerror tables projret using error_flag.

    if ( projret-TYPE = 'E' ).
      ERROR_FLAG = 'Y'.
      AD_STR-ERROR_FLAG = 'E'.
      ad_str-lights = '1'.
      concatenate 'E00X' '' into ad_str-MSGNO.
*      concatenate PROJSTRUC-PROJECT_DEFINITION ' could not created contact System administrator for error analysis' into AD_STR-MESSAGE.
      concatenate projret-message ' for ' projstruc-project_definition '. Contact your system administrator!' into ad_str-message SEPARATED BY space.
*      ad_str-MESSAGE = PROJRET-MESSAGE.
      APPEND AD_STR TO AD_ERROR.


    else.
      ERROR_FLAG = 'N'.
      AD_STR-ERROR_FLAG = 'S'.
      ad_str-lights = '3'.
      concatenate 'S00X' '' into ad_str-MSGNO.
      concatenate 'Project Definition ' PROJSTRUC-PROJECT_DEFINITION ' created successfully!' into AD_STR-MESSAGE.

      APPEND AD_STR TO AD_ERROR.


      CALL FUNCTION 'BAPI_PS_PRECOMMIT'
        TABLES
          ET_RETURN = NETHRET.

      PERFORM checkforerror tables nethret using error_flag.
      if ( error_flag = 'Y' ).
        LOOP AT NETHRET.
          ERROR_FLAG = 'Y'.
          AD_STR-ERROR_FLAG = 'E'.
          ad_str-lights = '1'.
          concatenate 'E00X' '' into ad_str-MSGNO.
          AD_STR-MESSAGE = NETHRET-MESSAGE.
          APPEND AD_STR TO AD_ERROR.
        ENDLOOP.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
*         IMPORTING
*           RETURN        =
  .
      ELSE.
        LOOP AT NETHRET.
          ERROR_FLAG = 'N'.
          AD_STR-ERROR_FLAG = 'S'.
          ad_str-lights = '3'.
          concatenate 'S00X' '' into ad_str-MSGNO.
          AD_STR-MESSAGE = NETHRET-MESSAGE.
          APPEND AD_STR TO AD_ERROR.
        ENDLOOP.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
*     EXPORTING
*       WAIT          =
*     IMPORTING
*       RETURN        =
                  .
*      COMMIT WORK.
      ENDIF.
    endif.
    CALL METHOD cl_salv_table=>factory
      IMPORTING
        r_salv_table = gr_alv
      CHANGING
        t_table      = ad_error.
    gr_columns = gr_alv->get_columns( ).
    gr_columns->set_exception_column( value = 'LIGHTS' ).

  endloop.

endform.

form uploadwbselements.
  CLEAR AD_ERROR[].
  loop at wbselem_tab.
    clear:
      wbsstruc.
    refresh:
      wbsstruc[].

    move-CORRESPONDING wbselem_tab to wbsstruc.
    append wbsstruc.


    CALL FUNCTION 'BAPI_PS_INITIALIZATION'.


    CALL FUNCTION 'BAPI_BUS2054_CREATE_MULTI'
      EXPORTING
        I_PROJECT_DEFINITION = wbselem_tab-proj_def
      TABLES
        IT_WBS_ELEMENT       = wbsstruc
        ET_RETURN            = NETHRET
*       EXTENSIONIN          =
*       EXTENSIONOUT         =
      .

    PERFORM checkforerror tables nethret using error_flag.
    if ( error_flag = 'Y' ).
      loop at nethret.
        AD_STR-MSGNO = 'E000X'.
        AD_STR-ERROR_FLAG = 'E'.
        ad_str-LIGHTS = '1'.
*        CONCATENATE 'Error trying to create wbs element ' wbsstruc-WBS_ELEMENT ' contact your administrator' into ad_str-MESSAGE SEPARATED BY space.
        ad_str-MESSAGE = nethret-MESSAGE.
        append ad_str to AD_ERROR.
      endloop.
    ELSE.
      loop at nethret.
        AD_STR-MSGNO = 'S000X'.
        AD_STR-ERROR_FLAG = 'S'.
        ad_str-LIGHTS = '3'.
*      CONCATENATE 'WBS Element ' wbsstruc-WBS_ELEMENT ' created successfully!' into ad_str-MESSAGE SEPARATED BY space.
        ad_str-message = nethret-MESSAGE.
        append ad_str to AD_ERROR.
      endloop.
      CALL FUNCTION 'BAPI_PS_PRECOMMIT'
        TABLES
          ET_RETURN = NETHRET.
      PERFORM checkforerror tables nethret using error_flag.
      if ( error_flag = 'Y' ).
        loop at nethret.
          AD_STR-MSGNO = 'E000X'.
          AD_STR-ERROR_FLAG = 'E'.
          ad_str-LIGHTS = '1'.
*        CONCATENATE 'Error trying to create wbs element ' wbsstruc-WBS_ELEMENT ' contact your administrator' into ad_str-MESSAGE SEPARATED BY space.
          ad_str-MESSAGE = nethret-MESSAGE.
          append ad_str to AD_ERROR.
        endloop.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
*         IMPORTING
*           RETURN        =
  .
      ELSE.
        loop at nethret.
          AD_STR-MSGNO = 'S000X'.
          AD_STR-ERROR_FLAG = 'S'.
          ad_str-LIGHTS = '3'.
*      CONCATENATE 'WBS Element ' wbsstruc-WBS_ELEMENT ' created successfully!' into ad_str-MESSAGE SEPARATED BY space.
          ad_str-message = nethret-MESSAGE.
          append ad_str to AD_ERROR.
        endloop.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
*     EXPORTING
*       WAIT          =
*     IMPORTING
*       RETURN        =
    .
*      COMMIT WORK.
      ENDIF.
    endif.
    CALL METHOD cl_salv_table=>factory
      IMPORTING
        r_salv_table = gr_alv
      CHANGING
        t_table      = ad_error.
    gr_columns = gr_alv->get_columns( ).
    gr_columns->set_exception_column( value = 'LIGHTS' ).

    wait up to 1 SECONDS.
  endloop.
endform.

form uploadnetheaders.

  CLEAR AD_ERROR[].
  loop at nethead_tab.
    clear:
      nethstruc.
*    refresh:
*      nethstruc[].

    move-CORRESPONDING nethead_tab to nethstruc.
    append wbsstruc.


    CALL FUNCTION 'BAPI_PS_INITIALIZATION'.

    CALL FUNCTION 'BAPI_BUS2002_CREATE'
      EXPORTING
        I_NETWORK    = nethstruc
      TABLES
        ET_RETURN    = nethret
*       EXTENSIONIN  =
*       EXTENSIONOUT =
      .

    .
    PERFORM checkforerror tables nethret using error_flag.

    if ( error_flag = 'Y' ).
      loop at nethret.
        AD_STR-MSGNO = 'E000X'.
        AD_STR-ERROR_FLAG = 'E'.
        AD_STR-LIGHTS = '1'.
*        CONCATENATE 'Error trying to create network ' nethstruc-NETWORK ' contact your administrator' into ad_str-MESSAGE.
        AD_STR-MESSAGE = NETHRET-MESSAGE.
        append ad_str to AD_ERROR.
      endloop.
    ELSE.
      loop at nethret.
        AD_STR-MSGNO = 'S000X'.
        AD_STR-ERROR_FLAG = 'S'.
        AD_STR-LIGHTS = '3'.
*        CONCATENATE 'Error trying to create network ' nethstruc-NETWORK ' contact your administrator' into ad_str-MESSAGE.
        AD_STR-MESSAGE = NETHRET-MESSAGE.
        append ad_str to AD_ERROR.
      endloop.
      clear nethret[].
      refresh nethret[].
      CALL FUNCTION 'BAPI_PS_PRECOMMIT'
        TABLES
          ET_RETURN = nethret.

      PERFORM checkforerror tables nethret using error_flag.

      IF ( ERROR_FLAG = 'N' ).
        loop at nethret.
          AD_STR-MSGNO = 'S000X'.
          AD_STR-ERROR_FLAG = 'S'.
          ad_str-LIGHTS = '3'.
*      CONCATENATE 'Network ' NETHSTRUC-NETWORK ' created successfully!' into ad_str-MESSAGE SEPARATED BY space.
          AD_STR-MESSAGE = NETHRET-MESSAGE.
          append ad_str to AD_ERROR.

          IF ( NETHRET-TYPE = 'S' AND NETHRET-ID = 'CNIF_PI' AND NETHRET-NUMBER = '003' ).
            LEG_REC-MANDT = SY-MANDT .
            LEG_REC-FIELDTYPE = 'NETWORK'.
            LEG_REC-LEGACY_NUMBER = NETHEAD_TAB-LEGACYNO.
            LEG_REC-SAP_NUMBER = NETHRET-MESSAGE_V2.

            INSERT INTO ZPS_LEG_REC VALUES LEG_REC.

          ENDIF.
        endloop.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
*     EXPORTING
*       WAIT          =
       IMPORTING
         RETURN        = NETHRET
    .
      ELSE.
        loop at nethret.
          AD_STR-MSGNO = 'E000X'.
          AD_STR-ERROR_FLAG = 'E'.
          AD_STR-LIGHTS = '1'.
*        CONCATENATE 'Error trying to create network ' nethstruc-NETWORK ' contact your administrator' into ad_str-MESSAGE.
          AD_STR-MESSAGE = NETHRET-MESSAGE.
          append ad_str to AD_ERROR.
        endloop.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
*         IMPORTING
*           RETURN        =
                  .

      ENDIF.

    endif.
    CALL METHOD cl_salv_table=>factory
      IMPORTING
        r_salv_table = gr_alv
      CHANGING
        t_table      = ad_error.
    gr_columns = gr_alv->get_columns( ).
    gr_columns->set_exception_column( value = 'LIGHTS' ).

    wait up to 1 seconds.
  endloop.
endform.
data nt_len type i.
data ct_len type i value 0.
form uploadnetactivity.
  CLEAR AD_ERROR[].
  describe table netact_tab lines nt_len.
  loop at netact_tab.
    add 1 to ct_len.
    clear: actstruc .
*    refresh: act_tab[].
    if ( PA_LEG = 'X' ) . ""25/01/2015 if legacy number is checked then get the sap number for the network header
      select sap_number from zps_leg_rec into tmp_network2 where legacy_number = netact_tab-I_NETWORK and fieldtype = 'NETWORK'.

      endselect.
      netact_tab-I_NETWORK = tmp_network2.

    endif.
    MOVE-CORRESPONDING NETACT_TAB to ACTSTRUC.
    if ( tmp_network is initial ).
      tmp_network = netact_tab-i_network.
*      append actstruc to act_tab.
    endif.
    if ( tmp_network = netact_tab-i_network or tmp_network is initial ).
      append actstruc to act_tab.

      if ( ct_len = nt_len ).
        perform call_bapi_network_activity.
      endif.
    else.


*    if ( tmp_network <> NETACT_TAB-I_NETWORK or tmp_network is initial ).
*    TMP_network = netact_tab-i_network.




*    else.
      perform call_bapi_network_activity.

*reset and set for the next iteration
      clear act_tab[]. refresh act_tab[].
      append actstruc to act_tab.
      TMP_NETWORK = netact_tab-I_NETWORK.

      if ( ct_len = nt_len ).
        perform call_bapi_network_activity.
      endif.

    endif.
    wait up to 1 seconds.
  endloop.

endform.

form projects.
  dtpfname = papfname.
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename            = dtpfname
      filetype            = 'ASC'
      has_field_separator = 'X'
    IMPORTING
      filelength          = dtpflen
    TABLES
      data_tab            = projdef_tab.

  perform uploadprojects.
*  l_err = 0.
*  describe table ad_error lines l_err.
*  IF ( l_err > 0 ).
*    perform displayalv2 using AD_ERROR[].
*  ELSE.
*    perform displayalv2 using projdef_tab[].
*  ENDIF.

*perform displayalv2 using AD_ERROR[].
  CALL METHOD gr_alv->display.
  perform displayalv2 using projdef_tab[].
endform.

form wbselements.
  dtwfname = pawfname.
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename            = dtwfname
      filetype            = 'ASC'
      has_field_separator = 'X'
    IMPORTING
      filelength          = dtwflen
    TABLES
      data_tab            = wbselem_tab.

  perform uploadwbselements.
* l_err = 0.
*  describe table ad_error lines l_err.
*  IF ( l_err > 0 ).
*    perform displayalv2 using AD_ERROR[].
*    else.
*    perform displayalv2 using wbselem_tab[].
*  endif.

  CALL METHOD gr_alv->display.
  perform displayalv2 using wbselem_tab[].
endform.

form networkheaders.
  dtnhname = PANHNAME.
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename            = dtnhname
      filetype            = 'ASC'
      has_field_separator = 'X'
    IMPORTING
      filelength          = dtnhlen
    TABLES
      data_tab            = nethead_tab.
  perform uploadnetheaders.
*  if ( error_flag = 'Y' ).
*    perform displayalv2 using AD_ERROR[].
*  else.
*    perform displayalv2 using nethead_tab[].
*  endif.
  CALL METHOD gr_alv->display.
  perform displayalv2 using nethead_tab[].
endform.

form networkactivity.
  dtnfname = panfname.
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename            = dtnfname
      filetype            = 'ASC'
      has_field_separator = 'X'
    IMPORTING
      filelength          = dtnflen
    TABLES
      data_tab            = netact_tab.
  perform uploadnetactivity.
*  if ( error_flag = 'Y' ).
*    perform displayalv2 using AD_ERROR[].
*  else.
*    perform displayalv2 using netact_tab[].
*  endif.
  CALL METHOD gr_alv->display.
  perform displayalv2 using netact_tab[].


endform.

FORM NETWORKACTIVITY2.
  dtnfnam2 = panfname.
  CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      FILENAME                = dtnfnam2
      I_BEGIN_COL             = 1
      I_BEGIN_ROW             = 2
      I_END_COL               = 122
      I_END_ROW               = 99999
    TABLES
      INTERN                  = netact_tab
    EXCEPTIONS
      INCONSISTENT_PARAMETERS = 1
      UPLOAD_OLE              = 2
      OTHERS                  = 3.
  IF SY-SUBRC <> 0.
* Implement suitable error handling here
  else.
    perform displayalv2 using netact_tab[].
  ENDIF.

endform.



form checkforerror TABLES msgtab type STANDARD TABLE using is_error type C.
  is_error = 'NO'.
  loop at msgtab into ERRSTR.
    if ( errstr-TYPE = 'E' ).
      is_error = 'YES'.
    endif.
  endloop.
endform.

FORM CALL_BAPI_NETWORK_ACTIVITY.
  CALL FUNCTION 'BAPI_PS_INITIALIZATION'
    .


  CALL FUNCTION 'BAPI_BUS2002_ACT_CREATE_MULTI'
    EXPORTING
      I_NUMBER     = TMP_NETWORK
    TABLES
      IT_ACTIVITY  = act_tab
      ET_RETURN    = nethret
*     EXTENSIONIN  =
*     EXTENSIONOUT =
    .
  data l type i.

  describe table nethret lines l.
  PERFORM checkforerror tables nethret using error_flag.
  if ( error_flag = 'N' ).
    LOOP AT NETHRET.
      AD_STR-MSGNO = 'S000X'.
      AD_STR-ERROR_FLAG = 'S'.
      ad_str-LIGHTS = '3'.
*      CONCATENATE 'Network activity '  NETACT_TAB-i_network ' created successfully!' into ad_str-MESSAGE SEPARATED BY space.
      AD_STR-MESSAGE = NETHRET-MESSAGE.
      append ad_str to AD_ERROR.

    ENDLOOP.


    CALL FUNCTION 'BAPI_PS_PRECOMMIT'
      TABLES
        ET_RETURN = preret.

    PERFORM checkforerror tables preret using error_flag.
    if ( error_flag = 'Y' ).
      LOOP AT PRERET.
        concatenate 'E00X' '' into ad_str-MSGNO.
*      concatenate NETACT_TAB-i_network ' activity could not created contact System administrator for error analysis' into AD_STR-MESSAGE.
        ad_str-lights = '1'.
        ad_str-message = PRERET-MESSAGE.
        append ad_str to AD_ERROR.
      ENDLOOP.
*        perform displayalv2 using preret[].
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
*         IMPORTING
*           RETURN        =
                .

    else.
      LOOP AT PRERET.
        AD_STR-MSGNO = 'S000X'.
        AD_STR-ERROR_FLAG = 'S'.
        ad_str-LIGHTS = '3'.
*      CONCATENATE 'Network activity '  NETACT_TAB-i_network ' created successfully!' into ad_str-MESSAGE SEPARATED BY space.
        AD_STR-MESSAGE = PRERET-MESSAGE.
        append ad_str to AD_ERROR.

      ENDLOOP.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
*     EXPORTING
*       WAIT          =
 IMPORTING
   RETURN        = tranret
.
      PERFORM checkforerror tables tranret using error_flag.
*        if ( error_flag = 'N').
*          COMMIT WORK.
*        else.
**          perform displayalv2 using tranret[].
*        endif.
    endif.
  else.
*      perform displayalv2 using nethret[].
    loop at nethret.
      AD_STR-ERROR_FLAG = 'E'.
      concatenate 'M00X' '' into ad_str-MSGNO.
*      concatenate NETACT_TAB-i_network ' activity could not created contact System administrator for error analysis' into AD_STR-MESSAGE.
      ad_str-lights = '1'.
      ad_str-message = NETHRET-MESSAGE.
      append ad_str to AD_ERROR.
    endloop.
  endif.
  CALL METHOD cl_salv_table=>factory
    IMPORTING
      r_salv_table = gr_alv
    CHANGING
      t_table      = ad_error.
  gr_columns = gr_alv->get_columns( ).
  gr_columns->set_exception_column( value = 'LIGHTS' ).

endform.