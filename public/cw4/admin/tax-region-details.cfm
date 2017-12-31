<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: tax-region-details.cfm
File Date: 2012-02-01
Description: Manage Tax Region Details
==========================================================
NOTE: tax_region_tax_id has no visible input, not used for default CW display,
but is available if a specific site modification requires it.
The taxID on invoices can be controlled via global Tax Settings
--->
<!--- GLOBAL INCLUDES --->
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("merchant,developer")>
<!--- PAGE PARAMS --->
<cfparam name="url.tax_region_id" type="numeric" default="0">
<cfparam name="request.cwpage.currentRecord" default="#url.tax_region_id#">
<cfparam name="url.sortby" type="string" default="tax_group_name">
<cfparam name="url.sortdir" type="string" default="asc">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("view,userconfirm,useralert,clickadd,sortby,sortdir")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- QUERY: Get tax region (active/archived, region ID)--->
<cfset taxRegionQuery = CWquerySelectTaxRegions(request.cwpage.currentrecord)>
<cfset request.cwpage.currentGroup = taxRegionQuery.tax_group_id>
<cfset request.cwpage.regionname = taxRegionQuery.tax_region_label>
<!--- set up form params --->
<cfif taxRegionQuery.RecordCount>
	<!--- Set default form variables --->
	<cfparam name="form.tax_region_label" default="#taxRegionQuery.tax_region_label#">
	<cfparam name="form.tax_region_tax_id" default="#taxRegionQuery.tax_region_tax_id#">
	<cfif taxRegionQuery.tax_region_ship_tax_method eq "Tax Group">
		<cfparam name="form.shippingTax" default="#taxRegionQuery.tax_region_ship_tax_group_id#">
	<cfelse>
		<cfparam name="form.shippingTax" default="#taxRegionQuery.tax_region_ship_tax_method#">
	</cfif>
</cfif>
<!--- QUERY: Get tax groups (id (none))--->
<cfset taxGroupsQueryAll = CWquerySelectTaxGroupDetails(0)>
<!--- QUERY: Get tax rates by region (region ID)--->
<cfset taxRatesQuery = CWquerySelectTaxGroupRates(request.cwpage.currentrecord)>
<!--- make query sortable --->
<cfset taxRatesQuery = CWsortableQuery(taxRatesQuery)>
<!--- set up the existing groups --->
<cfset request.cwpage.currentGroups = valueList(taxRatesQuery.tax_group_id)>
<cfif NOT len(trim(request.cwpage.currentGroups))>
	<cfset request.cwpage.currentGroups = 0>
</cfif>
<!--- QUERY: Get available tax groups not already in use (id (none), list to omit)--->
<cfset taxGroupsQuery = CWquerySelectTaxGroupDetails(0,'#request.cwpage.currentGroups#')>
<!--- /////// --->
<!--- UPDATE TAX REGION --->
<!--- /////// --->
<cfif isDefined('form.tax_region_label') and len(trim(form.tax_region_label)) and isDefined('form.TaxID')>
	<cfif IsNumeric(form.shippingTax)>
		<!--- Shipping based on tax group --->
		<cfset insertTaxMethod = "Tax Group">
		<cfset insertTaxGroup = form.shippingTax>
	<cfelse>
		<cfset insertTaxMethod = form.shippingTax>
		<cfset insertTaxGroup = 0>
	</cfif>
	<cfparam name="form.tax_region_show_id" default="0">
	<!--- QUERY: update tax region (region ID, tax label, tax ID, show tax ID y/n, tax method, tax group ID) --->
	<cfset updateTaxRegionID = CWqueryUpdateTaxRegion(
	request.cwpage.currentrecord,
	form.tax_region_label,
	form.tax_region_tax_id,
	form.tax_region_show_id,
	insertTaxMethod,
	insertTaxGroup
	)>
	<cfif not left(updateTaxRegionID,2) eq '0-'>
		<!--- update complete: return to page showing message --->
		<cfset CWpageMessage("confirm","#application.cw.taxSystemLabel# Region Name Saved")>
		<cflocation url="#request.cwpage.baseUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&sortby=#url.sortby#&sortdir=#url.sortdir#" addtoken="no">
		<!--- if we have an insert error, show message, do not insert --->
	<cfelse>
		<cfset CWpageMessage("alert",listLast(updateTaxRegionID,'-'))>
	</cfif>
	<!--- /END duplicate/error check --->
</cfif>
<!--- /////// --->
<!--- /END UPDATE TAX REGION --->
<!--- /////// --->
<!--- /////// --->
<!--- DELETE TAX REGION --->
<!--- /////// --->
<cfif isDefined('url.deleter') and isNumeric(url.deleter)>
	<cfparam name="url.returnurl" type="string" default="tax-regions.cfm?useralert=#CWurlSafe('Region Deleted')#">
	<!--- QUERY: delete customer record (id from url)--->
	<cfset deleteRegion = CWqueryDeleteTaxRegion(record_id=url.deleter)>
	<cflocation url="#url.returnurl#" addtoken="No">
</cfif>
<!--- /////// --->
<!--- /END DELETE TAX REGION --->
<!--- /////// --->
<!--- /////// --->
<!--- INSERT TAX RATE --->
<!--- /////// --->
<cfif isDefined('form.tax_group_id') and isNumeric(form.tax_group_id)>
	<!--- QUERY: insert new tax rage (region ID, group ID, tax rate)  --->
	<cfset insertTaxRateID = CWqueryInsertTaxRate(request.cwpage.currentrecord,form.tax_group_id,form.taxRate)>
	<!--- insert complete: return to page showing message --->
	<cfset CWpageMessage("confirm","1 #application.cw.taxSystemLabel# Rate Added")>
	<cflocation url="#request.cwpage.baseUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&sortby=#url.sortby#&sortdir=#url.sortdir#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END INSERT TAX RATE --->
<!--- /////// --->
<!--- /////// --->
<!--- UPDATE / DELETE TAX RATES --->
<!--- /////// --->
<!--- look for at least one valid ID field --->
<cfif isDefined('form.tax_rate_id1')>
	<cfparam name="form.deleteRecord" default="0">
	<cfset loopCt = 1>
	<cfset updateCt = 0>
	<cfset deleteCt = 0>
	<!--- loop record ids, handle each one as needed --->
	<cfloop list="#form.recordIDlist#" index="ID">
		<!--- DELETE RECORDS --->
		<!--- if the record ID is marked for deletion --->
		<cfif listFind(form.deleteRecord,evaluate('form.tax_rate_id'&loopCt))>
			<!--- QUERY: delete record (record id) --->
			<cfset deleteRecord = CWqueryDeleteTaxRate(id)>
			<cfset deleteCt = deleteCt + 1>
			<!--- if not deleting, update --->
		<cfelse>
			<!--- UPDATE RECORDS --->
			<!--- param for checkbox values --->
			<cfparam name="form.taxRate#loopct#" default="0">
			<!--- verify numeric tax region ID --->
			<cfif NOT isNumeric(#form["taxrate#loopct#"]#)>
				<cfset #form["taxrate#loopct#"]# = 0>
			</cfif>
			<!--- QUERY: update record (ID, percentage ) --->
			<cfset updateRecord = CWqueryUpdateTaxRate(#form["tax_rate_id#loopct#"]#,#form["taxrate#loopct#"]#)>
			<cfset updateCt = updateCt + 1>
			<!--- /END delete vs. update --->
		</cfif>
		<cfset loopCt = loopCt + 1>
	</cfloop>
	<!--- get the vars to keep by omitting the ones we don't want repeated --->
	<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert")>
	<!--- set up the base url --->
	<cfset request.cwpage.relocateUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
	<!--- save confirmation text --->
	<cfset CWpageMessage("confirm","Changes Saved")>
	<!--- save alert text --->
	<cfsavecontent variable="request.cwpage.userAlertText">
	<cfif deleteCt gt 0><cfoutput>#deleteCt# Record<cfif deleteCt gt 1>s</cfif> Deleted</cfoutput></cfif>
	</cfsavecontent>
	<cfset CWpageMessage("alert",request.cwpage.userAlertText)>
	<!--- return to page as submitted, clearing form scope --->
	<cflocation url="#request.cwpage.relocateUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END UPDATE / DELETE TAX RATES --->
<!--- /////// --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Manage #application.cw.taxSystemLabel# Region">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Manage #application.cw.taxSystemLabel# Region: #request.cwpage.regionname#">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 =  "Assign #application.cw.taxSystemLabel# Regions and manage #application.cw.taxSystemLabel# Rates">
<!--- current menu marker --->
<cfset request.cwpage.currentNav = "tax-regions.cfm">
<!--- load form scripts --->
<cfset request.cwpage.isFormPage = 1>
<!--- load table scripts --->
<cfset request.cwpage.isTablePage = 1>
</cfsilent>
<!--- START OUTPUT --->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head>
		<cfoutput>
		<title>#application.cw.companyName# : #request.cwpage.title#</title>
		</cfoutput>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<!-- admin styles -->
		<link href="css/cw-layout.css" rel="stylesheet" type="text/css">
		<link href="theme/<cfoutput>#application.cw.adminThemeDirectory#</cfoutput>/cw-admin-theme.css" rel="stylesheet" type="text/css">
		<!-- admin javascript -->
		<cfinclude template="cwadminapp/inc/cw-inc-admin-scripts.cfm">
	</head>
	<!--- body gets a class to match the filename --->
	<body <cfoutput>class="#listFirst(request.cw.thisPage, '.')#"</cfoutput>>
		<div id="CWadminWrapper">
			<!-- Navigation Area -->
			<div id="CWadminNav">
				<div class="CWinner">
					<cfinclude template="cwadminapp/inc/cw-inc-admin-nav.cfm">
				</div>
				<!-- /end CWinner -->
			</div>
			<!-- /end CWadminNav -->
			<!-- Main Content Area -->
			<div id="CWadminPage">
				<!-- inside div to provide padding -->
				<div class="CWinner">
					<!--- page start content / dashboard --->
					<cfinclude template="cwadminapp/inc/cw-inc-admin-page-start.cfm">
					<cfif len(trim(request.cwpage.heading1))><cfoutput><h1>#trim(request.cwpage.heading1)#</h1></cfoutput></cfif>
					<cfif len(trim(request.cwpage.heading2))><cfoutput><h2>#trim(request.cwpage.heading2)#</h2></cfoutput></cfif>
					<!-- Admin Alert - message shown to user -->
					<cfinclude template="cwadminapp/inc/cw-inc-admin-alerts.cfm">
					<!-- Page Content Area -->
					<div id="CWadminContent">
						<!-- //// PAGE CONTENT ////  -->
						<!--- if a valid record is not found --->
						<cfif not taxRegionQuery.recordCount is 1>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>Invalid <cfoutput>#application.cw.taxSystemLabel#</cfoutput> region id. Please return to the <a href="tax-regions.cfm"><cfoutput>#application.cw.taxSystemLabel#</cfoutput> Region Listing</a> and choose a valid #lcase(application.cw.taxSystemLabel)# region.</p>
							<!--- if a record is found --->
						<cfelse>
							<!--- /////// --->
							<!--- UPDATE TAX REGION --->
							<!--- /////// --->
							<!--- FORM --->
							<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" class="CWvalidate CWobserve" name="updateTaxRegionForm" id="updateTaxRegionForm" method="post">
								<p>&nbsp;</p>
								<h3>Edit <cfoutput>#lcase(application.cw.taxSystemLabel)#</cfoutput> Region Details</h3>
								<table class="CWinfoTable CWformTable">
									<tbody>
									<tr>
										<th class="label"><cfoutput>#application.cw.taxSystemLabel#</cfoutput> Label</th>
										<td><input name="tax_region_label" class="required" title="Tax Label is required" type="text" id="tax_region_label" size="30" value="<cfoutput>#form.tax_region_label#</cfoutput>" onblur="checkValue(this)"></td>
									</tr>
									<tr>
										<th class="label">Shipping <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Method</th>
										<td>
											<select name="ShippingTax" id="ShippingTax">
												<option value="No Tax"<cfif form.shippingTax eq "No Tax"> selected="selected"</cfif>>No <cfoutput>#lcase(application.cw.taxSystemLabel)#</cfoutput> on shipping</option>
												<option value="Highest Item Taxed" <cfif form.shippingTax eq "Highest Item Taxed"> selected="selected"</cfif>>Use Highest <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Rate applied to any item in the order</option>
												<optgroup label="Based on a <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Group">
												<cfoutput query="taxGroupsQueryAll">
													<cfif not taxgroupsqueryall.tax_group_archive eq 1>
													<option value="#taxGroupsQueryAll.tax_group_id#"<cfif FORM.ShippingTax eq taxGroupsQueryAll.tax_group_id> selected="selected"</cfif>>#taxGroupsQueryAll.tax_group_name#</option>
													</cfif>
												</cfoutput>
												</optgroup>
											</select>
										</td>
									</tr>
									<tr>
										<td colspan="2" style="text-align:center">
											<!--- submit button --->
											<input name="SubmitAdd" type="submit" class="CWformButton" id="SubmitAdd" value="Save Changes">
											<!--- hidden taxid - can be turned into a live input if needed --->
											<input type="hidden" value="<cfoutput>#form.tax_region_tax_id#</cfoutput>" name="taxID">
											<!--- delete link--->
										<cfif taxRatesQuery.recordCount eq 0>
											<cfoutput><a class="CWbuttonLink deleteButton" onclick="return confirm('Delete Tax Region #cwStringFormat(form.tax_region_label)#?')" href="tax-region-details.cfm?deleteR=#url.tax_region_id#&returnUrl=#urlEncodedFormat('tax-regions.cfm?userconfirm=Region Deleted')#">Delete Region</a></cfoutput>
										<cfelse>
											<p><br>(Delete all tax rates below before deleting this region)</p>
										</cfif>
										</td>
									</tr>
									</tbody>
								</table>
							</form>
							<!--- /////// --->
							<!--- /END UPDATE TAX REGION --->
							<!--- /////// --->
							<!--- /////// --->
							<!--- ADD NEW TAX RATE --->
							<!--- /////// --->
							<!--- FORM --->
							<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" name="addNewForm" id="addNewForm" method="post">
								<p>&nbsp;</p>
								<h3>Add New <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Rate</h3>
								<!--- verify tax regions exist --->
								<cfif NOT taxGroupsQuery.recordCount>
									<p>&nbsp;</p>
									<p>Create at least one active <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Group to add a new <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Rate</p>
								<cfelse>
									<table class="CWinfoTable">
										<thead>
										<tr>
											<th>Available <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Groups</th>
											<th><cfoutput>#application.cw.taxSystemLabel#</cfoutput> Rate</th>
										</tr>
										</thead>
										<tbody>
										<tr>
											<!--- tax group selection --->
											<td>
												<select name="tax_group_id">
													<cfoutput query="taxGroupsQuery">
													<option value="#taxgroupsQuery.tax_group_id#">#taxGroupsQuery.tax_group_name#</option>
													</cfoutput>
												</select>
												<br>
												<input name="SubmitAddTaxRate" type="submit" class="submitButton" id="SubmitAddTaxRegion" value="Save New <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Rate" onblur="checkValue(this)">
											</td>
											<!--- rate --->
											<td><input name="taxRate" type="text" id="taxRate" size="6" maxlength="10" value="0.00" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">%</td>
										</tr>
										</tbody>
									</table>
									<p><a href="tax-groups.cfm">Add New <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Group</a></p>
									<p>&nbsp;</p>
							</cfif>
							<!--- / end verify tax regions exist --->
					</form>
					<!--- /////// --->
					<!--- /END ADD NEW TAX RATE--->
					<!--- /////// --->
					<!--- /////// --->
					<!--- UPDATE TAX RATES --->
					<!--- /////// --->
					<p>&nbsp;</p>
					<h3>Active <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Rates</h3>
					<!--- check for existing records --->
					<cfif NOT taxRatesQuery.recordCount>
						<p>&nbsp;</p>
						<p>There are currently no <cfoutput>#lcase(application.cw.taxSystemLabel)#</cfoutput> rates defined for this <cfoutput>#lcase(application.cw.taxSystemLabel)#</cfoutput> region</p>
						<!--- if existing records found --->
					<cfelse>
						<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" name="recordForm" id="recordForm" method="post" class="CWobserve">
							<table class="CWsort CWstripe CWinfoTable wide" summary="<cfoutput>
								#request.cwpage.baseUrl#</cfoutput>">
								<thead>
								<tr class="sortRow">
									<th class="tax_group_name">Name</th>
									<th class="tax_rate_percentage" style="text-align:center"><cfoutput>#application.cw.taxSystemLabel#</cfoutput> Rate </th>
									<th width="85" style="text-align:center">
										<input type="checkbox" class="checkAll" name="checkAllDelete" rel="checkAllDel">Delete
									</th>
								</tr>
								</thead>
								<tbody>
								<cfoutput query="taxRatesQuery">
								<tr>
									<!--- name --->
									<td>
										<a href="tax-group-details.cfm?tax_group_id=#taxratesQuery.tax_group_id#" class="detailsLink" title="Manage #application.cw.taxSystemLabel# Group details">
										#taxRatesQuery.tax_group_name#
										</a>
									</td>
									<!--- rate --->
									<td>
										<input name="TaxRate#CurrentRow#" type="text" id="TaxRate#CurrentRow#" value="#taxRatesQuery.tax_rate_percentage#" size="5" maxlength="6" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
										%
									</td>
									<!--- delete --->
									<td style="text-align:center;">
										<input name="deleteRecord" type="checkbox" class="formCheckbox checkAllDel" value="#taxRatesQuery.tax_rate_id#">
										<input type="hidden" name="tax_rate_id#CurrentRow#" value="#taxRatesQuery.tax_rate_id#">
										<input name="recordIDlist" type="hidden" value="#taxratesQuery.tax_rate_id#">
									</td>
								</tr>
								</cfoutput>
								</tbody>
							</table>
							<input name="SubmitUpdate" type="submit" class="submitButton" id="UpdateTaxRates" value="Save Changes">
							<input type="hidden" value="<cfoutput>#taxRatesQuery.RecordCount#</cfoutput>" name="ratesCounter">
						</form>
					</cfif>
					<!--- /end check for existing records --->
					<!--- /////// --->
					<!--- /END UPDATE TAX RATES --->
					<!--- /////// --->
			</cfif>
			<!--- /end valid record --->
	</div>
	<!-- /end Page Content -->
	<div class="clear"></div>
</div>
<!-- /end CWinner -->
</div>
<!--- page end content / debug --->
<cfinclude template="cwadminapp/inc/cw-inc-admin-page-end.cfm">
<!-- /end CWadminPage-->
<div class="clear"></div>
</div>
<!-- /end CWadminWrapper -->
</body>
</html>