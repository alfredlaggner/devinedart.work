<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-related-products.cfm
File Date: 2012-08-25
Description: Handles Upsell management for product-details.cfm
Note: requires related queries, processing and form javascript in product-details.cfm
==========================================================
--->
<cfparam name="url.upsellc" type="integer" default="0">
<cfparam name="url.upsellsc" type="integer" default="0">
<cfparam name="url.upsellfind" type="string" default="">
<cfparam name="application.cw.adminProductUpsellThumbsEnabled" type="string" default="0">
<cfset varsToKeep = CWremoveUrlVars("upsellc,upsellsc,showtab,useralert,userconfirm")>
<cfset request.resetUrl = CWserializeUrl(varsToKeep,request.cw.thisPage) & '&showtab=5'>
<!--- Force the initial category restriction --->
<cfif application.cw.adminProductUpsellByCatEnabled>
	<cfif (listC.recordCount gt 1) and url.upsellc lt 1>
		<cfset url.upsellc = listFirst(valueList(listC.category_id))>
	</cfif>
</cfif>
<!--- set up list of products to omit from list (current product, and those already related) --->
<cfset omittedProducts = url.productid>
<cfif len(trim(valueList(productUpsellQuery.product_id)))>
	<cfset omittedProducts = omittedProducts & ',' & trim(valueList(productUpsellQuery.product_id))>
</cfif>
<!--- QUERY: get all potential upsell products (cat id, subcat id, list products to skip) --->
<cfset upsellsQuery = CWquerySelectUpsellSelections(
url.upsellc,
url.upsellsc,
omittedProducts
)>
<!--- sort the query --->
<cfset upsellsQuery = CWsortableQuery(upsellsQuery) >
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,showtab,delupsellid,submitupsellfilter,upselldelete,userconfirm,useralert,upsellc,upsellsc")>
<cfset request.cw.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage) & '&showtab=5'>
</cfsilent>
<!-- upsell container -->
<table class="noBorder">
	<!--- Display Up-sell items if there are any --->
	<tr>
		<td>
			<form action="<cfoutput>#request.cw.baseUrl#</cfoutput>" name="frmDeleteUpsell" method="post">
				<h3>Related Products</h3>
				<cfif productUpsellQuery.RecordCount>
					<cfset productUpsellQuery = CWsortableQuery(productUpsellQuery)>
					<!-- existing upsells table -->
					<table class="CWsort CWstripe CWformTable" summary="<cfoutput>
						#request.cw.baseUrl#</cfoutput>">
						<thead>
						<tr class="headerRow sortRow">
							<cfif application.cw.adminProductUpsellThumbsEnabled is not 0>
								<th class="noSort">Image</th>
							</cfif>
							<th class="product_name">Related Product Name</th>
							<th class="product_merchant_product_id">Related Product Id</th>
							<th class="noSort" style="text-align:center;"><input type="checkbox" name="all0" class="checkAll" rel="all0" id="relProdAll0">Delete</th>
						</tr>
						</thead>
						<tbody>
						<cfoutput query="productUpsellQuery">
						<tr>
							<cfif application.cw.adminProductUpsellThumbsEnabled is not 0>
								<cfset imageFn = listLast(CWgetImage(productUpsellQuery.product_id,4),'/')>
								<cfif len(trim(imageFn))>
									<cfset imageSrc = '#request.cwpage.adminImgPrefix##application.cw.appImagesDir#/admin_preview/' & imageFn>
								<cfelse>
									<cfset imageSrc = ''>
								</cfif>
								<td class="imageCell" style="text-align:center;">
									<cfif len(trim(imageSrc)) and fileExists(expandPath(imageSrc))>
										<a href="#request.cw.thisPage#?productid=#productUpsellQuery.product_id#" title="View product details"><img src="#imageSrc#" alt="View product details"></a>
									</cfif>
								</td>
							</cfif>
							<td><strong><a class="detailsLink" href="#request.cw.thisPage#?productid=#productUpsellQuery.product_id#" title="View product details">#productUpsellQuery.product_name#</a></strong></td>
							<td> #productUpsellQuery.product_merchant_product_id# </td>
							<td style="text-align: center;">
								<input type="checkbox" name="Deleteupsell_id" value="#productUpsellQuery.upsell_id#" class="all0 formCheckbox">
							</td>
						</tr>
						</cfoutput>
						<!--- delete upsells --->
						<tr>
							<td colspan="4">
								<input id="DelUpsell" name="DeleteChecked" type="submit" class="deleteButton" value="Delete Selected">
							</td>
						</tr>
						</tbody>
					</table>
					<!--- if no upsells --->
				<cfelse>
					<p>&nbsp;</p>
					<p class="formText"><strong>Use the options below to add related products</strong></p>
					<p>&nbsp;</p>
					<p>&nbsp;</p>
				</cfif>
			</form>
			<!-- /end existing upsells table -->
		</td>
	</tr>
	<!--- /END existing upsells--->
	<!--- Display Reciprocal Up-sell items if there are any --->
	<cfif productReciprocalUpsellQuery.RecordCount>
		<tr>
			<td>
				<form action="<cfoutput>#request.cw.baseUrl#</cfoutput>" name="frmDeleteRecipUpsell" method="post">
					<cfset productReciprocalUpsellQuery = CWsortableQuery(productReciprocalUpsellQuery)>
					<!-- reciprocal upsells table -->
					<h3>Reciprocal Related Products</h3>
					<table class="CWsort CWstripe CWformTable" summary="<cfoutput>
						#request.cw.baseUrl#</cfoutput>">
						<thead>
						<tr class="headerRow">
							<cfif application.cw.adminProductUpsellThumbsEnabled is not 0>
								<th class="noSort">Image</th>
							</cfif>
							<th class="product_name">Related Product Name</th>
							<th class="product_merchant_product_id">Related Product Id</th>
							<th class="noSort" style="text-align:center;"><input type="checkbox" name="all4" class="checkAll" rel="all4" id="relProdAll4">Delete</th>
						</tr>
						</thead>
						<tbody>
						<cfoutput query="productReciprocalUpsellQuery">
						<tr>
							<cfif application.cw.adminProductUpsellThumbsEnabled is not 0>
								<cfset imageFn = listLast(CWgetImage(productReciprocalUpsellQuery.product_id,4),'/')>
								<cfif len(trim(imageFn))>
									<cfset imageSrc = '#request.cwpage.adminImgPrefix##application.cw.appImagesDir#/admin_preview/' & imageFn>
								<cfelse>
									<cfset imageSrc = ''>
								</cfif>
								<td class="imageCell" style="text-align:center;">
									<cfif len(trim(imageSrc)) and fileExists(expandPath(imageSrc))>
										<a href="#request.cw.thisPage#?productid=#productReciprocalUpsellQuery.product_id#" title="View product details"><img src="#imageSrc#" alt="View product details"></a>
									</cfif>
								</td>
							</cfif>
							<td><strong><a class="detailsLink" href="#request.cw.thisPage#?productid=#productReciprocalUpsellQuery.product_id#" title="View product details">#productReciprocalUpsellQuery.product_name#</a></strong></td>
							<td> #productReciprocalUpsellQuery.product_merchant_product_id# </td>
							<td style="text-align: center;">
								<input type="checkbox" name="Deleteupsell_id" value="#productReciprocalUpsellQuery.upsell_id#" class="all4 formCheckbox">
							</td>
						</tr>
						</cfoutput>
						<tr>
							<td colspan="4">
								<input id="DelUpsellRecip" name="DeleteChecked" type="submit" class="deleteButton" value="Delete Selected">
							</td>
						</tr>
						</tbody>
					</table>
					<!-- /end reciprocal upsells table -->
				</form>
			</td>
		</tr>
		<!--- delete upsells --->
	</cfif>
	<!--- /END reciprocal upsells--->
	<tr>
		<td>
			<h3>Add Related Products</h3>
			<table class="wide">
				<tr class="headerRow">
					<th>
						Available Related Products
						<cfif (listC.recordCount gt 1 OR listSC.recordCount gt 1) AND application.cw.adminProductUpsellByCatEnabled> (select by category)</cfif>
					</th>
				</tr>
				<tr>
					<td>
						<!--- depends on 'listc and listsc' queries from product search include --->
						<cfif (listC.recordCount gt 1 OR listSC.recordCount gt 1) AND application.cw.adminProductUpsellByCatEnabled>
							<form name="filterUpsell" id="CWadminUpsellSearch" method="GET" action="<cfoutput>#request.cw.baseUrl#</cfoutput>">
								<strong>Filter By: </strong>
								<!--- categories --->
								<cfif listC.recordCount gt 1>
									&nbsp;Category:&nbsp;
									<select name="upsellc" id="upsellc" onchange="document.getElementById('CWadminUpsellSearch').submit()" onkeyup="this.change();">
										<!--- 	<option value="">All</option> --->
										<cfoutput query="listC">
										<option value="#category_id#"<cfif url.upsellc eq category_id> selected</cfif>>#left(category_name,23)#</option>
										</cfoutput>
									</select>
								</cfif>
								<!--- subcategories --->
								<cfif listSC.recordCount gt 1>
									&nbsp;Subcategory:&nbsp;
									<select name="upsellsc" id="upsellsc" onchange="document.getElementById('CWadminUpsellSearch').submit()" onkeyup="this.change();" >
										<option value="0">All</option>
										<cfoutput query="listSC">
										<option value="#secondary_id#"<cfif url.upsellsc eq secondary_id> selected</cfif>>#left(secondary_name,23)#</option>
										</cfoutput>
									</select>
								</cfif>
								<!--- hidden fields --->
								<input type="hidden" name="showtab" value="5">
								<input name="productid" type="hidden" value="<cfoutput>#url.productid#</cfoutput>">
								<!--- submit button --->
								<input type="submit" name="submitupsellfilter" id="submitupsellfilter" class="CWformButton" value="Go">
								<!--- reset search link --->
								<span>
									<a href="<cfoutput>#request.reseturl#</cfoutput>">Reset Search</a>
								</span>
							</form>
						</cfif>
						<!--- add upsell form --->
						<form name="frmAddUpsell" method="POST" action="<cfoutput>#request.cw.baseUrl#</cfoutput>">
							<!-- the select upsell table-->
							<table class="CWsort CWstripe" id="tblUpsellSelect" summary="<cfoutput>#request.cw.baseUrl#</cfoutput>">
								<thead>
								<tr>
									<th class="product_name">Product Name</th>
									<th class="product_merchant_product_id">Product ID</th>
									<th style="width:75px;"  class="noSort checkHeader"><input type="checkbox" name="all1" class="checkAll" rel="all1" id="relProdAll1">Add</th>
									<th style="width:75px;"  class="noSort checkHeader"><input type="checkbox" name="all2" class="checkAll" rel="all2" id="relProdAll2">2-Way</th>
									<cfif application.cw.adminProductLinksEnabled>
										<th style="width:50px; text-align:center;" class="noSort">View</th>
									</cfif>
								</tr>
								</thead>
								<tbody>
								<cfoutput query="upsellsQuery">
								<tr>
									<td title="Select related product">#product_name#</td>
									<td title="Select related product">#product_merchant_product_id#</td>
									<td title="Select related product" style="text-align:center" class="firstCheck">
										<input type="checkbox" name="UpSellproduct_id" value="#product_id#" class="all1">
									</td>
									<td title="Create two-way upsell" style="text-align:center" class="recipCheck">
										<input type="checkbox" name="UpSellProductRecip_ID" value="#product_id#" class="all2">
									</td>
									<cfif application.cw.adminProductLinksEnabled>
										<td style="width:50px;text-align:center">
											<a href="#application.cw.appPageDetailsUrl#?product=#product_id#" title="View on Web: #CWstringFormat(product_name)#" rel="external" class="columnLink"><img alt="View on Web: #product_name#" src="img/cw-product-view.png"></a>
										</td>
									</cfif>
								</tr>
								</cfoutput>
								</tbody>
							</table>
							<div style="clear:both">
								<input name="AddUpsell" type="submit" class="CWformButton" id="AddUpsell" value="Add Selected Products">
							</div>
							<input name="product_id" type="hidden" value="<cfoutput>#url.productid#</cfoutput>">
							<input type="hidden" name="showtab" value="5">
						</form>
					</td>
				</tr>
			</table>
		</td>
	</tr>
	<!--- Display an Up-sell error if one exist --->
	<cfif IsDefined ("request.upSellProductIDError")>
		<tr>
			<td>
				<div class="smallprint">
					<p><strong>**<cfoutput>#request.upSellProductIDError#</cfoutput></strong></p>
				</div>
			</td>
		</tr>
	</cfif>
</table>
<!-- /end upsell container -->