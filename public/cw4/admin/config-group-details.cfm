<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: config-group-details.cfm
File Date: 2012-09-05
Description: Displays details and config items for any config group, handles adding new config item
==========================================================
--->
<!--- GLOBAL INCLUDES --->
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("developer")>
<!--- PAGE PARAMS --->
<!--- default values for sort --->
<cfparam name="url.sortby" default="config_sort" type="string">
<cfparam name="url.sortdir" default="asc" type="string">
<!--- default group ID --->
<cfparam name="url.group_id" default="0" type="integer">
<!--- current record params --->
<cfparam name="request.cwpage.groupName" default="">
<cfparam name="request.cwpage.currentRecord" default="#url.group_id#">
<!--- allow editing of field type in list view --->
<cfparam name="application.cw.configSelectType" default="1">	
<cfif not isNumeric(application.cw.configSelectType)>
	<cfset application.cw.configSelectType = 1>
</cfif>
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,userconfirm,useralert,clickadd,resetapplication")>
<!--- create the base url for sorting out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- QUERY: get config group details --->
<cfset configGroupQuery = CWquerySelectConfigGroupDetails(url.group_id,'')>
<!--- if none found, send back to config groups page --->
<cfif configGroupQuery.recordCount lt 1>
<cflocation url="config-groups.cfm" addtoken="false">
</cfif>
<!--- QUERY: get config items in this group --->
<cfset itemsQuery = CWquerySelectConfigItems(url.group_id)>
<!--- make query sortable --->
<cfset itemsQuery = CWsortableQuery(itemsQuery)>
<!--- QUERY: get all  config groups --->
<cfset configGroupsListQuery = CWquerySelectConfigGroups()>
<!--- set page variables --->
<cfset request.cwpage.groupName = configGroupQuery.config_group_name>
<!--- use rich text editor  y/n --->
<cfparam name="request.cwpage.rte" default="0">
<cfif valueList(itemsQuery.config_type) contains 'texteditor' AND application.cw.adminEditorEnabled is not 0>
	<cfset rteFields = ''>
	<cfset request.cwpage.rte = 1>
</cfif>
<!--- form values --->
<!--- config group form --->
<cfparam name="form.config_group_name" default="#request.cwpage.groupName#">
<cfparam name="form.config_group_sort" default="#configGroupQuery.config_group_sort#">
<cfparam name="form.config_group_show_merchant" default="0">
<!--- config items form --->
<cfparam name="form.config_name" default="">
<cfparam name="form.config_variable" default="">
<cfparam name="form.config_sort" default="1">
<cfparam name="form.config_type" default="">
<cfparam name="form.config_value" default="">
<cfparam name="form.config_possibles" default="">
<cfparam name="form.config_description" default="">
<cfparam name="form.config_size" default="35">
<cfparam name="form.config_rows" default="5">
<cfparam name="form.config_reqd" default="0">
<cfparam name="form.config_protected" default="0">
<cfparam name="form.config_show_merchant" default="0">
<!--- param for delete checkbox --->
<cfparam name="form.deleteRecord" default="0">
<cfparam name="fieldProtectCt" default="0">
<!--- /////// --->
<!--- UPDATE CONFIG GROUP --->
<!--- /////// --->
<!--- if the update_ID was submitted, and matches the url ID --->
<cfif isDefined('form.update_ID') and form.update_ID eq request.cwpage.currentRecord>
	<!--- QUERY: update config group (ID, name, sort, show merchant)--->
	<cfset updateRecordID = CWqueryUpdateConfigGroup(
	form.update_ID,
	form.config_group_name,
	form.config_group_sort,
	form.config_group_show_merchant
	)>
	<!--- if no error returned from update query --->
	<cfif not left(updateRecordID,2) eq '0-'>
		<!--- update complete: return to page showing message --->
		<cfset CWpageMessage("confirm","Config Group Saved")>
		<cflocation url="#request.cwpage.baseUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&sortby=#url.sortby#&sortdir=#url.sortdir#&resetapplication=#application.cw.storePassword#" addtoken="no">
		<!--- if we have an insert error, show message, do not insert --->
	<cfelse>
		<cfset CWpageMessage("alert",listLast(updateRecordID,'-'))>
	</cfif>
	<!--- end error check --->
</cfif>
<!--- /////// --->
<!--- /END UPDATE CONFIG GROUP --->
<!--- /////// --->
<!--- /////// --->
<!--- ADD NEW CONFIG ITEM --->
<!--- /////// --->
<cfif isDefined('form.config_Name') and len(trim(form.config_Name))>
	<!--- QUERY: insert new config item (
	group ID, variable, name, value, type, description,
	possibles, showmerchant, sort, size, rows, protected, required)--->
	<!--- this query returns the new id, or a 0- error --->
	<cfset newRecordID = CWqueryInsertConfigItem(
	#request.cwpage.currentRecord#,
	'#trim(form.config_variable)#',
	'#trim(form.config_name)#',
	'#trim(form.config_value)#',
	'#trim(form.config_type)#',
	'#trim(form.config_description)#',
	'#trim(form.config_possibles)#',
	#form.config_show_merchant#,
	#form.config_sort#,
	#form.config_size#,
	#form.config_rows#,
	#form.config_protected#,
	#form.config_reqd#
	)>
	<!--- if no error returned from insert query --->
	<cfif not left(newRecordID,2) eq '0-'>
		<!--- update complete: return to page showing message --->
		<cfset CWpageMessage("confirm","Config Item '#trim(form.config_Name)#' Added")>
		<cflocation url="#request.cwpage.baseUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&sortby=#url.sortby#&sortdir=#url.sortdir#&resetapplication=#application.cw.storePassword#" addtoken="no">
		<!--- if we have an insert error, show message, do not insert --->
	<cfelse>
		<cfset errorMsg = listLast(newRecordID,'-')>
		<cfset CWpageMessage("alert","Error: #errorMsg#")>
		<cfset url.clickadd = 1>
	</cfif>
	<!--- /END duplicate/error check --->
</cfif>
<!--- /////// --->
<!--- /END ADD NEW CONFIG ITEM --->
<!--- /////// --->
<!--- /////// --->
<!--- UPDATE/DELETE CONFIG ITEMS --->
<!--- /////// --->
<!--- look for at least one valid ID field --->
<cfif isDefined('form.config_ID1')>
	<cfset loopCt = 1>
	<cfset updateCt = 0>
	<cfset deleteCt = 0>
	<!--- loop record ids, handle each one as needed --->
	<cfloop list="#form.recordIDlist#" index="ID">
		<!--- DELETE CONFIG ITEMS --->
		<!--- if the record ID is marked for deletion --->
		<cfif listFind(form.deleteRecord,evaluate('form.config_ID'&loopCt))>
			<!--- QUERY: delete record (record id) : returns a message --->
			<cfset deleteRecord = CWqueryDeleteConfigItem(id)>
			<cfif left(deleteRecord,2) eq '0-'>
				<cfset CWpageMessage("alert","#deleteRecord#")>
			<cfelse>
				<cfset deleteCt = deleteCt + 1>
			</cfif>
			<!--- if not deleting, update --->
		<cfelse>
			<!--- UPDATE RECORDS --->
			<!--- param value for checkboxes --->
			<cfparam name="form['config_value#loopct#']" default="0">
			<!--- QUERY: update config item (
			item ID, group ID, variable, name, value, type, description,
			possibles, showmerchant, sort)--->
			<cfset updateRecordID = CWqueryUpdateConfigItem(
									#form["config_ID#loopct#"]#,
									#request.cwpage.currentRecord#,
									#form["config_variable#loopct#"]#,
									#form["config_name#loopct#"]#,
									#form["config_value#loopct#"]#,
									#form["config_type#loopct#"]#,
									#form["config_description#loopct#"]#,
									#form["config_possibles#loopct#"]#,
									#form["config_show_merchant#loopct#"]#,
									#form["config_sort#loopct#"]#
									)>
			<!--- if an error is returned from update query --->
			<cfif left(updateRecordID,2) eq '0-'>
				<cfset errorMsg = listLast(updateRecordID,'-')>
				<cfset CWpageMessage("alert","#errorMsg#")>
				<!--- if no error --->
			<cfelse>
				<!--- create application variable  --->
				<cfset application.cw[form["config_variable#loopct#"]] = form["config_value#loopct#"] >
				<!--- update complete: continue processing --->
				<cfset updateCt = updateCt + 1>
			</cfif>
			<!--- /END delete vs. update --->
		</cfif>
		<!--- end error check --->
		<cfset loopCt = loopCt + 1>
	</cfloop>
	<!--- set mandatory tax settings if not localtax --->
	<cfif isDefined('application.cw.taxCalctype') and application.cw.taxCalctype is not 'localTax'>
		<cfset setTaxRequirements = CWsetNonLocalTaxOptions()>
		<cfset CWpageMessage("alert","Note: Tax settings adjusted to match #application.cw.taxCalctype# requirements")>
	</cfif>
	<!--- get the vars to keep by omitting the ones we don't want repeated --->
	<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert,method,resetapplication")>
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
	<cflocation url="#request.cwpage.relocateUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&useralert=#CWurlSafe(request.cwpage.userAlert)#&resetapplication=#application.cw.storePassword#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END UPDATE / DELETE CONFIG ITEMS --->
<!--- /////// --->
<!--- /////// --->
<!--- DELETE CONFIG GROUP --->
<!--- /////// --->
<cfif isDefined('form.deleteGroupID') and form.deleteGroupID eq request.cwpage.currentRecord>
	<!--- verify no items exist for this group --->
	<cfif itemsQuery.recordCount>
		<cfset CWpageMessage("alert","This group contains #itemsQuery.recordCount# active config items and cannot be deleted")>
	<cfelse>
		<!--- delete group --->
		<!--- QUERY: delete group (group id) --->
		<cfset deleteGroup = CWqueryDeleteConfigGroup(request.cwpage.currentRecord)>
		<cflocation url="config-groups.cfm?useralert=Config Group '#request.cwpage.groupName#' deleted&resetapplication=#application.cw.storePassword#">
	</cfif>
</cfif>
<!--- /////// --->
<!--- /END DELETE CONFIG GROUP --->
<!--- /////// --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Manage Config Group">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Manage Config Group: #request.cwpage.groupName#">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 =  'Create custom variables and manage variable values &nbsp; <a href="config-settings.cfm?group_ID=#url.group_id#">View Settings Page</a>'>
<!--- current menu marker --->
<cfset request.cwpage.currentNav = "config-groups.cfm">
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
		// select option group changes page location
		function groupSelect(selBox){
		 	var viewID = jQuery(selBox).val();
			if (viewID >= 1){
			window.location = '<cfoutput>#request.cw.thisPage#?group_ID=</cfoutput>' + viewID;
			}
		};
		jQuery(document).ready(function(){
			// add new show-hide
			jQuery('form#addNewForm').hide();
			jQuery('a#showAddNewFormLink').click(function(){
				jQuery(this).hide().siblings('a').show();
				jQuery('form#addNewForm').show().find('input.focusField').focus();
				return false;
			});
			jQuery('a#hideAddNewFormLink').hide().click(function(){
				jQuery(this).hide().siblings('a').show();
				jQuery('form#addNewForm').hide();
				return false;
			});
			// auto-click the link if adding
			<cfif isDefined('url.clickadd')>
				jQuery('a#showAddNewFormLink').click();
			</cfif>
			// show help in config items list
			jQuery('#recordForm a.showHelpLink').click(function(){
			jQuery(this).parents('td').siblings('td').children('.helpText').toggle();
			return false;
			}).parents('td').click(function(){
			jQuery(this).children('a').click();
			});

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
						<!--- if a valid record is not found --->
						<cfif not configGroupQuery.recordCount eq 1>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>Invalid config group id. Please return to the <a href="config-groups.cfm">Config Groups List</a> and choose a valid group.</p>
							<!--- if a record is found --->
						<cfelse>
							<!--- /////// --->
							<!--- UPDATE CONFIG GROUP --->
							<!--- /////// --->
							<!--- FORM --->
							<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" class="CWobserve" name="updateConfigGroupForm" id="updateConfigGroupForm" method="post">
								<p>&nbsp;</p>
								<h3>Edit Config Group Details</h3>
								<table class="CWinfoTablesa">
									<thead>
									<tr>
										<th width="165">Config Group Name</th>
										<th>Sort</th>
										<th width="120" style="text-align:center">Show Merchant</th>
									</tr>
									</thead>
									<tbody>
									<tr>
										<td>
											<!--- group name --->
											<div>
												<!--- select changes to new page --->
												<select name="config_group_id" id="config_group_id" onchange="groupSelect(this);">
													<cfoutput query="configGroupsListQuery">
													<option value="#config_group_id#"<cfif request.cwpage.currentRecord eq config_group_id> selected="selected"</cfif>>#config_group_name#</option>
													</cfoutput>
												</select>
												<div class="smallPrint"><a href="config-groups.cfm?clickadd=1">Add New Group</a></div>
											</div>
										</td>
										<!--- sort --->
										<td>
											<input name="config_group_sort" type="text" class="{required:true}" title="Sort Order is required" value="<cfoutput>#form.config_group_sort#</cfoutput>" size="5" maxlength="7" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
										</td>
										<!--- show merchant y/n --->
										<td style="text-align:center">
											<input name="config_group_show_merchant" type="checkbox" <cfif form.config_group_show_merchant OR configgroupQuery.config_group_show_merchant>checked="checked"</cfif> class="formCheckbox" value="1">
											<br>
											<input name="SubmitAdd" type="submit" class="CWformButton" id="SubmitAdd" value="Save Group Details">
										</td>
									</tr>
									</tbody>
								</table>
								<input type="hidden" name="config_group_name" value="<cfoutput>#request.cwpage.groupName#</cfoutput>">
								<input type="hidden" name="update_ID" value="<cfoutput>#request.cwpage.currentrecord#</cfoutput>">
							</form>
							<!--- /////// --->
							<!--- /END UPDATE CONFIG GROUP --->
							<!--- /////// --->
							<!--- /////// --->
							<!--- ADD NEW CONFIG ITEM --->
							<!--- /////// --->
							<p>&nbsp;</p>
							<h3>Add New Config Item in '<cfoutput>#request.cwpage.groupName#</cfoutput>'</h3>
							<!--- link for add-new form --->
							<div class="CWadminControlWrap">
								<a class="CWbuttonLink" id="showAddNewFormLink" href="#">Add New Config Item</a>
								<a class="deleteLink" id="hideAddNewFormLink" href="#">Cancel</a>
							</div>
							<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" class="CWvalidate" name="addNewForm" id="addNewForm" method="post">
								<table class="CWinfoTable CWformTable">
									<tr>
										<th class="label">Item Name</th>
										<td><input name="config_name" type="text" size="25" maxlength="254" id="config_name" class="required focusField" title="Variable Name is required" value="<cfoutput>#form.config_name#</cfoutput>"></td>
									</tr>
									<tr>
										<th class="label">Variable</th>
										<td><input name="config_variable" type="text" size="25" maxlength="254" id="config_variable" class="required" title="Variable is required" value="<cfoutput>#form.config_variable#</cfoutput>"></td>
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
										<td><input name="config_value" type="text" id="config_value" value="<cfoutput>#form.config_value#</cfoutput>"></td>
									</tr>
									<tr id="possiblesRow">
										<th class="label">Possible Values</th>
										<td>
											<textarea name="config_possibles" cols="40" rows="4" type="text" id="config_possibles"><cfoutput>#form.config_possibles#</cfoutput></textarea>
											<div class="smallPrint">Enter one Name|Value pair per line</div>
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
									<tr>
										<th class="label">Prevent Deletion</th>
										<td><input name="config_protected" type="checkbox" class="formCheckbox" id="config_protected" value="1"<cfif form.config_protected> checked="checked"</cfif>></td>
									</tr>
									<tr id="requiredRow">
										<th class="label">Required in Form</th>
										<td><input name="config_reqd" type="checkbox" class="formCheckbox" id="config_reqd" value="1"<cfif form.config_reqd> checked="checked"</cfif>></td>
									</tr>
									<tr>
										<th class="label">Show Merchant</th>
										<td><input name="config_show_merchant" type="checkbox" class="formCheckbox" id="config_show_merchant" value="1"<cfif form.config_show_merchant> checked="checked"</cfif>></td>
									</tr>
									<tr>
										<td colspan="2">
											<input type="submit" class="CWformButton" value="Add New Configuration Item">
										</td>
									</tr>
								</table>
							</form>
							<!--- /////// --->
							<!--- /END ADD NEW CONFIG ITEM --->
							<!--- /////// --->
							<!--- /////// --->
							<!--- UPDATE CONFIG ITEMS --->
							<!--- /////// --->
							<p>&nbsp;</p>
							<h3>Active Config Items</h3>
							<!--- check for existing records --->
							<cfif NOT itemsQuery.recordCount>
								<p>&nbsp;</p>
								<p>There are currently no config items defined for this group</p>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<!--- DELETE GROUP --->
								<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" name="deleteGroupForm" id="deleteGroupForm" method="post">
									<input name="deleteGroupID" type="hidden" value="<cfoutput>#request.cwpage.currentRecord#</cfoutput>">
									<!--- delete button --->
									<p><input name="SubmitDelete" type="submit" class="deleteButton" id="DeleteGroup" value="Delete Group"></p>
								</form>
								<!--- /END DELETE GROUP --->
								<!--- if existing records found --->
							<cfelse>
								<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" name="recordForm" id="recordForm" method="post">
									<table class="CWsort CWstripe" summary="<cfoutput>#request.cwpage.baseUrl#</cfoutput>">
										<thead>
										<tr class="sortRow">
											<th class="noSort" style="text-align:center;" width="50">Edit</th>
											<th>Help</th>
											<th class="config_name" width="305">Variable Name</th>
											<th class="config_variable" width="145">Application Variable</th>
											<th class="config_value">Value</th>
											<cfif application.cw.configSelectType eq 1>
												<th class="config_type">Type</th>
											</cfif>
											<th class="config_sort">Sort</th>
											<th class="noSort" width="50" style="text-align:center;">Delete</th>
										</tr>
										</thead>
										<tbody>
										<cfoutput query="itemsQuery">
										<cfsilent>
										<!--- create per-item values  --->
										<cfset fieldName = "config_value#currentRow#">
										<cfset fieldID = fieldName>
										<cfset fieldLabel = itemsQuery.config_name>
										<cfset fieldValue = itemsQuery.config_value>
										<cfset fieldType = itemsQuery.config_type>
										<cfset fieldHelp = itemsQuery.config_description>
										<cfset fieldOptions = itemsQuery.config_possibles>
										<cfset fieldSize = itemsQuery.config_size>
										<cfset fieldRows = itemsQuery.config_rows>
										<!--- count protected fields --->
											<cfif isNumeric(itemsQuery.config_protected)>
											<cfset fieldProtectCt = fieldProtectCt + itemsQuery.config_protected>
											</cfif>
										<!--- required fields --->
										<cfif itemsQuery.config_required eq true>
											<cfset fieldClass = 'required'>
										<cfelse>
											<cfset fieldClass = ''>
										</cfif>
										<!--- email fields --->
										<cfif right(itemsQuery.config_name,5) is 'email'>
											<cfset fieldClass = fieldClass & ' email'>
										</cfif>
										<!--- add variable to application scope --->
										<cfset application.cw[itemsQuery.config_variable] = itemsQuery.config_value>
										<!--- set up list of text editor fields --->
										<cfif config_type is 'texteditor' and request.cwpage.rte>
											<cfset rteFields = listAppend(rteFields,fieldName)>
										</cfif>

										<!--- CUSTOM FIELDS can be managed here, reference config_variable value --->

										<!--- Get Themes : Admin style directory --->
										<cfif itemsQuery.config_variable is 'adminThemeDirectory'>
											<!--- get directories within admin/css/cw-theme --->
											<cfdirectory name="getThemes" action="list" directory="#expandPath('theme')#" type="dir" recurse="false">
											<cfsavecontent variable = "fieldOptions">
												<!--- set up list of theme names for selection --->
											<cfloop query="getThemes">#getThemes.name#|#getThemes.name##chr(13)#</cfloop>
											</cfsavecontent>
										</cfif>

										<!--- FormField function creates field by type --->
										<cfset inputEl = CWformField(
										fieldType,
										fieldName,
										fieldID,
										fieldLabel,
										fieldValue,
										fieldOptions,
										fieldClass,
										fieldSize,
										fieldRows
										)>
										</cfsilent>
										<!--- output the rows --->
										<tr>
											<!--- details link --->
											<td style="text-align:center;"><a href="config-item-details.cfm?item_id=#itemsQuery.config_id#" title="Manage Config Item details" class="detailsLink"><img src="img/cw-edit.gif" width="15" height="15" alt="Edit"></a></td>
											<!--- help --->
											<td class="noLink">
												<cfif len(trim(itemsQuery.config_description))>
													<a href="##" class="showHelpLink"><img width="16" height="16" align="absmiddle" alt="" title="#CWstringFormat(itemsquery.config_description)#" src="img/cw-help.png"></a>
												<cfelse>
													(null)
												</cfif>
											</td>
											<!--- name / help --->
											<td>
												<a href="config-item-details.cfm?item_id=#itemsQuery.config_id#" class="detailsLink" title="Manage Config Item details">
												#fieldLabel#
												</a>
												<!--- hidden help text --->
												<div class="helpText" style="display:none;">#itemsQuery.config_description#</div>
											</td>
											<!--- variable --->
											<td>
												<a href="config-item-details.cfm?item_id=#itemsQuery.config_id#" class="detailsLink" title="Manage Config Item details">
												#itemsQuery.config_Variable#
												</a>
											</td>
											<!--- value --->
											<td>
												#inputEl#
											</td>
											<!--- type --->
											<cfif application.cw.configSelectType eq 1>
												<td>
													<select name="config_type#currentRow#" id="config_type#currentRow#" class="required">
														<cfset v = trim(fieldType)>
														<option value=""<cfif v eq ''> selected="selected"</cfif>>Choose Form Field Type</option>
														<option value="text"<cfif v eq 'text'> selected="selected"</cfif> multivalue="false">Text Field</option>
														<option value="textarea"<cfif v eq 'textarea'> selected="selected"</cfif> multivalue="false">Textarea</option>
														<option value="texteditor"<cfif v eq 'texteditor'> selected="selected"</cfif> multivalue="false">Text Editor (rich text)</option>
														<option value="boolean"<cfif v eq 'boolean'> selected="selected"</cfif> multivalue="false">Checkbox (single)</option>
														<option value="checkboxgroup"<cfif v eq 'checkboxgroup'> selected="selected"</cfif> multivalue="true">Checkbox Group</option>
														<option value="radio"<cfif v eq 'radio'> selected="selected"</cfif> multivalue="true">Radio Group</option>
														<option value="select"<cfif v eq 'select'> selected="selected"</cfif> multivalue="true">Select List</option>
														<option value="multiselect"<cfif v eq 'multiselect'> selected="selected"</cfif> multivalue="true">Multiple Select List</option>
													</select>
												</td>
											</cfif>
											<cfset configItemType = ''>
											<cfif application.cw.configSelectType neq 1>
												<cfsavecontent variable="configItemType">
												<input name="config_type#currentRow#" type="hidden" value="#fieldType#">
												</cfsavecontent>
											</cfif>
											<!--- sort --->
											<td>
												<input name="config_Sort#currentRow#" type="text" size="3" maxlength="7" class="required sort" title="Sort Order is required" value="#itemsQuery.config_Sort#" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
											</td>
											<!--- delete --->
											<td style="text-align:center;">
												<input name="deleteRecord" type="checkbox" class="formCheckbox" value="#itemsQuery.config_id#"<cfif config_protected neq 0> disabled="disabled"</cfif>>
												<input type="hidden" name="configItem#CurrentRow#" value="#itemsQuery.config_id#">
												<input type="hidden" name="config_Name#CurrentRow#" value="#itemsQuery.config_name#">
												<input type="hidden" name="config_Variable#CurrentRow#" value="#itemsQuery.config_variable#">
												<input type="hidden" name="config_ID#CurrentRow#" value="#itemsQuery.config_id#">
												<input type="hidden" name="config_Description#CurrentRow#" value="#itemsQuery.config_description#">
												<input type="hidden" name="config_Possibles#CurrentRow#" value="#itemsQuery.config_possibles#">
												<input type="hidden" name="config_show_merchant#CurrentRow#" value="#itemsQuery.config_show_merchant#">
												<input name="recordIDlist" type="hidden" value="#itemsQuery.config_ID#">
												<cfif len(trim(configItemType)) and application.cw.configSelectType neq 1>
													#configItemType#
												</cfif>
											</td>
										</tr>
										</cfoutput>
										</tbody>
									</table>

									<!--- submit button - save changes --->
									<input name="SubmitUpdate" type="submit" class="submitButton" id="UpdateConfigItems" value="Save Changes">

								</form>
								<!--- note to user --->
								<div class="smallPrint">
									Note:
									<cfif fieldProtectCt>
										Some items are protected and may not be deleted.
									<cfelse>
										Delete all config variables to enable deleting the group.
									</cfif>
								</div>
								<!--- RTE rich text editor fields --->
								<cfif request.cwpage.rte>
									<cfinclude template="cwadminapp/inc/cw-inc-admin-script-editor.cfm">
								</cfif>
							</cfif>
							<!--- end if records exist --->
							<!--- /////// --->
							<!--- /END UPDATE CONFIG ITEMS --->
							<!--- /////// --->
						</cfif>
						<!--- /end valid config group record --->
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