<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-func-tax.cfm
File Date: 2012-12-03
Description: manages tax calculations and related queries
==========================================================
--->

<!--- // ---------- // CWgetShipTax: Get shipping tax amount for cart shipping total // ---------- // --->
<cffunction name="CWgetShipTax"
			access="public"
			output="false"
			returntype="numeric"
			hint="Returns the amount of tax on a given shipping total"
			>

	<cfargument name="country_id"
			required="true"
			default=""
			type="numeric"
			hint="The country_id to look up for taxes">

	<cfargument name="region_id"
			required="true"
			default=""
			type="numeric"
			hint="The stateprov id to look up">

	<cfargument name="taxable_total"
			required="true"
			default=""
			type="numeric"
			hint="The amount to apply the tax to">

	<cfargument name="cart"
			required="true"
			default=""
			type="struct"
			hint="Cart data from calling page">

	<cfargument name="calc_type"
			required="false"
			default="#application.cw.taxCalctype#"
			type="string"
			hint="The type of tax calculation to use">


	<!--- no tax by default --->
	<cfset var TaxAmount = 0 >
	<cfset var TaxRate = 0 >
	<cfset var rsShipTax = "" >
	<cfset var rsMaxTax = "" >

	<!--- switch lookup based on calctype --->
	<cfswitch expression="#arguments.calc_type#">

	<!--- default (localtax) --->
	<cfdefaultcase>
		<!--- if tax type is groups --->
		<cfif application.cw.taxSystem eq "Groups">
		<cfquery name="rsShipTax" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			SELECT t.tax_rate_percentage as ShipTaxRate,
			r.tax_region_ship_tax_method as ship_tax_method
			FROM cw_tax_regions r
			RIGHT JOIN cw_tax_rates t
			ON r.tax_region_id = t.tax_rate_region_id
			WHERE
			NOT r.tax_region_ship_tax_method = 'No Tax'
			AND NOT r.tax_region_ship_tax_method = 'No Vat'
			AND r.tax_region_country_id = #Val(arguments.country_id)#
			AND (r.tax_region_state_id = #Val(arguments.region_id)#
				OR r.tax_region_state_id = 0)
			</cfquery>
			<!--- if tax record exist --->
			<cfif rsShipTax.recordCount gt 0>
				<!--- Determine method of charging tax to shipping --->
				<!--- Charge tax based on the highest taxed item currently in the cart --->
				<cfif rsShipTax.ship_tax_method eq "Highest Item Taxed">
					<!--- Check the cart to find the highest taxed item --->
					<cfset ShipTaxRate = 0>
					<cfloop from="1" to="#ArrayLen(arguments.cart.cartitems)#" index="i">
						<cfif arguments.cart.cartitems[i].Tax gt ShipTaxRate>
							<cfset ShipTaxRate = arguments.cart.cartitems[i].TaxRates.DisplayTax>
						</cfif>
					</cfloop>
					<cfset TaxAmount = cwCalculateTax(arguments.taxable_total, ShipTaxRate)>
					<!--- /end highest item taxed --->
				<cfelse>
					<!--- The tax rate is set to a specific tax group --->
					<cfset TaxAmount = cwCalculateTax(arguments.taxable_total, rsShipTax.ShipTaxRate)>
				</cfif>
			</cfif>
			<!--- /end if tax records exist --->
		<!--- if type is not 'groups' --->
		<cfelse>
			<cfset TaxRate = CWgetBasicTax(region_id=arguments.region_id, country_id=arguments.country_id)>
			<cfset TaxAmount = CWcalculateTax(arguments.taxable_total, TaxRate)>
		</cfif>
	</cfdefaultcase>
	<!--- /end localtax --->

	</cfswitch>

	<cfreturn TaxAmount>
</cffunction>

<!--- // ---------- // CWgetBasicTax: get a general tax rate from db lookup // ---------- // --->
<cffunction name="CWgetBasicTax"
			access="public"
			output="false"
			returntype="numeric"
			hint="returns a percentage, or 0"
			>

<!--- // Get a General tax (basic tax) --->

	<cfargument name="country_id"
				type="numeric"
				required="true">

	<cfargument name="region_id"
				type="numeric"
				required="false"
				default="0">

	<cfset var rsbasicTax = queryNew('empty')>
	<cfif arguments.region_id eq 0>
		<cfif CWcountryHasStates(arguments.country_id)>
			<!---  // user is not logged in, and country has states, so no default tax can be assumed --->
			<cfreturn 0>
		</cfif>
		<cfquery name="rsBasicTax" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT stateprov_tax as taxrate_percentage
		FROM cw_stateprov
		WHERE stateprov_country_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.country_id#">
		</cfquery>
	<cfelse>
		<cfquery name="rsBasicTax" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT stateprov_tax as taxrate_percentage
		FROM cw_stateprov
		WHERE stateprov_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.region_id#">
		</cfquery>
	</cfif>
	<cfif rsBasicTax.recordCount gt 0>
		<cfreturn rsBasicTax.taxrate_percentage>
	<cfelse>
		<cfreturn 0>
	</cfif>


</cffunction>

<!--- // ---------- // CWcountryHasStates: lookup states for any country // ---------- // --->
<cffunction name="CWcountryHasStates"
			access="public"
			output="false"
			returntype="boolean"
			hint="returns true/false if a country has any regions"
			>

	<cfargument name="country_id"
				type="numeric"
				required="true"
				hint="Country id of country to look up">

	<cfset var rsCWCountryHasStates = queryNew('empty')>

	<cfquery name="rsCWcountryHasStates" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT COUNT(*) as TheStateCount
	FROM cw_countries c
	INNER JOIN cw_stateprov s
	ON c.country_id = s.stateprov_country_id
	WHERE stateprov_archive = 0
	AND stateprov_country_id = #arguments.country_id#
	AND stateprov_name <> 'None'
	</cfquery>

	<cfif rsCWCountryHasStates.TheStateCount eq 0>
		<cfreturn false>
	<cfelse>
		<cfreturn true>
	</cfif>
</cffunction>

<!--- // ---------- // CWcalculateTax: calculate tax on a given amount with a given percentage // ---------- // --->
<cffunction name="CWcalculateTax"
			access="public"
			output="false"
			returntype="numeric"
			hint="returns a tax amount"
			>

	<cfargument name="taxable_total"
				type="numeric"
				required="true"
				hint="The cost that tax should be calculated against"
				>

	<cfargument name="tax_rate"
				type="numeric"
				required="true"
				hint="This should be a tax rate not already divided by 100.
				For 25%, pass in 25, not .25.">

	<cfreturn CWdecimalRound(arguments.taxable_total * (arguments.tax_rate/100))>
</cffunction>

<!--- // ---------- // CWdecimalRound: round to 2 places // ---------- // --->
<cffunction name="CWdecimalRound"
			access="public"
			output="false"
			returntype="numeric"
			hint="rounds a number to 2 places"
			>

	<cfargument name="number_value" type="numeric">
	<cfreturn round(arguments.number_value * 100)/100/>

</cffunction>

<!--- // ---------- // CWgetProductTax // ---------- // --->
<cffunction name="CWgetProductTax"
			access="public"
			output="false"
			returntype="any"
			hint="Returns a struct with total tax rate, and information on each individual rate (object: taxrates, or taxrates.rates)"
			>

	<cfargument name="product_id"
			required="true"
			type="numeric"
			hint="The product id to look up">

	<cfargument name="country_id"
			required="true"
			type="numeric"
			hint="The country id to look up">

	<cfargument name="region_id"
			required="true"
			type="numeric"
			hint="The stateprov id to look up">

	<cfargument name="calc_type"
			required="false"
			default="#application.cw.taxCalctype#"
			type="string"
			hint="The type of tax calculation to use">

	<cfset var rs = "">
	<cfset var taxRates = structNew()>
	<cfset var temp = structNew()>
	<cfset taxRates.displayTax = 0>
	<cfset taxRates.calcTax = 0>
	<cfset taxRates.rates = arrayNew(1)>

	<!--- switch lookup based on calctype --->
	<cfswitch expression="#arguments.calc_type#">

	<!--- localtax (default) --->
	<cfdefaultcase>
	<cfif application.cw.taxSystem eq "groups">
		<!--- Get the product tax information, including current tax rate and tax type --->
		<cfquery name="rs" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT r.tax_rate_percentage as taxrate_percentage, tr.tax_region_label
		FROM cw_tax_regions tr
		RIGHT JOIN ((cw_tax_groups g
		INNER JOIN cw_products p
		ON g.tax_group_id = p.product_tax_group_id)
		LEFT JOIN cw_tax_rates r
		ON g.tax_group_id = r.tax_rate_group_id)
		ON tr.tax_region_id = r.tax_rate_region_id
		WHERE
			p.product_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.product_id#">
			AND (
				(
					tax_region_country_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.country_id#">
					AND tax_region_state_id = 0)
				OR
				(
					tax_region_country_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.country_id#">
					AND tax_region_state_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.region_id#"> )
				)

		</cfquery>
	<cfelse>
		<!--- "general" tax on one or more states -- all products --->
		<cfif arguments.region_id eq 0>
			<cfif CWcountryHasStates(arguments.country_id)>
				<!---  // user is not logged in, and country has states, so no default tax can be assumed --->
				<cfreturn taxRates>
			</cfif>
			<cfquery name="rs" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			SELECT stateprov_tax as taxrate_percentage,
			stateprov_code + ' #application.cw.taxSystemLabel#' as tax_region_label,
			stateprov_name
			FROM cw_stateprov
			WHERE stateprov_country_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.country_id#">
			</cfquery>
		<cfelse>
			<cfquery name="rs" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			SELECT stateprov_tax as taxrate_percentage,
			stateprov_code + ' #application.cw.taxSystemLabel#' as tax_region_label,
			stateprov_name
			FROM cw_stateprov
			WHERE stateprov_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.region_id#">
			</cfquery>
		</cfif>
	</cfif>

	<cfloop query="rs">
		<cfset temp = structNew()>
		<cfset taxRates.displayTax = val(taxRates.displayTax) + val(rs.taxrate_percentage)>
		<cfset temp.Label = rs.tax_region_label>
		<cfset temp.displayTax = val(rs.taxrate_percentage)>
		<cfif temp.displayTax neq 0>
			<cfset temp.calcTax = (temp.displayTax / 100) + 1>
		<cfelse>
			<cfset temp.calcTax = 0>
		</cfif>
		<cfset ArrayAppend(taxRates.rates, temp)>
	</cfloop>

	<cfif val(taxRates.displayTax) neq 0>
		<cfset taxRates.appliedTax = taxRates.displayTax / 100>
		<cfset taxRates.calcTax = (taxRates.displayTax / 100) + 1>
	</cfif>

	</cfdefaultcase>

	</cfswitch>

	<cfreturn taxRates>
</cffunction>

<!--- // ---------- // CWgetCartTax: get whole-cart taxes from API service (i.e. AvaTax) // ---------- // --->
<cffunction name="CWgetCartTax"
			access="public"
			output="false"
			returntype="any"
			hint="gets tax totals for entire cart - not used for localtax tax method"
			>

		<cfargument name="cart_id"
			required="false"
			default="0"
			type="string"
			hint="Customer's cart ID for lookup of totals">

		<cfargument name="customer_id"
			required="false"
			default="0"
			type="string"
			hint="A customer ID to use for lookup of address values">

		<cfargument name="calc_type"
				required="false"
				default="#application.cw.taxCalctype#"
				type="string"
				hint="The type of tax calculation to use, e.g. avatax">

			<cfset var cartTaxData = structNew()>
			<cfset cartTaxData.error = ''>
			<cfset cartTaxData.xml = ''>
			<cfset cartTaxData.amounts = structNew()>

			<!--- override default/empty values with session --->
			<cfif arguments.cart_id eq 0 and isDefined('session.cwclient.cwCartID') and session.cwclient.cwCartID neq 0>
				<cfset arguments.cart_id = session.cwclient.cwCartID>
			</cfif>
			<cfif arguments.customer_id eq 0 and isDefined('session.cwclient.cwCustomerID') and session.cwclient.cwCustomerID neq 0>
				<cfset arguments.customer_id = session.cwclient.cwCustomerID>
			</cfif>

			<!--- if cart id is not available--->
			<cfif arguments.cart_id eq 0>
				<cfset cartTaxData.error = 'Cart Data Unavailable'>
			<!--- if customer id is not available --->
			<cfelseif arguments.customer_id eq 0>
				<cfset cartTaxData.error = 'Address Data Unavailable'>
			<!--- if customer id and cart id provided, continue processing --->
			<cfelse>

			<cfswitch expression="#arguments.calc_type#">
				<!--- AVALARA / AvaTax lookup --->
				<cfcase value="avatax">
					<!--- get array of tax data from ava tax --->
					<cfset cartTaxdata = CWgetAvalaraTax(
						cart_id = arguments.cart_id,
						customer_id = arguments.customer_id
					)>
				</cfcase>
				<!--- /end AvaTax --->

				<!--- default calc type (no processing) --->
				<cfdefaultcase>
					<cfset cartTaxData.error = 'Cart tax unavailable for method #arguments.calc_type#'>
				</cfdefaultcase>
			</cfswitch>

			</cfif>
			<!--- end if cart id / customer id ok --->

			<!--- set posted order xml into request scope for use in checkout processing --->
			<cfset request.cwpage.cartTaxXML = cartTaxData.xml>

			<!--- return error message if any exists --->
			<cfif len(trim(cartTaxData.error))>
				<cfset returnData = cartTaxData.error>
			<!--- if no error, return amounts --->
			<cfelse>
				<cfset returnData = cartTaxData.amounts>
			</cfif>

<!--- return error or amounts structure --->
<cfreturn returnData>

</cffunction>

<!--- // ---------- // get Avalara tax // ---------- // --->
<cffunction name="CWgetAvalaraTax"
			access="public"
			output="false"
			returntype="struct"
			hint="gets cart tax structure from Avalara tax system"
			>

		<cfargument name="cart_id"
			required="false"
			default="0"
			type="string"
			hint="Customer's cart ID for lookup of totals">

		<cfargument name="customer_id"
			required="false"
			default="0"
			type="string"
			hint="A customer ID to use for lookup of address values">

		<cfargument name="error_email"
			required="false"
			default="#application.cw.taxErrorEmail#"
			type="string"
			hint="Address for sending error details">

		<cfargument name="avalara_transaction_type"
			required="false"
			default="SalesOrder"
			type="string"
			hint="The Avalara DocType value (SalesOrder=lookup tax|SalesInvoice=commit tax)">

		<cfargument name="avalara_account"
			required="false"
			default="#application.cw.avalaraID#"
			type="string"
			hint="The account number for the AvaTax account">

		<cfargument name="avalara_license"
			required="false"
			default="#application.cw.avalaraKey#"
			type="string"
			hint="The license key for the AvaTax account">

		<cfargument name="avalara_url"
			required="false"
			default="#application.cw.avalaraUrl#"
			type="string"
			hint="The url for the Avalara transaction server">

		<cfargument name="avalara_default_tax_code"
			required="false"
			default="#application.cw.avalaraDefaultCode#"
			type="string"
			hint="The general tax code used if group code is unavailable">

		<cfargument name="avalara_ship_tax_code"
			required="false"
			default="#application.cw.avalaraDefaultShipCode#"
			type="string"
			hint="The tax code used to get tax on shipping">

		<cfargument name="avalara_company_code"
			required="false"
			default="#application.cw.avalaraCompanyCode#"
			type="string"
			hint="The company location/storefront code for the AvaTaxAccount">

		<cfset var xmlData = structNew()>
		<cfset var orderTaxData = structNew()>
		<cfset var taxData = structNew()>
		<cfset var orderQuery = ''>
		<cfset var itemTaxCode = ''>
		<cfset var mailContent = ''>
		<cfset var temp = ''>
		<cfset var loopCt = ''>
		<cfset var shipVal = ''>
		<cfset var cartDiscountRate = ''>
		<cfset cartTaxData.xml = ''>
		<cfset cartTaxData.error = ''>
		<cfset cartTaxData.response = ''>
		<cfset cartTaxData.amounts = structNew()>
		<cfset cartTaxData.responseData = ''>
		<cfif not right(arguments.avalara_url,1) is '/'>
			<cfset arguments.avalara_url = arguments.avalara_url & '/'>
		</cfif>
		<cfparam name="application.cw.companyShipState" default="#application.cw.companyState#">			
		<!--- get customer id and cart id from session if not implicitly defined --->
		<cfif arguments.customer_id is 0 and isDefined('session.cwclient.cwCustomerID') and session.cwclient.cwCustomerID neq 0>
			<cfset arguments.customer_id = session.cwclient.cwCustomerID>
		</cfif>
		<cfif arguments.cart_id is 0 and isDefined('session.cwclient.cwCartID') and session.cwclient.cwCartID neq 0>
			<cfset arguments.cart_id = session.cwclient.cwCartID>
		</cfif>

				<!--- DEBUG: uncomment to test server availability, should return an AvaTax response of some kind --->
 				<!---
				<cfhttp url="#arguments.avalara_url#address/validate.xml?line1=#replace(application.cw.companyAddress1,' ','+','all')#&postalCode=#application.cw.companyZip#" method="GET">
					<cfhttpparam type="header" name="content-type" value="text/xml">
					<cfhttpparam type="header" name="date" value="#getHttpTimeString(now())#">
					<cfhttpparam type="header" name="Authorization" value="Basic #toBase64(trim(arguments.avalara_account) & ':' &  trim(arguments.avalara_license))#">
				</cfhttp>
				<cfoutput>#cfhttp.filecontent#</cfoutput>
				<cfabort>
				 --->
				<!--- /END DEBUG --->

		<!--- handle errors --->
		<cftry>
			<!--- get customer details --->
			<cfquery name="customerQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			SELECT cw_customers.customer_id,
					cw_customers.customer_type_id,
					cw_customers.customer_first_name,
					cw_customers.customer_last_name,
					cw_customers.customer_phone,
					cw_customers.customer_ship_company,
					cw_customers.customer_ship_name,
					cw_customers.customer_ship_address1,
					cw_customers.customer_ship_address2,
					cw_customers.customer_ship_city,
					cw_customers.customer_ship_zip,
					cw_stateprov.stateprov_name,
					cw_stateprov.stateprov_id,
					cw_stateprov.stateprov_nexus,
					cw_customer_stateprov.customer_state_destination,
					cw_countries.country_name,
					cw_countries.country_code,
					cw_countries.country_id
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


			<!--- if customer record exists --->
			<cfif customerQuery.recordCount and len(trim(customerQuery.customer_ship_zip))>

				<!--- get cart details --->
				<cfset taxCart = CWgetCart(cart_id=arguments.cart_id,product_order='productName',tax_calc_method='none')>


			<!--- if state has nexus and order total gt 0--->
			<cfif customerQuery.stateprov_nexus is 1 and taxCart.carttotals.total gt 0>

				<!--- set up xml data --->
				<cfset xmldata.customerid = trim(arguments.customer_id)>
				<!--- delivery address --->
				<cfset xmlData.shipcompany = customerQuery.customer_ship_company>
				<cfset xmlData.shipname = customerQuery.customer_ship_name>
				<cfset xmlData.shipaddress1 = customerQuery.customer_ship_address1>
				<cfset xmlData.shipaddress2 = customerQuery.customer_ship_address2>
				<cfset xmlData.shipcity = customerQuery.customer_ship_city>
				<cfset xmlData.shipstate = customerQuery.stateprov_name>
				<cfset xmlData.shipcountry = customerQuery.country_code>
				<cfset xmlData.shippostcode = customerQuery.customer_ship_zip>
				<!--- ship from address --->
				<cfset xmlData.fromname = application.cw.companyName>
				<cfset xmlData.fromaddress1 = application.cw.companyAddress1>
				<cfset xmlData.fromaddress2 = application.cw.companyAddress2>
				<cfset xmlData.fromcity = application.cw.companyCity>
				<cfset xmlData.fromstate = application.cw.companyShipState>
				<cfset xmlData.fromcountry = application.cw.companyShipCountry>
				<cfset xmlData.frompostcode = application.cw.companyZip>

<!--- apply global discounts to items for tax purposes --->
<cfset cartDiscountRate = 1-(taxcart.carttotals.cartOrderDiscounts/taxcart.carttotals.base)>

				<!--- if cart has at least one item --->
				<cfif arrayLen(taxcart.cartItems)>

<!--- set up xml transaction content --->
<cfsavecontent variable="cartTaxData.XML">
<cfoutput>
<GetTaxRequest>
	<CustomerCode>#arguments.customer_id#</CustomerCode>
	<DocDate>#dateFormat(now(),'yyyy-mm-dd')#</DocDate>
	<DocCode>#taxCart.cartID#</DocCode>
	<DocType>#arguments.avalara_transaction_type#</DocType>
	<cfif len(trim(arguments.avalara_company_code))><CompanyCode>#arguments.avalara_company_code#</CompanyCode></cfif>
	<cfif arguments.avalara_transaction_type is 'salesInvoice'><Commit>1</Commit></cfif>
	<Addresses>
		<Address>
			<AddressCode>1</AddressCode>
			<Line1><cfif len(trim(xmlData.shipaddress1))>#xmlData.shipaddress1#<cfelse>Unavailable</cfif></Line1>
			<cfif len(trim(xmlData.shipaddress2))><Line2>#xmlData.shipaddress2#</Line2></cfif>
			<cfif len(trim(xmlData.shipcity))><City>#xmlData.shipcity#</City></cfif>
			<cfif len(trim(xmlData.shipstate))><Region>#xmlData.shipstate#</Region></cfif>
			<cfif len(trim(xmlData.shipcountry)) is 2><Country>#xmlData.shipcountry#</Country></cfif>
			<cfif len(trim(xmlData.shippostcode))><PostalCode>#xmlData.shippostcode#</PostalCode></cfif>
		</Address>
		<Address>
			<AddressCode>2</AddressCode>
			<Line1><cfif len(trim(xmlData.fromaddress1))>#xmlData.fromaddress1#<cfelse>Unavailable</cfif></Line1>
			<cfif len(trim(xmlData.fromaddress2))><Line2>#xmlData.fromaddress2#</Line2></cfif>
			<cfif len(trim(xmlData.fromcity))><City>#xmlData.fromcity#</City></cfif>
			<cfif len(trim(xmlData.fromstate))><Region>#xmlData.fromstate#</Region></cfif>
			<cfif len(trim(xmlData.fromcountry)) is 2><Country>#xmlData.fromcountry#</Country></cfif>
			<cfif len(trim(xmlData.frompostcode))><PostalCode>#xmlData.frompostcode#</PostalCode></cfif>
		</Address>
	</Addresses>
	<Lines>
	<cfloop from="1" to="#arrayLen(taxcart.cartItems)#" index="i">
		<cfset itemTaxCode = CWgetSkuTaxCode(taxcart.cartItems[i].skuid)>
		<Line>
			<LineNo>#i#</LineNo>
			<DestinationCode>1</DestinationCode>
			<OriginCode>2</OriginCode>
			<ItemCode>#taxcart.cartitems[i].skuuniqueid#</ItemCode>
			<TaxCode><cfif len(trim(itemTaxCode))>#trim(itemTaxCode)#<cfelse>#arguments.avalara_default_tax_code#</cfif></TaxCode>
			<cfif len(trim(taxcart.cartitems[i].merchskuid))><Description>#taxcart.cartitems[i].merchskuid#</Description></cfif>
			<Qty>#taxcart.cartitems[i].quantity#</Qty>
			<Amount>#taxcart.cartitems[i].subtotal*cartDiscountRate#</Amount>
		</Line>
	</cfloop>
	<cfif application.cw.taxChargeOnShipping and taxCart.cartTotals.shipsubtotal gt 0>
        <cfif isDefined("session.cwclient.cwShipTotal")>
			<cfset shipVal = session.cwclient.cwShipTotal>
		</cfif>
        <cfif isDefined("taxcart.carttotals.shipDiscounts")>
			<cfset shipVal = shipVal - taxcart.carttotals.shipDiscounts>
		</cfif>
        <cfset shipVal = max(0, shipVal)>
		<Line>
			<LineNo>#arrayLen(taxcart.cartItems)+1#</LineNo>
			<DestinationCode>1</DestinationCode>
			<OriginCode>2</OriginCode>
			<ItemCode>ShipTax</ItemCode>
			<TaxCode>#arguments.avalara_ship_tax_code#</TaxCode>
			<Description>Order shipping/delivery</Description>
			<Qty>1</Qty>
			<Amount>#shipVal#</Amount>
		</Line>
		</cfif>
	</Lines>
</GetTaxRequest>
</cfoutput>
</cfsavecontent>

						<!--- DEBUG: uncomment to show formatted XML request data --->
						<!---
						<p>SENDING TO: <cfoutput>#arguments.avalara_url#</cfoutput>tax/get</p>
						<pre><cfdump var="#trim(cartTaxData.xml)#"></pre>
						<cfdump var="#taxCart#" label="Raw cart data">
						<cfabort>
						--->
						<!--- /END DEBUG --->

				<!--- //////////// --->
				<!--- //////////// --->
				<!--- send request  --->
				<!--- //////////// --->
				<!--- //////////// --->

				<cfhttp url="#arguments.avalara_url#tax/get" method="POST">
					<!--- headers --->
					<cfhttpparam type="header" name="content-length" value="#len(cartTaxData.xml)#">
					<cfhttpparam type="header" name="content-type" value="text/xml">
					<cfhttpparam type="header" name="date" value="#getHttpTimeString(now())#">
					<cfhttpparam type="header" name="Authorization" value="Basic #toBase64(trim(arguments.avalara_account) & ':' &  trim(arguments.avalara_license))#">
					<!--- xml request body --->
					<cfhttpparam type="xml" value="#trim(cartTaxData.XML)#">
				</cfhttp>
				<cfset cartTaxData.response = trim(cfhttp.filecontent)>

						<!--- DEBUG: uncomment to show response from server --->
						<!---
						<pre><cfdump var="#cfhttp.filecontent#"></pre>
						<cfabort>
						 --->
						<!--- /END DEBUG --->

				<!--- //////////// --->
				<!--- //////////// --->
				<!--- parse response --->
				<!--- //////////// --->
				<!--- //////////// --->
				<cftry>
					<!--- parse response, add to returned structure --->
					<cfset cartTaxData.responseData = XmlParse(CFHTTP.FileContent)>

						<!--- if status is success--->
						<cfif isDefined('cartTaxData.responseData.GetTaxResult.ResultCode.XmlText')
						and cartTaxData.responseData.GetTaxResult.ResultCode.XmlText is 'Success'>

							<!--- verify order id is correct --->
							<cfif isDefined('cartTaxData.responseData.GetTaxResult.DocCode.XmlText')
							and cartTaxData.responseData.GetTaxResult.DocCode.XmlText is taxCart.cartID>

								<!--- ///////////////////////////////// --->
								<!--- create structure of cart tax data --->
								<!--- ///////////////////////////////// --->

								<!--- total cart tax --->
								<cfset cartTaxData.Amounts.totalCartTax = cartTaxData.responseData.GetTaxResult.TotalTax.XmlText>
								<!--- subtotals: shipping --->
								<cfset cartTaxData.Amounts.totalShipTax = 0>
								<!--- subtotals: cart lines --->
								<cfset cartTaxData.Amounts.cartLines = structNew()>
								<!--- if at least one line returned --->
								<cfif structCount(cartTaxData.responseData.GetTaxResult.TaxLines) gt 0>
									<!--- set amounts for each line --->
									<cfloop from="1" to="#structCount(cartTaxData.responseData.GetTaxResult.TaxLines)#" index="i">
											<!--- get shipping tax if using shipping (since it is always last row, index should remain consistent) --->
											<cfif application.cw.taxChargeOnShipping and taxCart.cartTotals.shipsubtotal gt 0
												AND i eq structCount(cartTaxData.responseData.GetTaxResult.TaxLines)>
												<cfset cartTaxData.Amounts.totalShipTax = cartTaxData.responseData.GetTaxResult.TaxLines.TaxLine[i].Tax.XmlText>
											<cfelse>
												<cfset cartTaxData.Amounts.cartLines[i] = structNew()>
												<cfset cartTaxData.Amounts.cartLines[i].itemTax = cartTaxData.responseData.GetTaxResult.TaxLines.TaxLine[i].Tax.XmlText>
												<cfset cartTaxData.Amounts.cartLines[i].itemID = taxcart.cartitems[i].skuuniqueid>
												<cfset cartTaxData.Amounts.cartLines[i].itemQty = taxcart.cartitems[i].quantity>
												<cfset cartTaxData.Amounts.cartLines[i].itemSubtotal = taxcart.cartitems[i].subtotal>
											</cfif>
									</cfloop>
								</cfif>
								<!--- /end if at least one line --->

							<!--- if order ID does not match --->
							<cfelse>
								<cfset cartTaxData.error = 'Response Transaction ID (DocCode) does not match'>
							</cfif>
							<!--- /end if order id matches --->

						<!--- if not a success message --->
						<cfelseif isDefined('cartTaxData.responseData.GetTaxResult.ResultCode.XmlText')>
							<cfset cartTaxData.error = '#cartTaxData.responseData.GetTaxResult.ResultCode.XmlText#'>
							<!--- parse out avalara error details for detailed response/error message --->
							<cfif isDefined('cartTaxData.responseData.GetTaxResult.Messages.Message.Summary.XmlText')>
								<cfset cartTaxData.error = cartTaxData.error & ': #cartTaxData.responseData.GetTaxResult.Messages.Message.Summary.XmlText#'>
							</cfif>
						<!--- if no message at all --->
						<cfelse>
							<cfset cartTaxData.error = 'Incomplete response: no status returned'>
						</cfif>
				<!--- handle errors --->
				<cfcatch>
					<cfset cartTaxData.error = 'Invalid response: #cfcatch.message#'>
				</cfcatch>
				</cftry>
				<!--- if cart is empty --->
				<cfelse>
					<cfset cartTaxData.error = 'No items available for calculation'>
				</cfif>
			<!--- if state does not have nexus, or cart total is 0 --->
			<cfelse>
					<!--- set empty values --->
					<cfset cartTaxData.Amounts.totalCartTax = 0>
					<cfset cartTaxData.Amounts.totalShipTax = 0>
					<cfset cartTaxData.Amounts.cartLines = structNew()>			
					<cfif customerQuery.stateprov_nexus neq 1>
						<cfset cartTaxData.error = 'Lookup not required for destination'>
					</cfif>
					<cfif taxCart.carttotals.total lte 0>
						<cfset cartTaxData.error = 'Cart total #taxCart.carttotals.total# not eligible'>
					</cfif>
			</cfif>
			<!--- end nexus / cart total check --->
			<!--- if no customer found --->
			<cfelse>
				<cfset cartTaxData.error = 'Destination address unavailable'>
			</cfif>
			<!--- /end if customer exists --->
			
		<!--- handle errors --->
		<cfcatch>
			<cfset cartTaxData.error = 'Tax retrieval incomplete: #cfcatch.message#'>
		</cfcatch>
		</cftry>

		<!--- if enabled, send any error message to the site admin --->
		<cfif len(trim(cartTaxData.error)) and isValid('email',arguments.error_email)
			AND application.cw.taxSendLookupErrors>
			<cfsavecontent variable="mailContent">
			<cfoutput>
			Cart ID: #arguments.cart_id##chr(13)#
			Customer ID: #arguments.customer_id##chr(13)#

			Error:#cartTaxData.error##chr(13)#

			POSTED CART DATA:#chr(13)#
			#cartTaxData.xml##chr(13)#

			AVALARA RESPONSE DATA:#chr(13)#
			#cartTaxData.response##chr(13)#

			</cfoutput>
			</cfsavecontent>
			<!--- send email --->
			<cfset temp = CWsendMail(mailContent, 'AvaTax Processing Error',arguments.error_email)>
			<cfset cartTaxData.error = cartTaxData.error & ' - email notification sent'>
		</cfif>
		<!--- /end send email --->

	<cfreturn cartTaxData>
</cffunction>

<!--- // ---------- // post Avalara order tax // ---------- // --->
<cffunction name="CWpostAvalaraTax"
			access="public"
			output="false"
			returntype="struct"
			hint="posts order data to Avalara tax system"
			>

		<cfargument name="order_id"
			required="true"
			type="string"
			hint="order ID for lookup of totals">

		<cfargument name="refund_order"
			required="false"
			default="false"
			type="boolean"
			hint="If true, amounts are posted as negative to create a refunded tax transaction">

		<cfargument name="error_email"
			required="false"
			default="#application.cw.taxErrorEmail#"
			type="string"
			hint="Address for sending error details">

		<cfargument name="avalara_account"
				required="false"
				default="#application.cw.avalaraID#"
				type="string"
				hint="The account number for the AvaTax account">

		<cfargument name="avalara_license"
				required="false"
				default="#application.cw.avalaraKey#"
				type="string"
				hint="The license key for the AvaTax account">

		<cfargument name="avalara_url"
				required="false"
				default="#application.cw.avalaraUrl#"
				type="string"
				hint="The url for the Avalara transaction server">

		<cfargument name="avalara_default_tax_code"
				required="false"
				default="#application.cw.avalaraDefaultCode#"
				type="string"
				hint="The general tax code used if group code is unavailable">

		<cfargument name="avalara_ship_tax_code"
				required="false"
				default="#application.cw.avalaraDefaultShipCode#"
				type="string"
				hint="The tax code used to get tax on shipping">

		<cfargument name="avalara_company_code"
				required="false"
				default="#application.cw.avalaraCompanyCode#"
				type="string"
				hint="The company location/storefront code for the AvaTaxAccount">

		<cfset var xmlData = structNew()>
		<cfset var orderTaxData = structNew()>
		<cfset var taxData = structNew()>
		<cfset var itemTaxCode = ''>
		<cfset var mailContent = ''>
		<cfset var temp = ''>
		<cfset var loopCt = ''>
		<cfset taxData.xml = ''>
		<cfset orderTaxData.error = ''>
		<cfset orderTaxData.response = ''>
		<cfset orderTaxData.amounts = structNew()>
		<cfset orderTaxData.responseData = ''>
		<cfset orderQuery = ''>
		<cfif not right(arguments.avalara_url,1) is '/'>
			<cfset arguments.avalara_url = arguments.avalara_url & '/'>
		</cfif>
		<cfparam name="application.cw.companyShipState" default="#application.cw.companyState#">	

		<!--- DEBUG: uncomment to test server availability, should return an AvaTax response of some kind --->
		<!---
		<cfhttp url="#arguments.avalara_url#address/validate.xml?line1=#replace(application.cw.companyAddress1,' ','+','all')#&postalCode=#application.cw.companyZip#" method="GET">
			<cfhttpparam type="header" name="content-type" value="text/xml">
			<cfhttpparam type="header" name="date" value="#getHttpTimeString(now())#">
			<cfhttpparam type="header" name="Authorization" value="Basic #toBase64(trim(arguments.avalara_account) & ':' &  trim(arguments.avalara_license))#">
		</cfhttp>
		<cfoutput>#cfhttp.filecontent#</cfoutput>
		<cfabort>
		 --->
		<!--- /END DEBUG --->

		<!--- handle errors --->
		<cftry>
			<!--- get order details --->
			<cfset orderQuery = CWquerySelectOrderDetails(arguments.order_id)>
			<!--- if order record exists --->
			<cfif orderQuery.recordCount>
				<!--- set up xml data --->
				<cfoutput query="orderQuery" maxrows="1">
					<cfset xmldata.customerid = orderQuery.customer_id>
					<cfset xmldata.orderid = orderQuery.order_id>
					<cfset xmldata.orderdate = orderQuery.order_date>
					<cfif arguments.refund_order>
						<cfset xmldata.orderid = xmldata.orderid & '-REF'>
					</cfif>
					<!--- delivery address --->
					<cfset xmlData.shipcompany = orderQuery.order_company>
					<cfset xmlData.shipname = orderQuery.customer_first_name & ' ' & orderQuery.customer_last_name>
					<cfset xmlData.shipaddress1 = orderQuery.order_address1>
					<cfset xmlData.shipaddress2 = orderQuery.order_address2>
					<cfset xmlData.shipcity = orderQuery.order_city>
					<cfset xmlData.shipstate = orderQuery.order_state>
					<!--- country must be 2 letter code --->
					<cfif orderQuery.order_country is 'United States'>
						<cfset xmlData.shipcountry = 'US'>
					<cfelseif orderQuery.order_country is 'Canada'>
						<cfset xmlData.shipcountry = 'CA'>
					<cfelseif len(trim(orderQuery.order_country)) eq 2>
						<cfset xmlData.shipcountry = orderQuery.order_country>
					<cfelse>
						<cfquery name="customerQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
						SELECT cw_customers.customer_id,
								cw_countries.country_code
							FROM (((cw_customers
							INNER JOIN cw_customer_stateprov
							ON cw_customers.customer_id = cw_customer_stateprov.customer_state_customer_id)
							INNER JOIN cw_stateprov
							ON cw_stateprov.stateprov_id = cw_customer_stateprov.customer_state_stateprov_id)
							INNER JOIN cw_countries
							ON cw_countries.country_id = cw_stateprov.stateprov_country_id)
						WHERE cw_customer_stateprov.customer_state_destination='ShipTo'
						AND #application.cw.sqlLower#(customer_id) = '#lcase(orderQuery.customer_id)#'
						</cfquery>
						<cfif customerQuery.recordCount is 1 and len(trim(customerQuery.country_code)) is 2>
							<cfset xmlData.shipcountry = customerQuery.country_code>
						</cfif>
					</cfif>
					<cfset xmlData.shippostcode = orderQuery.order_zip>
				</cfoutput>
					<!--- ship from address --->
					<cfset xmlData.fromname = application.cw.companyName>
					<cfset xmlData.fromaddress1 = application.cw.companyAddress1>
					<cfset xmlData.fromaddress2 = application.cw.companyAddress2>
					<cfset xmlData.fromcity = application.cw.companyCity>
					<cfset xmlData.fromstate = application.cw.companyShipState>
					<cfset xmlData.fromcountry = application.cw.companyShipCountry>
					<cfset xmlData.frompostcode = application.cw.companyZip>

<!--- set up xml transaction content --->
<cfsavecontent variable="orderTaxData.XML">
<cfoutput>
<GetTaxRequest>
	<CustomerCode>#xmldata.customerid#</CustomerCode>
	<DocDate>#dateFormat(now(),'yyyy-mm-dd')#</DocDate>
	<DocCode>#xmldata.orderid#</DocCode>
	<DocType>SalesInvoice</DocType>
	<cfif len(trim(arguments.avalara_company_code))><CompanyCode>#arguments.avalara_company_code#</CompanyCode></cfif>
	<Commit>1</Commit>
	<Addresses>
		<Address>
			<AddressCode>1</AddressCode>
			<Line1><cfif len(trim(xmlData.shipaddress1))>#xmlData.shipaddress1#<cfelse>Unavailable</cfif></Line1>
			<cfif len(trim(xmlData.shipaddress2))><Line2>#xmlData.shipaddress2#</Line2></cfif>
			<cfif len(trim(xmlData.shipcity))><City>#xmlData.shipcity#</City></cfif>
			<cfif len(trim(xmlData.shipstate))><Region>#xmlData.shipstate#</Region></cfif>
			<cfif len(trim(xmlData.shipcountry)) is 2><Country>#xmlData.shipcountry#</Country></cfif>
			<cfif len(trim(xmlData.shippostcode))><PostalCode>#xmlData.shippostcode#</PostalCode></cfif>
		</Address>
		<Address>
			<AddressCode>2</AddressCode>
			<Line1><cfif len(trim(xmlData.fromaddress1))>#xmlData.fromaddress1#<cfelse>Unavailable</cfif></Line1>
			<cfif len(trim(xmlData.fromaddress2))><Line2>#xmlData.fromaddress2#</Line2></cfif>
			<cfif len(trim(xmlData.fromcity))><City>#xmlData.fromcity#</City></cfif>
			<cfif len(trim(xmlData.fromstate))><Region>#xmlData.fromstate#</Region></cfif>
			<cfif len(trim(xmlData.fromcountry)) is 2><Country>#xmlData.fromcountry#</Country></cfif>
			<cfif len(trim(xmlData.frompostcode))><PostalCode>#xmlData.frompostcode#</PostalCode></cfif>
		</Address>
	</Addresses>
	<Lines>
	<cfset loopCt = 0>
	<cfloop query="orderQuery">
		<cfset loopCt = loopCt + 1>
		<cfset itemTaxCode = CWgetSkuTaxCode(orderQuery.ordersku_sku)>
		<Line>
			<LineNo>#loopCt#</LineNo>
			<DestinationCode>1</DestinationCode>
			<OriginCode>2</OriginCode>
			<ItemCode>#orderQuery.ordersku_unique_id#</ItemCode>
			<TaxCode><cfif len(trim(itemTaxCode))>#trim(itemTaxCode)#<cfelse>#arguments.avalara_default_tax_code#</cfif></TaxCode>
			<cfif len(trim(orderQuery.sku_merchant_sku_id))><Description>#orderQuery.sku_merchant_sku_id#</Description></cfif>
			<Qty>#orderQuery.ordersku_quantity#</Qty>
			<Amount><cfif arguments.refund_order>-</cfif>#orderQuery.ordersku_sku_total#</Amount>
		</Line>
	</cfloop>
		<cfif application.cw.taxChargeOnShipping and orderQuery.order_shipping gt 0>
		<Line>
			<LineNo>#loopCt+1#</LineNo>
			<DestinationCode>1</DestinationCode>
			<OriginCode>2</OriginCode>
			<ItemCode>ShipTax</ItemCode>
			<TaxCode>#arguments.avalara_ship_tax_code#</TaxCode>
			<Description>Order shipping/delivery</Description>
			<Qty>1</Qty>
			<Amount><cfif arguments.refund_order>-</cfif>#orderQuery.order_shipping#</Amount>
		</Line>
		</cfif>
	</Lines>
</GetTaxRequest>
</cfoutput>
</cfsavecontent>

	<!--- DEBUG: uncomment to show formatted XML request data --->
	<!---
	<p>SENDING TO: <cfoutput>#arguments.avalara_url#</cfoutput>tax/get</p>
	<pre><cfdump var="#trim(orderTaxData.xml)#"></pre>
	<cfabort>
	 --->
	<!--- /END DEBUG --->

				<!--- //////////// --->
				<!--- //////////// --->
				<!--- send request  --->
				<!--- //////////// --->
				<!--- //////////// --->

				<cfhttp url="#arguments.avalara_url#tax/get" method="POST">
					<!--- headers --->
					<cfhttpparam type="header" name="content-length" value="#len(orderTaxData.xml)#">
					<cfhttpparam type="header" name="content-type" value="text/xml">
					<cfhttpparam type="header" name="date" value="#getHttpTimeString(now())#">
					<cfhttpparam type="header" name="Authorization" value="Basic #toBase64(trim(arguments.avalara_account) & ':' &  trim(arguments.avalara_license))#">
					<!--- xml request body --->
					<cfhttpparam type="xml" value="#trim(orderTaxData.XML)#">
				</cfhttp>
				<cfset orderTaxData.response = trim(cfhttp.filecontent)>


						<!--- DEBUG: uncomment to show response from server --->
						<!---
						<pre><cfdump var="#cfhttp.filecontent#"></pre>
						<cfabort>
						 --->
						<!--- /END DEBUG --->

				<!--- //////////// --->
				<!--- //////////// --->
				<!--- handle errors --->
				<!--- //////////// --->
				<!--- //////////// --->
				<cftry>
					<!--- parse response, add to returned structure --->
					<cfset orderTaxData.responseData = XmlParse(CFHTTP.FileContent)>

						<!--- if status is success--->
						<cfif isDefined('orderTaxData.responseData.GetTaxResult.ResultCode.XmlText')
						and orderTaxData.responseData.GetTaxResult.ResultCode.XmlText is 'Success'>

							<!--- if order ID does not match --->
							<!--- verify order id is correct --->
							<cfif NOT (isDefined('orderTaxData.responseData.GetTaxResult.DocCode.XmlText')
							and orderTaxData.responseData.GetTaxResult.DocCode.XmlText is xmldata.orderid)>
								<cfset orderTaxData.error = 'Response Transaction ID (DocCode) does not match'>
							</cfif>
							<!--- /end if order id matches --->

						<!--- if not a success message --->
						<cfelseif isDefined('orderTaxData.responseData.GetTaxResult.ResultCode.XmlText')>
							<cfset orderTaxData.error = '#orderTaxData.responseData.GetTaxResult.ResultCode.XmlText#'>
							<!--- parse out avalara error details for detailed response/error message --->
							<cfif isDefined('orderTaxData.responseData.GetTaxResult.Messages.Message.Summary.XmlText')>
								<cfset orderTaxData.error = orderTaxData.error & ': #orderTaxData.responseData.GetTaxResult.Messages.Message.Summary.XmlText#'>
							</cfif>
						<!--- if no message at all --->
						<cfelse>
							<cfset orderTaxData.error = 'Incomplete response: no status returned'>
						</cfif>
				<!--- handle errors --->
				<cfcatch>
					<cfset orderTaxData.error = 'Invalid response: #cfcatch.message#'>
				</cfcatch>
				</cftry>
			<!--- if no order found --->
			<cfelse>
				<cfset orderTaxData.error = 'Order details unavailable'>
			</cfif>
			<!--- /end if customer exists --->
		<!--- handle errors --->
		<cfcatch>
			<cfset orderTaxData.error = 'Tax retrieval incomplete: #cfcatch.message#'>
		</cfcatch>
		</cftry>

		<!--- if enabled, send any error message to the site admin --->
		<cfif len(trim(orderTaxData.error)) and isValid('email',arguments.error_email)>
			<cfsavecontent variable="mailContent">
			<cfoutput>
			Order ID: #arguments.order_id##chr(13)#

			Error:#orderTaxData.error##chr(13)#

			AVALARA RESPONSE VALUES:#chr(13)#
			#orderTaxData.response##chr(13)#

			</cfoutput>
			</cfsavecontent>
			<!--- send email --->
			<cfset temp = CWsendMail(mailContent, 'AvaTax Processing Error',arguments.error_email)>
			<cfset orderTaxData.error = orderTaxData.error & ' - email notification sent'>
		</cfif>
		<!--- /end send email --->

	<cfreturn orderTaxData>
</cffunction>

<!--- // ---------- // CWgetSkuTaxCode // ---------- // --->
<cffunction name="CWgetSkuTaxCode"
			access="public"
			output="false"
			returntype="string"
			hint="Returns tax group code for a given sku"
			>

	<cfargument name="sku_id"
			required="true"
			type="numeric"
			hint="The sku id to look up">
			>

	<cfset var returnStr = ''>
	<cfset var rs = ''>

	<cfquery name="rs" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT tax_group_code
	FROM cw_tax_groups, cw_products, cw_skus
	WHERE cw_skus.sku_id = #arguments.sku_id#
	AND cw_products.product_id = cw_skus.sku_product_id
	AND cw_tax_groups.tax_group_id = cw_products.product_tax_group_id
	AND NOT cw_tax_groups.tax_group_archive = 1
	</cfquery>
	<cfif rs.recordCount>
		<cfset returnStr = rs.tax_group_code>
	</cfif>

<cfreturn returnStr>
</cffunction>

</cfsilent>