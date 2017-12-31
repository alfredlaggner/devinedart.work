<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: products.cfm
File Date: 2012-08-25
Description: Displays product management table
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
<cfparam name="application.cw.adminProductPaging" default="1">
<cfparam name="application.cw.adminRecordsPerPage" default="30">
<!--- show non-archived products by default (url.view = 'arch' or 'active') --->
<!--- default values for seach/sort--->
<cfparam name="url.pagenumresults" type="numeric" default="1">
<cfparam name="url.searchby" type="string" default="1">
<cfparam name="url.search" type="string" default="">
<cfparam name="url.matchtype" type="string" default="anyMatch">
<cfparam name="url.find" type="string" default="">
<cfparam name="url.maxrows" type="numeric" default="#application.cw.adminRecordsPerPage#">
<cfparam name="url.sortby" type="string" default="product_name">
<cfparam name="url.sortdir" type="string" default="asc">
<cfparam name="url.view" type="string" default="active">
<!--- search in cats, subcats --->
<cfparam name="url.searchc" type="any" default="0">
<cfparam name="url.searchsc" type="any" default="0">
<!--- default values for display --->
<cfparam name="ImagePath" default="">
<cfparam name="ImageSRC" default="">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,pagenumresults,reactivateid,archiveid,userconfirm,useralert")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- ARCHIVE VS. ACTIVE --->
<cfif url.view contains 'arch'>
	<cfset request.cwpage.viewProdType = 'Archived'>
	<cfset request.cwpage.subhead = 'Archived products are no longer in circulation and cannot be changed without reactivating'>
<cfelse>
	<cfset request.cwpage.viewProdType = 'Active'>
	<cfset request.cwpage.subhead = 'Use the search options and table links to view and manage active products'>
</cfif>
<!--- /////// --->
<!--- ARCHIVE PRODUCT --->
<!--- /////// --->
<cfif isDefined('url.archiveid') AND url.archiveid gt 0>
	<!--- QUERY: archive the product (product id) --->
	<cfset temp = CWqueryArchiveProduct(url.archiveid)>
	<cfset confirmMsg = 'Product Archived: Use Archived Products menu link to view or reactivate'>
	<cfset CWpageMessage("confirm",confirmMsg)>
</cfif>
<!--- /////// --->
<!--- /END ARCHIVE PRODUCT --->
<!--- /////// --->
<!--- /////// --->
<!--- ACTIVATE PRODUCT --->
<!--- /////// --->
<cfif isDefined('url.reactivateid') AND url.reactivateid gt 0>
	<!--- QUERY: reactivate product (product ID) --->
	<cfset temp = CWqueryReactivateProduct(url.reactivateid)>
	<cfset request.cwpage.userConfirmText = 'Product Reactivated: <a href="product-details.cfm?productid=#url.reactivateid#">View Product Details</a>'>
	<cfset CWpageMessage("confirm",request.cwpage.userConfirmText)>
</cfif>
<!--- /////// --->
<!--- /END ACTIVATE PRODUCT --->
<!--- /////// --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Manage Products">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Product Management: #request.cwpage.viewProdType# Products">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = request.cwpage.subhead>
<!--- current menu marker --->
<cfif url.view contains 'arch'><cfset request.cwpage.currentNav = 'products.cfm?view=arch'></cfif>
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
					<!--- user alerts --->
					<cfinclude template="cwadminapp/inc/cw-inc-admin-alerts.cfm">
					<!-- Page Content Area -->
					<div id="CWadminContent">
						<!-- //// PAGE CONTENT ////  -->
						<!--- SEARCH --->
						<div id="CWadminProductSearch" class="CWadminControlWrap">
							<!--- include the search form --->
							<cfinclude template="cwadminapp/inc/cw-inc-search-product.cfm">
							<!--- if products found, show the paging links --->
							<cfif productsQuery.recordCount gt 0>
								<cfoutput>#request.cwpage.pagingLinks#</cfoutput>
								<!--- set up the table display output --->
								<cfsilent>
								<cfif NOT application.cw.adminProductPaging>
									<cfset startRow_Results = 1>
									<cfset maxRows_Results = productsQuery.recordCount>
								</cfif>
								<!--- make the query sortable --->
								<cfset productsQuery = CWsortableQuery(productsQuery) >
								</cfsilent>
							</cfif>
						</div>
						<!--- /END SEARCH --->
						<!--- PRODUCTS TABLE --->
						<!--- if no records found, show message --->
						<cfif NOT productsQuery.recordCount>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p><strong>No products found.</strong> <br><br>Try a different search above or click the 'Active Products' link to see all currently active items.</p>
						<cfelse>
							<!--- if we have some records to show --->
							<table class="CWsort CWstripe" summary="<cfoutput>#request.cwpage.baseUrl#</cfoutput>">
								<thead>
								<tr class="sortRow">
									<cfif not request.cwpage.viewProdType is 'Archived'>
										<th width="20">Edit</th>
									</cfif>
									<th class="product_name">Product Name</th>
									<th class="product_merchant_product_id">Product ID</th>
									<!--- cats, subcats --->
									<cfif listActiveCats.recordCount gte 1>
										<th class="noSort"><cfoutput>#listFirst(application.cw.adminLabelCategory,' ')#</cfoutput></th>
									</cfif>
									<cfif listActiveScndCats.recordCount gte 1>
										<th class="noSort"><cfoutput>#listFirst(application.cw.adminLabelSecondary,' ')#</cfoutput></th>
									</cfif>
									<th class="noSort" width="80">Photo</th>
									<!--- add date modified --->
									<th class="product_date_modified">Modified</th>
									<cfif not request.cwpage.viewProdType is 'Archived'>
										<th class="product_on_web" width="60">On&nbsp;Web</th>
										<!--- add 'view on site' link --->
										<cfif isDefined('application.cw.adminProductLinksEnabled') AND application.cw.adminProductLinksEnabled>
											<th class="noSort" width="50">View</th>
										</cfif>
									</cfif>
									<!--- archive --->
									<th class="noSort" width="50"><cfif not request.cwpage.viewProdType is 'Archived'>Archive<cfelse>Activate</cfif></th>
								</tr>
								</thead>
								<tbody>
								<!--- OUTPUT THE PRODUCTS --->
								<cfoutput query="productsQuery" group="product_merchant_product_id" startrow="#StartRow_Results#" maxrows="#MaxRows_Results#">
								<tr>
									<!--- edit link --->
									<cfif not request.cwpage.viewProdType is 'Archived'>
										<td style="text-align:center;"><a href="product-details.cfm?productid=#productsQuery.product_id#" title="Edit Product Details: #CWstringFormat(productsQuery.product_name)#" class="columnLink"><img src="img/cw-edit.gif" alt="Edit #productsQuery.product_name#" width="15" height="15" border="0"></a></td>
									</cfif>
									<!--- name (linked) --->
									<td>
										<strong>
										<cfif not request.cwpage.viewProdType is 'Archived'>
											<a class="productLink" href="product-details.cfm?productid=#productsQuery.product_id#" title="Edit Product Details: #CWstringFormat(productsQuery.product_name)#">#productsQuery.product_name#</a>
										<cfelse>
											#productsQuery.product_name#
										</cfif>
										</strong>
									</td>
									<td>#productsQuery.product_merchant_product_id#</td>
									<!--- cats, subcats (only used if more than one exists in the store )--->
									<cfif listActiveCats.recordCount gte 1>
										<!--- QUERY: get categories --->
										<cfset listProdCats = CWquerySelectRelCategories(productsQuery.product_id)>
										<td>
											<cfset currentRow = 1>
											<cfloop query="listProdCats">#listProdCats.category_name#<cfif listProdCats.recordCount gt 1 and currentRow lt listProdCats.recordCount><br></cfif>
												<cfset currentRow = currentRow + 1>
											</cfloop>
										</td>
									</cfif>
									<cfif listActiveScndCats.recordCount gte 1>
										<!--- QUERY: get subcategories --->
										<cfset listProdSubcats = CWquerySelectRelScndCategories(productsQuery.product_id)>
										<td>
											<cfset currentRow = 1>
											<cfloop query="listProdSubcats">#listProdSubCats.secondary_name#<cfif listProdSubcats.recordCount gt 1 and currentRow lt listProdSubcats.recordCount><br></cfif>
												<cfset currentRow = currentRow + 1>
											</cfloop>
										</td>
									</cfif>
									<!--- PHOTO --->
									<!--- get the first image --->
									<cfset imageFn = listLast(CWgetImage(productsQuery.product_id,1),'/')>
									<cfif len(trim(imageFn))>
										<cfset imageSrc = '#request.cwpage.adminImgPrefix##application.cw.appImagesDir#/admin_preview/' & imageFn>
										<!--- if using default file , show it here --->
									<cfelseif isDefined('application.cw.appImageDefault') and len(trim(application.cw.appImageDefault))>
										<cfset imageSrc = '#request.cwpage.adminImgPrefix##application.cw.appImagesDir#/admin_preview/' & trim(application.cw.appImageDefault)>
									<cfelse>
										<cfset imageSrc = ''>
									</cfif>
									<td style="text-align:center;" class="imageCell">
										<cfif len(trim(imageSrc)) AND fileExists(expandPath(imageSrc))>
											<cfif not request.cwpage.viewProdType is 'Archived'>
												<a href="product-details.cfm?productid=#productsQuery.product_id#&showtab=3" title="View product details">
												<img src="#ImageSRC#" alt="View product details">
												</a>
											<cfelse>
												<img src="#ImageSRC#" title="Activate product to edit">
											</cfif>
										</cfif>
									</td>
									<!--- TIMESTAMP --->
									<td>
										<span class="dateStamp">
											#LSdateFormat(product_date_modified,application.cw.globalDateMask)#
											<br>#timeFormat(product_date_modified,'short')#
										</span>
									</td>
									<!--- if archived, don't show these columns --->
									<cfif not request.cwpage.viewProdType is 'Archived'>
										<!--- ON WEB --->
										<cfset onweb = productsQuery.product_on_web>
										<td style="text-align:center;"><cfif onweb is 0>No<cfelse>Yes</cfif></td>
										<!--- view product link --->
										<cfif isDefined('application.cw.adminProductLinksEnabled') and application.cw.adminProductLinksEnabled>
											<td style="text-align:center;"><a href="#application.cw.appPageDetailsUrl#?product=#productsQuery.product_id#" class="columnLink" title="View on Web: #CWstringFormat(productsQuery.product_name)#" rel="external"><img src="img/cw-product-view.png" alt="View on Web:  #productsQuery.product_name#"></a></td>
										</cfif>
										<!--- /END if archived --->
									</cfif>
									<!--- ARCHIVE / ACTIVATE --->
									<!--- keep same page when archiving --->
									<!--- get the vars to keep by omitting the ones we don't want repeated --->
									<cfset varsToPass = CWremoveUrlVars("reactivateid,archiveid,userconfirm,useralert")>
									<!--- set up the base url --->
									<cfset passQS = CWserializeUrl(varsToPass)>
									<!--- archive / activate button --->
									<td style="text-align:center;">
										<a href="#cgi.script_name#?<cfif not request.cwpage.viewProdType is 'Archived'>archiveid<cfelse>reactivateid</cfif>=#productsQuery.product_id#&#passQs#" class="columnLink" title="<cfif not request.cwpage.viewProdType is 'Archived'>Archive<cfelse>Reactivate</cfif> Product: #CWstringFormat(productsQuery.product_name)#"><img src="img/<cfif not request.cwpage.viewProdType is 'Archived'>cw-archive<cfelse>cw-archive-restore</cfif>.gif" alt="Archive" border="0"></a>
									</td>
								</tr>
								</cfoutput>
								</tbody>
							</table>
							<div class="tableFooter"><cfoutput>#request.cwpage.pagingLinks#</cfoutput></div>
						</cfif>
						<!--- /END PRODUCTS TABLE --->
					</div>
					<!-- /end Page Content -->
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