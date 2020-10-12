
 PROGRAM
  
 INCLUDE('cHoneycomb.inc')

 MAP
 END
 
intRandoData LONG 
 
strAPIKey    STRING(100)
strDataset   STRING(100)

oHoney   cHoneycomb 

 CODE

 strAPIKey   = COMMAND('APIKey')   ! get this some other way if you like - not coded here to avoid putting API keys i n pub
 strDataset  = COMMAND('Dataset')
 
 oHoney.SetAPIKey(strAPIKey)
 oHoney.SetDataset(strDataset)
 
 oHoney.AddLog('Testlog1 ' & CLOCK() )
 
 oHoney.AddLog('Testlog2 ' & CLOCK() )
 
 oHoney.AddLog('Testlog3 ' & CLOCK() )
 
 oHoney.AddLog('Testlog4 ' & CLOCK() )
 
 oHoney.AddLog('Testlog5 ' & CLOCK() )
 
! oHoney.SetHeading('date,time,someotherfield')
! 
! LOOP 10 TIMES
! 
!    oHoney.WriteLog('Someday ' & FORMAT(TODAY(),@D10-) & ' at sometime oclock ' & FORMAT(CLOCK(),@T05))
!    
!    LOOP 100 TIMES 
!       intRandoData = RANDOM(0,100000)
!       oHoney.SendMetrics()
!    END 
!    
! END
 
 RETURN 
 
 
 
   
  
  
