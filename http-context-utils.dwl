%dw 2.0

fun getContextFrom(operationContext, remoteCall) = {
	"app": Mule::p("app.name"),
	"env": Mule::p("mule.env") default 'undefined',
	"domain": Mule::p("domain.name"),
	"layer": Mule::p('anypoint.platform.visualizer.layer') default 'undefined',
	("operationContext": operationContext) if (operationContext != null),
    ("remoteCall": {
		"system": remoteCall.system default 'undefined',
		"serviceType": remoteCall.service."type" default 'undefined',
		"serviceName": remoteCall.service.name default 'undefined',
		"operation": remoteCall.operation default 'undefined'
	}) if (remoteCall != null)
}
