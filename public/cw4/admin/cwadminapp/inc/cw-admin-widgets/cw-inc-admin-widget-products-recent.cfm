<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-widget-products-recent.cfm
File Date: 2012-08-25
Description:
Displays recently added or modified products on admin home page
Uses the CWquerySearchProducts query to sort by date descending
==========================================================
--->
<cfset showCt = application.cw.adminWidgetProductsRecent>
</cfsilent>
<cfif showCt gt 0>
	<!--- QUERY: get recently added products
	(searchstring,searchby,searchcat,searchscndcat,searchsortby,searchsortdir,searcharchived)
	--->
	<cfset recentProductsQuery = CWquerySearchProducts('','',0,0,'product_date_modified','desc',0,showCt)>
	<!--- start output --->
	<div class="CWadminHomeWidget">
		<h3>Recently Added / Updated Products</h3>
		<!--- PRODUCTS TABLE --->
		<!--- if no records found, show message --->
		<cfif NOT recentProductsQuery.recordCount>
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
					<!--- add date modified --->
					<th>Modified</th>
					<!--- add 'view on site' link --->
					<cfif isDefined('application.cw.adminProductLinksEnabled') AND application.cw.adminProductLinksEnabled>
						<th class="noSort" width="30">View</th>
					</cfif>
				</tr>
				</thead>
				<tbody>
				<!--- OUTPUT THE PRODUCTS --->
				<cfoutput query="recentProductsQuery" group="product_merchant_product_id">
				<tr>
					<td><div class="tablePad"></div>
						<strong>
						<a class="productLink" href="product-details.cfm?productid=#recentProductsQuery.product_id#" title="Edit Product: #CWstringFormat(recentProductsQuery.product_name)#">#recentProductsQuery.product_name#</a>
						</strong>
					</td>
					<td>#recentProductsQuery.product_merchant_product_id#</td>
					<!--- TIMESTAMP --->
					<td>
						<span class="dateStamp">
							#LSdateFormat(product_date_modified,application.cw.globalDateMask)#
						</span>
					</td>
					<!--- view product link --->
					<cfif isDefined('application.cw.adminProductLinksEnabled') and application.cw.adminProductLinksEnabled>
						<td style="text-align:center;"><a href="#application.cw.appPageDetailsUrl#?product=#recentProductsQuery.product_id#" rel="external" class="columnLink" title="View on Web:  #CWstringFormat(recentProductsQuery.product_name)#"><img src="img/cw-product-view.png" alt="View on Web:  #recentProductsQuery.product_name#"></a></td>
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