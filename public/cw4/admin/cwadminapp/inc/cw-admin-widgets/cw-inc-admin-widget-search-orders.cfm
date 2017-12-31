<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-widget-search-orders.cfm
File Date: 2012-02-01
Description:
Displays basic orders search form on admin home page
==========================================================
--->
<!--- QUERY: get all possible order status types --->
<cfset orderStatusQuery = CWquerySelectOrderStatus()>
</cfsilent>
<div class="CWadminHomeSearch">
	<!--- // SHOW FORM // --->
	<form name="formOrderSearch" id="formOrderSearch" method="get" action="orders.cfm">
		<input name="Search" type="submit" class="CWformButton" id="Search" value="Search" style="margin-bottom: 2px;">
		<label for="orderStr">Order ID:</label>
		<input name="orderStr" id="orderStr" type="text" size="10" value="">
		<label for="selectStartDate" style="padding-left:23px;">From:</label>
		<input name="startDate" type="text" class="date_input_past" value="<cfoutput>#LSdateFormat(DateAdd("m",-1,CWtime()),request.cw.scriptdatemask)#</cfoutput>" size="10" id="selectStartDate">
		<label for="selectEndDate">To:</label>
		<input name="endDate" type="text" class="date_input_past" value="<cfoutput>#LSdateFormat(CWtime(),request.cw.scriptdatemask)#</cfoutput>" size="10" id="selectEndDate">
		<label for="status">Status:</label>
		<select name="Status" id="status">
			<option value="0">Any</option>
			<cfoutput query="orderStatusQuery">
			<option value="#orderStatusQuery.shipstatus_id#">#orderStatusQuery.shipstatus_name#</option>
			</cfoutput>
		</select>
	</form>
</div>

