<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: discount-details.cfm
File Date: 2013-02-27
Description: Displays discount add/edit/delete form
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
<!--- define showtab to set up default tab display --->
<cfparam name="url.showtab" type="numeric" default="1">
<!--- ID of discount (for updates/deletions) --->
<cfparam name="url.discount_id" default="0">
<cfparam name="form.discount_id" default="#url.discount_id#">

<!--- BASE URL --->
<cfset request.cwpage.baseUrl = request.cw.thisPage>

<!--- /////// --->
<!--- ADD NEW DISCOUNT --->
<!--- /////// --->
<cfif isDefined('form.addDiscount')>
	<!--- CHECKBOX PARAMS --->
	<cfparam name="form.discount_show_description" default="0">
	<cfparam name="form.discount_global" default="0">
	<cfparam name="form.discount_exclusive" default="0">
	<cfparam name="form.discount_archive" default="0">
	<!--- QUERY: Add new discount (all discount form variables) --->
	<!--- this query returns the discount id, or an error like '0-fieldname' --->
	<cfset newDiscountID = CWqueryInsertDiscount(
		discount_id=form.discount_id,
		discount_merchant_id=form.discount_merchant_id,
		discount_name=form.discount_name,
		discount_amount=form.discount_amount,
		discount_calc=form.discount_calc,
		discount_description=form.discount_description,
		discount_show_description=form.discount_show_description,
		discount_type=form.discount_type,
		discount_promotional_code=form.discount_promotional_code,
		discount_start_date=form.discount_start_date,
		discount_end_date=form.discount_end_date,
		discount_limit=form.discount_limit,
		discount_customer_limit=form.discount_customer_limit,
		discount_global=form.discount_global,
		discount_exclusive=form.discount_exclusive,
		discount_priority=form.discount_priority,
		discount_archive=form.discount_archive
	)>
	<!--- query checks for duplicate fields --->
	<cfif left(newDiscountID,2) eq '0-'>
		<cfset dupField = listLast(newDiscountID,'-')>
		<cfset CWpageMessage("alert","Error: #dupField# already exists")>
		<!--- update complete: return to page showing message --->
	<cfelse>
		<cfset CWpageMessage("confirm","Discount Added: Complete additional conditions as needed")>
		<cflocation url="#request.cw.thisPage#?discount_id=#newDiscountID#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&showtab=2" addtoken="no">
	</cfif>
</cfif>
<!--- /////// --->
<!--- /END ADD NEW DISCOUNT --->
<!--- /////// --->

<!--- /////// --->
<!--- UPDATE DISCOUNT --->
<!--- /////// --->
<cfif isDefined('form.discount_id') and form.discount_id gt 0 and isDefined('form.discount_name')>
	<!--- CHECKBOX PARAMS --->
	<cfparam name="form.discount_show_description" default="0">
	<cfparam name="form.discount_global" default="0">
	<cfparam name="form.discount_exclusive" default="0">
	<cfparam name="form.discount_archive" default="0">
	<cfparam name="form.discount_filter_customer_type" default="0">
	<cfparam name="form.discount_customer_type" default="0">
	<cfparam name="form.discount_filter_customer_id" default="0">
	<cfparam name="form.discount_filter_cart_total" default="0">
	<cfparam name="form.discount_filter_cart_qty" default="0">
	<cfparam name="form.discount_filter_item_qty" default="0">
	<!--- list of numeric fields --->
	<cfset request.cwpage.numericList = 'discount_amount,discount_limit,discount_customer_limit,
			discount_cart_total_max,discount_cart_total_min, discount_item_qty_min, discount_item_qty_max,
			discount_cart_qty_min,discount_cart_qty_max'>
			<!--- force numeric values or replace with 0 --->
			<cfloop list="#request.cwpage.numericList#" index="f">
				<cfset fieldName = trim(f)>
				<cfset formField = 'form.' & fieldname>
				<!--- set the value to 0 if not numeric or not defined --->
				<cfif NOT isDefined(formField) OR NOT isNumeric(evaluate(formField))>
					<cfset "#formField#" = 0>
				</cfif>
			</cfloop>

	<!--- QUERY: update discount record (all discount form variables) --->
	<cfset updateDiscountID = CWqueryUpdateDiscount(
			discount_id=form.discount_id
			,discount_merchant_id=form.discount_merchant_id
			,discount_name=form.discount_name
			,discount_amount=form.discount_amount
			,discount_calc=form.discount_calc
			,discount_description=form.discount_description
			,discount_show_description=form.discount_show_description
			,discount_type=form.discount_type
			,discount_promotional_code=form.discount_promotional_code
			,discount_start_date=form.discount_start_date
			,discount_end_date=form.discount_end_date
			,discount_limit=form.discount_limit
			,discount_customer_limit=form.discount_customer_limit
			,discount_global=form.discount_global
			,discount_exclusive=form.discount_exclusive
			,discount_priority=form.discount_priority
			,discount_archive=form.discount_archive
			,discount_filter_customer_type=form.discount_filter_customer_type
			,discount_customer_type=form.discount_customer_type
			,discount_filter_customer_id=form.discount_filter_customer_id
			,discount_customer_id=form.discount_customer_id
			,discount_filter_cart_total=form.discount_filter_cart_total
			,discount_cart_total_max=form.discount_cart_total_max
			,discount_cart_total_min=form.discount_cart_total_min
			,discount_filter_item_qty=form.discount_filter_item_qty
			,discount_item_qty_min=form.discount_item_qty_min
			,discount_item_qty_max=form.discount_item_qty_max
			,discount_filter_cart_qty=form.discount_filter_cart_qty
			,discount_cart_qty_min=form.discount_cart_qty_min
			,discount_cart_qty_max=form.discount_cart_qty_max
			)>
	<!--- query checks for duplicate fields --->
	<cfif left(updateDiscountID,2) eq '0-'>
		<cfset dupField = listLast(updateDiscountID,'-')>
		<cfset CWpageMessage("alert","Error: #dupField# already exists")>
		<!--- update complete: return to page showing message --->
	<cfelse>
		<cfset CWpageMessage("confirm","Discount Updated")>
		<cflocation url="#request.cw.thisPage#?discount_id=#form.discount_id#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
	</cfif>
</cfif>
<!--- /////// --->
<!--- /END UPDATE DISCOUNT --->
<!--- /////// --->

<!--- /////// --->
<!--- DELETE DISCOUNT --->
<!--- /////// --->
<cfif isDefined('url.deletedisc') and isNumeric(url.deletedisc)>
	<cfparam name="url.returnurl" type="string" default="discounts.cfm?useralert=#CWurlSafe('Unable to delete: discount #url.deletedisc# not found')#">
	<!--- QUERY: delete customer record (id from url)--->
	<cfset deleteDiscount = CWqueryDeleteDiscount(url.deletedisc)>
	<cflocation url="#url.returnurl#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END DELETE DISCOUNT --->
<!--- /////// --->

<!--- /////// --->
<!--- CHANGE ASSOCIATION METHOD--->
<!--- /////// --->
<cfif isDefined('form.discount_association_method') and len(trim(form.discount_association_method))>
	<cfset updateQuery = CWqueryUpdateDiscountAssociationMethod(form.discount_id,form.discount_association_method)>
	<cfset CWpageMessage("confirm","Association method updated. Complete selections below")>
	<cflocation url="#request.cw.thisPage#?discount_id=#form.discount_id#&showtab=3&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END CHANGE ASSOCIATION METHOD--->
<!--- /////// --->


<!--- /////// --->
<!--- UPDATE CATEGORIES--->
<!--- /////// --->
<cfif isDefined('form.category_id')>
	<!--- QUERY: get categories assigned to this discount --->
	<cfset listDiscCats = CWquerySelectDiscountRelCategories(form.discount_id)>
	<cfset listDiscScndCats = CWquerySelectDiscountRelSecondaries(form.discount_id)>
	<cfset currentCats = valueList(listDiscCats.discount2category_category_id)>
	<cfset currentScndCats = valueList(listDiscScndCats.discount2category_category_id)>
	<!--- check existing cat IDs, remove any not in new list --->
	<cfloop list="#currentCats#" index="i">
		<cfif not listFind(form.category_id,trim(i))>
			<!--- QUERY: delete category --->
			<cfset deleteCat = CWqueryDeleteDiscountCat(form.discount_id,i)>
		</cfif>
	</cfloop>
	<!--- check existing secondary IDs, remove any not in new list --->
	<cfloop list="#currentScndCats#" index="i">
		<cfif not listFind(form.secondary_id,trim(i))>
			<!--- QUERY: delete secondary --->
			<cfset deleteCat = CWqueryDeleteDiscountScndCat(form.discount_id,i)>
		</cfif>
	</cfloop>
	<!--- loop list of submitted cat IDs --->
	<cfloop list="#form.category_id#" index="i">
		<!--- insert any that don't already exist --->
		<cfif len(trim(i)) AND NOT listFind(currentCats,trim(i))>
			<!--- QUERY: insert category --->
			<cfset addCat = CWqueryInsertDiscountCat(form.discount_id,i)>
		</cfif>
	</cfloop>
	<!--- loop list of submitted secondary IDs --->
	<cfloop list="#form.secondary_id#" index="i">
		<!--- insert any that don't already exist --->
		<cfif len(trim(i)) AND NOT listFind(currentScndCats,trim(i))>
			<!--- QUERY: insert secondary--->
			<cfset addCat = CWqueryInsertDiscountScndCat(form.discount_id,i)>
		</cfif>
	</cfloop>
		<!--- clear stored discount data from memory --->
		<cftry>
		<cfset structClear(application.cw.discountData)>
		<cfcatch></cfcatch>
		</cftry>
		<!--- redirect to page with message and tab shown --->
		<cfset CWpageMessage('confirm','Associated #application.cw.adminLabelCategories# and #application.cw.adminLabelSecondaries# saved')>
		<cflocation url="#request.cw.thisPage#?discount_id=#form.discount_id#&showtab=3&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END UPDATE CATEGORIES--->
<!--- /////// --->

<!--- /////// --->
<!--- ADD ASSOCIATED SKUS --->
<!--- /////// --->
	<cfif isDefined('form.discount_sku_id') and len(trim(form.discount_sku_id)) and form.discount_sku_id neq '0'>

		<cfset insertCt = 0>
		<cfloop list="#form.discount_sku_id#" index="pp">
			<cfif len(trim(pp)) and trim(pp) neq 0>
			<cfset insertCt = insertCt + 1>
			<!--- QUERY: insert associated skus (discount id, sku id)--->
			<cfset addDiscSku = CWqueryInsertDiscountSku(form.discount_id,val(trim(pp)))>
			</cfif>
		</cfloop>
			<!--- handle plurals --->
			<cfif insertCt gt 1>
				<cfset s = 's'>
			<cfelse>
				<cfset s = ''>
			</cfif>
		<!--- clear stored discount data from memory --->
		<cftry>
		<cfset structClear(application.cw.discountData)>
		<cfcatch></cfcatch>
		</cftry>
		<cfset confirmMsg = "#insertCt# Associated SKU#s# created">
		<cfset CWpageMessage("confirm",confirmMsg)>
		<cflocation url="#request.cw.thisPage#?discount_id=#form.discount_id#&showtab=3&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
	</cfif>
<!--- /////// --->
<!--- /END ADD ASSOCIATED SKUS --->
<!--- /////// --->

<!--- /////// --->
<!--- DELETE ASSOCIATED SKUS --->
<!--- /////// --->
<cfif isDefined('form.deletesku_id') and len(trim(form.deletesku_id)) and form.deletesku_id neq 0>
		<!--- QUERY: delete discount records (discount, list of products) --->
		<cfset delProds = CWqueryDeleteDiscountSku(form.discount_id,form.deletesku_id)>
		<!--- set up confirmation --->
		<cfif listLen(form.deletesku_id) gt 1>
			<cfset s = 's'>
		<cfelse>
			<cfset s = ''>
		</cfif>
		<!--- clear stored discount data from memory --->
		<cftry>
		<cfset structClear(application.cw.discountData)>
		<cfcatch></cfcatch>
		</cftry>
		<!--- redirect to page with message and tab shown --->
		<cfset CWpageMessage('confirm','#listLen(form.deletesku_id)# associated sku#s# deleted')>
		<cflocation url="#request.cw.thisPage#?discount_id=#form.discount_id#&showtab=3&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END DELETE ASSOCIATED SKUS --->
<!--- /////// --->

<!--- /////// --->
<!--- ADD ASSOCIATED PRODUCTS --->
<!--- /////// --->
	<cfif isDefined('form.discount_product_id') and len(trim(form.discount_product_id)) and form.discount_product_id neq '0'>
		<cfset insertCt = 0>
		<cfloop list="#form.discount_product_id#" index="pp">
			<cfif len(trim(pp)) and trim(pp) neq 0>
			<cfset insertCt = insertCt + 1>
			<!--- QUERY: insert associated products (discount id, product id)--->
			<cfset addDiscProd = CWqueryInsertDiscountProduct(form.discount_id,val(trim(pp)))>
			</cfif>
		</cfloop>
		<!--- clear stored discount data from memory --->
		<cftry>
		<cfset structClear(application.cw.discountData)>
		<cfcatch></cfcatch>
		</cftry>
			<!--- handle plurals --->
			<cfif insertCt gt 1>
				<cfset s = 's'>
			<cfelse>
				<cfset s = ''>
			</cfif>
			<cfset confirmMsg = "#insertCt# Associated Product#s# created">
			<cfset CWpageMessage("confirm",confirmMsg)>
			<cflocation url="#request.cw.thisPage#?discount_id=#form.discount_id#&showtab=3&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
	</cfif>
<!--- /////// --->
<!--- /END ADD ASSOCIATED PRODUCTS --->
<!--- /////// --->

<!--- /////// --->
<!--- DELETE ASSOCIATED PRODUCTS --->
<!--- /////// --->
<cfif isDefined('form.deleteproduct_id') and len(trim(form.deleteproduct_id)) and form.deleteproduct_id neq 0>
		<!--- QUERY: delete discount records (discount, list of products) --->
		<cfset delProds = CWqueryDeleteDiscountProduct(form.discount_id,form.deleteproduct_id)>
		<!--- set up confirmation --->
		<cfif listLen(form.deleteproduct_id) gt 1>
			<cfset s = 's'>
		<cfelse>
			<cfset s = ''>
		</cfif>
		<!--- clear stored discount data from memory --->
		<cftry>
		<cfset structClear(application.cw.discountData)>
		<cfcatch></cfcatch>
		</cftry>
		<!--- redirect to page with message and tab shown --->
		<cfset CWpageMessage('confirm','#listLen(form.deleteproduct_id)# associated product#s# deleted')>
		<cflocation url="#request.cw.thisPage#?discount_id=#form.discount_id#&showtab=3&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END DELETE ASSOCIATED PRODUCTS --->
<!--- /////// --->

<!--- /////// --->
<!--- DEFAULT: LOOKUP DISCOUNT DETAILS --->
<!--- /////// --->
<!--- verify discount id is numeric --->
<cfif not isNumeric(form.discount_id)><cfset form.discount_id = 0></cfif>
<!--- QUERY: get discount by id --->
<cfset discountQuery = CWquerySelectDiscounts(form.discount_id)>
<!--- QUERY: get discount order details (discount id,number of orders to return) --->
<cfset ordersQuery = CWquerySelectDiscountOrderDetails(form.discount_id,50)>
<!--- QUERY: get discount types --->
<cfset discountTypesQuery = CWquerySelectDiscountTypes()>
<!--- QUERY: get all customer types --->
<cfset typesQuery = CWquerySelectCustomerTypes()>
<!--- NOTE: additional queries for 'edit' mode are after the form params, below --->
<!--- if discount id specified but not found, return to list page --->
<cfif form.discount_id gt 0 AND discountQuery.recordCount eq 0>
	<cflocation url="discounts.cfm?useralert=#CWurlSafe('Discount Details Unavailable')#" addtoken="no">
</cfif>
<!--- edit / add new --->
<cfif discountQuery.recordCount>
	<cfset request.cwpage.editmode = 'edit'>
	<cfset request.cwpage.headtext="Discount Details&nbsp;&nbsp;&nbsp;<span class='subhead'>#discountQuery.discount_name# (ID: #discountQuery.discount_merchant_id#)</span>">
<cfelse>
	<cfset request.cwpage.editmode = 'add'>
	<cfset request.cwpage.headtext = "Discount Management: Add New Discount">
</cfif>
<!--- /////// --->
<!--- /END LOOKUP DISCOUNT --->
<!--- /////// --->

<!--- FORM DEFAULTS --->
<!--- type of discount: sku_cost | sku_ship | order_total | ship_total --->
<cfparam name="form.discount_type" type="string" default="#discountQuery.discount_type#">
<!--- calculation: fixed | percent --->
<cfparam name="form.discount_calc" type="string" default="#discountQuery.discount_calc#">
<!--- amount (dollar value or percentage) --->
<cfparam name="form.discount_amount" type="string" default="#discountQuery.discount_amount#">
<!--- merchant id: in-store 'part number' for this discount --->
<cfparam name="form.discount_merchant_id" type="string" default="#discountQuery.discount_merchant_id#">
<!--- discount name: title of promotion e.g. "Spring Widgets Sale" --->
<cfparam name="form.discount_name" type="string" default="#discountQuery.discount_name#">
<!--- description of discount e.g. "Get 20% Off when you spend more than $100"--->
<cfparam name="form.discount_description" type="string" default="#discountQuery.discount_description#">
<!--- show the description in the cart, emails, etc --->
<cfparam name="form.discount_show_description" type="string" default="#discountQuery.discount_show_description#">
<!--- global discount: y/n (discount applies to all items or only specific skus) --->
<cfparam name="form.discount_global" type="string" default="#discountQuery.discount_global#">
<!--- exclusive discount: y/n (discount can be used with other discounts) --->
<cfparam name="form.discount_exclusive" type="string" default="#discountQuery.discount_exclusive#">
<!--- priority: if exclusive, determines applied discount  --->
<cfparam name="form.discount_priority" type="string" default="#discountQuery.discount_priority#">
<!--- promo code: if used, discount must enter this to invoke discount --->
<cfparam name="form.discount_promotional_code" type="string" default="#discountQuery.discount_promotional_code#">
<!--- start date --->
<cfparam name="form.discount_start_date" type="string" default="#lsDateFormat(discountQuery.discount_start_date)#">
<!--- end date --->
<cfparam name="form.discount_end_date" type="string" default="#lsDateFormat(discountQuery.discount_end_date)#">
<!--- use limit: number of times this discount can be used before it becomes invalid (0 = no limit) --->
<cfparam name="form.discount_limit" type="string" default="#discountQuery.discount_limit#">
<!--- discount limit: number of times a customer can use this discount (0 = no limit) --->
<cfparam name="form.discount_customer_limit" type="string" default="#discountQuery.discount_customer_limit#">
<!--- archived: yes/no - only active discounts are available to the cart --->
<cfparam name="form.discount_archive" type="string" default="#discountQuery.discount_archive#">
<!--- FILTERING PARAMS --->
<cfparam name="form.discount_filter_customer_type" default="#discountQuery.discount_filter_customer_type#">
<cfparam name="form.discount_customer_type" default="#discountQuery.discount_customer_type#">
<cfparam name="form.discount_filter_customer_id" default="#discountQuery.discount_filter_customer_id#">
<cfparam name="form.discount_customer_id" default="#discountQuery.discount_customer_id#">
<cfparam name="form.discount_filter_cart_total" default="#discountQuery.discount_filter_cart_total#">
<cfparam name="form.discount_cart_total_max" default="#discountQuery.discount_cart_total_max#">
<cfparam name="form.discount_cart_total_min" default="#discountQuery.discount_cart_total_min#">
<cfparam name="form.discount_filter_item_qty" default="#discountQuery.discount_filter_item_qty#">
<cfparam name="form.discount_item_qty_max" default="#discountQuery.discount_item_qty_max#">
<cfparam name="form.discount_item_qty_min" default="#discountQuery.discount_item_qty_min#">
<cfparam name="form.discount_filter_cart_qty" default="#discountQuery.discount_filter_cart_qty#">
<cfparam name="form.discount_cart_qty_max" default="#discountQuery.discount_cart_qty_max#">
<cfparam name="form.discount_cart_qty_min" default="#discountQuery.discount_cart_qty_min#">
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title <title> --->
<cfset request.cwpage.title = "Manage Discounts">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = request.cwpage.headtext>
<!--- Page request.cwpage.subheading (instructions) <h2> --->
<cfsavecontent variable="request.cwpage.subhead">
<cfif len(trim(discountQuery.discount_description))><cfoutput>#discountQuery.discount_description#</cfoutput></cfif>
</cfsavecontent>
<cfset request.cwpage.heading2 = request.cwpage.subhead>
<!--- current menu marker --->
<cfif request.cwpage.editmode is 'add'>
	<cfset request.cwpage.currentNav = request.cw.thisPage>
<cfelseif discountQuery.discount_archive is 1>
	<cfset request.cwpage.currentNav = 'discounts.cfm?view=arch'>
<cfelse>
	<cfset request.cwpage.currentNav = 'discounts.cfm'>
</cfif>
<!--- load form scripts --->
<cfset request.cwpage.isFormPage = 1>
<!--- load table scripts --->
<cfset request.cwpage.isTablePage = 1>
<!--- if editing, get advanced details --->
<cfif request.cwpage.editMode is 'edit'>
	<!--- queries for item selection --->
	<!--- QUERY: get categories, secondary cats (all) --->
	<cfset listC = CWquerySelectCategories()>
	<cfset listSC = CWquerySelectScndCategories()>
	<!--- QUERY: get categories assigned to this discount --->
	<cfset listDiscCats = CWquerySelectDiscountRelCategories(form.discount_id)>
	<!--- QUERY: get secondary categories assigned to this discount --->
	<cfset listDiscScndCats = CWquerySelectDiscountRelSecondaries(form.discount_id)>
	<!--- QUERY: get all products related to this discount --->
	<cfset discountProductsQuery = CWquerySelectDiscountProducts(form.discount_id)>
	<!--- QUERY: get all skus related to this discount --->
	<cfset discountSkusQuery = CWquerySelectDiscountSkus(form.discount_id)>
	<!--- Create a list of assigned categories for the checkboxes --->
	<cfset listRelCats = ValueList(listDiscCats.discount2category_category_id)>
	<!--- Create a list of assigned secondary categories for the select menus --->
	<cfset listRelScndCats = ValueList(listDiscScndCats.discount2category_category_id)>
	<!--- dynamic form elements, save as variables for use on multiple tabs --->
	<cfsavecontent variable="request.cwpage.discountSubmitButton">
	<input name="updateDiscount" type="submit" class="CWformButton" id="updateDiscount" value="Save Discount">
	</cfsavecontent>
	<cfsavecontent variable="request.cwpage.discountArchiveButton">
	<a class="CWbuttonLink" onclick="return confirm('Archive Discount <cfoutput>#cwStringFormat(form.discount_name)#</cfoutput>?');" title="Archive Discount: <cfoutput>#CWstringFormat(form.discount_name)#</cfoutput>"
	href="discounts.cfm?archiveid=<cfoutput>#form.discount_id#</cfoutput>">Archive Discount</a>
	</cfsavecontent>
	<cfsavecontent variable="request.cwpage.discountActivateButton">
	<a class="CWbuttonLink" title="Reactivate Discount: <cfoutput>#CWstringFormat(form.discount_name)#</cfoutput>"
	href="discounts.cfm?reactivateid=<cfoutput>#form.discount_id#</cfoutput>">Activate Discount</a>
	</cfsavecontent>
	<cfsavecontent variable="request.cwpage.discountDeleteButton">
	<cfoutput><a class="CWbuttonLink deleteButton" onclick="return confirm('Delete Discount #cwStringFormat(discountQuery.discount_merchant_id)#: #cwStringFormat(discountQuery.discount_name)#?')"
		href="discount-details.cfm?deletedisc=#form.discount_id#&returnurl=discounts.cfm?userconfirm=Discount Deleted">Delete Discount</a></cfoutput>
	</cfsavecontent>
</cfif>
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
		<!--- page js --->
		<script type="text/javascript">
		jQuery(document).ready(function(){
			// global discount hides association options
			jQuery('input#discount_global').click(function(){
				if (jQuery(this).prop('checked')==true){
					jQuery('#CWadminTabWrapper ul.CWtabList a[href="#tab3"]').parents('li').hide();
					jQuery(this).addClass('toggle');
				} else if (jQuery(this).hasClass('toggle') == true) {
					jQuery('#CWadminTabWrapper ul.CWtabList a[href="#tab3"]').parents('li').show();
				};
			});
			// sku shipping: partial sku_ship discounts not allowed
			var $skuShipSelect = function(el){
				var thisVal = jQuery(el).find('option:selected').val();
				var amountBox = jQuery('input#discount_amount');
				var typeSel = jQuery('select#discount_calc');
				if (thisVal=='sku_ship'){
					jQuery(amountBox).val('100').hide();
					jQuery(typeSel).val('percent').after('<p id="skuShipNote">Free Shipping</p>').hide();
				} else {
					jQuery(amountBox).show();
					jQuery(typeSel).show();
					jQuery('p#skuShipNote').remove();
				};
			};
			// run on change of discount type
			jQuery('select#discount_type').change(function(){
				$skuShipSelect(jQuery(this));
			});
			// also run on page load
			$skuShipSelect(jQuery('select#discount_type#'));
			// associated product click-to-select
			jQuery('#tblDiscProdSelect tr td').not(':has(a),:has(input)').css('cursor','pointer').click(function(event){
			if (event.target.type != 'checkbox') {
			jQuery(this).siblings('td.firstCheck').find(':checkbox').trigger('click');
			}
			}).hover(
			function(){
			jQuery(this).addClass('hoverCell');
			},
			function(){
			jQuery(this).removeClass('hoverCell');
			});
		});
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
					<!-- Admin Alert - message shown to user -->
					<cfinclude template="cwadminapp/inc/cw-inc-admin-alerts.cfm">
					<!-- Page Content Area -->
					<div id="CWadminContent">

						<!--- /////// --->
						<!--- ADD/UPDATE CUSTOMER --->
						<!--- /////// --->
							<!-- TABBED LAYOUT -->
							<div id="CWadminTabWrapper">
								<!-- TAB LINKS -->
								<ul class="CWtabList">
									<!--- tab 1 --->
									<li><a href="#tab1" title="Discount Info">Discount Details</a></li>
									<!--- tab 2 --->
									<cfif request.cwpage.editmode is 'edit'>
									<li><a href="#tab2" title="Conditions">Conditions</a></li>
									</cfif>
									<!--- tab 3 --->
									<cfif discountQuery.discount_global is 0 and request.cwpage.editmode is 'edit'>
									<li><a href="#tab3" title="Associated Items">Associated Items</a></li>
									</cfif>
									<!--- tab 4 --->
									<cfif ordersQuery.recordCount>
										<li><a href="#tab4" title="Usage History">Usage History</a></li>
									</cfif>
								</ul>
								<div class="CWtabBox">
									<!--- Discount Primary Info Form --->
									<form name="discountDetails" method="post" action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" class="CWvalidate">
									<!--- FIRST TAB (status) --->
									<div id="tab1" class="tabDiv">
										<h3>Discount Configuration</h3>
										<table class="noBorder">
										<tr><td>
										<!--- discount general info table --->
													<table class="CWformTable wide">
														<tr class="headerRow">
														<th colspan="2">Discount Parameters</th>
														</tr>
														<!--- reference ID: merchant id code for discount --->
														<tr>
															<th class="label" style="width:180px;">Reference ID</th>
															<td>
																<input name="discount_merchant_id" class="{required:true}" title="Reference ID is required" size="35" type="text" id="discount_merchant_id" value="<cfoutput>#htmlEditFormat(form.discount_merchant_id)#</cfoutput>">
																<span class="smallPrint">For internal use only - must be unique</span>
															</td>
														</tr>
														<!--- discount name shown to use --->
														<tr>
															<th class="label">Discount Name</th>
															<td>
																<input name="discount_name" class="{required:true}" title="Discount Name is required" size="35" type="text" id="discount_name" value="<cfoutput>#htmlEditFormat(form.discount_name)#</cfoutput>">
																<span class="smallPrint">Discount heading shown to customer</span>
															</td>
														</tr>
														<!--- discount description --->
														<tr>
															<th class="label">Description</th>
															<td><textarea name="discount_description" class="" title="Discount Description (optional)" cols="34" rows="2" id="discount_description"><cfoutput>#form.discount_description#</cfoutput></textarea></td>
														</tr>
														<!--- show description --->
														<tr>
															<th class="label">Show Description</th>
															<td>
																<input name="discount_show_description" type="checkbox" class="" value="1" <cfif form.discount_show_description eq 1> checked="checked"</cfif> id="discount_show_description">
																<span class="smallPrint">Show this description when the discount is activated</span>
															</td>
														</tr>

														<!--- promo code --->
														<tr>
															<th class="label">Promotional Code</th>
															<td>
																<input name="discount_promotional_code" class="" title="Promotional Code" size="35" type="text" maxlength="100" id="discount_promotional_code" value="<cfoutput>#form.discount_promotional_code#</cfoutput>">
																<span class="smallPrint"><br>(Optional: if left blank, discount is applied automatically)</span>
															</td>
														</tr>
														<!--- start/end dates --->
														<tr>
															<th class="label">Start Date</th>
															<td>
																<cfif not isDate(form.discount_start_date)>
																	<cfset form.discount_start_date = dateAdd('d',-1,CWtime())>
																</cfif>
																<input name="discount_start_date" type="text" class="date_input_future {required:true}" title="Start date is required" value="<cfoutput>#LSdateFormat(form.discount_start_date,request.cw.scriptdatemask)#</cfoutput>" size="10" id="discount_start_date">
															</td>
														</tr>
														<tr>
															<th class="label">End Date</th>
															<td>
																<input name="discount_end_date" type="text" class="date_input_future" value="<cfif isDate(form.discount_end_date)><cfoutput>#LSdateFormat(form.discount_end_date,request.cw.scriptdatemask)#</cfoutput></cfif>" size="10" id="discount_end_date">
																<span class="smallPrint">(Optional: blank = no expiration)</span>
															</td>
														</tr>
														<!--- limits --->
														<tr>
															<th class="label">Limit Total Uses</th>
															<td>
																<input name="discount_limit" type="text" class="{required:true}" title="Discount limit number is required" value="<cfif isNumeric(form.discount_limit)><cfoutput>#form.discount_limit#</cfoutput><cfelse>0</cfif>" size="6" id="discount_limit" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
																<span class="smallPrint">Total number of times this discount may be applied. 0 = no limit</span>
															</td>
														</tr>
														<tr>
															<th class="label">Limit Customer Uses
															<br><span class="smallPrint">* Note: requires login</span></th>
															<td>
																<input name="discount_customer_limit" type="text" class="{required:true}" title="Discount customer limit number is required" value="<cfif isNumeric(form.discount_customer_limit)><cfoutput>#form.discount_customer_limit#</cfoutput><cfelse>0</cfif>" size="6" id="discount_customer_limit" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
																<span class="smallPrint">Total number of times a customer may use this discount. 0 = no limit</span>
															</td>
														</tr>
													</table>
													<!--- /end general info --->
													<!--- discount calculation table --->
													<table class="CWformTable wide">
														<tr class="headerRow">
														<th colspan="2">Discount Calculation</th>
														</tr>
														<!--- discount type --->
														<tr>
															<th class="label">Discount Applies To</th>
															<td>
															<select name="discount_type" id="discount_type">
																<cfloop query="discountTypesQuery">
																<cfoutput><option value="#discount_type#"<cfif form.discount_type is trim(discount_type)> selected="selected"</cfif>>#discount_type_description#</option></cfoutput>
																</cfloop>
															</select>
															</td>
														</tr>
														<!--- amount / calculation type --->
														<tr>
															<th class="label" style="width:180px;">Amount/Rate</th>
															<td>
															<input name="discount_amount" class="{required:true}" title="Discount Amount is required" size="6" type="text" id="discount_amount" value="<cfoutput>#form.discount_amount#</cfoutput>" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
															<select name="discount_calc" id="discount_calc">
																<option value="fixed"<cfif form.discount_calc is 'fixed'> selected="selected"</cfif>>Fixed Amount</option>
																<option value="percent"<cfif form.discount_calc is 'percent'> selected="selected"</cfif>>Percentage</option>
															</select>
															</td>
														</tr>
														<!--- global --->
														<tr>
															<th class="label">Global Discount</th>
															<td>
																<input name="discount_global" type="checkbox" class="" value="1" <cfif form.discount_global eq 1> checked="checked"</cfif> id="discount_global">
																<span class="smallPrint">Associate this discount with all active products</span>
															</td>
														</tr>
														<!--- exclusive --->
														<tr>
															<th class="label">Exclusive</th>
															<td>
																<input name="discount_exclusive" type="checkbox" class="" value="1"<cfif form.discount_exclusive eq 1> checked="checked"</cfif> id="discount_exclusive">
																<span class="smallPrint">If checked, discount cannot be used with other discounts of this type</span>
															</td>
														</tr>
														<!--- priority --->
														<tr>
															<th class="label">Discount Priority</th>
															<td>
																<input name="discount_priority" type="text" class="{required:true}" maxlength="5" title="Discount priority number is required" value="<cfif isNumeric(form.discount_priority)><cfoutput>#form.discount_priority#</cfoutput><cfelse>0</cfif>" size="6" id="discount_priority" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
																<span class="smallPrint">Numeric only: if exclusive, higher priority discount is applied</span>
															</td>
														</tr>
													</table>
											</td></tr>
										</table>
										<!--- /end discount calculation --->
										<!--- FORM BUTTONS --->
										<div class="CWformButtonWrap"<cfif request.cwpage.editMode is 'add'> style="text-align:center"</cfif>>
											<!--- if editing --->
											<cfif request.cwpage.editmode is 'edit'>
												<!--- submit button --->
												<cfoutput>#request.cwpage.discountSubmitButton#</cfoutput>
												<!--- archive button --->
												<cfif form.discount_archive neq 1>
													<cfoutput>#request.cwpage.discountArchiveButton#</cfoutput>
												<!--- activate --->
												<cfelse>
													<cfoutput>#request.cwpage.discountActivateButton#</cfoutput>
												</cfif>
												<!--- If there are no orders show delete button --->
												<cfif ordersQuery.RecordCount eq 0>
													<cfoutput>#request.cwpage.discountDeleteButton#</cfoutput>
												<cfelse>
													<p>(Orders placed, delete disabled)</p>
												</cfif>
												<!--- hidden fields --->
												<input name="discount_id" type="hidden" id="discount_id" value="<cfoutput>#discountQuery.discount_id#</cfoutput>">
												<input name="discount_archive" type="hidden" id="discount_archive" value="<cfoutput>#discountQuery.discount_archive#</cfoutput>">
											<!--- if adding a new discount --->
											<cfelse>
												<div style="text-align:center;">
												<input name="AddDiscount" type="submit" class="CWformButton" id="AddDiscount" value="&raquo;&nbsp;Next">
												</div>
											</cfif>
										</div>
										<!--- /end form buttons --->
									</div>
									<!--- /end tab 1 --->

									<cfif request.cwpage.editmode is 'edit'>
										<!--- SECOND TAB (conditions) --->
										<div id="tab2" class="tabDiv">
											<h3>Configure Discount Requirements</h3>
											<table class="noBorder">
												<tr>
													<td>
														<!--- discount conditions table --->
														<table class="CWformTable wide">
															<tr class="headerRow">
																<th>Condition</th>
																<th style="width:40px;">Active</th>
																<th>Filter</th>
															</tr>
															<!--- customer type --->
															<tr>
																<th class="label" style="width:180px;">Customer Type</th>
																<td>
																	<input name="discount_filter_customer_type" type="checkbox" id="discount_filter_customer_type" title="Enable customer type filtering"<cfif form.discount_filter_customer_type is 1> checked="checked"</cfif>value="1">
																</td>
																<td class="noLink">
																	<cfoutput query="typesQuery">
																	<label>
																	<input type="checkbox" name="discount_customer_type" value="#customer_type_id#"<cfif listFind(discountQuery.discount_customer_type,typesQuery.customer_type_id)> checked="checked"</cfif>>
																	#customer_type_name#<br></label>
																	</cfoutput>
																	<span class="smallPrint">Requires login to activate discount, if selected</span>
																</td>
															</tr>
															<!--- customer id --->
															<tr>
																<th class="label">Customer ID</th>
																<td>
																	<input name="discount_filter_customer_id" type="checkbox" id="discount_filter_customer_id" title="Enable customer ID filtering"<cfif form.discount_filter_customer_id is 1> checked="checked"</cfif> value="1">
																</td>
																<td>
																	<textarea name="discount_customer_id" class="" title="Discount Customer ID" cols="34" rows="4" id="discount_customer_id"><cfoutput>#form.discount_customer_id#</cfoutput></textarea>
																	<span class="smallPrint"><br>Enter a customer ID (e.g. F45A2F10-25-09), or list of IDs with commas</span>
																</td>
															</tr>
															<!--- cart total --->
															<tr>
																<th class="label">Cart Total</th>
																<td>
																	<input name="discount_filter_cart_total" type="checkbox" id="discount_filter_cart_total" title="Enable cart total filtering"<cfif form.discount_filter_cart_total is 1> checked="checked"</cfif> value="1">
																</td>
																<td>
																<cfoutput>
																	Min: <input name="discount_cart_total_min" type="text" id="discount_cart_total_min" size="6" value="#form.discount_cart_total_min#" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">&nbsp;&nbsp;
																	Max: <input name="discount_cart_total_max" type="text" id="discount_cart_total_max" size="6" value="#form.discount_cart_total_max#" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">&nbsp;&nbsp;
																</cfoutput>
																<span class="smallPrint"><br>Applies to cart subtotal before tax or shipping</span>
																</td>
															</tr>
															<!--- cart qty --->
															<tr>
																<th class="label">Cart Quantity</th>
																<td>
																	<input name="discount_filter_cart_qty" type="checkbox" id="discount_filter_cart_qty" title="Enable cart quantity filtering"<cfif form.discount_filter_cart_qty is 1> checked="checked"</cfif> value="1">
																</td>
																<td>
																<cfoutput>
																	Min: <input name="discount_cart_qty_min" type="text" id="discount_cart_qty_min" size="6" value="#form.discount_cart_qty_min#" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">&nbsp;&nbsp;
																	Max: <input name="discount_cart_qty_max" type="text" id="discount_cart_qty_max" size="6" value="#form.discount_cart_qty_max#" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">&nbsp;&nbsp;
																</cfoutput>
																<span class="smallPrint"><br>Applies to total number of items in cart</span>
																</td>
															</tr>
															<!--- item qty --->
															<tr>
																<th class="label">Item Quantity</th>
																<td>
																	<input name="discount_filter_item_qty" type="checkbox" id="discount_filter_item_qty" title="Enable item quantity filtering"<cfif form.discount_filter_item_qty is 1> checked="checked"</cfif> value="1">
																</td>
																<td>
																<cfoutput>
																	Min: <input name="discount_item_qty_min" type="text" id="discount_item_qty_min" size="6" value="#form.discount_item_qty_min#" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">&nbsp;&nbsp;
																	Max: <input name="discount_item_qty_max" type="text" id="discount_item_qty_max" size="6" value="#form.discount_item_qty_max#" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">&nbsp;&nbsp;
																<span class="smallPrint"><br>Applies to quantity of each associated item</span>
																</cfoutput>
																</td>
															</tr>
														</table>
													</td>
												</tr>
											</table>
											<!--- FORM BUTTONS --->
											<div class="CWformButtonWrap">
												<!--- submit button --->
												<cfoutput>
													#request.cwpage.discountSubmitButton#
												</cfoutput>
												<!--- archive button --->
												<cfif form.discount_archive neq 1>
													<cfoutput>
														#request.cwpage.discountArchiveButton#
													</cfoutput>
													<!--- activate --->
												<cfelse>
													<cfoutput>
														#request.cwpage.discountActivateButton#
													</cfoutput>
												</cfif>
												<!--- If there are no orders show delete button --->
												<cfif ordersQuery.RecordCount eq 0>
													<cfoutput>
														#request.cwpage.discountDeleteButton#
													</cfoutput>
												<cfelse>
													<p>(Orders placed, delete disabled)</p>
												</cfif>
											</div>
											<!--- /end form buttons --->
										</div>
										<!--- /end tab 2 --->
									</cfif>
								</form>
								<!--- /End Discount Primary Info Form --->

									<!--- tab 3 --->
									<cfif discountQuery.discount_global is 0 and request.cwpage.editmode is 'edit'>
										<!--- THIRD TAB (associated items) --->
										<div id="tab3" class="tabDiv">
											<h3>Associated Items</h3>
												<table class="CWformTable wide">
												<tr>
												<th class="label">
												Select Association Method
												</th>
												<td>
													<!--- discount method selection form --->
													<form name="discountMethod" action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" method="post">
														<!--- select method --->
														<select name="discount_association_method" id="discount_association_method">
															<option value="categories"<cfif discountQuery.discount_association_method is 'categories'> selected="selected"</cfif>>Categories</option>
															<option value="products"<cfif discountQuery.discount_association_method is 'products'> selected="selected"</cfif>>Products</option>
															<option value="skus"<cfif discountQuery.discount_association_method is 'skus'> selected="selected"</cfif>>Skus</option>
														</select>
														<!--- submit selection --->
														<input name="changeMethod" type="submit" class="submitButton" value="Select">
														<span class="smallPrint">&nbsp;&nbsp;Note: only the selected method will apply</span>
														<input type="hidden" name="discount_id" value="<cfoutput>#discountQuery.discount_id#</cfoutput>">
													</form>
												</td>
												</tr>
												</table>
												<p>&nbsp;</p>
												<!--- ASSOCIATED ITEMS: SHOW EXISTING --->
												<!--- set default if not already in place --->
												<cfif not len(trim(discountQuery.discount_association_method))>
													<cfset discountQuery.discount_association_method = 'products'>
												</cfif>
												<!--- products --->
												<cfif discountQuery.discount_association_method is 'products'>
												<div class="prodSel products">
													<!--- include product selection --->
													<cfinclude template="cwadminapp/inc/cw-inc-admin-discount-products.cfm">
												</div>
												<cfelseif discountQuery.discount_association_method is 'skus'>
												<!--- skus --->
												<div class="prodSel skus">
													<!--- include sku selection --->
													<cfinclude template="cwadminapp/inc/cw-inc-admin-discount-skus.cfm">
												</div>
												<cfelseif discountQuery.discount_association_method is 'categories'>
												<!--- categories --->
												<div class="prodSel categories">
													<h3>Associated Categories</h3>
													<!--- categories form --->
													<form name="discountCats" method="post" action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" class="CWvalidate">
													<table class="CWformTable wide">
														<tr class="headerRow">
															<th>Select <cfoutput>#application.cw.adminLabelCategories#</cfoutput></th>
														</tr>
														<tr>
															<td>
																<cfset disabledBoxes = ''>
																<cfset splitC = 0>
																<div class="formSubCol">
																	<cfoutput query="listC">
																	<cfsavecontent variable="checkboxCode">
																	<label <cfif listC.category_archive eq 1> class="disabled"</cfif>>
																	<input type="checkbox" name="category_id" value="#listC.category_id#"<cfif listC.category_archive eq 1> disabled="disabled"</cfif><cfif ListFind(listRelCats,listC.category_id,",") neq 0> checked="checked"</cfif>>
																	&nbsp;#listC.category_name#
																	</label><br>
																	<cfif listC.category_archive eq 1>
																		<cfset catsArchived = 1>
																	</cfif>
																	<!--- break into two columns --->
																	<cfif currentRow gte (listC.recordCount/2 - .5) and splitC eq 0 AND NOT listC.category_archive eq 1>
																		<cfset splitC = 1>
																		<!--- create new div in code output to page --->
																		<cfscript>
																		writeOutput('<' & '/div>' & '<' & 'div class="formSubCol">');
																		</cfscript>
																	</cfif>
																	</cfsavecontent>
																	<!--- show enabled cats first, then archived --->
																	<cfif NOT listC.category_archive eq 1>
																		#checkboxCode#
																	<cfelse>
																		<cfset disabledBoxes = disabledBoxes & checkBoxCode>
																	</cfif>
																	</cfoutput>
																</div>
																<cfif len(trim(disabledBoxes))><div class="clear"></div><cfoutput>#disabledBoxes#</cfoutput></cfif>
																<!--- if some cats are archived, show note --->
																<cfif isDefined('catsArchived')>
																	<span class="smallPrint">
																		<br>Archived  <cfoutput>#lcase(application.cw.adminLabelCategories)#</cfoutput> are disabled.
																		<br><a href="categories-main.cfm?view=arch">Activate</a> <cfoutput>#lcase(application.cw.adminLabelCategories)#</cfoutput> to select.
																		<br>
																	</span>
																</cfif>
															</td>
														</tr>
														<tr class="headerRow">
															<th>Select <cfoutput>#application.cw.adminLabelSecondaries#</cfoutput></th>
														</tr>
														<tr>
															<td>
																<cfset disabledBoxes = ''>
																<cfset splitSC = 0>
																<div class="formSubCol">
																	<cfoutput query="listSC">
																	<cfsavecontent variable="checkboxCode">
																	<label <cfif listSC.secondary_archive eq 1> class="disabled"</cfif>>
																	<input type="checkbox" name="secondary_id" value="#listSC.secondary_id#"<cfif listSC.secondary_archive eq 1> disabled="disabled"</cfif><cfif ListFind(listRelScndCats,listSC.secondary_id,",") neq 0> checked="checked"</cfif>>
																	&nbsp;#listSC.secondary_name#
																	</label><br>
																	<cfif listSC.secondary_archive eq 1>
																		<cfset scndcatsArchived = 1>
																	</cfif>
																	<!--- break into two columns --->
																	<cfif currentRow gte (listSC.recordCount/2 - .5) and splitSC eq 0 AND NOT listsC.secondary_archive eq 1>
																		<cfset splitSC = 1>
																		<!--- create new div in code output to page --->
																		<cfscript>
																		writeOutput('<' & '/div>' & '<' & 'div class="formSubCol">');
																		</cfscript>
																	</cfif>
																	</cfsavecontent>
																	<!--- show enabled cats first, then archived --->
																	<cfif NOT listSC.secondary_archive eq 1>
																		#checkboxCode#
																	<cfelse>
																		<cfset disabledBoxes = disabledBoxes & checkBoxCode>
																	</cfif>
																	</cfoutput>
																</div>
																<cfif len(trim(disabledBoxes))><div class="clear"></div><cfoutput>#disabledBoxes#</cfoutput></cfif>
																<!--- if some cats are archived, show note --->
																<cfif isDefined('scndcatsArchived')>
																	<div class="smallPrint">
																		Archived <cfoutput>#lcase(application.cw.adminLabelSecondaries)#</cfoutput> are disabled.
																		<br><a href="categories-secondary.cfm?view=arch">Activate</a> <cfoutput>#lcase(application.cw.adminLabelSecondaries)#</cfoutput> to select.
																	</div>
																</cfif>
															</td>
														</tr>
													</table>
													<!--- /end cats/secondaries table --->
													<div style="clear:both">
														<input name="saveDiscCats" type="submit" class="CWformButton" id="saveDiscCats" value="Save Selection">
														<input name="discount_id" type="hidden" value="<cfoutput>#form.discount_id#</cfoutput>">
														<!--- hidden fields force processing when no boxes selected (clear all) --->
														<input name="category_id" type="hidden" value="">
														<input name="secondary_id" type="hidden" value="">
													</div>
													</form>
													<!--- /end categories form --->
												</div>
												</cfif>
										</div>
									</cfif>
									<!--- /end tab 3 --->

									<cfif ordersQuery.recordCount>
										<!--- FOURTH TAB (discount usage details) --->
										<div id="tab4" class="tabDiv">
											<h3>Discount Usage</h3>
											<table id="tblOrderDetails" class="wide CWinfoTable" style="width:735px;">
												<thead>
												<tr class="sortRow">
													<th class="noSort">View Order</th>
													<th class="order_id">Order ID</th>
													<th width="75" class="order_date">Date</th>
													<th class="noSort">Customer</th>
												</tr>
												</thead>
												<tbody>
												<cfoutput query="ordersQuery">
												<tr>
													<td style="text-align:center">
														<a href="order-details.cfm?order_id=#ordersQuery.discount_usage_order_id#&amp;returnurl=#URLEncodedFormat(request.cwpage.baseUrl)#">
														<img src="img/cw-edit.gif" alt="View Order Details" width="15" height="15"></a>
													</td>
													<cfset order_id = ordersQuery.discount_usage_order_id>
													<td>
														<a href="order-details.cfm?order_id=#discount_usage_order_id#" class="productLink">
														<cfif len(discount_usage_order_id) gt 16>...</cfif>#right(discount_usage_order_id,  16)#
														</a>
													</td>
													<td style="text-align:right;">#LSdateFormat(ordersQuery.discount_usage_datetime,application.cw.globalDateMask)#</td>
													<td class="noLink">
														<a href="customer-details.cfm?customer_id=#ordersQuery.discount_usage_customer_id#" class="columnLink">#ordersQuery.customer_last_name#, #ordersQuery.customer_first_name#</a>
													</td>
												</tr>
												</cfoutput>
												</tbody>
											</table>
										</div>
									</cfif>
									<!--- /END tab 4 --->
								</div>
								<!--- /END tab content --->
							</div>

						<!--- /////// --->
						<!--- END ADD/UPDATE CUSTOMER --->
						<!--- /////// --->
						<div class="clear"></div>
					</div>
					<!-- /end Page Content -->
				</div>
				<!-- /end CWinner -->
				<!--- page end content / debug --->
				<cfinclude template="cwadminapp/inc/cw-inc-admin-page-end.cfm">
				<!-- /end CWadminPage-->
				<div class="clear"></div>
					</div>
					<!-- /end CWadminPage -->
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