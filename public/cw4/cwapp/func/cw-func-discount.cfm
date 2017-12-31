<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-func-discount.cfm
File Date: 2012-09-05
Description: manages product/sku, shipping, or order discount calculations and related queries
Dependencies: product functions, global functions in head of calling page
==========================================================
--->
 
<!--- // ---------- // Get discounts applicable to any order // ---------- // --->
<cffunction name="CWgetCartDiscountData"
			access="public"
			output="false"
			returntype="struct"
			hint="Returns a structure of information when attempting to apply discount(s) to an order.
			      Each discount either has an amount and/or percentage, or is rejected with a text response."
			>

<!---
NOTES:
Quantity and sku ids are provided to check for discount requirements - the discount amount is only calculated for the order total.

The discount matching selections are processed in the order they appear in the code.
The first filter to cause a rejection will prevent any further checks,
and will return an error message specific to that rejection.
To change the priority of the filtering and response messages,
the order of the filter checks may be rearranged below.
Exclusive discount checking should be left last.
 --->

	<cfargument name="cart"
			required="true"
			type="struct"
			hint="cart structure">

	<cfargument name="customer_id"
			required="false"
			default="0"
			type="string"
			hint="A single customer ID (0 or '' = don't check)">

	<cfargument name="customer_type"
			required="false"
			default="0"
			type="string"
			hint="A numeric customer type id (0 or '' = don't check)">

	<cfargument name="promo_code"
			required="false"
			default=""
			type="string"
			hint="the code(s) being used by the customer to invoke the discount(s) - delimited list with ^ separator">

	<cfargument name="compare_date"
			required="false"
			default="#cwtime()#"
			type="date"
			hint="the date to compare the discount to, default is current time (cannot be blank, must be a valid date format)">

	<cfargument name="return_rejects"
			required="false"
			default="true"
			type="boolean"
			hint="If true, this function will return any non-matching active discounts, with the rejection reason for each">

	<cfargument name="discount_id"
			required="false"
			default="0"
			type="numeric"
			hint="If provided, function will only attempt to match provided discount id">

<cfset var discountQuery = ''>
<cfset var skuId = ''>
<cfset var productList = ''>
<cfset var discountData = structNew()>
<cfset var responseStruct = structNew()>
<cfset var matchStatus = ''>
<cfset var matchResponse = ''>
<cfset var matchAmount = 0>
<cfset var matchPercent= 0>
<cfset var exclusiveFound = false>
<cfset var exclusiveFoundName = ''>
<cfset var matchQuery = ''>
<cfset var catsQuery = ''>
<cfset var scndCatsQuery = ''>
<cfset var parentProductID = ''>
<cfset var discountUsedCt = ''>
<cfset var customerUsedCt = ''>
<cfset var rowCt = 0>
<cfset var cartTotal = 0>
<cfset var cartQty = 0>

<!--- get actual totals from cart data --->
<cfif isDefined('arguments.cart.carttotals.sub')>
	<cfset cartTotal = arguments.cart.carttotals.sub>
</cfif>

<cfif isDefined('arguments.cart.carttotals.skucount')>
	<cfset cartQty = arguments.cart.carttotals.skucount>
</cfif>

<!--- If no ID provided, get ALL POSSIBLE MATCHES - stored in application memory on first run --->
	<cfif arguments.discount_id eq 0>
	<!--- get all active discounts --->
	<cfset discountQuery = CWgetDiscountData()>
	<!--- if id provided, get only this discount --->
	<cfelse>
	<cfset discountQuery = CWgetDiscountData(discount_id=arguments.discount_id)>
	</cfif>

	<!--- /// /// --->
	<!--- /// START DISCOUNT FILTERS /// --->
	<!--- /// /// --->

<!--- loop matching discounts, comparing each, returning OK message or reason for rejection --->
<cfoutput query="discountQuery">
	<cfset responseStruct = structNew()>
	<cfset matchStatus = ''>
	<cfset matchResponse = ''>

	<!--- match discount type --->
	<cfif trim(discountQuery.discount_type) is not 'order_total'>
		<cfset matchStatus = false>
		<cfset matchResponse = 'Discount type #discountQuery.discount_type# not applicable'>
		<!--- if an exclusive match has already been found, all others are set to false --->
	<cfelseif exclusiveFound is true>
		<cfset matchStatus = false>
		<cfset matchResponse = 'Exclusive discount #exclusiveFoundName# cannot be used with other offers'>
	</cfif>

	<!--- add fixed values into response --->
	<cfset responseStruct.discount_id = discountQuery.discount_id>
	<cfset responseStruct.discount_merchant_id = discountQuery.discount_merchant_id>
	<cfset responseStruct.discount_name = discountQuery.discount_name>
	<cfset responseStruct.discount_promotional_code = discountQuery.discount_promotional_code>
	<cfset responseStruct.discount_exclusive = discountQuery.discount_exclusive>
	<cfset responseStruct.discount_priority = discountQuery.discount_priority>
	<cfset responseStruct.discount_type = discountQuery.discount_type>
	<!--- get conditional values --->
	<cfif discountQuery.discount_show_description>
		<cfset responseStruct.discount_description = discountQuery.discount_description>
	<cfelse>
		<cfset responseStruct.discount_description = ''>
	</cfif>
	<cfif discountQuery.discount_global>
		<cfset responseStruct.association_method = "global">
	<cfelse>
		<cfset responseStruct.association_method = discountQuery.discount_association_method>
	</cfif>
	<!--- get or create remaining values - amount, percent, response message --->

	<!--- PROMO CODE: if provided, or if discount requires one, check for matching string --->
	<cfif matchStatus neq 'false' AND len(trim(discountQuery.discount_promotional_code))>
		<cfif not listFind(arguments.promo_code,discountQuery.discount_promotional_code,'^')
		AND trim(discountQuery.discount_promotional_code) is not trim(arguments.promo_code)>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Promo code #trim(arguments.promo_code)# not matched'>
		</cfif>
	</cfif>

	<!--- DATE: start/stop dates --->
	<cfif matchStatus neq 'false'>
		<cfif not(discount_start_date lte arguments.compare_date
				AND (discount_end_date is ''
					OR dateAdd('d',1,discount_end_date) gte arguments.compare_date))>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Discount not currently available'>
		</cfif>
	</cfif>

	<!--- PRODUCT ASSOCIATIONS --->
	<!--- if not global, check matching records (sku, product, category association methods) --->
	<cfif matchStatus neq 'false' and discountQuery.discount_global neq 1>

		<!--- for products, assume no match until one is found --->
		<cfset matchstatus = false>

		<!--- loop cart items --->
		<cfloop from="1" to="#arrayLen(arguments.cart.cartItems)#" index="cartLine">
			<cfset skuId = arguments.cart.cartItems[cartLine].skuid>
			<cfset skuqty = arguments.cart.cartItems[cartLine].quantity>
			<cfset productId = CWgetProductBySku(arguments.cart.cartItems[cartLine].skuid)>

			<!--- look up matching items by association type --->
			<cfswitch expression="#discountQuery.discount_association_method#">

				<!--- PRODUCTS: straight match by product id --->
				<cfcase value="products">
					<cfquery name="matchQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
					SELECT discount2product_discount_id
					FROM cw_discount_products
					WHERE discount2product_product_id = <cfqueryparam value="#productid#" cfsqltype="cf_sql_numeric">
					AND discount2product_discount_id = <cfqueryparam value="#discountQuery.discount_id#" cfsqltype="cf_sql_integer">
					</cfquery>
					<cfif matchQuery.recordCount>
						<cfset matchStatus = true>
					</cfif>
				</cfcase>

				<!--- SKUS: straight match by sku id --->
				<cfcase value="skus">
					<cfquery name="matchQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
					SELECT discount2sku_discount_id
					FROM cw_discount_skus
					WHERE discount2sku_sku_id = <cfqueryparam value="#skuid#" cfsqltype="cf_sql_numeric">
					AND discount2sku_discount_id = <cfqueryparam value="#discountQuery.discount_id#" cfsqltype="cf_sql_integer">
					</cfquery>
					<cfif matchQuery.recordCount>
						<cfset matchStatus = true>
					</cfif>
				</cfcase>

				<!--- CATEGORIES: get categories & secondaries the product belongs to, check for match --->
				<cfcase value="categories">
					<!--- QUERY: get categories for this product --->
					<cfset catsQuery = CWquerySelectRelCategories(productid)>
					<cfset scndcatsQuery = CWquerySelectRelScndCategories(productid)>
					<!--- check for match by type and id --->
					<cfquery name="matchQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
					SELECT discount_category_id
					FROM cw_discount_categories
					WHERE discount2category_discount_id = <cfqueryparam value="#discountQuery.discount_id#" cfsqltype="cf_sql_integer">
					AND ((
						discount_category_type = 1
						AND discount2category_category_id in(#valueList(catsQuery.category_id)#)
						) OR (
						discount_category_type = 2
						AND discount2category_category_id in(#valueList(scndCatsQuery.secondary_id)#)
					))
					</cfquery>
					<cfif matchQuery.recordCount>
						<cfset matchStatus = true>
					</cfif>
				</cfcase>
			</cfswitch>
			<!--- /end product association types --->

			<!--- ITEM QTY --->
			<cfif matchStatus neq 'false' and skuqty gt 0 and discountQuery.discount_filter_item_qty eq 1>
				<cfif skuqty lt discountQuery.discount_item_qty_min
					AND discountQuery.discount_item_qty_min neq 0
					>
					<cfset matchStatus = false>
					<cfset matchResponse = 'Add #discountQuery.discount_item_qty_min - skuqty# more of this item to your cart to activate this discount'>
				<cfelseif discountQuery.discount_filter_item_qty neq 0
					AND discountQuery.discount_item_qty_max neq 0
					AND skuqty gt discountQuery.discount_item_qty_max
					>
					<cfset matchStatus = false>
					<cfset matchResponse = 'Only available for quantities of #discountQuery.discount_item_qty_max# or less'>
				</cfif>
			</cfif>
			<!--- /end item qty --->
		<!--- end the loop if at least one item matches --->
		<cfif matchstatus eq 'true'><cfbreak></cfif>
		</cfloop>

		<!--- if no match was found, set message --->
		<cfif matchStatus neq 'true'>
			<cfset matchResponse = 'Discount does not apply to items in cart'>
		</cfif>
		<!--- /end product associations --->
	</cfif>

	<!--- CUSTOMER ID --->
	<cfif matchStatus neq 'false' and arguments.customer_id neq 0 and len(trim(arguments.customer_id))
		and len(trim(discountQuery.discount_customer_id)) and discountQuery.discount_filter_customer_id eq 1>
		<cfset customerIdList = replace(discountQuery.discount_customer_id,' ','','all')>
		<cfif not listFind(customeridlist,arguments.customer_id)>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Discount not available for current customer'>
		</cfif>
	<!--- if no customer id provided, return false if filtered by id --->
	<cfelseif matchStatus neq 'false' and discountQuery.discount_filter_customer_id eq 1>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Customer ID not matched. Create an account to use this discount'>
	</cfif>

	<!--- CUSTOMER TYPE --->
	<cfif matchStatus neq 'false' and arguments.customer_type neq 0 and len(trim(arguments.customer_type))
			and len(trim(discountQuery.discount_customer_type)) and discountQuery.discount_filter_customer_type eq 1>
		<cfset customerTypeList = replace(discountQuery.discount_customer_type,' ','','all')>
		<cfif not listFind(customerTypeList,arguments.customer_type)>
				<cfset matchStatus = false>
				<cfset matchResponse = 'Discount not available for current customer type'>
		</cfif>
	<!--- if no customer type provided, return false if filtered by type --->
	<cfelseif discountQuery.discount_filter_customer_type eq 1>
				<cfset matchStatus = false>
				<cfset matchResponse = 'Customer type not matched. Create an account to use this discount'>
	</cfif>

	<!--- DISCOUNT LIMIT (past usage) --->
	<cfif matchStatus neq 'false' and discountQuery.discount_limit neq 0>
		<!--- function returns number of times  --->
		<cfset discountUsedCt = cwGetDiscountUsage(discountQuery.discount_id)>
		<cfif discountQuery.discount_limit lte discountUsedCt>
				<cfset matchStatus = false>
				<cfset matchResponse = 'Discount limited use has expired'>
		</cfif>
	</cfif>

	<!--- CUSTOMER DISCOUNT LIMIT (past usage) --->
	<cfif matchStatus neq 'false' and discountQuery.discount_customer_limit neq 0 and application.cw.customerAccountEnabled>
		<!--- if this is a limited use discount, we must have a customer id --->
		<cfif len(trim(arguments.customer_id)) AND arguments.customer_id neq 0>
			<cfset customerUsedCt = cwGetDiscountCustomerUsage(discountQuery.discount_id,arguments.customer_id)>
			<cfif discountQuery.discount_customer_limit lte customerUsedCt>
					<cfset matchStatus = false>
					<cfset matchResponse = 'Discount has been used maximum number of times by current customer'>
			</cfif>
		<!--- if no customer id available, cannot be used --->
		<cfelse>
				<cfset matchStatus = false>
				<cfset matchResponse = 'Log in or create an account to use this discount'>
		</cfif>
	</cfif>

	<!--- CART TOTAL --->
	<cfif matchStatus neq 'false' and carttotal gt 0 and discountQuery.discount_filter_cart_total eq 1>
		<cfif carttotal lt discountQuery.discount_cart_total_min>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Add #lsCurrencyFormat(discountQuery.discount_cart_total_min - carttotal,'local')# to your cart to activate this discount'>
		<cfelseif discountQuery.discount_cart_total_max neq 0
				AND carttotal gt discountQuery.discount_cart_total_max>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Discount only available for orders up to #lsCurrencyFormat(discountQuery.discount_cart_total_max,'local')#'>
		</cfif>
	</cfif>

	<!--- CART QTY --->
	<cfif matchStatus neq 'false' and cartqty gt 0 and discountQuery.discount_filter_cart_qty eq 1>
		<cfif cartqty lt discountQuery.discount_cart_qty_min>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Add #discountQuery.discount_cart_qty_min - cartqty# more item(s) to your cart to activate this discount'>
		<cfelseif discountQuery.discount_filter_cart_qty neq 0
			AND cartqty gt discountQuery.discount_cart_qty_max>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Only available for orders containing #discountQuery.discount_cart_qty_max# or fewer items'>
		</cfif>
	</cfif>

	<!--- EXCLUSIVE DISCOUNTS: set match for all others to false --->
	<!--- if any discount is exclusive (should catch first matching record, see 'sort by' in discountsQuery)--->
	<!--- NOTE: THIS MUST REMAIN LAST, at the end of filter selections --->
	<cfif matchStatus neq 'false' AND discountQuery.discount_exclusive is 1>
		<cfset exclusiveFound = true >
		<cfset exclusiveFoundName = discountQuery.discount_name>
	</cfif>

	<!--- if discount is a match, calculate amount, set status--->
	<cfif matchStatus neq 'false'>
		<cfset matchStatus = true>

		<!--- PERCENTAGE --->
		<cfif discountQuery.discount_calc is 'percent'>
			<cfset matchPercent = discountQuery.discount_amount>
			<cfset matchAmount = 0>
		<!--- FIXED COST --->
		<cfelse>
			<cfset matchPercent = 0>
			<cfset matchAmount = discountQuery.discount_amount>
		</cfif>
		<!--- /end percentage or fixed --->
	<!--- if no match, all values 0 --->
	<cfelse>
		<cfset matchPercent = 0>
		<cfset matchAmount = 0>
	</cfif>
	<!--- /end if match --->

	<!--- add values to current record --->
	<cfset responseStruct.discount_match_response = matchresponse>
	<cfset responseStruct.discount_match_status = matchStatus>
	<cfset responseStruct.discount_amount = matchamount>
	<cfset responseStruct.discount_percent = matchpercent>

	<!--- add current record data to the structure being returned --->
	<cfif arguments.return_rejects is true OR matchStatus is true>
		<cfset rowCt = rowCt + 1>
		<cfset discountdata.discountResponse[rowCt] = responseStruct>
	</cfif>

</cfoutput>
<!--- /end loop discount query --->

<cfreturn discountData>
</cffunction>

<!--- // ---------- // Get discount totals for any cart // ---------- // --->
<cffunction name="CWgetCartDiscountTotals"
			access="public"
			output="false"
			returntype="struct"
			hint="Returns a structure of totals for all available discounts on any order"
			>

	<cfargument name="cart"
			required="true"
			type="struct"
			hint="cart structure">

	<cfargument name="customer_id"
			required="false"
			default="0"
			type="string"
			hint="A single customer ID (0 or '' = don't check)">

	<cfargument name="customer_type"
			required="false"
			default="0"
			type="string"
			hint="A numeric customer type id (0 or '' = don't check)">

	<cfargument name="promo_code"
			required="false"
			default=""
			type="string"
			hint="the code(s) being used by the customer to invoke the discount(s) - delimited list with ^ separator">

	<cfargument name="compare_date"
			required="false"
			default="#cwtime()#"
			type="date"
			hint="the date to compare the discount to, default is current time (cannot be blank, must be a valid date format)">

<cfset var discountData = structNew()>
<cfset var responseData = structNew()>
<cfset var discountItem = structNew()>
<cfset var discountTotals = structNew()>
<cfset var discountAmount = 0>
<cfset var discountPercent = 0>
<cfset var discountID = ''>
<cfset var cartTotal = 0>
<cfset discountData.discountresponse = structNew()>
<cfset discountTotals.amount = 0>
<cfset discountTotals.percent = 0>
<cfset discountTotals.id = ''>

<!--- get actual totals from cart data --->
<cfif isDefined('arguments.cart.carttotals.sub')>
	<cfset cartTotal = arguments.cart.carttotals.sub>
</cfif>

<!--- get all matching discounts --->
<cfset discountData = CWgetCartDiscountData(
						cart=arguments.cart,
						customer_id=arguments.customer_id,
						customer_type=arguments.customer_type,
						promo_code=arguments.promo_code,
						compare_date=arguments.compare_date,
						return_rejects=false
						)
						>


<cfif structKeyExists(discountData,'discountResponse')>
	<cfset responseData = discountData.discountResponse>
</cfif>

<!--- loop the discount data --->
<cfloop collection="#responseData#" item="i">

	<!--- get needed info about this discount --->
	<cfset discountItem = evaluate('responseData.#i#')>
	<cfset discountPercent = discountItem.discount_percent>
	<cfset discountAmount = discountItem.discount_amount>
	<cfset discountID = discountItem.discount_id>

	<!--- if discount is an amount, get the percentage that is of the total order --->
	<cfif discountpercent eq 0 and discountamount gt 0 and carttotal gt 0>
		<!--- get rounded 2 decimal percentage by rounding and multiplying --->
		<cfset discountpercent = round((discountamount/carttotal*100)*100)/100>
	<!--- and if discount is a percent, turn it into an amount --->
	<cfelseif carttotal gt 0>
		<cfset discountamount = min(cartTotal,round((cartTotal * discountPercent/100)*100)/100)>
	</cfif>

	<!--- sum totals, percentages --->
	<cfset discountTotals.amount = discountTotals.amount + discountAmount>
	<cfset discountTotals.percent = discountTotals.percent + discountPercent>

	<!--- return list of matching discount IDs --->
	<cfset discountTotals.ID = listAppend(discountTotals.ID,discountID)>

</cfloop>

<!--- percent cannot be over 100 --->
<cfif discountTotals.percent gt 100>
	<cfset discountTotals.percent eq 100>
</cfif>
<!--- total cannot be higher than cart total --->
<cfif discountTotals.amount gt cartTotal>
	<cfset discountTotals.amount eq cartTotal>
</cfif>

<cfreturn discountTotals>

</cffunction>

<!--- // ---------- // Get discount amount for any cart // ---------- // --->
<cffunction name="CWgetCartDiscountAmount"
			access="public"
			output="false"
			returntype="numeric"
			hint="Returns a numeric discount amount via CWgetCartDiscountTotals"
			>

	<cfargument name="cart"
			required="false"
			default="0"
			type="struct"
			hint="cart object">

	<cfargument name="customer_id"
			required="false"
			default="0"
			type="string"
			hint="A single customer ID (0 or '' = don't check)">

	<cfargument name="customer_type"
			required="false"
			default="0"
			type="string"
			hint="A numeric customer type id (0 or '' = don't check)">

	<cfargument name="promo_code"
			required="false"
			default=""
			type="string"
			hint="the code(s) being used by the customer to invoke the discount(s) - delimited list with ^ separator">

	<cfargument name="compare_date"
			required="false"
			default="#cwtime()#"
			type="date"
			hint="the date to compare the discount to, default is current time (cannot be blank, must be a valid date format)">

	<cfset var discountAmount = 0>

	<cfset discountData = CWgetCartDiscountTotals(
			cart=arguments.cart,
			customer_id=arguments.customer_id,
			customer_type=arguments.customer_type,
			promo_code=arguments.promo_code,
			compare_date=arguments.compare_date
			)>

		<cfif isNumeric(discountData.amount)>
			<cfset discountAmount = discountData.amount>
		</cfif>

	<cfreturn discountAmount>

</cffunction>

<!--- // ---------- // Get shipping discounts applicable to any cart // ---------- // --->
<cffunction name="CWgetShipDiscountData"
			access="public"
			output="false"
			returntype="struct"
			hint="Returns a structure of information when attempting to apply discount(s) to shipping total.
			      Each discount either has an amount and/or percentage, or is rejected with a text response."
			>

<!---
NOTES:

Quantity and sku ids are provided to check for discount requirements - the discount amount is only calculated for the order total.

The discount matching selections are processed in the order they appear in the code.
The first filter to cause a rejection will prevent any further checks,
and will return an error message specific to that rejection.
To change the priority of the filtering and response messages,
the order of the filter checks may be rearranged below.
Exclusive discount checking should be left last.
 --->

	<cfargument name="cart"
			required="true"
			type="struct"
			hint="cart structure">

	<cfargument name="customer_id"
			required="false"
			default="0"
			type="string"
			hint="A single customer ID (0 or '' = don't check)">

	<cfargument name="customer_type"
			required="false"
			default="0"
			type="string"
			hint="A numeric customer type id (0 or '' = don't check)">

	<cfargument name="promo_code"
			required="false"
			default=""
			type="string"
			hint="the code(s) being used by the customer to invoke the discount(s) - delimited list with ^ separator">

	<cfargument name="compare_date"
			required="false"
			default="#cwtime()#"
			type="date"
			hint="the date to compare the discount to, default is current time (cannot be blank, must be a valid date format)">

	<cfargument name="return_rejects"
			required="false"
			default="true"
			type="boolean"
			hint="If true, this function will return any non-matching active discounts, with the rejection reason for each">

	<cfargument name="discount_id"
			required="true"
			default="0"
			type="numeric"
			hint="Id of the discount to look up">

<cfset var discountQuery = ''>
<cfset var skuId = ''>
<cfset var productList = ''>
<cfset var discountData = structNew()>
<cfset var responseStruct = structNew()>
<cfset var matchStatus = ''>
<cfset var matchResponse = ''>
<cfset var matchAmount = 0>
<cfset var matchPercent= 0>
<cfset var exclusiveFound = false>
<cfset var exclusiveFoundName = ''>
<cfset var matchQuery = ''>
<cfset var catsQuery = ''>
<cfset var scndCatsQuery = ''>
<cfset var parentProductID = ''>
<cfset var discountUsedCt = ''>
<cfset var customerUsedCt = ''>
<cfset var rowCt = 0>
<cfset var cartTotal = 0>
<cfset var cartQty = 0>

<!--- get actual totals from cart data --->
<cfif isDefined('arguments.cart.carttotals.sub')>
	<cfset cartTotal = arguments.cart.carttotals.sub>
</cfif>

<cfif isDefined('arguments.cart.carttotals.skucount')>
	<cfset cartQty = arguments.cart.carttotals.skucount>
</cfif>

<!--- If no ID provided, get ALL POSSIBLE MATCHES - stored in application memory on first run --->
	<cfif arguments.discount_id eq 0>
	<!--- get all active discounts --->
	<cfset discountQuery = CWgetDiscountData()>
	<!--- if id provided, get only this discount --->
	<cfelse>
	<cfset discountQuery = CWgetDiscountData(discount_id=arguments.discount_id)>
	</cfif>
	<!--- /// /// --->
	<!--- /// START DISCOUNT FILTERS /// --->
	<!--- /// /// --->

<!--- loop matching discounts, comparing each, returning OK message or reason for rejection --->
<cfoutput query="discountQuery">
	<cfset responseStruct = structNew()>
	<cfset matchStatus = ''>
	<cfset matchResponse = ''>

	<!--- match discount type --->
	<cfif trim(discountQuery.discount_type) is not 'ship_total'>
		<cfset matchStatus = false>
		<cfset matchResponse = 'Discount type #discountQuery.discount_type# not applicable'>
		<!--- if an exclusive match has already been found, all others are set to false --->
	<cfelseif exclusiveFound is true>
		<cfset matchStatus = false>
		<cfset matchResponse = 'Exclusive discount #exclusiveFoundName# cannot be used with other offers'>
	</cfif>

	<!--- add fixed values into response --->
	<cfset responseStruct.discount_id = discountQuery.discount_id>
	<cfset responseStruct.discount_merchant_id = discountQuery.discount_merchant_id>
	<cfset responseStruct.discount_name = discountQuery.discount_name>
	<cfset responseStruct.discount_promotional_code = discountQuery.discount_promotional_code>
	<cfset responseStruct.discount_exclusive = discountQuery.discount_exclusive>
	<cfset responseStruct.discount_priority = discountQuery.discount_priority>
	<cfset responseStruct.discount_type = discountQuery.discount_type>
	<!--- get conditional values --->
	<cfif discountQuery.discount_show_description>
		<cfset responseStruct.discount_description = discountQuery.discount_description>
	<cfelse>
		<cfset responseStruct.discount_description = ''>
	</cfif>
	<cfif discountQuery.discount_global>
		<cfset responseStruct.association_method = "global">
	<cfelse>
		<cfset responseStruct.association_method = discountQuery.discount_association_method>
	</cfif>
	<!--- get or create remaining values - amount, percent, response message --->

	<!--- PROMO CODE: check for matching string --->
	<cfif matchStatus neq 'false' AND len(trim(discountQuery.discount_promotional_code))>
		<!--- if not found in the list, and not a direct match --->
		<cfif not listFind(arguments.promo_code,discountQuery.discount_promotional_code,'^')
		AND trim(discountQuery.discount_promotional_code) is not trim(arguments.promo_code)>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Promo code #trim(arguments.promo_code)# not matched'>
		</cfif>
	</cfif>

	<!--- DATE: start/stop dates --->
	<cfif matchStatus neq 'false'>
		<cfif not(discount_start_date lte arguments.compare_date
				AND (discount_end_date is ''
					OR dateAdd('d',1,discount_end_date) gte arguments.compare_date))>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Discount not currently available'>
		</cfif>
	</cfif>

	<!--- PRODUCT ASSOCIATIONS --->
	<!--- if not global, check matching records (sku, product, category association methods) --->
	<cfif matchStatus neq 'false' and discountQuery.discount_global neq 1>

		<!--- for products, assume no match until one is found --->
		<cfset matchstatus = false>

		<!--- loop cart items --->
		<cfloop from="1" to="#arrayLen(arguments.cart.cartItems)#" index="cartLine">
			<cfset skuId = arguments.cart.cartItems[cartLine].skuid>
			<cfset skuqty = arguments.cart.cartItems[cartLine].quantity>
			<cfset productId = CWgetProductBySku(arguments.cart.cartItems[cartLine].skuid)>

			<!--- look up matching items by association type --->
			<cfswitch expression="#discountQuery.discount_association_method#">

				<!--- PRODUCTS: straight match by product id --->
				<cfcase value="products">
					<cfquery name="matchQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
					SELECT discount2product_discount_id
					FROM cw_discount_products
					WHERE discount2product_product_id = <cfqueryparam value="#productid#" cfsqltype="cf_sql_numeric">
					AND discount2product_discount_id = <cfqueryparam value="#discountQuery.discount_id#" cfsqltype="cf_sql_integer">
					</cfquery>
					<cfif matchQuery.recordCount>
						<cfset matchStatus = true>
					</cfif>
				</cfcase>

				<!--- SKUS: straight match by sku id --->
				<cfcase value="skus">
					<cfquery name="matchQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
					SELECT discount2sku_discount_id
					FROM cw_discount_skus
					WHERE discount2sku_sku_id = <cfqueryparam value="#skuid#" cfsqltype="cf_sql_numeric">
					AND discount2sku_discount_id = <cfqueryparam value="#discountQuery.discount_id#" cfsqltype="cf_sql_integer">
					</cfquery>
					<cfif matchQuery.recordCount>
						<cfset matchStatus = true>
					</cfif>
				</cfcase>

				<!--- CATEGORIES: get categories & secondaries the product belongs to, check for match --->
				<cfcase value="categories">
					<!--- QUERY: get categories for this product --->
					<cfset catsQuery = CWquerySelectRelCategories(productid)>
					<cfset scndcatsQuery = CWquerySelectRelScndCategories(productid)>
					<!--- check for match by type and id --->
					<cfquery name="matchQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
					SELECT discount_category_id
					FROM cw_discount_categories
					WHERE discount2category_discount_id = <cfqueryparam value="#discountQuery.discount_id#" cfsqltype="cf_sql_integer">
					AND ((
						discount_category_type = 1
						AND discount2category_category_id in(#valueList(catsQuery.category_id)#)
						) OR (
						discount_category_type = 2
						AND discount2category_category_id in(#valueList(scndCatsQuery.secondary_id)#)
					))
					</cfquery>
					<cfif matchQuery.recordCount>
						<cfset matchStatus = true>
					</cfif>
				</cfcase>

			</cfswitch>
			<!--- /end product association types --->

			<!--- ITEM QTY --->
			<cfif matchStatus neq 'false' and skuqty gt 0 and discountQuery.discount_filter_item_qty eq 1>
				<cfif skuqty lt discountQuery.discount_item_qty_min
					AND discount_item_qty_min neq 0
					>
					<cfset matchStatus = false>
					<cfset matchResponse = 'Add #discountQuery.discount_item_qty_min - skuqty# more of this item to your cart to activate this discount'>
				<cfelseif discountQuery.discount_filter_item_qty neq 0
					AND discount_item_qty_max neq 0
					AND skuqty gt discountQuery.discount_item_qty_max
					>
					<cfset matchStatus = false>
					<cfset matchResponse = 'Only available for quantities of #discountQuery.discount_item_qty_max# or less'>
				</cfif>
			</cfif>
			<!--- /end item qty --->
		<!--- end loop if one product matches --->
		<cfif matchstatus eq 'true'><cfbreak></cfif>
		</cfloop>
		<!--- if no match was found, set message --->
		<cfif matchStatus neq 'true'>
			<cfset matchResponse = 'Discount does not apply to items in cart'>
		</cfif>
		<!--- /end product associations --->
	</cfif>

	<!--- CUSTOMER ID --->
	<cfif matchStatus neq 'false' and arguments.customer_id neq 0 and len(trim(arguments.customer_id))
			and len(trim(discountQuery.discount_customer_id))  and discountQuery.discount_filter_customer_id eq 1>
		<cfset customerIdList = replace(discountQuery.discount_customer_id,' ','','all')>
		<cfif not listFind(customeridlist,arguments.customer_id)>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Discount not available for current customer'>
		</cfif>
	<!--- if no customer id provided, return false if filtered by id --->
	<cfelseif matchStatus neq 'false' and discountQuery.discount_filter_customer_id eq 1>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Customer ID not matched. Create an account to use this discount'>
	</cfif>

	<!--- CUSTOMER TYPE --->
	<cfif matchStatus neq 'false' and arguments.customer_type neq 0 and len(trim(arguments.customer_type))
			and len(trim(discountQuery.discount_customer_type)) and discountQuery.discount_filter_customer_type eq 1>
		<cfset customerTypeList = replace(discountQuery.discount_customer_type,' ','','all')>
		<cfif not listFind(customerTypeList,arguments.customer_type)>
				<cfset matchStatus = false>
				<cfset matchResponse = 'Discount not available for current customer type'>
		</cfif>
	<!--- if no customer type provided, return false if filtered by type --->
	<cfelseif discountQuery.discount_filter_customer_type eq 1>
				<cfset matchStatus = false>
				<cfset matchResponse = 'Customer type not matched. Create an account to use this discount'>
	</cfif>


	<!--- DISCOUNT LIMIT (past usage) --->
	<cfif matchStatus neq 'false' and discountQuery.discount_limit neq 0>
		<!--- function returns number of times  --->
		<cfset discountUsedCt = cwGetDiscountUsage(discountQuery.discount_id)>
		<cfif discountQuery.discount_limit lte discountUsedCt>
				<cfset matchStatus = false>
				<cfset matchResponse = 'Discount limited use has expired'>
		</cfif>
	</cfif>

	<!--- CUSTOMER DISCOUNT LIMIT (past usage) --->
	<cfif matchStatus neq 'false' and discountQuery.discount_customer_limit neq 0 and application.cw.customerAccountEnabled>
		<!--- if this is a limited use discount, we must have a customer id --->
		<cfif len(trim(arguments.customer_id)) AND arguments.customer_id neq 0>
			<cfset customerUsedCt = cwGetDiscountCustomerUsage(discountQuery.discount_id,arguments.customer_id)>
			<cfif discountQuery.discount_customer_limit lte customerUsedCt>
					<cfset matchStatus = false>
					<cfset matchResponse = 'Discount has been used maximum number of times by current customer'>
			</cfif>
		<!--- if no customer id available, cannot be used --->
		<cfelse>
				<cfset matchStatus = false>
				<cfset matchResponse = 'Log in or create an account to use this discount'>
		</cfif>
	</cfif>

	<!--- CART TOTAL --->
	<cfif matchStatus neq 'false' and carttotal gt 0 and discountQuery.discount_filter_cart_total eq 1>
		<cfif carttotal lt discountQuery.discount_cart_total_min>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Add #lsCurrencyFormat(discountQuery.discount_cart_total_min - carttotal,'local')# to your cart to activate this discount'>
		<cfelseif discountQuery.discount_cart_total_max neq 0
				AND carttotal gt discountQuery.discount_cart_total_max>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Discount only available for orders up to #lsCurrencyFormat(discountQuery.discount_cart_total_max,'local')#'>
		</cfif>
	</cfif>

	<!--- CART QTY --->
	<cfif matchStatus neq 'false' and cartqty gt 0 and discountQuery.discount_filter_cart_qty eq 1>
		<cfif cartqty lt discountQuery.discount_cart_qty_min>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Add #discountQuery.discount_cart_qty_min - cartqty# more item(s) to your cart to activate this discount'>
		<cfelseif discountQuery.discount_filter_cart_qty neq 0
			AND cartqty gt discountQuery.discount_cart_qty_max>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Only available for orders containing #discountQuery.discount_cart_qty_max# or fewer items'>
		</cfif>
	</cfif>

	<!--- EXCLUSIVE DISCOUNTS: set match for all others to false --->
	<!--- if any discount is exclusive (should catch first matching record, see 'sort by' in discountsQuery)--->
	<!--- NOTE: THIS MUST REMAIN LAST, at the end of filter selections --->
	<cfif matchStatus neq 'false' AND discountQuery.discount_exclusive is 1>
		<cfset exclusiveFound = true >
		<cfset exclusiveFoundName = discountQuery.discount_name>
	</cfif>

	<!--- if discount is a match, calculate amount, set status--->
	<cfif matchStatus neq 'false'>
		<cfset matchStatus = true>

		<!--- PERCENTAGE --->
		<cfif discountQuery.discount_calc is 'percent'>
			<cfset matchPercent = discountQuery.discount_amount>
			<cfset matchAmount = 0>
		<!--- FIXED COST --->
		<cfelse>
			<cfset matchPercent = 0>
			<cfset matchAmount = discountQuery.discount_amount>
		</cfif>
		<!--- /end percentage or fixed --->
	<!--- if no match, all values 0 --->
	<cfelse>
		<cfset matchPercent = 0>
		<cfset matchAmount = 0>
	</cfif>
	<!--- /end if match --->

	<!--- add values to current record --->
	<cfset responseStruct.discount_match_response = matchresponse>
	<cfset responseStruct.discount_match_status = matchStatus>
	<cfset responseStruct.discount_amount = matchamount>
	<cfset responseStruct.discount_percent = matchpercent>

	<!--- add current record data to the structure being returned --->
	<cfif arguments.return_rejects is true OR matchStatus is true>
		<cfset rowCt = rowCt + 1>
		<cfset discountdata.discountResponse[rowCt] = responseStruct>
	</cfif>

</cfoutput>
<!--- /end loop discount query --->

<cfreturn discountData>

</cffunction>

<!--- // ---------- // Get shipping discount totals for any cart // ---------- // --->
<cffunction name="CWgetShipDiscountTotals"
			access="public"
			output="false"
			returntype="struct"
			hint="Returns a structure of totals for all available shipping discounts on any cart"
			>

	<cfargument name="cart"
			required="true"
			type="struct"
			hint="cart structure">

	<cfargument name="customer_id"
			required="false"
			default="0"
			type="string"
			hint="A single customer ID (0 or '' = don't check)">

	<cfargument name="customer_type"
			required="false"
			default="0"
			type="string"
			hint="A numeric customer type id (0 or '' = don't check)">

	<cfargument name="promo_code"
			required="false"
			default=""
			type="string"
			hint="the code(s) being used by the customer to invoke the discount(s) - delimited list with ^ separator">

	<cfargument name="compare_date"
			required="false"
			default="#cwtime()#"
			type="date"
			hint="the date to compare the discount to, default is current time (cannot be blank, must be a valid date format)">

<cfset var discountData = structNew()>
<cfset var responseData = structNew()>
<cfset var discountItem = structNew()>
<cfset var discountTotals = structNew()>
<cfset var discountAmount = 0>
<cfset var discountPercent = 0>
<cfset var discountID = ''>
<cfset discountData.discountresponse = structNew()>
<cfset discountTotals.amount = 0>
<cfset discountTotals.percent = 0>
<cfset discountTotals.id = ''>

<!--- get all matching discounts --->
<cfset discountData = CWgetShipDiscountData(
						cart=arguments.cart,
						customer_id=arguments.customer_id,
						customer_type=arguments.customer_type,
						promo_code=arguments.promo_code,
						compare_date=arguments.compare_date,
						return_rejects=false
						)
						>

<cfif structKeyExists(discountData,'discountResponse')>
	<cfset responseData = discountData.discountResponse>
</cfif>

<!--- loop the discount data --->
<cfloop collection="#responseData#" item="i">

	<!--- get needed info about this discount --->
	<cfset discountItem = evaluate('responseData.#i#')>
	<cfset discountPercent = discountItem.discount_percent>
	<cfset discountAmount = discountItem.discount_amount>
	<cfset discountID = discountItem.discount_id>

	<!--- sum totals, percentages --->
	<cfset discountTotals.amount = discountTotals.amount + discountAmount>
	<cfset discountTotals.percent = discountTotals.percent + discountPercent>

	<!--- return list of matching discount IDs --->
	<cfset discountTotals.ID = listAppend(discountTotals.ID,discountID)>

</cfloop>

<!--- percent cannot be over 100 --->
<cfif discountTotals.percent gt 100>
	<cfset discountTotals.percent eq 100>
</cfif>

<cfreturn discountTotals>

</cffunction>

<!--- // ---------- // Get shipping discount amount for any cart // ---------- // --->
<cffunction name="CWgetShipDiscountAmount"
			access="public"
			output="false"
			returntype="numeric"
			hint="Returns a numeric discount amount via CWgetShipDiscountTotals"
			>

	<cfargument name="cart"
			required="false"
			default="0"
			type="struct"
			hint="cart object">

	<cfargument name="customer_id"
			required="false"
			default="0"
			type="string"
			hint="A single customer ID (0 or '' = don't check)">

	<cfargument name="customer_type"
			required="false"
			default="0"
			type="string"
			hint="A numeric customer type id (0 or '' = don't check)">

	<cfargument name="promo_code"
			required="false"
			default=""
			type="string"
			hint="the code(s) being used by the customer to invoke the discount(s) - delimited list with ^ separator">

	<cfargument name="compare_date"
			required="false"
			default="#cwtime()#"
			type="date"
			hint="the date to compare the discount to, default is current time (cannot be blank, must be a valid date format)">

	<cfset var discountAmount = 0>

	<cfset discountData = CWgetShipDiscountTotals(
			cart=arguments.cart,
			customer_id=arguments.customer_id,
			customer_type=arguments.customer_type,
			promo_code=arguments.promo_code,
			compare_date=arguments.compare_date
			)>

		<cfif isNumeric(discountData.amount)>
			<cfset discountAmount = discountData.amount>
		</cfif>

	<cfreturn discountAmount>

</cffunction>

<!--- // ---------- // Get discounts applicable to any sku // ---------- // --->
<cffunction name="CWgetSkuDiscountData"
			access="public"
			output="false"
			returntype="struct"
			hint="Returns a structure of information when attempting to apply discount(s) to a sku.
			      Each discount either has an amount and/or percentage, or is rejected with a text response."
			>
<!---
NOTES:

Quantity is provided to check for discount requirements - the currency amount of the discount is only calculated for a single item.

The discount matching selections are processed in the order they appear in the code.
The first filter to cause a rejection will prevent any further checks,
and will return an error message specific to that rejection.
To change the priority of the filtering and response messages,
the order of the filter checks may be rearranged below.
Exclusive discount checking should be left last.
--->

	<cfargument name="sku_id"
			required="true"
			type="numeric"
			hint="ID of sku">

	<cfargument name="discount_type"
			required="false"
			default="sku_cost"
			type="string"
			hint="can be 'sku_cost' or 'sku_ship' to match cost or shipping types">

	<cfargument name="sku_qty"
			required="false"
			default="0"
			type="numeric"
			hint="quantity of the sku being purchased (0 = don't check)">

	<cfargument name="cart_qty"
			required="false"
			default="0"
			type="numeric"
			hint="total quantity of items in cart, used for discount filtering (0 = don't check)">

	<cfargument name="order_total"
			required="false"
			default="0"
			type="numeric"
			hint="total of order before discounts, used for discount filtering (0 = don't check)">

	<cfargument name="customer_id"
			required="false"
			default="0"
			type="string"
			hint="A single customer ID (0 or '' = don't check)">

	<cfargument name="customer_type"
			required="false"
			default="0"
			type="string"
			hint="A numeric customer type id (0 or '' = don't check)">

	<cfargument name="promo_code"
			required="false"
			default=""
			type="string"
			hint="the code(s) being used by the customer to invoke the discount(s) - delimited list with ^ separator">

	<cfargument name="compare_date"
			required="false"
			default="#cwtime()#"
			type="date"
			hint="the date to compare the discount to, default is current time (cannot be blank, must be a valid date format)">

	<cfargument name="return_rejects"
			required="false"
			default="true"
			type="boolean"
			hint="If true, this function will return any non-matching active discounts, with the rejection reason for each">

	<cfargument name="discount_id"
			required="true"
			default="0"
			type="numeric"
			hint="Id of the discount to look up">

	<cfset var discountQuery = ''>
	<cfset var skuQuery = ''>
	<cfset var discountData = structNew()>
	<cfset var responseStruct = structNew()>
	<cfset var matchStatus = ''>
	<cfset var matchResponse = ''>
	<cfset var matchAmount = 0>
	<cfset var matchPercent= 0>
	<cfset var exclusiveFound = false>
	<cfset var exclusiveFoundName = ''>
	<cfset var matchQuery = ''>
	<cfset var catsQuery = ''>
	<cfset var scndCatsQuery = ''>
	<cfset var parentProductID = ''>
	<cfset var discountUsedCt = ''>
	<cfset var customerUsedCt = ''>
	<cfset var rowCt = 0>
	<cfset var catList = 0>
	<cfset var scndcatList = 0>

<!--- QUERY: get details about sku --->
<cfset skuQuery = CWquerySkuDetails(arguments.sku_id)>
<!--- If no ID provided, get ALL POSSIBLE MATCHES - stored in application memory on first run --->
	<cfif arguments.discount_id eq 0>
		<!--- get all active discounts --->
		<cfset discountQuery = CWgetDiscountData()>
	<!--- if id provided, get only this discount --->
	<cfelse>
		<cfset discountQuery = CWgetDiscountData(discount_id=arguments.discount_id)>
	</cfif>
	<!--- /// /// --->
	<!--- /// START DISCOUNT FILTERS /// --->
	<!--- /// /// --->

<!--- loop matching discounts, comparing each, returning OK message or reason for rejection --->
<cfoutput query="discountQuery">
	<cfset responseStruct = structNew()>
	<cfset matchStatus = ''>
	<cfset matchResponse = ''>

	<!--- match discount type --->
	<cfif trim(discountQuery.discount_type) is not trim(arguments.discount_type)>
		<cfset matchStatus = false>
		<cfset matchResponse = 'Discount type #discountQuery.discount_type# not applicable'>
		<!--- if an exclusive match has already been found, all others are set to false --->
	<cfelseif exclusiveFound is true>
		<cfset matchStatus = false>
		<cfset matchResponse = 'Exclusive discount #exclusiveFoundName# cannot be used with other offers'>
	</cfif>

	<!--- add fixed values into response --->
	<cfset responseStruct.discount_id = discountQuery.discount_id>
	<cfset responseStruct.discount_merchant_id = discountQuery.discount_merchant_id>
	<cfset responseStruct.discount_name = discountQuery.discount_name>
	<cfset responseStruct.discount_promotional_code = discountQuery.discount_promotional_code>
	<cfset responseStruct.discount_exclusive = discountQuery.discount_exclusive>
	<cfset responseStruct.discount_priority = discountQuery.discount_priority>
	<cfset responseStruct.discount_type = discountQuery.discount_type>
	<!--- get conditional values (global discount, show description y/n) --->
	<cfif discountQuery.discount_show_description>
		<cfset responseStruct.discount_description = discountQuery.discount_description>
	<cfelse>
		<cfset responseStruct.discount_description = ''>
	</cfif>
	<cfif discountQuery.discount_global>
		<cfset responseStruct.association_method = "global">
	<cfelse>
		<cfset responseStruct.association_method = discountQuery.discount_association_method>
	</cfif>

	<!--- SET DISCOUNT TOTALS: get or create remaining values - amount, percent, response message --->

	<!--- PROMO CODE: check for matching string --->
	<cfif matchStatus neq 'false' and
			len(trim(discountQuery.discount_promotional_code))>
		<!--- if not found in the list, and not a direct match --->
		<cfif not listFind(arguments.promo_code,discountQuery.discount_promotional_code,'^')
		AND trim(discountQuery.discount_promotional_code) is not trim(arguments.promo_code)>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Promo code #trim(arguments.promo_code)# not matched'>
		</cfif>
	</cfif>

	<!--- DATE: start/stop dates --->
	<cfif matchStatus neq 'false'>
		<cfif not(discount_start_date lte arguments.compare_date
				AND (discount_end_date is ''
					OR dateAdd('d',1,discount_end_date) gte arguments.compare_date))>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Discount not currently available'>
		</cfif>
	</cfif>

	<!--- PRODUCT ASSOCIATIONS --->
	<!--- if not global, check matching records (sku, product, category association methods) --->
	<cfif matchStatus neq 'false' and discountQuery.discount_global neq 1>

			<cfswitch expression="#discountQuery.discount_association_method#">

				<!--- PRODUCTS: get product sku belongs to, check for match --->
				<cfcase value="products">
					<cfquery name="matchQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
					SELECT discount2product_discount_id
					FROM cw_discount_products
					WHERE discount2product_product_id = <cfqueryparam value="#skuQuery.sku_product_id#" cfsqltype="cf_sql_numeric">
					AND discount2product_discount_id = <cfqueryparam value="#discountQuery.discount_id#" cfsqltype="cf_sql_integer">
					</cfquery>
					<cfif not matchQuery.recordCount>
						<cfset matchStatus = false>
						<cfset matchResponse = 'Discount does not apply to selected item'>
					</cfif>
				</cfcase>

				<!--- SKUS: straight match by sku id --->
				<cfcase value="skus">
					<cfquery name="matchQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
					SELECT discount2sku_discount_id
					FROM cw_discount_skus
					WHERE discount2sku_sku_id = <cfqueryparam value="#arguments.sku_id#" cfsqltype="cf_sql_numeric">
					AND discount2sku_discount_id = <cfqueryparam value="#discountQuery.discount_id#" cfsqltype="cf_sql_integer">
					</cfquery>
					<cfif not matchQuery.recordCount>
						<cfset matchStatus = false>
						<cfset matchResponse = 'Discount does not apply to selected item'>
					</cfif>
				</cfcase>

				<!--- CATEGORIES: get categories & secondaries the sku's parent product belongs to, check for match --->
				<cfcase value="categories">
					<!--- QUERY: get categories for this product --->
					<cfset catsQuery = CWquerySelectRelCategories(skuQuery.sku_product_id)>
					<cfset scndcatsQuery = CWquerySelectRelScndCategories(skuQuery.sku_product_id)>
					<!--- set values into matching lists if found --->
					<cfif listLen(valueList(catsQuery.category_id))>
						<cfset catList = valueList(catsQuery.category_id)>
					</cfif>
					<cfif listLen(valueList(scndCatsQuery.secondary_id))>
						<cfset scndcatList = valueList(scndCatsQuery.secondary_id)>
					</cfif>
					<!--- check for match by type and id --->
					<cfquery name="matchQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
					SELECT discount_category_id
					FROM cw_discount_categories
					WHERE discount2category_discount_id = <cfqueryparam value="#discountQuery.discount_id#" cfsqltype="cf_sql_integer">
					AND ((
						discount_category_type = 1
						AND discount2category_category_id in(#catList#)
						) OR (
						discount_category_type = 2
						AND discount2category_category_id in(#scndcatList#)
					))
					</cfquery>
					<cfif not matchQuery.recordCount>
						<cfset matchStatus = false>
						<cfset matchResponse = 'Discount does not apply to selected item'>
					</cfif>
				</cfcase>

			</cfswitch>
	</cfif>
	<!--- /end product associations --->

	<!--- CUSTOMER ID --->
	<cfif matchStatus neq 'false' and arguments.customer_id neq 0 and len(trim(arguments.customer_id))
			and len(trim(discountQuery.discount_customer_id)) and discountQuery.discount_filter_customer_id eq 1>
		<cfset customerIdList = replace(discountQuery.discount_customer_id,' ','','all')>
		<cfif not listFind(customeridlist,arguments.customer_id)>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Discount not available for current customer'>
		</cfif>
	<!--- if no customer id provided, return false if filtered by id --->
	<cfelseif matchStatus neq 'false' and discountQuery.discount_filter_customer_id eq 1>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Customer ID not matched. Create an account to use this discount'>
	</cfif>

	<!--- CUSTOMER TYPE --->
	<cfif matchStatus neq 'false' and arguments.customer_type neq 0 and len(trim(arguments.customer_type))
			and len(trim(discountQuery.discount_customer_type)) and discountQuery.discount_filter_customer_type eq 1>
		<cfset customerTypeList = replace(discountQuery.discount_customer_type,' ','','all')>
		<cfif not listFind(customerTypeList,arguments.customer_type)>
				<cfset matchStatus = false>
				<cfset matchResponse = 'Discount not available for current customer type'>
		</cfif>
	<!--- if no customer type provided, return false if filtered by type --->
	<cfelseif matchStatus neq 'false' and discountQuery.discount_filter_customer_type eq 1>
				<cfset matchStatus = false>
				<cfset matchResponse = 'Customer type not matched. Create an account to use this discount'>
	</cfif>

	<!--- DISCOUNT LIMIT (past usage) --->
	<cfif matchStatus neq 'false' and discountQuery.discount_limit neq 0>
		<!--- function returns number of times  --->
		<cfset discountUsedCt = cwGetDiscountUsage(discountQuery.discount_id)>
		<cfif discountQuery.discount_limit lte discountUsedCt>
				<cfset matchStatus = false>
				<cfset matchResponse = 'Discount limited use has expired'>
		</cfif>
	</cfif>

	<!--- CUSTOMER DISCOUNT LIMIT (past usage) --->
	<cfif matchStatus neq 'false' and discountQuery.discount_customer_limit neq 0 and application.cw.customerAccountEnabled>
		<!--- if this is a limited use discount, we must have a customer id --->
		<cfif len(trim(arguments.customer_id)) AND arguments.customer_id neq 0>
			<cfset customerUsedCt = cwGetDiscountCustomerUsage(discountQuery.discount_id,arguments.customer_id)>
			<cfif discountQuery.discount_customer_limit lte customerUsedCt>
					<cfset matchStatus = false>
					<cfset matchResponse = 'Discount has been used maximum number of times by current customer'>
			</cfif>
		<!--- if no customer id available, cannot be used --->
		<cfelse>
				<cfset matchStatus = false>
				<cfset matchResponse = 'Log in or create an account to use this discount'>
		</cfif>
	</cfif>

	<!--- CART TOTAL --->
	<cfif matchStatus neq 'false' and arguments.order_total gt 0 and discountQuery.discount_filter_cart_total eq 1>
		<cfif arguments.order_total lt discountQuery.discount_cart_total_min>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Add #lsCurrencyFormat(discountQuery.discount_cart_total_min - arguments.order_total,'local')# to your cart to activate this discount'>
		<cfelseif discountQuery.discount_cart_total_max neq 0
				AND arguments.order_total gt discountQuery.discount_cart_total_max>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Discount only available for orders up to #lsCurrencyFormat(discountQuery.discount_cart_total_max,'local')#'>
		</cfif>
	<!--- if cart total is 0 (general product discount lookup), return false against any required quantity --->
	<cfelseif matchStatus neq 'false' and arguments.order_total eq 0 and discountQuery.discount_filter_cart_total eq 1>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Add #lsCurrencyFormat(discountQuery.discount_cart_total_min,'local')# to your cart to activate this discount'>
	</cfif>

	<!--- ITEM QTY --->
	<cfif matchStatus neq 'false' and arguments.sku_qty gt 0 and discountQuery.discount_filter_item_qty eq 1>
		<cfif arguments.sku_qty lt discountQuery.discount_item_qty_min>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Add #discountQuery.discount_item_qty_min - arguments.sku_qty# more of this item to your cart to activate this discount'>
		<cfelseif discountQuery.discount_filter_item_qty neq 0
			AND arguments.sku_qty gt discountQuery.discount_item_qty_max>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Only available for quantities of #discountQuery.discount_item_qty_max# or less'>
		</cfif>
	<!--- if quantity is 0 (general product discount lookup), return false against any required quantity --->
	<cfelseif matchStatus neq 'false' and arguments.sku_qty eq 0 and discountQuery.discount_filter_item_qty eq 1>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Add #discountQuery.discount_item_qty_min# of this item to your cart to activate this discount'>
	</cfif>

	<!--- CART QTY --->
	<cfif matchStatus neq 'false' and arguments.cart_qty gt 0 and discountQuery.discount_filter_cart_qty eq 1>
		<cfif arguments.cart_qty lt discountQuery.discount_cart_qty_min>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Add #discountQuery.discount_cart_qty_min - arguments.cart_qty# more item(s) to your cart to activate this discount'>
		<cfelseif discountQuery.discount_filter_cart_qty neq 0
			AND arguments.cart_qty gt discountQuery.discount_cart_qty_max>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Only available for orders containing #discountQuery.discount_cart_qty_max# or fewer items'>
		</cfif>
	<!--- if quantity is 0 (general product discount lookup), return false against any required quantity --->
	<cfelseif matchStatus neq 'false' and arguments.cart_qty eq 0 and discountQuery.discount_filter_cart_qty eq 1>
			<cfset matchStatus = false>
			<cfset matchResponse = 'Add #discountQuery.discount_cart_qty_min# item(s) to your cart to activate this discount'>
	</cfif>

	<!--- EXCLUSIVE DISCOUNTS: set match for all others to false --->
	<!--- if any discount is exclusive (should catch first matching record, see 'sort by' in discountsQuery)--->
	<!--- NOTE: THIS MUST REMAIN LAST, at the end of filter selections --->
	<cfif matchStatus neq 'false' AND discountQuery.discount_exclusive is 1>
		<cfset exclusiveFound = true >
		<cfset exclusiveFoundName = discountQuery.discount_name>
	</cfif>

	<!--- if discount is a match, calculate amount, set status--->
	<cfif matchStatus neq 'false'>
		<cfset matchStatus = true>

		<!--- PERCENTAGE --->
		<!--- set base 0 for shipping percentage --->
		<cfif discountQuery.discount_type is 'sku_ship'
			and discountQuery.discount_calc is 'percent'>
			<cfset matchPercent = discountQuery.discount_amount>
			<cfset matchAmount = 0>
		<cfelseif discountQuery.discount_type is 'sku_cost'
			and discountQuery.discount_calc is 'percent'>
			<cfset matchPercent = discountQuery.discount_amount>
			<cfset matchAmount = min(skuQuery.sku_price,round((skuQuery.sku_price * discountQuery.discount_amount/100)*100)/100)>
		<!--- FIXED COST --->
		<cfelse>
			<cfset matchPercent = 0>
			<cfset matchAmount = min(skuQuery.sku_price,discountQuery.discount_amount)>
		</cfif>
		<!--- /end percentage or fixed --->
	<!--- if no match, all values 0 --->
	<cfelse>
		<cfset matchPercent = 0>
		<cfset matchAmount = 0>
	</cfif>
	<!--- /end if match --->

	<!--- add values to current record --->
	<cfset responseStruct.discount_match_response = matchresponse>
	<cfset responseStruct.discount_match_status = matchStatus>
	<cfset responseStruct.discount_amount = matchamount>
	<cfset responseStruct.discount_percent = matchpercent>

	<!--- add current record data to the structure being returned --->
	<cfif arguments.return_rejects is true OR matchStatus is true>
		<cfset rowCt = rowCt + 1>
		<cfset discountdata.discountResponse[rowCt] = responseStruct>
	</cfif>

</cfoutput>
<!--- /end loop discount query --->

<cfreturn discountData>

</cffunction>

<!--- // ---------- // Get discount data for any sku // ---------- // --->
<cffunction name="CWgetSkuDiscountTotals"
			access="public"
			output="false"
			returntype="struct"
			hint="Returns a structure of totals for all available discounts on any specific sku"
			>

	<cfargument name="sku_id"
			required="true"
			type="numeric"
			hint="ID of sku">

	<cfargument name="discount_type"
			required="false"
			default="sku_cost"
			type="string"
			hint="can be 'sku_cost' or 'sku_ship' to match cost or shipping types">

	<cfargument name="sku_qty"
			required="false"
			default="0"
			type="numeric"
			hint="quantity of the sku being purchased (0 = don't check)">

	<cfargument name="cart_qty"
			required="false"
			default="0"
			type="numeric"
			hint="total quantity of items in cart, used for discount filtering (0 = don't check)">

	<cfargument name="order_total"
			required="false"
			default="0"
			type="numeric"
			hint="total of order before discounts, used for discount filtering (0 = don't check)">

	<cfargument name="customer_id"
			required="false"
			default="0"
			type="string"
			hint="A single customer ID (0 or '' = don't check)">

	<cfargument name="customer_type"
			required="false"
			default="0"
			type="string"
			hint="A numeric customer type id (0 or '' = don't check)">

	<cfargument name="promo_code"
			required="false"
			default=""
			type="string"
			hint="the code(s) being used by the customer to invoke the discount(s) - delimited list with ^ separator">

	<cfargument name="compare_date"
			required="false"
			default="#cwtime()#"
			type="date"
			hint="the date to compare the discount to, default is current time (cannot be blank, must be a valid date format)">

	<cfset var discountData = structNew()>
	<cfset var responseData = structNew()>
	<cfset var discountItem = structNew()>
	<cfset var discountTotals = structNew()>
	<cfset var discountAmount = 0>
	<cfset var discountPercent = 0>
	<cfset var discountID = ''>
	<cfset var skuQuery = ''>
	<cfset discountData.discountresponse = structNew()>
	<cfset discountTotals.amount = 0>
	<cfset discountTotals.percent = 0>
	<cfset discountTotals.id = ''>

<!--- QUERY: get details about sku --->
<cfset skuQuery = CWquerySkuDetails(arguments.sku_id)>

<!--- get all matching discounts --->
<cfset discountData = CWgetSkuDiscountData(
						sku_id=arguments.sku_id,
						discount_type=arguments.discount_type,
						sku_qty=arguments.sku_qty,
						cart_qty=arguments.cart_qty,
						order_total=arguments.order_total,
						customer_id=arguments.customer_id,
						customer_type=arguments.customer_type,
						promo_code=arguments.promo_code,
						compare_date=arguments.compare_date,
						return_rejects=false
						)>

<cfif structKeyExists(discountData,'discountResponse')>
	<cfset responseData = discountData.discountResponse>
</cfif>

<!--- loop the discount data --->
<cfloop collection="#responseData#" item="i">

	<!--- get needed info about this discount --->
	<cfset discountItem = evaluate('responseData.#i#')>
	<cfset discountPercent = discountItem.discount_percent>
	<cfset discountAmount = discountItem.discount_amount>
	<cfset discountID = discountItem.discount_id>
	<!--- sum totals, percentages --->
	<cfset discountTotals.amount = discountTotals.amount + discountAmount>
	<cfset discountTotals.percent = discountTotals.percent + discountPercent>

	<!--- amount cannot be higher than sku cost --->
	<cfif arguments.discount_type is 'sku_cost'
			AND skuQuery.sku_price gt 0
			AND discountTotals.amount gt skuQuery.sku_price>
		<cfset discountTotals.amount = skuQuery.sku_price>
	<!--- for sku_ship, only 100% of amount is allowed (deducted from ship range calculation) --->
	<cfelseif arguments.discount_type is 'sku_ship'>
		<cfset discountTotals.amount = skuQuery.sku_price>
	</cfif>

	<!--- return list of matching discount IDs --->
	<cfset discountTotals.ID = listAppend(discountTotals.ID,discountID)>

</cfloop>

<!--- percent cannot be over 100 --->
<cfif discountTotals.percent gt 100>
	<cfset discountTotals.percent eq 100>
</cfif>

<cfreturn discountTotals>

</cffunction>

<!--- // ---------- // Get discount amount for any sku // ---------- // --->
<cffunction name="CWgetSkuDiscountAmount"
			access="public"
			output="false"
			returntype="numeric"
			hint="Returns a numeric discount amount via CWgetSkuDiscountTotals"
			>

	<cfargument name="sku_id"
			required="true"
			type="numeric"
			hint="ID of sku">

	<cfargument name="discount_type"
			required="false"
			default="sku_cost"
			type="string"
			hint="can be 'sku_cost' or 'sku_ship' to match cost or shipping types">

	<cfargument name="sku_qty"
			required="false"
			default="0"
			type="numeric"
			hint="quantity of the sku being purchased (0 = don't check)">

	<cfargument name="cart_qty"
			required="false"
			default="0"
			type="numeric"
			hint="total quantity of items in cart, used for discount filtering (0 = don't check)">

	<cfargument name="order_total"
			required="false"
			default="0"
			type="numeric"
			hint="total of order before discounts, used for discount filtering (0 = don't check)">

	<cfargument name="customer_id"
			required="false"
			default="0"
			type="string"
			hint="A single customer ID (0 or '' = don't check)">

	<cfargument name="customer_type"
			required="false"
			default="0"
			type="string"
			hint="A numeric customer type id (0 or '' = don't check)">

	<cfargument name="promo_code"
			required="false"
			default=""
			type="string"
			hint="the code(s) being used by the customer to invoke the discount(s) - delimited list with ^ separator">

	<cfargument name="compare_date"
			required="false"
			default="#cwtime()#"
			type="date"
			hint="the date to compare the discount to, default is current time (cannot be blank, must be a valid date format)">

	<cfset var discountAmount = 0>

	<cfset discountData = CWgetSkuDiscountTotals(
			sku_id=arguments.sku_id,
			discount_type=arguments.discount_type,
			sku_qty=arguments.sku_qty,
			cart_qty=arguments.cart_qty,
			order_total=arguments.order_total,
			customer_id=arguments.customer_id,
			customer_type=arguments.customer_type,
			promo_code=arguments.promo_code,
			compare_date=arguments.compare_date
			)>

		<cfif isNumeric(discountData.amount)>
			<cfset discountAmount = discountData.amount>
		</cfif>

	<cfreturn discountAmount>

</cffunction>

<!--- // ---------- // Get discount usage count // ---------- // --->
<cffunction name="CWgetDiscountUsage"
			access="public"
			output="false"
			returntype="numeric"
			hint="Returns the number of times a discount has been used"
			>

	<cfargument name="discount_id"
		required="true"
		default="0"
		type="numeric"
		hint="Id of the discount to look up">

		<cfset var discountCt = 0>
		<cfset var prodQuery = ''>

	<cfquery name="prodQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT discount_usage_discount_id
	FROM cw_discount_usage
	WHERE discount_usage_discount_id = #arguments.discount_id#
	</cfquery>
	<cfset discountCt = prodQuery.recordCount>

	<cfreturn discountCt>

</cffunction>

<!--- // ---------- // Get discount usage count per customer // ---------- // --->
<cffunction name="CWgetDiscountCustomerUsage"
			access="public"
			output="false"
			returntype="numeric"
			hint="Returns the number of times a discount has been used"
			>

	<cfargument name="discount_id"
		required="true"
		default=""
		type="numeric"
		hint="Id of the discount to look up">

	<cfargument name="customer_id"
		required="true"
		default=""
		type="string"
		hint="Id of the customer to look up">

		<cfset var discountCt = 0>
		<cfset var prodQuery = ''>

	<cfquery name="prodQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT discount_usage_discount_id
	FROM cw_discount_usage
	WHERE discount_usage_discount_id = #arguments.discount_id#
	AND discount_usage_customer_id = '#arguments.customer_id#'
	</cfquery>
	<cfset discountCt = prodQuery.recordCount>

	<cfreturn discountCt>

</cffunction>

<!--- // ---------- // Get discount usage by order ID // ---------- // --->
<cffunction name="CWgetOrderDiscounts"
			access="public"
			output="false"
			returntype="query"
			hint="Returns a query of discounts used for any order"
			>

	<cfargument name="order_id" required="true" default="0" type="string"
				hint="ID of order to look up">

	<cfset var discountsQuery = ''>

	<cfquery name="discountsQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT *
	FROM cw_discount_usage
	WHERE discount_usage_order_id = '#trim(arguments.order_id)#'
	</cfquery>

	<cfreturn discountsQuery>

</cffunction>

<!--- // ---------- // Match a single promo code to a customer's cart // ---------- // --->
<cffunction name="CWmatchPromoCode"
			access="public"
			output="false"
			returntype="struct"
			hint="match a promo code discount, returns a structure of details about the discount if matched"
			>

	<cfargument name="promo_code"
			required="true"
			default=""
			type="string"
			hint="a single promo code being used by the customer to invoke the discount">

	<cfargument name="cart"
			required="true"
			type="struct"
			hint="cart structure">

	<cfargument name="customer_id"
			required="false"
			default="0"
			type="string"
			hint="A single customer ID (0 or '' = don't check)">

	<cfargument name="set_promocode_session"
			required="false"
			default="true"
			type="boolean"
			hint="if true, and promo code is matched, sets session variable with promocode id">

	<!--- once status is true, a match is found, all others are skipped --->
	<cfset var matchStatus = false>
	<cfset var matchData = structNew()>
	<cfset var cartTotal = 0>
	<cfset var cartQty = 0>
	<cfset var promoQuery = ''>
	<cfset var promoType = ''>
	<cfset var promoID = 0>

	<!--- get actual totals from cart data --->
	<cfif isDefined('arguments.cart.carttotals.sub')>
		<cfset cartTotal = arguments.cart.carttotals.sub>
	</cfif>
	<cfif isDefined('arguments.cart.carttotals.skucount')>
		<cfset cartQty = arguments.cart.carttotals.skucount>
	</cfif>
	<!--- only run if promo_code is not null  --->
	<cfif len(trim(arguments.promo_code))>
		<!--- remove default promo delimiter to avoid submitting a list of codes --->
		<cfset arguments.promo_code = replace(arguments.promo_code,"^"," ","all")>
		<!--- get information about the discount by promocode --->
		<cfset promoQuery = CWgetDiscountbyPromoCode(trim(arguments.promo_code))>
		<cfset promoID = promoquery.discount_id>
		<cfset promoType = promoquery.discount_type>

		<!--- check for cart discounts --->
		<cfif promoType eq 'order_total' AND not matchStatus eq true>

			<cfset discountData = CWgetCartDiscountData(
									cart=arguments.cart,
									customer_id=arguments.customer_id,
									promo_code=arguments.promo_code,
									discount_id=promoID
									)
									>
				<!--- if a match is found --->
				<cfif structKeyExists(discountData,'discountResponse')>
					<cfset matchData = discountData.discountResponse[1]>
					<cfif isDefined('matchData.discount_match_status') and matchData.discount_match_status is true>
						<cfset matchStatus = true>
					</cfif>
				</cfif>
		</cfif>
		<!--- /end cart discounts --->

		<!--- check for shipping discounts --->
		<cfif promoType eq 'ship_total' AND not matchStatus eq true>
			<cfset discountData = CWgetShipDiscountData(
									cart=arguments.cart,
									customer_id=arguments.customer_id,
									promo_code=arguments.promo_code,
									discount_id=promoID
									)
									>

				<!--- if a match is found --->
				<cfif structKeyExists(discountData,'discountResponse')>
					<cfset matchData = discountData.discountResponse[1]>
					<cfset matchStatus = matchData.discount_match_status>
				</cfif>
		</cfif>
		<!--- /end ship discounts --->

		<!--- check for sku discounts --->
		<cfif promoType eq 'sku_cost' AND not matchStatus eq true>
			<!--- loop skus in provided cart structure --->
			<cfloop from="1" to="#arrayLen(arguments.cart.cartitems)#" index="i">
				<!--- get sku cost discounts --->
					<cfset discountData =  CWgetSKUDiscountData(
										discount_type='sku_cost',
										sku_id=arguments.cart.cartitems[i].skuid,
										sku_qty=arguments.cart.cartitems[i].quantity,
										cart_qty=cartQty,
										order_total=cartTotal,
										customer_id=arguments.customer_id,
										promo_code=arguments.promo_code,
										discount_id=promoID
										)>
				<!--- if a match is found --->
				<cfif structKeyExists(discountData,'discountResponse')>
					<cfset matchData = discountData.discountResponse[1]>
					<cfset matchStatus = matchData.discount_match_status>
				<cfbreak>
				</cfif>
			</cfloop>
		</cfif>

		<cfif promoType eq 'sku_ship' AND not matchStatus eq true>
			<!--- loop skus in provided cart structure --->
			<cfloop from="1" to="#arrayLen(arguments.cart.cartitems)#" index="i">
				<!--- get sku ship discounts --->
					<cfset discountData =  CWgetSKUDiscountData(
										discount_type='sku_ship',
										sku_id=arguments.cart.cartitems[i].skuid,
										sku_qty=arguments.cart.cartitems[i].quantity,
										cart_qty=cartQty,
										order_total=cartTotal,
										customer_id=arguments.customer_id,
										promo_code=arguments.promo_code,
										discount_id=promoID
										)>

				<!--- if a match is found --->
				<cfif structKeyExists(discountData,'discountResponse')>
					<cfset matchData = discountData.discountResponse[1]>
					<cfset matchStatus = matchData.discount_match_status>
				<cfbreak>
				</cfif>
			</cfloop>
		</cfif>
		<!--- /end sku discounts --->

	<!--- if matched, set into session where applicable --->
	<cfif matchStatus is true and arguments.set_promocode_session>
		<!--- if not already matched, add to list of applied discounts in user's session --->
		<cfif not listFind(session.cwclient.discountPromoCode,arguments.promo_code,'^')>
			<!--- append id to list (default delimiter) --->
			<cfset session.cwclient.discountApplied = listAppend(session.cwclient.discountApplied,promoID)>
			<!--- append string to list (^ delimiter, allows commas in strings) --->
			<cfset session.cwclient.discountPromoCode = listAppend(session.cwclient.discountPromoCode,arguments.promo_code,'^')>
		</cfif>
	</cfif>
	</cfif>
	<!--- /end promocode exists --->

	<!--- return structure of matched discount data, or rejection message --->
	<cfreturn matchData>
</cffunction>

<!--- // ---------- // CWresetSessionPromoCodes // ---------- // --->
<cffunction name="CWresetSessionPromoCodes"
			access="public"
			output="false"
			returntype="void"
			hint="verifies list of promo codes in session, resets to only current matches"
			>

	<cfargument name="promo_codes"
			required="true" 
			type="string"
			hint="list of promo codes to match">

	<cfargument name="cart"
			required="true" 
			type="struct"
			hint="cart structure">

	<cfargument name="customer_id"
			required="false"
			default="0"
			type="string"
			hint="A single customer ID (0 or '' = don't check)">
			
	<cfset var temp = structNew()>
	
	<!--- id in session sets default customer id --->	
	<cfif arguments.customer_id is 0 and isDefined('session.cwclient.cwCustomerID') and session.cwclient.cwCustomerID is not 0>
		<cfset arguments.customer_id = session.cwclient.cwCustomerID>
	</cfif>					
			
	<!--- clear any stored promo codes --->
	<cfset session.cwclient.discountApplied = ''>
	<cfset session.cwclient.discountPromoCode = ''>
	<!--- loop list of promo codes passed in --->
	<cfloop list="#arguments.promo_codes#" index="i">
		<!--- match promo codes, setting into session --->
		<cfset temp = CWmatchPromoCode(i,arguments.cart,arguments.customer_id,true)>
	</cfloop>
	
</cffunction>

<!--- // ---------- // Get discount details by promocode // ---------- // --->
<cffunction name="CWgetDiscountbyPromoCode"
			access="public"
			output="false"
			returntype="query"
			hint="returns a query of discount details"
			>

	<cfargument name="promo_code"
		required="true"
		default="-"
		type="string"
		hint="A single discount string to match">

		<cfset var discQuery = ''>

	<cfquery name="discQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT *
	FROM cw_discounts
	WHERE discount_promotional_code = '#trim(arguments.promo_code)#'
	</cfquery>

	<cfreturn discQuery>
</cffunction>

<!--- // ---------- // Get discount details by id // ---------- // --->
<cffunction name="CWgetDiscountDetails"
			access="public"
			output="false"
			returntype="query"
			hint="returns a query of discount details"
			>

	<cfargument name="discount_id"
		required="true"
		default="0"
		type="numeric"
		hint="Id of the discount to look up">

		<cfset var discQuery = ''>

	<cfquery name="discQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT discount_id, discount_name, discount_amount, discount_merchant_id,
	discount_promotional_code, discount_type, discount_show_description, discount_description
	FROM cw_discounts
	WHERE discount_id = #arguments.discount_id#
	</cfquery>

	<cfreturn discQuery>
</cffunction>

<!--- // ---------- // Get discount description by id // ---------- // --->
<cffunction name="CWgetDiscountDescription"
			access="public"
			output="false"
			returntype="string"
			hint="returns a discount description, or an empty string"
			>

	<cfargument name="discount_id"
		required="true"
		default="0"
		type="numeric"
		hint="Id of the discount to look up">

	<cfargument name="show_description"
		required="false"
		default="true"
		type="boolean"
		hint="if true, the description will be added to the discount name">

	<cfargument name="show_promocode"
		required="false"
		default="true"
		type="boolean"
		hint="if true, the name will include the promo code">

		<cfset var discQuery = ''>
		<cfset var discDescrip = ''>

	<cfquery name="discQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT discount_description, discount_name, discount_promotional_code, discount_show_description
	FROM cw_discounts
	WHERE discount_id = #arguments.discount_id#
	</cfquery>

	<!--- get name --->
	<cfset discDescrip = discQuery.discount_name>
	<!--- add promo code --->
	<cfif arguments.show_promocode and len(trim(discQuery.discount_promotional_code))>
		<cfset discDescrip = discDescrip & ' (#discQuery.discount_promotional_code#)' >
	</cfif>
	<!--- add description --->
	<cfif discQuery.discount_show_description neq 0>
		<cfset discDescrip = discDescrip & '<br><span class="CWdiscountDescription">' & #discQuery.discount_description# & '</span>'>
	</cfif>

	<cfreturn discDescrip>
</cffunction>

<!--- // ---------- // get discount data, set into application scope // ---------- // --->
<cffunction name="CWgetDiscountData"
			access="public"
			output="false"
			returntype="query"
			hint="get discount data from application memory, or refresh as needed"
			>

	<cfargument name="refresh_data"
			required="false"
			default="false"
			type="boolean"
			hint="If true, new query is run">
			<!--- NOTE: use <cfset discountQuery = CWgetDiscountData(true)> to force refresh of stored data --->

	<cfargument name="discount_id"
			required="false"
			default="0"
			type="numeric"
			hint="If provided, application data is not altered, only current lookup info is returned">

	<cfset var discountQuery = ''>
	<cfset var codeList = ''>

	<!--- get all active discounts --->
	<cfif arguments.refresh_data is true
			OR arguments.discount_id neq 0
			OR NOT isDefined('application.cw.discountData.activeDiscounts')>
		<!--- get all columns, exclusive discounts first
			  sort by priority (lower priority number comes first),
			  then higher percentage rate, then highest fixed amount --->
		<cfquery name="discountQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT *
		FROM cw_discounts
		WHERE NOT discount_archive = 1
			<cfif arguments.discount_id gt 0>
			AND discount_id = #arguments.discount_id#
			</cfif>
		ORDER BY discount_exclusive DESC, discount_priority, discount_calc DESC, discount_amount DESC, discount_merchant_id
		</cfquery>

		<!--- if listing all discounts, set into application scope --->
		<cfif not arguments.discount_id gt 0>
			<cfset application.cw.discountData.activeDiscounts = discountQuery>
			<!--- set list of available promo codes into application memory for fast lookup --->
			<cfloop list="#valueList(discountQuery.discount_promotional_code)#" index="c">
				<cfif len(trim(c))>
				<!--- add to list --->
				<cfset codelist = listAppend(codeList,trim(c),'^')>
				</cfif>
			</cfloop>
			<cfset application.cw.discountData.promocodes = codeList>
		</cfif>

	<cfelseif arguments.refresh_data is false>
		<!--- if we already have this in memory, use the stored query --->
		<cfset discountQuery = application.cw.discountData.activeDiscounts>
	</cfif>

<cfreturn discountQuery>
</cffunction>

</cfsilent>