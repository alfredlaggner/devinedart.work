<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: ship-ranges.cfm
File Date: 2013-01-17
Description: Manage Shipping Ranges
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
<!--- add-new method dropdown default value  --->
<cfparam name="url.method" type="numeric" default="0">
<!--- country management selection --->
<cfparam name="url.country" default="#application.cw.defaultCountryID#">	
<cfif not isNumeric(url.country)>
	<cfset url.country = 0>
</cfif>
<!--- default form values --->
<cfparam name="form.ship_range_method_id" default="0">
<cfparam name="form.ship_range_From" default="">
<cfparam name="form.ship_range_to" default="">
<cfparam name="form.ship_range_amount" default="0"> 
<cfparam name="form.country_id" default="">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("view,userconfirm,useralert,clickadd,method")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- QUERY: get all active shipping methods --->
<cfset methodsQuery = CWquerySelectShippingMethods()>
<!--- QUERY: get all ship ranges by country --->
<cfset rangesQuery = CWquerySelectShippingCountryRanges()>
<!--- /////// --->
<!--- ADD NEW SHIP RANGE --->
<!--- /////// --->
<cfif isDefined('form.ship_range_method_id') and form.ship_range_method_id gt 0>
	<!--- make sure end is greater than start --->
	<cfif form.ship_range_to gt form.ship_range_from>
		<!--- QUERY: insert new ship range (method ID, from, to, amount)--->
		<cfset newRecordID = CWqueryInsertShippingRange(
		form.ship_range_method_id,
		form.ship_range_from,
		form.ship_range_to,
		form.ship_range_amount
		)>
		<cfset CWpageMessage("confirm","Shipping Range Added")>
		<cflocation url="#request.cwpage.baseUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&clickadd=1&method=#form.ship_range_method_id#" addtoken="no">
	<cfelse>
		<cfset CWpageMessage("alert","Error: To amount must be greater than From")>
		<cflocation url="#request.cwpage.baseUrl#&useralert=#CWurlSafe(request.cwpage.userAlert)#&clickadd=1&method=#form.ship_range_method_id#" addtoken="no">
	</cfif>
</cfif>
<!--- /////// --->
<!--- /END ADD NEW SHIP RANGE --->
<!--- /////// --->
<!--- /////// --->
<!--- UPDATE / DELETE SHIP RANGES --->
<!--- /////// --->
<!--- look for at least one valid ID field --->
<cfif isDefined('form.rangeCounter')>
	<cfparam name="form.deleteRecord" default="">
	<cfset loopCt = 1>
	<cfset updateCt = 0>
	<cfset deleteCt = 0>
	<!--- loop record ids, handle each one as needed --->
	<cfloop list="#form.recordIDlist#" index="ID">
		<!--- DELETE RECORDS --->
		<!--- if the record ID is marked for deletion --->
		<cfif listFind(form.deleteRecord,trim(evaluate('form.ship_range_id'&loopCt)))>
			<!--- QUERY: delete record (record id) --->
			<cfset deleteRecord = CWqueryDeleteShippingRange(id)>
			<cfset deleteCt = deleteCt + 1>
			<!--- if not deleting, update --->
		<cfelse>
			<!--- UPDATE RECORDS --->
			<!--- make sure end is greater than start --->
			<cfif form["ship_range_to#loopct#"] gt form["ship_range_from#loopct#"]>
				<!--- QUERY: update ship range (range ID, from, to, amount)--->
				<cfset updateRecord = CWqueryUpdateShippingRange(
				form["ship_range_id#loopct#"],
				form["ship_range_from#loopct#"],
				form["ship_range_to#loopct#"],
				form["ship_range_amount#loopct#"]
				)>
				<cfset updateCt = updateCt + 1>
			<cfelse>
				<cfset insertError = "Error: Range starting amount (#form['ship_range_from#loopct#']#) must be less than end amount (#form['ship_range_to#loopct#']#)">
			</cfif>
		</cfif>
		<!--- /END delete vs. update --->
		<cfset loopCt = loopCt + 1>
	</cfloop>
	<!--- if we have errors, return showing details about last errant record --->
	<cfif isDefined('insertError')>
		<cflocation url="#request.cwpage.baseUrl#&useralert=#CWurlsafe(insertError)#&clickadd=1" addtoken="no">
		<!--- if no errors, return showing message --->
	<cfelse>
		<!--- get the vars to keep by omitting the ones we don't want repeated --->
		<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert,method")>
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
	<!--- /end if no errors --->
</cfif>
<!--- /////// --->
<!--- /END UPDATE / DELETE SHIP RANGES --->
<!--- /////// --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Manage Shipping Ranges">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Shipping Ranges &amp; Rates">
<!--- Page Subheading (instructions) <h2> --->
<cfsavecontent variable="head2text">
Manage shipping rates scale<cfif application.cw.shipChargeBasedOn neq 'none'> based on <cfoutput>#lcase(application.cw.shipChargeBasedOn)#</cfoutput></cfif>
</cfsavecontent>
<cfset request.cwpage.heading2 =  "#head2text#">
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
			// method selector adds first input value
			jQuery('#methodSelect').change(function(){
				var selVal = jQuery(this).val();
				var changeClass = 'to' + selVal;
				//alert(changeClass);
				var lastTo = 'input[class*=' + changeClass + ']:last';
				var lastToVal = jQuery(lastTo).val();
				var newFromVal = Math.round((Number(lastToVal) + .01) * 100) / 100;
				if(!(isNaN(newFromVal)==true)){
				jQuery('input[name=ship_range_from]').val(newFromVal);
				} else {
				jQuery('input[name=ship_range_from]').val(0);
				};
				jQuery('input[name=ship_range_to]').focus();
			});

			// add new show-hide
			jQuery('form#addNewForm').hide();
			jQuery('a#showAddNewFormLink').click(function(){
				jQuery(this).hide();
				jQuery('form#addNewForm').show().find('input.focusField').focus();
				jQuery('#methodSelect').trigger('change');
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
						<!--- link for add-new form --->
						<div class="CWadminControlWrap">
							<strong><a class="CWbuttonLink" id="showAddNewFormLink" href="#">Add New Shipping Range</a></strong>
						</div>
						<!--- /////// --->
						<!--- ADD NEW RECORD --->
						<!--- /////// --->
						<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>&clickadd=1" class="CWvalidate" name="addNewForm" id="addNewForm" method="post">
							<p>&nbsp;</p>
							<h3>Add New Shipping Range</h3>
							<table class="CWinfoTable wide">
								<thead>
								<tr>
									<th>Shipping Method / Country</th>
									<th>From</th>
									<th>To</th>
									<th>Rate</th>
								</tr>
								</thead>
								<tbody>
								<tr>
									<!--- country/method --->
									<td style="text-align:center">
										<div>
											<select name="ship_range_method_id" id="methodSelect">
												<cfoutput query="methodsQuery" group="country_name">
												<optgroup label="#country_name#"> <cfoutput>
												<option value="#methodsQuery.ship_method_id#" <cfif methodsQuery.ship_method_id eq url.method>selected="selected"</cfif>>#methodsQuery.ship_method_name#</option>
												</cfoutput>
												</optgroup>
												</cfoutput>
											</select>
										</div>
										<br>
										<input name="SubmitAdd" type="submit" class="CWformButton" id="SubmitAdd" value="Save New Shipping Range">
									</td>
									<!--- from --->
									<td>
										<input name="ship_range_from" type="text" class="required" title="Beginning range value required (numeric)" value="0" size="11" maxlength="11" onblur="extractNumeric(this,2,true);">
									</td>
									<!--- to --->
									<td>
										<input name="ship_range_to" type="text" class="required focusField" title="Ending range value required (numeric)" size="11" maxlength="11" onblur="extractNumeric(this,2,true);">
									</td>
									<!--- rate --->
									<td>
										<input name="ship_range_amount" type="text" class="required" title="Ship range amount required (numeric)" size="7" maxlength="11" onblur="extractNumeric(this,2,true);">
									</td>
								</tr>
								</tbody>
							</table>
						</form>
						<!--- /////// --->
						<!--- /END ADD NEW RECORD --->
						<!--- /////// --->
						<!--- /////// --->
						<!--- EDIT RECORDS --->
						<!--- /////// --->
						<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" name="recordForm" id="recordForm" method="post" class="CWobserve">
							<!--- if no records found, show message --->
							<cfif not rangesQuery.recordCount>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p><strong>No Shipping Ranges available.</strong> <br><br></p>
								<!--- if records found --->
							<cfelse>
								<!--- output records --->
								<!--- Container table --->
								<table class="CWinfoTable wide">
									<thead>
									<tr class="headerRow">
										<th>Active Shipping Ranges</th>
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
													<cfif listFind(valueList(rangesQuery.country_id),country_id)>
													<option value="#request.cw.thisPage#?country=#country_id#"<cfif url.country eq country_id> selected="selected"</cfif>>#country_name#</option>
													</cfif>
												</cfoutput>
											</select>
											</label>
											<input type="hidden" value="<cfoutput>#rangesQuery.RecordCount#</cfoutput>" name="rangeCounter">
											<!--- save changes submit button --->
											<input name="SubmitUpdate" type="submit" class="CWformButton" id="SubmitUpdate" value="Save Changes">
											<div style="clear:right;"></div>
											<!--- LOOP RANGES BY COUNTRY --->
											<cfset countryCt = 0>
											<!--- limit query if country is defined in url --->
											<cfif url.country gt 0>
												<cfquery dbtype="query" name="rangesQuery">
												SELECT * FROM rangesQuery WHERE country_id = #url.country#
												</cfquery>											
											</cfif>
											<cfoutput query="rangesQuery" group="country_name">
											<!--- Country Table --->
											<table class="CWinfoTable">
												<tr class="headerRow">
													<th><h3>#country_name#</h3></th>
												</tr>
												<tr>
													<td>
														<!--- Ranges Table --->
														<table class="CWstripe">
															<!--- set up counter for varying methods within this country group --->
															<cfset prevMethod = 0>
															<cfset rowCt = 1>
															<!--- nested cfoutput ungroups the records by country --->
															<cfoutput>
															<cfset nextMethod = rangesQuery.ship_method_id>
															<cfset checkClass = 'range#nextMethod#'>
															<cfset fromClass = 'from#nextMethod#'>
															<cfset toClass = 'to#nextMethod#'>
															<!--- spacer row --->
															<cfif nextMethod neq prevMethod>
																<cfif currentRow neq 1>
																	<tr>
																	<td colspan="5">&nbsp;</td>
																	</tr>
																</cfif>
																<cfset rowCt = 1>
																<tr class="headerRow">
																	<th width="182"><a href="ship-methods.cfm" title="Manage Ship Method: #rangesQuery.ship_method_name#">#rangesQuery.ship_method_name# (#rangesQuery.ship_method_calctype#)</a></th>
																	<th width="105">From</th>
																	<th width="105">To</th>
																	<th width="84">Rate</th>
																	<th width="82" style="text-align:center;"><input type="checkbox" class="checkAll" rel="#checkClass#">Delete</th>
																</tr>
															</cfif>
															<tr>
																<!--- range number --->
																<td style="text-align:left;">
																	Range #rowCt#
																	<!--- hidden fields used for processing update/delete --->
																	<input name="ship_range_id#CurrentRow#" type="hidden" value="#rangesQuery.ship_range_id#">
																	<input name="recordIDlist" type="hidden" value="#rangesQuery.ship_range_id#">
																</td>
																<!--- from --->
																<td>
																	<cfif nextMethod neq prevMethod>
																		<input type="hidden"name="ship_range_from#CurrentRow#" id="ship_range_from#CurrentRow#" value="0">&nbsp;0&nbsp;
																	<cfelse>
																		<input name="ship_range_from#CurrentRow#" type="text" class="#fromClass#" id="ship_range_from#CurrentRow#" size="9" maxlength="11" value="#rangesQuery.ship_range_from#" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
																	</cfif>
																</td>
																<!--- to --->
																<td>
																	<input name="ship_range_to#CurrentRow#" type="text" class="#toClass#" id="ship_range_to#CurrentRow#" size="9" maxlength="11" value="#rangesQuery.ship_range_to#" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
																</td>
																<!--- rate --->
																<td>
																	<input name="ship_range_amount#CurrentRow#" type="text" id="ship_range_amount#CurrentRow#" size="5" maxlength="11" value="#LSNumberFormat(rangesQuery.ship_range_amount,'9.99')#" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
																</td>
																<!--- delete --->
																<td style="text-align:center">
																	<input type="checkbox" value="#ship_range_id#" class="formCheckbox #checkClass#" name="deleteRecord">
																</td>
															</tr>
														<cfset rowCt = rowCt + 1>
														<cfset prevMethod = nextMethod>
														</cfoutput>
														<!--- show message for any remaining ship methods, with no ranges --->
														<cfloop query="methodsQuery">
															<cfif methodsQuery.country_name is rangesQuery.country_name and not listFind(valueList(rangesQuery.ship_method_id),methodsQuery.ship_method_id)>
															<tr class="headerRow">
															<th><strong>#methodsQuery.ship_method_name#</strong></th>
															<cfif methodsQuery.ship_method_calctype is 'localcalc'>	
																<th colspan="4">No shipping ranges</th>
															<cfelse>
																<th colspan="4">Calculation set to "#methodsQuery.ship_method_calctype#"</th>
															</cfif>																
															</tr>
															<tr>
																<td colspan="5"><a href="ship-ranges.cfm?clickadd=1&method=#methodsQuery.ship_method_id#">Add at least one range above for this method</a> (#methodsQuery.ship_method_name#)</td>
															</tr>
															</cfif>														
														</cfloop>
														<!--- /end remaining methods --->
														</table>
														<!--- /END Method Records Table --->
													</td>
												</tr>
											</table>
											<!--- /end url country --->
											<!--- /END Country Table --->
											<cfset countryCt = countryCt + 1>
											</cfoutput>
											<!--- /END Loop Methods by Country --->
											<!--- show the submit button here if we have a long list --->
											<cfif countryCt gt 1>
												<input name="SubmitUpdate" type="submit" class="CWformButton" id="SubmitUpdate" value="Save Changes">
											</cfif>
											<span class="smallPrint" style="float:right;">
											<br>	Note: The first range of any method must start with 0
											</span>
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