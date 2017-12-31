<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: order-details.cfm
File Date: 2012-11-17
Description: Displays order details and status options
==========================================================
--->
<!--- GLOBAL INCLUDES --->
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- include the mail functions --->
<!--- mail functions --->
<cfif not isDefined('variables.CWsendMail')>
	<cfinclude template="#request.cwpage.cwapppath#func/cw-func-mail.cfm">
</cfif>
<!--- avatax returns use the front end tax functions --->
<cfif application.cw.taxCalctype is 'avatax'>
	<cfinclude template="#request.cwpage.cwapppath#func/cw-func-tax.cfm">
</cfif>
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("any")>
<!--- SPECIAL STATUS CODES --->
<!--- shipping status (change this number if status options are altered) --->
<cfset request.cwpage.paidStatusCode = 3>
<cfset request.cwpage.shippedStatusCode = 4>
<cfset request.cwpage.cancelledStatusCode = 5>
<cfset request.cwpage.returnedStatusCode = 6>
<!--- PAGE PARAMS --->
<cfparam name="application.cw.adminRecordsPerPage" default="30">
<!--- default values for seach/sort--->
<cfparam name="url.pagenumresults" type="numeric" default="1">
<cfparam name="url.status" type="numeric" default="0">
<cfparam name="url.startdate" type="string" default="#LSdateFormat(DateAdd("m",-1,CWtime()),'yyyy-mm-dd')#">
<cfparam name="url.enddate" type="string" default="#LSdateFormat(CWtime(),'yyyy-mm-dd')#">
<cfparam name="url.orderstr" type="string" default="">
<cfparam name="url.custname" type="string" default="">
<cfparam name="url.maxrows" type="numeric" default="#application.cw.adminRecordsPerPage#">
<cfparam name="url.sortby" type="string" default="order_date">
<cfparam name="url.sortdir" type="string" default="asc">
<cfparam name="url.returnurl" type="string" default="orders.cfm">
<!--- define showtab to set up default tab display --->
<cfparam name="url.showtab" type="numeric" default="1">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("view,userconfirm,useralert,sortby,sortdir")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- Set local variable for storing display line item tax and discount preferences --->
<cfparam name="application.cw.taxDisplayLineItem" default="false">
<cfparam name="application.cw.taxSystemLabel" default="false">
<cfparam name="application.cw.discountDisplayLineItem" default="false">
<cfset taxDisplayLineItem = application.cw.taxDisplayLineItem>
<cfset discountDisplayLineItem = application.cw.discountDisplayLineItem>
<!--- /////// --->
<!--- DELETE ORDER --->
<!--- /////// --->
<cfif IsDefined ('url.deleteorder')>
	<!--- QUERY: delete order (order id) --->
	<cfset deleteOrder = CWqueryDeleteOrder(url.deleteorder)>
	<cflocation url="#url.returnurl#" addtoken="No">
</cfif>
<!--- /////// --->
<!--- /END DELETE ORDER --->
<!--- /////// --->
<!--- /////// --->
<!--- LOOKUP ORDER --->
<!--- /////// --->
<!--- make sure we have a valid order ID --->
<cfparam name="url.order_id" type="string" default="">
<!--- if not id specified, return to list page --->
<cfif not len(trim(url.order_id))>
	<cflocation url="orders.cfm" addtoken="no">
	<!--- if we do have an order, run queries --->
<cfelse>
	<!--- QUERY: check that order exists (order id) --->
	<cfset checkOrder = CWquerySelectOrder(url.order_id)>
	<!--- QUERY: get order and related details (order id) --->
	<cfset orderQuery = CWquerySelectOrderDetails(url.order_id)>
	<!--- if one order not found, redirect to list --->
	<cfif not checkorder.recordCount eq 1>
		<cfset CWpageMessage("alert","Order Not Found")>
		<cflocation url="orders.cfm?useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
		<!--- if one order is found --->
	<cfelse>
		<!--- if order details not found, i.e. no skus exist --->
		<cfif not orderQuery.recordCount>
			<cfset CWpageMessage("alert","Incomplete Order Data (ID: #url.order_id#)")>
		</cfif>
	</cfif>
	<!--- /end order check --->
	<!--- set up columns for display --->
	<cfif not orderQuery.order_discount_total gt 0>
		<cfset discountDisplayLineItem = false>
	</cfif>
	<cfset CartColumnCount = 0>
	<cfif taxDisplayLineItem>
		<cfset CartColumnCount = CartColumnCount + 2>
	</cfif>
	<cfif discountDisplayLineItem>
		<cfset CartColumnCount = CartColumnCount + 1>
	</cfif>
	<!--- order ID is ok in URL, run other queries --->
	<!--- QUERY: get all available shipping status options --->
	<cfset orderStatusQuery = CWquerySelectOrderStatus()>
	<!--- query of query - get sums from orderQuery --->
	<cfquery name="rsCWSums" dbtype="query">
	SELECT SUM(ordersku_discount_amount * ordersku_quantity) as TotalDiscount,
	SUM(ordersku_unit_price * ordersku_quantity) as SubTotal,
	SUM(sku_weight * ordersku_quantity) as OrderWeight,
	SUM(ordersku_tax_rate) as TotalTax 
	FROM orderQuery
	</cfquery>
	<!--- QUERY: get applied discounts --->
	<cfset discountsQuery = CWquerySelectOrderDiscounts(orderQuery.order_id)>
	<!--- set up discount list --->
	<cfset discountList = valueList(discountsQuery.discount_usage_discount_id)>
	<!--- set up descriptions content --->
		<!--- reset description list --->
		<cfset request.cwpage.discountdescriptions = ''>
	<cfif len(discountList)>
		<!--- loop list of applied discounts --->
		<cfloop list="#discountlist#" index="d">
		<!--- lookup description --->
		<cfset discountDescription = CWgetDiscountDescription(d)>
		<!--- add description to list --->
		<cfset request.cwpage.discountdescriptions = listAppend(request.cwpage.discountdescriptions,trim(discountDescription),'|')>
		</cfloop>
	</cfif>
	<!--- QUERY: get payments for this order --->
	<cfset paymentsQuery = CWorderPayments(url.order_id)>
</cfif>
<!--- /////// --->
<!--- /END LOOKUP ORDER --->
<!--- /////// --->
<!--- /////// --->
<!--- UPDATE ORDER --->
<!--- /////// --->
<cfif IsDefined ('form.update')>
	<!--- if set to 'shipped' or 'returned' and we don't have a date, show an error --->
	<cfif form.order_status eq request.cwpage.shippedStatusCode AND (NOT len(trim(form.order_ship_date)) OR NOT isDate(trim(form.order_ship_date)))>
		<cfset CWpageMessage("alert","Ship Date is Required")>
	<cfelseif form.order_status eq request.cwpage.returnedStatusCode AND (NOT len(trim(form.order_return_date)) OR NOT isDate(trim(form.order_return_date)))>
		<cfset CWpageMessage("alert","Return Date is Required")>
		<!--- if date is ok, update the order --->
	<cfelse>
		<!--- QUERY: update order details (order form variables) --->
		<cfset updateOrder = CWqueryUpdateOrder(
		form.orderID,
		form.order_status,
		order_ship_date,
		form.order_actual_ship_charge,
		form.order_ship_tracking_id,
		form.order_notes,
		form.order_return_date,
		form.order_return_amount
		)>
		<!--- set up confirmation message --->
		<cfset CWpageMessage("confirm","Order Updated")>
		<!--- if changing to status 'shipped', send email --->
		<cfif form.order_status eq request.cwpage.shippedStatusCode AND orderQuery.order_status neq request.cwpage.shippedStatusCode>
		<cfif not (isDefined('application.cw.mailSendPaymentCustomer') and application.cw.mailSendPaymentCustomer is false)>
			<!--- build the order details content --->
			<cfset mailBody = CWtextOrderDetails(form.orderID)>
			<cfsavecontent variable="mailContent">
			<cfoutput>#application.cw.mailDefaultOrderShippedIntro#

			#mailBody#

			#application.cw.mailDefaultOrderShippedEnd#
			</cfoutput>
			</cfsavecontent>
			<!--- send the content to the customer --->
			<cfset confirmationResponse = CWsendMail(mailContent, 'Order Shipment Notification',orderQuery.customer_email)>
			<!--- add the response to the page message --->
			<cfif confirmationResponse contains 'error'>
				<cfset CWpageMessage("alert","#confirmationresponse#")>
			<cfelse>
				<cfset CWpageMessage("confirm","Shipping Status Updated: #confirmationresponse#")>
			</cfif>
		</cfif>
		<!--- if changing to status paid in full, and using avatax, send order details --->
		<cfelseif form.order_status eq request.cwpage.paidStatusCode
				AND orderQuery.order_status lt request.cwpage.paidStatusCode
				AND application.cw.taxCalctype eq 'AvaTax'
				AND orderQuery.order_total gt 0>
				<cfset postTax = CWpostAvalaraTax(order_id=orderQuery.order_id)>
		<!--- if changing to status cancelled, and using avatax, send cancellation --->
		<cfelseif (form.order_status eq request.cwpage.cancelledStatusCode or form.order_status eq request.cwpage.returnedStatusCode)
				AND orderQuery.order_status gte request.cwpage.paidStatusCode
				AND application.cw.taxCalctype eq 'AvaTax'
				and orderQuery.order_total gt 0>
				<cfset refundTax = CWpostAvalaraTax(order_id=orderQuery.order_id,refund_order=true)>
		</cfif>
		<!--- update complete: return to page showing message --->
		<cflocation url="#request.cw.thisPage#?order_id=#url.order_id#&userconfirm=#cwurlsafe(request.cwpage.userConfirm)#" addtoken="no">
	</cfif>
</cfif>
<!--- /////// --->
<!--- /END UPDATE ORDER --->
<!--- /////// --->
<!--- set up subheading --->
<cfsavecontent variable="request.cwpage.subhead"><cfoutput>
Date/Time: #LSdateFormat(orderQuery.order_date,application.cw.globalDateMask)#&nbsp;#timeFormat(orderQuery.order_date,'short')#&nbsp;&nbsp;
Status: #orderQuery.shipstatus_name#&nbsp;&nbsp;&nbsp;
Total: #lsCurrencyFormat(orderQuery.order_total)#&nbsp;&nbsp;&nbsp;
SKUs: #orderQuery.recordCount#
</cfoutput></cfsavecontent>
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Order Details">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Order Details&nbsp;&nbsp;&nbsp;<span class='subHead'>ID: #orderQuery.order_id#&nbsp;&nbsp;&nbsp;</span>">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = request.cwpage.subhead>
<!--- current menu marker --->
<!--- if order has a known status, mark that status link in admin --->
<cfif orderQuery.order_status gt 0
	AND listFind(valueList(orderStatusQuery.shipstatus_id),orderQuery.order_status)>
	<cfset request.cwpage.currentNav = 'orders.cfm?status=#orderQuery.order_status#'>
<cfelse>
	<cfset request.cwpage.currentNav = 'orders.cfm'>
</cfif>
<!--- load form scripts --->
<cfset request.cwpage.isFormPage = 1>
<!--- load table scripts --->
<cfset request.cwpage.isTablePage = 1>
<!--- Set default form values for the form --->
<cfparam name="form.order_status" default="#orderquery.order_status#">
<cfparam name="form.order_ship_date" default="#orderquery.order_ship_date#">
<cfparam name="form.order_return_date" default="#orderquery.order_return_date#">
<cfparam name="form.order_return_amount" default="#orderquery.order_return_amount#">
<cfparam name="form.order_ship_tracking_id" default="#orderquery.order_ship_tracking_id#">
<cfparam name="form.order_notes" default="#orderquery.order_notes#">
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
		<!-- admin styles -->
		<link href="css/cw-layout.css" rel="stylesheet" type="text/css">
		<link href="theme/<cfoutput>#application.cw.adminThemeDirectory#</cfoutput>/cw-admin-theme.css" rel="stylesheet" type="text/css">
		<!-- admin javascript -->
		<cfinclude template="cwadminapp/inc/cw-inc-admin-scripts.cfm">
		<!--- PAGE JAVASCRIPT --->
		<script type="text/javascript">
		jQuery(document).ready(function(){
			// hide shipRow if status is not 'shipped' or higher
			if((jQuery('#order_status').find('option:selected').val() != <cfoutput>#request.cwpage.shippedStatusCode#</cfoutput>) && (jQuery('#order_ship_date').val() == '' )){
			jQuery('tr.shipRow').hide();
			};
			// hide returnRow if status is not 'returned' or higher
			if((jQuery('#order_status').find('option:selected').val() != <cfoutput>#request.cwpage.returnedStatusCode#</cfoutput>) && (jQuery('#order_return_date').val() == '' )){
			jQuery('tr.returnRow').hide();
			};
			// show/hide shipRow based on change of shipping value
			jQuery('#order_status').change(function(){
			 if (jQuery(this).find('option:selected').val() == <cfoutput>#request.cwpage.shippedStatusCode#</cfoutput>){
				jQuery('tr.returnRow').hide();
				jQuery('tr.shipRow').show();
			 } else if (jQuery(this).find('option:selected').val() == <cfoutput>#request.cwpage.returnedStatusCode#</cfoutput>){
				jQuery('tr.shipRow').hide();
				jQuery('tr.returnRow').show();
			 } else if(jQuery('#order_ship_date').val() == '' )  {
			jQuery('tr.shipRow').hide();
			 };
			});
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
					<cfif len(trim(request.cwpage.heading1))><cfoutput><h1>#trim(request.cwpage.heading1)# <span class="smallPrint"><a href="javascript:window.print()">Print Order</a></span></h1></cfoutput></cfif>
					<cfif len(trim(request.cwpage.heading2))><cfoutput><h2>#trim(request.cwpage.heading2)#</h2></cfoutput></cfif>
					<!-- Admin Alert - message shown to user -->
					<cfinclude template="cwadminapp/inc/cw-inc-admin-alerts.cfm">
					<!-- Page Content Area -->
					<div id="CWadminContent">
						<!-- //// PAGE CONTENT ////  -->
						<!--- SEARCH --->
						<div id="CWadminOrderSearch" class="CWadminControlWrap">
							<!--- Order Search Form --->
							<cfif NOT isDate(url.startdate) OR NOT isDate(url.enddate)>
								<!--- if dates are invalid, redirect --->
								<cfset CWpageMessage("alert","Invalid Date Range")>
								<cflocation url="#request.cw.thisPage#?useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
							<cfelse>
								<cfinclude template="cwadminapp/inc/cw-inc-search-order.cfm">
							</cfif>
						</div>
						<!--- /END SEARCH --->
						<!--- /////// --->
						<!--- UPDATE ORDER --->
						<!--- /////// --->
						<form name="OrderStatus" method="post" action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" class="CWvalidate CWobserve">
							<cfif orderquery.recordCount>
								<table class="wider CWinfoTable">
									<tr class="headerRow">
											<th style="width:50%">Order Details</th>
											<th>Shipping Information</th>
									</tr>
									<tr class="dataRow">
										<td class="padTop">
											<cfoutput>
												<p><strong>Order ID: #url.order_id#</strong></p>
												<p>Placed: #LSdateFormat(orderQuery.order_date,application.cw.globalDateMask)#&nbsp;#timeFormat(orderQuery.order_date,'short')#</p>
												<p>Sold To: <a href="customer-details.cfm?customer_id=#orderQuery.customer_id#">#orderQuery.customer_first_name# #orderQuery.customer_last_name#</a></p>
												<p>Email: #orderQuery.customer_email#</p>
												<p>Customer ID: #orderQuery.customer_id#</p>
											</cfoutput>
										</td>
										<td class="padTop">
											<cfoutput>
												<p><span class="infoLabel">Ship To: </span><cfif len(trim(orderQuery.order_ship_name))>#orderQuery.order_ship_name#,</p> </cfif>
												<cfif len(trim(orderQuery.order_company))><p>#orderQuery.order_company#,</p> </cfif>
												<p>#orderQuery.order_address1#,</p>
												<cfif orderQuery.order_address2 neq ""><p>#orderQuery.order_address2#</p></cfif>
												<p>#orderQuery.order_city#, #orderQuery.order_state# #orderQuery.order_zip#, #orderQuery.order_country#</p>
												<cfif orderQuery.order_ship_method_id neq 0><p>Ship Via #orderQuery.ship_method_name#</p></cfif>
											</cfoutput>
										</td>
									</tr>
								</table>
								<!-- TABBED LAYOUT -->
								<div id="CWadminTabWrapper">
									<!-- TAB LINKS -->
									<ul class="CWtabList">
										<!--- tab 1 --->
										<li><a href="#tab1" title="Order Status">Order Status</a></li>
										<!--- tab 2 --->
										<li><a href="#tab2" title="Order Contents">Order Contents</a></li>
										<!--- tab 3 --->
										<li><a href="#tab3" title="Payment Details">Payment Details</a></li>
									</ul>
									<!--- TAB CONTENT --->
									<div class="CWtabBox">
										<!--- FIRST TAB (status) --->
										<div id="tab1" class="tabDiv">
											<h3>Order Status</h3>
											<table class="CWformTable wide">
												<tr>
													<!--- Order Status --->
													<th class="label" style="width:180px">
														Status:
													</th>
													<td>
														<select name="order_status" id="order_status">
															<!--- If order status is NOT Shipped or Returned --->
															<cfif orderquery.order_status neq request.cwpage.shippedStatusCode AND
															orderquery.order_status neq request.cwpage.returnedStatusCode>
																<cfoutput query="orderStatusQuery">
																	<option value="#orderStatusQuery.shipstatus_id#"<cfif form.order_status eq orderStatusQuery.shipstatus_id > selected="selected"</cfif>>#orderStatusQuery.shipstatus_name#</option>
																</cfoutput>
															<cfelseif orderquery.order_status EQ request.cwpage.returnedStatusCode>
															<!--- if order is returned, no status changes allowed --->
																<option value="<cfoutput>#request.cwpage.returnedStatusCode#</cfoutput>">Returned</option>
															<cfelse>
																<!--- If order status is shipped  --->
																<option value="<cfoutput>#request.cwpage.shippedStatusCode#</cfoutput>" selected="selected">Shipped</option>
																<option value="<cfoutput>#request.cwpage.returnedStatusCode#</cfoutput>">Returned</option>
															</cfif>
														</select>
														<!--- save order details --->
														<cfif orderquery.order_status neq request.cwpage.cancelledStatusCode AND orderquery.order_status neq request.cwpage.returnedStatusCode>
															<input name="Update" type="submit" class="CWformButton" id="Update" value="Save Order">
														</cfif>
														<!--- view formatted order message contents --->
														&nbsp;&nbsp;<a class="smallPrint" href="order-email.cfm?order_id=<cfoutput>#url.order_id#</cfoutput>" rel="external">View Order Email</a>
														<!--- hidden field for order id --->
														<input name="orderID" type="hidden" value="<cfoutput>#orderquery.order_id#</cfoutput>">
													</td>
												</tr>
												<!--- Shipping method --->
												<tr class="dataRow">
													<th class="label">Shipping Method: </th>
													<td><p><cfoutput>#orderquery.ship_method_name#</cfoutput></p></td>
												</tr>
												<!--- Shipping weight --->
												<tr class="dataRow">
													<th class="label">Order Ship Weight: </th>
													<td><p><cfoutput>#rsCWSums.OrderWeight# #application.cw.shipWeightUOM#</cfoutput></p></td>
												</tr>
												<!--- 'tr.shipRow' is hidden for unshipped status types --->
												<!--- Ship date - required for status 'shipped'  --->
												<tr class="shipRow">
													<th class="label">
														Ship Date:
													</th>
													<td>
														<input name="order_ship_date" id="order_ship_date" class="date_input {required: function(){return (jQuery('select[name=order_status]').val() == '<cfoutput>#request.cwpage.shippedStatusCode#</cfoutput>')}}" title="Ship Date is required for the selected status" type="text" size="12" value="<cfoutput>#LSdateFormat(form.order_ship_date,request.cw.scriptDateMask)#</cfoutput>">
													</td>
												</tr>
												<tr class="shipRow">
													<th class="label">Tracking ID: </th>
													<td>
														<cfif orderquery.order_status neq request.cwpage.cancelledStatusCode>
															<input name="order_ship_tracking_id" type="text" id="order_ship_tracking_id" size="35" value="<cfoutput>#order_ship_tracking_id#</cfoutput>">
														<cfelse>
															<cfoutput>#order_ship_tracking_id#</cfoutput>
														</cfif>
													</td>
												</tr>
												<tr class="shipRow">
													<th class="label">Actual Shipping Cost: </th>
													<td>
														<input name="order_actual_ship_charge" size="8" type="text" value="<cfoutput>#orderquery.order_actual_ship_charge#</cfoutput>" onkeyup="extractNumeric(this,2,false)">
													</td>
												</tr>
												<tr class="returnRow">
													<th class="label">Return Date: </th>
													<td>
														<input name="order_return_date" id="order_return_date" class="date_input {required: function(){return (jQuery('select[name=order_status]').val() == '<cfoutput>#request.cwpage.returnedStatusCode#</cfoutput>')}}" title="Return Date is required for the selected status" type="text" size="12" value="<cfoutput>#LSdateFormat(form.order_return_date,request.cw.scriptDateMask)#</cfoutput>">
													</td>
												</tr>
												<tr class="returnRow">
													<th class="label">Return Amount: </th>
													<td>
														<input name="order_return_amount" size="8" type="text" value="<cfoutput>#orderquery.order_return_amount#</cfoutput>" onkeyup="extractNumeric(this,2,false)">
													</td>
												</tr>

												<cfif len(trim(orderquery.order_comments))>
													<tr>
														<th class="label">Order Comments: </th>
														<td><cfoutput>#orderquery.order_comments#</cfoutput></td>
													</tr>
												</cfif>
												<tr>
													<tr>
														<th class="label">Store Notes: </th>
														<td><textarea name="order_notes" cols="34" rows="10" id="order_notes"><cfoutput>#form.order_notes#</cfoutput></textarea></td>
													</tr>
												</tr>
											</table>
										</div>
										<!--- SECOND TAB (details) --->
										<div id="tab2" class="tabDiv">
											<h3>Order Contents</h3>
											<table id="tblOrderDetails" class="CWinfoTable wide">
												<tr class="headerRow">
													<th>Product Name</th>
													<th style="text-align:right;">Qty.</th>
													<th style="text-align:right;">Price</th>
													<cfif discountDisplayLineItem>
														<th style="text-align:right;">Discount</th>
													</cfif>
													<cfif taxDisplayLineItem>
														<th style="text-align:right;">Subtotal</th>
														<th style="text-align:right;"><cfoutput>#application.cw.taxSystemLabel#</cfoutput></th>
													</cfif>
													<th style="text-align:right;">Total</th>
												</tr>
												<cfset rowCount = 0>
												<cfoutput query="orderQuery" group="ordersku_unique_id">
												<!--- QUERY: get options for this order SKU (sku id) --->
												<cfset optionsQuery = CWquerySelectSkuOptions(orderQuery.ordersku_sku)>
												<cfset rowCount = IncrementValue(rowCount)>
												<tr class="dataRow">
													<td>
														<a href="product-details.cfm?productid=<cfoutput>#orderQuery.product_id#</cfoutput>" class="columnLink">#orderQuery.product_name#</a> (#orderQuery.sku_merchant_sku_id#)
														<!--- show SKU options --->
														<cfloop query="optionsQuery">
															<br>
															<strong style="margin-left: 10px;">#optiontype_name#</strong>: #option_name#
														</cfloop>
														<!--- show custom info --->
														<cfif len(trim(orderQuery.product_custom_info_label)) and orderQuery.ordersku_sku neq orderQuery.ordersku_unique_id>
														<br>
															<strong style="margin-left: 10px;">#orderQuery.product_custom_info_label#</strong>: #CWgetCustomInfo(listLast(orderQuery.ordersku_unique_id,'-'))#
														</cfif>
													</td>
													<td style="text-align:center;">#orderQuery.ordersku_quantity#</td>
													<td style="text-align:right;">#lsCurrencyFormat(val(orderQuery.ordersku_unit_price), 'local')#</td>
													<cfif discountDisplayLineItem>
														<td style="text-align:right;"><cfif val(orderQuery.ordersku_discount_amount) neq 0>#lsCurrencyFormat(val(orderQuery.ordersku_discount_amount) * val(orderQuery.ordersku_quantity),'local')#</cfif></td>
													</cfif>
													<cfif taxDisplayLineItem>
														<td style="text-align:right;">#lsCurrencyFormat((val(orderQuery.ordersku_unit_price)  - val(orderQuery.ordersku_discount_amount))* val(orderQuery.ordersku_quantity),'local')#</td>
														<td style="text-align:right;">#lsCurrencyFormat(val(orderQuery.ordersku_tax_rate),'local')#</td>
														<td style="text-align:right;">
															#lsCurrencyFormat(((val(orderQuery.ordersku_unit_price) - val(orderQuery.ordersku_discount_amount)) * val(orderQuery.ordersku_quantity) + val(orderQuery.ordersku_tax_rate)),'local')#
														</td>
													<cfelse>
														<td style="text-align:right;">#lsCurrencyFormat((val(orderQuery.ordersku_unit_price) - val(orderQuery.ordersku_discount_amount)) * val(orderQuery.ordersku_quantity),'local')#</td>
													</cfif>
												</tr>
												</cfoutput>
												<cfif rsCWSums.recordCount>
												<!--- subtotal row --->
													<tr class="dataRow totalRow subTotalRow">
														<th colspan="2" style="text-align:right;">Subtotal: </th>
														<td style="text-align:right;"><cfoutput>#lsCurrencyFormat(rsCWSums.SubTotal,'local')#</cfoutput></td>
														<cfif discountDisplayLineItem>
															<td style="text-align:right;"><cfif rsCWSums.TotalDiscount neq 0><em><cfoutput>-#lsCurrencyFormat(rsCWSums.TotalDiscount,'local')#</cfoutput></em></cfif></td>
														</cfif>
														<cfif taxDisplayLineItem>
															<td style="text-align:right;"><cfoutput>#lsCurrencyFormat(rsCWSums.SubTotal - rsCWSums.TotalDiscount,'local')#</cfoutput></td>
															<td style="text-align:right;"><cfoutput>#lsCurrencyFormat(rsCWSums.TotalTax,'local')#</cfoutput></td>
															<td style="text-align:right;"><cfoutput>#lsCurrencyFormat(rsCWSums.SubTotal + rsCWSums.TotalTax - rsCWSums.TotalDiscount,'local')#</cfoutput></td>
														<cfelse>
															<td style="text-align:right;"><cfoutput>#lsCurrencyFormat(rsCWSums.SubTotal,'local')#</cfoutput></td>
														</cfif>
													</tr>
													<!--- global cart discounts --->
													<cfif orderQuery.order_discount_total gt 0 and orderQuery.order_discount_total gt rsCWsums.totalDiscount>
														<tr class="dataRow totalRow">
															<th colspan="2" style="text-align:right;">Additional Discounts: </th>
															<td style="text-align:right;">-<cfoutput>#lsCurrencyFormat(orderQuery.order_discount_total - rsCWsums.totalDiscount)#</cfoutput></td>
															<cfif discountDisplayLineItem>
																<td style="text-align:right;"><cfif rsCWSums.TotalDiscount neq 0><em>- <cfoutput>#lsCurrencyFormat(val(orderQuery.order_discount_total-rsCWsums.totalDiscount))#</cfoutput></em></cfif></td>
															</cfif>
															<cfif taxDisplayLineItem>
																<td style="text-align:right;"><cfif not discountDisplayLineItem><em>- <cfoutput>#lsCurrencyFormat(val(orderQuery.order_discount_total-rsCWsums.totalDiscount))#</cfoutput></em></cfif></td>
																<td style="text-align:right;">&nbsp;</td>
																<td style="text-align:right;"><cfoutput>#lsCurrencyFormat(rsCWSums.SubTotal + rsCWSums.TotalTax - orderQuery.order_discount_total,'local')#</cfoutput></td>
															<cfelse>
																<td style="text-align:right;"><cfoutput>#lsCurrencyFormat(orderQuery.order_total-(orderQuery.order_shipping+orderQuery.order_tax),'local')#</cfoutput></td>
															</cfif>
														</tr>
													</cfif>
												</cfif>

												<cfif orderQuery.order_ship_method_id neq 0>
													<tr class="dataRow totalRow">
														<th colspan="2" style="text-align:right;" valign="top"> Ship By: <cfoutput>#orderQuery.ship_method_name#</cfoutput></th>
														<td style="text-align:right;"><cfoutput>#lsCurrencyFormat(orderQuery.order_shipping + orderQuery.order_ship_discount_total,'local')#</cfoutput></td>
														<!--- If showing line item discounts, show shipping discount in cell --->
														<cfif discountDisplayLineItem>
															<td style="text-align:right;" valign="top">&nbsp;<cfif orderQuery.order_ship_discount_total neq 0><em>- <cfoutput>#lsCurrencyFormat(val(orderQuery.order_ship_discount_total),'local')#</cfoutput></em></cfif></td>
														</cfif>
														<!--- If showing line item discounts, show shipping taxes and subtotals in cells --->
														<cfif taxDisplayLineItem>
															<td style="text-align:right;" valign="top">
																<cfoutput>#lsCurrencyFormat(val(orderQuery.order_shipping),'local')#</cfoutput>
															</td>
															<td style="text-align:right;" valign="top"><cfoutput>#lsCurrencyFormat(val(orderQuery.order_shipping_tax),'local')#</cfoutput></td>
															<td style="text-align:right;" valign="top"><cfoutput>#lsCurrencyFormat(val(orderQuery.order_shipping_tax) + val(orderQuery.order_shipping),'local')#</cfoutput></td>
														<cfelse>
															<td style="text-align:right;" valign="top">
																<cfoutput>#lsCurrencyFormat(val(orderQuery.order_shipping),'local')#</cfoutput>
															</td>
														</cfif>
													</tr>
												</cfif>
												<cfif NOT taxDisplayLineItem>
													<tr class="dataRow totalRow">
														<th colspan="<cfoutput>#CartColumnCount + 3#</cfoutput>" style="text-align:right;"><cfoutput>#application.cw.taxSystemLabel#</cfoutput>: </th>
														<td style="text-align:right;"><cfoutput>#lsCurrencyFormat(val(orderQuery.order_tax))#</cfoutput></td>
													</tr>
												</cfif>
												<!--- Display ORDER TOTAL --->
												<tr class="dataRow totalRow">
													<th colspan="<cfoutput>#CartColumnCount + 3#</cfoutput>" style="text-align:right;">Order Total: </th>
													<td style="text-align:right;"><strong><cfoutput>#lsCurrencyFormat(val(orderQuery.order_total))#</cfoutput></strong></td>
												</tr>
												<!--- DISCOUNT DETAILS --->
												<cfif isdefined("discountsQuery.RecordCount") And discountsQuery.RecordCount gt 0>
													<tr class="dataRow totalRow">
														<th colspan="2" style="text-align:right;">Applied Discounts</th>
														<td colspan="<cfoutput>#CartColumnCount + 2#</cfoutput>">
														<!--- APPLIED DISCOUNTS --->
														<cfif listLen(request.cwpage.discountdescriptions)>
															<div class="CWcartDiscounts">
															<p class="CWdiscountHeader">Discounts applied to this order:</p>
																<!--- loop descriptions, get ID for linking --->
																<cfset loopct = 1>
																<cfloop list="#request.cwpage.discountdescriptions#" delimiters="|" index="i">
																	<cfset linkid = listGetAt(discountlist, loopct)>
																	<!--- remove line breaks, show on one line --->
																	<cfset discText = replace(i,'<br>',': ','all')>
																	<cfif left(discText,1) is not ':'>
																		<cfif linkid gt 0>
																			<cfoutput><p><a href="discount-details.cfm?discount_id=#linkid#">#discText#</a></p></cfoutput>
																		<cfelse>
																			<cfoutput><p>#discText#</p></cfoutput>
																		</cfif>
																	<cfset loopct = loopct + 1>
																	</cfif>
																</cfloop>
															</div>
														</cfif>														
														</td>
													</tr>
												</cfif>
											</table>
										</div>
										<!--- THIRD TAB (Payment Details) --->
										<div id="tab3" class="tabDiv">
											<h3>Payment Details</h3>
											<!--- if we have some payments --->
											<cfif paymentsQuery.recordCount gt 0>
											<table id="tblOrderPayments" class="CWinfoTable wide">
												<tr class="headerRow">
													<th>Date/Time</th>
													<th>Amount</th>
													<th>Payment Method</th>
													<th>Type</th>
													<th>Status</th>
													<th>Transaction ID</th>
												</tr>
												<!--- output payment data --->
												<cfoutput query="paymentsQuery">
												<tr class="dataRow">
													<td>
													<span class="dateStamp">
														#LSdateFormat(payment_timestamp,application.cw.globalDateMask)#
														&nbsp;&nbsp;#timeFormat(payment_timestamp,'short')#
													</span>
													</td>
													<td>#lsCurrencyFormat(payment_amount)#</td>
													<td>#payment_method#</td>
													<td>#payment_type#</td>
													<td>#payment_status#</td>
													<td>#payment_trans_id#</td>
												</tr>
												<tr class="CWtransData">
													<td colspan="6">
													<p><strong>Transaction Data</strong></p>
													<textarea style="width:680px;height:110px;" readonly="readonly">#payment_trans_response#</textarea>
													</td>
												</tr>
												</cfoutput>
											</table>
											<!--- if we don't have any payments --->
											<cfelse>
												<p>&nbsp;</p>
												<p>&nbsp;</p>
												<p>No payments have been applied to this order.</p>
											</cfif>
										</div>
										<!--- delete button --->
										<cfif orderQuery.order_status neq request.cwpage.shippedstatuscode AND orderQuery.order_status neq request.cwpage.returnedstatuscode>
										<div class="CWformButtonWrap">
											<p>&nbsp;</p>
											<p>&nbsp;</p>
											<a href="order-details.cfm?deleteOrder=<cfoutput>#url.order_id#</cfoutput>&returnUrl=orders.cfm?useralert=Order Deleted" onClick="return confirm('Delete Order ID <cfoutput>#url.order_id#</cfoutput>?')" class="CWbuttonLink deleteButton">Delete Order</a>
										</div>
										<div class="clear"></div>
										</cfif>
									</div>
									<!--- /END tab content --->
									<!--- /////// --->
									<!--- /END UPDATE ORDER --->
									<!--- /////// --->
								</div>
								<!--- /END tab wrapper --->
							</cfif>
							<!--- /END if orderQuery.recordCount --->
						</form>
					</div>
					<!-- /end Page Content -->
					<div class="clear"></div>
				</div>
				<!-- /end CWinner -->
			</div>
			<!-- /end CWadminPage-->
			<!--- page end content / debug --->
			<cfinclude template="cwadminapp/inc/cw-inc-admin-page-end.cfm">
			<div class="clear"></div>
		</div>
		<!-- /end CWadminWrapper -->
	</body>
</html>