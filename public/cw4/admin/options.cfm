<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: options.cfm
File Date: 2012-02-01
Description: Displays option management table
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
<!--- default form values --->
<cfparam name="form.optiontype_id" type="numeric" default="0">
<cfparam name="form.optiontype_name" type="string" default="">
<cfparam name="form.optiontype_Status" type="numeric" default="0">
<cfparam name="form.optiontype_sort" type="numeric" default="0">
<cfparam name="form.optionIDlist" type="string" default="">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,view,userconfirm,useralert")>
<!--- create the base url for sorting out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- ACTIVE / ARCHIVED --->
<!--- set up page title --->
<cfif url.view contains 'arch'>
	<cfset request.cwpage.viewType = 'Archived'>
	<cfset request.cwpage.subHead = 'Archived product options are not shown in the store'>
<cfelse>
	<cfset request.cwpage.viewType = 'Active'>
	<cfset request.cwpage.subHead = 'Manage active product options or add a new option group'>
</cfif>
<cfif request.cwpage.viewType contains 'Arch'>
	<cfset request.cwpage.optionsArchived = 1>
<cfelse>
	<cfset request.cwpage.optionsArchived = 0>
</cfif>
<!--- QUERY: get option groups --->
<cfset optionGroupsQuery = CWquerySelectStatusOptionGroups(request.cwpage.optionsArchived)>
<!--- /////// --->
<!--- UPDATE / DELETE OPTION GROUPS --->
<!--- /////// --->
<cfif isDefined('form.updateOptions')>
	<cfset loopCt = 1>
	<cfset updateCt = 0>
	<cfset deleteCt = 0>
	<cfset archiveCt = 0>
	<cfset activeCt = 0>
	<!--- loop all records from this page --->
	<cfloop list="#form.optionIDlist#" index="ID">
		<!--- param for status values --->
		<cfparam name="form.optionType_status#loopct#" default="#request.cwpage.optionsArchived#">
		<!--- if the option group ID is marked for deletion --->
		<cfset statusVal = evaluate('form.optionType_Status#id#')>
		<cfif statusVal eq 'Deleted'>
			<!--- QUERY: delete option group (option group ID) --->
			<!--- Note: marks record as deleted=1, does not actually delete, to avoid orders-placed errors --->
			<cfset deleteOptionGroup = CWqueryDeleteOptionGroup(id)>
			<cfset deleteCt = deleteCt + 1>
			<!--- if not deleting, update --->
		<cfelse>
			<!--- verify numeric sort order --->
			<cfif NOT isNumeric(form["optiontype_sort#loopct#"])>
				<cfset #form["optiontype_sort#loopct#"]# = 0>
			</cfif>
			<!--- determine archive 1/0, set up counts for confirmation message --->
			<cfif statusVal eq 'Archived'>
				<cfset optiontype_archive = 1>
				<cfif request.cwpage.optionsArchived is 0><cfset archiveCt = archiveCt + 1><cfelse><cfset updateCt = updateCt + 1></cfif>
			<cfelse>
				<cfset optiontype_archive = 0>
				<cfif request.cwpage.optionsArchived is 1><cfset activeCt = activeCt + 1><cfelse><cfset updateCt = updateCt + 1></cfif>
			</cfif>
			<!--- QUERY: update option group(id, name, sort, archive, text) --->
			<cfset updateOptionGroup = CWqueryUpdateOptionGroup(
			#form["optiontype_id#loopct#"]#,
			'#form["optiontype_name#loopct#"]#',
			#form["optiontype_sort#loopct#"]#,
			#optiontype_archive#,
			'#form["optiontype_text#loopct#"]#'
			)>
		</cfif>
		<!--- /END if deleting or updating --->
		<cfset loopCt = loopCt + 1>
	</cfloop>
	<!--- /END record loop --->
	<!--- get the vars to keep by omitting the ones we don't want repeated --->
	<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert")>
	<!--- set up the base url --->
	<cfset request.cwpage.relocateUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
	<!--- save confirmation text --->
	<cfset CWpageMessage("confirm","Changes Saved")>
	<!--- save alert text --->
	<cfsavecontent variable="request.cwpage.userAlertText">
	<cfif archiveCt gt 0>
		<cfoutput>#archiveCt# <cfif archiveCt is 1>Option Group<cfelse>Option Groups</cfif> Archived</cfoutput>
	<cfelseif activeCt gt 0>
		<cfoutput>#activeCt# <cfif activeCt is 1>Option Group<cfelse>Option Groups</cfif> Activated</cfoutput>
	</cfif>
	<cfif deleteCt gt 0><cfif archiveCt gt 0 OR activeCt gt 0><br></cfif><cfoutput>#deleteCt# <cfif deleteCt is 1>Option Group<cfelse>Option Groups</cfif> Deleted</cfoutput></cfif>
	</cfsavecontent>
	<cfset CWpageMessage("alert",request.cwpage.userAlertText)>
	<!--- return to page as submitted, clearing form scope --->
	<cflocation url="#request.cwpage.relocateUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END UPDATE / DELETE OPTION GROUPS --->
<!--- /////// --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Manage Product Options">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Option Management: #request.cwpage.viewType# Option Groups">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = request.cwpage.subhead>
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
		// confirm deletion
		function confirmDelete(selID,prodCt){
		// if this option has products
		if (prodCt > 0){
		if (prodCt > 1){var prodWord = 'products'}else{var prodWord = 'product'};
		var confirmSelect = '#'+ selID;
			// if the dropdown has the value 'deleted'
				if( jQuery(confirmSelect).attr('value') == 'Deleted' ){
				deleteConfirm = confirm("This option group will be permanently removed - currently used on " + prodCt + " " + prodWord + ".\nContinue?");
					// if confirm is returned false
					if(!deleteConfirm){
						jQuery(confirmSelect).attr('value','<cfoutput>#request.cwpage.viewType#</cfoutput>');
					};
				};
			// end if checked
			};
		// end if prodct
		};
		// end jquery
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
						<!--- LINKS FOR VIEW TYPE --->
						<div class="CWadminControlWrap">
							<strong>
							<cfif url.view eq 'arch'>
								<a href="<cfoutput>#request.cw.thisPage#</cfoutput>">View Active</a>
							<cfelse>
								<a href="<cfoutput>#request.cw.thisPage#</cfoutput>?view=arch">View Archived</a>
								<!--- link for add-new form --->
								<cfif request.cwpage.optionsArchived is 0>
									&nbsp;&nbsp;<a class="CWbuttonLink" href="option-details.cfm">Add New Option Group</a>
								</cfif>
							</cfif>
							</strong>
						</div>
						<!--- LINKS FOR VIEW TYPE --->
						<!--- /////// --->
						<!--- EDIT OPTIONS --->
						<!--- /////// --->
						<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" name="optionForm" id="optionForm" class="CWobserve" method="post">
							<!--- save changes / submit button --->
							<cfif optionGroupsQuery.recordCount>
								<div class="CWadminControlWrap">
									<input name="UpdateOptions" type="submit" class="CWformButton" id="UpdateOptions" value="Save Changes">
									<div style="clear:right;"></div>
								</div>
							</cfif>
							<!--- /end submit button --->
							<!--- if no records found, show message --->
							<cfif NOT optionGroupsQuery.recordCount>
								<cfoutput>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p><strong>No #lcase(request.cwpage.viewType)# Option Groups available</strong> <br><br></p></cfoutput>
								<!--- if we have records to show --->
							<cfelse>
								<!--- SHOW OPTION GROUPS --->
								<cfset optionGroupsQuery = CWsortableQuery(optionGroupsQuery)>
								<table class="CWsort CWstripe" summary="<cfoutput>#request.cwpage.baseUrl#</cfoutput>">
									<thead>
									<tr class="sortRow">
										<th class="noSort" style="text-align:center;" width="50">Edit</th>
										<th class="optiontype_name">Option Group Name</th>
										<th width="50" class="optiontype_id">ID</th>
										<th class="optiontype_text">Description</th>
										<th width="55" class="optiontype_sort">Order</th>
										<th width="65" class="optionProdCount">Products</th>
										<th width="95">Status</th>
									</tr>
									</thead>
									<tbody>
									<cfset disabledCt = 0>
									<cfoutput query="optionGroupsQuery">
									<!--- output the row --->
									<tr>
										<!--- details link --->
										<td style="text-align:center;"><a href="option-details.cfm?optiontype_id=#optiontype_id#" title="Manage Options in this Group" class="detailsLink"><img src="img/cw-edit.gif" width="15" height="15" alt="View Option Group Details"></a></td>
										<!--- option group name --->
										<td>
											<strong><a href="option-details.cfm?optiontype_id=#optiontype_id#" title="Manage Options in this Group" class="detailsLink">#optionGroupsQuery.optiontype_name#</a></strong>
											<!--- option group ID --->
											<td>#optionGroupsQuery.optiontype_id#</td>
											<!--- text description --->
											<td>
												<input name="optiontype_text#currentRow#"  type="text" size="15" value="#optionGroupsQuery.optiontype_text#">
											</td>
											<!--- Sort Order --->
											<td><input name="optiontype_sort#currentRow#" type="text" size="3" maxlength="7" class="required sort" title="Sort Order is required" value="#optionGroupsQuery.optiontype_sort#" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);"></td>
											<!--- Products --->
											<td style="text-align:center;">#optionGroupsQuery.optionProdCount#</td>
											<!--- Status --->
											<td>
												<!--- if no products are associated , or option is already archived, allow changes --->
												<cfif not optionGroupsQuery.optionProdCount gt 0 OR optionGroupsQuery.optiontype_archive eq 1>
													<select name="optionType_Status#optiontype_id#" class="optionStatusSelect" id="optionType_Status#optiontype_id#" onchange="confirmDelete('optionType_Status#optiontype_id#',#optionGroupsQuery.optionProdCount#)">
														<option value="Active"<cfif optionGroupsQuery.optiontype_archive is not 1> selected="selected"</cfif>>Active</option>
														<option value="Archived"<cfif optionGroupsQuery.optiontype_archive is 1> selected="selected"</cfif>>Archived</option>
														<option value="Deleted">Deleted</option>
													</select>
												<cfelse>
													<cfset disabledCt = disabledCt + 1>
													Active
													<input type="hidden" name="optionType_Status#optiontype_id#" value="#optionGroupsQuery.optiontype_archive#">
												</cfif>
												<!--- hidden values for managing updates--->
												<input name="optiontype_name#currentRow#" type="hidden" value="#optionGroupsQuery.optiontype_name#">
											</td>
											<input name="optiontype_id#currentRow#" type="hidden" value="#optionGroupsQuery.optiontype_id#">
											<input name="optionIDlist" type="hidden" value="#optionGroupsQuery.optiontype_id#">
										</td>
									</tr>
									</cfoutput>
									</tbody>
								</table>
								<!--- if we have disabled status options, explain --->
								<span class="smallPrint" style="float:right;">
									<cfif disabledCt>
										Note:&nbsp;&nbsp;options with associated products or orders cannot be deleted
									</cfif>
								</span>
							</cfif>
							<!--- /END if records found --->
						</form>
						<!--- /////// --->
						<!--- /END EDIT OPTIONS--->
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