<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-func-cart.cfm
File Date: 2012-12-27
Description: manages cart contents, creates cart object and handles cart-related queries
Dependencies: requires cw-func-query, cw-func-tax to be included in calling page
==========================================================
--->

<!--- // ---------- // CWgetCart // ---------- // --->
<cffunction name="CWgetCart"
			access="public"
			output="false"
			returntype="struct"
			hint="Returns a structure containing customer's cart, with product information"
			>

	<!--- NOTE: THESE ARGUMENTS CAN BE AUTOMATICALLY RETREIVED FROM SESSION/APPLICATION VALUES (see below) --->
	<cfargument name="cart_id" required="false" default="0" type="string"
				hint="the ID of the cart, usually session.cwclient.cwCartID">

	<cfargument name="tax_region_id" required="false" default="0"
				hint="the Tax Region ID to use for calculations">

	<cfargument name="tax_country_id" required="false" default="0"
				hint="the Tax Country ID to use for calculations">

	<cfargument name="product_order" required="false" type="string" default="#application.cw.appDisplayCartOrder#"
				hint="Order of products in cart">

	<cfargument name="customer_id" required="false" type="string" default="0"
				hint="ID of current customer: used for discount lookup">

	<cfargument name="customer_type" required="false" type="string" default="0"
				hint="ID of current customer's type: used for discount lookup">

	<cfargument name="promo_code" required="false" type="string" default=""
				hint="Promotional code, or list of codes delimited with ^, used for discount lookup">

	<cfargument name="tax_calc_method" required="false" type="string" default="#application.cw.taxCalctype#"
				hint="The type of tax calculation to use (localtax|avatax|none)">

	<!--- /END AUTOMATED ARGUMENTS --->

	<cfargument name="set_discount_request" required="false" type="boolean" default="true"
				hint="If true, sets any applied discounts into request.cwpage.discountsapplied">

	<!--- creates a structure representing the user's cart --->
	<cfset var cart = structNew()>
	<cfset var rsCart = queryNew('empty')>
	<cfset var rsUnique = queryNew('empty')>
	<cfset var rsCartTotals = queryNew('empty')>
	<cfset var cartitem = structNew()>
	<cfset var option = structNew()>
	<cfset var discountTotals = structNew()>
	<cfset var shipdiscountTotals = structNew()>
	<cfset var cartTaxData = structNew()>
	<cfset var dataStruct = structNew()>
	<cfset var subStruct = structNew()>
	<cfset var discountedTax = 0>
	<!--- defaults for cart caching --->
	<cfparam name="request.cw.customerCart" default="structNew()">	
	<cfparam name="request.cw.customerCartSet" default="0">		
	<!--- set default values for cart totals --->
	<cfset cart.carttotals = structNew()>
	<cfset cart.carttotals.base = 0>
	<cfset cart.carttotals.shipProductBase = 0>
	<cfset cart.carttotals.sub = 0>
	<cfset cart.carttotals.tax = 0>
	<cfset cart.carttotals.cartItemTotal = 0>
	<cfset cart.carttotals.weight = 0>
	<cfset cart.carttotals.itemcount = 0>
	<cfset cart.carttotals.skucount = 0>
	<!--- discount totals --->
	<cfset cart.carttotals.cartItemDiscounts = 0>
	<cfset cart.carttotals.cartOrderDiscounts = 0>
	<cfset cart.carttotals.cartdiscounts = 0>
	<cfset cart.carttotals.shipItemDiscounts = 0>
	<cfset cart.carttotals.shipOrderDiscounts = 0>
	<cfset cart.carttotals.shipOrderDiscountPercent = 0>
	<cfset cart.carttotals.shipdiscounts = 0>
	<cfset cart.carttotals.discountids = ''>
	<!--- shipping discounts --->
	<cfset cart.carttotals.shipWeight = 0>
	<cfset cart.carttotals.shipSubtotal = 0>
	<!--- set default cartitem information --->
	<cfset cart.cartItems = arrayNew(1)>
	<!--- use cart id from session if not provided --->
	<cfif arguments.cart_id eq '0'
		and isDefined('session.cwclient.cwCartID')
		and session.cwclient.cwCartID neq '0'
		and session.cwclient.cwCartID neq ''>
		<cfset arguments.cart_id = session.cwclient.cwCartID>
	</cfif>
	<!--- use country id from session if not provided --->
	<cfif arguments.tax_country_id eq '0'
		and isDefined('session.cwclient.cwTaxCountryID')
		and session.cwclient.cwTaxCountryID neq '0'
		and session.cwclient.cwTaxCountryID neq ''>
		<cfset arguments.tax_country_id = session.cwclient.cwTaxCountryID>
	</cfif>
	<!--- use region id from session if not provided --->
	<cfif arguments.tax_region_id eq '0'
		and isDefined('session.cwclient.cwTaxRegionID')
		and session.cwclient.cwTaxRegionID neq '0'
		and session.cwclient.cwTaxRegionID neq ''>
		<cfset arguments.tax_region_id = session.cwclient.cwTaxRegionID>
	</cfif>
	<!--- use customer id from session if not provided --->
	<cfif arguments.customer_id eq '0'
		and isDefined('session.cwclient.cwCustomerID')
		and session.cwclient.cwCustomerID neq '0'
		and session.cwclient.cwCustomerID neq ''>
		<cfset arguments.customer_id = session.cwclient.cwCustomerID>
		<!--- get customer type --->
		<cfset customerQuery = CWquerySelectCustomerDetails(arguments.customer_id)>
		<cfif customerQuery.customer_type_id gt 0><cfset arguments.customer_type = customerQuery.customer_type_id></cfif>
	</cfif>

	<!--- use promo codes from session if not provided --->
	<cfif not len(trim(arguments.promo_code))
			and isDefined('session.cwclient.discountPromoCode')
			and len(trim(session.cwclient.discountPromoCode))>
			<cfset arguments.promo_code = trim(session.cwclient.discountPromoCode)>
	</cfif>
	<!--- use product order from application if not provided --->
	<cfif not len(trim(arguments.product_order))
			and isDefined('application.cw.appDisplayCartOrder')
			and len(trim(application.cw.appDisplayCartOrder))>
			<cfset arguments.product_order = application.cw.appDisplayCartOrder>
	</cfif>

	<!--- collect cart and sku info --->
	<cfquery name="rsCart" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT
		p.product_id,
		p.product_name,
		p.product_ship_charge,
		p.product_custom_info_label,
		s.sku_merchant_sku_id,
		s.sku_id,
		ot.optiontype_name,
		op.option_name,
		op.option_sort,
		c.cart_sku_qty,
		c.cart_sku_unique_id,
		c.cart_sku_qty * s.sku_price AS TotalPrice,
		c.cart_sku_qty * s.sku_weight AS TotalWeight,
		s.sku_price,
		s.sku_weight,
		s.sku_ship_base
		FROM cw_products p
		INNER JOIN cw_skus s
		ON p.product_id = s.sku_product_id
		INNER JOIN cw_cart c
		ON c.cart_sku_id = s.sku_id
		LEFT JOIN cw_sku_options so
		ON s.sku_id = so.sku_option2sku_id
		LEFT JOIN cw_options op
		ON op.option_id = so.sku_option2option_id
		LEFT JOIN cw_option_types ot
		ON ot.optiontype_id = op.option_type_id
		WHERE c.cart_custcart_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.cart_id#">
		AND NOT p.product_archive = 1
		AND NOT s.sku_on_web = 0
		AND NOT p.product_on_web = 0
		<cfif arguments.product_order is 'timeAdded'>
		ORDER BY c.cart_line_id DESC
		<cfelse>
		ORDER BY p.product_name,
		s.sku_sort, c.cart_sku_unique_id, op.option_sort, op.option_name
		</cfif>
	</cfquery>

	<cfset cartQuery = rsCart>

	<cfif cartQuery.RecordCount neq 0>
		<!--- add the ID to the cart structure --->
		<cfset cart.cartID = arguments.cart_ID>

		<!--- get unique rows - avoid duplicating total addition for multiple options --->
		<cfquery name="rsunique" dbtype="query">
			SELECT DISTINCT cart_sku_unique_id, cart_sku_qty, totalPrice
			FROM cartQuery
		</cfquery>

		<!--- get totals for use in discount lookup --->
		<cfquery name="rscarttotals" dbtype="query">
			SELECT SUM(cart_sku_qty) as totalQty,
			SUM(totalPrice) as totalPrice
			FROM rsUnique
		</cfquery>

		<!--- loop the items in the cart--->
		<cfoutput query="cartQuery" group="cart_sku_unique_id">
			<!--- increment the cartitem count --->
			<cfset cart.carttotals.itemcount = cart.carttotals.itemcount + 1>
			<cfset cart.carttotals.skucount = cart.carttotals.skucount + cartQuery.cart_sku_qty>

			<!--- create a new cartitem struct for each line of the cart --->
			<cfset cartitem = structNew()>
			<cfset cartitem.options = arrayNew(1)>

			<!--- set up container for any applied discounts --->
			<cfset cartitem.discountsapplied = structNew()>
			<cfset cartitem.shipdiscountsapplied = structNew()>

			<!--- Set the cartitem base price, before *any* adjustments --->
			<cfset cartitem.basePrice = cartQuery.TotalPrice>
			<cfset cartitem.price = cartQuery.sku_Price>
			<cfset cart.carttotals.base = cart.carttotals.base + cartitem.basePrice>

			<!--- Set the cartitem information values --->
			<cfset cartitem.Name = cartQuery.product_name>
			<cfset cartitem.ID = cartQuery.product_id>
			<cfset cartitem.customInfoLabel = cartQuery.product_custom_info_label>
			<cfset cartitem.skuID = cartQuery.sku_id>
			<cfset cartitem.skuUniqueID = cartQuery.cart_sku_unique_id>
			<cfset cartitem.merchskuID = cartQuery.sku_merchant_sku_id>
			<cfset cartitem.quantity = cartQuery.cart_sku_qty>

			<!--- get discounts: look up and store discount details applied to any cart item --->
			<cfif application.cw.discountsEnabled>
				<!--- sku shipping discounts --->
				<cfset cartitem.shipdiscountsapplied =  CWgetSKUDiscountTotals(sku_id=cartitem.skuID,
																		 discount_type="sku_ship",
																		 cart_id=cart.cartid,
																		 sku_qty=cartitem.quantity,
																		 cart_qty=rscarttotals.totalQty,
																		 order_total=rscarttotals.totalPrice,
																		 customer_id=arguments.customer_id,
																		 customer_type=arguments.customer_type,
																		 promo_code=arguments.promo_code)>
				<!--- amount is tracked for deduction from shipping ranges --->
				<cfset cartitem.shipdiscountAmount =  cartitem.shipdiscountsapplied.amount>
				<!--- add applied discounts to stored list --->
				<cfloop list="#cartitem.shipdiscountsapplied.id#" index="d">
					<cfif not listFind(cart.carttotals.discountids,d)>
						<cfset cart.carttotals.discountids = listAppend(cart.carttotals.discountids,d)>
					</cfif>
				</cfloop>

				<!--- sku price discounts --->
				<cfset cartitem.discountsapplied =  CWgetSKUDiscountTotals(sku_id=cartitem.skuID,
																		 discount_type="sku_cost",
																		 cart_id=cart.cartid,
																		 sku_qty=cartitem.quantity,
																		 cart_qty=rscarttotals.totalQty,
																		 order_total=rscarttotals.totalPrice,
																		 customer_id=arguments.customer_id,
																		 customer_type=arguments.customer_type,
																		 promo_code=arguments.promo_code)>

				<!--- set totals for amount and price --->
				<cfset cartitem.discountAmount =  cartitem.discountsapplied.amount>
				<cfset cartitem.discountPrice = cartitem.price - cartitem.discountAmount>
				<!--- add applied discounts to stored list --->
				<cfloop list="#cartitem.discountsapplied.id#" index="d">
					<cfif not listFind(cart.carttotals.discountids,d)>
						<cfset cart.carttotals.discountids = listAppend(cart.carttotals.discountids,d)>
					</cfif>
				</cfloop>

				<!--- total of discounts applied to cart items --->
				<cfset cart.carttotals.cartItemDiscounts = round((cart.carttotals.cartItemDiscounts + cartitem.quantity*cartitem.discountAmount)*100)/100>
				<cfset cart.carttotals.shipItemDiscounts = round((cart.carttotals.shipItemDiscounts + cartitem.quantity*cartitem.shipdiscountAmount)*100)/100>
			<cfelse>
				<cfset cartitem.discountAmount = 0>
				<cfset cartitem.shipdiscountAmount = 0>
				<cfset cartitem.discountPrice = cartitem.price>
			</cfif>
			<!--- subtotal is the base price minus any applied discounts --->
			<cfset cartitem.subTotal = cartitem.quantity*cartitem.Price - (cartitem.quantity*cartitem.discountAmount)>
			<cfset cart.carttotals.sub = cart.carttotals.sub + cartitem.subTotal>

			<!--- set the weight and cost totals for shipping calculations --->
			<cfset cartitem.weight = cartQuery.TotalWeight>
			<cfset cart.carttotals.weight = cart.carttotals.weight + cartitem.weight>
			<!--- if shipping is enabled for this item --->
			<cfif cartQuery.product_ship_charge neq 0>
				<cfset cartItem.shipEnabled = true>
			<cfelse>	
				<cfset cartItem.shipEnabled = false>
			</cfif>
			<!--- if the item is set to use shipping, and has no shipping discounts applied --->
			<cfif cartQuery.product_ship_charge eq 1 and application.cw.shipEnabled
				and cartitem.shipDiscountAmount lt 1 and cart.carttotals.shipItemDiscounts eq 0>
				<cfset cartitem.shipCharge = True>
				<cfset cart.carttotals.shipWeight = cart.carttotals.shipWeight + cartitem.weight>
				<cfset cart.carttotals.shipSubtotal = cart.carttotals.shipSubtotal + cartitem.subTotal>
				<!--- base shipping rate applied to each sku --->
				<cfset cartitem.shipBase = cartQuery.sku_ship_base * cartitem.quantity>
				<cfset cart.carttotals.shipProductBase = cart.carttotals.shipProductBase + cartitem.shipBase>
			<!--- if not using shipping for this item --->
			<cfelse>
				<cfset cartitem.shipCharge = False>
			</cfif>

		<cfif arguments.tax_calc_method is 'localtax'>
			<!--- calculate tax rates --->
 			<cfset cartitem.taxRates = cwGetProductTax(product_id=val(cartitem.id), region_id=val(arguments.tax_region_id), country_id=val(arguments.tax_country_id))>
			<cfset cartitem.tax = round((cartitem.subTotal * cartitem.taxRates.calcTax)*100)/100 - cartitem.subTotal>
			<cfif cartitem.tax lt 0>
				<cfset cartitem.tax = 0>
			</cfif>
			<!--- set item tax  --->
			<cfset cart.carttotals.tax = cart.carttotals.tax + cartitem.tax>
			<!--- cartitem total is the subtotal plus any applicable taxes --->
			<cfset cartitem.total = cartitem.subTotal + cartitem.tax>
		<!--- set tax to 0 if not calculated here --->
		<cfelse>
			<cfset cartitem.total = cartitem.subTotal>
			<cfset cartitem.tax = 0>
		</cfif>

			<!--- calculate cart subtotals --->
			<cfset cart.carttotals.cartItemTotal = cart.carttotals.cartItemTotal + cartitem.total>
			<!--- total at this stage is same as itemtotal (other calculations done on page) --->
			<cfset cart.carttotals.total = round(cart.carttotals.cartItemTotal*100)/100>

			<!--- create cartitem options array --->
			<cfoutput>
				<!--- loop through the grouped options --->
				<cfif cartQuery.option_Name neq "">
					<cfset Option = structNew()>
					<cfset Option.Name = cartQuery.optiontype_Name>
					<cfset Option.Value = cartQuery.option_Name>
					<cfset Option.Sort = cartQuery.option_sort>
					<cfset arrayAppend(cartitem.Options, Option)>
				</cfif>
			</cfoutput>
			<!--- /end cart options --->
			<cfset arrayAppend(cart.cartItems, cartitem)>
		</cfoutput>
		<!--- /end products query --->

		<cfif application.cw.discountsEnabled>
		<!--- cart discounts --->
			<!--- get discounts applied to cart (pass in cart structure) --->
			<cfset discounttotals = CWgetCartDiscountTotals(
										cart=cart,
										customer_id=arguments.customer_id,
										customer_type=arguments.customer_type,
										promo_code=arguments.promo_code
										)>
			<cfset cart.carttotals.cartOrderDiscounts = discountTotals.amount>
			<cfset cart.carttotals.sub = cart.carttotals.sub - discountTotals.amount>
			<!--- adjust total of all product discounts --->
			<cfset cart.carttotals.cartdiscounts = cart.carttotals.cartItemDiscounts + cart.carttotals.cartOrderDiscounts>
			<!--- adjust tax total by same percent --->
			<cfset discountedTax = round(cart.carttotals.tax * (100-discountTotals.percent))/100>
			<!--- since order total already has tax added, remove difference of tax --->
			<cfset cart.carttotals.total = cart.carttotals.total - (cart.carttotals.tax - discountedTax)>
			<cfset cart.carttotals.tax = discountedTax>
			<!--- adjust order total --->
			<cfset cart.carttotals.total = cart.carttotals.total - cart.carttotals.cartOrderDiscounts>
			<!--- add applied discounts to stored list --->
			<cfloop list="#discountTotals.ID#" index="d">
				<cfif not listFind(cart.carttotals.discountids,d)>
					<cfset cart.carttotals.discountids = listAppend(cart.carttotals.discountids,d)>
				</cfif>
			</cfloop>
		<!--- /end order discounts --->

		<!--- shipping discounts --->
			<cfset shipdiscounttotals = CWgetShipDiscountTotals(
										cart=cart,
										customer_id=arguments.customer_id,
										customer_type=arguments.customer_type,
										promo_code=arguments.promo_code
										)>

			<cfset cart.carttotals.shipOrderDiscounts = shipdiscounttotals.amount>
			<cfset cart.carttotals.shipOrderDiscountPercent = shipdiscounttotals.percent>

			<!--- adjust order total--->
			<cfset cart.carttotals.shipdiscounts = cart.carttotals.shipOrderDiscounts>

			<!--- add applied discounts to stored list --->
			<cfloop list="#shipdiscountTotals.ID#" index="d">
				<cfif not listFind(cart.carttotals.discountids,d)>
					<cfset cart.carttotals.discountids = listAppend(cart.carttotals.discountids,d)>
				</cfif>
			</cfloop>
		<!--- /end shipping discounts --->

		<!--- set applied discounts into request scope --->
		<cfif arguments.set_discount_request>
			<cfloop list="#cart.carttotals.discountids#" index="d">
				<cfif not listFind(request.cwpage.discountsapplied,d)>
					<cfset request.cwpage.discountsapplied = listAppend(request.cwpage.discountsapplied,d)>
				</cfif>
			</cfloop>
		</cfif>
		</cfif>
		<!--- /end cart-level discounts --->

	<!--- if not using localtax taxes, get whole cart tax --->
	<cfif not arguments.tax_calc_method is 'localtax'
	and not arguments.tax_calc_method is 'none'
	and not arguments.customer_id is 0
	and not arguments.tax_region_id is 0
	and cart.carttotals.total gt 0>
	
	<!--- verify state has tax nexus --->
	<cfquery name="rsNexus" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT stateprov_nexus 
	FROM cw_stateprov
	WHERE stateprov_id = #arguments.tax_region_id#
	</cfquery>
	<!--- if tax nexus applies --->
	<cfif rsNexus.stateprov_nexus is 1>

		<!--- get all cart tax data (e.g. avatax) --->
		<cfset cartTaxData = CWgetCartTax(
								 cart_id=cart.cartid,
								 customer_id=arguments.customer_id
								)>
		<!--- get tax for each item based on item id = skuuniqueid --->
		<cfset loopCt = 0>

		<cfloop array="#cart.cartItems#" index="i">
			<cftry>
			<cfset loopCt = loopCt + 1>
			<!--- find the product key in the cart that contains the unique id --->
			<cfset dataStruct = structFindValue(cartTaxData.cartlines,i.skuuniqueid,'all')>
			<!--- loop the found array, and get the Item ID --->
			<cfloop array="#dataStruct#" index="subStruct">
				<!--- if the matching key is 'itemid' --->
				<cfif subStruct.key is 'itemid'>
					<!--- use coldfusion structFindValue 'owner' struct to get tax amount  --->
					<cfset cart.cartItems[loopCt].tax = subStruct.owner.itemTax>
					<!--- set item tax  --->
					<cfset cart.carttotals.tax = cart.carttotals.tax + cart.cartItems[loopCt].tax>
					<!--- cartitem total is the subtotal plus any applicable taxes --->
					<cfset cart.cartItems[loopCt].total = cart.cartItems[loopCt].subTotal + cart.cartItems[loopCt].tax>
					<!--- calculate cart subtotals --->
					<cfset cart.carttotals.cartItemTotal = cart.carttotals.cartItemTotal + cart.cartItems[loopCt].tax>
					<cfset cart.carttotals.total = cart.carttotals.total + cart.cartItems[loopCt].tax>
				</cfif>
			</cfloop>
			<!--- /end loop of found array  --->
			<cfcatch>
				<!--- on error, no tax is added for this item --->
			</cfcatch>
			</cftry>
		</cfloop>
		<!--- /end loop of cart items --->

		</cfif>
		<!--- /end check for nexus --->

		<!--- shipping tax --->
		<cfif isDefined('cartTaxData.Amounts.totalShipTax') and cartTaxData.Amounts.totalShipTax gt 0>
			<!--- set into request scope for display on cart view/checkout page as needed --->
			<cfset request.cwpage.cartShipTaxTotal = cartTaxdata.Amounts.totalShiptax>
		</cfif>
	</cfif>

		<!--- /end whole cart tax --->
	</cfif>
	<!--- /end if items exist --->

	<cfreturn cart>
</cffunction>

<!--- // ---------- // CWcartAddItem // ---------- // --->
<cffunction name="CWcartAddItem"
			access="public"
			output="false"
			returntype="struct"
			hint="Inserts a sku into the cart, returns sku ID or error message, and sku quantity added"
			>

	<cfargument required="true" name="sku_id" type="numeric"
				hint="The ID of the sku to add">

	<cfargument required="false" name="sku_unique_id" type="string" default="#arguments.sku_id#"
				hint="A unique value for the sku (skuid + custom value)">

	<cfargument required="false" name="sku_qty" type="numeric" default="1"
				hint="The quantity of this sku to insert">

	<cfargument name="ignore_stock" required="false" type="boolean" default="no"
			hint="Allow cart quantity regardless of stock quantities y/n">

	<cfargument name="cart_id" required="false" type="string" default="0"
			hint="Overridden by session variable">


	<cfset var addskuResults = structNew()>
	<cfset var rsCartskuExists = ''>
	<cfset var oldQty = ''>
	<cfset var newQty = ''>
	<cfset addskuResults.message = ''>
	<cfset addskuResults.qty = 0>

	<!--- cart id in session can override --->
	<cfparam name="session.cwclient.cwCartID" default="0">
	<cfif arguments.cart_id is '0' and session.cwclient.cwCartID is not '0' and session.cwclient.cwCartID is not ''>
		<cfset arguments.cart_id = session.cwclient.cwCartID>
	</cfif>

	<!--- check for quantity provided (sku is skipped if qty = 0, no message returned --->
	<cfif arguments.sku_qty gte 1>

		<!--- check for existing sku --->
		<cfquery name="rsCartskuExists" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			SELECT cart_line_id, cart_sku_qty
			FROM cw_cart
			WHERE cart_custcart_id ='#arguments.cart_id#'
			AND
			(cart_sku_unique_id = '#arguments.sku_unique_id#'
				<!--- if unique id is empty, can match sku id --->
				<cfif not len(trim(arguments.sku_unique_id))>
					OR cart_sku_unique_id = '#arguments.sku_id#'
				</cfif>
			)
			AND cart_sku_id = #arguments.sku_id#
		</cfquery>

			<!--- if existing, factor in for quantity check --->
			<cfset oldQty = val(rsCartskuExists.cart_sku_qty)>
			<!--- if already existing, add provided qty to existing --->
			<cfif oldQty gt 0>
				<cfset newQTY = oldQty + arguments.sku_qty>
			<!--- if not already existing, use provided qty --->
			<cfelse>
				<cfset newQTY = arguments.sku_qty>
			</cfif>

		<!--- check quantity available --->
		<cfquery name="rsCartskuQty" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			SELECT sku_stock
			FROM cw_skus
			WHERE sku_id = #arguments.sku_id#
		</cfquery>

			<!--- if quantity not available, limit number added, show message --->
			<cfif arguments.ignore_stock is false
				AND rsCartskuQty.sku_stock lt newQty>
					<!--- set new quantity to number available (for update) --->
					<cfset newQty = val(rsCartskuQty.sku_stock)>
					<!--- add the number remaining (for new, and display to customer)--->
					<cfset insertQty = newQty - oldQty>
			<!--- if stock is not checked, or enough exists, insert the number requested --->
			<cfelse>
					<cfset insertQty = arguments.sku_qty>
			</cfif>

		<!--- if sku already exists in cart --->
		<cfif rsCartskuExists.recordCount gt 0>

			<!--- UPDATE EXISTING sku IN CART --->
			<cftry>
			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			UPDATE cw_cart
			<!--- set total to new quantity --->
			SET cart_sku_qty = #newQty#,
			cart_dateadded = #CreateODBCDateTime(Now())#
			WHERE cart_sku_id = #arguments.sku_id#
			AND cart_sku_unique_id= '#arguments.sku_unique_id#'
			AND cart_custcart_id = '#arguments.cart_id#'
			</cfquery>
			<cfset addskuResults.message = arguments.sku_id>
			<cfset addskuResults.qty = insertQty>

			<!--- handle any errors --->
			<cfcatch>
				<cfset addskuResults.message = cfcatch.message>
				<cfset addskuResults.qty = 0>
			</cfcatch>
			</cftry>
			<!--- /end update existing sku --->

		<!--- if sku does not exist, insert it --->
		<cfelse>
			<!--- INSERT NEW sku TO CART --->
			<cftry>
			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			INSERT INTO cw_cart
			(
			cart_custcart_id,
			cart_sku_id,
			cart_sku_unique_id,
			cart_sku_qty,
			cart_dateadded
			)
			VALUES
			(
			'#arguments.cart_id#',
			#arguments.sku_id#,
			'#arguments.sku_unique_id#',
			<!--- set quantity to number determined above --->
			#insertQty#,
			#CreateODBCDateTime(Now())#
			)
			</cfquery>
			<cfset addskuResults.message = arguments.sku_id>
			<cfset addskuResults.qty = insertQty>
			<!--- handle any errors --->
			<cfcatch>
				<cfset addskuResults.message = cfcatch.message>
				<cfset addskuResults.qty = 0>
			</cfcatch>
			</cftry>
			<!--- /end insert sku --->

		</cfif>
		<!--- /end if sku already exists --->

	</cfif>
	<!--- /end check for quantity --->

<cfreturn addskuResults>

</cffunction>

<!--- // ---------- // CWcartDeleteItem // ---------- // --->
<cffunction name="CWcartDeleteItem"
			access="public"
			output="false"
			returntype="string"
			hint="Delete item from cart. Returns sku_unique_id value if successful."
			>
	<cfargument name="sku_unique_id"
			required="true"
			default="0"
			type="string"
			hint="the unique ID marker of the item to remove from cart">

	<cfset var skuDeleteResults = ''>

	<cftry>
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#" result="deleteResult">
	DELETE FROM cw_cart
	WHERE cw_cart.cart_sku_unique_id = '#arguments.sku_unique_id#'
	AND cart_custcart_id = '#session.cwclient.cwCartID#'
	</cfquery>

	<cfset skuDeleteResults = arguments.sku_unique_id>
	<cfcatch>
		<cfset skuDeleteResults = 'Unable to remove item from cart'>
	</cfcatch>
	</cftry>

	<cfreturn skuDeleteResults>

</cffunction>

<!--- // ---------- // CWcartUpdateItem // ---------- // --->
<cffunction name="CWcartUpdateItem"
			access="public"
			output="false"
			returntype="struct"
			hint="Updates an item's quantity in the cart, returns quantity added, with sku unique ID or a message"
			>

		<cfargument name="sku_unique_id"
				required="true"
				default="0"
				type="string"
				hint="the unique ID marker of the item to update in the cart">

		<cfargument name="sku_qty"
				required="true"
				default="0"
				type="numeric"
				hint="The quantity to set the cart item to">

		<cfargument name="ignore_stock"
				required="false"
				type="boolean"
				default="no"
				hint="Allow cart quantity regardless of stock quantities y/n">

		<cfargument name="sku_new_unique_id"
				required="false"
				default=""
				type="string"
				hint="a new unique ID to apply">

	<cfset var updateSkuResults = structNew()>

	<cfset var updateQty = ''>

	<!--- check quantity available --->
		<cfquery name="rsCartskuQty" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			SELECT sku_stock
			FROM cw_skus, cw_cart
			WHERE cw_skus.sku_id = cw_cart.cart_sku_id
			AND cw_cart.cart_sku_unique_id = '#arguments.sku_unique_id#'
		</cfquery>

			<!--- if quantity not available, limit number added, show message --->
			<cfif arguments.ignore_stock is false
				and rsCartskuQty.sku_stock lt arguments.sku_qty>
					<!--- set new quantity to number available (for update) --->
					<cfset updateQty = val(rsCartskuQty.sku_stock)>
			<!--- if stock is not checked, or if enough stock exists, insert the number requested --->
			<cfelse>
					<cfset updateQty = arguments.sku_qty>
			</cfif>

			<cfif isNumeric(updateQty) and updateQty gt 0>
			<cftry>
				<cfquery name="rsUpdateCartItem" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
				UPDATE cw_cart
				SET cart_sku_qty = #updateQty#
				<cfif len(trim(arguments.sku_new_unique_id))>
				, cart_sku_unique_id = trim(arguments.sku_new_unique_id)
				</cfif>
				WHERE cw_cart.cart_sku_unique_id = '#arguments.sku_unique_id#'
				AND cart_custcart_id = '#session.cwclient.cwCartID#'				
				</cfquery>
				<!--- create update results --->
					<cfset updateSkuResults.message = arguments.sku_unique_id>
					<cfset updateSkuResults.qty = updateQty>
				<cfcatch>
					<cfset updateSkuResults.message = cfcatch.message>
					<cfset updateSkuResults.qty = 0>
				</cfcatch>
			</cftry>
			<cfelseif updateQty eq 0>
			<!--- if quantity is 0, remove item from cart --->
			<cftry>
				<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
				DELETE FROM cw_cart
				WHERE cw_cart.cart_sku_unique_id = '#arguments.sku_unique_id#'
				AND cart_custcart_id = '#session.cwclient.cwCartID#'
				</cfquery>
					<cfset updateSkuResults.message = arguments.sku_unique_id>
			<cfcatch>
					<cfset updateSkuResults.message = 'Unable to remove from cart'>
			</cfcatch>
			</cftry>
			<!--- quantity is returned as empty string when deleting --->
					<cfset updateSkuResults.qty = ''>
			</cfif>

	<cfreturn UpdateSkuResults>

</cffunction>

<!--- // ---------- // CWcartGetskuByOptions // ---------- // --->
<cffunction name="CWcartGetskuNoOptions"
			access="public"
			output="false"
			returntype="string"
			hint="look up a sku based on a product ID, returns sku ID or an error message"
			>

	<cfargument required="true" name="product_id" type="numeric"
				hint="The ID of the product to look up">

	<cfset var rsskuLookup1 = ''>

	<cftry>
	<cfquery maxrows="1" name="rsskuLookup1" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT sku_id
	FROM cw_skus
	WHERE cw_skus.sku_product_id = #arguments.product_id#
	</cfquery>

	<cfset skuLookupResults = rsskuLookup1.sku_id>
	<cfcatch><cfset skuLookupResults = cfcatch.message></cfcatch>
	</cftry>

<cfreturn skuLookupResults>

</cffunction>

<!--- // ---------- // CWcartGetskuByOptions // ---------- // --->
<cffunction name="CWcartGetskuByOptions"
			access="public"
			output="false"
			returntype="string"
			hint="look up a sku based on a product ID and list of option IDs, returns sku ID or an error message"
			>

	<cfargument required="true" name="product_id" type="numeric"
				hint="The ID of the product to look up">

	<cfargument required="true" name="option_list" type="string"
				hint="List of option IDs to match">

	<cfset var rsskuLookup1 = ''>
	<cfset var rsskuLookup2 = ''>
	<cfset var numOptions = listLen(arguments.option_list)>
	<cfset var skuLookupResults = ''>

	<cftry>
	<cfquery name="rsskuLookup1" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT cw_sku_options.sku_option2sku_id
	FROM cw_skus
	INNER JOIN cw_sku_options
		ON cw_skus.sku_id = cw_sku_options.sku_option2sku_id
		WHERE cw_skus.sku_product_id = #arguments.product_ID#
	GROUP BY cw_sku_options.sku_option2sku_id
	HAVING count(cw_sku_options.sku_option2sku_id) = #numOptions#
	</cfquery>
	<cfset sku_option2sku_id = ValueList(rsskuLookup1.sku_option2sku_id)>
	<cfif sku_option2sku_id eq "">
		<cfset sku_option2sku_id = 0>
	</cfif>
	<cfquery name="rsskuLookup2" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT cw_sku_options.sku_option2sku_id
	FROM cw_sku_options
	WHERE cw_sku_options.sku_option2option_id IN (#arguments.option_list#)
	AND cw_sku_options.sku_option2sku_id IN (#sku_option2sku_id#)
	GROUP BY cw_sku_options.sku_option2sku_id
	HAVING Count(cw_sku_options.sku_option2sku_id)=#numOptions#
	</cfquery>
	<cfset sku_option2sku_id2 = ValueList(rsskuLookup2.sku_option2sku_id)>
	<cfif sku_option2sku_id2 eq "">
		<cfset sku_option2sku_id2 = 0>
	</cfif>
	<cfquery name="findsku" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT DISTINCT (sku_id) AS skuID, sku_stock
	FROM  cw_sku_options, cw_skus
	WHERE sku_id IN (#sku_option2sku_id2#)
	AND sku_product_id = #arguments.product_id#
	</cfquery>
	<cfset skuLookupResults = findsku.skuID>
	<cfcatch><cfset skuLookupResults = cfcatch.message></cfcatch>
	</cftry>

<cfreturn skuLookupResults>

</cffunction>

<!--- // ---------- // CWcartGetskuData // ---------- // --->
<cffunction name="CWcartGetskuData"
			access="public"
			output="false"
			returntype="string"
			hint="Gets sku custom data (personalization) based on provided ID"
			>

		<cfargument required="false" name="sku_data_id" type="string" default=""
					hint="The ID of the data item to retrieve">

	<cfset var getData = ''>

	<cfset var returnContent = ''>

	<cfquery name="getData" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT data_content
	FROM cw_order_sku_data
	WHERE data_id = #arguments.sku_data_id#
	</cfquery>

	<cfset returnContent = getData.data_content>

<cfreturn returnContent>

</cffunction>

<!--- // ---------- // CWcartAddskuData // ---------- // --->
<cffunction name="CWcartAddskuData"
			access="public"
			output="false"
			returntype="string"
			hint="Inserts sku data, returns sku ID or error message"
			>

	<cfargument required="true" name="sku_id" type="numeric"
				hint="The ID of the sku to add">

	<cfargument required="false" name="sku_data" type="string" default=""
				hint="The custom data to save">

	<cfset var addDataResults = ''>
	<cfset var checkID = ''>
	<cfset var getNewID = ''>
	<cfset var addDataTS = createODBCdateTime(now())>

	<cfparam name="session.cwclient.cwCartID" default="0">

<cftry>

	<!--- check for this string, in this cart --->
	<cfquery name="checkID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT data_id as dataID
	FROM cw_order_sku_data
	WHERE data_sku_id = '#arguments.sku_ID#'
	AND data_cart_id = '#session.cwclient.cwCartID#'
	AND data_content = '#htmlEditFormat(arguments.sku_data)#'
	</cfquery>

<!--- if we already have a match,use that ID --->
	<cfif checkID.recordCount gt 0>
		<cfset addDataResults = checkID.dataID>
	<cfelse>
		<!--- if no match, insert --->
		<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		INSERT INTO cw_order_sku_data
		(
		data_sku_id,
		data_cart_id,
		data_content,
		data_date_added
		)VALUES(
		#arguments.sku_id#,
		'#session.cwclient.cwCartID#',
		'#htmlEditFormat(arguments.sku_data)#',
		#addDataTS#
		)
		</cfquery>

		<!---get the new ID (from any db type) by matching all vars inserted --->
		<cfquery name="getNewID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT data_id as newID
		FROM cw_order_sku_data
		WHERE data_sku_id = #arguments.sku_id#
		AND data_cart_id = '#session.cwclient.cwCartID#'
		AND data_content = '#htmlEditFormat(arguments.sku_data)#'
		</cfquery>

	<!--- if successful, message will be the ID from the data table --->
	<cfset addDataResults = getNewID.newID>

</cfif>

	<!--- /end check for existing --->
	<cfcatch>
	<!--- if any error, return the server error message in place of ID --->
	<cfset addDataResults = cfcatch.message>
	</cfcatch>
</cftry>

	<!--- return results --->
	<cfreturn addDataResults>
</cffunction>

<!--- // ---------- // CWcartVerifyProduct // ---------- // --->
<cffunction name="CWcartVerifyProduct"
			access="public"
			output="false"
			returntype="boolean"
			hint="Verifies product is eligible to be added to cart"
			>

	<cfargument required="true" name="product_id" type="numeric"
				hint="The ID of the product to look up">

	<cfargument name="ignore_stock" required="false" type="boolean" default="no"
				hint="Allow sale regardless of stock quantities y/n">

	<cfset var rsProductStockCheck = ''>
	<cfquery name="rsProductStockCheck" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT product_id, sku_id, sku_stock
	FROM cw_products, cw_skus
	WHERE product_id = #arguments.product_id#
	AND cw_skus.sku_product_id = #arguments.product_id#
	<cfif NOT arguments.ignore_stock>
	AND cw_skus.sku_stock > 0
	</cfif>
	AND NOT sku_on_web = 0
	AND NOT product_on_web = 0
	</cfquery>

	<cfif rsProductStockCheck.recordCount gt 0>
	<cfreturn true>
	<cfelse>
	<cfreturn false>
	</cfif>

</cffunction>

<!--- // ---------- // CWgetCartTotal // ---------- // --->
<cffunction name="CWgetCartTotal"
			access="public"
			output="false"
			returntype="string"
			hint="returns cart total as unformatted numeric value"
			>

	<cfargument name="cart_id"
			required="true"
			default="0"
			type="string"
			hint="ID of the cart to show - usually session.cwclient.cwCartID">

	<cfargument name="tax_calc_method"
			required="false"
			default="none"
			type="string"
			hint="the type of calculation , if any, to use for tax (none|localtax|avatax)">

	<cfset var cartTotal = 0>
	<cfset var cartData = structNew()>
	<cfset cartData.carttotals.total = 0>

	<cfif arguments.cart_id neq 0>
		<cfset cartData = CWgetCart(cart_id=arguments.cart_id,tax_calc_method=arguments.tax_calc_method)>
		<cfif isDefined('cartData.carttotals.total') and cartData.carttotals.total gt 0>
			<cfset cartTotal = cartData.carttotals.total>
		</cfif>
	</cfif>

<cfreturn cartTotal>

</cffunction>

<!--- // ---------- // CWgetCartItems // ---------- // --->
<cffunction name="CWgetCartItems"
			access="public"
			output="false"
			returntype="query"
			hint="returns query of items in cw_cart based on cart ID"
			>

	<cfargument name="cart_id"
			required="true"
			default="0"
			type="string"
			hint="ID of the cart to show - usually session.cwclient.cwCartID">

	<cfset var rsCartItems = ''>

	<cfquery name="rsCartItems" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT *
	FROM cw_cart
	WHERE cart_custcart_id ='#arguments.cart_id#'
	</cfquery>

<cfreturn rsCartItems>

</cffunction>

<!--- // ---------- // CWgetCartCount // ---------- // --->
<cffunction name="CWgetCartCount"
			access="public"
			output="false"
			returntype="numeric"
			hint="returns number of items in cw_cart based on cart ID"
			>

	<cfargument name="cart_id"
			required="true"
			type="string"
			hint="ID of the cart to show - usually session.cwclient.cwCartID">

	<cfset var rsCartCount = ''>
	<cfset var returnCount = ''>

	<!--- defaults for cart caching --->
	<cfparam name="request.cw.customerCartCount" default="0">	
	<cfparam name="request.cw.customerCartCountSet" default="0">

	<cfquery name="rsCartCount" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT SUM(cart_sku_qty) AS CartCount, cart_custcart_id
	FROM cw_cart c, cw_skus s
	WHERE c.cart_custcart_id ='#arguments.cart_id#'
	AND s.sku_id = c.cart_sku_id
	AND NOT c.cart_sku_id = 0
	AND NOT c.cart_sku_id IS NULL
	AND NOT c.cart_sku_qty = 0
	AND NOT s.sku_on_web = 0
	GROUP BY cart_custcart_id
	</cfquery>

	<cfif isNumeric(rsCartCount.cartCount)>
		<cfset returnCount = rsCartCount.cartCount>
	<cfelse>
		<cfset returnCount = 0>
	</cfif>

<cfreturn returnCount>

</cffunction>

<!--- // ---------- // CWclearCart // ---------- // --->
<cffunction name="CWclearCart"
			access="public"
			output="false"
			returntype="void"
			hint="Deletes all stored items in cart table for a given cart id"
			>

	<cfargument name="cart_id"
			required="true"
			type="string"
			hint="ID of the cart to clear - usually session.cwclient.cwCartID">

	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	  DELETE FROM cw_cart
	  WHERE cart_custcart_id='#arguments.cart_ID#'
	</cfquery>

</cffunction>

</cfsilent>