<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-optionselect.cfm
File Date: 2012-02-01
Description: standalone internal page to show option selection
used for add to cart function in cw-mod-productpreview.cfm
==========================================================
--->
	<cfparam name="accessok" default="false">
	<cfparam name="optionct" default="3">
	<!--- defaults for lookup and form --->
	<cfparam name="url.action" default="">
	<cfparam name="url.qty" default="true">
	<cfparam name="url.intqty" default="1">
	<cfparam name="url.optiontype" default="select">
	<!--- if product id is valid --->
	<cfif isDefined('url.product') and url.product gt 0>
		<!--- global functions--->
		<cfif not isDefined('variables.CWtime')>
			<cfinclude template="../func/cw-func-global.cfm">
		</cfif>
		<!--- global queries--->
		<cfif not isDefined('variables.CWquerySelectProductDetails')>
			<cfinclude template="../func/cw-func-query.cfm">
		</cfif>
		<!--- product functions--->
		<cfif not isDefined('variables.CWgetProduct')>
			<cfinclude template="../func/cw-func-product.cfm">
		</cfif>
		<!--- discount functions--->
		<cfif not isDefined('variables.CWgetSkuDiscountData')>
			<cfinclude template="../func/cw-func-discount.cfm">
		</cfif>
		<!--- QUERY: get product info needed to show selections --->
		<cfset product = CWgetProduct(product_id=url.product)>
		<!--- if product is valid --->
		<cfif product.product_id gt 0 and listLen(product.optiontype_ids) gt 0>
			<cfset accessok = true>
			<cfset optionCt = listLen(product.optiontype_ids)>
		</cfif>
	</cfif>
	<!--- height for form based on number of select elements --->
	<!--- leaving room for alert/validation below submit button --->
	<cfset formHeight = (optionCt * 45) + 90>
</cfsilent>
<!--- javascript for form validation  --->
<cfinclude template="cw-inc-script-validation.cfm">
<script type="text/javascript">
jQuery(document).ready(function(){
	jQuery('form#CWformAddToCartWindow input.qty').keyup(function(){
		var windowSumVal = jQuery('form#CWformAddToCartWindow input.qty').sum();
		jQuery('form#CWformAddToCartWindow input#totalQty').val(windowSumVal);
	}).click(function(){
		jQuery(this).focus();
	});
});
</script>
<!--- if product is not valid, or info is not correct --->
<cfif accessOK is false>
	<cfabort>
</cfif>
<div id="CWformWindow" class="CWcontent">
	<cfoutput>
		<h2>Select Options for</h2>
		<h1>#product.product_name#</h1>
		<!-- add to cart form w/ option selections -->
		<form action="#url.action#" class="CWvalidate" style="min-height:#formHeight#px" method="post" name="addToCart-#product.product_id#" id="CWformAddToCartWindow">
			<!--- selection boxes --->
			<cfif len(trim(product.optiontype_ids))>
				<div class="productPreviewSelect">
					<!-- product options -->
					<cfmodule
						template="../mod/cw-mod-productoptions.cfm"
						product_id="#product.product_id#"
						product_options="#product.optiontype_ids#"
						display_type="#url.optiontype#"
						form_id="CWformAddToCartWindow"
						price_id="CWproductPrices-#product.product_id#w"
						>
				</div>
			</cfif>
			<!--- custom input (show here if label provided in admin) --->
			<cfif len(trim(product.product_custom_info_label)) AND application.cw.adminProductCustomInfoEnabled>
				<!-- custom value -->
				<div class="CWcustomInfo">
					<label class="wide" for="customInfo">
						#trim(product.product_custom_info_label)#:
					</label>
					<input type="text" name="customInfo" class="custom" size="22" value="">
				</div>
			</cfif>
			<!--- if stock is ok --->
			<cfif application.cw.appEnableBackOrders eq 'true' OR product.qty_max gt 0>
				<!-- quantity/submit -->
				<div>
					<!--- dropdowns only (or table with no options): tables method includes its own quantity fields --->
					<cfif url.qty and not url.optiontype eq 'table'>
						<!--- quantity input --->
						<label for="qty">
							Quantity:
						</label>
						<cfif application.cw.appDisplayProductQtyType is 'text'>
							<input name="qty" id="qtyInput" type="text" value="#url.intqty#" class="required qty number" title="Quantity is required" size="2" onkeyup="extractNumeric(this,0,false)">
						<cfelse>
							<select name="qty" class="required" title="Quantity">
								<cfloop from="1" to="#request.cwpage.qtymax#" index="ii">
									<option value="#ii#">#ii#</option>
								</cfloop>
							</select>
						</cfif>
					<cfelse>
						<input type="hidden" value="1" name="qty">
						<span style="width:104px;display:block;float:left;">&nbsp;</span>
					</cfif>
					<!--- / end quantity --->
					<!-- submit button -->
					<input name="submit" type="submit" class="CWformButton" value="Add to Cart&nbsp;&raquo;">
				</div>
				<!--- if stock is not ok --->
			<cfelse>
				<cfoutput>
					<div class="CWalertBox alertText">
						#product.product_out_of_stock_message#
					</div>
				</cfoutput>
			</cfif>
			<!--- hidden values --->
			<input name="productID" type="hidden" value="#product.product_id#">
		</form>
	</cfoutput>
</div>