<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-discount-products.cfm
File Date: 2012-08-25
Description: handles product management for discount-details.cfm
Dependencies: requires related queries, processing and form javascript in discount-details.cfm
==========================================================
--->

<cfparam name="url.discountc" type="integer" default="0">
<cfparam name="url.discountsc" type="integer" default="0">
<cfparam name="url.discountfind" type="string" default="">
<cfparam name="url.find" type="string" default="">
<cfparam name="url.searchby" type="string" default="any">
<cfparam name="url.sortby" type="string" default="product_name">
<cfparam name="url.showimg" type="boolean" default="false">
<cfparam name="application.cw.adminDiscountThumbsEnabled" type="string" default="0">
<cfset varsToKeep = CWremoveUrlVars("discountc,discountsc,showtab,useralert,userconfirm,searchby,find")>
<cfset request.resetUrl = CWserializeUrl(varsToKeep,request.cw.thisPage) & '&showtab=3'>

<!--- set up list of products to omit from list (already related) --->
<cfset omittedProducts = ''>
<cfif len(trim(valueList(discountProductsQuery.product_id)))>
	<cfset omittedProducts = trim(valueList(discountProductsQuery.product_id))>
</cfif>
<!--- QUERY: get all potential discount products (cat id, subcat id, keywords, fields to match, products to skip) --->
<cfset productsQuery = CWqueryDiscountProductSelections(
url.discountc,
url.discountsc,
url.find,
url.searchby,
omittedProducts
)>
<!--- sort the query --->
<cfset productsQuery = CWsortableQuery(productsQuery) >
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,showtab,deldiscountid,submitdiscountfilter,discountdelete,userconfirm,useralert,discountc,discountsc,showimg")>
<cfset request.cw.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage) & '&showtab=3'>
</cfsilent>
<!-- discount container -->
<table class="noBorder">
	<!--- display associated items if there are any --->
	<tr>
		<td>
			<form action="<cfoutput>#request.cw.baseUrl#</cfoutput>" name="frmDeleteDiscountProd" method="post">
				<h3>Associated Products</h3>
				<cfif discountProductsQuery.RecordCount>
					<cfset discountProductsQuery = CWsortableQuery(discountProductsQuery)>
					<!-- existing discounts table -->
					<table class="CWsort CWstripe CWformTable" summary="<cfoutput>#request.cw.baseUrl#</cfoutput>">
						<thead>
						<tr class="headerRow sortRow">
							<cfif application.cw.adminDiscountThumbsEnabled is not 0>
								<th class="noSort">Image</th>
							</cfif>
							<th class="product_name">Associated Product Name</th>
							<th class="product_merchant_product_id">Associated Product Id</th>
							<th class="noSort" style="text-align:center;"><input type="checkbox" name="all0" class="checkAll" rel="all0" id="relProdAll0">Delete</th>
						</tr>
						</thead>
						<tbody>
						<cfoutput query="discountProductsQuery">
						<tr>
							<cfif application.cw.adminDiscountThumbsEnabled is not 0>
								<cfset imageFn = listLast(CWgetImage(discountProductsQuery.product_id,4),'/')>
								<cfif len(trim(imageFn))>
									<cfset imageSrc = '#request.cwpage.adminImgPrefix##application.cw.appImagesDir#/admin_preview/' & imageFn>
								<cfelse>
									<cfset imageSrc = ''>
								</cfif>
								<td class="imageCell" style="text-align:center;">
									<cfif len(trim(imageSrc)) and fileExists(expandPath(imageSrc))>
										<a href="product-details.cfm?productid=#discountProductsQuery.product_id#" title="View product details"><img src="#imageSrc#" alt="View product details"></a>
									</cfif>
								</td>
							</cfif>
							<td><strong><a class="detailsLink" href="product-details.cfm?productid=#discountProductsQuery.product_id#" title="View product details">#discountProductsQuery.product_name#</a></strong></td>
							<td> #discountProductsQuery.product_merchant_product_id# </td>
							<td style="text-align: center;">
								<input type="checkbox" name="deleteproduct_id" value="#discountProductsQuery.product_id#" class="all0 formCheckbox">
							</td>
						</tr>
						</cfoutput>
						<!--- delete products --->
						<tr>
							<td colspan="4">
								<input id="DelDiscProduct" name="DeleteChecked" type="submit" class="deleteButton" value="Delete Selected">
								<input name="discount_id" type="hidden" id="discount_id" value="<cfoutput>#discountQuery.discount_id#</cfoutput>">
							</td>
						</tr>
						</tbody>
					</table>
					<!--- if no products --->
				<cfelse>
					<p>&nbsp;</p>
					<p class="formText"><strong>Use the options below to add related products</strong></p>
					<p>&nbsp;</p>
					<p>&nbsp;</p>
				</cfif>
			</form>
			<!-- /end existing products table -->
		</td>
	</tr>
	<!--- /END existing products--->

	<tr>
		<td>
			<h3>Add Associated Products</h3>
			<table class="wide">
				<tr class="headerRow">
					<th>
						Available Associated Products (discount will be applied to all SKUs for selected items)
					</th>
				</tr>
				<tr>
					<td>
							<form name="filterDiscount" id="CWadminDiscountSearch" method="GET" action="<cfoutput>#request.cw.baseUrl#</cfoutput>">
							<div class="CWadminControlWrap">
								<span class="advanced pushRight"><strong>Find Products:</strong></span>
								<!--- keyword search --->
								<label for="find">&nbsp;Keyword:</label>
								<input name="find" type="text" size="15" id="Find" value="<cfoutput>#url.find#</cfoutput>">
								<!--- search fields --->
								<label for="searchBy">&nbsp;Search In:</label>
								<select name="searchBy" id="searchBy">
									<option value="any" <cfif url.searchby eq "any">selected</cfif>>All Fields</option>
									<option value="prodID" <cfif url.searchby eq "prodID">selected</cfif>>Product ID</option>
									<option value="prodName" <cfif url.searchby eq "prodName">selected</cfif>>Product Name</option>
									<option value="descrip" <cfif url.searchby eq "descrip">selected</cfif>>Description</option>
								</select>

								<!--- hidden fields --->
								<input type="hidden" name="showtab" value="3">
								<input name="discount_id" type="hidden" value="<cfoutput>#url.discount_id#</cfoutput>">
								<!--- show images --->
								<cfif application.cw.adminDiscountThumbsEnabled is not 0>
								<label for="showimg">&nbsp;&nbsp;Images:<input name="showimg" type="checkbox"<cfif url.showimg is not 'false'> checked="checked"</cfif> value="true"></label>
								</cfif>
								<!--- submit button --->
								<input type="submit" name="submitdiscountfilter" id="submitdiscountfilter" class="CWformButton" value="Go">
								<!--- categories --->
								<br>
								<!--- show all / reset search --->
								<span class="pushRight"><a href="<cfoutput>#request.reseturl#&submitdiscountfilter=1</cfoutput>#addNew" onclick="return confirm('Show All Products?')">Show All</a></span>
									<label for="discountc"><cfoutput>&nbsp;#application.cw.adminLabelCategory#:&nbsp;</cfoutput></label>
									<select name="discountc" id="discountc">
										<option value="0">All</option>
										<cfoutput query="listC">
										<option value="#category_id#"<cfif url.discountc eq category_id> selected</cfif>>#left(category_name,20)#</option>
										</cfoutput>
									</select>
									<!--- subcategories --->
									<label for="discountsc"><cfoutput>&nbsp;#application.cw.adminLabelSecondary#:&nbsp;</cfoutput></label>
									<select name="discountsc" id="discountsc">
										<option value="0">All</option>
										<cfoutput query="listSC">
										<option value="#secondary_id#"<cfif url.discountsc eq secondary_id> selected</cfif>>#left(secondary_name,20)#</option>
										</cfoutput>
									</select>
							</div>
							</form>
							<!--- /end product search form --->
						<!--- add product form --->
						<form name="frmAddProduct" method="POST" action="<cfoutput>#request.cw.baseUrl#</cfoutput>">
							<!-- the select discount table-->
							<table class="CWsort CWstripe CWformTable" id="tblDiscProdSelect" summary="<cfoutput>#request.cw.baseUrl#</cfoutput>">
								<thead>
								<tr class="headerRow sortRow">
									<cfif url.showimg>
										<th class="img nosort">Image</th>
									</cfif>
									<th class="product_name">Product Name</th>
									<th class="product_merchant_product_id">Product ID</th>
									<th style="width:75px;"  class="noSort checkHeader"><input type="checkbox" name="all1" class="checkAll" rel="all1" id="relProdAll1">Add</th>
									<th style="width:50px; text-align:center;" class="noSort">View</th>
								</tr>
								</thead>

								<!--- only show if search has been submitted (avoid showing all products on every page load) --->
								<cfif isDefined('url.submitdiscountfilter')>

								<tbody>
								<cfif productsQuery.recordCount>
								<cfoutput query="productsQuery">
								<tr>
									<!--- image cell --->
									<cfif url.showimg>
										<cfset imageFn = listLast(CWgetImage(product_id,4),'/')>
										<cfif len(trim(imageFn))>
											<cfset imageSrc = '#request.cwpage.adminImgPrefix##application.cw.appImagesDir#/admin_preview/' & imageFn>
										<cfelse>
											<cfset imageSrc = ''>
										</cfif>
										<td class="imageCell" style="text-align:center;">
											<cfif len(trim(imageSrc)) and fileExists(expandPath(imageSrc))>
												<a href="product-details.cfm?productid=#productsQuery.product_id#" title="View product details"><img src="#imageSrc#" alt="View product details"></a>
											</cfif>
										</td>
									</cfif>
									<!--- name --->
									<td title="Select related product">#product_name#</td>
									<!--- merchant id--->
									<td title="Select related product">#product_merchant_product_id#</td>
									<!--- select box --->
									<td title="Select related product" style="text-align:center" class="firstCheck">
										<input type="checkbox" name="discount_product_id" value="#product_id#" class="all1">
									</td>
									<!--- view product link --->
									<td style="width:50px;text-align:center">
										<a href="#application.cw.appPageDetailsUrl#?product=#product_id#" title="View on Web: #CWstringFormat(product_name)#" rel="external" class="columnLink"><img alt="View on Web: #product_name#" src="img/cw-product-view.png"></a>
									</td>
								</tr>
								</cfoutput>
								</cfif>
								</tbody>
								</cfif>
							</table>
							<cfif not productsQuery.recordCount>
								<p>&nbsp;</p>
								<p>No available products found.</p>
								<p>&nbsp;</p>
							<cfelse>
								<cfif isDefined('url.submitdiscountfilter')>
									<div style="clear:both">
										<input name="AddDiscProd" type="submit" class="CWformButton" id="AddDiscProd" value="Add Selected Products">
									</div>
									<input name="discount_id" type="hidden" value="<cfoutput>#url.discount_id#</cfoutput>">
									<input name="discount_product_id" type="hidden" value="">
									<input type="hidden" name="showtab" value="3">
								<cfelse>
									<p>&nbsp;</p>
									<p>Use the search controls to find and select products</p>
									<p>&nbsp;</p>
								</cfif>
							</cfif>
						</form>
					</td>
				</tr>
			</table>
		</td>
	</tr>
</table>
<!-- /end discount container -->