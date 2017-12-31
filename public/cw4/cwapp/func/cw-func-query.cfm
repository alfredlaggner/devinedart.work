<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-func-query.cfm
File Date: 2012-02-01
Description: misc. Cartweaver query functions
==========================================================
--->

<!--- /////////////// --->
<!--- COUNTRY / REGION QUERIES --->
<!--- /////////////// --->

<!--- // ---------- Get ALL State/Provs ---------- // --->
<cffunction name="CWquerySelectStates" access="public" output="false" returntype="query"
			hint="Returns a query with all available states including country details">

			<cfargument name="country_id" required="false" default="0" type="numeric"
						hint="The Country ID to lookup. Default is 0 (all)">

<cfset var rsGetStateList = "">
<cfquery name="rsGetStateList" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT
	cw_countries.*,
	cw_stateprov.*
FROM cw_countries
INNER JOIN cw_stateprov
	ON cw_countries.country_id = cw_stateprov.stateprov_country_id
WHERE
	cw_stateprov.stateprov_archive = 0
	AND cw_countries.country_archive = 0
	<cfif arguments.country_id gt 0>
	AND cw_countries.country_id = #arguments.country_id#
	</cfif>
ORDER BY
	cw_countries.country_sort,
	cw_countries.country_name,
	cw_stateprov.stateprov_name
</cfquery>

<cfreturn rsGetStateList>
</cffunction>

<!--- // ---------- Get ALL Countries ---------- // --->
<cffunction name="CWquerySelectCountries" access="public" output="false" returntype="query"
			hint="Returns a query with all available countries">

		<cfargument name="show_archived" required="false" default="1" type="boolean"
					hint="Include archived countries (y/n)">

<cfset var rsGetCountryList = "">
<cfquery name="rsGetCountryList" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT country_id, country_name
FROM cw_countries
<cfif arguments.show_archived eq 0>
WHERE NOT country_archive = 1
</cfif>
ORDER BY country_name
</cfquery>

<cfreturn rsGetCountryList>
</cffunction>

<!--- // ---------- Get ALL State/Provs by country ---------- // --->
<cffunction name="CWquerySelectCountryStates" access="public" output="false" returntype="query"
			hint="Returns a query with all available countries">

		<cfargument name="states_archived" required="false" default="0" type="numeric"
					hint="Show archived or active countries (1=archived,0=active,)">

<cfset var rsCountryStatesList = "">
<cfquery name="rsCountryStatesList" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT
cw_countries.*,
cw_stateprov.*
FROM cw_countries
LEFT JOIN cw_stateprov
ON cw_countries.country_id = cw_stateprov.stateprov_country_id
<cfif arguments.states_archived neq 2>
WHERE cw_countries.country_archive = #arguments.states_archived#
</cfif>
ORDER BY country_sort, country_name, stateprov_name
</cfquery>

<cfreturn rsCountryStatesList>
</cffunction>

<!--- // ---------- Get Country IDs for user defined states ---------- // --->
<cffunction name="CWquerySelectStateCountryIDs" access="public" output="false" returntype="query"
			hint="Select country IDs with user defined states">

<cfset var rsGetStateCountryIDs = ''>

<cfquery name="rsGetStateCountryIDs" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT DISTINCT stateprov_country_id
FROM cw_stateprov
WHERE NOT #application.cw.sqlLower#(stateprov_name) in('none','all')
</cfquery>

<cfreturn rsGetStateCountryIDs>

</cffunction>

<!--- // ---------- Get State/Prov Details ---------- // --->
<cffunction name="CWquerySelectStateProvDetails" access="public" output="false" returntype="query"
			hint="Look up stateprov details by ID, name or code - at least one argument must match">

	<cfargument name="stateprov_id" required="true" type="numeric"
				hint="ID of the stateprov to look up - pass in 0 to select all IDs">
	<cfargument name="stateprov_name" required="false" default='' type="string"
				hint="Name of the stateprov - pass in blank '' or omit to select all names">
	<cfargument name="stateprov_code" required="false" default='' type="string"
				hint="Stateprov processing code - pass in blank '' or omit to select all codes">
	<cfargument name="country_id" required="false" default="0" type="boolean"
				hint="Stateprov related country ID - pass in 0 or blank to select all countries">
	<cfargument name="omit_list" required="false" default="0" type="string"
		hint="A list of IDs to omit">

	<cfset var rsSelectStateProv = ''>

		<!--- look up stateprov --->
		<cfquery name="rsSelectStateProv" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT *
		FROM cw_stateprov
		WHERE 1 = 1
		<cfif arguments.stateprov_id gt 0>AND stateprov_id = #arguments.stateprov_id#</cfif>
		<cfif arguments.stateprov_name gt 0>AND stateprov_name = '#arguments.stateprov_name#'</cfif>
		<cfif arguments.stateprov_code gt 0>AND stateprov_code = '#arguments.stateprov_code#'</cfif>
		<cfif arguments.country_id gt 0>AND stateprov_country_id = #arguments.country_id#</cfif>
		<cfif arguments.omit_list neq 0>AND NOT stateprov_id in(#arguments.omit_list#)</cfif>
		</cfquery>

	<cfreturn rsSelectStateProv>

</cffunction>

<!--- /////////////// --->
<!--- CREDIT CARD QUERIES --->
<!--- /////////////// --->

<!--- // ---------- Get All Credit Cards ---------- // --->
<cffunction name="CWquerySelectCreditCards" access="public" output="false" returntype="query"
			hint="Returns a query with all credit card names and codes">

	<cfargument name="card_code"
			required="false"
			default=""
			type="string"
			hint="a card code to match">

<cfset var rsCCardList = ''>
<cfquery name="rsCCardList" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT *
FROM cw_credit_cards
<cfif len(trim(arguments.card_code))>
WHERE creditcard_code = <cfqueryparam value="#trim(arguments.card_code)#" cfsqltype="cf_sql_varchar">
</cfif>
ORDER BY creditcard_name
</cfquery>

<cfreturn rsCCardList>
</cffunction>

</cfsilent>