<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-mod-downloadlink.cfm
File Date: 2012-08-25
Description:
Displays links to download a file, with optional customer-related info
==========================================================
--->

<!--- sku id is required --->
<cfparam name="attributes.sku_id" default="0">
<!--- other display attributes are optional --->
<cfparam name="attributes.download_url" default="#application.cw.appPageDownload#">
<cfparam name="attributes.download_text" default="download">
<cfparam name="attributes.show_file_name" default="true">
<cfparam name="attributes.show_file_size" default="true">
<cfparam name="attributes.show_file_version" default="true">
<cfparam name="attributes.show_remaining" default="true">
<!--- customer specific data --->
<cfparam name="attributes.customer_id" default="0">
<cfparam name="attributes.show_last_version" default="true">
<cfparam name="attributes.show_last_date" default="true">

<!--- global functions --->
<cfinclude template="../inc/cw-inc-functions.cfm">
<!--- clean up form and url variables --->
<cfinclude template="../inc/cw-inc-sanitize.cfm">

<!--- create URL (if blank, file does not exist) --->
<cfset dlUrl = CWcreateDownloadURL(attributes.sku_id)>
<cfif len(trim(dlUrl))>
	<cfset dlOk = true>
<cfelse>
	<cfset dlOk = false>
</cfif>

<!--- if file exists, continue processing --->
<cfif dlOk>
	<cfif attributes.show_file_size>
		<!--- download details - server path and saved dlName --->
		<cfset dlPath = CWgetDownloadPath(sku_id=attributes.sku_id)>
		<cfset dlName = listLast(dlPath,'/')>
		<cfset dlDir = left(dlPath,len(dlPath)-len(dlName))>
		<cfdirectory name="fileLookup" action="list" filter="#dlName#" directory="#dlDir#">
		<cfset dlSize = round(fileLookup.size/1000)>
	</cfif>
	<!--- set up link text --->
	<cfset dlStr = trim(attributes.download_text)>
	<cfset dlFn = CWqueryGetSkuFile(attributes.sku_id)>
	<!--- get version --->
	<cfif attributes.show_file_version>
		<cfset dlVersion = CWgetDownloadVersion(attributes.sku_id)>
	</cfif>
	<!--- get customer download info --->
	<cfif attributes.show_last_version or attributes.show_last_date>
		<!--- function returns a struct with date and version --->
		<cfset dlData = CWgetCustomerDownloadData(attributes.sku_id,attributes.customer_id)>
	</cfif>
</cfif>
</cfsilent>

<!--- if file exists, show link --->
<cfif dlOk>
	<cfif len(trim(dlUrl))>
		<cfoutput>
			<!--- if showing filename --->
			<cfif attributes.show_file_name>
				#trim(attributes.download_text)# <a href="#dlUrl#">#dlFn#</a>
			<!--- standard link --->
			<cfelse>
				<a href="#dlUrl#">#trim(attributes.download_text)#<cfif attributes.show_file_size and dlSize gt 0> (#trim(numberFormat(dlSize,'_,___'))#kb)</cfif></a>
			</cfif>

			<cfif attributes.show_file_version and len(dlVersion)><br>Current Version: #dlVersion#</cfif>
			<!--- number remaining --->
			<cfif attributes.customer_id is not '0'
				  AND attributes.show_remaining>
				<cfset downloadCheck = CWcheckCustomerDownload(
								attributes.sku_id,
								attributes.customer_id
								)>
				<cfif isNumeric(downloadCheck) and downloadCheck gt 0>
					<br><span class="smallPrint">#downloadCheck# download<cfif downloadCheck gt 1>s</cfif> remaining</span>
				</cfif>
			</cfif>
			<!--- /end show remaining --->
			<!--- previous download data --->
			<cfif attributes.customer_id is not '0'
				  AND (attributes.show_last_version
				  		OR attributes.show_last_date)
					  >
					<br><span class="smallPrint">
			  		<!--- last download date --->
					<cfif isDate(dlData.date)>Last Download: #lsDateFormat(dldata.date)#</cfif>
					<!--- last download version --->
					<cfif len(trim(dlData.version))> Version: #trim(dldata.version)#</cfif>
					</span>
			</cfif>
			<!--- /end previous data --->
		</cfoutput>
	</cfif>
</cfif>


