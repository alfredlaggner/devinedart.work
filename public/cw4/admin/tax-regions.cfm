<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: tax-regions.cfm
File Date: 2012-04-12
Description: Manage Tax Regions
==========================================================
NOTE: showTaxID has no visible input, not used for default CW display,
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
<cfparam name="url.country_id" default="#application.cw.defaultCountryID#" type="numeric">
<cfparam name="request.cwpage.currentID" default="#url.country_id#">
<!--- default form values --->
<cfparam name="form.showTaxID" default="false" type="boolean">
<cfparam name="form.taxregion_Name" default="">
<!--- default values for sort --->
<cfparam name="url.sortby" type="string" default="region_Location">
<cfparam name="url.sortdir" type="string" default="asc">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("view,userconfirm,useralert,clickadd")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- QUERY: Get tax groups (active/archived )--->
<cfset taxGroupsQuery = CWquerySelectTaxGroups(0)>
<!--- QUERY: Get tax regions (id (0=all))--->
<cfset taxRegionsQuery = CWquerySelectTaxRegions(0)>
<!--- make the query sortable --->
<cfset taxRegionsQuery = CWsortableQuery(taxRegionsQuery)>
<!--- QUERY: Get states for select menu --->
<cfset countriesQuery = CWquerySelectCountries(0)>
<!--- QUERY: Get states for select menu --->
<cfset statesQuery = CWquerySelectStates()>
<!--- /////// --->
<!--- ADD NEW TAX REGION --->
<!--- /////// --->
<!--- if submitting the 'add new' form, and  --->
<cfif isDefined('form.taxregion_Name') and len(trim(form.taxregion_Name))>
	<!--- determine tax method/group values --->
	<cfif isNumeric(form.shippingTax)>
		<cfset insertTaxMethod = "Tax Group">
		<cfset insertTaxGroup = form.shippingTax>
	<cfelse>
		<cfset insertTaxMethod = form.shippingTax>
		<cfset insertTaxGroup = 0>
	</cfif>
	<!--- verify numeric values --->
	<cfif NOT isNumeric(form.countryID)>
		<cfset form.countryID = 0>
	</cfif>
	<cfif NOT isNumeric(form.stateID)>
		<cfset form.stateID = 0>
	</cfif>
	<cfif NOT isNumeric(form.taxID)>
		<cfset form.taxID = 0>
	</cfif>
	<cfif NOT isNumeric(insertTaxGroup)>
		<cfset insertTaxGroup = 0>
	</cfif>
	<!--- QUERY: insert new tax region (name, country, state, show tax, tax method, tax group)--->
	<cfset newRecordID = CWqueryInsertTaxRegion(
	form.taxregion_Name,
	form.countryID,
	form.stateID,
	form.taxID,
	form.showTaxID,
	insertTaxMethod,
	insertTaxGroup
	)>
	<!--- if no error returned from insert query --->
	<cfif not left(newRecordID,2) eq '0-'>
		<!--- update complete: return to page showing message --->
		<cfset CWpageMessage("confirm","#application.cw.taxSystemLabel# Region '#form.taxregion_Name#' Added")>
		<cflocation url="#request.cwpage.baseUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&clickadd=1" addtoken="no">
		<!--- if we have an insert error, show message, do not insert --->
	<cfelse>
		<cfset request.cwpage.errorMessage = listLast(newRecordID,'-')>
		<cfset CWpageMessage("alert",request.cwpage.errorMessage)>
		<cfset url.clickadd = 1>
	</cfif>
	<!--- /END duplicate/error check --->
</cfif>
<!--- /////// --->
<!--- /END ADD TAX REGION --->
<!--- /////// --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Manage #application.cw.taxSystemLabel# Regions">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "#application.cw.taxSystemLabel# Regions Management">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 =  "Manage active #application.cw.taxSystemLabel# Regions or add a new #application.cw.taxSystemLabel# Region">
<!--- current menu marker --->
<cfset request.cwpage.currentNav = request.cw.thisPage>
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
		<!--- PAGE JAVASCRIPT --->
		<script type="text/javascript">
		jQuery(document).ready(function(){
			// add new show-hide
			jQuery('form#addNewForm').hide();
			jQuery('a#showAddNewFormLink').click(function(){
				jQuery(this).hide();
				jQuery('form#addNewForm').show().find('input.focusField').focus();
				return false;
			});
			// auto-click the link if adding
			<cfif isDefined('url.clickadd')>
				jQuery('a#showAddNewFormLink').click();
			</cfif>
			// related selects - class on option elements relates the selectors
			jQuery('#s1').change(function(){
			jQuery('#s2').val("");
			});
			// function to copy the select list, save clone for next use
			var $s2copy = function(){
			jQuery('#s2').clone().attr('id','s2-copy').insertBefore('#s2').hide();
			};
			$s2copy();
			// country/state change functions
			jQuery('#s1').change(function(){
			// get the class of the selected item
			var classtoshow = jQuery(this).children('option:selected').attr('class');
			// if class is null
			if (classtoshow == "")
			{
			jQuery('#s2').remove();
			jQuery('#s2-copy').show().attr('id','s2');
			$s2copy();
			}
			else
			// if class has value
			{
			// remove the existing state list
			jQuery('#s2').remove();
			// show the copy, change the id
			jQuery('#s2-copy').show().attr('id','s2');
			// create and save the copy (function above)
			$s2copy();
			// remove the unwanted options
			var selClass = '[class*=' + classtoshow + ']';
			jQuery('#s2').children('option').not(selClass).remove();
			}
			});
			// trigger selection of first option on page load
			jQuery('#s1').children('option:nth-child(1)').prop('selected',true).trigger('change');

			});
		</script>
		<!--- /END PAGE JAVASCRIPT --->
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
						<!--- if tax regions are not enabled --->
						<cfif application.cw.taxSystem neq "Groups">
							<div class="CWadminControlWrap">
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p class="formText"><strong><cfoutput>#application.cw.taxSystemLabel#</cfoutput> Regions disabled. To enable, select '<cfoutput>#application.cw.taxSystemLabel#</cfoutput> System: Groups' <a href="config-settings.cfm?group_ID=5">here</a></strong></p>
							</div>
						<cfelseif application.cw.taxCalctype neq 'localTax'>
							<div class="CWadminControlWrap">
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p class="formText"><strong><cfoutput>#application.cw.taxSystemLabel#</cfoutput> Regions disabled for calculation method '<cfoutput>#application.cw.taxCalctype#</cfoutput>'. To enable, select 'Local Database' <a href="config-settings.cfm?group_ID=5">here</a></strong></p>
							</div>

							<!--- if using tax regions, proceed --->
						<cfelse>
							<!--- SHOW FORM LINK --->
							<div class="CWadminControlWrap">
								<a class="CWbuttonLink" id="showAddNewFormLink" href="#">Add New <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Region</a>
							</div>
							<!--- /END SHOW FORM LINK --->
							<!--- /////// --->
							<!--- ADD NEW TAX REGION --->
							<!--- /////// --->
							<!--- FORM --->
							<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" class="CWvalidate" name="addNewForm" id="addNewForm" method="post">
								<p>&nbsp;</p>
								<h3>Add New <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Region</h3>
								<table class="CWinfoTable">
									<tbody>
									<tr>
										<!--- country / state selectors --->
										<th class="label"><cfoutput>#application.cw.taxSystemLabel#</cfoutput> Region:<div class="smallPrint">( Country / State )</div></th>
										<td>
											<div id="countryMenus">
												<!--- country --->
												<select name="CountryID" id="s1">
													<option value="" class="any" selected="selected">Select Country</option>
													<cfoutput query="countriesQuery">
													<cfset optclass = replace(lcase(country_name), " ", "-", "all")>
													<option class="#optClass#" value="#country_id#">#country_name#</option>
													</cfoutput>
												</select>
												:
												<!--- state --->
												<select name="StateID" id="s2">
													<option value="" class="any" selected="selected">Select State/Prov</option>
													<cfoutput query="statesQuery" group="country_name">
													<cfset optclass = replace(lcase(country_name), " ", "-", "all")>
													<option value="0" class="#optClass#">Entire Country</option>
													<cfoutput>
													<option value="#stateprov_id#" class="#optclass#">#stateprov_name#</option>
													</cfoutput>
													</cfoutput>
												</select>
											</div>
										</td>
									</tr>
									<tr>
										<th class="label"><cfoutput>#application.cw.taxSystemLabel#</cfoutput> Label</th>
										<td><input name="TaxRegion_Name" class="required" title="<cfoutput>#application.cw.taxSystemLabel#</cfoutput> Label is required" type="text" id="TaxRegion_Name" size="30"></td>
									</tr>
									<tr>
										<th class="label"><cfoutput>#application.cw.taxSystemLabel#</cfoutput> Number</th>
										<td><input name="TaxID" type="text" id="TaxID" size="30"></td>
									</tr>
									<tr>
										<th class="label">Shipping <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Method</th>
										<td>
											<select name="ShippingTax" id="ShippingTax">
												<option value="No Tax">No <cfoutput>#lcase(application.cw.taxSystemLabel)#</cfoutput> on shipping</option>
												<option value="Highest Item Taxed">Use <cfoutput>#lcase(application.cw.taxSystemLabel)#</cfoutput> rate applied to any item in the order</option>
												<optgroup label="Based on a Tax Group"> <cfoutput query="taxGroupsQuery">
												<option value="#taxGroupsQuery.tax_group_id#">#taxGroupsQuery.tax_group_name#</option>
												</cfoutput> </optgroup>
											</select>
										</td>
									</tr>
									<tr>
										<td colspan="2" style="text-align:center">
											<!--- submit button --->
											<input name="SubmitAdd" type="submit" class="CWformButton" id="SubmitAdd" value="Save New <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Region">
										</td>
									</tr>
									</tbody>
								</table>
							</form>
							<!--- /////// --->
							<!--- /END ADD TAX REGION --->
							<!--- /////// --->
							<!--- /////// --->
							<!--- LIST REGIONS --->
							<!--- /////// --->
							<!--- if no records found, show message --->
							<cfif not taxRegionsQuery.recordCount>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p><strong>No <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Regions available.</strong> <br><br></p>
								<!--- if records found --->
							<cfelse>
								<!--- output records --->
								<!--- Container table --->
								<p>&nbsp;</p>
								<table class="wide">
									<thead>
									<tr class="headerRow">
										<th>Active <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Regions</th>
									</tr>
									</thead>
									<tbody>
									<tr>
										<td>
											<div style="clear:right;"></div>
											<!--- Method Records Table --->
											<p>&nbsp;</p>
											<table class="CWinfoTable CWstripe CWsort" summary="<cfoutput>#request.cwpage.baseUrl#</cfoutput>">
												<thead>
												<tr class="sortRow">
													<th class="noSort">Edit</th>
													<th class="region_Location">Location</th>
													<th class="tax_region_label"><cfoutput>#application.cw.taxSystemLabel#</cfoutput> Label </th>
													<th class="tax_region_tax_id"><cfoutput>#application.cw.taxSystemLabel#</cfoutput> ID </th>
													<th class="tax_region_ship_tax_method">Ship <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Method </th>
												</tr>
												</thead>
												<tbody>
												<cfoutput query="taxRegionsQuery">
												<tr>
													<td style="text-align:center;">
														<a href="tax-region-details.cfm?tax_region_id=#taxRegionsQuery.tax_region_id#" title="Manage #application.cw.taxSystemLabel# Region" class="detailsLink"><img src="img/cw-edit.gif" width="15" height="15" alt="Manage #application.cw.taxSystemLabel# Region Details"></a>
													</td>
													<td>
														<strong><a href="tax-region-details.cfm?tax_region_id=#taxRegionsQuery.tax_region_id#" class="detailsLink">#taxRegionsQuery.country_name#
														<cfif taxRegionsQuery.stateprov_name neq ""> : #taxRegionsQuery.stateprov_name#</cfif>
														</a></strong>
													</td>
													<td>#taxRegionsQuery.tax_region_label#</td>
													<td>#taxRegionsQuery.tax_region_tax_id#</td>
													<td>
														#taxRegionsQuery.tax_region_ship_tax_method#
														<cfif taxRegionsQuery.tax_group_name neq "">
															:
															<a href="TaxGroup.cfm?id=#taxRegionsQuery.tax_region_ship_tax_group_id#" class="detailsLink">#taxRegionsQuery.tax_group_name#</a>
														</cfif>
													</td>
												</tr>
												</cfoutput>
												</tbody>
											</table>
											<p>&nbsp;</p>
											<!--- /END Records Table --->
										</td>
									</tr>
									</tbody>
								</table>
								<!--- /END Output Records --->
							</cfif>
							<!--- /END if records found --->
						</cfif>
						<!--- /end if tax regions enabled --->
						<!--- /////// --->
						<!--- /END LIST REGIONS --->
						<!--- /////// --->
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