<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: plugins/cw-sitemap/config.cfm
File Date: 03-14-2013
Package: CW4 XML Sitemap Generator Plugin
Description: Settings for Cartweaver XML Sitemap plugin
==========================================================
Usage: 
This plugin will automatically generate a sitemap.xml file
whenever a product is added, updated or deleted in your Cartweaver admin.

The default location for the sitemap file is your site root as defined in your Cartweaver admin, under Global Settings.
A specific server location can be entered below in the optional site_root plugin setting.
--->

<!--- /////////////// --->
<!--- PLUGIN SETTINGS --->
<!--- /////////////// --->

<!--- SITE PAGES: comma-delimited list of page names to add to xml sitemap Replace examples with your actual page file names. Include only the ones you want Google to index --->
<cfset pluginsettings.sitemap.pageList = 'index.cfm,aboutus.cfm,ourproducts.cfm,policies.cfm,service.cfm,wholesale.cfm,contact.cfm'>

<!--- SITE ROOT (OPTIONAL): full path to location for sitemap.xml, e.g. C:\websites\mysite.com\wwwroot --->
<!--- leave empty to use Cartweaver Global Settings for site root --->
<cfset pluginsettings.sitemap.siteRoot = ''>

<!--- SITE URL (OPTIONAL): url for your website's home directory, e.g. http://www.cartweaver.com --->
<!--- leave empty to use Cartweaver Global Settings for home directory --->
<cfset pluginsettings.sitemap.siteUrl = ''>

<!--- DETAILS URL (OPTIONAL): url for your website's product details page, e.g. http://www.cartweaver.com/store/product.cfm --->
<!--- leave empty to use Cartweaver Global Settings for product details page url --->
<cfset pluginsettings.sitemap.detailsUrl = ''>


<!--- /////////////// --->
<!--- /////////////// --->
<!--- /////////////// --->
<!--- /END USER SETTINGS --->
<!--- /////////////// --->
<!--- /////////////// --->
<!--- /////////////// --->



<!--- /////////////// --->
<!--- /////////////// --->
<!--- /////////////// --->
<!--- /DO NOT EDIT BELOW --->
<!--- /////////////// --->
<!--- /////////////// --->
<!--- /////////////// --->

<!--- START PROCESSING --->

<!--- if editing product on product-details.cfm --->
<cfif request.cw.thisPage is 'product-details.cfm'>
	<cfif isDefined('form.action') or isDefined('url.deleteproduct')>
		<cfinclude template="func.cfm">
		<!--- create sitemap --->
		<cfset temp = CWcreateSitemap(pluginsettings.sitemap.pageList,pluginsettings.sitemap.siteRoot,pluginsettings.sitemap.siteUrl,pluginsettings.sitemap.detailsUrl)>
	</cfif>
</cfif>

</cfsilent>