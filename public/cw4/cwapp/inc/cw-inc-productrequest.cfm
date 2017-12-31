<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-productrequest.cfm
File Date: 2013-01-16
Description: validates and manages URL product and category details,
sets up product name and category string for page title,
with ids and text values in request.cwpage scope,
sets up product/category description for page meta description,
included into cart pages via Application.cfc 'onRequestStart'

NOTE:
Lookup functions are based on URL variables.
If enabled, category and secondary are added to the URL scope dynamically
based on a product ID (product=xx) in url
Category names are pulled from lists stored in application scope.
(Reset Cartweaver application variables if values are not as expected.)
==========================================================
--->
<!--- default page title (company name) --->
<cfset request.cwpage.title = application.cw.companyName>
<!--- default description (blank by default) --->
<cfset request.cwpage.description = ''>
<!--- defaults for stored data --->
<cfparam name="application.cw.listProducts" default="#structNew()#">
<cfparam name="application.cw.listCategories" default="#structNew()#">
<cfparam name="application.cw.listSubcategories" default="#structNew()#">
<!--- defaults for url values --->
<cfparam name="url.product" default="0">
<cfparam name="url.category" default="0">
<cfparam name="url.secondary" default="0">
<!--- if category and secondary are not defined in url, get via query for product page --->
<cfif isNumeric(url.product) and url.product gt 0 and application.cw.appDisplayProductCategories>
	<!--- get category if not provided --->
	<cfif not IsNumeric('url.category') or url.category is 0>
		<cfquery name="rsRelCategories" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#" maxrows="1">
		SELECT cc.category_id, cc.category_name
		FROM cw_product_categories_primary rr, cw_categories_primary cc
		WHERE rr.product2category_product_id = <cfqueryparam value="#url.product#" cfsqltype="cf_sql_integer">
		AND cc.category_id = rr.product2category_category_id
		ORDER BY cc.category_id
		</cfquery>
		<cfset url.category = rsRelCategories.category_id>
	</cfif>
	<!--- get secondary if not provided --->
	<cfif not IsNumeric('url.secondary') or url.secondary is 0>
		<cfquery name="rsRelScndCategories" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#" maxrows="1">
		SELECT sc.secondary_id, sc.secondary_name
		FROM cw_product_categories_secondary rr, cw_categories_secondary sc
		WHERE rr.product2secondary_product_id = <cfqueryparam value="#url.product#" cfsqltype="cf_sql_integer">
		AND sc.secondary_id = rr.product2secondary_secondary_id
		ORDER BY sc.secondary_id
		</cfquery>
		<cfset url.secondary = rsRelScndCategories.secondary_id>
	</cfif>
</cfif>
<!--- CATEGORY NAMES (for product listings and details pages) --->
	<!--- PRIMARY --->
	<!--- if a valid category is defined in url --->
	<cfif isDefined('url.category') and isNumeric(url.category) and url.category gt 0>
		<cfset request.cwpage.categoryID = url.category>
		<!--- get the value from saved list in application scope --->
		<cfif structKeyExists(application.cw.listCategories,url.category)>
			<cfset request.cwpage.categoryName = structFind(application.cw.listCategories,url.category)>
		<cfelse>
			<cfset request.cwpage.categoryName = ''>
		</cfif>
		<!--- add to title --->
		<cfif len(trim(request.cwpage.categoryName))>
			<cfset request.cwpage.title = request.cwpage.categoryName & ' | ' & request.cwpage.title>
		</cfif>
	<cfelse>
		<cfset request.cwpage.categoryName = ''>
		<cfset request.cwpage.categoryID = 0>
	</cfif>
	<!--- /end primary --->
	<!--- SECONDARY --->
	<!--- if a valid category is defined in url --->
	<cfif isDefined('url.secondary') and isNumeric(url.secondary) and url.secondary gt 0>
			<cfset request.cwpage.secondaryID = url.secondary>
		<!--- get the value from saved list in application scope --->
		<cfif structKeyExists(application.cw.listSubcategories,url.secondary)>
			<cfset request.cwpage.secondaryName = structFind(application.cw.listSubcategories,url.secondary)>
		<cfelse>
			<cfset request.cwpage.secondaryName = ''>
		</cfif>
		<!--- add to title --->
		<cfif len(trim(request.cwpage.secondaryName))>
			<cfset request.cwpage.title = request.cwpage.secondaryName & ' | ' & request.cwpage.title>
		</cfif>
	<cfelse>
		<cfset request.cwpage.secondaryName = ''>
		<cfset request.cwpage.secondaryID = 0>
	</cfif>
	<!--- /end secondary --->
	<!--- PRODUCT NAME/DESCRIPTION (details page only)--->
	<!--- if details page --->
	<cfif request.cw.thisPage is listLast(request.cwpage.urlDetails,'/')>
		<!--- if a valid product is defined in url --->
		<cfif isDefined('url.product') and isNumeric(url.product) and url.product gt 0>
			<cfset request.cwpage.productID = url.product>
			<!--- get the product name from saved list in application scope --->
			<cfif structKeyExists(application.cw.listProducts,url.product)>
				<cfset request.cwpage.productName = structFind(application.cw.listProducts,url.product)>
			<cfelse>
				<cfset request.cwpage.productName = 'Product Details'>
			</cfif>
			<!--- add to title --->
			<cfif len(trim(request.cwpage.productName))>
				<cfset request.cwpage.title = request.cwpage.productName & ' | ' & request.cwpage.title>
			</cfif>
			<!--- get description from products table --->
			<cfquery name="rsDescription" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#" maxrows="1">
			SELECT product_preview_description as descripText
			FROM cw_products
			WHERE product_id = <cfqueryparam value="#url.product#" cfsqltype="cf_sql_integer">
			</cfquery>
		<cfelse>
			<cfset request.cwpage.productName = ''>
			<cfset request.cwpage.productID = 0>
		</cfif>
		<!--- /end if valid product defined --->
	<!--- CATEGORY DESCRIPTIONS --->
	<cfelse>
		<!--- if not product details page, check for category/secondary descriptions --->
		<cfif request.cwpage.secondaryID gt 0>
			<cfquery name="rsDescription" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#" maxrows="1">
			SELECT secondary_description as descripText
			FROM cw_categories_secondary
			WHERE secondary_id = <cfqueryparam value="#request.cwpage.secondaryID#" cfsqltype="cf_sql_integer">
			</cfquery>
		<cfelseif request.cwpage.categoryID gt 0>
			<cfquery name="rsDescription" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#" maxrows="1">
			SELECT category_description as descripText
			FROM cw_categories_primary
			WHERE category_id = <cfqueryparam value="#request.cwpage.categoryID#" cfsqltype="cf_sql_integer">
			</cfquery>
		</cfif>
		<!--- /end category descriptions --->
	</cfif>
	<!--- /end if product details page --->
	<!--- DESCRIPTION TEXT --->
	<cfif isDefined('rsDescription.descripText') and len(trim(rsDescription.descripText))>
		<cfset request.cwpage.description = trim(ReReplaceNoCase(trim(rsDescription.descripText),"<[^>]*>","","all")
& ' ' & request.cwpage.description)>
	</cfif>
</cfsilent>