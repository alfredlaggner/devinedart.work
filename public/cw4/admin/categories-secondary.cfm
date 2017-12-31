<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: categories-secondary.cfm
File Date: 2012-08-25
Description: Manage second-level categories in Cartweaver
==========================================================
--->
<!--- GLOBAL INCLUDES --->
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- include init functions --->
<cfif not isDefined('variables.CWinitProductData')>
	<cfinclude template="#request.cwpage.cwapppath#func/cw-func-init.cfm">
</cfif>
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("manager,merchant,developer")>
<!--- PAGE PARAMS --->
<!--- default values for sort / active or archived--->
<cfparam name="url.sortby" type="string" default="secondary_sort">
<cfparam name="url.sortdir" type="string" default="asc">
<cfparam name="url.view" type="string" default="active">
<!--- default form values --->
<cfparam name="form.secondary_name" default="">
<cfparam name="form.secondary_description" default="">
<cfparam name="form.secondary_sort" default="0">
<cfparam name="form.secondary_nav" default="1">
<!--- default value for order type label--->
<cfparam name="request.cwpage.orderType" default="All">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,view,userconfirm,useralert,clickadd")>
<!--- create the base url for sorting out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- PARAMS FOR CATEGORY LABELS --->
<cfparam name="application.cw.adminLabelSecondary" default="category">
<cfparam name="application.cw.adminLabelSecondaries" default="categories">
<cfset request.cwpage.catText = application.cw.adminLabelSecondary>
<cfset request.cwpage.catsText = application.cw.adminLabelSecondaries>
<!--- ACTIVE VS ARCHIVED --->
<cfif url.view contains 'arch'>
	<cfset request.cwpage.viewType = 'Archived'>
	<cfset request.cwpage.subHead = 'Archived #lcase(request.cwpage.catsText)# are not shown in the store'>
<cfelse>
	<cfset request.cwpage.viewType = 'Active'>
	<cfset request.cwpage.subHead = 'Manage active #lcase(request.cwpage.catsText)# or add a new #lcase(request.cwpage.catText)#'>
</cfif>
<!--- QUERIES: get categories --->
<cfif request.cwpage.viewType contains 'Arch'>
	<cfset request.cwpage.catsArchived = 1>
<cfelse>
	<cfset request.cwpage.catsArchived = 0>
</cfif>
<cfset catsQuery = CWquerySelectStatusSecondaryCategories(request.cwpage.catsArchived)>
<!--- /////// --->
<!--- ADD NEW CATEGORY --->
<!--- /////// --->
<cfif isDefined('form.addCat') and request.cwpage.catsArchived eq 0>
	<!--- QUERY: insert new category (name, order, archived, description)--->
	<!--- this query returns the category id, or an error like '0-fieldname' --->
	<cfset newCatID = CWqueryInsertSecondaryCategory(
	trim(form.secondary_name),
	form.secondary_sort,
	0,
	form.secondary_description,
	form.secondary_nav
	)>
	<!--- refresh category data --->
	<cfset temp = CWinitCategoryData(2)>
	<!--- if no error returned from insert query --->
	<cfif not left(newCatID,2) eq '0-'>
		<!--- update complete: return to page showing message --->
		<cfset CWpageMessage("confirm","#request.cwpage.catText# '#form.secondary_name#' Added")>
		<cflocation url="#request.cwpage.baseUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&sortby=#url.sortby#&sortdir=#url.sortdir#&clickadd=1" addtoken="no">
		<!--- if we have an insert error, show message, do not insert --->
	<cfelse>
		<cfset dupField = listLast(newCatID,'-')>
		<cfset CWpageMessage("alert","Error: #dupField# already exists")>
		<cfset url.clickadd = 1>
	</cfif>
	<!--- /END duplicate/error check --->
</cfif>
<!--- /////// --->
<!--- /END ADD NEW CATEGORY --->
<!--- /////// --->
<!--- /////// --->
<!--- UPDATE / DELETE CATEGORIES --->
<!--- /////// --->
<cfif isDefined('form.updateCats')>
	<cfparam name="form.deleteCategory" default="">
	<cfset loopCt = 1>
	<cfset updateCt = 0>
	<cfset deleteCt = 0>
	<cfset archiveCt = 0>
	<cfset activeCt = 0>
	<cfloop list="#form.catIDlist#" index="ID">
		<!--- DELETE CATS --->
		<!--- if the category ID is marked for deletion --->
		<cfif listFind(form.deleteCategory,evaluate('form.secondary_id'&loopCt))>
			<!--- QUERY: delete category (category id) --->
			<cfset deleteCat = CWqueryDeleteSecondaryCategory(id)>
			<cfset deleteCt = deleteCt + 1>
			<!--- if not deleting, update --->
		<cfelse>
			<!--- UPDATE CATS --->
			<!--- param for checkbox values --->
			<cfparam name="form.secondary_archive#loopct#" default="#request.cwpage.catsArchived#">
			<cfparam name="form.secondary_nav#loopct#" default="0">
			<!--- QUERY: update category record (id, name, sort, archive, description) --->
			<cfset updateCatID = CWqueryUpdateSecondaryCategory(
			#form["secondary_id#loopct#"]#,
			'#form["secondary_name#loopct#"]#',
			#form["secondary_sort#loopct#"]#,
			#form["secondary_archive#loopct#"]#,
			'#form["secondary_description#loopct#"]#',
			#form["secondary_nav#loopct#"]#
			)>
			<!--- query checks for duplicate fields --->
			<cfif left(updateCatID,2) eq '0-'>
				<cfset dupField = listLast(updateCatID,'-')>
				<cfset errorName = #form["secondary_name#loopct#"]#>
				<cfset CWpageMessage("alert","Error: Name '#errorName#' already exists")>
				<!--- update complete: continue processing --->
			<cfelse>
				<cfif #form["secondary_archive#loopct#"]# is 1 and request.cwpage.catsArchived is 0>
					<cfset archiveCt = archiveCt + 1>
				<cfelseif #form["secondary_archive#loopct#"]# is 0 and request.cwpage.catsArchived is 1>
					<cfset activeCt = activeCt + 1>
				<cfelse>
					<cfset updateCt = updateCt + 1>
				</cfif>
				<!--- /END if deleting or updating --->
			</cfif>
			<!--- /END duplicate check --->
		</cfif>
		<cfset loopCt = loopCt + 1>
	</cfloop>
	<!--- refresh category data --->
	<cfset temp = CWinitCategoryData(2)>
	<!--- get the vars to keep by omitting the ones we don't want repeated --->
	<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert")>
	<!--- set up the base url --->
	<cfset request.cwpage.relocateUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
	<!--- return to page as submitted, clearing form scope --->
	<cfset CWpageMessage("confirm","Changes Saved")>
	<cfsavecontent variable="useralertText">
	<cfif archiveCt gt 0>
		<cfoutput>#archiveCt# <cfif archiveCt is 1>#request.cwpage.catText#<cfelse>#request.cwpage.catsText#</cfif> Archived</cfoutput>
	<cfelseif activeCt gt 0>
		<cfoutput>#activeCt# <cfif activeCt is 1>#request.cwpage.catText#<cfelse>#request.cwpage.catsText#</cfif> Activated</cfoutput>
	</cfif>
	<cfif deleteCt gt 0><cfif archiveCt gt 0 OR activeCt gt 0><br></cfif><cfoutput>#deleteCt# <cfif deleteCt is 1>#request.cwpage.catText#<cfelse>#request.cwpage.catsText#</cfif> Deleted</cfoutput></cfif>
	</cfsavecontent>
	<cfset CWpageMessage("alert",useralertText)>
	<cflocation url="#request.cwpage.relocateUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END UPDATE / DELETE CATEGORIES --->
<!--- /////// --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "#request.cwpage.catsText#">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "#request.cwpage.catsText# Management: #request.cwpage.viewType#">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 =  request.cwpage.subhead>
<!--- current menu marker --->
<cfset request.cwpage.currentNav = request.cw.thisPage>
<cfif isDefined('url.clickadd')>
	<cfset request.cwpage.currentNav = request.cwpage.currentNav & '?clickadd=1'>
</cfif>
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
		<!--- text editor javascript --->
		<cfif application.cw.adminEditorEnabled>
			<cfinclude template="cwadminapp/inc/cw-inc-admin-script-editor.cfm">
		</cfif>
		<!--- PAGE JAVASCRIPT --->
		<script type="text/javascript">
			function confirmDelete(boxID,prodCt){
			// if this cat has products
			if (prodCt > 0){
				if (prodCt > 1){var prodWord = 'products'}else{var prodWord = 'product'};
				var confirmBox = '#'+ boxID;
					// if the box is checked
					if( jQuery(confirmBox).is(':checked') ){
					clickConfirm = confirm("This <cfoutput>#cwStringFormat(lcase(request.cwpage.catText))#</cfoutput> will be unassigned for " + prodCt + " " + prodWord + ".\nContinue?");
					// if confirm is returned false
					if(!clickConfirm){
						jQuery(confirmBox).prop('checked','');
					};
				};
				// end if checked
			};
			// end if prodct
		};
		// end function
		</script>
		<script type="text/javascript">
		jQuery(document).ready(function(){
		// description edit
		jQuery('span.descripEdit').hide();
		// show-editor link
		jQuery('a.descripEditLink, span.descripText').click(function(){
			jQuery(this).hide().siblings('.descripText, .descripEditLink').hide();
			jQuery(this).siblings('span.descripEdit').show();
			return false;
		});
		// add new show-hide
		jQuery('form#catAddForm').hide();
		jQuery('a#showCatFormLink').click(function(){
			jQuery(this).hide();
			jQuery('form#catAddForm').show();
			jQuery('#secondary_nameAdd').focus();
			return false;
		});
		// auto-click the link if adding
		<cfif isDefined('url.clickadd')>
		jQuery('a#showCatFormLink').click();
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
						<!--- FORM --->
						<!--- LINKS FOR VIEW TYPE --->
						<div class="CWadminControlWrap">
							<strong>
							<cfif url.view eq 'arch'>
								<a href="<cfoutput>#request.cw.thisPage#</cfoutput>">View Active</a>
							<cfelse>
								<a href="<cfoutput>#request.cw.thisPage#</cfoutput>?view=arch">View Archived</a>
								<!--- link for add-new form --->
								<cfif request.cwpage.catsArchived is 0>
									&nbsp;&nbsp;<a class="CWbuttonLink" id="showCatFormLink" href="#">Add New <cfoutput>#request.cwpage.catText#</cfoutput></a>
								</cfif>
							</cfif>
							</strong>
						</div>
						<!--- /END LINKS FOR VIEW TYPE --->
						<!--- /////// --->
						<!--- ADD NEW CATEGORY--->
						<!--- /////// --->
						<cfif request.cwpage.catsArchived is 0>
							<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" class="CWvalidate CWobserve" name="catAddForm" id="catAddForm" method="post">
								<p>&nbsp;</p>
								<h3>Add New <cfoutput>#request.cwpage.catText#</cfoutput></h3>
								<table class="CWinfoTable wider">
									<thead>
									<tr>
										<th class="secondary_name"><cfoutput>#request.cwpage.catText#</cfoutput> Name</th>
										<th width="485" class="secondary_description">Description</th>
										<th width="55" class="secondary_sort">Order</th>
										<th width="55" class="secondary_nav">Nav</th>
									</tr>
									</thead>
									<cfoutput>
									<tbody>
									<tr>
										<!--- name --->
										<td>
											<input name="secondary_name" id="secondary_nameAdd" type="text" size="17"  class="required" value="#form.secondary_name#" title="#request.cwpage.catText# Name is required">
											<input name="AddCat" type="submit" class="CWformButton" id="AddCat" value="Save New #request.cwpage.catText#">
										</td>
										<!--- description --->
										<td class="noLink noHover">
											<!--- show text --->
											<textarea name="secondary_description" class="textEdit" cols="45" rows="3">#form.secondary_description#</textarea>
										</td>
										<!--- order --->
										<td><input name="secondary_sort" type="text" size="4" maxlength="7" class="required sort" title="Sort Order is required" value="#form.secondary_sort#" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);"></td>
										<!--- nav --->
										<td style="text-align:center;"><input name="secondary_nav" type="checkbox" title="Show category in navigation menus and search forms" value="1"<cfif form.secondary_nav> checked="checked"</cfif>></td>
									</tr>
									</tbody>
									</cfoutput>
								</table>
							</form>
							<p>&nbsp;</p>
						</cfif>
						<!--- /////// --->
						<!--- /END ADD NEW CATEGORY--->
						<!--- /////// --->
						<!--- /////// --->
						<!--- EDIT CATEGORIES --->
						<!--- /////// --->
						<form action="<cfoutput>#request.cwpage.baseUrl#&view=#url.view#</cfoutput>" name="catForm" id="catForm" method="post" class="CWobserve">
							<h3>Manage <cfoutput>#request.cwpage.catText#</cfoutput> Details</h3>
							<!--- save changes / submit button --->
							<cfif catsQuery.recordCount>
								<div class="CWadminControlWrap">
									<input name="UpdateCats" type="submit" class="CWformButton" id="UpdateCats" value="Save Changes">
									<div style="clear:right;"></div>
								</div>
							</cfif>
							<!--- /END submit button --->
							<!--- if no records found, show message --->
							<cfif NOT catsQuery.recordCount>
								<cfoutput>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p><strong>No #lcase(request.cwpage.viewType)# #lcase(request.cwpage.catsText)# available.</strong> <br><br></p></cfoutput>
							<cfelse>
								<!--- SHOW CATEGORIES --->
								<cfset catsQuery = CWsortableQuery(catsQuery)>
								<table class="CWsort CWstripe" summary="<cfoutput>
									#request.cwpage.baseUrl#</cfoutput>">
									<thead>
									<tr class="sortRow">
										<th class="secondary_name"><cfoutput>#request.cwpage.catText#</cfoutput> Name</th>
										<th width="24" class="secondary_id">ID</th>
										<th width="485" class="secondary_description">Description</th>
										<th width="55" class="secondary_sort">Order</th>
										<th width="55" class="secondary_nav">Nav</th>
										<th width="65" class="catProdCount">Products</th>
										<!--- view category link --->
										<cfif isDefined('application.cw.adminProductLinksEnabled') and application.cw.adminProductLinksEnabled>
											<th class="noSort" width="50">View</th>
										</cfif>
										<th width="55">
											<cfif request.cwpage.viewType contains 'arch'>Activate<cfelse>Archive</cfif>
										</th>
										<th width="55">Delete</th>
									</tr>
									</thead>
									<tbody>
									<!--- OUTPUT THE CATEGORIES --->
									<cfoutput query="catsQuery">
									<!--- output the row --->
									<tr>
										<!--- Category Name --->
										<td><input name="secondary_name#currentRow#" type="text" size="17"  class="required" value="#catsQuery.secondary_name#" title="#request.cwpage.catText# Name is required" onblur="checkValue(this)"> </td>
										<!--- Category ID --->
										<td>
											#catsQuery.secondary_id#
											<input name="secondary_id#currentRow#" type="hidden" value="#catsQuery.secondary_id#">
											<input name="catIDlist" type="hidden" value="#catsQuery.secondary_id#">
										</td>
										<!--- Description --->
										<td>
											<!--- show text editor --->
											<cfif application.cw.adminEditorCategoryDescrip>
												<a class="descripEditLink" href="##" title="Edit"><img src="img/cw-edit.gif" alt="Edit"></a>
												<span class="descripText">#catsQuery.secondary_description#</span>
												<span class="descripEdit">
													<textarea name="secondary_description#currentRow#" class="textEdit" cols="45" rows="3">#catsQuery.secondary_description#</textarea>
												</span>
												<!--- show text input --->
											<cfelse>
												<input type="text" name="secondary_description#currentRow#" size="30" value="#catsQuery.secondary_description#">
											</cfif>
										</td>
										<!--- Sort Order --->
										<td><input name="secondary_sort#currentRow#" type="text" size="4" maxlength="7" class="required" title="Sort Order is required" value="#catsQuery.secondary_sort#" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);"></td>
										<!--- nav --->
										<td style="text-align:center"><input type="checkbox" name="secondary_nav#currentRow#" class="formCheckbox" value="1"<cfif catsQuery.secondary_nav is 1> checked="checked"</cfif>></td>
										<!--- Products --->
										<td style="text-align:center;">#catsQuery.catprodcount#<cfif catsQuery.catProdCount gt 0><br><br><a href="products.cfm?searchSC=#catsQuery.secondary_id#&search=1" title="Manage products in this category"><img alt="Manage products in this category" src="img/cw-product-edit.png"></a></cfif></td>
										<!--- view category link --->
										<cfif isDefined('application.cw.adminProductLinksEnabled') and application.cw.adminProductLinksEnabled>
											<td style="text-align:center;"><a href="#application.cw.appPageResultsUrl#?secondary=#catsQuery.secondary_id#" class="columnLink" title="View on Web:  #catsQuery.secondary_name#" rel="external"><img src="img/cw-product-view.png" alt="View on Web:  #catsQuery.secondary_name#"></a></td>
										</cfif>
										<!--- Activate/Archive--->
										<td style="text-align:center"><input type="checkbox" name="secondary_archive#CurrentRow#" class="formCheckbox radioGroup" rel="group#currentRow#" value="<cfif catsQuery.secondary_archive is 0>1<cfelse>0</cfif>"> </td>
										<!--- Delete --->
										<td style="text-align:center"><input type="checkbox" name="deleteCategory" id="confirmBox#secondary_id#" value="#secondary_id#" class="formCheckbox radioGroup" rel="group#currentRow#" onclick="confirmDelete('confirmBox#secondary_id#',#catsQuery.catProdCount#)"></td>
									</tr>
									</cfoutput>
								</table>
								<!--- /end categories table --->
								<!--- save changes / submit button --->
								<cfif catsQuery.recordCount>
									<div class="CWadminControlWrap">
										<input name="UpdateCats" type="submit" class="CWformButton" id="UpdateCats2" value="Save Changes">
										<div style="clear:right;"></div>
									</div>
								</cfif>
								<!--- /END submit button --->
							</cfif>
							<!--- /end if records found --->
						</form>
						<!--- /////// --->
						<!--- /END EDIT CATEGORIES --->
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