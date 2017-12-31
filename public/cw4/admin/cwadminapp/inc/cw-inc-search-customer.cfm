<cfsilent> 
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-search-customer.cfm
File Date: 2012-12-13
Description: Search form for admin customer records
==========================================================
--->
<!--- defaults for sorting --->
<cfparam name="request.sortBy" default="custName">
<cfparam name="request.sortDir" default="ASC">
<!--- defaults for form post (url params are in containing page)--->
<cfparam name="form.custName" default="#url.custname#">
<cfparam name="form.custID" default="#url.custid#">
<cfparam name="form.custEmail" default="#url.custemail#">
<cfparam name="form.custAddr" default="#url.custaddr#">
<cfparam name="form.orderStr" default="#url.orderstr#">
<cfparam name="url.custtype" default="0">	
<cfparam name="form.custType" default="#url.custtype#">
<!--- use session if not defined in url --->
<cfif isDefined('session.cw.customerSortBy') AND NOT isDefined('url.sortby')>
	<cfset request.sortBy = session.cw.customerSortBy>
	<cfset url.sortby = session.cw.customerSortBy>
<cfelseif isDefined('url.sortby')>
	<cfset request.sortBy = url.sortby>
</cfif>
<cfif isDefined('session.cw.customerSortDir') AND NOT isDefined('url.sortdir')>
	<cfset request.sortDir = session.cw.customerSortDir>
	<cfset url.sortdir = session.cw.customerSortDir>
<cfelseif isDefined('url.sortdir')>
	<cfset request.sortDir = url.sortdir>
</cfif>
<!--- put new values in session for next time --->
<cfset session.cw.customerSortBy = request.sortBy>
<cfset session.cw.customerSortDir = request.sortDir>
<!--- QUERY: search customers (search form vars) --->
<cfset customersQuery = CWquerySelectCustomers(
		form.custName,
		form.custID,
		form.custEmail,
		form.custAddr,
		form.orderStr,
		0,
		form.custType
)>

<!--- if only one record found, go to customer details --->
<cfif customersQuery.recordCount eq 1 and request.cw.thisPage is not 'customer-details.cfm'>
	<cfset CWpageMessage("confirm","1 Customer Found: details below")>
	<cflocation url="customer-details.cfm?customer_id=#customersQuery.customer_id#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&search=Search" addtoken="no">
</cfif>

<!--- QUERY: get customer types --->
<cfset customerTypesQuery = CWquerySelectCustomerTypes()>

</cfsilent>
<!--- // SHOW FORM // --->
<form name="formCustomerSearch" id="formCustomerSearch" method="get" action="customers.cfm">
	<span style="line-height:1em;" class="pushRight"><strong>Search Customers&nbsp;&raquo;</strong><a id="showSearchFormLink" href="#">Search Customers</a></span>
	<label for="searchCustName" style="padding-left:20px;">Name:</label>
	<input name="custName" type="text" value="<cfoutput>#form.custName#</cfoutput>" size="13" id="searchCustName">
	<label for="custID">&nbsp;&nbsp;ID:</label>
	<input name="custID" id="custID" type="text" value="<cfoutput>#form.custID#</cfoutput>" size="12" id="searchCustID">
	<span class="advanced">
		<label for="custEmail">&nbsp;&nbsp;Email:</label>
		<input name="custEmail" id="custEmail" type="text" value="<cfoutput>#form.custEmail#</cfoutput>" size="12" id="searchCustEmail">
	</span>
	&nbsp;&nbsp;<input name="search" type="submit" class="CWformButton" id="Search" value="Search" style="margin-bottom: 2px;">
	<div class="subForm advanced">
		<span class="pushRight"><cfif listLen(cgi.QUERY_STRING,'&') gt 2><a href="<cfoutput>#request.cw.thisPage#</cfoutput>?search=Search<cfif isDefined('url.customer_id')><cfoutput>&customer_id=#url.customer_id#</cfoutput></cfif>">Reset Search</a><cfelse>&nbsp;</cfif></span>
		<label for="searchCustAddr" style="padding-left:23px;">Address:</label>
		<input name="custAddr" id="searchCustAddr" type="text" size="8" value="<cfoutput>#form.custAddr#</cfoutput>">&nbsp;&nbsp;&nbsp;
		<label for="searchOrderStr">Order ID:</label>
		<input name="orderStr" id="searchOrderStr" type="text" size="8" value="<cfif not form.orderStr is '%'><cfoutput>#form.orderStr#</cfoutput></cfif>">&nbsp;&nbsp;&nbsp;
		<label for="searchCustType">Type:</label>
		<select name="custType" id="searchCustType">
			<option value="0" <cfif form.custType is 0>selected</cfif>>Any</option>
			<cfoutput query="customerTypesQuery">
			<option value="#customerTypesQuery.customer_type_id#"<cfif customerTypesQuery.customer_type_id eq form.custType>selected="selected"</cfif>>#customerTypesQuery.customer_type_name#</option>
			</cfoutput>			
		</select>
		<!--- rows per page --->
		<cfif application.cw.adminCustomerPaging>
			<label for="maxRows">&nbsp;Per Page:</label>
			<select name="maxRows" id="maxRows">
				<cfoutput>
				<cfloop from="10" to="100" step="10" index="mm">
					<option value="#mm#"<cfif mm eq url.maxrows> selected="selected"</cfif>>#mm#</option>
				</cfloop>
				</cfoutput>
			</select>
		</cfif>
	</div>
</form>
<cfsilent>
<!--- Set Variables for recordset Paging  --->
<cfset MaxRows_Results= url.maxrows>
<cfset StartRow_Results=Min((pagenumresults-1)*MaxRows_Results+1,Max(customersQuery.RecordCount,1))>
<cfset EndRow_Results=Min(StartRow_Results+MaxRows_Results-1,customersQuery.RecordCount)>
<cfset TotalPages_Results=Ceiling(customersQuery.RecordCount/MaxRows_Results)>
<!--- SERIALIZE --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("pagenumresults,userconfirm,useralert")>
<cfset pagingUrl = CWserializeUrl(varsToKeep)>
<cfif application.cw.adminCustomerPaging>
	<cfsavecontent variable="request.cwpage.pagingLinks">
	<span class="pagingLinks">
		Page <cfoutput>#pagenumresults#</cfoutput> of <cfoutput>#TotalPages_Results#</cfoutput>
		&nbsp;[Showing <cfoutput>#customersQuery.RecordCount#</cfoutput> Customer<cfif customersQuery.RecordCount neq 1>s</cfif>]<br>
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
		[Showing <cfoutput>#customersQuery.RecordCount#</cfoutput> Customer<cfif customersQuery.RecordCount neq 1>s</cfif>]<br>
	</span>
	</cfsavecontent>
</cfif>
</cfsilent>