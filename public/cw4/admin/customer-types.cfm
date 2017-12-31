<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: customer-types.cfm
File Date: 2012-12-04
Description: Displays customer types management table
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
<cfparam name="url.sortby" type="string" default="customer_type_name">
<cfparam name="url.sortdir" type="string" default="asc">
<!--- default form values --->
<cfparam name="form.customer_type_name" default="">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,view,userconfirm,useralert,clickadd")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- QUERY: get all customer types --->
<cfset customerTypesQuery = CWquerySelectCustomerTypes()>
<!--- make query sortable --->
<cfset customerTypesQuery = CWsortableQuery(customerTypesQuery)>
<!--- QUERY: get count of members in each type --->
<cfset customerCountQuery = CWquerySelectCustomerTypes(count_members=true)>
<cfset customerCountArray = arrayNew(1)>
<!--- put count into array --->
<cfloop query="customerCountQuery">
	<cfset customerCountArray[customerCountQuery.customer_type_id] = customerCountQuery.customer_type_members>
</cfloop>
<!--- /////// --->
<!--- ADD NEW CUSTOMER TYPE --->
<!--- /////// --->
<cfif isDefined('form.customer_type_name') and len(trim(form.customer_type_name))>
	<!--- QUERY: insert new customer type (name)--->
	<!--- this query returns the new id, or a 0- error --->
	<cfset newCustomerTypeID = CWqueryInsertCustomerType(
	trim(form.customer_type_name)
	)>
	<!--- if no error returned from insert query --->
	<cfif not left(newCustomerTypeID,2) eq '0-'>
		<!--- update complete: return to page showing message --->
		<cfset CWpageMessage("confirm","Customer Type '#form.customer_type_name#' Added")>
		<cflocation url="#request.cwpage.baseUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&sortby=#url.sortby#&sortdir=#url.sortdir#&clickadd=1" addtoken="no">
		<!--- if we have an insert error, show message, do not insert --->
	<cfelse>
		<cfset errorMsg = listLast(newCustomerTypeID,'-')>
		<cfset CWpageMessage("alert","Error: #errorMsg#")>
		<cfset url.clickadd = 1>
	</cfif>
	<!--- /END duplicate/error check --->
</cfif>
<!--- /////// --->
<!--- /END ADD NEW CUSTOMER TYPE --->
<!--- /////// --->
<!--- /////// --->
<!--- UPDATE / DELETE CUSTOMER TYPES --->
<!--- /////// --->
<!--- look for at least one valid ID field --->
<cfif isDefined('form.customer_type_id1')>
	<cfparam name="form.deleteRecord" default="">
	<cfset loopCt = 1>
	<cfset updateCt = 0>
	<cfset deleteCt = 0>
	<!--- loop record ids, handle each one as needed --->
	<cfloop list="#form.recordIDlist#" index="ID">
		<!--- DELETE RECORDS --->
		<!--- if the record ID is marked for deletion --->
		<cfif listFind(form.deleteRecord,trim(evaluate('form.customer_type_id'&loopCt)))>
			<!--- QUERY: delete record (record id) --->
			<cfset deleteRecord = CWqueryDeletecustomer_type(id)>
			<cfset deleteCt = deleteCt + 1>
			<!--- if not deleting, update --->
		<cfelse>
			<!--- UPDATE RECORDS --->
			<!--- QUERY: update customer type (ID, name)--->
			<cfset updateRecordID = CWqueryUpdateCustomerType(
			#form["customer_type_id#loopct#"]#,
			'#form["customer_type_name#loopct#"]#'
			)>
			<!--- if no error returned from insert query --->
			<cfif left(updateRecordID,2) eq '0-'>
				<cfset errorMsg = listLast(updateRecordID,'-')>
				<cfset CWpageMessage("alert",errorMsg)>
				<!--- update complete: continue processing --->
			<cfelse>
				<cfset updateCt = updateCt + 1>
			</cfif>
			<!--- end duplicate check --->
		</cfif>
		<!--- /END delete vs. update --->
		<cfset loopCt = loopCt + 1>
	</cfloop>
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
<!--- /////// --->
<!--- /END UPDATE / DELETE CUSTOMER TYPES --->
<!--- /////// --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title
<title>
--->
<cfset request.cwpage.title = "Manage Customer Types">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Customer Type Management">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = "Manage customer groups used for discounts">
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
							<strong><a class="CWbuttonLink" id="showAddNewFormLink" href="#">Add New Customer Type</a></strong>
						</div>
						<!--- /////// --->
						<!--- ADD NEW RECORD --->
						<!--- /////// --->
						<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>&clickadd=1" class="CWvalidate" name="addNewForm" id="addNewForm" method="post">
							<p>&nbsp;</p>
							<h3>Add New Customer Type</h3>
							<table class="CWinfoTable wide">
								<thead>
								<tr>
									<th width="165">Customer Type Name</th>
								</tr>
								</thead>
								<tbody>
								<tr>
									<!--- customer type name --->
									<td>
										<div>
											<input name="customer_type_name" tabindex="1" type="text" class="{required:true,minlength:2}" title="Customer Type Name is required" value="<cfoutput>#form.customer_type_name#</cfoutput>" size="21">
										</div>
										<br>
										<input name="SubmitAdd" type="submit" tabindex="3" class="CWformButton" id="SubmitAdd" value="Save New Customer Type">
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
							<cfif customerTypesQuery.recordCount>
								<div class="CWadminControlWrap">
									<input name="SubmitUpdate" type="submit" class="CWformButton" id="SubmitUpdate" value="Save Changes">
									<div style="clear:right;"></div>
								</div>
								<!--- /END submit button --->
								<h3>Active Customer Types</h3>
							</cfif>
							<!--- if no records found, show message --->
							<cfif not customerTypesQuery.recordCount>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p><strong>No Customer Types available.</strong> <br><br></p>
								<!--- if records found --->
							<cfelse>
								<input type="hidden" value="<cfoutput>#customerTypesQuery.RecordCount#</cfoutput>" name="userCounter">
								<!--- save changes submit button --->
								<div style="clear:right;"></div>
								<!--- Records Table --->
								<table class="CWstripe CWsort wide" summary="<cfoutput>#request.cwpage.baseUrl#</cfoutput>">
									<thead>
									<tr class="sortRow">
										<th class="customer_type_name">Customer Type Name</th>
										<th class="noSort">Members</th>
										<th class="customer_type_id">ID</th>
										<th class="noSort" width="82" style="text-align:center;">
											<input type="checkbox" class="checkAll" rel="userDelete">Delete
										</th>
									</tr>
									</thead>
									<tbody>
									<cfoutput query="customerTypesQuery">
									<tr>
										<!--- type name--->
										<td>
											<input name="customer_type_name#CurrentRow#" type="text" class="required" title="Customer type name required" value="#customerTypesQuery.customer_type_name#" size="25">
											<!--- hidden fields used for processing update/delete --->
											<input name="customer_type_id#CurrentRow#" type="hidden" value="#customerTypesQuery.customer_type_id#">
											<input name="recordIDlist" type="hidden" value="#customerTypesQuery.customer_type_id#">
										</td>
										<!--- count of members --->
										
										<cfparam name="customerCountArray[customerTypesQuery.customer_type_id]" default="0">	
										<cfset customerCount = customerCountArray[customerTypesQuery.customer_type_id]>
										<td><cfif isNumeric(customerCount)>#customerCount#<cfelse>0</cfif></td>
										<!--- id for coding reference --->
										<td>#customerTypesQuery.customer_type_id#</td>
										<!--- delete --->
										<td style="text-align:center">
											<cfif customerCount lte 0><input type="checkbox" value="#customer_type_id#" class="formCheckbox userDelete" name="deleteRecord"></cfif>
										</td>
									</tr>
									</cfoutput>
									</tbody>
								</table>
								<!--- if we have disabled delete boxes, explain --->
								<span class="smallPrint">
									<cfif customerCountQuery.recordCount>
										Note: types with associated customers cannot be deleted
									</cfif>
								</span>
								
								<!--- show the submit button here if we have a long list --->
								<cfif customerTypesQuery.recordCount gt 10>
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