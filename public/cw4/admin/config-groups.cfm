<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: config-groups.cfm
File Date: 2012-02-01
Description: Displays config groups management table
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
<cfparam name="url.sortby" type="string" default="config_group_sort">
<cfparam name="url.sortdir" type="string" default="asc">
<!--- default form values --->
<cfparam name="form.config_group_name" default="">
<cfparam name="form.config_group_sort" default="1">
<cfparam name="	form.config_group_show_merchant" default="0">
<!--- default alerts --->
<cfparam name="request.cwpage.userAlert" default="">
<cfparam name="request.cwpage.userConfirm" default="">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,view,userconfirm,useralert,clickadd,resetapplication")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- QUERY: get all config groups --->
<cfset configGroupsQuery = CWquerySelectConfigGroups()>
<!--- make query sortable --->
<cfset configGroupsQuery = CWsortableQuery(configGroupsQuery)>
<!--- /////// --->
<!--- ADD NEW CONFIG GROUP --->
<!--- /////// --->
<cfif isDefined('form.config_group_name') and len(trim(form.config_group_name))>
	<!--- QUERY: insert new config group (name, sort, show merchant)--->
	<!--- this query returns the new id, or a 0- error --->
	<cfset newConfigGroupID = CWqueryInsertConfigGroup(
	trim(form.config_group_name),
	form.config_group_sort,
	form.config_group_show_merchant
	)>
	<!--- if no error returned from insert query --->
	<cfif not left(newConfigGroupID,2) eq '0-'>
		<!--- update complete: return to page showing message --->
		<cfsavecontent variable="request.cwpage.userConfirmText">
		<cfoutput>Config Group '#form.config_group_name#' Added&nbsp;&nbsp;<a href="config-group-details.cfm?group_ID=#newConfigGroupID#">Manage Details</a></cfoutput>
		</cfsavecontent>
		<cfset CWpageMessage("confirm",request.cwpage.userConfirmText)>
		<cflocation url="#request.cwpage.baseUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&sortby=#url.sortby#&sortdir=#url.sortdir#&clickadd=1&resetapplication=#application.cw.storePassword#" addtoken="no">
		<!--- if we have an insert error, show message, do not insert --->
	<cfelse>
		<cfset errorMsg = listLast(newConfigGroupID,'-')>
		<cfset CWpageMessage("alert",errorMsg)>
		<cfset url.clickadd = 1>
	</cfif>
	<!--- /END duplicate/error check --->
</cfif>
<!--- /////// --->
<!--- /END ADD NEW CONFIG GROUP --->
<!--- /////// --->
<!--- /////// --->
<!--- UPDATE CONFIG GROUPS --->
<!--- /////// --->
<!--- look for at least one valid ID field --->
<cfif isDefined('form.config_group_id1')>
	<cfset loopCt = 1>
	<cfset updateCt = 0>
	<cfset deleteCt = 0>
	<!--- loop record ids, handle each one as needed --->
	<cfloop list="#form.recordIDlist#" index="ID">
		<!--- param for show merchant checkbox --->
		<cfparam name="form['config_group_show_merchant#loopct#']" default="0">
		<!--- UPDATE RECORDS --->
		<!--- QUERY: update config group (ID, name, sort, show merchant)--->
		<cfset updateRecordID = CWqueryUpdateConfigGroup(
		#form["config_group_id#loopct#"]#,
		'#form["config_group_name#loopct#"]#',
		#form["config_group_sort#loopct#"]#,
		#form["config_group_show_merchant#loopct#"]#
		)>
		<!--- if no error returned from insert query --->
		<cfif left(updateRecordID,2) eq '0-'>
			<cfset errorMsg = listLast(updateRecordID,'-')>
			<cfset CWpageMessage("alert",errorMsg)>
			<!--- update complete: continue processing --->
		<cfelse>
			<cfset updateCt = updateCt + 1>
		</cfif>
		<!--- end error check --->
		<cfset loopCt = loopCt + 1>
	</cfloop>
	<!--- get the vars to keep by omitting the ones we don't want repeated --->
	<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert,method,resetapplication")>
	<!--- set up the base url --->
	<cfset request.cwpage.relocateUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
	<!--- save confirmation text --->
	<cfset CWpageMessage("confirm","Changes Saved")>
	<!--- return to page as submitted, clearing form scope --->
	<cflocation url="#request.cwpage.relocateUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END UPDATE / DELETE CONFIG GROUPS --->
<!--- /////// --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title
<title>
--->
<cfset request.cwpage.title = "Manage Config Groups">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Config Group Management">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = "Manage configuration groups for custom variables">
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
							<strong><a class="CWbuttonLink" id="showAddNewFormLink" href="#">Add New Config Group</a></strong>
						</div>
						<!--- /////// --->
						<!--- ADD NEW RECORD --->
						<!--- /////// --->
						<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>&clickadd=1" class="CWvalidate" name="addNewForm" id="addNewForm" method="post">
							<p>&nbsp;</p>
							<h3>Add New Config Group</h3>
							<table class="CWinfoTable wide">
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
											<input name="config_group_name" type="text" class="{required:true} focusField" title="Config Group Name is required" value="<cfoutput>#form.config_group_name#</cfoutput>" size="21">
										</div>
										<!--- submit button --->
										<br>
										<input name="SubmitAdd" type="submit" class="CWformButton" id="SubmitAdd" value="Save New Config Group">
									</td>
									<!--- sort order --->
									<td>
										<input name="config_group_sort" type="text" class="{required:true}" title="Sort Order is required" value="<cfoutput>#form.config_group_sort#</cfoutput>" size="5" maxlength="7" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
									</td>
									<!--- show merchant y/n --->
									<td style="text-align:center">
										<input name="config_group_show_merchant" type="checkbox" class="formCheckbox" value="1">
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
						<p>&nbsp;</p>
						<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" name="recordForm" id="recordForm" method="post" class="CWobserve">
							<!--- save changes / submit button --->
							<cfif configGroupsQuery.recordCount>
								<div class="CWadminControlWrap">
									<input name="SubmitUpdate" type="submit" class="CWformButton" id="SubmitUpdate" value="Save Changes">
									<div style="clear:right;"></div>
								</div>
								<!--- /END submit button --->
								<h3>Active Config Groups</h3>
							</cfif>
							<!--- if no records found, show message --->
							<cfif not configGroupsQuery.recordCount>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p><strong>No Config Groups available.</strong> <br><br></p>
								<!--- if records found --->
							<cfelse>
								<input type="hidden" value="<cfoutput>#configGroupsQuery.RecordCount#</cfoutput>" name="userCounter">
								<!--- save changes submit button --->
								<div style="clear:right;"></div>
								<!--- Records Table --->
								<table class="CWstripe CWsort wide" summary="<cfoutput>
									#request.cwpage.baseUrl#</cfoutput>">
									<thead>
									<tr class="sortRow">
										<th class="noSort" width="50">Edit</th>
										<th class="config_group_name">Config Group Name</th>
										<th class="config_group_sort">Sort</th>
										<th width="152" style="text-align:center;">
											<input type="checkbox" class="checkAll" rel="showMerchant">Show Merchant
										</th>
									</tr>
									</thead>
									<tbody>
									<cfoutput query="configGroupsQuery">
									<tr>
										<!--- details link --->
										<td style="text-align:center;"><a href="config-group-details.cfm?group_ID=#config_group_id#" title="Manage Config Group details" class="detailsLink"><img src="img/cw-edit.gif" width="15" height="15" alt="Manage Config Group Details"></a></td>
										<!--- group name --->
										<td>
											<input name="config_group_name#CurrentRow#" type="text" class="required" title="Config Group name required" value="#configGroupsQuery.config_group_name#" size="25" onblur="checkValue(this)">
											<!--- hidden fields used for processing update/delete --->
											<input name="config_group_id#CurrentRow#" type="hidden" value="#configGroupsQuery.config_group_id#">
											<input name="recordIDlist" type="hidden" value="#configGroupsQuery.config_group_id#">
										</td>
										<!--- sort --->
										<td>
											<input name="config_group_sort#CurrentRow#" type="text" class="required sort" title="Sort order required" value="#configGroupsQuery.config_group_sort#" maxlength="7" size="5" onkeyup="extractNumeric(this,2,true)" onblur="checkValue(this);">
										</td>
										<!--- show merchant --->
										<td style="text-align:center">
											<input type="checkbox" name="config_group_show_merchant#currentRow#" <cfif configgroupsquery.config_group_show_merchant neq 0>checked="checked"</cfif> value="1" class="formCheckbox showMerchant">
										</td>
									</tr>
									</cfoutput>
									</tbody>
								</table>
								<!--- show the submit button here if we have a long list --->
								<cfif configGroupsQuery.recordCount gt 10>
									<input name="SubmitUpdate" type="submit" class="CWformButton" id="SubmitUpdate" value="Save Changes">
								</cfif>
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