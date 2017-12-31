<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: ship-status.cfm
File Date: 2012-02-01
Description: Displays shipping status codes management table
==========================================================
--->
<!--- GLOBAL INCLUDES --->
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("developer")>
<!--- param for nav status update --->
<cfparam name="request.cwpage.updateStatus" default="0">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,view,userconfirm,useralert,clickadd")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- QUERY: get all credit cards --->
<cfset shipStatusQuery = CWquerySelectOrderStatus()>
<!--- /////// --->
<!--- UPDATE STATUS --->
<!--- /////// --->
<!--- look for at least one valid ID field --->
<cfif isDefined('form.shipstatus_id1')>
	<cfset loopCt = 1>
	<cfset updateCt = 0>
	<!--- loop record ids, handle each one as needed --->
	<cfloop list="#form.recordIDlist#" index="ID">
		<!--- UPDATE RECORDS --->
		<!--- QUERY: update ship status (ID, name, code)--->
		<cfset updateRecord = CWqueryUpdateShipStatus(
		#form["shipstatus_id#loopct#"]#,
		#form["shipstatus_name#loopct#"]#,
		#form["shipstatus_sort#loopct#"]#
		)>
		<cfset updateCt = updateCt + 1>
		<cfset loopCt = loopCt + 1>
	</cfloop>
	<!--- get the vars to keep by omitting the ones we don't want repeated --->
	<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert,method")>
	<!--- set up the base url --->
	<cfset request.cwpage.relocateUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
	<!--- save confirmation text --->
	<cfset CWpageMessage("confirm","Changes Saved")>
	<!--- return to page as submitted, clearing form scope --->
	<cflocation url="#request.cwpage.relocateUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END UPDATE STATUS --->
<!--- /////// --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title
<title>
--->
<cfset request.cwpage.title = "Manage Order Status Codes">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Order Status Code Management">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = "Manage order and shipping status codes">
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
						<!--- EDIT RECORDS --->
						<!--- /////// --->
						<p>&nbsp;</p>
						<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" name="recordForm" id="recordForm" method="post" class="CWobserve">
							<!--- /END submit button --->
							<!--- if no records found, show message --->
							<cfif not shipStatusQuery.recordCount>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p><strong>No Ship Status Codes available.</strong> <br><br></p>
								<!--- if records found --->
							<cfelse>
								<input type="hidden" value="<cfoutput>#shipStatusQuery.RecordCount#</cfoutput>" name="userCounter">
								<!--- save changes submit button --->
								<div style="clear:right;"></div>
								<table class="CWinfoTable wide">
									<thead>
									<tr class="headerRow">
										<th>Active Status Codes</th>
									</tr>
									</thead>
									<tr>
										<td>
											<!--- save changes / submit button --->
											<div class="CWadminControlWrap">
												<input name="SubmitUpdate" type="submit" class="CWformButton floatLeft" id="SubmitUpdate" value="Save Changes">
												<div style="clear:both;"></div>
											</div>
											<!--- Records Table --->
											<table class="CWstripe" summary="<cfoutput>
												#request.cwpage.baseUrl#</cfoutput>">
												<thead>
												<tr class="sortRow">
													<th width="180">Status Code</th>
													<th width="75">Sort</th>
												</tr>
												</thead>
												<tbody>
												<cfoutput query="shipStatusQuery">
												<tr class="dataRow">
													<!--- card name--->
													<td>
														<!--- hidden fields used for processing updates --->
														<p><strong>#shipStatusQuery.shipstatus_name#</strong></p>
														<input name="shipstatus_name#CurrentRow#" type="hidden" value="#shipStatusQuery.shipstatus_name#">
														<input name="shipstatus_id#CurrentRow#" type="hidden" value="#shipStatusQuery.shipstatus_id#">
														<input name="recordIDlist" type="hidden" value="#shipStatusQuery.shipstatus_id#">
													</td>
													<!--- sort--->
													<td>
														<input name="shipstatus_sort#CurrentRow#" type="text" value="#shipStatusQuery.shipstatus_sort#" class="sort" size="5" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
													</td>
												</tr>
												</cfoutput>
												</tbody>
											</table>
										</td>
									</tr>
								</table>
								<!--- show the submit button here if we have a long list --->
								<cfif shipStatusQuery.recordCount gt 10>
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