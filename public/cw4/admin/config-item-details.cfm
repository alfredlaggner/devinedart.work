<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: config-item-details.cfm
File Date: 2012-02-01
Description: Displays config item details
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
<!--- default item ID --->
<cfparam name="url.item_ID" type="numeric" default="0">
<cfparam name="request.cwpage.userAlert" default="">
<cfparam name="request.cwpage.userConfirm" default="">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert,resetapplication")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- current record --->
<cfparam name="request.cwpage.currentRecord" default="#url.item_ID#">
<!--- QUERY: get config item details (id, name, variable) --->
<cfset configItemQuery = CWquerySelectConfigItemDetails(request.cwpage.currentRecord,'','')>
<!--- if none found, send back to config groups page --->
<cfif configItemQuery.recordCount lt 1>
<cflocation url="config-groups.cfm" addtoken="false">
</cfif>
<!--- QUERY: get config group details --->
<cfset configGroupQuery = CWquerySelectConfigGroupDetails(configItemQuery.config_group_id,'')>
<!--- current record name --->
<cfset request.cwpage.itemName = configitemQuery.config_name>
<cfset request.cwpage.currentGroup = configItemQuery.config_group_id>
<!--- current group name --->
<cfset request.cwpage.groupName = configGroupQuery.config_group_name>
<!--- /////// --->
<!--- UPDATE CONFIG ITEM --->
<!--- /////// --->
<!--- look for at least one valid ID field --->
<cfif isDefined('form.update_ID')>
	<!--- checkbox values --->
	<cfparam name="form.config_reqd" default="0">
	<cfparam name="form.config_show_merchant" default="0">
	<!--- UPDATE RECORD --->
	<!--- QUERY: update config item (
	item ID, group ID, variable, name, value, type, description,
	possibles, showmerchant, sort, size, rows, protected, required)--->
	<cfset updateRecordID = CWqueryUpdateConfigItem(
	#form.config_ID#,
	#request.cwpage.currentGroup#,
	#form.config_variable#,
	#form.config_name#,
	#form.config_value#,
	#form.config_type#,
	#form.config_description#,
	#form.config_possibles#,
	#form.config_show_merchant#,
	#form.config_sort#,
	#form.config_size#,
	#form.config_rows#,
	#form.config_protected#,
	#form.config_reqd#
	)>
	<!--- if an error is returned from update query --->
	<cfif left(updateRecordID,2) eq '0-'>
		<cfset errorMsg = listLast(updateRecordID,'-')>
		<cfset CWpageMessage("alert",errorMsg)>
		<!--- if no error --->
	<cfelse>
		<!--- set the new application variable --->
		<cfset application.cw[form.config_variable] = form.config_value>
		<!--- build confirmation message --->
		<cfset CWpageMessage("confirm","Config Item Updated")>
	</cfif>
	<!--- end error check --->
	<!--- get the vars to keep by omitting the ones we don't want repeated --->
	<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert,method,resetapplication")>
	<!--- set up the base url --->
	<cfset request.cwpage.relocateUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
	<!--- return to page as submitted, clearing form scope --->
	<cflocation url="#request.cwpage.relocateUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&useralert=#CWurlSafe(request.cwpage.userAlert)#&resetapplication=#application.cw.storePassword#" addtoken="no">
</cfif>
<!--- /END UPDATE CONFIG ITEM --->
<!--- /////// --->
<!--- DELETE CONFIG ITEM --->
<!--- /////// --->
<cfif isDefined('form.deleteItemID') and form.deleteItemID eq request.cwpage.currentRecord>
	<!--- QUERY: delete item (item id) --->
	<cfset deleteGroup = CWqueryDeleteConfigItem(request.cwpage.currentRecord)>
	<!--- if item was deleted --->
	<cfif left(deleteGroup,2) neq '0-'>
		<cfset CWpageMessage("alert","Config Item '#request.cwpage.itemName#' deleted")>
		<cflocation url="config-group-details.cfm?group_ID=#request.cwpage.currentGroup#&useralert=#CWurlSafe(request.cwpage.userAlert)#&resetapplication=#application.cw.storePassword#">
		<!--- if item not deleted --->
	<cfelse>
		<cfset CWpageMessage("alert","Config item '#request.cwpage.itemName#' is protected and cannot be deleted")>
	</cfif>
</cfif>
<!--- /END DELETE CONFIG ITEM --->
<!--- default form values --->
<cfparam name="form.config_id" default="#request.cwpage.currentRecord#">
<cfparam name="form.config_name" default="#configItemQuery.config_name#">
<cfparam name="form.config_variable" default="#configItemQuery.config_variable#">
<cfparam name="form.config_sort" default="#configItemQuery.config_sort#">
<cfparam name="form.config_type" default="#configItemQuery.config_type#">
<cfparam name="form.config_value" default="#configItemQuery.config_value#">
<cfparam name="form.config_possibles" default="#configItemQuery.config_possibles#">
<cfparam name="form.config_description" default="#configItemQuery.config_description#">
<cfparam name="form.config_size" default="#configItemQuery.config_size#">
<cfparam name="form.config_rows" default="#configItemQuery.config_rows#">
<cfparam name="form.config_reqd" default="#configItemQuery.config_required#">
<cfparam name="form.config_protected" default="#configItemQuery.config_protected#">
<cfparam name="form.config_show_merchant" default="#configItemQuery.config_show_merchant#">
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title
<title>
--->
<cfset request.cwpage.title = "Update Config Item">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Manage Config Item: #request.cwpage.itemName#">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = 'In Group: #request.cwpage.groupName# &nbsp; <a href="config-group-details.cfm?group_ID=#request.cwpage.currentGroup#">View Group</a>'>
<!--- current menu marker --->
<cfset request.cwpage.currentNav = 'config-groups.cfm'>
<!--- load form scripts --->
<cfset request.cwpage.isFormPage = 1>
<!--- load table scripts --->
<cfset request.cwpage.isTablePage = 0>
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
						<cfif not configItemQuery.recordCount is 1>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>Invalid config item id. Please return to the <a href="config-group-details.cfm?group_ID=#request.cwpage.currentGroup#">Config Items List</a> and choose a valid group.</p>
							<!--- if a record is found --->
						<cfelse>
							<!--- /////// --->
							<!--- UPDATE CONFIG ITEM --->
							<!--- /////// --->
							<p>&nbsp;</p>
							<h3>Edit Config Item Details</h3>
							<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" class="CWvalidate" name="addNewForm" id="addNewForm" method="post">
								<table class="CWinfoTable CWformTable">
									<tr>
										<th class="label">Item Name</th>
										<td><input name="config_name" type="text" size="25" maxlength="254" id="config_name" class="required focusField" title="Variable Name is required" value="<cfoutput>#form.config_name#</cfoutput>" onblur="checkValue(this)"></td>
									</tr>
									<tr>
										<th class="label">Variable</th>
										<td><input name="config_variable" type="text" size="25" maxlength="254" id="config_variable" class="required" title="Variable is required" value="<cfoutput>#form.config_variable#</cfoutput>" onblur="checkValue(this)"></td>
									</tr>
									<tr>
										<th class="label">Sort Order</th>
										<td><input name="config_sort" type="text" id="config_sort" class="required sort" maxlength="7" size="4" title="Sort Order is required" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);" value="<cfoutput>#form.config_sort#</cfoutput>"></td>
									</tr>
									<cfparam name="fieldType" default="#form.config_type#">
									<cfset v = trim(fieldType)>
									<tr>
										<th class="label">Form Input Type</th>
										<td scope="col">
											<select name="config_type" id="config_type" class="required" title="Form Input Type is required">
												<option value=""<cfif v eq ''> selected="selected"</cfif>>Choose Form Field Type</option>
												<option value="text"<cfif v eq 'text'> selected="selected"</cfif> multivalue="false">Text Field</option>
												<option value="number"<cfif v eq 'number'> selected="selected"</cfif> multivalue="false">Numeric Input</option>
												<option value="textarea"<cfif v eq 'textarea'> selected="selected"</cfif> multivalue="false">Textarea</option>
												<option value="texteditor"<cfif v eq 'texteditor'> selected="selected"</cfif> multivalue="false">Text Editor (rich text)</option>
												<option value="boolean"<cfif v eq 'boolean'> selected="selected"</cfif> multivalue="false">Checkbox (single)</option>
												<option value="checkboxgroup"<cfif v eq 'checkboxgroup'> selected="selected"</cfif> multivalue="true">Checkbox Group</option>
												<option value="radio"<cfif v eq 'radio'> selected="selected"</cfif> multivalue="true">Radio Group</option>
												<option value="select"<cfif v eq 'select'> selected="selected"</cfif> multivalue="true">Select List</option>
												<option value="multiselect"<cfif v eq 'multiselect'> selected="selected"</cfif> multivalue="true">Multiple Select List</option>
											</select>
										</td>
									</tr>
									<tr id="valueRow">
										<th class="label">Value</th>
										<td>
											<!--- payment methods should not be edited here --->
											<cfif form.config_variable is 'paymentMethods'>
												<div style="display:none;">
												<input name="config_value" type="text" id="config_value" value="<cfoutput>#form.config_value#</cfoutput>">
												</div>
												<div class="smallPrint">Use config setting checkboxes to enable selected methods</div>
											<!--- theme directory not edited here --->
											<cfelseif form.config_variable is 'adminThemeDirectory'>
												<div style="display:none;">
												<input name="config_value" type="text" id="config_value" value="<cfoutput>#form.config_value#</cfoutput>">
												</div>
												<div class="smallPrint">Use select box in config item settings to select active theme</div>
											<cfelse>
												<input name="config_value" type="text" id="config_value" value="<cfoutput>#form.config_value#</cfoutput>">
											</cfif>

										</td>
									</tr>
									<tr id="possiblesRow">
										<th class="label">Possible Values</th>
										<td>
											<!--- payment methods should not be edited here --->
											<cfif form.config_variable is 'paymentMethods'>
												<div style="display:none;">
													<textarea name="config_possibles" cols="40" rows="4" type="text" id="config_possibles"><cfoutput>#form.config_possibles#</cfoutput></textarea>
												</div>
												<div class="smallPrint">Automatically generated via settings in cwapp/auth/ payment configuration files</div>
											<!--- theme directory not edited here --->
											<cfelseif form.config_variable is 'adminThemeDirectory'>
												<div style="display:none;">
													<textarea name="config_possibles" cols="40" rows="4" type="text" id="config_possibles"><cfoutput>#form.config_possibles#</cfoutput></textarea>
												</div>
												<div class="smallPrint">Automatically generated via theme directories in cw4/admin/theme/</div>
											<cfelse>
											<textarea name="config_possibles" cols="40" rows="4" type="text" id="config_possibles"><cfoutput>#form.config_possibles#</cfoutput></textarea>
											<div class="smallPrint">Enter one Name|Value pair per line</div>
											</cfif>
										</td>
									</tr>
									<tr>
										<th class="label">Help Description</th>
										<td>
											<textarea name="config_description" cols="40" rows="2" type="text" id="config_description"><cfoutput>#form.config_description#</cfoutput></textarea>
											<div class="smallPrint">The descriptive help context for config form users</div>
										</td>
									</tr>
									<tr id="sizeRow">
										<th class="label">Size</th>
										<td><input name="config_size" type="text" id="config_size" class="required" maxlength="3" size="3" title="Size of input is required" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);" value="<cfoutput>#form.config_size#</cfoutput>"></td>
									</tr>
									<tr id="rowsRow">
										<th class="label">Rows</th>
										<td><input name="config_rows" type="text" id="config_rows" class="required" maxlength="3" size="3" title="Number of rows is required" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);" value="<cfoutput>#form.config_rows#</cfoutput>"></td>
									</tr>
									<tr id="requiredRow">
										<th class="label">Required in Form</th>
										<td><input name="config_reqd" type="checkbox" class="formCheckbox" id="config_reqd" value="1"<cfif form.config_reqd is 1> checked="checked"</cfif>></td>
									</tr>
									<tr>
										<th class="label">Show Merchant</th>
										<td><input name="config_show_merchant" type="checkbox" class="formCheckbox" id="config_show_merchant" value="1"<cfif form.config_show_merchant is 1> checked="checked"</cfif>></td>
									</tr>
									<tr>
										<td colspan="2">
											<input type="submit" class="CWformButton" value="Save Changes">
											<cfoutput>
											<input type="hidden" name="config_ID" value="#request.cwpage.currentRecord#">
											<input type="hidden" name="update_ID" value="#request.cwpage.currentRecord#">
											<cfif isNumeric(configitemQuery.config_protected)>
											<input name="config_protected" type="hidden" value="#configitemQuery.config_protected#">
											<cfelse>
											<input name="config_protected" type="hidden" value="0">
											</cfif>
											</cfoutput>
										</td>
									</tr>
								</table>
							</form>
							<!--- /////// --->
							<!--- DELETE CONFIG ITEM --->
							<!--- /////// --->
							<cfif configItemQuery.config_protected is 1>
								<p>This custom variable cannot be deleted</p>
							<cfelse>
								<form method="post" name="deleteConfigItem">
									<input name="deleteItemID" type="hidden" value="<cfoutput>#request.cwpage.currentRecord#</cfoutput>">
									<p><input name="deleteConfigItem" type="submit" class="deleteButton" value="Delete"></p>
								</form>
							</cfif>
							<!--- /////// --->
							<!--- /END DELETE CONFIG ITEM --->
							<!--- /////// --->
						</cfif>
						<!--- /////// --->
						<!--- /END UPDATE CONFIG ITEM --->
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