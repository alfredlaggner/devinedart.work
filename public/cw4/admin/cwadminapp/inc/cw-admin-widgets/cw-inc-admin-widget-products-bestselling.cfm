<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-widget-products-bestselling.cfm
File Date: 2012-08-25
Description:
Displays top selling products on admin home page
Uses the specific Top Products query function
==========================================================
--->
<cfset showCt = application.cw.adminWidgetProductsBestselling>
</cfsilent>
<cfif showCt gt 0>
	<!--- QUERY: get best selling products (number of records to show) --->
	<cfset topProductsQuery = CWquerySelectTopProducts(showCt)>
	<!--- start output --->
	<div class="CWadminHomeWidget">
		<h3>Best Selling Products</h3>
		<!--- PRODUCTS TABLE --->
		<!--- if no records found, show message --->
		<cfif NOT topProductsQuery.recordCount>
			<p>&nbsp;</p>
			<p>&nbsp;</p>
			<p>&nbsp;</p>
			<p><strong>No products found.</strong></p>
		<cfelse>
			<!--- if we have some records to show --->
			<table class="CWwidgetTable CWstripe">
				<thead>
				<tr class="sortRow">
					<th class="product_name">Product Name</th>
					<th class="product_merchant_product_id">Product ID</th>
					<!--- number sold --->
					<th>Sold</th>
					<!--- add 'view on site' link --->
					<cfif isDefined('application.cw.adminProductLinksEnabled') AND application.cw.adminProductLinksEnabled>
						<th class="noSort" width="30">View</th>
					</cfif>
				</tr>
				</thead>
				<tbody>
				<!--- OUTPUT THE PRODUCTS --->
				<cfoutput query="topProductsQuery" group="product_id">
				<tr>
					<td><div class="tablePad"></div>
						<strong>
						<a class="productLink" href="product-details.cfm?productid=#topProductsQuery.product_id#" title="Edit Product: #CWstringFormat(topProductsQuery.product_name)#">#topProductsQuery.product_name#</a>
						</strong>
					</td>
					<td>#topProductsQuery.product_merchant_product_id#</td>
					<!--- number sold --->
					<td>#prod_counter#</td>
					<!--- view product link --->
					<cfif isDefined('application.cw.adminProductLinksEnabled') and application.cw.adminProductLinksEnabled>
						<td style="text-align:center;"><a href="#application.cw.appPageDetailsUrl#?product=#topProductsQuery.product_id#" class="columnLink" rel="external" title="View on Web: #CWstringFormat(topProductsQuery.product_name)#"><img src="img/cw-product-view.png" alt="View on Web:  #topProductsQuery.product_name#"></a></td>
					</cfif>
					</tr>
					</cfoutput>
					</tbody>
			</table>
			<div class="tableFooter"><a href="products.cfm">View all Products</a></div>
	</cfif>
	<!--- /END PRODUCTS TABLE --->
</div>
</cfif>