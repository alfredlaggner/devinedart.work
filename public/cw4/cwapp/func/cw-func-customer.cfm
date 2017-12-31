<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-func-customer.cfm
File Date: 2013-02-10
Description: managers customer information, and related queries
Dependencies: requires cw-func-query to be included in calling page
==========================================================
--->

<!--- // ---------- Get All Customer Data ---------- // --->
<cffunction name="CWgetCustomer"
			access="public"
			output="false"
			returntype="struct"
			hint="Returns a structure containing customer's information, including shipping and billing address"
			>

	<cfargument name="customer_id"
			required="true"
			default="0"
			type="any"
			hint="ID of the customer to show - usually session.cwclient.cwCustomerID">

	<cfset var customerQuery = ''>
	<cfset var shippingQuery = ''>
	<cfset var customer = structNew()>
	<cfset var varname = ''>

<cfif arguments.customer_id gt 0>
	<!--- get all customer data --->
	<cfset customerQuery = CWquerySelectCustomerDetails(arguments.customer_id)>
	<!--- if customer is found --->
	<cfif customerQuery.recordCount eq 1>
		<cfset customer.customerid = arguments.customer_id>
		<!--- write all vars into customer struct --->
		<cfloop list="#customerQuery.columnList#" index="cc">
			<!--- remove customer_ prefix from all variables for easier use --->
			<cfset varname = replaceNoCase(cc,'customer_','','all')>
			<cfset varname = lcase(replace(varname,'_','','all'))>
			<!--- do not use ID, handled separately --->
			<cfif not cc eq 'customer_id'>
			<cfset customer[varname] = evaluate('customerQuery.#cc#')>
			</cfif>
		</cfloop>
		<!--- QUERY: get customer's shipping info (customer id)--->
		<cfset shippingQuery = CWquerySelectCustomerShipping(session.cwclient.cwCustomerID)>
		<!--- add shipping info to customer struct --->
		<cfset customer.shipcountry = shippingQuery.country_name>
		<cfset customer.shipcountrycode = shippingQuery.country_code>
		<cfset customer.shipcountryID = shippingQuery.country_ID>
		<cfset customer.shipstateprovname = shippingQuery.stateprov_name>
		<cfset customer.shipstateprovcode = shippingQuery.stateprov_code>
		<cfset customer.shipstateprovID = shippingQuery.stateprov_ID>
	<!--- if no customer found --->
	<cfelse>
		<cfset customer.customerid = 0>
	</cfif>

</cfif>

<cfreturn customer>

</cffunction>

<!--- // ---------- Select Customer Details ---------- // --->
<cffunction name="CWquerySelectCustomerDetails" access="public" output="false" returntype="query"
			hint="Returns a query with customer details including billing address info, state and country">

	<cfargument name="customer_id" required="false" default="" type="string"
				hint="A customer ID, or part of an ID to match">

<cfset var rsCustomerDetails = ''>
<cfquery name="rsCustomerDetails" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT cw_customers.customer_id,
				cw_customers.customer_type_id,
				cw_customers.customer_first_name,
				cw_customers.customer_last_name,
				cw_customers.customer_address1,
				cw_customers.customer_address2,
				cw_customers.customer_city,
				cw_customers.customer_zip,
				cw_customers.customer_ship_name,
				cw_customers.customer_ship_company,
				cw_customers.customer_ship_address1,
				cw_customers.customer_ship_address2,
				cw_customers.customer_ship_city,
				cw_customers.customer_ship_zip,
				cw_customers.customer_phone,
				cw_customers.customer_phone_mobile,
				cw_customers.customer_email,
				cw_customers.customer_company,
				cw_customers.customer_username,
				cw_customers.customer_password,
				cw_customers.customer_guest,
				cw_stateprov.stateprov_name,
				cw_stateprov.stateprov_code,
				cw_stateprov.stateprov_id,
				cw_stateprov.stateprov_nexus,
				cw_customer_stateprov.customer_state_destination,
				cw_countries.country_name,
				cw_countries.country_id,
				cw_countries.country_code
	FROM (((cw_customers
			INNER JOIN cw_customer_stateprov
			ON cw_customers.customer_id = cw_customer_stateprov.customer_state_customer_id)

			INNER JOIN cw_stateprov
			ON cw_stateprov.stateprov_id = cw_customer_stateprov.customer_state_stateprov_id)

			INNER JOIN cw_countries
			ON cw_countries.country_id = cw_stateprov.stateprov_country_id)

		WHERE cw_customer_stateprov.customer_state_destination='BillTo'
		AND #application.cw.sqlLower#(customer_id) = '#lcase(arguments.customer_id)#'
</cfquery>

<cfreturn rsCustomerDetails>
</cffunction>

<!--- // ---------- Select Customer Shipping Details ---------- // --->
<cffunction name="CWquerySelectCustomerShipping" access="public" output="false" returntype="query"
			hint="Returns a query with customer shipping details including address info, state and country">

	<cfargument name="customer_id" required="false" default="" type="string"
				hint="A customer ID, or part of an ID to match">

<cfset var rscustomerShpping = ''>
<cfquery name="rscustomerShpping" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT cw_customers.customer_id,
				cw_customers.customer_type_id,
				cw_customers.customer_first_name,
				cw_customers.customer_last_name,
				cw_customers.customer_ship_name,
				cw_customers.customer_ship_address1,
				cw_customers.customer_ship_address2,
				cw_customers.customer_ship_company,
				cw_customers.customer_ship_city,
				cw_customers.customer_ship_zip,
				cw_stateprov.stateprov_name,
				cw_stateprov.stateprov_id,
				cw_stateprov.stateprov_code,
				cw_stateprov.stateprov_nexus,
				cw_customer_stateprov.customer_state_destination,
				cw_countries.country_name,
				cw_countries.country_id,
				cw_countries.country_code
			FROM (((cw_customers
			INNER JOIN cw_customer_stateprov
			ON cw_customers.customer_id = cw_customer_stateprov.customer_state_customer_id)

			INNER JOIN cw_stateprov
			ON cw_stateprov.stateprov_id = cw_customer_stateprov.customer_state_stateprov_id)

			INNER JOIN cw_countries
			ON cw_countries.country_id = cw_stateprov.stateprov_country_id)

		WHERE cw_customer_stateprov.customer_state_destination='ShipTo'
		AND #application.cw.sqlLower#(customer_id) = '#lcase(arguments.customer_id)#'
</cfquery>

<cfreturn rscustomerShpping>
</cffunction>

<!--- // ---------- Select Customer Orders ---------- // --->
<cffunction name="CWquerySelectCustomerOrders" access="public" output="false" returntype="query"
			hint="Returns a query of orders for any given customer">

	<cfargument name="customer_id" required="true" default="0" type="string"
				hint="ID of customer to look up">

	<cfargument name="max_return" required="false" default="0" type="numeric"
				hint="Maximum number of rows to return, sorted by date descending">

<cfset var rsCustOrders = ''>
<cfquery name="rsCustOrders" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT *
FROM cw_orders
WHERE order_customer_id = '#arguments.customer_id#'
ORDER BY order_date DESC
</cfquery>

<cfif arguments.max_return gt 0>
<cfquery dbtype="query" name="rsCustOrders" maxrows="#arguments.max_return#">
SELECT *
FROM rsCustOrders
</cfquery>
</cfif>

<cfreturn rsCustOrders>
</cffunction>

<!--- // ---------- Select Customer Order Details ---------- // --->
<cffunction name="CWquerySelectCustomerOrderDetails" access="public" output="false" returntype="query"
			hint="Returns a query with customer order info">

	<cfargument name="customer_id" required="false" default="" type="string"
				hint="A customer ID, or part of an ID to match">

	<cfargument name="max_return" required="false" default="0" type="numeric"
				hint="Maximum number of rows to return, sorted by date descending">

<cfset var rsCustomerOrderDetails = ''>
<cfquery name="rsCustomerOrderDetails" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT
	cw_orders.order_id,
	cw_orders.order_date,
	cw_orders.order_total,
	cw_order_skus.ordersku_sku,
	cw_skus.sku_merchant_sku_id,
	cw_products.product_name,
	cw_products.product_id
FROM
	cw_products
	INNER JOIN (cw_skus
		INNER JOIN (cw_orders
			INNER JOIN cw_order_skus
			ON cw_orders.order_id = cw_order_skus.ordersku_order_id)
		ON cw_skus.sku_id = cw_order_skus.ordersku_sku)
	ON cw_products.product_id = cw_skus.sku_product_id
WHERE
	cw_orders.order_customer_id = '#arguments.customer_id#'
ORDER BY
	cw_orders.order_date DESC
</cfquery>
<cfif arguments.max_return gt 0>
<cfquery dbtype="query" name="rsCustomerOrderDetails" maxrows="#arguments.max_return#">
SELECT *
FROM rsCustomerOrderDetails
</cfquery>
</cfif>

<cfreturn rsCustomerOrderDetails>
</cffunction>

<!--- // ---------- Select Customer Types ---------- // --->
<cffunction name="CWquerySelectCustomerTypes" access="public" output="false" returntype="query"
			hint="Returns a query with all available customer types">

	<cfset var rsCustTypes = "">

	<cfquery name="rsCustTypes" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT *
	FROM cw_customer_types
	ORDER BY customer_type_name
	</cfquery>

<cfreturn rsCustTypes>
</cffunction>

<!--- // ---------- Insert Customer---------- // --->
<cffunction name="CWqueryInsertCustomer" access="public" output="false" returntype="string"
			hint="Inserts a new customer record including billing/shipping - returns ID of the new customer, or 0-message if unsuccessful">

<!--- Type and Name are required --->
	<cfargument name="customer_type_id" default="0" required="true" type="numeric"
				hint="ID of the customer type">

	<cfargument name="customer_firstname" default="0" required="true" type="string"
				hint="First Name of the customer to update">

	<cfargument name="customer_lastname" default="0" required="true" type="string"
				hint="Last Name of the customer to update">

<!--- others optional, default NULL --->
	<cfargument name="customer_email" default="" required="false" type="string"
				hint="Email Address">

	<cfargument name="customer_username" default="" required="false" type="string"
				hint="username">

	<cfargument name="customer_password" default="" required="false" type="string"
				hint="Password">

	<cfargument name="customer_company" default="" required="false" type="string"
				hint="Company Name">

	<cfargument name="customer_phone" default="" required="false" type="string"
				hint="Phone Number">

	<cfargument name="customer_phone_mobile" default="" required="false" type="string"
				hint="Mobile Phone Number">

	<cfargument name="customer_address1" default="" required="false" type="string"
				hint="Billing Address Line 1">

	<cfargument name="customer_address2" default="" required="false" type="string"
				hint="Billing Address Line 2">

	<cfargument name="customer_city" default="" required="false" type="string"
				hint="Billing City">

	<cfargument name="customer_state" default="0" required="false" type="numeric"
				hint="Billing State">

	<cfargument name="customer_zip" default="" required="false" type="string"
				hint="Billing Postal Code">

	<cfargument name="customer_ship_name" default="" required="false" type="string"
				hint="Shipping Name (Ship To)">

	<cfargument name="customer_ship_company" default="" required="false" type="string"
				hint="Shipping Company (Ship To)">

	<cfargument name="customer_ship_address1" default="" required="false" type="string"
				hint="Shipping Address Line 1">

	<cfargument name="customer_ship_address2" default="" required="false" type="string"
				hint="Shipping Address Line 2">

	<cfargument name="customer_ship_city" default="" required="false" type="string"
				hint="Shipping City">

	<cfargument name="customer_ship_state" default="0" required="false" type="numeric"
				hint="Shipping State">

	<cfargument name="customer_ship_zip" default="" required="false" type="string"
				hint="Shipping Postal Code">

	<!--- Validate unique email/username --->
	<cfargument name="prevent_duplicates" default="true" required="false" type="boolean"
				hint="If true, function throws error for duplicate email/username">

	<!--- Customer guest: set to 1 if using guest checkout  --->
	<cfargument name="customer_guest" default="0" required="false" type="boolean"
				hint="If 1, duplicate accounts can be created">

	<!--- make sure email and username are unique --->
	<cfset var checkDupEmail = "">
	<cfset var newCustID = "">
	<cfset var checkDupusername = "">
	<cfset var newUUID = CreateUUID()>
	<cfset var randomStr = randRange(100000,999999)>
	<!--- no duplicate checking for new guest accounts --->
	<cfif arguments.customer_guest>
		<cfset arguments.prevent_duplicates = false>
	</cfif>

		<cfquery name="checkDupEmail" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT customer_email
		FROM cw_customers
		<!--- if checking for duplicates, check against existing email --->
			<cfif arguments.prevent_duplicates>
				WHERE customer_email = '#trim(arguments.customer_email)#'
				AND NOT customer_guest = 1
			<!--- if ignoring duplicates, pass dummy string to match --->
			<cfelse>
				WHERE customer_email = '#randomStr#'
			</cfif>
		</cfquery>
	<!--- if we have a dup, stop and return a message --->
	<cfif checkDupEmail.recordCount>
	<cfset newCustID = '0-Email'>
	<!--- if no dup email, continue --->
	<cfelse>
			<cfquery name="checkDupusername" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			SELECT customer_username
			FROM cw_customers
				<!--- if checking for duplicates, check against existing username --->
				<cfif arguments.prevent_duplicates>
					WHERE customer_username = '#trim(arguments.customer_username)#'
					AND NOT customer_guest = 1
				<!--- if ignoring duplicates, pass dummy string to match --->
				<cfelse>
					WHERE customer_username = '#randomStr#'
				</cfif>
			</cfquery>
	<!--- if we have a dup, stop and return a message --->
	<cfif checkDupusername.recordCount>
	<cfset newCustID = '0-username'>
	<!--- if no dup username, continue --->
	<cfelse>
		<cfset newCustID = right(newUUID,6)&LSdateFormat(CWtime(),'-yymmdd')>
	<!--- insert main customer record --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_customers
	(
	customer_id
	,customer_type_id
	,customer_first_name
	,customer_last_name
	,customer_email
	,customer_username
	,customer_password
	,customer_guest
	,customer_company
	,customer_address1
	,customer_address2
	,customer_city
	,customer_zip
	,customer_ship_name
	,customer_ship_company
	,customer_ship_address1
	,customer_ship_address2
	,customer_ship_city
	,customer_ship_zip
	,customer_phone
	,customer_phone_mobile
	,customer_date_modified
	,customer_date_added
	)
	VALUES
	(
	'#newCustID#'
	,#arguments.customer_type_id#
	,'#arguments.customer_firstname#'
	,'#arguments.customer_lastname#'
	,	<cfif len(trim(arguments.customer_email))>'#arguments.customer_email#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_username))>'#arguments.customer_username#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_password))>'#arguments.customer_password#'<cfelse>NULL</cfif>
	,	#arguments.customer_guest#
	,	<cfif len(trim(arguments.customer_company))>'#arguments.customer_company#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_address1))>'#arguments.customer_address1#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_address2))>'#arguments.customer_address2#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_city))>'#arguments.customer_city#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_zip))>'#arguments.customer_zip#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_ship_name))>'#arguments.customer_ship_name#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_ship_company))>'#arguments.customer_ship_company#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_ship_address1))>'#arguments.customer_ship_address1#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_ship_address2))>'#arguments.customer_ship_address2#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_ship_city))>'#arguments.customer_ship_city#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_ship_zip))>'#arguments.customer_ship_zip#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_phone))>'#arguments.customer_phone#'<cfelse>NULL</cfif>
	,	<cfif len(trim(arguments.customer_phone_mobile))>'#arguments.customer_phone_mobile#'<cfelse>NULL</cfif>
	, #createODBCDateTime(CWtime())#
	, #createODBCDateTime(CWtime())#
	)
	</cfquery>

	<!--- insert billing state --->
	<cfif arguments.customer_state gt 0>
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_customer_stateprov
	(
	customer_state_customer_id,
	customer_state_stateprov_id,
	customer_state_destination
	)
	VALUES
	(
	'#newCustID#',
	#arguments.customer_state#,
	'BillTo'
	)
	</cfquery>
	</cfif>

	<!--- insert shipping state --->
	<cfif arguments.customer_ship_state gt 0>
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	INSERT INTO cw_customer_stateprov
	(
	customer_state_customer_id,
	customer_state_stateprov_id,
	customer_state_destination
	)
	VALUES
	(
	'#newCustID#',
	#arguments.customer_ship_state#,
	'ShipTo'
	)
	</cfquery>
	</cfif>

	</cfif>
	<!--- /END check username dup --->
	</cfif>
	<!--- /END check email dup --->

<!--- pass back the ID of the new customer, or error 0 message --->
	<cfreturn newCustID>
</cffunction>

<!--- // ---------- Update Customer---------- // --->
<cffunction name="CWqueryUpdateCustomer" access="public" output="false" returntype="string"
			hint="Updates a customer record - returns ID of the customer, or 0-message if unsuccessful">

<!--- ID and Name are required --->
	<cfargument name="customer_id" default="0" required="true" type="string"
				hint="ID of the customer to update">

	<cfargument name="customer_type_id" default="0" required="true" type="numeric"
				hint="ID of the customer type">

	<cfargument name="customer_firstname" default="0" required="true" type="string"
				hint="First Name of the customer to update">

	<cfargument name="customer_lastname" default="0" required="true" type="string"
				hint="Last Name of the customer to update">

<!--- others optional, default NULL --->
	<cfargument name="customer_email" default="" required="false" type="string"
				hint="Email Address">

	<cfargument name="customer_username" default="" required="false" type="string"
				hint="username">

	<cfargument name="customer_password" default="" required="false" type="string"
				hint="Password">

	<cfargument name="customer_company" default="" required="false" type="string"
			hint="Company Name">

	<cfargument name="customer_phone" default="" required="false" type="string"
				hint="Phone Number">

	<cfargument name="customer_phone_mobile" default="" required="false" type="string"
				hint="Mobile Phone Number">

	<cfargument name="customer_address1" default="" required="false" type="string"
				hint="Billing Address Line 1">

	<cfargument name="customer_address2" default="" required="false" type="string"
				hint="Billing Address Line 2">

	<cfargument name="customer_city" default="" required="false" type="string"
				hint="Billing City">

	<cfargument name="customer_state" default="0" required="false" type="numeric"
				hint="Billing State">

	<cfargument name="customer_zip" default="" required="false" type="string"
				hint="Billing Postal Code">

	<cfargument name="customer_ship_name" default="" required="false" type="string"
				hint="Shipping Name (Ship To)">

	<cfargument name="customer_ship_company" default="" required="false" type="string"
				hint="Shipping Company (Ship To)">

	<cfargument name="customer_ship_address1" default="" required="false" type="string"
				hint="Shipping Address Line 1">

	<cfargument name="customer_ship_address2" default="" required="false" type="string"
				hint="Shipping Address Line 2">

	<cfargument name="customer_ship_city" default="" required="false" type="string"
				hint="Shipping City">

	<cfargument name="customer_ship_state" default="0" required="false" type="numeric"
				hint="Shipping State">

	<cfargument name="customer_ship_zip" default="" required="false" type="string"
				hint="Shipping Postal Code">

	<!--- validate unique email/username --->
	<cfargument name="prevent_duplicates" default="true" required="false" type="boolean"
				hint="If true, function throws error for duplicate email/username">

	<cfset var checkDupEmail = ''>
	<cfset var checkDupusername = ''>
	<cfset var updateCustID = ''>
	<cfset var randomStr = randRange(100000,999999)>

	<!--- verify email and username are unique --->
	<!--- check email --->
	<cfif len(trim(arguments.customer_email))>
	<cfquery name="checkDupEmail" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT customer_email
	FROM cw_customers
	<!--- if checking for duplicates, check against existing email --->
		<cfif arguments.prevent_duplicates>
			WHERE customer_email = '#trim(arguments.customer_email)#'
			AND NOT customer_guest = 1
		<!--- if ignoring duplicates, pass dummy string to match --->
		<cfelse>
			WHERE customer_email = '#randomStr#'
		</cfif>
	AND NOT customer_id='#arguments.customer_id#'
	</cfquery>
	<!--- if we have a dup, return a message --->
	<cfif checkDupEmail.recordCount>
	<cfset updateCustID = '0-Email'>
	</cfif>
	</cfif>
	<!--- check username --->
	<cfif len(trim(arguments.customer_username))>
	<cfquery name="checkDupusername" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT customer_username
	FROM cw_customers
		<!--- if checking for duplicates, check against existing username --->
		<cfif arguments.prevent_duplicates>
			WHERE customer_username = '#trim(arguments.customer_username)#'
			AND NOT customer_guest = 1
		<!--- if ignoring duplicates, pass dummy string to match --->
		<cfelse>
			WHERE customer_username = '#randomStr#'
		</cfif>
	AND NOT customer_id='#arguments.customer_id#'
	</cfquery>
	<!--- if we have a dup, return a message --->
	<cfif checkDupusername.recordCount>
	<cfset updateCustID = '0-username'>
	</cfif>
	</cfif>
	<!--- if no duplicates --->
	<cfif not left(updateCustID,2) eq '0-'>
	<!--- update main customer record --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	UPDATE cw_customers SET
	customer_type_id = #arguments.customer_type_id#
	,customer_first_name = '#arguments.customer_firstname#'
	, customer_last_name = '#arguments.customer_lastname#'
	, customer_email=
	<cfif len(trim(arguments.customer_email))>'#arguments.customer_email#'<cfelse>NULL</cfif>
	, customer_username=
	<cfif len(trim(arguments.customer_username))>'#arguments.customer_username#'<cfelse>NULL</cfif>
	, customer_password=
	<cfif len(trim(arguments.customer_password))>'#arguments.customer_password#'<cfelse>NULL</cfif>
	, customer_company=
	<cfif len(trim(arguments.customer_company))>'#arguments.customer_company#'<cfelse>NULL</cfif>
	, customer_address1=
	<cfif len(trim(arguments.customer_address1))>'#arguments.customer_address1#'<cfelse>NULL</cfif>
	, customer_address2=
	<cfif len(trim(arguments.customer_address2))>'#arguments.customer_address2#'<cfelse>NULL</cfif>
	, customer_city=
	<cfif len(trim(arguments.customer_city))>'#arguments.customer_city#'<cfelse>NULL</cfif>
	, customer_zip=
	<cfif len(trim(arguments.customer_zip))>'#arguments.customer_zip#'<cfelse>NULL</cfif>
	, customer_ship_address1=
	<cfif len(trim(arguments.customer_ship_address1))>'#arguments.customer_ship_address1#'<cfelse>NULL</cfif>
	, customer_ship_company=
	<cfif len(trim(arguments.customer_ship_company))>'#arguments.customer_ship_company#'<cfelse>NULL</cfif>
	, customer_ship_name=
	<cfif len(trim(arguments.customer_ship_name))>'#arguments.customer_ship_name#'<cfelse>NULL</cfif>
	, customer_ship_address2=
	<cfif len(trim(arguments.customer_ship_address2))>'#arguments.customer_ship_address2#'<cfelse>NULL</cfif>
	, customer_ship_city=
	<cfif len(trim(arguments.customer_ship_city))>'#arguments.customer_ship_city#'<cfelse>NULL</cfif>
	, customer_ship_zip=
	<cfif len(trim(arguments.customer_ship_zip))>'#arguments.customer_ship_zip#'<cfelse>NULL</cfif>
	, customer_phone=
	<cfif len(trim(arguments.customer_phone))>'#arguments.customer_phone#'<cfelse>NULL</cfif>
	, customer_phone_mobile=
	<cfif len(trim(arguments.customer_phone_mobile))>'#arguments.customer_phone_mobile#'<cfelse>NULL</cfif>
	, customer_date_modified = #createODBCDateTime(CWtime())#
	WHERE customer_id='#arguments.customer_id#'
	</cfquery>
	<!--- update billing state --->
	<cfif arguments.customer_state gt 0>
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	UPDATE cw_customer_stateprov SET
	customer_state_stateprov_id = #arguments.customer_state#
	WHERE customer_state_customer_id = '#arguments.customer_id#' AND customer_state_destination = 'BillTo'
	</cfquery>
	</cfif>
	<!--- update shipping state --->
	<cfif arguments.customer_ship_state gt 0>
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	UPDATE cw_customer_stateprov SET
	customer_state_stateprov_id = #arguments.customer_ship_state#
	WHERE customer_state_customer_id = '#arguments.customer_id#' AND customer_state_destination = 'ShipTo'
	</cfquery>
	</cfif>
	<cfset updateCustID = arguments.customer_id>
	</cfif>
	<!--- /END check dups --->

<cfreturn updateCustId>
</cffunction>

<!--- // ---------- Delete Customer ---------- // --->
<cffunction name="CWqueryDeleteCustomer" access="public" output="false" returntype="void"
			hint="Delete a customer and associated address info">

	<cfargument name="customer_id" required="true" type="string"
				hint="ID of the customer to delete">

	<!--- delete customer state relationships --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_customer_stateprov WHERE customer_state_customer_id = '#arguments.customer_id#'
	</cfquery>
	<!--- delete customer --->
	<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	DELETE FROM cw_customers WHERE customer_id='#arguments.customer_id#'
	</cfquery>

</cffunction>

<!--- // ---------- Customer Login ---------- // --->
<cffunction name="CWqueryCustomerLogin"
			access="public"
			output="false"
			returntype="query"
			hint="Look up a user based on username and password, return customer details"
			>

	<cfargument name="login_username"
			required="true"
			type="string"
			hint="username to match">

	<cfargument name="login_password"
			required="true"
			type="string"
			hint="Password to match">

	<cfset var rsCustomerLogin = ''>
	<cfquery name="rsCustomerLogin" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT customer_id, customer_ship_city, customer_username
			FROM cw_customers
			WHERE customer_username = <cfqueryparam value="#arguments.login_username#" cfsqltype="cf_sql_varchar">
			AND customer_password = <cfqueryparam value="#arguments.login_password#" cfsqltype="cf_sql_varchar">
	</cfquery>

	<cfreturn rsCustomerLogin>

</cffunction>

<!--- // ---------- Customer Password Lookup ---------- // --->
<cffunction name="CWqueryCustomerLookup"
			access="public"
			output="false"
			returntype="query"
			hint="Look up a user based on email address, return customer details"
			>

	<cfargument name="customer_email"
			required="true"
			type="string"
			hint="Email address to match">

	<cfset var rsCustomerLookup = ''>
	<cfquery name="rsCustomerLookup" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT customer_id, customer_username, customer_password, customer_email
	FROM cw_customers
	WHERE customer_email = <cfqueryparam value="#arguments.customer_email#" cfsqltype="cf_sql_varchar">
	AND NOT customer_guest = 1
	</cfquery>

	<cfreturn rsCustomerLookup>

</cffunction>

</cfsilent>