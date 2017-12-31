<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-widget-orders.cfm
File Date: 2012-02-01
Description:
Displays recent orders on admin home page
Uses the select orders query (order search) to return orders by date
==========================================================
--->
<cfset showCt = application.cw.adminWidgetOrders>
</cfsilent>
<cfif showCt gt 0>
	<!--- QUERY: get recent orders (status, datestart, dateend, IDstring, customer, maxorders) --->
	<cfset recentOrdersQuery = CWquerySelectOrders(0,0,0,'','',showCt)>
	<!--- start output --->
	<div class="CWadminHomeWidget">
		<h3>Recent Orders</h3>
		<!--- ORDERS TABLE --->
		<!--- if no records found, show message --->
		<cfif NOT recentOrdersQuery.recordCount>
			<p>&nbsp;</p>
			<p>&nbsp;</p>
			<p>&nbsp;</p>
			<p><strong>No orders found.</strong></p>
		<cfelse>
			<!--- if we have some records to show --->
			<table class="CWstripe CWwidgetTable">
				<thead>
				<tr>
					<th width="45" class="order_date">Date</th>
					<th width="80" class="order_id">Order ID</th>
					<th>Customer</th>
					<th width="60" class="order_total">Total</th>
					<th width="55" class="shipstatus_name">Status</th>
				</tr>
				</thead>
				<tbody>
				<!--- OUTPUT ORDERS --->
				<cfoutput query="recentOrdersQuery" group="order_id">
				<!--- simple var for status --->
				<cfset status = recentOrdersQuery.shipstatus_name>
				<cfset statusID = recentOrdersQuery.order_status>
				<!--- output the row --->
				<tr>
					<!--- date --->
					<td style="white-space: nowrap;"><div class="tablePad"></div><strong>#LSdateFormat(order_date,'mmm DD')#</strong></td>
					<!--- order id --->
					<cfif len(order_id) gt 8>
						<cfset showID = '...' & right(order_id,8)>
					<cfelse>
						<cfset showID = order_id>
					</cfif>
					<td style="text-align:left;"><strong><a class="productLink" href="order-details.cfm?order_id=#order_id#">#showID#</a></strong></td>
					<!--- customer name --->
					<td>#customer_last_name#, #customer_first_name#</td>
					<!--- order total --->
					<td class="decimal">
						#lsCurrencyFormat(order_total)#
					</td>
					<!--- status --->
					<cfif statusID is 1>
						<cfset status = "<strong>#status#</strong>">
					</cfif>
					<td>#status#</td>
				</tr>
				</cfoutput>
				<!--- /END OUTPUT ORDERS --->
				</tbody>
			</table>
			<!--- footer links --->
			<div class="tableFooter"><a href="orders.cfm">View all Order History</a></div>
		</cfif>
	</div>
	<!--- /END if records found --->
</cfif>