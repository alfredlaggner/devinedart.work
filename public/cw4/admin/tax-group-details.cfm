<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: tax-group-details.cfm
File Date: 2012-02-01
Description: Manage Tax Group Details
==========================================================
--->
<!--- GLOBAL INCLUDES --->
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("merchant,developer")>
<!--- PAGE PARAMS --->
<!--- default value for active or archived view--->
<cfparam name="url.view" type="string" default="active">
<cfparam name="url.tax_group_id" type="numeric" default="0">
<cfparam name="request.cwpage.currentRecord" type="numeric" default="#url.tax_group_id#">
<cfparam name="url.sortby" type="string" default="region_location">
<cfparam name="url.sortdir" type="string" default="asc">
<!--- default form values --->
<cfparam name="form.tax_group_name" type="string" default="">
<cfparam name="form.tax_group_code" type="string" default="">
<cfparam name="form.tax_region_id" type="string" default="">
<cfparam name="form.taxRate" type="string" default="">
<cfparam name="form.tateCount" type="string" default="">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("view,userconfirm,useralert,clickadd,sortby,sortdir")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- QUERY: Get tax group (active/archived, group ID)--->
<cfset taxGroupQuery = CWquerySelectTaxGroups(0,request.cwpage.currentrecord)>
<cfset request.cwpage.currentGroup = taxGroupQuery.tax_group_id>
<cfset request.cwpage.groupname = taxGroupQuery.tax_group_name>
<!--- QUERY: Get tax rates by region (group ID)--->
<cfset taxRatesQuery = CWquerySelectTaxRegionRates(request.cwpage.currentrecord)>
<!--- make query sortable --->
<cfset taxRatesQuery = CWsortableQuery(taxRatesQuery)>
<!--- set up the existing regions --->
<cfset request.cwpage.currentRegions = valueList(taxRatesQuery.tax_rate_region_id)>
<cfif NOT len(trim(request.cwpage.currentRegions))><cfset request.cwpage.currentRegions = 0></cfif>
<!--- QUERY: Get tax regions (id (none), list to omit)--->
<cfset taxRegionsQuery = CWquerySelectTaxRegions(0,'#request.cwpage.currentRegions#')>
<!--- /////// --->
<!--- UPDATE TAX GROUP --->
<!--- /////// --->
<cfif isDefined('form.tax_group_name') and len(trim(form.tax_group_name))>
	<!--- QUERY: update tax group (group id, archive y/n, tax group name, tax group code) --->
	<cfset updateTaxGroupID = CWqueryUpdateTaxGroup(request.cwpage.currentRecord,
													0,
													form.tax_group_name,
													form.tax_group_code
													)>
	<cfif not left(updateTaxGroupID,2) eq '0-'>
		<!--- update complete: return to page showing message --->
		<cfset CWpageMessage("confirm","#application.cw.taxSystemLabel# Group Saved")>
		<cflocation url="#request.cwpage.baseUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&sortby=#url.sortby#&sortdir=#url.sortdir#" addtoken="no">
		<!--- if we have an insert error, show message, do not insert --->
	<cfelse>
		<cfset dupField = listLast(updateTaxGroupID,'-')>
		<cfset CWpageMessage("alert","Error: #dupField# '#trim(form.tax_group_name)#' already exists")>
	</cfif>
	<!--- /END duplicate/error check --->
</cfif>
<!--- /////// --->
<!--- /END UPDATE TAX GROUP --->
<!--- /////// --->
<!--- /////// --->
<!--- INSERT TAX RATE --->
<!--- /////// --->
<cfif isDefined('form.tax_region_id') and isNumeric(form.tax_region_id)>
	<cfset insertTaxRateID = CWqueryInsertTaxRate(form.tax_region_id,request.cwpage.currentrecord,form.taxRate)>
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
	<cfparam name="form.deleteRecord" default="">
	<cfset loopCt = 1>
	<cfset updateCt = 0>
	<cfset deleteCt = 0>
	<cfset archiveCt = 0>
	<cfset activeCt = 0>
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
			<!--- verify numeric tax group ID --->
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
	<cfif deleteCt gt 0><cfoutput><cfif activeCt or archiveCt><br></cfif>#deleteCt# Record<cfif deleteCt gt 1>s</cfif> Deleted</cfoutput></cfif>
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
<cfset request.cwpage.title = "Manage #application.cw.taxSystemLabel# Group">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Manage #application.cw.taxSystemLabel# Group: #request.cwpage.groupname#">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 =  "Assign #application.cw.taxSystemLabel# Regions and manage #application.cw.taxSystemLabel# Rates">
<!--- current menu marker --->
<cfset request.cwpage.currentNav = "tax-groups.cfm">
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
						<!--- LINKS FOR VIEW OPTIONS --->
						<div class="CWadminControlWrap">
							<strong>
							<p><a href="tax-group-products.cfm?tax_group_id=<cfoutput>#request.cwpage.currentrecord#</cfoutput>">Associated Products</a> </p>
							</strong>
						</div>
						<!--- /END LINKS FOR VIEW OPTIONS --->
						<!--- if a valid record is not found --->
						<cfif not taxGroupQuery.recordCount is 1>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>Invalid #lcase(application.cw.taxSystemLabel)# group id. Please return to the <a href="tax-groups.cfm">#application.cw.taxSystemLabel# Group Listing</a> and choose a valid #lcase(application.cw.taxSystemLabel)# group.</p>
							<!--- if a record is found --->
						<cfelse>
							<!--- /////// --->
							<!--- UPDATE TAX GROUP --->
							<!--- /////// --->
							<!--- FORM --->
							<form action="<cfoutput>
								#request.cwpage.baseUrl#</cfoutput>" class="CWvalidate" name="updateTaxGroupForm" id="updateTaxGroupForm" method="post">
								<p>&nbsp;</p>
								<cfoutput><h3>Edit #application.cw.taxSystemLabel# Group</h3></cfoutput>
								<table class="CWinfoTable CWformTable">
									<thead>
									<tr>
										<th>Name</th>
										<th>Code</th>
									</tr>
									</thead>
									<tbody>
									<tr>
										<!--- name --->
										<td>
											<input name="tax_group_name" type="text" size="25" class="required" title="Group Name is required" id="tax_group_name" value="<cfoutput>#taxgroupquery.tax_group_name#</cfoutput>" onblur="checkValue(this)">
											<br>
											<!--- submit button --->
											<input name="SubmitAddTaxGroup" type="submit" class="submitButton" id="SubmitAddTaxGroup" value="Save Changes">
										</td>
										<!--- code --->
										<td>
											<input name="tax_group_code" type="text" size="25" class="required" title="Group code is required" id="tax_group_code" value="<cfoutput>#taxgroupquery.tax_group_code#</cfoutput>" onblur="checkValue(this)">
										</td>
									</tr>
									</tbody>
								</table>
							</form>
							<!--- /////// --->
							<!--- /END UPDATE TAX GROUP --->
							<!--- /////// --->

							<!--- Tax Rates only available for localtax --->
							<cfif application.cw.taxCalctype eq 'localTax'>
							<!--- /////// --->
							<!--- ADD NEW TAX RATE --->
							<!--- /////// --->
							<!--- FORM --->
							<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" class="CWvalidate" name="addNewForm" id="addNewForm" method="post">
								<p>&nbsp;</p>
								<cfoutput><h3>Add New #application.cw.taxSystemLabel# Rate</h3></cfoutput>
								<!--- verify tax regions exist --->
								<cfif NOT taxRegionsQuery.recordCount>
									<p>&nbsp;</p>
									<cfoutput><p>Create at least one active #application.cw.taxSystemLabel# Region to add a new #application.cw.taxSystemLabel# Rate</p></cfoutput>
								<cfelse>
									<table class="CWinfoTable">
										<thead>
										<tr>
											<cfoutput>
											<th>Available #application.cw.taxSystemLabel# Regions</th>
											</cfoutput>
											<cfoutput>
											<th>#application.cw.taxSystemLabel# Rate</th>
											</cfoutput>
										</tr>
										</thead>
										<tbody>
										<tr>
											<!--- tax region selection --->
											<td>
												<select name="tax_region_id">
													<cfoutput query="taxRegionsQuery">
													<option value="#taxRegionsQuery.tax_region_id#">#taxRegionsQuery.country_name#
													<cfif taxRegionsQuery.stateprov_name neq "">
														: #taxRegionsQuery.stateprov_name#
													</cfif>
													(#taxRegionsQuery.tax_region_label#)</option>
													</cfoutput>
												</select>
												<br>
												<input name="SubmitAddTaxRate" type="submit" class="submitButton" id="SubmitAddTaxGroup" value="Save New <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Rate">
											</td>
											<!--- rate --->
											<td><input name="taxRate" type="text" id="taxRate" size="6" maxlength="10" value="0.00" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">%</td>
										</tr>
										</tbody>
									</table>
									<cfoutput><p><a href="tax-regions.cfm">Add New #application.cw.taxSystemLabel# Region</a></p></cfoutput>
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
							<!--- check for existing records --->
							<p>&nbsp;</p>
							<cfoutput><h3>Active #application.cw.taxSystemLabel# Rates</h3></cfoutput>
							<cfif NOT taxRatesQuery.recordCount>
								<p>&nbsp;</p>
								<cfoutput><p>There are currently no #lcase(application.cw.taxSystemLabel)# rates defined for this #lcase(application.cw.taxSystemLabel)# group</p></cfoutput>
								<!--- if existing records found --->
							<cfelse>
								<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" name="recordForm" id="recordForm" method="post" class="CWobserve">
									<table class="CWsort CWstripe CWinfoTable wide" summary="<cfoutput>
										=#request.cwpage.baseUrl#</cfoutput>">
										<thead>
										<tr class="sortRow">
											<th class="region_Location">Region</th>
											<th class="tax_region_label">Name</th>
											<th class="tax_rate_percentage" style="text-align:center"><cfoutput>#application.cw.taxSystemLabel#</cfoutput> Rate </th>
											<th width="85" style="text-align:center">
												<input type="checkbox" class="checkAll" name="checkAllDelete" rel="checkAllDel">Delete
											</th>
										</tr>
										</thead>
										<tbody>
										<cfoutput query="taxRatesQuery">
										<tr>
											<!--- region --->
											<td>
												<a href="tax-region-details.cfm?tax_region_id=#taxratesQuery.tax_region_id#" class="detailsLink" title="Manage #application.cw.taxSystemLabel# Rate details">
												#taxRatesQuery.country_name#<cfif taxRatesQuery.stateprov_name neq "">: #taxRatesQuery.stateprov_name#</cfif>
												</a>
											</td>
											<!--- name --->
											<td>
												<a href="tax-region-details.cfm?id=#taxratesQuery.tax_region_id#" class="detailsLink">
												#taxRatesQuery.tax_region_label#
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
							<!--- /end if localtax --->
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