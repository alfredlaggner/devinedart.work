<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: option-details.cfm
File Date: 2012-04-12
Description: Displays option details for any option group, handles adding new option group
==========================================================
--->
<!--- GLOBAL INCLUDES --->
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("manager,merchant,developer")>
<!--- PAGE PARAMS --->
<!--- default values for sort / active or archived--->
<cfparam name="url.sortby" type="string" default="optiontype_sort">
<cfparam name="url.sortdir" type="string" default="asc">
<cfparam name="url.view" type="string" default="active">
<cfif not (isDefined('url.optiontype_id') AND isNumeric(url.optiontype_id))>
<cfset url.optiontype_id = 0>
</cfif>
<!--- new vs. edit defaults --->
<cfparam name="request.cwpage.editMode" default="edit">
<!--- Param for delete allowed --->
<cfparam name="request.cwpage.deleteOK" default="0">
<cfparam name="request.cwpage.relatedOrders" default="0">
<!--- Param for name of this option group --->
<cfparam name="request.cwpage.groupName" default="">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,view,userconfirm,useralert,clickadd")>
<!--- create the base url for sorting out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- QUERY: get option group details --->
<cfset optionGroupQuery = CWquerySelectOptionGroupDetails(url.optiontype_id)>
<!--- QUERY: get options in this group --->
<cfset optionsQuery = CWquerySelectGroupOptions(url.optiontype_id)>
<!--- QUERY: get all orders using an option in this group --->
<cfset optionOrdersQuery = CWquerySelectOptionGroupOrders(url.optiontype_id,1)>
<!--- QUERY: get all orderSkus using an option in this group --->
<cfset optionOrderSkusQuery = CWquerySelectOptionGroupOrders(url.optiontype_id,0)>
<!--- QUERY: get all active option groups --->
<cfset optionGroupsActive = CWquerySelectStatusOptionGroups()>
<!--- QUERY: get all archived option groups: used for deleteok check --->
<cfset optionGroupsArchived = CWquerySelectStatusOptionGroups(1)>

<!--- form params --->
<cfparam name="form.option_archivePrev" default="">
<cfparam name="form.option_Active" default="">
<cfif optionGroupQuery.optiontype_archive eq 1>
	<cfparam name="form.optiontype_archive" default="1">
<cfelse>
	<cfparam name="form.optiontype_archive" default="0">
</cfif>
<cfparam name="form.deleteOption" default="">
<!--- NEW VS. EDIT MODE--->
<!--- EDIT  --->
<!--- if one valid group is found and we have a valid ID:
note joined query with a 'count' will always return at least 1 row --->
<cfif optionGroupQuery.recordCount eq 1 AND optiongroupQuery.optiontype_id gt 0>
	<!--- set the name of this group --->
	<cfset request.cwpage.groupName = optionGroupQuery.optiontype_name>
	<!--- subheading --->
	<cfset request.cwpage.subhead = "Manage #request.cwpage.groupName# Options">
	<cfif optionGroupQuery.optiontype_archive is 1>
		<cfset request.cwpage.subhead =  request.cwpage.subhead & '&nbsp;&nbsp;&nbsp;<em>Note: This option group is archived and will not be displayed</em>'>
	</cfif>
	<!--- count all the totals of the 'skucount' and 'prodcount' columns from queries --->
	<cfset request.cwpage.relatedSkus = ArraySum(ListToArray(valueList(optionsQuery.optionSkuCount)))>
	<cfset request.cwpage.relatedProducts = ArraySum(ListToArray(valueList(optionGroupQuery.optionProdCount)))>
	<cfset request.cwpage.relatedOrders = optionOrdersQuery.recordCount>
	<!--- ok to delete? --->
	<cfif (request.cwpage.relatedSkus + request.cwpage.relatedProducts) lt 1>
		<cfset request.cwpage.deleteOK = 1>
	</cfif>
	<!--- /end count totals --->
	<!--- ADD --->
<cfelse>
	<!--- check for valid id: if id is 0 --->
	<cfif url.optiontype_id is 0>
		<cfset request.cwpage.editMode = 'add'>
		<cfset request.cwpage.subhead = "Add a new option group">
		<!--- if id is not 0 but not found --->
	<cfelse>
		<cfset CWpageMessage("alert","Option Group #url.optiontype_id# not found")>
		<cflocation url="options.cfm?&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
	</cfif>
	<!--- end valid id --->
</cfif>
<!--- /END NEW VS. EDIT--->
<!--- set up relocation url for confirmation --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert")>
<!--- set up the base url --->
<cfset request.cwpage.relocateUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- /////// --->
<!--- ADD NEW OPTION GROUP --->
<!--- /////// --->
<!--- the newoption fields are not available when first inserting a new group --->
<cfif isDefined('form.optiontype_name') and len(trim(form.optiontype_name))
	AND NOT isDefined('form.newoption_text')>
	<cfset dupCheck = CWquerySelectOptionGroupDetails(0,trim(form.optiontype_name))>
	<!--- QUERY: insert new option (name, sort, text, archive) --->
	<!--- this query returns the option group id, or an error like '0-fieldname' --->
	<cfset newOptionGroupID = CWqueryInsertOptionGroup(
	trim(form.optiontype_name),
	trim(form.optiontype_sort),
	trim(form.optiontype_text),
	0
	)>
	<!--- if no error returned from insert query --->
	<cfif not left(newOptionGroupID,2) eq '0-'>
		<!--- update complete: return to page showing message --->
		<cfset CWpageMessage("confirm","Option '#form.optiontype_name#' Added")>
		<cflocation url="#request.cwpage.baseUrl#&optiontype_id=#newOptionGroupID#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&clickadd=1&sortby=#url.sortby#&sortdir=#url.sortdir#" addtoken="no">
		<!--- if we have an insert error, show message, do not insert --->
	<cfelse>
		<cfset dupField = listLast(newOptionGroupID,'-')>
		<cfset CWpageMessage("alert","Error: #dupField# already exists")>
		<cfset url.clickadd = 1>
	</cfif>
	<!--- /END duplicate/error check --->
</cfif>
<!--- /////// --->
<!--- /END ADD NEW OPTION GROUP --->
<!--- /////// --->
<!--- /////// --->
<!--- ADD NEW OPTION --->
<!--- /////// --->
<cfif isDefined('form.newoption_name') and len(trim(form.newoption_name))>
	<!--- QUERY: insert new option (name, group ID, sort, text, archive) --->
	<!--- this query returns the option id, or an error like '0-fieldname' --->
	<cfset newOptionID = CWqueryInsertOption(
	trim(htmlEditFormat(form.newoption_name)),
	url.optiontype_id,
	trim(form.newoption_sort),
	trim(htmlEditFormat(form.newoption_text)),
	0
	)>
	<!--- if no error returned from insert query --->
	<cfif not left(newOptionID,2) eq '0-'>
		<!--- update complete: return to page showing message --->
		<cfset CWpageMessage("confirm","Option '#form.newoption_name#' Added")>
		<cflocation url="#request.cwpage.baseUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&sortby=#url.sortby#&sortdir=#url.sortdir#&clickadd=1" addtoken="no">
		<!--- if we have an insert error, show message, do not insert --->
	<cfelse>
		<cfset dupField = listLast(newOptionID,'-')>
		<cfset CWpageMessage("alert","Error: #dupField# already exists")>
		<cfset url.clickadd = 1>
	</cfif>
	<!--- /end duplicate/error check --->
	<!--- /////// --->
	<!--- /END ADD NEW OPTION --->
	<!--- /////// --->
	<!--- /////// --->
	<!--- UPDATE OPTION GROUP --->
	<!--- /////// --->
<cfelseif isDefined('form.optiontype_name') and len(trim(form.optiontype_name))>
	<!--- ( other actions have been handled above, if the name field makes it this far, run update ) --->
	<cfset loopCt = 1>
	<cfset updateCt = 0>
	<cfset deleteCt = 0>
	<cfset archiveCt = 0>
	<cfset activeCt = 0>
	<!--- verify numeric sort order --->
	<cfif NOT isNumeric(form.optiontype_sort)>
		<cfset form.optiontype_sort = 0>
	</cfif>
	<!--- QUERY: update option group(id, name, sort, archive, text) --->
	<cfset updateGroup = CWqueryUpdateOptionGroup(
	#url.optiontype_id#,
	'#form.optiontype_name#',
	#form.optiontype_sort#,
	#form.optiontype_archive#,
	'#form.optiontype_text#'
	)>
	<!--- /////// --->
	<!--- PROCESS ALL OPTIONS --->
	<!--- /////// --->
	<cfif isDefined('form.optionIDlist')>
		<!--- loop option IDs, handle each one as needed --->
		<cfloop list="#form.optionIDlist#" index="ID">
			<!--- /////// --->
			<!--- DELETE OPTIONS --->
			<!--- /////// --->
			<!--- if the option id is marked for deletion --->
			<cfif listFind(form.deleteOption,evaluate('form.option_id'&loopCt))>
				<!--- QUERY: delete option (option id) --->
				<cfset deleteOption = CWqueryDeleteOption(id)>
				<cfset deleteCt = deleteCt + 1>
				<!--- if not deleting, update --->
			<cfelse>
				<!--- /////// --->
				<!--- UPDATE OPTIONS --->
				<!--- /////// --->
				<!--- param for checkbox values --->
				<cfparam name="form.option_Active#loopct#" default="0">
				<!--- verify numeric sort order --->
				<cfif NOT isNumeric(#form["option_sort#loopct#"]#)>
					<cfset #form["option_sort#loopct#"]# = 0>
				</cfif>
				<!--- if the option id is marked for archiving
				(note checkbox is for ACTIVE in this usage, so we archive the options NOT in the list) --->
				<cfif NOT listFind(form.option_Active,id)>
					<cfset optionArchive = 1>
					<!--- if it was not previously archived --->
					<cfif NOT listFind(form.option_archivePrev,id)>
						<cfset archiveCt = archiveCt + 1>
					</cfif>
					<!--- if not marked for archiving, activate --->
				<cfelse>
					<cfset optionArchive = 0>
					<cfif listFind(form.option_archivePrev,id)>
						<cfset activeCt = activeCt + 1>
					</cfif>
				</cfif>
				<!--- QUERY: update option record (id, name, group, sort, archive, description) --->
				<cfset updateOptionID = CWqueryUpdateOption(
				#form["option_id#loopct#"]#,
				'#htmlEditFormat(form["option_name#loopct#"])#',
				#url.optiontype_id#,
				#form["option_sort#loopct#"]#,
				#optionArchive#,
				'#htmlEditFormat(form["option_text#loopct#"])#'
				)>
				<!--- query checks for duplicate fields --->
				<cfif left(updateOptionID,2) eq '0-'>
					<cfset errorName = '#form["option_name#loopct#"]#'>
					<cfset CWpageMessage("alert","Error: Name '#errorName#' already exists")>
					<!--- update complete: continue processing --->
				<cfelse>
					<cfset updateCt = updateCt + 1>
				</cfif>
				<!--- /END duplicate check --->
			</cfif>
			<!--- /END if deleting or updating --->
			<cfset loopCt = loopCt + 1>
		</cfloop>
		<!--- return to page as submitted, clearing form scope --->
		<cfset CWpageMessage("confirm","Changes Saved")>
		<cfsavecontent variable="request.cwpage.userAlertText">
		<cfif archiveCt gt 0><cfoutput>#archiveCt# Option<cfif archiveCt gt 1>s</cfif> Deactivated</cfoutput>
		<cfelseif activeCt gt 0><cfoutput>#activeCt# Option<cfif activeCt gt 1>s</cfif> Activated</cfoutput></cfif>
		<cfif deleteCt gt 0><cfif archiveCt gt 0 OR activeCt gt 0><br></cfif><cfoutput>#deleteCt# Option<cfif deleteCt gt 1>s</cfif> Deleted</cfoutput></cfif>
		</cfsavecontent>
		<cfset CWpageMessage("alert",request.cwpage.userAlertText)>
		<cflocation url="#request.cwpage.relocateUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
	<cfelse>
		<cfset CWpageMessage("alert","Changes Saved")>
		<cflocation url="#request.cwpage.relocateUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
	</cfif>
</cfif>
<!--- /////// --->
<!--- /END ADD/UPDATE --->
<!--- /////// --->
<!--- /////// --->
<!--- DELETE OPTION GROUP --->
<!--- /////// --->
<cfif IsDefined ('url.deletegroup')>
	<cfparam name="url.returnurl" type="string" default="options.cfm?useralert=Unable to delete: option group #url.deletegroup# not found">
	<cfset request.cwpage.returnUrl = url.returnurl>
	<cftry>
		<!--- QUERY: delete group record (id from url)--->
		<cfset deleteOrder = CWqueryDeleteOptionGroup(url.deletegroup)>
		<!--- handle errors --->
		<cfcatch>
			<cfset CWpageMessage("alert","Deletion Error: #cfcatch.message#")>
			<cfset request.cwpage.returnUrl = "#request.cw.thisPage#?optiontype_id=#url.optiontype_id#&useralert=#CWurlSafe(request.cwpage.userAlert)#" >
		</cfcatch>
	</cftry>
	<cflocation url="#request.cwpage.returnUrl#" addtoken="No">
</cfif>
<!--- /////// --->
<!--- /END DELETE OPTION GROUP --->
<!--- /////// --->
<!--- default values for form inputs, persist entered values when returning insert errors --->
<cfparam name="form.optiontype_name" default="#optionGroupQuery.optiontype_name#">
<cfparam name="form.optiontype_text" default="#optionGroupQuery.optiontype_text#">
<cfparam name="form.optiontype_sort" default="#optionGroupQuery.optiontype_sort#">
<cfif not len(trim(form.optiontype_sort))><cfset form.optiontype_sort = 0></cfif>
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title
<title>
--->
<cfset request.cwpage.title = "Manage Product Options">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Product Option Management">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = request.cwpage.subhead>
<!--- current menu marker --->
<cfif request.cwpage.editMode eq 'add'>
	<cfset request.cwpage.currentNav = 'option-details.cfm'>
<cfelse>
	<cfset request.cwpage.currentNav = 'options.cfm'>
</cfif>
<!--- load form scripts --->
<cfset request.cwpage.isFormPage = 1>
<!--- load table scripts --->
<cfset request.cwpage.isTablePage = 1>
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert")>
<!--- set up the base url --->
<cfset request.cwpage.relocateUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
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
		<!--- text editor javascript --->
		<cfif application.cw.adminEditorEnabled and application.cw.adminEditorOptionDescrip>
			<cfinclude template="cwadminapp/inc/cw-inc-admin-script-editor.cfm">
		</cfif>
		<!--- PAGE JAVASCRIPT --->
		<script type="text/javascript">
		// confirm deletion
		function confirmDelete(prodCt,orderCt,newLocation){
		// build the confirmation message
			if (prodCt == 1){var prodLabel = 'product'} else {var prodLabel = 'products'};
			if (orderCt == 1){var orderLabel = 'order'} else {var orderLabel = 'orders'};
			var confirmA = "This option group and all associated options will be permanently removed";
			var confirmB = ". \nCurrently used on " + prodCt + " " + prodLabel;
			var confirmC = ". \nAssociated with " + orderCt + " " + orderLabel;
			var confirmD = ".\nContinue?";
		// if this option group has products, show the product count in the alert
			var confirmStr = confirmA;
			if (prodCt > 0){confirmStr = confirmStr + confirmB};
			if (orderCt > 0){confirmStr = confirmStr + confirmC};
			confirmStr = confirmStr + confirmD;
			deleteConfirm = confirm(confirmStr);
			// if cancelled return false
			if(deleteConfirm){
			window.location = newLocation;
			};
		};
		// end if product
		// select option group changes page location
		function groupSelect(selBox){
		 	var viewID = jQuery(selBox).val();
			if (viewID >= 1){
		 	window.location = '<cfoutput>#request.cw.thisPage#?optiontype_id=</cfoutput>' + viewID;
			}
		};
		<!--- show/hide new option form, disable name input --->
		// initialize jQuery
		jQuery(document).ready(function(){
			// add new option
			jQuery('#showNewOptionFormLink').click(function(){
			jQuery('#addOptionTable').show();
			jQuery(this).hide().siblings('a').show();
			jQuery('#newoption_name').removeAttr('disabled').focus();
			jQuery('#UpdateOptionGroup').hide();
			return false;
		});
		// cancel new option
		jQuery('#hideNewOptionFormLink').click(function(){
			jQuery('#addOptionTable').hide();
			jQuery('#newoption_name').attr('disabled',true);
			jQuery(this).hide().siblings('a').show();
			jQuery('#UpdateOptionGroup').show();
			return false;
		});

			// click button from url
			<cfif isDefined('url.clickadd') OR
				(not optionsQuery.recordCount
				and request.cwpage.editmode neq 'add')>
				jQuery('#showNewOptionFormLink').click();
			</cfif>
			// hide add new form when editing table below
			jQuery('table#productOptionsTable input, table#productOptionsTable textarea').focus(function(){
				jQuery('#hideNewOptionFormLink').click();
			});

			});
		</script>
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
						<!--- EDIT OPTION GROUP AND OPTIONS --->
						<!--- /////// --->
						<form action="<cfoutput>#request.cwpage.baseUrl#&sortby=#url.sortby#&sortdir=#url.sortdir#</cfoutput>" class="CWvalidate CWobserve" name="optionsForm" id="optionsForm" method="post">
							<!--- option group table --->
							<table class="CWinfoTable wide">
								<thead>
								<tr class="headerRow">
									<th>Option Group Name</th>
									<th>Description</th>
									<th width="55">Order</th>
									<cfif not request.cwpage.editmode is 'add'><th width="55">Status</th></cfif>
								</tr>
								</thead>
								<tbody>
								<cfoutput>
								<tr>
									<!--- option group name --->
									<td>
										<!--- if adding new, allow for input here --->
										<cfif request.cwpage.editmode is 'add'>
											<input name="optiontype_name" type="text" size="17"  class="required" value="#form.optiontype_name#" title="Option Group Name is required" onblur="checkValue(this)">
											<!--- if editing, show selection list --->
										<cfelse>
											<!--- select changes to new page --->
											<select name="optiontype_nameSelector" id="optionGroupSelect" onchange="groupSelect(this);">
												<cfif optionGroupsActive.recordCount>
													<optgroup label="Active">
													<cfloop query="optionGroupsActive">
														<option value="<cfoutput>#optiontype_id#</cfoutput>"<cfif optiontype_id eq url.optiontype_id> selected="selected"</cfif>><cfoutput>#optiontype_name#</cfoutput></option>
													</cfloop>
													</optgroup>
												</cfif>
												<cfif optionGroupsArchived.recordCount>
												<optgroup label="Archived">
													<cfloop query="optionGroupsArchived">
														<option value="<cfoutput>#optiontype_id#</cfoutput>"<cfif optiontype_id eq url.optiontype_id> selected="selected"</cfif>><cfoutput>#optiontype_name#</cfoutput></option>
													</cfloop>
												</optgroup>
												</cfif>
											</select>
											<br>
											<span class="smallPrint"><a href="#request.cw.thisPage#">Add New Group</a></span>
											<!--- name can't be edited, hidden --->
											<input name="optiontype_name" type="hidden" value="#form.optiontype_name#">
										</cfif>
									</td>
									<!--- text description --->
									<td>
										<textarea name="optiontype_text" cols="45" rows="1">#form.optiontype_text#</textarea>
									</td>
									<!--- sort order --->
									<td><input name="optiontype_sort" type="text" size="3" maxlength="7" class="required sort" title="Sort Order is required" value="#form.optiontype_sort#" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);"></td>
									<!--- active yes/no --->
									<cfif not request.cwpage.editmode is 'add'>
										<td>
											<!--- can only be archived if not attached to products --->
											<cfif request.cwpage.relatedProducts eq 0>
												<select name="optiontype_archive">
													<cfif form.optiontype_archive neq 1>
														<option value="0" selected="selected">Active
														<option value="1">Archived
													<cfelse>
														<option value="0" >Active
														<option value="1" selected="selected">Archived
													</cfif>
												</select>
											<cfelse>
												Active
												<input type="hidden" name="optiontype_archive" value="#form.optiontype_archive#">
											</cfif>
										</td>
									</cfif>
								</tr>
								</cfoutput>
								<!--- /////// --->
								<!--- END ADD / EDIT OPTION GROUP --->
								<!--- /////// --->
								<!--- /////// --->
								<!--- EDIT OPTIONS --->
								<!--- /////// --->
								<!--- if editing --->
								<cfif NOT request.cwpage.editmode is 'add'>
									<tr>
										<td colspan="4">
											<div class="CWformButtonWrap">
												<!--- save changes / submit button --->
												<input name="UpdateOptionGroup" type="submit" class="CWformButton" id="UpdateOptionGroup" value="<cfif request.cwpage.editMode is 'add'>Save Details<cfelse>Save Changes</cfif>">
												<!--- delete button --->
												<cfif request.cwpage.deleteOK>
													<cfoutput>
													<cfset confirmStr = CWurlSafe("Option Group Deleted")>
													<a href="##" onclick="confirmDelete(#optionGroupQuery.optionProdCount#,#request.cwpage.relatedOrders#,'#request.cw.thisPage#?deleteGroup=#url.optiontype_id#&returnUrl=options.cfm?userconfirm=#confirmStr#')" class="CWbuttonLink deleteButton">Delete Option Group</a>
													</cfoutput>
												<cfelse>
													<span style="float: right;" class="smallPrint">Option group in use, cannot be deleted.</span>
												</cfif>
												<!--- if no options exist, show alert --->
												<cfif not optionsQuery.recordCount>
													<div class="clear"></div>
													<div class="alert clear">Create at least one option to activate this option group</div>
												</cfif>
												<a class="CWbuttonLink" href="##" id="showNewOptionFormLink" style="display: block;">Add New Option</a>
												<a class="CWbuttonLink" href="##" id="hideNewOptionFormLink" style="display: none;">Cancel New Option</a>
											</div>
											<!--- /////// --->
											<!--- ADD NEW OPTION --->
											<!--- /////// --->
											<table class="CWsort CWstripe" id="addOptionTable" style="display:none;">
												<thead>
												<tr class="sortRow">
													<th width="185" class="noSort">Option</th>
													<th class="noSort">Description</th>
													<th width="55" class="noSort">Order</th>
												</tr>
												</thead>
												<tbody>
												<tr>
													<!--- option name: loaded as disabled, show new option link enables it for validation --->
													<td>
														<div>
															<input name="newoption_name" id="newoption_name" type="text" size="17" disabled="disabled" class="required" value="" title="Option Name is required">
														</div>
														<br>
														<input name="AddOption" type="submit" class="CWformButton" id="AddOption" value="Add Option">
													</td>
													<!--- option text --->
													<td>
														<textarea name="newoption_text" cols="45" rows="1"></textarea>
													</td>
													<!--- order --->
													<td>
														<input name="newoption_sort" type="text" size="3" maxlength="7" class="required sort" title="Sort Order is required" value="1" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
													</td>
												</tr>
												</tbody>
											</table>
											<!--- /////// --->
											<!--- END ADD NEW OPTION --->
											<!--- /////// --->
											<!--- /////// --->
											<!--- EDIT OPTIONS --->
											<!--- /////// --->
											<!--- show this table if options exist --->
											<cfif optionsQuery.recordCount>
												<!--- make the query sortable --->
												<cfset optionsQuery = CWsortableQuery(optionsQuery)>
												<!--- options table --->
												<table class="CWsort CWstripe" summary="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" id="productOptionsTable">
													<thead>
													<tr class="sortRow">
														<th width="185" class="option_name">Option</th>
														<th class="option_text">Description</th>
														<th width="55" class="option_sort">Order</th>
														<th width="55" class="noSort">Active</th>
														<th width="55" class="noSort">Delete</th>
													</tr>
													</thead>
													<tbody>
													<cfset disabledDeleteCt = 0>
													<cfset disabledArchiveCt = 0>
													<cfoutput query="optionsQuery">
													<tr>
														<!--- option name and hidden fields --->
														<td>
															<input name="option_name#currentRow#" type="text" size="17"  class="required" value="#optionsQuery.option_name#" title="Option Name is required" onblur="checkValue(this)">
															<input name="option_id#currentRow#" type="hidden" value="#optionsQuery.option_id#">
															<input name="optionIDlist" type="hidden" value="#optionsQuery.option_id#">
														</td>
														<!--- option text --->
														<td>
															<textarea name="option_text#currentRow#" cols="45" rows="1">#optionsQuery.option_text#</textarea>
														</td>
														<!--- option order --->
														<td>
															<input name="option_sort#currentRow#" type="text" size="3" maxlength="7" class="required sort" title="Sort Order is required" value="#optionsQuery.option_sort#" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
														</td>
														<!--- archive --->
														<td style="text-align:center">
															<!--- if we have skus related to this option, disable archive, use hidden field to pass in id to active list --->
															<input type="checkbox" name="option_Active" class="formCheckbox radioGroup" rel="group#currentrow#" value="#optionsQuery.option_id#"<cfif NOT optionsQuery.option_archive is 1> checked="checked"</cfif>
															<cfif optionsQuery.optionSkuCount gt 0>
																<cfset disabledArchiveCt = disabledArchiveCt + 1>
																disabled="disabled"
															</cfif>
															>
															<cfif optionsQuery.optionSkuCount gt 0>
																<input type="hidden" name="option_Active" value="#optionsQuery.option_id#">
															</cfif>
															<!--- hidden field used to determine new archive/activations --->
															<cfif optionsQuery.option_archive is 1>
																<input type="hidden" name="option_archivePrev" value="#optionsQuery.option_id#">
															</cfif>
														</td>
														<!--- delete--->
														<td style="text-align:center">
															<!--- if we have skus or orders related to this option, disable delete --->
															<input type="checkbox" name="deleteOption" id="confirmBox#option_id#" value="#option_id#" class="formCheckbox<cfif optionsQuery.optionSkuCount gt 0>deleteDisabled</cfif> radioGroup" rel="group#currentrow#"
															<cfif optionsQuery.optionSkuCount gt 0 OR listFind(valueList(optionOrderSkusQuery.sku_option2option_id),option_id)>
																<cfset disabledDeleteCt = disabledDeleteCt + 1>
																disabled="disabled"
															</cfif>
															>
														</td>
													</tr>
													</cfoutput>
													</tbody>
												</table>
												<!--- if we have disabled delete boxes, explain --->
												<span class="smallPrint" style="float:right;">
													<cfif disabledDeleteCt>
														Note:&nbsp;&nbsp;options with associated products or orders cannot be deleted
													</cfif>
													<!--- if we have disabled archive boxes --->
													<cfif disabledArchiveCt>
														<cfif disabledDeleteCt><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<cfelse>Note: </cfif>
														options with associated products cannot be archived
													</cfif>
												</span>
												<!--- /END options table --->
											</cfif>
											<!--- end if no options exist --->
										</td>
									</tr>
								</cfif>
								<!--- /////// --->
								<!--- /END EDIT OPTIONS --->
								<!--- /////// --->
								</tbody>
							</table>
							<!--- /end optiongroup table --->
							<!--- if adding new --->
							<cfif request.cwpage.editmode is 'add'>
								<!--- save changes / submit button --->
								<div class="CWformButtonWrap">
									<input name="UpdateOptionGroup" type="submit" class="CWformButton" id="UpdateOptionGroup" value="<cfif request.cwpage.editMode is 'add'>Save Details<cfelse>Save Changes</cfif>">
								</div>
							</cfif>
						</form>
						<!--- /////// --->
						<!--- /END EDIT OPTION GROUP AND OPTIONS --->
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