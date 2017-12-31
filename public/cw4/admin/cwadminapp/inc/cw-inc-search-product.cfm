<cfsilent> 
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-search-product.cfm
File Date: 2012-12-13
Description: Search form for product listings
==========================================================
--->
<!--- defaults for sorting --->
<cfparam name="request.sortBy" default="product_name">
<cfparam name="request.sortDir" default="ASC">
<!--- use session if not defined in url --->
<cfif isDefined('session.cwclient.cwProductSortBy') AND NOT isDefined('url.sortby')>
	<cfset request.sortBy = session.cwclient.cwProductSortBy>
	<cfset url.sortby = session.cwclient.cwProductSortBy>
<cfelseif isDefined('url.sortby') AND NOT isDefined('url.productid')>
	<cfset request.sortBy = url.sortby>
</cfif>
<cfif isDefined('session.cwclient.cwProductSortDir') AND NOT isDefined('url.sortdir')>
	<cfset request.sortDir = session.cwclient.cwProductSortDir>
	<cfset url.sortdir = session.cwclient.cwProductSortDir>
<cfelseif isDefined('url.sortdir') AND NOT isDefined('url.productid')>
	<cfset request.sortDir = url.sortdir>
</cfif>
<!--- put new values in session for next time --->
<cfset session.cwclient.cwProductSortBy = request.sortBy>
<cfset session.cwclient.cwProductSortDir = request.sortDir>
<!--- default for field to search --->
<cfparam name="url.searchby" type="string" default="">
<cfparam name="url.find" type="string" default="">
<!--- defaults for secondary categories based on top level category --->
<cfparam name="filterCat" type="numeric" default="0">
<cfparam name="filterScndCat" type="numeric" default="0">
<cfif isDefined('url.searchc') AND url.searchc gt 0>
	<cfset filterCat = url.searchc>
</cfif>
<cfif isDefined('url.searchsc') AND url.searchsc gt 0>
	<cfset filterScndCat = url.searchsc>
</cfif>
<!--- archive vs active --->
<cfif isDefined('request.cwpage.viewProdType') and request.cwpage.viewProdType contains 'arch'>
	<cfset searchArchived = 1>
<cfelse>
	<cfset searchArchived = 0>
</cfif>
<!--- default search string (all/any) --->
<cfparam name="QueryFind" default="%">
<!--- get all cats and subcats --->
<!--- QUERY: get all active categories --->
<cfset listActiveCats = CWquerySelectActiveCategories()>
<!--- QUERY: get all active secondary categories --->
<cfset listActiveScndCats = CWquerySelectActiveScndCategories(filterCat)>
<cfif url.find neq "">
	<!--- make search string case insensitive --->
	<cfset QueryFind = lcase(url.find)>
</cfif>
<!--- QUERY: search products (product search form vars) --->
<cfset productsQuery = CWquerySearchProducts(queryFind,
url.searchby,
filterCat,
filterScndCat,
request.sortBy,
request.sortDir,
searchArchived
)>
<!--- if only one record found, go to productForm --->
<cfif searchArchived eq 0 and productsQuery.recordCount eq 1 and ((queryFind neq '%' and queryFind neq '') OR filterCat gt 0 OR filterScndCat gt 0) and url.search eq 'search' and request.cw.thisPage is not 'product-details.cfm'>
	<cfset CWpageMessage("confirm","1 Product Found: details below")>
	<cflocation url="product-details.cfm?productid=#productsQuery.product_id#&searchby=#url.searchby#&searchC=#url.searchc#&searchSC=#url.searchsc#&find=#CWurlSafe(url.find)#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
</cfif>
</cfsilent>
<!--- // SHOW FORM // --->
<form name="formProductSearch" id="formProductSearch" method="get" action="products.cfm">
	<span style="line-height:1em;" class="pushRight"><strong>Search Products&nbsp;&raquo;</strong><a id="showSearchFormLink" href="#">Search Products</a></span>
	<label for="Find">&nbsp;Keyword:</label>
	<input name="Find" type="text" size="15" id="Find" value="<cfoutput>#url.find#</cfoutput>">
	<label for="searchBy">&nbsp;Search In:</label>
	<select name="searchBy" id="searchBy">
		<option value="any" <cfif url.searchby eq "any">selected</cfif>>All Fields</option>
		<option value="prodID" <cfif url.searchby eq "prodID">selected</cfif>>Product ID</option>
		<option value="prodName" <cfif url.searchby eq "prodName">selected</cfif>>Product Name</option>
		<option value="descrip" <cfif url.searchby eq "descrip">selected</cfif>>Description</option>
	</select>
	<span class="advanced">
		<cfif application.cw.adminProductPaging>
			<!--- rows per page --->
			<label for="maxRows">&nbsp;Per Page:</label>
			<select name="maxRows" id="maxRows">
				<cfoutput>
				<cfloop from="10" to="100" step="10" index="mm">
					<option value="#mm#"<cfif mm eq url.maxrows> selected="selected"</cfif>>#mm#</option>
				</cfloop>
				</cfoutput>
			</select>
		</cfif>
	</span>
	&nbsp;&nbsp;<input name="search" type="submit" class="CWformButton" id="Search" value="Search" style="margin-bottom: 2px;">
	<div class="subForm advanced">
		<cfif listActiveCats.recordCount gt 1 OR listActiveScndCats.recordCount gt 1>
			<span class="pushRight"><cfif listLen(cgi.QUERY_STRING,'&')><a href="<cfoutput>#request.cw.thisPage#?view=#url.view#&search=Search<cfif isDefined('url.productid')>&productid=#url.productid#</cfif></cfoutput>">Reset Search</a><cfelse>&nbsp;</cfif></span>
		</cfif>
		<!--- categories --->
		<cfif listActiveCats.recordCount gt 1>
			<label for="searchC"><cfoutput>#listFirst(application.cw.adminLabelCategory, ' ')#</cfoutput>:</label>
			<select name="searchC" id="searchC" onkeyup="this.change();" onchange="searchSelect(this);">
				<option value="">All</option>
				<cfoutput query="listActiveCats">
				<option value="#category_id#"<cfif url.searchc eq category_id> selected</cfif>>#left(category_name,15)#</option>
				</cfoutput>
			</select>
		<cfelse>
			<input type="hidden" name="searchC" value="">
		</cfif>
		<!--- subcategories --->
		<cfif listActiveScndCats.recordCount gt 1>
			&nbsp;	<label for="searchSC"><cfoutput>#listFirst(application.cw.adminLabelSecondary, ' ')#</cfoutput>:</label>
			<select name="searchSC" id="searchSC" onkeyup="this.change();" onchange="searchSelect(this);">
				<option value="">All</option>
				<cfoutput query="listActiveScndCats">
				<option value="#secondary_id#"<cfif url.searchsc eq secondary_id> selected</cfif>>#left(secondary_name,15)#</option>
				</cfoutput>
			</select>
		<cfelse>
			<input type="hidden" name="searchSC" value="">
		</cfif>
		<label for="view">Status:</label>
		<select name="view" id="view">
			<option value="active"<cfif not url.view contains 'arch'>selected="selected"</cfif>>Active</option>
			<option value="arch" <cfif url.view contains 'arch'>selected="selected"</cfif>>Archived</option>
		</select>
	</div>
</form>
<cfsilent>
<!--- Set Variables for recordset Paging  --->
<cfset MaxRows_Results= url.maxrows>
<cfset StartRow_Results=Min((pagenumresults-1)*MaxRows_Results+1,Max(productsQuery.RecordCount,1))>
<cfset EndRow_Results=Min(StartRow_Results+MaxRows_Results-1,productsQuery.RecordCount)>
<cfset TotalPages_Results=Ceiling(productsQuery.RecordCount/MaxRows_Results)>
<!--- SERIALIZE --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("pagenumresults,userconfirm,useralert")>
<cfset pagingUrl = CWserializeUrl(varsToKeep)>
<cfif application.cw.adminProductPaging>
	<cfsavecontent variable="request.cwpage.pagingLinks">
	<span class="pagingLinks">
		Page <cfoutput>#pagenumresults#</cfoutput> of <cfoutput>#TotalPages_Results#</cfoutput>
		&nbsp;[Showing <cfoutput>#productsQuery.RecordCount#</cfoutput> Product<cfif productsQuery.RecordCount neq 1>s</cfif>]<br>
		<cfif totalPages_results gt 1>
			<cfif pagenumresults gt 1>
				<a href="<cfoutput>#request.cw.thisPage#?pagenumresults=1&#PagingUrl#</cfoutput>">First</a> | <a href="<cfoutput>#request.cw.thisPage#?pagenumresults=#Max(DecrementValue(pagenumresults),1)#</cfoutput>&<cfoutput>#PagingUrl#</cfoutput>">Previous</a>  |
			<cfelse>
				First | Previous |
			</cfif>
			<cfif pagenumresults LT TotalPages_Results>
				<a href="<cfoutput>#request.cw.thisPage#?pagenumresults=#Min(IncrementValue(pagenumresults),TotalPages_Results)#</cfoutput>&<cfoutput>#PagingUrl#</cfoutput>">Next</a> | <a href="<cfoutput>#request.cw.thisPage#?pagenumresults=#TotalPages_Results#</cfoutput>&<cfoutput>#PagingUrl#</cfoutput>">Last</a>
			<cfelse>
				Next | Last
			</cfif>
		</cfif>
	</span>
	</cfsavecontent>
<cfelse>
	<cfsavecontent variable="request.cwpage.pagingLinks">
	<span class="pagingLinks">
		[Showing <cfoutput>#productsQuery.RecordCount#</cfoutput> Product<cfif productsQuery.RecordCount neq 1>s</cfif>]<br>
	</span>
	</cfsavecontent>
</cfif>
</cfsilent>
<!--- Submit form if Subcat/Category select changed --->
<cfsavecontent variable="headcontent">
<script type="text/javascript">
function searchSelect(selBox){
 	if (jQuery('input#Find').val() == ''){
		jQuery(selBox).parents('form').submit();
		}
	};
</script>
</cfsavecontent>
<cfhtmlhead text="#headcontent#">