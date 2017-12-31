<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: credit-cards.cfm
File Date: 2012-02-01
Description: Displays credit card management table
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
<cfparam name="url.sortby" type="string" default="creditcard_name">
<cfparam name="url.sortdir" type="string" default="asc">
<!--- default form values --->
<cfparam name="form.creditcard_name" default="">
<cfparam name="form.creditcard_code" default="">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,view,userconfirm,useralert,clickadd")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- QUERY: get all credit cards --->
<cfset creditcardsQuery = CWquerySelectCreditCards()>
<!--- make query sortable --->
<cfset creditcardsQuery = CWsortableQuery(creditcardsQuery)>
<!--- /////// --->
<!--- ADD NEW CREDIT CARD --->
<!--- /////// --->
<cfif isDefined('form.creditcard_name') and len(trim(form.creditcard_name))>
	<!--- QUERY: insert new credit card (name, code)--->
	<!--- this query returns the new id, or a 0- error --->
	<cfset newCreditCardID = CWqueryInsertCreditCard(
	trim(form.creditcard_name),
	trim(form.creditcard_code)
	)>
	<!--- if no error returned from insert query --->
	<cfif not left(newCreditCardID,2) eq '0-'>
		<!--- update complete: return to page showing message --->
		<cfset CWpageMessage("confirm","Credit Card '#form.creditcard_name#' Added")>
		<cflocation url="#request.cwpage.baseUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&sortby=#url.sortby#&sortdir=#url.sortdir#&clickadd=1" addtoken="no">
		<!--- if we have an insert error, show message, do not insert --->
	<cfelse>
		<cfset errorMsg = listLast(newCreditCardID,'-')>
		<cfset CWpageMessage("alert","Error: #errorMsg#")>
		<cfset url.clickadd = 1>
	</cfif>
	<!--- /END duplicate/error check --->
</cfif>
<!--- /////// --->
<!--- /END ADD NEW CREDIT CARD --->
<!--- /////// --->
<!--- /////// --->
<!--- UPDATE / DELETE CREDIT CARDS --->
<!--- /////// --->
<!--- look for at least one valid ID field --->
<cfif isDefined('form.creditcard_ID1')>
	<cfparam name="form.deleteRecord" default="">
	<cfset loopCt = 1>
	<cfset updateCt = 0>
	<cfset deleteCt = 0>
	<!--- loop record ids, handle each one as needed --->
	<cfloop list="#form.recordIDlist#" index="ID">
		<!--- DELETE RECORDS --->
		<!--- if the record ID is marked for deletion --->
		<cfif listFind(form.deleteRecord,trim(evaluate('form.creditcard_ID'&loopCt)))>
			<!--- QUERY: delete record (record id) --->
			<cfset deleteRecord = CWqueryDeleteCreditCard(id)>
			<cfset deleteCt = deleteCt + 1>
			<!--- if not deleting, update --->
		<cfelse>
			<!--- UPDATE RECORDS --->
			<!--- QUERY: update credit card (ID, name, code)--->
			<cfset updateRecordID = CWqueryUpdateCreditCard(
			#form["creditcard_ID#loopct#"]#,
			'#form["creditcard_name#loopct#"]#',
			'#form["creditcard_code#loopct#"]#'
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
<!--- /END UPDATE / DELETE CREDIT CARDS --->
<!--- /////// --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title
<title>
--->
<cfset request.cwpage.title = "Manage Credit Cards">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Credit Card Management">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = "Manage accepted credit cards and codes">
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
							<strong><a class="CWbuttonLink" id="showAddNewFormLink" href="#">Add New Credit Card</a></strong>
						</div>
						<!--- /////// --->
						<!--- ADD NEW RECORD --->
						<!--- /////// --->
						<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>&clickadd=1" class="CWvalidate" name="addNewForm" id="addNewForm" method="post">
							<p>&nbsp;</p>
							<h3>Add New Credit Card</h3>
							<table class="CWinfoTable wide">
								<thead>
								<tr>
									<th width="165">Card Name</th>
									<th>Card Code</th>
								</tr>
								</thead>
								<tbody>
								<tr>
									<!--- card name --->
									<td>
										<div>
											<input name="creditcard_name" tabindex="1" type="text" class="{required:true,minlength:2}" title="Credit Card Name is required" value="<cfoutput>#form.creditcard_name#</cfoutput>" size="21">
										</div>
										<br>
										<input name="SubmitAdd" type="submit" tabindex="3" class="CWformButton" id="SubmitAdd" value="Save New Credit Card">
									</td>
									<td>
										<input name="creditcard_code" type="text" tabindex="2" class="{required:true,minlength:2}" title="Credit Card Code is required" value="<cfoutput>#form.creditcard_code#</cfoutput>" size="15">
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
							<cfif creditcardsQuery.recordCount>
								<div class="CWadminControlWrap">
									<input name="SubmitUpdate" type="submit" class="CWformButton" id="SubmitUpdate" value="Save Changes">
									<div style="clear:right;"></div>
								</div>
								<!--- /END submit button --->
								<h3>Accepted Credit Cards</h3>
							</cfif>
							<!--- if no records found, show message --->
							<cfif not creditcardsQuery.recordCount>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p><strong>No Credit Cards available.</strong> <br><br></p>
								<!--- if records found --->
							<cfelse>
								<input type="hidden" value="<cfoutput>#creditcardsQuery.RecordCount#</cfoutput>" name="userCounter">
								<!--- save changes submit button --->
								<div style="clear:right;"></div>
								<!--- Records Table --->
								<table class="CWstripe CWsort wide" summary="<cfoutput>
									#request.cwpage.baseUrl#</cfoutput>">
									<thead>
									<tr class="sortRow">
										<th class="creditcard_name">Card Name</th>
										<th class="creditcard_code">Card Code</th>
										<th width="82" style="text-align:center;">
											<input type="checkbox" class="checkAll" rel="userDelete">Delete
										</th>
									</tr>
									</thead>
									<tbody>
									<cfoutput query="creditcardsQuery">
									<tr>
										<!--- card name--->
										<td>
											<input name="creditcard_name#CurrentRow#" type="text" class="required" title="Credit card name required" value="#creditcardsQuery.creditcard_name#" size="25">
											<!--- hidden fields used for processing update/delete --->
											<input name="creditcard_ID#CurrentRow#" type="hidden" value="#creditcardsQuery.creditcard_ID#">
											<input name="recordIDlist" type="hidden" value="#creditcardsQuery.creditcard_ID#">
										</td>
										<!--- code--->
										<td>
											<input name="creditcard_code#CurrentRow#" type="text" class="required" title="Credit card code required" value="#creditcardsQuery.creditcard_code#" size="12">
										</td>
										<!--- delete --->
										<td style="text-align:center">
											<input type="checkbox" value="#creditcard_ID#" class="formCheckbox userDelete" name="deleteRecord">
										</td>
									</tr>
									</cfoutput>
									</tbody>
								</table>
								<!--- show the submit button here if we have a long list --->
								<cfif creditcardsQuery.recordCount gt 10>
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