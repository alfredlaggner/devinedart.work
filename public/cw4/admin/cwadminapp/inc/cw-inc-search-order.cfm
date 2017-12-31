<cfsilent> 
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-search-order.cfm
File Date: 2012-12-13
Description: Search form for admin orders
==========================================================
--->
<!--- defaults for sorting --->
<cfparam name="request.sortBy" default="order_date">
<cfparam name="request.sortDir" default="DESC">
<!--- defaults for form post (url params are in containing page)--->

<!--- be sure dates are valid for locale --->
<cfset request.cwpage.orderDateMask = cwLocaleDateMask()>
<!--- parse url dates into global format, or use default dates --->
<cfif LSisDate(url.startDate)>
	<cfparam name="form.startDate" default="#LSdateFormat(lsParseDateTime(url.startdate),request.cwpage.orderDateMask)#">
<cfelse>
	<cfparam name="form.startDate" default="#LSdateFormat(DateAdd('m',-3,CWtime()),request.cwpage.orderDateMask)#">
</cfif>
<cfif LSisDate(url.enddate)>
	<cfparam name="form.endDate" default="#LSdateFormat(lsParseDateTime(url.enddate),request.cwpage.orderDateMask)#">
<cfelse>
	<cfparam name="form.endDate" default="#LSdateFormat(cwtime(),request.cwpage.orderDateMask)#">
</cfif>

<cfparam name="form.status" default="#url.status#" type="numeric">
<cfparam name="form.orderStr" default="#url.orderstr#">
<cfparam name="form.custName" default="#url.custname#">
<!--- use session if not defined in url --->
<cfif isDefined('session.cw.ordersortby') AND NOT isDefined('url.sortby')>
	<cfset request.sortBy = session.cw.ordersortby>
	<cfset url.sortby = session.cw.ordersortby>
<cfelseif isDefined('url.sortby')>
	<cfset request.sortBy = url.sortby>
</cfif>
<cfif isDefined('session.cw.ordersortdir') AND NOT isDefined('url.sortdir')>
	<cfset request.sortDir = session.cw.ordersortdir>
	<cfset url.sortdir = session.cw.ordersortdir>
<cfelseif isDefined('url.sortdir')>
	<cfset request.sortDir = url.sortdir>
</cfif>
<!--- put new values in session for next time --->
<cfset session.cw.ordersortby = request.sortBy>
<cfset session.cw.ordersortdir = request.sortDir>
<!--- QUERY: get all possible order status types --->
<cfset orderStatusQuery = CWquerySelectOrderStatus()>
<!--- QUERY: search orders (order search form vars) --->
<cfset ordersQuery = CWquerySelectOrders(form.status,form.startDate,form.endDate,form.orderStr,form.custName)>
<!--- if only one record found, go to order details --->
<cfif ordersQuery.recordCount eq 1 and request.cw.thisPage is not 'order-details.cfm'>
	<cfset CWpageMessage("confirm","1 Order Found: details below")>
	<cflocation url="order-details.cfm?order_id=#ordersQuery.order_id#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&search=Search" addtoken="no">
</cfif>
</cfsilent>
<!--- // SHOW FORM // --->
<form name="formOrderSearch" id="formOrderSearch" method="get" action="orders.cfm">
	<span style="line-height:1em;" class="pushRight"><strong>Search Orders&nbsp;&raquo;</strong><a id="showSearchFormLink" href="#">Search Orders</a></span>
	<label for="selectStartDate" style="padding-left:23px;">From:</label>
	<input name="startDate" type="text" class="date_input_past" value="<cfoutput>#LSdateFormat(form.startDate,request.cw.scriptDateMask)#</cfoutput>" size="10" id="selectStartDate">
	<label for="selectEndDate">&nbsp;&nbsp;To:</label>
	<input name="endDate" type="text" class="date_input_past" value="<cfoutput>#LSdateFormat(form.endDate,request.cw.scriptDateMask)#</cfoutput>" size="10" id="selectEndDate">
	<span class="advanced">
		<label for="status">&nbsp;&nbsp;Status:</label>
		<select name="Status" id="status">
			<option value="0" <cfif form.status is 0>selected</cfif>>Any</option>
			<cfoutput query="orderStatusQuery">
			<option value="#orderStatusQuery.shipstatus_id#"
			<cfif orderStatusQuery.shipstatus_id eq form.status>selected="selected"</cfif>>#orderStatusQuery.shipstatus_name#</option>
			</cfoutput>
		</select>
	</span>
	&nbsp;&nbsp;<input name="search" type="submit" class="CWformButton" id="Search" value="Search" style="margin-bottom: 2px;">
	<div class="subForm advanced">
		<span class="pushRight"><cfif listLen(cgi.QUERY_STRING,'&') gt 2><a href="<cfoutput>#request.cw.thisPage#</cfoutput>?search=Search">Reset Search</a><cfelse>&nbsp;</cfif></span>
		<label for="orderStr">Order ID:</label>
		<input name="orderStr" id="orderStr" type="text" size="15" value="<cfoutput>#form.orderStr#</cfoutput>">&nbsp;&nbsp;&nbsp;
		<label for="custName">Customer:</label>
		<input name="custName" id="custName" type="text" size="15" value="<cfoutput>#form.custName#</cfoutput>">
		<!--- rows per page --->
		<cfif application.cw.adminOrderPaging>
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
<cfset StartRow_Results=Min((pagenumresults-1)*MaxRows_Results+1,Max(ordersQuery.RecordCount,1))>
<cfset EndRow_Results=Min(StartRow_Results+MaxRows_Results-1,ordersQuery.RecordCount)>
<cfset TotalPages_Results=Ceiling(ordersQuery.RecordCount/MaxRows_Results)>
<!--- SERIALIZE --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("pagenumresults,userconfirm,useralert")>
<cfset pagingUrl = CWserializeUrl(varsToKeep)>
<cfif application.cw.adminOrderPaging>
	<cfsavecontent variable="request.cwpage.pagingLinks">
	<span class="pagingLinks">
		Page <cfoutput>#pagenumresults#</cfoutput> of <cfoutput>#TotalPages_Results#</cfoutput>
		&nbsp;[Showing <cfoutput>#ordersQuery.RecordCount#</cfoutput> Order<cfif ordersQuery.RecordCount neq 1>s</cfif>]<br>
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
		[Showing <cfoutput>#ordersQuery.RecordCount#</cfoutput> Order<cfif ordersQuery.RecordCount neq 1>s</cfif>]<br>
	</span>
	</cfsavecontent>
</cfif>
</cfsilent>