<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: CWincAdminPageStart
File Date: 2012-08-25
Description: Admin dashboard controls and other global page start elements
==========================================================
--->
<!--- DEBUGGING --->
<cfif isDefined("url.debug")
	AND isDefined('session.cw.accessLevel') AND listFindNoCase('developer',session.cw.accessLevel)
	AND application.cw.debugEnabled eq 'true'>

	<cfif url.debug eq application.cw.storePassword
		AND NOT session.cw.debug eq 'true'
		AND NOT(
			isDefined('url.resetapplication')
			AND url.resetapplication eq application.cw.storePassword
			)>
		<cfset session.cw.debug = "true">
	</cfif>
	<cfset varsToKeep = CWremoveUrlVars("debug,resetapplication,userconfirm,useralert")>
	<cfset request.redirectUrl = CWserializeUrl(varsToKeep, request.cw.thisPage)>
	<cflocation url="#request.redirecturl###debug-top" addtoken="false">
</cfif>
<!--- view site link - default cw store root location if site http url not provided --->
<cfif not (isDefined('request.cwpage.viewSiteUrl') and len(trim(request.cwpage.viewSiteUrl)) gt 1)>
	<cfset request.cwpage.viewSiteUrl = "../../">
	<cfset application.cw.adminProductLinksEnabled = false>
</cfif>
<!--- custom view site link for product page --->
<cfif application.cw.adminProductLinksEnabled and request.cw.thisPage contains 'product-details.cfm' and isDefined('url.productid')>
	<cfset request.cwpage.viewSiteText = "View Product">
	<cfset request.cwpage.viewSiteUrl = "#application.cw.appPageDetailsUrl#?product=#url.productid#">
</cfif>
<!--- strip out debug  --->
<cfset resetVarsToKeep = CWremoveUrlVars("debug,userconfirm,useralert,resetapplication")>
<cfset request.cw.baseString = CWserializeUrl(resetVarsToKeep, request.cw.thisPage)>
<cfset request.cw.baseDebugLink = request.cw.baseString & '&debug=' & application.cw.storePassword>
<cfset request.cw.baseResetLink = request.cw.baseString & '&resetapplication=' & application.cw.storePassword>
<!--- debug link url --->
<cfif isDefined('session.cw.accessLevel') AND listFindNoCase('merchant,developer',session.cw.accessLevel)
	AND application.cw.debugEnabled eq 'true'>
	<!--- if debug is on, add reset control to debugging link (turn debugging back off to reset application) --->
	<cfif isDefined('session.cw.debug') AND session.cw.debug eq 'true'>
		<cfset request.cw.baseDebugLink = request.cw.baseDebugLink & '&resetapplication=' & application.cw.storePassword>
	</cfif>
</cfif>
<!--- help link url --->
<cfif request.cw.thisPage is 'config-settings.cfm' and isDefined('url.group_id') and url.group_id gt 0>
	<!--- for config settings, use the group name --->
	<cfset request.cwpage.helpFileName = lcase(replace(CWgetConfigGroupName(url.group_id),' ','-','all'))>
<cfelse>
	<!--- other pages, use the page name --->
	<cfset request.cwpage.helpFileName = lcase(listFirst(request.cw.thisPage,'.'))>
</cfif>
<!--- remove non-alpha chars --->
<cfset request.cwpage.helpFileName = rereplace(request.cwpage.helpFileName,'[\s]','-','all')>
<cfset request.cwpage.helpFileName = rereplace(request.cwpage.helpFileName,'[^a-zA-Z-]','','all')>
</cfsilent>
<!-- admin dashboard controls/search -->
<div id="CWadminDashboard">
	<!-- admin help icon/link -->
	<div id="CWadminHelp">
		<a href="http://help.cartweaver.com/CW4_Docs_AdminHelp/index.cfm?pagename=<cfoutput>#request.cwpage.helpFileName#</cfoutput>" class="zoomHelp" rel="external" title="Help for this page">
		<img src="img/cw-help.png" alt="Help for this page" width="16" height="16" align="absmiddle">
		</a>
	</div>
	<!-- logged in as -->
	<cfoutput>
	<span id="loggedInAs">Logged in as <cfoutput><em>#session.cw.loggedUser#</em></cfoutput></span>
	<!-- log out -->
	<a id="logoutLink" href="#request.cw.thisPageQS#&logout=1">Log Out</a>
	<!-- view site -->
	<cfif isDefined('request.cwpage.viewSiteUrl') and len(trim(request.cwpage.viewSiteUrl))
		  AND isDefined('request.cwpage.viewSiteText') and len(trim(request.cwpage.viewSiteText))>
		<a id="viewSiteLink" href="#request.cwpage.viewSiteUrl#" rel="external">#request.cwpage.viewSiteText#</a>
	</cfif>
	<!-- reset / debugging -->
	<cfif isDefined('session.cw.accessLevel')
		AND listFindNoCase('developer',session.cw.accessLevel)>
		<a id="resetLink" href="<cfoutput>#request.cw.baseResetLink#</cfoutput>">Reset</a>
		<cfif application.cw.debugEnabled eq 'true'>
			<a id="debugLink" href="<cfoutput>#request.cw.baseDebugLink#</cfoutput>">Turn <cfif session.cw.debug>Off<cfelse>On</cfif> Debugging</a>
		</cfif>
	</cfif>
	</cfoutput>
</div>