<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2010, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-download.cfm
File Date: 2012-08-25
Description: delivers product as downloadable file, handles
authentication and access messages
==========================================================
--->
<!--- default url variables --->
<cfparam name="url.sku" default="0" type="numeric">
<!--- default authentication --->
<cfparam name="request.cwpage.dlok" default="false">
<cfparam name="request.cwpage.dlerror" default="Access Denied">
<cfparam name="session.cwclient.cwCustomerID" default="0">
<cfparam name="request.cwpage.loginurl" default="#request.cwpage.urlAccount#">
<!--- clean up form and url variables --->
<cfinclude template="cwapp/inc/cw-inc-sanitize.cfm">
<!--- CARTWEAVER REQUIRED FUNCTIONS --->
<cfinclude template="cwapp/inc/cw-inc-functions.cfm">
<!--- check customer permission, downloads enabled --->
<cfif session.cwclient.cwCustomerID neq 0
      AND application.cw.appDownloadsEnabled>
	<!--- verify this customer can get this file --->
	<cfset downloadCheck = CWcheckCustomerDownload(
								url.sku,
								session.cwclient.cwCustomerID
								)>
	<!--- if a "0-" error message is returned, no dl available, show text string --->
	<cfif left(downloadCheck,2) is '0-'>
		<cfset request.cwpage.dlerror = listRest(downloadCheck,'-')>
	<cfelse>
		<cfset request.cwpage.dlok = true>
	</cfif>
<!--- if customer not logged in --->
<cfelse>
	<!--- redirect to account main page if not logged in --->
	<cflocation url="#request.cwpage.loginurl#" addtoken="no">
</cfif>
<!--- if ok to this point, check file exists --->
<cfif request.cwpage.dlok>
	<cfset dlPath = CWgetDownloadPath(sku_id=url.sku)>
	<cfif not len(trim(dlPath))>
		<cfset request.cwpage.dlerror = 'File Unavailable'>
	<!--- if file exists --->
	<cfelse>
		<!--- set this message, only seen by user if something goes wrong --->
		<cfset request.cwpage.dlerror = 'Download Error: please contact customer service for assistance'>
	</cfif>
</cfif>
</cfsilent>
<!--- /////// START OUTPUT /////// --->
<!--- deliver file --->
<cfif request.cwpage.dlok>
	<!--- handle errors w/ custom message --->
	<cftry>
		<!--- store download data in customer record --->
		<cfset CWrecordCustomerDownload(
				url.sku,
				session.cwclient.cwCustomerID
				)>
	<!--- download details - server path and saved filename --->
	<cfset fileName = listLast(dlPath,'/')>
	<cfset fileDir = left(dlPath,len(dlPath)-len(fileName))>
	<!--- get friendly filename --->
	<cfset downloadName = cwQueryGetSkuFile(url.sku)>
	<cfif not len(trim(downloadName))>
		<cfset downloadName = filename>
	</cfif>
	
	<!--- get file size --->
	<cfset fileLookup = getFileInfo(dlPath)>
	<cfset fileSize = fileLookup.size>
	<!---set headers--->
	<cfheader name="Content-Length" value="#filesize#">
	<cfheader name="Content-Disposition" VALUE="attachment; filename=#fileLookup.name#">
	<!--- serve up file content --->
	<cfcontent type="application/unknown" file="#fileLookup.path#">
	<cfabort>
	
	<!--- on error, reload, show unavailable message --->
	<cfcatch>
		<cfset request.cwpage.dlerror = 'Download Error: please contact customer service for assistance'>
		<!--- add error details if available --->
		<cfif len(trim(cfcatch.detail))>
			<cfset request.cwpage.dlerror = request.cwpage.dlerror & '<br>(Detail: #cfcatch.detail#)'>
		</cfif>
	</cfcatch>
	</cftry>
</cfif>
<!--- /end if file ok --->
	<!--- show message --->
	<cfif len(trim(request.cwpage.dlerror))>
	<div class="CWcontent">
		<div class="CWalertBox<cfif not request.cwpage.dlok> alertText</cfif>">
			<cfoutput>#request.cwpage.dlerror#</cfoutput>
			<div class="confirmText">
				<br>Contact us for assistance&nbsp;&nbsp;&bull;&nbsp;&nbsp;<a href="<cfoutput>#request.cwpage.urlAccount#</cfoutput>">Return to Account</a>
			</div>
		</div>
	</div>
	</cfif>
	<div class="CWclear"></div>
</div>
<!-- / end #CWdetails -->
<!--- recently viewed products --->
<cfinclude template="cwapp/inc/cw-inc-recentview.cfm">
<!--- page end / debug --->
<cfinclude template="cwapp/inc/cw-inc-pageend.cfm">