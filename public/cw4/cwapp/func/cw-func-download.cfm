<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2010, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-func-downloads.cfm
File Date: 2012-09-01
Description: Handles download-related functions for the Cartweaver download add-on
Dependencies: Requires cw-func-admin in calling page for string manipulation functions
==========================================================
--->

<!--- // ---------- // check file download permission for user // ---------- // --->
<cffunction name="CWcheckCustomerDownload"
			access="public"
			output="false"
			returntype="string"
			hint="verify customer download permission - return number of downloads remaining, or 0-message if denied"
			>

	<cfargument name="sku_id"
			required="true"
			default="0"
			type="numeric"
			hint="the id of the sku to look up">

	<cfargument name="customer_id"
			required="true"
			default="0"
			type="string"
			hint="the id of the customer to look up">

	<cfargument name="order_id"
			required="false"
			default="0"
			type="string"
			hint="the id of the order to match">

	<cfargument name="status_codes"
			required="false"
			default="#application.cw.appDownloadStatusCodes#"
			type="string"
			hint="list of order status codes allowed for file download">

	<cfset var returnStr = ''>
	<cfset var orderQuery = ''>
	<cfset var orderOk = false>
	<cfset var dlQuery = ''>
	<cfset var skuQuery = ''>

	<!--- verify customer has purchased this item --->
	<cfquery name="orderQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT oo.order_id, oo.order_status
	FROM cw_order_skus os, cw_orders oo
	WHERE os.ordersku_sku = #arguments.sku_id#
	AND os.ordersku_order_id = oo.order_id
	AND oo.order_customer_id = '#arguments.customer_id#'
	<cfif arguments.order_id is not '0'>
		AND oo.order_id = '#arguments.order_id#'
	</cfif>
	</cfquery>

	<!--- check order status (paid or shipped allows download) - use listFind in case multiple purchases are found --->
	<cfif listLen(arguments.status_codes)>
		<cfloop list="#arguments.status_codes#" index="i">
			<cfif listFind(valueList(orderQuery.order_status),i)>
				<cfset orderOk = true><cfbreak>
			</cfif>
		</cfloop>
	</cfif>

	<!--- if the order status is ok --->
	<cfif orderOk>
		<!--- check number of downloads for this customer --->
		<cfquery name="dlQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT dl_id
		FROM cw_downloads
		WHERE dl_sku_id = #arguments.sku_id#
		AND dl_customer_id = '#arguments.customer_id#'
		</cfquery>

		<!--- check download total for this sku --->
		<cfquery name="skuQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT sku_download_limit
		FROM cw_skus
		WHERE sku_id = #arguments.sku_id#
		</cfquery>

		<!--- set value for maximum downloads allowed --->
		<cfif not isNumeric(skuQuery.sku_download_limit)>
			<cfset maxDownloads = 0>
		<cfelse>
			<cfset maxDownloads = skuQuery.sku_download_limit>
		</cfif>

		<!--- if 0, no limit is imposed, return simple '0' response --->
		<cfif maxDownloads eq 0>
			<cfset returnStr = 0>
		<!--- if limit has been reached, return message --->
		<cfelseif dlQuery.recordCount gte maxDownloads>
			<cfset returnStr = '0-The maximum number of downloads for this file has been reached'>
		<!--- if tracking downloads, return number remaining  --->
		<cfelse>
			<cfset returnStr = maxDownloads - dlQuery.recordCount>
		</cfif>

	<!--- any other status returns a message --->
	<cfelseif orderQuery.recordCount is 1>
		<cfset returnStr = '0-Item not available'>

	<!--- if no order is found --->
	<cfelseif orderQuery.recordCount is 0>
		<cfset returnStr = '0-Unavailable - missing purchase confirmation'>
	</cfif>

	<cfreturn returnStr>

</cffunction>

<!--- // ---------- // get customer downloadable items // ---------- // --->
<cffunction name="CWselectCustomerDownloads"
			access="public"
			output="false"
			returntype="query"
			hint="returns a query of sku data with download details"
			>

	<cfargument name="customer_id"
			required="true"
			default="0"
			type="string"
			hint="the id of the customer to look up">

	<cfset var dlQuery = ''>

		<cfquery name="dlQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT DISTINCT p.product_id,
		p.product_name,
		p.product_preview_description,
		p.product_date_modified,
		p.product_on_web,
		p.product_archive,
		s.sku_on_web,
		s.sku_id,
		s.sku_download_id,
		s.sku_download_version,
		o.order_date,
		o.order_id,
		os.ordersku_unique_id,
		os.ordersku_unit_price,
		os.ordersku_quantity
		FROM cw_products p, 
		cw_order_skus os, 
		cw_skus s,
		cw_orders o
		WHERE os.ordersku_sku = s.sku_id
		AND s.sku_product_id = p.product_id
		AND NOT s.sku_download_id IS NULL
		AND NOT s.sku_download_id = ''
		AND NOT s.sku_download_file IS NULL
		AND NOT s.sku_download_file = ''
		AND NOT p.product_archive = 1
		AND NOT s.sku_on_web = 0
		AND o.order_customer_id = <cfqueryparam value="#arguments.customer_id#" cfsqltype="cf_sql_varchar">
		AND o.order_id = os.ordersku_order_id
		ORDER BY p.product_name, p.product_id, o.order_date DESC
		</cfquery>

	<cfreturn dlQuery>

</cffunction>

<!--- // ---------- // record customer download // ---------- // --->
<cffunction name="CWrecordCustomerDownload"
			access="public"
			output="false"
			returntype="void"
			hint="enters customer download record with timestamp to downloads table"
			>

	<cfargument name="sku_id"
			required="true"
			default="0"
			type="numeric"
			hint="the id of the sku to look up">

	<cfargument name="customer_id"
			required="true"
			default="0"
			type="string"
			hint="the id of the customer to look up">

	<cfargument name="file_name"
			required="false"
			default=""
			type="string"
			hint="name of file to record - default = blank (look up from sku table)">

	<cfargument name="file_version"
			required="false"
			default=""
			type="string"
			hint="version of file to record - default = blank (look up from sku table)">

	<cfset var skuQuery = ''>
	<cfset var customer_address = ''>

	<cfquery name="skuQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT sku_download_version, sku_download_file
		FROM cw_skus
		WHERE sku_id = #arguments.sku_id#
		AND NOT sku_download_id = ''
		AND NOT sku_download_id IS NULL
	</cfquery>

	<cfif len(trim(skuQuery.sku_download_file))>
		<cfset arguments.file_name = trim(skuQuery.sku_download_file)>
	</cfif>
	<cfif len(trim(skuQuery.sku_download_version))>
		<cfset arguments.file_version = trim(skuQuery.sku_download_version)>
	</cfif>
	
	<!--- get remote IP for downloading user --->
	<cftry>
		<cfset customer_address = cgi.remote_addr>
		<cfcatch>
			<cfset customer_address = ''>
		</cfcatch>
	</cftry>

	<!--- insert customer download record --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_downloads (
		dl_sku_id,
		dl_customer_id,
		dl_timestamp,
		dl_file,
		dl_version,
		dl_remote_addr
	) VALUES (
		#arguments.sku_id#,
		'#arguments.customer_id#',
		#createODBCdateTime(now())#,
		'#arguments.file_name#',
		'#arguments.file_version#',
		'#customer_address#'
	)
	</cfquery>

</cffunction>

<!--- // ---------- // get current file download version // ---------- // --->
<cffunction name="CWgetDownloadVersion"
			access="public"
			output="false"
			returntype="string"
			hint="returns the current version of a sku download file"
			>

	<cfargument name="sku_id"
			required="true"
			type="numeric"
			hint="the sku to look up">

	<cfset var skuVersQuery = ''>
	<cfset var returnStr = ''>

	<cfquery name="skuVersQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT sku_download_version as vers
		FROM cw_skus
		WHERE sku_id = #arguments.sku_id#
		AND NOT sku_download_id = ''
		AND NOT sku_download_id IS NULL
	</cfquery>

	<cfif len(trim(skuVersQuery.vers))>
		<cfset returnStr = trim(skuVersQuery.vers)>
	</cfif>

	<cfreturn returnStr>

</cffunction>

<!--- // ---------- // get customer previous download version date // ---------- // --->
<cffunction name="CWgetCustomerDownloadData"
			access="public"
			output="false"
			returntype="struct"
			hint="returns a structure with date and version"
			>

	<cfargument name="sku_id"
			required="true"
			type="numeric"
			hint="the sku to look up">

	<cfargument name="customer_id"
			required="true"
			type="string"
			hint="the customer to look up">

	<cfset var skuDataQuery = ''>
	<cfset var skuData = structNew()>
	<cfset var returnStruct = structNew()>
		<cfset skuData.date = ''>
		<cfset skuData.version = ''>

	<cfquery name="skuDataQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT dl_timestamp, dl_version
		FROM cw_downloads
		WHERE dl_sku_id = #arguments.sku_id#
		AND dl_customer_id = '#arguments.customer_id#'
	</cfquery>

	<cfif len(trim(skuDataQuery.dl_version))>
		<cfset skuData.version = trim(skuDataQuery.dl_version)>
	</cfif>
	<cfif len(trim(skuDataQuery.dl_timestamp))>
		<cfset skuData.date = trim(skuDataQuery.dl_timestamp)>
	</cfif>

	<cfset returnStruct = skuData>

	<cfreturn returnStruct>

</cffunction>

<!--- // ---------- // get file download path // ---------- // --->
<cffunction name="CWgetDownloadPath"
			access="public"
			output="false"
			returntype="string"
			hint="returns the path for file storage"
			>

	<cfargument name="downloads_dir"
			required="false"
			default="#application.cw.appDownloadsDir#"
			type="string"
			hint="the directory for downloadable file storage">

	<cfargument name="file_root"
			required="false"
			default="#application.cw.siteRootPath#"
			type="string"
			hint="the site root to use as base for relative paths">

	<cfargument name="sku_id"
			required="false"
			default="0"
			type="numeric"
			hint="the sku the file is attached to - if included, the returned path will include the file location">

	<cfargument name="ext_dirs"
			required="false"
			default="#application.cw.appDownloadsFileExtDirs#"
			type="string"
			hint="Use directory for separate file extensions y/n">

<cfset var returnPath = ''>

	<cfset arguments.downloads_dir = cwLeadingChar(cwTrailingChar(replace(arguments.downloads_dir,'\','/','all')),'remove')>
	<!--- Download directory: if outside of site root (path starting with ../) --->
	<cfif left(arguments.downloads_dir,3) is "../" >
	<!--- recurse up one level from site root for each "../" in the path - limit 2 for security purposes --->
		<cfset loopCt = 0>
		<cfloop list="#arguments.downloads_dir#" index="i" delimiters="/">
			<cfif i is '..'>
			<cfset loopct = loopct + 1>
				<cfset arguments.file_root = left(arguments.file_root,len(arguments.file_root) - len(ListLast(arguments.file_root,"/")) - 1)>
			</cfif>
			<!--- can only go up two levels to avoid putting stuff in other people's domains --->
			<cfif loopct gte 2><cfbreak></cfif>
		</cfloop>
		<cfset returnPath = cwTrailingChar(arguments.file_root,'add','/') & cwTrailingChar(replace(arguments.downloads_dir,'../','','all'),'remove')>
		<!--- if using the recursive path, directory must already exist --->
		<cfif not directoryExists(returnPath)>
			<!--- set to site root w/ last folder name given in path  --->
			<cfset returnPath = application.cw.siteRootPath & cwLeadingChar(listLast(cwTrailingChar(arguments.downloads_dir,'remove'),'/'),'remove')>
		</cfif>
	<!--- if a standard directory name, append to file root --->
	<cfelse>
		<cfset returnPath = application.cw.siteRootPath & cwLeadingChar(arguments.downloads_dir,'remove')>
	</cfif>
	<!--- clean up parent path, remove any funky path traversing stuff --->
	<cfset returnPath = replace(returnPath,'../','','all')>
	<cfset returnPath = replace(returnPath,'./','','all')>
	<!--- upload path can be manually set here, must be a full path, and existing directory --->
	<cfif isDefined('application.cw.appDownloadsPath') and len(trim(application.cw.appDownloadsPath)) and directoryExists(application.cw.appDownloadsPath)>
		<cfset returnPath = application.cw.appDownloadsPath>
	</cfif>
		<!--- make sure path has trailing slash --->
	<cfset returnPath = cwTrailingChar(returnPath)>
	<!--- if a sku id is provided --->
	<cfif arguments.sku_id gt 0>
		<!--- get the sku file info --->
		<cfquery name="skuFileQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT sku_download_file, sku_download_id
		FROM cw_skus
		WHERE sku_id = #arguments.sku_id#
		AND NOT sku_download_id = ''
		AND NOT sku_download_id IS NULL
		</cfquery>
		<!--- if a sku file is found --->
		<cfif skuFileQuery.recordCount is 1>
			<!--- add file directory if using extension dirs --->
			<cfif arguments.ext_dirs>
				<cfset fileExtDir = trim(listlast(skuFileQuery.sku_download_id,'.')) & '/'>
			<cfelse>
				<cfset fileExtDir = ''>
			</cfif>
			<!--- add file id to path --->
			<cfset returnPath = returnPath & fileExtDir & trim(skuFileQuery.sku_download_id)>
		</cfif>
	</cfif>

	<cfreturn returnPath>
</cffunction>

<!--- // ---------- // create url for download // ---------- // --->
<cffunction name="CWcreateDownloadURL"
			access="public"
			output="false"
			returntype="any"
			hint="returns url for download link based on SKU id and download page settings. returns blank if file does not exist"
			>

	<cfargument name="sku_id"
			required="true"
			type="numeric"
			hint="The sku the file is attached to">

	<cfargument name="downloads_page"
			required="false"
			default="#application.cw.appPageDownload#"
			type="string"
			hint="The page to use as the download target">

	<cfargument name="downloads_dir"
			required="false"
			default="#application.cw.appDownloadsDir#"
			type="string"
			hint="The directory containing the download file">

	<cfargument name="ext_dirs"
			required="false"
			default="#application.cw.appDownloadsFileExtDirs#"
			type="string"
			hint="Use directory for separate file extensions y/n">

	<cfset var returnStr = ''>
	<cfset var parentPath = ''>
	<cfset var fileExtDir = ''>
	<cfset var filePath = ''>
	<cfset var skuFileQuery = ''>

		<cfset filepath = cwGetDownloadPath(
								sku_id=arguments.sku_id,
								downloads_dir=arguments.downloads_dir,
								ext_dirs=arguments.ext_dirs
								)>
		<!--- verify file exists --->
		<cfif fileExists(filePath)>
			<!--- if file exists, return link --->
			<cfset returnStr = '#arguments.downloads_page#?sku=#arguments.sku_id#'>
		</cfif>

	<cfreturn returnStr>

</cffunction>

<!--- // ---------- // get SKU filename by sku id // ---------- // --->
<cffunction name="CWqueryGetSkuFile"
			access="public"
			output="false"
			returntype="string"
			hint="gets the download filename (friendly name) for any download file"
			>

	<cfargument name="sku_id"
			required="true"
			default="0"
			type="numeric"
			hint="ID of the SKU to update">

	<cfset var returnStr = ''>
	<cfset var skuFileQuery = ''>

	<cfif arguments.sku_id gt 0>
		<!--- get the sku file info --->
		<cfquery name="skuFileQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT sku_download_file
		FROM cw_skus
		WHERE sku_id = #arguments.sku_id#
		AND NOT sku_download_file = ''
		AND NOT sku_download_file IS NULL
		</cfquery>
		<cfif skuFileQuery.recordCount>
			<cfset returnStr = trim(skuFileQuery.sku_download_file)>
		</cfif>
	</cfif>

<cfreturn returnStr>

</cffunction>

</cfsilent>