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

	<cffunction name="$createSQLFieldList" returntype="string" access="public" output="false" mixin="model">
		<cfargument name="list" type="string" required="true">
		<cfargument name="include" type="string" required="true">
		<cfargument name="returnAs" type="string" required="true">
		<cfargument name="renameFields" type="boolean" required="false" default="true">
		<cfargument name="addCalculatedProperties" type="boolean" required="false" default="true">
		<cfargument name="useExpandedColumnAliases" type="boolean" required="false" default="#application.wheels.useExpandedColumnAliases#">
		<cfscript>
			var loc = {};
			// setup an array containing class info for current class and all the ones that should be included
			loc.classes = [];
			if (Len(arguments.include))
				loc.classes = $expandedAssociations(include=arguments.include);
			ArrayPrepend(loc.classes, variables.wheels.class);

			// if the develop passes in tablename.*, translate it into the list of fields for the developer
			// this is so we don't get *'s in the group by
			if (Find(".*", arguments.list))
				arguments.list = $expandProperties(list=arguments.list, classes=loc.classes);

			// add properties to select if the developer did not specify any
			if (!Len(arguments.list))
			{
				loc.iEnd = ArrayLen(loc.classes);
				for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
				{
					loc.classData = loc.classes[loc.i];
					arguments.list = ListAppend(arguments.list, loc.classData.propertyList);
					if (Len(loc.classData.calculatedPropertyList))
						arguments.list = ListAppend(arguments.list, loc.classData.calculatedPropertyList);
				}
			}

			// go through the properties and map them to the database unless the developer passed in a table name or an alias in which case we assume they know what they're doing and leave the select clause as is
			if (arguments.list Does Not Contain "." AND arguments.list Does Not Contain " AS ")
			{
				loc.list = "";
				loc.addedProperties = "";
				loc.addedPropertiesByModel = {};
				loc.iEnd = ListLen(arguments.list);
				for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
				{
					loc.iItem = Trim(ListGetAt(arguments.list, loc.i));

					// look for duplicates
					loc.duplicateCount = ListValueCountNoCase(loc.addedProperties, loc.iItem);
					loc.addedProperties = ListAppend(loc.addedProperties, loc.iItem);

					// loop through all classes (current and all included ones)
					loc.jEnd = ArrayLen(loc.classes);
					for (loc.j=1; loc.j <= loc.jEnd; loc.j++)
					{
						loc.toAppend = "";
						loc.classData = loc.classes[loc.j];

						// create a struct for this model unless it already exists
						if (!StructKeyExists(loc.addedPropertiesByModel, loc.classData.modelName))
							loc.addedPropertiesByModel[loc.classData.modelName] = "";

						// if we find the property in this model and it's not already added we go ahead and add it to the select clause
						if ((ListFindNoCase(loc.classData.propertyList, loc.iItem) || ListFindNoCase(loc.classData.calculatedPropertyList, loc.iItem)) && !ListFindNoCase(loc.addedPropertiesByModel[loc.classData.modelName], loc.iItem))
						{
							// if expanded column aliases is enabled then mark all columns from included classes as duplicates in order to prepend them with their class name
							loc.flagAsDuplicate = false;
							if (arguments.renameFields)
							{
								if (loc.duplicateCount)
								{
									// always flag as a duplicate when a property with this name has already been added
									loc.flagAsDuplicate  = true;
								}
								else if (loc.j > 1)
								{
									if (arguments.useExpandedColumnAliases)
									{
										// when on included models and using the new setting we flag every property as a duplicate so that the model name always gets prepended
										loc.flagAsDuplicate  = true;
									}
									else if (!arguments.useExpandedColumnAliases && arguments.returnAs != "query")
									{
										// with the old setting we only do it when we're returning object(s) since when creating instances on none base models we need the model name prepended
										loc.flagAsDuplicate  = true;
									}
								}
							}
							if (loc.flagAsDuplicate )
								loc.toAppend = loc.toAppend & "[[duplicate]]" & loc.j;
							if (ListFindNoCase(loc.classData.propertyList, loc.iItem))
							{
								loc.toAppend = loc.toAppend & loc.classData.tableName & ".";
								if (ListFindNoCase(loc.classData.columnList, loc.iItem))
								{
									loc.toAppend = loc.toAppend & loc.iItem;
								}
								else
								{
									loc.toAppend = loc.toAppend & loc.classData.properties[loc.iItem].column;
									if (arguments.renameFields)
										loc.toAppend = loc.toAppend & ' AS "' & loc.iItem & '"';
								}
							}
							else if (ListFindNoCase(loc.classData.calculatedPropertyList, loc.iItem) && arguments.addCalculatedProperties)
							{
								loc.toAppend = loc.toAppend & "(" & Replace(loc.classData.calculatedProperties[loc.iItem].sql, ",", "[[comma]]", "all") & ') AS "' & loc.iItem & '"';
							}
							loc.addedPropertiesByModel[loc.classData.modelName] = ListAppend(loc.addedPropertiesByModel[loc.classData.modelName], loc.iItem);
							break;
						}
					}
					if (Len(loc.toAppend))
						loc.list = ListAppend(loc.list, loc.toAppend);
					else if (application.wheels.showErrorInformation && (not arguments.addCalculatedProperties && not ListFindNoCase(loc.classData.calculatedPropertyList, loc.iItem)))
						$throw(type="Wheels.ColumnNotFound", message="Wheels looked for the column mapped to the `#loc.iItem#` property but couldn't find it in the database table.", extendedInfo="Verify the `select` argument and/or your property to column mappings done with the `property` method inside the model's `init` method to make sure everything is correct.");
				}

				// let's replace eventual duplicates in the clause by prepending the class name
				if (Len(arguments.include) && arguments.renameFields)
				{
					loc.newSelect = "";
					loc.addedProperties = "";
					loc.iEnd = ListLen(loc.list);
					for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
					{
						loc.iItem = ListGetAt(loc.list, loc.i);

						// get the property part, done by taking everytyhing from the end of the string to a . or a space (which would be found when using " AS ")
						loc.property = Reverse(SpanExcluding(Reverse(loc.iItem), ". "));

						// check if this one has been flagged as a duplicate, we get the number of classes to skip and also remove the flagged info from the item
						loc.duplicateCount = 0;
						loc.matches = REFind("^\[\[duplicate\]\](\d+)(.+)$", loc.iItem, 1, true);
						if (loc.matches.pos[1] gt 0)
						{
							loc.duplicateCount = Mid(loc.iItem, loc.matches.pos[2], loc.matches.len[2]);
							loc.iItem = Mid(loc.iItem, loc.matches.pos[3], loc.matches.len[3]);
						}

						if (!loc.duplicateCount)
						{
							// this is not a duplicate so we can just insert it as is
							loc.newItem = loc.iItem;
							loc.newProperty = loc.property;
						}
						else
						{
							// this is a duplicate so we prepend the class name and then insert it unless a property with the resulting name already exist
							loc.classData = loc.classes[loc.duplicateCount];

							// prepend class name to the property
							loc.newProperty = loc.classData.modelName & loc.property;

							if (loc.iItem Contains " AS ")
								loc.newItem = ReplaceNoCase(loc.iItem, ' AS "' & loc.property & '"', ' AS "' & loc.newProperty & '"');
							else
								loc.newItem = loc.iItem & ' AS "' & loc.newProperty & '"';
						}
						if (!ListFindNoCase(loc.addedProperties, loc.newProperty))
						{
							loc.newSelect = ListAppend(loc.newSelect, loc.newItem);
							loc.addedProperties = ListAppend(loc.addedProperties, loc.newProperty);
						}
					}
					loc.list = loc.newSelect;
				}
			}
			else
			{
				loc.list = arguments.list;
				if (!arguments.renameFields && Find(" AS ", loc.list))
					loc.list = REReplace(loc.list, variables.wheels.class.RESQLAs, "", "all");
			}
		</cfscript>
		<cfreturn loc.list />
	</cffunction>

</cfcomponent>