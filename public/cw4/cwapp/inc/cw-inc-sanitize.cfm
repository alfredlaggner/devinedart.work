<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-sanitize.cfm
File Date: 2013-01-10
Description: cleans up all form and url variables for processing
==========================================================
--->
<!--- verify only included once in any page --->
<cfif not (isDefined('request.cwpage.sanitized') and request.cwpage.sanitized is true)>
	<!--- global functions--->
	<cfif not isDefined('variables.CWtime')>
		<cfinclude template="../func/cw-func-global.cfm">
	</cfif>
	<!--- list of url variables that must be numeric --->
	<cfset request.cwpage.numericQS = 'product,category,secondary,page,showall,cartconfirm,custreset,shipreset,authreset,logout'>
	<!--- remove unwanted content from form and url variables --->
	<cfif isDefined('form.fieldnames')>
		<!--- clean up form submissions --->
		<cfloop list="#form.fieldnames#" index="f">
			<!--- clean up each value --->
			<cfset form[f] = CWsafeHTML(form[f])>
		</cfloop>
	</cfif>
	<cfset urlvars = CWremoveUrlVars(returncontent='vars')>
	<cfif listLen('urlvars')>
		<!--- clean up url variables --->
		<cfloop list="#urlvars#" index="v">
			<cftry>
				<cfset v = ReReplaceNoCase(v,"[^a-zA-Z0-9-..]","","all")>
				<cfparam name="url.#v#" default="">
				<cfset url[v] = Replace(url[v],"'","","all")>
				<cfset url[v] = ReReplaceNoCase(url[v],'(?s)<\s?script.*?(/\s?>|<\s?/\s?script\s?>)','')>
				<cfset varVal = ReReplaceNoCase(url[v],"[<>\(\);]","","all")>				
				<!--- full html escaping --->
				<cfset url[v] = CWsafeHTML(url[v])>
				<cfcatch>
					<cfset url[v] = ''>
				</cfcatch>
			</cftry>
		</cfloop>		 
	</cfif>
	<!--- verify numeric values for url or form numeric id fields --->
	<cfloop list="#request.cwpage.numericQS#" index="i">
		<cfif isDefined('form.#i#') and Not isNumeric(form[i])>
			<cfset form[i] = val(form[i])>
		</cfif>
		<cfif isDefined('url.#i#') and Not isNumeric(url[i])>
			<cfset url[i] = val(url[i])>
		</cfif>
	</cfloop>
	<cfset request.cwpage.sanitized = true>
</cfif>
<!--- /end only include once --->
</cfsilent>