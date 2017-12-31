<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: tax-group-products.cfm
File Date: 2012-02-01
Description: Manage Products in a tax group
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
<cfparam name="url.tax_group_id" type="integer" default="0">
<cfparam name="request.cwpage.currentRecord" default="#url.tax_group_id#">
<cfparam name="url.sortby" type="string" default="product_name">
<cfparam name="url.sortdir" type="string" default="asc">
<!--- default form values --->
<cfparam name="form.productCount" default="">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("view,userconfirm,useralert,clickadd,sortby,sortdir")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- /////// --->
<!--- UPDATE PRODUCT TAX GROUPS --->
<!--- /////// --->
<!--- look for at least one valid ID field --->
<cfif isDefined('form.tax_group_id1')>
	<cfset loopCt = 1>
	<cfset updateCt = 0>
	<!--- loop record ids, handle each one as needed --->
	<cfloop list="#form.recordIDlist#" index="ID">
		<!--- UPDATE RECORDS --->
		<cfparam name="form.tax_group_id#loopct#" default="0">
		<!--- verify numeric tax group --->
		<cfif NOT isNumeric(#form["tax_group_id#loopct#"]#)>
			<cfset #form["tax_group_id#loopct#"]# = 0>
		</cfif>
		<!--- only update those not already set to this group --->
		<cfif #form["tax_group_id#loopct#"]# neq request.cwpage.currentRecord>
			<!--- QUERY: update record (product ID, tax group ID) --->
			<cfset updateRecord = CWqueryUpdateProductTaxGroup(#form["product_id#loopct#"]#,#form["tax_group_id#loopct#"]#)>
			<cfset updateCt = updateCt + 1>
		</cfif>
		<!--- /end only those not in this group --->
		<cfset loopCt = loopCt + 1>
	</cfloop>
	<!--- get the vars to keep by omitting the ones we don't want repeated --->
	<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert")>
	<!--- set up the base url --->
	<cfset request.cwpage.relocateUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
	<!--- save confirmation text --->
	<cfsavecontent variable="request.cwpage.userConfirmText">
	<cfif updateCt gt 0><cfoutput>#updateCt# Product<cfif updateCt gt 1>s</cfif> Reassigned</cfoutput></cfif>
	</cfsavecontent>
	<cfset CWpageMessage("confirm",request.cwpage.userConfirm)>
	<!--- return to page as submitted, clearing form scope --->
	<cflocation url="#request.cwpage.relocateUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirmText)#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END UPDATE PRODUCT TAX GROUPS --->
<!--- /////// --->
<!--- QUERY: get tax group (active/archived, group ID)--->
<cfset taxGroupQuery = CWquerySelectTaxGroups(0,request.cwpage.currentrecord)>
<cfset request.cwpage.currentGroup = taxGroupQuery.tax_group_id>
<cfset request.cwpage.groupname = taxGroupQuery.tax_group_name>
<!--- QUERY: get products by tax group (group ID)--->
<cfset taxGroupProductsQuery = CWquerySelectTaxGroupProducts(request.cwpage.currentrecord)>
<!--- make query sortable --->
<cfset taxGroupProductsQuery = CWsortableQuery(taxGroupProductsQuery)>
<!--- QUERY: get all active tax groups  --->
<cfset taxGroupsQuery = CWquerySelectTaxGroups(0)>
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Manage #application.cw.taxSystemLabel# Group">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Manage #application.cw.taxSystemLabel# Group: #request.cwpage.groupname#">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 =  "Manage products within this #application.cw.taxSystemLabel# Group">
<!--- current menu marker --->
<cfset request.cwpage.currentNav = "tax-groups.cfm">
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
						<!--- LINKS FOR VIEW OPTIONS --->
						<div class="CWadminControlWrap">
							<strong>
							<p><a href="tax-group-details.cfm?tax_group_id=<cfoutput>#request.cwpage.currentrecord#</cfoutput>">Tax Rates</a></p>
							</strong>
						</div>
						<!--- /END LINKS FOR VIEW OPTIONS --->
						<!--- if a valid record is not found --->
						<cfif not taxGroupQuery.recordCount is 1>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>Invalid <cfoutput>#application.cw.taxSystemLabel#</cfoutput> group id. Please return to the <a href="tax-groups.cfm"><cfoutput>#application.cw.taxSystemLabel#</cfoutput> Group Listing</a> and choose a valid <cfoutput>#application.cw.taxSystemLabel#</cfoutput> group.</p>
							<!--- if a record is found --->
						<cfelse>
							<!--- /////// --->
							<!--- UPDATE TAX RATES --->
							<!--- /////// --->
							<!--- check for existing records --->
							<p>&nbsp;</p>
							<h3>Associated Products</h3>
							<cfif NOT taxGroupProductsQuery.recordCount>
								<p>&nbsp;</p>
								<p>There are currently no products assigned to this <cfoutput>#application.cw.taxSystemLabel#</cfoutput> group</p>
								<!--- if existing records found --->
							<cfelse>
								<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" name="recordForm" id="recordForm" method="post" class="CWobserve">
									<table class="CWsort CWstripe wide" summary="<cfoutput>
										#request.cwpage.baseUrl#</cfoutput>">
										<thead>
										<tr class="sortRow">
											<th class="product_name">Product Name</th>
											<th class="noSort"><cfoutput>#application.cw.taxSystemLabel#</cfoutput> Group</th>
										</tr>
										</thead>
										<tbody>
										<cfoutput query="taxGroupProductsQuery">
										<tr>
											<td><a href="product-details.cfm?productid=#product_id#" class="detailsLink" title="Edit Product Details: #CWstringFormat(taxGroupProductsQuery.product_name)#">#product_name#</a></td>
											<td>
												<select name="tax_group_id#CurrentRow#">
													<option value="0">No #application.cw.taxSystemLabel#</option>
													<cfloop query="taxgroupsQuery">
														<option value="#taxgroupsQuery.tax_group_id#" <cfif taxgroupsQuery.tax_group_id eq request.cwpage.currentrecord>selected="selected"</cfif>>#taxgroupsQuery.tax_group_name#</option>
													</cfloop>
												</select>
												<input type="hidden" name="product_id#CurrentRow#" value="#taxGroupProductsQuery.product_id#" >
												<input name="recordIDlist" type="hidden" value="#taxGroupProductsQuery.product_id#">
											</td>
										</tr>
										</cfoutput>
										</tbody>
									</table>
									<input name="SubmitUpdate" type="submit" class="submitButton" id="UpdateProducts" value="Save Changes">
									<input type="hidden" value="<cfoutput>#taxGroupProductsQuery.RecordCount#</cfoutput>" name="recordCounter">
								</form>
							</cfif>
							<!--- /end check for existing records --->
							<!--- /////// --->
							<!--- /END UPDATE TAX RATES --->
							<!--- /////// --->
						</cfif>
						<!--- /end valid record --->
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