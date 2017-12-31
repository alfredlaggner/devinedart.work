<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: ship-extensions.cfm
File Date: 2012-04-12
Description: Manage Shipping Location Extensions
Note: Only active states and countries are shown.
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
<cfparam name="url.country_id" type="numeric" default="#application.cw.defaultCountryID#">
<cfparam name="request.cwpage.currentID" default="#url.country_id#">
<!--- default values for sort --->
<cfparam name="url.sortby" type="string" default="stateprov_code">
<cfparam name="url.sortdir" type="string" default="asc">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("view,userconfirm,useralert,sortby,sortdir")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- QUERY: Get all available countries --->
<cfset countriesQuery = CWquerySelectCountries(0)>
<!--- if only one country, set page ID to that value --->
<cfif countriesQuery.recordCount is 1>
	<cfset request.cwpage.currentID = countriesQuery.country_id>
</cfif>
<!--- QUERY: Get all available active states for the country in url --->
<cfset stateprovQuery = CWquerySelectStates(request.cwpage.currentID)>
<cfset stateProvQuery = CWsortableQuery(stateProvQuery)>
<!--- /////// --->
<!--- UPDATE SHIP EXTENSIONS --->
<!--- /////// --->
<!--- look for at least one valid ID field --->
<cfif isDefined('form.stateprov_ship_ext1')>
	<cfset loopCt = 1>
	<cfset updateCt = 0>
	<!--- loop record ids, handle each one as needed --->
	<cfloop list="#form.recordIDlist#" index="ID">
		<!--- UPDATE RECORDS --->
		<!--- verify numeric values --->
		<cfif NOT isNumeric(#form["stateprov_ship_ext#loopct#"]#)>
			<cfset #form["stateprov_ship_ext#loopct#"]# = 0>
		</cfif>
		<cfif NOT isNumeric(#form["stateprov_tax#loopct#"]#)>
			<cfset #form["stateprov_tax#loopct#"]# = 0>
		</cfif>
		<!--- set up tax rate depending on application setting --->
		<cfif application.cw.taxSystem EQ "Groups">
			<!--- value lt 0 is ignored by the update function --->
			<cfset taxExt = -1>
		<!--- if not groups, use the live rate --->
		<cfelse>
			<cfset taxExt = #form["stateprov_tax#loopct#"]#>
		</cfif>
		<!--- QUERY: update record (ID, name, rate, order, archived) --->
		<cfset updateRecord = CWqueryUpdateShippingExtension(
		#form["stateprov_id#loopct#"]#,
		#form["stateprov_ship_ext#loopct#"]#,
		taxExt
		)>
		<cfset updateCt = updateCt + 1>
		<cfset loopCt = loopCt + 1>
	</cfloop>

	<!--- get the vars to keep by omitting the ones we don't want repeated --->
	<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert")>
	<!--- set up the base url --->
	<cfset request.cwpage.relocateUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
	<!--- save confirmation text --->
	<cfset CWpageMessage("confirm","Changes Saved")>
	<!--- return to page as submitted, clearing form scope --->
	<cflocation url="#request.cwpage.relocateUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- END UPDATE / DELETE SHIP METHODS --->
<!--- /////// --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Manage #application.cw.taxSystemLabel# & Shipping Extensions">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "#application.cw.taxSystemLabel# & Shipping Extensions Management">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 =  "Control ship or #lcase(application.cw.taxSystemLabel)# cost extensions by country">
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
		// select country changes page location
		function groupSelect(selBox){
		 	var viewID = jQuery(selBox).val();
			if (viewID >= 1){
		 	window.location = '<cfoutput>#request.cw.thisPage#?country_id=</cfoutput>' + viewID;
			}
		};
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
						<!--- /////// --->
						<!--- SELECT COUNTRY --->
						<!--- /////// --->
						<cfif countriesQuery.recordCount gt 1>
							<table class="CWinfoTable">
								<tr class="headerRow"><th>Select Country</th></tr>
								<tr>
									<td>
										<form name="selectCountryForm" action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>">
											<select name="selectCountry" id="selectCountry" onchange="groupSelect(this);">
												<cfif request.cwpage.currentID eq 0><option value="0">Select Country</option></cfif>
												<cfoutput query="countriesQuery">
												<option value="#country_id#"<cfif request.cwpage.currentID eq country_id> selected="selected"</cfif>>#country_name#</option>
												</cfoutput>
											</select>
										</form>
									</td>
								</tr>
							</table>
						</cfif>
						<!--- /////// --->
						<!--- /END SELECT COUNTRY --->
						<!--- /////// --->
						<!--- /////// --->
						<!--- EDIT RECORDS --->
						<!--- /////// --->
						<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" name="recordForm" id="recordForm" method="post" class="CWobserve">
							<!--- if no records found, show message --->
							<cfif not request.cwpage.currentID gt 0>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p><strong>Select a country above</strong> <br>or use the <a href="countries.cfm">Countries</a> page to set up shipping regions.<br></p>
								<!--- if records found --->
							<cfelse>
								<!--- output records --->
								<!--- Container table --->
								<table class="CWinfoTable wide">
									<thead>
									<tr class="headerRow">
										<th>Active Shipping Extensions</th>
									</tr>
									</thead>
									<tbody>
									<tr>
										<td>
											<!--- if no records found --->
											<cfif not stateprovQuery.recordCount>
												<p>&nbsp;</p>
												<p>&nbsp;</p>
												<p>&nbsp;</p>
												<p><strong>No Shipping Extensions available for this country.</strong> <br><br></p>
												<!--- if records found --->
											<cfelse>
												<input type="hidden" value="
												<cfoutput>#stateprovQuery.RecordCount#</cfoutput>" name="stateprovCounter">
												<!--- save changes submit button --->
												<input name="SubmitUpdate" type="submit" class="CWformButton" id="SubmitUpdate" value="Save Changes">
												<div style="clear:right;"></div>
												<!--- LOOP METHODS BY COUNTRY --->
												<cfset countryCt = 0>
												<cfoutput query="stateprovQuery" group="country_id">
												<!--- Country Table --->
												<table class="CWinfoTable">
													<tr class="headerRow">
														<th><h3>#country_name#</h3></th>
													</tr>
													<tr>
														<td>
															<!--- Method Records Table --->
															<table class="CWstripe <cfif stateProvQuery.recordCount gt 1>CWsort</cfif>" summary="#request.cwpage.baseUrl#">
																<thead>
																<tr class="sortRow">
																	<!--- state code and name --->
																	<cfif stateprov_code neq "None">
																		<th style="text-align:center" class="stateprov_code">Code</th>
																		<th style="text-align:center" class="stateprov_name">Name</th>
																	</cfif>
																	<!--- tax --->
																	<cfif application.cw.taxCalctype is 'localTax'>
																	<th style="text-align:center" class="stateprov_tax">#application.cw.taxSystemLabel# Ext. %</th>
																	</cfif>
																	<!--- shipping --->
																	<th style="text-align:center" class="stateprov_ship_ext">Ship Ext. %</th>
																</tr>
																</thead>
																<tbody>
																<cfoutput>
																<cfif stateprov_code eq "None">
																	<cfset CurrentState = country_name>
																<cfelse>
																	<cfset CurrentState = stateprov_name>
																</cfif>
																<tr>
																	<!--- state code and name --->
																	<cfif stateprov_code neq "None">
																		<td>#stateprov_code#</td>
																		<td>#stateprov_name#</td>
																	</cfif>
																	<!--- tax --->
																	<cfif application.cw.taxCalctype is 'localTax'>
																	<td style="text-align:center;">
																		<cfif isDefined('application.cw.taxsystem') and application.cw.taxSystem eq 'groups'>
																			<input name="stateprov_tax#CurrentRow#" type="text" readonly="readonly" value="#LSNumberFormat(stateprov_tax,'9.9999')#" onclick="alert('Using #application.cw.taxSystemLabel# Groups. Set #application.cw.taxSystemLabel# System to General to enable editing rates here.')" size="6">
																		<cfelse>
																			<input name="stateprov_tax#CurrentRow#" type="text" value="#LSNumberFormat(stateprov_tax,'9.9999')#" size="6" onkeyup="extractNumeric(this,4,true);" onblur="checkValue(this);">
																		</cfif>
																		<!--- hidden id field --->
																		<input name="stateprov_id#CurrentRow#" type="hidden" id="stateprov_id#CurrentRow#" value="#stateprov_id#">
																		<input name="recordIDlist" type="hidden" value="#stateprovQuery.stateprov_id#">
																	</td>
																	</cfif>
																	<!--- shipping --->
																	<td style="text-align:center;">
																		<input name="stateprov_ship_ext#CurrentRow#" type="text" class="required" title="Ship Extension required (numeric)" value="#LSNumberFormat(stateprov_ship_ext,'9.9999')#" size="6" onkeyup="extractNumeric(this,4,true);" onblur="checkValue(this);">
																	</td>
																</tr>
																</cfoutput>
																</tbody>
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
												<cfif countryCt gt 1 or stateprovQuery.recordCount gt 9>
													<input name="SubmitUpdate" type="submit" class="CWformButton" id="SubmitUpdate" value="Save Changes">
												</cfif>
											</cfif>
											<!--- /end if records exist --->
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