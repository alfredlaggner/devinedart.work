<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: errorException.cfm
File Date: 2012-02-01
Description:
Handle exception errors / included via application.cw.cfc
==========================================================
--->

<cfparam name="error.mailto" default="">
<cfparam name="error.template" default="">
<cfparam name="application.cw.sitename" default="">
<cfparam name="application.cw.appSiteUrlHttp" default="">
<cfparam name="application.cw.errorheading" default="Error">
<cfparam name="application.cw.includestyle" default="">
<cfparam name="application.cw.includebodystart" default="">
<cfparam name="application.cw.includebodyend" default="">
<cfparam name="application.cw.mailSmtpServer" default="">
<cfparam name="application.cw.mailSmtpUsername" default="">
<cfparam name="application.cw.mailSmtpPassword" default="">

<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- START OUTPUT --->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head>
		<cfoutput>
		<title>#application.cw.companyName# : ERROR</title>
		</cfoutput>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<!-- admin styles -->
		<link href="css/cw-layout.css" rel="stylesheet" type="text/css">
		<link href="theme/<cfoutput>#application.cw.adminThemeDirectory#</cfoutput>/cw-admin-theme.css" rel="stylesheet" type="text/css">
	</head>
	<body>
		<div style="text-align:center;">
			<!--- page start content / dashboard --->
			<cfinclude template="cwadminapp/inc/cw-inc-admin-page-start.cfm">
			<!-- Page Content Area -->
			<div id="CWadminContent">
				<div style="padding:200px 0;margin:0 auto;width:370px;">
					<!--- Display error message --->
					<h1 style="text-align:center;"><cfoutput>Exception Error</cfoutput></h1>
					<p>&nbsp;</p>
					<p>&nbsp;</p>
					<p style="text-align:center;">The <a href="mailto:<cfoutput>#error.MailTo#</cfoutput>">site administrator</a> has been notified via email.</p>
					<p>&nbsp;</p>
					<p style="text-align:center;">Use your browser's back button or select another option.</p>
				</div>
			</div>
			<!-- /end Page Content -->
			<!--- page end content / debug --->
			<cfinclude template="cwadminapp/inc/cw-inc-admin-page-end.cfm">
			<!-- /end CWadminPage-->
			<div class="clear"></div>
		</div>
		<!-- /end CWadminWrapper -->
	</body>
</html>
<!--- send email --->
<cftry>
	<!--- set up the error content --->
	<cfsavecontent variable="errorText">
	<cfoutput>
	<p>Current URL: #request.cw.thisUrl#<br>
	Time: #dateFormat(now(), "short")# #timeFormat(now(), "short")#<br>
	</p>
	<p>
	User’s Browser: #error.browser#<br>
	URL Parameters: #error.queryString#<br>
	Previous Page: #error.HTTPReferer#<br>
	<br>
	------------------------------------<br>
	#error.diagnostics#<br>
	------------------------------------<br>
	<br>
	</p>
	<cfif isdefined('application.cw.errorlog') and trim(application.cw.errorlog) is not ''>
		<p>View Log File: <a href="#logfileurl#">#logfileurl#</a> </p>
	</cfif>
	</cfoutput>
	<cfdump var="#error.TagContext#" label="error" format="text">
	<br><br>
	<cfdump var="#form#" label="Form" format="text">
	<br><br>
	<cfdump var="#url#" label="URL" format="text">
	<br><br>
	<cfif isdefined('arguments.exception.sql')>
		<cfdump var="#arguments.exception.sql#" format="text">
		<br><br>
	</cfif>
	</cfsavecontent>
	<!--- Send an email message to site administrator --->
	<cfif error.mailTo neq "">
		<cfif len(trim(application.cw.mailSmtpServer))>
			<cfmail to="#error.mailTo#" from="#error.mailTo#" type="html" subject="#application.cw.companyName# : error on Page #error.Template#" server="#application.cw.mailSmtpServer#" username="#application.cw.mailSmtpUsername#" password="#application.cw.mailSmtpPassword#">
				#errorText#
			</cfmail>
		<cfelse>
			<cfmail to="#error.mailTo#" from="#error.mailTo#" type="html" subject="#application.cw.companyName# : error on Page #error.Template#">
				#errorText#
			</cfmail>
		</cfif>
	</cfif>
	<cfcatch></cfcatch>
</cftry>