<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: errorRequest.cfm
File Date: 2012-02-01
Description:
Handle request errors / included via application.cw.cfc
==========================================================
--->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head>
		<title>Request Error</title>
		<link href="css/cw-layout.css" rel="stylesheet" type="text/css">
		<link href="theme/default/cw-admin-theme.css" rel="stylesheet" type="text/css">
	</head>
	<body>
		<div id="CWadminWrapper">
			<!-- Page Content Area -->
			<div style="text-align:center;">
				<div style="padding:200px 0;margin:0 auto;width:370px;">
					<h1 style="text-align:center;">An error has occurred</h1>
					<p>&nbsp;</p>
					<p>&nbsp;</p>
					<p style="text-align:center;">
					Please go <a href="javascript:history.back()">back</a> and try another option.</p>
					<p>&nbsp;</p>
					<p style="text-align:center;">If the problem persists, <a href='mailto:#error.mailto#?subject=Error on Page #error.template#&body=Message: #error.diagnostics# | Error on Page: #error.template# | Referring Page: #error.httpreferer# | Query String:#error.querystring# | Date Time: #error.dateTime#'>contact the site administrator</a>.</p>
				</div>
			</div>
		</div>
	</body>
</html>