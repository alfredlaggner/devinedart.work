<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: db-handler.cfm
File Date: 2012-02-12
Description: Handles database operations
Note:
Run the cleanup script with caution! It will permanently remove _all_ data from your CW tables.

==========================================================
--->
<!--- time out the page if it takes too long - avoid server overload for massive product deletions --->
<cfsetting requesttimeout="9000">
<!--- GLOBAL INCLUDES --->
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- include init functions --->
<cfif not isDefined('variables.CWinitProductData')>
	<cfinclude template="#request.cwpage.cwapppath#func/cw-func-init.cfm">
</cfif>
<!--- product functions--->
<cfinclude template="cwadminapp/func/cw-func-product.cfm">
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("developer")>
<!--- PAGE PARAMS --->
<cfparam name="url.mode" default="">

<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert,mode")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>

<!--- data delete must be enabled --->
<cfif url.mode is 'testdata' and
	application.cw.appDataDeleteEnabled neq true>
	<cfset CWpageMessage("alert","Data Deletion Disabled")>
	<cflocation url="#request.cwpage.baseUrl#&mode=declined&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
</cfif>

<!--- GET TOTALS --->
<!--- products --->
<cfparam name="application.cw.listProducts" default="#structNew()#">
<cfset request.cwpage.productCt = structCount(application.cw.listProducts)>
<!--- categories --->
<cfparam name="application.cw.listCategories" default="#structNew()#">
<cfset request.cwpage.categoryCt = structCount(application.cw.listCategories)>
<!--- secondary categories --->
<cfparam name="application.cw.listSubcategories" default="#structNew()#">
<cfset request.cwpage.secondaryCt = structCount(application.cw.listSubcategories)>
<!--- customers --->
<cfset customerQuery = CWquerySelectCustomers()>
<cfset request.cwpage.customerCt = customerQuery.recordCount>
<!--- discounts --->
<cfset discountQuery = CWquerySelectDiscounts()>
<cfset request.cwpage.discountCt = discountQuery.recordCount>
<!--- orders --->
<cfset orderQuery = CWquerySelectOrders()>
<cfset request.cwpage.orderCt = orderQuery.recordCount>
<!--- options --->
<cfset optionsQuery = CWquerySelectOptions()>
<cfset request.cwpage.optionCt = optionsQuery.recordCount>
<!--- shipping --->
<cfset shippingQuery = CWquerySelectShippingMethods()>
<cfset request.cwpage.shippingCt = shippingQuery.recordCount>
<!--- taxes --->
<cfset taxGroupsQuery = CWquerySelectTaxGroups()>
<cfset request.cwpage.taxCt = taxGroupsQuery.recordCount>
<!--- list of tables for auto increment reset --->
<cfset resetTables = ''>

<!--- /////// --->
<!--- DELETE TEST DATA --->
<!--- /////// --->
<cfif url.mode is 'testdata'
	AND isDefined('form.testDataDelete') and form.testDataDelete is 'true'>
<!--- defaults for checkboxes --->
<cfparam name="form.emptycart" default="false">
<cfparam name="form.emptycats" default="false">
<cfparam name="form.emptycustomers" default="false">
<cfparam name="form.emptydiscounts" default="false">
<cfparam name="form.emptyoptions" default="false">
<cfparam name="form.emptyorders" default="false">
<cfparam name="form.emptyproducts" default="false">
<cfparam name="form.emptyshipping" default="false">
<cfparam name="form.emptysubcats" default="false">
<cfparam name="form.emptytax" default="false">
<cfparam name="form.resetincrement" default="false">

<!--- DELETE SELECTED ITEMS --->

<!--- cart --->
<cfif form.emptyCart is 'true'>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_cart
	</cfquery>
	<cfif form.resetincrement is true>
		<cfset resetTables = listAppend(resetTables,'cw_cart')>
	</cfif>
</cfif>

<!--- categories --->
<cfif form.emptyCats is 'true'>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_categories_primary
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_discount_categories
		WHERE discount_category_type = 1
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_product_categories_primary
	</cfquery>
	<cfif form.resetincrement is true>
		<cfset resetTables = listAppend(resetTables,'cw_categories_primary')>
		<cfset resetTables = listAppend(resetTables,'cw_product_categories_primary')>
	</cfif>

</cfif>
<!--- secondary categories --->
<cfif form.emptySubCats is 'true'>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_categories_secondary
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_discount_categories
		WHERE discount_category_type = 2
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_product_categories_secondary
	</cfquery>
	<cfif form.resetincrement is true>
		<cfset resetTables = listAppend(resetTables,'cw_categories_secondary')>
		<cfset resetTables = listAppend(resetTables,'cw_product_categories_secondary')>
		<cfif form.emptyCats is 'true'>
			<cfset resetTables = listAppend(resetTables,'cw_discount_categories')>
		</cfif>
	</cfif>
</cfif>

<!--- products --->
<cfif form.emptyProducts is 'true'>
	<!--- function clears out selective related data --->
	<cfloop collection="#application.cw.listProducts#" item="prodid">
	<cfset CWfuncProductDelete(prodid)>
	</cfloop>
	<!--- empty all product tables for complete cleanout --->
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_products
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_skus
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_discount_products
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_discount_skus
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_product_upsell
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_product_options
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_product_images
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_product_categories_primary
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_product_categories_secondary
	</cfquery>
	<cfif form.resetincrement is true>
		<cfset resetTables = listAppend(resetTables,'cw_products')>
		<cfset resetTables = listAppend(resetTables,'cw_skus')>
		<cfset resetTables = listAppend(resetTables,'cw_discount_products')>
		<cfset resetTables = listAppend(resetTables,'cw_discount_skus')>
		<cfset resetTables = listAppend(resetTables,'cw_product_upsell')>
		<cfset resetTables = listAppend(resetTables,'cw_product_options')>
		<cfset resetTables = listAppend(resetTables,'cw_product_images')>
		<cfset resetTables = listAppend(resetTables,'cw_product_categories_primary')>
		<cfset resetTables = listAppend(resetTables,'cw_product_categories_secondary')>
	</cfif>

</cfif>

<!--- options --->
<cfif form.emptyOptions is 'true'>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_options
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_option_types
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_product_options
	</cfquery>
	<cfif form.resetincrement is true>
		<cfset resetTables = listAppend(resetTables,'cw_options')>
		<cfset resetTables = listAppend(resetTables,'cw_option_types')>
		<cfset resetTables = listAppend(resetTables,'cw_product_options')>
	</cfif>
</cfif>

<!--- customers --->
<cfif form.emptyCustomers is 'true'>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_customers
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_customer_stateprov
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_orders
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_order_sku_data
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_order_skus
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_order_payments
	</cfquery>
	<cfif form.resetincrement is true>
		<cfset resetTables = listAppend(resetTables,'cw_customers')>
		<cfset resetTables = listAppend(resetTables,'cw_customer_stateprov')>
		<cfset resetTables = listAppend(resetTables,'cw_orders')>
		<cfset resetTables = listAppend(resetTables,'cw_order_sku_data')>
		<cfset resetTables = listAppend(resetTables,'cw_order_skus')>
		<cfset resetTables = listAppend(resetTables,'cw_order_payments')>
	</cfif>
</cfif>

<!--- discounts --->
<cfif form.emptyDiscounts is 'true'>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_discounts
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_discount_products
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_discount_skus
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_discount_categories
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_discount_usage
	</cfquery>
	<cfif form.resetincrement is true>
		<cfset resetTables = listAppend(resetTables,'cw_discounts')>
		<cfset resetTables = listAppend(resetTables,'cw_discount_products')>
		<cfset resetTables = listAppend(resetTables,'cw_discount_skus')>
		<cfset resetTables = listAppend(resetTables,'cw_discount_categories')>
		<cfset resetTables = listAppend(resetTables,'cw_discount_usage')>
	</cfif>
</cfif>

<!--- orders --->
<cfif form.emptyOrders is 'true'>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_orders
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_order_sku_data
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_order_skus
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_order_payments
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_discount_usage
	</cfquery>
</cfif>
	<cfif form.resetincrement is true>
		<cfset resetTables = listAppend(resetTables,'cw_orders')>
		<cfset resetTables = listAppend(resetTables,'cw_order_sku_data')>
		<cfset resetTables = listAppend(resetTables,'cw_order_skus')>
		<cfset resetTables = listAppend(resetTables,'cw_order_payments')>
	</cfif>

<!--- shipping --->
<cfif form.emptyShipping is 'true'>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_ship_methods
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_ship_ranges
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_ship_method_countries
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		UPDATE cw_stateprov
		SET stateprov_ship_ext = 0
	</cfquery>
	<cfif form.resetincrement is true>
		<cfset resetTables = listAppend(resetTables,'cw_ship_methods')>
		<cfset resetTables = listAppend(resetTables,'cw_ship_ranges')>
		<cfset resetTables = listAppend(resetTables,'cw_ship_method_countries')>
		<cfset resetTables = listAppend(resetTables,'cw_stateprov')>
	</cfif>
</cfif>

<!--- taxes --->
<cfif form.emptyTax is 'true'>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_tax_groups
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_tax_rates
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		DELETE from cw_tax_regions
	</cfquery>
	<cfquery name="rsClear" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		UPDATE cw_stateprov
		SET stateprov_tax = 0
	</cfquery>
	<cfif form.resetincrement is true>
		<cfset resetTables = listAppend(resetTables,'cw_tax_groups')>
		<cfset resetTables = listAppend(resetTables,'cw_tax_rates')>
		<cfset resetTables = listAppend(resetTables,'cw_tax_regions')>
	</cfif>
</cfif>

<!--- reset auto increment on listed tables --->
<cfif len(trim(resetTables))>
	<cfloop list="#resetTables#" index="t">
		<cftry>
			<cfquery name="rsReset" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
				<cfif application.cw.appDbType is 'mssqlserver'>
					DBCC CHECKIDENT('#t#', RESEED, 0);
				<cfelse>
					ALTER TABLE #t# auto_increment = 1;
				</cfif>
			</cfquery>
		<cfcatch></cfcatch>
		</cftry>
	</cfloop>
</cfif>
<!--- return to page showing confirmation, resetting application vars--->
	<cfset CWpageMessage("confirm","Data Deletion Complete")>
	<cflocation url="#request.cwpage.baseUrl#&mode=testdata&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&resetapplication=#application.cw.storePassword#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END DELETE TEST DATA --->
<!--- /////// --->

<!--- SUBHEADING --->
<cfsavecontent variable="request.cwpage.subhead">
<cfoutput>
Existing Products: #request.cwpage.productCt#&nbsp;&nbsp;
#application.cw.adminLabelCategories#: #request.cwpage.categoryCt#&nbsp;&nbsp;
#application.cw.adminLabelSecondaries#: #request.cwpage.secondaryCt#&nbsp;&nbsp;
</cfoutput>
</cfsavecontent>
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Manage Data">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Database Management">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = request.cwpage.subhead>
<!--- current menu marker --->
<cfset request.cwpage.currentNav = 'db-handler.cfm'>
<cfif len(trim(url.mode))><cfset request.cwpage.currentNav = 'db-handler.cfm?mode=#url.mode#'></cfif>
<!--- load form scripts --->
<cfset request.cwpage.isFormPage = 1>
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
		<!--- fancybox --->
		<link href="js/fancybox/jquery.fancybox.css" rel="stylesheet" type="text/css">
		<script type="text/javascript" src="js/fancybox/jquery.fancybox.pack.js"></script>
		<!--- PAGE JAVASCRIPT --->
		<script type="text/javascript">
			// this takes the ID of a checkbox, the number to show in the alert
			function confirmDelete(boxID,itemCt){
			// if this cat has itemucts
				if (itemCt > 0){
					if (itemCt > 1){var itemWord = 'records'}else{var itemWord = 'record'};
				var confirmBox = '#'+ boxID;
					// if the box is checked and itemToggle is true
					if( jQuery(confirmBox).is(':checked') ){
					clickConfirm = confirm("Warning: \n" + itemCt + ' ' + itemWord + " will be deleted, along with all related data.\nContinue?");
						// if confirm is returned false
						if(!clickConfirm){
							jQuery(confirmBox).prop('checked','');
						};
					};
					// end if checked
				};
				// end if prodct
			};
		</script>
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
						<p>&nbsp;</p>
						<!--- PAGE MODE --->
						<cfswitch expression="#url.mode#">

						<!--- DELETE TEST DATA --->
						<cfcase value="testdata">
						<h3>Select Items for Deletion</h3>
						<p class="subText">CAUTION! Deletions are permanent. It is <em>highly recommended</em> to create a backup of your database before proceeding.</p>
						<!--- DATA CLEANUP FORM --->
							<!--- form submits to same page --->
							<cfoutput>
							<form action="<cfoutput>#request.cwpage.baseUrl#&mode=testdata</cfoutput>" name="cleanupForm" id="cleanupForm" method="post">
								<table class="CWstripe CWformTable wide">
								<tbody>
								<!--- products --->
								<tr>
									<th class="label">
										<p><strong>Delete Products</strong></p>
									</th>
									<td class="noLink noHover">
											<input type="checkbox" name="emptyProducts" id="emptyProducts"
											class="formCheckbox delBox" value="true"
											<cfif request.cwpage.productCt gt 0>onclick="confirmDelete('emptyProducts',#request.cwpage.productCt#)"</cfif>>
									</td>
								</tr>
								<tr>
									<td colspan="2">
										<p>Removes all data stored in cw_products, along with all relative product data.</p>
									</td>
								</tr>

								<!--- options --->
								<tr>
									<th class="label">
										<p><strong>Delete Options</strong></p>
									</th>
									<td class="noLink noHover">
											<input type="checkbox" name="emptyOptions" id="emptyOptions"
											class="formCheckbox delBox" value="true"
											<cfif request.cwpage.optionCt gt 0>onclick="confirmDelete('emptyOptions',#request.cwpage.optionCt#)"</cfif>>
									</td>
								</tr>
								<tr>
									<td colspan="2">
										<p>Removes all product options, option groups, and related product option data.</p>
									</td>
								</tr>

								<!--- cart --->
								<tr>
									<th class="label">
										<p><strong>Delete Cart Data</strong></p>
									</th>
									<td class="noLink noHover">
											<input type="checkbox" name="emptyCart" id="emptyCart"
											class="formCheckbox delBox" value="true"
											>
									</td>
								</tr>
								<tr>
									<td colspan="2">
										<p>Removes all data stored in cw_cart, from open or unfinished orders.</p>
									</td>
								</tr>

								<!--- categories --->
								<tr>
									<th class="label">
										<p><strong>Delete Categories</strong></p>
									</th>
									<td class="noLink noHover">
											<input type="checkbox" name="emptyCats" id="emptyCats"
											class="formCheckbox delBox" value="true"
											<cfif request.cwpage.categoryCt gt 0>onclick="confirmDelete('emptyCats',#request.cwpage.categoryCt#)"</cfif>>
									</td>
								</tr>
								<tr>
									<td colspan="2">
										<p>Removes all data stored in cw_categories_primary, along with relative product/category data.</p>
									</td>
								</tr>

								<!--- secondary categories --->
								<tr>
									<th class="label">
										<p><strong>Delete #application.cw.adminLabelSecondaries#</strong></p>
									</th>
									<td class="noLink noHover">
											<input type="checkbox" name="emptySubcats" id="emptySubcats"
											class="formCheckbox delBox" value="true"
											<cfif request.cwpage.secondaryCt gt 0>onclick="confirmDelete('emptySubcats',#request.cwpage.secondaryCt#)"</cfif>>
									</td>
								</tr>
								<tr>
									<td colspan="2">
										<p>Removes all data stored in cw_categories_secondary, along with relative product/category data.</p>
									</td>
								</tr>

								<!--- customers --->
								<tr>
									<th class="label">
										<p><strong>Delete Customers</strong></p>
									</th>
									<td class="noLink noHover">
											<input type="checkbox" name="emptyCustomers" id="emptyCustomers"
											class="formCheckbox delBox" value="true"
											<cfif request.cwpage.customerCt gt 0>onclick="confirmDelete('emptyCustomers',#request.cwpage.customerCt#)"</cfif>>
									</td>
								</tr>
								<tr>
									<td colspan="2">
										<p>Removes all data stored in cw_customers, and all stored orders, along with relative customer data.</p>
									</td>
								</tr>

								<!--- discounts --->
								<tr>
									<th class="label">
										<p><strong>Delete Discounts</strong></p>
									</th>
									<td class="noLink noHover">
											<input type="checkbox" name="emptyDiscounts" id="emptyDiscounts"
											class="formCheckbox delBox" value="true"
											<cfif request.cwpage.discountCt gt 0>onclick="confirmDelete('emptyDiscounts',#request.cwpage.discountCt#)"</cfif>>
									</td>
								</tr>
								<tr>
									<td colspan="2">
										<p>Removes all data stored in cw_discounts, along with relative discount data.</p>
									</td>
								</tr>

								<!--- orders --->
								<tr>
									<th class="label">
										<p><strong>Delete Orders</strong></p>
									</th>
									<td class="noLink noHover">
											<input type="checkbox" name="emptyOrders" id="emptyOrders"
											class="formCheckbox delBox" value="true"
											<cfif request.cwpage.orderCt gt 0>onclick="confirmDelete('emptyOrders',#request.cwpage.orderCt#)"</cfif>>
									</td>
								</tr>
								<tr>
									<td colspan="2">
										<p>Removes all data stored in cw_orders, along with all relative order data.</p>
									</td>
								</tr>

								<!--- shipping --->
								<tr>
									<th class="label">
										<p><strong>Delete Shipping Data</strong></p>
									</th>
									<td class="noLink noHover">
											<input type="checkbox" name="emptyShipping" id="emptyShipping"
											class="formCheckbox delBox" value="true"
											<cfif request.cwpage.shippingCt gt 0>onclick="confirmDelete('emptyShipping',#request.cwpage.shippingCt#)"</cfif>>
									</td>
								</tr>
								<tr>
									<td colspan="2">
										<p>Removes all shipping ranges, methods and regions.</p>
									</td>
								</tr>

								<!--- taxes --->
								<tr>
									<th class="label">
										<p><strong>Delete #application.cw.taxSystemLabel# Data</strong></p>
									</th>
									<td class="noLink noHover">
											<input type="checkbox" name="emptyTax" id="emptyTax"
											class="formCheckbox delBox" value="true"
											<cfif request.cwpage.taxCt gt 0>onclick="confirmDelete('emptyTax',#request.cwpage.taxCt#"</cfif>>
									</td>
								</tr>
								<tr>
									<td colspan="2">
										<p>Removes all #application.cw.taxSystemLabel# groups, rates and regions.</p>
									</td>
								</tr>
								<!--- reset auto increment --->
								<tr>
									<th class="label">
										<p><strong>Reset Auto Increment Value</strong></p>
									</th>
									<td class="noLink noHover">
											<input type="checkbox" name="resetIncrement" id="resetIncrement"
											class="formCheckbox delBox" value="true">
									</td>
								</tr>
								<tr>
									<td colspan="2">
										<p>Resets all emptied tables to ID 1 during the deletion process</p>
									</td>
								</tr>
								</tbody>
								</table>
								<p>&nbsp;</p>
								<p><strong>WARNING: Deletions cannot be undone. All selected data will be permanently erased!</strong></p>
								<p>&nbsp;</p>
								<!--- submit button --->
								<input name="submitDelete" type="submit" class="submitButton" id="submitDelete" value="Start Cleanup">
								<!--- hidden field, required for operation --->
								<input type="hidden" name="testDataDelete" value="true">
							</form>
							</cfoutput>
						</cfcase>
						<!--- /END TEST DATA MODE --->

						<!--- DEFAULT MODE (no mode defined) --->
						<cfdefaultcase>
						<p><strong>Access Denied</strong></p>
						</cfdefaultcase>
						<!--- /END DEFAULT MODE --->
						</cfswitch>


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