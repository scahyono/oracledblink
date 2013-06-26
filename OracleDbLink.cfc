<cfcomponent output="false" displayname="Multi Module" mixin="Oracle">

  <cffunction name="init" access="public" output="false" returntype="any">
		<cfset this.version = "1.1.8" />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="$query" returntype="struct" access="public" output="false">
		<cfargument name="sql" type="array" required="true">
		<cfargument name="limit" type="numeric" required="false" default=0>
		<cfargument name="offset" type="numeric" required="false" default=0>
		<cfargument name="parameterize" type="boolean" required="true">
		<cfargument name="$primaryKey" type="string" required="false" default="">
		<cfscript>
			var loc = {};
//			EPSO PATCH cahyosi(2013-04-12) - prevent missing property after using findOne or findByKey
//			arguments = $convertMaxRowsToLimit(arguments);
			arguments.sql = $removeColumnAliasesInOrderClause(arguments.sql);
			arguments.sql = $addColumnsToSelectAndGroupBy(arguments.sql);
			if (arguments.limit > 0)
			{
				loc.beforeWhere = "SELECT #arguments.$primaryKey# FROM (SELECT tmp.#arguments.$primaryKey#, rownum rnum FROM (";
				loc.afterWhere = ") tmp WHERE rownum <=" & arguments.limit+arguments.offset & ")" & " WHERE rnum >" & arguments.offset;
				ArrayPrepend(arguments.sql, loc.beforeWhere);
				ArrayAppend(arguments.sql, loc.afterWhere);
			}

			// oracle doesn't support limit and offset in sql
			StructDelete(arguments, "limit", false);
			StructDelete(arguments, "offset", false);
			loc.returnValue = $performQuery(argumentCollection=arguments);
			loc.returnValue = $handleTimestampObject(loc.returnValue);
		</cfscript>
		<cfreturn loc.returnValue>
	</cffunction>

	<cffunction name="$getColumnInfo" returntype="query" access="public" output="false">
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
			<!--- EPSO PATCH cahyosi(2013-05-24) maybe we can get the metadata from dblink? --->
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
