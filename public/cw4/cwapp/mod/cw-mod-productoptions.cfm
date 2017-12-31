<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-mod-productoptions.cfm
File Date: 2013-01-17
Description: displays product options for selection as part of the 'add to cart' form,
and adds javascript to page for function of dropdowns and form validation.
Options can be shown as related select lists, or as a table where multiple skus
can be selected at once.

NOTES:
To reset the dropdown selections, we restore options from a hidden copy of each select list, created onload with $clone()

// ATTRIBUTES
- product_id: id of the product to show
- display_type: optional - the type of options display being shown (table|select)
- product_options: optional - struct (from getproduct function)
- product_option_list: optional - list of product ids
- int_qty: optional - quantity shown by default
- max_qty: optional - max number of items available in qty dropdowns
- tax_rate: optional - a structure of tax info returned by the cwGetProductTax() function
			(if not provided, a lookup is attempted within this routine, based on product ID)

==========================================================
--->

<!--- id of product to show options for --->
<cfparam name="attributes.product_id" default="0" type="numeric">
<!--- display type --->
<cfparam name="attributes.display_type" default="#application.cw.appDisplayOptionView#" type="string">
<!--- list of option type ids --->
<cfparam name="attributes.product_options" default="" type="string">
<!--- defaults for quantity --->
<cfparam name="application.cw.appDisplayProductQtyType" default="text" type="string">
<cfparam name="attributes.int_qty" default="1" type="string">
<cfparam name="attributes.max_qty" default="100" type="string">
<!--- id of the parent form --->
<cfparam name="attributes.form_id" default="CWformAddToCart" type="string">
<!--- id of the pricing area for this selection --->
<cfparam name="attributes.price_id" default="CWproductPrices" type="string">
<!--- tax rate: passed in as a structure from calling page --->
<cfparam name="attributes.tax_rate" default="">
<cfparam name="attributes.tax_calc_type" default="#application.cw.taxCalctype#">
<!--- customer id: used for getting customer-specific discounts --->
<cfparam name="session.cwclient.cwCustomerID" default="0">
<cfparam name="attributes.customer_id" default="#session.cwclient.cwCustomerID#">
<!--- promo code: used for getting customer-applied discounts --->
<cfparam name="session.cwclient.discountPromoCode" default="">
<cfparam name="attributes.promo_code" default="#session.cwclient.discountPromoCode#">
<!--- clean up form and url variables --->
<cfinclude template="../inc/cw-inc-sanitize.cfm">
<!--- global functions --->
<cfinclude template="../inc/cw-inc-functions.cfm">
<!--- look up tax rate if not provided (only if using local calc) --->
<cfif application.cw.taxDisplayOnProduct and attributes.tax_calc_type is 'localtax'>
	<cfif (not isStruct(attributes.tax_rate)) and isDefined('session.cwclient.cwTaxRegionID') and session.cwclient.cwTaxRegionID gt 0>
	<cfset attributes.tax_rate = cwGetProductTax(product_id=val(attributes.product_id), region_id=val(session.cwclient.cwTaxRegionID), country_id=val(session.cwclient.cwTaxCountryID))>
	</cfif>
<cfelse>
	<cfset attributes.tax_rate = ''>
</cfif>
<!--- if we have a list, use it --->
<cfif len(trim(attributes.product_options)) AND isNumeric(trim(listFirst(attributes.product_options)))>
	<cfset optiondata.idlist = trim(attributes.product_options)>
<!--- if no list, get from query based on product id --->
<cfelse>
	<cfset optiontypesquery = CWquerySelectOptionTypes(attributes.product_id)>
	<cfset optiondata.idlist = ''>
	<cfoutput query="optiontypesquery" group="optiontype_id">
		<cfset optiondata.idlist = listAppend(optiondata.idlist,'#optiontype_id#')>
	</cfoutput>
</cfif>
<!--- query for all product skus and prices --->
<cfset skusQuery = CWquerySelectSkus(attributes.product_id)>
	<!--- get product data for building option lists --->
	<cfset skuTableQuery = CWquerySelectSkuOptions(attributes.product_id)>
	<!--- get options for this product --->
	<cfif not isDefined('optiontypesquery')>
		<cfset optiontypesquery = CWquerySelectOptionTypes(attributes.product_id)>
	</cfif>
	<!--- only show table if we have valid options --->
	<cfif skuTableQuery.recordCount lt 1 OR optionTypesQuery.recordCount lt 1>
		<cfset attributes.display_type = 'select'>
	</cfif>
</cfsilent>
<!--- START OUTPUT --->
<!--- show options for selected display type --->
<cfswitch expression="#attributes.display_type#">
<!--- TABLES ('table') --->
<cfcase value="table">
	<!--- create array of options --->
	<cfset optionList = ''>
	<cfoutput query="optionTypesQuery" group="optiontype_id">
		<cfset optionList = listAppend(optionList,optionTypesQuery.optionType_Name)>
	</cfoutput>
	<cfset optionLabels = listToArray(optionList)>
	<cfset optionCt = arrayLen(optionLabels)>
	<cfset optionArray = arrayNew(1)>
	<cfset prodCt = 0>
	<table class="CWtable" id="CWoptionsTable">
	<!--- header row --->
	<tr class="headerRow">
	<!--- SKU --->
	<th>SKU</th>
	<!--- OPTION NAMES --->
	<!--- output the headers for each column --->
	<cfloop index="ii" from="1" to="#optionCt#">
	<th><cfoutput>#trim(optionLabels[ii])#</cfoutput></th>
	</cfloop>
	<!--- PRICE --->
	<th>Price</th>
	<!--- QTY --->
	<th>Qty.</th>
	</tr>
	<!--- /end header row --->
	<!--- output product data with qty/add to cart --->
	<cfoutput query="skuTableQuery" group="sku_merchant_sku_id">
	<!--- create a row for each SKU --->
	<cfset prodCt = prodCt + 1>
	<!--- default qty value --->
	<cfset prodQtyField = "form.qty#prodCt#">
	<cfparam name="#prodQtyField#" default="">
	<cfset prodQtyVal = evaluate(prodQtyField)>
	<!--- set up the price --->
	<cfset currentPrice = skuTableQuery.sku_price>
	<cfset displayPrice = lsCurrencyFormat(skuTableQuery.sku_price,'local')>
	<cfset skuCalcPrice = currentPrice>
	<cfset showDiscountTax = false>
	<!--- if showing tax price --->
	<cfif application.cw.taxDisplayOnProduct
		AND isStruct(attributes.tax_rate) and isDefined('attributes.tax_rate.calctax') and attributes.tax_rate.calctax gt 0>
		<cfset skuCalcPrice = round(skuTableQuery.sku_Price*attributes.tax_rate.calctax*100)/100>
		<cfset displayPrice = displayPrice & '<br><span class="smallPrint">(#lsCurrencyFormat(skuCalcPrice,'local')# including #attributes.tax_rate.displaytax#% #application.cw.taxSystemLabel#)</span>'>
		<cfset showDiscountTax = true>
	</cfif>
	<!--- if showing discounts --->
	<cfif application.cw.discountsEnabled>
		<!--- check for discounts applied to each sku --->
		<cfset discountAmount = CWgetSKUDiscountAmount(
				discount_type='sku_cost',
				sku_id=sku_id,
				customer_id=attributes.customer_id,
				promo_code=attributes.promo_code
				)>
		<cfif discountAmount gt 0>
			<cfset discountedPrice = skuCalcPrice - discountAmount>
			<cfif showDiscountTax eq true>
				<cfset discountTaxText = '<span class="smallPrint"> including #attributes.tax_rate.displaytax#% #application.cw.taxSystemLabel#</span>'>
			<cfelse>
				<cfset discountTaxText = ''>
			</cfif>
			<cfset displayPrice = '<span class="CWproductPriceOld">' & displayPrice & '</span>' & '<br><span class="CWproductPriceDisc">' & lsCurrencyFormat(discountedPrice,'local') & discountTaxText & '</span>' >
		</cfif>
	</cfif>
	<tr>
		<!--- sku --->
		<td>#skuTableQuery.sku_merchant_sku_id#</td>
		<!--- option values --->
		<!--- set all options to 'none' --->
		<cfset temp = ArraySet(optionArray,1,optionCt,'none')>
			<!--- nested cfoutput ungroups options --->
			<cfoutput>
				<!--- find the current option in the OptionNames list --->
				<cfset i = listFind(optionList, skuTableQuery.optiontype_name)>
				<!--- Set the array to the option name --->
				<cfset temp = arraySet(optionArray, i, i, skuTableQuery.option_name)>
			</cfoutput>
			<!--- output each option for this sku --->
			<cfloop index="ii" from="1" to="#optionCt#">
				<td>#optionArray[ii]#</td>
			</cfloop>
		<!--- price --->
		<td>#displayPrice#</td>
		<!--- qty --->
		<td class="CWinputCell">
			<cfif application.cw.appDisplayProductQtyType is 'text'>
			<input name="qty#prodCt#" class="qty" type="text" value="#prodQtyVal#" size="1" onkeyup="extractNumeric(this,0,false)">
			<cfelse>
			<select name="qty#prodCt#">
			<cfloop from="0" to="#attributes.max_qty#" index="ii"><option value="#ii#"<cfif ii eq 0 or ii eq prodQtyVal> selected="selected"</cfif>>#ii#</option></cfloop>
			</select>
			</cfif>
			<!--- hidden field for sku id --->
			<input name="skuID#prodCt#" type="hidden" value="#skuTableQuery.sku_id#">
		</td>
	</tr>
	</cfoutput>
</table>
<!--- addSkus field contains number of skus being submitted via table options --->
<div>
	<input type="hidden" name="addSkus" value="<cfoutput>#prodCt#</cfoutput>">
	<!--- total qty used for validation of table sums --->
	<input type="hidden" name="totalQty" id="totalQty" value="0">
</div>
<!--- validation script for tables
(uses calculation script called from global scripts)
--->
<cfset formScriptvar = 'request.#attributes.form_id#FormScript'>
<cfif not isDefined(#formScriptVar#)>
<cfsavecontent variable="#formScriptVar#">
	<script type="text/javascript">
	jQuery(document).ready(function(){
		jQuery('form#CWformAddToCart input.qty').keyup(function(){
			var sumVal = jQuery('form#CWformAddToCart input.qty').sum();
			//alert(sumVal);
			jQuery('form#CWformAddToCart input#totalQty').val(sumVal);
		});
	});
	</script>
</cfsavecontent>
<cfhtmlhead text="#evaluate(formscriptvar)#">
</cfif>
</cfcase>
<!--- / END TABLES --->
<!--- SELECT BOXES ('select')--->
<cfdefaultcase>
<!--- loop the list of option IDs --->
<cfloop list="#optiondata.idlist#" index="ii">
	<div class="CWoptionSel" id="opt<cfoutput>#ii#</cfoutput>">
		<div class="CWoptionInner">
		<!--- get options for this product with sku ids --->
		<cfset optionQuery = CWquerySelectRelOptions(product_id=attributes.product_id,product_options=ii)>
		<!--- label for select list element --->
		<cfoutput><label for="optionSel#ii#">#optionQuery.optiontype_name#:</label></cfoutput>
		<!--- select list --->
		<cfset selectName = 'optionSel#ii#'>
		<cfparam name="form.#selectName#" default="">
		<cfset selectVal = evaluate('form.#selectName#')>
			<select name="<cfoutput>#selectName#</cfoutput>" id="<cfoutput>#selectName#</cfoutput>" class="CWoption required" title="<cfoutput>#optionQuery.optiontype_name#</cfoutput> is required" onkeyup="this.blur();this.focus();">
				<!--- placeholder select option --->
				<option value="" class="sku0" data-sort="-9999">-- Select --</option>
				<!--- output options --->
				<cfoutput query="optionQuery" group="option_name">
					<!--- create list of classes for related scripting, save as variable --->
					<cfsavecontent variable="skuidclasses">
						<!--- nested cfoutput ungroups query results --->
						<cfoutput>sku#sku_id# </cfoutput>
					</cfsavecontent>
					<!--- show option with listed classes --->
					<option value="#option_id#" class="#trim(skuidclasses)#"<cfif option_id eq selectVal> selected="selected"</cfif> data-sort="#option_sort#">#trim(option_name)#</option>
				</cfoutput>
			</select>
		</div>
		<!--- option description text --->
		<cfif len(trim(optionQuery.optiontype_text))>
			<cfoutput><div class="CWoptionText">#trim(optionQuery.optiontype_text)#</div></cfoutput>
		</cfif>
</div>
<!--- hidden clone div, for resetting selections --->
<div style="display:none;" class="CWoptionRes" id="res<cfoutput>#ii#</cfoutput>"></div>
</cfloop>
<!--- hidden sku ids placeholder field --->
<div><input type="hidden" value="" name="availSkus" id="availSkus"></div>
</cfdefaultcase>
<!--- / END SELECT BOXES--->
</cfswitch>
<!--- / END OUTPUT --->
<!---  JAVASCRIPT FOR SELECTION CONTROLS --->
<cfif listLen(optiondata.idlist)>
<cfsilent>
<!--- content sent to <head> of calling page --->
<cfset formScriptvar = 'request.#attributes.form_id#FormScript'>
<cfif not isDefined(#formScriptVar#)>
	<cfsavecontent variable="#formScriptVar#">
	<!-- javascript for selection boxes -->
	<script type="text/javascript">
	jQuery(document).ready(function(){
		// currency format function
      	var $cwCurrencyFormat = function(start_value,currency_symbol,space_separator,cs_precedes,thousands_sep,decimal_point) {
			<cfoutput>
			// default formatting elements
			var currency_symbol = currency_symbol || "#application.cw.currencySymbol#";
			var space_separator = space_separator || "#application.cw.currencySpace#";
			var cs_precedes = cs_precedes || #application.cw.currencyPrecedes#;
			var thousands_sep = thousands_sep || "#application.cw.currencyGroup#";
			var decimal_point = decimal_point || "#application.cw.currencyDecimal#";
			</cfoutput>
			var ret_str = '';
			var num_arr = start_value.split('.');
			var reg_ex = /\d+(\d{3})/;
			var reg_match = num_arr[0].match(reg_ex);
			while (reg_match) {
				ret_str = thousands_sep + reg_match[1] + ret_str;
				num_arr[0] = num_arr[0].substring(0, (num_arr[0].length - reg_match[1].length));
				reg_match = num_arr[0].match(reg_ex);
			   }
			   ret_str = num_arr[0] + ret_str;
		   if (num_arr.length > 1) ret_str += decimal_point + num_arr[1];
		   if (cs_precedes) {
				ret_str = currency_symbol + space_separator + ret_str;
				} else {
				ret_str += space_separator + currency_symbol;
			}
	   return ret_str;
      }
	// function runs on page load, or can be invoked: $jLoad()
	var $jLoad = function(){
		// variables for target price elements - can be changed as needed
		var price_parent = '#<cfoutput>#attributes.price_id#</cfoutput>';
		var form_parent = '#<cfoutput>#attributes.form_id#</cfoutput>';
		// debug
		// alert(price_parent + ' : ' + form_parent);
		// duplicate price area inside window (for window option form)
		var origPriceID = 'CWproductPrices-<cfoutput>#attributes.product_id#</cfoutput>';
		var windowPriceID = 'CWproductPrices-<cfoutput>#attributes.product_id#</cfoutput>w';
		jQuery('div#' + origPriceID).clone().insertBefore('#CWformAddToCartWindow').attr('id',windowPriceID).addClass('CWwindowPrice');
		// build string for selectors below
		var target_orig_low = price_parent + ' ' + '.CWproductPriceLow';
		var target_orig_high = price_parent + ' ' + '.CWproductPriceHigh';
		var target_tax_low = price_parent + ' ' + '.CWproductTaxPriceLow';
		var target_tax_high = price_parent + ' ' + '.CWproductTaxPriceHigh';
		var target_disc_low = price_parent + ' ' + '.CWproductPriceDiscLow';
		var target_disc_high = price_parent + ' ' + '.CWproductPriceDiscHigh';
		var target_alt_low = price_parent + ' ' + '.CWproductPriceAltLow';
		var target_alt_high = price_parent + ' ' + '.CWproductPriceAltHigh';
		// get original values
		var default_orig_low = jQuery(target_orig_low).text();
		var default_orig_high = jQuery(target_orig_high).text();
		var default_tax_low = jQuery(target_tax_low).text();
		var default_tax_high = jQuery(target_tax_high).text();
		var default_disc_low = jQuery(target_disc_low).text();
		var default_disc_high = jQuery(target_disc_high).text();
		var default_alt_low = jQuery(target_alt_low).text();
		var default_alt_high = jQuery(target_alt_high).text();
		// clear placeholder value on load
		jQuery('#availSkus').val();
		// create hidden copies of select elements
		jQuery(form_parent + ' ' +  'select.CWoption').each(function(){
			var res = jQuery(this).parents('div').next('div.CWoptionRes');
			// add temp id with separator -
			var tempID = jQuery(this).attr('id') + '-temp';
			var tempName = jQuery(this).attr('name') + '-temp';
			jQuery(this).clone().removeClass().addClass('CWoptionTemp').attr('id',tempID).attr('name',tempName).appendTo(res);
			// make sure res is hidden
			jQuery(res).hide();
		});
		// restore removed selection list
		var $restoreSelect = function(selectList){
			// target the -temp copy of the select list
			var origId = jQuery(selectList).attr('id');
			var formID = jQuery(selectList).parents('form').attr('id');
			//alert(form_parent + ' ' + origId);
			var reserveList = jQuery(form_parent + ' ' + 'select#' + origId + '-temp');
			// show the hidden list, remove all options
			jQuery(selectList).show().children('option').remove();
			// hide the text value
			jQuery(selectList).siblings('span.CWselectedText').hide();
			// copy original options back to parent
			jQuery(reserveList).children('option').each(function(){
				jQuery(this).clone().appendTo(selectList);
			});
			// set the default non-selected option
			jQuery(selectList).children('option.sku0').prop('selected','selected');
		};
		// restore removed option to original parent
		var $restoreOption = function(optionClass){
				// get all options in reserve copy elements
				jQuery(form_parent + ' ' + 'select.CWoptionTemp').children('option.' + optionClass).each(function(){
				// get the id of the original element
				var origId = jQuery(this).parents('select').attr('id').split('-');
				var origSelect = jQuery(form_parent + ' ' + 'select#' + origId[0]);
				// get the value of the currently restored option
				var restoreVal = jQuery(this).val();
				jQuery(origSelect).children('option[value=' + restoreVal + ']').remove();
				jQuery(this).clone().appendTo(origSelect).prop('selected','');
				jQuery(origSelect).show().siblings('span.CWselectedText').remove();
			});
		};
		// master function to set options
		var $setOptions = function(selectList){
			// create array from skus query above
			// sku_id, orig_price, alt_price, discount_price
			var sku_arr = new Array();
			var	id_arr = new Array();
				<!--- loop query, build array of sku ids and prices --->
				<cfset rowCt = 0>
				<cfoutput query="skusQuery">
					sku_arr[#rowct#] = new Array();
					sku_arr[#rowct#]["sku_id"] = '#sku_id#';
					sku_arr[#rowct#]["orig_price"] = '#sku_price#';
					sku_arr[#rowct#]["alt_price"] = '#sku_alt_price#';
					<!--- discount price defaults to regular price --->
					<cfset discountedPrice = sku_price>
					<!--- get actual discount if being used --->
					<cfif application.cw.discountsEnabled>
						<cfset discountAmount = CWgetSkuDiscountAmount(
													sku_id=sku_id,
													discount_type='sku_cost',
													customer_id=attributes.customer_id,
													promo_code=attributes.promo_code
													)>
						<cfif discountAmount gt 0>
							<cfset discountedPrice = sku_price - discountAmount>
						</cfif>
					</cfif>
					sku_arr[#rowct#]["discount_price"] = '#discountedPrice#';
					<cfif isStruct(attributes.tax_rate) and isDefined('attributes.tax_rate.calctax') and attributes.tax_rate.calctax gt 0>
						<!--- if discounts are active, apply to tax price --->
						<cfif application.cw.discountsEnabled and discountedPrice neq sku_price and isNumeric(discountedPrice)>
							sku_arr[#rowct#]["tax_price"] = '#discountedPrice*attributes.tax_rate.calctax#';
						<!--- if no discount --->
						<cfelse>
							sku_arr[#rowct#]["tax_price"] = '#sku_price*attributes.tax_rate.calctax#';
						</cfif>
					</cfif>
					id_arr[#rowct#] = '#sku_id#';
				<cfset rowct = rowct + 1>
				</cfoutput>
			// get the class(es) of the selected option that was changed
			var selOpt = jQuery(selectList).find('option:selected');
			var selClass = jQuery(selOpt).attr('class');
			// create array for list of classes
			var selected_arr = selClass.split(" ");
			// get the classes of all selected sibling options
			var global_arr = [];
			if(selected_arr.length &&  selected_arr[0] != 'sku0'){ 
				global_arr[global_arr.length] = selected_arr;
				}
			// placeholder array
			var keep_arr = new Array();
			var show_arr = new Array();
			// loop all option lists other than currently selected
			jQuery(form_parent + ' ' + 'select.CWoption').not(selectList).each(function(){
				// get array of classes for this element
				var selSiblingClass = jQuery(this).find('option:selected').attr('class');
				var sibling_arr = selSiblingClass.split(" ");
				// if a non-blank option is selected, compare arrays
				if (sibling_arr.length > 0 && sibling_arr[0] != 'sku0'){
					// add to globals
					global_arr[global_arr.length] = sibling_arr;
					// loop the sibling array
						for(var i = 0;i < sibling_arr.length;i++){
						var matchClass = sibling_arr[i];
							//if in selected array, but not found in new array
							if (jQuery.inArray(matchClass,selected_arr) > -1 && jQuery.inArray(matchClass,keep_arr) == -1){
							// add to placeholder array
							keep_arr = keep_arr.concat(matchClass);
							}
						};
				}
			});
			var ok_arr = [];								
			if (global_arr.length > 0){
				ok_arr = global_arr[0];
				if(global_arr.length > 1){
					ok_arr = CWarrayCompare.apply(window, global_arr);
				}
			}
			// end loop all option lists
			// loop the new array
			for(var i = 0;i < keep_arr.length;i++){
				var keepClass = keep_arr[i];
				//if found in selected array
				if (jQuery.inArray(keepClass,selected_arr) != -1 && jQuery.inArray(keepClass,ok_arr) != -1){
					//if not in show array
					if (jQuery.inArray(keepClass,show_arr) == -1){
						// copy to show array
						show_arr = show_arr.concat(keepClass);
					}
				}
			};
			if (show_arr == '' && selected_arr != 'sku0'){
				show_arr = selected_arr;
			}
		// placeholder value in storage field
		if(show_arr != 'sku0'){
			jQuery('#availSkus').val(show_arr);
		} else {
			jQuery('#availSkus').val();
		};
		//----------- SELECTION FUNCTIONS ----------//
		//--- change display based on selections ---//
		//------------------------------------------//
			// if not resetting
				if(show_arr != ''){
					//alert('not reset');
					// remove keeper attribute from all options to clear selection
					jQuery(form_parent + ' ' + 'select.CWoption option').removeAttr('rel','');
					// set up pricing variables
					var orig_price_arr = new Array();
					var alt_price_arr = new Array();
					var disc_price_arr = new Array();
					<cfif isStruct(attributes.tax_rate) and isDefined('attributes.tax_rate.calctax') and attributes.tax_rate.calctax gt 0>
					var tax_price_arr = new Array();
					</cfif>
					// loop classes in array
					for(var i = 0;i < show_arr.length;i++){
						var matchClass = show_arr[i];
						// get index of match to original sku_arr
						var skuID = matchClass.replace('sku','');
						var matchPos = jQuery.inArray(skuID,id_arr);
						// if matched
						if((matchClass != '')&&(matchPos != -1)){
							//add keeper attribute
						 	jQuery("'select.CWoption option." + matchClass + "'").attr('rel','keeper');
							// get skuID from the class name
							// set up price arrays

							// if the current value is not in the array, add it
							if (jQuery.inArray(sku_arr[matchPos]["orig_price"],orig_price_arr) == -1){
								orig_price_arr[orig_price_arr.length] = sku_arr[matchPos]["orig_price"];
							}
							if (jQuery.inArray(sku_arr[matchPos]["alt_price"],alt_price_arr) == -1){
								alt_price_arr[alt_price_arr.length] = sku_arr[matchPos]["alt_price"];
							}
							if (jQuery.inArray(sku_arr[matchPos]["discount_price"],disc_price_arr) == -1){
								disc_price_arr[disc_price_arr.length] = sku_arr[matchPos]["discount_price"];
							}
							<cfif isStruct(attributes.tax_rate) and isDefined('attributes.tax_rate.calctax') and attributes.tax_rate.calctax gt 0>
							if (jQuery.inArray(sku_arr[matchPos]["tax_price"],tax_price_arr) == -1){
								tax_price_arr[tax_price_arr.length] = sku_arr[matchPos]["tax_price"];
							}
							</cfif>
						}
					}
						// sort the arrays
						orig_price_arr.sort(function(a,b){return a - b});
						alt_price_arr.sort(function(a,b){return a - b});
						disc_price_arr.sort(function(a,b){return a - b});
						<cfif isStruct(attributes.tax_rate) and isDefined('attributes.tax_rate.calctax') and attributes.tax_rate.calctax gt 0>
						tax_price_arr.sort(function(a,b){return a - b});
						</cfif>
						// original price
						var origLen = orig_price_arr.length - 1;
						var val_orig_low = parseFloat(orig_price_arr[0]).toFixed(2);
						var val_orig_high = parseFloat(orig_price_arr[origLen]).toFixed(2);
						// set low price
						jQuery(target_orig_low).text($cwCurrencyFormat(val_orig_low));
						// hide or set high price
						if (origLen > 0){
						jQuery(target_orig_high).show().text($cwCurrencyFormat(val_orig_high)).siblings('.priceDelim').show();
						} else {
						jQuery(target_orig_high).hide().siblings('.priceDelim').hide();
						};
						// discount price
						var discLen = disc_price_arr.length - 1;
						var val_disc_low = parseFloat(disc_price_arr[0]).toFixed(2);
						var val_disc_high = parseFloat(disc_price_arr[discLen]).toFixed(2);
						// set low price
						jQuery(target_disc_low).text($cwCurrencyFormat(val_disc_low));
						// hide or set high price
						if (discLen > 0){
						jQuery(target_disc_high).text($cwCurrencyFormat(val_disc_high));
						} else {
						jQuery(target_disc_high).hide().siblings('.priceDelim').hide();
						};
						// tax price range
						<cfif isStruct(attributes.tax_rate) and isDefined('attributes.tax_rate.calctax') and attributes.tax_rate.calctax gt 0>
						var taxLen = tax_price_arr.length - 1;
						var val_tax_low = parseFloat(tax_price_arr[0]).toFixed(2);
						var val_tax_high = parseFloat(tax_price_arr[taxLen]).toFixed(2);
						// set low price
						jQuery(target_tax_low).text($cwCurrencyFormat(val_tax_low));
						// hide or set high price
						if (taxLen > 0){
						jQuery(target_tax_high).text($cwCurrencyFormat(val_tax_high));
						} else {
						jQuery(target_tax_high).hide().siblings('.priceDelim').hide();
						};
						</cfif>
						// alt price
						var altLen = alt_price_arr.length - 1;
						var val_alt_low = parseFloat(alt_price_arr[0]).toFixed(2);
						var val_alt_high = parseFloat(alt_price_arr[altLen]).toFixed(2);
						// set low price
						jQuery(target_alt_low).text($cwCurrencyFormat(val_alt_low));
						// hide or set high price
						if (altLen > 0){
						jQuery(target_alt_high).text($cwCurrencyFormat(val_alt_high));
						} else {
						jQuery(target_alt_high).hide().siblings('.priceDelim').hide();
						};
					// end loop classes

					// keep the 'select' option
					jQuery(form_parent + ' ' + 'select.CWoption option.sku0').attr('rel','keeper');
					// remove all non-keeper prices
					jQuery(form_parent + ' ' + 'select.CWoption option[rel!=keeper]').remove();
				// if resetting
				} else {
					// restore original prices
					jQuery(price_parent).find('span').show();
					jQuery(target_orig_low).text(default_orig_low);
					jQuery(target_orig_high).text(default_orig_high);
					jQuery(target_tax_low).text(default_tax_low);
					jQuery(target_tax_high).text(default_tax_high);
					jQuery(target_disc_low).text(default_disc_low);
					jQuery(target_disc_high).text(default_disc_high);
					jQuery(target_alt_low).text(default_alt_low);
					jQuery(target_alt_high).text(default_alt_high);
				};
				// end if resetting
			// if only one option remains in a list, show the option
			jQuery(form_parent + ' ' + 'select.CWoption:visible').each(function(){
					// debug - alerts show values being set
					//alert('select id: ' + jQuery(this).attr('id'));
					var numOpts = jQuery(this).children('option').not('.sku0').length;
					//alert('active options: ' + numOpts);
					// if one option
					if (numOpts == 1){
					// set option to selected
					var keepOpt = jQuery(this).children('option').not('.sku0');
					var keepVal = jQuery(keepOpt).val();
					jQuery(keepOpt).prop('selected','selected');
					// set up the value to show
					var valueText = jQuery(keepOpt).text();
					// show reset link if more than one option originally
					var origOpts = jQuery('select#' + jQuery(this).attr('id') + '-temp').children('option[class!=sku0]').length;
					if (origOpts == 1){
					var resetLink = '';
					} else {
					var resetLink = '<a href="#" class="CWselectReset">[x]</a>';
					};
					var valueShow = '<span class="CWselectedText">' + valueText + resetLink + '</span>';
					var selLabel = jQuery(this).prev('label');
					jQuery(selLabel).removeClass('warning');
					// add the value before the select list
					jQuery(valueShow).insertBefore(jQuery(this));
					// hide the select list - focus and blur triggers validation reset
					jQuery(this).trigger('focus').trigger('blur').removeClass('required').hide();
					};
			});
			// remove duplicates (ie)
			jQuery(form_parent + ' ' + '.CWselectedText + .CWselectedText').remove();
			// end if only one option
		// end handle selection
		// reset option when clicking
		jQuery(form_parent + ' ' + 'a.CWselectReset').click(function(){
			var parentSelect = jQuery(this).parents('span').siblings('select.CWoption');
			//alert(jQuery(parentSelect).attr('id'));
			jQuery(parentSelect).show();
			$restoreSelect(parentSelect);
			// create array for selected classes
			var restoreOption = jQuery(parentSelect).children('option').not('.sku0');
			jQuery(restoreOption).each(function(){
				var restoreClass = jQuery(this).attr('class');
				var restore_arr = restoreClass.split(" ");
					// loop classes in array
					for(var i = 0;i < restore_arr.length;i++){
						var matchClass = restore_arr[i];
						//alert(matchClass);
						// if matched, restore options
						if(matchClass != '' && matchClass !='sku0'){
								$restoreOption(matchClass);
						}
					}
					// end loop classes
			});
			// sort option lists back into sort order
			jQuery(form_parent + ' ' + 'select.CWoption').each(function(){
			// reorder by data-sort
				var newOptions = jQuery(this).find('option');
				newOptions.sort(function(a,b) {
					if (parseFloat(jQuery(a).attr('data-sort')) > parseFloat(jQuery(b).attr('data-sort'))) return 1;
					else if (parseFloat(jQuery(a).attr('data-sort')) < parseFloat(jQuery(b).attr('data-sort'))) return -1;
					else return 0
				});
				// replace unsorted options with sorted	
				jQuery(this).empty().append(newOptions);
				jQuery(this).find('option.sku0').attr('selected','selected').show().siblings('option').show();
			});
			// run the set options function based on the first select box w/ more than one visible option
			jQuery(form_parent + ' ' + 'select.CWoption:visible').not('.required').addClass('required');
			$setOptions(jQuery(form_parent + ' ' + 'select.CWoption:visible:first'));
			return false;
		});
		// end $setOptions function
		};
		<cfif attributes.display_type neq "table">
		// run on page load, based on first select list
		$setOptions(jQuery(form_parent + ' ' + 'select.CWoption:first'));
		</cfif>
	// run on change
	jQuery(form_parent + ' ' + 'select.CWoption').change(function(){
		$setOptions(jQuery(this));
	});
	// end jLoad
	};
	// invoke on page load
	$jLoad();
	<!---
	run entire script above as jLoad function when new form is invoked, passing in form name
	example: $jLoad(jQuery('#<cfoutput>#attributes.form_id#</cfoutput>'));
	 --->	 
	});
	// return elements found in all arrays 
    function CWarrayCompare() {
        var output = [];
        var countObject = {};
        var array, item, itemct;
		// loop arguments (arrays passed in to function)
        for (var i = 0; i < arguments.length; i++) {
            array = arguments[i];
            unique = {};
            for (var j = 0; j < array.length; j++) {
                item = array[j];
                itemct = countObject[item] || 0;
                if (itemct == i) {
                    countObject[item] = itemct + 1;
                }
            }
        }
        // now collect all results that are in all arrays
        for (item in countObject) {
            if (countObject[item] === arguments.length) {
                output.push(item);
            }
        }
        return(output);
    }    
	</script>
	<!-- end selection boxes script -->
	</cfsavecontent>
<!--- end content for head of page --->
<cfhtmlhead text="#evaluate(formscriptvar)#">
</cfif>
</cfsilent>
</cfif>
<!--- / END SELECT SCRIPT --->