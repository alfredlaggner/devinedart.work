<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: tax-groups.cfm
File Date: 2012-02-01
Description: Manage Tax Groups
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
<cfparam name="url.tax_group_id" type="numeric" default="0">
<!--- default form values --->
<cfparam name="form.tax_group_name" default="">
<cfparam name="form.tax_group_code" default="">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("view,userconfirm,useralert,clickadd")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- ACTIVE VS. ARCHIVED --->
<cfif url.view contains 'arch'>
	<cfset request.cwpage.viewType = 'Archived'>
	<cfset request.cwpage.recordsArchived = 1>
	<cfset request.cwpage.subHead = 'Archived #application.cw.taxSystemLabel# Groups are ignored in the store'>
<cfelse>
	<cfset request.cwpage.viewType = 'Active'>
	<cfset request.cwpage.recordsArchived = 0>
	<cfset request.cwpage.subHead = 'Manage active #application.cw.taxSystemLabel# Groups or add a new #application.cw.taxSystemLabel# Group'>
</cfif>
<!--- QUERY: Get tax groups (active/archived )--->
<cfset taxGroupsQuery = CWquerySelectTaxGroups(request.cwpage.recordsArchived)>
<!--- /////// --->
<!--- ADD NEW TAX GROUP --->
<!--- /////// --->
<!--- if submitting the 'add new' form, and  --->
<cfif isDefined('form.tax_group_name') and len(trim(form.tax_group_name))>
	<!--- QUERY: insert new tax group (name, archived)--->
	<cfset newRecordID = CWqueryInsertTaxGroup(
	trim(form.tax_group_name),
	0,
	trim(form.tax_group_code)
	)>
	<!--- if no error returned from insert query --->
	<cfif not left(newRecordID,2) eq '0-'>
		<!--- update complete: return to page showing message --->
		<cfset CWpageMessage("confirm","#application.cw.taxSystemLabel# Group '#form.tax_group_name#' Added")>
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
<!--- /END ADD TAX GROUP --->
<!--- /////// --->
<!--- /////// --->
<!--- UPDATE / DELETE TAX GROUPS --->
<!--- /////// --->
<!--- look for at least one valid ID field --->
<cfif isDefined('form.tax_group_id1')>
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
		<cfif listFind(form.deleteRecord,evaluate('form.tax_group_id'&loopCt))>
			<!--- QUERY: delete record (record id) --->
			<cfset deleteRecord = CWqueryDeleteTaxGroup(id)>
			<cfset deleteCt = deleteCt + 1>
			<!--- if not deleting, update --->
		<cfelse>
			<!--- UPDATE RECORDS --->
			<!--- param for checkbox values --->
			<cfparam name="form.tax_group_archive#loopct#" default="#request.cwpage.recordsArchived#">
			<!--- QUERY: update record (ID, archived) --->
			<cfset updateRecord = CWqueryUpdateTaxGroup(
			#form["tax_group_id#loopct#"]#,
			#form["tax_group_archive#loopct#"]#
			)>
			<cfif #form["tax_group_archive#loopct#"]# is 1 and request.cwpage.recordsArchived is 0>
				<cfset archiveCt = archiveCt + 1>
			<cfelseif #form["tax_group_archive#loopct#"]# is 0 and request.cwpage.recordsArchived is 1>
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
	<cflocation url="#request.cwpage.relocateUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- END UPDATE / DELETE TAX GROUPS --->
<!--- /////// --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Manage #application.cw.taxSystemLabel# Groups">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "#application.cw.taxSystemLabel# Groups Management : #request.cwpage.viewType#">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 =  request.cwpage.subhead>
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
						<!--- if tax groups are not enabled --->
						<cfif application.cw.taxSystem neq "Groups">
							<div class="CWadminControlWrap">
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p class="formText"><strong><cfoutput>Tax#application.cw.taxSystemLabel#</cfoutput> groups disabled. To enable, select '<cfoutput>#application.cw.taxSystemLabel#</cfoutput> System: Groups' <a href="config-settings.cfm?group_ID=5">here</a></strong></p>
							</div>
							<!--- if using tax groups, proceed --->
						<cfelse>
							<!--- LINKS FOR VIEW TYPE --->
							<div class="CWadminControlWrap">
								<strong>
								<cfif url.view eq 'arch'>
									<a href="<cfoutput>#request.cw.thisPage#</cfoutput>">View Active</a>
								<cfelse>
									<a href="<cfoutput>#request.cw.thisPage#</cfoutput>?view=arch">View Archived</a>
									<!--- link for add-new form --->
									<cfif request.cwpage.recordsArchived is 0>
										&nbsp;&nbsp;<a class="CWbuttonLink" id="showAddNewFormLink" href="#">Add New <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Group</a>
									</cfif>
								</cfif>
								</strong>
							</div>
							<!--- /END LINKS FOR VIEW TYPE --->
							<!--- /////// --->
							<!--- ADD NEW TAX GROUP --->
							<!--- /////// --->
							<cfif request.cwpage.recordsArchived is 0>
								<!--- FORM --->
								<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" class="CWvalidate" name="addNewForm" id="addNewForm" method="post">
									<p>&nbsp;</p>
									<h3>Add New <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Group</h3>
									<table class="CWinfoTable">
										<thead>
										<tr>
											<th><cfoutput>#application.cw.taxSystemLabel#</cfoutput> Group Name</th>
											<th><cfoutput>#application.cw.taxSystemLabel#</cfoutput> Group Code</th>
										</tr>
										</thead>
										<tbody>
										<tr>
											<!--- group name --->
											<td style="text-align:center">
												<input name="tax_group_name" type="text" size="25" class="required focusField" title="Group Name is required" id="tax_group_name" value="<cfoutput>#form.tax_group_name#</cfoutput>">
												<br>
												<!--- submit button --->
												<input name="SubmitAdd" type="submit" class="CWformButton" id="SubmitAdd" value="Save New <cfoutput>#application.cw.taxSystemLabel#</cfoutput> Group">
											</td>
											<!--- group code --->
											<td style="text-align:center">
												<input name="tax_group_code" type="text" size="25" title="Group Code (optional)" id="tax_group_code" value="<cfoutput>#form.tax_group_code#</cfoutput>">
											</td>
										</tr>
										</tbody>
									</table>
								</form>
							</cfif>
							<!--- /////// --->
							<!--- /END ADD TAX GROUP --->
							<!--- /////// --->
							<!--- /////// --->
							<!--- EDIT RECORDS --->
							<!--- /////// --->
							<form action="<cfoutput>#request.cwpage.baseUrl#&view=#url.view#</cfoutput>" name="recordForm" id="recordForm" method="post" class="CWobserve">
								<!--- if no records found, show message --->
								<cfif not taxGroupsQuery.recordCount>
									<p>&nbsp;</p>
									<p>&nbsp;</p>
									<p>&nbsp;</p>
									<p><strong>No <cfoutput>#request.cwpage.viewtype# #application.cw.taxSystemLabel#</cfoutput> Groups available.</strong> <br><br></p>
									<!--- if records found --->
								<cfelse>
									<!--- output records --->
									<!--- Container table --->
									<table class="CWinfoTable wide">
										<thead>
										<tr class="headerRow">
											<th><cfoutput>#request.cwpage.viewType# #application.cw.taxSystemLabel# Groups</cfoutput></th>
										</tr>
										</thead>

										<tbody>
										<tr>
											<td>
												<input type="hidden" value="<cfoutput>#taxgroupsQuery.RecordCount#</cfoutput>" name="Counter">
												<!--- save changes submit button --->
												<input name="SubmitUpdate" type="submit" class="CWformButton" id="SubmitUpdate" value="Save Changes">
												<div style="clear:right;"></div>
												<cfset disabledDeleteCt = 0>
												<!--- Method Records Table --->
												<table class="CWinfoTable CWstripe">
													<tr>
														<th width="220"><cfoutput>#application.cw.taxSystemLabel# Group Name</cfoutput></th>
														<th width="85" style="text-align:center;"><input type="checkbox" class="checkAll" name="checkAllDelete" rel="checkAllDel">Delete</th>
														<th width="85" style="text-align:center;"><input type="checkbox" class="checkAll" name="checkAllArchive" rel="checkAllArch"><cfif request.cwpage.viewType contains 'arch'>Activate<cfelse>Archive</cfif></th>
													</tr>
													<cfoutput query="taxGroupsQuery">
													<!--- QUERY: check for existing related products --->
													<cfset taxGroupProductsQuery = CWquerySelectTaxGroupProducts(taxgroupsQuery.tax_group_id)>
													<cfset taxGroupProducts = taxGroupProductsQuery.recordCount>
													<tr>
														<!--- tax group name --->
														<td style="text-align:right;">
															<!--- show row number --->
															<strong><a href="tax-group-details.cfm?tax_group_id=#taxGroupsQuery.tax_group_id#">#taxGroupsQuery.tax_group_name#<cfif len(trim(taxgroupsquery.tax_group_code))> (#trim(taxgroupsquery.tax_group_code)#)</cfif></a></strong>
															<!--- hidden fields used for processing update/delete --->
															<input name="recordIDlist" type="hidden" value="#taxgroupsquery.tax_group_id#">
															<input name="tax_group_id#CurrentRow#" type="hidden" id="tax_group_id#CurrentRow#" value="#taxgroupsquery.tax_group_id#">
														</td>
														<!--- delete --->
														<td style="text-align:center">
															<input type="checkbox" value="#tax_group_id#" class="formCheckbox radioGroup checkAllDel" rel="group#currentRow#" name="deleteRecord"<cfif taxgroupProducts neq 0> disabled="disabled"</cfif>>
															<cfif taxgroupProducts neq 0>
																<cfset disabledDeleteCt = disabledDeleteCt + 1>
															</cfif>
														</td>
														<!--- archive --->
														<td style="text-align:center">
															<input type="checkbox" value="<cfif request.cwpage.viewType eq 'Active'>1<cfelse>0</cfif>" class="checkAllArch formCheckbox radioGroup" rel="group#currentRow#" name="tax_group_archive#CurrentRow#">
														</td>
													</tr>
													</cfoutput>
												</table>
												<!--- /END Method Records Table --->
												<!--- if we have disabled delete boxes, explain --->
												<span class="smallPrint" style="float:right;">
													<cfif disabledDeleteCt>
														Note: records with associated orders cannot be deleted
													</cfif>
												</span>
											</td>
										</tr>
										</tbody>
									</table>
									<!--- /END Output Records --->
								</cfif>
								<!--- /END if records found --->
							</form>
						</cfif>
						<!--- /end if tax groups enabled --->
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