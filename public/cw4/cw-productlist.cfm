<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-productlist.cfm
File Date: 2013-01-08
Description: shows product listings and search results
==========================================================
--->
<!--- default url variables --->
<cfparam name="url.category" default="0">
<cfparam name="url.secondary" default="0">
<cfparam name="url.keywords" default="">
<cfparam name="url.page" default="1">
<cfparam name="url.showall" default="0">
<cfif not (isDefined('application.cw.productShowAll') and application.cw.productShowAll is true) 
		and (url.showall eq 'true' or url.showall eq 1)>
	<cfset url.showall = 0>
</cfif>
<cfif not isNumeric(url.page)>
	<cfset url.page = 1>
</cfif>
<!--- sorting vars --->
<cfparam name="session.cwclient.cwProductSortBy" default="sort">
<cfparam name="session.cwclient.cwProductSortDir" default="asc">
<cfparam name="session.cwclient.cwProductPerPage" default="#application.cw.appDisplayPerPage#">
<cfparam name="url.sortby" default="#session.cwclient.cwProductSortBy#">
<cfparam name="url.sortdir" default="#session.cwclient.cwProductSortDir#">
<cfparam name="url.perpage" default="#session.cwclient.cwProductPerPage#">
<!--- page variables passed to search function
can be overridden per page or passed in via URL --->
<cfparam name="request.cwpage.categoryName" default="">
<cfparam name="request.cwpage.categoryID" default="#url.category#">
<cfparam name="request.cwpage.secondaryName" default="">
<cfparam name="request.cwpage.secondaryID" default="#url.secondary#">
<cfparam name="request.cwpage.keywords" default="#url.keywords#">
<cfparam name="request.cwpage.resultsPage" default="#url.page#">
<cfparam name="request.cwpage.resultsMaxRows" default="#url.perpage#">
<cfparam name="request.cwpage.showAll" default="#url.showall#">
<cfparam name="request.cwpage.sortBy" default="#url.sortby#">
<cfparam name="request.cwpage.sortDir" default="#url.sortdir#">
<cfparam name="request.cwpage.storeLinkText" default="#application.cw.companyName#">
<cfparam name="primaryText" default="">
<cfparam name="secondaryText" default="">
<!--- if using sort order default, force 'ascending' order (1-9999) --->
<cfif request.cwpage.sortBy is 'sort'>
	<cfset request.cwpage.sortDir = 'asc'>
</cfif>
<!--- set up sortable links --->
<cfparam name="application.cw.appDisplayProductSort" default="true">
<cfparam name="request.cwpage.showSortLinks" default="#application.cw.appDisplayProductSort#">
<!--- toggle sort direction --->
<cfif request.cwpage.showSortLinks>
	<cfif request.cwpage.sortDir is 'asc'>
		<cfset newSortDir = 'desc'>
	<cfelse>
		<cfset newSortDir = 'asc'>
	</cfif>
</cfif>
<!--- verify sortby is allowed --->
<cfif not listFindNoCase('name,price,id',request.cwpage.sortBy)>
	<cfset request.cwpage.sortBy = 'sort'>
</cfif>
<!--- verify per page is numeric, and one of our specified values --->
<cfif not (isNumeric(request.cwpage.resultsMaxRows) AND listFind(application.cw.productPerPageOptions,request.cwpage.resultsMaxRows))>
	<cfset request.cwpage.resultsMaxRows = application.cw.appDisplayPerPage>
</cfif>
<!--- set up link to edit admin product listing (if logged in) --->
<cfparam name="application.cw.adminProductLinksEnabled" default="false">
<!--- set up add to cart in listings --->
<cfparam name="application.cw.appDisplayListingAddToCart" default="false">
<!--- defaults for product search --->
<cfparam name="request.cwpage.productsPerRow" default="#application.cw.appDisplayColumns#">
<!--- clean up form and url variables --->
<cfinclude template="cwapp/inc/cw-inc-sanitize.cfm">
<!--- CARTWEAVER REQUIRED FUNCTIONS --->
<cfinclude template="cwapp/inc/cw-inc-functions.cfm">
<!--- form and link actions --->
<cfparam name="request.cwpage.hrefUrl" default="#CWtrailingChar(trim(application.cw.appCwStoreRoot))##request.cw.thisPage#">
<cfparam name="request.cwpage.adminUrlPrefix" default="">
<!--- page variables - request scope can be overridden per product as needed
params w/ default values are in application.cfc --->
<cfset request.cwpage.useAltPrice = application.cw.adminProductAltPriceEnabled>
<cfset request.cwpage.altPriceLabel = application.cw.adminLabelProductAltPrice>
<cfset request.cwpage.imageZoom = application.cw.appEnableImageZoom>
<cfset request.cwpage.continueShopping = application.cw.appActionContinueShopping>
<!--- address used for redirection --->
<cfset request.cwpage.relocateUrl = application.cw.appSiteUrlHttp>
<!--- address for continue shopping --->
<cfparam name="request.cwpage.returnUrl" default="#request.cwpage.urlResults#">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,perpage,showall,page,maxrows,submit,userconfirm,useralert,listingSortSelect,listingPerPage")>
<!--- create the base url out of serialized url variables--->
<cfparam name="request.cwpage.baseUrl" default="#CWserializeUrl(varsToKeep,request.cwpage.urlResults)#">
	<cfif request.cwpage.baseUrl contains "=">
		<cfset request.cwpage.baseUrl = request.cwpage.baseUrl & "&">
	</cfif>
<!--- persist showall for sorting --->
<cfset request.cwpage.baseSortUrl = request.cwpage.baseUrl & 'showall=#request.cwpage.showAll#'>
	<cfif not right(request.cwpage.baseSortUrl,1) is "&">
		<cfset request.cwpage.baseSortUrl = request.cwpage.baseSortUrl & "&">
	</cfif>
<!--- handle show all / paging (url.showall) --->
<cfif request.cwpage.showAll is true>
	<cfset request.cwpage.resultsPage = 1>
	<cfset request.cwpage.maxproducts = 1000>
<cfelse>
	<cfset request.cwpage.maxproducts = request.cwpage.resultsMaxRows>
</cfif>
<!--- if dropdowns are posted rather than changed (no js) --->
<cfif isDefined('url.listingSortSelect')>
	<cfif url.listingSortSelect contains '?' and len(trim(listLast(url.listingSortSelect,'?')))>
		<cflocation url="#request.cw.thisPage#?#listLast(url.listingSortSelect,'?')#" addtoken="no">
	<cfelse>
		<cflocation url="#request.cwpage.baseSortUrl#" addtoken="no">
	</cfif>
</cfif>
<!--- PRODUCT SEARCH QUERY --->
<cfset products = CWqueryProductSearch(
	category="#request.cwpage.categoryID#",
	secondary="#request.cwpage.secondaryID#",
	keywords="#request.cwpage.keywords#",
	start_page="#request.cwpage.resultsPage#",
	max_rows="#request.cwpage.maxproducts#",
	sort_by="#request.cwpage.sortBy#",
	sort_dir="#request.cwpage.sortDir#",
	match_type="#application.cw.appSearchMatchType#"
	)>
<cfset idlist = products.idlist>
<cfset productCount = products.count>
<!--- if only one is found, direct to that page --->
<cfif productCount is 1 and listLen(idlist) is 1>
	<cflocation url="#request.cwpage.urlDetails#?product=#idList#" addtoken="no">
</cfif>
<!--- style width for results --->
<cfset listingW = 100/request.cwpage.productsPerRow & '%'>
<!--- javascript for form sort links --->
<cfsavecontent variable="headcontent">
<cfif application.cw.appDisplayProductSortType is 'select' and request.cwpage.showSortLinks>
	<script type="text/javascript">
			jQuery(document).ready(function(){
			jQuery('select.listingSortSelect,select.listingPerPage').change(function(){
			var submitUrl = jQuery(this).children('option:selected').val();
			window.location=submitUrl;
			});
		});
	</script>
</cfif>
</cfsavecontent>
<!--- send to head of page --->
<cfhtmlhead text="#headcontent#">
</cfsilent>
<!--- /////// START OUTPUT /////// --->
<!--- product sorting --->
<cfif request.cwpage.showSortLinks>
	<!--- links --->
	<cfif application.cw.appDisplayProductSortType is 'links'>
		<div class="CWlistingSortLinks">
			<cfoutput>
				Sort by: <a href="#request.cwpage.baseSortUrl#sortby=name<cfif request.cwpage.sortBy is 'name'>&sortdir=#newSortDir#</cfif>"<cfif request.cwpage.sortBy is 'name'>class="currentLink"</cfif>>Product Name</a> <a href="#request.cwpage.baseSortUrl#sortby=price<cfif request.cwpage.sortBy is 'price'>&sortdir=#newSortDir#</cfif>"<cfif request.cwpage.sortBy is 'price'>class="currentLink"</cfif>>Price</a> <a href="#request.cwpage.baseSortUrl#sortby=id&sortdir=desc"<cfif request.cwpage.sortBy is 'id'>class="currentLink"</cfif>>Newly Added</a> <a href="#request.cwpage.baseSortUrl#sortby=sort&sortdir=asc"<cfif request.cwpage.sortBy is 'sort'>class="currentLink"</cfif>>Recommended Items</a>
			</cfoutput>
		</div>
		<!--- select dropdown --->
	<cfelse>
		<div class="CWlistingSortSelect">
			<cfoutput>
				<form name="listingSortForm" class="listingSortForm" action="#request.cwpage.baseSortUrl#">
					<cfif listLen(application.cw.productPerPageOptions) gt 1 and not request.cwpage.showAll eq 1>
						<label for="listingPerPage">Per Page:</label>
						<select name="listingPerPage" class="listingSortSelect">
						<cfloop list="#application.cw.productPerPageOptions#" index="i">
							<cfif isNumeric(trim(i))>
							<option value="#request.cwpage.baseSortUrl#perpage=#trim(i)#"<cfif request.cwpage.resultsMaxRows is trim(i)> selected="selected"</cfif>>#trim(i)#</option>
							</cfif>
						</cfloop>
						</select>
					</cfif>
					<label for="listingSortSelect">Sort By:</label>
					<select name="listingSortSelect" class="listingSortSelect">
						<option value="#request.cwpage.baseSortUrl#sortby=id&sortdir=desc"<cfif request.cwpage.sortBy is 'id'> selected="selected"</cfif>>Newly Added</option>
						<option value="#request.cwpage.baseSortUrl#sortby=price&sortdir=asc"<cfif request.cwpage.sortBy is 'price' and request.cwpage.sortDir is 'asc'> selected="selected"</cfif>>Price (Lowest First)</option>
						<option value="#request.cwpage.baseSortUrl#sortby=price&sortdir=desc"<cfif request.cwpage.sortBy is 'price' and request.cwpage.sortDir is 'desc'> selected="selected"</cfif>>Price (Highest First)</option>
						<option value="#request.cwpage.baseSortUrl#sortby=name&sortdir=asc"<cfif request.cwpage.sortBy is 'name' and request.cwpage.sortDir is 'asc'> selected="selected"</cfif>>Name (A-Z)</option>
						<option value="#request.cwpage.baseSortUrl#sortby=name&sortdir=desc"<cfif request.cwpage.sortBy is 'name' and request.cwpage.sortDir is 'desc'> selected="selected"</cfif>>Name (Z-A)</option>
						<option value="#request.cwpage.baseSortUrl#sortby=sort&sortdir=asc"<cfif request.cwpage.sortBy is 'sort'> selected="selected"</cfif>>Recommended Items</option>
					</select>					
				</form>
			</cfoutput>
		</div>
	</cfif>
</cfif>
<!--- /end sort links --->
<!--- breadcrumb navigation 
<cfmodule template="cwapp/mod/cw-mod-searchnav.cfm"
search_type="breadcrumb"
separator=" &raquo; "
all_categories_label="All Products"
all_secondaries_label="All"
all_products_label=""
> --->
<!--- paging and product count 
<cfmodule template="cwapp/mod/cw-mod-productpaging.cfm"
results_per_page="#request.cwpage.resultsMaxRows#"
total_records="#productCount#"
max_links="#application.cw.appDisplayPageLinksMax#"
base_url="#request.cwpage.baseUrl#sortby=#request.cwpage.sortBy#&sortdir=#request.cwpage.sortDir#"
current_page="#request.cwpage.resultsPage#"
show_all="#request.cwpage.showAll#"
> --->
<!--- show listings --->
<div id="CWlistings" class="CWcontent">
	<!-- category/secondary/product name -->
	<cfif request.cwpage.categoryID gt 0 and len(trim(request.cwpage.categoryName))
		AND (
		application.cw.appEnableCatsRelated eq 'true'
		OR
		(application.cw.appEnableCatsRelated eq 'false' and request.cwpage.secondaryID is 0)
		)>
		<cfsavecontent variable="primaryText">
		<cfoutput>
			<a href="#request.cwpage.urlResults#?category=#request.cwpage.categoryID#">#request.cwpage.categoryName#</a>
		</cfoutput>
		</cfsavecontent>
	<cfelseif len(trim(request.cwpage.storeLinkText))>
		<cfsavecontent variable="primaryText">
		<cfoutput>
			<a href="#request.cwpage.urlResults#">#request.cwpage.storeLinkText#</a>
		</cfoutput>
		</cfsavecontent>
	</cfif>
	<cfif request.cwpage.secondaryID gt 0 and len(trim(request.cwpage.secondaryName))>
		<cfsavecontent variable="secondaryText">
		<cfoutput>
			<a href="#request.cwpage.urlResults#?<cfif request.cwpage.categoryID gt 0>category=#request.cwpage.categoryID#&</cfif>secondary=#request.cwpage.secondaryID#">#request.cwpage.secondaryName#</a>
		</cfoutput>
		</cfsavecontent>
	</cfif>
	<h1 class="CWcategoryName">
		<cfif len(trim(primaryText))><cfoutput>#primaryText#</cfoutput></cfif>
		<cfif len(trim(primaryText)) and len(trim(secondaryText))>:</cfif>
		<cfif len(trim(secondaryText))><cfoutput>#secondaryText#</cfoutput></cfif>
	</h1>
	<!--- category / subcategory descriptions --->
	<cfset listingPrimaryText = CWgetListingText(category_id=request.cwpage.categoryID)>
	<cfset listingSecondaryText = CWgetListingText(secondary_id=request.cwpage.secondaryID)>
	<!--- primary description --->
	<!--- if related categories are selected, primary description is shown only for 'all' in category (no secondary category) --->
	<cfif (application.cw.appEnableCatsRelated eq 'true' AND len(trim(listingSecondaryText)) eq 0 AND len(trim(listingPrimaryText)) gt 0)
		OR application.cw.appEnableCatsRelated eq 'false' AND len(trim(listingPrimaryText)) gt 0>
		<div class="CWlistingText" id="CWprimaryDesc">
			<cfoutput>#listingPrimaryText#</cfoutput>
		</div>
	</cfif>
	<!--- secondary description --->
	<cfif len(trim(listingSecondaryText)) gt 0>
		<div class="CWlistingText" id="CWsecondaryDesc">
			<cfoutput>#listingSecondaryText#</cfoutput>
		</div>
	</cfif>
	<!--- if products were found --->
	<!--- if no products are returned --->
	<cfif products.count eq 0>
		<div class="CWalertBox">
			<cfoutput>
				No Products Found<cfif len(trim(request.cwpage.keywords))> for search term "#request.cwpage.keywords#"</cfif>
				<br><br><a href="#request.cwpage.hrefUrl#">View All Products</a>
			</cfoutput>
		</div>
	</cfif>
	<!--- loop list of IDs from function above --->
	<cfset loopCt = 1>
	<cfloop list="#idList#" index="pp">
		<!--- count output for insertion of breaks or other formatting --->
		<!--- show the product include --->
		<div class="CWlistingBox" style="width:<cfoutput>#listingW#</cfoutput>;">
			<!--- product preview --->
			<cfmodule
			template="cwapp/mod/cw-mod-productpreview.cfm"
			product_id="#pp#"
			add_to_cart="#application.cw.appDisplayListingAddToCart#"
			show_qty="false"
			show_description="true"
			show_image="true"
			show_price="false"
			image_class="CWimgResults"
			image_position="above"
			title_position="above"
			details_link_text="&raquo; details"
			>
			<!--- edit product link --->
			<cfif application.cw.adminProductLinksEnabled
				and isDefined('session.cw.loggedIn') and session.cw.loggedIn is '1'
				and isDefined('session.cw.accessLevel') and	listFindNoCase('developer,merchant',session.cw.accessLevel)>
				<cfoutput>
					<p><a href="#request.cwpage.adminUrlPrefix##application.cw.appCwAdminDir#product-details.cfm?productid=#pp#" class="CWeditProductLink" title="Edit Product"><img alt="Edit Product" src="#request.cwpage.adminUrlPrefix##application.cw.appCwAdminDir#img/cw-edit.gif"></a></p>
				</cfoutput>
			</cfif>
		</div>
		<!--- divide rows --->
		<cfif loopCt mod request.cwpage.productsPerRow is 0>
			<div class="CWclear"></div>
		</cfif>
		<!--- advance counter --->
		<cfset loopCt = loopCt + 1>
	</cfloop>
	<!-- clear floated content -->
	<div class="CWclear"></div>
</div>
<!--- paging and product count --->
<cfmodule template="cwapp/mod/cw-mod-productpaging.cfm"
results_per_page="#request.cwpage.resultsMaxRows#"
total_records="#productCount#"
max_links="#application.cw.appDisplayPageLinksMax#"
base_url="#request.cwpage.baseUrl#sortby=#request.cwpage.sortBy#&sortdir=#request.cwpage.sortDir#"
current_page="#request.cwpage.resultsPage#"
show_all="#request.cwpage.showAll#"
>
<!-- / end #CWlistings -->
<!-- clear floated content -->
<div class="CWclear"></div>
<!--- recently viewed products --->
<cfinclude template="cwapp/inc/cw-inc-recentview.cfm">
<!--- page end / debug --->
<cfinclude template="cwapp/inc/cw-inc-pageend.cfm">