fun isSigningError(error) = 
  error.description == 'Failed signing payload'
  

fun checkIfTransient(error) = 
  if (isSigningError(error)) false else null  
  
  
fun getErrorMessage(sfdcOperation, requestConfig, error) = do {
	var errorMessage =  "An error occurred while calling Salesforce '" ++ sfdcOperation.name ++ "' operation"
	---
  if (isSigningError(error))
    errorMessage 
    ++ ": keystore file  '" 
    ++ requestConfig.keyStorePath 
    ++ "' not found or invalid, invalid keystore passowrd (keyStorePassword) and/or invalid certificate alias (certAlias)"
  else
    errorMessage
	
}

  
