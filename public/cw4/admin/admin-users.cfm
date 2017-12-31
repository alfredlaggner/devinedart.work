<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: admin-users.cfm
File Date: 2012-08-25
Description: Displays admin user management
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
<!--- default values for sort --->
<cfparam name="url.sortby" type="string" default="admin_user_alias">
<cfparam name="url.sortdir" type="string" default="asc">
<!--- default form values --->
<cfparam name="form.admin_user_alias" type="string" default="">
<cfparam name="form.admin_user_email" type="string" default="">
<cfparam name="form.admin_username" type="string" default="">
<cfparam name="form.admin_password" type="string" default="">
<cfparam name="form.admin_access_level" type="string" default="merchant">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("view,userconfirm,useralert,clickadd,sortby,sortdir")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- QUERY: get all users (ID (0=all), username [blank], levels to omit) --->
<cfif listFindNoCase('developer',request.cwpage.accessLevel)>
	<!--- if developer, get all --->
	<cfset usersQuery = CWquerySelectAdminUsers(0)>
<cfelse>
	<!--- if merchant, don't get developers --->
	<cfset usersQuery = CWquerySelectAdminUsers(0,'','developer')>
</cfif>
<!--- make query sortable --->
<cfset usersQuery = CWsortableQuery(usersQuery)>
<!--- /////// --->
<!--- ADD NEW ADMIN USER --->
<!--- /////// --->
<cfif isDefined('form.admin_username') and len(trim(form.admin_username))>
	<!--- QUERY: insert new user (username, password, user level, name, email)--->
	<!--- this query returns the category id, or an error like '0-fieldname' --->
	<cfset newUserID = CWqueryInsertUser(
	trim(form.admin_username),
	trim(form.admin_password),
	trim(form.admin_access_level),
	trim(form.admin_user_alias),
	trim(form.admin_user_email)
	)>
	<!--- if no error returned from insert query --->
	<cfif not left(newUserID,2) eq '0-'>
		<!--- update complete: return to page showing message --->
		<cfset CWpageMessage("confirm","User '#form.admin_username#' Added")>
		<cflocation url="#request.cwpage.baseUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&sortby=#url.sortby#&sortdir=#url.sortdir#&clickadd=1" addtoken="no">
		<!--- if we have an insert error, show message, do not insert --->
	<cfelse>
		<cfset dupField = listLast(newUserID,'-')>
		<cfset CWpageMessage("alert","Error: #dupfield# '#form.admin_username#' already exists")>
		<cfset url.clickadd = 1>
	</cfif>
	<!--- /END duplicate/error check --->
</cfif>
<!--- /////// --->
<!--- /END ADD NEW ADMIN USER --->
<!--- /////// --->
<!--- /////// --->
<!--- UPDATE / DELETE ADMIN USERS --->
<!--- /////// --->
<!--- look for at least one valid ID field --->
<cfif isDefined('form.admin_user_id1')>
	<cfparam name="form.deleteRecord" default="">
	<cfset loopCt = 1>
	<cfset updateCt = 0>
	<cfset deleteCt = 0>
	<!--- loop record ids, handle each one as needed --->
	<cfloop list="#form.recordIDlist#" index="ID">
		<!--- DELETE RECORDS --->
		<!--- if the record ID is marked for deletion --->
		<cfif listFind(form.deleteRecord,trim(evaluate('form.admin_user_id'&loopCt)))>
			<!--- QUERY: delete record (record id) --->
			<cfset deleteRecord = CWqueryDeleteUser(id)>
			<cfset deleteCt = deleteCt + 1>
			<!--- if not deleting, update --->
		<cfelse>
			<!--- UPDATE RECORDS --->
			<cfset userEmail = '#form["admin_user_email#loopct#"]#'>
			<cfif not isValid('email',userEmail)>
				<cfset insertError = "Error: email address '#useremail#' is not valid">
			<cfelse>
				<!--- QUERY: update admin user (ID, username, password, user level, name, email)--->
				<cfset updateRecordID = CWqueryUpdateUser(
				#form["admin_user_id#loopct#"]#,
				'#form["admin_username#loopct#"]#',
				'#form["admin_password#loopct#"]#',
				'#form["admin_access_level#loopct#"]#',
				'#form["admin_user_alias#loopct#"]#',
				'#form["admin_user_email#loopct#"]#'
				)>
				<!--- if no error returned from insert query --->
				<cfif left(updateRecordID,2) eq '0-'>
					<cfset errorName = '#form["admin_username#loopct#"]#'>
					<cfset CWpageMessage("alert","Error: User Name '#errorName#' already exists")>
					<!--- update complete: continue processing --->
				<cfelse>
					<cfset updateCt = updateCt + 1>
				</cfif>
				<!--- end duplicate check --->
			</cfif>
		</cfif>
		<!--- /END delete vs. update --->
		<cfset loopCt = loopCt + 1>
	</cfloop>
	<!--- check for default password still in use --->
	<cfset getDefaultUsers = CWquerySelectUserLogin('admin,sa,merchant,developer,manager,service','admin',6)>
	<cfif getDefaultUsers.recordCount gt 0 and not application.cw.appTestModeEnabled>
		<cfset session.cw.useralert = 'IMPORTANT: Default password (admin) still in use. Create a new user account or <a href="#cwTrailingChar(application.cw.appSiteUrlHttp)##cwTrailingChar(cwLeadingChar(application.cw.appCWAdminDir,"remove"),"remove")#/admin-users.cfm">change the password</a>.'>
	<cfelse>
		<cfset session.cw.useralert = ''>
	</cfif>
	<!--- if we have errors, return showing details about last errant record --->
	<cfif isDefined('insertError')>
		<cflocation url="#request.cwpage.baseUrl#&useralert=#CWurlSafe(insertError)#&clickadd=1" addtoken="no">
		<!--- if no errors, return showing message --->
	<cfelse>
		<!--- get the vars to keep by omitting the ones we don't want repeated --->
		<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert,method")>
		<!--- set up the base url --->
		<cfset request.cwpage.relocateUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
		<!--- save confirmation text --->
		<cfif updateCt gt 0>
			<cfset CWpageMessage("confirm","Changes Saved")>
		</cfif>
		<!--- save alert text --->
		<cfif deleteCt gt 0>
			<cfsavecontent variable="request.cwpage.alertText">
			<cfoutput>#deleteCt# Record<cfif deleteCt gt 1>s</cfif> Deleted</cfoutput>
			</cfsavecontent>
			<cfset CWpageMessage("alert",request.cwpage.alertText)>
			<cfset request.cwpage.relocateUrl = request.cwpage.relocateUrl & '&useralert=#CWurlSafe(request.cwpage.userAlert)#'>
		</cfif>
		<!--- return to page as submitted, clearing form scope --->
		<cflocation url="#request.cwpage.relocateUrl#" addtoken="no">
	</cfif>
	<!--- /end if no errors --->
</cfif>
<!--- /////// --->
<!--- /END UPDATE / DELETE ADMIN USERS --->
<!--- /////// --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title
<title>
--->
<cfset request.cwpage.title = "Manage Admin Users">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Admin User Management">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = "Manage user account details or add new admin users">
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
							<strong><a class="CWbuttonLink" id="showAddNewFormLink" href="#">Add New Admin User</a></strong>
						</div>
						<!--- /////// --->
						<!--- ADD NEW RECORD --->
						<!--- /////// --->
						<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>&clickadd=1" class="CWvalidate" name="addNewForm" id="addNewForm" method="post">
							<p>&nbsp;</p>
							<h3>Add New Admin User</h3>
							<table class="CWinfoTable wide">
								<thead>
								<tr>
									<th width="165">Access Level</th>
									<th>Login Name</th>
									<th>Login Password</th>
									<th>Name / Title</th>
									<th>Email</th>
								</tr>
								</thead>
								<tbody>
								<tr>
									<!--- access level --->
									<td>
										<div>
											<select name="admin_access_level">
												<option value="service"<cfif form.admin_access_level eq 'service'> selected="selected"</cfif>>Customer Service (service)</option>
												<option value="manager"<cfif form.admin_access_level eq 'manager'> selected="selected"</cfif>>Store Manager (manager)</option>
												<option value="merchant"<cfif form.admin_access_level eq 'merchant'> selected="selected"</cfif>>Site Owner (merchant)</option>
												<cfif request.cwpage.accessLevel is 'developer'>
													<option value="developer"<cfif form.admin_access_level eq 'developer'> selected="selected"</cfif>>Developer (developer)</option>
												</cfif>
											</select>
										</div>
										<br>
										<input name="SubmitAdd" type="submit" class="CWformButton" id="SubmitAdd" value="Save New Admin User">
									</td>
									<!--- username--->
									<td>
										<input name="admin_username" type="text" class="{required:true,minlength:2}" maxlength="45" title="Username is required" value="<cfoutput>#form.admin_username#</cfoutput>" size="15">
									</td>
									<!--- password--->
									<td>
										<input name="admin_password" type="text" class="{required:true,minlength:5}" maxlength="45" title="Password must be at least 6 characters" value="<cfoutput>#form.admin_password#</cfoutput>" size="15">
									</td>
									<!--- name / title --->
									<td>
										<input name="admin_user_alias" type="text" class="required" maxlength="45" title="User's name or title required" value="<cfoutput>#form.admin_user_alias#</cfoutput>" size="15">
									</td>
									<!--- email--->
									<td>
										<input name="admin_user_email" type="text" class="{email:true}" maxlength="75" title="Email must be a valid address (e.g. user@domain.com) or left blank" value="<cfoutput>#form.admin_user_email#</cfoutput>" size="15">
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
							<cfif usersQuery.recordCount>
								<div class="CWadminControlWrap">
									<input name="SubmitUpdate" type="submit" class="CWformButton" id="SubmitUpdate" value="Save Changes">
									<div style="clear:right;"></div>
								</div>
								<!--- /END submit button --->
								<h3>Active Admin Users</h3>
							</cfif>
							<!--- if no records found, show message --->
							<cfif not usersQuery.recordCount>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p><strong>No Admin User accounts available.</strong> <br><br></p>
								<!--- if records found --->
							<cfelse>
								<input type="hidden" value="<cfoutput>#usersQuery.RecordCount#</cfoutput>" name="userCounter">
								<!--- save changes submit button --->
								<div style="clear:right;"></div>
								<!--- Records Table --->
								<table class="CWstripe CWsort" summary="<cfoutput>
									#request.cwpage.baseUrl#</cfoutput>">
									<thead>
									<tr class="sortRow">
										<th class="admin_username">Login Name</th>
										<th class="admin_password">Password</th>
										<th class="admin_access_level">Access Level</th>
										<th class="admin_user_alias">Name / Title</th>
										<th class="admin_user_email">Email</th>
										<th width="82" style="text-align:center;">
											<input type="checkbox" class="checkAll" rel="userDelete">Delete
										</th>
									</tr>
									</thead>
									<tbody>
									<cfoutput query="usersQuery">
									<!--- show delete or user level as disabled under these conditions --->
									<cfif admin_username eq session.cw.loggedUser>
										<cfset currentDisabled = 1>
									<cfelse>
										<cfset currentDisabled = 0>
									</cfif>
									<tr>
										<!--- username--->
										<td>
											<strong>#admin_username#</strong>
											<br>
											<span class="smallPrint">#LSdateFormat(admin_login_date,application.cw.globalDateMask)# #timeFormat(admin_login_date)#</span>
											<!--- hidden fields used for processing update/delete --->
											<input name="admin_username#CurrentRow#" type="hidden" value="#usersQuery.admin_username#">
											<input name="admin_user_id#CurrentRow#" type="hidden" value="#usersQuery.admin_user_id#">
											<input name="recordIDlist" type="hidden" value="#usersQuery.admin_user_id#">
										</td>
										<!--- password--->
										<td>
											<input name="admin_password#CurrentRow#" type="text" class="{required:true,minlength:6}" maxlength="45" title="Password must be at least 6 characters" value="#usersQuery.admin_password#" size="12">
										</td>
										<!--- access level --->
										<td>
											<cfif currentDisabled eq 1>
												#admin_access_level#
												<input name="admin_access_level#CurrentRow#" type="hidden" value="#usersQuery.admin_access_level#">
											<cfelse>
												<select name="admin_access_level#CurrentRow#">
													<option value="service"<cfif usersQuery.admin_access_level eq 'service'> selected="selected"</cfif>>Customer Service (service)</option>
													<option value="manager"<cfif usersQuery.admin_access_level eq 'manager'> selected="selected"</cfif>>Store Manager (manager)</option>
													<option value="merchant"<cfif usersQuery.admin_access_level eq 'merchant'> selected="selected"</cfif>>Site Owner (merchant)</option>
													<cfif request.cwpage.accessLevel is 'developer'>
														<option value="developer"<cfif usersQuery.admin_access_level eq 'developer'> selected="selected"</cfif>>Developer (developer)</option>
													</cfif>
												</select>
											</cfif>
										</td>
										<!--- name / title --->
										<td>
											<input name="admin_user_alias#CurrentRow#" type="text" class="required" maxlength="45" title="User's name or title required" value="#usersQuery.admin_user_alias#" size="12">
										</td>
										<!--- email--->
										<td>
											<input name="admin_user_email#CurrentRow#" type="text" class="{email:true}" maxlength="75" title="Email must be a valid address (e.g. user@domain.com) or left blank" value="#usersQuery.admin_user_email#" size="12">
										</td>
										<!--- delete --->
										<td style="text-align:center">
											<input type="checkbox" value="#admin_user_id#" class="formCheckbox userDelete" name="deleteRecord"<cfif currentDisabled> disabled="disabled"</cfif>>
										</td>
									</tr>
									</cfoutput>
									</tbody>
								</table>
								<!--- show the submit button here if we have a long list --->
								<cfif usersQuery.recordCount gt 10>
									<input name="SubmitUpdate" type="submit" class="CWformButton" id="SubmitUpdate" value="Save Changes">
								</cfif>
								<!--- explain delete restriction --->
								<span class="smallPrint" style="float:right;">
									Note: You cannot delete your own account
								</span>
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