  MEMBER() 
  !PRAGMA('link(crypt32.lib)')
                   
  INCLUDE('EQUATES.CLW')
  INCLUDE('cHoneycomb.inc')
  
RemoveTheQuotes      EQUATE(TRUE)
DontRemoveTheQuotes  EQUATE(FALSE)
ClipTheData          EQUATE(TRUE)  

intLoop              LONG,THREAD 

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
    SELF.intFlushInterval = 30
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
 
 IF intNextFlushTime < CLOCK() OR CLOCK() < SELF.intLastFlushTime ! we passed a flush interval, or rolled across midnight
    IF SELF.oSTHoneyLog.Len() > 0 OR SELF.oSTHoneyMetrics.Len() > 0
       SELF.intRC = SELF.Flush() 
    END 
 END

 RETURN 
 
!-----------------------------------------
cHoneycomb.SetTimestamp  PROCEDURE(<LONG pDate>,<LONG pTime>) 
!-----------------------------------------
rTimestamp    REAL 
oFmt          StringFormat
intToday      LONG 
intClock      LONG 

 CODE
  
 IF OMITTED(pDate) = TRUE  
    intToday = TODAY() 
 ELSE
    intToday = pDate 
 END 
 
 IF OMITTED(pTime) = TRUE 
    intClock = CLOCK() 
 ELSE 
    intClock = pTime 
 END 
 
 rTimestamp        = oFmt.ClarionToUnixDate(intToday,intClock,TRUE )
 SELF.strTimestamp = oFmt.FormatValue(rTimestamp, '@U2TM@D10-@T04')
 SELF.strTimestamp = CLIP(SELF.strTimestamp) & '.' & SUB(rTimestamp,-3,3) & 'Z'  ! add the rightmost 3 digits (ms) and a Z to indicate this is UTC time. 
 
 ! SELF.oSTHoneyOut.Trace('cHoneycomb.SetTimestamp: Clock=' & CLOCK() & ' Timestamp=' & CLIP(SELF.strTimestamp))
 
 ! RFC3339 high precision format (e.g. YYYY-MM-DDTHH:MM:SS.mmmZ)
 ! @U2TM@D10-@T04
   
 RETURN 
 
 
!-----------------------------------------
cHoneycomb.SetHeadings      PROCEDURE(STRING pstrHeadings)!,LONG 
!-----------------------------------------

 CODE
 
 ! limited editing done by virtue of the ST.SPLIT. 
 SELF.oSTHoneyHeading.SetValue(pstrHeadings) 
 SELF.oSTHoneyHeading.Split(',','"',,RemoveTheQuotes,ClipTheData)

 SELF.intRC = RECORDS(SELF.oSTHoneyHeading.lines)
 IF SELF.intRC > 0   ! should there be a minimum > 1?   Yes, kinda crude. 
    SELF.intRC = TRUE
 ELSE
    SELF.intRC = FALSE 
 END 
 
 !SELF.CheckFlush() 
 
 RETURN SELF.intRC 
 
 
!-----------------------------------------
cHoneycomb.SetAutoFormatDate      PROCEDURE(LONG pAutoFormat)
!-----------------------------------------

 CODE
 
 IF pAutoFormat = TRUE OR pAutoFormat = FALSE 
    SELF.AutoFormatDate = pAutoFormat
 END 
 
 RETURN 

!-----------------------------------------
cHoneycomb.SetAutoFormatTime      PROCEDURE(LONG pAutoFormat)
!-----------------------------------------

 CODE
 
 IF pAutoFormat = TRUE OR pAutoFormat = FALSE 
    SELF.AutoFormatTime = pAutoFormat
 END 
 
 RETURN 
 
 
!-----------------------------------------
cHoneycomb.SetMergeDateAndTime               PROCEDURE(LONG pMergeDateTime) 
!-----------------------------------------

 CODE
 
 IF pMergeDateTime = TRUE OR pMergeDateTime = FALSE 
    SELF.MergeDateAndTime = pMergeDateTime
 END 
 
 RETURN 


!-----------------------------------------
cHoneycomb.AddMetrics     PROCEDURE(STRING pstrMetrics)
!-----------------------------------------
intLines   LONG 

strWorkDate           STRING(10)
strWorkTime           STRING(10)
intDateInThisMetric   LONG 
intTimeInThisMetric   LONG 
oSTTemp               StringTheory

 CODE
 
 intLines = RECORDS(SELF.oSTHoneyHeading.Lines)
 
 IF CLIP(SELF.HoneycombAPIKey) > ' ' AND CLIP(SELF.HoneycombDataset) > ' ' AND intLines > 0
    SELF.SetTimestamp()
    
    SELF.oSTWork.SetValue(CLIP(pstrMetrics))
    
    SELF.oSTWork.Split(',','"',,RemoveTheQuotes,ClipTheData)
    
    ! now we have data in individual queue entries in SELF.oSTWork.Lines and headings in individual queue entries in SELF.oHoneyHeadings.Lines. 

    intDateInThisMetric = FALSE 
    intTimeInThisMetric = FALSE     

! WIP - needs to be smarter than coded so far. 
! ideally, logs the first set of zero metrics, suppresses 2nd-nth for x seconds, then logs again.     
!    IF SELF.intZeroMetricsSuppression = TRUE      ! metrics zero suppression prevents a ton of lines with 0 in them. Not terribly useful in most cases. 
!       IF SELF.intZeroMetricsReportInterval > 0   ! buuuuut we want to send even zero metrics occasionally, just to prove we're alive. Value is in seconds
!          IF SELF.intLastZeroMetricsSend + SELF.intZeroMetricsReportInterval * Time:Seconds < CLOCK() OR SELF.intLastZeroMetricsSend = 0 ! its time to send
!             intZeroLines = 0
!             LOOP intLoop = 1 TO intLines 
!                SELF.oSTWork.GetLine(intLoop)                 
!                oSTTemp.SetValue(CLIP(SELF.oSTWork.lines.line))
!                IF oSTTemp.IsAll('01233456789,.+-') = TRUE ! if the data is numeric
!                   IF oSTTemp.IsAll('0.,+-') = TRUE 
!                      intZeroLines += 1
!                   END                   
!                ELSE
!                   intZeroLines += 1  ! treat alpha data as zero.
!                END 
!             END   
!             IF intZeroLines = intLines ! its all zeros
!                RETURN
!             END 
!          END 
!       END
!    END 

    
    LOOP intLoop = 1 TO intLines 
       !SELF.oSTHoneyHeading.Trace('before processing intloop=' & intLoop & ' datefound=' & intDateInThisMetric & ' timefound=' & intTimeInThisMetric)
       SELF.oSTWork.GetLine(intLoop)
       SELF.oSTHoneyHeading.GetLine(intLoop)
       !SELF.oSTHoneyMetrics.Trace('field ' & intLoop & ' Heading=' & CLIP(SELF.oSTHoneyHeading.lines.line) & ' data=' & CLIP(SELF.oSTWork.lines.line))
       IF intLoop = 1       
          IF SELF.oSTHoneyMetrics.Len() > 0
             SELF.oSTHoneyMetrics.Append(',{{ "created_at": "' & CLIP(SELF.strTimestamp) & '", ' )             
          ELSE
             SELF.oSTHoneyMetrics.Append('{{ "created_at": "' & CLIP(SELF.strTimestamp) & '", ' )             
          END
       END
       
       ! a numeric test would be good so numbers arent surrounded by quotes.
       ! if the heading name is date or time, it will automatically format as a date/time unless you disable that feature.
       
       IF INSTRING('date',LOWER(CLIP(SELF.oSTHoneyHeading.lines.line)),1,1) > 0
          intDateInThisMetric = TRUE  
          IF SELF.AutoFormatDate = TRUE                                            ! the json world doesnt really like standalone dates. If no time component exists, set time to 00:00:00
             strWorkDate = FORMAT(CLIP(SELF.oSTWork.lines.line),@d10-)
             SELF.oSTHoneyMetrics.Append('"' & CLIP(SELF.oSTHoneyHeading.lines.line) & '": "' & CLIP(strWorkDate) & '"' )
          ELSE              
             SELF.oSTHoneyMetrics.Append('"' & CLIP(SELF.oSTHoneyHeading.lines.line) & '": "' & CLIP(SELF.oSTWork.lines.line) & '"' )
          END 
          
       ELSIF INSTRING('time',LOWER(CLIP(SELF.oSTHoneyHeading.lines.line)),1,1) > 0
             intTimeInThisMetric = TRUE 
             IF SELF.AutoFormatTime = TRUE
                strWorkTime = FORMAT(CLIP(SELF.oSTWork.lines.line),@T04)
                SELF.oSTHoneyMetrics.Append('"' & CLIP(SELF.oSTHoneyHeading.lines.line) & '": "' & CLIP(strWorkTime) & '"' )
             ELSE
                SELF.oSTHoneyMetrics.Append('"' & CLIP(SELF.oSTHoneyHeading.lines.line) & '": "' & CLIP(SELF.oSTWork.lines.line) & '"' )
             END 
       ELSE
          ! if the data is all numeric, let's omit the quotes from the JSON.
          oSTTemp.SetValue(CLIP(SELF.oSTWork.lines.line))
          IF oSTTemp.IsAll('01233456789,.+-') = TRUE 
             SELF.oSTHoneyMetrics.Append('"' & CLIP(SELF.oSTHoneyHeading.lines.line) & '": ' & CLIP(SELF.oSTWork.lines.line) & '' )
          ELSE 
             SELF.oSTHoneyMetrics.Append('"' & CLIP(SELF.oSTHoneyHeading.lines.line) & '": "' & CLIP(SELF.oSTWork.lines.line) & '"' )
          END 
       END        
          
       IF intLoop = intLines ! ie: we're processing the last column - dont add trailing comma and do add the trailing brace.
          IF SELF.MergeDateAndTime = TRUE 
             IF intDateInThisMetric = TRUE AND intTimeInThisMetric = TRUE
                !SELF.oSTHoneyHeading.Trace('date and time found')
                SELF.oSTHoneyMetrics.Append(', "DateTime": "' & CLIP(strWorkDate) & 'T' & CLIP(strWorkTime) & '.000Z"')   
             END 
          END 
          SELF.oSTHoneyMetrics.Append('}')
       ELSE ! there's at least 1 more column so add the trailing comma. 
          SELF.oSTHoneyMetrics.Append(',' )
       END 
       
    END 
    
    SELF.oSTHoneyMetrics.Append(eqHoneyCRLF)
        
 ELSE
    SELF.oSTHoneyLog.Trace('cHoneycomb.AddMetrics: PROBLEM: no apikey (' & CLIP(SELF.HoneycombAPIKey) & '), or dataset (' & CLIP(SELF.HoneycombDataset) & '), or headings (count=' & intLines & ')')
 END 
 
 SELF.CheckFlush() 
 
 RETURN
 
!-----------------------------------------
cHoneycomb.AddLog         PROCEDURE(STRING pstrLog)
!-----------------------------------------
strLogData STRING(5000)
 CODE

 IF CLIP(SELF.HoneycombAPIKey) > ' ' AND CLIP(SELF.HoneycombDataset) > ' '
    SELF.SetTimestamp()
    
    SELF.oSTWork.SetValue(CLIP(pstrLog))
    
    SELF.oSTWork.Replace('"','\"')        ! escape any " inside the log data.
    strLogData = SELF.oSTWork.GetValue()
    
    IF SELF.oSTHoneyLog.Len() > 0
       SELF.oSTHoneyLog.Append(',{{ "created_at": "' & CLIP(SELF.strTimestamp) & '", "log": "' & CLIP(strLogData) & '"}' & eqHoneyCRLF)
    ELSE
       SELF.oSTHoneyLog.Append('{{ "created_at": "' & CLIP(SELF.strTimestamp) & '", "log": "' & CLIP(strLogData) & '"}' & eqHoneyCRLF)
    END 
    
    IF SELF.oSTHoneyLog.Len() > 999999 ! 1 meg - let's flush often enough to not overload things, delay shutdowns or risk large loss of log data.1
       SELF.Flush()
    END 
    
    !SELF.oSTHoneyLog.Trace('cHoneycomb.AddLog: log=' & CLIP(pstrLog) )
    !SELF.oSTHoneyLog.Trace('cHoneycomb.AddLog: loglen=' & SELF.oSTHoneyLog.Len() & ' LogValue=' & CLIP(SELF.oSTHoneyLog.GetValue()) )
        
 ELSE
    SELF.oSTHoneyLog.Trace('cHoneycomb.AddLog: PROBLEM: no apikey (' & CLIP(SELF.HoneycombAPIKey) & ') or dataset (' & CLIP(SELF.HoneycombDataset) & ') log=' & CLIP(pstrLog) )
 END 
 
 SELF.CheckFlush() 
 
 RETURN 
 
 
!----------------------------------------------------------------------------------------------------------------
cHoneycomb.Flush          PROCEDURE()!,LONG 
!----------------------------------------------------------------------------------------------------------------
csTempPath           CSTRING(255)
strSavePath          STRING(255)
  CODE
  
  SELF.FlushLog()
  
  SELF.FlushMetrics() 
      
  SELF.intLastFlushTime = CLOCK()  

  RETURN SELF.intRC 

!----------------------------------------------------------------------------------------------------------------
cHoneycomb.FlushMetrics      PROCEDURE()!,LONG 
!----------------------------------------------------------------------------------------------------------------
csTempPath           CSTRING(255)
strSavePath          STRING(255)
  CODE
  
  ! push log data to honeycomb

  IF CLIP(SELF.oSTHoneyMetrics.GetValue()) > ' '     
     SELF.oSTHoneyOut.SetValue('{{"metrics":[' & CLIP(SELF.oSTHoneyMetrics.GetValue()) & ']}')
     csTempPath = cHoneycombInternal_GetTempPath()
     strSavePath = CLIP(csTempPath) & 'HoneyMetrics-' & FORMAT(TODAY(),@D12) & '-' & FORMAT(CLOCK(),@T05) & '.json'
     SELF.oSTHoneyMetrics.Trace('Savepath=' & CLIP(strSavePath))
     SELF.oSTHoneyOut.SaveFile(strSavePath)
     SELF.oSTHoneyMetrics.SetValue('')
     RUN('cmd /c python ./HoneyMetrics.py --logfile "' & CLIP(strSavePath) & '" --apikey "' & CLIP(SELF.HoneycombAPIKey) & '" --dataset "' & CLIP(SELF.HoneycombDataset) & '-metrics"') ! no need to wait, the py script throttles itself. 
  END 
    
  SELF.intLastFlushTime = CLOCK()  

  RETURN SELF.intRC 


!----------------------------------------------------------------------------------------------------------------
cHoneycomb.FlushLog      PROCEDURE()!,LONG 
!----------------------------------------------------------------------------------------------------------------
csTempPath           CSTRING(255)
strSavePath          STRING(255)
  CODE
  
  ! push log data to honeycomb

  IF CLIP(SELF.oSTHoneyLog.GetValue()) > ' '
     !SELF.oSTHoneyLog.Trace('Log: [' )
     !SELF.oSTHoneyLog.Trace(CLIP(SELF.oSTHoneyLog.GetValue()))
     !SELF.oSTHoneyLog.Trace(']')
     
     SELF.oSTHoneyLog.Replace('\','\\')
     SELF.oSTHoneyLog.Replace('\\"','\"')   ! restore the escapes for "  
     
     SELF.oSTHoneyOut.SetValue('{{"logs":[' & CLIP(SELF.oSTHoneyLog.GetValue()) & ']}')
     csTempPath = cHoneycombInternal_GetTempPath()
     strSavePath = CLIP(csTempPath) & 'Honeylog-' & FORMAT(TODAY(),@D12) & '-' & FORMAT(CLOCK(),@T05) & '.json'
     SELF.oSTHoneyLog.Trace('Savepath=' & CLIP(strSavePath))
     SELF.oSTHoneyOut.SaveFile(strSavePath)
     SELF.oSTHoneyLog.SetValue('')
     RUN('cmd /c python ./HoneyLog.py --logfile "' & CLIP(strSavePath) & '" --apikey "' & CLIP(SELF.HoneycombAPIKey) & '" --dataset "' & CLIP(SELF.HoneycombDataset) & '"') ! no need to wait, the py script throttles itself. 
  END   
    
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
 SELF.oSTWork          &= NEW(StringTheory)
 
 SELF.intLastFlushTime = CLOCK() 
 SELF.intFlushInterval = 30 ! default flush
 
 SELF.SetAutoFormatDate(TRUE)
 SELF.SetAutoFormatTime(TRUE)
 SELF.SetMergeDateAndTime(TRUE) 
      
 RETURN


!----------------------------------------------------------------------------------------------------------------
cHoneycomb.Destruct   PROCEDURE()
!----------------------------------------------------------------------------------------------------------------
 CODE

 SELF.intRC = SELF.Flush()

 IF SELF.oSTWork &= NULL
 ELSE
    DISPOSE(SELF.oSTWork)
    SELF.oSTWork &= NULL
 END 
 
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