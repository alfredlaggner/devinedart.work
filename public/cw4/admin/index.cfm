<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: admin/index.cfm
File Date: 2012-08-25
Description:
Login page for store admin
==========================================================
--->
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<cfparam name="application.cw.companyName" default="Cartweaver">
<cfparam name="application.cw.adminThemeDirectory" default="default">
<cfparam name="session.cw.userAlert" default="">

<!--- if logging on --->
<cfif IsDefined("form.adminUsername")>
	<!--- QUERY: log on, look up the submitted username and password --->
	<cfset getLogOn = CWquerySelectUserLogin('#form.adminUsername#','#form.adminPassword#')>
	<cfparam name="LastLogin" default="#getLogOn.admin_login_date#">
	<cfif NOT len(trim(LastLogin)) OR NOT IsDate(LastLogin)>
		<cfset LastLogin=CreateODBCDateTime("2000-01-01 01:00:00")>
	<cfelse>
		<cfset LastLogin=CreateODBCDateTime(LastLogin)>
	</cfif>
	<!--- Record found, login  --->
	<cfif getLogOn.RecordCount>
		<cflock timeout="5" throwontimeout="no" type="exclusive">
		<!--- Set the session vars --->
		<cfset session.cw.loggedIn = 1>
		<!--- This session store the username --->
		<cfset session.cw.loggedUser="#getLogOn.admin_username#">
		<cfset session.cw.lastLogin = LastLogin>
		<cfset session.cw.accessLevel = getLogOn.admin_access_level>
		</cflock>
		<!--- Store username inside a cookie if remember me was checked --->
		<cfif isDefined("form.remember_me")>
			<cfcookie name="CWAdminUsername" value="#form.adminUsername#" expires="NEVER">
			<!--- Else, clean any existing cookie --->
		<cfelse>
			<cfcookie name="CWAdminUsername" value="" expires="NOW">
		</cfif>
		<!--- QUERY: update user logon date (user id, date) --->
		<cfset updateUser = CWqueryUpdateUserDate('#session.cw.loggedUser#',lastLogin)>
		<!--- QUERY: check for default 'admin' password and any of the default account names, show warning if exists --->
		<cfset getDefaultUsers = CWquerySelectUserLogin('admin,sa,merchant,developer,manager,service','admin',6)>
		<cfif getDefaultUsers.recordCount gt 0 and not application.cw.appTestModeEnabled>
			<cfset session.cw.userAlert = 'IMPORTANT: Default password (admin) still in use. Create a new user account or <a href="#cwTrailingChar(application.cw.appSiteUrlHttp)##cwTrailingChar(cwLeadingChar(application.cw.appCWAdminDir,"remove"),"remove")#/admin-users.cfm">change the password</a>.'>
		</cfif>
		<!--- ALERT IF NO AUTH METHODS EXIST --->
		<cfif (not isDefined('application.cw.authMethods')) OR application.cw.authMethods is ''
		 and not (isDefined('application.cw.appTestModeEnabled') and application.cw.appTestModeEnabled is true)>
			<cfset session.cw.userAlert = session.cw.userAlert & 'WARNING: Checkout Process Offline - payment transaction options for this store are currently unavailable.'>
		</cfif>
		<!--- QUERY: set installation date if not defined --->
		<cfif not (isDefined('application.cw.appInstallationDate') and isDate(application.cw.appInstallationDate))>
			<cfset installDate = CWsetInstallationDate()>
		</cfif>
		<!--- REDIRECT AFTER LOGIN --->
		<!--- If the user requested a specific page, redirect there --->
		<cfif IsDefined("form.redirect_to") and len(trim(form.redirect_to))>
			<cflocation addtoken="no" url="#URLDecode(form.redirect_to)#">
			<!--- if no specific page requested, use the defaults --->
		<cfelse>
			<!--- if store defaults still in place, developer goes to company settings by default  --->
			<cfif session.cw.accessLevel is 'developer' and application.cw.companyemail contains 'cartweaver'>
				<cflocation addtoken="no" url="config-settings.cfm?group_ID=3">
			<cfelse>
				<cflocation addtoken="no" url="admin-home.cfm">
			</cfif>
		</cfif>
		<!--- Login failed --->
	<cfelse>
		<!--- Display an error message --->
		<cfset request.cwpage.logonerror="Log on unsuccessful. No match was found. Please try again or contact administrator">
	</cfif>
</cfif>
<!--- set blank cookie value as a default --->
<cfif not isdefined("cookie.cwAdminUsername")>
	<cfcookie name="CWAdminUsername" value="">
</cfif>
</cfsilent>
<!--- REDIRECT FROM OTHER PAGES --->
<cfif isDefined('url.pagenotfound') and len(trim(url.pagenotfound))>
	<cfset request.cwpage.logonerror = "Page not found: #trim(urlDecode(url.pagenotfound))#">
<cfelseif isDefined('url.timeout') and len(trim(url.timeout))>
	<cfset request.cwpage.logonerror = "Session timed out. Log in again to continue.">
<cfelseif isDefined('url.dbsetup') and url.dbsetup is 'ok'>
	<cfset request.cwpage.logonerror = "Database setup complete">
</cfif>
<!--- START OUTPUT --->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head>
		<cfoutput>
<title>#application.cw.companyName# : Log In</title>
		</cfoutput>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<!-- admin styles -->
		<link href="css/cw-layout.css" rel="stylesheet" type="text/css">
		<link href="theme/
		<cfoutput>#application.cw.adminThemeDirectory#</cfoutput>/cw-admin-theme.css" rel="stylesheet" type="text/css">
	</head>
	<!--- focus cursor on username or password field depending on saved value --->
	<body onLoad="document.login.<cfif cookie.cwAdminUsername eq "">adminUsername<cfelse>adminPassword</cfif>.focus();">
		<div id="CWadminWrapper">
			<div id="CWadminLoginWrap">
				<cfif IsDefined("request.cwpage.logonerror")>
					<div class="alert"><cfoutput>#request.cwpage.logonerror#</cfoutput></div>
				</cfif>
				<cfif isDefined('application.cw.dbok')>
					<cfoutput>
						<form action="#request.cw.thisPage#" method="post" name="login" id="login">
							<h2>
							<cfoutput>#application.cw.companyName#</cfoutput>: Log In</h2>
							<table>
								<tr>
									<th class="rightText">Username</th>
									<td><input name="adminUsername" type="text" id="adminUsername" value="#cookie.cwAdminUsername#" class="focusField" tabindex="1"> </td>
								</tr>
								<tr>
									<th class="rightText">Password</th>
									<td>
										<input name="adminPassword" type="password" id="adminPassword" tabindex="2">
									</td>
								</tr>
								<tr class="dataRow">
									<td colspan="2" class="centerText">
										<div id="siteReturnLink">
											<a href="<cfoutput>#application.cw.appSiteUrlHttp#</cfoutput>" tabindex="10">Return to Site</a>
										</div>
										<input name="remember_me" type="checkbox" class="formCheckbox" tabindex="3" value="1"<cfif cookie.cwAdminUsername neq ""> checked</cfif>>
										Remember me
									</td>
								</tr>
							</table>
							<input name="Submit" type="submit" class="CWformButton" value="Log In" tabindex="4">
							<!--- Store the path to the requested page inside an hidden field --->
							<cfif IsDefined("url.accessdenied") and not url.accessdenied contains 'logout'>
								<input type="hidden" name="redirect_to" value="#URLEncodedFormat(url.accessdenied)#">
							</cfif>
						</form>
					</cfoutput>
				</cfif>
			</div>
		</div>
	</body>
</html>