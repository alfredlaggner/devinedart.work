<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-widget-customers.cfm
File Date: 2012-02-01
Description:
Displays top spending customers on admin home page
Uses the CWquerySearchProducts query to sort by date descending
==========================================================
--->
<cfset showCt = application.cw.adminWidgetCustomers>
</cfsilent>
<cfif showCt gt 0>
	<!--- QUERY: get top spending customers --->
	<cfset topCustomersQuery = CWquerySelectTopCustomers(showCt)>

	<!--- start output --->
	<div class="CWadminHomeWidget">
		<h3>Top Customers</h3>
		<!--- PRODUCTS TABLE --->
		<!--- if no records found, show message --->
		<cfif NOT topCustomersQuery.recordCount>
			<p>&nbsp;</p>
			<p>&nbsp;</p>
			<p>&nbsp;</p>
			<p><strong>No customers found.</strong></p>
		<cfelse>
			<!--- if we have some records to show --->
			<table class="CWwidgetTable CWstripe">
				<thead>
				<tr class="sortRow">
					<th class="customer_last_name">Name</th>
					<th class="customer_email">Email</th>
					<th class="top_order_date">Order</th>
					<th width="35" class="order_total">Amt.</th>
					<th class="total_spending">Total</th>
				</tr>
				</thead>
				<tbody>

				<!--- OUTPUT CUSTOMERS --->
				<cfoutput query="topCustomersQuery">
					<!--- set up email --->
					<cfif len(customer_email) gt 15>
					<cfset showEmail = left(customer_email,12) & '...'>
					<cfelse>
					<cfset showEmail = customer_email>
					</cfif>
				<!--- output the row --->
				<tr>
					<!--- name --->
					<td><div class="tablePad"></div><strong><a class="productLink" href="customer-details.cfm?customer_id=#topCustomersQuery.customer_id#">#topCustomersQuery.customer_last_name#, #topCustomersQuery.customer_first_name#</a></strong></td>
					<!--- email --->
					<td class="noLink"><cfif isValid('email',customer_email)><a href="mailto:#customer_email#" class="columnLink">#showEmail#</a></cfif></td>
					<!--- order date --->
					<cfif isDefined('topCustomersQuery.top_order_date') and isDate(topCustomersQuery.top_order_date)>
						<!--- if searching by order, we have this info already above --->
						<cfset customer_date = topCustomersQuery.top_order_date >
					<cfelse>
						<!--- QUERY: get customer's last order via simple query (customer id, no. of rows to return) --->
						<cfset lastOrderQuery = CWquerySelectCustomerOrders(topCustomersQuery.customer_id,1)>
						<cfset customer_date = lastOrderQuery.order_date >
					</cfif>
					<td style="white-space: nowrap;">#LSdateFormat(customer_Date,application.cw.globalDateMask)#</td>
					<!--- order total --->
					<td class="decimal">
						<cfif isDefined('topCustomersQuery.order_total') and isNumeric(topCustomersQuery.order_total)>
							#lsCurrencyFormat(topCustomersQuery.order_total)#
						</cfif>
					</td>
					<!--- grand total --->
					<td class="decimal">
						#lsCurrencyFormat(topCustomersQuery.total_spending)#
					</td>
				</tr>
				</cfoutput>
				<!--- /END OUTPUT CUSTOMERS --->
				</tbody>
			</table>
			<!--- footer links --->
			<div class="tableFooter"><a href="customers.cfm">View all Customers</a></div>
		</cfif>
		<!--- /END PRODUCTS TABLE --->
	</div>
</cfif>