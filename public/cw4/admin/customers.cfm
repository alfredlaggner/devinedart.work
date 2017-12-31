<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: customers.cfm
File Date: 2012-02-16
Description: Displays customer management table
==========================================================
--->
<!--- GLOBAL INCLUDES --->
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("any")>
<!--- PAGE PARAMS --->
<cfparam name="application.cw.adminRecordsPerPage" default="30">
<!--- default values for paging/sorting--->
<cfparam name="url.pagenumresults" type="numeric" default="1">
<cfparam name="url.maxrows" type="numeric" default="#application.cw.adminRecordsPerPage#">
<cfparam name="url.sortby" type="string" default="customer_last_name">
<cfparam name="url.sortdir" type="string" default="asc">
<!--- default search values --->
<cfparam name="url.custname" type="string" default="">
<cfparam name="url.custid" type="string" default="">
<cfparam name="url.custemail" type="string" default="">
<cfparam name="url.custaddr" type="string" default="">
<cfparam name="url.orderstr" type="string" default="">
<!--- BASE URL --->
<!--- create the base url for sorting out of serialized url variables--->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,pagenumresults,userconfirm,useralert")>
<!--- set up the base url --->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Manage Customers">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Customer Management">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = "Use the search options and table links to view and manage customer info">
<!--- current menu marker --->
<cfset request.cwpage.currentNav = request.cw.thisPage>
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
							<!--- Order Search Form : Contains Customers QUERY --->
							<cfinclude template="cwadminapp/inc/cw-inc-search-customer.cfm">
							<!--- if customers found, show the paging links --->
							<cfif customersQuery.recordCount gt 0>
								<cfoutput>#request.cwpage.pagingLinks#</cfoutput>
								<!--- set up the table display output --->
								<cfparam name="application.cw.adminCustomerPaging" default="1">
								<cfif NOT application.cw.adminCustomerPaging>
									<cfset startRow_Results = 1>
									<cfset maxRows_Results = customersQuery.recordCount>
								</cfif>
								<!--- make the query sortable --->
								<cfset customersQuery = CWsortableQuery(customersQuery)>
							</cfif>
						</div>
						<!--- /END SEARCH --->
						<!--- CUSTOMERS TABLE --->
						<!--- if no records found, show message --->
						<cfif NOT customersQuery.recordCount>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p><strong>No customers found.</strong> <br><br>Try a different search above or click the 'Manage Customers' link to see all customers.</p>
						<cfelse>
							<!--- if we have some records to show --->
							<table class="CWsort CWstripe" summary="<cfoutput>#request.cwpage.baseUrl#</cfoutput>">
								<thead>
								<tr class="sortRow">
									<th class="noSort" width="50">View</th>
									<th class="customer_last_name">Last</th>
									<th class="customer_first_name">First</th>
									<th class="customer_zip">Address (Post Code)</th>
									<th class="customer_email">Email</th>
									<th class="customer_phone">Phone</th>
									<th class="customer_guest">Guest</th>
									<th width="85" class="order_date">Last Order</th>
									<th width="35" class="order_total">Amount</th>
									<th width="55" class="total_spending">Total</th>
								</tr>
								</thead>
								<tbody>
								<!--- OUTPUT CUSTOMERS --->
								<cfoutput query="customersQuery" startrow="#StartRow_Results#" maxrows="#MaxRows_Results#" group="customer_id">
								<!--- set up location  --->
								<cfset customer_location = customer_address1 & ', ' & customer_city & ', ' & stateprov_name & ' ' & customer_zip>
								<!--- output the row --->
								<tr>
									<!--- details link --->
									<td style="text-align:center;"><a href="customer-details.cfm?customer_id=#customer_id#" title="View Customer Details"><img src="img/cw-edit.gif" width="15" height="15" alt="View Customer Details"></a></td>
									<!--- last name --->
									<td><strong><a class="productLink" href="customer-details.cfm?customer_id=#customersQuery.customer_id#">#customersQuery.customer_last_name#</a></strong></td>
									<!--- first name --->
									<td><strong><a class="productLink" href="customer-details.cfm?customer_id=#customersQuery.customer_id#">#customersQuery.customer_first_name#</a></strong></td>
									<!--- address --->
									<td>#customer_location#</td>
									<!--- email --->
									<td><cfif isValid('email',customer_email)>#customer_email#</cfif></td>
									<!--- phone --->
									<td>#customer_phone#</td>
									<!--- guest --->
									<td><cfif customer_guest is 1>Yes<cfelse>No</cfif></td>
									<!--- order date --->
									<cfif isDefined('customersQuery.top_order_date') and isDate(customersQuery.top_order_date)>
										<!--- if searching by order, we have this info already above --->
										<cfset customer_date = customersQuery.top_order_date >
									<cfelse>
										<!--- QUERY: get customer's last order via simple query (customer id, no. of rows to return) --->
										<cfset lastOrderQuery = CWquerySelectCustomerOrders(customersQuery.customer_id,1)>
										<cfset customer_date = lastOrderQuery.order_date >
									</cfif>
									<td style="white-space: nowrap;">#LSdateFormat(customer_Date,application.cw.globalDateMask)#</td>
									<!--- order total --->
									<td>
										<cfif isDefined('customersQuery.top_order_date') and isDate(customersQuery.top_order_date)>
											#lsCurrencyFormat(customersQuery.order_total)#
										</cfif>
									</td>
									<!--- total spending --->
									<td>
										<cfif isDefined('customersQuery.top_order_date') and isDate(customersQuery.top_order_date)>
											#lsCurrencyFormat(customersQuery.total_spending)#
										</cfif>
									</td>
								</tr>
								</cfoutput>
								<!--- /END OUTPUT CUSTOMERS --->
								</tbody>
							</table>






							<!--- footer links --->
							<div class="tableFooter"><cfoutput>#request.cwpage.pagingLinks#</cfoutput></div>
						</cfif>
					</div>
					<!-- /end Page Content -->
					<div class="clear"></div>
				</div>
				<!-- /end CWinner -->
			</div>
			<!--- page end content / debug --->
			<cfinclude template="cwadminapp/inc/cw-inc-admin-page-end.cfm">
			<!-- /end CWadminPage-->
			<div class="clear"></div>
		</div>
		<!-- /end CWadminWrapper -->
	</body>
</html>