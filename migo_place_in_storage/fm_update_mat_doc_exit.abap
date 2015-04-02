*&---------------------------------------------------------------------*
*&  Include           ZXMBCU01
*&---------------------------------------------------------------------*
*MESSAGE I000(ZMSG2).

*data: zpchk_tab type table of zpchk,
*      zpchk_line like line of zpchk_tab.
data mblnr1 like zpchk-mblnr.
*data zpchk_wa type ZPCHK.


select max( mblnr ) into mblnr1 from MSEG WHERE mblnr like '49%'.
*
if ( sy-subrc = 0 ).

endif.





if ( sy-subrc = 0 ).
  select * from zpchk_temp into zpchk_wa.
     zpchk_wa-new_mblnr = mblnr1.
    insert into zpchk values zpchk_wa .
  ENDSELECT.

endif.


*insert into zpchk values zpchk_wa .

delete from zpchk_temp where mblnr = zpchk_wa-mblnr.
*
*append zpchk_line to zpchk_tab.