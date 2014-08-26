<cfcomponent extends="wheelsMapping.Test" output="false">

	<cffunction name="setup">
		<cfquery datasource="wheelstestdb">
			create or replace view all_tab_columns as
			select
				table_schema as owner,
				table_name,
				column_name,
				case type_name
					when 'STRING' then 'VARCHAR2'
					when 'VARCHAR' then 'VARCHAR2'
					when 'INTEGER' then 'NUMBER'
					when 'DOUBLE' then 'NUMBER'
					when 'DECIMAL' then 'NUMBER'
					else type_name
				end
				as data_type,
				is_nullable as nullable,
				numeric_precision as data_precision,
				character_maximum_length as data_length,
				numeric_scale as data_scale,
				column_default as data_default,
				ordinal_position as column_id
			from information_schema.columns
			where table_schema<>'INFORMATION_SCHEMA' and table_name<>'AUTHORS'
		</cfquery>
		<cfquery datasource="wheelstestdb">
			create or replace view all_constraints as
			select
				table_schema as owner,
				table_name,
				left(constraint_type,1) as constraint_type,
				constraint_name
			from information_schema.constraints
			where table_schema<>'INFORMATION_SCHEMA' and table_name<>'AUTHORS'
		</cfquery>
		<cfquery datasource="wheelstestdb">
			create or replace view all_cons_columns as
			select
				table_schema as owner,
				column_name,
				constraint_name
			from information_schema.indexes
			where table_schema<>'INFORMATION_SCHEMA' and table_name<>'AUTHORS'
		</cfquery>
		<cfquery datasource="wheelstestdb">
			create or replace view all_tab_columns_at_mydblink as
			select
				table_schema as owner,
				table_name,
				column_name,
				case type_name
					when 'STRING' then 'VARCHAR2'
					when 'VARCHAR' then 'VARCHAR2'
					when 'INTEGER' then 'NUMBER'
					when 'DOUBLE' then 'NUMBER'
					when 'DECIMAL' then 'NUMBER'
					else type_name
				end
				as data_type,
				is_nullable as nullable,
				numeric_precision as data_precision,
				character_maximum_length as data_length,
				numeric_scale as data_scale,
				column_default as data_default,
				ordinal_position as column_id
			from information_schema.columns
			where table_schema<>'INFORMATION_SCHEMA' and table_name='AUTHORS'
		</cfquery>
		<cfquery datasource="wheelstestdb">
			create or replace view all_constraints_at_mydblink as
			select
				table_schema as owner,
				table_name,
				left(constraint_type,1) as constraint_type,
				constraint_name
			from information_schema.constraints
			where table_schema<>'INFORMATION_SCHEMA' and table_name='AUTHORS'
		</cfquery>
		<cfquery datasource="wheelstestdb">
			create or replace view all_cons_columns_at_mydblink as
			select
				table_schema as owner,
				column_name,
				constraint_name
			from information_schema.indexes
			where table_schema<>'INFORMATION_SCHEMA' and table_name='AUTHORS'
		</cfquery>
		<cfquery datasource="wheelstestdb">
			create or replace view all_synonyms as
			select
				'MYDBLINK' as db_link,
				table_name as synonym_name
			from information_schema.tables
			where table_schema<>'INFORMATION_SCHEMA' and table_name='AUTHORS'
		</cfquery>
		<cfset application.wheels.plugins.oracledblink.init(dblinksign='_at_')>
	</cffunction>

	<cffunction name="test_findOne" hint="can search for model in module paths">
		<cfset results.author = model("author").findOne(1)>
		<cfset assert("IsObject(results.author)")>
	</cffunction>

	<cffunction name="teardown">
		<cfinclude template="../../../src/test/coldfusion/_oracle-emu.cfm">
	</cffunction>

</cfcomponent>