<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-mod-orderdisplay.cfm
File Date: 2012-09-10
Description: creates and displays order details, with options for various uses
NOTES:
Mode "summary" shows cart details without update/edit functions
Mode "totals" shows order totals only, useful for split-display or quick reports
--->

<!--- order details passed in (query) --->
<cfparam name="attributes.order_query" default="">
<!--- transfer order passed in to shorter variable --->
<cfset orderQuery = attributes.order_query>
<!--- show cart edit form or summary ( summary | totals ) --->
<cfparam name="attributes.display_mode" default="summary">
<!--- show images next to products --->
<cfparam name="attributes.show_images" default="false">
<!--- show options and custom values for product --->
<cfparam name="attributes.show_options" default="false">
<!--- show sku next to product name --->
<cfparam name="attributes.show_sku" default="false">
<!--- show row w/ order totals --->
<cfparam name="attributes.show_total_row" default="true">
<!--- show specific totals --->
<cfparam name="attributes.show_tax_total" default="true">
<cfparam name="attributes.show_discount_total" default="true">
<cfparam name="attributes.show_ship_total" default="true">
<cfparam name="attributes.show_order_total" default="true">
<cfparam name="attributes.show_tax_id" default="#application.cw.taxDisplayID#">
<!--- show discount descriptions --->
<cfparam name="attributes.show_discount_descriptions" default="true">
<!--- show payments made, deduct from order total --->
<cfparam name="attributes.show_payment_total" default="true">
<!--- link products to details page --->
<cfparam name="attributes.link_products" default="false">
<!--- shipping method name (overrides auto lookup below) --->
<cfparam name="attributes.ship_method_name" default="">
<!--- custom errors can be passed in here --->
<cfset request.cwpage.cartErrors = ''>
<!--- order defaults --->
<cfparam name="orderQuery.recordCount" default="0">
<!--- determine which columns to show --->
<cfparam name="application.cw.taxDisplayLineItem" default="false">
<cfparam name="application.cw.discountDisplayLineItem" default="false">
<cfparam name="application.cw.taxChargeOnShipping" default="false">
<cfparam name="application.cw.shipDisplayInfo" default="true">
<cfset request.cwpage.shipDisplayInfo = application.cw.shipDisplayInfo>
<cfset request.cwpage.taxDisplayLineItem = application.cw.taxDisplayLineItem>
<!--- if discounts are enabled, and at least one discount applied  --->
<cfif application.cw.discountsEnabled and orderQuery.order_discount_total gt 0>
	<cfset request.cwpage.discountDisplayLineItem = application.cw.discountDisplayLineItem>
<cfelse>
	<cfset request.cwpage.discountDisplayLineItem = false>
</cfif>
<cfset taxChargeOnShipping = application.cw.taxChargeOnShipping>
<!--- number of columns --->
<cfset request.cwpage.cartColumnCount = 4>
<!--- tax adds 2 columns --->
<cfif request.cwpage.taxDisplayLineItem>
	<cfset request.cwpage.cartColumnCount = request.cwpage.cartColumnCount + 2>
</cfif>
<!--- discount adds 1 column --->
<cfif request.cwpage.discountDisplayLineItem>
	<cfset request.cwpage.cartColumnCount = request.cwpage.cartColumnCount + 1>
</cfif>
<!--- global functions --->
<cfinclude template="../inc/cw-inc-functions.cfm">
<!--- clean up form and url variables --->
<cfinclude template="../inc/cw-inc-sanitize.cfm">
<!--- QUERY: get payment total applied to order --->
<cfset orderPayments = CWorderPaymentTotal(orderQuery.order_id)>
<!--- payment total --->
<cfif attributes.show_payment_total>
	<!--- get payment types associatd to an order --->
	<cfset paymentQuery = CWorderPaymentTypes(orderQuery.order_id)>
	<!--- only show paid in full message if there is no 'account' payment --->
	<cfif listFindNoCase(valueList(paymentQuery.payment_type),'account')
	AND listFindNoCase(valueList(paymentQuery.payment_status),'approved')>
		<!--- note: custom notes or paid-order status can be added here --->
		<cfset request.cwpage.zeroBalanceMessage = "On Account">
	<cfelse>
		<cfset request.cwpage.zeroBalanceMessage = "Paid in Full">
	</cfif>
</cfif>
<!--- use orderquery name for shipping method if not passed in --->
<cfif attributes.ship_method_name is '' and len(trim(orderQuery.ship_method_name))>
	<cfset attributes.ship_method_name = trim(orderQuery.ship_method_name)>
</cfif>
</cfsilent>
<!--- //////////// --->
<!--- START OUTPUT --->
<!--- //////////// --->
<!--- VERIFY ORDER EXISTS --->
<cfif orderQuery.recordCount gt 0>
	<!--- TOTALS ONLY --->
	<cfif attributes.display_mode eq 'totals'>
	<cfoutput>
		<p>
			<!--- order subtotal --->
			<span class="label CWsubtotalText">Subtotal:</span><span class="CWtotalText CWsubtotalText">#lsCurrencyFormat(orderQuery.order_subtotal,'local')# </span><br>
			<!--- discounts total --->
			<cfif application.cw.discountsEnabled
				and attributes.show_discount_total
				and orderQuery.order_discount_total gt 0>
				<span class="CWdiscountText label">Discounts:</span><span class="CWtotalText CWdiscountText">-#lsCurrencyFormat(orderQuery.order_discount_total,'local')# </span><br>
			</cfif>
			<!--- tax label --->
			<cfif attributes.show_tax_total>
			<span class="label">#application.cw.taxSystemLabel#:</span><span class="CWtotalText">#lsCurrencyFormat(orderQuery.order_tax,'local')# </span><br>
			</cfif>
			<!--- shipping total --->
			<cfif application.cw.shipEnabled AND attributes.show_ship_total>
			<cfif orderQuery.order_shipping gt 0>
				<span class="label">Shipping/Handling:</span><span class="CWtotalText">#lsCurrencyFormat(orderQuery.order_shipping + orderQuery.order_ship_discount_total,'local')# </span>
				<!--- shipping discounts --->
				<cfif application.cw.discountsEnabled and orderQuery.order_ship_discount_total gt 0 AND attributes.show_discount_total>
						<br><span class="CWdiscountText label">Shipping Discounts:</span><span class="CWdiscountText CWtotalText">-#lsCurrencyFormat(orderQuery.order_ship_discount_total,'local')# </span>
						<br><span class="label CWsubtotalText">Shipping Total:</span><span class="CWtotalText CWsubtotalText">#lsCurrencyFormat(orderQuery.order_shipping,'local')# </span>
					</cfif>
			</cfif>
			<br>
			<!--- shipping tax --->
			<cfif orderQuery.order_shipping_tax gt 0 and application.cw.taxChargeOnShipping>
				<br><span class="label">Shipping #application.cw.taxSystemLabel#:</span><span class="CWtotalText">#lsCurrencyFormat(orderQuery.order_shipping_tax,'local')# </span>
			</cfif>
		</cfif>
		</p>
		<!--- complete order total (payment due amount) --->
		<cfif attributes.show_order_total>
		<p class="CWtotal">
		<span class="label CWsubtotalText">Order Total:</span><span class="CWtotalText">#lsCurrencyFormat(orderQuery.order_total ,'local')# </span>
		</p>
		</cfif>
		<!--- payment total --->
		<cfif attributes.show_payment_total>
			<p class="CWtotal">
				<cfif lsCurrencyFormat(orderPayments,'local') eq lsCurrencyFormat(orderQuery.order_total,'local')>
					<span class="label">#request.cwpage.zeroBalanceMessage#</span>
				<cfelseif orderPayments gt 0>
				<span class="label CWsubtotalText">Payments:</span><span class="CWtotalText">-#lsCurrencyFormat(orderPayments,'local')# </span>
			</cfif>
			</p>
		</cfif>
		</cfoutput>
		<div class="CWclear"></div>
		<!--- /end Totals --->
		<!--- FULL CONTENT (summary) --->
	<cfelse>
		<!--- CUSTOMER INFO --->
		<table class="CWtable">
			<thead>
				<tr class="headerRow">
					<th>Order Details</th>
					<cfif application.cw.shipEnabled and request.cwpage.shipDisplayInfo>
						<th>Shipping Information</th>
					</cfif>
				</tr>
			</thead>
			<tbody>
				<tr>
					<!--- order details --->
					<td>
						<cfoutput>
						<p>
						<strong>Order ID: #orderQuery.order_id#</strong><br>
						<strong>Status: #orderQuery.shipstatus_name#</strong><br>
						<cfif attributes.show_tax_id and len(trim(application.cw.taxIDNumber))>
						#application.cw.taxSystemLabel# ID: #trim(application.cw.taxIDNumber)#<br></cfif>
						Sold To: #orderQuery.customer_first_name# #orderQuery.customer_last_name#<br>
						Email: #orderQuery.customer_email#<br>
						Customer ID: #orderQuery.customer_id#
						</p>
						</cfoutput>
					</td>
					<!--- shipping info --->
					<cfif application.cw.shipEnabled and request.cwpage.shipDisplayInfo>
						<td>
						<cfoutput>
						<p>
						Ship To:
						<cfif len(trim(orderQuery.order_ship_name))>#orderQuery.order_ship_name#<br></cfif>
						<cfif len(trim(orderQuery.order_company))>#orderQuery.order_company#<br></cfif>
						<cfif len(trim(orderQuery.order_address1))>#orderQuery.order_address1#</cfif>
						<cfif len(trim(orderQuery.order_address2))>, #orderQuery.order_address2#</cfif><br>
						#orderQuery.order_city#, #orderQuery.order_state# #orderQuery.order_zip#
						<cfif len(trim(orderQuery.order_country))>, #orderQuery.order_country#</cfif>
						<cfif len(trim(attributes.ship_method_name))><br>Ship Via: #attributes.ship_method_name#</cfif>
						<cfif len(trim(orderQuery.order_ship_tracking_id))> (Tracking ID: #trim(orderQuery.order_ship_tracking_id)#)</cfif>
						</p>
						</cfoutput>
						</td>
					</cfif>
				</tr>
			</tbody>
		</table>
		<!--- PRODUCTS TABLE --->
		<!--- products in order--->
		<table class="CWtable" id="CWcartProductsTable">
			<thead>
				<!--- table headers --->
				<tr class="headerRow">
					<th>Item</th>
					<th class="center">Qty.</th>
					<th>Price</th>
					<cfif request.cwpage.discountDisplayLineItem>
						<th class="CWleft">Discount</th>
					</cfif>
					<cfif request.cwpage.taxDisplayLineItem>
						<th class="CWleft">Subtotal</th>
						<th class="CWleft"><cfoutput>#application.cw.taxSystemLabel#</cfoutput></th>
					</cfif>
					<th class="center">Total</th>
				</tr>
			</thead>
			<tbody>
				<!--- OUTPUT PRODUCTS --->
				<cfset currentRow = 1>
				<cfoutput query="orderQuery">
					<!--- get image for item ( add to cart item info )--->
					<cfif attributes.show_images>
						<cfset itemImg = CWgetImage(product_id=orderQuery.product_ID,image_type=4,default_image=application.cw.appImageDefault)>
					<cfelse>
						<cfset itemImg = ''>
					</cfif>
					<!--- url for linked info --->
					<cfset itemUrl = '#request.cwpage.urlDetails#?product=#orderQuery.product_ID#'>
					<cfset rowClass = 'itemRow row-#currentRow#'>
					<!--- SHOW 1 ROW FOR EACH PRODUCT --->
					<tr class="#rowClass#">
						<!--- product name, image, options --->
						<td class="productCell">
							<!--- product image --->
							<cfif len(trim(itemImg))>
								<div class="CWcartImage">
									<cfif attributes.link_products>
										<a href="#itemUrl#" title="View Product">
											<img src="#itemImg#" alt="#orderQuery.product_name#">
										</a>
									<cfelse>
										<img src="#itemImg#" alt="#orderQuery.product_name#">
									</cfif>
								</div>
							</cfif>
							<!--- product name --->
							<div class="CWcartItemDetails">
								<span class="CWcartProdName">
												<cfif attributes.link_products>
												<a href="#itemUrl#" title="View Product" class="CWlink">#orderQuery.product_name#</a>
											<cfelse>
												#orderQuery.product_name#
												</cfif>
												<cfif attributes.show_sku>
													<span class="CWcartSkuName">(#orderQuery.sku_merchant_sku_id#)</span>
												</cfif>
											</span>
								<cfif attributes.show_options>
									<!--- QUERY: get sku options --->
									<cfset optionsQuery = CWquerySelectSkuOptions(product_id=orderQuery.product_id,sku_id=orderQuery.sku_id)>
									<!--- if the sku has options --->
									<cfif optionsQuery.recordCount>
										<cfloop query="optionsQuery">
											<div class="CWcartOption">
												<span class="CWcartOptionName">#optionsQuery.optiontype_name#:</span>
												<span class="CWcartOptionValue">#optionsQuery.option_name#</span>
											</div>
										</cfloop>
									</cfif>
									<!--- /end sku options --->
								</cfif>
								<!--- custom value --->
								<cfif orderQuery.sku_id neq orderQuery.ordersku_unique_id
									AND application.cw.appDisplayCartCustom and attributes.show_options>
									<cfset phraseID = listLast(orderQuery.ordersku_unique_id,'-')>
									<cfset phraseText = CWgetCustomInfo(phrase_ID=phraseID)>
									<cfset trimLength = 35>
									<cfif len(trim(phraseText))>
										<div class="CWcartOption">
											<cfif len(trim(orderQuery.product_custom_info_label))>
												<span class="CWcartCustomLabel">#orderQuery.product_custom_info_label#:</span>
											</cfif>
											<span class="CWcartCustomValue">#left(trim(phraseText),trimlength)#<cfif len(trim(phraseText)) gt trimlength>...</cfif></span>
										</div>
									</cfif>
								</cfif>
								<!--- /end custom value --->
							</div>
							<!--- /end cartitemdetails --->
						</td>
						<!--- qty --->
						<td class="center">
							#orderQuery.ordersku_quantity#
						</td>
						<!--- price --->
						<td class="priceCell">
							<span class="CWcartPrice">#lsCurrencyFormat(orderQuery.ordersku_unit_price,'local')#</span>
						</td>
						<!--- discounts --->
						<cfif request.cwpage.discountDisplayLineItem>
						<td class="priceCell">
							<span class="CWcartPrice">#lsCurrencyFormat(orderQuery.ordersku_discount_amount,'local')#</span>
						</td>
						</cfif>
						<!--- taxes (subtotal before tax, and the tax amount) --->
						<cfif request.cwpage.taxDisplayLineItem>
						<!--- item subtotal --->
						<td class="priceCell">#lsCurrencyFormat(orderQuery.ordersku_unit_price*orderQuery.ordersku_quantity,'local')#</td>
						<!--- item tax --->
						<td class="priceCell">#lsCurrencyFormat(orderQuery.ordersku_tax_rate,'local')#</td>
						</cfif>
						<!--- total --->
						<td class="totalCell center">
							<span class="CWcartPrice">#lsCurrencyFormat(orderQuery.ordersku_sku_total,'local')#</span>
						</td>
					</tr>
					<!--- clear values, increment counter --->
					<cfset itemImg = ''>
					<cfset itemUrl = ''>
				</cfoutput>
				<!--- totals row --->
				<cfif attributes.show_total_row or attributes.show_discount_descriptions>
					<tr class="totalRow">
						<!--- order comments --->
						<td>
							<cfif len(trim(orderQuery.order_comments))>
								Order Comments:
								<br>
								<cfoutput>
									#trim(orderQuery.order_comments)#
								</cfoutput>
							</cfif>

								<!--- applied discount descriptions --->
								<cfif attributes.show_discount_descriptions>
									<!--- reset description list --->
									<cfset request.cwpage.discountDescriptions = ''>
									<!--- QUERY: get discounts applied to this order --->
									<cfset orderDiscounts = CWgetOrderDiscounts(orderQuery.order_id)>
									<!--- output list of applied discounts --->
									<cfoutput query="orderDiscounts">
									<cfset discountDescription = ''>
									<cfsavecontent variable="discountDescription">
									#orderDiscounts.discount_usage_discount_name#<cfif len(trim(orderDiscounts.discount_usage_promocode))> (#orderDiscounts.discount_usage_promocode#)</cfif>
									<cfif len(trim(orderDiscounts.discount_usage_discount_description))><br><span class="CWdiscountDescription">#orderDiscounts.discount_usage_discount_description#</span></cfif>
									</cfsavecontent>
									<!--- if description exists, add it to a list --->
									<cfif len(trim(discountDescription))>
										<cfset request.cwpage.discountDescriptions = listAppend(request.cwpage.discountDescriptions,trim(discountDescription),'|')>
									</cfif>
									</cfoutput>
									<!--- if we have descriptions to show --->
									<cfif listLen(request.cwpage.discountDescriptions,'|')>
										<div class="CWcartDiscounts">
										<p class="CWdiscountHeader">Discounts applied to this order:</p>
											<cfloop list="#request.cwpage.discountDescriptions#" delimiters="|" index="i">
											<cfoutput><p>#i#</p></cfoutput>
											</cfloop>
										</div>
									</cfif>
								</cfif>
						</td>
						<!--- ORDER TOTALS --->
						<!--- text labels for totals --->
						<td colspan="<cfoutput>#request.cwpage.cartColumnCount - 2#</cfoutput>" class="CWright totalCell">
							<cfif attributes.show_total_row>
							<!--- item total, if showing discounts --->
							<cfif attributes.show_discount_total and orderQuery.order_discount_total gt 0>
							<span class="CWdiscountText label">Item Total: </span><br>
							<!--- discount --->
							<span class="CWdiscountText label">Discounts: </span><br>
							</cfif>
							<!--- cart subtotal label --->
							<span class="label">Subtotal: </span>
							<!--- tax label --->
							<cfif attributes.show_tax_total>
							<br><span class="label"><cfoutput>#application.cw.taxSystemLabel#:</cfoutput> </span>
							</cfif>
							<!--- shipping total labels --->
							<cfif application.cw.shipEnabled AND attributes.show_ship_total>
								<cfif orderQuery.order_shipping gt 0>
									<br><span class="label">Shipping/Handling: </span>
								</cfif>
								<!--- shipping discounts --->
								<cfif application.cw.discountsEnabled and orderQuery.order_ship_discount_total gt 0 AND attributes.show_discount_total>
									<br><span class="CWdiscountText label">Shipping Discounts: </span>
									<br><span class="label CWsubtotalText">Shipping Total: </span>
								</cfif>
								<!--- shipping tax --->
								<cfif orderQuery.order_shipping_tax gt 0 and application.cw.taxChargeOnShipping>
									<br><cfoutput><span class="label">Shipping #application.cw.taxSystemLabel#: </span></cfoutput>
								</cfif>
							</cfif>
							<cfif attributes.show_order_total>
							<br><span class="label CWsubtotalText">Order Total: </span>
							</cfif>
							<!--- payment total --->
							<cfif attributes.show_payment_total>
								<cfif lsCurrencyFormat(orderPayments,'local') eq lsCurrencyFormat(orderQuery.order_total,'local')>
									<br>
									<cfoutput><span class="label">#request.cwpage.zeroBalanceMessage#</span></cfoutput>
								<cfelseif orderPayments gt 0>
									<br><span class="label CWsubtotalText">Payments: </span>
									<br><span class="label CWsubtotalText">Balance Due: </span>
								</cfif>
							</cfif>
							</cfif>
						</td>
						<!--- total amounts --->
						<td class="totalCell totalAmounts">
							<cfoutput>
							<cfif attributes.show_total_row>
							<!--- item total, if showing discounts --->
							<cfif attributes.show_discount_total and orderQuery.order_discount_total gt 0>
							<span class="CWtotalText CWsubtotalText">#lsCurrencyFormat(orderQuery.order_subtotal+orderQuery.order_discount_total,'local')# </span><br>
							<!--- discount --->
							<span class="CWdiscountText CWtotalText">-#lsCurrencyFormat(orderQuery.order_discount_total,'local')# </span><br>
							</cfif>
							<!--- subtotal --->
							<span class="CWtotalText CWsubtotalText">#lsCurrencyFormat(orderQuery.order_subtotal,'local')# </span>
							<!--- tax total --->
							<cfif attributes.show_tax_total>
							<br><span class="CWtotalText">#lsCurrencyFormat(orderQuery.order_tax,'local')# </span>
							</cfif>
							<!--- if shipping is selected, shipping total --->
							<cfif application.cw.shipEnabled>
								<cfif attributes.show_ship_total>
									<cfif orderQuery.order_shipping gt 0>
										<br><span class="CWtotalText">#lsCurrencyFormat(orderQuery.order_shipping + orderQuery.order_ship_discount_total,'local')# </span>
									</cfif>
									<!--- shipping discounts --->
									<cfif application.cw.discountsEnabled and orderQuery.order_ship_discount_total gt 0 AND attributes.show_discount_total>
										<br><span class="CWdiscountText CWtotaltext">-#lsCurrencyFormat(orderQuery.order_ship_discount_total,'local')# </span>
										<br><span class="CWtotalText CWsubtotalText">#lsCurrencyFormat(orderQuery.order_shipping,'local')# </span>
									</cfif>
									<!--- shipping tax --->
									<cfif orderQuery.order_shipping_tax gt 0 and application.cw.taxChargeOnShipping>
										<br><span class="CWtotalText">#lsCurrencyFormat(orderQuery.order_shipping_tax,'local')# </span>
									</cfif>
								</cfif>
							</cfif>
							<!--- complete order total (payment due amount) --->
							<cfif attributes.show_order_total>
								<br><span class="CWtotalText CWsubtotalText">#lsCurrencyFormat(orderQuery.order_total,'local')# </span>
							</cfif>
							<!--- payment total --->
							<cfif orderPayments gt 0 AND attributes.show_payment_total
							AND NOT (lsCurrencyFormat(orderPayments,'local') eq lsCurrencyFormat(orderQuery.order_total,'local'))>
								<cfset orderBalance = orderQuery.order_total - orderPayments>
								<br><span class="CWtotalText CWsubtotalText">#lsCurrencyFormat(orderPayments,'local')# </span>
								<br><span class="CWtotalText CWsubtotalText">#lsCurrencyFormat(orderBalance,'local')# </span>
							</cfif>
						</cfif>
						</cfoutput>
						</td>
					</tr>
				</cfif>
				<!--- /end totals row --->
			</tbody>
		</table>
		<!--- /end products table --->
	</cfif>
	<!--- /END Display Mode --->
<!--- IF ORDER NOT VALID --->
<cfelse>
	<p>Invalid Order : Details Unavailable</p>
</cfif>