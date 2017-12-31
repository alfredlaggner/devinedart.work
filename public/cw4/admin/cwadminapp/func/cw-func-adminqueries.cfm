<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-func-adminqueries.cfm
File Date: 2013-02-10
Description:
Include database queries as functions with variable arguments
See each function for argument types, values and ordering
==========================================================
--->

<!--- /////////////// --->
<!--- PRODUCT QUERIES --->
<!--- /////////////// --->

<!--- // ---------- Product Search ---------- // --->
<cffunction name="CWquerySearchProducts" access="public" output="false"returntype="query"
			hint="Get products based on optional search string,category and subcategory">

	<cfargument name="search_string" default="%" type="String" required="False"
				hint="A string to search for">

	<cfargument name="search_by" default="" type="String" required="False"
				hint="The field or column to search within (default blank=all)">

	<cfargument name="search_cat" default="0" type="Numeric" required="False"
				hint="A category ID to search within">

	<cfargument name="search_scndcat" default="0" type="Numeric" required="False"
				hint="A secondary category ID to search within">

	<cfargument name="search_sortby" default="product_name" type="String" required="False"
				hint="The query column to sort by">

	<cfargument name="search_sortdir" default="asc" type="String" required="False"
				hint="The direction (asc|desc) to sort">

	<cfargument name="search_archived" default="false" type="Boolean" required="False"
				hint="Search in archived products (true = archived, false = active)">

	<cfargument name="show_ct" default="0" type="numeric" required="False"
				hint="The maximum number of records to return (0=all)">

<cfset var rsSearchProducts = "">
<cfset var searchFor = lcase(arguments.search_string)>
<cfquery name="rsSearchProducts" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT
	cw_products.product_id,
	cw_products.product_name,
	cw_products.product_on_web,
	cw_products.product_merchant_product_id,
	cw_products.product_date_modified
FROM cw_products
<!--- if using categories --->
<cfif arguments.search_cat gt 0>
, cw_product_categories_primary cc
</cfif>
<cfif arguments.search_scndcat gt 0>
<!--- if using secondary categories --->
, cw_product_categories_secondary sc
</cfif>
WHERE 1 = 1
<!--- archived vs active --->
AND <cfif NOT search_archived>NOT</cfif> cw_products.product_archive = 1
	<!--- add search_by options, make case insensitive --->
  <cfif arguments.search_by	EQ "prodID">
    AND #application.cw.sqlLower#(cw_products.product_merchant_product_id) LIKE '%#searchFor#%'
    <cfelseif arguments.search_by eq "description">
    AND (#application.cw.sqlLower#(cw_products.product_description) LIKE '%#searchFor#%'
		OR #application.cw.sqlLower#(cw_products.product_preview_description) LIKE '%#searchFor#%')
    <cfelseif arguments.search_by eq "prodName">
	AND #application.cw.sqlLower#(cw_products.product_name) LIKE '%#searchFor#%'
	<!--- any field --->
	<cfelse>
	AND (
	#application.cw.sqlLower#(cw_products.product_name) LIKE '%#searchFor#%'
	OR
	#application.cw.sqlLower#(cw_products.product_description) LIKE '%#searchFor#%'
	OR
	#application.cw.sqlLower#(cw_products.product_preview_description) LIKE '%#searchFor#%'
	OR
	#application.cw.sqlLower#(cw_products.product_name) LIKE '%#searchFor#%'
	OR
	#application.cw.sqlLower#(cw_products.product_merchant_product_id) LIKE '%#searchFor#%'
	<cfif application.cw.adminProductKeywordsEnabled>
		OR
		#application.cw.sqlLower#(cw_products.product_keywords) LIKE '%#searchFor#%'
	</cfif>
	)
  </cfif>
<cfif search_cat gt 0>
AND cc.product2category_category_id = #arguments.search_cat#
AND cc.product2category_product_id = cw_products.product_id
</cfif>
<cfif search_scndcat gt 0>
AND sc.product2secondary_secondary_id = #arguments.search_scndcat#
AND sc.product2secondary_product_id = cw_products.product_id
</cfif>
<!--- add sorting --->
ORDER BY #search_sortby# #search_sortdir#
</cfquery>

<cfif arguments.show_ct gt 0>
<cfquery name="rsSearchProducts" dbtype="query" maxrows="#arguments.show_ct#">
SELECT *
FROM rsSearchProducts
</cfquery>
</cfif>

<cfreturn rsSearchProducts>

</cffunction>

<!--- // ---------- Get Product Details ---------- // --->
<cffunction name="CWquerySelectProductDetails" access="public" output="false" returntype="query"
			hint="Returns all columns from the products table">

	<cfargument required="true" name="product_id" type="numeric"
				hint="The ID of the product to look up">

<cfset var rsProductDetails = "">
<cfquery name="rsProductDetails" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT * FROM cw_products
WHERE product_id = #arguments.product_id#
</cfquery>
<cfreturn rsProductDetails>
</cffunction>

<!--- // ---------- Update a Product ---------- // --->
<cffunction name="CWqueryUpdateProduct" access="public" returntype="void"  output="false"
			hint="Update product details in cw_products">

	<!--- id and name are required . --->
	<cfargument name="product_id" required="true" type="Numeric"
				hint="The ID of the product to update">
	<cfargument name="product_name" required="true" type="String"
				hint="product name">
	<!--- optional values --->
	<cfargument name="product_on_web" required="false" default="0" type="Boolean"
				hint="product on web">
	<cfargument name="product_ship_charge" required="false" default="0" type="Boolean"
				hint="charge shipping">
	<cfargument name="product_tax_group_id" required="false" default="0" type="Numeric"
				hint="id of product tax group">
	<cfargument name="product_sort" required="false" default="0" type="Numeric"
				hint="product sort">
	<cfargument name="product_out_of_stock_message" required="false" default="" type="String"
				hint="product out of stock message">
	<cfargument name="product_custom_info_label" required="false" default="" type="String"
				hint="label for custom info field">
	<cfargument name="product_description" required="false" default="" type="String"
				hint="product description">
	<cfargument name="product_preview_description" required="false" default="" type="String"
				hint="product short description">
	<cfargument name="product_special_description" required="false" default="" type="String"
				hint="product specs or additional info">
	<cfargument name="product_keywords" required="false" default="" type="String"
				hint="product keywords">


<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	UPDATE cw_products
	SET
	product_name = '#arguments.product_name#',
	product_on_web = #arguments.product_on_web#,
	product_ship_charge = #arguments.product_ship_charge#,
	product_tax_group_id = #arguments.product_tax_group_id#,
	product_sort = #arguments.product_sort#,
	product_out_of_stock_message = '#arguments.product_out_of_stock_message#',
	product_custom_info_label = '#arguments.product_custom_info_label#',
	product_description = '#arguments.product_description#',
	product_preview_description = '#arguments.product_preview_description#',
	product_special_description = '#arguments.product_special_description#',
	product_keywords = '#arguments.product_keywords#',
	product_date_modified = #createODBCdateTime(CWtime())#
	WHERE
	product_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.product_id#">
  </cfquery>
</cffunction>

<!--- // ---------- Insert a Product ---------- // --->
<cffunction name="CWqueryInsertProduct" access="public" returntype="numeric"  output="false"
			hint="Insert new product into cw_products - returns ID of newly inserted product">

	<!--- merchant id and name are required . --->
	<cfargument name="product_merchant_product_id" required="true" type="String"
				hint="Merchant Product ID or Part Number for the new product">
	<cfargument name="product_name" required="true" type="String"
				hint="product name">
	<!--- optional values --->
	<cfargument name="product_on_web" required="false" default="0" type="Boolean"
				hint="product on web">
	<cfargument name="product_ship_charge" required="false" default="0" type="Boolean"
				hint="charge shipping">
	<cfargument name="product_tax_group_id" required="false" default="0" type="Numeric"
				hint="id of product tax group">
	<cfargument name="product_sort" required="false" default="0" type="Numeric"
				hint="product sort">
	<cfargument name="product_out_of_stock_message" required="false" default="" type="String"
				hint="product out of stock message">
	<cfargument name="product_custom_info_label" required="false" default="" type="String"
				hint="label for custom info field">
	<cfargument name="product_description" required="false" default="" type="String"
				hint="product description">
	<cfargument name="product_preview_description" required="false" default="" type="String"
				hint="product short description">
	<cfargument name="product_special_description" required="false" default="" type="String"
				hint="product specs or additional info">
	<cfargument name="product_keywords" required="false" default="" type="String"
				hint="product keywords">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO
		cw_products
			(product_merchant_product_id,
			product_name,
			product_on_web,
			product_ship_charge,
			product_tax_group_id,
			product_sort,
			product_out_of_stock_message,
			product_custom_info_label,
			product_description,
			product_preview_description,
			product_special_description,
			product_keywords,
			product_archive,
			product_date_modified
			)
	VALUES (
			'#arguments.product_merchant_product_id#',
			'#arguments.product_name#',
			#arguments.product_on_web#,
			#arguments.product_ship_charge#,
			#arguments.product_tax_group_id#,
			#arguments.product_sort#,
			'#arguments.product_out_of_stock_message#',
			'#arguments.product_custom_info_label#',
			'#arguments.product_description#',
			'#arguments.product_preview_description#',
			'#arguments.product_special_description#',
			'#arguments.product_keywords#',
			0,
			#createODBCDateTime(CWtime())#
			)
	</cfquery>

	<!--- Get the ID of the new product for further inserts --->
	<cfquery name="rsGetNewProdID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT product_id AS newproduct_id FROM cw_products WHERE product_merchant_product_id = '#arguments.product_merchant_product_id#'
	</cfquery>
	
	<!--- return the numeric new id --->
	<cfreturn rsGetNewProdID.newproduct_id>
</cffunction>

<!--- // ---------- Delete a Product ---------- // --->
<cffunction name="CWqueryDeleteProduct" access="public" returntype="void" output="false"
			hint="Deletes a product from cw_products">

	<cfargument name="product_id" required="true" type="Numeric"
				hint="The ID of the product to delete">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_products
	WHERE product_id = #arguments.product_id#
</cfquery>

</cffunction>

<!--- // ---------- Check for Existing Merchant ID ---------- // --->
<cffunction name="CWquerySelectMerchantID" access="public" output="false" returntype="query"
			hint="Select all products with a specified Merchant ID (part number)">

	<cfargument name="merchant_id" required="true" type="string"
				hint="The Merchant ID of the product to look up">

<cfset var rsSelectMerchantID = "">
<cfquery name="rsSelectMerchantID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT product_merchant_product_id FROM cw_products WHERE product_merchant_product_id = '#arguments.merchant_id#'
</cfquery>
<cfreturn rsSelectMerchantID>
</cffunction>

<!--- // ---------- Get Product Related Categories ---------- // --->
<cffunction name="CWquerySelectRelCategories" access="public" output="false" returntype="query"
			hint="Returns all selected categories for a given product">

	<cfargument name="product_id" required="true" type="numeric"
				hint="ID of product to look up">

<cfset var rsRelCategories = "">
<cfquery name="rsRelCategories" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT rr.product2category_category_id, cc.category_name
FROM
cw_product_categories_primary rr,
cw_categories_primary cc
WHERE rr.product2category_product_id = #arguments.product_id#
AND cc.category_id = rr.product2category_category_id
</cfquery>
<cfreturn rsRelCategories>
</cffunction>

<!--- // ---------- Get Product Related Secondary Categories ---------- // --->
<cffunction name="CWquerySelectRelScndCategories" access="public" output="false" returntype="query"
			hint="Returns all selected secondary categories for a given product">

	<cfargument name="product_id" required="true" type="numeric"
				hint="ID of product to look up">

<cfset var rsRelScndCategories = "">
<cfquery name="rsRelScndCategories" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT rr.product2secondary_secondary_id, sc.secondary_name
FROM
cw_product_categories_secondary rr,
cw_categories_secondary sc
WHERE rr.product2secondary_product_id = #arguments.product_id#
AND sc.secondary_id = rr.product2secondary_secondary_id
</cfquery>
<cfreturn rsRelScndCategories>
</cffunction>

<!--- // ---------- Delete Product Category Record(s) ---------- // --->
<cffunction name="CWqueryDeleteProductCat" access="public" output="false" returntype="void"
			hint="Deletes a relative category/product record">

	<cfargument name="product_id" required="true" type="numeric"
				hint="the Product ID to look up">
	<cfargument name="category_id" required="false" default="0" type="numeric"
				hint="optional category ID - if omitted, all related cats for this product are deleted">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_product_categories_primary
	WHERE product2category_product_id = #arguments.product_id#
	<cfif arguments.category_id gt 0>
	AND product2category_category_id = #arguments.category_id#
	</cfif>
</cfquery>
</cffunction>

<!--- // ---------- Insert Related Category Record ---------- // --->
<cffunction name="CWqueryInsertProductCat" access="public" output="false" returntype="void"
			hint="Creates a new relative category/product record">

	<cfargument name="product_id" required="true" type="numeric"
				hint="the Product ID to insert">
	<cfargument name="category_id" required="true" type="numeric"
				hint="category ID to insert">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_product_categories_primary
	(product2category_product_id, product2category_category_id )
	VALUES (#arguments.product_id#, #arguments.category_id#)
</cfquery>
</cffunction>

<!--- // ---------- Delete Product Secondary Category Record(s) ---------- // --->
<cffunction name="CWqueryDeleteProductScndCat" access="public" output="false" returntype="void"
			hint="Deletes a relative secondary category/product record">

	<cfargument name="product_id" required="true" type="numeric"
				hint="the Product ID to look up">
	<cfargument name="scndcat_id" required="false" default="0" type="numeric"
				hint="optional secondary category ID - if omitted, all related secondary cats for this product are deleted">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_product_categories_secondary
	WHERE product2secondary_product_id = #arguments.product_id#
	<cfif arguments.scndcat_id gt 0>
	AND product2secondary_secondary_id = #arguments.scndcat_id#
	</cfif>
	</cfquery>
</cffunction>

<!--- // ---------- Insert Related Secondary Category Record ---------- // --->
<cffunction name="CWqueryInsertProductScndCat" access="public" output="false" returntype="void"
			hint="Creates a new relative secondary category/product record">

	<cfargument name="product_id" required="true" type="numeric"
				hint="the Product ID to insert">
	<cfargument name="scndcat_id" required="true" type="numeric"
				hint="secondary category ID to insert">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_product_categories_secondary
	(product2secondary_product_id, product2secondary_secondary_id )
	VALUES (#arguments.product_id#, #arguments.scndcat_id#)
</cfquery>
</cffunction>

<!--- // ---------- Get Related Products for a Specific Product ---------- // --->
<cffunction name="CWquerySelectUpsellProducts" access="public" output="false" returntype="query"
			hint="Returns all related (upsell) products for a given product">

	<cfargument name="product_id" required="true" type="numeric"
				hint="the Product ID to look up">

<cfset var rsSelectUpsell = "">
<cfquery name="rsSelectUpsell" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT p.product_id,
	p.product_merchant_product_id,
	p.product_name,
	u.upsell_id
	FROM cw_products p, cw_product_upsell u
	WHERE p.product_id = u.upsell_2product_id
	AND u.upsell_product_id = #arguments.product_id#
	ORDER BY p.product_name, p.product_merchant_product_id
</cfquery>
<cfreturn rsSelectUpsell>
</cffunction>

<!--- // ---------- Get Reciprocal Related Products for a Specific Product ---------- // --->
<cffunction name="CWquerySelectReciprocalUpsellProducts" access="public" output="false" returntype="query"
			hint="Returns all upsell record with a given product as the related item">

	<cfargument name="product_id" required="true" type="numeric"
				hint="the Product ID to look up">

<cfset var rsSelectRecipUpsell = "">
<cfquery name="rsSelectRecipUpsell" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT p.product_id,
	p.product_merchant_product_id,
	p.product_name,
	u.upsell_id
	FROM cw_products p, cw_product_upsell u
	WHERE p.product_id = u.upsell_product_id
	AND u.upsell_2product_id = #arguments.product_id#
	ORDER BY p.product_name, p.product_merchant_product_id
</cfquery>
<cfreturn rsSelectRecipUpsell>
</cffunction>

<!--- // ---------- List All Active Product Categories ---------- // --->
<cffunction name="CWquerySelectActiveCategories" access="public" returntype="query"  output="false"
			hint="Returns query of all active categories containing active products">

	<cfargument name="product_id" required="false" type="numeric" default="0"
				hint="Optional Product ID - returns only categories associated w/ this product">

<cfset var rsListCategories = "">
<cfquery name="rsListCategories" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT DISTINCT cc.category_id, cc.category_name, cc.category_sort
	FROM
	cw_categories_primary cc,
	cw_product_categories_primary rr,
	cw_products pp
	WHERE cc.category_name <> ''
	AND pp.product_archive <> 1
	AND pp.product_on_web <> 0
	AND rr.product2category_category_id = cc.category_id
	AND rr.product2category_product_id = pp.product_id
	<cfif product_id>AND pp.product_id = #product_id#</cfif>
	ORDER BY category_sort, category_name
</cfquery>
<cfreturn rsListCategories>
</cffunction>

<!--- // ---------- List All Active Product Secondary Categories ---------- // --->
<cffunction name="CWquerySelectActiveScndCategories" access="public" returntype="query"  output="false"
			hint="Returns query of all active sub categories containing active products, based on an optional top level category">

	<cfargument name="filter_cat" required="false" default="0" type="numeric"
				hint="Filters subcategories by related category, according to existing active products. Can be left blank or passed in as (0)" >
	<cfargument name="product_id" required="false" type="numeric" default="0"
				hint="Optional Product ID - returns only secondary categories associated w/ this product">

<cfset var rsListScndCategories = "">
<cfquery name="rsListScndCategories" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT DISTINCT sc.secondary_id, sc.secondary_name, sc.secondary_sort
	FROM cw_categories_secondary sc
	,cw_product_categories_secondary rr
	, cw_products pp
	<cfif filter_cat gt 0>
	, cw_product_categories_primary cr
	</cfif>
	WHERE secondary_archive <> 1
	AND pp.product_archive <> 1
	AND pp.product_on_web <> 0
	AND rr.product2secondary_secondary_id = sc.secondary_id
	AND rr.product2secondary_product_id = pp.product_id
	<cfif filter_cat gt 0>
	AND cr.product2category_category_id = #filter_cat#
	AND cr.product2category_product_id = pp.product_id
	</cfif>
	<cfif product_id gt 0>AND pp.product_id = #product_id#</cfif>
	ORDER BY secondary_sort, secondary_name
</cfquery>
<cfreturn rsListScndCategories>
</cffunction>

<!--- // ---------- List Product Options ---------- // --->
<cffunction name="CWquerySelectOptions" access="public" returntype="query"  output="false"
			hint="Returns query of all active options">

	<cfargument name="product_id" required="false" type="numeric" default="0"
				hint="Optional Product ID - returns only options associated w/ this product">

<cfset var rsListOptions = "">
<cfquery name="rsListOptions" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT DISTINCT
		cw_option_types.optiontype_id,
		cw_option_types.optiontype_name
		<cfif arguments.product_id gt 0>
		,
		cw_options.option_id,
		cw_options.option_name,
		cw_options.option_sort
		</cfif>
	FROM
		<cfif arguments.product_id gt 0>
	cw_products
	INNER JOIN (( cw_option_types
		INNER JOIN cw_options ON cw_option_types.optiontype_id = cw_options.option_type_id)
		INNER JOIN cw_product_options ON cw_option_types.optiontype_id = cw_product_options.product_options2optiontype_id) ON cw_products.product_id = cw_product_options.product_options2prod_id
	WHERE cw_products.product_id= #arguments.product_id# AND NOT cw_options.option_archive = 1
		<cfelse>
	cw_option_types
	WHERE NOT optiontype_archive = 1
	AND NOT optiontype_deleted = 1
		</cfif>
	ORDER BY
		cw_option_types.optiontype_name
		<cfif arguments.product_id gt 0>
		,cw_options.option_name
		,cw_options.option_sort
		</cfif>
</cfquery>
<cfreturn rsListOptions>
</cffunction>

<!--- // ---------- List Related Product Options  ---------- // --->
<cffunction name="CWquerySelectRelOptions" access="public" returntype="query" output="false"
			hint="Returns a query of relative options for a product">

	<cfargument name="product_id" type="numeric" required="true"
				hint="ID of Product to look up">
	<cfargument name="product_options" type="string" required="false" default=""
				hint="Comma separated list of option group IDs to filter query by">

<cfset var rsGetOptnRelIDs = "">
<cfquery name="rsGetOptnRelIDs" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
  SELECT r.sku_option_id
	FROM (cw_skus s
	INNER JOIN cw_sku_options r
	ON s.sku_id = r.sku_option2sku_id)
	INNER JOIN cw_options so
	ON so.option_id = r.sku_option2option_id
	WHERE s.sku_product_id = #arguments.product_id#
       <!--- only use this if there are some options --->
       <cfif listlen(arguments.product_options) gt 0>
	AND so.option_type_id IN (#arguments.product_options#)
       </cfif>
	ORDER BY so.option_sort
</cfquery>
<cfreturn rsGetOptnRelIDs>
</cffunction>

<!--- // ---------- Delete Related Product Options ---------- // --->
<cffunction name="CWqueryDeleteRelProductOptions" access="public" returntype="void" output="false"
			hint="Deletes relative options for a product">

	<cfargument name="product_id" type="numeric" required="true"
				hint="ID of Product to look up">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_product_options
	WHERE product_options2prod_id = #arguments.product_id#
</cfquery>
</cffunction>

<!--- // ---------- Insert Related Product Options ---------- // --->
<cffunction name="CWqueryInsertProductOptions" access="public" returntype="void" output="false"
			hint="Creates a related product option record">

	<cfargument name="product_id" type="numeric" required="true"
				hint="ID of Product to insert">
	<cfargument name="optiontype_id" required="true" type="numeric"
				hint="optionType ID to insert">

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
				INSERT INTO cw_product_options
				(product_options2prod_id, product_options2optiontype_id)
				VALUES (#arguments.product_id#, #arguments.optiontype_id# )
			</cfquery>

</cffunction>

<!--- // ---------- Archive a Product ---------- // --->
<cffunction name="CWqueryArchiveProduct" access="public" returntype="void"  output="false"
			hint="Sets a product to archived status in admin (Archived = true)">

		<cfargument name="product_id" required="true" type="Numeric"
					hint="The ID of the product to archive">

<!--- set archive = 1 --->
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
UPDATE cw_products
SET product_archive = 1
WHERE product_id = #arguments.product_id#
</cfquery>
</cffunction>

<!--- // ---------- Reactivate an Archived Product ---------- // --->
<cffunction name="CWqueryReactivateProduct" access="public" returntype="void"  output="false"
			hint="Sets a product to non-archived status in admin (Archived = false) and updates related info">

	<cfargument name="product_id" required="true" type="Numeric"
				hint="The ID of the product to activate">

<!--- set archive = 0 --->
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	UPDATE cw_products
	SET product_archive = 0
	WHERE product_id = #arguments.product_id#
</cfquery>
<!--- Reactivate all options associated with this product --->
<cfquery name="rsArchivedOptions" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT cw_options.option_id
	FROM cw_options
		INNER JOIN ((cw_products
			INNER JOIN cw_skus
			ON cw_products.product_id = cw_skus.sku_product_id)
			INNER JOIN cw_sku_options ON cw_skus.sku_id = cw_sku_options.sku_option2sku_id)
			ON cw_options.option_id = cw_sku_options.sku_option2option_id
	WHERE cw_products.product_id = #product_id#
	AND cw_options.option_archive = 1
	</cfquery>
	<cfif rsArchivedOptions.recordCount neq 0>
	<cfset ArchivedOptions = ValueList(rsArchivedOptions.option_id,",")>
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	UPDATE cw_options SET option_archive = 0 WHERE option_id IN (#ArchivedOptions#)
</cfquery>
</cfif>

</cffunction>

<!--- // ---------- List Top Selling Products ---------- // --->
<cffunction name="CWquerySelectTopProducts" access="public" returntype="query" output="false"
			hint="Returns a query with top selling products">

<cfargument name="show_ct"
		required="false"
		default="15"
		type="numeric"
		hint="Number of products to return">

<cfset var rsTopProductsQuery = ''>
<cfset var sortQuery = ''>

<cfquery name="rsTopProductsQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT count(*) as prod_counter,
p.product_id,
p.product_name,
p.product_merchant_product_id,
p.product_date_modified
FROM cw_products p
, cw_order_skus o
, cw_skus s
WHERE o.ordersku_sku = s.sku_id
AND s.sku_product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.product_merchant_product_id, p.product_date_modified
</cfquery>

<!--- sort the results --->
<cfquery name="sortQuery" dbtype="query" maxrows="#arguments.show_ct#">
SELECT *
FROM rsTopProductsQuery
ORDER BY prod_counter DESC, product_date_modified
</cfquery>

<cfreturn sortQuery>
</cffunction>

<!--- // ---------- Delete Product Discount Records ---------- // --->
<cffunction name="CWqueryDeleteProductDiscount" access="public" returntype="void" output="false"
			hint="Deletes all discount records for a given product ID">

	<cfargument name="product_id" required="true" type="Numeric"
				hint="The ID of the product">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM
	cw_discount_products
	WHERE discount2product_product_id = #arguments.product_id#
</cfquery>
</cffunction>

<!--- // ---------- Delete SKU Discount Records ---------- // --->
<cffunction name="CWqueryDeleteSkuDiscount" access="public" returntype="void" output="false"
			hint="Deletes all discount records for skus in a given list">

	<cfargument name="sku_list" required="true" type="string"
				hint="list of product SKUS">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM
	cw_discount_skus
	WHERE discount2sku_sku_id IN (#arguments.sku_list#)
</cfquery>
</cffunction>

<!--- /////////// --->
<!--- SKU QUERIES --->
<!--- /////////// --->

<!--- // ---------- List Product Skus ---------- // --->
<cffunction name="CWquerySelectSkus" access="public" output="false" returntype="query"
			hint="Returns all skus for a product">

	<cfargument name="product_id" type="numeric" required="true"
				hint="ID of Product to look up">

<cfset var rsGetSKUs = "">
<cfquery name="rsGetSKUs" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT * FROM cw_skus
	WHERE sku_product_id = #arguments.product_id#
	ORDER BY sku_sort
</cfquery>
<cfreturn rsGetSkus>
</cffunction>

<!--- // ---------- Get SKU Options ---------- // --->
<cffunction name="CWquerySelectSkuOptions" access="public" output="false" returntype="query"
			hint="Returns a query of relative options for a given SKU ID">

	<cfargument name="sku_id" required="true" type="numeric"
				hint="The SKU ID to look up">

<cfset var rsSkuOptions = ''>

<cfquery name="rsSkuOptions" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
					SELECT
					ot.optiontype_name,
					so.option_name,
					r.sku_option_id,
					r.sku_option2option_id,
					so.option_type_id
				FROM (
					cw_option_types ot
						INNER JOIN cw_options so
						ON (ot.optiontype_id = so.option_type_id)
						AND (ot.optiontype_id = so.option_type_id))
						INNER JOIN cw_sku_options r
						ON so.option_id = r.sku_option2option_id
				WHERE
					r.sku_option2sku_id=#arguments.sku_id#
				AND NOT ot.optiontype_deleted = 1
				ORDER BY so.option_sort, ot.optiontype_name
</cfquery>
<cfreturn rsSkuOptions>
</cffunction>

<!--- // ---------- Insert a SKU ---------- // --->
<cffunction name="CWqueryInsertSKU" access="public" returntype="numeric" output="false"
			hint="Insert new sku into cw_skus - returns ID of newly inserted SKU" >

	<!--- product id and sku merchant id are required --->
	<cfargument name="sku_merchant_sku_id" required="true" type="String"
				hint="The Merchant Name (part number)">
	<cfargument name="sku_product_id" required="true" type="Numeric"
				hint="The ID of the product this SKU belongs to">
	<!--- optional values --->
	<cfargument name="sku_price" required="false" default="0" type="String"
				hint="sku price">
	<cfargument name="sku_ship_base" required="false" default="0" type="String"
				hint="sku fixed shipping cost">
	<cfargument name="sku_alt_price" required="false" default="0" type="String"
				hint="sku alt price">
	<cfargument name="sku_weight" required="false" default="0" type="String"
				hint="sku weight">
	<cfargument name="sku_stock" required="false" default="0" type="String"
				hint="sku stock">
	<cfargument name="sku_on_web" required="false" default="1" type="Boolean"
				hint="show on web y/n">
	<cfargument name="sku_sort" required="false" default="0" type="Numeric"
				hint="sort order">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_skus (
	sku_merchant_sku_id,
	sku_product_id,
	sku_price,
	sku_alt_price,
	sku_ship_base,
	sku_weight,
	sku_stock,
	sku_on_web,
	sku_sort
	)
	VALUES
	(
		'#arguments.sku_merchant_sku_id#',
		'#arguments.sku_product_id#',
		#CWsqlNumber(arguments.sku_price)#,
		#CWsqlNumber(arguments.sku_alt_price)#,
		#CWsqlNumber(arguments.sku_ship_base)#,
		#arguments.sku_weight#,
		#arguments.sku_stock#,
		#arguments.sku_on_web#,
		#arguments.sku_sort#
)
</cfquery>

<!--- Get the ID of the new SKU for further inserts --->
<cfquery name="rsNewSKUID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT sku_id
	FROM cw_skus
	WHERE sku_merchant_sku_id = '#arguments.sku_merchant_sku_id#'
</cfquery>

<cfreturn rsNewSKUID.sku_id>
</cffunction>

<!--- // ---------- Update a SKU ---------- // --->
<cffunction name="CWqueryUpdateSKU" access="public" returntype="void"  output="false"
			hint="Update sku details in cw_skus">

	<!--- product id and sku id are required --->
	<cfargument name="sku_id" required="true" type="Numeric"
				hint="The ID of the SKU to update">
	<cfargument name="sku_product_id" required="true" type="Numeric"
				hint="The ID of the product this SKU belongs to">
	<!--- optional values --->
	<cfargument name="sku_price" required="false" default="0" type="String"
				hint="sku price">
	<cfargument name="sku_ship_base" required="false" default="0" type="String"
				hint="sku ship base">
	<cfargument name="sku_alt_price" required="false" default="0" type="String"
				hint="sku alt price">
	<cfargument name="sku_weight" required="false" default="0" type="String"
				hint="sku weight">
	<cfargument name="sku_stock" required="false" default="0" type="String"
				hint="sku stock">
	<cfargument name="sku_on_web" required="false" default="1" type="Boolean"
				hint="show on web y/n">
	<cfargument name="sku_sort" required="false" default="0" type="Numeric"
				hint="sort order">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	UPDATE cw_skus
	SET
		sku_product_id='#arguments.sku_product_id#',
		sku_price=#CWsqlNumber(arguments.sku_price)#,
		sku_ship_base=#CWsqlNumber(arguments.sku_ship_base)#,
		sku_alt_price=#CWsqlNumber(arguments.sku_alt_price)#,
		sku_weight=#arguments.sku_weight#,
		sku_stock= #arguments.sku_stock#,
		sku_on_web= #arguments.sku_on_web#,
		sku_sort= #arguments.sku_sort#
	WHERE sku_id=#arguments.sku_id#
</cfquery>
</cffunction>

<!--- // ---------- Delete SKUS ---------- // --->
<cffunction name="CWqueryDeleteSKUs" access="public" output="false" returntype="void"
			hint="Deletes all skus based on a list of SKU IDs">

	<cfargument name="sku_list" type="string" required="true"
				hint="List of SKU IDs">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_skus
	WHERE sku_id IN (#arguments.sku_list#)
</cfquery>
</cffunction>

<!--- // ---------- Insert Related SKU Option ---------- // --->
<cffunction name="CWqueryInsertRelSKUOption" access="public" returntype="void" output="false"
			hint="Creates a relative option for a SKU">

	<cfargument name="sku_id" required="true" type="numeric"
				hint="SKU ID to insert">
	<cfargument name="option_id" required="true" type="numeric"
				hint="Option ID to insert">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_sku_options
	(sku_option2sku_id, sku_option2option_id)
	VALUES (#arguments.sku_id#, #arguments.option_id# )
</cfquery>

</cffunction>

<!--- // ---------- Delete Related SKU Options ---------- // --->
<cffunction name="CWqueryDeleteRelSKUOptions" access="public" returntype="void" output="false"
			hint="Deletes relative sku option values for a product">

	<cfargument name="option_list" type="string" required="true"
				hint="List of option IDs to preserve - pass in 0 to delete all">
	<cfargument name="sku_list" type="string" required="true"
				hint="List of SKU IDs">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_sku_options
	WHERE sku_option_id NOT IN (#arguments.option_list#)
	AND sku_option2sku_id IN (#arguments.sku_list#)
</cfquery>
</cffunction>

<!--- // ---------- Check for existing SKU ID ---------- // --->
<cffunction name="CWquerySelectSKUID" access="public" returntype="query" output="false"
			hint="Returns a query all SKUs with a given SKU Merchant ID (part number)">

	<cfargument name="sku_merchant_sku_id" type="string" required="true"
				hint="The SKU Merchant ID to look up">

<cfset var rsCheckUniqueSKU = "">
<cfquery name="rsCheckUniqueSKU" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT sku_merchant_sku_id
	FROM cw_skus
	WHERE sku_merchant_sku_id = '#arguments.sku_merchant_sku_id#'
</cfquery>
<cfreturn rsCheckUniqueSKU>
</cffunction>

<!--- // ---------- Count Orders for Product SKUS ---------- // --->
<cffunction name="CWqueryCountSKUOrders" access="public" output="false" returntype="numeric"
			hint="Returns total number of orders for skus of a given product">

	<cfargument name="sku_list" required="true" type="string"
				hint="list of product SKUS">

<cfset var rsCheckForOrders = "">
<cfquery name="rsCheckForOrders" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT Count(ordersku_id) as orderCount
	FROM cw_order_skus
	WHERE ordersku_sku IN(#arguments.sku_list#)
</cfquery>
<cfreturn rsCheckForOrders.orderCount>
</cffunction>

<!--- ///////////////////// --->
<!--- PRODUCT IMAGE QUERIES --->
<!--- ///////////////////// --->

<!--- // ---------- List Upload Groups ---------- // --->
<cffunction name="CWquerySelectImageUploadGroups" access="public" returntype="query" output="false"
			hint="Returns all upload groups with active image types (sizes) defined">

<cfset var rsGetImageCount = "">
<cfquery name="rsGetImageCount" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT  DISTINCT  imagetype_upload_group
	FROM cw_image_types
	ORDER BY imagetype_upload_group
</cfquery>
<cfreturn rsGetImageCount>
</cffunction>

<!--- // ---------- List Image Types ---------- // --->
<cffunction name="CWquerySelectImageTypes" access="public" returntype="query" output="false"
			hint="Returns all image types (sizes) with optional upload group variable">

	<cfargument name="upload_group_id" default="0" required="false" type="numeric"
			hint="specify an upload group to filter results">

	<cfargument name="imagetype_id" default="0" required="false" type="numeric"
			hint="specify an image type to filter results">

<cfset var rsListImageTypes = "">
<cfquery name="rsListImageTypes" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT  *
	FROM cw_image_types
	WHERE 1=1
	<cfif arguments.upload_group_id gt 0>
	AND imagetype_upload_group = #arguments.upload_group_id#
	</cfif>
	<cfif arguments.imagetype_id gt 0>
	AND imagetype_id = #arguments.imagetype_id#
	</cfif>
	ORDER BY imagetype_upload_group, imagetype_max_width, imagetype_name
</cfquery>
<cfreturn rsListImageTypes>
</cffunction>

<!--- // ---------- // Add Image Type // ---------- // --->
<cffunction name="CWqueryInsertImageType"
			access="public"
			output="false"
			returntype="any"
			hint="Add image type or size option"
			>
				
	<cfargument name="imagetype_upload_group" required="true" type="numeric"
		hint="the group or file upload field which uses this size">

	<cfargument name="imagetype_name" required="true" type="string"
		hint="the image type name or label">

	<cfargument name="imagetype_sortorder" required="true" type="numeric"
		hint="the order of the image type when shown in specific listings">

	<cfargument name="imagetype_folder" required="true" type="string"
		hint="the folder where the image type is stored">

	<cfargument name="imagetype_max_width" required="false" default="120" type="any"
		hint="the max scale width allowed">

	<cfargument name="imagetype_max_height" required="false" default="120" type="any"
		hint="the max scale height allowed">

	<cfargument name="imagetype_crop_width" required="false" default="0" type="any"
		hint="if defined, image is resized, then center-cropped to this width">

	<cfargument name="imagetype_crop_height" required="false" default="0" type="any"
		hint="if defined, image is resized, then center-cropped to this height">

	<cfargument name="imagetype_user_edit" required="false" default="1" type="numeric"
		hint="if 0, image type will be hidden from display page">

		<cfif not isNumeric(arguments.imagetype_max_width)><cfset arguments.imagetype_max_width = 0></cfif>
		<cfif not isNumeric(arguments.imagetype_max_height)><cfset arguments.imagetype_max_height = 0></cfif>
		<cfif not isNumeric(arguments.imagetype_crop_width)><cfset arguments.imagetype_crop_width = 0></cfif>
		<cfif not isNumeric(arguments.imagetype_crop_height)><cfset arguments.imagetype_crop_height = 0></cfif>
	
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			INSERT INTO cw_image_types(
			imagetype_name,
			imagetype_sortorder,
			imagetype_folder,
			imagetype_max_width,
			imagetype_max_height,
			<cfif arguments.imagetype_crop_width gt 0>imagetype_crop_width,</cfif>
			<cfif arguments.imagetype_crop_height gt 0>imagetype_crop_height,</cfif>
			imagetype_upload_group,
			imagetype_user_edit
			) VALUES (
			'#trim(arguments.imagetype_name)#',
			#arguments.imagetype_sortorder#,
			'#trim(arguments.imagetype_folder)#',
			#arguments.imagetype_max_width#,
			#arguments.imagetype_max_height#,
			<cfif arguments.imagetype_crop_width gt 0>#arguments.imagetype_crop_width#,</cfif>
			<cfif arguments.imagetype_crop_height gt 0>#arguments.imagetype_crop_height#,</cfif>
			#arguments.imagetype_upload_group#,
			#arguments.imagetype_user_edit#
			)
		</cfquery>

</cffunction>


<!--- // ---------- // Update Image Type // ---------- // --->
<cffunction name="CWqueryUpdateImageType"
			access="public"
			output="false"
			returntype="void"
			hint="Updates an image type record"
			>

	<cfargument name="imagetype_id" required="true" type="numeric"
		hint="specify an image type to update">

	<cfargument name="imagetype_upload_group" required="true" type="numeric"
		hint="the group or file upload field which uses this size">

	<cfargument name="imagetype_name" required="false" default="" type="string"
		hint="the image type name or label">

	<cfargument name="imagetype_sortorder" required="false" default="-1" type="numeric"
		hint="the order of the image type when shown in specific listings">

	<cfargument name="imagetype_folder" required="false" default="" type="string"
		hint="the folder where the image type is stored - update skipped if blank">

	<cfargument name="imagetype_max_width" required="false" default="0" type="numeric"
		hint="the max scale width allowed">

	<cfargument name="imagetype_max_height" required="false" default="0" type="numeric"
		hint="the max scale height allowed">

	<cfargument name="imagetype_crop_width" required="false" default="0" type="numeric"
		hint="if defined, image is resized, then center-cropped to this width">

	<cfargument name="imagetype_crop_height" required="false" default="0" type="numeric"
		hint="if defined, image is resized, then center-cropped to this height">

		<cfset var rsUpdateImageType = ''>

		<cfquery name="rsUpdateImageType" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			UPDATE cw_image_types
			SET
			<cfif len(trim(arguments.imagetype_name))>imagetype_name = '#trim(arguments.imagetype_name)#',</cfif>
			<cfif arguments.imagetype_sortorder gt -1>imagetype_sortorder = #arguments.imagetype_sortorder#,</cfif>
			<cfif len(trim(arguments.imagetype_folder))>imagetype_folder = '#trim(arguments.imagetype_folder)#',</cfif>
			<cfif arguments.imagetype_max_width gt 0>imagetype_max_width = #arguments.imagetype_max_width#,</cfif>
			<cfif arguments.imagetype_max_height gt 0>imagetype_max_height = #arguments.imagetype_max_height#,</cfif>
			<cfif arguments.imagetype_crop_width gt 0>imagetype_crop_width = #arguments.imagetype_crop_width#,</cfif>
			<cfif arguments.imagetype_crop_height gt 0>imagetype_crop_height = #arguments.imagetype_crop_height#,</cfif>
			imagetype_upload_group = #arguments.imagetype_upload_group#
			WHERE imagetype_id = #arguments.imagetype_id#
		</cfquery>

</cffunction>

<!--- // ---------- // Delete Image Type // ---------- // --->
<cffunction name="CWqueryDeleteImageType"
			access="public"
			output="false"
			returntype="void"
			hint="Delete image type or size option"
			>

	<cfargument name="imagetype_id" required="true" type="numeric"
			hint="specify an image type to delete">

	<cfargument name="remove_rel" required="false" default="false" type="boolean"
			hint="if true, all related product image records will be removed">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_image_types
	WHERE imagetype_id = #arguments.imagetype_id#
</cfquery>
<cfif arguments.remove_rel>
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_product_images
	WHERE product_image_imagetype_id = #arguments.imagetype_id#
</cfquery>
</cfif>
</cffunction>

<!--- // ---------- List Product Images ---------- // --->
<cffunction name="CWquerySelectProductImages" access="public" returntype="query" output="false"
			hint="Returns all image information for images associated with a given product - pass in ID of 0 to get all">

	<cfargument name="product_id" required="false" default="0" type="numeric"
				hint="the Product ID to look up">
	<cfargument name="imagetype_id" required="false" default="0" type="numeric"
				hint="specific image type from cw_image_types">
	<cfargument name="imagetype_upload_group" required="false" default="0" type="numeric"
				hint="return all image sizes for a specific upload group">

<cfset var rsProductImages = "">
<cfquery name="rsProductImages" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT *
	FROM cw_product_images ii,
	cw_image_types tt
	WHERE tt.imagetype_id = ii.product_image_imagetype_id
	<cfif arguments.product_id gt 0>
	AND ii.product_image_product_id = #arguments.product_id#
	</cfif>
	<cfif arguments.imagetype_id gt 0>
	AND ii.product_image_imagetype_id = #arguments.imagetype_id#
	</cfif>
	<cfif arguments.imagetype_upload_group gt 0>
	AND tt.imagetype_upload_group = #arguments.imagetype_upload_group#
	</cfif>
	ORDER BY ii.product_image_sortorder, tt.imagetype_sortorder
</cfquery>
<cfreturn rsProductImages>
</cffunction>

<!--- // ---------- List Product Images by Filename ---------- // --->
<cffunction name="CWquerySelectProductImageFiles" access="public" returntype="query" output="false"
			hint="Returns relative product image records images with a given filename">

	<cfargument name="img_filename" required="true" type="string"
				hint="The filename to look up">

<cfset var rsProductImages = "">
<cfquery name="rsProductImages" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT *
	FROM cw_product_images
	WHERE product_image_filename = '#arguments.img_filename#'
	ORDER BY tt.imagetype_sortorder
</cfquery>
<cfreturn rsProductImages>
</cffunction>

<!--- // ---------- Delete Product Image Record ---------- // --->
<cffunction name="CWqueryDeleteProductImage" access="public" returntype="void" output="false"
			hint="Deletes an associated image/product record">

	<cfargument name="product_id" required="true" type="Numeric"
				hint="The ID of the product">
	<cfargument name="imagetype_id" required="true" type="Numeric"
				hint="The ID of the 'image type' to remove from the product - pass in 0 to remove all">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
DELETE FROM cw_product_images
WHERE product_image_product_id = #arguments.product_id#
<cfif arguments.imagetype_id gt 0>AND product_image_imagetype_id = #arguments.imagetype_id#</cfif>
</cfquery>
</cffunction>

<!--- // ---------- Delete Product Images by Filename ---------- // --->
<cffunction name="CWqueryDeleteProductImageFile" access="public" returntype="void" output="false"
			hint="Deletes an associated image/product record">

	<cfargument name="img_filename" required="true" type="string"
				hint="The filename to delete">
	<cfargument name="product_id" required="false" default="0" type="Numeric"
				hint="The ID of the product - leave blank to remove all by name">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
				DELETE from cw_product_images
				WHERE product_image_filename = '#arguments.img_filename#'
			<cfif arguments.product_id gt 0>
				AND product_image_product_id = #arguments.product_id#
			</cfif>
</cfquery>
</cffunction>

<!--- // ---------- Update Product Image Record ---------- // --->
<cffunction name="CWqueryUpdateProductImage" access="public" returntype="void" output="false"
			hint="Updates an associated image/product record">

	<cfargument name="product_id" required="true" type="Numeric"
				hint="The ID of the product">
	<cfargument name="imagetype_id" required="true" type="Numeric"
				hint="The ID of the 'image type' to update">
	<cfargument name="image_filename" required="true" type="String"
				hint="The image filename to record">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	UPDATE cw_product_images
	SET product_image_filename = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.image_filename#">
	WHERE product_image_product_id = #arguments.product_id#
	AND product_image_imagetype_id = #arguments.imagetype_id#
</cfquery>
</cffunction>

<!--- // ---------- Insert New Product Image Record ---------- // --->
<cffunction name="CWqueryInsertProductImage" access="public" returntype="void" output="false"
			hint="Creates a new associated image/product record">

	<cfargument name="product_id" required="true" type="Numeric"
				hint="The ID of the product">
	<cfargument name="imagetype_id" required="true" type="Numeric"
				hint="The ID of the 'image type' to update">
	<cfargument name="image_filename" required="true" type="String"
				hint="The image filename to record">
	<cfargument name="imagetype_sortorder" required="true" type="Numeric"
				hint="A value to assign for sort order">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_product_images (
		product_image_product_id,
		product_image_imagetype_id,
		product_image_filename,
		product_image_sortorder
	) VALUES (
		<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.product_id#">
		, #arguments.imagetype_id#
		, <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.image_filename#">
		, #arguments.imagetype_sortorder#
	)
</cfquery>
</cffunction>


<!--- ////////////// --->
<!--- UPSELL QUERIES --->
<!--- ////////////// --->

<!--- // ---------- List Available Products for Upsell Selection ---------- // --->
<cffunction name="CWquerySelectUpsellSelections" access="public" returntype="query" output="false"
			hint="Returns a query of available upsell products for a specified product">

	<!--- optional arguments to restrict results --->
	<cfargument name="upsell_cat" required="false" default="0" type="numeric"
				hint="Category ID to filter results by">
	<cfargument name="upsell_scndcat" required="false" default="0" type="numeric"
				hint="Secondary Category ID to filter results by">
	<cfargument name="omitted_products" required="false" default="0" type="string"
				hint="A comma separated list of product IDs to ignore">

<cfset var rsUpsellProducts = "">
<cfquery name="rsUpsellProducts" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT pp.product_name, pp.product_id
	, pp.product_merchant_product_id
	FROM cw_products pp
	<cfif arguments.upsell_cat gt 0>
	, cw_product_categories_primary cc
	</cfif>
	<cfif arguments.upsell_scndcat gt 0>
	, cw_product_categories_secondary sc
	</cfif>
	WHERE NOT product_archive = 1
	<cfif listLen(trim(arguments.omitted_products))>
	AND NOT product_id in(#arguments.omitted_products#)
	</cfif>
	<!--- category / secondary cat --->
	<cfif arguments.upsell_cat gt 0 and application.cw.adminProductUpsellByCatEnabled>
	AND cc.product2category_category_id = #arguments.upsell_cat#
	AND cc.product2category_product_id = pp.product_id
	</cfif>
	<cfif arguments.upsell_scndcat gt 0 and application.cw.adminProductUpsellByCatEnabled>
	AND sc.product2secondary_secondary_id = #arguments.upsell_scndcat#
	AND sc.product2secondary_product_id = pp.product_id
	</cfif>
	ORDER BY pp.product_name
</cfquery>

<cfreturn rsUpsellProducts>
</cffunction>

<!--- // ---------- Check for Existing Upsell Record ---------- // --->
<cffunction name="CWquerySelectUpsell" access="public" returntype="numeric" output="false"
			hint="Check for upsell records using given product ID and relative product ID">

	<cfargument name="product_id" required="true" type="numeric"
				hint="The Product ID to look up">
	<cfargument name="upsell_rel_ID" required="false" type="numeric" default="0"
				hint="The Relative Product ID to look up">

<cfset var rsSelectUpsell = "">
<cfquery name="rsSelectUpsell" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT upsell_id
	FROM cw_product_upsell
	WHERE upsell_product_id = #arguments.product_id#
	<cfif arguments.upsell_rel_ID gt 0>
		AND upsell_2product_id = #arguments.upsell_rel_ID#
	</cfif>
</cfquery>
<cfreturn rsSelectUpsell.recordCount>
</cffunction>

<!--- // ---------- Insert Upsell Record ---------- // --->
<cffunction name="CWqueryInsertUpsell" access="public" returntype="void" output="false"
			hint="Creates an upsell record">

	<cfargument name="upsell_product_id" required="true" type="numeric"
				hint="The Product ID to insert">
	<cfargument name="upsell_2product_id" required="true" type="numeric"
				hint="The Related Product ID to insert">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_product_upsell (upsell_product_id, upsell_2product_id)
	VALUES (#arguments.upsell_product_id#,#arguments.upsell_2product_id#)
</cfquery>

</cffunction>

<!--- // ---------- Delete Upsell Record ---------- // --->
<cffunction name="CWqueryDeleteUpsell" access="public" output="false" returntype="void"
			hint="Deletes a specified upsell ID, or all upsell records for a given optional product">

	<cfargument name="product_id" required="false" default="0" type="numeric"
				hint="Product ID to delete all upsells from">
	<cfargument name="upsell_id" required="false" default="0" type="numeric"
				hint="Upsell ID to delete">
	<cfargument name="delete_both" required="false" default="0" type="boolean"
				hint="If yes, delete both ways - direct and relative upsells">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_product_upsell
	WHERE 1=1
	<cfif arguments.product_id gt 0>AND (upsell_product_id=#arguments.upsell_id#<cfif arguments.delete_both> OR upsell_2product_id = #arguments.product_id#</cfif>)</cfif>
	<cfif arguments.upsell_id gt 0>	AND upsell_id=#arguments.upsell_id#</cfif>
</cfquery>
</cffunction>


<!--- //////////////// --->
<!--- ORDER QUERIES --->
<!--- //////////////// --->

<!--- // ---------- Get Order ---------- // --->
<cffunction name="CWquerySelectOrder" access="public" output="false" returntype="query"
			hint="Returns a query containing a single record from the orders table">

	<cfargument name="order_id" required="true" default="0" type="string"
				hint="ID of order to look up">

<cfset var rsOrder = ''>
<cfquery name="rsOrder" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT *
FROM cw_orders
WHERE order_id = '#arguments.order_id#'
</cfquery>

<cfreturn rsOrder>
</cffunction>

<!--- // ---------- Select Order Details w/ sku info, customer info, etc ---------- // --->
<cffunction name="CWquerySelectOrderDetails" access="public" output="false" returntype="query"
			hint="Returns a query with all details about a given order">

	<cfargument name="order_id" required="true" default="0" type="string"
				hint="ID of order to look up">

<cfset var rsOrderDetails = ''>
<cfquery name="rsOrderDetails" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT
	ss.shipstatus_name,
	o.*,
	c.customer_first_name,
	c.customer_last_name,
	c.customer_id,
	c.customer_email,
	p.product_name,
	p.product_id,
	p.product_custom_info_label,
	s.sku_id,
	s.sku_weight,
	s.sku_merchant_sku_id,
	sm.ship_method_name,
	os.ordersku_sku,
	os.ordersku_unique_id,
	os.ordersku_quantity,
	os.ordersku_unit_price,
	os.ordersku_sku_total,
	os.ordersku_tax_rate,
	os.ordersku_discount_amount,
	(o.order_total - (o.order_tax + o.order_shipping + o.order_shipping_tax)) as order_SubTotal
FROM (
	cw_products p
	INNER JOIN cw_skus s
	ON p.product_id = s.sku_product_id)
	INNER JOIN ((cw_customers c
		INNER JOIN (cw_order_status ss
			RIGHT JOIN (cw_ship_methods sm
				RIGHT JOIN cw_orders o
				ON sm.ship_method_id = o.order_ship_method_id)
			ON ss.shipstatus_id = o.order_status)
		ON c.customer_id = o.order_customer_id)
		INNER JOIN cw_order_skus os
		ON o.order_id = os.ordersku_order_id)
	ON s.sku_id = os.ordersku_sku
WHERE o.order_id = '#arguments.order_id#'
ORDER BY
	p.product_name,
	s.sku_sort,
	s.sku_merchant_sku_id
</cfquery>

<cfreturn rsOrderDetails>
</cffunction>

<!--- // ---------- Select Orders (Search) ---------- // --->
<cffunction name="CWquerySelectOrders" access="public" output="false" returntype="query"
			hint="Returns a query with order details">

	<cfargument name="status_id" required="false" default="0" type="numeric"
				hint="Limit orders to specific status">
	<cfargument name="date_start" required="false" default="0" type="date"
				hint="Limit orders to this date or after">
	<cfargument name="date_end" required="false" default="0" type="date"
				hint="Limit orders to this date or before">
	<cfargument name="id_str" required="false" default="" type="string"
				hint="An order ID, or partial ID to match">
	<cfargument name="cust_name" required="false" default="" type="string"
				hint="A customer first or last name or ID, or part of a name or ID to match">
	<cfargument name="max_orders" required="false" default="0" type="numeric"
				hint="Max orders to return - pass in 0 to show all">

<cfset var rsOrders = ''>
<cfset var maxRows = 100000>
<cfif arguments.max_orders gt 0>
	<cfset var maxRows = arguments.max_orders>
</cfif>

<cfquery name="rsOrders" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT <cfif application.cw.appDbType is not 'mysql' and maxRows gt 0> TOP #maxRows# </cfif>
cw_customers.customer_first_name,
cw_customers.customer_last_name,
cw_customers.customer_zip,
cw_customers.customer_id,
cw_orders.order_id,
cw_orders.order_date,
cw_orders.order_status,
cw_orders.order_address1,
cw_orders.order_city,
cw_orders.order_state,
cw_orders.order_zip,
cw_orders.order_total,
cw_order_status.shipstatus_name
FROM ((cw_customers
INNER JOIN cw_orders
ON cw_customers.customer_id = cw_orders.order_customer_id)
INNER JOIN cw_order_status
ON cw_order_status.shipstatus_id = cw_orders.order_status)
WHERE 1=1
<cfif arguments.date_start neq 0>AND cw_orders.order_date >= #CreateODBCDate(LSParseDateTime(arguments.date_start))#</cfif>
<cfif arguments.date_end neq 0>AND cw_orders.order_date <= #CreateODBCDateTime(DateAdd("d",1,LSParseDateTime(arguments.date_end)))#</cfif>
<cfif arguments.status_id>AND order_status = #arguments.status_id#</cfif>
<cfif len(trim(arguments.id_str))>AND #application.cw.sqlLower#(order_id) like '%#lcase(arguments.id_str)#%'</cfif>
<cfif len(trim(arguments.cust_name))>
	AND (
	#application.cw.sqlLower#(customer_first_name) like '%#lcase(arguments.cust_name)#%'
	OR #application.cw.sqlLower#(customer_last_name) like '%#lcase(arguments.cust_name)#%'
	OR #application.cw.sqlLower#(customer_id) like '%#lcase(arguments.cust_name)#%'
	)
</cfif>
GROUP BY
cw_orders.order_id,
cw_orders.order_date,
cw_orders.order_status,
cw_orders.order_address1,
cw_orders.order_city,
cw_orders.order_state,
cw_orders.order_zip,
cw_orders.order_total,
cw_order_status.shipstatus_name,
cw_customers.customer_first_name,
cw_customers.customer_last_name,
cw_customers.customer_zip,
cw_customers.customer_id
ORDER BY cw_orders.order_date DESC
<cfif application.cw.appDbType is 'mysql' and maxRows gt 0> LIMIT #maxRows# </cfif>
</cfquery>


<cfif arguments.max_orders gt 0>
	<cfquery name="rsOrders" dbtype="query" maxrows="#arguments.max_orders#">
	SELECT *
	FROM rsOrders
	</cfquery>
</cfif>

<cfreturn rsOrders>
</cffunction>

<!--- // ---------- // Get Payments Related to Order // ---------- // --->
<cffunction name="CWorderPayments"
			access="public"
			output="false"
			returntype="query"
			hint="returns all payments related to order"
			>

	<cfargument name="order_id"
			required="true"
			default="0"
			type="any"
			hint="order ID to look up">

	<cfset var rsOrderPayments = ''>

	<cfquery name="rsOrderPayments" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT *
	FROM cw_order_payments
	WHERE order_id = <cfqueryparam value="#arguments.order_id#" cfsqltype="cf_sql_varchar">
	</cfquery>

<cfreturn rsOrderPayments>
</cffunction>

<!--- // ---------- // Get Payment Totals for Order // ---------- // --->
<cffunction name="CWorderPaymentTotal"
			access="public"
			output="false"
			returntype="numeric"
			hint="returns a numeric total of all payments made against a given order"
			>

	<cfargument name="order_id"
			required="true"
			default="0"
			type="any"
			hint="order ID to look up">

	<cfset var paymentQuery = ''>
	<cfset var paymentTotalsQuery = ''>
	<cfset var paymentTotal = 0>

	<cfset paymentQuery = CWorderPayments(arguments.order_id)>
	<cfquery name="paymentTotalsQuery" dbtype="query">
	SELECT sum(payment_amount) as paymentTotal
	FROM paymentQuery
	WHERE payment_amount > 0
	AND payment_status = 'approved'
	</cfquery>

	<cfif not isNumeric(paymentTotal)>
		<cfset paymentTotal = 0>
	</cfif>

<cfreturn paymentTotal>
</cffunction>

<!--- // ---------- Select SKUS in an order ---------- // --->
<cffunction name="CWquerySelectOrderSkus" access="public" output="false" returntype="query"
			hint="Returns sku details for any order, along with some details about the order">

	<cfargument name="order_id" required="true" type="string"
				hint="order ID to look up">

<cfset var rsOrderSkus = "">
<cfquery name="rsOrderSkus" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT
os.ordersku_sku,
os.ordersku_quantity,
os.ordersku_unit_price,
os.ordersku_sku_total,
s.sku_id,
s.sku_merchant_sku_id,
c.customer_id,
ss.shipstatus_name as orderstatus,
o.order_id,
o.order_total
FROM (
cw_products p
INNER JOIN cw_skus s
ON p.product_id = s.sku_product_id)
INNER JOIN ((cw_customers c
INNER JOIN (cw_order_status ss
RIGHT JOIN (cw_ship_methods sm
RIGHT JOIN cw_orders o
ON sm.ship_method_id = o.order_ship_method_id)
ON ss.shipstatus_id = o.order_status)
ON c.customer_id = o.order_customer_id)
INNER JOIN cw_order_skus os
ON o.order_id = os.ordersku_order_id)
ON s.sku_id = os.ordersku_sku
WHERE o.order_id = '#arguments.order_id#'
ORDER BY
p.product_name,
s.sku_sort
</cfquery>
<cfreturn rsOrderSkus>
</cffunction>

<!--- // ---------- Update Order ---------- // --->
<cffunction name="CWqueryUpdateOrder" access="public" returntype="void"  output="false"
			hint="Update an existing order record">

	<!--- ID and Status are required --->
	<cfargument name="order_id" required="true" default="" type="string"
				hint="The ID of the order to update">
	<cfargument name="order_status" required="true" default="" type="numeric"
				hint="The ID of the order status">

	<!--- optional arguments --->
	<cfargument name="order_ship_date" required="false" default="" type="string"
				hint="The date this order was shipped">
	<cfargument name="order_ship_charge" required="false" default="0" type="string"
				hint="The amount of shipping charged to this order">
	<cfargument name="order_tracking_id" required="false" default="" type="string"
				hint="The tracking ID for this order">
	<cfargument name="order_notes" required="false" default="" type="string"
				hint="Admin notes for the order">
	<cfargument name="order_return_date" required="false" default="" type="string"
				hint="The date order was returned">
	<cfargument name="order_return_amount" required="false" default="" type="string"
				hint="The amount of the return refund">

    <cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
    UPDATE cw_orders
		SET order_status='#arguments.order_status#'
			, order_ship_date=
				<cfif arguments.order_ship_date neq "" and isDate(arguments.order_ship_date)>
				#createODBCdateTime(LSParseDateTime(dateFormat(arguments.order_ship_date,'yyyy-mm-dd')))#
				<cfelse>
				Null
				</cfif>
			, order_actual_ship_charge = #CWsqlNumber(arguments.order_ship_charge)#
			, order_ship_tracking_id='#arguments.order_tracking_id#'
			, order_notes='#arguments.order_notes#'
			, order_return_date =
				<cfif arguments.order_return_date neq "" and isDate(arguments.order_return_date)>
				#createODBCdateTime(LSParseDateTime(dateFormat(arguments.order_return_date,'short')))#
				<cfelse>
				Null
				</cfif>
			, order_return_amount = #CWsqlNumber(arguments.order_return_amount)#
    WHERE order_id='#arguments.order_id#'
		</cfquery>


</cffunction>

<!--- // ---------- Delete Order ---------- // --->
<cffunction name="CWqueryDeleteOrder" access="public" output="false" returntype="void"
			hint="Delete order and associated order sku records">

	<cfargument name="order_id" required="true" type="string"
				hint="ID of the order to delete">

<!--- delete the order skus --->
  <cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
  DELETE FROM cw_order_skus WHERE ordersku_order_id='#arguments.order_id#'
  </cfquery>
<!--- delete the order discounts --->
  <cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
  DELETE FROM cw_discount_usage WHERE discount_usage_order_id='#arguments.order_id#'
  </cfquery>
<!--- delete the order record --->
  <cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
  DELETE FROM cw_orders WHERE order_id='#arguments.order_id#'
  </cfquery>

</cffunction>

<!--- // ---------- Select Order Status Code Value(s) ---------- // --->
<cffunction name="CWquerySelectOrderStatus" access="public" returntype="query" output="true"
			hint="Returns a query with status of a given order, or all order status options">

	<cfargument name="shipstatus_id" required="false" default="0" type="Numeric"
				hint="A specific ship status to look up (if omitted, all status types are returned)">

	<cfset var orderStatusQuery = ''>
	<cfquery name="orderStatusQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT *
	FROM cw_order_status
	<cfif arguments.shipstatus_id gt 0>
	WHERE shipstatus_id = #arguments.shipstatus_id#
	</cfif>
	ORDER BY shipstatus_sort ASC
	</cfquery>
<cfreturn orderStatusQuery>
</cffunction>

<!--- // ---------- Update Order Status Code Values ---------- // --->
<cffunction name="CWqueryUpdateShipStatus" access="public" returntype="void" output="false"
			hint="Update an order status code based on ID">

<!--- ID is required --->
	<cfargument name="status_id" required="true" type="numeric"
					hint="ID of the record to update">
<!--- others are optional --->
		<cfargument name="status_name" type="string" required="false" default=""
					hint="Name of the ship status">
		<cfargument name="status_sort" type="numeric" required="false" default="0"
					hint="Ship Status sort order">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		UPDATE cw_order_status
		SET
		shipstatus_sort=#arguments.status_sort#
		<cfif len(trim(arguments.status_name))>,shipstatus_name='#arguments.status_name#'</cfif>
		WHERE shipstatus_id=#arguments.status_id#
</cfquery>

</cffunction>

<!--- // ---------- // Get Custom Info Text: CWgetCustomInfo() // ---------- // --->
<cffunction name="CWgetCustomInfo" access="public" output="false" returntype="any"
			hint="Returns the custom value stored for a customized sku, based on phrase ID">

	<cfargument name="phrase_id"
			required="true"
			type="string"
			hint="the ID of the custom value to look up">

	<cfset var lookup_id = val(arguments.phrase_id)>
	<cfset var returnVal = ''>
	<cfset var infoQuery = ''>

	<cfquery name="infoQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT data_content
	FROM cw_order_sku_data
	WHERE data_id = <cfqueryparam value="#lookup_id#" cfsqltype="cf_sql_integer">
	</cfquery>

	<cfif infoQuery.RecordCount neq 0>
		<cfset returnVal = infoQuery.data_content>
	</cfif>


	<cfreturn returnVal>

</cffunction>
<!--- //////////////// --->
<!--- CUSTOMER QUERIES --->
<!--- //////////////// --->

<!--- // ---------- Select Customers (search) ---------- // --->
<cffunction name="CWquerySelectCustomers" access="public" output="false" returntype="query"
			hint="Returns a query with customer info for admin search. Default is all customers">

	<cfargument name="cust_name" required="false" default="" type="string"
				hint="A customer first or last name, or part of a name to match">
	<cfargument name="id_str" required="false" default="" type="string"
				hint="A customer ID, or part of an ID to match">
	<cfargument name="cust_email" required="false" default="" type="string"
				hint="A customer email, or partial email to match">
	<cfargument name="cust_addr" required="false" default="" type="string"
				hint="A customer address, compared to all address fields for matching">
	<cfargument name="order_str" required="false" default="" type="string"
				hint="An order ID, or partial ID to match">
	<cfargument name="show_ct" required="false" default="0" type="numeric"
				hint="Maximum records to return (default 0 = all)">
	<cfargument name="customer_type" required="false" default="0" type="numeric"
				hint="customer type to filter (default 0 = all)">
				

<cfset var rsCustomers = ''>
<cfset var columnList = ''>
<cfset var columnTypeList = ''>
<cfset var customerGroupQuery = ''>
<cfset var tempTotal = 0>
<cfset var tempVal = ''>
<cfset var temp = ''>
<cfset var maxRows = 100000>
<cfif arguments.show_ct gt 0>
	<cfset maxRows = arguments.show_ct>
</cfif>

<cfquery name="rsCustomers" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT <cfif application.cw.appDbType is not 'mysql' and maxRows gt 0> TOP #maxRows# </cfif>
		cw_customers.customer_id,
				cw_customers.customer_type_id,
				cw_customers.customer_first_name,
				cw_customers.customer_last_name,
				cw_customers.customer_address1,
				cw_customers.customer_address2,
				cw_customers.customer_city,
				cw_customers.customer_zip,
				cw_customers.customer_ship_name,
				cw_customers.customer_ship_company,
				cw_customers.customer_ship_address1,
				cw_customers.customer_ship_address2,
				cw_customers.customer_ship_city,
				cw_customers.customer_ship_zip,
				cw_customers.customer_phone,
				cw_customers.customer_phone_mobile,
				cw_customers.customer_email,
				cw_customers.customer_username,
				cw_customers.customer_password,
				cw_customers.customer_guest,
				cw_customers.customer_company,
				cw_stateprov.stateprov_name,
				cw_customer_stateprov.customer_state_destination,
				cw_orders.order_id,
				cw_orders.order_customer_id,
				cw_orders.order_total,
				cw_orders.order_date,
				cw_customer_types.customer_type_name,
				SUM(order_total) as total_spending,
				MAX(order_date) as top_order_date
	FROM ((((cw_customers
			INNER JOIN cw_customer_stateprov
			ON cw_customers.customer_id = cw_customer_stateprov.customer_state_customer_id)
			INNER JOIN cw_stateprov
			ON cw_stateprov.stateprov_id = cw_customer_stateprov.customer_state_stateprov_id)
			LEFT OUTER JOIN cw_orders
			ON cw_orders.order_customer_id = cw_customers.customer_id)
			LEFT OUTER JOIN cw_customer_types
			ON cw_customers.customer_type_id = cw_customer_types.customer_type_id)
		WHERE cw_customer_stateprov.customer_state_destination='BillTo'
		<!--- customer name --->
		<cfif len(trim(arguments.cust_name))>
		AND (
		#application.cw.sqlLower#(customer_first_name) like '%#lcase(arguments.cust_name)#%'
		OR #application.cw.sqlLower#(customer_last_name) like '%#lcase(arguments.cust_name)#%'
		OR #application.cw.sqlLower#(customer_company) like '%#lcase(arguments.cust_name)#%'
		)
		</cfif>
		<!--- customer ID --->
		<cfif len(trim(arguments.id_str))>AND #application.cw.sqlLower#(customer_id) like '%#lcase(arguments.id_str)#%'</cfif>
		<!--- customer Email --->
		<cfif len(trim(arguments.cust_email))>AND #application.cw.sqlLower#(customer_email) like '%#lcase(arguments.cust_email)#%'</cfif>
		<!--- customer address --->
		<cfif len(trim(arguments.cust_addr))>
		AND (
		#application.cw.sqlLower#(customer_address1) like '%#lcase(arguments.cust_addr)#%'
		OR #application.cw.sqlLower#(customer_address2) like '%#lcase(arguments.cust_addr)#%'
		OR #application.cw.sqlLower#(customer_city) like '%#lcase(arguments.cust_addr)#%'
		OR #application.cw.sqlLower#(customer_zip) like '%#lcase(arguments.cust_addr)#%'
		OR #application.cw.sqlLower#(stateprov_name) like '%#lcase(arguments.cust_addr)#%'
		OR #application.cw.sqlLower#(customer_state_destination) like '%#lcase(arguments.cust_addr)#%'
		)
		</cfif>
		<cfif len(trim(arguments.order_str))>
	    AND customer_id IN (SELECT order_customer_id
						FROM cw_orders
						WHERE #application.cw.sqlLower#(order_id) like '%#lcase(arguments.order_str)#%')
		</cfif>
		<cfif arguments.customer_type gt 0>
		AND cw_customers.customer_type_id = #arguments.customer_type#
		</cfif>
			GROUP BY
				cw_customers.customer_id,
				cw_customers.customer_type_id,
				cw_customers.customer_first_name,
				cw_customers.customer_last_name,
				cw_customers.customer_address1,
				cw_customers.customer_address2,
				cw_customers.customer_city,
				cw_customers.customer_zip,
				cw_customers.customer_ship_name,
				cw_customers.customer_ship_company,
				cw_customers.customer_ship_address1,
				cw_customers.customer_ship_address2,
				cw_customers.customer_ship_city,
				cw_customers.customer_ship_zip,
				cw_customers.customer_phone,
				cw_customers.customer_phone_mobile,
				cw_customers.customer_email,
				cw_customers.customer_username,
				cw_customers.customer_password,
				cw_customers.customer_guest,
				cw_customers.customer_company,
				cw_stateprov.stateprov_name,
				cw_customer_stateprov.customer_state_destination,
				cw_orders.order_id,
				cw_orders.order_customer_id,
				cw_orders.order_total,
				cw_orders.order_date,
				cw_customer_types.customer_type_name				
			ORDER BY customer_last_name, customer_first_name
			<cfif application.cw.appDbType is 'mysql' and maxRows gt 0> LIMIT #maxRows# </cfif>			
</cfquery>

<!--- group by ID into new query --->
<cfset columnList = "
	customer_id,
	customer_type_id,
	customer_first_name,
	customer_last_name,
	customer_address1,
	customer_address2,
	customer_city,
	customer_zip,
	customer_ship_name,
	customer_ship_company,
	customer_ship_address1,
	customer_ship_address2,
	customer_ship_city,
	customer_ship_zip,
	customer_phone,
	customer_phone_mobile,
	customer_email,
	customer_username,
	customer_password,
	customer_guest,
	customer_company,
	stateprov_name,
	customer_state_destination,
	order_id,
	order_customer_id,
	order_total,
	order_date,
	customer_type_name,
	total_spending,
	top_order_date
			">
<cfset columnTypeList = "varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						decimal,
						date,
						varchar,
						decimal,
						date">

<cfset customerGroupQuery = queryNew("#columnList#","#columnTypeList#")>
<cfoutput query="rsCustomers" group="customer_id">
<cfset tempTotal = 0>
<cfset tempVal = ''>

<!--- total the grouped order values --->
<cfoutput>
	<cfif isNumeric(total_spending)>
<cfset tempTotal = tempTotal + total_spending>
	</cfif>
</cfoutput>
<cfset queryAddRow(customerGroupQuery)>
<cfloop list="#columnList#" index="cc">
	<cfif trim(cc) eq 'total_spending'>
	<cfset tempVal = "tempTotal">
	<cfelse>
	<cfset tempVal = 'rsCustomers.#trim(cc)#'>
	</cfif>
<cfset temp = querySetCell(customerGroupQuery,"#trim(cc)#","#evaluate(trim(tempVal))#")>
</cfloop>
</cfoutput>

<!--- query of query to sort --->
<cfquery dbtype="query" name="rsCustomers" maxrows="#maxRows#">
SELECT *
FROM customerGroupQuery
ORDER BY total_spending DESC
</cfquery>

<cfreturn rsCustomers>
</cffunction>

<!--- // ---------- Select Customer Details ---------- // --->
<cffunction name="CWquerySelectCustomerDetails" access="public" output="false" returntype="query"
			hint="Returns a query with customer details including billing address info, state and country">

	<cfargument name="customer_id" required="false" default="" type="string"
				hint="A customer ID, or part of an ID to match">

<cfset var rsCustomerDetails = ''>
<cfquery name="rsCustomerDetails" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT cw_customers.customer_id,
				cw_customers.customer_type_id,
				cw_customers.customer_first_name,
				cw_customers.customer_last_name,
				cw_customers.customer_address1,
				cw_customers.customer_address2,
				cw_customers.customer_city,
				cw_customers.customer_zip,
				cw_customers.customer_ship_name,
				cw_customers.customer_ship_company,
				cw_customers.customer_ship_address1,
				cw_customers.customer_ship_address2,
				cw_customers.customer_ship_city,
				cw_customers.customer_ship_zip,
				cw_customers.customer_phone,
				cw_customers.customer_phone_mobile,
				cw_customers.customer_email,
				cw_customers.customer_company,
				cw_customers.customer_username,
				cw_customers.customer_password,
				cw_customers.customer_guest,
				cw_stateprov.stateprov_name,
				cw_stateprov.stateprov_id,
				cw_customer_stateprov.customer_state_destination,
				cw_countries.country_name,
				cw_countries.country_id

	FROM (((cw_customers
			INNER JOIN cw_customer_stateprov
			ON cw_customers.customer_id = cw_customer_stateprov.customer_state_customer_id)

			INNER JOIN cw_stateprov
			ON cw_stateprov.stateprov_id = cw_customer_stateprov.customer_state_stateprov_id)

			INNER JOIN cw_countries
			ON cw_countries.country_id = cw_stateprov.stateprov_country_id)

		WHERE cw_customer_stateprov.customer_state_destination='BillTo'
		AND #application.cw.sqlLower#(customer_id) = '#lcase(arguments.customer_id)#'
</cfquery>

<cfreturn rsCustomerDetails>
</cffunction>

<!--- // ---------- Select Customer Shipping Details ---------- // --->
<cffunction name="CWquerySelectCustomerShipping" access="public" output="false" returntype="query"
			hint="Returns a query with customer shipping details including address info, state and country">

	<cfargument name="customer_id" required="false" default="" type="string"
				hint="A customer ID, or part of an ID to match">

<cfset var rscustomerShpping = ''>
<cfquery name="rscustomerShpping" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT cw_customers.customer_id,
				cw_customers.customer_type_id,
				cw_customers.customer_first_name,
				cw_customers.customer_last_name,
				cw_customers.customer_ship_name,
				cw_customers.customer_ship_address1,
				cw_customers.customer_ship_address2,
				cw_customers.customer_ship_city,
				cw_customers.customer_ship_zip,
				cw_stateprov.stateprov_name,
				cw_stateprov.stateprov_id,
				cw_customer_stateprov.customer_state_destination,
				cw_countries.country_name,
				cw_countries.country_id

			FROM (((cw_customers
			INNER JOIN cw_customer_stateprov
			ON cw_customers.customer_id = cw_customer_stateprov.customer_state_customer_id)

			INNER JOIN cw_stateprov
			ON cw_stateprov.stateprov_id = cw_customer_stateprov.customer_state_stateprov_id)

			INNER JOIN cw_countries
			ON cw_countries.country_id = cw_stateprov.stateprov_country_id)

		WHERE cw_customer_stateprov.customer_state_destination='ShipTo'
		AND #application.cw.sqlLower#(customer_id) = '#lcase(arguments.customer_id)#'
</cfquery>

<cfreturn rscustomerShpping>
</cffunction>

<!--- // ---------- Select Customer Orders ---------- // --->
<cffunction name="CWquerySelectCustomerOrders" access="public" output="false" returntype="query"
			hint="Returns a query of orders for any given customer">

	<cfargument name="customer_id" required="true" default="0" type="string"
				hint="ID of customer to look up">
	<cfargument name="max_return" required="false" default="0" type="numeric"
				hint="Maximum number of rows to return, sorted by date descending">

<cfset var rsCustOrders = ''>
<cfquery name="rsCustOrders" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT *
FROM cw_orders
WHERE order_customer_id = '#arguments.customer_id#'
ORDER BY order_date DESC
</cfquery>

<cfif arguments.max_return gt 0>
<cfquery dbtype="query" name="rsCustOrders" maxrows="#arguments.max_return#">
SELECT *
FROM rsCustOrders
</cfquery>
</cfif>

<cfreturn rsCustOrders>
</cffunction>

<!--- // ---------- Select Customer Order Details ---------- // --->
<cffunction name="CWquerySelectCustomerOrderDetails" access="public" output="false" returntype="query"
			hint="Returns a query with customer order info">

	<cfargument name="customer_id" required="false" default="" type="string"
				hint="A customer ID, or part of an ID to match">
	<cfargument name="max_return" required="false" default="0" type="numeric"
				hint="Maximum number of rows to return, sorted by date descending">

<cfset var rsCustomerOrderDetails = ''>
<cfquery name="rsCustomerOrderDetails" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT
	cw_orders.order_id,
	cw_orders.order_date,
	cw_orders.order_total,
	cw_order_skus.ordersku_sku,
	cw_skus.sku_merchant_sku_id,
	cw_products.product_name,
	cw_products.product_id
FROM
	cw_products
	INNER JOIN (cw_skus
		INNER JOIN (cw_orders
			INNER JOIN cw_order_skus
			ON cw_orders.order_id = cw_order_skus.ordersku_order_id)
		ON cw_skus.sku_id = cw_order_skus.ordersku_sku)
	ON cw_products.product_id = cw_skus.sku_product_id
WHERE
	cw_orders.order_customer_id = '#arguments.customer_id#'
ORDER BY
	cw_orders.order_date DESC
</cfquery>
<cfif arguments.max_return gt 0>
<cfquery dbtype="query" name="rsCustomerOrderDetails" maxrows="#arguments.max_return#">
SELECT *
FROM rsCustomerOrderDetails
</cfquery>
</cfif>

<cfreturn rsCustomerOrderDetails>
</cffunction>

<!--- // ---------- Select Customer Types ---------- // --->
<cffunction name="CWquerySelectCustomerTypes" access="public" output="false" returntype="query"
			hint="Returns a query with all available customer types">
	
	<cfargument name="count_members" required="false" default="false" type="boolean" 
				hint="if true, only groups with memebers will be returned, along with a count of membership">

	<cfset var rsCustTypes = "">

	<cfquery name="rsCustTypes" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT ct.customer_type_name, ct.customer_type_id
	<cfif arguments.count_members is true>
		, count(cc.customer_id) as customer_type_members
	</cfif> 
	FROM cw_customer_types ct
	<cfif arguments.count_members is true>, cw_customers cc
		WHERE cc.customer_type_id = ct.customer_type_id
		GROUP BY customer_type_name
	</cfif>
	ORDER BY customer_type_name
	</cfquery>

<cfreturn rsCustTypes>
</cffunction>

<!--- // ---------- Get Customer Type Details ---------- // --->
<cffunction name="CWquerySelectCustomerTypeDetails" access="public" output="false" returntype="query"
			hint="Look up customer type details by ID, name or code - at least one argument must match">

	<cfargument name="customer_type_id" required="true" type="numeric"
				hint="ID of the CredCustomer Typelook up - pass in 0 to select all IDs">
	<cfargument name="customer_type_name" required="true" type="string"
				hint="Name of the Customer Type - pass in blank '' to select all names">
	<cfargument name="omit_id_list" required="false" default="0" type="string"
				hint="List of Ids to omit from data">

	<cfset var rsSelectCustomerType = ''>

		<!--- look up customerType --->
		<cfquery name="rsSelectcustomerType" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT *
		FROM cw_customer_types
		WHERE 1 = 1
		<cfif arguments.customer_type_id gt 0>AND customer_type_id = #arguments.customer_type_id#</cfif>
		<cfif len(trim(arguments.customer_type_name))>AND customer_type_name = '#arguments.customer_type_name#'</cfif>
		<cfif arguments.omit_id_list neq 0>
		AND NOT customer_type_id in(#arguments.omit_id_list#)
		</cfif>
		</cfquery>

	<cfreturn rsSelectcustomerType>

</cffunction>

<!--- // ---------- Insert Customer Type ---------- // --->
<cffunction name="CWqueryInsertCustomerType" access="public" output="false" returntype="string"
			hint="Inserts a customer type record - returns new ID or 0- error">

	<!--- Name and code are required --->
	<cfargument name="customer_type_name" required="true" type="string"
				hint="Name of the customer type">

	<cfset var newRecordID = ''>
	<cfset var getNewID = ''>
	<cfset var errorMsg = ''>

<!--- check for duplicates by name  --->
<cfset dupNameCheck = CWquerySelectCustomerTypeDetails(0,arguments.customer_type_name)>
<!--- if we have a duplicate, return an error message --->
<cfif dupNameCheck.recordCount>
<cfset errorMsg = errorMsg & "<br>Customer Type Name '#arguments.customer_type_name#' already exists">
</cfif>

<!--- if no duplicate, insert --->
<cfif not len(trim(errorMsg))>
		<!--- insert record --->
		<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		INSERT INTO cw_customer_types
		(
		customer_type_name
		)
		VALUES
		(
		'#arguments.customer_type_name#'		)
		</cfquery>

		<!--- Get the new ID --->
		<cfquery name="getNewID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT customer_type_id
		FROM cw_customer_types
		WHERE customer_type_name = '#arguments.customer_type_name#'
		</cfquery>

	<cfset newRecordID = getnewID.customer_type_id>

<!--- if we did have a duplicate, return error code --->
<cfelse>
<cfset newRecordID = '0-Error: #errorMsg#'>
</cfif>

<cfreturn newRecordID>

</cffunction>

<!--- // ---------- Update Customer Type ---------- // --->
<cffunction name="CWqueryUpdateCustomerType" access="public" output="false" returntype="string"
			hint="Update a customer type record - returns updated ID or 0- error message">

<!--- id is required --->
		<cfargument name="customer_type_id" type="numeric" required="true"
					hint="ID of the record to update">

<!--- others are optional --->
		<cfargument name="customer_type_name" type="string" required="false" default=""
					hint="Name of the customer type">

<cfset var updatedID = ''>
<cfset var errorMsg = ''>

<!--- name must have some length --->
<cfif not len(trim(arguments.customer_type_name))>
	<cfset errorMsg = 'Customer Type Name must be provided'>
</cfif>

<!--- check for duplicates by name  --->
<cfif not len(trim(errorMsg))>
<cfset dupNameCheck = CWquerySelectCustomerTypeDetails(0,arguments.customer_type_name,arguments.customer_type_id)>
	<!--- if we have a duplicate, return an error message --->
	<cfif dupNameCheck.recordCount>
		<cfset errorMsg = errorMsg & "Customer Type '#arguments.customer_type_name#' already exists">
	</cfif>
</cfif>

<!--- if no duplicate, update --->
<cfif not len(trim(errorMsg))>

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			UPDATE cw_customer_types
			SET customer_type_name = '#arguments.customer_type_name#'
			WHERE customer_type_id = #arguments.customer_type_id#
			</cfquery>
			<cfset updatedID = arguments.customer_type_id>

<!--- if error message, return string --->
<cfelse>
<cfset updatedID  = '0-Error: #errorMsg#'>

</cfif>

<cfreturn updatedID>

</cffunction>

<!--- // ---------- Delete Customer Type ---------- // --->
<cffunction name="CWqueryDeleteCustomerType" access="public" output="false" returntype="void"
			hint="Delete a customer type record">

<cfargument name="customer_type_id" required="true" type="numeric"
			hint="ID of the customer type to delete">

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			DELETE FROM cw_customer_types
			WHERE customer_type_id = #arguments.customer_type_id#
			</cfquery>

</cffunction>

<!--- // ---------- Insert Customer---------- // --->
<cffunction name="CWqueryInsertCustomer" access="public" output="false" returntype="string"
			hint="Inserts a new customer record including billing/shipping - returns ID of the new customer, or 0-message if unsuccessful">

<!--- Type and Name are required --->
	<cfargument name="customer_type_id" default="0" required="true" type="numeric"
				hint="ID of the customer type">
	<cfargument name="customer_firstname" default="0" required="true" type="string"
				hint="First Name of the customer to update">
	<cfargument name="customer_lastname" default="0" required="true" type="string"
				hint="Last Name of the customer to update">

<!--- Others optional, default NULL --->
	<cfargument name="customer_email" default="" required="false" type="string"
				hint="Email Address">
	<cfargument name="customer_username" default="" required="false" type="string"
				hint="username">
	<cfargument name="customer_password" default="" required="false" type="string"
				hint="Password">
	<cfargument name="customer_company" default="" required="false" type="string"
				hint="Company Name">
	<cfargument name="customer_phone" default="" required="false" type="string"
				hint="Phone Number">
	<cfargument name="customer_phone_mobile" default="" required="false" type="string"
				hint="Mobile Phone Number">
	<cfargument name="customer_address1" default="" required="false" type="string"
				hint="Billing Address Line 1">
	<cfargument name="customer_address2" default="" required="false" type="string"
				hint="Billing Address Line 2">
	<cfargument name="customer_city" default="" required="false" type="string"
				hint="Billing City">
	<cfargument name="customer_state" default="0" required="false" type="numeric"
				hint="Billing State">
	<cfargument name="customer_zip" default="" required="false" type="string"
				hint="Billing Postal Code">
	<cfargument name="customer_ship_name" default="" required="false" type="string"
				hint="Shipping Name (Ship To)">
	<cfargument name="customer_ship_company" default="" required="false" type="string"
				hint="Shipping Company (Ship To)">
	<cfargument name="customer_ship_address1" default="" required="false" type="string"
				hint="Shipping Address Line 1">
	<cfargument name="customer_ship_address2" default="" required="false" type="string"
				hint="Shipping Address Line 2">
	<cfargument name="customer_ship_city" default="" required="false" type="string"
				hint="Shipping City">
	<cfargument name="customer_ship_state" default="0" required="false" type="numeric"
				hint="Shipping State">
	<cfargument name="customer_ship_zip" default="" required="false" type="string"
				hint="Shipping Postal Code">

	<!--- make sure email and username are unique --->
	<cfset var checkDupEmail = "">
	<cfset var checkDupusername = "">
	<cfset var newUUID = CreateUUID()>
	<cfset var newCustID = ''>

	<cfquery name="checkDupEmail" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT customer_email
	FROM cw_customers
	WHERE customer_email = '#trim(arguments.customer_email)#'
	AND NOT customer_guest = 1
	</cfquery>

	<!--- if we have a dup, stop and return a message --->
	<cfif checkDupEmail.recordCount and application.cw.customerAccountRequired>
	<cfset newCustID = '0-Email'>

	<!--- if no dup email, contine --->
	<cfelse>
	<cfquery name="checkDupusername" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT customer_username
	FROM cw_customers
	WHERE customer_username = '#trim(arguments.customer_username)#'
	AND NOT customer_guest = 1
	</cfquery>

	<!--- if we have a dup, stop and return a message --->
	<cfif checkDupusername.recordCount and application.cw.customerAccountRequired>
	<cfset newCustID = '0-username'>

	<!--- if no dup username, contine --->
	<cfelse>

	<cfset newCustID = Left(newUUID,6)&LSdateFormat(CWtime(),'-yymmdd')>

	<!--- insert main customer record --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_customers
	(
	customer_id
	,customer_type_id
	,customer_first_name
	,customer_last_name
	,customer_email
	,customer_username
	,customer_password
	,customer_company
	,customer_address1
	,customer_address2
	,customer_city
	,customer_zip
	,customer_ship_name
	,customer_ship_company
	,customer_ship_address1
	,customer_ship_address2
	,customer_ship_city
	,customer_ship_zip
	,customer_phone
	,customer_phone_mobile
	,customer_date_modified
	,customer_date_added
	)
	VALUES
	(
	'#newCustID#'
	,#arguments.customer_type_id#
	,'#arguments.customer_firstname#'
	,'#arguments.customer_lastname#'
	,	<cfif len(trim(arguments.customer_email))>'#arguments.customer_email#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_username))>'#arguments.customer_username#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_password))>'#arguments.customer_password#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_company))>'#arguments.customer_company#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_address1))>'#arguments.customer_address1#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_address2))>'#arguments.customer_address2#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_city))>'#arguments.customer_city#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_zip))>'#arguments.customer_zip#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_ship_name))>'#arguments.customer_ship_name#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_ship_company))>'#arguments.customer_ship_company#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_ship_address1))>'#arguments.customer_ship_address1#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_ship_address2))>'#arguments.customer_ship_address2#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_ship_city))>'#arguments.customer_ship_city#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_ship_zip))>'#arguments.customer_ship_zip#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_phone))>'#arguments.customer_phone#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_phone_mobile))>'#arguments.customer_phone_mobile#'<cfelse>NULL</cfif>
	, #createODBCDateTime(CWtime())#
	, #createODBCDateTime(CWtime())#
	)
	</cfquery>

	<!--- Insert Billing state --->
	<cfif arguments.customer_ship_state gt 0>
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_customer_stateprov
	(
	customer_state_customer_id,
	customer_state_stateprov_id,
	customer_state_destination
	)
	VALUES
	(
	'#newCustID#',
	#arguments.customer_state#,
	'BillTo'
	)
	</cfquery>
	</cfif>

	<!--- Insert Shipping State --->
	<cfif arguments.customer_state gt 0>
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_customer_stateprov
	(
	customer_state_customer_id,
	customer_state_stateprov_id,
	customer_state_destination
	)
	VALUES
	(
	'#newCustID#',
	#arguments.customer_state#,
	'ShipTo'
	)
	</cfquery>
	</cfif>


	</cfif>
	<!--- /END check username dup --->
	</cfif>
	<!--- /END check email dup --->

<!--- pass back the ID of the new customer, or error 0 message --->
	<cfreturn newCustID>
</cffunction>

<!--- // ---------- Update Customer---------- // --->
<cffunction name="CWqueryUpdateCustomer" access="public" output="false" returntype="string"
			hint="Updates a customer record - returns ID of the customer, or 0-message if unsuccessful">

<!--- ID and Name are required --->
	<cfargument name="customer_id" default="0" required="true" type="string"
				hint="ID of the customer to update">
	<cfargument name="customer_type_id" default="0" required="true" type="numeric"
				hint="ID of the customer type">
	<cfargument name="customer_firstname" default="0" required="true" type="string"
				hint="First Name of the customer to update">
	<cfargument name="customer_lastname" default="0" required="true" type="string"
				hint="Last Name of the customer to update">

<!--- Others optional, default NULL --->
	<cfargument name="customer_email" default="" required="false" type="string"
				hint="Email Address">
	<cfargument name="customer_username" default="" required="false" type="string"
				hint="username">
	<cfargument name="customer_password" default="" required="false" type="string"
				hint="Password">
	<cfargument name="customer_company" default="" required="false" type="string"
			hint="Company Name">
	<cfargument name="customer_phone" default="" required="false" type="string"
				hint="Phone Number">
	<cfargument name="customer_phone_mobile" default="" required="false" type="string"
				hint="Mobile Phone Number">
	<cfargument name="customer_address1" default="" required="false" type="string"
				hint="Billing Address Line 1">
	<cfargument name="customer_address2" default="" required="false" type="string"
				hint="Billing Address Line 2">
	<cfargument name="customer_city" default="" required="false" type="string"
				hint="Billing City">
	<cfargument name="customer_state" default="0" required="false" type="numeric"
				hint="Billing State">
	<cfargument name="customer_zip" default="" required="false" type="string"
				hint="Billing Postal Code">
	<cfargument name="customer_ship_name" default="" required="false" type="string"
				hint="Shipping Name (Ship To)">
	<cfargument name="customer_ship_company" default="" required="false" type="string"
				hint="Shipping Company (Ship To)">
	<cfargument name="customer_ship_address1" default="" required="false" type="string"
				hint="Shipping Address Line 1">
	<cfargument name="customer_ship_address2" default="" required="false" type="string"
				hint="Shipping Address Line 2">
	<cfargument name="customer_ship_city" default="" required="false" type="string"
				hint="Shipping City">
	<cfargument name="customer_ship_state" default="0" required="false" type="numeric"
				hint="Shipping State">
	<cfargument name="customer_ship_zip" default="" required="false" type="string"
				hint="Shipping Postal Code">

	<cfset var checkDupEmail = ''>
	<cfset var checkDupusername = ''>
	<cfset var updateCustID = ''>

	<!--- verify email and username are unique --->
	<!--- check email --->
	<cfif len(trim(arguments.customer_email)) and application.cw.customerAccountRequired>
	<cfquery name="checkDupEmail" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT customer_email
	FROM cw_customers
	WHERE customer_email = '#trim(arguments.customer_email)#'
	AND NOT customer_id='#arguments.customer_id#'
	AND NOT customer_guest = 1
	</cfquery>

	<!--- if we have a dup, return a message --->
	<cfif checkDupEmail.recordCount>
	<cfset updateCustID = '0-Email'>
	</cfif>
	</cfif>

	<!--- check username --->
	<cfif len(trim(arguments.customer_username)) and application.cw.customerAccountRequired>
	<cfquery name="checkDupusername" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT customer_username
	FROM cw_customers
	WHERE customer_username = '#trim(arguments.customer_username)#'
	AND NOT customer_id='#arguments.customer_id#'
	AND NOT customer_guest = 1
	</cfquery>

	<!--- if we have a dup, return a message --->
	<cfif checkDupusername.recordCount>
	<cfset updateCustID = '0-username'>
	</cfif>
	</cfif>

	<!--- if no duplicates --->
	<cfif not left(updateCustID,2) eq '0-'>
	<!--- update main customer record --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	UPDATE cw_customers SET
	customer_type_id = #arguments.customer_type_id#
	,customer_first_name = '#arguments.customer_firstname#'
	, customer_last_name = '#arguments.customer_lastname#'
	, customer_email=
	<cfif len(trim(arguments.customer_email))>'#arguments.customer_email#'<cfelse>NULL</cfif>
	, customer_username=
	<cfif len(trim(arguments.customer_username))>'#arguments.customer_username#'<cfelse>NULL</cfif>
	, customer_password=
	<cfif len(trim(arguments.customer_password))>'#arguments.customer_password#'<cfelse>NULL</cfif>
	, customer_company=
	<cfif len(trim(arguments.customer_company))>'#arguments.customer_company#'<cfelse>NULL</cfif>
	, customer_address1=
	<cfif len(trim(arguments.customer_address1))>'#arguments.customer_address1#'<cfelse>NULL</cfif>
	, customer_address2=
	<cfif len(trim(arguments.customer_address2))>'#arguments.customer_address2#'<cfelse>NULL</cfif>
	, customer_city=
	<cfif len(trim(arguments.customer_city))>'#arguments.customer_city#'<cfelse>NULL</cfif>
	, customer_zip=
	<cfif len(trim(arguments.customer_zip))>'#arguments.customer_zip#'<cfelse>NULL</cfif>
	, customer_ship_address1=
	<cfif len(trim(arguments.customer_ship_address1))>'#arguments.customer_ship_address1#'<cfelse>NULL</cfif>
	, customer_ship_company=
	<cfif len(trim(arguments.customer_ship_company))>'#arguments.customer_ship_company#'<cfelse>NULL</cfif>
	, customer_ship_name=
	<cfif len(trim(arguments.customer_ship_name))>'#arguments.customer_ship_name#'<cfelse>NULL</cfif>
	, customer_ship_address2=
	<cfif len(trim(arguments.customer_ship_address2))>'#arguments.customer_ship_address2#'<cfelse>NULL</cfif>
	, customer_ship_city=
	<cfif len(trim(arguments.customer_ship_city))>'#arguments.customer_ship_city#'<cfelse>NULL</cfif>
	, customer_ship_zip=
	<cfif len(trim(arguments.customer_ship_zip))>'#arguments.customer_ship_zip#'<cfelse>NULL</cfif>
	, customer_phone=
	<cfif len(trim(arguments.customer_phone))>'#arguments.customer_phone#'<cfelse>NULL</cfif>
	, customer_phone_mobile=
	<cfif len(trim(arguments.customer_phone_mobile))>'#arguments.customer_phone_mobile#'<cfelse>NULL</cfif>
	, customer_date_modified = #createODBCDateTime(CWtime())#
	WHERE customer_id='#arguments.customer_id#'
	</cfquery>

	<!--- Update Billing state --->
	<cfif arguments.customer_state gt 0>
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	UPDATE cw_customer_stateprov SET
	customer_state_stateprov_id = #arguments.customer_state#
	WHERE customer_state_customer_id = '#arguments.customer_id#' AND customer_state_destination = 'BillTo'
	</cfquery>
	</cfif>

	<!--- Update Shipping State --->
	<cfif arguments.customer_ship_state gt 0>
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	UPDATE cw_customer_stateprov SET
	customer_state_stateprov_id = #arguments.customer_ship_state#
	WHERE customer_state_customer_id = '#arguments.customer_id#' AND customer_state_destination = 'ShipTo'
	</cfquery>
	</cfif>

	<cfset updateCustID = arguments.customer_id>
	</cfif>
	<!--- /END check dups --->

<cfreturn updateCustId>
</cffunction>

<!--- // ---------- Delete Customer ---------- // --->
<cffunction name="CWqueryDeleteCustomer" access="public" output="false" returntype="void"
			hint="Delete a customer and associated address info">

	<cfargument name="customer_id" required="true" type="string"
				hint="ID of the customer to delete">
	<!--- delete customer state relationships --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_customer_stateprov WHERE customer_state_customer_id = '#arguments.customer_id#'
	</cfquery>
	<!--- delete customer --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_customers WHERE customer_id='#arguments.customer_id#'
	</cfquery>

</cffunction>

<!--- // ---------- Select Top Customers ---------- // --->
<cffunction name="CWquerySelectTopCustomers" access="public" output="false" returntype="query"
			hint="Returns a query with customers and total order amounts">

	<cfargument name="show_ct" required="false" default="0" type="numeric"
				hint="The number of customer records to return">

<cfset var rsTopCustomers = ''>
<cfset var columnList = ''>
<cfset var columnTypeList = ''>
<cfset var customerGroupQuery = ''>
<cfset var tempTotal = ''>
<cfset var tempVal = ''>
<cfset var temp = ''>
<cfset var maxRows = 1000>

<cfif arguments.show_ct gt 0>
	<cfset maxRows = arguments.show_ct>
</cfif>

<cfquery name="rsTopCustomers" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		 SELECT <cfif application.cw.appDbType is not 'mysql' and maxrows gt 0> TOP #maxRows# </cfif>
		 		cw_customers.customer_id,
				cw_customers.customer_first_name,
				cw_customers.customer_last_name,
				cw_customers.customer_email,
				cw_orders.order_id,
				cw_orders.order_total,
				MAX(order_date) as top_order_date,
				SUM(order_total) as total_spending
				FROM
				cw_customers
				, cw_orders
				WHERE cw_orders.order_customer_id = cw_customers.customer_id
			 GROUP BY
				cw_customers.customer_id,
				cw_customers.customer_first_name,
				cw_customers.customer_last_name,
				cw_customers.customer_email,
				cw_orders.order_id,
				cw_orders.order_total
				ORDER BY customer_id, SUM(order_total) DESC
				<cfif application.cw.appDbType is 'mysql' and maxrows gt 0> LIMIT #maxRows# </cfif>
</cfquery>

<!--- group by ID into new query --->
<cfset columnList = "customer_email,
						customer_first_name,
						customer_id,
						customer_last_name,
						order_id,
						order_total,
						top_order_date,
						total_spending
							">
<cfset columnTypeList = "varchar,
						varchar,
						varchar,
						varchar,
						varchar,
						decimal,
						date,
						decimal
							">

<cfset customerGroupQuery = queryNew("#columnList#","#columnTypeList#")>
<cfoutput query="rsTopCustomers" group="customer_id">
<cfset tempTotal = 0>
<cfset tempVal = ''>

<!--- total the grouped order values --->
<cfoutput>
<cfset tempTotal = tempTotal + total_spending>
</cfoutput>
<cfset queryAddRow(customerGroupQuery)>
<cfloop list="#columnList#" index="cc">
	<cfif trim(cc) eq 'total_spending'>
	<cfset tempVal = "tempTotal">
	<cfelse>
	<cfset tempVal = 'rsTopCustomers.#trim(cc)#'>
	</cfif>
<cfset temp = querySetCell(customerGroupQuery,"#trim(cc)#","#evaluate(trim(tempVal))#")>
</cfloop>
</cfoutput>

<!--- query of query to sort --->
<cfquery dbtype="query" name="rsTopCustomers" maxrows="#maxRows#">
SELECT *
FROM customerGroupQuery
ORDER BY total_spending DESC
</cfquery>

<cfreturn rsTopCustomers>
</cffunction>

<!--- //////////////// --->
<!--- DISCOUNT QUERIES --->
<!--- //////////////// --->

<!--- // ---------- Select Discount Types ---------- // --->
<cffunction name="CWquerySelectDiscountTypes" access="public" returntype="query" output="false"
			hint="Returns a query of discount types">

			<cfargument name="show_archived" required="false" default="false" type="boolean"
						hint="If set to true, archive flag is ignored, all types returned">

			<cfset var rsGetTypes = ''>
			<cfquery name="rsGetTypes" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			SELECT discount_type,
			discount_type_description,
			discount_type_archive
			FROM cw_discount_types
			<cfif NOT arguments.show_archived>
				WHERE NOT discount_type_archive = 1
			</cfif>
			ORDER BY discount_type_order
			</cfquery>

<cfreturn rsGetTypes>
</cffunction>

<!--- // ---------- Get ALL active or archived discounts ---------- // --->
<cffunction name="CWquerySelectStatusDiscounts" access="public" output="false" returntype="query"
			hint="Returns all active or archived discounts">

<cfargument name="discounts_active" default="1" type="numeric" required="false"
			hint="Set to 0 to return archived discounts">

	<cfset var compareTo = 1>
	<cfset var rsStatusDiscounts = "">

<!--- set up opposite value so we can query with 'not' --->
<cfif arguments.discounts_active is 1>
	<cfset compareTo = 0>
</cfif>

<cfquery name="rsStatusDiscounts" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT discount_id,
	dd.discount_merchant_id,
	dd.discount_name,
	dd.discount_description,
	dd.discount_promotional_code,
	dd.discount_calc,
	dd.discount_amount,
	dd.discount_type,
	dd.discount_start_date,
	dd.discount_end_date,
	dd.discount_limit,
	dd.discount_customer_limit,
	dd.discount_global,
	dd.discount_exclusive,
	dd.discount_priority,
	dd.discount_archive,
	dd.discount_show_description,
	dd.discount_filter_customer_type,
	dd.discount_customer_type,
	dd.discount_filter_customer_id,
	dd.discount_customer_id,
	dd.discount_filter_cart_total,
	dd.discount_cart_total_max,
	dd.discount_cart_total_min,
	dd.discount_filter_item_qty,
	dd.discount_item_qty_min,
	dd.discount_item_qty_max,
	dd.discount_filter_cart_qty,
	dd.discount_cart_qty_min,
	dd.discount_cart_qty_max,
	dd.discount_association_method,
	dt.discount_type_description
	FROM cw_discounts dd, cw_discount_types dt
	WHERE dd.discount_type = dt.discount_type
	AND NOT dd.discount_archive = #compareTo#
</cfquery>
<cfreturn rsStatusDiscounts>
</cffunction>

<!--- // ---------- Select Discounts by ID ---------- // --->
<cffunction name="CWquerySelectDiscounts" access="public" returntype="query" output="false"
			hint="Returns a query of discount details based on a list of discount IDs">

			<cfargument name="id_list" required="false" type="string" default=""
						hint="A comma separated list of discount IDs to look up - if not provided, all discounts are returned">

			<cfset var rsGetDiscounts = ''>
			<cfquery name="rsGetDiscounts" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			SELECT discount_id,
			discount_merchant_id,
			discount_name,
			discount_description,
			discount_promotional_code,
			discount_calc,
			discount_amount,
			discount_type,
			discount_start_date,
			discount_end_date,
			discount_limit,
			discount_customer_limit,
			discount_global,
			discount_exclusive,
			discount_priority,
			discount_archive,
			discount_show_description,
			discount_filter_customer_type,
			discount_customer_type,
			discount_filter_customer_id,
			discount_customer_id,
			discount_filter_cart_total,
			discount_cart_total_max,
			discount_cart_total_min,
			discount_filter_item_qty,
			discount_item_qty_min,
			discount_item_qty_max,
			discount_filter_cart_qty,
			discount_cart_qty_min,
			discount_cart_qty_max,
			discount_association_method
			FROM cw_discounts
			<cfif len(trim(arguments.id_list))>
				WHERE discount_id IN (#arguments.id_list#)
			</cfif>
			</cfquery>

<cfreturn rsGetDiscounts>
</cffunction>

<!--- // ---------- Select Discount Order Details ---------- // --->
<cffunction name="CWquerySelectDiscountOrderDetails" access="public" returntype="query" output="false"
			hint="Returns a query of order ids and other details, based on a discount ID">

			<cfargument name="discount_id" required="true" type="numeric"
						hint="The ID to look up">

			<cfargument name="max_records" required="false" default="100" type="numeric"
						hint="the maximum number of records to return">

			<cfargument name="order_by" required="false" default="" type="string"
						hint="the column the results are sorted by (optional: desc|asc)">

			<cfset var rsGetDiscountOrders = ''>
			<cfquery name="rsGetDiscountOrders" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#" maxrows="#arguments.max_records#">
			SELECT uu.discount_usage_order_id,
			uu.discount_usage_customer_id,
			uu.discount_usage_datetime,
			cc.customer_first_name,
			cc.customer_last_name
			FROM cw_discount_usage uu, cw_customers cc
			WHERE uu.discount_usage_discount_id = #arguments.discount_id#
			AND uu.discount_usage_customer_id = cc.customer_id
			<cfif len(trim(arguments.order_by))>
				ORDER BY #arguments.order_by#
			<cfelse>
				ORDER BY discount_usage_datetime desc
			</cfif>
			</cfquery>

<cfreturn rsGetDiscountOrders>
</cffunction>

<!--- // ---------- Insert Discount ---------- // --->
<cffunction name="CWqueryInsertDiscount" access="public" output="false" returntype="string"
			hint="Inserts a discount record - returns ID of the discount, or 0-message if unsuccessful">

	<!--- required values --->
	<cfargument name="discount_merchant_id" required="true" type="string"
				hint="Merchant discount name / reference id">

	<cfargument name="discount_name" required="true" type="string"
				hint="Merchant name">

	<cfargument name="discount_amount" required="true" type="numeric"
				hint="Amount of the discount">

	<cfargument name="discount_calc" required="true" type="string"
				hint="Calculation type">

	<!--- other fields are optional --->
	<cfargument name="discount_description" required="false" default="" type="string"
				hint="Tesxt message shown at checkout">

	<cfargument name="discount_show_description" required="false" default="0" type="numeric"
				hint="Limit uses of this discount for any one customer">

	<cfargument name="discount_type" required="false" default="" type="string"
				hint="Text message shown at checkout">

	<cfargument name="discount_promotional_code" required="false" default="" type="string"
				hint="Promo code to activate discount">

	<cfargument name="discount_start_date" required="false" default="" type="string"
				hint="Start Date">

	<cfargument name="discount_end_date" required="false" default="" type="string"
				hint="End Date">

	<cfargument name="discount_limit" required="false" default="0" type="numeric"
				hint="Limit total uses of this discount">

	<cfargument name="discount_customer_limit" required="false" default="0" type="numeric"
				hint="Limit uses of this discount for any one customer">

	<cfargument name="discount_global" required="false" default="0" type="numeric"
				hint="Apply to all products yes/n">

	<cfargument name="discount_exclusive" required="false" default="0" type="numeric"
				hint="Allow multiple discounts y/n">

	<cfargument name="discount_priority" required="false" default="0" type="numeric"
				hint="If exclusive, used to determine applied discount">

	<cfargument name="discount_archive" required="false" default="0" type="numeric"
				hint="Archived yes/no">

	<cfset var checkDupMerchID = ''>
	<cfset var checkDupPromoCode = ''>
	<cfset var insertDiscID = ''>
	<cfset var getnewDiscID = ''>

	<!--- verify merchant ID is unique --->
	<cfif len(trim(arguments.discount_merchant_id))>
		<cfquery name="checkDupMerchID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT discount_merchant_id
		FROM cw_discounts
		WHERE discount_merchant_id = '#trim(arguments.discount_merchant_id)#'
		AND NOT discount_id='#arguments.discount_id#'
		</cfquery>

		<!--- if we have a dup, return a message --->
		<cfif checkDupMerchID.recordCount>
		<cfset insertDiscID = '0-Merchant ID'>
		</cfif>
	</cfif>
	<!--- verify promocode is unique --->
	<cfif len(trim(arguments.discount_promotional_code))>
		<cfquery name="checkDupPromoCode" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT discount_promotional_code
		FROM cw_discounts
		WHERE discount_promotional_code = '#trim(arguments.discount_promotional_code)#'
		AND NOT discount_id='#arguments.discount_id#'
		</cfquery>

		<!--- if we have a dup, return a message --->
		<cfif checkDupPromoCode.recordCount>
		<cfset insertDiscID = '0-Promo Code'>
		</cfif>
	</cfif>

<!--- if no duplicates --->
	<cfif not left(insertDiscID,2) eq '0-'>
	<!--- insert discount record --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_discounts
	(
	 discount_merchant_id
	,discount_name
	,discount_amount
	,discount_calc
	,discount_description
	,discount_show_description
	,discount_type
	,discount_promotional_code
	,discount_start_date
	,discount_end_date
	,discount_limit
	,discount_customer_limit
	,discount_global
	,discount_exclusive
	,discount_priority
	,discount_archive
	,discount_association_method
	)
	VALUES
	(
	'#arguments.discount_merchant_id#'
	,'#arguments.discount_name#'
	,#arguments.discount_amount#
	,'#arguments.discount_calc#'
	,<cfif len(trim(arguments.discount_description))>'#arguments.discount_description#'<cfelse>NULL</cfif>
	,<cfif len(trim(arguments.discount_show_description))>#arguments.discount_show_description#<cfelse>1</cfif>
	,<cfif len(trim(arguments.discount_type))>'#arguments.discount_type#'<cfelse>NULL</cfif>
	,<cfif len(trim(arguments.discount_promotional_code))>'#arguments.discount_promotional_code#'<cfelse>NULL</cfif>
	,<cfif len(trim(arguments.discount_start_date))>'#dateFormat(lsParseDateTime(arguments.discount_start_date),'yyyy-mm-dd')#'<cfelse>NULL</cfif>
	,<cfif len(trim(arguments.discount_end_date))>'#dateFormat(lsParseDateTime(arguments.discount_end_date),'yyyy-mm-dd')#'<cfelse>NULL</cfif>
	,<cfif len(trim(arguments.discount_limit))>#arguments.discount_limit#<cfelse>1</cfif>
	,<cfif len(trim(arguments.discount_customer_limit))>#arguments.discount_customer_limit#<cfelse>1</cfif>
	,<cfif len(trim(arguments.discount_global))>#arguments.discount_global#<cfelse>1</cfif>
	,<cfif len(trim(arguments.discount_exclusive))>#arguments.discount_exclusive#<cfelse>0</cfif>
	,<cfif len(trim(arguments.discount_priority))>#arguments.discount_priority#<cfelse>1</cfif>
	,<cfif len(trim(arguments.discount_archive))>#arguments.discount_archive#<cfelse>1</cfif>
	,'products'
	)
	</cfquery>

	<!--- get ID for return value --->
	<cfquery name="getNewDiscID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT discount_id
	FROM cw_discounts
	WHERE discount_merchant_id = '#trim(arguments.discount_merchant_id)#'
	</cfquery>

	<cfset insertDiscID = getNewDiscID.discount_id>
	</cfif>

		<!--- clear stored discount data from memory --->
		<cftry>
		<cfset structClear(application.cw.discountData)>
		<cfcatch></cfcatch>
		</cftry>

	<cfreturn insertDiscID>

</cffunction>

<!--- // ---------- Update Discount (includes filtering data) ---------- // --->
<cffunction name="CWqueryUpdateDiscount" access="public" output="false" returntype="string"
			hint="Updates a discount record - returns ID of the discount, or 0-message if unsuccessful">

	<!--- required values --->
	<cfargument name="discount_id" required="true" type="numeric"
				hint="ID of the discount to update">

	<cfargument name="discount_merchant_id" required="true" type="string"
				hint="Merchant discount name / reference id">

	<cfargument name="discount_name" required="true" type="string"
				hint="Merchant name">

	<cfargument name="discount_amount" required="true" type="numeric"
				hint="Amount of the discount">

	<cfargument name="discount_calc" required="true" type="string"
				hint="Calculation type">

	<!--- other fields are optional --->
	<cfargument name="discount_description" required="false" default="" type="string"
				hint="Tesxt message shown at checkout">

	<cfargument name="discount_show_description" required="false" default="0" type="numeric"
				hint="Limit uses of this discount for any one customer">

	<cfargument name="discount_type" required="false" default="" type="string"
				hint="Text message shown at checkout">

	<cfargument name="discount_promotional_code" required="false" default="" type="string"
				hint="Promo code to activate discount">

	<cfargument name="discount_start_date" required="false" default="" type="string"
				hint="Start Date">

	<cfargument name="discount_end_date" required="false" default="" type="string"
				hint="End Date">

	<cfargument name="discount_limit" required="false" default="0" type="numeric"
				hint="Limit total uses of this discount">

	<cfargument name="discount_customer_limit" required="false" default="0" type="numeric"
				hint="Limit uses of this discount for any one customer">

	<cfargument name="discount_global" required="false" default="0" type="numeric"
				hint="Apply to all products yes/n">

	<cfargument name="discount_exclusive" required="false" default="0" type="numeric"
				hint="Allow multiple discounts y/n">

	<cfargument name="discount_priority" required="false" default="0" type="numeric"
				hint="If exclusive, used to determine applied discount">

	<cfargument name="discount_archive" required="false" default="0" type="numeric"
				hint="Archived yes/no">

	<cfargument name="discount_association_method" required="false" default="" type="string"
				hint="type of product association, if any, used by this discount">

		<!--- filtering arguments --->
		<cfargument name="discount_filter_customer_type" required="false" default="0" type="numeric">
		<cfargument name="discount_customer_type" required="false" default="" type="string">
		<cfargument name="discount_filter_customer_id" required="false" default="0" type="numeric">
		<cfargument name="discount_customer_id" required="false" default="" type="string">
		<cfargument name="discount_filter_cart_total" required="false" default="0" type="numeric">
		<cfargument name="discount_cart_total_max" required="false" default="0" type="numeric">
		<cfargument name="discount_cart_total_min" required="false" default="0" type="numeric">
		<cfargument name="discount_filter_item_qty" required="false" default="0" type="numeric">
		<cfargument name="discount_item_qty_min" required="false" default="0" type="numeric">
		<cfargument name="discount_item_qty_max" required="false" default="0" type="numeric">
		<cfargument name="discount_filter_cart_qty" required="false" default="0" type="numeric">
		<cfargument name="discount_cart_qty_min" required="false" default="0" type="numeric">
		<cfargument name="discount_cart_qty_max" required="false" default="0" type="numeric">


	<cfset var checkDupMerchID = ''>
	<cfset var checkDupPromoCode = ''>
	<cfset var updateDiscID = ''>

	<!--- verify merchant ID is unique --->
	<cfif len(trim(arguments.discount_merchant_id))>
		<cfquery name="checkDupMerchID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT discount_merchant_id
		FROM cw_discounts
		WHERE discount_merchant_id = '#trim(arguments.discount_merchant_id)#'
		AND NOT discount_id='#arguments.discount_id#'
		</cfquery>

		<!--- if we have a dup, return a message --->
		<cfif checkDupMerchID.recordCount>
		<cfset updateDiscID = '0-Merchant ID'>
		</cfif>
	</cfif>
	<!--- verify promocode is unique --->
	<cfif len(trim(arguments.discount_promotional_code))>
		<cfquery name="checkDupPromoCode" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT discount_promotional_code
		FROM cw_discounts
		WHERE discount_promotional_code = '#trim(arguments.discount_promotional_code)#'
		AND NOT discount_id='#arguments.discount_id#'
		</cfquery>

		<!--- if we have a dup, return a message --->
		<cfif checkDupPromoCode.recordCount>
		<cfset updateDiscID = '0-Promo Code'>
		</cfif>
	</cfif>

<!--- if no duplicates --->
	<cfif not left(updateDiscID,2) eq '0-'>
	<!--- update main discount record --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	UPDATE cw_discounts SET
	discount_merchant_id = '#arguments.discount_merchant_id#'
	,discount_name = '#arguments.discount_name#'
	,discount_amount = #arguments.discount_amount#
	,discount_calc = '#arguments.discount_calc#'
	,discount_description=
	<cfif len(trim(arguments.discount_description))>'#arguments.discount_description#'<cfelse>NULL</cfif>
	,discount_show_description=
	<cfif len(trim(arguments.discount_show_description))>#arguments.discount_show_description#<cfelse>1</cfif>
	,discount_type=
	<cfif len(trim(arguments.discount_type))>'#arguments.discount_type#'<cfelse>NULL</cfif>
	,discount_promotional_code=
	<cfif len(trim(arguments.discount_promotional_code))>'#arguments.discount_promotional_code#'<cfelse>NULL</cfif>
	,discount_start_date=
	<cfif len(trim(arguments.discount_start_date))>'#dateFormat(lsParseDateTime(arguments.discount_start_date),'yyyy-mm-dd')#'<cfelse>NULL</cfif>
	,discount_end_date=
	<cfif len(trim(arguments.discount_end_date))>'#dateFormat(lsParseDateTime(arguments.discount_end_date),'yyyy-mm-dd')#'<cfelse>NULL</cfif>
	,discount_limit=
	<cfif len(trim(arguments.discount_limit))>#arguments.discount_limit#<cfelse>1</cfif>
	,discount_customer_limit=
	<cfif len(trim(arguments.discount_customer_limit))>#arguments.discount_customer_limit#<cfelse>1</cfif>
	,discount_global=
	<cfif len(trim(arguments.discount_global))>#arguments.discount_global#<cfelse>1</cfif>
	,discount_exclusive=
	<cfif len(trim(arguments.discount_exclusive))>#arguments.discount_exclusive#<cfelse>0</cfif>
	,discount_priority=
	<cfif len(trim(arguments.discount_priority))>#arguments.discount_priority#<cfelse>1</cfif>
	,discount_archive=
	<cfif len(trim(arguments.discount_archive))>#arguments.discount_archive#<cfelse>1</cfif>
	<!--- filtering conditions --->
	,discount_filter_customer_type=
	<cfif len(trim(arguments.discount_filter_customer_type))>#arguments.discount_filter_customer_type#<cfelse>0</cfif>
	,discount_customer_type=
	<cfif len(trim(arguments.discount_customer_type))>'#trim(replace(arguments.discount_customer_type,' ','','all'))#'<cfelse>NULL</cfif>
	,discount_filter_customer_id=
	<cfif len(trim(arguments.discount_filter_customer_id))>#arguments.discount_filter_customer_id#<cfelse>0</cfif>
	,discount_customer_id=
	<cfif len(trim(arguments.discount_customer_id))>'#trim(replace(arguments.discount_customer_id,' ','','all'))#'<cfelse>NULL</cfif>
	,discount_filter_cart_total=
	<cfif len(trim(arguments.discount_filter_cart_total))>#arguments.discount_filter_cart_total#<cfelse>0</cfif>
	,discount_cart_total_max=
	<cfif len(trim(arguments.discount_cart_total_max))>#arguments.discount_cart_total_max#<cfelse>0</cfif>
	,discount_cart_total_min=
	<cfif len(trim(arguments.discount_cart_total_min))>#arguments.discount_cart_total_min#<cfelse>0</cfif>
	,discount_filter_item_qty=
	<cfif len(trim(arguments.discount_filter_item_qty))>#arguments.discount_filter_item_qty#<cfelse>0</cfif>
	,discount_item_qty_min=
	<cfif len(trim(arguments.discount_item_qty_min))>#arguments.discount_item_qty_min#<cfelse>0</cfif>
	,discount_item_qty_max=
	<cfif len(trim(arguments.discount_item_qty_max))>#arguments.discount_item_qty_max#<cfelse>0</cfif>
	,discount_filter_cart_qty=
	<cfif len(trim(arguments.discount_filter_cart_qty))>#arguments.discount_filter_cart_qty#<cfelse>0</cfif>
	,discount_cart_qty_min=
	<cfif len(trim(arguments.discount_cart_qty_min))>#arguments.discount_cart_qty_min#<cfelse>0</cfif>
	,discount_cart_qty_max=
	<cfif len(trim(arguments.discount_cart_qty_max))>#arguments.discount_cart_qty_max#<cfelse>0</cfif>
	<!--- only update method if value is provided --->
	<cfif len(trim(arguments.discount_association_method)) AND arguments.discount_global neq 1>
		,discount_association_method=#arguments.discount_association_method#
	</cfif>
	WHERE discount_id=#arguments.discount_id#
	</cfquery>

	<cfset updateDiscID = arguments.discount_id>
	</cfif>

		<!--- clear stored discount data from memory --->
		<cftry>
		<cfset structClear(application.cw.discountData)>
		<cfcatch></cfcatch>
		</cftry>

	<cfreturn updateDiscID>

</cffunction>

<!--- // ---------- Update Discount Association Method ---------- // --->
<cffunction name="CWqueryUpdateDiscountAssociationMethod" access="public" output="false" returntype="void"
			hint="Updates a discount record - returns ID of the discount, or 0-message if unsuccessful">

	<!--- required values --->
	<cfargument name="discount_id" required="true" type="numeric"
				hint="ID of the discount to update">

	<cfargument name="discount_association_method" required="true" type="string"
				hint="The name of the method">

	<cfset var updateMethod = ''>

	<cfif len(trim(arguments.discount_association_method))>
		<cfquery name="updateMethod" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		UPDATE cw_discounts
		SET discount_association_method = '#trim(arguments.discount_association_method)#'
		WHERE discount_id='#arguments.discount_id#'
		</cfquery>
	</cfif>

		<!--- clear stored discount data from memory --->
		<cftry>
		<cfset structClear(application.cw.discountData)>
		<cfcatch></cfcatch>
		</cftry>

</cffunction>

<!--- // ---------- Delete Discount ---------- // --->
<cffunction name="CWqueryDeleteDiscount" access="public" output="false" returntype="void"
			hint="Delete a discount and all associated records">

	<cfargument name="discount_id" required="true" type="numeric"
				hint="ID of the discount to delete">

	<!--- delete relative product records --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_discount_products WHERE discount2product_discount_id = #arguments.discount_id#
	</cfquery>

	<!--- delete relative sku records --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_discount_skus WHERE discount2sku_discount_id = #arguments.discount_id#
	</cfquery>

	<!--- delete relative category records --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_discount_categories WHERE discount2category_category_id = #arguments.discount_id#
	</cfquery>

	<!--- delete discount --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_discounts
	WHERE discount_id=#arguments.discount_id#
	</cfquery>

		<!--- clear stored discount data from memory --->
		<cftry>
		<cfset structClear(application.cw.discountData)>
		<cfcatch></cfcatch>
		</cftry>

</cffunction>

<!--- // ---------- List Available Products for Discount Selection ---------- // --->
<cffunction name="CWqueryDiscountProductSelections" access="public" returntype="query" output="false"
			hint="Returns a query of available associated products for a specified discount">

	<!--- optional arguments to restrict results --->
	<cfargument name="discount_cat" required="false" default="0" type="numeric"
				hint="Category ID to filter results by">

	<cfargument name="discount_scndcat" required="false" default="0" type="numeric"
				hint="Secondary Category ID to filter results by">

	<cfargument name="search_string" default="%" type="String" required="False"
				hint="A string to search for">

	<cfargument name="search_by" default="" type="String" required="False"
				hint="The field or column to search within (default blank=all)">

	<cfargument name="omitted_products" required="false" default="0" type="string"
				hint="A comma separated list of product IDs to ignore">

	<cfargument name="show_archived" required="false" default="false" type="boolean"
				hint="If true, include archived products in results">

<cfset var searchFor = lcase(arguments.search_string)>
<cfset var rsDiscountProducts = "">

<cfquery name="rsDiscountProducts" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT pp.product_name, pp.product_id
	, pp.product_merchant_product_id
	FROM cw_products pp
	<cfif arguments.discount_cat gt 0>
	INNER JOIN cw_product_categories_primary cc
	</cfif>
	<cfif arguments.discount_scndcat gt 0>
	INNER JOIN cw_product_categories_secondary sc
	</cfif>
	WHERE 1 = 1
	<cfif not arguments.show_archived>
	AND NOT product_archive = 1
	</cfif>
	<cfif listLen(trim(arguments.omitted_products))>
	AND NOT product_id in(#arguments.omitted_products#)
	</cfif>
	<!--- add search_by options, make case insensitive --->
	  <cfif arguments.search_by	EQ "prodID">
	    AND #application.cw.sqlLower#(pp.product_merchant_product_id) LIKE '%#searchFor#%'
	    <cfelseif arguments.search_by eq "description">
	    AND (#application.cw.sqlLower#(pp.product_description) LIKE '%#searchFor#%'
			OR #application.cw.sqlLower#(pp.product_preview_description) LIKE '%#searchFor#%')
	    <cfelseif arguments.search_by eq "prodName">
		AND #application.cw.sqlLower#(pp.product_name) LIKE '%#searchFor#%'
		<!--- any field --->
		<cfelse>
		AND (
		#application.cw.sqlLower#(pp.product_name) LIKE '%#searchFor#%'
		OR
		#application.cw.sqlLower#(pp.product_description) LIKE '%#searchFor#%'
		OR
		#application.cw.sqlLower#(pp.product_preview_description) LIKE '%#searchFor#%'
		OR
		#application.cw.sqlLower#(pp.product_name) LIKE '%#searchFor#%'
		OR
		#application.cw.sqlLower#(pp.product_merchant_product_id) LIKE '%#searchFor#%'
		<cfif application.cw.adminProductKeywordsEnabled>
			OR
			#application.cw.sqlLower#(pp.product_keywords) LIKE '%#searchFor#%'
		</cfif>
		)
	  </cfif>
<!--- category / secondary cat --->
	<cfif arguments.discount_cat gt 0>
	AND cc.product2category_category_id = #arguments.discount_cat#
	AND cc.product2category_product_id = pp.product_id
	</cfif>
	<cfif arguments.discount_scndcat gt 0>
	AND sc.product2secondary_secondary_id = #arguments.discount_scndcat#
	AND sc.product2secondary_product_id = pp.product_id
	</cfif>
	ORDER BY pp.product_sort, pp.product_name
</cfquery>

<cfreturn rsDiscountProducts>
</cffunction>

<!--- // ---------- List Available Skus for Discount Selection ---------- // --->
<cffunction name="CWqueryDiscountSkuSelections" access="public" returntype="query" output="false"
			hint="Returns a query of available associated skus for a specified discount">

	<!--- optional arguments to restrict results --->
	<cfargument name="discount_cat" required="false" default="0" type="numeric"
				hint="Category ID to filter results by">

	<cfargument name="discount_scndcat" required="false" default="0" type="numeric"
				hint="Secondary Category ID to filter results by">

	<cfargument name="search_string" default="%" type="String" required="False"
				hint="A string to search for">

	<cfargument name="search_by" default="" type="String" required="False"
				hint="The field or column to search within (default blank=all)">

	<cfargument name="omitted_skus" required="false" default="0" type="string"
				hint="A comma separated list of sku IDs to ignore">

	<cfargument name="show_archived" required="false" default="false" type="boolean"
				hint="If true, include archived products in results">

<cfset var searchFor = lcase(arguments.search_string)>
<cfset var rsDiscountSkus = "">
<cfset var returnSkus = "">

<cfquery name="rsDiscountSkus" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT
	pp.product_name,
	pp.product_id,
	pp.product_merchant_product_id,
	ss.sku_id,
	ss.sku_merchant_sku_id,
	ss.sku_price
	FROM cw_products pp
	INNER join cw_skus ss
	<cfif arguments.discount_cat gt 0>
	INNER JOIN cw_product_categories_primary cc
	</cfif>
	<cfif arguments.discount_scndcat gt 0>
	INNER JOIN cw_product_categories_secondary sc
	</cfif>
	WHERE ss.sku_product_id = pp.product_id
	<cfif not arguments.show_archived>
	AND NOT product_archive = 1
	</cfif>
	<!--- add search_by options, make case insensitive --->
	  <cfif arguments.search_by	EQ "prodID">
	    AND #application.cw.sqlLower#(pp.product_merchant_product_id) LIKE '%#searchFor#%'
	    <cfelseif arguments.search_by eq "description">
	    AND (#application.cw.sqlLower#(pp.product_description) LIKE '%#searchFor#%'
			OR #application.cw.sqlLower#(pp.product_preview_description) LIKE '%#searchFor#%')
	    <cfelseif arguments.search_by eq "prodName">
		AND #application.cw.sqlLower#(pp.product_name) LIKE '%#searchFor#%'
	    <cfelseif arguments.search_by eq "skuName">
		AND #application.cw.sqlLower#(ss.sku_merchant_sku_id) LIKE '%#searchFor#%'
		<!--- any field --->
		<cfelse>
		AND (
		#application.cw.sqlLower#(pp.product_name) LIKE '%#searchFor#%'
		OR
		#application.cw.sqlLower#(pp.product_description) LIKE '%#searchFor#%'
		OR
		#application.cw.sqlLower#(pp.product_preview_description) LIKE '%#searchFor#%'
		OR
		#application.cw.sqlLower#(pp.product_name) LIKE '%#searchFor#%'
		OR
		#application.cw.sqlLower#(pp.product_merchant_product_id) LIKE '%#searchFor#%'
		OR
		#application.cw.sqlLower#(ss.sku_merchant_sku_id) LIKE '%#searchFor#%'
		<cfif application.cw.adminProductKeywordsEnabled>
			OR
			#application.cw.sqlLower#(pp.product_keywords) LIKE '%#searchFor#%'
		</cfif>
		)
	  </cfif>
	<!--- category / secondary cat --->
	<cfif arguments.discount_cat gt 0>
	AND cc.product2category_category_id = #arguments.discount_cat#
	AND cc.product2category_product_id = pp.product_id
	</cfif>
	<cfif arguments.discount_scndcat gt 0>
	AND sc.product2secondary_secondary_id = #arguments.discount_scndcat#
	AND sc.product2secondary_product_id = pp.product_id
	</cfif>
	AND NOT ss.sku_on_web = 0
	ORDER BY pp.product_sort, pp.product_name, ss.sku_sort, ss.sku_merchant_sku_id
</cfquery>
	<!--- query of query returns skus not specifically omitted --->
	<cfquery dbtype="query" name="returnSkus">
	SELECT *
	FROM rsDiscountSkus
	<cfif listLen(trim(arguments.omitted_skus))>
	WHERE NOT sku_id in(#arguments.omitted_skus#)
	</cfif>
	</cfquery>

<cfreturn returnSkus>
</cffunction>

<!--- // ---------- Select Existing Discount Product Records ---------- // --->
<cffunction name="CWquerySelectDiscountProducts" access="public" output="false" returntype="query"
			hint="Returns all associated products for a discount">

	<cfargument name="discount_id" type="numeric" required="true"
				hint="ID of Discount to look up">

	<cfargument name="show_archived" type="boolean" required="false" default="false"
				hint="If true, include archived products">

<cfset var rsGetproducts = "">
<cfquery name="rsGetproducts" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT
	pp.product_id,
	pp.product_merchant_product_id,
	pp.product_name,
	pp.product_description,
	pp.product_sort,
	dp.discount2product_discount_id as discount_id
	FROM cw_discount_products dp, cw_products pp
	WHERE dp.discount2product_discount_id = #arguments.discount_id#
	AND pp.product_id = dp.discount2product_product_id
	AND NOT pp.product_on_web = 0
	<cfif not arguments.show_archived>
	AND NOT pp.product_archive = 1
	</cfif>
	ORDER BY product_sort
</cfquery>
<cfreturn rsGetproducts>
</cffunction>

<!--- // ---------- Select Existing Discount SKU Records ---------- // --->
<cffunction name="CWquerySelectDiscountSKUs" access="public" output="false" returntype="query"
			hint="Returns all associated skus for a discount">

	<cfargument name="discount_id" type="numeric" required="true"
				hint="ID of Discount to look up">

	<cfargument name="product_id" type="numeric" required="false" default="0"
				hint="ID of Product to look up (default = 0, all products)">

	<cfargument name="show_archived" type="boolean" required="false" default="false"
				hint="If true, include archived skus">

<cfset var rsGetskus = "">
<cfquery name="rsGetskus" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT
	ss.sku_id,
	ss.sku_merchant_sku_id,
	ss.sku_sort,
	pp.product_name,
	pp.product_id,
	pp.product_merchant_product_id
	FROM
	(cw_discount_skus ds
		INNER JOIN	cw_skus ss
		ON ss.sku_id = ds.discount2sku_sku_id)
		INNER JOIN cw_products pp
		ON ss.sku_product_id = pp.product_id
	WHERE ds.discount2sku_discount_id = #arguments.discount_id#
	AND NOT ss.sku_on_web = 0
	AND NOT pp.product_on_web = 0
	<cfif not arguments.show_archived>
	AND NOT pp.product_archive = 1
	</cfif>
	<cfif not arguments.product_id eq 0>
	AND pp.product_id = #arguments.product_id#
	</cfif>
	ORDER BY pp.product_sort, pp.product_name
</cfquery>

<cfreturn rsGetskus>
</cffunction>

<!--- // ---------- Delete Discount Product Record ---------- // --->
<cffunction name="CWqueryDeleteDiscountProduct" access="public" returntype="void" output="false"
			hint="Deletes associated product record(s) for a given discount ID">

	<cfargument name="discount_id" required="true" type="Numeric"
				hint="The ID of the Discount">

	<cfargument name="product_id" required="false" default="0" type="string"
				hint="A list of product IDs. If not specified, all products will be removed from the discount">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM
	cw_discount_products
	WHERE
	 discount2product_discount_id = #arguments.discount_id#
	<cfif len(trim(arguments.product_id)) and arguments.product_id is not '0'>
		AND discount2product_product_id in(#arguments.product_id#)
	</cfif>
</cfquery>
</cffunction>

<!--- // ---------- Delete Discount SKU Record ---------- // --->
<cffunction name="CWqueryDeleteDiscountSKU" access="public" returntype="void" output="false"
			hint="Deletes associated SKU record(s) for a given discount ID">

	<cfargument name="discount_id" required="true" type="Numeric"
				hint="The ID of the Discount">

	<cfargument name="SKU_id" required="false" default="0" type="string"
				hint="A list of SKU IDs. If not specified, all SKUs will be removed from the discount">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM
	cw_discount_skus
	WHERE
	 discount2sku_discount_id = #arguments.discount_id#
	<cfif len(trim(arguments.SKU_id)) and arguments.sku_id is not '0'>
		AND discount2sku_sku_id in(#arguments.sku_id#)
	</cfif>
</cfquery>
</cffunction>

<!--- // ---------- Insert Associated Product Record ---------- // --->
<cffunction name="CWqueryInsertDiscountProduct" access="public" output="false" returntype="void"
			hint="Creates a new relative category/discount record">

	<cfargument name="discount_id" required="true" type="numeric"
				hint="the Discount ID to insert">
	<cfargument name="product_id" required="true" type="numeric"
				hint="product ID to insert">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_discount_products
	(discount2product_discount_id, discount2product_product_id)
	VALUES (#arguments.discount_id#, #arguments.product_id#)
</cfquery>
</cffunction>

<!--- // ---------- Insert Associated Sku Record ---------- // --->
<cffunction name="CWqueryInsertDiscountSku" access="public" output="false" returntype="void"
			hint="Creates a new relative category/discount record">

	<cfargument name="discount_id" required="true" type="numeric"
				hint="the Discount ID to insert">
	<cfargument name="sku_id" required="true" type="numeric"
				hint="sku ID to insert">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_discount_skus
	(discount2sku_discount_id, discount2sku_sku_id)
	VALUES (#arguments.discount_id#, #arguments.sku_id#)
</cfquery>
</cffunction>

<!--- // ---------- Archive a Discount ---------- // --->
<cffunction name="CWqueryArchiveDiscount" access="public" returntype="void"  output="false"
			hint="Sets a discount to archived status in admin (Archived = true)">

		<cfargument name="discount_id" required="true" type="Numeric"
					hint="The ID of the discount to archive">

<!--- set archive = 1 --->
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
UPDATE cw_discounts
SET discount_archive = 1
WHERE discount_id = #arguments.discount_id#
</cfquery>

	<!--- clear stored discount data from memory --->
	<cftry>
	<cfset structClear(application.cw.discountData)>
	<cfcatch></cfcatch>
	</cftry>

</cffunction>

<!--- // ---------- Reactivate an Archived Discount ---------- // --->
<cffunction name="CWqueryReactivateDiscount" access="public" returntype="void"  output="false"
			hint="Sets a discount to non-archived status in admin (Archived = false)">

	<cfargument name="discount_id" required="true" type="Numeric"
				hint="The ID of the discount to activate">

<!--- set archive = 0 --->
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	UPDATE cw_discounts
	SET discount_archive = 0
	WHERE discount_id = #arguments.discount_id#
</cfquery>

	<!--- clear stored discount data from memory --->
	<cftry>
	<cfset structClear(application.cw.discountData)>
	<cfcatch></cfcatch>
	</cftry>

</cffunction>

<!--- // ---------- Get Discount Related Categories ---------- // --->
<cffunction name="CWquerySelectDiscountRelCategories" access="public" output="false" returntype="query"
			hint="Returns all selected categories for a given discount">

	<cfargument name="discount_id" required="true" type="numeric"
				hint="ID of discount to look up">

<cfset var rsRelCategories = "">
<cfquery name="rsRelCategories" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT rr.discount2category_category_id, cc.category_name
FROM
cw_discount_categories rr,
cw_categories_primary cc
WHERE rr.discount2category_discount_id = #arguments.discount_id#
AND cc.category_id = rr.discount2category_category_id
AND rr.discount_category_type = 1
</cfquery>
<cfreturn rsRelCategories>
</cffunction>

<!--- // ---------- Get Discount Related Secondary Categories ---------- // --->
<cffunction name="CWquerySelectDiscountRelSecondaries" access="public" output="false" returntype="query"
			hint="Returns all selected secondary categories for a given discount">

	<cfargument name="discount_id" required="true" type="numeric"
				hint="ID of discount to look up">

<cfset var rsRelScndCategories = "">
<cfquery name="rsRelScndCategories" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT rr.discount2category_category_id, cc.secondary_name
FROM
cw_discount_categories rr,
cw_categories_secondary cc
WHERE rr.discount2category_discount_id = #arguments.discount_id#
AND cc.secondary_id = rr.discount2category_category_id
AND rr.discount_category_type = 2
</cfquery>
<cfreturn rsRelScndCategories>
</cffunction>

<!--- // ---------- Delete Discount Category Record(s) ---------- // --->
<cffunction name="CWqueryDeleteDiscountCat" access="public" output="false" returntype="void"
			hint="Deletes a relative category/discount record">

	<cfargument name="discount_id" required="true" type="numeric"
				hint="the Discount ID to look up">
	<cfargument name="category_id" required="false" default="0" type="numeric"
				hint="optional category ID - if omitted, all related cats for this discount are deleted">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_discount_categories
	WHERE discount2category_discount_id = #arguments.discount_id#
	<cfif arguments.category_id gt 0>
	AND discount2category_category_id = #arguments.category_id#
	</cfif>
	AND discount_category_type = 1
</cfquery>
</cffunction>

<!--- // ---------- Insert Associated Category Record ---------- // --->
<cffunction name="CWqueryInsertDiscountCat" access="public" output="false" returntype="void"
			hint="Creates a new relative category/discount record">

	<cfargument name="discount_id" required="true" type="numeric"
				hint="the Discount ID to insert">
	<cfargument name="category_id" required="true" type="numeric"
				hint="category ID to insert">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_discount_categories
	(discount2category_discount_id, discount2category_category_id,discount_category_type )
	VALUES (#arguments.discount_id#, #arguments.category_id#,1)
</cfquery>
</cffunction>

<!--- // ---------- Delete Discount Secondary Category Record(s) ---------- // --->
<cffunction name="CWqueryDeleteDiscountScndCat" access="public" output="false" returntype="void"
			hint="Deletes a relative secondary category/discount record">

	<cfargument name="discount_id" required="true" type="numeric"
				hint="the Discount ID to look up">
	<cfargument name="category_id" required="false" default="0" type="numeric"
				hint="optional category ID - if omitted, all related cats for this discount are deleted">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_discount_categories
	WHERE discount2category_discount_id = #arguments.discount_id#
	<cfif arguments.category_id gt 0>
	AND discount2category_category_id = #arguments.category_id#
	</cfif>
	AND discount_category_type = 2
	</cfquery>
</cffunction>

<!--- // ---------- Insert Associated Secondary Category Record ---------- // --->
<cffunction name="CWqueryInsertDiscountScndCat" access="public" output="false" returntype="void"
			hint="Creates a new relative secondary category/discount record">

	<cfargument name="discount_id" required="true" type="numeric"
				hint="the Discount ID to insert">
	<cfargument name="category_id" required="true" type="numeric"
				hint="category ID to insert">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_discount_categories
	(discount2category_discount_id, discount2category_category_id,discount_category_type )
	VALUES (#arguments.discount_id#, #arguments.category_id#,2)
</cfquery>
</cffunction>

<!--- // ---------- // Get discount usage by order ID // ---------- // --->
<cffunction name="CWquerySelectOrderDiscounts"
			access="public"
			output="false"
			returntype="query"
			hint="Returns a query of discounts used for any order"
			>

	<cfargument name="order_id" required="true" default="0" type="string"
				hint="ID of order to look up">

	<cfset var discountsQuery = ''>

	<cfquery name="discountsQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT *
	FROM cw_discount_usage
	WHERE discount_usage_order_id = '#trim(arguments.order_id)#'
	</cfquery>

	<cfreturn discountsQuery>

</cffunction>

<!--- // ---------- // Get discount description by id // ---------- // --->
<cffunction name="CWgetDiscountDescription"
			access="public"
			output="false"
			returntype="string"
			hint="returns a discount description, or an empty string"
			>

	<cfargument name="discount_id"
		required="true"
		default="0"
		type="numeric"
		hint="Id of the discount to look up">

	<cfargument name="show_description"
		required="false"
		default="true"
		type="boolean"
		hint="if true, the description will be added to the discount name">

	<cfargument name="show_promocode"
		required="false"
		default="true"
		type="boolean"
		hint="if true, the name will include the promo code">

		<cfset var discQuery = ''>
		<cfset var discDescrip = ''>

	<cfquery name="discQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT discount_description, discount_name, discount_promotional_code, discount_show_description
	FROM cw_discounts
	WHERE discount_id = #arguments.discount_id#
	</cfquery>

	<!--- get name --->
	<cfset discDescrip = discQuery.discount_name>
	<!--- add promo code --->
	<cfif arguments.show_promocode and len(trim(discQuery.discount_promotional_code))>
		<cfset discDescrip = discDescrip & ' (#discQuery.discount_promotional_code#)' >
	</cfif>
	<!--- add description --->
	<cfif discQuery.discount_show_description neq 0>
		<cfset discDescrip = discDescrip & '<br><span class="CWdiscountDescription">' & #discQuery.discount_description# & '</span>'>
	</cfif>

	<cfreturn discDescrip>
</cffunction>

<!--- /////////////// --->
<!--- CATEGORY QUERIES --->
<!--- /////////////// --->

<!--- // ---------- Get Category Details ---------- // --->
<cffunction name="CWquerySelectCatDetails" access="public" output="false" returntype="query"
			hint="Returns all details about a category, by name or ID">

	<cfargument name="cat_id" required="true" type="numeric"
				hint="ID of the category to lookup - pass in 0 to use name lookup instead">

	<cfargument name="cat_name" required="false" default="" type="string"
				hint="Name of the category to look up">

<cfset var rsSelectCatDetails = ''>
<cfquery name="rsSelectCatDetails" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT *
FROM cw_categories_primary
WHERE
<cfif arguments.cat_id>
category_id = #arguments.cat_id#
<cfelse>
#application.cw.sqlLower#(category_name) ='#lcase(arguments.cat_name)#'
</cfif>
</cfquery>
<cfreturn rsSelectCatDetails>
</cffunction>

<!--- // ---------- Get ALL active or archived categories ---------- // --->
<cffunction name="CWquerySelectStatusCategories" access="public" output="false" returntype="query"
			hint="Returns all active or archived categories, along with number of products in each">

<cfargument name="cats_active" default="1" type="numeric" required="false"
			hint="Set to 0 to return archived categories">

	<cfset var compareTo = 1>
	<cfset var rsStatusCats = "">

<!--- set up opposite value so we can query with 'not' --->
<cfif arguments.cats_active is 1>
	<cfset compareTo = 0>
</cfif>

<cfquery name="rsStatusCats" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT
	category_id,
	category_name,
	category_archive,
	category_sort,
	category_description,
	category_nav,
	count(product2category_product_id) as catProdCount
	FROM cw_categories_primary
	LEFT OUTER JOIN cw_product_categories_primary
	ON cw_product_categories_primary.product2category_category_id = cw_categories_primary.category_id
	WHERE NOT category_archive = #compareTo#
	GROUP BY
	category_id,
	category_name,
	category_archive,
	category_sort,
	category_description,
	category_nav
	ORDER BY category_sort, category_name

</cfquery>
<cfreturn rsStatusCats>
</cffunction>

<!--- // ---------- Insert Category ---------- // --->
<cffunction name="CWqueryInsertCategory" access="public" output="false" returntype="string"
			hint="Inserts a category record - returns ID of the new category, or 0-message if unsuccessful">

	<!--- Name is required --->
	<cfargument name="cat_name" required="true" type="string"
				hint="Name of the category">
	<!--- others are optional --->
	<cfargument name="cat_sort" required="false" default="0" type="numeric"
				hint="Sort order">
	<cfargument name="cat_archive" required="false" default="0" type="numeric"
				hint="Archived yes/no">
	<cfargument name="cat_description" required="false" default="" type="string"
				hint="Text description">
	<cfargument name="cat_nav" required="false" default="1" type="numeric"
				hint="Show in navigation or search">

<cfset var newCatID = ''>
<!--- first look up existing category --->
<cfset dupCheck = CWquerySelectCatDetails(0,trim(arguments.cat_name))>
<!--- force nav to be 1 or 0 --->
<cfif not (arguments.cat_nav is 1 or arguments.cat_nav is 0)>
	<cfset arguments.cat_nav = 1>
</cfif>
<!--- if we have a duplicate, return an error message --->
<cfif dupCheck.recordCount>
<cfset newCatID = '0-Name'>
<!--- if no duplicate, insert --->
<cfelse>
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
INSERT INTO cw_categories_primary (
category_name,
category_sort,
category_archive,
category_description,
category_nav
) VALUES (
'#trim(arguments.cat_name)#',
#arguments.cat_sort#,
#arguments.cat_archive#,
'#trim(arguments.cat_description)#',
#arguments.cat_nav#
)
</cfquery>

<!--- get ID for return value --->
<cfquery name="getNewCatID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT category_id
FROM cw_categories_primary
WHERE category_name = '#trim(arguments.cat_name)#'
</cfquery>
<cfset newCatID = getNewCatID.category_id>

</cfif>
<cfreturn newCatID>

</cffunction>

<!--- // ---------- Update Category ---------- // --->
<cffunction name="CWqueryUpdateCategory" access="public" output="false" returntype="string"
	hint="Updates a category record - returns ID of the updated category, or 0-message if unsuccessful">

	<!--- ID and name are required --->
	<cfargument name="cat_id" required="true" type="numeric"
				hint="ID of the category to update">
	<cfargument name="cat_name" required="true" type="string"
				hint="Name of the category">
	<!--- other are optional --->
	<cfargument name="cat_sort" required="false" default="0" type="numeric"
				hint="Sort order">
	<cfargument name="cat_archive" required="false" default="0" type="numeric"
				hint="Archived yes/no">
	<cfargument name="cat_description" required="false" default="" type="string"
				hint="Text description">
	<cfargument name="cat_nav" required="false" default="1" type="numeric"
				hint="Show in navigation or search">				

<cfset var updateCatID = ''>
<!--- first look up existing category --->
<cfset dupCheck = CWquerySelectCatDetails(0,trim(arguments.cat_name))>
<!--- if we have a duplicate, return an error message --->
<cfif dupCheck.recordCount AND NOT dupCheck.category_id eq arguments.cat_id>
<cfset updateCatID = '0-Name'>
<!--- if no duplicate, insert --->
<cfelse>
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
UPDATE cw_categories_primary SET
category_name = '#trim(arguments.cat_name)#',
category_sort = #arguments.cat_sort#,
category_archive = #arguments.cat_archive#,
category_description = '#trim(arguments.cat_description)#',
category_nav = #arguments.cat_nav#
WHERE category_id = #arguments.cat_id#
</cfquery>
<cfset updateCatID = arguments.cat_id>

</cfif>

<cfreturn updateCatID>

</cffunction>

<!--- // ---------- Delete Category  ---------- // --->
<cffunction name="CWqueryDeleteCategory" access="public" output="false" returntype="void"
			hint="Delete a category and associated product relationships">

	<cfargument name="cat_id" required="true" type="numeric"
				hint="ID of the category to delete">

<!--- delete product relationships --->
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
DELETE FROM cw_product_categories_primary WHERE product2category_category_id = #arguments.cat_id#
</cfquery>
<!--- delete discount relationships --->
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
DELETE FROM cw_discount_categories WHERE discount2category_category_id = #arguments.cat_id# AND discount_category_type = 1
</cfquery>
<!--- delete category --->
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
DELETE FROM cw_categories_primary WHERE category_id = #arguments.cat_id#
</cfquery>

</cffunction>

<!--- // ---------- Get Secondary Category Details ---------- // --->
<cffunction name="CWquerySelectSecondaryCatDetails" access="public" output="false" returntype="query"
			hint="Returns all details about a secondary category, by name or ID">

	<cfargument name="cat_id" required="true" type="numeric"
				hint="ID of the category to lookup - pass in 0 to use name lookup instead">

	<cfargument name="cat_name" required="false" default="" type="string"
				hint="Name of the category to look up">

<cfset var rsSelectCatDetails = ''>
<cfquery name="rsSelectCatDetails" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT *
FROM cw_categories_secondary
WHERE
<cfif arguments.cat_id>
secondary_id = #arguments.cat_id#
<cfelse>
#application.cw.sqlLower#(secondary_name) ='#lcase(arguments.cat_name)#'
</cfif>
</cfquery>
<cfreturn rsSelectCatDetails>
</cffunction>

<!--- // ---------- Get ALL active or archived secondary categories ---------- // --->
<cffunction name="CWquerySelectStatusSecondaryCategories" access="public" output="false" returntype="query"
			hint="Returns all active or archived secondary categories, along with number of products in each">

<cfargument name="cats_active" default="1" type="numeric" required="false"
			hint="Set to 0 to return archived categories">

	<cfset var compareTo = 1>
	<cfset var rsStatusCats = "">

<!--- set up opposite value so we can query with 'not' --->
<cfif arguments.cats_active is 1>
	<cfset compareTo = 0>
</cfif>

<cfquery name="rsStatusCats" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT secondary_id,
	secondary_name,
	secondary_archive,
	secondary_sort,
	secondary_description,
	secondary_nav,
	count(product2secondary_product_id) as catProdCount
	FROM cw_categories_secondary
	LEFT OUTER JOIN cw_product_categories_secondary
	ON cw_product_categories_secondary.product2secondary_secondary_id = cw_categories_secondary.secondary_id
	WHERE NOT secondary_archive = #compareTo#
	GROUP BY
	secondary_id,
	secondary_name,
	secondary_archive,
	secondary_sort,
	secondary_description,
	secondary_nav
	ORDER BY secondary_sort, secondary_name

</cfquery>
<cfreturn rsStatusCats>
</cffunction>

<!--- // ---------- Insert Secondary Category ---------- // --->
<cffunction name="CWqueryInsertSecondaryCategory" access="public" output="false" returntype="string"
			hint="Inserts a secondary category record - returns ID of the new category, or 0-message if unsuccessful">

	<!--- Name is required --->
	<cfargument name="cat_name" required="true" type="string"
				hint="Name of the category">
	<!--- others are optional --->
	<cfargument name="cat_sort" required="false" default="0" type="numeric"
				hint="Sort order">
	<cfargument name="cat_archive" required="false" default="0" type="numeric"
				hint="Archived yes/no">
	<cfargument name="cat_description" required="false" default="" type="string"
				hint="Text description">
	<cfargument name="cat_nav" required="false" default="1" type="numeric"
				hint="Show in navigation or search">
				
<cfset var newCatID = ''>
<!--- force nav to be 1 or 0 --->
<cfif not (arguments.cat_nav is 1 or arguments.cat_nav is 0)>
	<cfset arguments.cat_nav = 1>
</cfif>
<!--- first look up existing category --->
<cfset dupCheck = CWquerySelectSecondaryCatDetails(0,trim(arguments.cat_name))>
<!--- if we have a duplicate, return an error message --->
<cfif dupCheck.recordCount>
<cfset newCatID = '0-Name'>
<!--- if no duplicate, insert --->
<cfelse>
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
INSERT INTO cw_categories_secondary (
secondary_name,
secondary_sort,
secondary_archive,
secondary_description,
secondary_nav
) VALUES (
'#trim(arguments.cat_name)#',
#arguments.cat_sort#,
#arguments.cat_archive#,
'#trim(arguments.cat_description)#',
#arguments.cat_nav#
)
</cfquery>

<!--- get ID for return value --->
<cfquery name="getNewCatID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT secondary_id
FROM cw_categories_secondary
WHERE secondary_name = '#trim(arguments.cat_name)#'
</cfquery>
<cfset newCatID = getNewCatID.secondary_id>

</cfif>
<cfreturn newCatID>

</cffunction>

<!--- // ---------- Update Secondary Category ---------- // --->
<cffunction name="CWqueryUpdateSecondaryCategory" access="public" output="false" returntype="string"
			hint="Updates a secondary category record - returns ID of the updated category, or 0-message if unsuccessful">

	<!--- ID and name are required --->
	<cfargument name="cat_id" required="true" type="numeric"
				hint="ID of the category to update">
	<cfargument name="cat_name" required="true" type="string"
				hint="Name of the category">
	<!--- other are optional --->
	<cfargument name="cat_sort" required="false" default="0" type="numeric"
				hint="Sort order">
	<cfargument name="cat_archive" required="false" default="0" type="numeric"
				hint="Archived yes/no">
	<cfargument name="cat_description" required="false" default="" type="string"
				hint="Text description">
	<cfargument name="cat_nav" required="false" default="1" type="numeric"
				hint="Show in navigation or search">
				
<cfset var updateCatID = ''>
<!--- first look up existing category --->
<cfset dupCheck = CWquerySelectSecondaryCatDetails(0,trim(arguments.cat_name))>
<!--- if we have a duplicate, return an error message --->
<cfif dupCheck.recordCount AND NOT dupCheck.secondary_id eq arguments.cat_id>
<cfset updateCatID = '0-Name'>
<!--- if no duplicate, insert --->
<cfelse>
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
UPDATE cw_categories_secondary SET
secondary_name = '#arguments.cat_name#',
secondary_sort = #arguments.cat_sort#,
secondary_archive = #arguments.cat_archive#,
secondary_description = '#arguments.cat_description#',
secondary_nav = #arguments.cat_nav#
WHERE secondary_id = #arguments.cat_id#
</cfquery>
<cfset updateCatID = arguments.cat_id>
</cfif>

<cfreturn updateCatID>

</cffunction>

<!--- // ---------- Delete Secondary Category  ---------- // --->
<cffunction name="CWqueryDeleteSecondaryCategory" access="public" output="false" returntype="void"
			hint="Delete a secondary category and associated product relationships">

	<cfargument name="cat_id" required="true" type="numeric"
				hint="ID of the secondary category to delete">

<!--- delete product relationships --->
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
DELETE FROM cw_product_categories_secondary
WHERE product2secondary_secondary_id = #arguments.cat_id#
</cfquery>
<!--- delete discount relationships --->
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
DELETE FROM cw_discount_categories WHERE discount2category_category_id = #arguments.cat_id# AND discount_category_type = 2
</cfquery>
<!--- delete category --->
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
DELETE FROM cw_categories_secondary
WHERE secondary_id = #arguments.cat_id#
</cfquery>

</cffunction>

<!--- ////////////////////// --->
<!--- PRODUCT OPTION QUERIES --->
<!--- ////////////////////// --->

<!--- // ---------- Get ALL active or archived option groups ---------- // --->
<cffunction name="CWquerySelectStatusOptionGroups" access="public" output="false" returntype="query"
			hint="Returns all active or archived option groups, along with number of products using each">

<cfargument name="options_active" default="0" type="numeric" required="false"
			hint="Set to 1 to return archived option groups">

	<cfset var compareTo = 1>
	<cfset var rsStatusOptionGroups = "">
<!--- set up opposite value so we can query with 'not' --->
<cfif arguments.options_active is 1>
	<cfset compareTo = 0>
</cfif>

	<cfquery name="rsStatusOptionGroups" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT optiontype_id, optiontype_name, optiontype_required, optiontype_archive, optiontype_sort, optiontype_text,
		count(product_options2prod_id) as optionProdCount
		FROM (cw_option_types
			LEFT OUTER JOIN cw_product_options
			ON cw_product_options.product_options2optiontype_id = cw_option_types.optiontype_id)
		WHERE NOT optiontype_archive = #compareTo#
		AND NOT optiontype_deleted = 1
		GROUP BY optiontype_id, optiontype_name, optiontype_required, optiontype_archive, optiontype_sort, optiontype_text
		ORDER BY optiontype_sort
	</cfquery>
<cfreturn rsStatusOptionGroups>
</cffunction>

<!--- // ---------- Update Option Group ---------- // --->
<cffunction name="CWqueryUpdateOptionGroup" access="public" output="false" returntype="void"
			hint="Updates an option group record">

	<!--- ID and name are required --->
	<cfargument name="optiongroup_id" required="true" type="numeric"
				hint="ID of the option group to update">
	<cfargument name="optiongroup_name" required="true" type="string"
				hint="Name of the option group">
	<!--- others are optional --->
	<cfargument name="optiongroup_sort" required="false" default="0" type="numeric"
				hint="Sort order">
	<cfargument name="optiongroup_archive" required="false" default="0" type="numeric"
				hint="Archived yes/no">
	<cfargument name="optiongroup_text" required="false" default="" type="string"
				hint="Text description">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
UPDATE cw_option_types SET
optiontype_name = '#trim(arguments.optiongroup_name)#',
optiontype_sort = #arguments.optiongroup_sort#,
optiontype_archive = #arguments.optiongroup_archive#,
optiontype_text = '#trim(arguments.optiongroup_text)#'
WHERE optiontype_id = #arguments.optiongroup_id#
</cfquery>
</cffunction>

<!--- // ---------- Get Option Group Details ---------- // --->
<cffunction name="CWquerySelectOptionGroupDetails" access="public" output="false" returntype="query"
			hint="Returns all details about an option group, by name or ID, including number of associated products">

	<cfargument name="optiongroup_id" required="true" type="numeric"
				hint="ID of the option group to lookup - pass in 0 to use name lookup instead">

	<cfargument name="optiongroup_name" required="false" default="" type="string"
				hint="Name of the Option Group to look up">

<cfset var rsSelectOptionGroupDetails = ''>
<cfquery name="rsSelectOptionGroupDetails" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT  optiontype_id, optiontype_name, optiontype_required, optiontype_archive, optiontype_sort, optiontype_text,
		count(product_options2prod_id) as optionProdCount
FROM cw_option_types
LEFT OUTER JOIN cw_product_options
		ON cw_product_options.product_options2optiontype_id = cw_option_types.optiontype_id
WHERE <cfif arguments.optiongroup_id>
optiontype_id = #arguments.optiongroup_id#
<cfelse>
#application.cw.sqlLower#(optiontype_name) ='#lcase(arguments.optiongroup_name)#'
</cfif>
GROUP BY optiontype_id, optiontype_name, optiontype_required, optiontype_archive, optiontype_sort, optiontype_text
</cfquery>
<cfreturn rsSelectOptionGroupDetails>
</cffunction>

<!--- // ---------- Get Option Order SKUs ---------- // --->
<cffunction name="CWquerySelectOptionGroupOrders" access="public" output="false" returntype="query"
			hint="Returns a query with all Order Skus associated with options in a group">

	<cfargument name="optiongroup_id" required="true" type="numeric"
				hint="ID of the option group to lookup">

	<cfargument name="count_orders" required="false" default="0" type="boolean"
				hint="Groups by order id, returning only one row per order rather than all skus">

	<cfset var rsSelectOptionGroupOrders = ''>

	<!--- get a list of all option IDs in this group --->
	<cfset var groupOptionsQuery = CWquerySelectGroupOptions(arguments.optiongroup_id)>
	<cfset var optionIDlist = valueList(groupOptionsQuery.option_id)>
	<!--- if there are options in this group --->
	<cfif listLen(optionIdList)>
	<!--- look for order skus with any id in the list --->
	<cfquery name="rsSelectOptionGroupOrders" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT
	cw_order_skus.ordersku_discount_amount,
	cw_order_skus.ordersku_id,
	cw_order_skus.ordersku_order_id,
	cw_order_skus.ordersku_quantity,
	cw_order_skus.ordersku_sku,
	cw_order_skus.ordersku_sku_total,
	cw_order_skus.ordersku_taxrate_id,
	cw_order_skus.ordersku_tax_rate,
	cw_order_skus.ordersku_unit_price,
	cw_sku_options.sku_option2option_id,
	cw_sku_options.sku_option2sku_id,
	cw_sku_options.sku_option_id
	FROM cw_order_skus, cw_sku_options
	WHERE cw_sku_options.sku_option2sku_id = cw_order_skus.ordersku_sku
	AND sku_option2option_id in(#optionIDlist#)
	<cfif arguments.count_orders>
	GROUP by
	cw_order_skus.ordersku_discount_amount,
	cw_order_skus.ordersku_id,
	cw_order_skus.ordersku_order_id,
	cw_order_skus.ordersku_quantity,
	cw_order_skus.ordersku_sku,
	cw_order_skus.ordersku_sku_total,
	cw_order_skus.ordersku_taxrate_id,
	cw_order_skus.ordersku_tax_rate,
	cw_order_skus.ordersku_unit_price,
	cw_sku_options.sku_option2option_id,
	cw_sku_options.sku_option2sku_id,
	cw_sku_options.sku_option_id
	</cfif>
	</cfquery>
	<!--- if there are no options  --->
	<cfelse>
	<!--- run a dummy query to return the blank column list --->
	<cfquery name="rsSelectOptionGroupOrders" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT
	cw_order_skus.ordersku_discount_amount,
	cw_order_skus.ordersku_id,
	cw_order_skus.ordersku_order_id,
	cw_order_skus.ordersku_quantity,
	cw_order_skus.ordersku_sku,
	cw_order_skus.ordersku_sku_total,
	cw_order_skus.ordersku_taxrate_id,
	cw_order_skus.ordersku_tax_rate,
	cw_order_skus.ordersku_unit_price,
	cw_sku_options.sku_option2option_id,
	cw_sku_options.sku_option2sku_id,
	cw_sku_options.sku_option_id
	FROM cw_order_skus, cw_sku_options
	WHERE cw_sku_options.sku_option2sku_id = cw_order_skus.ordersku_sku
	AND sku_option2option_id = 0
	</cfquery>
	</cfif>

	<cfreturn rsSelectOptionGroupOrders>
</cffunction>

<!--- // ---------- Get Option Details ---------- // --->
<cffunction name="CWquerySelectOptionDetails" access="public" output="false" returntype="query"
			hint="Returns all details about an option, by name or ID">

	<cfargument name="option_id" required="true" type="numeric"
				hint="ID of the option to lookup - pass in 0 to use name lookup instead">

	<cfargument name="option_name" required="false" default="" type="string"
				hint="Name of the Option to look up">

	<cfargument name="option_group" required="false" default="0" type="numeric"
				hint="ID of the option group">

<cfset var rsSelectOptionDetails = ''>
<cfquery name="rsSelectOptionDetails" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT * FROM cw_options WHERE
<cfif arguments.option_id>
option_id = #arguments.option_id#
<cfelse>
#application.cw.sqlLower#(option_name) ='#lcase(arguments.option_name)#'
</cfif>
<cfif arguments.option_group gt 0>
AND option_type_id = #arguments.option_group#
</cfif>
</cfquery>
<cfreturn rsSelectOptionDetails>
</cffunction>

<!--- // ---------- Get Options in Group ---------- // --->
<cffunction name="CWquerySelectGroupOptions" access="public" output="false" returntype="query"
			hint="Returns all options in an option group, with number of skus">

	<cfargument name="optiongroup_id" required="true" type="numeric"
				hint="ID of the option group to lookup">

<cfset var rsSelectGroupOptions = ''>
<cfquery name="rsSelectGroupOptions" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT option_id, option_type_id, option_name, option_sort, option_archive, option_text,
count(sku_option2sku_id) as optionSkuCount
FROM cw_options
LEFT OUTER JOIN cw_sku_options
ON cw_sku_options.sku_option2option_id = cw_options.option_id
WHERE option_type_id = #arguments.optiongroup_id#
GROUP BY option_id, option_type_id, option_name, option_sort, option_archive, option_text
ORDER BY option_sort, option_name
</cfquery>

<cfreturn rsSelectGroupOptions>
</cffunction>

<!--- // ---------- Insert Option ---------- // --->
<cffunction name="CWqueryInsertOption" access="public" output="false" returntype="string"
			hint="Inserts an option record - returns ID of the new option, or 0-message if unsuccessful">

	<!--- Name and group ID are required --->
	<cfargument name="option_name" required="true" type="string"
				hint="Name of the option">
	<cfargument name="option_group" required="true" type="string"
				hint="ID of the option group">
	<!--- others are optional --->
	<cfargument name="option_sort" required="false" default="0" type="numeric"
				hint="Sort order">
	<cfargument name="option_text" required="false" default="" type="string"
				hint="Text description">
	<cfargument name="option_archive" required="false" default="0" type="numeric"
				hint="Archived yes/no">

<cfset var newOptionID = ''>
<!--- first look up existing option by name --->
<cfset dupCheck = CWquerySelectOptionDetails(0,trim(arguments.option_name),arguments.option_group)>
<!--- if we have a duplicate, return an error message --->
<cfif dupCheck.recordCount>
<cfset newOptionID = '0-Name'>
<!--- if no duplicate, insert --->
<cfelse>
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
INSERT INTO cw_options (
option_name,
option_type_id,
option_sort,
option_text,
option_archive
) VALUES (
'#trim(arguments.option_name)#',
#arguments.option_group#,
#arguments.option_sort#,
'#trim(arguments.option_text)#',
#arguments.option_archive#
)
</cfquery>

<!--- get ID for return value --->
<cfquery name="getNewOptionID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT option_id
FROM cw_options
WHERE option_name = '#trim(arguments.option_name)#'
</cfquery>

<cfset newOptionID = getNewOptionID.option_id>
</cfif>

<cfreturn newOptionID>
</cffunction>

<!--- // ---------- Update Option ---------- // --->
<cffunction name="CWqueryUpdateOption" access="public" output="false" returntype="string"
			hint="Updates an Option record- returns ID of the updated option, or 0-message if unsuccessful">

	<!--- ID and name are required --->
	<cfargument name="option_id" required="true" type="numeric"
				hint="ID of the option to update">
	<cfargument name="option_name" required="true" type="string"
				hint="Name of the option">
	<cfargument name="option_group" required="true" type="string"
				hint="ID of the option group">
	<!--- others are optional --->
	<cfargument name="option_sort" required="false" default="0" type="numeric"
				hint="Sort order">
	<cfargument name="option_archive" required="false" default="0" type="numeric"
				hint="Archived yes/no">
	<cfargument name="option_text" required="false" default="" type="string"
				hint="Text description">

	<cfset var updateOptionID = ''>

	<!--- first look up existing option by name --->
	<cfset dupCheck = CWquerySelectOptionDetails(0,trim(arguments.option_name),arguments.option_group)>
	<!--- if we have a duplicate, return an error message --->
	<cfif dupCheck.recordCount and not dupCheck.option_id eq arguments.option_id>
	<cfset updateOptionID = '0-Name'>
	<!--- if no duplicate, insert --->
	<cfelse>

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			UPDATE cw_options
			SET
			option_name = '#arguments.option_name#',
			option_sort = #arguments.option_sort#,
			option_archive = #arguments.option_archive#,
			option_text = '#arguments.option_text#'
			WHERE option_id = #arguments.option_id#
			</cfquery>

	<cfset updateOptionID = arguments.option_id>
	</cfif>

	<cfreturn updateOptionID>

</cffunction>

<!--- // ---------- Archive Option ---------- // --->
<cffunction name="CWqueryArchiveOption" access="public" output="false" returntype="void"
			hint="Sets Archive status (1 or 0) on an Option record">

	<!--- ID and archive 1/0 are required --->
	<cfargument name="option_id" required="true" type="numeric"
				hint="ID of the option to update">
	<cfargument name="option_archive" required="true" default="0" type="boolean"
				hint="Archived yes/no, 1 = yes">

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			UPDATE cw_options
			SET option_archive = #arguments.option_archive#
			WHERE option_id = #arguments.option_id#
			</cfquery>

</cffunction>

<!--- // ---------- Delete Option ---------- // --->
<cffunction name="CWqueryDeleteOption" access="public" output="false" returntype="void"
			hint="Deletes a product option record by ID">

			<cfargument name="option_id" required="true" type="numeric"
						hint="ID of the option to delete">

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			DELETE FROM cw_options
			WHERE option_id = #arguments.option_id#
			</cfquery>

</cffunction>

<!--- // ---------- Insert Option Group ---------- // --->
<cffunction name="CWqueryInsertOptionGroup" access="public" output="false" returntype="string"
			hint="Inserts an option group record - returns ID of the new option group, or 0-message if unsuccessful">

	<!--- Name and group ID are required --->
	<cfargument name="optiongroup_name" required="true" type="string"
				hint="Name of the option">
	<!--- others are optional --->
	<cfargument name="optiongroup_sort" required="false" default="0" type="numeric"
				hint="Sort order">
	<cfargument name="optiongroup_text" required="false" default="" type="string"
				hint="Text description">
	<cfargument name="optiongroup_archive" required="false" default="0" type="numeric"
				hint="Archived yes/no">

<cfset var newOptionGroupID = '0-Name'>
<!--- first look up existing option by name --->
<cfset dupCheck = CWquerySelectOptionGroupDetails(0,trim(arguments.optiongroup_name))>
<!--- if we have a duplicate, return an error message
note: relational query with 'count' will always return one row --->
<cfif dupCheck.recordCount AND dupCheck.optiontype_id gt 0>
<cfset newOptionGroupID = '0-Name'>
<!--- if no duplicate, insert --->
<cfelse>
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
INSERT INTO cw_option_types(
optiontype_name,
optiontype_sort,
optiontype_text,
optiontype_archive
) VALUES (
'#trim(arguments.optiongroup_name)#',
#arguments.optiongroup_sort#,
'#trim(arguments.optiongroup_text)#',
#arguments.optiongroup_archive#
)
</cfquery>

<!--- get ID for return value --->
<cfquery name="getNewOptionGroupID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT optiontype_id
FROM cw_option_types
WHERE optiontype_name = '#trim(arguments.optiongroup_name)#'
</cfquery>

<cfset newOptionGroupID = getNewOptionGroupID.optiontype_id>
</cfif>

<cfreturn newOptionGroupID>
</cffunction>

<!--- // ---------- Delete Option Group ---------- // --->
<cffunction name="CWqueryDeleteOptionGroup" access="public" output="false" returntype="void"
			hint="Deletes an option group and all associated options. If orders or products exist, group is marked as deleted but not removed from db, options are archived">

	<cfargument name="optiongroup_id" required="true" type="numeric"
				hint="ID of the option group to delete">

	<!--- get a list of all option IDs in this group --->
	<cfset var groupOptionsQuery = CWquerySelectGroupOptions(arguments.optiongroup_id)>
	<!--- get all orderSKUs related to this option group --->
	<cfset var optionOrdersQuery = CWquerySelectOptionGroupOrders(arguments.optiongroup_id,0)>
	<cfset var optionOrders = valueList(optionOrdersQuery.sku_option2option_id)>
	<!--- lists for counting --->
	<cfset var deletedCt = 0>
	<cfset var archivedCt = 0>
	<cfset var relatedCt = 0>
	<cfset var archivedOption = ''>
	<cfset var deleteOption = ''>
	<cfset var checkOptionsQuery = ''>

			<!--- loop through the option IDs --->
			<cfoutput query="groupOptionsQuery">

			<!--- if the option has no skus it can be archived, and/or deleted--->
			<cfif groupOptionsQuery.optionSkuCount lt 1>

				<!--- if not already archived, archive the option --->
				<cfif groupOptionsQuery.option_archive neq 1>

				<!--- archive option record (id,archive) --->
				<cfset archiveOption = CWqueryArchiveOption(option_id,1)>

				</cfif>
				<!--- /END if not already archived --->

						<!--- if the option has no orders, it can be deleted --->
						<!--- check for the option ID in the list --->
						<cfif not listFind(optionOrders,option_id)>

				<!--- delete option record (id) --->
				<cfset deleteOption = CWqueryDeleteOption(option_id,1)>



							<!--- count as deleted --->
							<cfset deletedCt = deletedCt + 1>
							<!--- if not deleted, count as archived --->
							<cfelse>
							<cfset archivedCt = archivedCt + 1>
						</cfif>
						<!--- /END delete (no orders) --->
			<!--- if this option has skus, it cannot be deleted --->
			<cfelse>
			<!--- count as related --->
			<cfset relatedCt = relatedCt + 1>
			</cfif>
			<!--- /END archive (no skus)--->

			</cfoutput>
			<!--- /END option ID loop --->

	<!--- check for any remaining options --->
	<cfset checkOptionsQuery = CWquerySelectGroupOptions(arguments.optiongroup_id)>

	<!--- at this point, all unattached options have been deleted, or archived --->
	<!--- if we still have some options, but no active products attached, mark the group 'deleted' in database --->
	<cfif checkOptionsQuery.recordCount gt 0 AND relatedct eq 0>
	<!--- mark deleted, do not remove record --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	UPDATE cw_option_types
	SET optiontype_archive = 1,
	optiontype_deleted = 1
	WHERE optiontype_id = #arguments.optiongroup_id#
	</cfquery>

	<!--- else if all the options were deleted, delete the group --->
	<cfelseif checkOptionsQuery.recordCount is 0>
	<!--- delete, removing record from database--->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE from cw_option_types
	WHERE optiontype_id = #arguments.optiongroup_id#
	</cfquery>
	</cfif>
	<!--- /END if options still exist --->

</cffunction>

<!--- /////////////// --->
<!--- SHIPPING QUERIES --->
<!--- /////////////// --->

<!--- // ---------- Get Active or Archived Shipping Methods ---------- // --->
<cffunction name="CWquerySelectStatusShipMethods" access="public" output="false" returntype="query"
			hint="Returns a query containing active or archived shipping method details">

<cfargument name="records_active" default="1" type="numeric" required="false"
			hint="Set to 0 to return archived records">

	<cfset var compareTo = 1>
	<cfset var rsStatusShipping = ''>
<!--- set up opposite value so we can query with 'not' --->
<cfif arguments.records_active is 1>
	<cfset compareTo = 0>
</cfif>

<cfquery name="rsStatusShipping" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT cw_ship_methods.*,
cw_countries.country_name,
cw_countries.country_id
FROM (cw_ship_methods
	INNER JOIN cw_ship_method_countries
	ON cw_ship_methods.ship_method_id = cw_ship_method_countries.ship_method_country_method_id)
		INNER JOIN cw_countries
		ON cw_ship_method_countries.ship_method_country_country_id = cw_countries.country_id
WHERE NOT ship_method_archive = #compareTo#
ORDER BY cw_countries.country_sort, cw_countries.country_name,
cw_ship_methods.ship_method_sort, cw_ship_methods.ship_method_name
</cfquery>

<cfreturn rsStatusShipping>
</cffunction>

<!--- // ---------- Get Shipping Method Details ---------- // --->
<cffunction name="CWquerySelectShippingMethodDetails" access="public" output="false" returntype="query"
			hint="Returns a query with details about a given shipping method including country">

	<cfargument name="method_id" required="true" type="numeric"
				hint="ID of the record to look up">

	<cfset var rsShipMethodDetails = ''>
	<cfquery name="rsShipMethodDetails" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">

	</cfquery>

<cfreturn  rsShipMethodDetails>
</cffunction>

<!--- // ---------- Insert Ship Method ---------- // --->
<cffunction name="CWqueryInsertShippingMethod" access="public" output="false" returntype="numeric"
			hint="Inserts a new shipping method and related country record, returns the method ID or a 0- error message">

	<!--- Name and country ID are required --->
	<cfargument name="record_name" required="true" type="string"
				hint="Name of the option">
	<cfargument name="country_id" required="true" type="string"
				hint="ID of the related country">
	<!--- others are optional --->
	<cfargument name="record_rate" required="false" default="0" type="numeric"
				hint="Shipping Rate">
	<cfargument name="record_sort" required="false" default="0" type="numeric"
				hint="Sort order">
	<cfargument name="record_calctype" required="false" default="localcacl" type="string"
				hint="Calculation Type">
	<cfargument name="record_archive" required="false" default="0" type="numeric"
				hint="Archived yes/no">

	<cfset var NewID = "">
	<cfset var getNewID = "">
	<cftry>
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_ship_methods
	(
	ship_method_sort,
	ship_method_name,
	ship_method_rate,
	ship_method_calctype,
	ship_method_archive
	)
	VALUES
	(
	#arguments.record_sort#,
	'#arguments.record_name#',
	#arguments.record_rate#,
	'#arguments.record_calctype#',
	0
	)
	</cfquery>
	<!--- get the new method id we just added --->
	<cfquery name="getNewID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#" maxrows="1">
	SELECT ship_method_id AS newID
	FROM cw_ship_methods
	ORDER BY ship_method_id DESC
	</cfquery>
	<cfset newID = getNewID.newID>
	<!--- now add country / method relationship --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO
	cw_ship_method_countries
	(
	ship_method_country_method_id,
	ship_method_country_country_id
	)
	VALUES (
	#newID#,
	#arguments.country_id#
	)
	</cfquery>

<cfcatch>
	<cfset newID = '0-Error: ' & cfcatch.message>
</cfcatch>
</cftry>
<cfreturn newID>
</cffunction>

<!--- // ---------- Update Ship Method ---------- // --->
<cffunction name="CWqueryUpdateShippingMethod" access="public" output="false" returntype="void"
			hint="Updates a shipping method record">

	<!--- ID is required --->

	<cfargument name="record_id" required="true" type="numeric"
				hint="ID of the record to update">
	<!--- others are optional --->
	<cfargument name="record_name" required="true" type="string"
				hint="Name of the option">
	<cfargument name="record_rate" required="false" default="0" type="numeric"
				hint="Shipping Rate">
	<cfargument name="record_sort" required="false" default="0" type="numeric"
				hint="Sort order">
	<cfargument name="record_calctype" required="false" default="" type="string"
				hint="Calculation Type">
	<cfargument name="record_archive" required="false" default="0" type="numeric"
				hint="Archived yes/no">

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			UPDATE cw_ship_methods
			SET
			ship_method_name = '#arguments.record_name#',
			ship_method_rate = #arguments.record_rate#,
			ship_method_archive = #arguments.record_archive#,
			<cfif arguments.record_calctype neq ''>ship_method_calctype = '#arguments.record_calctype#',</cfif>
			ship_method_sort = #arguments.record_sort#
			WHERE ship_method_id = #arguments.record_id#
			</cfquery>

</cffunction>

<!--- // ---------- Delete Ship Method ---------- // --->
<cffunction name="CWqueryDeleteShippingMethod" access="public" output="false" returntype="void"
			hint="Delete a shipping method and associated country info">

	<cfargument name="record_id" required="true" type="numeric"
				hint="ID of the record to delete - pass in 0 to delete by country">

			<!--- DELETE Country Relationship --->
			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			DELETE FROM cw_ship_method_countries
			WHERE ship_method_country_method_id = #arguments.record_id#
			</cfquery>

			<!--- DELETE Method --->
			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			DELETE FROM cw_ship_methods
			WHERE ship_method_id = #arguments.record_id#
			</cfquery>

</cffunction>

<!--- // ---------- Get All Shipping Methods by country ---------- // --->
<cffunction name="CWquerySelectShippingMethods" access="public" output="false" returntype="query"
			hint="Returns a query containing all active shipping methods by country">

<cfargument name="country_id" required="false" type="numeric" default="0"
			hint="A country ID to look up">
<cfargument name="record_archive" required="false" type="numeric" default="0"
			hint="archived records y/n - pass in 2 to get all">

<cfset var rsGetMethods = "">
<!--- Get Shipping Method List --->
<cfquery name="rsGetMethods" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT
cw_ship_methods.ship_method_name,
cw_ship_methods.ship_method_id,
cw_ship_methods.ship_method_calctype,
cw_countries.country_name,
cw_countries.country_id
FROM (cw_ship_methods
	INNER JOIN cw_ship_method_countries
		ON cw_ship_methods.ship_method_id = cw_ship_method_countries.ship_method_country_method_id)
	INNER JOIN cw_countries
		ON cw_ship_method_countries.ship_method_country_country_id = cw_countries.country_id
		WHERE 1=1
		<cfif arguments.record_archive neq 2>
		AND ship_method_archive = #arguments.record_archive#
		</cfif>
		<cfif arguments.country_id gt 0>
		AND cw_ship_method_countries.ship_method_country_country_id = #arguments.country_id#
		</cfif>
ORDER BY
cw_countries.country_sort,
cw_countries.country_name,
cw_ship_methods.ship_method_sort,
cw_ship_methods.ship_method_name
</cfquery>

<cfreturn rsGetMethods>
</cffunction>

<!--- // ---------- Get Orders with a specific Ship Method ---------- // --->
<cffunction name="CWquerySelectShippingMethodOrders" access="public" output="false" returntype="query"
			hint="Returns a query with order IDs using a specified shipping method">

	<cfargument name="method_id" required="true" type="numeric"
				hint="ID of the record to look up">

	<cfset var rsShipMethodOrders = ''>
	<cfquery name="rsShipMethodOrders" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT order_id
	FROM cw_orders
	WHERE order_ship_method_id = #arguments.method_id#
	</cfquery>

<cfreturn  rsShipMethodOrders>
</cffunction>

<!--- // ---------- Get Shipping Ranges by country ---------- // --->
<cffunction name="CWquerySelectShippingCountryRanges" access="public" output="false" returntype="query"
			hint="Returns a query with shipping ranges by country">

<cfargument name="country_id" required="false" type="numeric" default="0"
			hint="A country ID to look up">
<cfargument name="record_archive" required="false" type="numeric" default="0"
			hint="archived records y/n - pass in 2 to get all">

<cfset var rsShipRanges = ''>
<!--- Get Record --->
<cfquery name="rsShipRanges" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT
cw_ship_ranges.*,
cw_ship_methods.ship_method_name,
cw_ship_methods.ship_method_id,
cw_ship_methods.ship_method_calctype,
cw_countries.country_name,
cw_countries.country_id
FROM cw_ship_ranges
	INNER JOIN
	((cw_ship_method_countries
	INNER JOIN cw_countries
		ON cw_ship_method_countries.ship_method_country_country_id = cw_countries.country_id)
	INNER JOIN cw_ship_methods
		ON cw_ship_method_countries.ship_method_country_method_id = cw_ship_methods.ship_method_id)
		ON cw_ship_ranges.ship_range_method_id = cw_ship_methods.ship_method_id
		WHERE 1=1
		<cfif arguments.record_archive neq 2>
		AND cw_ship_methods.ship_method_archive = #arguments.record_archive#
		</cfif>
		<cfif arguments.country_id gt 0>
		AND cw_ship_method_countries.ship_method_country_country_id = #arguments.country_id#
		</cfif>
ORDER BY
cw_countries.country_sort,
cw_countries.country_name,
cw_ship_methods.ship_method_sort,
cw_ship_methods.ship_method_name,
cw_ship_methods.ship_method_id,
cw_ship_ranges.ship_range_from,
cw_ship_ranges.ship_range_to
</cfquery>

<cfreturn  rsShipRanges>
</cffunction>

<!--- // ---------- Insert Ship Range ---------- // --->
<cffunction name="CWqueryInsertShippingRange" access="public" output="false" returntype="void"
			hint="Inserts a shipping range">

	<!--- all vars required --->
	<cfargument name="method_id" required="true" type="numeric"
				hint="Shipping method this range belongs to">
	<cfargument name="range_from" required="true" type="numeric"
				hint="Shipping range start value">
	<cfargument name="range_to" required="true" type="numeric"
				hint="Shipping range end value">
	<cfargument name="range_amount" required="true" type="numeric"
				hint="Shipping range amount">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
INSERT INTO cw_ship_ranges
(ship_range_method_id,
ship_range_from,
ship_range_to,
ship_range_amount
) VALUES (
#arguments.method_id#,
#arguments.range_from#,
#arguments.range_to#,
#CWsqlNumber(arguments.range_amount)#
)
</cfquery>

</cffunction>

<!--- // ---------- Update Ship Range ---------- // --->
<cffunction name="CWqueryUpdateShippingRange" access="public" output="false" returntype="void"
			hint="Updates a shipping range">

	<!--- all vars required --->
	<cfargument name="range_id" required="true" type="numeric"
				hint="Shipping range ID to update">
	<cfargument name="range_from" required="true" type="numeric"
				hint="Shipping range start value">
	<cfargument name="range_to" required="true" type="numeric"
				hint="Shipping range end value">
	<cfargument name="range_amount" required="true" type="numeric"
				hint="Shipping range amount">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
UPDATE cw_ship_ranges
SET
ship_range_from = #arguments.range_from#,
ship_range_to = #arguments.range_to#,
ship_range_amount = #CWsqlNumber(arguments.range_amount)#
WHERE ship_range_id = #arguments.range_id#
</cfquery>

</cffunction>

<!--- // ---------- Delete Ship Range ---------- // --->
<cffunction name="CWqueryDeleteShippingRange" access="public" output="false" returntype="void"
			hint="Delete a shipping range">

	<cfargument name="record_id" required="true" type="numeric"
				hint="ID of the record to delete - pass in ">

			<!--- DELETE ship range --->
			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			DELETE FROM cw_ship_ranges
			WHERE ship_range_id = #arguments.record_id#
			</cfquery>

</cffunction>

<!--- // ---------- Get Shipping Ranges with a specific Ship Method ---------- // --->
<cffunction name="CWquerySelectShippingMethodRanges" access="public" output="false" returntype="query"
			hint="Returns a query with ship range IDs using a specified shipping method">

	<cfargument name="method_id" required="true" type="numeric"
				hint="ID of the record to look up">

	<cfset var rsShipMethodRanges = ''>
	<cfquery name="rsShipMethodRanges" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT ship_range_id
	FROM cw_ship_ranges
	WHERE ship_range_method_id = #arguments.method_id#
	</cfquery>

<cfreturn  rsShipMethodRanges>
</cffunction>

<!--- // ---------- Update StateProv Shipping Extension ---------- // --->
<cffunction name="CWqueryUpdateShippingExtension" access="public" output="false" returntype="void"
			hint="Update a shipping extension record by ID">

		<cfargument name="update_id" type="string" required="true"
					hint="ID of the record to update">

		<cfargument name="ship_ext" type="numeric" required="true"
					hint="The shipping extension for this record">

		<cfargument name="tax_ext" type="numeric" required="false" default="0"
					hint="The tax extension for this record">

		<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		UPDATE cw_stateprov
		SET stateprov_ship_ext = #CWsqlNumber(arguments.ship_ext)#
		<cfif arguments.tax_ext gte 0>
			, stateprov_tax = #CWsqlNumber(arguments.tax_ext)#
		</cfif>
		WHERE stateprov_id = #arguments.update_id#
		</cfquery>

		</cffunction>

<!--- /////////////// --->
<!--- TAX QUERIES --->
<!--- /////////////// --->

<!--- // ---------- Get Tax Rates by region ---------- // --->
<cffunction name="CWquerySelectTaxRegionRates" access="public" output="false" returntype="query"
			hint="Returns a query of tax rates by region, within a specific group">

	<cfargument name="group_id" required="true" type="numeric"
				hint="The tax group ID to look up">

<cfset var rsTaxRates = ''>

<cfquery name="rsTaxRates" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT
cw_tax_regions.tax_region_id,
cw_tax_regions.tax_region_label,
cw_tax_rates.tax_rate_region_id,
cw_stateprov.stateprov_name,
cw_countries.country_name,
<cfif application.cw.appDbType eq 'mysql'>
CONCAT(cw_stateprov.stateprov_name,' : ',cw_countries.country_name) AS region_location,
<cfelse>
cw_stateprov.stateprov_name + ' : ' + cw_countries.country_name AS region_location,
</cfif>
cw_tax_rates.tax_rate_id,
cw_tax_rates.tax_rate_percentage
FROM (cw_stateprov
	RIGHT JOIN (cw_countries
		RIGHT JOIN cw_tax_regions ON cw_countries.country_id = cw_tax_regions.tax_region_country_id)
	ON cw_stateprov.stateprov_id = cw_tax_regions.tax_region_state_id)
	INNER JOIN cw_tax_rates
	ON cw_tax_regions.tax_region_id = cw_tax_rates.tax_rate_region_id
WHERE cw_tax_rates.tax_rate_group_id = #arguments.group_id#
</cfquery>

<cfreturn rsTaxRates>
</cffunction>

<!--- // ---------- Get Tax Rates by group ---------- // --->
<cffunction name="CWquerySelectTaxGroupRates" access="public" output="false" returntype="query"
			hint="Returns a query of tax rates by group, within a specific region">

	<cfargument name="region_id" required="true" type="numeric"
				hint="The tax region ID to look up">

<cfset var rsTaxRates = ''>

<cfquery name="rsTaxRates" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT cw_tax_rates.tax_rate_id,
cw_tax_rates.tax_rate_percentage,
cw_tax_groups.tax_group_name,
cw_tax_groups.tax_group_id
FROM cw_tax_groups, cw_tax_rates
WHERE cw_tax_groups.tax_group_id = cw_tax_rates.tax_rate_group_id
AND cw_tax_rates.tax_rate_region_id = #arguments.region_id#
ORDER BY tax_group_name
</cfquery>

<cfreturn rsTaxRates>
</cffunction>

<!--- // ---------- Get Tax Regions with StateProv/Country information ---------- // --->
<cffunction name="CWquerySelectTaxRegions" access="public" output="false" returntype="query"
			hint="Returns a query of tax regions">

	<cfargument name="region_id" required="true" type="numeric"
				hint="The tax region ID to look up - 0 returns all">

	<cfargument name="omit_list" required="false" default="0" type="string"
				hint="A list of IDs to omit">

	<cfargument name="region_name" required="false" default="" type="string"
				hint="Match tax region by name">

<cfset var rsTaxRegions = ''>
<cfquery name="rsTaxRegions" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT
cw_tax_regions.*,
cw_stateprov.stateprov_name,
cw_countries.country_name,
<cfif application.cw.appDbType eq 'mysql'>
CONCAT(cw_stateprov.stateprov_name,' : ',cw_countries.country_name) AS region_location,
<cfelse>
cw_stateprov.stateprov_name + ' : ' + cw_countries.country_name AS region_location,
</cfif>
cw_tax_groups.tax_group_name,
cw_tax_groups.tax_group_id
FROM (((cw_stateprov
		RIGHT JOIN cw_tax_regions
		ON cw_stateprov.stateprov_id = cw_tax_regions.tax_region_state_id)

		RIGHT JOIN cw_countries
		ON cw_countries.country_id = cw_tax_regions.tax_region_country_id)

		LEFT JOIN cw_tax_groups
		ON cw_tax_regions.tax_region_ship_tax_group_id = cw_tax_groups.tax_group_id)

<!--- omit any specified IDs --->
WHERE tax_region_id NOT IN (#arguments.omit_list#)
<!--- match ID --->
<cfif arguments.region_id neq 0>AND tax_region_id = #arguments.region_id#</cfif>
<!--- match Name --->
<cfif len(trim(arguments.region_name))>AND tax_region_label = '#arguments.region_name#'</cfif>
ORDER BY cw_countries.country_name, cw_stateprov.stateprov_name
</cfquery>

<cfreturn rsTaxRegions>
</cffunction>

<!--- // ---------- Insert Tax Region ---------- // --->
<cffunction name="CWqueryInsertTaxRegion" access="public" output="false" returntype="string"
			hint="Inserts a new tax region, returns the region ID or a 0- error message">

	<cfargument name="region_name" required="true" type="string"
				hint="Name of the tax region">

	<cfargument name="country_id" required="false" default="0" type="numeric"
				hint="ID of the related country">

	<cfargument name="state_id" required="false" default="0" type="numeric"
				hint="ID of the related state">

	<cfargument name="tax_id" required="false" default="0" type="string"
				hint="Tax or Vat Number">

	<cfargument name="show_tax_id" required="false" default="0" type="boolean"
				hint="show the tax ID y/n">

	<cfargument name="ship_tax_method" required="false" default="" type="string"
				hint="Shipping taxation method">

	<cfargument name="ship_tax_group" required="false" default="0" type="numeric"
				hint="Shipping tax group ID">

<cfset var getNewRecordID = ''>
<cfset var newRecordID =  ''>
<!--- first look up existing tax region --->
<cfset dupCheck = CWquerySelectTaxRegions(0,0,trim(arguments.region_name))>

<!--- if we have a duplicate, return an error message --->
<cfif dupCheck.recordCount>
<cfset newRecordID = "0-Name '#arguments.region_name#' already exists">
<!--- if no duplicate, insert --->
<cfelse>
		<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		INSERT INTO cw_tax_regions (
			tax_region_label,
			tax_region_country_id,
			tax_region_state_id,
			tax_region_tax_id,
			tax_region_show_id,
			tax_region_ship_tax_method,
			tax_region_ship_tax_group_id
			) VALUES (
			'#arguments.region_name#',
			#arguments.country_id#,
			#arguments.state_id#,
			'#arguments.tax_id#',
			#arguments.show_tax_id#,
			'#arguments.ship_tax_method#',
			#arguments.ship_tax_group#
			)
		</cfquery>

		<!--- get ID for return value --->
		<cfquery name="getNewRecordID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT tax_region_id
		FROM cw_tax_regions
		WHERE tax_region_label = '#trim(arguments.region_name)#'
		</cfquery>
		<cfset newRecordID = getNewRecordID.tax_region_id>

</cfif>

<cfreturn newRecordID>
</cffunction>

<!--- // ---------- Update Tax Region ---------- // --->
<cffunction name="CWqueryUpdateTaxRegion" access="public" output="false" returntype="string"
			hint="Update a tax region record">

	<cfargument name="region_id" required="true" type="numeric"
				hint="ID of the region to update">

	<cfargument name="tax_label" required="false" default="" type="string"
				hint="The name or label for this tax region">

	<cfargument name="tax_id" required="false" default="" type="string"
				hint="ID of the related tax">

	<cfargument name="show_tax_id" required="false" default="" type="string"
				hint="Show the tax ID y/n">

	<cfargument name="tax_method" required="false" default="" type="string"
				hint="Tax method">

	<cfargument name="tax_group_id" required="false" default="0" type="numeric"
				hint="Tax group Id">

<cfset var updatedID = ''>

	<!--- first look up existing tax region --->
	<cfset dupCheck = CWquerySelectTaxRegions(0,arguments.region_id,trim(arguments.tax_label))>

<!--- if we have a duplicate, return an error message --->
<cfif dupCheck.recordCount>
<cfset updatedID = "0-Name '#arguments.tax_label#' already exists">
<cfelse>

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
UPDATE cw_tax_regions
SET
tax_region_label = '#arguments.tax_label#',
tax_region_tax_id = '#arguments.tax_id#',
tax_region_show_id = #arguments.show_tax_id#,
tax_region_ship_tax_method = '#arguments.tax_method#',
tax_region_ship_tax_group_id = #arguments.tax_group_id#
WHERE tax_region_id = #arguments.region_id#
</cfquery>

<cfset updatedID = arguments.region_id>
</cfif>

<cfreturn updatedID>
</cffunction>

<!--- // ---------- Delete Tax Region ---------- // --->
<cffunction name="CWqueryDeleteTaxRegion" access="public" output="false" returntype="void"
			hint="Delete a tax region, by ID or by state">

		<cfargument name="record_id" required="false" default="0" type="numeric"
				hint="ID of the record to delete">
		<cfargument name="state_id" required="false" default="0" type="numeric"
				hint="ID of the state to delete all regions from">
		<cfargument name="country_id" required="false" default="0" type="numeric"
				hint="ID of the country to delete all regions from">

		<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE FROM cw_tax_regions
		WHERE 1=1
		<cfif arguments.record_id gt 0>AND tax_region_id = #arguments.record_id#</cfif>
		<cfif arguments.state_id gt 0>AND tax_region_state_id = #arguments.state_id#</cfif>
		<cfif arguments.country_id gt 0>AND tax_region_country_id = #arguments.country_id#</cfif>
		</cfquery>

</cffunction>

<!--- // ---------- List All Tax Groups ---------- // --->
<cffunction name="CWquerySelectTaxGroups" access="public" output="false" returntype="query"
			hint="Returns all Tax Groups or a specific tax group by ID (optional archived/active)">

	<cfargument name="show_archived" required="false" default="false" type="string"
				hint="True = archived, False = active, blank = show all">

	<cfargument name="group_id" required="false" default="0" type="boolean"
				hint="Restrict to a specific group ID">

<cfset var rsTaxGroups = "">
<cfquery name="rsTaxgroups" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT *
	FROM cw_tax_groups
	<cfif len(trim(arguments.show_archived))>
	WHERE
		<cfif arguments.show_archived eq false>NOT</cfif> tax_group_archive = 1
	</cfif>
	<cfif arguments.group_id gt 0>AND tax_group_id = #arguments.group_id#</cfif>
	ORDER BY tax_group_name ASC
</cfquery>
<cfreturn rsTaxGroups>
</cffunction>

<!--- // ---------- Get Products related to a tax group ---------- // --->
<cffunction name="CWquerySelectTaxGroupProducts" access="public" output="false" returntype="query"
			hint="Returns a query with products related to a specified tax group">

			<cfargument name="group_id" required="true" type="numeric"
						hint="ID of the group to look up">

		<cfset var rsProductTaxGroups = ''>

		<cfquery name="rsProductTaxGroups" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT product_tax_group_id, product_name, product_id
		FROM cw_products
		WHERE product_tax_group_id = #arguments.group_id#
		</cfquery>

		<cfreturn rsProductTaxgroups>
</cffunction>

<!--- // ---------- Get Tax Group details by id or name ---------- // --->
<cffunction name="CWquerySelectTaxGroupDetails" access="public" output="false" returntype="query"
			hint="Get tax group details">

	<cfargument name="group_id" required="true" type="numeric"
				hint="ID of the group to look up, use value of 0 to look up by name, or all">

	<cfargument name="omit_list" required="false" default="0" type="string"
				hint="A list of IDs to omit">

	<cfargument name="group_name" required="false" default="" type="string"
				hint="Name of the group to look up">

	<cfset var rsTaxGroup = ''>
	<cfquery name="rsTaxGroup" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT *
	FROM cw_tax_groups
	<!--- omit any specified IDs --->
	WHERE tax_group_id NOT IN (#arguments.omit_list#)
	<cfif arguments.group_id gt 0>
	AND tax_group_id = #arguments.group_id#
	</cfif>
	<cfif len(trim(arguments.group_name))>
	AND tax_group_name = '#arguments.group_name#'
	</cfif>
	</cfquery>

	<cfreturn rsTaxGroup>
</cffunction>

<!--- // ---------- Insert Tax Group ---------- // --->
<cffunction name="CWqueryInsertTaxGroup" access="public" output="false" returntype="string"
			hint="Inserts a new tax group, returns the group ID or a 0- error message">

	<!--- Name is required --->
	<cfargument name="group_name" required="true" type="string"
				hint="Name of the tax group">
	<!--- archive is optional --->
	<cfargument name="group_archive" required="false" default="0" type="boolean"
				hint="Archived yes/no">
	<!--- code is optional --->
	<cfargument name="group_code" required="false" default="00000" type="string"
				hint="Tax category designation">

<cfset var newRecordID = ''>
<cfset var getNewRecordID = ''>

<!--- first look up existing tax group --->
<cfset dupCheck = CWquerySelectTaxGroupDetails(0,0,trim(arguments.group_name))>

<!--- if we have a duplicate, return an error message --->
<cfif dupCheck.recordCount>
<cfset newRecordID = "0-Name '#arguments.group_name#' already exists">
<!--- if no duplicate, insert --->
<cfelse>
		<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		INSERT INTO cw_tax_groups (
		tax_group_name,
		tax_group_archive,
		tax_group_code
		)
		VALUES
		(
		'#trim(arguments.group_name)#',
		#arguments.group_archive#,
		'#trim(arguments.group_code)#'
		)
		</cfquery>

		<!--- get ID for return value --->
		<cfquery name="getNewRecordID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT tax_group_id
		FROM cw_tax_groups
		WHERE tax_group_name = '#trim(arguments.group_name)#'
		</cfquery>
		<cfset newRecordID = getNewRecordID.tax_group_id>

</cfif>

<cfreturn newRecordID>
</cffunction>

<!--- // ---------- Delete Tax Group ---------- // --->
<cffunction name="CWqueryDeleteTaxGroup" access="public" output="false" returntype="void"
			hint="Delete a tax group">

	<cfargument name="record_id" required="true" type="numeric"
				hint="ID of the record to delete">

			<!--- DELETE tax group --->
			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			DELETE FROM cw_tax_groups
			WHERE tax_group_id = #arguments.record_id#
			</cfquery>

</cffunction>

<!--- // ---------- Update Tax Group ---------- // --->
<cffunction name="CWqueryUpdateTaxGroup" access="public" output="false" returntype="string"
			hint="Updates a tax group's name and archive/active status, returns updated ID or 0- error">

	<cfargument name="record_id" required="true" type="numeric"
				hint="ID of the record to update">
	<cfargument name="group_archive" required="false" default="0" type="boolean"
				hint="Archived yes/no">
	<cfargument name="group_name" required="false" default="" type="string"
				hint="Name of the group, checked for duplicates">
	<cfargument name="group_code" required="false" default="" type="string"
				hint="Tax designation code, if blank, not changed (pass in value 00000 for none, or general)">

	<cfset var updatedID = ''>

	<cfif len(trim(arguments.group_name))>
	<!--- check for duplicates --->
	<cfset dupCheck = CWquerySelectTaxGroupDetails(0,arguments.record_id,trim(arguments.group_name))>
<!--- if we have a duplicate, return an error message --->
<cfif dupCheck.recordCount>
<cfset updatedID = '0-Name'>
	</cfif>
	</cfif>
<cfif not len(trim(updatedID))>
<!--- if no duplicate, insert --->
			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			UPDATE cw_tax_groups
			SET tax_group_archive = #arguments.group_archive#
			<!--- if group name provided --->
			<cfif len(trim(arguments.group_name))>,tax_group_name = '#trim(arguments.group_name)#'</cfif>
			<!--- if group code provided --->
			<cfif len(trim(arguments.group_code))>,tax_group_code = '#trim(arguments.group_code)#'</cfif>
			WHERE tax_group_id = #arguments.record_id#
			</cfquery>
			<cfset updatedID = arguments.record_id>
</cfif>
<cfreturn updatedID>
</cffunction>

<!--- // ---------- Insert Tax rate ---------- // --->
<cffunction name="CWqueryInsertTaxRate" access="public" output="false" returntype="numeric"
			hint="Inserts a new tax rate record, returns inserted ID">

	<cfargument name="region_id" required="true" type="numeric"
				hint="ID of the region for this tax rate">
	<cfargument name="group_id" required="true" type="numeric"
				hint="ID of the group for this tax rate">
	<cfargument name="tax_rate" required="false" default="0" type="numeric"
				hint="Tax Rate percentage">

	<cfset var newID = ''>
		<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		INSERT INTO cw_tax_rates (
		tax_rate_region_id,
		tax_rate_group_id,
		tax_rate_percentage
		)
		VALUES
		(
		#arguments.region_id#,
		#arguments.group_id#,
		#arguments.tax_rate#
		)
		</cfquery>

		<!--- get the new ID --->
	<cfquery name="getNewID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#" maxrows="1">
	SELECT tax_rate_region_id AS newID
	FROM cw_tax_rates
	ORDER BY tax_rate_region_id DESC
	</cfquery>
	<cfset newID = getNewID.newID>

<cfreturn newID>

</cffunction>

<!--- // ---------- Update Tax rate ---------- // --->
<cffunction name="CWqueryUpdateTaxRate" access="public" output="false" returntype="void"
			hint="Updates a tax rate record by ID">

	<cfargument name="record_id" required="true" type="numeric"
				hint="ID of the record to update">
	<cfargument name="tax_rate" required="false" default="0" type="numeric"
				hint="Tax Rate percentage">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
UPDATE cw_tax_rates
SET
tax_rate_percentage = #arguments.tax_rate#
WHERE tax_rate_id = #arguments.record_id#
</cfquery>

</cffunction>

<!--- // ---------- Delete Tax rate ---------- // --->
<cffunction name="CWqueryDeleteTaxRate" access="public" output="false" returntype="void"
			hint="Updates a tax rate record by ID">

	<cfargument name="record_id" required="true" type="numeric"
				hint="ID of the record to delete">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
DELETE FROM cw_tax_rates
WHERE tax_rate_id = #arguments.record_id#
</cfquery>

</cffunction>

<!--- // ---------- Update Product Tax Group ---------- // --->
<cffunction name="CWqueryUpdateProductTaxGroup" access="public" output="false" returntype="void"
			hint="Updates a product record Tax Group value">

	<cfargument name="record_id" required="true" type="numeric"
				hint="ID of the product to update">
	<cfargument name="group_id" required="true" type="numeric"
				hint="ID of the tax group to use">

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
UPDATE cw_products
SET product_tax_group_id = #arguments.group_id#
WHERE product_id = #arguments.record_id#
</cfquery>

</cffunction>

<!--- // ---------- // Set mandatory settings when not using localtax // ---------- // --->
<cffunction name="CWsetNonLocalTaxOptions"
			access="public"
			output="false"
			returntype="void"
			hint="Sets mandatory tax options for using remote lookup systems (e.g. AvaTax)"
			>

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
UPDATE cw_config_items
SET config_value = 'Groups'
WHERE config_variable = 'taxSystem'
</cfquery>

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
UPDATE cw_config_items
SET config_value = 'shipping'
WHERE config_variable = 'taxChargeBasedOn'
</cfquery>

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
UPDATE cw_config_items
SET config_value = 'false'
WHERE config_variable = 'taxUseDefaultCountry'
</cfquery>

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
UPDATE cw_config_items
SET config_value = 'false'
WHERE config_variable = 'taxDisplayOnProduct'
</cfquery>

</cffunction>

<!--- /////////////// --->
<!--- COUNTRY / REGION QUERIES --->
<!--- /////////////// --->

<!--- // ---------- Get ALL State/Provs ---------- // --->
<cffunction name="CWquerySelectStates" access="public" output="false" returntype="query"
			hint="Returns a query with all available states including country details">

			<cfargument name="country_id" required="false" default="0" type="numeric"
						hint="The Country ID to lookup. Default is 0 (all)">

<cfset var rsGetStateList = "">
<cfquery name="rsGetStateList" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT
	cw_countries.*,
	cw_stateprov.*
FROM cw_countries, cw_stateprov
WHERE cw_countries.country_id = cw_stateprov.stateprov_country_id
AND
	cw_stateprov.stateprov_archive = 0
	AND cw_countries.country_archive = 0
	<cfif arguments.country_id gt 0>
	AND cw_countries.country_id = #arguments.country_id#
	</cfif>
ORDER BY
	cw_countries.country_sort,
	cw_countries.country_name,
	cw_stateprov.stateprov_name
</cfquery>

<cfreturn rsGetStateList>
</cffunction>

<!--- // ---------- Get ALL Countries ---------- // --->
<cffunction name="CWquerySelectCountries" access="public" output="false" returntype="query"
			hint="Returns a query with all available countries">

		<cfargument name="show_archived" required="false" default="true" type="boolean"
					hint="Include archived countries (y/n)">

<cfset var rsGetCountryList = "">
<cfquery name="rsGetCountryList" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT country_id, country_name
FROM cw_countries
<cfif arguments.show_archived eq 0>
WHERE NOT country_archive = 1
</cfif>
ORDER BY country_name
</cfquery>

<cfreturn rsGetCountryList>
</cffunction>

<!--- // ---------- Get ALL State/Provs by country ---------- // --->
<cffunction name="CWquerySelectCountryStates" access="public" output="false" returntype="query"
			hint="Returns a query with all available countries">

		<cfargument name="states_archived" required="false" default="0" type="numeric"
					hint="Show archived or active countries (1=archived,0=active,)">

<cfset var rsCountryStatesList = "">
<cfquery name="rsCountryStatesList" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT
cw_countries.*,
cw_stateprov.*
FROM cw_countries
LEFT JOIN cw_stateprov
ON cw_countries.country_id = cw_stateprov.stateprov_country_id
<cfif arguments.states_archived neq 2>
WHERE cw_countries.country_archive = #arguments.states_archived#
</cfif>
ORDER BY country_sort, country_name, stateprov_name
</cfquery>

<cfreturn rsCountryStatesList>
</cffunction>

<!--- // ---------- Get Country IDs for user defined states ---------- // --->
<cffunction name="CWquerySelectStateCountryIDs" access="public" output="false" returntype="query"
			hint="Select country IDs with user defined states">

<cfset var rsGetStateCountryIDs = ''>

<cfquery name="rsGetStateCountryIDs" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT DISTINCT stateprov_country_id
FROM cw_stateprov
WHERE NOT #application.cw.sqlLower#(stateprov_name) in('none','all')
</cfquery>

<cfreturn rsGetStateCountryIDs>

</cffunction>

<!--- // ---------- Get Customer Regions ---------- // --->
<cffunction name="CWquerySelectCustomerCountries" access="public" output="false" returntype="query"
			hint="Select states and countries with customer address matches">

<cfset var rsSelectCustomerCountries = ''>

<cfquery name="rsSelectCustomerCountries" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT DISTINCT
c.customer_state_stateprov_id,
s.stateprov_country_id
FROM cw_customer_stateprov c, cw_stateprov s
WHERE s.stateprov_id = c.customer_state_stateprov_id
</cfquery>

<cfreturn rsSelectCustomerCountries>

</cffunction>

<!--- // ---------- Get ship methods with orders ---------- // --->
<cffunction name="CWquerySelectOrderShipMethods" access="public" output="false" returntype="query"
			hint="Select ship methods with orders recorded">

<cfset var rsUsedShippingMethodList = ''>

<cfquery name="rsUsedShippingMethodList" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT DISTINCT order_ship_method_id
FROM cw_orders
</cfquery>

<cfreturn rsUsedShippingMethodList>

</cffunction>

<!--- // ---------- Get states with customer address matches ---------- // --->
<cffunction name="CWquerySelectCustomerStates" access="public" output="false" returntype="query"
			hint="Select all states with customer record matches">

<cfset var rsUsedStatesList = ''>

<cfquery name="rsUsedStatesList" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT DISTINCT customer_state_stateprov_id
FROM cw_customer_stateprov
</cfquery>

<cfreturn rsUsedStatesList>

</cffunction>

<!--- // ---------- Get country shipping methods with orders attached ---------- // --->
<cffunction name="CWquerySelectShipCountries" access="public" output="false" returntype="query"
			hint="Select country shipping methods that have orders">

		<cfargument name="omit_list" required="false" default="0"
					hint="List of IDs to omit">

<cfset var rsUsedCountryList = ''>

<cfquery name="rsUsedCountryList" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT DISTINCT ship_method_country_country_id
FROM cw_ship_method_countries
WHERE ship_method_country_method_id
NOT IN (#arguments.omit_list#)
</cfquery>

<cfreturn rsUsedCountryList>

</cffunction>

<!--- // ---------- Get Country Details ---------- // --->
<cffunction name="CWquerySelectCountryDetails" access="public" output="false" returntype="query"
			hint="Look up country details by ID, name or code - at least one argument must match">

	<cfargument name="country_id" required="true" type="numeric"
				hint="ID of the country to look up - pass in 0 to select all IDs">
	<cfargument name="country_name" required="true" type="string"
				hint="Name of the country - pass in blank to select all names">
	<cfargument name="country_code" required="true" type="string"
				hint="Country processing code - pass in blank to select all codes">
	<cfargument name="omit_list" required="false" default="0" type="string"
		hint="A list of IDs to omit">

	<cfset var rsSelectCountry = ''>

		<!--- look up country --->
		<cfquery name="rsSelectCountry" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT *
		FROM cw_countries
		WHERE 1 = 1
		<cfif arguments.country_id gt 0>AND country_id = #arguments.country_id#</cfif>
		<cfif arguments.country_name gt 0>AND country_name = '#arguments.country_name#'</cfif>
		<cfif arguments.country_code gt 0>AND country_code = '#arguments.country_code#'</cfif>
		<cfif arguments.omit_list neq 0>AND NOT country_id in(#arguments.omit_list#)</cfif>
		</cfquery>

	<cfreturn rsSelectCountry>

</cffunction>

<!--- // ---------- Insert Country ---------- // --->
<cffunction name="CWqueryInsertCountry" access="public" output="false" returntype="string"
			hint="Inserts a country record - returns new ID or 0- error">

	<!--- Name and code are required --->
	<cfargument name="country_name" required="true" type="string"
				hint="Name of the country">
	<cfargument name="country_code" required="true" type="string"
				hint="Country processing code">
	<!--- others are optional --->
	<cfargument name="country_sort" required="false" default="0" type="string"
				hint="Country sort order">
	<cfargument name="country_archive" required="false" default="0" type="string"
				hint="Archive Y/N">
	<cfargument name="country_default" required="false" default="0" type="string"
				hint="Default Country Y/N">

	<cfset var newRecordID = ''>
	<cfset var getNewID = ''>
	<cfset var errorMsg = ''>

<!--- check for duplicates by name --->
<cfset dupNameCheck = CWquerySelectCountryDetails(0,arguments.country_name,'')>
<!--- if we have a duplicate, return an error message --->
<cfif dupNameCheck.recordCount>
<cfset errorMsg = errorMsg & "<br>Country Name '#arguments.country_name#' already exists">
</cfif>

<!--- check for duplicates by code --->
<cfset dupCodeCheck = CWquerySelectCountryDetails(0,'',arguments.country_code)>
<!--- if we have a duplicate, return an error message --->
<cfif dupCodeCheck.recordCount>
<cfset errorMsg = errorMsg & "<br>Code '#arguments.country_code#' already exists">
</cfif>

<!--- if no duplicate, insert --->
<cfif not len(trim(errorMsg))>
		<!--- insert record --->
		<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		INSERT INTO cw_countries
		(
		country_name,
		country_code,
		country_sort,
		country_archive,
		country_default_country
		)
		VALUES (
		'#arguments.country_name#',
		'#arguments.country_code#',
		#arguments.country_sort#,
		#arguments.country_archive#,
		#arguments.country_default#
		)
		</cfquery>

		<!--- Get the new ID --->
		<cfquery name="getNewID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT country_id FROM cw_countries
		WHERE country_name = '#arguments.country_name#'
		AND country_code = '#arguments.country_code#'
		</cfquery>

	<cfset newRecordID = getnewID.country_id>

<!--- if we did have a duplicate, return error code --->
<cfelse>
<cfset newRecordID = '0-Error: #errorMsg#'>
</cfif>

<cfreturn newRecordID>

</cffunction>

<!--- // ---------- Update Country ---------- // --->
<cffunction name="CWqueryUpdateCountry" access="public" output="false" returntype="string"
			hint="Update a country record - returns updated ID or 0- error message">

<!--- id is required --->
		<cfargument name="country_id" type="numeric" required="true"
					hint="ID of the country to update">

<!--- others are optional --->
		<cfargument name="country_name" type="string" required="false" default=""
					hint="Name of the country">
		<cfargument name="country_code" type="string" required="true" default=""
					hint="country processing code">
		<cfargument name="country_archive" required="false" default="2" type="string"
					hint="Archive Y/N">
		<cfargument name="country_sort" required="false" default="0" type="numeric"
					hint="Sort order - skipped if 0">
		<cfargument name="country_default" required="false" default="0" type="boolean"
					hint="Set as default country y/n">


<cfset var errorMsg = ''>
<cfset var updatedID = ''>


<!--- check for duplicates by name --->
<cfset dupNameCheck = CWquerySelectCountryDetails(0,arguments.country_name,'',arguments.country_id)>
<!--- if we have a duplicate, return an error message --->
<cfif dupNameCheck.recordCount>
<cfset errorMsg = errorMsg & "<br>Country Name '#arguments.country_name#' already exists">
</cfif>

<!--- check for duplicates by code --->
<cfset dupCodeCheck = CWquerySelectCountryDetails(0,'',arguments.country_code,arguments.country_id)>
<!--- if we have a duplicate, return an error message --->
<cfif dupCodeCheck.recordCount>
<cfset errorMsg = errorMsg & "<br>Code '#arguments.country_code#' already exists">
</cfif>

<!--- if no duplicate, insert --->
<cfif not len(trim(errorMsg))>

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			UPDATE cw_countries
				SET country_default_country = #arguments.country_default#
				<cfif len(trim(arguments.country_name))>
					,country_name = '#trim(arguments.country_name)#'
				</cfif>
				<cfif len(trim(arguments.country_code))>
					,country_code = '#trim(arguments.country_code)#'
				</cfif>
				<cfif arguments.country_archive neq 2>
					,country_archive = #arguments.country_archive#
				</cfif>
				<cfif arguments.country_sort neq 0>
					,country_sort = #arguments.country_sort#
				</cfif>
					WHERE country_id = #arguments.country_id#
			</cfquery>
				<cfset updatedID = arguments.country_id>
				<!--- if default country, set all others to non-default --->
				<cfif arguments.country_default>
					<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
					UPDATE cw_countries
					SET country_default_country = 0
					WHERE NOT country_id = #arguments.country_id#
					</cfquery>
				</cfif>
				
<!--- if error message, return string --->
<cfelse>
<cfset updatedID  = '0-Error: #errorMsg#'>

</cfif>
<!--- /end if error message --->

<cfreturn updatedID>

</cffunction>

<!--- // ---------- Delete Country ---------- // --->
<cffunction name="CWqueryDeleteCountry" access="public" output="false" returntype="void"
			hint="Delete a country record">

<cfargument name="country_id" required="true" type="numeric"
			hint="ID of the country to delete">

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			DELETE FROM cw_countries
			WHERE country_id = #arguments.country_id#
			</cfquery>


</cffunction>

<!--- // ---------- Get State/Prov Details ---------- // --->
<cffunction name="CWquerySelectStateProvDetails" access="public" output="false" returntype="query"
			hint="Look up stateprov details by ID, name or code - at least one argument must match">

	<cfargument name="stateprov_id" required="true" type="numeric"
				hint="ID of the stateprov to look up - pass in 0 to select all IDs">
	<cfargument name="stateprov_name" required="true" type="string"
				hint="Name of the stateprov - pass in blank '' to select all names">
	<cfargument name="stateprov_code" required="true" type="string"
				hint="Stateprov processing code - pass in blank '' to select all codes">
	<cfargument name="country_id" required="false" default="0" type="any"
				hint="Stateprov related country ID - pass in 0 or blank to select all countries">
	<cfargument name="omit_list" required="false" default="0" type="string"
		hint="A list of IDs to omit">

	<cfset var rsSelectStateProv = ''>

		<!--- look up stateprov --->
		<cfquery name="rsSelectStateProv" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT *
		FROM cw_stateprov
		WHERE 1 = 1
		<cfif arguments.stateprov_id gt 0>AND stateprov_id = #arguments.stateprov_id#</cfif>
		<cfif arguments.stateprov_name gt 0>AND stateprov_name = '#arguments.stateprov_name#'</cfif>
		<cfif arguments.stateprov_code gt 0>AND stateprov_code = '#arguments.stateprov_code#'</cfif>
		<cfif arguments.country_id gt 0>AND stateprov_country_id = #arguments.country_id#</cfif>
		<cfif arguments.omit_list neq 0>AND NOT stateprov_id in(#arguments.omit_list#)</cfif>
		</cfquery>

	<cfreturn rsSelectStateProv>

</cffunction>

<!--- // ---------- Insert State/Prov ---------- // --->
<cffunction name="CWqueryInsertStateProv" access="public" output="false" returntype="string"
			hint="Inserts a stateprov record - returns new ID or 0- error">

	<!--- Name, code and country are required --->
	<cfargument name="stateprov_name" required="true" type="string"
				hint="Name of the stateprov">
	<cfargument name="stateprov_code" required="true" type="string"
				hint="StateProv processing code">
	<cfargument name="country_id" required="true" type="string"
				hint="Country ID for related country">
	<!--- others are optional --->
	<cfargument name="stateprov_archive" required="false" default="0" type="string"
				hint="Archive Y/N">
	<cfargument name="stateprov_tax" required="false" default="0" type="string"
				hint="Tax Rate">
	<cfargument name="stateprov_ship_ext" required="false" default="0" type="string"
				hint="Shipping Extension">

	<cfset var newRecordID = ''>
	<cfset var getNewID = ''>
	<cfset var errorMsg = ''>

<!--- check for duplicates by name, in given country --->
<cfset dupNameCheck = CWquerySelectStateProvDetails(0,arguments.stateprov_name,'',arguments.country_id)>
<!--- if we have a duplicate, return an error message --->
<cfif dupNameCheck.recordCount>
<cfset errorMsg = errorMsg & "<br>Region Name '#arguments.stateprov_name#' already exists">
</cfif>

<!--- check for duplicates by code, in given country --->
<cfset dupCodeCheck = CWquerySelectStateProvDetails(0,'',arguments.stateprov_code,arguments.country_id)>
<!--- if we have a duplicate, return an error message --->
<cfif dupCodeCheck.recordCount>
<cfset errorMsg = errorMsg & "<br>Code '#arguments.stateprov_code#' already exists">
</cfif>

<!--- if no duplicate, insert --->
<cfif not len(trim(errorMsg))>
		<!--- insert record --->
		<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		INSERT INTO cw_stateprov
		(
		stateprov_name,
		stateprov_code,
		stateprov_country_id,
		stateprov_archive,
		stateprov_tax,
		stateprov_ship_ext
		)
		VALUES
		(
		'#arguments.stateprov_name#',
		'#arguments.stateprov_code#',
		#arguments.country_id#,
		#arguments.stateprov_archive#,
		#arguments.stateprov_tax#,
		#arguments.stateprov_ship_ext#
		)
		</cfquery>

		<!--- Get the new ID --->
		<cfquery name="getNewID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT stateprov_id FROM cw_stateprov
		WHERE stateprov_name = '#arguments.stateprov_name#'
		AND stateprov_code = '#arguments.stateprov_code#'
		AND stateprov_country_id = #arguments.country_id#
		</cfquery>

	<cfset newRecordID = getnewID.stateprov_id>

<!--- if we did have a duplicate, return error code --->
<cfelse>
<cfset newRecordID = '0-Error: #errorMsg#'>
</cfif>

<cfreturn newRecordID>

</cffunction>

<!--- // ---------- Update State/Prov ---------- // --->
<cffunction name="CWqueryUpdateStateProv" access="public" output="false" returntype="string"
			hint="Update a stateprov record - returns updated ID or 0- error message">

<!--- id is required --->
		<cfargument name="stateprov_id" type="numeric" required="true"
					hint="ID of the record to update">

<!--- others are optional --->
		<cfargument name="stateprov_name" type="string" required="false" default=""
					hint="Name of the stateprov">
		<cfargument name="stateprov_code" type="string" required="false" default=""
					hint="Stateprov processing code">
		<cfargument name="stateprov_archive" required="false" default="2" type="string"
					hint="Archive Y/N">
		<cfargument name="stateprov_nexus" required="false" default="2" type="string"
					hint="Tax Applicable Y/N">

<cfset var updatedID = ''>
<cfset var errorMsg = ''>
<cfset var checkCountry = ''>
<cfset var countryID = ''>

<!--- get country of this stateprov --->
<cfset checkCountry = CWquerySelectStateProvDetails(arguments.stateprov_id,'','',0)>
<cfset countryID = checkCountry.stateprov_country_id>

<!--- check for duplicates by name, in given country --->
<cfset dupNameCheck = CWquerySelectStateProvDetails(0,arguments.stateprov_name,'',countryID,arguments.stateprov_id)>
<!--- if we have a duplicate, return an error message --->
<cfif dupNameCheck.recordCount>
<cfset errorMsg = errorMsg & "<br>Region Name '#arguments.stateprov_name#' already exists">
</cfif>

<!--- check for duplicates by code, in given country --->
<cfset dupCodeCheck = CWquerySelectStateProvDetails(0,'',arguments.stateprov_code,countryID,arguments.stateprov_id)>
<!--- if we have a duplicate, return an error message --->
<cfif dupCodeCheck.recordCount>
<cfset errorMsg = errorMsg & "<br>Code '#arguments.stateprov_code#' already exists">
</cfif>

<!--- if no duplicate, update --->
<cfif not len(trim(errorMsg))>

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			UPDATE cw_stateprov
				SET stateprov_country_id = #countryID#
					<cfif len(trim(arguments.stateprov_name))>
						,stateprov_name = '#arguments.stateprov_name#'
					</cfif>
					<cfif len(trim(arguments.stateprov_code))>
						,stateprov_code = '#arguments.stateprov_code#'
					</cfif>
					<cfif arguments.stateprov_archive neq 2>
						,stateprov_archive = #arguments.stateprov_archive#
					</cfif>
					<cfif arguments.stateprov_nexus neq 2>
						,stateprov_nexus = #arguments.stateprov_nexus#
					</cfif>
				WHERE stateprov_id=#arguments.stateprov_id#
			</cfquery>
			<cfset updatedID = arguments.stateprov_id>

<!--- if error message, return string --->
<cfelse>
<cfset updatedID  = '0-Error: #errorMsg#'>

</cfif>

<cfreturn updatedID>

</cffunction>

<!--- // ---------- Archive State/Prov ---------- // --->
<cffunction name="CWqueryArchiveStateProv" access="public" output="false" returntype="void"
			hint="Archives or activates stateprov records based on Country ID, name, and/or code">

	<!--- archive status is required --->
	<cfargument name="stateprov_archive" required="true" type="numeric"
				hint="1 = Archived, 0 = Active">
	<!--- others are not required: leave all 0/blank to archive or update all stateprovs --->
	<cfargument name="country_id" required="false" default="0" type="string"
				hint="Country ID (or list of IDs) to update">
	<cfargument name="stateprov_name" required="false" default="" type="string"
				hint="Name of the stateprov (or list of names)">
	<cfargument name="stateprov_code" required="false" default="" type="string"
				hint="StateProv processing code (or list of codes) ">
	<cfargument name="omit_id_list" required="false" default="0" type="string"
				hint="List of Ids to omit from update">


		<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		UPDATE cw_stateprov
		SET stateprov_archive = #arguments.stateprov_archive#
		WHERE 1=1
		<cfif arguments.country_id neq 0>
		AND stateprov_country_id in(#arguments.country_id#)
		</cfif>
		<cfif arguments.stateprov_name neq ''>
		AND #application.cw.sqlLower#(stateprov_name) in(#arguments.stateprov_name#)
		</cfif>
		<cfif arguments.stateprov_code neq ''>
		AND #application.cw.sqlLower#(stateprov_code) in('#arguments.stateprov_code#')
		</cfif>
		<cfif arguments.omit_id_list neq 0>
		AND NOT stateprov_country_id in(#arguments.omit_id_list#)
		</cfif>

		</cfquery>

</cffunction>

<!--- // ---------- Delete State/Prov ---------- // --->
<cffunction name="CWqueryDeleteStateProv" access="public" output="false" returntype="void"
			hint="Delete a state/prov record">

<cfargument name="state_id" required="true" type="numeric"
			hint="State/prov record to delete - pass in 0 to select by country">
<cfargument name="country_id" required="false" default="0" type="numeric"
			hint="State/prov country ID to delete - pass in 0 to select by state">

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			DELETE FROM cw_stateprov
			WHERE 1 = 1
			<cfif arguments.state_id gt 0>AND stateprov_id = #arguments.state_id#</cfif>
			<cfif arguments.country_id gt 0>AND stateprov_country_id = #arguments.country_id#</cfif>
			</cfquery>


</cffunction>

<!--- // ---------- Get Countries with active stateprovs ---------- // --->
<cffunction name="CWquerySelectUserStateProvCountries" access="public" output="false" returntype="query"
			hint="Select country IDs with active user-assigned state provs">

<cfset var rsCheckActive = ''>

	<cfquery name="rsCheckActive" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT DISTINCT c.country_id
	FROM cw_countries c, cw_stateprov s
	WHERE c.country_id = s.stateprov_country_id
	AND s.stateprov_archive = 0
	AND NOT #application.cw.sqlLower#(s.stateprov_code) in('none,all')
	</cfquery>

<cfreturn rsCheckActive>
</cffunction>

<!--- /////////////// --->
<!--- PRODUCT GLOBALS --->
<!--- /////////////// --->

<!--- // ---------- Get ALL categories ---------- // --->
<cffunction name="CWquerySelectCategories" access="public" output="false" returntype="query"
			hint="Returns all categories">

<cfset var rsCategories = "">
<cfquery name="rsCategories" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT *
	FROM cw_categories_primary
	ORDER BY category_sort, category_name
</cfquery>
<cfreturn rsCategories>
</cffunction>

<!--- // ---------- Get ALL secondary categories ---------- // --->
<cffunction name="CWquerySelectScndCategories" access="public" output="false" returntype="query"
			hint="Returns all secondary categories">

<cfset var rsScndCategories = "">
<cfquery name="rsScndCategories" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT * FROM cw_categories_secondary
	ORDER BY secondary_sort, secondary_name
</cfquery>
<cfreturn rsScndCategories>
</cffunction>

<!--- /////////////// --->
<!--- CREDIT CARD QUERIES --->
<!--- /////////////// --->

<!--- // ---------- Get All Credit Cards ---------- // --->
<cffunction name="CWquerySelectCreditCards" access="public" output="false" returntype="query"
			hint="Returns a query with all credit card names and codes">

<cfset var rsCCardList = ''>
<cfquery name="rsCCardList" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT * FROM cw_credit_cards
ORDER BY creditcard_name
</cfquery>

<cfreturn rsCCardList>
</cffunction>

<!--- // ---------- Get Credit Card Details ---------- // --->
<cffunction name="CWquerySelectCreditCardDetails" access="public" output="false" returntype="query"
			hint="Look up credit card details by ID, name or code - at least one argument must match">

	<cfargument name="creditcard_id" required="true" type="numeric"
				hint="ID of the Credit Card to look up - pass in 0 to select all IDs">
	<cfargument name="creditcard_name" required="true" type="string"
				hint="Name of the Credit Card - pass in blank '' to select all names">
	<cfargument name="creditcard_code" required="true" type="string"
				hint="Credit Card processing code - pass in blank '' to select all codes">
	<cfargument name="omit_id_list" required="false" default="0" type="string"
				hint="List of Ids to omit from update">

	<cfset var rsSelectcreditCard = ''>

		<!--- look up creditCard --->
		<cfquery name="rsSelectcreditCard" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT *
		FROM cw_credit_cards
		WHERE 1 = 1
		<cfif arguments.creditcard_id gt 0>AND creditcard_id = #arguments.creditcard_id#</cfif>
		<cfif len(trim(arguments.creditcard_name))>AND creditcard_name = '#arguments.creditcard_name#'</cfif>
		<cfif len(trim(arguments.creditcard_code))>AND creditcard_code = '#arguments.creditcard_code#'</cfif>
		<cfif arguments.omit_id_list neq 0>
		AND NOT creditcard_id in(#arguments.omit_id_list#)
		</cfif>
		</cfquery>

	<cfreturn rsSelectcreditCard>

</cffunction>

<!--- // ---------- Insert Credit Card ---------- // --->
<cffunction name="CWqueryInsertCreditCard" access="public" output="false" returntype="string"
			hint="Inserts a credit card record - returns new ID or 0- error">

	<!--- Name and code are required --->
	<cfargument name="creditcard_name" required="true" type="string"
				hint="Name of the credit card">
	<cfargument name="creditcard_code" required="true" type="string"
				hint="Credit Card processing code">

	<cfset var newRecordID = ''>
	<cfset var getNewID = ''>
	<cfset var errorMsg = ''>

<!--- check for duplicates by name  --->
<cfset dupNameCheck = CWquerySelectCreditCardDetails(0,arguments.creditcard_name,'')>
<!--- if we have a duplicate, return an error message --->
<cfif dupNameCheck.recordCount>
<cfset errorMsg = errorMsg & "<br>Card Name '#arguments.creditcard_name#' already exists">
</cfif>

<!--- check for duplicates by code --->
<cfset dupCodeCheck = CWquerySelectCreditCardDetails(0,'',arguments.creditcard_code)>
<!--- if we have a duplicate, return an error message --->
<cfif dupCodeCheck.recordCount>
<cfset errorMsg = errorMsg & "<br>Code '#arguments.creditcard_code#' already exists">
</cfif>

<!--- if no duplicate, insert --->
<cfif not len(trim(errorMsg))>
		<!--- insert record --->
		<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		INSERT INTO cw_credit_cards
		(
		creditcard_name,
		creditcard_code
		)
		VALUES
		(
		'#arguments.creditcard_name#',
		'#arguments.creditcard_code#'
		)
		</cfquery>


		<!--- Get the new ID --->
		<cfquery name="getNewID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT creditcard_id
		FROM cw_credit_cards
		WHERE creditcard_name = '#arguments.creditcard_name#'
		AND creditcard_code = '#arguments.creditcard_code#'
		</cfquery>

	<cfset newRecordID = getnewID.creditcard_id>

<!--- if we did have a duplicate, return error code --->
<cfelse>
<cfset newRecordID = '0-Error: #errorMsg#'>
</cfif>

<cfreturn newRecordID>

</cffunction>

<!--- // ---------- Update Credit Card ---------- // --->
<cffunction name="CWqueryUpdateCreditCard" access="public" output="false" returntype="string"
			hint="Update a credit card record - returns updated ID or 0- error message">

<!--- id is required --->
		<cfargument name="creditcard_id" type="numeric" required="true"
					hint="ID of the record to update">

<!--- others are optional --->
		<cfargument name="creditcard_name" type="string" required="false" default=""
					hint="Name of the credit card">
		<cfargument name="creditcard_code" type="string" required="false" default=""
					hint="Credit Card processing code">

<cfset var updatedID = ''>
<cfset var errorMsg = ''>


<!--- check for duplicates by name  --->
<cfset dupNameCheck = CWquerySelectCreditCardDetails(0,arguments.creditcard_name,'',arguments.creditcard_id)>
<!--- if we have a duplicate, return an error message --->
<cfif dupNameCheck.recordCount>
<cfset errorMsg = errorMsg & "<br>Card Name '#arguments.creditcard_name#' already exists">
</cfif>

<!--- check for duplicates by code --->
<cfset dupCodeCheck = CWquerySelectCreditCardDetails(0,'',arguments.creditcard_code,arguments.creditcard_id)>
<!--- if we have a duplicate, return an error message --->
<cfif dupCodeCheck.recordCount>
<cfset errorMsg = errorMsg & "<br>Code '#arguments.creditcard_code#' already exists">
</cfif>

<!--- if no duplicate, update --->
<cfif not len(trim(errorMsg))>

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			UPDATE cw_credit_cards
			SET
			creditcard_archive = creditcard_archive
			<cfif len(trim(arguments.creditcard_code))>
			,creditcard_code = '#arguments.creditcard_code#'
			</cfif>
			<cfif len(trim(arguments.creditcard_name))>
			,creditcard_name = '#arguments.creditcard_name#'
			</cfif>
			WHERE creditcard_id = #arguments.creditcard_id#
			</cfquery>
			<cfset updatedID = arguments.creditcard_id>

<!--- if error message, return string --->
<cfelse>
<cfset updatedID  = '0-Error: #errorMsg#'>

</cfif>

<cfreturn updatedID>

</cffunction>

<!--- // ---------- Delete Credit Card ---------- // --->
<cffunction name="CWqueryDeleteCreditCard" access="public" output="false" returntype="void"
			hint="Delete a credit card record">

<cfargument name="creditcard_id" required="true" type="numeric"
			hint="ID of the credit card to delete">

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			DELETE FROM cw_credit_cards
			WHERE creditcard_id = #arguments.creditcard_id#
			</cfquery>

</cffunction>

<!--- /////////// --->
<!--- CONFIG GROUPS --->
<!--- /////////// --->

<!--- // ---------- Select All Config Groups ---------- // --->
<cffunction name="CWquerySelectConfigGroups" access="public" output="false" returntype="query"
			hint="Returns a query with all config groups">

<cfset var rsConfigGroups = ''>
<cfquery name="rsConfigGroups" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT *
FROM cw_config_groups
ORDER BY config_group_sort, config_group_name
</cfquery>

<cfreturn rsConfigGroups>
</cffunction>

<!--- // ---------- Get Config Group Details ---------- // --->
<cffunction name="CWquerySelectConfigGroupDetails" access="public" output="false" returntype="query"
			hint="Look up config group details by ID or name - at least one argument must match">

<!--- name and ID are required, can be passed in as 0 or '' --->
	<cfargument name="config_group_id" required="true" type="numeric"
				hint="ID of the Config Group to look up - pass in 0 to select all IDs">
	<cfargument name="config_group_name" required="true" type="string"
				hint="Name of the Config Group - pass in blank '' to select all names">
	<cfargument name="omit_id_list" required="false" default="0" type="string"
				hint="List of Ids to omit from update">

	<cfset var rsSelectConfigGroup = ''>

		<!--- look up configGroup --->
		<cfquery name="rsSelectConfigGroup" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT *
		FROM cw_config_groups
		WHERE 1 = 1
		<cfif arguments.config_group_id gt 0>AND config_group_id = #arguments.config_group_id#</cfif>
		<cfif len(trim(arguments.config_group_name))>AND config_group_name = '#arguments.config_group_name#'</cfif>
		<cfif arguments.omit_id_list neq 0>
		AND NOT config_group_id in(#arguments.omit_id_list#)
		</cfif>
		</cfquery>

	<cfreturn rsSelectConfigGroup>

</cffunction>

<!--- // ---------- Insert Config Group ---------- // --->
<cffunction name="CWqueryInsertConfigGroup" access="public" output="false" returntype="string"
			hint="Inserts a config group record - returns new ID or 0- error">

	<!--- Name is required --->
	<cfargument name="config_group_name" required="true" type="string"
				hint="Name of the config group">
<!--- others are optional --->
		<cfargument name="config_group_sort" type="numeric" required="false" default="1"
					hint="Sort order">
		<cfargument name="config_group_showmerchant" type="boolean" required="false" default="0"
					hint="Show config group to lower user levels y/n">
		<cfargument name="config_group_protected" type="boolean" required="false" default="0"
					hint="Config group protected from deletion y/n">
		<cfargument name="config_group_description" type="string" required="false" default=""
					hint="Description/instructions for this config group">

	<cfset var newRecordID = ''>
	<cfset var getNewID = ''>
	<cfset var errorMsg = ''>

<!--- check for duplicates by name  --->
<cfset dupNameCheck = CWquerySelectConfigGroupDetails(0,arguments.config_group_name)>
<!--- if we have a duplicate, return an error message --->
<cfif dupNameCheck.recordCount>
<cfset errorMsg = errorMsg & "<br>Group Name '#arguments.config_group_name#' already exists">
</cfif>

<!--- if no duplicate, insert --->
<cfif not len(trim(errorMsg))>
		<!--- insert record --->
		<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		INSERT INTO cw_config_groups
		(
		config_group_name,
		config_group_sort,
		config_group_show_merchant,
		config_group_protected,
		config_group_description
		)
		VALUES (
		'#arguments.config_group_name#',
		#arguments.config_group_sort#,
		#arguments.config_group_showmerchant#,
		#arguments.config_group_protected#,
		'#arguments.config_group_description#'
		)
		</cfquery>

		<!--- get the new ID --->
		<cfquery name="getNewID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT config_group_id
		FROM cw_config_groups
		WHERE config_group_name = '#arguments.config_group_name#'
		</cfquery>

	<cfset newRecordID = getnewID.config_group_id>

<!--- if we did have a duplicate, return error code --->
<cfelse>
<cfset newRecordID = '0-Error: #errorMsg#'>
</cfif>

<cfreturn newRecordID>

</cffunction>

<!--- // ---------- Update Config Group ---------- // --->
<cffunction name="CWqueryUpdateConfigGroup" access="public" output="false" returntype="string"
			hint="Update a config group record - returns updated ID or 0- error message">

<!--- id is required --->
		<cfargument name="config_group_id" type="numeric" required="true"
					hint="ID of the record to update">

<!--- others are optional --->
		<cfargument name="config_group_name" type="string" required="false" default=""
					hint="Name of the config group">
		<cfargument name="config_group_sort" type="numeric" required="false" default="1"
					hint="Sort order">
		<cfargument name="config_group_showmerchant" type="boolean" required="false" default="0"
					hint="Show config group to lower user levels y/n">
		<cfargument name="config_group_description" type="string" required="false" default=""
					hint="Description/instructions for this config group">

<cfset var updatedID = ''>
<cfset var errorMsg = ''>

<!--- check for duplicates by name  --->
<cfset dupNameCheck = CWquerySelectConfigGroupDetails(0,arguments.config_group_name,arguments.config_group_id)>
<!--- if we have a duplicate, return an error message --->
<cfif dupNameCheck.recordCount>
<cfset errorMsg = errorMsg & "<br>Config Group Name '#arguments.config_group_name#' already exists">
</cfif>

<!--- if no duplicate, update --->
<cfif not len(trim(errorMsg))>

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			UPDATE cw_config_groups
			SET
			config_group_sort = #arguments.config_group_sort#,
			config_group_show_merchant = #arguments.config_group_showmerchant#,
			<cfif len(trim(arguments.config_group_description))>
			config_group_description = '#arguments.config_group_description#'
			</cfif>
			<cfif len(trim(arguments.config_group_name))>
			,config_group_name = '#arguments.config_group_name#'
			</cfif>
			WHERE config_group_id = #arguments.config_group_id#
			</cfquery>
			<cfset updatedID = arguments.config_group_id>

<!--- if error message, return string --->
<cfelse>
<cfset updatedID  = '0-Error: #errorMsg#'>

</cfif>

<cfreturn updatedID>

</cffunction>

<!--- // ---------- Delete Config Group ---------- // --->
<cffunction name="CWqueryDeleteConfigGroup" access="public" output="false" returntype="string"
			hint="Delete a config group - only if no items exist in the group">

		<cfargument name="group_id" required="true" type="numeric"
					hint="The ID of the config group record to delete">

<cfset var deleteCheck = ''>
<cfset var deleteVar = ''>

<cftry>
<!--- check for protected items by group ID  --->
<cfset deleteCheck = CWquerySelectConfigItems(arguments.group_id)>
<!--- if any items are found, do not delete --->
<cfif deleteCheck.recordCount>
<cfset returnString = "0- Config Group contains #deleteCheck.recordCount# items and cannot be deleted">
<cfelse>
<!--- if no items are found --->


<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
DELETE FROM cw_config_groups
WHERE config_group_id = #arguments.group_id#
</cfquery>

<!--- return a message confirming deletion --->
<cfset returnString = "Config Group deleted">

</cfif>

<!--- if any errors occur during the operation, return an error message --->
<cfcatch type="any">
<cfset returnString = '0-' & cfcatch.message & ';' & cfcatch.detail>
</cfcatch>

</cftry>
<cfreturn returnString>
</cffunction>

<!--- // ---------- Get Config Items in a given group ---------- // --->
<cffunction name="CWquerySelectConfigItems" access="public" output="false" returntype="query"
			hint="Returns a query with all config items in any config group">

	<cfargument name="config_group_id" required="true" type="numeric"
				hint="ID of the config group to lookup">

<cfset var rsSelectConfigItems = ''>
<cfquery name="rsSelectConfigItems" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT *
FROM cw_config_items
WHERE config_group_id = #arguments.config_group_id#
<cfif Not (isDefined('session.cw.accessLevel') AND listFindNoCase('merchant,developer',session.cw.accessLevel))>
AND config_show_merchant = 1
</cfif>
ORDER BY config_sort, config_name
</cfquery>

<cfreturn rsSelectConfigItems>
</cffunction>

<!--- // ---------- Get Config Item Details ---------- // --->
<cffunction name="CWquerySelectConfigItemDetails" access="public" output="false" returntype="query"
			hint="Look up config item details by ID, variable or name - at least one argument must match">

<!--- ID, name and variable are required, can be passed in as 0 or '' --->
	<cfargument name="config_id" required="true" type="numeric"
				hint="ID of the Config Item to look up - pass in 0 to select all IDs">

	<cfargument name="config_name" required="true" type="string"
				hint="Name of the Config Item - pass in blank '' to select all names">

	<cfargument name="config_variable" required="true" type="string"
				hint="Variable string for the Config Item - pass in blank '' to select all variables">

<!--- others are optional --->
	<cfargument name="group_id" required="false" default="0" type="numeric"
				hint="restrict lookup to items in a specific group">

	<cfargument name="omit_id_list" required="false" default="0" type="string"
				hint="List of Ids to omit from update">

	<cfset var rsSelectConfigItem = ''>

		<!--- look up config item --->
		<cfquery name="rsSelectConfigItem" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT *
		FROM cw_config_items
		WHERE 1 = 1
		<cfif arguments.config_id gt 0>AND config_id = #arguments.config_id#</cfif>
		<cfif len(trim(arguments.config_name))>AND config_name = '#arguments.config_name#'</cfif>
		<cfif len(trim(arguments.config_variable))>AND config_variable = '#arguments.config_variable#'</cfif>

		<cfif arguments.omit_id_list neq 0>
		AND NOT config_ID in(#arguments.omit_id_list#)
		</cfif>
		</cfquery>

	<cfreturn rsSelectConfigItem>

</cffunction>

<!--- // ---------- Insert Config Item ---------- // --->
<cffunction name="CWqueryInsertConfigItem" access="public" output="false" returntype="string"
			hint="Inserts a new config item, returns the item ID or a 0- error message">

	<!--- required arguments --->
	<cfargument name="group_id" required="true" type="numeric"
				hint="Config group this item belongs to">

	<cfargument name="config_variable" required="true" type="string"
				hint="Variable string to be used in the application scope">

	<cfargument name="config_name" required="true" type="string"
				hint="Name of the config item">

	<cfargument name="config_value" required="true" type="string"
				hint="Value for this variable. May be empty '' but not omitted">

	<cfargument name="config_type" required="true" type="string"
				hint="Type of form field to be displayed to the user">

	<!--- optional --->
	<cfargument name="config_description" required="false" default="" type="string"
				hint="Descriptive help text for the form input">

	<cfargument name="config_possibles" required="false" default="" type="string"
				hint="List of possible options for checkbox, select or radio elements">

	<cfargument name="config_showmerchant" required="false" default="" type="boolean"
				hint="List of possible options for checkbox, select or radio elements">

	<cfargument name="config_sort" required="false" default="1" type="numeric"
				hint="order shown in the form">

	<cfargument name="config_size" required="false" default="25" type="numeric"
				hint="Size of config item in displayed form">

	<cfargument name="config_rows" required="false" default="5" type="numeric"
				hint="Rows of config item in displayed form">

	<cfargument name="config_protected" required="false" default="0" type="numeric"
				hint="Prevent deletion y/n">

	<cfargument name="config_required" required="false" default="0" type="numeric"
				hint="Required input in displayed form y/n">

	<cfset var newRecordID = ''>
	<cfset var getNewRecordID = ''>
	<cfset var errorMsg = ''>

<!--- check for duplicates: look up existing config item by name --->
<cfset dupNameCheck = CWquerySelectConfigItemDetails(0,trim(arguments.config_name),'',arguments.group_id)>
<!--- if we have a duplicate, return an error message --->
<cfif dupNameCheck.recordCount>
<cfset errorMsg = errorMsg & "<div>Item Name '#arguments.config_name#' already exists</div>">
</cfif>

<!--- check for duplicates by variable --->
<cfset dupVarCheck = CWquerySelectConfigItemDetails(0,'',trim(arguments.config_variable),arguments.group_id)>
<!--- if we have a duplicate, return an error message --->
<cfif dupVarCheck.recordCount>
<cfset errorMsg = errorMsg & "<div>Variable '#arguments.config_variable#' already exists</div>">
</cfif>

<!--- if no duplicate, insert --->
<cfif not len(trim(errorMsg))>
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		INSERT INTO cw_config_items (
			config_group_id,
			config_variable,
			config_name,
			config_value,
			config_type,
			config_description,
			config_possibles,
			config_show_merchant,
			config_sort,
			config_size,
			config_rows,
			config_protected,
			config_required

		)
		VALUES(
			#arguments.group_id#,
			'#trim(arguments.config_variable)#',
			'#trim(arguments.config_name)#',
			'#trim(arguments.config_value)#',
			'#trim(arguments.config_type)#',
			'#trim(arguments.config_description)#',
			'#trim(arguments.config_possibles)#',
			#arguments.config_showmerchant#,
			#arguments.config_sort#,
			#arguments.config_size#,
			#arguments.config_rows#,
			#arguments.config_protected#,
			#arguments.config_required#
			)
		</cfquery>

		<!--- get ID for return value --->
		<cfquery name="getNewRecordID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT config_id
		FROM cw_config_items
		WHERE config_name = '#trim(arguments.config_name)#'
		AND config_variable = '#trim(arguments.config_variable)#'
		</cfquery>
		<cfset newRecordID = getNewRecordID.config_id>

<cfelse>
<cfset newRecordID = '0-' & errorMsg>
</cfif>

<cfreturn newRecordID>
</cffunction>

<!--- // ---------- Update Config Item ---------- // --->
<cffunction name="CWqueryUpdateConfigItem" access="public" output="false" returntype="string"
			hint="Updates a config item record, returns the item ID or a 0- error message">

	<!--- required arguments --->
	<cfargument name="config_id" required="true" type="numeric"
				hint="ID of the record to update">

	<cfargument name="group_id" required="true" type="numeric"
				hint="Config group this item belongs to">

	<cfargument name="config_variable" required="true" type="string"
				hint="Variable string to be used in the application scope">

	<cfargument name="config_name" required="true" type="string"
				hint="Name of the config item">

	<cfargument name="config_value" required="true" type="string"
				hint="Value for this variable. May be empty '' but not omitted">


	<!--- optional --->
	<cfargument name="config_type" required="false" default="" type="string"
				hint="Type of form field to be displayed to the user">

	<cfargument name="config_description" required="false" default="" type="string"
				hint="Descriptive help text for the form input">

	<cfargument name="config_possibles" required="false" default="" type="string"
				hint="List of possible options for checkbox, select or radio elements">

	<cfargument name="config_showmerchant" required="false" default="0" type="boolean"
				hint="List of possible options for checkbox, select or radio elements">

	<cfargument name="config_sort" required="false" default="0" type="numeric"
				hint="order shown in the form">

	<cfargument name="config_size" required="false" default="0" type="numeric"
				hint="Size of config item in displayed form">

	<cfargument name="config_rows" required="false" default="0" type="numeric"
				hint="Rows of config item in displayed form">

	<cfargument name="config_protected" required="false" default="2" type="numeric"
				hint="Prevent deletion y/n">

	<cfargument name="config_required" required="false" default="2" type="numeric"
				hint="Required input in displayed form y/n">

	<cfset var updatedID = ''>
	<cfset var errorMsg = ''>

<!--- check for duplicates: look up existing config item by name --->
<cfset dupNameCheck = CWquerySelectConfigItemDetails(0,trim(arguments.config_name),'',arguments.group_id,arguments.config_id)>
<!--- if we have a duplicate, return an error message --->
<cfif dupNameCheck.recordCount>
<cfset errorMsg = errorMsg & "<div>Item Name '#arguments.config_name#' already exists</div>">
</cfif>

<!--- check for duplicates by variable --->
<cfset dupVarCheck = CWquerySelectConfigItemDetails(0,'',trim(arguments.config_variable),arguments.group_id,arguments.config_id)>
<!--- if we have a duplicate, return an error message --->
<cfif dupVarCheck.recordCount>
<cfset errorMsg = errorMsg & "<div>Variable '#arguments.config_variable#' already exists</div>">
</cfif>

<!--- if no duplicate, update --->
<cfif not len(trim(errorMsg))>
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		UPDATE cw_config_items
	 	SET config_group_id = #arguments.group_id#
			,config_variable = '#trim(arguments.config_variable)#'
			,config_name = '#trim(arguments.config_name)#'
			,config_value = '#trim(arguments.config_value)#'
			<cfif len(trim(arguments.config_type))>,config_type = '#trim(arguments.config_type)#'</cfif>
			<cfif len(trim(arguments.config_description))>,config_description = '#trim(arguments.config_description)#'</cfif>
			<cfif len(trim(arguments.config_possibles))>,config_possibles = '#trim(arguments.config_possibles)#'</cfif>
			<cfif len(trim(arguments.config_showmerchant))>,config_show_merchant = #arguments.config_showmerchant#</cfif>
			<cfif arguments.config_sort neq 0>,config_sort = #arguments.config_sort#</cfif>
			<cfif arguments.config_size neq 0>,config_size = #arguments.config_size#</cfif>
			<cfif arguments.config_rows neq 0>,config_rows = #arguments.config_rows#</cfif>
			<cfif arguments.config_protected neq 2>,config_protected = #arguments.config_protected#</cfif>
			<cfif arguments.config_required neq 2>,config_required = #arguments.config_required#</cfif>
		WHERE config_id = #arguments.config_id#
		</cfquery>

			<cfset updatedID = arguments.config_id>

<cfelse>
<cfset updatedID = '0-' & errorMsg>
</cfif>

<cfreturn updatedID>
</cffunction>

<!--- // ---------- Delete Config Item ---------- // --->
<cffunction name="CWqueryDeleteConfigItem" access="public" output="false" returntype="string"
			hint="Delete a config item - only if not marked as 'protected' in the database; returns a message">

		<cfargument name="config_id" required="true" type="numeric"
					hint="The ID of the config item record to delete">

<cfset var deleteCheck = ''>
<cfset var deleteVar = ''>

<!--- check for record protected by ID  --->
<cfset deleteCheck = CWquerySelectConfigItemDetails(arguments.config_id,'','')>

<cftry>
<!--- if the item is not 'protected' --->
<cfif deleteCheck.config_protected is 0>

		<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE FROM cw_config_items
		WHERE config_id = #arguments.config_id#
		AND config_protected = 0
		</cfquery>

		<!--- delete the corresponding CW application scope --->
<cfset deleteVar = structDelete(application.cw, deleteCheck.config_variable) >

<!--- return a message confirming deletion --->
<cfset returnString = "Config Item '#deleteCheck.config_name#' deleted">
<!--- if the variable is protected, return an error --->
<cfelse>
<cfset returnString = "0- Config Item '#deleteCheck.config_name#' cannot be deleted">
</cfif>

<!--- if any errors occur during the operation, return an error message --->
<cfcatch type="any">
<cfset returnString = '0-' & cfcatch.message & ';' & cfcatch.detail>
</cfcatch>

</cftry>
<cfreturn returnString>
</cffunction>

<!--- // ---------- // Get Config Group Name // ---------- // --->
<cffunction name="CWgetConfigGroupName" access="public" output="false" returntype="string"
			hint="Returns the text string for the given config group ID">

	<cfargument name="config_group_id" required="true" type="numeric"
				hint="ID of the Config Group to look up - pass in 0 to select all IDs">

	<cfset var returnStr = ''>
	<cfset var rsSelectConfigGroup = ''>

		<!--- look up configGroup --->
		<cfquery name="rsSelectConfigGroup" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT config_group_name
		FROM cw_config_groups
		WHERE config_group_id = #arguments.config_group_id#
		</cfquery>

	<cfset returnStr = rsSelectconfigGroup.config_group_name>

	<cfreturn returnStr>
</cffunction>

<!--- /////////////// --->
<!--- ADMIN NAV MENUS --->
<!--- /////////////// --->

<!--- // ---------- Order Status Menu ---------- // --->
<cffunction name="CWqueryNavOrders" access="public" returntype="string"  output="true"
			hint="Returns list|value pair of Options and IDs for use in nav menu">

	<cfargument name="menu_counter" required="false" default="1" type="Numeric"
				hint="the number to place first in the returned nav menu string - see cw-inc-admin-nav.cfm">

	<!--- get all ship status types --->
	<cfset var orderStatusQuery = CWquerySelectOrderStatus()>

<cfif NOT IsDefined("application.cw.shipStatusMenu")
		OR NOT len(trim(application.cw.shipStatusMenu))>
	<cfset application.cw.shipStatusMenu = ''>

	<cfif orderStatusQuery.recordCount>
	<cflock scope="application" type="exclusive" throwontimeout="no" timeout="5">
		<cfsavecontent variable="application.cw.shipStatusMenu">
		<cfoutput query="orderStatusQuery">#arguments.menu_counter#|orders.cfm?status=#orderStatusQuery.shipstatus_id#|#orderStatusQuery.shipstatus_name#,</cfoutput>
		</cfsavecontent>
	</cflock>
	</cfif>
</cfif>
<cfreturn application.cw.shipStatusMenu>
</cffunction>

<!--- // ---------- Config Groups Menu ---------- // --->
<cffunction name="CWqueryNavConfig" access="public" returntype="string"  output="true"
			hint="Returns list|value pair of Options and IDs for use in nav menu">

	<cfargument name="menu_counter" required="false" default="1" type="Numeric"
				hint="the number to place first in the returned nav menu string - see cw-inc-admin-nav.cfm">
	<cfargument name="omit_list" required="false" default="0" type="String"
				hint="list of IDs to omit from results">
	<cfargument name="return_rows" required="false" default="99" type="Numeric"
				hint="number of results to return">

	<cfset var rsNavConfig = ''>
	<cfset var configMenu = ''>
<cfsavecontent variable="configMenu">
<!--- get config groups to show to the user --->
<cfquery name="rsNavConfig" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT config_group_name, config_group_id
	FROM cw_config_groups
	WHERE 1 = 1
	<cfif Not IsDefined('session.cw.accessLevel') OR session.cw.accessLevel neq 'developer'>
	AND config_group_show_merchant = 1
	</cfif>
	<cfif arguments.omit_list neq '0'>
	AND NOT config_group_id in(#arguments.omit_list#)
	</cfif>
	ORDER BY config_group_sort, config_group_name
</cfquery>

<!--- build list - if only 1 row being returned, label it 'custom settings' --->
<cfoutput query="rsNavConfig" maxrows="#arguments.return_rows#">
	#arguments.menu_counter#|config-settings.cfm?group_ID=#rsNavConfig.config_group_id#|
	<cfif arguments.return_rows eq 1>Custom Settings<cfelse>#rsNavConfig.config_group_name#</cfif>,
</cfoutput>
</cfsavecontent>
<cfreturn configMenu>
</cffunction>

<!--- // ---------- Text Items Menu ---------- // --->
<cffunction name="CWqueryNavText" access="public" returntype="string"  output="true"
			hint="Returns list|value pair of Options and IDs for use in nav menu">

	<cfargument name="menu_counter" required="false" default="1" type="Numeric"
				hint="the number to place first in the returned nav menu string - see cw-inc-admin-nav.cfm">
	<cfargument name="return_rows" required="false" default="99" type="Numeric"
				hint="number of results to return">

	<cfset var rsNavText = ''>
	<cfset var configMenu = ''>

<cfsavecontent variable="configMenu">
<!--- get config groups to show to the user --->
<cfquery name="rsNavText" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT text_group_name, text_group_id, text_group_language
	FROM cw_text_groups
	ORDER BY text_group_sort, text_group_name
</cfquery>

<!--- build list - if only 1 row being returned, label it 'text items' --->
<cfoutput query="rsNavText" maxrows="#arguments.return_rows#">
	<cfif len(trim(rsNavText.text_group_Name))>
		#arguments.menu_counter#|text-items.cfm?group_ID=#rsNavText.text_group_id#|
		<cfif arguments.return_rows eq 1>Text Items<cfelse>#rsNavText.text_group_name# (#rsNavText.text_group_language#)</cfif>,
	</cfif>
</cfoutput>
</cfsavecontent>

<cfreturn configMenu>
</cffunction>

<!--- /////////// --->
<!--- ADMIN USERS --->
<!--- /////////// --->

<!--- // ---------- Get all active Admin Users ---------- // --->
<cffunction name="CWquerySelectAdminUsers" access="public" returntype="query" output="false"
			hint="Select all users with details for admin users management">

	<cfargument name="record_id" type="numeric" required="false"  default="0"
				hint="The user ID to look up">
	<cfargument name="username" type="string" required="false"  default=""
				hint="User name to look up">
	<cfargument name="omit_levels" type="string" required="false"  default=""
				hint="Access levels to omit">

<cfset var rsGetAdminUsers="">
<cfquery name="rsGetAdminUsers" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT *
FROM cw_admin_users
WHERE 1 = 1
<!--- user id --->
<cfif arguments.record_id gt 0>
AND admin_user_id = arguments.record_id
</cfif>
<!--- user name --->
<cfif len(trim(arguments.username))>
AND admin_username = '#arguments.username#'
</cfif>
<!--- levels to omit --->
<cfif len(trim(arguments.omit_levels))>
AND NOT admin_access_level in('#omit_levels#')
</cfif>

</cfquery>

<cfreturn rsGetAdminUsers>

</cffunction>

<!--- // ---------- Insert Admin User ---------- // --->
<cffunction name="CWqueryInsertUser" access="public" output="false" returntype="string"
			hint="Inserts an user record - returns ID of the new record, or 0-message if unsuccessful">

	<cfargument name="username" required="true" type="string"
				hint="The user login name">
	<cfargument name="password" required="true" type="string"
				hint="The login password">
	<cfargument name="user_level" required="true" type="string"
				hint="The user's access level">
	<cfargument name="user_title" required="true" type="string"
				hint="The user's name or title">
	<cfargument name="user_email" required="false" default="" type="string"
				hint="The user's email address">

<cfset var newUserID = ''>
<!--- first look up existing user by username --->
<cfset dupCheck = CWquerySelectAdminUsers(0,'#arguments.username#')>

<!--- if we have a duplicate, return an error message --->
<cfif dupCheck.recordCount>
<cfset newUserID = '0-username'>
<!--- if no duplicate, insert --->
<cfelse>
<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
INSERT INTO cw_admin_users
(
admin_username,
admin_password,
admin_access_level,
admin_user_alias,
admin_user_email
)
VALUES
(
'#arguments.username#',
'#FORM.admin_password#',
'#FORM.admin_access_level#',
'#arguments.user_title#',
'#arguments.user_email#'
)
</cfquery>

<!--- get ID for return value --->
<cfquery name="getnewUserID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT admin_user_id
FROM cw_admin_users
WHERE admin_username = '#trim(arguments.username)#'
</cfquery>

<cfset newUserID = getnewUserID.admin_user_id>
</cfif>

<cfreturn newUserID>
</cffunction>

<!--- // ---------- Update Admin User ---------- // --->
<cffunction name="CWqueryUpdateUser" access="public" returntype="string" output="false"
			hint="Update a user record based on ID">

	<cfargument name="record_id" required="true" type="numeric"
					hint="ID of the record to update">

	<cfargument name="username" required="true" type="string"
				hint="The user login name">
	<cfargument name="password" required="true" type="string"
				hint="The login password">
	<cfargument name="user_level" required="true" type="string"
				hint="The user's access level">
	<cfargument name="user_title" required="true" type="string"
				hint="The user's name or title">
	<cfargument name="user_email" required="false" default="" type="string"
				hint="The user's email address">

	<cfset var updateuserid = ''>

<!--- first look up existing user by username --->
<cfset dupCheck = CWquerySelectAdminUsers(0,'#arguments.username#')>

<!--- if we have a duplicate, return an error message --->
<cfif dupCheck.recordCount and not dupcheck.admin_username eq arguments.username>
<cfset updateuserid = '0-username'>
<!--- if no duplicate, insert --->
<cfelse>

<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	UPDATE cw_admin_users
	SET
	admin_username = '#arguments.username#',
	admin_password = '#arguments.password#',
	admin_user_alias = '#arguments.user_title#',
	admin_user_email = '#arguments.user_email#',
	admin_access_level = '#arguments.user_level#'
	WHERE admin_user_id = #arguments.record_id#
</cfquery>
<cfset updateuserid = arguments.record_id>
</cfif>

<cfreturn updateuserid>

</cffunction>

<!--- // ---------- Log On / Look Up User ---------- // --->
<cffunction name="CWquerySelectUserLogin" access="public" returntype="query" output="false"
			hint="Look up admin user based on username and password - can match any combination of two lists">

	<cfargument name="usernamestr" required="true" default="" type="string"
				hint="A username (or comma separate list of usernames)">
	<cfargument name="passwordstr" required="true" default="" type="string"
				hint="A password (or comma separate list of passwords)">
	<cfargument name="list_max" required="false" default="1" type="numeric"
				hint="Max number of items to allow for comparison">

<cfset var rsSelectUsers = "">
<cfquery name="rsSelectUsers" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT * FROM cw_admin_users
WHERE (1=0
<cfif listLen(arguments.usernameStr) lte arguments.list_max>
<cfloop list="#arguments.usernamestr#" index="uu">
OR admin_username = '#trim(uu)#'
</cfloop></cfif>
)
AND (1=0
<cfif listLen(arguments.passwordStr) lte arguments.list_max>
<cfloop list="#arguments.passwordstr#" index="pp">
OR admin_password = '#trim(pp)#'
</cfloop></cfif>
)
</cfquery>

<cfreturn rsSelectUsers>
</cffunction>

<!--- // ---------- Update User Logon Date---------- // --->
<cffunction name="CWqueryUpdateUserDate" access="public" returntype="void"  output="false"
			hint="Update the last logon date for any user">

	<cfargument name="username" required="true" default="" type="string"
				hint="A username">
	<cfargument name="prev_date" required="false" default="" type="date"
				hint="The previous login date">

	<cfset var newTime = dateAdd('h',application.cw.globalTimeOffset,now())>
		<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		UPDATE cw_admin_users
		SET admin_last_login = #arguments.prev_date#,
		admin_login_date = #CreateODBCDateTime(newTime)#
		WHERE admin_username = '#arguments.username#'
		</cfquery>

</cffunction>

<!--- // ---------- Delete Admin User ---------- // --->
<cffunction name="CWqueryDeleteUser" access="public" output="false" returntype="void"
			hint="Delete an admin user">

	<cfargument name="record_id" required="true" type="numeric"
				hint="ID of the record to delete">

			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			DELETE FROM cw_admin_users
			WHERE admin_user_id=#arguments.record_id#
			</cfquery>

</cffunction>

</cfsilent>