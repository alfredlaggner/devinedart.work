<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: discounts.cfm
File Date: 2012-02-01
Description: Displays list of active/archived discounts
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
<!--- default values for sort / active or archived--->
<cfparam name="url.sortby" type="string" default="discount_merchant_id">
<cfparam name="url.sortdir" type="string" default="asc">
<cfparam name="url.view" type="string" default="active">

<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert,sortby,sortdir,archiveid,reactivateid")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>

<!--- ACTIVE VS ARCHIVED --->
<cfif url.view contains 'arch'>
	<cfset request.cwpage.viewType = 'Archived'>
	<cfset request.cwpage.subHead = 'Archived discounts are not available for customer use'>
<cfelse>
	<cfset request.cwpage.viewType = 'Active'>
	<cfset request.cwpage.subHead = 'Manage active discounts or add a new discount'>
</cfif>

<!--- /////// --->
<!--- ARCHIVE DISCOUNT --->
<!--- /////// --->
<cfif isDefined('url.archiveid') AND url.archiveid gt 0>
	<!--- QUERY: archive the product (product id) --->
	<cfset temp = CWqueryArchiveDiscount(url.archiveid)>
	<cfset confirmMsg = 'Discount Archived: Use Archived Discounts menu link to view or reactivate'>
	<cfset CWpageMessage("confirm",confirmMsg)>
</cfif>
<!--- /////// --->
<!--- /END ARCHIVE DISCOUNT --->
<!--- /////// --->
<!--- /////// --->
<!--- ACTIVATE DISCOUNT --->
<!--- /////// --->
<cfif isDefined('url.reactivateid') AND url.reactivateid gt 0>
	<!--- QUERY: reactivate product (product ID) --->
	<cfset temp = CWqueryReactivateDiscount(url.reactivateid)>
	<cfset request.cwpage.userConfirmText = 'Discount Reactivated: <a href="discount-details.cfm?discount_id=#url.reactivateid#">View Discount Details</a>'>
	<cfset CWpageMessage("confirm",request.cwpage.userConfirmText)>
</cfif>
<!--- /////// --->
<!--- /END ACTIVATE DISCOUNT --->
<!--- /////// --->

<!--- QUERY: get all discounts --->
<cfif request.cwpage.viewType contains 'Arch'>
	<cfset request.cwpage.discountsArchived = 1>
	<cfset request.cwpage.currentNav = request.cw.thisPage & '?view=arch'>
	<cfset request.cwpage.heading2 = 'Manage archived discounts <span class="smallPrint"><a href="#request.cw.thisPage#">View active</a></span>'>
<cfelse>
	<cfset request.cwpage.discountsArchived = 0>
	<cfset request.cwpage.heading2 = "Manage active discounts">
	<cfset request.cwpage.currentNav = request.cw.thisPage>
</cfif>
<cfset discountsQuery = CWquerySelectStatusDiscounts(request.cwpage.discountsArchived)>
<!--- make query sortable --->
<cfset discountsQuery = CWsortableQuery(discountsQuery)>

<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title <title> --->
<cfset request.cwpage.title = "Manage Discounts">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Manage Discounts">
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
						<!--- PRODUCTS TABLE --->
						<!--- if no records found, show message --->
						<cfif NOT discountsQuery.recordCount>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p><strong>No discounts found.</strong> <cfif request.cwpage.viewType is 'Active'><a href="discount-details.cfm">Add a new discount</a><cfelse><a href="discounts.cfm">View active discounts</a></cfif></p>
						<cfelse>
							<!--- if we have some records to show --->
							<table class="CWsort CWstripe" summary="<cfoutput>#request.cwpage.baseUrl#</cfoutput>">
								<thead>
								<tr class="sortRow">
									<th width="20">Edit</th>
									<th class="discount_name">Discount Name</th>
									<th class="discount_merchant_id">Reference ID</th>
									<th class="discount_promotional_code">Promo Code</th>
									<th class="discount_type">Applies To</th>
									<th class="discount_association_method">Association</th>
									<th class="discount_start_date">Start Date</th>
									<th class="discount_end_date">End Date</th>
									<!--- archive --->
									<th class="noSort" width="50"><cfif not request.cwpage.viewType is 'Archived'>Archive<cfelse>Activate</cfif></th>
								</tr>
								</thead>
								<tbody>
								<!--- OUTPUT THE DISCOUNTS --->
								<cfoutput query="discountsQuery">
								<tr>
									<!--- edit link --->
									<td style="text-align:center;"><a href="discount-details.cfm?discount_id=#discountsQuery.discount_id#" title="Edit Discount Details: #CWstringFormat(discountsQuery.discount_name)#" class="columnLink"><img src="img/cw-edit.gif" alt="Edit #discountsQuery.discount_name#" width="15" height="15" border="0"></a></td>
									<!--- discount name (linked) --->
									<td>
										<strong><a class="discountLink" href="discount-details.cfm?discount_id=#discountsQuery.discount_id#" title="Edit Discount Details: #CWstringFormat(discountsQuery.discount_name)#">#discountsQuery.discount_name#</a></strong>
									</td>
									<!--- reference id --->
									<td>#discountsQuery.discount_merchant_id#</td>
									<!--- promo code --->
									<td>#discountsQuery.discount_promotional_code#</td>
									<!--- applies to --->
									<td>#discountsQuery.discount_type_description#</td>
									<!--- association --->
									<td>#discountsQuery.discount_association_method#<cfif discountsQuery.discount_global is 1> (all items)</cfif></td>
									<!--- start date --->
									<td>#lsDateFormat(discountsQuery.discount_start_date,application.cw.globalDateMask)#</td>
									<!--- end date --->
									<td<cfif discountsQuery.discount_end_date lt cwtime()> class="warning"</cfif>>#lsDateFormat(discountsQuery.discount_end_date,application.cw.globalDateMask)#</td>
									<!--- ARCHIVE / ACTIVATE --->
									<!--- keep same page when archiving --->
									<!--- get the vars to keep by omitting the ones we don't want repeated --->
									<cfset varsToPass = CWremoveUrlVars("reactivateid,archiveid,userconfirm,useralert")>
									<!--- set up the base url --->
									<cfset passQS = CWserializeUrl(varsToPass)>
									<!--- archive / activate button --->
									<td style="text-align:center;">
										<a href="#cgi.script_name#?<cfif not request.cwpage.viewType is 'Archived'>archiveid<cfelse>reactivateid</cfif>=#discountsQuery.discount_id#&#passQs#" class="columnLink" title="<cfif not request.cwpage.viewType is 'Archived'>Archive<cfelse>Reactivate</cfif> Discount: #CWstringFormat(discountsQuery.discount_name)#"><img src="img/<cfif not request.cwpage.viewType is 'Archived'>cw-archive<cfelse>cw-archive-restore</cfif>.gif" alt="Archive" border="0"></a>
									</td>
								</tr>
								</cfoutput>
								</tbody>
							</table>
						</cfif>
						<!--- /END PRODUCTS TABLE --->
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