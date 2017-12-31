<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-mod-cartdisplay.cfm
File Date: 2012-09-10
Description: creates and displays cart details, with options for various uses
==========================================================
Mode "showcart" creates editable form for cart quantity updates, etc
Mode "summary" shows cart details without update/edit functions
Mode "totals" shows order totals only, useful for split-display or quick reports
--->

<!--- cart is a cart structure from CWcart function --->
<cfparam name="attributes.cart" default="">
<cfparam name="session.cwclient.cwCartID" default="1">
<!--- show cart edit form or summary ( showcart | summary | totals ) --->
<cfparam name="attributes.display_mode" default="showcart">
<!--- show images next to products --->
<cfparam name="attributes.show_images" default="false">
<!--- show options and custom values for product --->
<cfparam name="attributes.show_options" default="false">
<!--- show sku next to product name --->
<cfparam name="attributes.show_sku" default="false">
<!--- show continue shopping link y/n --->
<cfparam name="attributes.show_continue" default="false">
<!--- show row w/ cart totals --->
<cfparam name="attributes.show_total_row" default="true">
<!--- show specific totals --->
<cfparam name="attributes.show_tax_total" default="true">
<cfparam name="attributes.show_discount_total" default="true">
<cfparam name="attributes.show_ship_total" default="true">
<cfparam name="attributes.show_order_total" default="true">
<!--- show discount descriptions --->
<cfparam name="attributes.show_discount_descriptions" default="true">
<!--- show input for discount promo code --->
<cfparam name="attributes.show_promocode_input" default="#application.cw.discountsenabled#">
<!--- show payments made and balance due --->
<cfparam name="attributes.show_payment_total" default="false">
<!--- link products to details page --->
<cfparam name="attributes.link_products" default="false">
<!--- product order (timeadded sorts by order added, othrwise by product name) --->
<cfparam name="attributes.product_order" default="">
<!--- edit cart url (not used for showcart mode - blank = not shown at all) --->
<cfparam name="attributes.edit_cart_url" default="#request.cwpage.urlShowCart#">
<!--- customer id: used for getting customer-specific discounts --->
<cfparam name="session.cwclient.cwCustomerID" default="0">
<cfparam name="attributes.customer_id" default="#session.cwclient.cwCustomerID#">
<!--- promo codes: delimited list with ^ separator --->
<cfparam name="request.cwpage.promocode" default="">
<cfparam name="attributes.promocode" default="#request.cwpage.promocode#">
<!--- page alerts and errors --->
<cfparam name="request.cwpage.cartAlert" default="">
<cfparam name="request.cwpage.cartconfirm" default="">
<cfparam name="request.cwpage.cartconfirmids" default="">
<cfparam name="request.cwpage.stockalertids" default="">
<!--- parse alert id values out of session if available --->
<cfif isDefined('session.cw.stockalertids')>
	<cfset request.cwpage.stockalertids = session.cw.stockalertids>
	<cfset structDelete(session.cw,'stockalertids')>
</cfif>
<cfif isDefined('session.cw.cartconfirmids')>
	<cfset request.cwpage.cartconfirmids = session.cw.cartconfirmids>
	<cfset structDelete(session.cw,'cartconfirmids')>
</cfif>
<!--- values for showcart mode --->
<cfif attributes.display_mode eq 'showcart'>
	<cfif isDefined('session.cw.cartAlert')>
		<cfset request.cwpage.cartAlert = session.cw.cartAlert>
		<cfset structDelete(session.cw,'cartAlert')>
	</cfif>
	<!--- alerts / confirmations --->
	<cfif isDefined('session.cw.cartConfirm')>
		<cfset request.cwpage.cartconfirm = session.cw.cartConfirm>
		<cfset structDelete(session.cw,'cartConfirm')>
	</cfif>
	<cfif isDefined('url.addedid') and len(trim(url.addedid))>
		<cfset request.cwpage.cartconfirmids = listAppend(request.cwpage.cartconfirmids,url.addedid)>
	</cfif>
	<cfif isDefined('url.alertid') and len(trim(url.alertid)) and application.cw.appEnableBackOrders neq true>
		<cfset request.cwpage.stockalertids = listAppend(request.cwpage.stockalertids,url.alertid)>
	</cfif>
</cfif>
<!--- custom errors can be passed in here --->
<cfset request.cwpage.cartErrors = ''>
	<!--- determine which columns to show --->
	<cfparam name="application.cw.taxDisplayLineItem" default="false">
	<cfparam name="application.cw.discountDisplayLineItem" default="false">
	<cfparam name="application.cw.taxChargeOnShipping" default="false">
	<cfparam name="application.cw.shipDisplayInfo" default="true">
	<!--- default country can be set in admin, used for calculations if customer selection not available --->
	<cfparam name="application.cw.defaultCountryID" default="0">
	<!--- set request values for control of display --->
	<cfset request.cwpage.shipDisplayInfo = application.cw.shipDisplayInfo>
	<cfif attributes.show_tax_total eq true>
		<cfset request.cwpage.taxDisplayLineItem = application.cw.taxDisplayLineItem>
	<cfelse>
		<cfset request.cwpage.taxDisplayLineItem = false>
	</cfif>
	<!--- if discounts are enabled, and at least one discount is applied --->
	<cfif application.cw.discountsEnabled eq true and isDefined('attributes.cart.carttotals.cartdiscounts') and attributes.cart.carttotals.cartdiscounts gt 0>
		<cfset request.cwpage.discountDisplayLineItem = application.cw.discountDisplayLineItem>
	<cfelse>
		<cfset request.cwpage.discountDisplayLineItem = false>
	</cfif>
	<cfset request.cwpage.taxChargeOnShipping = application.cw.taxChargeOnShipping>
	<!--- number of columns --->
	<cfset request.cwpage.cartColumnCount = 4>
	<!--- tax adds 2 columns --->
	<cfif request.cwpage.taxDisplayLineItem>
		<cfset request.cwpage.cartColumnCount = request.cwpage.cartColumnCount + 2>
	</cfif>
	<!--- discount adds a column --->
	<cfif request.cwpage.discountDisplayLineItem>
		<cfset request.cwpage.cartColumnCount = request.cwpage.cartColumnCount + 1>
	</cfif>
	<!--- remove checkbox adds a column --->
	<cfif  attributes.display_mode eq 'showcart'>
		<cfset request.cwpage.cartColumnCount = request.cwpage.cartColumnCount + 1>
	</cfif>
<!--- global functions --->
<cfinclude template="../inc/cw-inc-functions.cfm">
<!--- clean up form and url variables --->
<cfinclude template="../inc/cw-inc-sanitize.cfm">
<!--- page for form base action --->
<cfparam name="request.cwpage.hrefUrl" default="#CWtrailingChar(trim(application.cw.appCwStoreRoot))##request.cw.thisPage#">
<!--- page for form to post to --->
<cfparam name="attributes.form_action" default="#request.cwpage.hrefUrl#">
<!--- verify cart structure is valid, and ID matches client's session --->
<cfif isStruct(attributes.cart) and isDefined('cart.cartID') and cart.cartID eq session.cwclient.cwCartID>
	<cfset cwcart = attributes.cart>
<!--- get cart if not already defined --->
<cfelse>
	<!--- set defaults for tax region and country --->
	<cfif not (isDefined('session.cwclient.cwTaxRegionID') and isNumeric(session.cwclient.cwTaxRegionID))>
		<cfset session.cwclient.cwTaxRegionID = 0>
	</cfif>
	<!--- country can be set by default in admin, client selection/login overrides --->
	<cfif not (isDefined('session.cwclient.cwTaxCountryID') and isNumeric(session.cwclient.cwTaxCountryID) and session.cwclient.cwTaxCountryID gt 0)
			and application.cw.taxUseDefaultCountry is true>
		<cfset session.cwclient.cwTaxCountryID = application.cw.defaultCountryID>
	</cfif>
	<!--- get new cart structure --->
	<cfset cwcart = CWgetCart()>
</cfif>
<!--- /end get cart --->
<!--- cart defaults --->
	<cfparam name="cwcart.carttotals.productCount" default="0">
	<cfparam name="cwcart.carttotals.total" default="0">
	<cfparam name="cwcart.carttotals.itemCount" default="0">
	<cfparam name="cwcart.cartitems" default="#arrayNew(1)#">
<!--- if cart is empty, set alert message - usually overridden by containing page --->
<cfif attributes.display_mode eq 'showcart'
	  and cwcart.carttotals.itemCount eq 0
	  and NOT len(trim(request.cwpage.cartAlert))>
	<cfset request.cwpage.cartAlert = 'Cart is Empty'>
</cfif>
<!--- HANDLE FORM SUBMISSION --->
	<!--- // UPDATE CART // --->
	<cfif isDefined('form.action') and form.action is 'update'>
		<cfset valuesChanged = false>
		<!--- handle deleted items --->
		<cfif isDefined('form.remove')>
			<cfmodule
				template="cw-mod-cartweaver.cfm"
				cart_action="delete"
				sku_unique_id="#trim(form.remove)#"
				>
		</cfif>
		<!--- handle updated quantities --->
		<cfset unique_id_list = ''>
		<cfset sku_qty_list = ''>
		<!--- build list of unique id markers --->
		<cfloop from="1" to="#form.productCount#" index="ii">
			<cfset itemID = "#form['sku_unique_id#ii#']#">
			<cfset itemQty = "#form['qty#ii#']#">
			<cfif NOT (isNumeric(itemQty) and itemQty gt 0)>
				<cfset itemQty = 0>
			</cfif>
			<cfset unique_id_list = listAppend(unique_id_list,itemID)>
			<cfset sku_qty_list = listAppend(sku_qty_list,itemQty)>
		</cfloop>
		<!--- update all at once --->
		<cfmodule
			template="cw-mod-cartweaver.cfm"
			cart_action="update"
			sku_unique_id="#unique_id_list#"
			sku_qty="#sku_qty_list#"
			>
		<cfset valuesChanged = true>
		<!--- reset any stored ship total, since quantities may have changed --->
		<cfif session.cwclient.cwCustomerID gt 0>
			<cfset session.cwclient.cwShipTotal = 0>
		</cfif>
		<!--- handle custom info changes --->
		<cfloop from="1" to="#form.productCount#" index="ii">
			<!--- if a value is passed in, and this sku is not already set to be removed --->
			<cfif isDefined('form.customInfo#ii#')
					and not(isDefined('form.remove') and listFind(trim(form.remove),form['sku_unique_id#ii#']))>
				<cfset customInfoStr = evaluate('form.customInfo#ii#')>
				<!--- check to see if string is different --->
				<cfset oldStr = CWgetCustomInfo(listLast(form['sku_unique_id#ii#'],'-'))>
				<!--- if string is new, and we have a valid persisted quantity --->
				<cfif customInfoStr neq oldStr
					and isNumeric(form['qty#ii#']) and form['qty#ii#'] neq 0>
					<!--- delete existing item from cart, hide alerts --->
					<cfmodule
						template="cw-mod-cartweaver.cfm"
						cart_action="delete"
						sku_unique_id="#form['sku_unique_id#ii#']#"
						alert_removed="false"
						>
					<!--- add new custom info item, hide alerts --->
					<cfmodule
						template="cw-mod-cartweaver.cfm"
						cart_action="add"
						sku_id="#listFirst(form['sku_unique_id#ii#'],'-')#"
						sku_qty="#form['qty#ii#']#"
						sku_custom_info="#customInfoStr#"
						alert_added="false"
						>
					<!--- set marker for change value --->
					<cfset valuesChanged = true>
				</cfif>
			</cfif>
		</cfloop>
		<!--- if updates were made, show confirmation --->
		<cfif valuesChanged>
			<cfset request.cwpage.cartconfirm = listAppend(request.cwpage.cartconfirm,'Cart updates saved')>
			<!--- clear stored shipping total --->
			<cfset session.cwclient.cwShipTotal = 0>
		</cfif>
		<!--- remove true/false marker for order confirmed in checkout --->
		<cfset session.cw.confirmCart = false>
		<!--- set confirmation message into session --->
		<cfset session.cw.cartConfirm = request.cwpage.cartConfirm>
		<!--- reload page --->
		<cflocation url="#request.cw.thisPage#" addtoken="no">
	</cfif>
	<!--- /END UPDATE CART --->
	<!--- HANDLE PROMO CODE --->
	<cfif application.cw.discountsEnabled AND
		isDefined('form.promocode') and len(trim(form.promocode))>
		<!--- refresh list of available promo codes if it doesn't already exist --->
		<cfif not isDefined('application.cw.discountdata.promocodes')>
			<cfset discountQuery = CWgetDiscountData(true)>
		</cfif>
		<!--- get all active discounts --->
		<cfset temp = structClear(application.cw.discountdata)>
		<cfif application.cw.discountsEnabled and not isDefined('application.cw.discountdata.activediscounts')>
			<cfset discountQuery = CWgetDiscountData(refresh_data=true)>
		</cfif>
		<!--- verify promo code matches an active discount --->
		<cfif listFindNoCase(application.cw.discountdata.promocodes,trim(form.promocode),'^')>
			<cfset discountData = CWmatchPromoCode(promo_code=trim(form.promocode),
											   	   cart=cwcart,
												   customer_id=attributes.customer_id
													)>
			<!--- if we have a match --->
			<cfif discountData.discount_match_status is true>
				<cfset request.cwpage.promoresponse = "Promo code #trim(form.promocode)# applied">
				<!--- add to list if not already in the list --->
				<cfif not listFind(attributes.promocode,trim(form.promocode),'^')>
					<cfset attributes.promocode = listAppend(attributes.promocode,trim(form.promocode),'^')>
				</cfif>
			<!--- if no match, show response message --->
			<cfelseif isDefined('discountData.discount_match_response') and len(trim(discountData.discount_match_response))>
				<cfset request.cwpage.promoresponse = discountData.discount_match_response>
			</cfif>
			<!--- clear stored shipping total --->
			<cfset session.cwclient.cwShipTotal = 0>
			<!--- get new cart structure (refresh cart w/ new discount) --->
			<cfset cwcart = CWgetCart(promo_code=trim(form.promocode))>
			<!--- if not a valid promo code, show message to user --->
		<cfelse>
			<!--- set message into page request for display below --->
			<cfset request.cwpage.promoresponse = 'Promo code "#trim(form.promocode)#" not available'>
		</cfif>
		<!--- /end verify promo code --->
		<!--- if entered during checkout final step, client must reconfirm cart --->
		<cfif NOT len(trim(request.cwpage.promoresponse)) and NOT (isDefined('session.cw.confirmCart') and session.cw.confirmCart is true)>
		<cfset session.cw.confirmCart = false>
		<cflocation url="#request.cw.thisPage#" addtoken="no">
		</cfif>
	</cfif>
	<!--- /END PROMO CODE --->
	<!--- handle stock alerts --->
	<cfif application.cw.appEnableBackOrders neq true>
		<!--- if quantity has changed, show alert, mark the row below by ID --->
		<cfloop from="1" to="#arrayLen(cwcart.cartItems)#" index="cartLine">
			<!--- get info struct for each item in cart --->
			<cfset cwcartItem = cwcart.cartItems[cartLine]>
			<!--- check cart item quantity against live total in database --->
			<cfset availQty = CWgetSkuQty(CWcartItem.skuID)>
			<!--- if less available --->
			<cfif isNumeric(availQty) and availQty lt CWcartItem.quantity>
				<!--- update in cart table--->
				<cfset updateQty = CWcartUpdateItem(sku_unique_id=CWcartItem.skuUniqueID,sku_qty=availQty)>
				<!--- change in cart object --->
				<cfset cwcart.cartItems[cartLine].quantity = availQty>
				<!--- set up alert --->
				<cfset request.cwpage.stockalertids = listAppend(request.cwpage.stockalertids,CWcartItem.skuID)>
				<cfset alertMsg = 'Quantity of some items has changed: totals adjusted'>
				<cfif not request.cwpage.cartAlert contains alertMsg>
					<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,alertMsg)>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	<!--- /end stock alerts --->
	<!--- if custom info can be edited, include script for show/hide links --->
	<cfif application.cw.appDisplayCartCustomEdit and attributes.display_mode eq 'showcart'>
		<cfsavecontent variable="editInfoScript">
			<script type="text/javascript">
					jQuery(document).ready(function(){
						jQuery('span.CWcartChangeInput').hide();
						jQuery('span.CWcartChangeLink').show();
						jQuery('form#formUpdateCart a.CWchangeInfo').click(function(){
							jQuery(this).parents('span.CWcartChangeLink').hide().next('span.CWcartChangeInput').show().parents('span.CWcartCustomInfo').prev('span.CWcartCustomValue').hide();
							return false;
						});
					});
				</script>
			</cfsavecontent>
			<cfhtmlhead text="#editInfoScript#">
		</cfif>
	<!--- CALCULATE ORDER TOTALS --->
		<!--- shipping totals --->
		<cfif isDefined('session.cwclient.cwShipCountryID') and session.cwclient.cwShipCountryID gt 0 and application.cw.shipEnabled>
			<!--- if customer has confirmed shipping --->
			<cfif isDefined('session.cw.confirmShipID') and session.cw.confirmShipID gt 0>
				<!--- if we don't have a valid rate stored yet --->
				<cfif not (isDefined('session.cwclient.cwShipTotal') and session.cwclient.cwShipTotal gt 0)>
					<cfset shipVal = CWgetShipRate(
						ship_method_id=session.cw.confirmShipID,
						cart_id=cwcart.cartid
						)>
				<cfelse>
					<cfset shipVal = session.cwclient.cwShipTotal>
				</cfif>
			<cfelse>
				<cfset shipVal = 0>
			</cfif>
		<!--- subtract shipping discounts --->
		<cfif not (isDefined('cwcart.carttotals.shipOrderDiscounts') and isNumeric(cwcart.carttotals.shipOrderDiscounts) and cwcart.carttotals.shipOrderDiscounts gt 0)>
			<cfset cwcart.carttotals.shipOrderDiscounts = 0>
		</cfif>
		<cfif not (isDefined('cwcart.carttotals.shipItemDiscounts') and isNumeric(cwcart.carttotals.shipItemDiscounts) and cwcart.carttotals.shipItemDiscounts gt 0)>
			<cfset cwcart.carttotals.shipItemDiscounts = 0>
		</cfif>
		<!--- subtract shipping discounts --->
		<cfset cwcart.carttotals.shipDiscounts = cwcart.carttotals.shipOrderDiscounts>		<!--- if value returned from ship rate function is numeric (no errors) --->
		<cfif isNumeric(shipVal)>
			<!--- cannot be greater than the shipping total --->
			<cfif cwcart.carttotals.shipDiscounts gt shipVal>
				<cfset cwcart.carttotals.shipDiscounts = shipVal>
			</cfif>
			<!--- resulting total cannot be less than 0 --->
			<cfset shipTotal = max(0,shipVal - cwcart.carttotals.shipDiscounts)>
			<!--- set cart shipping total, store in client scope --->
			<cfif isNumeric(shipVal) and shipVal gt 0>
				<cfset session.cwclient.cwShipTotal = shipVal>
				<cfset cwcart.carttotals.shipping = lsNumberFormat(shipTotal,'9.99')>
			<cfelse>
				<cfset cwcart.carttotals.shipping = 0>
				<cfset session.cwclient.cwShipTotal = 0>
			</cfif>
			<!--- shipping tax --->
			<cfif request.cwpage.taxChargeOnShipping and application.cw.taxCalcType is 'localtax'>
				<cfset shipTaxVal = CWgetShipTax(
					country_id=session.cwclient.cwShipCountryID,
					region_id=session.cwclient.cwShipRegionID,
					taxable_total=cwcart.carttotals.shipping,
					cart=cwcart
					)>
			<cfelseif isDefined('request.cwpage.cartShipTaxTotal')>
				<cfset shipTaxVal = request.cwpage.cartShipTaxTotal>
			<cfelse>
				<cfset shipTaxVal = 0>
			</cfif>
			<cfset cwcart.carttotals.shippingTax = lsNumberFormat(shipTaxVal,'9.99')>
			<cfset session.cwclient.cwShipTaxTotal = cwcart.carttotals.shippingTax>
			<cfset session.cwclient.cwTaxTotal = cwcart.carttotals.tax>
			<!--- /end shipping tax --->
			<!--- add shipping amounts to cart cost total --->
			<cfset cwcart.carttotals.total = cwcart.carttotals.total + cwcart.carttotals.shipping + cwcart.carttotals.shippingTax>
		<!--- if the shipping rate is not numeric, we have an error --->
		<cfelse>
			<cfset cwcart.carttotals.shipping = 0>
			<!--- set page message shown to customer --->
			<cfif len(trim(shipVal))>
				<cfset request.cwpage.shipRateError = trim(shipval)>
			</cfif>
		</cfif>
		<!--- /end numeric value check --->
	</cfif>
	<!--- /end shipping totals --->
	<!--- set order total into client scope --->
		<cfset session.cwclient.cwOrderTotal = cwcart.carttotals.total>
		<!--- get existing payments for this order --->
		<cfif attributes.show_payment_total and isDefined('session.cwclient.cwCompleteOrderID') and session.cwclient.cwCompleteOrderID gt 0>
			<cfset orderPayments = CWorderPaymentTotal(session.cwclient.cwCompleteOrderID)>
		<cfelse>
			<cfset orderPayments = 0>
		</cfif>
		<!--- deduct existing payments --->
		<cfset tempTotal= cwcart.carttotals.total>
		<cfif attributes.show_payment_total>
			<cfset tempTotal= tempTotal - orderPayments >
		</cfif>
	</cfsilent>
	<!--- //////////// --->
	<!--- START OUTPUT --->
	<!--- //////////// --->
	<!--- TOTALS ONLY --->
	<cfif attributes.display_mode eq 'totals'>
	<cfoutput>
	<p class="CWcartTotals">
		<!--- discounts --->
		<cfif attributes.show_discount_total and application.cw.discountsEnabled and cwcart.carttotals.cartDiscounts gt 0>
			<span class="label">Item Total:</span><span class="CWtotalText"><cfoutput>#lsCurrencyFormat(cwcart.carttotals.sub + cwcart.carttotals.cartDiscounts,'local')#</cfoutput> </span><br>
			<span class="label CWdiscountText">Discounts:</span><span class="CWtotalText CWdiscountText">-<cfoutput>#lsCurrencyFormat(cwcart.carttotals.cartDiscounts,'local')#</cfoutput> </span><br>
		</cfif>
		<!--- cart subtotal --->
		<span class="label CWsubtotalText">Subtotal:</span><span class="CWtotalText"><cfoutput>#lsCurrencyFormat(cwcart.carttotals.sub,'local')#</cfoutput> </span>
		<!--- edit cart link --->
			<cfif len(trim(attributes.edit_cart_url)) and not attributes.display_mode eq 'showcart'>
				<span class="CWeditLink">
					&raquo;&nbsp;<a href="<cfoutput>#attributes.edit_cart_url#</cfoutput>">Edit Cart</a>
				</span>
			</cfif>
		<br>
		<!--- tax total --->
		<cfif attributes.show_tax_total>
			<span class="label"><cfoutput>#application.cw.taxSystemLabel#</cfoutput>:</span><span class="CWtotalText"><cfoutput>#lsCurrencyFormat(cwcart.carttotals.tax,'local')#</cfoutput> </span><br>
		</cfif>
		<!--- shipping total if shipping is selected --->
		<cfif attributes.show_ship_total>
			<cfif application.cw.shipEnabled
				AND isDefined('session.cw.confirmShipID')
				AND session.cw.confirmShipID gt 0
				AND isDefined('cwcart.carttotals.shipping')>
				<!--- shipping base cost --->
				<span class="label">Shipping/Handling:</span><span class="CWtotalText"><cfoutput>#lsCurrencyFormat(cwcart.carttotals.shipping + cwcart.carttotals.shipDiscounts,'local')#</cfoutput> </span>
				<!--- shipping discounts --->
				<cfif application.cw.discountsEnabled and cwcart.carttotals.shipDiscounts gt 0 and attributes.show_discount_total>
					<br><span class="label CWdiscountText">Shipping Discounts:</span><span class="CWdiscountText CWtotalText">-<cfoutput>#lsCurrencyFormat(cwcart.carttotals.shipDiscounts,'local')#</cfoutput> </span>
					<br><span class="label CWsubtotalText">Shipping Total:</span><span class="CWsubtotalText CWtotalText"><cfoutput>#lsCurrencyFormat(cwcart.carttotals.shipping,'local')#</cfoutput> </span>
				</cfif>
				<br>
				<!--- shipping value message (if error or other text returned for ship total above) --->
				<cfif isDefined('request.cwpage.shipRateError')>
					<span class="label">&nbsp;</span><span class="CWtotalText"><cfoutput>#request.cwpage.shipRateError#</cfoutput> </span><br>
				</cfif>
				<!--- shipping tax --->
				<cfif isDefined('cwcart.carttotals.shippingTax')
					and cwcart.carttotals.shippingTax gt 0
					and request.cwpage.taxChargeOnShipping
					and attributes.show_tax_total>
					<cfoutput>
						<span class="label">Shipping #application.cw.taxSystemLabel#:</span><span class="CWtotalText">#lsCurrencyFormat(cwcart.carttotals.shippingTax,'local')# </span><br>
					</cfoutput>
				<cfelse>
					<cfset cwcart.carttotals.shippingTax = 0>
				</cfif>
			</cfif>
		</cfif>
	</p>
	<!--- BALANCE / PAYMENT TOTALS --->
			<!--- show order total --->
			<cfif attributes.show_order_total>
				<p class="CWtotal">
				<span class="label CWsubtotalText">Order Total:</span><span class="CWtotalText CWsubtotalText"><cfoutput>#lsCurrencyFormat(cwcart.carttotals.total,'local')#</cfoutput> </span>
				</p>
				<!--- show payments total --->
				<cfif orderPayments gt 0 and attributes.show_payment_total>
					<p class="CWtotal">
					<span class="label CWsubtotalText">Payments Made:</span><span class="CWtotalText CWsubtotalText">-<cfoutput>#lsCurrencyFormat(orderPayments,'local')#</cfoutput> </span>
					</p>
					<!--- balance due --->
					<p class="CWtotal">
					<span class="label CWsubtotalText">Balance Due:</span><span class="CWtotalText CWsubtotalText"><cfoutput>#lsCurrencyFormat(tempTotal,'local')#</cfoutput> </span>
					</p>
				</cfif>
			</cfif>
			<!--- /end if showing order total --->
		</cfoutput>
	<!--- /end mode = totals --->
	<!--- FULL CONTENT (showcart | summary) --->
	<cfelse>
			<!--- if showcart mode, wrap table in form to handle cart updates --->
			<cfif  attributes.display_mode eq 'showcart'>
			<form name="updatecart" action="<cfoutput>#attributes.form_action#</cfoutput>" method="post" id="formUpdateCart">
			</cfif>
				<!--- CART PRODUCTS TABLE --->
				<!--- products in cart--->
				<table class="CWtable" id="CWcartProductsTable">
					<thead>
						<!--- alert row --->
						<tr class="fadeOut CWalertRow">
							<!--- dynamic column span, depends on discounts or taxes on each line --->
							<td colspan="<cfoutput>#request.cwpage.cartColumnCount#</cfoutput>" class="noPad">
								<cfif isDefined('request.cwpage.cartAlert') and len(trim(request.cwpage.cartAlert))>
									<cfoutput>
										<div class="CWalertBox alertText">
											<div>#replace(request.cwpage.cartAlert,',','</div>
											<div>','all')#</div>
										</div>
									</cfoutput>
								</cfif>
								<cfif isDefined('request.cwpage.cartconfirm') and len(trim(request.cwpage.cartconfirm))>
									<cfoutput>
										<div class="CWconfirmBox confirmText">
											<div>#replace(request.cwpage.cartconfirm,',','</div>
											<div>','all')#</div>
										</div>
									</cfoutput>
								</cfif>
							</td>
						</tr>
						<!--- table headers --->
						<tr class="headerRow">
							<!--- product name --->
							<th>Item</th>
							<!--- quantity --->
							<th class="center">Qty.</th>
							<!--- price --->
							<th class="CWleft">Price</th>
							<!--- discounts --->
							<cfif request.cwpage.discountDisplayLineItem>
								<th class="CWleft">Discount</th>
							</cfif>
							<!--- taxes --->
							<cfif request.cwpage.taxDisplayLineItem>
							<th>Subtotal</th>
							<th class="CWleft"><cfoutput>#application.cw.taxSystemLabel#</cfoutput></th>
							</cfif>
							<!--- total --->
							<th class="CWleft">Total</th>
							<cfif  attributes.display_mode eq 'showcart'>
							<th class="center notBold smallPrint"><input type="checkbox" rel="checkAllRemove" name="checkAllProducts" class="checkAll" tabindex="1">Remove</th>
							</cfif>
						</tr>
					</thead>
					<tbody>
						<cfoutput>
							<cfloop from="1" to="#arrayLen(cwcart.cartItems)#" index="cartLine">
								<!--- get info struct for each item in cart --->
								<cfset cwcartItem = cwcart.cartItems[cartLine]>
								<!--- get image for item ( add to cart item info )--->
								<cfif attributes.show_images>
									<cfset cwcartItem.cartImg = CWgetImage(product_id=CWcartItem.ID,image_type=4,default_image=application.cw.appImageDefault)>
								<cfelse>
									<cfset cwcartItem.cartImg = ''>
								</cfif>
								<!--- url for linked info --->
								<cfset cwcartItem.itemUrl = '#request.cwpage.urlDetails#?product=#CWcartItem.ID#'>
								<cfset rowClass = 'itemRow row-#cartLine#'>
								<cfif isDefined('request.cwpage.stockalertids') and listFindNoCase(request.cwpage.stockalertids,CWcartItem.skuUniqueId)>
									<cfset rowClass = rowClass & ' stockAlert'>
								</cfif>
								<cfif isDefined('request.cwpage.cartconfirmids') and listFindNoCase(request.cwpage.cartconfirmids,CWcartItem.skuUniqueId)>
									<cfset rowClass = rowClass & ' cartConfirm'>
								</cfif>
								<tr class="#rowClass#">
									<!--- product name, image, options --->
									<td class="productCell">
										<!--- product image --->
										<cfif len(trim(CWcartItem.cartImg))>
											<div class="CWcartImage">
												<cfif attributes.link_products>
												<a href="#CWcartItem.itemUrl#" title="View Product">
													<img src="#CWcartItem.cartImg#" alt="#CWcartItem.name#">
												</a>
												<cfelse>
													<img src="#CWcartItem.cartImg#" alt="#CWcartItem.name#">
												</cfif>
											</div>
										</cfif>
										<!--- product name --->
										<div class="CWcartItemDetails">
											<span class="CWcartProdName">
												<cfif attributes.link_products>
												<a href="#CWcartItem.itemUrl#" title="View Product" class="CWlink">#CWcartItem.name#</a>
												<cfelse>
												#CWcartItem.name#
												</cfif>
												<cfif attributes.show_sku>
													<br><span class="CWcartSkuName">(#CWcartItem.MerchSKUID#)</span>
												</cfif>
											</span>
											<!--- sku options --->
											<cfif arrayLen(CWcartItem.options) gt 0 and attributes.show_options>
												<!--- sort the array --->
												<cfloop index="outer" from="1" to="#arrayLen(CWcartItem.options)#">
													<cfloop index="inner" from="1" to="#arrayLen(CWcartItem.options)-1#">
														<!--- if sort comes first --->
														<cfif CWcartItem.options[inner].sort lt CWcartItem.options[outer].sort>
															<cfset arraySwap(CWcartItem.options,outer,inner)>
															<!--- if not by sort, by name --->
														<cfelseif CWcartItem.options[inner].sort eq CWcartItem.options[outer].sort and CWcartItem.options[inner].name gt CWcartItem.options[outer].name>
															<cfset arraySwap(CWcartItem.options,outer,inner)>
														</cfif>
													</cfloop>
												</cfloop>
												<cfset displayOptions = CWcartItem.options>
												<!--- loop the sorted array, show each option with its value --->
												<cfloop from="1" to="#arrayLen(displayOptions)#" index="optionNumber">
													<div class="CWcartOption">
														<span class="CWcartOptionName">#displayOptions[optionNumber].name#:</span>
														<span class="CWcartOptionValue">#displayOptions[optionNumber].value#</span>
													</div>
												</cfloop>
											</cfif>
											<!--- custom value --->
											<cfif CWcartItem.skuID neq CWcartItem.SkuUniqueID
												  and application.cw.appDisplayCartCustom and attributes.show_options>
												<cfset phraseID = listLast(CWcartItem.SkuUniqueID,'-')>
												<cfset phraseText = CWgetCustomInfo(phrase_ID=phraseID)>
												<!--- length of text to show before trimming --->
												<cfset trimLength = 20>
												<cfif len(trim(phraseText))>
													<div class="CWcartOption">
														<cfif len(trim(CWcartItem.customInfoLabel))>
															<span class="CWcartCustomLabel">#CWcartItem.customInfoLabel#:</span>
														</cfif>
														<span class="CWcartCustomValue">
															#left(trim(phraseText),trimlength)#
															<cfif len(trim(phraseText)) gt trimlength>...</cfif>
														</span>
														<!--- if allowed to edit --->
														<cfif application.cw.appDisplayCartCustomEdit and attributes.display_mode eq 'showcart'>
															<span class="CWcartCustomInfo">
																<span class="CWcartChangeLink" style="display:none;">[<a href="##" class="CWchangeInfo">x</a>]</span>
																<span class="CWcartChangeInput">
																	<input type="text" name="customInfo#cartLine#" class="custom" size="22" value="#phraseText#" maxlength="255">
																</span>
															</span>
														</cfif>
													</div>
												</cfif>
											</cfif>
											<!--- free shipping message --->
											<cfif application.cw.appDisplayFreeShipMessage and ((not isDefined('CWcartItem.shipEnabled')) or CWcartItem.shipEnabled eq true)
											and (CWcartItem.shipCharge is not 'true' or isDefined('CWcartItem.shipDiscountsApplied.percent') and CWcartItem.shipDiscountsApplied.percent eq 100)>
											<div class="CWcartOption CWshipText">#application.cw.appFreeShipMessage#</div>
											</cfif>
										</div>
										<!--- hidden field for sku --->
										<div>
											<input name="sku_unique_id#cartLine#" type="hidden" value="#CWcartItem.SKUuniqueID#">
										</div>
									</td>
									<!--- qty --->
									<td class="qtyCell center">
										<cfif attributes.display_mode eq 'showcart'>
										<input name="qty#cartLine#" type="text" value="#CWcartItem.quantity#" size="2" onkeyup="extractNumeric(this,0,false)" class="qty">
										<input name="qty_now#cartLine#" type="hidden" value="#CWcartItem.quantity#">
										<cfelse>
										#CWcartItem.quantity#
										</cfif>
									</td>
									<!--- price --->
									<td class="priceCell">
										<span class="CWcartPrice">#lsCurrencyFormat(CWcartItem.price,'local')#</span>
									</td>
									<!--- discounts --->
									<cfif request.cwpage.discountDisplayLineItem>
										<td class="priceCell">#lsCurrencyFormat(CWcartItem.discountAmount,'local')#</td>
									</cfif>
									<!--- taxes (subtotal before tax, and the tax amount) --->
									<cfif request.cwpage.taxDisplayLineItem>
									<td class="priceCell"><cfoutput>#lsCurrencyFormat(CWcartItem.subTotal,'local')#</cfoutput></td>
									<td class="priceCell"><cfoutput>#lsCurrencyFormat(CWcartItem.tax,'local')#</cfoutput></td>
									</cfif>
									<!--- total --->
									<td class="totalCell totalAmounts">
										<span class="CWcartPrice">#lsCurrencyFormat(CWcartItem.total,'local')#</span>
									</td>
									<cfif  attributes.display_mode eq 'showcart'>
									<td class="checkboxCell center">
										<!--- remove item checkbox --->
										<input name="remove" type="checkbox" class="formCheckbox checkAllRemove" value="#CWcartItem.SkuUniqueID#" rel="group1">
									</td>
									</cfif>
								</tr>
							</cfloop>
						</cfoutput>
						<!--- /end product rows --->
						<!---DISCOUNT INFO / CONTINUE LINK --->
						<cfif attributes.show_total_row or attributes.show_discount_descriptions>
						<tr class="totalRow">
							<td>
								<!--- continue shopping --->
								<cfif attributes.show_continue eq true>
									<cfif isDefined('request.cwpage.returnUrl') and len(trim(request.cwpage.returnUrl))>
										<p class="CWcontShop">&raquo;&nbsp;<a href="<cfoutput>#request.cwpage.returnUrl#</cfoutput>">Continue Shopping</a></p>
									</cfif>
								</cfif>
								<!--- applied discount descriptions --->
								<cfif attributes.show_discount_descriptions>
									<!--- reset description list --->
									<cfset request.cwpage.discountDescriptions = ''>
									<!--- loop list of applied discounts --->
									<cfloop list="#request.cwpage.discountsapplied#" index="d">
									<!--- lookup description --->
									<cfset discountDescription = CWgetDiscountDescription(d)>
									<!--- if description exists, add it to a list --->
									<cfif len(trim(discountDescription)) and listFind(valueList(application.cw.discountData.activeDiscounts.discount_id),d)>
										<cfset request.cwpage.discountDescriptions = listAppend(request.cwpage.discountDescriptions,trim(discountDescription),'|')>
									</cfif>
									</cfloop>
									<!--- if we have descriptions to show --->
									<cfif listLen(request.cwpage.discountDescriptions,'|')>
										<div class="CWcartDiscounts">
										<p class="CWdiscountHeader">Discounts applied to this order:</p>
											<cfloop list="#request.cwpage.discountDescriptions#" index="i" delimiters="|">
											<cfoutput><p>#i#</p></cfoutput>
											</cfloop>
										</div>
									</cfif>
								</cfif>
							</td>
							<!--- ORDER TOTALS --->
							<!--- text labels for totals --->
							<td colspan="<cfoutput>#request.cwpage.cartColumnCount - 3#</cfoutput>" class="CWright totalCell">
								<cfif attributes.show_total_row>
									<!--- discounts / subtotal --->
									<cfif attributes.show_discount_total
										and application.cw.discountsEnabled
										and cwcart.carttotals.cartDiscounts gt 0>
										<span class="label">Item Total:</span><br>
										<span class="label CWdiscountText">Discounts: </span><br>
									</cfif>
									<!--- subtotal label --->
									<span class="label CWsubtotalText">Subtotal: </span>
									<!--- tax label --->
									<cfif attributes.show_tax_total>
									<br><span class="label"><cfoutput>#application.cw.taxSystemLabel#</cfoutput>: </span>
									</cfif>
									<!--- if shipping is selected, shipping label --->
									<cfif application.cw.shipEnabled
										AND isDefined('session.cw.confirmShipID')
										AND session.cw.confirmShipID gt 0
										AND isDefined('cwcart.carttotals.shipping')>
										<!--- if showing shipping totals --->
										<cfif attributes.show_ship_total>
											<br><span class="label">Shipping/Handling: </span>
											<!--- shipping discounts --->
											<cfif application.cw.discountsEnabled
												and cwcart.carttotals.shipDiscounts gt 0
												and attributes.show_discount_total>
											<br><span class="label CWdiscountText">Shipping Discounts: </span>
											<br><span class="label CWsubtotalText">Shipping Total: </span>
											</cfif>
											<!--- shipping tax --->
											<cfif isDefined('cwcart.carttotals.shippingTax') and cwcart.carttotals.shippingTax gt 0 and request.cwpage.taxChargeOnShipping>
												<br><span class="label">Shipping <cfoutput>#application.cw.taxSystemLabel#</cfoutput>: </span>
											</cfif>
										</cfif>
										<!--- order total label --->
										<cfif attributes.show_order_total>
											<br><span class="label CWsubtotalText">Order Total: </span>
										</cfif>
									</cfif>
									<!--- payment total --->
									<cfif orderPayments gt 0 and attributes.show_payment_total>
									<br><span class="label CWsubtotalText">Payments Made: </span>
									</cfif>
								</cfif>
							</td>
							<!--- total amounts --->
							<td class="totalCell totalAmounts">
								<cfif attributes.show_total_row>
								<cfoutput>
									<!--- discounts / subtotal --->
									<cfif attributes.show_discount_total
										and application.cw.discountsEnabled
										and cwcart.carttotals.cartDiscounts gt 0>
										<span class="CWtotalText">#lsCurrencyFormat(cwcart.carttotals.sub + cwcart.carttotals.cartDiscounts,'local')# </span><br>
										<span class="CWtotalText CWdiscountText">-#lsCurrencyFormat(cwcart.carttotals.cartDiscounts,'local')# </span><br>
									</cfif>
									<!--- subtotal --->
									<span class="CWtotalText CWsubtotalText">#lsCurrencyFormat(cwcart.carttotals.sub,'local')# </span>
									<!--- tax total --->
									<cfif attributes.show_tax_total>
									<br><span class="CWtotalText">#lsCurrencyFormat(cwcart.carttotals.tax,'local')# </span>
									</cfif>
									<!--- if shipping is selected, shipping total --->
									<cfif application.cw.shipEnabled
										AND isDefined('session.cw.confirmShipID')
										AND session.cw.confirmShipID gt 0
										AND isDefined('cwcart.carttotals.shipping')>
										<!--- shipping totals --->
										<cfif attributes.show_ship_total>
											<br><span class="CWtotalText">#lsCurrencyFormat(cwcart.carttotals.shipping + cwcart.carttotals.shipDiscounts,'local')# </span>
											<!--- shipping discounts --->
											<cfif application.cw.discountsEnabled
												and cwcart.carttotals.shipDiscounts gt 0
												and attributes.show_discount_total>
											<br><span class="CWtotalText CWdiscountText">-#lsCurrencyFormat(cwcart.carttotals.shipDiscounts,'local')# </span>
											<br><span class="CWtotalText CWsubtotalText">#lsCurrencyFormat(cwcart.carttotals.shipping,'local')# </span>
											</cfif>
											<!--- shipping tax --->
											<cfif isDefined('cwcart.carttotals.shippingTax') and cwcart.carttotals.shippingTax gt 0 and application.cw.taxChargeOnShipping>
												<br><span class="CWtotalText">#lsCurrencyFormat(cwcart.carttotals.shippingTax,'local')# </span>
											</cfif>
										</cfif>
										<!--- complete order total (payment due amount) --->
										<cfif attributes.show_order_total>
											<br><span class="CWtotalText CWsubtotalText">#lsCurrencyFormat(tempTotal,'local')# </span>
										</cfif>
									</cfif>
									<!--- /end if shipping enabled --->
								<!--- payments made total --->
								<cfif orderPayments gt 0 and attributes.show_payment_total>
									<br><span class="CWtotalText">#lsCurrencyFormat(orderPayments,'local')# </span>
								</cfif>
							</cfoutput>
							</cfif>
						</td>
						<!--- /end totalCell --->
						<cfif  attributes.display_mode eq 'showcart'>
						<td class="center">
							<!--- update button --->
							<input name="updateCart" type="submit" class="CWformButtonSmall" id="update" value="Update">
							<input name="action" type="hidden" id="action" value="update">
						</td>
						</cfif>
					</tr>
					</cfif>
				</tbody>
			</table>
			<!--- /end products table --->
		<cfif  attributes.display_mode eq 'showcart'>
			<!--- hidden input: number of products --->
			<div>
				<input type="hidden" name="productCount" value="<cfoutput>#arrayLen(cwcart.cartItems)#</cfoutput>">
			</div>
		</form>
		</cfif>
		<!--- promocode input --->
	<cfif attributes.show_promocode_input>
	<div class="CWpromoCode">
		<form name="cartpromo" action="<cfoutput>#attributes.form_action#</cfoutput>" method="post" id="formCartPromo">
			<p>Enter Promotional Code: </p>
			<input type="text" name="promocode" id="CWpromocode" size="20" maxlength="255" value="">
			<input name="submitPromo" type="submit" class="CWformButtonSmall" id="CWsubmitPromo" value="Apply Code">
		</form>
		<cfif isDefined('request.cwpage.promoresponse') and len(trim(request.cwpage.promoresponse))>
			<div class="CWpromoResponse">
			<p><cfoutput>#request.cwpage.promoresponse#</cfoutput></p>
			</div>
		</cfif>
	</div>
	</cfif>
	<!--- edit cart link --->
	<cfif len(trim(attributes.edit_cart_url)) and not attributes.display_mode eq 'showcart'>
	<p class="CWeditLink">&raquo;&nbsp;<a href="<cfoutput>#attributes.edit_cart_url#</cfoutput>">Edit Cart</a></p>
	</cfif>
</cfif>
<!--- /END Display Mode --->