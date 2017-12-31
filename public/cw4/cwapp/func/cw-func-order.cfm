<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-func-order.cfm
File Date: 2012-09-05
Description: manages order insertion to database, and other related functions
Dependencies: requires cw-func-query and cw-func-global to be included in calling page
==========================================================
--->

<!--- // ---------- // Insert Order to Database // ---------- // --->
<cffunction name="CWsaveOrder"
			access="public"
			output="false"
			returntype="string"
			hint="Insert order to database, return order ID or error message"
			>

	<cfargument name="order_id"
			required="true"
			type="string"
			hint="ID to use for new order">

	<cfargument name="order_status"
			required="true"
			type="numeric"
			hint="Status ID for new order">

	<cfargument name="cart"
			required="true"
			default=""
			type="struct"
			hint="structure containing cart data">

	<cfargument name="customer"
			required="true"
			default=""
			type="struct"
			hint="structure containing customer data">

	<cfargument name="ship_method"
			required="false"
			default="0"
			type="numeric"
			hint="ID for the ship method selected by customer">

	<cfargument name="message"
			required="false"
			default=""
			type="string"
			hint="order comments / message from customer">

	<cfargument name="checkout_type"
			required="false"
			default=""
			type="string"
			hint="account|guest">

<cfset var rsCheckOrder = ''>
<cfset var rsInsertOrder = ''>
<cfset var returnStr = ''>
<cfset var temp = ''>

<cftry>
<!--- check for unique order ID (no duplicates) --->

<cfquery name="rsCheckOrder" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT order_id
FROM cw_orders
WHERE order_id = <cfqueryparam value="#arguments.order_id#" cfsqltype="cf_sql_varchar">
</cfquery>

<!--- if a duplicate order is found --->
<cfif rsCheckOrder.recordCount gt 0>
<cfset returnStr = '0-Processing Error: Duplicate Order ID'>

<!--- if no duplicate order --->
<cfelse>

<cfquery name="rsInsertOrder" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
INSERT INTO cw_orders (
order_id,
order_date,
order_status,
order_customer_id,
order_tax,
order_shipping,
order_shipping_tax,
order_total,
order_ship_method_id,
order_ship_name,
order_company,
order_address1,
order_address2,
order_city,
order_state,
order_zip,
order_country,
order_comments,
order_checkout_type,
order_discount_total,
order_ship_discount_total
) VALUES (
'#arguments.order_id#',
#createODBCdateTime(cwTime())#,
#arguments.order_status#,
'#arguments.customer.customerid#',
#arguments.cart.carttotals.tax#,
#arguments.cart.carttotals.shipping - arguments.cart.carttotals.shipdiscounts#,
#arguments.cart.carttotals.shippingtax#,
#arguments.cart.carttotals.total#,
#arguments.ship_method#,
'#arguments.customer.shipname#',
'#arguments.customer.shipcompany#',
'#arguments.customer.shipaddress1#',
'#arguments.customer.shipaddress2#',
'#arguments.customer.shipcity#',
'#arguments.customer.shipstateprovname#',
'#arguments.customer.shipzip#',
'#arguments.customer.shipcountry#',
'#arguments.message#',
'#arguments.checkout_type#',
'#arguments.cart.carttotals.cartdiscounts#',
'#arguments.cart.carttotals.shipdiscounts#'
)
</cfquery>

<!--- INSERT SKUS --->
     <cfloop from="1" to="#arrayLen(attributes.cart.cartItems)#" index="lineNumber">
			<!--- set the current product to a variable for easier reference --->
			<cfset product = attributes.cart.cartItems[lineNumber]>
			<cfparam name="product.discountsapplied.id" default="">
			<!--- QUERY: save order sku --->
			<cfset saveSku = CWsaveOrderSku(
					order_id=arguments.order_id,
					sku_id=product.skuid,
					sku_unique_id=product.skuuniqueid,
					sku_qty=product.quantity,
					sku_price=product.price,
					sku_subtotal=product.subtotal,
					sku_tax_rate=product.tax,
					sku_discount_id=product.discountsapplied.id,
					sku_discount_amount=product.discountamount,
					sku_custom_info=product.custominfolabel
							)>

			<!--- QUERY: debit purchased quantity from stock on hand --->
			<cfset setQty = CWsetSkuStock(
								sku_id=product.skuid,
								qty_purchased=product.quantity,
								reload_appdata=false
								)>
        </cfloop>
	
<!--- RECORD DISCOUNT USAGE --->
<cfif len(trim(arguments.cart.carttotals.discountids)) and arguments.cart.carttotals.discountids neq 0>
<cfloop list="#trim(arguments.cart.carttotals.discountids)#" index="d">
	<!--- QUERY: get discount details --->
	<cfset discountQuery = CWgetDiscountDetails(d)>

	<cfquery name="rsInsertDiscountUsage" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		INSERT INTO cw_discount_usage(
		discount_usage_customer_id,
		discount_usage_datetime,
		discount_usage_order_id,
		discount_usage_discount_name,
		<cfif discountQuery.discount_show_description neq 0>
			discount_usage_discount_description,
		</cfif>
		discount_usage_promocode,
		discount_usage_discount_id
		) VALUES (
		'#arguments.customer.customerid#',
		#createODBCdateTime(cwTime())#,
		'#arguments.order_id#',
		'#discountQuery.discount_name#',
		<cfif discountQuery.discount_show_description neq 0>
			'#discountQuery.discount_description#',
		</cfif>
		'#discountQuery.discount_promotional_code#',
		#d#
			)
	</cfquery>

</cfloop>

</cfif>

	<!--- return order id as confirmation string --->
	<cfset returnStr = arguments.order_id>
</cfif>
<!--- /end check for duplicates --->

	<!--- reload saved sku data in application scope --->
	<cftry>
	<cfset temp = CWinitSkuData()>
	<cfcatch></cfcatch>
	</cftry>
	<!--- if any errors, return message --->
	<cfcatch>
		<cfset returnStr = '0-Processing Error'>
		<cfif len(trim(cfcatch.detail))>
			<cfif cfcatch.detail contains 'duplicate'>
			<cfset returnStr = returnStr & ': Duplicate Order ID'>
			<cfelse>
			<cfset returnStr = returnStr & ': #cfcatch.detail#'>
			</cfif>
		</cfif>
	</cfcatch>
	</cftry>
<cfreturn returnStr>
</cffunction>

<!--- // ---------- // Insert Order SKU // ---------- // --->
<cffunction name="CWsaveOrderSku"
			access="public"
			output="false"
			returntype="any"
			hint="Insert order sku"
			>

	<cfargument name="order_id"
			required="true"
			type="string"
			hint="ID of order">

	<cfargument name="sku_id"
			required="true"
			type="numeric"
			hint="ID of sku">

	<cfargument name="sku_unique_id"
			required="false"
			default="#arguments.sku_id#"
			type="string"
			hint="Unique ID of sku w/ custom value">

	<cfargument name="sku_qty"
			required="false"
			default="1"
			type="numeric"
			hint="Quantity purchased">

	<cfargument name="sku_price"
			required="true"
			type="numeric"
			hint="Purchase price of sku">

	<cfargument name="sku_subtotal"
			required="false"
			type="numeric"
			default="#(arguments.sku_qty*arguments.sku_price)#"
			hint="Line total for sku">

	<cfargument name="sku_tax_rate"
			required="false"
			type="numeric"
			default="0"
			hint="Tax rate for sku">

	<cfargument name="sku_discount_amount"
			required="false"
			type="numeric"
			default="0"
			hint="Amount of discount applied to sku">

	<cfargument name="sku_custom_info"
			required="false"
			type="string"
			default=""
			hint="Custom personalization message or other customer-selected info">

<cfset var rsInsertSku = ''>

<cfquery name="rsInsertSku" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_order_skus(
			ordersku_order_id,
			ordersku_sku,
			ordersku_unique_id,
			ordersku_quantity,
			ordersku_unit_price,
			ordersku_sku_total,
			ordersku_tax_rate,
			ordersku_discount_amount,
			ordersku_customval
			) VALUES (
			'#arguments.order_id#',
			#arguments.sku_id#,
			'#arguments.sku_unique_id#',
			#arguments.sku_qty#,
			#arguments.sku_price#,
			#arguments.sku_subtotal#,
			#arguments.sku_tax_rate#,
			#arguments.sku_discount_amount#,
			'#arguments.sku_custom_info#'
			)
</cfquery>

</cffunction>

<!--- // ---------- // Get Order Record // ---------- // --->
<cffunction name="CWquerySelectOrder"
			access="public"
			output="false"
			returntype="query"
			hint="Returns a query containing a single record from the orders table">

	<cfargument name="order_id" required="true" default="0" type="string"
				hint="ID of order to look up">

<cfset var rsOrder = ''>
<cfquery name="rsOrder" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT *
FROM cw_orders
WHERE order_id = '#arguments.order_id#'
</cfquery>

<cfreturn rsOrder>
</cffunction>

<!--- // ---------- Select Orders (Search) ---------- // --->
<cffunction name="CWquerySelectOrders"
			access="public"
			output="false"
			returntype="query"
			hint="Returns a query with order details">

	<cfargument name="customer_id" required="false" default="" type="string"
				hint="ID of customer to look up">

	<cfargument name="status_id" required="false" default="0" type="numeric"
				hint="Limit orders to specific status">

	<cfargument name="date_start" required="false" default="0" type="date"
				hint="Limit orders to this date or after">

	<cfargument name="date_end" required="false" default="0" type="date"
				hint="Limit orders to this date or before">

	<cfargument name="id_str" required="false" default="" type="string"
				hint="An order ID, or partial ID to match">

	<cfargument name="cust_name" required="false" default="" type="string"
				hint="A customer first or last name or ID, or part of a name or ID to match">

	<cfargument name="max_orders" required="false" default="0" type="numeric"
				hint="Max orders to return - pass in 0 to show all">

<cfset var rsOrders = ''>
<cfquery name="rsOrders" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT
cw_customers.customer_first_name,
cw_customers.customer_last_name,
cw_customers.customer_zip,
cw_customers.customer_id,
cw_orders.order_id,
cw_orders.order_ship_name,
cw_orders.order_date,
cw_orders.order_company,
cw_orders.order_status,
cw_orders.order_address1,
cw_orders.order_address2,
cw_orders.order_city,
cw_orders.order_state,
cw_orders.order_zip,
cw_orders.order_total,
cw_order_status.shipstatus_name
FROM ((cw_customers
INNER JOIN cw_orders
ON cw_customers.customer_id = cw_orders.order_customer_id)
INNER JOIN cw_order_status
ON cw_order_status.shipstatus_id = cw_orders.order_status)
WHERE 1=1
<cfif arguments.date_start neq 0>AND cw_orders.order_date >= #CreateODBCDate(LSParseDateTime(dateFormat(arguments.date_start,'short')))#</cfif>
<cfif arguments.date_end neq 0>AND cw_orders.order_date <= #CreateODBCDateTime(DateAdd("d",1,LSParseDateTime(dateFormat(arguments.date_end,'short'))))#</cfif>
<cfif arguments.status_id>AND order_status = #arguments.status_id#</cfif>
<cfif len(trim(arguments.id_str))>AND #application.cw.sqlLower#(order_id) like '%#lcase(arguments.id_str)#%'</cfif>
<cfif len(trim(arguments.cust_name))>
	AND (
	#application.cw.sqlLower#(customer_first_name) like '%#lcase(arguments.cust_name)#%'
	OR #application.cw.sqlLower#(customer_last_name) like '%#lcase(arguments.cust_name)#%'
	OR #application.cw.sqlLower#(customer_id) like '%#lcase(arguments.cust_name)#%'
	)
</cfif>
<cfif len(trim(arguments.customer_id))>
	AND customer_id like '#arguments.customer_id#'
</cfif>
GROUP BY
cw_orders.order_id,
cw_orders.order_date,
cw_orders.order_status,
cw_orders.order_address1,
cw_orders.order_address2,
cw_orders.order_city,
cw_orders.order_state,
cw_orders.order_zip,
cw_orders.order_total,
cw_order_status.shipstatus_name,
cw_customers.customer_first_name,
cw_customers.customer_last_name,
cw_orders.order_ship_name,
cw_orders.order_company,
cw_customers.customer_zip,
cw_customers.customer_id
ORDER BY
cw_orders.order_date DESC,
cw_orders.order_status,
cw_customers.customer_last_name,
cw_customers.customer_first_name,
cw_orders.order_id,
cw_orders.order_address1,
cw_orders.order_address2,
cw_orders.order_city,
cw_orders.order_state,
cw_orders.order_zip,
cw_orders.order_total,
cw_order_status.shipstatus_name,
cw_orders.order_ship_name,
cw_orders.order_company,
cw_customers.customer_zip,
cw_customers.customer_id
</cfquery>


<cfif arguments.max_orders gt 0>
	<cfquery name="rsOrders" dbtype="query" maxrows="#arguments.max_orders#">
	SELECT *
	FROM rsOrders
	</cfquery>
</cfif>

<cfreturn rsOrders>
</cffunction>

<!--- // ---------- Select Order Details w/ sku info, customer info, etc ---------- // --->
<cffunction name="CWquerySelectOrderDetails"
			access="public"
			output="false"
			returntype="query"
			hint="Returns a query with all details about a given order">

	<cfargument name="order_id" required="true" default="0" type="string"
				hint="ID of order to look up">

<cfset var rsOrderDetails = ''>
<cfquery name="rsOrderDetails" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT
	ss.shipstatus_name,
	o.*,
	c.customer_first_name,
	c.customer_last_name,
	c.customer_id,
	c.customer_email,
	p.product_name,
	p.product_id,
	p.product_custom_info_label,
	p.product_out_of_stock_message,
	s.sku_id,
	s.sku_merchant_sku_id,
	s.sku_download_id,
	sm.ship_method_name,
	os.ordersku_sku,
	os.ordersku_unique_id,
	os.ordersku_quantity,
	os.ordersku_unit_price,
	os.ordersku_sku_total,
	os.ordersku_tax_rate,
	os.ordersku_discount_amount,
	(o.order_total - (o.order_tax + o.order_shipping + o.order_shipping_tax)) as order_subtotal
FROM (
	cw_products p
	INNER JOIN cw_skus s
	ON p.product_id = s.sku_product_id)
	INNER JOIN ((cw_customers c
		INNER JOIN (cw_order_status ss
			RIGHT JOIN (cw_ship_methods sm
				RIGHT JOIN cw_orders o
				ON sm.ship_method_id = o.order_ship_method_id)
			ON ss.shipstatus_id = o.order_status)
		ON c.customer_id = o.order_customer_id)
		INNER JOIN cw_order_skus os
		ON o.order_id = os.ordersku_order_id)
	ON s.sku_id = os.ordersku_sku
WHERE o.order_id = '#arguments.order_id#'
ORDER BY
	p.product_name,
	s.sku_sort,
	s.sku_merchant_sku_id
</cfquery>

<cfreturn rsOrderDetails>
</cffunction>

<!--- // ---------- // Insert Payment to Database // ---------- // --->
<cffunction name="CWsavePayment"
			access="public"
			output="false"
			returntype="string"
			hint="Inserts a payment transaction, returns transaction ID, or 0-message on error"
			>

	<cfargument name="order_id"
			required="true"
			type="string"
			hint="order ID to insert">

	<cfargument name="payment_method"
			required="true"
			type="string"
			hint="payment method (text value, e.g. 'Authorize.net')">

	<cfargument name="payment_type"
			required="true"
			type="string"
			hint="payment type (text value, e.g. 'Gateway')">

	<cfargument name="payment_amount"
			required="true"
			type="numeric"
			hint="payment amount">

	<cfargument name="payment_status"
			required="true"
			type="string"
			hint="approved|denied|pending|none">

	<cfargument name="payment_trans_id"
			required="true"
			type="string"
			hint="transaction id from processor">

	<cfargument name="payment_trans_response"
			required="true"
			type="string"
			hint="any returned message, xml content or other values to store">

<cfset var rsInsertPayment = ''>
<cfset var returnStr = ''>
<cfset var getNewID = ''>

<!--- verify order id is valid --->
<cfif CWorderStatus(arguments.order_id) eq 0>
	<cfset returnStr = '0-No Matching Order'>
<cfelse>
	<cftry>
		<cfquery name="rsInsertPayment" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		INSERT INTO cw_order_payments (
		order_id,
		payment_method,
		payment_type,
		payment_amount,
		payment_status,
		payment_trans_id,
		payment_trans_response,
		payment_timestamp
		) VALUES (
		<cfqueryparam value="#arguments.order_id#" cfsqltype="cf_sql_varchar">,
		<cfqueryparam value="#arguments.payment_method#" cfsqltype="cf_sql_varchar">,
		<cfqueryparam value="#arguments.payment_type#" cfsqltype="cf_sql_varchar">,
		<cfqueryparam value="#arguments.payment_amount#" cfsqltype="cf_sql_float">,
		<cfqueryparam value="#arguments.payment_status#" cfsqltype="cf_sql_varchar">,
		<cfqueryparam value="#arguments.payment_trans_id#" cfsqltype="cf_sql_varchar">,
		<cfqueryparam value="#arguments.payment_trans_response#" cfsqltype="cf_sql_longvarchar">,
		<cfqueryparam value="#createODBCdateTime(now())#" cfsqltype="cf_sql_timestamp">
		);
		</cfquery>

		<!--- get new transaction id --->
			<cfquery name="getNewID" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#" maxrows="1">
			SELECT payment_id FROM cw_order_payments
			WHERE order_id = <cfqueryparam value="#arguments.order_id#" cfsqltype="cf_sql_varchar">
			ORDER BY payment_id DESC
			</cfquery>
		<cfset returnStr = getNewId.payment_id>
	<cfcatch>
		<cfset returnStr = '0-' & cfcatch.detail>
	</cfcatch>
	</cftry>
</cfif>

<cfreturn returnStr>
</cffunction>

<!--- // ---------- // Get Order Status (numeric) // ---------- // --->
<cffunction name="CWorderStatus"
			access="public"
			output="false"
			returntype="numeric"
			hint="returns the numeric code for the status of any order (0 = none, not found)"
			>
<cfargument name="order_id"
		required="true"
		type="string"
		hint="order ID to look up">

<cfset var rsOrderStatus = ''>
<cfset var returnStatus = 0>

<cfquery name="rsOrderStatus" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT order_status as statusCode
FROM cw_orders
WHERE order_id = <cfqueryparam value="#arguments.order_id#" cfsqltype="cf_sql_varchar">
</cfquery>

<cfif rsOrderStatus.recordCount eq 1>
	<cfset returnStatus = rsOrderStatus.statusCode>
</cfif>

<cfreturn returnStatus>
</cffunction>

<!--- // ---------- Update Order ---------- // --->
<cffunction name="CWqueryUpdateOrder"
			access="public"
			returntype="void"
			output="false"
			hint="Update an existing order record">

	<!--- ID isrequired --->
	<cfargument name="order_id" required="true" default="" type="string"
				hint="The ID of the order to update">

	<!--- optional arguments --->
	<cfargument name="order_status" required="false" default="0" type="numeric"
				hint="The ID of the order status">

	<cfargument name="order_ship_date" required="false" default="" type="string"
				hint="The date this order was shipped">

	<cfargument name="order_ship_charge" required="false" default="0" type="string"
				hint="The amount of shipping charged to this order">

	<cfargument name="order_tracking_id" required="false" default="" type="string"
				hint="The tracking ID for this order">

	<cfargument name="order_notes" required="false" default="" type="string"
				hint="Admin notes for the order">

	<cfargument name="order_message" required="false" default="" type="string"
				hint="Customer message for the order">

    <cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
    UPDATE cw_orders
		SET order_id = order_id
			<cfif arguments.order_status gt 0>
			,order_status='#arguments.order_status#'
			</cfif>
			, order_ship_date=
				<cfif arguments.order_ship_date neq "" and isDate(arguments.order_ship_date)>
				#createODBCdateTime(LSParseDateTime(dateFormat(arguments.order_ship_date,'short')))#
				<cfelse>
				Null
				</cfif>
			<cfif arguments.order_ship_charge gt 0>
			, order_actual_ship_charge = #CWsqlNumber(arguments.order_ship_charge)#
			</cfif>
			<cfif len(trim(arguments.order_tracking_id))>
			, order_ship_tracking_id='#arguments.order_tracking_id#'
			</cfif>
			<cfif len(trim(arguments.order_notes))>
			,order_notes = '#arguments.order_notes#'
			</cfif>
			<cfif len(trim(arguments.order_message))>
			,order_comments = <cfqueryparam value="#arguments.order_message#" cfsqltype="cf_sql_varchar">
			</cfif>
    WHERE order_id='#arguments.order_id#'
		</cfquery>

</cffunction>

<!--- // ---------- // Get Payments Related to Order // ---------- // --->
<cffunction name="CWorderPayments"
			access="public"
			output="false"
			returntype="query"
			hint="returns all payments related to order"
			>

	<cfargument name="order_id"
			required="true"
			default="0"
			type="string"
			hint="order ID to look up">

	<cfset var rsOrderPayments = ''>

	<cfquery name="rsOrderPayments" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT *
	FROM cw_order_payments
	WHERE order_id = <cfqueryparam value="#arguments.order_id#" cfsqltype="cf_sql_varchar">
	</cfquery>

<cfreturn rsOrderPayments>
</cffunction>

<!--- // ---------- // Get Payments Types related to Order // ---------- // --->
<cffunction name="CWorderPaymentTypes"
			access="public"
			output="false"
			returntype="query"
			hint="returns all payments related to order"
			>

	<cfargument name="order_id"
			required="true"
			default="0"
			type="string"
			hint="order ID to look up">

	<cfset var rsOrderPayments = ''>

	<cfquery name="rsOrderPayments" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT payment_type, payment_method, payment_status
	FROM cw_order_payments
	WHERE order_id = <cfqueryparam value="#arguments.order_id#" cfsqltype="cf_sql_varchar">
	</cfquery>

<cfreturn rsOrderPayments>
</cffunction>

<!--- // ---------- // Get Payment Totals for Order // ---------- // --->
<cffunction name="CWorderPaymentTotal"
			access="public"
			output="false"
			returntype="numeric"
			hint="returns a numeric total of all payments made against a given order"
			>

	<cfargument name="order_id"
			required="true"
			default="0"
			type="string"
			hint="order ID to look up">

	<cfset var paymentQuery = ''>
	<cfset var paymentTotalsQuery = ''>
	<cfset var returnTotal = 0>

	<cfset paymentQuery = CWorderPayments(arguments.order_id)>
	<cfquery name="paymentTotalsQuery" dbtype="query">
	SELECT sum(payment_amount) as paymentTotal
	FROM paymentQuery
	WHERE payment_amount > 0
	AND payment_status = 'approved'
	</cfquery>

	<cfif not isNumeric(paymentTotalsQuery.paymentTotal)>
		<cfset returnTotal = 0>
		<cfelse>
		<cfset returnTotal = paymentTotalsQuery.paymentTotal>
	</cfif>

<cfreturn returnTotal>
</cffunction>

<!--- // ---------- // Get Order by Transaction ID // ---------- // --->
<cffunction name="CWqueryGetTransaction"
			access="public"
			output="false"
			returntype="query"
			hint="Looks up details of any order payment by transaction id"
			>

	<cfargument name="transaction_id"
			required="true"
			default="0"
			type="string"
			hint="transaction ID to look up">

	<cfset var rsTrans = ''>

	<cfquery name="rsTrans" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT *
	FROM cw_order_payments
	WHERE payment_trans_id = <cfqueryparam value="#arguments.transaction_id#" cfsqltype="cf_sql_varchar">
	</cfquery>

	<cfreturn rsTrans>
</cffunction>

</cfsilent>