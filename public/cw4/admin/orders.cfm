<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: orders.cfm
File Date: 2012-02-01
Description: Displays order management table
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
<!--- default values for seach/sort--->
<cfparam name="url.pagenumresults" type="integer" default="1">
<cfparam name="url.status" type="integer" default="0">
<cfparam name="url.orderstr" type="string" default="">
<cfparam name="url.custname" type="string" default="">
<cfparam name="url.maxrows" type="numeric" default="#application.cw.adminRecordsPerPage#">
<cfparam name="url.sortby" type="string" default="order_date">
<cfparam name="url.sortdir" default="desc" type="string">
<!--- start/end dates --->
<cfparam name="url.startdate" type="string" default="#LSdateFormat(DateAdd('m',-3,CWtime()),application.cw.globalDateMask)#">
<cfif isDate(url.startdate)>
	<cfparam name="url.enddate" type="string" default="#LSdateFormat(CWtime(),application.cw.globalDateMask)#">
<cfelse>
	<cfparam name="url.enddate" type="string" default="">
</cfif>
<!--- default value for order type label--->
<cfparam name="request.cwpage.orderType" default="All">
<!--- starting value for order total row --->
<cfset request.cwpage.orderTotal = 0>
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,pagenumresults,userconfirm,useralert,status")>
<!--- create the base url for sorting out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- get current page status if defined --->
<cfif url.status gt 0>
	<!--- QUERY: get order status to show --->
	<cfset getStatus = CWquerySelectOrderStatus(url.status)>
	<cfset request.cwpage.orderType = getStatus.shipstatus_name>
<cfelseif isDefined('form.status') and form.status gt 0>
	<cfset getStatus = CWquerySelectOrderStatus(form.status)>
	<cfset request.cwpage.orderType = getStatus.shipstatus_name>
</cfif>
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Manage Orders">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Order Management: #request.cwpage.orderType# Orders">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = "Use the search options and table links to view and manage orders">
<!--- current menu marker --->
<cfset request.cwpage.currentNav = request.cw.thisPage>
<cfif url.status gt 0>
	<cfset request.cwpage.currentNav = request.cw.thisPage & "?status=#url.status#">
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
	</head>
	<!--- body gets a class to match the filename --->
	<body <cfoutput> class="#listFirst(request.cw.thisPage, '.')#"</cfoutput>>
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
						<div id="CWadminOrderSearch" class="CWadminControlWrap">
							<!--- Order Search Form --->
							<cfif NOT isDate(url.startdate) OR NOT isDate(url.enddate)>
								<!--- if dates are invalid, redirect --->
								<cfset CWpageMessage("alert","Invalid Date Range")>
								<cflocation url="#request.cw.thisPage#?useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
							<cfelse>
								<cfinclude template="cwadminapp/inc/cw-inc-search-order.cfm">
							</cfif>
							<!--- if orders found, show the paging links --->
							<cfif ordersQuery.recordCount gt 0>
								<cfoutput>#request.cwpage.pagingLinks#</cfoutput>
								<!--- set up the table display output --->
								<cfparam name="application.cw.adminOrderPaging" default="1">
								<cfif NOT application.cw.adminOrderPaging>
									<cfset startRow_Results = 1>
									<cfset maxRows_Results = ordersQuery.recordCount>
								</cfif>
								<!--- make the query sortable --->
								<cfset ordersQuery = CWsortableQuery(ordersQuery,'desc') >
							</cfif>
						</div>
						<!--- /END SEARCH --->
						<!--- ORDERS TABLE --->
						<!--- if no records found, show message --->
						<cfif NOT ordersQuery.recordCount>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p><strong>No orders found.</strong> <br><br>Try a different search above.</p>
						<cfelse>
							<!--- if we have some records to show --->
							<table class="CWsort CWstripe" summary="<cfoutput>#request.cwpage.baseUrl#</cfoutput>">
								<thead>
								<tr class="sortRow">
									<th class="noSort" width="50">View</th>
									<th width="85" class="order_date">Date</th>
									<th width="135" class="order_id">Order ID</th>
									<th class="customer_last_name">Customer</th>
									<th class="customer_zip">Ship To Address</th>
									<th width="75" class="order_total">Total</th>
									<th width="75" class="shipstatus_name">Status</th>
								</tr>
								</thead>
								<tbody>
								<!--- OUTPUT ORDERS --->
								<cfoutput query="ordersQuery" startrow="#StartRow_Results#" maxrows="#MaxRows_Results#">
								<!--- simple var for status --->
								<cfset status = ordersQuery.shipstatus_name>
								<cfset statusID = ordersQuery.order_status>
								<!--- set up location  --->
								<cfset order_location = order_address1 & ', ' & order_city & ', ' & order_state & ' ' & order_zip>
								<!--- tabulate running total --->
								<cfset request.cwpage.orderTotal = request.cwpage.orderTotal + ordersQuery.order_total>
								<!--- output the row --->
								<tr>
									<!--- details link --->
									<td style="text-align:center;"><a href="order-details.cfm?order_id=#order_id#" title="View Order Details"><img src="img/cw-edit.gif" width="15" height="15" alt="View Order Details"></a></td>
									<!--- date --->
									<td style="white-space: nowrap;"><strong>#LSdateFormat(order_date,application.cw.globalDateMask)#</strong></td>
									<!--- order id --->
									<cfif len(order_id) gt 18>
										<cfset showID = '...' & right(order_id,18)>
									<cfelse>
										<cfset showID = order_id>
									</cfif>
									<td style="text-align:left;"><strong><a class="productLink" href="order-details.cfm?order_id=#order_id#">#showID#</a></strong></td>
									<!--- customer name --->
									<td><a href="customer-details.cfm?customer_id=#customer_id#" class="columnLink">#customer_last_name#, #customer_first_name#</a></td>
									<!--- order location : remove blanks ( , , )--->
									<td>#replace(order_location,", ,","","all")#</td>
									<!--- order total --->
									<td style="text-align:right;">
										#lsCurrencyFormat(order_total)#
									</td>
									<!--- status --->
									<cfif statusID is 1>
										<cfset status = "<strong>#status#</strong>">
									</cfif>
									<td style="text-align:center;">#status#</td>
								</tr>
								</cfoutput>
								<!--- sum total row --->
								<tr class="dataRow">
									<th colspan="5" style="text-align:right;"><strong>Total</strong></th>
									<td style="text-align:right;"><strong><cfoutput>#lsCurrencyFormat(request.cwpage.orderTotal)#</cfoutput></strong></td>
									<td></td>
								</tr>
								<!--- /END OUTPUT ORDERS --->
								</tbody>
							</table>
							<!--- footer links --->
							<div class="tableFooter"><cfoutput>#request.cwpage.pagingLinks#</cfoutput></div>
						</cfif>
						<!--- /END if records found --->
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