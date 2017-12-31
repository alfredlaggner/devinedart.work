<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: customer-details.cfm
File Date:2012-09-12
Description: Displays customer details and options
==========================================================
--->
<!--- GLOBAL INCLUDES --->
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("any")>
<!--- PAGE PARAMS --->
<cfparam name="application.cw.adminRecordsPerPage" default="30">
<!--- default search values --->
<cfparam name="url.custname" type="string" default="">
<cfparam name="url.custid" type="string" default="">
<cfparam name="url.custemail" type="string" default="">
<cfparam name="url.custaddr" type="string" default="">
<cfparam name="url.orderstr" type="string" default="">
<!--- define showtab to set up default tab display --->
<cfparam name="url.showtab" type="numeric" default="1">
<!--- default values for paging/sorting include--->
<cfparam name="url.pagenumresults" type="numeric" default="1">
<cfparam name="url.maxrows" type="numeric" default="#application.cw.adminRecordsPerPage#">
<cfparam name="url.sortby" type="string"default="custName">
<cfparam name="url.sortdir" type="string"default="asc">
<!--- this customer_id var is used for current page lookup - different from search var --->
<cfparam name="url.customer_id" type="string" default="0">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("view,userconfirm,useralert,sortby,sortdir")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- QUERY: get details on customer based on url (customer id)--->
<cfset customerQuery = CWquerySelectCustomerDetails(url.customer_id)>
<!--- QUERY: get users's order details (customer id,number of orders to return --->
<cfset ordersQuery = CWquerySelectCustomerOrderDetails(url.customer_id,50)>
<!--- QUERY: get user's shipping info (customer id)--->
<cfset shippingQuery = CWquerySelectCustomerShipping(url.customer_id)>
<!--- if we do not have a customer ID, add new --->
<!--- QUERY: get all states / countries --->
<cfset statesQuery = CWquerySelectStates()>
<!--- QUERY: get all customer types --->
<cfset typesQuery = CWquerySelectCustomerTypes()>
<!--- if we have a customer ID in the url, redirect to main page if no customer found --->
<cfif url.customer_id gt 0 and not customerQuery.recordCount>
	<cfset CWpageMessage("alert",'Customer #url.customer_id# not found')>
	<cflocation url="customers.cfm?useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
	<!--- if we did not have customer ID in the url, only allow higher levels here --->
<cfelseif url.customer_id is 0>
	<cfset request.cwpage.accessLevel = CWauth("manager,merchant,developer")>
</cfif>
<!--- starting value for order total row --->
<cfset request.cwpage.orderTotal = 0>
<!--- /////// --->
<!--- UPDATE CUSTOMER --->
<!--- /////// --->
<cfif IsDefined ('form.updateCustomer')>
	<!--- QUERY: update customer record (all customer form variables) --->
	<cfset updateCustomerID = CWqueryUpdateCustomer(
	url.customer_id,
	form.customer_type_id,
	form.customer_first_name,
	form.customer_last_name,
	form.customer_email,
	form.customer_username,
	form.customer_password,
	form.customer_company,
	form.customer_phone,
	form.customer_phone_mobile,
	form.customer_address1,
	form.customer_address2,
	form.customer_city,
	form.customer_billing_state,
	form.customer_zip,
	form.customer_ship_name,
	form.customer_ship_company,
	form.customer_ship_address1,
	form.customer_ship_address2,
	form.customer_ship_city,
	form.customer_ship_state,
	form.customer_ship_zip
	)>
	<!--- query checks for duplicate fields --->
	<cfif left(updateCustomerID,2) eq '0-'>
		<cfset dupField = listLast(updateCustomerID,'-')>
		<cfset CWpageMessage("alert","Error: #dupField# already exists")>
		<!--- update complete: return to page showing message --->
	<cfelse>
		<cfset CWpageMessage("confirm","Customer Updated")>
		<cflocation url="#request.cw.thisPage#?customer_id=#url.customer_id#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
	</cfif>
</cfif>
<!--- /////// --->
<!--- /END UPDATE CUSTOMER --->
<!--- /////// --->
<!--- /////// --->
<!--- ADD NEW CUSTOMER --->
<!--- /////// --->
<cfif IsDefined ('form.addCustomer')>
	<!--- QUERY: Add new customer (all customer form variables) --->
	<!--- this query returns the customer id, or an error like '0-fieldname' --->
	<cfset newCustomerID = CWqueryInsertCustomer(
	form.customer_type_id,
	form.customer_first_name,
	form.customer_last_name,
	form.customer_email,
	form.customer_username,
	form.customer_password,
	form.customer_company,
	form.customer_phone,
	form.customer_phone_mobile,
	form.customer_address1,
	form.customer_address2,
	form.customer_city,
	form.customer_billing_state,
	form.customer_zip,
	form.customer_ship_name,
	form.customer_ship_company,
	form.customer_ship_address1,
	form.customer_ship_address2,
	form.customer_ship_city,
	form.customer_ship_state,
	form.customer_ship_zip,
	application.cw.customerAccountEnabled
	)>
	<!--- if no error returned from insert query --->
	<cfif not left(newCustomerID,2) eq '0-'>
		<!--- update complete: return to page showing message --->
		<cfset CWpageMessage("confirm","Customer Added")>
		<cflocation url="#request.cw.thisPage#?customer_id=#newCustomerID#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
		<!--- if we have an insert error, show message, do not insert --->
	<cfelse>
		<cfset dupField = listLast(newCustomerID,'-')>
		<cfset CWpageMessage("alert","Error: #dupField# already exists")>
	</cfif>
	<!--- /END duplicate/error check --->
</cfif>
<!--- /////// --->
<!--- /END ADD NEW CUSTOMER --->
<!--- /////// --->
<!--- /////// --->
<!--- DELETE CUSTOMER --->
<!--- /////// --->
<cfif IsDefined ('url.deletecst')>
	<cfparam name="url.returnurl" type="string" default="customers.cfm?useralert=#CWurlSafe('Unable to delete: customer #url.deletecst# not found')#">
	<!--- QUERY: delete customer record (id from url)--->
	<cfset deleteCustomer = CWqueryDeleteCustomer(url.deletecst)>
	<cflocation url="#url.returnurl#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END DELETE CUSTOMER --->
<!--- /////// --->
<!--- Params for form fields below --->
<cfparam name="form.customer_type_id" default="#customerQuery.customer_type_id#">
<cfparam name="form.customer_first_name" default="#customerQuery.customer_first_name#">
<cfparam name="form.customer_last_name" default="#customerQuery.customer_last_name#">
<cfparam name="form.customer_email" default="#customerQuery.customer_email#">
<cfparam name="form.customer_username" default="#customerQuery.customer_username#">
<cfparam name="form.customer_password" default="#customerQuery.customer_password#">
<cfparam name="form.customer_company" default="#customerQuery.customer_company#">
<cfparam name="form.customer_phone" default="#customerQuery.customer_phone#">
<cfparam name="form.customer_phone_mobile" default="#customerQuery.customer_phone_mobile#">
<cfparam name="form.customer_address1" default="#customerQuery.customer_address1#">
<cfparam name="form.customer_address2" default="#customerQuery.customer_address2#">
<cfparam name="form.customer_city" default="#customerQuery.customer_city#">
<cfparam name="form.customer_billing_state" default="">
<cfparam name="form.customer_zip" default="#customerQuery.customer_zip#">
<cfparam name="form.customer_ship_name" default="#customerQuery.customer_ship_name#">
<cfparam name="form.customer_ship_company" default="#customerQuery.customer_ship_company#">
<cfparam name="form.customer_ship_address1" default="#customerQuery.customer_ship_address1#">
<cfparam name="form.customer_ship_address2" default="#customerQuery.customer_ship_address2#">
<cfparam name="form.customer_ship_city" default="#customerQuery.customer_ship_city#">
<cfparam name="form.customer_ship_state" default="">
<cfparam name="form.customer_ship_zip" default="#customerQuery.customer_ship_zip#">
<!--- set up heading --->
<cfsavecontent variable="request.cwpage.headtext">
<!--- if we are editing, show details --->
<cfoutput>
<cfif customerQuery.recordCount>
	Customer Details&nbsp;&nbsp;&nbsp;
	<span class='subhead'>#customerQuery.customer_first_name# #customerQuery.customer_last_name# (ID: #customerQuery.customer_id#)</span>
	<!--- if adding new, show simple heading --->
	<cfset request.cwpage.editmode = 'edit'>
<cfelse>
	Customer Management: Add New Customer
	<cfset request.cwpage.editmode = 'add'>
</cfif>
</cfoutput>
</cfsavecontent>
<!--- set up subheading --->
<cfsavecontent variable="request.cwpage.subhead">
<cfif len(trim(customerQuery.customer_phone))>Phone: <cfoutput>#customerQuery.customer_phone#</cfoutput>&nbsp;&nbsp;&nbsp;</cfif>
<cfif len(trim(customerQuery.customer_email))>Email: <cfoutput><cfif isValid('email',customerQuery.customer_email)><a href="mailto:#customerQuery.customer_email#"></cfif>#customerQuery.customer_email#<cfif isValid('email',customerQuery.customer_email)></a></cfif></cfoutput>&nbsp;&nbsp;&nbsp;</cfif>
<cfoutput query="ordersQuery" maxrows="1">
Orders: #ordersQuery.recordCount#&nbsp;&nbsp;&nbsp;
Last Order: #LSdateFormat(ordersQuery.order_date,application.cw.globalDateMask)# (#lsCurrencyFormat(ordersQuery.order_total)#)
</cfoutput>
</cfsavecontent>
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Customer Details">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = request.cwpage.headtext>
<!--- Page request.cwpage.subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = request.cwpage.subhead>
<!--- current menu marker --->
<cfif customerQuery.recordCount>
	<cfset request.cwpage.currentNav = "customers.cfm">
<cfelse>
	<cfset request.cwpage.currentNav = "customer-details.cfm">
</cfif>
<!--- load form scripts --->
<cfset request.cwpage.isFormPage = 1>
<!--- load table scripts --->
<cfset request.cwpage.isTablePage = 1>
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
		<!-- page javascript -->
		<script type="text/javascript">
		jQuery(document).ready(function(){
			// copy billing info to shipping
			jQuery('#copyInfo').click(function(){
			// if checking the box
			if (jQuery(this).prop('checked')==true){
				// get values of shipping
				var valName = jQuery('#customer_first_name').val() + ' ' + jQuery('#customer_last_name').val();
				var valCo = jQuery('#customer_company').val();
				var valAddr1 = jQuery('#customer_address1').val();
				var valAddr2 = jQuery('#customer_address2').val();
				var valCity = jQuery('#customer_city').val();
				var valState = jQuery('#customer_billing_state').val();
				var valZip = jQuery('#customer_zip').val();
				// add to billing
				jQuery('#customer_ship_name').val(valName);
				jQuery('#customer_ship_company').val(valCo);
				jQuery('#customer_ship_address1').val(valAddr1);
				jQuery('#customer_ship_address2').val(valAddr2);
				jQuery('#customer_ship_city').val(valCity);
				jQuery('#customer_ship_state').val(valState);
				jQuery('#customer_ship_zip').val(valZip);
			}
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
					<cfif len(trim(request.cwpage.heading1))><cfoutput><h1>#trim(request.cwpage.heading1)#</h1></cfoutput></cfif>
					<cfif len(trim(request.cwpage.heading2))><cfoutput><h2>#trim(request.cwpage.heading2)#</h2></cfoutput></cfif>
					<!-- Admin Alert - message shown to user -->
					<cfinclude template="cwadminapp/inc/cw-inc-admin-alerts.cfm">
					<!-- Page Content Area -->
					<div id="CWadminContent">
						<!-- //// PAGE CONTENT ////  -->
						<!--- SEARCH --->
						<div id="CWadminCustomerSearch" class="CWadminControlWrap">
							<!--- Order Search Form --->
							<cfinclude template="cwadminapp/inc/cw-inc-search-customer.cfm">
						</div>
						<!--- /END SEARCH --->
						<!--- /////// --->
						<!--- ADD/UPDATE CUSTOMER --->
						<!--- /////// --->
						<form name="CustomerDetails" method="post" action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" class="CWvalidate CWobserve">
							<!-- TABBED LAYOUT -->
							<div id="CWadminTabWrapper">
								<!-- TAB LINKS -->
								<ul class="CWtabList">
									<!--- tab 1 --->
									<li><a href="#tab1" title="Customer Info">Customer Info</a></li>
									<!--- tab 2 --->
									<cfif ordersQuery.recordCount>
										<li><a href="#tab2" title="Purchase History">Purchase History</a></li>
									</cfif>
								</ul>
								<div class="CWtabBox">
									<!--- FIRST TAB (status) --->
									<div id="tab1" class="tabDiv">
										<h3>Customer Details<cfif customerQuery.customer_guest is 1> *Guest Account</cfif></h3>
										<!--- customer details table --->
										<table class="CWformTable wide">
											<!--- split into billing/shipping --->
											<tr>
												<td class="customerInfo" id="contactCell" colspan="2">

												<!--- contact / login info --->
													<table class="CWformTable">
														<tr class="headerRow">
															<th colspan="2"><h3>Contact Details</h3></th>
														</tr>
														<tr>
															<th class="label">First Name</th>
															<td><input name="customer_first_name" class="{required:true}" title="First Name is required" size="17" type="text" id="customer_first_name" value="<cfoutput>#form.customer_first_name#</cfoutput>"></td>
														</tr>
														<tr>
															<th class="label">Last Name</th>
															<td><input name="customer_last_name" class="{required:true}" title="Last Name is required" size="17" type="text" id="customer_last_name" value="<cfoutput>#form.customer_last_name#</cfoutput>"></td>
														</tr>
														<tr>
															<th class="label">Email</th>
															<td><input type="text" class="{required:true,email:true}" title="Valid Email is required"  size="21" name="customer_email" id="customer_email" value="<cfoutput>#form.customer_email#</cfoutput>"></td>
														</tr>
														<tr>
															<th class="label">Phone</th>
															<td><input type="text" class="{required:true}" title="Phone Number is required" size="14" name="customer_phone" id="customer_phone" value="<cfoutput>#form.customer_phone#</cfoutput>"></td>
														</tr>
														<tr>
															<th class="label">Mobile</th>
															<td><input type="text" size="14" name="customer_phone_mobile" id="customer_phone_mobile" value="<cfoutput>#form.customer_phone_mobile#</cfoutput>"></td>
														</tr>
													</table>
													<!--- /end general info --->

													<!--- contact / billing --->
													<table class="CWformTable">
														<tr class="headerRow"><th colspan="2"><h3>Billing Information</h3></th></tr>

														<tr>
															<th class="label">Company</th>
															<td><input type="text" size="21" name="customer_company" id="customer_company" value="<cfoutput>#form.customer_company#</cfoutput>"></td>
														</tr>
														<tr>
															<th class="label">Address</th>
															<td>
																<input type="text" class="{required:true}" title="Billing Address is required"  name="customer_address1" id="customer_address1" value="<cfoutput>#form.customer_address1#</cfoutput>">
																<br>
																<br>
																<input type="text" name="customer_address2" id="customer_address2" value="<cfoutput>#form.customer_address2#</cfoutput>">
															</td>
														</tr>
														<tr>
															<th class="label">City</th>
															<td>
																<input type="text" name="customer_city" id="customer_city" class="{required:true}" title="Billing City is required" value="<cfoutput>#form.customer_city#</cfoutput>">
															</td>
														</tr>
														<tr>
															<th class="label">State/Prov</th>
															<td>
																<select name="customer_billing_state" id="customer_billing_state">
																	<cfoutput query="statesQuery" group="country_name">
																	<optgroup label="#country_name#">
																	<cfoutput><option value="#stateprov_id#"<cfif statesQuery.stateprov_id eq customerQuery.stateprov_id OR statesQuery.stateprov_id eq form.customer_billing_state> selected="selected"</cfif>>#stateprov_name#</option></cfoutput>
																	</optgroup>
																	</cfoutput>
																</select>
															</td>
														</tr>
														<tr>
															<th class="label">Post Code/Zip</th>
															<td>
																<input type="text" name="customer_zip" id="customer_zip" class="{required:true}" title="Billing Post Code is required" value="<cfoutput>#form.customer_zip#</cfoutput>" size="8">
															</td>
														</tr>
														<!--- only show country if a saved record exists --->
														<cfif customerQuery.recordCount>
															<tr>
																<th class="label">Country</th>
																<td>
																	<cfoutput>#customerQuery.country_name#</cfoutput>
																</td>
															</tr>
														</cfif>
													</table>
												</td>
												<!--- /END billing info --->
												<td class="customerInfo" id="shippingCell" colspan="2">
												<!--- general customer info --->
													<table class="CWformTable">
														<tr class="headerRow">
															<th colspan="2"><h3>Customer Account</h3></th>
														</tr>
														<!--- if we have more than one type, show the selector --->
														<cfif typesQuery.recordCount gt 1>
															<tr>
																<th class="label">Customer Type</th>
																<td>
																	<select name="customer_type_id" id="customer_type_id">
																		<cfoutput query="typesQuery">
																		<option value="#customer_type_id#"<cfif typesQuery.customer_type_id eq form.customer_type_id> selected="selected"</cfif>>#customer_type_name#</option>
																		</cfoutput>
																	</select>
																</td>
															</tr>
															<!--- if only one type exists, use this by default --->
														<cfelse>
															<input type="hidden" name="customer_type_id" id="customer_type_id" value="<cfoutput>#form.customer_type_id#</cfoutput>">
														</cfif>
														<!--- /end customer type --->
														<tr>
														<th class="label">Username<span class="smallPrint">(min. length 6)</span></th>
														<td><input name="customer_username" class="{required:true,minlength:6}" title="Username is required" size="17" type="text" id="customer_username" value="<cfoutput>#form.customer_username#</cfoutput>"></td>
														</tr>
														<tr>
														<th class="label">Password<span class="smallPrint">(min. length 6)</span></th>
														<td><input name="customer_password" class="{required:true,minlength:6}" title="Password is required" size="17" type="text" id="customer_password" value="<cfoutput>#form.customer_password#</cfoutput>"></td>
														</tr>
														<tr>
														<th class="label">Order Details</th>
														<td><cfif ordersQuery.recordCount><a href="orders.cfm?custName=<cfoutput>#url.customer_id#</cfoutput>&startDate=<cfoutput>#urlEncodedFormat(LSdateFormat('2000-01-01',application.cw.globalDateMask))#</cfoutput>">View Order History</a><cfelse>No Orders Placed</cfif></td>
														</tr>
													</table>

												<!--- Shipping info --->
													<table class="CWformTable">
														<tr class="headerRow">
															<th colspan="2">
																<h3>Shipping Information
																<span class="smallPrint"><input type="checkbox" id="copyInfo">&nbsp;Same as Billing</span>
																</h3>
															</th>
														</tr>
														<tr>
															<th class="label">Ship To (Name)</th>
															<td><input name="customer_ship_name" id="customer_ship_name" class="{required:true}" title="Ship To (name) is required" type="text" value="<cfoutput>#form.customer_ship_name#</cfoutput>"></td>
														</tr>
														<tr>
															<th class="label">Company</th>
															<td><input type="text" size="21" name="customer_ship_company" id="customer_ship_company" value="<cfoutput>#form.customer_ship_company#</cfoutput>"></td>
														</tr>
														<tr>
															<th class="label">Address</th>
															<td>
																<input type="text" name="customer_ship_address1" id="customer_ship_address1" class="{required:true}" title="Shipping Address is required" value="<cfoutput>#form.customer_ship_address1#</cfoutput>">
																<br>
																<br>
																<input type="text" name="customer_ship_address2" id="customer_ship_address2" value="<cfoutput>#form.customer_ship_address2#</cfoutput>">
															</td>
														</tr>
														<tr>
															<th class="label">City</th>
															<td><input type="text" name="customer_ship_city" id="customer_ship_city" class="{required:true}" title="Shipping City is required" value="<cfoutput>#form.customer_ship_city#</cfoutput>"></td>
														</tr>
														<tr>
															<th class="label">State/Prov</th>
															<td>
																<select name="customer_ship_state" id="customer_ship_state">
																	<cfoutput query="statesQuery" group="country_name">
																	<optgroup label="#country_name#">
																	<cfoutput><option value="#stateprov_id#"<cfif statesQuery.stateprov_id eq shippingQuery.stateprov_id OR statesQuery.stateprov_id eq form.customer_ship_state> selected="selected"</cfif>>#stateprov_name#</option></cfoutput>
																	</optgroup>
																	</cfoutput>
																</select>
															</td>
														</tr>
														<tr>
															<th class="label">Post Code/Zip</th>
															<td><input type="text" name="customer_ship_zip" id="customer_ship_zip" class="{required:true}" title="Shipping Post Code is required"value="<cfoutput>#form.customer_ship_zip#</cfoutput>" size="8"></td>
														</tr>
														<!--- only show country if a saved record exists --->
														<cfif customerQuery.recordCount>
															<tr>
																<th class="label">Country</th>
																<td>
																	<cfoutput>#shippingQuery.country_name#</cfoutput>
																</td>
															</tr>
														</cfif>
													</table>
													<!--- SUBMIT BUTTON --->
													<cfif customerQuery.recordCount>
														<input name="UpdateCustomer" type="submit" class="CWformButton" id="UpdateCustomer" value="Save Changes">
													<cfelse>
														<input name="AddCustomer" type="submit" class="CWformButton" id="AddCustomer" value="Save Customer">
													</cfif>
												</td>
												<!--- /END shipping info --->
											</tr>
											<!--- /END billing shipping --->
										</table>
									</div>
									<cfif ordersQuery.recordCount>
										<!--- SECOND TAB (details) --->
										<div id="tab2" class="tabDiv">
											<h3>Order Summary
											<span class="smallPrint"><a href="orders.cfm?custName=<cfoutput>#url.customer_id#</cfoutput>&startDate=<cfoutput>#urlEncodedFormat(LSdateFormat('2000-01-01',application.cw.globalDateMask))#</cfoutput>">View all orders for this customer</a></span>
											</h3>
											<table id="tblOrderDetails" class="wide CWinfoTable" style="width:735px;">
												<thead>
												<tr class="sortRow">
													<th class="noSort">View</th>
													<th class="order_id">Order ID</th>
													<th width="75" class="order_date">Date</th>
													<th class="noSort">Products</th>
													<th class="order_total">Total</th>
												</tr>
												</thead>
												<tbody>
												<cfoutput query="ordersQuery" group="order_id">
												<!--- tabulate running total --->
												<cfset request.cwpage.orderTotal = request.cwpage.orderTotal + ordersQuery.order_total>
												<tr>
													<td style="text-align:center">
														<a href="order-details.cfm?order_id=#ordersQuery.order_id#&amp;returnurl=#URLEncodedFormat(request.cwpage.baseUrl)#">
														<img src="img/cw-edit.gif" alt="View Order Details" width="15" height="15"></a>
													</td>
													<cfset order_id = ordersQuery.order_id>
													<td>
														<a href="order-details.cfm?order_id=#order_id#" class="productLink">
														<cfif len(order_id) gt 16>...</cfif>#right(order_id,  16)#
														</a>
													</td>
													<td style="text-align:right;">#LSdateFormat(ordersQuery.order_date,application.cw.globalDateMask)#</td>
													<td class="noLink">
														<!--- ungroup output --->
														<cfset lastOrderSku = ''>	
														<cfoutput>
															<cfif ordersQuery.ordersku_sku neq lastOrderSku>
																<cfset lastOrderSku = ordersQuery.ordersku_sku>
																<cfif request.cwpage.accessLevel eq 'service'>
																	<a href="#application.cw.appPageResultsUrl#?product=#ordersQuery.product_id#" class="columnLink">#ordersQuery.product_name#</a>
																<cfelse>
																	<a href="product-details.cfm?productid=#ordersQuery.product_id#" class="columnLink">#ordersQuery.product_name#</a>
																</cfif>
																<span class="smallprint">(#ordersQuery.sku_merchant_sku_id#)</span>
																<br>
															</cfif>	
														</cfoutput>
													</td>
													<td style="text-align:right;">#lsCurrencyFormat(ordersQuery.order_total)#</td>
												</tr>
												</cfoutput>
												<!--- sum total row --->
												<tr class="dataRow">
													<th colspan="4" style="text-align:right;"><strong>Total Spending</strong></th>
													<td style="text-align:right;"><strong><cfoutput>#lsCurrencyFormat(request.cwpage.orderTotal)#</cfoutput></strong></td>
												</tr>
												</tbody>
											</table>
										</div>
									</cfif>
									<!--- /END tab 2 --->
								</div>
								<!--- /END tab content --->
								<!--- delete button --->
								<cfif request.cwpage.editmode is 'edit'>
									<div class="CWformButtonWrap">
										<p>&nbsp;</p>
										<p>&nbsp;</p>
										<!--- If there are no orders show delete button --->
										<cfif ordersQuery.RecordCount eq 0>
											<cfoutput><a class="CWbuttonLink deleteButton" onclick="return confirm('Delete Customer #cwStringFormat(customerQuery.customer_first_name)# #cwStringFormat(customerQuery.customer_last_name)#?')" href="customer-details.cfm?deleteCst=#url.customer_id#&returnUrl=customers.cfm?userconfirm=Customer Deleted">Delete Customer</a></cfoutput>
										<cfelse>
											<p>(Orders placed, delete disabled)</p>
										</cfif>
									</div>
								</cfif>
							</div>
						</form>
						<!--- /////// --->
						<!--- END ADD/UPDATE CUSTOMER --->
						<!--- /////// --->
						<div class="clear"></div>
					</div>
					<!-- /end Page Content -->
				</div>
				<!-- /end CWinner -->
				<!--- page end content / debug --->
				<cfinclude template="cwadminapp/inc/cw-inc-admin-page-end.cfm">
				<!-- /end CWadminPage-->
				<div class="clear"></div>
			</div>
			<!-- /end CWadminPage -->
		</div>
		<!-- /end CWadminWrapper -->
	</body>
</html>