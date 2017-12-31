<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-app-onrequeststart.cfc
File Date: 2012-11-14
Description: Cartweaver onRequestStart method contents, used in front-end Application.cfc
==========================================================
--->
<cfset application.cw.appIncludePath = "../">
<cfparam name="request.cwapp.datasourcename" default="">
<cfparam name="request.cwapp.datasourceusername" default="">
<cfparam name="request.cwapp.datasourcepassword" default="">
<!--- set up DSN query variables --->
<cfif not (isDefined('application.cw.dsn') AND application.cw.dsn eq request.cwapp.datasourcename)>
	<cfset application.cw.dsn = request.cwapp.datasourcename>
	<cfset application.cw.dsnUsername = request.cwapp.datasourceusername>
	<cfset application.cw.dsnPassword = request.cwapp.datasourcepassword>
</cfif>
<!--- remove temporary structure --->
<cfset structDelete(request,'cwapp')>
<!--- INIT FUNCTIONS set up global variables --->
<cfif not isDefined('variables.CWinitRequest')>
	<cfinclude template="#application.cw.appIncludePath#func/cw-func-init.cfm">
</cfif>
<!--- initialize application scope variables --->
<cfset initApplication = CWinitApplication()>
<!--- initialize request scope variables --->
<cfset initRequest = CWinitRequest()>
<!--- product page request variables --->
<cfif request.cw.thisPage is listLast(request.cwpage.urlDetails,'/')
   OR request.cw.thisPage is listLast(request.cwpage.urlResults,'/')>
	<cfinclude template="#application.cw.appIncludePath#inc/cw-inc-productrequest.cfm">
<cfelse>
	<!--- defaults prevent errors when filenames don't match --->
	<cfset request.cwpage.title = application.cw.companyName>
	<cfset request.cwpage.description = ''>
</cfif>
<!--- html head content (not needed for product pop-up or other modular files) --->
<cfif not cgi.script_name contains 'cw-inc-' and not request.cw.thisPage is listLast(request.cwpage.urlDownload,'/')>
	<cfinclude template="#application.cw.appIncludePath#inc/cw-inc-htmlhead.cfm">
</cfif>
<!--- session defaults --->
<cfparam name="session.cw.debug" default="false">
<!--- block database injection attempts by redirecting to home page --->
<cfif len(trim(application.cw.appSiteUrlHttp))
	AND (
	FindNoCase('cast(',cgi.query_string)
	OR findNoCase('declare',cgi.query_string)
	OR findNoCase('EXEC(@',cgi.query_string)
	)>
	<cflocation url="#application.cw.appSiteUrlHttp#" addtoken="no">
</cfif>