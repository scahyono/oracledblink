<cfcomponent extends="wheelsMapping.Test" output="false">

	<cffunction name="setup">
		<cfset application.wheels.dataSourceName = "wheelstestdb">
		<cfset loc.identityColumnType = "number(38,0) NOT NULL">
		<cfset loc.storageEngine = "">
		<cfset loc.i = "remoteauthors">
		<cfset loc.seq = "#loc.i#_seq">
		<cfquery name="loc.query" datasource="#application.wheels.dataSourceName#">
		CREATE TABLE remoteauthors
		(
			id #loc.identityColumnType#
			,firstname varchar(100) NOT NULL
			,lastname varchar(100) NOT NULL
			,PRIMARY KEY(id)
		) #loc.storageEngine#
		</cfquery>
		<cfquery name="loc.query" datasource="#application.wheels.dataSourceName#">
		CREATE SEQUENCE #loc.seq# START WITH 1 INCREMENT BY 1
		</cfquery>
		<cfquery name="loc.query" datasource="#application.wheels.dataSourceName#">
		ALTER TABLE #loc.i# MODIFY COLUMN id #loc.identityColumnType# DEFAULT #loc.seq#.nextval
		</cfquery>
		<cfquery name="loc.query" datasource="#application.wheels.dataSourceName#">
		</cfquery>
		<cfinclude template="../../../src/test/coldfusion/_oracle-emu.cfm">
	</cffunction>

	<cffunction name="test_findOne" hint="can search for model in module paths">
		<cfset loc.per = model("remoteAuthor").create(firstName="Per", lastName="Djurner")>
		<cfset results.author = model("remoteAuthor").findOne(1)>
		<cfset assert("IsObject(results.author)")>
	</cffunction>

	<cffunction name="teardown">
		<cfquery name="loc.query" datasource="#application.wheels.dataSourceName#">
		DROP TABLE remoteauthors
		</cfquery>
		<cfquery name="loc.query" datasource="#application.wheels.dataSourceName#">
		DROP SEQUENCE #loc.seq#
		</cfquery>
	</cffunction>
</cfcomponent>