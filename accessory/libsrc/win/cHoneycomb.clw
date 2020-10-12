  MEMBER() 
  !PRAGMA('link(crypt32.lib)')
                   
  INCLUDE('EQUATES.CLW')
  INCLUDE('cHoneycomb.inc')

  MAP
     cHoneycombInternal_GetTempPath(),STRING
     MODULE('Win32')
       cHoneycomb_GetTempPath(LONG,*CSTRING),LONG,RAW,PASCAL,NAME('GetTempPathA')          
     END 
  END 


!-----------------------------------------
cHoneycomb.SetFlushInterval  PROCEDURE(LONG pSecs)
!-----------------------------------------

 CODE
 
 IF pSecs > 0 
    SELF.intFlushInterval = pSecs
 ELSIF SELF.intFlushInterval > 0
 ELSE
    SELF.intFlushInterval = 5
 END 
 
 SELF.CheckFlush() 
 
 RETURN 

  
!-----------------------------------------
cHoneycomb.SetAPIKey  PROCEDURE(STRING pAPIKey)
!-----------------------------------------

 CODE
 
 SELF.HoneycombAPIKey = CLIP(pAPIKey)
 SELF.CheckFlush() 
 
 RETURN 

!-----------------------------------------
cHoneycomb.SetDataset  PROCEDURE(STRING pDataset)
!-----------------------------------------

 CODE
 
 SELF.HoneycombDataset = CLIP(pDataset)
 
 SELF.CheckFlush() 
 
 RETURN 
 
!-----------------------------------------
cHoneycomb.CheckFlush  PROCEDURE()
!-----------------------------------------
intNextFlushTime LONG 
 CODE
 
 ! has it been more than SELF.intFlushInterval seconds since the last flush?
 intNextFlushTime = eqHoneyTime:Seconds * SELF.intFlushInterval + SELF.intLastFlushTime 
 
 IF intNextFlushTime < CLOCK() 
    SELF.intRC = SELF.Flush() 
 END

 RETURN 
 
!-----------------------------------------
cHoneycomb.SetTimestamp  PROCEDURE(<LONG pDate>,<LONG pTime>) 
!-----------------------------------------
rTimestamp    REAL 
!oUnixDate     UnixDate
oFmt          StringFormat
intToday      LONG 
intClock      LONG 
cstempdebug   CSTRING(1000)

 CODE
 
 IF OMITTED(pDate) = TRUE  
    intToday = TODAY() 
 END 
 
 IF OMITTED(pTime) = TRUE 
    intClock = CLOCK() 
 END 
 
 rTimestamp        = oFmt.ClarionToUnixDate(intToday,intClock,TRUE )
 SELF.strTimestamp = oFmt.FormatValue(rTimestamp, '@U2TM@D10-@T04')
 SELF.strTimestamp = CLIP(SELF.strTimestamp) & '.' & SUB(rTimestamp,-3,3) & 'Z'
 
 ! RFC3339 high precision format (e.g. YYYY-MM-DDTHH:MM:SS.mmmZ)
 ! @U2TM@D10-@T04
   
 RETURN 
 
 
!-----------------------------------------
cHoneycomb.SetHeadings      PROCEDURE(STRING pstrHeadings)!,LONG 
!-----------------------------------------
RemoveTheQuotes  EQUATE(TRUE)
ClipTheData      EQUATE(TRUE)
 CODE
 
 ! limited editing done by virtue of the ST.SPLIT. 
 FREE(SELF.oSTHoneyHeading)
 SELF.oSTHoneyHeading.SetValue(pstrHeadings) 
 SELF.oSTHoneyHeading.Split(',','"',,RemoveTheQuotes,ClipTheData)

 SELF.intRC = RECORDS(SELF.oSTHoneyHeading.lines)
 IF SELF.intRC > 0   ! should there be a minimum > 1?   Yes, kinda crude. 
    SELF.intRC = TRUE
 ELSE
    SELF.intRC = FALSE 
 END 
 
 SELF.CheckFlush() 
 
 RETURN SELF.intRC 

!-----------------------------------------
cHoneycomb.AddMetrics     PROCEDURE(STRING pstrMetrics)
!-----------------------------------------

 CODE
 
 SELF.CheckFlush() 
 
 RETURN 
 
!-----------------------------------------
cHoneycomb.AddLog         PROCEDURE(STRING pstrLog)
!-----------------------------------------

 CODE

 IF CLIP(SELF.HoneycombAPIKey) > ' ' AND CLIP(SELF.HoneycombDataset) > ' '
    SELF.SetTimestamp()
    
    IF SELF.oSTHoneyLog.Len() > 0
       SELF.oSTHoneyLog.Append(',{{ "created_at": "' & CLIP(SELF.strTimestamp) & '", "log": "' & CLIP(pstrLog) & '"}' & eqHoneyCRLF)
    ELSE
       SELF.oSTHoneyLog.Append('{{ "created_at": "' & CLIP(SELF.strTimestamp) & '", "log": "' & CLIP(pstrLog) & '"}' & eqHoneyCRLF)
    END 
    
    !SELF.oSTHoneyLog.Trace('input=' & CLIP(pstrLog))
    !SELF.oSTHoneyLog.Trace(CLIP(SELF.oSTHoneyLog.GetValue()))
        
 ELSE
    SELF.oSTHoneyLog.Trace('cHoneycomb.AddLog: no key (' & CLIP(SELF.HoneycombAPIKey) & ') or dataset (' & CLIP(SELF.HoneycombDataset) & ')' )
 END 
 
 SELF.CheckFlush() 
 
 RETURN 
 
!----------------------------------------------------------------------------------------------------------------
cHoneycomb.Flush          PROCEDURE()!,LONG 
!----------------------------------------------------------------------------------------------------------------
csTempPath           CSTRING(255)
strSavePath          STRING(255)
  CODE
  
  ! push log data to honeycomb

  IF CLIP(SELF.oSTHoneyLog.GetValue()) > ' '
     SELF.oSTHoneyLog.Trace('Log: [' )
     SELF.oSTHoneyLog.Trace(CLIP(SELF.oSTHoneyLog.GetValue()))
     SELF.oSTHoneyLog.Trace(']')
     
     SELF.oSTHoneyOut.SetValue('{{"logs":[' & CLIP(SELF.oSTHoneyLog.GetValue()) & ']}')
     csTempPath = cHoneycombInternal_GetTempPath()
     strSavePath = CLIP(csTempPath) & 'Honeylog-' & FORMAT(TODAY(),@D12) & '-' & FORMAT(CLOCK(),@T05) & '.json'
     SELF.oSTHoneyLog.Trace('Savepath=' & CLIP(strSavePath))
     SELF.oSTHoneyOut.SaveFile(strSavePath)
     SELF.oSTHoneyLog.SetValue('')
  END 
  ! push metrics data to honeycomb
  
  RUN('cmd /c python ./HoneyLog.py --logfile "' & CLIP(strSavePath) & '" --apikey "' & CLIP(SELF.HoneycombAPIKey) & '" --dataset "' & CLIP(SELF.HoneycombDataset))
    
  SELF.intLastFlushTime = CLOCK()  

  RETURN SELF.intRC 



!----------------------------------------------------------------------------------------------------------------
cHoneycomb.Init       PROCEDURE()
!----------------------------------------------------------------------------------------------------------------
  CODE

  RETURN

!----------------------------------------------------------------------------------------------------------------
cHoneycomb.Kill       PROCEDURE()
!----------------------------------------------------------------------------------------------------------------
  CODE
 
  SELF.Flush()  
  SELF.Destruct() 
  
  RETURN

!----------------------------------------------------------------------------------------------------------------
cHoneycomb.Construct  PROCEDURE()
!----------------------------------------------------------------------------------------------------------------
  
 CODE

 SELF.oSTHoneyLog      &= NEW(StringTheory)
 SELF.oSTHoneyMetrics  &= NEW(StringTheory)
 SELF.oSTHoneyHeading  &= NEW(StringTheory)
 SELF.oSTHoneyOut      &= NEW(StringTheory)
 
 SELF.intLastFlushTime = CLOCK() 
 SELF.intFlushInterval = 5 ! default flush
      
 RETURN


!----------------------------------------------------------------------------------------------------------------
cHoneycomb.Destruct   PROCEDURE()
!----------------------------------------------------------------------------------------------------------------
 CODE

 SELF.Flush()

 IF SELF.oSTHoneyOut &= NULL
 ELSE
    DISPOSE(SELF.oSTHoneyOut)
    SELF.oSTHoneyOut &= NULL
 END
 
 IF SELF.oSTHoneyLog &= NULL
 ELSE
    DISPOSE(SELF.oSTHoneyLog)
    SELF.oSTHoneyLog &= NULL
 END
 
 IF SELF.oSTHoneyMetrics &= NULL
 ELSE
    DISPOSE(SELF.oSTHoneyMetrics)
    SELF.oSTHoneyMetrics &= NULL
 END

 IF SELF.oSTHoneyHeading &= NULL
 ELSE
    DISPOSE(SELF.oSTHoneyHeading)
    SELF.oSTHoneyHeading &= NULL
 END

     
 RETURN

!------------------------------------------------------------
cHoneycombInternal_GetTempPath        PROCEDURE()!,STRING
!------------------------------------------------------------

csTempPath    CSTRING(255)
intSize       LONG 

strTempPath   STRING(255) 

 CODE
 
 intSize = cHoneycomb_GetTempPath(255,csTempPath)
 IF intSize <= 0 OR intSize > 255
    CLEAR(strTempPath)
 ELSE
    strTempPath = csTempPath[ 1 : intSize ]
 END
  
 RETURN(strTempPath)