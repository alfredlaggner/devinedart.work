<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-widget-search-products.cfm
File Date: 2012-02-01
Description:
Displays basic product search form on admin home page
==========================================================
--->
<!--- get all cats and subcats --->
<!--- QUERY: get all active categories --->
<cfset listActiveCats = CWquerySelectActiveCategories()>
<!--- QUERY: get all active secondary categories --->
</cfsilent>
<div class="CWadminHomeSearch">
	<!--- // SHOW FORM // --->
	<form name="formProductSearch" method="get" action="products.cfm" id="formProductSearch">
		<input name="Search" type="submit" class="CWformButton" id="Search" value="Search">
		<label for="Find">Keyword:</label>
		<input name="Find" type="text" size="12" id="Find" value="" class="focusField">
		<label for="searchBy">Search In:</label>
		<select name="searchBy" id="searchBy">
			<option value="any">All Fields</option>
			<option value="prodID">Product ID</option>
			<option value="prodName">Product Name</option>
			<option value="descrip">Description</option>
		</select>
		<!--- categories --->
		<cfif listActiveCats.recordCount gt 1>
			<label for="searchC"><cfoutput>#application.cw.adminLabelCategory#</cfoutput>:</label>
			<select name="searchC" id="searchC" onkeyup="this.change();">
				<option value="">All</option>
				<cfoutput query="listActiveCats">
				<option value="#category_id#">#left(category_name,15)#</option>
				</cfoutput>
			</select>
		<cfelse>
			<input type="hidden" name="searchC" value="">
		</cfif>
	</form>
</div>