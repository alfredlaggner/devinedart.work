<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: ship-methods.cfm
File Date: 2013-01-17
Description: Manage Shipping Methods
==========================================================
Notes:
To add new shipping calculation types, add your API connection to cw-func-shipping.cfm
then add the option to the two select lists below 
see comments ("add new calculation types here")
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
<!--- country management selection --->
<cfparam name="url.country" default="#application.cw.defaultCountryID#">	
<cfif not isNumeric(url.country)>
	<cfset url.country = 0>
</cfif>
<!--- default form values --->
<cfparam name="form.ship_method_name" type="string" default="">
<cfparam name="form.ship_method_rate" type="numeric" default="0">
<cfparam name="form.ship_method_sort" type="numeric" default="0">
<cfparam name="form.ship_method_calctype" type="string" default="localcalc">
<cfparam name="form.country_id" type="string" default="">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("view,userconfirm,useralert,clickadd,resetapplication")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- ACTIVE VS. ARCHIVED --->
<cfif url.view contains 'arch'>
	<cfset request.cwpage.viewType = 'Archived'>
	<cfset request.cwpage.recordsArchived = 1>
	<cfset request.cwpage.subHead = 'Archived Shipping Methods are not shown in the store'>
<cfelse>
	<cfset request.cwpage.viewType = 'Active'>
	<cfset request.cwpage.recordsArchived = 0>
	<cfset request.cwpage.subHead = 'Manage active Shipping Methods or add a new Method'>
</cfif>
<!--- QUERY: Get all available countries --->
<cfset countriesQuery = CWquerySelectCountries(0)>
<!--- QUERY: Get all ship methods by status --->
<cfset methodsQuery = CWquerySelectStatusShipMethods(request.cwpage.recordsArchived)>
<!--- /////// --->
<!--- ADD NEW SHIP METHOD --->
<!--- /////// --->
<!--- if submitting the 'add new' form, and  --->
<cfif isDefined('form.ship_method_name') and len(trim(form.ship_method_name)) and request.cwpage.recordsArchived eq 0>
	<!--- QUERY: insert new ship method (name, country ID, rate, order, calctype, archived)--->
	<cfset newRecordID = CWqueryInsertShippingMethod(
	trim(form.ship_method_name),
	form.country_id,
	form.ship_method_rate,
	form.ship_method_sort,
	form.ship_method_calctype,
	0
	)>
	<!--- if no error returned from insert query --->
	<cfif not left(newRecordID,2) eq '0-'>
		<!--- update complete: return to page showing message --->
		<cfset CWpageMessage("confirm","Shipping Method '#form.ship_method_name#' Added")>
		<cflocation url="#request.cwpage.baseUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&clickadd=1&resetapplication=#application.cw.storePassword#" addtoken="no">
		<!--- if we have an insert error, show message, do not insert --->
	<cfelse>
		<cfset request.cwpage.errorMessage = listLast(newRecordID,'-')>
		<cfset CWpageMessage("alert",request.cwpage.errorMessage)>
		<cfset url.clickadd = 1>
	</cfif>
	<!--- /END duplicate/error check --->
</cfif>
<!--- /////// --->
<!--- /END ADD SHIP METHOD --->
<!--- /////// --->
<!--- /////// --->
<!--- UPDATE / DELETE SHIP METHODS --->
<!--- /////// --->
<!--- look for at least one valid ID field --->
<cfif isDefined('form.ship_method_id1')>
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
		<cfif listFind(form.deleteRecord,evaluate('form.ship_method_id'&loopCt))>
			<!--- QUERY: delete record (record id) --->
			<cfset deleteRecord = CWqueryDeleteShippingMethod(id)>
			<cfset deleteCt = deleteCt + 1>
			<!--- if not deleting, update --->
		<cfelse>
			<!--- UPDATE RECORDS --->
			<!--- param for checkbox values --->
			<cfparam name="form.ship_method_archive#loopct#" default="#request.cwpage.recordsArchived#">
			<!--- verify numeric sort order --->
			<cfif NOT isNumeric(#form["ship_method_sort#loopct#"]#)>
				<cfset #form["ship_method_sort#loopct#"]# = 0>
			</cfif>
			<!--- QUERY: update record (ID, name, rate, order, archived) --->
			<cfset updateRecord = CWqueryUpdateShippingMethod(
			#form["ship_method_id#loopct#"]#,
			'#form["ship_method_name#loopct#"]#',
			#form["ship_method_rate#loopct#"]#,
			#form["ship_method_sort#loopct#"]#,
			#form["ship_method_calctype#loopct#"]#,
			#form["ship_method_archive#loopct#"]#
			)>
			<cfif #form["ship_method_archive#loopct#"]# is 1 and request.cwpage.recordsArchived is 0>
				<cfset archiveCt = archiveCt + 1>
			<cfelseif #form["ship_method_archive#loopct#"]# is 0 and request.cwpage.recordsArchived is 1>
				<cfset activeCt = activeCt + 1>
			<cfelse>
				<cfset updateCt = updateCt + 1>
			</cfif>
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
	<cfif archiveCt gt 0>
		<cfoutput>#archiveCt# Record<cfif archiveCt gt 1>s</cfif> Archived</cfoutput>
	<cfelseif activeCt gt 0>
		<cfoutput>#activeCt# Record<cfif activeCt gt 1>s</cfif> Activated</cfoutput>
	</cfif>
	<cfif deleteCt gt 0><cfoutput><cfif activeCt or archiveCt><br></cfif>#deleteCt# Record<cfif deleteCt gt 1>s</cfif> Deleted</cfoutput></cfif>
	</cfsavecontent>
	<cfset CWpageMessage("alert",request.cwpage.userAlertText)>
	<!--- return to page as submitted, clearing form scope --->
	<cflocation url="#request.cwpage.relocateUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&useralert=#CWurlSafe(request.cwpage.userAlert)#&resetapplication=#application.cw.storePassword#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- END UPDATE / DELETE SHIP METHODS --->
<!--- /////// --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Manage Shipping Methods">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Shipping Methods Management">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 =  "Add or edit shipping transport options by country">
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
			// change country with select
			jQuery('#countrySel').change(function(){
			 	var newUrl = jQuery(this).find('option:selected').attr('value');
			 	window.location = newUrl;
			});		
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
						<!--- LINKS FOR VIEW TYPE --->
						<div class="CWadminControlWrap">
							<strong>
							<cfif url.view eq 'arch'>
								<a href="<cfoutput>#request.cw.thisPage#</cfoutput>">View Active</a>
							<cfelse>
								<a href="<cfoutput>#request.cw.thisPage#</cfoutput>?view=arch">View Archived</a>
								<!--- link for add-new form --->
								<cfif request.cwpage.recordsArchived is 0>
									&nbsp;&nbsp;<a class="CWbuttonLink" id="showAddNewFormLink" href="#">Add New Shipping Method</a>
								</cfif>
							</cfif>
							</strong>
						</div>
						<!--- /END LINKS FOR VIEW TYPE --->
						<!--- /////// --->
						<!--- ADD NEW METHOD --->
						<!--- /////// --->
						<cfif request.cwpage.recordsArchived is 0>
							<!--- FORM --->
							<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" class="CWvalidate" name="addNewForm" id="addNewForm" method="post">
								<p>&nbsp;</p>
								<h3>Add New Shipping Method</h3>
								<table class="CWinfoTable wide">
									<thead>
									<tr>
										<th>Method Name</th>
										<th>Country</th>
										<th>Base Rate</th>
										<th>Sort</th>
										<th>Calculation</th>
									</tr>
									</thead>
									<tbody>
									<tr>
										<!--- ship method --->
										<td style="text-align:center">
											<div>
												<input name="ship_method_name" type="text" size="20" class="required focusField" title="Method Name is required" id="ship_method_name" value="<cfoutput>#form.ship_method_name#</cfoutput>">
											</div>
											<br>
											<input name="SubmitAdd" type="submit" class="CWformButton" id="SubmitAdd" value="Save New Shipping Method">
										</td>
										<!--- country --->
										<td style="text-align:center">
											<select name="country_id">
												<cfoutput query="countriesQuery">
												<option value="#country_id#"<cfif form.country_id eq '#country_id#'> selected="selected"</cfif> title="#country_name#">#left(country_name,22)#<cfif len(country_name) gt 25>...</cfif></option>
												</cfoutput>
											</select>
										</td>
										<!--- rate --->
										<td><input name="ship_method_rate" type="text" size="4" maxlength="7" class="required" title="Rate is required" id="ship_method_rate" value="<cfoutput>#form.ship_method_rate#</cfoutput>" onblut="extractNumeric(this,2,true);"> </td>
										<!--- sort order --->
										<td>
											<input name="ship_method_sort" type="text" id="ship_method_sort" size="3" maxlength="7" class="required sort" title="Sort order is required" value="<cfoutput>#form.ship_method_sort#</cfoutput>" onblur="extractNumeric(this,2,true);">
										</td>
										<!--- calculation type --->
										<td style="text-align:center">
											<!--- add new calculation types here --->
											<select name="ship_method_calctype" id="ship_method_calctype">
											<option value="localcalc"<cfif form.ship_method_calctype eq 'localcalc'> selected="selected"</cfif>>Local (CW)</option>
											<option value="upsgroundcalc"<cfif form.ship_method_calctype eq 'upsgroundcalc'> selected="selected"</cfif>>UPS Ground</option>
											<option value="ups2daycalc"<cfif form.ship_method_calctype eq 'ups2daycalc'> selected="selected"</cfif>>UPS 2-Day</option>
											<option value="ups3daycalc"<cfif form.ship_method_calctype eq 'ups3daycalc'> selected="selected"</cfif>>UPS 3-Day</option>
											<option value="upsnextdaycalc"<cfif form.ship_method_calctype eq 'upsnextdaycalc'> selected="selected"</cfif>>UPS Next Day</option>
											<option value="fedexgroundcalc"<cfif form.ship_method_calctype eq 'fedexgroundcalc'> selected="selected"</cfif>>FedEx Ground</option>
											<option value="fedexstandardovernightcalc"<cfif form.ship_method_calctype eq 'fedexstandardovernightcalc'> selected="selected"</cfif>>FedEx Overnight</option>
											<option value="fedex2daycalc"<cfif form.ship_method_calctype eq 'fedex2daycalc'> selected="selected"</cfif>>FedEx Two Day</option>
											<option value="uspsfirstclasscalc"<cfif form.ship_method_calctype eq 'uspsfirstclasscalc'> selected="selected"</cfif>>US Postal 1st Class Domestic</option>
											<option value="uspsprioritycalc"<cfif form.ship_method_calctype eq 'uspsprioritycalc'> selected="selected"</cfif>>US Postal Priority Domestic</option>
											<option value="uspsparcelcalc"<cfif form.ship_method_calctype eq 'uspsparcelcalc'> selected="selected"</cfif>>US Postal Parcel Domestic</option>
											<option value="uspsexpresscalc"<cfif form.ship_method_calctype eq 'uspsexpresscalc'> selected="selected"</cfif>>US Postal Express Domestic</option>
											</select>
										</td>
									</tr>
									</tbody>
								</table>
							</form>
						</cfif>
						<!--- /////// --->
						<!--- /END ADD NEW METHOD --->
						<!--- /////// --->
						<!--- /////// --->
						<!--- EDIT RECORDS --->
						<!--- /////// --->
						<form action="<cfoutput>#request.cwpage.baseUrl#&view=#url.view#</cfoutput>" name="recordForm" id="recordForm" method="post" class="CWobserve">
							<!--- if no records found, show message --->
							<cfif not methodsQuery.recordCount>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p><strong>No <cfoutput>#request.cwpage.viewtype#</cfoutput> Shipping Methods available.</strong> <br><br></p>
								<!--- if records found --->
							<cfelse>
								<!--- output records --->
								<!--- Container table --->
								<table class="CWinfoTable wide">
									<thead>
									<tr class="headerRow">
										<th><cfoutput>#request.cwpage.viewType# Shipping Methods</cfoutput></th>
									</tr>
									</thead>
									<tbody>
									<tr>
										<td>
											<!--- country selection --->
											<label>&nbsp;&nbsp;Manage Country:
											<select name="countrySel" id="countrySel">
												<cfoutput><option value="#request.cw.thisPage#?country=0">All Countries</option></cfoutput>
												<cfoutput query="methodsQuery" group="country_name">
													<option value="#request.cw.thisPage#?country=#country_id#"<cfif url.country eq country_id> selected="selected"</cfif>>#country_name#</option>
												</cfoutput>
											</select>
											</label>
											<input type="hidden" value="<cfoutput>#methodsQuery.RecordCount#</cfoutput>" name="methodCounter">
											<!--- save changes submit button --->
											<input name="SubmitUpdate" type="submit" class="CWformButton" id="SubmitUpdate" value="Save Changes">
											<div style="clear:right;"></div>
											<!--- LOOP METHODS BY COUNTRY --->
											<cfset disabledDeleteCt = 0>
											<cfset countryCt = 0>
											<!--- limit query if country is defined in url --->
											<cfif url.country gt 0>
												<cfquery dbtype="query" name="methodsQuery">
												SELECT * FROM methodsQuery WHERE country_id = #url.country#
												</cfquery>											
											</cfif>											
											<cfoutput query="methodsQuery" group="country_id">
											<!--- Country Table --->
											<table class="CWinfoTable">
												<tr class="headerRow">
													<th><h3>#country_name#</h3></th>
												</tr>
												<tr>
													<td>
														<!--- Method Records Table --->
														<table class="CWstripe">
															<tr>
																<th width="198">Method Name</th>
																<th width="24">ID</th>
																<th width="75">Base Rate</th>
																<th width="55">Sort</th>
																<th width="115">Calculation Type</th>
																<th width="85"><input type="checkbox" class="checkAll" name="checkAllDelete" rel="checkAllDel#country_id#">Delete</th>
																<th width="85">
																	<input type="checkbox" class="checkAll" name="checkAllArchive" rel="checkAllArch#country_id#">
																	<cfif request.cwpage.viewType contains 'arch'>Activate<cfelse>Archive</cfif>
																</th>
															</tr>
															<cfoutput>
															<!--- QUERY: check for existing related orders --->
															<cfset methodOrdersQuery = CWquerySelectShippingMethodOrders(methodsQuery.ship_method_id)>
															<cfset methodOrders = methodOrdersQuery.recordCount>
															<!--- QUERY: check for existing related ranges --->
															<cfset methodRangesQuery = CWquerySelectShippingMethodRanges(methodsQuery.ship_method_id)>
															<cfset methodRanges = methodRangesQuery.recordCount>
															<tr>
																<!--- method name --->
																<td style="text-align:right;">
																	<input name="ship_method_name#CurrentRow#" type="text" id="ship_method_name#CurrentRow#" size="10"  value="#methodsQuery.ship_method_name#" onblur="checkValue(this)">
																</td>
																<!--- ID --->
																<td>#methodsQuery.ship_method_id#</td>
																<!--- rate --->
																<td style="text-align:center">
																	<input name="ship_method_rate#CurrentRow#" id="ship_method_rate#CurrentRow#" type="text" value="#LSNumberFormat(methodsQuery.ship_method_rate,'.99')#" size="3" maxlength="7" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
																</td>
																<!--- sort order --->
																<td style="text-align:center">
																	<input name="ship_method_sort#CurrentRow#" type="text" value="#methodsQuery.ship_method_sort#" size="3" maxlength="7" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
																	<!--- hidden fields used for processing update/delete --->
																	<input name="recordIDlist" type="hidden" value="#methodsQuery.ship_method_id#">
																	<input name="ship_method_id#CurrentRow#" type="hidden" id="ship_method_id#CurrentRow#" value="#methodsQuery.ship_method_id#">
																</td>
																<!--- calculation type --->
																<td style="text-align:center">
																	<!--- add new calculation types here --->
																	<select name="ship_method_calctype#CurrentRow#" id="ship_method_calctype#CurrentRow#">
																	<option value="localcalc"<cfif methodsQuery.ship_method_calctype eq 'localcalc'> selected="selected"</cfif>>Local (CW)</option>
																	<option value="upsgroundcalc"<cfif methodsQuery.ship_method_calctype eq 'upsgroundcalc'> selected="selected"</cfif>>UPS Ground</option>
																	<option value="ups2daycalc"<cfif methodsQuery.ship_method_calctype eq 'ups2daycalc'> selected="selected"</cfif>>UPS 2 Day</option>
																	<option value="ups3daycalc"<cfif methodsQuery.ship_method_calctype eq 'ups3daycalc'> selected="selected"</cfif>>UPS 3 Day</option>
																	<option value="upsnextdaycalc"<cfif methodsQuery.ship_method_calctype eq 'upsnextdaycalc'> selected="selected"</cfif>>UPS Next Day</option>
                                                                    <option value="fedexgroundcalc"<cfif methodsQuery.ship_method_calctype eq 'fedexgroundcalc'> selected="selected"</cfif>>FedEx Ground</option>
                                                                    <option value="fedexstandardovernightcalc"<cfif methodsQuery.ship_method_calctype eq 'fedexstandardovernightcalc'> selected="selected"</cfif>>FedEx Overnight</option>
                                                                    <option value="fedex2daycalc"<cfif methodsQuery.ship_method_calctype eq 'fedex2daycalc'> selected="selected"</cfif>>FedEx Two Day</option>
																	<option value="uspsfirstclasscalc"<cfif methodsQuery.ship_method_calctype eq 'uspsfirstclasscalc'> selected="selected"</cfif>>US Postal 1st Class Domestic</option>
																	<option value="uspsprioritycalc"<cfif methodsQuery.ship_method_calctype eq 'uspsprioritycalc'> selected="selected"</cfif>>US Postal Priority Domestic</option>
																	<option value="uspsparcelcalc"<cfif methodsQuery.ship_method_calctype eq 'uspsparcelcalc'> selected="selected"</cfif>>US Postal Parcel Domestic</option>
																	<option value="uspsexpresscalc"<cfif methodsQuery.ship_method_calctype eq 'uspsexpresscalc'> selected="selected"</cfif>>US Postal Express Domestic</option>
																	</select>
																	<span class="smallPrint" style="float:left;"><br><a href="ship-ranges.cfm?country=#methodsQuery.country_id#<cfif methodRanges eq 0>&clickadd=1</cfif>&method=#methodsQuery.ship_method_id#"><cfif methodRanges eq 0>Add<cfelse>Manage</cfif> <cfif methodsQuery.ship_method_calctype eq 'localcalc'>shipping<cfelse>fallback</cfif> ranges</span>																	
																</td>
																<!--- delete --->
																<td style="text-align:center">
																	<input type="checkbox" value="#ship_method_id#" class="checkAllDel#country_id# formCheckbox radioGroup" rel="group#currentRow#" name="deleteRecord"<cfif methodOrders neq 0 OR methodRanges neq 0> disabled="disabled"</cfif>>
																	<cfif methodOrders neq 0 OR methodRanges neq 0>
																		<cfset disabledDeleteCt = disabledDeleteCt + 1>
																	</cfif>
																</td>
																<!--- archive --->
																<td style="text-align:center">
																	<input type="checkbox" value="<cfif request.cwpage.viewType eq 'Active'>1<cfelse>0</cfif>" class="checkAllArch#country_id# formCheckbox radioGroup" rel="group#currentRow#" name="ship_method_archive#CurrentRow#">
																</td>
															</tr>
															</cfoutput>
														</table>
														<!--- /END Method Records Table --->
													</td>
												</tr>
											</table>
											<!--- /END Country Table --->
											<cfset countryCt = countryCt + 1>
											</cfoutput>
											<!--- /END Loop Methods by Country --->
											<!--- show the submit button here if we have a long list --->
											<cfif countryCt gt 1>
												<input name="SubmitUpdate" type="submit" class="CWformButton" id="SubmitUpdate" value="Save Changes">
											</cfif>
											<!--- if we have disabled delete boxes, explain --->
											<cfif disabledDeleteCt>
												<span class="smallPrint" style="float:right;">
													Note: records with associated orders or active ship ranges cannot be deleted
												</span>
											</cfif>
										</td>
									</tr>
									</tbody>
								</table>
								<!--- /END Output Records --->
							</cfif>
							<!--- /END if records found --->
						</form>
						<!--- /////// --->
						<!--- /END EDIT RECORDS --->
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