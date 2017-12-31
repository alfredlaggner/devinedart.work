<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-discount-skus.cfm
File Date: 2012-08-25
Description: Handles skus management for discount-details.cfm
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

<!--- set up list of skus to omit from list (already related) --->
<cfset omittedSkus = ''>
<cfif len(trim(valueList(discountSkusQuery.product_id)))>
	<cfset omittedSkus = trim(valueList(discountSkusQuery.sku_id))>
</cfif>
<!--- QUERY: get all potential discount products (cat id, subcat id, keywords, fields to match, products to skip) --->
<cfset skuQuery = CWqueryDiscountSkuSelections(
url.discountc,
url.discountsc,
url.find,
url.searchby,
omittedSkus
)>
<!--- sort the query --->
<cfset skuQuery = CWsortableQuery(skuQuery) >
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,showtab,deldiscountid,submitdiscountfilter,discountdelete,userconfirm,useralert,discountc,discountsc,showimg")>
<cfset request.cw.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage) & '&showtab=3'>
<!--- javascript for show/hide sku details --->
<cfsavecontent variable="discountSkujs">
<script type="text/javascript">
jQuery(document).ready(function(){
	jQuery('td.detailsShow').click(function(){
		var thisRel = jQuery(this).children('a.showSkusLink').attr('rel');
		jQuery(this).parents('tr.CWskuHeader').hide();
		jQuery(this).parents('tr').siblings('tr.CWskuDetails[rel=' + thisRel + ']').show();
		return false;
	});
	jQuery('td.detailsHide').click(function(){
		var thisRel = jQuery(this).children('a.hideSkusLink').attr('rel');
		jQuery(this).parents('tr.CWskuDetails').hide().prev('tr.CWskuHeader').show();
		jQuery(this).parents('tr').siblings('tr.CWskuDetails[rel=' + thisRel + ']').hide();
		return false;
	});
		jQuery('a.showAll').click(function(){
		jQuery(this).hide();
		jQuery(this).siblings('a.hideAll').show();
		jQuery('tr.CWskuHeader').hide();
		jQuery('tr.CWskuDetails').show();
	});

	jQuery('a.hideAll').click(function(){
		jQuery(this).hide();
		jQuery(this).siblings('a.showAll').show();
		jQuery('tr.CWskuDetails').hide();
		jQuery('tr.CWskuHeader').show();
	});
	jQuery('a.delAll').click(function(){
		jQuery('tr.CWskuHeader').hide();
		jQuery('tr.CWskuDetails').show();
		jQuery('a.hideAll').show();
		jQuery('a.showAll').hide();
		jQuery('#tblDiscSkus input[type=checkbox]').prop('checked',true);
	});
});
</script>
<style type="text/css">
	a.showSkusLink, a.hideSkusLink{
	margin-left:11px;
	text-decoration:none !important;
	}
	td.detailsShow{
	padding:6px 7px !important;
	}
	a.delAll{
	float:right;
	margin-right:18px;
	}
	a.showAll, a.hideAll, a.delAll{
	text-decoration:none !important;
	}
</style>

</cfsavecontent>
<cfhtmlhead text="#discountSkujs#">
</cfsilent>
<!-- discount container -->
<table class="noBorder">
	<!--- display associated items if there are any --->
	<tr>
		<td>
			<form action="<cfoutput>#request.cw.baseUrl#</cfoutput>" name="frmDeleteDiscountProd" method="post">
				<h3>Associated SKUs by Product <span class="smallPrint">
				<a href="#" class="showAll">Show All</a>
				<a href="#" class="hideAll" style="display:none;">Hide All</a>
				<a href="#" class="delAll">Delete All</a></span> </h3>
				<cfif discountSkusQuery.RecordCount>
					<cfset discountSkusQuery = CWsortableQuery(discountSkusQuery)>
					<table class="CWsort CWformTable" id="tblDiscSkus" summary="<cfoutput>#request.cw.baseUrl#</cfoutput>">
						<thead>
						<tr class="headerRow sortRow">
							<cfif application.cw.adminDiscountThumbsEnabled is not 0>
								<th class="noSort" style="width:100px;">Image</th>
							</cfif>
							<th class="sku_name"<cfif application.cw.adminDiscountThumbsEnabled is 0> colspan="2"</cfif>>Associated Product Name</th>
							<th class="product_merchant_product_id" style="width:215px;">Associated Product Id</th>
						</tr>
						</thead>
						<tbody>
						<!--- group by product --->
						<cfoutput query="discountSkusQuery" group="product_id">
						<!--- manual coloring by adding odd or even classes here --->
						<tr class="CWrowOdd CWproductRow">
							<cfif application.cw.adminDiscountThumbsEnabled is not 0>
								<cfset imageFn = listLast(CWgetImage(discountSkusQuery.product_id,4),'/')>
								<cfif len(trim(imageFn))>
									<cfset imageSrc = '#request.cwpage.adminImgPrefix##application.cw.appImagesDir#/admin_preview/' & imageFn>
								<cfelse>
									<cfset imageSrc = ''>
								</cfif>
								<td class="imageCell" style="text-align:center;">
									<cfif len(trim(imageSrc)) and fileExists(expandPath(imageSrc))>
										<a href="product-details.cfm?productid=#discountSkusQuery.product_id#" title="View product details"><img src="#imageSrc#" alt="View product details"></a>
									</cfif>
								</td>
							</cfif>
							<td<cfif application.cw.adminDiscountThumbsEnabled is 0> colspan="2"</cfif>><strong><a class="detailsLink" href="product-details.cfm?productid=#discountSkusQuery.product_id#" title="View product details">#discountSkusQuery.product_name#</a></strong></td>
							<td> #discountSkusQuery.product_merchant_product_id# </td>
						</tr>
						<!--- skus header --->
						<tr class="CWskuHeader">
						<td colspan="3" class="detailsShow">
							<!--- show/hide function usees 'rel' attribute of this link --->
							<a href="##" class="showSkusLink" rel="prod#discountSkusQuery.product_id#">&raquo;&nbsp;Show Skus</a>
						</td>
						</tr>
						<!--- sku details --->
							<tr class="CWskuDetails" rel="prod#discountSkusQuery.product_id#" style="display:none;">
								<td class="detailsHide">
									<!--- show/hide function usees 'rel' attribute of this link --->
									<a href="##" style="font-weight:100;" class="hideSkusLink" rel="prod#discountSkusQuery.product_id#">&laquo;&nbsp;Hide Skus</a>
								</td>
								<td colspan="2">
									<table style="width:100%;" class="CWformTable">
										<tr>
											<th style="text-align: center;width:230px;">
											SKU ID
											</th>
											<th style="text-align: center;">
											SKU Options
											</th>
											<th style="text-align: center; width:100px;">
											<input type="checkbox" name="deleteskuproduct_id" value="#discountSkusQuery.product_id#" class="checkAll formCheckbox" rel="all#product_id#">
											Delete
											</th>
										</tr>
									<!--- ungroup the grouped sku output --->
									<cfoutput>
										<!--- QUERY: get SKU options --->
										<cfset skuOptionsQuery = CWquerySelectSkuOptions(sku_id)>
										<tr>
											<td>
												#sku_merchant_sku_id#
											</td>
											<td>
											<cfif skuOptionsQuery.recordCount>
												<p>
												<cfloop query="skuOptionsQuery">
												#optionType_name#: #option_name#<br>
												</cfloop>
												</p>
											<cfelse>
											<p>No Options</p>
											</cfif>
											</td>
											<td style="text-align: center;">
												<!--- delete checkbox --->
												<input type="checkbox" name="deletesku_id" value="#discountSkusQuery.sku_id#" class="all#product_id# all0 formCheckbox">
											</td>
										</tr>
									</cfoutput>
									</table>
								</td>
							</tr>
							<!--- /end sku details --->
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
					<p class="formText"><strong>Use the options below to add related skus</strong></p>
					<p>&nbsp;</p>
					<p>&nbsp;</p>
				</cfif>
				<!--- anchor link for lower section --->
				<a name="addNew"></a>
			</form>
		</td>
	</tr>
	<!--- /END existing products--->

	<!--- ADD NEW PRODUCTS --->
	<tr>
		<td>
			<h3>Add Associated SKUs</h3>
			<table class="wide">
				<tr class="headerRow">
					<th>
						Available Associated Products (search by product or sku name)
					</th>
				</tr>
				<tr>
					<td>
							<!--- product/sku search form - anchor link on action returns to lower page area --->
							<form name="filterDiscount" id="CWadminDiscountSearch" method="GET" action="<cfoutput>#request.cw.baseUrl#</cfoutput>#addNew">
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
									<option value="skuName" <cfif url.searchby eq "skuName">selected</cfif>>SKU Name</option>
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
									<th style="width:50px; text-align:center;" class="noSort">View</th>
								</tr>
								</thead>

								<!--- only show if search has been submitted (avoid showing all products on every page load) --->
								<cfif isDefined('url.submitdiscountfilter')>

								<tbody>
								<cfif skuQuery.recordCount>
								<cfoutput query="skuQuery" group="product_id">
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
												<a href="product-details.cfm?productid=#discountSkusQuery.product_id#" title="View product details"><img src="#imageSrc#" alt="View product details"></a>
											</cfif>
										</td>
									</cfif>
									<!--- name --->
									<td title="Select related product">#product_name#</td>
									<!--- merchant id--->
									<td title="Select related product">#product_merchant_product_id#</td>
									<!--- view product link --->
									<td style="width:50px;text-align:center">
										<a href="#application.cw.appPageDetailsUrl#?product=#product_id#" title="View on Web: #CWstringFormat(product_name)#" rel="external" class="columnLink"><img alt="View on Web: #product_name#" src="img/cw-product-view.png"></a>
									</td>
								</tr>

							<!--- sku details --->
							<tr>
								</td>
								<td colspan="<cfif url.showimg>3<cfelse>2</cfif>">
									<table style="width:98%;" class="CWformTable">
										<tr>
											<th style="text-align: center;width:230px;">
											SKU ID
											</th>
											<th style="text-align: center;">
											SKU Options
											</th>
											<th style="text-align: center; width:100px;">
											<input type="checkbox" class="checkAll formCheckbox" rel="addall#product_id#">
											Add
											</th>
										</tr>
									<!--- ungroup the grouped sku output --->
									<cfoutput>
										<!--- QUERY: get SKU options --->
										<cfset skuOptionsQuery = CWquerySelectSkuOptions(sku_id)>
										<tr>
											<td>
												#sku_merchant_sku_id#
											</td>
											<td>
										<cfif skuOptionsQuery.recordCount>
											<p>
											<cfloop query="skuOptionsQuery">
											#optionType_name#: #option_name#<br>
											</cfloop>
											</p>
										<cfelse>
										<p>No Options</p>
										</cfif>
											</td>
											<td style="text-align: center;">
												<!--- add item checkbox --->
												<input type="checkbox" name="discount_sku_id" value="#sku_id#" class="addall#product_id# all0 formCheckbox">
											</td>
										</tr>
									</cfoutput>
									</table>
								</td>
							</tr>
							<!--- /end sku details --->

								</cfoutput>
								</cfif>
								</tbody>
								</cfif>
							</table>
							<cfif not skuQuery.recordCount>
								<p>&nbsp;</p>
								<p>No available skus found.</p>
								<p>&nbsp;</p>
							<cfelse>
								<cfif isDefined('url.submitdiscountfilter')>
									<div style="clear:both">
										<input name="AddDiscSku" type="submit" class="CWformButton" id="AddDiscProd" value="Add Selected Skus">
									</div>
									<input name="discount_id" type="hidden" value="<cfoutput>#url.discount_id#</cfoutput>">
									<input name="discount_sku_id" type="hidden" value="">
									<input type="hidden" name="showtab" value="3">
								<cfelse>
									<p>&nbsp;</p>
									<p>Use the search controls to find and select SKUs</p>
									<p>&nbsp;</p>
								</cfif>
							</cfif>
						</form>
					</td>
				</tr>
			</table>
		</td>
	</tr>
	<!--- /end add new products --->
</table>
<!-- /end discount container -->