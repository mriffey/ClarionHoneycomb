        OMIT('_EndOfInclude_',_IFDef_cHoneycomb_)
_IFDef_cHoneycomb_          EQUATE(1)

   INCLUDE('StringTheory.inc')
   
Time:Seconds EQUATE(100) 
eqCRLF       EQUATE('<13,10>')
 
                          
!--------------------------------------------------------------------------------
cHoneycomb   CLASS(StringTheory),TYPE,THREAD,MODULE('cHoneycomb.CLW'),LINK('cHoneycomb.CLW',_ABCLinkMode_),DLL(_ABCDllMode_)
!
!--------------------------------------------------------------------------------
!Properties
!----------

intRC                             LONG 
HoneycombAPIKey                   STRING(100)
HoneycombDataset                  STRING(100)
strTimestamp                      STRING(50)
intLastFlushTime                  LONG 
intFlushInterval                  LONG ! Seconds 

CSVHeading                        STRING(512)

oSTHoneyHeading                   &StringTheory  ! used to manage headings
oSTHoneyLog                       &StringTheory  ! used to build incoming log of event data
oSTHoneyMetrics                   &StringTheory  ! used to write logged data to file for Honey
oSTHoneyOut                       &StringTheory  ! used to create output file


  
!--------------------------------------------------------------------------------
!Methods
!-------
Init                              PROCEDURE()
Kill                              PROCEDURE()
Construct                         PROCEDURE()
Destruct                          PROCEDURE()

AddLog                            PROCEDURE(STRING pstrLog)
AddMetrics                        PROCEDURE(STRING pstrMetrics)

SetAPIKey                         PROCEDURE(STRING pstrAPIKey)
SetDataset                        PROCEDURE(STRING pstrDataset)
SetHeadings                       PROCEDURE(STRING pstrHeadings),LONG
SetTimestamp                      PROCEDURE(<LONG pDate>,<LONG pTime>)

Flush                             PROCEDURE(),LONG 
CheckFlush                        PROCEDURE() 
SetFlushInterval                  PROCEDURE(LONG pSecs)

    END 

        _EndOfInclude_
        