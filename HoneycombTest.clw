
 PROGRAM
  
 INCLUDE('cHoneycomb.inc')

 MAP
 END
 
intRandoData LONG 
 
strAPIKey    STRING(100)
strDataset   STRING(100)

oHoney   cHoneycomb 

 CODE

 strAPIKey   = COMMAND('APIKey')   ! get this some other way if you like - not coded here to avoid putting API keys in a public repo. 
 strDataset  = COMMAND('Dataset')
 
 oHoney.SetAPIKey(strAPIKey)
 oHoney.SetDataset(strDataset)
 
 oHoney.SetHeadings('"date","time","sales"')
 oHoney.AddMetrics('70234,' & 8 * 100 * 60 * 60 & ',123.45')
 oHoney.AddMetrics('70235,' & 9 * 100 * 60 * 60 & ',223.45')
 oHoney.AddMetrics('70236,' & 10 * 100 * 60 * 60 & ',323.45')
 oHoney.AddMetrics('70237,' & 11 * 100 * 60 * 60 & ',423.45')
 oHoney.AddMetrics('70238,' & 12 * 100 * 60 * 60 & ',523.45')
 
 oHoney.AddLog('Testlog1 Arnold' & CLOCK() )
 
 oHoney.AddLog('Testlog2 John' & CLOCK() )
 
 oHoney.AddLog('Testlog3 Bruce' & CLOCK() )
 
 oHoney.AddLog('Testlog4 MarkG' & CLOCK() )
 
 oHoney.AddLog('Testlog5 Where is the Cajun man?' & CLOCK() )

 
 RETURN 
 
 
 
   
  
  
