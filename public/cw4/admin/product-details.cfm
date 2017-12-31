<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: product-details.cfm
File Date: 2012-12-27
Description:Manage product details, descriptions, images, skus and related products
==========================================================
--->
<!--- GLOBAL INCLUDES --->
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- download functions --->
<cfinclude template="cwadminapp/func/cw-func-download.cfm">
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("manager,merchant,developer")>
<!--- PRODUCT INCLUDES --->
<!--- include init functions --->
<cfif not isDefined('variables.CWinitProductData')>
	<cfinclude template="#request.cwpage.cwapppath#func/cw-func-init.cfm">
</cfif>
<!--- include the product functions --->
<cfinclude template="cwadminapp/func/cw-func-product.cfm">
<!--- BASE URL --->
<!--- for this page the base url is the standard current page variable --->
<cfset request.cwpage.baseUrl = request.cw.thisPage>
<!--- PAGE PARAMS --->
<cfparam name="application.cw.adminRecordsPerPage" default="30">
<!--- params for dynamic page headings --->
<cfparam name="request.cwpage.productName" default="Add New Product">
<cfparam name="request.cwpage.subhead" default="Add product details, descriptions and images">
<cfparam name="request.cwpage.currentNav" default="#request.cw.thisPage#">
<cfparam name="detailsQuery.recordCount" default="0">
<!--- global params --->
<cfparam name="SKUList" default="0">
<cfparam name="form.hasOrders" default="0">
<cfparam name="ProductHasOrders" default="0">
<cfparam name="DisabledText" default="">
<cfparam name="url.productid" type="numeric" default="0">
<cfparam name="url.showtab" type="numeric" default="1">
<cfparam name="request.cwpage.productlookupID" default="0">
<!--- default values for seach form--->
<cfparam name="url.pagenumresults" type="numeric" default="1">
<cfparam name="url.searchby" type="string" default="1">
<cfparam name="url.search" type="string" default="">
<cfparam name="url.matchtype" type="string" default="anyMatch">
<cfparam name="url.find" type="string" default="">
<cfparam name="url.maxrows" type="numeric" default="#application.cw.adminRecordsPerPage#">
<cfparam name="url.sortby" type="string" default="product_name">
<cfparam name="url.sortdir" type="string" default="asc">
<cfparam name="url.view" type="string" default="">
<!--- mode can be passed in via url, or request scope, to override application setting --->
<cfparam name="url.skumode" default="#application.cw.adminSkuEditMode#">
<!--- search in cats, subcats --->
<cfif not isDefined('url.searchc') or url.searchc is ''>
<cfset url.searchc = 0>
</cfif>
<cfif not isDefined('url.searchsc') or url.searchsc is ''>
<cfset url.searchsc = 0>
</cfif>
<cfparam name="url.searchc" type="numeric" default="0">
<cfparam name="url.searchsc" type="numeric" default="0">
<!--- use upsell? --->
<cfset request.cwpage.showUpsell = application.cw.appDisplayUpsell>
<!--- /////// --->
<!--- LOOKUP PRODUCT --->
<!--- /////// --->
<!--- run the query on url.id number (or default of 0 to get blank fields for new form)--->
<cfif isNumeric(url.productid)><cfset request.cwpage.productlookupID = url.productid></cfif>
<!--- QUERY: get product details (product id) --->
<cfset detailsQuery = CWquerySelectProductDetails(request.cwpage.productlookupID)>
<!--- if we have an ID in the url but not found in the query, return to products page --->
<cfif url.productid gt 0 and detailsQuery.recordCount neq 1>
	<cflocation url="products.cfm" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END LOOKUP PRODUCT --->
<!--- /////// --->
<!--- PRODUCT FORM DEFAULTS --->
<!--- Set visible form values - all values are null if query returns no results (new product) --->
<cfparam name="application.cw.adminProductDefaultPrice" default="0">
<cfparam name="form.product_merchant_product_id" default="">
<cfparam name="form.product_name" default="#detailsQuery.product_name#">
<cfparam name="form.product_sort" default="#detailsQuery.product_sort#">
<cfparam name="form.product_on_web" default="#detailsQuery.product_on_web#">
<cfparam name="form.product_tax_group_id" default="#detailsQuery.product_tax_group_id#">
<cfparam name="form.product_ship_charge" default="#detailsQuery.product_ship_charge#">
<cfparam name="form.product_preview_description" default="#detailsQuery.product_preview_description#">
<cfparam name="form.product_description" default="#detailsQuery.product_description#">
<cfparam name="form.product_special_description" default="#detailsQuery.product_special_description#">
<cfparam name="form.product_keywords" default="#detailsQuery.product_keywords#">
<cfparam name="form.product_out_of_stock_message" default="#detailsQuery.product_out_of_stock_message#">
<cfparam name="form.product_custom_info_label" default="#detailsQuery.product_custom_info_label#">
<cfparam name="form.hasOrders" default="0">
<!--- SKU FORM DEFAULTS --->
<!--- base sku values --->
<cfparam name="form.sku_merchant_sku_id" default="">
<cfparam name="form.sku_product_id" default="#url.productid#">
<cfparam name="form.sku_price" default="#application.cw.adminProductDefaultPrice#">
<cfparam name="form.sku_ship_base" default="0">
<cfparam name="form.sku_sort" default="1">
<cfparam name="form.sku_weight" default="0">
<cfparam name="form.sku_stock" default="0">
<cfparam name="form.sku_alt_price" default="0">
<cfparam name="form.sku_on_web" default="1">
<cfparam name="form.sku_delete" default="1">
<!--- javascript to show New SKU form (for sku actions) --->
<cfsavecontent variable="clickNewSkuCode">
<script type="text/javascript">
// show/hide new sku form
jQuery(document).ready(function(){
jQuery('a#showNewSkuFormLink').click();
jQuery('form#addSkuForm').children('input:first').focus();
});
</script>
</cfsavecontent>
<!--- params for add product/sku errors --->
<cfparam name="request.cwpage.addProductError" default="">
<cfparam name="request.cwpage.addSKUError" default="">
<!--- include server-side form validation --->
<cfmodule template="cwadminapp/inc/cw-inc-admin-product-validate.cfm">
<!--- if no validation errors, we can proceed with add/update/delete functions --->
<cfif (isDefined('form.action') AND request.cwpage.addProductError eq "" AND request.cwpage.addSKUError eq "")
	OR (isDefined('url.deleteproduct') and isNumeric(url.deleteproduct) and url.deleteproduct gt 0)
	OR (isDefined('form.sku_id') AND request.cwpage.addProductError eq "" AND request.cwpage.addSKUError eq "")
	OR (isDefined('form.sku_id1') AND request.cwpage.addProductError eq "" AND request.cwpage.addSKUError eq "")
	OR (isDefined('form.addSKU') AND request.cwpage.addProductError eq "" AND request.cwpage.addSKUError eq "")
	OR (isDefined('url.deletesku') and isNumeric(url.deletesku) and url.deletesku gt 0)
	OR isDefined('form.addUpsell') OR isDefined('url.delupsellid') OR isDefined('url.upselldelete') OR isDefined('form.deleteupsell_id')
	>
	<!--- /////// --->
	<!--- INSERT UPSELL --->
	<!--- /////// --->
	<cfif isDefined('form.addUpsell') and isDefined('form.upsellproduct_id')>
		<!--- QUERY: insert upsells, returns number inserted --->
		<cfset addUpsell = CWfuncUpsellAdd(form.product_id,form.upsellproduct_id)>
		<!--- loop related product IDs --->
		<cfset addRelCt = 0>
		<cfif isDefined('form.upsellProductRecip_ID')>
			<cfloop list="#form.upsellProductRecip_ID#" index="relID">
				<!--- QUERY: insert reciprocals one at a time, returns 1  --->
				<cfset addRel = CWfuncUpsellAdd(relID,form.product_id)>
				<cfif isDefined('addRel') and addRel gt 0>
					<cfset addRelCt = addRelCt + addRel>
				</cfif>
			</cfloop>
		</cfif>
		<!--- if errors --->
		<cfif isDefined('request.cwpage.upsellInsertError') and len(trim(request.cwpage.upsellInsertError))>
			<cfset CWpageMessage("alert",request.cwpage.upsellInsertError)>
		<cfelse>
			<!--- handle plurals --->
			<cfif addUpsell gt 1>
				<cfset s = 's'>
			<cfelse>
				<cfset s = ''>
			</cfif>
			<cfset confirmMsg = "#addUpsell# Related Product#s# created">
			<cfif addRelCt gt 0>
				<cfset confirmMsg = confirmMsg & '<br>' & '#addRelCt# Reciprocal Record#s# created'>
			</cfif>
			<cfset CWpageMessage("confirm",confirmMsg)>
			<cflocation url="#request.cw.thisPage#?productid=#form.product_id#&showtab=5&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
		</cfif>
		<!--- /END if errors --->
	</cfif>
	<!--- /////// --->
	<!--- /END INSERT UPSELL --->
	<!--- /////// --->
	<!--- /////// --->
	<!--- DELETE UPSELL --->
	<!--- /////// --->
	<!--- delete single upsell via url var--->
	<cfif IsDefined("url.delupsellid")>
		<cfset deleteUpsell = CWfuncUpsellDelete(0,url.delupsellid)>
		<!--- if we have any error --->
		<cfif isDefined('request.cwpage.upselldeleteError') and len(trim(request.cwpage.upselldeleteError))>
			<cfset CWpageMessage("alert",request.cwpage.upselldeleteError)>
		<cfelse>
			<!--- if no error --->
			<cfset CWpageMessage("confirm","Related Product Deleted")>
			<cflocation url="#request.cw.thisPage#?productid=#url.productid#&showtab=5&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
		</cfif>
		<!--- delete list of upsells via checkboxes--->
	<cfelseif isDefined('form.deleteupsell_id')>
		<cfset delCt = 0>
		<cfloop list="#form.deleteupsell_id#" index="delID">
			<cfset deleteUpsell = CWfuncUpsellDelete(0,delID)>
			<!--- if we have any error --->
			<cfif isDefined('request.cwpage.upselldeleteError') and len(trim(request.cwpage.upselldeleteError))>
				<cfset CWpageMessage("alert",request.cwpage.upselldeleteError)>
			<cfelse>
				<!--- if no error --->
				<cfset delCt = delCt + 1>
			</cfif>
		</cfloop>
		<!--- set up confirmation --->
		<cfif delCt gt 1>
			<cfset s = 's'>
		<cfelse>
			<cfset s = ''>
		</cfif>
		<cfset alertMsg = '#delCt# Related Product#s# deleted'>
		<cfset CWpageMessage("confirm",alertMsg)>
		<cflocation url="#request.cw.thisPage#?productid=#url.productid#&showtab=5&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
		<!--- DELETE ALL UPSELLS via URL variable--->
	<cfelseif IsDefined("url.upselldelete")>
		<cfset deleteAllUpsell = CWfuncUpsellDelete(url.upselldelete,0,1)>
		<!--- if we have any error --->
		<cfif isDefined('request.cwpage.upselldeleteError') and len(trim(request.cwpage.upselldeleteError))>
			<cfset CWpageMessage("alert",request.cwpage.upselldeleteError)>
		<cfelse>
			<!--- if no error --->
			<cfset CWpageMessage("confirm","All Related Products Deleted")>
			<cflocation url="#request.cw.thisPage#?productid=#url.productid#&showtab=5&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
		</cfif>
	</cfif>
	<!--- /////// --->
	<!--- /END DELETE UPSELL --->
	<!--- /////// --->
	<!--- /////// --->
	<!--- DELETE PRODUCT --->
	<!--- /////// --->
	<cfif isDefined('url.deleteproduct')>
		<!--- call the delete product function - takes just one argument, product ID --->
		<cfset deleteProd = CWfuncProductDelete(url.deleteproduct)>
		<!--- if we have an error, show it to the user --->
		<cfif isDefined('request.cwpage.productDeleteError')>
			<cfset CWpageMessage("alert","Error: #request.cwpage.productDeleteError#")>
			<cflocation url="product-details.cfm?productid=#url.deleteproduct#&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
			<!--- if no error, return showing message --->
		<cfelse>
			<!--- refresh product data --->
			<cfset temp = CWinitProductData()>		
			<cflocation url="products.cfm?userconfirm=Product%20Deleted" addtoken="no">
		</cfif>
		<!--- /////// --->
		<!--- /END DELETE PRODUCT --->
		<!--- /////// --->
		<!--- /////// --->
		<!--- UPDATE PRODUCT --->
		<!--- /////// --->
	<cfelseif isDefined('form.action') and form.action eq 'updateProduct'>
		<!--- additional form params here, default values not desired unless adding/editing product --->
		<cfparam name="form.product_options" default="">
		<cfparam name="form.product_category_id" default="">
		<cfparam name="form.product_scndcat_ID" default="">
		<!--- call the update product function - see function arguments for details --->
		<cfset updateProd = CWfuncProductUpdate(
		form.product_id,
		form.product_name,
		form.product_on_web,
		form.product_ship_charge,
		form.product_tax_group_id,
		form.product_sort,
		form.product_out_of_stock_message,
		form.product_custom_info_label,
		form.product_description,
		form.product_preview_description,
		form.product_special_description,
		form.product_keywords,
		form.hasOrders,
		form.product_options,
		form.product_category_id,
		form.product_scndcat_ID
		)>
		<cfif isDefined('request.cwpage.productUpdateError')>
			<cfset CWpageMessage("alert",request.cwpage.productUpdateError)>
		<cfelse>
			<!--- refresh product data --->
			<cfset temp = CWinitProductData()>		
			<cfset CWpageMessage("confirm","Product Details Saved")>
		</cfif>
		<!--- if we have a tab to return to --->
		<cfif isDefined('form.returnTab') AND form.returnTab gt 0>
			<cflocation url="#request.cw.thisPage#?productid=#form.product_id#&showtab=#form.returnTab#&useralert=#CWurlSafe(request.cwpage.userAlert)#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
		</cfif>
		<!--- /////// --->
		<!--- /END UPDATE PRODUCT --->
		<!--- /////// --->
		<!--- /////// --->
		<!--- ADD PRODUCT --->
		<!--- /////// --->
	<cfelseif isDefined('form.action') and form.action eq 'addProduct'>
		<!--- additional form params here, default values not desired unless adding/editing product --->
		<cfparam name="form.product_options" default="">
		<cfparam name="form.product_category_id" default="">
		<cfparam name="form.product_scndcat_ID" default="">
		<!--- duplicate product - use dup name field instead (if defined and not blank) --->
		<cfif isDefined('form.product_DupName') and trim(form.product_DupName) neq '' and form.product_DupName neq form.product_name>
			<cfset form.product_name = form.product_DupName>
		</cfif>
		<!--- call the add product function - see function arguments for details --->
		<cfset updateProd = CWfuncProductAdd(
		form.product_merchant_product_id,
		form.product_name,
		form.product_on_web,
		form.product_ship_charge,
		form.product_tax_group_id,
		form.product_sort,
		form.product_out_of_stock_message,
		form.product_custom_info_label,
		form.product_description,
		form.product_preview_description,
		form.product_special_description,
		form.product_keywords,
		form.hasOrders,
		form.product_options,
		form.product_category_id,
		form.product_scndcat_ID
		)>
		<!--- if we have no errors, redirect showing SKUs tab --->
		<cfif not isDefined('request.cwpage.productinsertError') AND isDefined('request.cwpage.newProductID')>
			<!--- refresh product data --->
			<cfset temp = CWinitProductData()>
			<cfset CWpageMessage("confirm","Product Added")>
			<cflocation url="#request.cw.thisPage#?showtab=4&productid=#request.cwpage.newproductID#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&resetapplication=#application.cw.storePassword#" addtoken="no">
		<cfelseif isDefined('request.cwpage.productinsertError')>
			<!--- if the eror is because product already exists, put some js in the page head to show the right content --->
			<cfif isDefined('request.cwpage.productExists')>
				<cfsavecontent variable="headcontent">
				<script type="text/javascript">
		jQuery(document).ready(function(){
			var url = document.location.toString();
			// if no anchor defined in url
			if (!(url.match('#tab'))){
		 jQuery('#CWadminTabWrapper ul.CWtabList > li:first > a').click();
			};
		 jQuery('#productDupLink').click();
		 jQuery('input#product_merchant_product_id').focus().select();
		});
				</script>
				</cfsavecontent>
				<cfhtmlhead text="#headcontent#">
			</cfif>
			<cfset CWpageMessage("alert","Error: #request.cwpage.productinsertError#")>
		</cfif>
		<!--- end if error  --->
		<!--- /////// --->
		<!--- /END ADD PRODUCT --->
		<!--- /////// --->
	</cfif>
	<!--- /////// --->
	<!--- /END product actions --->
	<!--- /////// --->
	<!--- /////// --->
	<!--- START SKU ACTIONS --->
	<!--- /////// --->
	<!--- /////// --->
	<!--- DELETE SKU --->
	<!--- /////// --->
	<cfif isDefined('url.deletesku') and url.deletesku gt 0>
		<!--- call the delete SKU function - takes just one argument, SKU ID --->
		<cfset deletesku = CWfuncSKUDelete(url.deletesku)>
		<cfif isDefined('request.cwpage.skuDeleteError')>
			<cfset CWpageMessage("alert","Error: #request.cwpage.skuDeleteError#")>
		<cfelse>
			<cflocation url="#request.cw.thisPage#?productid=#url.productid#&showtab=4&&skumode=#url.skumode#&userconfirm=SKU%20Deleted" addtoken="no">
		</cfif>
		<!--- /////// --->
		<!--- /END DELETE SKU --->
		<!--- /////// --->
		<!--- /////// --->
		<!--- UPDATE/DELETE MULTIPLE SKUS --->
		<!--- /////// --->
	<cfelseif IsDefined('form.sku_editmode') and form.sku_editmode is 'list'>
		<cfloop collection="#form#" item="fn">
			<cfif left(fn,3) is 'sku'>
				<cfset "form.skufields.#fn#" = evaluate('form.#fn#')>
			</cfif>
		</cfloop>
		<!--- make sure at least one sku id exists to update --->
		<cfif listLen(form.sku_id) gt 0>
			<!--- loop the list of sku ids, updating each one --->
			<cfset loopLen = listLen(form.sku_id)>
			<cfset request.cwpage.skuupdatect = 0>
			<cfset request.cwpage.skudelct = 0>
			<cfloop from="1" to="#loopLen#" index="skuCt">
				<cftry>
					<!--- catch errors --->
					<!--- if deleting the sku --->
					<cfif isDefined('form.deletesku_id#skuCt#')>
						<!--- DELETE THE SKU --->
						<cfset deletesku = CWfuncSKUDelete(evaluate('form.deletesku_id#skuCt#'))>
						<cfif isDefined('request.cwpage.skuDeleteError')>
							<cfset CWpageMessage("alert","Error: #request.cwpage.skuDeleteError#")>
						<cfelse>
							<cfset request.cwpage.skuDelCt = request.cwpage.skuDelCt + 1>
						</cfif>
						<!--- if not deleting, update here --->
					<cfelse>
						<!--- Set up form options --->
						<!--- Loop throught the form collection and grab all of the chosen options --->
						<cfset strOptions = "">
						<cfloop collection="#FORM#" item="FieldName">
							<cfif Left(FieldName,9) eq "selOption"
								AND listLast(FieldName,'_') eq '#skuCt#'
								AND FORM[FieldName] neq "choose">
								<cfset strOptions = ListAppend(strOptions, FORM[FieldName], ",")>
							</cfif>
						</cfloop>
						<!--- add options to the form scope to keep things together --->
						<cfset "form.sku_stroptions#skuCt#" = strOptions>
						<cfparam name="form['sku_on_web#skuCt#']" default="1">
						<cfparam name="form['sku_alt_price#skuCt#']" default="0">
						<!--- update the sku --->
						<cfset updateSKU = CWfuncSkuUpdate(
						#form["sku_id#skuCt#"]#,
						form.sku_product_id,
						#form["sku_price#skuCt#"]#,
						#form["sku_ship_base#skuCt#"]#,
						#form["sku_alt_price#skuCt#"]#,
						#form["sku_weight#skuCt#"]#,
						#form["sku_stock#skuCt#"]#,
						#form["sku_on_web#skuCt#"]#,
						#form["sku_sort#skuCt#"]#,
						#form["sku_stroptions#skuCt#"]#,
						false
						)>
						<!--- update sku with file info, request.cwpage.newSkuID set by insert sku above --->
						<cfif application.cw.appDownloadsEnabled and isDefined('form.sku_download_file1')>
							<cfset updateSkuFile = CWqueryUpdateSkuFile(
								sku_id=#form["sku_id#skuCt#"]#,
								file_name=#form["sku_download_file#skuCt#"]#,
								download_id=#form["sku_download_id#skuCt#"]#,
								file_version=#form["sku_download_version#skuCt#"]#,
								download_limit=#val(form["sku_download_limit#skuCt#"])#
								)>
							<!--- catch any errors --->
							<cfif updateSkuFile is 0>
								<cfset CWpageMessage("alert","Error: file attachment not updated")>
							</cfif>
						</cfif>
						<!--- set up error messages --->						
						<cfif isDefined('request.cwpage.skuUpdateError')>
							<cfset CWpageMessage("alert","Error: #request.cwpage.skuUpdateError#")>
						<!--- if no error, add to total skus updated --->
						<cfelse>
							<cfset request.cwpage.skuupdatect = request.cwpage.skuupdatect + 1>
						</cfif>
					</cfif>
					<!--- handle page errors --->
					<cfcatch>
						<cfset CWpageMessage("alert","Error: invalid data for sku #evaluate('form.sku_id#skuCt#')# #cfcatch.detail#")>
					</cfcatch>
				</cftry>
			</cfloop>
			<!--- if at least one update or delete was done, redirect showing alerts --->
			<cfif request.cwpage.skuUpdateCt gt 0 OR request.cwpage.skuDelCt gt 0>
				<!--- refresh sku data --->
				<cfset temp = CWinitProductData()>
				<cfset temp = CWinitSkuData()>
				<!--- set alert --->
				<cfset CWpageMessage("confirm","Changes Saved")>
				<cfif request.cwpage.skuDelCt gt 0>
					<cfset CWpageMessage("alert","#request.cwpage.skuDelCt# SKUs deleted")>
				</cfif>
				<cflocation url="#request.cw.thisPage#?showtab=4&productid=#url.productid#&skumode=#url.skumode#&sortby=#url.sortby#&sortdir=#url.sortdir#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
			</cfif>
			<!--- if no sku ids were submitted --->
		<cfelse>
			<cfset CWpageMessage("alert","Error: No sku data submitted")>
			<cflocation url="#request.cw.thisPage#?showtab=4&productid=#url.productid#&skumode=#url.skumode#&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
		</cfif>
		<!--- /end make sure sku id exists --->
		<!--- /////// --->
		<!--- UPDATE SINGLE SKU --->
		<!--- /////// --->
	<cfelseif IsDefined('form.sku_editmode') and form.sku_editmode is 'standard' and not len(trim(form.sku_merchant_sku_id))>
		<!--- Loop throught the form collection and grab all of the chosen options --->
		<cfset strOptions = "">
		<cfloop collection="#FORM#" item="FieldName">
			<cfif Left(FieldName,9) eq "selOption" AND FORM[FieldName] neq "choose">
				<cfset strOptions = ListAppend(strOptions, FORM[FieldName], ",")>
			</cfif>
		</cfloop>
		<!--- add options to the form scope to keep things together --->
		<cfset form.sku_stroptions = strOptions>
		<cfset updateSKU = CWfuncSkuUpdate(
		form.sku_id,
		form.sku_product_id,
		form.sku_price,
		form.sku_ship_base,
		form.sku_alt_price,
		form.sku_weight,
		form.sku_stock,
		form.sku_on_web,
		form.sku_sort,
		form.sku_stroptions
		)>
		<!--- update sku file --->
		<cfif application.cw.appDownloadsEnabled and isDefined('form.sku_download_file')>
			<cfif not isNumeric(form.sku_download_limit)>
				<cfset form.sku_download_limit = 0>
			</cfif>
			<cfset updateSkuFile = CWqueryUpdateSkuFile(
				sku_id=form.sku_id,
				file_name=form.sku_download_file,
				download_id=form.sku_download_id,
				file_version=form.sku_download_version,
				download_limit=form.sku_download_limit
				)>
			<!--- catch any errors --->
			<cfif updateSkuFile is 0>
				<cfset CWpageMessage("alert","Error: file attachment not updated")>
			</cfif>
		</cfif>
		<cfif isDefined('request.cwpage.skuUpdateError')>
			<cfset CWpageMessage("alert","Error: #request.cwpage.skuUpdateError#")>
		<cfelse>
			<!--- refresh sku data --->
			<cfset temp = CWinitProductData()>
			<cfset temp = CWinitSkuData()>		
			<cfset CWpageMessage("confirm","SKU Updated")>
			<cflocation url="#request.cw.thisPage#?showtab=4&productid=#url.productid#&skumode=#url.skumode#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
		</cfif>
		<!--- /////// --->
		<!--- /END UPDATE SKU --->
		<!--- /////// --->
		<!--- /////// --->
		<!--- ADD SKU --->
		<!--- /////// --->
	<cfelseif isDefined('form.newSku')>
		<!--- Loop through the form collection and grab all of the chosen options --->
		<cfset strOptions = "">
		<cfloop collection="#FORM#" item="FieldName">
			<cfif Left(FieldName,9) eq "selOption" AND FORM[FieldName] neq "choose">
				<cfset strOptions = ListAppend(strOptions, FORM[FieldName], ",")>
			</cfif>
		</cfloop>
		<!--- add options to the form scope to keep things together --->
		<cfset form.sku_stroptions = strOptions>
		<cfset insertSKU = CWfuncSkuAdd(
		form.sku_merchant_sku_id,
		form.sku_product_id,
		form.sku_price,
		form.sku_ship_base,
		form.sku_alt_price,
		form.sku_weight,
		form.sku_stock,
		form.sku_on_web,
		form.sku_sort,
		form.sku_stroptions
		)>
		<!--- update sku with file info, request.cwpage.newSkuID set by insert sku above --->
		<cfif application.cw.appDownloadsEnabled and isDefined('form.sku_download_file')
			and isDefined('request.cwpage.newSkuID')>
			<cfif not isNumeric(form.sku_download_limit)>
				<cfset form.sku_download_limit = 0>
			</cfif>
			<cfset updateSkuFile = CWqueryUpdateSkuFile(
				sku_id=request.cwpage.newSkuID,
				file_name=form.sku_download_file,
				download_id=form.sku_download_id,
				file_version=form.sku_download_version,
				download_limit=form.sku_download_limit
				)>
			<!--- catch any errors --->
			<cfif updateSkuFile is 0>
				<cfset CWpageMessage("alert","Error: file attachment not updated")>
			</cfif>
		</cfif>
		<cfif not isDefined('request.cwpage.skuInsertError') AND isDefined('url.productid')>
			<!--- refresh sku data --->
			<cfset temp = CWinitProductData()>
			<cfset temp = CWinitSkuData()>			
			<cfset CWpageMessage("confirm","SKU Added")>
			<cflocation url="#request.cw.thisPage#?showtab=4&productid=#url.productid#&skumode=#url.skumode#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
			<!--- if we have an error, show the error, and show the add sku form again --->
		<cfelseif isDefined('request.cwpage.skuInsertError')>
			<!--- put the code to click New SKU link in the page (see above) --->
			<cfhtmlhead text="#clickNewSkuCode#">
			<cfset CWpageMessage("alert","Error: #request.cwpage.skuInsertError#")>
		</cfif>
		<!--- /////// --->
		<!--- /END ADD SKU --->
		<!--- /////// --->

		<!--- /////// --->
		<!--- COPY SKU --->
		<!--- /////// --->
	<cfelseif isDefined('form.sku_merchant_sku_id') and len(trim(form.sku_merchant_sku_id))>
		<!--- just like adding a sku above --->
		<!--- Loop through the form collection and grab all of the chosen options --->
		<cfset strOptions = "">
		<cfloop collection="#FORM#" item="FieldName">
			<cfif Left(FieldName,9) eq "selOption" AND FORM[FieldName] neq "choose">
				<cfset strOptions = ListAppend(strOptions, FORM[FieldName], ",")>
			</cfif>
		</cfloop>
		<!--- add options to the form scope to keep things together --->
		<cfset form.sku_stroptions = strOptions>
		<cfset insertSKU = CWfuncSkuAdd(
		form.sku_merchant_sku_id,
		form.sku_product_id,
		form.sku_price,
		form.sku_ship_base,
		form.sku_alt_price,
		form.sku_weight,
		form.sku_stock,
		form.sku_on_web,
		form.sku_sort,
		form.sku_stroptions
		)>
		<cfif not isDefined('request.cwpage.skuInsertError') AND isDefined('url.productid')>
			<!--- refresh sku data --->
			<cfset temp = CWinitProductData()>
			<cfset temp = CWinitSkuData()>			
			<cfset CWpageMessage("confirm","SKU Copied")>
			<cfset CWpageMessage("confirm","Change at least one product option and save the new sku to prevent duplication")>
			<cflocation url="#request.cw.thisPage#?showtab=4&productid=#url.productid#&skumode=#url.skumode#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
			<!--- if we have an error, show the error, and show the add sku form again --->
		<cfelseif isDefined('request.cwpage.skuInsertError')>
			<!--- put the code to click New SKU link in the page (see above) --->
			<cfhtmlhead text="#clickNewSkuCode#">
			<cfset CWpageMessage("alert","Error: #request.cwpage.skuInsertError#")>
		</cfif>
		<!--- /////// --->
		<!--- /END COPY SKU --->
		<!--- /////// --->
	</cfif>
	<!--- /////// --->
	<!--- /end sku actions--->
	<!--- /////// --->
<cfelseif isDefined('request.cwpage.skuInsertError') AND len(trim(request.cwpage.addSKUError))>
	<cfhtmlhead text="#clickNewSkuCode#">
</cfif>
<!--- /end error check - actions ok --->
<!--- QUERIES --->
<!--- QUERY: get list of options --->
<cfset productOptionsQuery = CWquerySelectOptions()>
<!--- QUERY: get selected options for this product (product ID) --->
<cfset productOptionsRelQuery = CWquerySelectOptions(request.cwpage.productlookupID)>
<!--- QUERY: get Skus for this product (product ID) --->
<cfset skusQuery = CWquerySelectSkus(request.cwpage.productlookupID)>
<!--- list of sku IDs (used to check for orders below) --->
<cfif skusQuery.recordCount>
	<cfset SKUList = ValueList(skusQuery.sku_id)>
	<!--- if no skus, we can't show the upsell form yet --->
<cfelse>
	<cfset request.cwpage.showUpsell = 0>
	<!--- if this is not the new product form, show a SKU message --->
	<cfif url.productid gt 0>
		<cfset CWpageMessage("alert","Create at least one SKU to activate this product")>
	</cfif>
</cfif>
<!--- QUERY: get categories, secondary cats (all) --->
<cfset listC = CWquerySelectCategories()>
<cfset listSC = CWquerySelectScndCategories()>
<!--- QUERY: get related categories, secondary cats --->
<cfset listProdCats = CWquerySelectRelCategories(request.cwpage.productlookupID)>
<cfset listProdScndCats = CWquerySelectRelScndCategories(request.cwpage.productlookupID)>
<!--- QUERY: image queries --->
<cfset listProdImages = CWquerySelectProductImages(request.cwpage.productlookupID)>
<cfset listImageTypes = CWquerySelectImageTypes()>
<cfset listUploadGroups = CWquerySelectImageUploadGroups()>
<!--- QUERY: get all active tax groups --->
<cfset listTaxGroups = CWquerySelectTaxGroups()>
<!--- NEW VS EDIT--->
<!--- if one valid product is found --->
<cfif detailsQuery.recordCount eq 1>
	<!--- IF EDITING --->
	<!--- set page to 'edit' mode --->
	<cfset request.cwpage.editMode = 'edit'>
	<!--- set values based on query results --->
	<cfset request.cwpage.productName = htmlEditFormat(form.product_name)>
	<!--- QUERY: count orders based on the list of skus--->
	<cfset request.cwpage.orderCount = CWqueryCountSKUOrders(skuList)>
	<cfif request.cwpage.orderCount gt 0>
		<cfset productHasOrders = 1>
		<cfset DisabledText = " disabled=""disabled""">
	</cfif>
	<!--- get upsell list --->
	<cfset productUpsellQuery = CWquerySelectUpsellProducts(request.cwpage.productlookupID)>
	<!--- get reciprocal upsell list --->
	<cfset productReciprocalUpsellQuery = CWquerySelectReciprocalUpsellProducts(request.cwpage.productlookupID)>
	<!--- subheading --->
	<cfsavecontent variable="request.cwpage.subhead">
	<cfoutput>
	ID: #detailsQuery.product_merchant_product_id#
	&nbsp;&nbsp;SKUs: #skusQuery.recordCount#
	&nbsp;&nbsp;Orders: #request.cwpage.orderCount#
	<cfif request.cwpage.showUpsell>
		&nbsp;&nbsp;Related Products: #productUpsellQuery.recordCount#
	</cfif>
	</cfoutput>
	</cfsavecontent>
	<!---  IF ADDING NEW PRODUCT --->
<cfelse>
	<cfset request.cwpage.editMode = 'add'>
</cfif>
<!--- SET UP OPTIONS  / CATEGORIES --->
<cfset listProductOptions = "">
<cfif IsDefined("form.product_options")>
	<cfset listProductOptions = form.product_options>
<cfelseif request.cwpage.editMode eq 'edit'>
	<cfset listProductOptions = ValueList(productOptionsRelQuery.optiontype_id)>
</cfif>
<!--- put in request scope for use in skus include --->
<cfset request.listProductOptions = listProductOptions>
<!--- Create a list of assigned categories for the select menus --->
<cfset listRelCats = "">
<cfif IsDefined("form.product_category_id")>
	<cfset listRelCats = form.product_category_id>
<cfelse>
	<cfset listRelCats = ValueList(listProdCats.product2category_category_id)>
</cfif>
<!--- Create a list of assigned secondary categories for the select menus --->
<cfif IsDefined("form.product_scndcat_ID")>
	<cfset listRelScndCats = form.product_scndcat_ID>
<cfelse>
	<cfset listRelScndCats = ValueList(listProdScndCats.product2secondary_secondary_id)>
</cfif>
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Product Details: #request.cwpage.productName#">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Product Details: #request.cwpage.productName#">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = request.cwpage.subhead>
<!--- current menu marker --->
<cfif request.cwpage.editMode eq 'edit'>
	<cfset request.cwpage.currentNav = 'products.cfm'>
</cfif>
<!--- load form scripts --->
<cfset request.cwpage.isFormPage = 1>
<!--- load table scripts --->
<cfset request.cwpage.isTablePage = 1>
<!--- dynamic form elements, save as variables for use on multiple tabs --->
<cfif request.cwpage.editMode is 'edit'>
	<cfsavecontent variable="request.cwpage.productSubmitButton">
	<input name="updateProduct" type="button" class="submitButton" rel="productForm" id="updateProduct" value="Save Product">
	</cfsavecontent>
	<cfsavecontent variable="request.cwpage.productArchiveButton">
	<a class="CWbuttonLink" onclick="return confirm('Archive Product <cfoutput>#cwStringFormat(request.cwpage.productName)#</cfoutput>?');" title="Archive Product: <cfoutput>#CWstringFormat(request.cwpage.productName)#</cfoutput>"
	href="products.cfm?archiveid=<cfoutput>#request.cwpage.productlookupID#</cfoutput>">Archive Product</a>
	</cfsavecontent>
	<cfsavecontent variable="request.cwpage.productActivateButton">
	<a class="CWbuttonLink" title="Reactivate Product: <cfoutput>#CWstringFormat(request.cwpage.productName)#</cfoutput>"
	href="products.cfm?reactivateid=<cfoutput>#request.cwpage.productlookupID#</cfoutput>">Activate Product</a>
	</cfsavecontent>
	<cfsavecontent variable="request.cwpage.productDeleteButton">
	<a class="CWbuttonLink deleteButton" onclick="return confirm('Delete Product <cfoutput>#cwStringFormat(request.cwpage.productName)#</cfoutput> and all related information?');" title="Delete Product: <cfoutput>#CWstringFormat(request.cwpage.productName)#</cfoutput>"
	href="product-details.cfm?deleteproduct=<cfoutput>#request.cwpage.productlookupID#</cfoutput>">Delete Product</a>
	</cfsavecontent>
</cfif>
</cfsilent>
<!--- START OUTPUT --->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head>
		<cfoutput>
		<title>#application.cw.companyName# : #request.cwpage.title#</title>
		</cfoutput>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<!--- Don't Cache content  --->
		<meta http-equiv="Cache-Control" content="no-cache">
		<meta http-equiv="Pragma" content="no-cache">
		<!-- admin styles -->
		<link href="css/cw-layout.css" rel="stylesheet" type="text/css">
		<link href="theme/<cfoutput>#application.cw.adminThemeDirectory#</cfoutput>/cw-admin-theme.css" rel="stylesheet" type="text/css">
		<!-- admin javascript -->
		<cfinclude template="cwadminapp/inc/cw-inc-admin-scripts.cfm">
		<link href="js/fancybox/jquery.fancybox.css" rel="stylesheet" type="text/css">
		<script type="text/javascript" src="js/fancybox/jquery.fancybox.pack.js"></script>
		<!--- text editor javascript --->
		<cfif application.cw.adminEditorEnabled and application.cw.adminEditorProductDescrip>
			<cfinclude template="cwadminapp/inc/cw-inc-admin-script-editor.cfm">
		</cfif>
		<!--- PAGE JAVASCRIPT --->
		<script type="text/javascript">
		jQuery(document).ready(function(){
		// fancybox
		jQuery('a.zoomImg').each(function(){
			jQuery(this).fancybox({
			'titlePosition': 'inside',
			'padding': 3,
			'overlayShow': true,
			'showCloseButton': true,
			'hideOnOverlayClick':true,
			'hideOnContentClick': true
			});
		});
		// upload image
		jQuery('a.showImageUploader').click(function(){
			var thisSrcUrl = jQuery(this).attr('href');
		jQuery(this).parents('td').find('div.imageUpload').show().children('iframe').attr('src',thisSrcUrl);
		jQuery(this).parents('td').find('img.productImagePreview').hide();
		return false;
		});
		// end upload image

		// select image
		jQuery('a.showImageSelector').click(function(){
			var thisSrcUrl = jQuery(this).attr('href');
		jQuery(this).parents('td').find('div.imageUpload').show().children('iframe').attr('src',thisSrcUrl);
		jQuery(this).parents('td').find('img.productImagePreview').hide();
		return false;
		});
		// end select image

		// clear image
		jQuery('#tab3 img.clearImageLink').click(function(){
		jQuery(this).parents().siblings('input.imageInput').val('').siblings('img.productImagePreview').attr('src','');
		jQuery(this).parents('td').find('div.imageUpload').hide().children('iframe').attr('src','');
		jQuery(this).parents('td').find('img.productImagePreview').attr('src','').attr('alt','').hide();
		return false;
		});
		// end clear image

		// duplicate product
		// show the dup product form
		jQuery('#productDupLink').click(function(){
		jQuery('#productDup').show();
		jQuery(this).hide();
		return false;
		});
		// submit the dup product form
		jQuery('#productDup_Submit').click(function(){
			jQuery('#productFormAction').val('AddProduct');
			jQuery('#productForm').submit();
		});
		// end duplicate product

		// duplicate SKU
		// show the dup sku form
		jQuery('#tab4 div.CWformButtonWrap a.skuDupLink').click(function(){
		jQuery(this).parents('div').siblings('#skuDup').toggle();
		return false;
		});
		// end duplicate SKU

		// tab selectors
		jQuery('#tab1complete').click(function(){
		jQuery('#CWadminTabWrapper ul.CWtabList > li:nth-child(2) > a').click();
		jQuery( 'html, body' ).animate( { scrollTop: 0 }, 0 );
		});
		jQuery('#tab2complete').click(function(){
		jQuery('#CWadminTabWrapper ul.CWtabList > li:nth-child(3) > a').click();
		jQuery( 'html, body' ).animate( { scrollTop: 0 }, 0 );
		});
		// tab return value for product form
		jQuery('#CWadminTabWrapper ul.CWtabList > li > a').click(function(){
			if (jQuery(this).attr('href') == '#tab1'){
			 jQuery('input.returnTab').attr('value','1')
			 } else if 	(jQuery(this).attr('href') == '#tab2'){
			 jQuery('input.returnTab').attr('value','2')
			 } else if 	(jQuery(this).attr('href') == '#tab3'){
			 jQuery('input.returnTab').attr('value','3')
			 } else if 	(jQuery(this).attr('href') == '#tab4'){
			 jQuery('input.returnTab').attr('value','4')
			 } else if 	(jQuery(this).attr('href') == '#tab5'){
			 jQuery('input.returnTab').attr('value','5')
			 };
		});
		// end tab selectors

		// sku links
		jQuery('#hideNewSkuFormLink').hide();
		jQuery('#showNewSkuFormLink').click(function(){
		jQuery(this).hide();
			<cfif skusQuery.recordCount>
				jQuery(this).siblings('a').show();
			</cfif>
			jQuery('#addSkuForm').show();
			return false;
			});
		jQuery('#hideNewSkuFormLink').click(function(){
		jQuery(this).hide();
			<cfif skusQuery.recordCount>
				jQuery(this).siblings('a').show();
			</cfif>
			jQuery('#addSkuForm').hide();
			return false;
			});
			// show sku form if no skus exist yet
			<cfif not skusQuery.recordCount>
				jQuery('#showNewSkuFormLink').click();
			</cfif>
			// end sku links
			// end upsell search form
			// upsell two-way checkboxes
			// function to click the box in the 'firstCheck' cell
			var $recipCheck = function(el){
			if (jQuery(el).attr('checked') == true || jQuery(el).attr('checked') == 'checked'){
			jQuery(el).parents('td').siblings('td.firstCheck').children('input[type=checkbox]').prop('checked',true);
			};
			};
			var $firstCheck = function(el){
			if (!(jQuery(el).attr('checked') == true || jQuery(el).attr('checked') == 'checked')){
			jQuery(el).parents('td').siblings('td.recipCheck').children('input[type=checkbox]').prop('checked',false);
			};
			};
			// run the function when clicking the two-way checkbox
			jQuery('td.recipCheck input[type=checkbox]').click(function(){
			$recipCheck(jQuery(this));
			});
			jQuery('td.firstCheck input[type=checkbox]').click(function(){
			$firstCheck(jQuery(this));
			});
			// run the function when clicking the two-way parent cell
			jQuery('td.recipCheck').click(function(event){
			if (event.target.type != 'checkbox') {
			$recipCheck(jQuery(this).children('input[type=checkbox]'));
			}
			});
			// run the function when clicking the two-way parent cell
			jQuery('td.firstCheck').click(function(event){
			if (event.target.type != 'checkbox') {
			$firstCheck(jQuery(this).children('input[type=checkbox]'));
			}
			});
			// run the function when clicking the two-way parent cell
			jQuery('input[rel=all2]').click(function(){
			jQuery('input.all2').each(function(){
			$recipCheck(jQuery(this));
			});
			});
			// run the function when clicking the two-way parent cell
			jQuery('input[rel=all1]').click(function(){
			jQuery('input.all1').each(function(){
			$firstCheck(jQuery(this));
			});
			});
			// end upsell checkboxes
			// upsell click-to-select
			jQuery('#tblUpsellSelect tr td').not(':has(a),:has(input)').css('cursor','pointer').click(function(event){
			if (event.target.type != 'checkbox') {
			jQuery(this).siblings('td.firstCheck').find(':checkbox').trigger('click');
			}
			}).hover(
			function(){
			jQuery(this).addClass('hoverCell');
			},
			function(){
			jQuery(this).removeClass('hoverCell');
			});
			jQuery('#relProdAll1').click(function(){
			if(jQuery(this).attr('checked')!=true){
			jQuery('#relProdAll2').prop('checked',false);
			};
			});
			jQuery('#relProdAll2').click(function(){
			if(jQuery(this).prop('checked')==true){
			jQuery('#relProdAll1').prop('checked',true);
			};
			});
			// end upsell click-to-select
			// only run this section for blank new product form
			<cfif request.cwpage.editMode is 'add' and not isDefined('form.action')>
				// reset form to prevent cached values
				jQuery('#tab3 input.imageInput').val('');
			</cfif>

			});
		</script>
	</head>
	<!--- body gets a class to match the filename --->
	<body <cfoutput>class="#listFirst(request.cw.thisPage, '.')#"</cfoutput>>
		<div id="CWadminWrapper">
			<!-- Navigation Area -->
			<div id="CWadminNav">
				<div class="CWinner">
					<cfinclude template="cwadminapp/inc/cw-inc-admin-nav.cfm">
				</div>
				<!-- /end CWinner -->
			</div>
			<!-- /end CWadminNav -->
			<!-- Main Content Area -->
			<div id="CWadminPage">
				<!-- inside div to provide padding -->
				<div class="CWinner">
					<!--- page start content / dashboard --->
					<cfinclude template="cwadminapp/inc/cw-inc-admin-page-start.cfm">
					<cfif len(trim(request.cwpage.heading1))><cfoutput><h1>#trim(request.cwpage.heading1)#</h1></cfoutput></cfif>
					<cfif len(trim(request.cwpage.heading2))><cfoutput><h2>#trim(request.cwpage.heading2)#</h2></cfoutput></cfif>
					<!--- user alerts --->
					<cfinclude template="cwadminapp/inc/cw-inc-admin-alerts.cfm">
					<!-- Page Content Area -->
					<div id="CWadminContent">
						<!-- //// PAGE CONTENT ////  -->
						<!--- include the search form --->
						<div id="CWadminProductSearch" class="CWadminControlWrap">
							<cfinclude template="cwadminapp/inc/cw-inc-search-product.cfm">
						</div>
						<!-- TABBED LAYOUT -->
						<div id="CWadminTabWrapper">
							<!--- if product is archived, show message and option to activate --->
							<cfif request.cwpage.editMode is 'edit' and detailsQuery.product_archive is 1>
								<p><strong>This product is archived. Reactivate to allow editing.</strong><br><br></p>
								<p><cfoutput>#request.cwpage.productActivateButton#</cfoutput></p>
							<cfelse>
								<!-- TAB LINKS -->
								<ul class="CWtabList">
									<!-- main tab -->
									<li><a href="#tab1" title="General Information">Product Details</a></li>
									<!-- descrip -->
									<li><a href="#tab2" title="Descriptions">Descriptions</a></li>
									<!-- photos -->
									<li><a href="#tab3" title="Photos">Photos</a></li>
									<!-- SKUs -->
									<li<cfif request.cwpage.editMode is 'add'> style="display:none"</cfif>><a href="#tab4" title="SKUs">SKUs</a></li>
									<!-- upsell -->
									<cfif request.cwpage.showUpsell>
										<li<cfif request.cwpage.editMode is 'add'> style="display:none"</cfif>><a href="#tab5" title="Related Products">Related Products</a></li>
									</cfif>
								</ul>
								<!--- TAB CONTENT --->
								<div class="CWtabBox">
									<!--- /////// --->
									<!--- PRODUCT FORM --->
									<!--- /////// --->
									<form method="post" id="productForm" name="productForm" class="CWvalidate CWobserve" action="<cfoutput>#request.cw.thisPage#?productid=#url.productid#&showtab=#url.showtab#</cfoutput>">
										<!--- FIRST TAB (info) --->
										<div id="tab1" class="tabDiv">
											<h3>General Information</h3>
											<!--- Form Table --->
											<table class="CWformTable wide">
												<!--- product_id --->
												<tr>
													<th class="label">ID (Part No.)</th>
													<td class="noHover">
														<!--- if adding a new product --->
														<cfif request.cwpage.editMode is 'add'>
															<input name="product_merchant_product_id" type="text" id="product_merchant_product_id" value="<cfoutput>#form.product_merchant_product_id#</cfoutput>"  class="required" title="Product ID is required" size="25">
															<input name="action" type="hidden" id="productFormAction" value="AddProduct">
														<cfelse>
															<!--- if editing a product --->
															<span class="formText"><cfoutput>#detailsQuery.product_merchant_product_id#</cfoutput></span>
															<input name="product_id" type="hidden" value="<cfoutput>#detailsQuery.product_id#</cfoutput>">
															<input name="action" type="hidden" id="productFormAction" value="UpdateProduct">
															<!--- duplicate product --->
															<a href="#" id="productDupLink" class="CWbuttonLink">Copy Product</a>
															<div id="productDup" style="display:none;">
																<!--- productDup_MerchantProductID --->
																<!--- productDup_Name --->
																<label>New Product ID: </label><input id="product_merchant_product_id" name="product_merchant_product_id" type="text" value="<cfoutput>#detailsQuery.product_merchant_product_id#</cfoutput>" size="25"><br>
																<label>New Product Name: </label><input id="product_DupName" name="product_DupName" type="text" value="<cfoutput>#HTMLEditFormat(detailsQuery.product_name)#</cfoutput>" size="25"><br>
																<input name="AddProduct" type="button" class="submitButton" id="productDup_Submit" value="Copy Product">
															</div>
														</cfif>
													</td>
												</tr>
												<!--- product_name --->
												<tr>
													<th class="label">Display Name</th>
													<td>
														<input name="product_name" type="text" value="<cfoutput>#HTMLEditFormat(form.product_name)#</cfoutput>" size="30" class="required" title="Product Name is required">
													</td>
												</tr>
												<!--- product_on_web --->
												<tr>
													<th class="label">Show In Store</th>
													<td>
														<select name="product_on_web">
															<cfif form.product_on_web neq "0">
																<option value="1" selected="selected">Yes
																<option value="0">No
															<cfelse>
																<option value="1" >Yes
																<option value="0" selected="selected">No
															</cfif>
														</select>
													</td>
												</tr>
												<!--- product_ship_charge --->
												<tr>
													<th class="label">Charge Shipping</th>
													<td>
														<select name="product_ship_charge">
															<cfif form.product_ship_charge neq "0">
																<option value="1" selected >Yes
																<option value="0">No
															<cfelse>
																<option value="1">Yes
																<option value="0" selected >No
															</cfif>
														</select>
													</td>
												</tr>
												<!--- product_tax_group_id --->
												<cfif IsDefined("application.cw.taxSystem") AND application.cw.taxSystem eq "Groups">
													<tr>
														<th class="label"><cfoutput>#application.cw.taxSystemLabel#</cfoutput> Group</th>
														<td>
															<select name="product_tax_group_id">
																<cfif application.cw.taxCalctype is 'localTax'><option value="0">No <cfoutput>#application.cw.taxSystemLabel#</cfoutput></option></cfif>
																<cfoutput query="listTaxGroups"><option value="#listTaxGroups.tax_group_id#" <cfif detailsQuery.product_tax_group_id eq listTaxGroups.tax_group_id> selected="selected"</cfif>>#listTaxGroups.tax_group_name#</option></cfoutput>
															</select>
														</td>
													</tr>
												<cfelse>
													<input type="hidden" name="product_tax_group_id" value="0">
												</cfif>
												<!--- product_sort --->
												<tr>
													<th class="label">Results Sort Order</th>
													<td>
														<!--- change null sort to 0 --->
														<cfif form.product_sort is ''><cfset form.product_sort = 0></cfif>
														<input name="product_sort" type="text" class="sort" value="<cfoutput>#form.product_sort#</cfoutput>" maxlength="7" size="5" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
														<div class="smallPrint">
															Order in results listings (1-9999, 0 = default/abc)
														</div>
													</td>
												</tr>
												<!--- categories --->
												<tr>
													<th class="label">
														<cfoutput>#application.cw.adminLabelCategories#</cfoutput>
													</th>
													<td>
														<cfset disabledBoxes = ''>
														<cfset splitC = 0>
														<div class="formSubCol">
															<cfoutput query="listC">
															<cfsavecontent variable="checkboxCode">
															<label <cfif listC.category_archive eq 1> class="disabled"</cfif>>
															<input type="checkbox" name="product_category_id" value="#listC.category_id#"<cfif listC.category_archive eq 1> disabled="disabled"</cfif><cfif ListFind(listRelCats,listC.category_id,",") neq 0> checked="checked"</cfif>>
															&nbsp;#listC.category_name#
															</label><br>
															<cfif listC.category_archive eq 1>
																<cfset catsArchived = 1>
															</cfif>
															<!--- break into two columns --->
															<cfif currentRow gte (listC.recordCount/2 - .5) and splitC eq 0 AND NOT listC.category_archive eq 1>
																<cfset splitC = 1>
																<!--- create new div in code output to page --->
																<cfscript>
																writeOutput('<' & '/div>' & '<' & 'div class="formSubCol">');
																</cfscript>
															</cfif>
															</cfsavecontent>
															<!--- show enabled cats first, then archived --->
															<cfif NOT listC.category_archive eq 1>
																#checkboxCode#
															<cfelse>
																<cfset disabledBoxes = disabledBoxes & checkBoxCode>
															</cfif>
															</cfoutput>
														</div>
														<cfif len(trim(disabledBoxes))><div class="clear"></div><cfoutput>#disabledBoxes#</cfoutput></cfif>
														<!--- if some cats are archived, show note --->
														<cfif isDefined('catsArchived')>
															<div class="smallPrint">
																Archived  <cfoutput>#lcase(application.cw.adminLabelCategories)#</cfoutput> are disabled.
																<br><a href="categories-main.cfm">Activate</a> <cfoutput>#lcase(application.cw.adminLabelCategories)#</cfoutput> to select.
															</div>
														</cfif>
													</td>
												</tr>
												<!--- secondary categories --->
												<tr>
													<th class="label"><cfoutput>#application.cw.adminLabelSecondaries#</cfoutput></th>
													<td>
														<cfset disabledBoxes = ''>
														<cfset splitSC = 0>
														<div class="formSubCol">
															<cfoutput query="listSC">
															<cfsavecontent variable="checkboxCode">
															<label <cfif listSC.secondary_archive eq 1> class="disabled"</cfif>>
															<input type="checkbox" name="product_Scndcat_ID" value="#listSC.secondary_id#"<cfif listSC.secondary_archive eq 1> disabled="disabled"</cfif><cfif ListFind(listRelScndCats,listSC.secondary_id,",") neq 0> checked="checked"</cfif>>
															&nbsp;#listSC.secondary_name#
															</label><br>
															<cfif listSC.secondary_archive eq 1>
																<cfset scndcatsArchived = 1>
															</cfif>
															<!--- break into two columns --->
															<cfif currentRow gte (listSC.recordCount/2 - .5) and splitSC eq 0 AND NOT listsC.secondary_archive eq 1>
																<cfset splitSC = 1>
																<!--- create new div in code output to page --->
																<cfscript>
																writeOutput('<' & '/div>' & '<' & 'div class="formSubCol">');
																</cfscript>
															</cfif>
															</cfsavecontent>
															<!--- show enabled cats first, then archived --->
															<cfif NOT listSC.secondary_archive eq 1>
																#checkboxCode#
															<cfelse>
																<cfset disabledBoxes = disabledBoxes & checkBoxCode>
															</cfif>
															</cfoutput>
														</div>
														<cfif len(trim(disabledBoxes))><div class="clear"></div><cfoutput>#disabledBoxes#</cfoutput></cfif>
														<!--- if some cats are archived, show note --->
														<cfif isDefined('scndcatsArchived')>
															<div class="smallPrint">
																Archived <cfoutput>#lcase(application.cw.adminLabelSecondaries)#</cfoutput> are disabled.
																<br><a href="categories-secondary.cfm">Activate</a> <cfoutput>#lcase(application.cw.adminLabelSecondaries)#</cfoutput> to select.
															</div>
														</cfif>
													</td>
												</tr>
												<!--- product_options --->
												<tr>
													<th class="label">Product Options</th>
													<td>
														<!--- if some options exist for this product --->
														<cfif productOptionsQuery.recordCount>
															<cfset splitO = 0>
															<div class="formSubCol">
																<cfoutput query="productOptionsQuery">
																<label <cfif len(trim(disabledText))> class="disabled"</cfif>>
																<input type="checkbox" name="product_options" value="#productOptionsQuery.optiontype_id#" #disabledtext#
																<cfif ListFind(listProductOptions,productOptionsQuery.optiontype_id,",")> checked="checked"</cfif>
																>&nbsp;#productOptionsQuery.optiontype_name#
																</label><br>
																<!--- break into two columns --->
																<cfif currentRow gte (productOptionsQuery.recordCount/2 -.5) and splitO eq 0 AND NOT len(trim(disabledText))>
																	<cfset splitO = 1>
																	<!--- create new div in code output to page --->
																	<cfscript>
																	writeOutput('<' & '/div>' & '<' & 'div class="formSubCol">');
																	</cfscript>
																</cfif>
																</cfoutput>
															</div>
															<!--- if we have orders, no changes are allowed --->
															<cfif ProductHasOrders eq 1>
																<div class="smallPrint">Orders placed, unable to remove or change options</div>
															</cfif>
															<!--- if no options exist --->
														<cfelse>
															<span class="formText">No options available</span>
														</cfif>
													</td>
												</tr>
												<!--- product_out_of_stock_message --->
												<!--- if the message is blank, and we have a default, use that instead --->
												<cfif request.cwpage.editMode eq 'add' AND not len(trim(form.product_out_of_stock_message))>
													<cfset form.product_out_of_stock_message = application.cw.adminProductDefaultBackOrderText>
												</cfif>
												<tr>
													<th class="label">Out of Stock Message</th>
													<td>
														<input name="product_out_of_stock_message" type="text" value="<cfoutput>#HTMLEditFormat(form.product_out_of_stock_message)#</cfoutput>" size="45">
														<div class="smallPrint">Shown in place of 'add to cart' button if back orders are allowed and stock for all SKUs is 0. <br>Note: leave blank to disable this function.</div>
													</td>
												</tr>
												<!--- product_custom_info_label --->
												<!--- if the message is blank, and we have a default, use that instead --->
												<cfif application.cw.adminProductCustomInfoEnabled>
													<cfif request.cwpage.editMode eq 'add' AND not len(trim(form.product_custom_info_label))>
														<cfset form.product_custom_info_label = application.cw.adminProductDefaultCustomInfo>
													</cfif>
													<tr>
														<th class="label">Custom Info Label</th>
														<td>
															<input name="product_custom_info_label" type="text" value="<cfoutput>#HTMLEditFormat(form.product_custom_info_label)#</cfoutput>" size="30">
															<div class="smallPrint">Allows customer to attach custom info to each product added to cart.<br>Note: leave blank to disable this function.</div>
														</td>
													</tr>
												</cfif>
											</table>
											<!-- FORM BUTTONS -->
											<div class="CWformButtonWrap"<cfif request.cwpage.editMode is 'add'> style="text-align:center"</cfif>>
												<cfif request.cwpage.editMode is 'add'>
													<input name="tab1complete" type="button" class="CWformButton" id="tab1complete" value="&raquo;&nbsp;Next&nbsp;">
												<cfelse>
													<cfoutput>
														<cfif ProductHasOrders eq 0>#request.cwpage.productDeleteButton#</cfif>#request.cwpage.productArchiveButton##request.cwpage.productSubmitButton#
														<cfif ProductHasOrders eq 1>
														<span style="float:right;margin-right:23px;margin-top:8px;" class="smallPrint">Note:&nbsp;&nbsp;products with associated orders cannot be deleted</span>
														</cfif>
													</cfoutput>
												</cfif>
											</div>
										</div>
										<!-- /end info tab (1)-->
										<!-- DESCRIPTIONS TAB -->
										<div id="tab2" class="tabDiv">
											<h3>Product Descriptions and Specifications</h3>
											<!--- Form Table --->
											<table class="CWformTable wide">
												<!--- product_preview_description --->
												<tr>
													<th class="label">Meta Description</th>
													<td class="noHover">
														<textarea name="product_preview_description" cols="72" rows="10"><cfoutput>#form.product_preview_description#</cfoutput></textarea>
													</td>
												</tr>
												<!--- product_description --->
												<tr>
													<th class="label">Full Description</th>
													<td class="noHover">
														<textarea name="product_description" class="textEdit" cols="72" rows="10"><cfoutput>#form.product_description#</cfoutput></textarea>
													</td>
												</tr>
												<!--- product_Spec --->
												<cfif application.cw.adminProductSpecsEnabled>
													<tr>
														<th class="label"><cfoutput>#application.cw.adminLabelProductSpecs#</cfoutput></th>
														<td class="noHover">
															<textarea name="product_special_description" cols="72" rows="2" ><cfoutput>#form.product_special_description#</cfoutput></textarea>
														</td>
													</tr>
												</cfif>
												<!--- product_keywords--->
												<cfif application.cw.adminProductKeywordsEnabled>
													<tr>
														<th class="label"><cfoutput>#application.cw.adminLabelProductKeywords#</cfoutput></th>
														<td class="noHover">
															<textarea name="product_keywords" cols="72" rows="3"><cfoutput>#form.product_keywords#</cfoutput></textarea>
														</td>
													</tr>
												</cfif>
											</table>
											<!-- FORM BUTTONS -->
											<div class="CWformButtonWrap"	<cfif request.cwpage.editMode is 'add'>style="text-align:center"</cfif>>
												<cfif request.cwpage.editMode is 'add'>
													<input name="tab2complete" type="button" class="CWformButton" id="tab2complete" value="&raquo;&nbsp;Next&nbsp;">
												<cfelse>
													<cfoutput>
														<cfif ProductHasOrders eq 0>#request.cwpage.productDeleteButton#</cfif>#request.cwpage.productArchiveButton##request.cwpage.productSubmitButton#
														<cfif ProductHasOrders eq 1>
														<span style="float:right;margin-right:23px;margin-top:8px;" class="smallPrint">Note:&nbsp;&nbsp;products with associated orders cannot be deleted</span>
														</cfif>
													</cfoutput>
												</cfif>
											</div>
										</div>
										<!-- /end descriptions tab (2)-->
										<!-- IMAGES TAB -->
										<div id="tab3" class="tabDiv">
											<h3>Product Image<cfif listUploadGroups.recordCount gt 1>s</cfif></h3>
											<table class="CWformTable wide">
												<!--- loop the query of upload groups --->
												<cfoutput query="listUploadGroups">
												<!--- set up field name and number to use --->
												<cfset imgNo="#listUploadGroups.imagetype_upload_group#">
												<cfset imageFieldName = "Image#imgNo#">
												<!--- QUERY: get image types for this upload group --->
												<cfset getImageTypes = CWquerySelectImageTypes(imgNo)>
												<!--- query of query, get largest image to test for existing image record --->
												<cfquery dbtype="query" name="getSampleImgType" maxrows="1">
												SELECT *
												FROM getImageTypes
												ORDER by imagetype_max_width DESC
												</cfquery>
												<!--- get the image currently in this slot --->
												<cfset getCurrentImageValue = CWquerySelectProductImages(request.cwpage.productlookupID, getSampleImgType.imagetype_id,imgNo)>
												<cfif request.cwpage.productlookupID gt 0>
													<cfset currentImageFileName = getCurrentImageValue.product_image_filename >
												<cfelse>
													<cfset currentImageFileName = ''>
												</cfif>
												<cfset request.imgParentUrl = "#request.cwpage.adminImgPrefix##application.cw.appImagesDir#/">
												<cfset imgDir = request.imgParentUrl & 'admin_preview/'>
												<!--- set the initial value of this form input --->
												<cfparam name="form.#imageFieldName#" default="#currentImageFileName#">
												<cfset imageField="evaluate(de(form.#imageFieldName#))">
												<cfset imageFieldVal="#evaluate(imageField)#">
												<cfset ImageSRC = imgDir & imageFieldVal>
												<!--- Build link for image uploader or selector: includes preview folder name, and upload group number --->
												<cfset imgUploadUrl="product-image-upload.cfm?UploadGroup=#imgNo#">
												<cfset imgSelectUrl="product-image-select.cfm?UploadGroup=#imgNo#&listfolder=admin_preview&showImages=#application.cw.adminProductImageSelectorThumbsEnabled#">
												<!--- create input field for this upload group --->
												<tr>
													<th class="label">
														<cfif listUploadGroups.recordCount gt 1>Image #imgNo#<cfelse>Product Image</cfif>
														<!--- images preview links and info --->
														<cfif len(trim(#form[ImageFieldName]#))>
															<cfsavecontent variable="imgPreviewLinks">
																<cfloop query="getImageTypes">
																	<cfif getImageTypes.imagetype_user_edit neq 0>
																		<cfset fileUrl = '#request.cwpage.adminImgPrefix##application.cw.appImagesDir#/#getImageTypes.imagetype_folder#/#FORM[ImageFieldName]#'>
																		<!--- if the file exists --->
																		<cfif fileExists(expandPath(fileUrl))>
																			<a href="#fileUrl#" class="zoomImg" title="#CWstringFormat(getImageTypes.imagetype_name)#">#getImageTypes.imagetype_name# [#getImageTypes.imagetype_id#]</a>
																			<!--- show size dimensions if debugging on --->
																			<cfif session.cw.debug>: #getImageTypes.imagetype_max_width#(w) x #getImageTypes.imagetype_max_width#(h)</cfif>
																			<br>
																		</cfif>
																	</cfif>
																</cfloop>
																<!--- show original --->
																<cfset fileUrl = '#request.cwpage.adminImgPrefix##application.cw.appImagesDir#/orig/#FORM[ImageFieldName]#'>
																<!--- if the file exists --->
																<cfif fileExists(expandPath(fileUrl))>
																	<a href="#fileUrl#" class="zoomImg" title="Original Image">Original Image</a>
																	<br>
																</cfif>
															</cfsavecontent>
															<cfif len(trim(imgPreviewLinks))>
															<div class="smallPrint imgTypesList">
																VIEW IMAGES:<br>
																#imgPreviewLinks#
															</div>
															</cfif>
														</cfif>
													</th>
													<!--- image field / content area--->
													<td class="noHover">
														<input name="#ImageFieldName#" id="#ImageFieldName#" type="text" value="#FORM[ImageFieldName]#" class="imageInput" size="40">
														<!--- links w/ image upload field --->
														<span class="fieldLinks">
															<!--- ICON: upload image --->
															<a href="#imgUploadUrl#" title="Upload image" class="showImageUploader"><img src="img/cw-image-upload.png" alt="Upload image" class="iconLink"></a>
															<!--- ICON: choose image --->
															<a href="#imgSelectUrl#" title="Choose existing image" class="showImageSelector"><img src="img/cw-image-select.png" alt="Choose existing image" class="iconLink"></a>
															<!--- ICON: clear filename field --->
															<img src="img/cw-delete.png" title="Clear image field" class="iconLink clearImageLink">
														</span>
														<!--- image content area --->
														<div class="productImageContent">
															<!--- image uploader --->
															<div class="imageUpload">
																<iframe width="460" height="224" frameborder="no" scrolling="false">
																</iframe>
															</div>
															<!--- image preview --->
															<div class="imagePreview">
																<!--- if the image is blank or does not exist --->
																<cfif trim(FORM[ImageFieldName]) eq "" OR not FileExists(expandPath(imageSrc))>
																	<img id="image#imgNo#" src="" style="display: none;">
																	<!--- if the image field is not blank, and image is not found, show error --->
																	<cfif len(trim(FORM[ImageFieldName])) and not FileExists(expandPath(imageSrc))>
																		<div class="alert">Image file not found</div>
																	</cfif>
																	<!--- if the image file is ok, show it --->
																<cfelse>
																	<img src="#ImageSRC#" alt="Image Location: #ImageSRC#" class="productImagePreview" id="image#imgNo#" style="border:none;">
																</cfif>
															</div>
															<!-- /end Image Preview -->
														</div>
														<!--- hidden image fields --->
														<input name="ImageID#imgNo#" type="hidden" value="#getCurrentImageValue.product_image_id#">
														<input name="PhotoNumber#imgNo#" type="hidden" value="#imgNo#" >
														<!--- modify the image count, one per field --->
														<input type="hidden" name="ImageCount#imgNo#" value="#GetImageTypes.RecordCount#">
													</td>
												</tr>
												</cfoutput>
											</table>
											<!-- FORM BUTTONS -->
											<div class="CWformButtonWrap"<cfif request.cwpage.editMode is 'add'> style="text-align:center"</cfif>>
												<cfif request.cwpage.editMode is 'add'>
													<input name="AddProduct" type="button" class="submitButton" rel="productForm" id="AddProduct" value="Save Product">
												<cfelse>
													<cfoutput>
														<cfif ProductHasOrders eq 0>#request.cwpage.productDeleteButton#</cfif>#request.cwpage.productArchiveButton##request.cwpage.productSubmitButton#
														<cfif ProductHasOrders eq 1>
														<span style="float:right;margin-right:23px;margin-top:8px;" class="smallPrint">Note:&nbsp;&nbsp;products with associated orders cannot be deleted</span>
														</cfif>
													</cfoutput>
												</cfif>
											</div>
										</div>
										<!-- /end photos tab (3)-->
										<!--- hidden fields --->
										<!--- product has orders? --->
										<input name="hasOrders" type="hidden" id="hasOrders" value="<cfoutput>#ProductHasOrders#</cfoutput>">
										<!--- the tab to return to when this form is submitted: changed dynamically when clicking on various tabs --->
										<input name="returnTab" class="returnTab" type="hidden" value="<cfoutput>#url.showtab#</cfoutput>">
									</form>
									<!--- /////// --->
									<!--- /END PRODUCT FORM --->
									<!--- /////// --->
									<!--- SKUs TAB --->
									<div id="tab4" class="tabDiv">
										<cfif request.cwpage.editMode neq 'add'>
											<h3>Product SKUs (Stock Keeping Units)</h3>
											<cfinclude template="cwadminapp/inc/cw-inc-admin-product-skus.cfm">
										</cfif>
									</div>
									<!-- /end skus tab (4)-->
									<!--- UPSELL TAB --->
									<cfif request.cwpage.showUpsell>
										<div id="tab5" class="tabDiv">
											<cfif request.cwpage.editMode neq 'add'>
												<cfinclude template="cwadminapp/inc/cw-inc-admin-related-products.cfm">
											</cfif>
										</div>
									</cfif>
									<!-- /end upsell tab (5)-->
									<!--- END LAST TAB --->
								</div>
								<!-- end CWtabBox -->
								<!-- / end tabs -->
							</cfif>
						</div>
						<!--- end if product is archived --->
					</div>
					<!-- /end Page Content -->
					<div class="clear"></div>
				</div>
				<!-- /end CWinner -->
			</div>
			<!-- /end Content -->
			<!--- page end content / debug --->
			<cfinclude template="cwadminapp/inc/cw-inc-admin-page-end.cfm">
			<!-- /end CWadminPage-->
			<div class="clear"></div>
		</div>
		<!-- /end CWadminWrapper -->
	</body>
</html>