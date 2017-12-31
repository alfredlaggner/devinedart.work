<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-func-product.cfm
File Date: 2013-01-17
Description: Handles all actions for the Cartweaver product form (product-details.cfm)
Manages Products, SKUs, and Upsell Items by running related queries
Catches errors and returns each in the request scope with a specific name
(see error parsing, confirmation and other event handling in product-details.cfm)
Dependencies: Requires admin query functions and cartweaver init functions to be included in calling page
==========================================================
--->

<!--- // ---------- Update Existing Product ---------- // --->
<cffunction name="CWfuncProductUpdate" access="public" returntype="void" output="false" hint="Invokes a series of queries to update product info">
	<!--- product id and name are required . --->
	<cfargument name="product_id" required="true" type="Numeric" hint="The ID of the product to update">
	<cfargument name="product_name" required="true" type="String" hint="product name">
	<!--- optional product values --->
	<cfargument name="product_on_web" required="false" default="0" type="Boolean" hint="product on web">
	<cfargument name="product_ship_charge" required="false" default="0" type="Boolean" hint="charge shipping">
	<cfargument name="product_tax_group_id" required="false" default="0" type="Numeric" hint="id of product tax group">
	<cfargument name="product_sort" required="false" default="0" type="Numeric" hint="product sort">
	<cfargument name="product_out_of_stock_message" required="false" default="" type="String" hint="product out of stock message">
	<cfargument name="product_custom_info_label" required="false" default="" type="String" hint="label for custom info field">
	<cfargument name="product_description" required="false" default="" type="String" hint="product description">
	<cfargument name="product_preview_description" required="false" default="" type="String" hint="product short description">
	<cfargument name="product_special_description" required="false" default="" type="String" hint="product specs or additional info">
	<cfargument name="product_keywords" required="false" default="" type="String" hint="product keywords">
	<!--- additional arguments --->
	<cfargument name="has_orders" required="false" default="0" type="boolean" hint="does this product have orders?">
	<cfargument name="product_options" required="false" default="" type="string" hint="a comma-delimited list of option values (from the product form)">
	<cfargument name="product_categories" required="false" default="" type="string" hint="a comma-delimited list of category values (from the product form)">
	<cfargument name="product_ScndCategories" required="false" default="" type="string" hint="a comma-delimited list of secondary category values (from the product form)">
	<cfargument name="reload_appdata" required="false" default="true" type="boolean" hint="if true, content is reset in application scope">
<!--- function vars --->
	<cfset var updateProd = ''>
	<cfset var deleteCats = ''>
	<cfset var insertCat = ''>
	<cfset var insertImg = ''>
	<cfset var updateImg = ''>
	<cfset var deleteImg = ''>
	<cfset var insertCats = ''>
	<cfset var rsGetOptnRelIDs = ''>
	<cfset var rsGetSKUIDs = ''>
	<cfset var listOptionRelIDs = ''>
	<cfset var listSkuIDs = ''>
	<cfset var deleteskuOpts = ''>
	<cfset var deleteProdOpts = ''>
	<cfset var ii = ''>
	<cfset var createOpt = ''>
	<cfset var getImageCount = ''>
	<cfset var imgNo = ''>
	<cfset var imageFieldName = ''>
	<cfset var formField = ''>
	<cfset var formFieldVal = ''>
	<cfset var imageIDField = ''>
	<cfset var imageIDVal = ''>
	<cfset var formImageName = ''>
	<cfset var formImageID = ''>
	<cfset var getImageTypes = ''>
	<cfset var temp = ''>		
	<!--- /////// --->
	<!--- UPDATE PRODUCT --->
	<!--- /////// --->
	<cftry>
		<!--- update the record in cw_products --->
		<cfset updateProd = CWqueryUpdateProduct(
		arguments.product_id,
		arguments.product_name,
		arguments.product_on_web,
		arguments.product_ship_charge,
		arguments.product_tax_group_id,
		arguments.product_sort,
		arguments.product_out_of_stock_message,
		arguments.product_custom_info_label,
		arguments.product_description,
		arguments.product_preview_description,
		arguments.product_special_description,
		arguments.product_keywords
		)>
		<!--- CATEGORY ACTIONS --->
		<!--- Delete current Category Relationships --->
		<cfset deleteCats = CWqueryDeleteProductCat(arguments.product_id)>
		<!---  INSERT the new ones  --->
		<cfloop index="ii" list="#arguments.product_categories#">
			<cfset insertCat = CWqueryInsertProductCat(arguments.product_id, ii)>
		</cfloop>
		<!--- Delete current Subcategory Relationships --->
		<cfset deleteCats = CWqueryDeleteProductScndCat(arguments.product_id)>
		<!---  INSERT the new ones  --->
		<cfloop index="ii" list="#arguments.product_ScndCategories#">
			<cfset insertCat = CWqueryInsertProductScndCat(arguments.product_id, ii)>
		</cfloop>
		<!--- /END CATEGORY OPTIONS --->
		<!--- OPTION ACTIONS --->
		<!--- only change options if there are no orders on this product --->
		<cfif not arguments.has_orders>
			<!--- If we've removed a product option, remove the related sku options --->
			<!--- get current list of relative option record IDs --->
			<cfset rsGetOptnRelIDs = CWquerySelectRelOptions(arguments.product_id,arguments.product_options)>
			<!--- get skus for this product --->
			<cfset rsGetSKUIDs = CWquerySelectSkus(arguments.product_id)>
			<!--- if we have both skus and relative options, delete them --->
			<cfif rsGetOptnRelIDs.RecordCount AND rsGetSKUIDs.RecordCount>
				<cfset listOptionRelIDs = ValueList(rsGetSKUIDs.sku_id)>
				<cfset listSkuIDs = ValueList(rsGetOptnRelIDs.sku_option_id)>
				<cfset deleteskuOpts = CWqueryDeleteRelSKUOptions(ListOptionRelIDs,listSkuIDs)>
			</cfif>
			<!--- Delete Product Option Information --->
			<cfset deleteProdOpts = CWqueryDeleteRelProductOptions(arguments.product_id)>
			<!--- Add Selected Product Options --->
			<cfloop index="ii" list="#arguments.product_options#">
				<cfset createOpt = CWqueryInsertProductOptions(arguments.product_id,ii)>
			</cfloop>
		</cfif>
		<!--- /END has orders check --->
		<!--- /END OPTION ACTIONS --->
		<!--- IMAGE ACTIONS --->
		<!--- get number of unique upload groups --->
		<cfset getImageCount = CWquerySelectImageUploadGroups()>
		<!--- loop the image count query --->
		<cfloop query="getImageCount">
			<!--- set up field name and number to use --->
			<cfset imgNo = "#getImageCount.imagetype_upload_group#">
			<cfset imageFieldName = "Image#imgNo#">
			<cfparam name="form.#imageFieldName#" default="">
			<cfset formField = "#evaluate(de('form.#imageFieldName#'))#">
			<cfset formFieldVal = "#evaluate(formField)#">
			<cfparam name="form.imageID#imgNo#" default="">
			<cfset imageIDField = "#evaluate(de('form.imageID#imgNo#'))#">
			<cfset imageIDVal = evaluate(imageIDfield)>
			<cfset formImageName = "#formFieldVal#">
			<cfset formImageID = #imageIDVal# >
			<!--- get the image types that go with this upload group value --->
			<cfset getImageTypes = CWquerySelectImageTypes(imgNo)>
			<!--- if the image name is blank but an ID is associated, DELETE --->
			<cfif formImageName eq "" AND formImageID neq "">
				<!--- Loop the query and delete all related images --->
				<cfloop query="getImageTypes">
					<!--- delete the associated record --->
					<cfset deleteImg = CWqueryDeleteProductImage(arguments.product_id, getImageTypes.imagetype_id)>
				</cfloop>
			<!--- if the image is not blank , but an ID was already given, UPDATE --->
			<cfelseif formImageName neq "" AND formImageID neq "">
			<!--- check for existing images with saved name --->
			<cfset imageQuery = CWquerySelectProductImages(arguments.product_id)>
			<!--- if no image exists with this saved filename --->
			<cfif not listFindNoCase(valueList(imageQuery.product_image_filename),formImageName)>			
				<!--- loop the query and update all related images --->
				<cfloop query="getImageTypes">	
					<!--- UPDATE existing image record --->
					<cfif listFind(valueList(imageQuery.imagetype_id),getImageTypes.imagetype_id)>
						<cfset updateImg = CWqueryUpdateProductImage(arguments.product_id,getImageTypes.imagetype_id,formImageName)>
					<!--- if a new image size has been added, or record does not exist, create it --->
					<cfelse>
						<cfset insertImg = CWqueryInsertProductImage(arguments.product_id,getImageTypes.imagetype_id,formImageName,getImageTypes.imagetype_sortorder)>					
					</cfif>
				</cfloop>
			</cfif>				
			<!--- if the image ID is blank, not existing before now, INSERT --->
			<cfelseif formImageName neq "" AND formImageID eq "">
				<cfloop query="getImageTypes">
					<cfset insertImg = CWqueryInsertProductImage(arguments.product_id,getImageTypes.imagetype_id,formImageName,getImageTypes.imagetype_sortorder)>
				</cfloop>
			</cfif>
		</cfloop>
		<!--- end IMAGE ACTIONS --->
		<!--- reload saved data --->
		<cfif arguments.reload_appdata>
			<cfset temp = CWinitProductData()>
		</cfif>
		<cfcatch>
			<cfset request.cwpage.productUpdateError = cfcatch.message>
		</cfcatch>
	</cftry>
	<!--- /////// --->
	<!--- /END UPDATE PRODUCT --->
	<!--- /////// --->
</cffunction>

<!--- // ---------- Add New Product ---------- // --->
<cffunction name="CWfuncProductAdd" access="public" returntype="void" output="false" hint="Invokes a series of queries to update product info">
	<!--- merchant ID and product name are required . --->
	<cfargument name="product_merchant_product_id" required="true" type="String" hint="product merchant ID (part number)">
	<cfargument name="product_name" required="true" type="String" hint="product name">
	<!--- optional product values --->
	<cfargument name="product_on_web" required="false" default="0" type="Boolean" hint="product on web">
	<cfargument name="product_ship_charge" required="false" default="0" type="Boolean" hint="charge shipping">
	<cfargument name="product_tax_group_id" required="false" default="0" type="Numeric" hint="id of product tax group">
	<cfargument name="product_sort" required="false" default="0" type="Numeric" hint="product sort">
	<cfargument name="product_out_of_stock_message" required="false" default="" type="String" hint="product out of stock message">
	<cfargument name="product_custom_info_label" required="false" default="" type="String" hint="label for custom info field">
	<cfargument name="product_description" required="false" default="" type="String" hint="product description">
	<cfargument name="product_preview_description" required="false" default="" type="String" hint="product short description">
	<cfargument name="product_special_description" required="false" default="" type="String" hint="product specs or additional info">
	<cfargument name="product_keywords" required="false" default="" type="String" hint="product keywords">
	<!--- additional arguments --->
	<cfargument name="has_orders" required="false" default="0" type="boolean" hint="does this product have orders?">
	<cfargument name="product_options" required="false" default="" type="string" hint="a comma-delimited list of option values (from the product form)">
	<cfargument name="product_categories" required="false" default="" type="string" hint="a comma-delimited list of category values (from the product form)">
	<cfargument name="product_ScndCategories" required="false" default="" type="string" hint="a comma-delimited list of secondary category values (from the product form)">
	<cfargument name="reload_appdata" required="false" default="true" type="boolean" hint="if true, content is reset in application scope">
	<cfset var temp = ''>
	<!--- /////// --->
	<!--- ADD NEW PRODUCT --->
	<!--- /////// --->
	<cftry>
		<!--- check for existing product with same merchant ID (part number) --->
		<cfset rsCheckMerchantID = CWquerySelectMerchantID(arguments.product_merchant_product_id)>
		<!--- if the product Merchant ID exists, show an alert to the user, focus the merchant ID field --->
		<cfif rsCheckMerchantID.RecordCount>
			<cfset request.cwpage.productinsertError = "Product already exists, please enter a new Product ID">
			<cfset request.cwpage.productExists = 1>
			<!--- if the merchant ID does not already exist, run processing --->
		<cfelse>
			<!--- INSERT PRODUCT --->
			<!--- this function returns the last inserted product ID
			for further processing after creating the new product--->
			<cfset newproduct_id = CWqueryInsertProduct(
			arguments.product_merchant_product_id,
			arguments.product_name,
			arguments.product_on_web,
			arguments.product_ship_charge,
			arguments.product_tax_group_id,
			arguments.product_sort,
			arguments.product_out_of_stock_message,
			arguments.product_custom_info_label,
			arguments.product_description,
			arguments.product_preview_description,
			arguments.product_special_description,
			arguments.product_keywords
			)>
			<!--- CATEGORY ACTIONS --->
			<!--- Create new Category Relationships --->
			<cfloop index="ii" list="#arguments.product_categories#">
				<cfset insertCat = CWqueryInsertProductCat(newproduct_id, ii)>
			</cfloop>
			<!--- Create new Secondary Category Relationships --->
			<cfloop index="ii" list="#arguments.product_ScndCategories#">
				<cfset insertCat = CWqueryInsertProductScndCat(newproduct_id, ii)>
			</cfloop>
			<!--- /END CATEGORY ACTIONS --->
			<!--- OPTION ACTIONS --->
			<!--- Add Selected Product Options --->
			<cfloop index="ii" list="#arguments.product_options#">
				<cfset createOpt = CWqueryInsertProductOptions(newproduct_id,ii)>
			</cfloop>
			<!--- /END OPTION ACTIONS --->
			<!--- IMAGE ACTIONS --->
			<!--- get number of unique upload groups --->
			<cfset getImageCount = CWquerySelectImageUploadGroups()>
			<!--- loop the image count query --->
			<cfloop query="getImageCount">
				<!--- set up field name and number to use --->
				<cfset imgNo="#getImageCount.imagetype_upload_group#">
				<cfset imageFieldName = "Image#imgNo#">
				<cfparam name="form.#imageFieldName#" default="">				
				<cfset formField="#evaluate(de('form.#imageFieldName#'))#">
				<cfset formFieldVal="#evaluate(formField)#">
				<cfparam name="form.imageID#imgNo#" default="">
				<cfset imageIDField="#evaluate(de('form.imageID#imgNo#'))#">
				<cfset imageIDVal=evaluate(imageIDfield)>
				<cfset formImageName = "#formFieldVal#">
				<cfset formImageID = #imageIDVal# >
				<!--- get the image types that go with this upload group value --->
				<cfset getImageTypes = CWquerySelectImageTypes(imgNo)>
				<!--- Loop all fields, if value is not blank, INSERT  --->
				<cfif formImageName neq "">
					<cfloop query="getImageTypes">
						<cfset insertImg = CWqueryInsertProductImage(newproduct_id,getImageTypes.imagetype_id,formImageName,getImageTypes.imagetype_sortorder)>
					</cfloop>
				</cfif>
				<!--- /END loop/insert --->
			</cfloop>
			<!--- /END loop image count query --->
			<!--- /END IMAGE ACTIONS --->
			<!--- set up the id so we can use it further down the page --->
			<cfset request.cwpage.newproductID = newproduct_id>
		</cfif>
		<!--- reload saved data --->
		<cfif arguments.reload_appdata>
			<cfset temp = CWinitProductData()>
		</cfif>
		<!--- END IF rsCheckproduct_id.RecordCount neq 0 --->
		<cfcatch>
			<cfset request.cwpage.productInsertError = cfcatch.message>
		</cfcatch>
	</cftry>
	<!--- /////// --->
	<!--- /END ADD NEW PRODUCT --->
	<!--- /////// --->
</cffunction>

<!--- // ---------- Delete Product ---------- // --->
<cffunction name="CWfuncProductDelete" access="public" returntype="void" output="false" hint="Invokes a series of queries to delete a product and all related info">
	<!--- product id and name are required . --->
	<cfargument name="product_id" required="true" type="Numeric" hint="The ID of the product to delete">
	<cfargument name="reload_appdata" required="false" default="true" type="boolean" hint="if true, content is reset in application scope">
	<!--- vars --->
	<cfset var getSkus = ''>
	<cfset var skuList = ''>
	<cfset var temp = ''>
	<cftry>
		<!--- Get any product SKUs --->
		<cfset getSkus = CWquerySelectSkus(arguments.product_id)>
		<!--- If we have skus, delete them along with related options --->
		<cfif getSKUS.recordCount>
			<cfset SKUList = ValueList(getSKUS.sku_id)>
			<!--- Delete options --->
			<cfset temp = CWqueryDeleteRelSkuOptions(0,skuList)>
			<!--- Delete SKUs --->
			<cfset temp = CWqueryDeleteSKUs(skuList)>
		</cfif>
		<!--- Delete Product Option Information --->
		<cfset temp = CWqueryDeleteRelProductOptions(arguments.product_id)>
		<!--- Delete all Category Relationships --->
		<cfset temp = CWqueryDeleteProductCat(arguments.product_id)>
		<!--- Delete all Secondary Category Relationships --->
		<cfset temp = CWqueryDeleteProductScndCat(arguments.product_id)>
		<!--- Delete Product Image Information --->
		<cfset temp = CWqueryDeleteProductImage(arguments.product_id,0)>
		<!--- Delete Product Up-sell Records and relative upsells --->
		<cfset temp = CWqueryDeleteUpsell(arguments.product_id,0,1)>
		<!--- Delete Product Discount records--->
		<cfset temp = CWqueryDeleteProductDiscount(arguments.product_id)>
		<!--- Delete Related Sku Discount records --->
		<cfset temp = CWqueryDeleteSKUDiscount(skuList)>
		<!--- Delete Product --->
		<cfset temp = CWqueryDeleteProduct(arguments.product_id)>
		<!--- reload saved data --->
		<cfif arguments.reload_appdata>
			<cfset temp = CWinitProductData()>
		</cfif>
		<cfcatch>
			<cfset request.cwpage.productDeleteError = cfcatch.message>
		</cfcatch>
	</cftry>
</cffunction>

<!--- // ---------- Update SKU ---------- // --->
<cffunction name="CWfuncSkuUpdate" access="public" returntype="void" output="false" hint="Invokes a series of queries to update SKU info">
	<!--- product id and sku id are required --->
	<cfargument name="sku_id" required="true" type="Numeric" hint="The ID of the SKU to update">
	<cfargument name="sku_product_id" required="true" type="Numeric" hint="The ID of the product this SKU belongs to">
	<!--- optional values --->
	<cfargument name="sku_price" required="false" default="0" type="String" hint="sku price">
	<cfargument name="sku_ship_base" required="false" default="0" type="String" hint="shipping base per sku">
	<cfargument name="sku_alt_price" required="false" default="0" type="String" hint="sku alt price">
	<cfargument name="sku_weight" required="false" default="0" type="String" hint="sku weight">
	<cfargument name="sku_stock" required="false" default="0" type="String" hint="sku stock">
	<cfargument name="sku_on_web" required="false" default="1" type="Boolean" hint="show on web y/n">
	<cfargument name="sku_sort" required="false" default="0" type="Numeric" hint="sort order">
	<cfargument name="sku_str_options" required="false" default="" type="Any" hint="the sku options data">
	<cfargument name="reload_appdata" required="false" default="true" type="boolean" hint="if true, content is reset in application scope">
	<cfset var updateProd = ''>
	<cfset var deleteSkuOpts = ''>
	<cfset var ii = ''>
	<cfset var createSKUOption = ''>
	<cfset var temp = ''>
	<cftry>
		<!--- update SKU details --->
		<cfset updateProd = CWqueryUpdateSKU(
		arguments.sku_id,
		arguments.sku_product_id,
		arguments.sku_price,
		arguments.sku_ship_base,
		arguments.sku_alt_price,
		arguments.sku_weight,
		arguments.sku_stock,
		arguments.sku_on_web,
		arguments.sku_sort
		)>
		<!--- DELETE current SKU options --->
		<cfif listLen(arguments.sku_str_options)>
		<cfset deleteSkuOpts = CWqueryDeleteRelSKUOptions(0,arguments.sku_id)>
		<!---  INSERT the new SKU option relationships  --->
			<cfloop index="ii" list="#arguments.sku_str_options#">
				<!--- insert sku option --->
				<cfset createSKUOption = CWqueryInsertRelSKUOption(#arguments.sku_id#,#ii#)>
			</cfloop>
		</cfif>
		<!--- reload saved data --->
		<cfif arguments.reload_appdata>
			<cfset temp = CWinitSkuData()>
		</cfif>
		<cfcatch>
			<cfset request.cwpage.skuUpdateError = cfcatch.message>
		</cfcatch>
	</cftry>
</cffunction>

<!--- // ---------- Add New SKU ---------- // --->
<cffunction name="CWfuncSkuAdd" access="public" returntype="void" output="false" hint="Invokes a series of queries to insert a new sku">
	<!--- product id and sku merchant id are required --->
	<cfargument name="sku_merchant_sku_id" required="true" type="String" hint="The Merchant Name (part number)">
	<cfargument name="sku_product_id" required="true" type="Numeric" hint="The ID of the product this SKU belongs to">
	<!--- optional values --->
	<cfargument name="sku_price" required="false" default="0" type="String" hint="sku price">
	<cfargument name="sku_ship_base" required="false" default="0" type="String" hint="shipping base per sku">
	<cfargument name="sku_alt_price" required="false" default="0" type="String" hint="sku alt price">
	<cfargument name="sku_weight" required="false" default="0" type="String" hint="sku weight">
	<cfargument name="sku_stock" required="false" default="0" type="String" hint="sku stock">
	<cfargument name="sku_on_web" required="false" default="1" type="Boolean" hint="show on web y/n">
	<cfargument name="sku_sort" required="false" default="0" type="Numeric" hint="sort order">
	<cfargument name="sku_str_options" required="false" default="" type="Any" hint="the sku options data">
	<cfargument name="reload_appdata" required="false" default="true" type="boolean" hint="if true, content is reset in application scope">
	<cfset var rsCheckUniqueSKU = ''>
	<cfset var newSKUID = ''>
	<cfset var createSKUoption = ''>
	<cfset var temp = ''>
	<cftry>
		<!--- Check to make sure the sku_id is unique --->
		<cfset rsCheckUniqueSKU = CWquerySelectSKUID(arguments.sku_merchant_sku_id)>
		<cfif rsCheckUniqueSKU.RecordCount neq 0>
			<!--- if the sku already exists --->
			<cfset request.cwpage.skuInsertError = "SKU ID <em>#arguments.sku_merchant_sku_id#</em> already exists. Please choose a different SKU ID">
		<cfelse>
			<!--- insert the new sku, get the ID --->
			<cfset newSKUID = CWqueryInsertSKU(
			arguments.sku_merchant_sku_id,
			arguments.sku_product_id,
			arguments.sku_price,
			arguments.sku_ship_base,
			arguments.sku_alt_price,
			arguments.sku_weight,
			arguments.sku_stock,
			arguments.sku_on_web,
			arguments.sku_sort
			)>
			<!--- set new sku into request scope for further processing --->
			<cfset request.cwpage.newSkuID = newSKUID>
			<!--- Add SKU Options --->
			<cfloop index="ii" list="#arguments.sku_str_options#">
				<!--- insert sku option --->
				<cfset createSKUOption = CWqueryInsertRelSKUOption(#newSKUID#,#ii#)>
			</cfloop>
		</cfif>
		<!--- reload saved data --->
		<cfif arguments.reload_appdata>
			<cfset temp = CWinitSkuData()>
		</cfif>
		<!--- END IF - rsCheckUniqueSKU.RecordCount eq 0 --->
		<cfcatch>
			<cfset request.cwpage.skuInsertError = cfcatch.message>
		</cfcatch>
	</cftry>
</cffunction>

<!--- // ---------- Delete SKU---------- // --->
<cffunction name="CWfuncSKUDelete" access="public" returntype="void" output="false" hint="Deletes a SKU and all related options">
	<cfargument name="sku_id" required="true" type="numeric" hint="the SKU ID to delete">
	<cfargument name="reload_appdata" required="false" default="true" type="boolean" hint="if true, content is reset in application scope">
	<cfset var rsCheckSkuUse = ''>
	<cfset var temp = ''>
	<cftry>
		<!--- First, see if it is in use : function returns number of orders (none = 0) --->
		<cfset rsCheckSkuUse = CWqueryCountSKUOrders(arguments.sku_id)>
		<!--- if not in use on any orders --->
		<cfif rsCheckSkuUse eq 0>
			<!--- delete options --->
			<cfset temp = CWqueryDeleteRelSkuOptions(0,arguments.sku_id)>
			<!--- delete discounts --->
			<cfset temp = CWqueryDeleteSkuDiscount(arguments.sku_id)>
			<!--- delete sku --->
			<cfset temp = CWqueryDeleteSKUs(arguments.sku_id)>
			<!--- if it IS in use, can't delete - show message --->
		<cfelse>
			<cfset request.cwpage.userAlertText = "SKUs may not be deleted once orders have been placed. To remove from inventory, set <em>on Web</em> to <em>No</em>">
			<cfset CWpageMessage("alert",request.cwpage.userAlertText)>
		</cfif>
		<!--- reload saved data --->
		<cfif arguments.reload_appdata>
			<cfset temp = CWinitSkuData()>
		</cfif>
		<cfcatch>
			<cfset request.cwpage.skuDeleteError = cfcatch.message>
		</cfcatch>
	</cftry>
</cffunction>

<!--- // ---------- Add New Upsell ---------- // --->
<cffunction name="CWfuncUpsellAdd" access="public" returntype="any" output="false" hint="Adds upsell items, returns number inserted">
	<cfargument name="product_id" required="true" type="numeric" hint="Product ID to add upsells to">
	<cfargument name="listupsell_id" required="true" type="string" hint="Comma separated list of upsell IDs to add">
	<!--- note: set to returntype any for instances where an error message is returned --->
	<cftry>
		<!--- prepare for errors --->
		<cfset request.cwpage.upsellInsertError = ''>
		<cfset insertCt = 0>
		<!--- loop the list of inserted ids --->
		<cfloop list="#arguments.listupsell_id#" index="upsellID">
			<cfset checkDupUpsell = CWquerySelectUpsell(arguments.product_id,upsellID)>
			<!--- if not a duplicate, insert the upsell, increase count of inserted items --->
			<cfif checkDupUpsell eq 0>
				<cfset insertUpsell = CWqueryInsertUpsell(arguments.product_id,upsellID)>
				<cfset insertCt = insertCt + 1>
			<cfelse>
				<!--- if it is a duplicate, show a specific error, don't count as inserted --->
				<cfset getDupName = CWquerySelectProductDetails(arguments.product_id)>
				<cfset request.cwpage.upsellInsertError = listAppend(request.cwpage.upsellInsertError,"<strong>#checkdupupsell.product_name# </strong> is already associated <br>with this Product. Record not added.<br>")>
			</cfif>
		</cfloop>
		<!--- return the number of upsells created --->
		<cfif isNumeric(insertCt) and insertCt gt 0>
			<cfreturn insertCt>
		<cfelse>
			<cfreturn 0>
		</cfif>
		<!--- handle errors --->
		<cfcatch>
			<cfset request.cwpage.upsellInsertError = cfcatch.message>
		</cfcatch>
	</cftry>
</cffunction>

<!--- // ---------- Delete Upsell ---------- // --->
<cffunction name="CWfuncUpsellDelete" access="public" output="false" returntype="void" hint="Deletes a specified upsell ID, or all upsell records for a given optional product">
	<cfargument name="product_id" required="false" default="0" type="numeric" hint="Product ID to delete all upsells from">
	<cfargument name="upsell_id" required="false" default="0" type="numeric" hint="Upsell ID to delete">
	<cftry>
		<cfset deleteUpsell = CWqueryDeleteUpsell(product_id, upsell_id)>
		<cfcatch>
			<cfset request.cwpage.upselldeleteError = cfcatch.message>
		</cfcatch>
	</cftry>
</cffunction>

</cfsilent>