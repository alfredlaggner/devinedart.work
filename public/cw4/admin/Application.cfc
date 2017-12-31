<cfcomponent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2010, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: application.cw.cfc (cartweaver admin)
File Date: 2012-12-30
Description: controls application variables and global functions
Note: includes global settings via cw-config.cfm
==========================================================
--->
<!--- //////////// --->
<!--- Edit the CWconfig file to change site settings --->
<!--- //////////// --->
<cfinclude template="../cwconfig/cw-config.cfm">
<!--- //////////// --->
<!--- //////////// --->
<!--- //////////// --->
<!--- //////////// --->
<!--- No Need to Edit Below This Line --->
<!--- //////////// --->
<!--- //////////// --->
<!--- //////////// --->
<!--- //////////// --->
<!--- global application settings --->
<cfinclude template="../cwapp/appcfc/cw-app-cfcstart.cfm">

<!--- // ---------- REQUEST START ---------- // --->
<cffunction name="onRequestStart">
	<cfparam name="request.cwpage.userAlert" default="">
	<cfparam name="request.cwpage.userConfirm" default="">
	<cfif (not isDefined('application.cw.dsn')) or (not len(trim(application.cw.dsn)) gt 0)>
	<cfset application.cw.dsn = request.cwapp.datasourcename>
	<cfset application.cw.dsnUsername = request.cwapp.datasourceusername>
	<cfset application.cw.dsnPassword = request.cwapp.datasourcepassword>
	</cfif>
	<!--- global variable for path to cwapp/ directory - end with trailing slash
	(front end mail and init functions in /cwapp/func/ are used by admin)
	--->
	<cfparam name="request.cwpage.cwapppath" default="../cwapp/">	
	<!--- verify DSN --->
	<cfif not isDefined('application.cw.dbok')>
	<cftry>
		<cfquery name="checkDB" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT config_value
		FROM cw_config_items
		WHERE config_variable = 'appVersionNumber'
		</cfquery>
			<cfif checkDB.recordCount>
			<cfset application.cw.dbok = true>
			<cfelse>
			<cfset request.cwpage.logonerror = 'Datasource Unavailable'>
			</cfif>
	<cfcatch>
			<cfset request.cwpage.logonerror = 'Datasource Unavailable'>
	</cfcatch>
	</cftry>
	</cfif>
	<!--- if the dsn is ok --->
	<cfif isdefined('application.cw.dbok')>
	<!--- global settings --->
	<cfinclude template="#request.cwpage.cwapppath#func/cw-func-init.cfm">
	<!--- initialize application scope variables --->
	<cfset initApplication = CWinitApplication()>
	<!--- initialize request scope variables --->
	<cfset initRequest = CWinitRequest()>
	<!--- clean form and url vars --->
	<cfinclude template="cwadminapp/inc/cw-inc-admin-sanitize.cfm">
	<!--- default for admin HTTPS redirection --->
	<cfparam name="application.cw.adminHttpsRedirectEnabled" default="false">	
	<!--- LOG IN --->
	<!--- Verify the user is logged in. --->
	<cflock scope="Session" type="exclusive" timeout="5">
	<!--- these pages are not redirected (list)--->
	<cfset loginExceptions = 'product-image-upload.cfm,product-image-select.cfm'>
	<cfif request.cw.thisPage neq "index.cfm"
			AND request.cw.thisPage neq "db-setup.cfm"
			AND (NOT IsDefined("session.cw.loggedIn") OR session.cw.loggedIn eq 0)>
		<cfset strUrl="#cgi.script_name#?#cgi.query_string#">
		<cfif Find("helpfiles",cgi.script_name)>
			<cflocation url="../index.cfm?accessdenied=#URLEncodedFormat(strUrl)#" addtoken="no">
		<cfelse>
			<!--- if not in our excepted file list --->
			<cfif not ListFindNoCase(loginExceptions,listLast(cgi.SCRIPT_NAME,'/'))>
				<!--- remove trigger variables for returning after login  --->
				<cfset relocUrl = replace(strUrl,'logout=1','')>
				<cfset relocUrl = replace(relocUrl,'&timeout=1','')>
				<!--- set up url to log out to --->
				<cfset logoutUrl = 'index.cfm?'>
				<!--- if redirecting due to timeout, add trigger to login page querystring --->
				<cfif isDefined('url.timeout') and url.timeout is 1>
					<cfset logoutUrl = logouturl & '&timeout=1'>
				</cfif>
				<cfset logoutUrl = logoutUrl & 'accessdenied=#URLEncodedFormat(relocUrl)#'>
				<cflocation url="#logoutUrl#" addtoken="no">
			<!--- if it is an excepted page, show message, stop processing --->
			<cfelse>
				<cfoutput>
				<span style="font-size:12px; font-family:Arial, sans-serif;color:##990000;">Log In to Continue</span>
				</cfoutput>
				<cfabort>
			</cfif>
		</cfif>
	</cfif>
	</cflock>
	<!--- https redirection --->
	<cftry>
		<!--- if admin secure redirection is enabled --->
		<cfif left(application.cw.appSiteUrlHttps,6) eq 'https:'
				and application.cw.adminHttpsRedirectEnabled is true>
			<!--- check for secure connection to page --->
			<cfset request.cw.requestContext = getPageContext().getRequest()>	
			<!--- if page is being requested via http, send to https version of same address --->
			<cfif not (request.cw.requestContext.isSecure() or cgi.https is 'on' or cgi.server_port_secure is '1')>
				<cflocation url="https://#request.cw.requestContext.getServerName()##request.cw.requestContext.getRequestURI()#?#request.cw.requestContext.getQueryString()#" addtoken="false">
			</cfif>
		</cfif>
		<cfcatch></cfcatch>
	</cftry>	
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
	<!--- error handling --->
	<cfif application.cw.adminErrorHandling is true>
		<!--- capture most errors --->
		<cferror type="exception" template="error-exception.cfm" mailto="#application.cw.developerEmail#">
		<!--- if exception handler fails, this is shown --->
		<cferror type="request" template="error-request.cfm" mailto="#application.cw.developerEmail#">
	</cfif>
	<!--- if db is not ok, send to home page --->
	<cfelse>
		<cfif not cgi.script_name contains 'index.cfm' and not cgi.script_name contains 'db-setup.cfm'>
			<cflocation url="index.cfm" addtoken="no">
		<!--- on admin home page, check for db setup available --->
		<cfelseif fileExists(expandPath('db-setup.cfm')) and not cgi.script_name contains 'db-setup.cfm'>
			<cflocation url="db-setup.cfm" addtoken="no">
		</cfif>
	</cfif>
	<!--- / end db ok check --->
	<!--- log out --->
	<cfif IsDefined('url.logout') and url.logout is not 0>
		<cfparam name="url.accessdenied" default="">
		<cfparam name="url.pagenotfound" default="">
		<!--- clear the session --->
		<cfloop list="#structkeylist(session)#" index="ss">
		<!--- leave session id alone to avoid errors --->
			<cfif not listFindNoCase('sessionid,cfid,urltoken,cftoken',ss)>
			<cfset cleanvar = structDelete(session,ss)>
			</cfif>
		</cfloop>
		<!--- redirect to login page --->
		<cflocation url="index.cfm?accessdenied=#url.accessdenied#&pagenotfound=#url.pagenotfound#" addtoken="no">
	</cfif>
</cffunction>
<!--- /END REQUEST START --->
<!--- // ---------- ERROR ---------- // --->
<cffunction name="onError" returntype="void" output="false">
	<cfargument name="exception" required="true">
	<cfargument name="eventName" type="string" required="true">
	<!--- throw back to <cferror> tags --->
	<cfthrow object="#arguments.exception#">
</cffunction>
<!--- /END ERROR --->
<!--- // ---------- MISSING TEMPLATE ---------- // --->
<cffunction name="onMissingTemplate" returnType="boolean" output="false">
	<cfargument type="string" name="targetPage" required="true">
	<!--- get the page name from the url requested --->
	<cfset var strUrl = listLast(targetPage,'/')>
	<!--- log the user out, showing a message on the log in page --->
	<cfset var relocateUrl = 'index.cfm?pagenotfound=#URLEncodedFormat(strUrl)#&logout=1'>
	<cflocation addtoken="false" url="#relocateurl#">
</cffunction>
<!--- /END MISSING TEMPLATE --->
</cfcomponent>