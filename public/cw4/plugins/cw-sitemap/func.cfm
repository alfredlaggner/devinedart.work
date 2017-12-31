<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: plugins/cw-sitemap/func.cfm
File Date: 03-14-2013
Package: CW4 XML Sitemap Generator Plugin
Description: Generates specially-formatted sitemap.xml for Google Sitemap service
==========================================================
Usage: see cw-sitemap/config.cfm

--->

<!--- START PROCESSING --->

<!--- // ---------- // SITEMAP FUNCTION: Generate XML Sitemap // ---------- // --->
<cffunction name="CWcreateSiteMap"
			access="public"
			output="false"
			hint="creates Google Sitemaps XML"
			>

	<cfargument name="page_list"
			required="false" 
			default="#variables.staticPages#"
			type="string"
			hint="comma delimited list of pages to add to the sitemap">

	<cfargument name="site_root"
			required="false" 
			default="#variables.siteRoot#"
			type="string"
			hint="root path for file">
			
	<cfargument name="site_url"
			required="false" 
			default="#variables.siteUrl#"
			type="string"
			hint="URL for site home directory">

	<cfargument name="details_url"
			required="false" 
			default=""
			type="string"
			hint="page name for details">

	<cfargument name="store_directory"
			required="false" 
			default=""
			type="string"
			hint="root path for file">
			
	<cfset var sitemapXML = ''>
	<cfset var productsQuery = ''>
	
			<!--- if no page list is defined in the application, use the manually defined setting above --->
			<cfparam name="application.cw.appPageList" default="">
			<cfif len(trim(application.cw.appPageList))>
				<cfset arguments.page_list = application.cw.appPageList>
			<!--- if not set elsewhere, set into application here for further usage --->
			<cfelse>
				<cfset application.cw.appPageList = arguments.page_list>
			</cfif>	
	
			<!--- if no url is defined in arguments, use the global setting --->
			<cfparam name="application.cw.appSiteUrlHttp" default="">	
			<!--- url in settings must be http or https --->
			<cfif not (isValid('url',arguments.site_url) and left(siteUrl,4) eq 'http')>
				<!--- set from global setting --->
				<cfif isValid('url',application.cw.appSiteUrlHttp) and left(application.cw.appSiteUrlHttp,5) eq 'http:'>
					<cfset arguments.site_url = trim(application.cw.appSiteUrlHttp)>
				<cfelse>
					<cfset arguments.site_url = 'http://' & cgi.server_name>
				</cfif> 
			</cfif> 
			<cfif len(trim(arguments.site_url)) and right(arguments.site_url,1) neq '/'>
				<cfset arguments.site_url = arguments.site_url & '/'>
			</cfif>
			
			<!--- if no root path is defined above, use the global setting --->
			<cfparam name="application.cw.siteRootPath" default="">	
			<cfif not (len(trim(arguments.site_root)) and directoryExists(arguments.site_root))>
				<!--- set from global setting --->
				<cfif len(trim(application.cw.siteRootPath))>
					<cfset arguments.site_root = application.cw.siteRootPath>
				<cfelse>
					<cfset arguments.site_root = replaceNoCase(expandPath('/'),'\','/','all')>
				</cfif>
			</cfif>
			<cfif len(trim(arguments.site_root)) and right(arguments.site_root,1) neq '/'>
				<cfset arguments.site_root = arguments.site_root & '/'>
			</cfif>
			
			<!--- get store folder from global settings --->
			<cfparam name="application.cw.appCWStoreRoot" default="">
			<cfif not len(trim(arguments.store_directory))>
				<cfset arguments.store_directory = application.cw.appCWStoreRoot>
			</cfif>	
			<cfif len(trim(arguments.store_directory)) and right(arguments.store_directory,1) neq '/'>
				<cfset arguments.store_directory = arguments.store_directory & '/'>
			</cfif>
			<cfif len(trim(arguments.store_directory)) and left(arguments.store_directory,1) eq '/'>
				<cfset arguments.store_directory = right(arguments.store_directory,len(arguments.store_directory)-1)>
			</cfif>
			
			<!--- get page names from global settings --->
			<cfparam name="application.cw.appPageDetailsurl" default="#arguments.site_url##arguments.store_directory#product.cfm">	
			<cfif not len(trim(arguments.details_url))>
				<cfset arguments.details_url = application.cw.appPageDetailsUrl>
			</cfif>

			<!--- get product data from memory --->
			<cfif isDefined('application.cw.productsQuery')>
				<cfset productsQuery = application.cw.productsQuery>
			<!--- if not stored in memory, get from database --->
			<cfelse>
				<cfquery name="productsQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
					SELECT product_id, product_date_modified
					FROM cw_products
					WHERE product_on_web = 1
					AND NOT product_archive = 1
				</cfquery>
			</cfif>			

<!--- use try/catch to prevent global errors from this added function --->
<cftry>
<!--- save xml content --->
<cfsavecontent variable="sitemapXML"><cfoutput>
<?xml version="1.0" ?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.google.com/schemas/sitemap/0.84 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd"><cfloop index="pp" list="#arguments.page_list#"><url><loc>#arguments.site_url##trim(pp)#</loc><lastmod>#dateFormat(now(), "yyyy-mm-dd")#T#timeFormat(now(),"hh:mm:ss")#+00:00</lastmod><changefreq>weekly</changefreq><priority>0.50</priority></url></cfloop><cfloop query="productsQuery"><url><loc>#arguments.details_url#?product=#productsQuery.product_id#</loc><lastmod>#dateFormat(productsQuery.product_date_modified, "yyyy-mm-dd")#T#timeFormat(productsQuery.product_date_modified,"hh:mm:ss")#+00:00</lastmod><changefreq>weekly</changefreq><priority>0.50</priority></url></cfloop></urlset>
</cfoutput></cfsavecontent>

	<!--- write file --->
	<cffile action="write" file="#arguments.site_root#/sitemap.xml" output="#trim(sitemapXML)#">

<cfcatch>
</cfcatch>
</cftry>			

</cffunction>

</cfsilent>