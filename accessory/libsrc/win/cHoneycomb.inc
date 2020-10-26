        OMIT('_EndOfInclude_',_IFDef_cHoneycomb_)
_IFDef_cHoneycomb_          EQUATE(1)

   INCLUDE('StringTheory.inc'),ONCE
   
eqHoneyTime:Seconds EQUATE(100) 
eqHoneyCRLF         EQUATE('<13,10>')
 
                          
!--------------------------------------------------------------------------------
cHoneycomb   CLASS(StringTheory),TYPE,THREAD,MODULE('cHoneycomb.CLW'),LINK('cHoneycomb.CLW',_ABCLinkMode_),DLL(_ABCDllMode_)
!--------------------------------------------------------------------------------
!Properties
!----------

intRC                             LONG 
HoneycombAPIKey                   STRING(100)
HoneycombDataset                  STRING(100)
strTimestamp                      STRING(50)
intLastFlushTime                  LONG 
intFlushInterval                  LONG ! Seconds 
AutoFormatDate                    LONG 
AutoFormatTime                    LONG 
MergeDateAndTime                  LONG 

intZeroMetricsSuppression         LONG ! true/false
intZeroMetricsReportInterval      LONG ! seconds

CSVHeading                        STRING(512)

oSTHoneyHeading                   &StringTheory  ! used to manage headings
oSTHoneyLog                       &StringTheory  ! used to build incoming log of event data
oSTHoneyMetrics                   &StringTheory  ! used to write logged data to file for Honey
oSTHoneyOut                       &StringTheory  ! used to create output file
oSTWork                           &StringTheory  ! because you can never have too many StringTheorys - and for some temp work:)


  
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

SetAutoFormatDate                 PROCEDURE(LONG pAutoFormat)
SetAutoFormatTime                 PROCEDURE(LONG pAutoFormat)
SetMergeDateAndTime               PROCEDURE(LONG pMergeDateTime)

Flush                             PROCEDURE(),LONG 
FlushLog                          PROCEDURE(),LONG 
FlushMetrics                      PROCEDURE(),LONG 
CheckFlush                        PROCEDURE() 
SetFlushInterval                  PROCEDURE(LONG pSecs)

    END 

        _EndOfInclude_
        