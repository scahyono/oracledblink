<cfcomponent output="false" displayname="Oracle DB Link">

	<cffunction name="init" access="public" output="false" returntype="any">
		<cfset this.version = "1.1.8" />
		<cfreturn this />
	</cffunction>

	<cffunction name="$convertMaxRowsToLimit" returntype="struct" access="public" output="false" mixin="oracle">
		<cfargument name="argScope" type="struct" required="true">
		<cfscript>
		return arguments.argScope;
		</cfscript>
	</cffunction>

	<cffunction name="$getColumnInfo" returntype="query" access="public" output="false" mixin="oracle">
		<cfargument name="table" type="string" required="true">
		<cfargument name="datasource" type="string" required="true">
		<cfargument name="username" type="string" required="true">
		<cfargument name="password" type="string" required="true">
		<cfscript>
		var loc = {};
		loc.args = duplicate(arguments);
		StructDelete(loc.args, "table");
		if (!Len(loc.args.username))
		{
			StructDelete(loc.args, "username");
		}
		if (!Len(loc.args.password))
		{
			StructDelete(loc.args, "password");
		}
		loc.args.name = "loc.returnValue";
		</cfscript>
		<cfquery attributeCollection="#loc.args#">
		SELECT
			TC.COLUMN_NAME
			,TC.DATA_TYPE AS TYPE_NAME
			,TC.NULLABLE AS IS_NULLABLE
			,CASE WHEN PKC.COLUMN_NAME IS NULL THEN 0 ELSE 1 END AS IS_PRIMARYKEY
			,0 AS IS_FOREIGNKEY
			,'' AS REFERENCED_PRIMARYKEY
			,'' AS REFERENCED_PRIMARYKEY_TABLE
			,NVL(TC.DATA_PRECISION, TC.DATA_LENGTH) AS COLUMN_SIZE
			,TC.DATA_SCALE AS DECIMAL_DIGITS
			,TC.DATA_DEFAULT AS COLUMN_DEFAULT_VALUE
			,TC.DATA_LENGTH AS CHAR_OCTET_LENGTH
			,TC.COLUMN_ID AS ORDINAL_POSITION
			,'' AS REMARKS
		FROM
			ALL_TAB_COLUMNS TC
			LEFT JOIN ALL_CONSTRAINTS PK
				ON (PK.CONSTRAINT_TYPE = 'P'
				AND PK.TABLE_NAME = TC.TABLE_NAME
				AND TC.OWNER = PK.OWNER)
			LEFT JOIN ALL_CONS_COLUMNS PKC
				ON (PK.CONSTRAINT_NAME = PKC.CONSTRAINT_NAME
				AND TC.COLUMN_NAME = PKC.COLUMN_NAME
				AND TC.OWNER = PKC.OWNER)
		WHERE
			TC.TABLE_NAME = '#UCase(arguments.table)#'
		ORDER BY
			TC.COLUMN_ID
		</cfquery>
		<!---
		wheels catches the error and raises a Wheels.TableNotFound error
		to mimic this we will throw an error if the query result is empty
		 --->
		<cfif !loc.returnValue.RecordCount>
			<!--- get the metadata from dblink --->
			<cfquery attributeCollection="#loc.args#">
				SELECT DB_LINK FROM ALL_SYNONYMS WHERE SYNONYM_NAME='#UCase(arguments.table)#'
			</cfquery>
			<cfif !loc.returnValue.RecordCount>
				<cfthrow/>
			</cfif>
			<cfquery attributeCollection="#loc.args#">
	        SELECT
	            TC.COLUMN_NAME
	            ,TC.DATA_TYPE AS TYPE_NAME
	            ,TC.NULLABLE AS IS_NULLABLE
	            ,0 AS IS_PRIMARYKEY
	            ,0 AS IS_FOREIGNKEY
	            ,'' AS REFERENCED_PRIMARYKEY
	            ,'' AS REFERENCED_PRIMARYKEY_TABLE
	            ,NVL(TC.DATA_PRECISION, TC.DATA_LENGTH) AS COLUMN_SIZE
	            ,TC.DATA_SCALE AS DECIMAL_DIGITS
	            ,TC.DATA_DEFAULT AS COLUMN_DEFAULT_VALUE
	            ,TC.DATA_LENGTH AS CHAR_OCTET_LENGTH
	            ,TC.COLUMN_ID AS ORDINAL_POSITION
	            ,'' AS REMARKS
	        FROM
	            ALL_TAB_COLUMNS@"#loc.returnValue.DB_LINK#" TC
	        WHERE
				TC.TABLE_NAME = '#UCase(arguments.table)#'
	        ORDER BY
	        TC.COLUMN_ID
			</cfquery>
			<cfif !loc.returnValue.RecordCount>
				<cfthrow/>
			</cfif>
		</cfif>
		<cfreturn loc.returnValue>
	</cffunction>

</cfcomponent>