<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: order-email.cfm
File Date: 2012-02-01
Description: Displays order email confirmation message contents
==========================================================
--->
<!--- GLOBAL INCLUDES --->
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- include the mail functions --->
<cfinclude template="#request.cwpage.cwapppath#func/cw-func-mail.cfm">
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("any")>
<!--- PAGE PARAMS --->
<cfparam name="url.orderid" default="">
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Order Details Email Content">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Order Details&nbsp;&nbsp;&nbsp;
<span class='subHead'>ID: #url.order_id#&nbsp;&nbsp;&nbsp;</span>
">
</cfsilent>
<!--- START OUTPUT --->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head>
		<cfoutput>
		<title>#application.cw.companyName# : #request.cwpage.title#</title>
		</cfoutput>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<!-- admin styles -->
		<link href="css/cw-layout.css" rel="stylesheet" type="text/css">
		<link href="theme/<cfoutput>#application.cw.adminThemeDirectory#</cfoutput>/cw-admin-theme.css" rel="stylesheet" type="text/css">
	</head>
	<!--- body gets a class to match the filename --->
	<body <cfoutput>
		class="#listFirst(request.cw.thisPage, '.')#"</cfoutput>>
		<!-- inside div to provide padding -->
		<div class="CWinner">
			<h2><cfoutput>#request.cwpage.heading1#</cfoutput></h2>
			<!--- get the order email contents --->
			<cfset mailContent = CWtextOrderDetails(url.order_id)>
			<!--- show in text area to retain formatting --->
			<p style="text-align:center;">This is a representation of the order contents using current settings.<br>The actual message sent to the customer may vary slightly.<br><br></p>
			<form>
<textarea rows="24" cols="64">
<cfoutput>#application.cw.mailDefaultOrderShippedIntro#
#chr(10)##chr(13)##chr(10)#
#mailContent#
#chr(10)##chr(13)##chr(10)#
#application.cw.mailDefaultOrderShippedEnd#</cfoutput>
</textarea>
			</form>
		</div>
		<!-- /end CWinner -->
		<div class="clear"></div>
		<!-- /end CWadminPage-->
		<div class="clear"></div>
	</body>
</html>