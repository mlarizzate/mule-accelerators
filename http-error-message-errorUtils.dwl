%dw 2.0

import modules::errorHandler::ObjectUtils
import modules::errorHandler::ContextUtils
import * from dw::Runtime

fun getErrorTypeAsString(error) = do {
	var namespace = error.errorType.namespace default 'APP'
	var identifier = error.errorType.identifier default 'UNKNOWN'
	---
	namespace ++ ":" ++ identifier
}


fun getCause(cause, currentStep, maxSteps)= 
if (!isEmpty(cause.localizedMessage) and (currentStep <= maxSteps))
{
	localizedMessage: cause.localizedMessage,
	cause: getCause(cause.cause, currentStep +1, maxSteps)
} else null

fun getCauseMessage(obj) =
  ((getCause(obj.cause, 1, 5) default [])..*localizedMessage distinctBy $) joinBy " - Caused by: "

fun cleanup(error, includeFailingComponent = true) = do {
	var textToSearch = (error.description default "%%UNDEFINED%%") ++ " - Caused by: "
	var causedByMessage = getCauseMessage(error default error.exception)
	var effectiveCausedByMessage = 
		if ((causedByMessage default "") startsWith textToSearch) 
			causedByMessage replace textToSearch with ""
		else
			if (causedByMessage == error.description)
				null
			else	
			  causedByMessage
---
  if (!isEmpty(error)) 
    ((error default {}) -- ['cause', 'childErrors', 'exception', 'errorType', 'suppressedErrors', 'dslSource', 'errorMessage', 'detailedDescription',
    	(if (includeFailingComponent default true) "" else "failingComponent")
    ]) 
    ++    
    {
    	"detailedDescription": 
    		(
    			if (isEmpty(error.detailedDescription) or (error.detailedDescription == error.description))
    				effectiveCausedByMessage
    			else
    				if (!isEmpty(effectiveCausedByMessage))
    		  			error.detailedDescription ++ " - Caused by: " ++ effectiveCausedByMessage
    				else
    		  			error.detailedDescription    					  		
    		),    	
    	"errorType": getErrorTypeAsString(error)
    }
  else
    null	
}

    
fun isHandledError(obj) =
  ObjectUtils::isObject(obj)
  and (obj.code? and obj.isBusinessError?)
  
var isExperienceApi = ((Mule::p('anypoint.platform.visualizer.layer') default 'Experience') == "Experience")

fun canIncludeErrorCause(exceptionHandlerConfig) = 
  (!isExperienceApi) or (exceptionHandlerConfig.includeCause default false)

fun buildError(exceptionHandlerConfig, error, operationContext, remoteCall, transientErrors, remoteServiceResponse, correlationId) = do {
  var errorType = getErrorTypeAsString(error)
  var isRemoteServiceException = errorType == 'APP:REMOTE_SERVICE_EXCEPTION'
  
var includeErrorCauseAndContext = canIncludeErrorCause(exceptionHandlerConfig) default true  
---
  {
	code: exceptionHandlerConfig.code default '500',
	message: exceptionHandlerConfig.message default (
		if (isRemoteServiceException)
			"Unhandled remote service exception occurred"
		else	
		    "Unhandled error occurred"
	),
	isBusinessError: false,
	isTransient: exceptionHandlerConfig.isTransient default ((transientErrors default []) contains errorType),
	details: exceptionHandlerConfig.details,
	(businessKey: operationContext.businessKey) if (!isEmpty(operationContext.businessKey)),
	(processId: operationContext.processId) if (!isEmpty(operationContext.processId)),
	(transactionId: operationContext.transactionId) if (!isEmpty(operationContext.transactionId)),	
	correlationId: exceptionHandlerConfig.correlationId default correlationId,
	timestamp: now() >> "UTC",
	causedBy: if (includeErrorCauseAndContext) 
		cleanup(error, exceptionHandlerConfig.includeFailingComponent)
		++ if (isRemoteServiceException) {
			remoteServiceResponse: {
				encoding: try(() -> remoteServiceResponse.^encoding) orElse 'unavailable',
				mimeType: try(() -> remoteServiceResponse.^mimeType) orElse 'unavailable',
				mediaType: try(() -> remoteServiceResponse.^mediaType) orElse 'unavailable',
				rawContent: try(() -> remoteServiceResponse.^raw) orElse 'unavailable',
			}
		} else {}
	else null,
	context: if (includeErrorCauseAndContext) ContextUtils::getContextFrom(operationContext, remoteCall) else null
  }
}   
