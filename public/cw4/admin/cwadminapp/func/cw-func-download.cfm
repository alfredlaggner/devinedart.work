<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-func-download.cfm
File Date: 2012-09-01
Description: Handles download-related functions for the Cartweaver download add-on
Dependencies: Requires cw-func-admin in calling page for string manipulation functions
==========================================================
--->

<!--- // ---------- // create file download path // ---------- // --->
<cffunction name="CWcreateDownloadPath"
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

	<!--- clean up slash syntax --->
	<cfset arguments.downloads_dir = cwLeadingChar(cwTrailingChar(replace(arguments.downloads_dir,'\','/','all')),'remove')>
	<cfset arguments.file_root = replace(arguments.file_root,'\','/','all')>
	<!--- download directory: if outside of site root (path starting with ../) --->
	<cfif left(arguments.downloads_dir,3) is "../" >
	<!--- recurse up one level from site root for each "../" in the path - limit 2 for security purposes --->
		<cfset loopCt = 0>
		<cfloop list="#arguments.downloads_dir#" index="i" delimiters="/">
			<cfif i is '..' and (len(arguments.file_root) - len(listLast(arguments.file_root,"/")) gt 1)>
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
			<cfset returnPath = application.cw.siteRootPath & listLast(cwTrailingChar(arguments.downloads_dir,'remove'),'/')>
		</cfif>
	<!--- if a standard directory name, append to file root --->
	<cfelse>
		<cfset returnPath = application.cw.siteRootPath & arguments.downloads_dir>
	</cfif>
	<!--- clean up parent path, remove any funky path traversing stuff --->
	<cfset returnPath = replace(returnPath,'\','/','all')>
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

		<cfset filepath = cwCreateDownloadPath(
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

<!--- // ---------- // attach file values to SKU record // ---------- // --->
<cffunction name="CWqueryUpdateSkuFile"
			access="public"
			output="false"
			returntype="string"
			hint="adds/updates sku record with relevant file download info"
			>

<cfargument name="sku_id"
		required="true"
		default=""
		type="numeric"
		hint="ID of the SKU to update">

<cfargument name="file_name"
		required="false"
		default=""
		type="string"
		hint="Filename to add - leave blank to delete">

<cfargument name="file_version"
		required="false"
		default="0.00"
		type="string"
		hint="optional version info">

<cfargument name="download_id"
		required="false"
		default="#arguments.file_name#"
		type="string"
		hint="if filenames are being masked, this is the actual filename on the server">

<cfargument name="download_limit"
		required="false"
		default="0"
		type="numeric"
		hint="the number of times the file can be downloaded by the same customer">

<cfset var skuFileQuery = ''>
<cfset var updatedID = '0'>

<!--- id cannot be blank --->
<cfif not len(trim(arguments.download_id))>
	<cfset arguments.download_id = trim(arguments.file_name)>
</cfif>

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			UPDATE cw_skus
				SET
				sku_download_file = <cfqueryparam value="#arguments.file_name#" cfsqltype="cf_sql_varchar">
				<cfif arguments.file_version neq '0.00'>
					,sku_download_version = <cfqueryparam value="#arguments.file_version#" cfsqltype="cf_sql_varchar">
				</cfif>
					,sku_download_id = <cfqueryparam value="#arguments.download_id#" cfsqltype="cf_sql_varchar">
					,sku_download_limit = <cfqueryparam value="#arguments.download_limit#" cfsqltype="cf_sql_integer">
				WHERE sku_id = #arguments.sku_id#
			</cfquery>
			<cfset updatedID = arguments.sku_id>

<cfreturn updatedID>

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

<!--- // ---------- // get all sku filenames // ---------- // --->
<cffunction name="CWquerySelectSkuFiles"
			access="public"
			output="false"
			returntype="any"
			hint="get filenames and IDs associated with all product skus"
			>

	<cfset var rsProductFiles = "">

	<cfquery name="rsProductFiles" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT ss.sku_download_file, ss.sku_download_id,
		ss.sku_id, ss.sku_merchant_sku_id,
		pp.product_name,pp.product_id
		FROM cw_skus ss, cw_products pp
		WHERE ss.sku_product_id = pp.product_id
		AND NOT ss.sku_download_file = ''
		AND NOT ss.sku_download_file IS NULL
	</cfquery>

<cfreturn rsProductFiles>


</cffunction>

<!--- // ---------- // remove filename from skus // ---------- // --->
<cffunction name="CWqueryDeleteSkuFile"
			access="public"
			output="false"
			returntype="void"
			hint="delete file entry from any skus matching the provided filename"
			>

	<cfargument name="download_key"
			required="true"
			default=""
			type="string"
			hint="the sku_download_key filename to delete">

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			UPDATE cw_skus
			SET sku_download_file = '',
			sku_download_id = '',
			sku_download_version = ''
			WHERE sku_download_id = '#trim(arguments.download_key)#'
			</cfquery>

</cffunction>

</cfsilent>