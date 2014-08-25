<cfcomponent extends="wheelsMapping.Test" output="false">

	<cffunction name="setup">
		<cfset application.wheels.plugins.oracledblink.init()>
	</cffunction>

	<cffunction name="test_model" hint="can search for model in module paths">
		<cfset results.userModel = model("user")>
		<cfset assert("IsObject(results.userModel)")>
	</cffunction>

</cfcomponent>