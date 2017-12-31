<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: product-file-preview.cfm
File Date: 2012-08-25
Description: delivers file as browser download based on sku id in url
==========================================================
--->
<!--- time out the page if it takes too long - avoid server overload --->
<cfsetting requesttimeout="9000">
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<cfinclude template="cwadminapp/func/cw-func-download.cfm">
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("any")>
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "File Download">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "File Download Preview">
<!--- sku id must be provided to get file --->
<cfparam name="url.sku" default="0">
<cfset downloadOK = false>
	<!--- GET FILE --->
	<cfif isNumeric(url.sku) and url.sku gt 0>
		<cfset filePath = CWcreateDownloadPath(sku_id=url.sku)>
		<!--- if file exists --->
		<cfif len(trim(filePath))>
			<cfset downloadOK = true>
		</cfif>
	</cfif>
</cfsilent>

<!--- START OUTPUT --->
<!--- if file is available, deliver as downloadable --->
<cfif downloadOK>

<cftry>
<!--- download details - server path and saved filename --->
<cfset fileName = listLast(filePath,'/')>
<cfset fileDir = left(filePath,len(filePath)-len(fileName))>
<!--- get friendly filename --->
<cfset downloadName = cwQueryGetSkuFile(url.sku)>
<cfif not len(trim(downloadName))>
	<cfset downloadName = filename>
</cfif>
	<!--- get file size --->
	<cfset fileLookup = getFileInfo(filePath)>
	<cfset fileSize = fileLookup.size>
	<!---set headers--->
	<cfheader name="Content-Length" value="#filesize#">
	<cfheader name="Content-Disposition" VALUE="attachment; filename=#downloadName#">
	<!--- serve up file content --->
	<cfcontent type="application/unknown" file="#filePath#">
	<cfabort>
<!--- on error, reload, show unavailable message --->
<cfcatch>
	<cflocation url="#cgi.script_name#" addtoken="no">
</cfcatch>
</cftry>

<!--- if file is not available, show message --->
<cfelse>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head>
		<title>Product File Preview</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<link href="css/cw-layout.css" rel="stylesheet" type="text/css">
		<link href="theme/<cfoutput>#application.cw.adminThemeDirectory#</cfoutput>/cw-admin-theme.css" rel="stylesheet" type="text/css">
		<!-- admin javascript -->
		<cfinclude template="cwadminapp/inc/cw-inc-admin-scripts.cfm">
	</head>
	<body <cfoutput>class="#listFirst(request.cw.thisPage, '.')#"</cfoutput>>
		<div id="CWadminWrapper">
			<!-- Main Content Area -->
			<div id="CWadminPage">
				<!-- inside div to provide padding -->
				<div class="CWinner">
					<cfif len(trim(request.cwpage.heading1))><cfoutput><h1>#trim(request.cwpage.heading1)#</h1></cfoutput></cfif>
				</div>
				<!-- Page Content Area -->
				<div id="CWadminContent">
					<p>&nbsp;</p>
					<p>&nbsp;</p>
					<p>&nbsp;</p>
					<p><strong>Download unavailable.</strong> <br><br>Verify the file has been uploaded and saved correctly.</p>
				</div>
			</div>
		</div>

	</body>
</html>
</cfif>
<!--- /end if downloadok --->