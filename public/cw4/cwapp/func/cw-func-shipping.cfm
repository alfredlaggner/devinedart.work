<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-func-shipping.cfm
File Date: 2012-12-30
Description: manages shipping methods, shipping costs, and related queries
Dependencies: requires cw-func-query and cw-func-cart to be included in calling page
==========================================================
NOTES:
Function: Calculate Shipping Rates (CWgetShipRate)

- Calculation Types
Shipping rates are figured either through "local calculation (localcalc)",
where we use the ranges set in the CW admin for this method, by country,
OR through another method, e.g. "ups calculation (upsgroundcalc)", which looks up
shipping rates through a live shipping API (FedEx, UPS, USPS).

- Adding Calculation Types
Additional methods may be added, with corresponding options in the
Shipping Methods area of the Cartweaver admin.

- Local Calculation variables
There are three possible variables used for calculating local shipping;
a base shipping fee, shipping by range, and a shipping
extension by location.  Shipping charges can be a result of any
one of these or a combination. This criteria is set in the admin
section on the Company Information Page.

- UPS/FedEx/USPS
For general purposes, the UPS, US Postal(USPS) and FedEx rates are calculated using the values for
Company Info in the CW admin, and the stored customer address details.

The rate functions can be modified to accept variables for package dimensions,
separate ship from address, additional shipping methods, and custom ship to
address info, along with other options in the shipping method's own API (see USPS/UPS/FedEx documentation for details)

IMPORTANT: Values returned by these functions may vary from actual shipping rates.
Live lookups "calculated weight" depending on package size and other variables.
Your default packaging options can be set directly in the XML content
for the various shipping rate functions below.
--->
<!--- // ---------- // Get Shipping Cost // ---------- // --->
<cffunction name="CWgetShipRate"
	access="public"
	output="false"
	returntype="string"
	hint="Calculates shipping rate through various methods.
	Returns a numeric rate or a string error message"
	>

	<cfargument name="ship_method_id"
		required="true"
		type="numeric"
		hint="The ID of the shipping method to use. Required.">

	<cfargument name="cart_id"
		required="false"
		default="0"
		type="string"
		hint="Customer's cart ID for lookup of totals - can be passed in directly below">

	<cfargument name="calc_type"
		required="false"
		default="localcalc"
		type="any"
		hint="The type of calculation method to use (localcalc = lookup from cw db).
		If a method id is provided, this value is taken from the lookup.">

	<!--- default values for cart totals - this function can be used without a cart id --->
	<cfargument name="cart_weight"
		required="false"
		default="0"
		type="numeric"
		hint="Used if cart ID is not provided">

	<cfargument name="cart_total"
		required="false"
		default="0"
		type="numeric"
		hint="Used if cart ID is not provided">

	<cfargument name="charge_sku_base"
		required="false"
		default="true"
		type="boolean"
		hint="Include the product base rates (carttotals.shipproductbase) in the returned cost (y/n)">

	<cfargument name="sku_base_amount"
		required="false"
		default="0"
		type="numeric"
		hint="Value to use for base amount of sku shipping (if cart id not provided)">

	<!--- defaults in client scope for customer id, shipping country and region, can be passed in to override --->
	<cfargument name="customer_id"
		required="false"
		default="#session.cwclient.cwCustomerID#"
		type="string"
		hint="Customer ID for lookup of address info (remote methods)">

	<cfargument name="ship_country_id"
		required="false"
		default="#session.cwclient.cwShipCountryID#"
		type="any"
		hint="ID of the customer's shipping country">

	<cfargument name="ship_region_id"
		required="false"
		default="#session.cwclient.cwShipRegionID#"
		type="any"
		hint="ID of the customer's shipping region or state/prov">

	<!--- optional arguments, defaults set in application --->
	<cfargument name="range_type"
		required="false"
		default="#application.cw.shipChargeBasedOn#"
		type="string"
		hint="Determines how ship ranges are calculated (none|subtotal|weight)">

	<cfargument name="charge_method_base"
		required="false"
		default="#application.cw.shipChargeBase#"
		type="boolean"
		hint="Include the given shipping method's base rate in the returned cost (y/n)">

	<cfargument name="charge_extension"
		required="false"
		default="#application.cw.shipChargeExtension#"
		type="boolean"
		hint="Include the location extension value in the returned cost (y/n)">

	<cfargument name="discount_amount"
			required="false"
			default="0"
			type="numeric"
			hint="A discount amount to be subtracted from the returned total">

	<!--- if using UPS, set or pass in these variables --->
	<cfargument name="ups_access_license"
		required="false"
		default="#application.cw.upsAccessLicense#"
		type="string"
		hint="UPS Access License">

	<cfargument name="ups_userid"
		required="false"
		default="#application.cw.upsUserID#"
		type="string"
		hint="UPS user ID">

	<cfargument name="ups_password"
		required="false"
		default="#application.cw.upsPassword#"
		type="string"
		hint="UPS account password">

	<cfargument name="ups_url"
		required="false"
		default="#application.cw.upsUrl#"
		type="string"
		hint="UPS Server Address">

	<cfargument name="weight_uom"
		required="false"
		default="#application.cw.shipWeightUOM#"
		type="string"
		hint="Weight unit of measure (lbs|kgs)">

	<!--- if using FEDEX, set or pass in these variables --->
	<cfargument name="fedex_access_key"
		required="false"
		default="#application.cw.fedexAccessKey#"
		type="string"
		hint="FedEx account access key">

	<cfargument name="fedex_password"
		required="false"
		default="#application.cw.fedexPassword#"
		type="string"
		hint="FedEx account password">

	<cfargument name="fedex_account_number"
		required="false"
		default="#application.cw.fedexAccountNumber#"
		type="string"
		hint="FedEx account access key">

	<cfargument name="fedex_meternumber"
		required="false"
		default="#application.cw.fedexMeterNumber#"
		type="string"
		hint="FedEx account meter number">

	<cfargument name="fedex_url"
		required="false"
		default="#application.cw.fedexUrl#"
		type="string"
		hint="FedEx Server Address">

	<!--- if using USPS, set or pass in these variables --->
	<cfargument name="usps_userid"
		required="false"
		default="#application.cw.uspsUserID#"
		type="string"
		hint="USPS user ID">

	<cfargument name="usps_password"
		required="false"
		default="#application.cw.uspsPassword#"
		type="string"
		hint="USPS account password">

	<cfargument name="usps_url"
		required="false"
		default="#application.cw.uspsUrl#"
		type="string"
		hint="USPS Server Address">		

	<!--- package dimensions --->
	<cfargument name="package_width"
		required="false" 
		default="10"
		type="numeric">
		
	<cfargument name="package_length"
		required="false" 
		default="12"
		type="numeric">
		
	<cfargument name="package_height"
		required="false" 
		default="7"
		type="numeric">
		
	<cfargument name="package_girth"
		required="false" 
		default="46"
		type="numeric">
		
	<!--- FUNCTION DEFAULTS: DO NOT CHANGE --->
	<cfset var calcValue = 0>
	<cfset var methodQuery = ''>
	<cfset var baseShipRate = 0>
	<cfset var baseProductRate = 0>
	<cfset var rangeValue = 0>
	<cfset var rateValue = 0>
	<cfset var extensionRate = 0>
	<cfset var shipSubCalc = 0>
	<cfset var shipDiscountAmount = 0>
	<cfset var shipDiscountTotal = 0>
	<cfset var cartWeight = 0>
	<cfset var cartTotal = 0>
	<cfset var calcType = 0>
	<!--- get cart data --->
	<cfset var shipcart = cwGetCart(arguments.cart_id)>
	<!--- get cart shipping discount total if not provided --->
	<cfif arguments.discount_amount is 0 and isDefined('shipcart.cartottals.shiporderdiscounts')
		and shipcart.carttotals.shiporderdiscounts gt 0>
			<cfset arguments.discount_amount = shipcart.carttotals.shiporderdiscounts>
	</cfif>

	<!--- handle totals if cart id not provided --->
	<cfif arguments.cart_id gt 0>
		<cfset cartweight = shipCart.carttotals.shipweight>
		<cfset carttotal = shipCart.carttotals.base-shipCart.carttotals.shipitemdiscounts>
	<cfelse>
		<cfset cartweight = arguments.cart_weight>
		<cfset carttotal = arguments.cart_total>
	</cfif>

	<!--- avoid zero weight --->
	<cfif not cartweight gt 0>
		<cfset cartweight = 1>
	</cfif>

	<!--- get calctype for method if a method id is provided --->
	<cfif arguments.ship_method_id gt 0>
		<cfset calctype = CWgetShipMethodCalctype(arguments.ship_method_id)>
	<cfelse>
		<cfset calctype = trim(arguments.calc_type)>
	</cfif>

	<!--- start error catching --->
	<cftry>
		<!--- get details of shipping method --->
		<cfset methodQuery = CWgetShipMethodDetails(
			ship_method_id=arguments.ship_method_id,
			cart_id=arguments.cart_id,
			range_type=arguments.range_type,
			ship_country_id=arguments.ship_country_id,
			cart_weight=cartweight,
			cart_total=carttotal
			)>

		<!--- base rate for this shipping method --->
		<cfif arguments.charge_method_base and isNumeric(methodQuery.ship_method_rate)>
			<cfset baseShipRate = methodQuery.ship_method_rate>
		</cfif>
		<!--- add sku base rate total from cart --->
		<cfif arguments.charge_sku_base>
			<!--- if no cart provided --->
			<cfif arguments.cart_id eq 0>
				<cfset baseShipRate = baseShipRate + arguments.sku_base_amount>
			<cfelse>
			<!--- if cart provided --->
				<cfset baseShipRate = baseShipRate + shipCart.carttotals.shipproductbase>
			</cfif>
		</cfif>

		<!--- if total is 0 due to shipitem discounts, ship range should not be calculated --->
		<cfif shipcart.carttotals.base lte shipcart.carttotals.shipitemdiscounts>
			<cfset arguments.range_type = 'none'>
			<cfset calctype = 'localcalc'>
		<!--- if weight and subtotal for shipping are both 0, no shipping applies --->
		<cfelseif shipcart.carttotals.shipweight eq 0 and shipcart.carttotals.shipsubtotal eq 0>
			<cfset arguments.range_type = 'none'>
			<cfset calctype = 'localcalc'>
		</cfif>

		<!--- SWITCH FOR CALCULATION TYPES - look up by range, or remote --->
		<cfswitch expression="#calctype#">
			<!--- note: copy any cfcase block to add new ship calc types --->
			<!--- UPS GROUND --->
			<cfcase value="upsgroundcalc">
				<!--- lookup ups rate, passing arguments through --->
				<cfset rateValue = CWgetUpsRate(
					ups_license=arguments.ups_access_license,
					ups_userid=arguments.ups_userid,
					ups_password=arguments.ups_password,
					ups_url=arguments.ups_url,
					ups_service_code='03',
					customer_id=arguments.customer_id,
					weight_val=cartweight,
					weight_uom=arguments.weight_uom,
					package_width=arguments.package_width,
					package_length=arguments.package_length,
					package_height=arguments.package_height
					)>
				<!--- if numeric rate is not returned, handle error string --->
				<cfif len(trim(rateValue)) and not isNumeric(rateValue)>
					<cfset calcValue = trim(rateValue)>
				</cfif>				
			</cfcase>
			<!--- UPS 2-DAY --->
			<cfcase value="ups2daycalc">
				<!--- lookup ups rate, passing arguments through --->
				<cfset rateValue = CWgetUpsRate(
					ups_license=arguments.ups_access_license,
					ups_userid=arguments.ups_userid,
					ups_password=arguments.ups_password,
					ups_url=arguments.ups_url,
					ups_service_code='02',
					customer_id=arguments.customer_id,
					weight_val=cartweight,
					weight_uom=arguments.weight_uom,
					package_width=arguments.package_width,
					package_length=arguments.package_length,
					package_height=arguments.package_height
					)>
				<!--- if numeric rate is not returned, handle error string --->
				<cfif len(trim(rateValue)) and not isNumeric(rateValue)>
					<cfset calcValue = trim(rateValue)>
				</cfif>
			</cfcase>
			<!--- UPS 3-DAY --->
			<cfcase value="ups3daycalc">
				<!--- lookup ups rate, passing arguments through --->
				<cfset rateValue = CWgetUpsRate(
					ups_license=arguments.ups_access_license,
					ups_userid=arguments.ups_userid,
					ups_password=arguments.ups_password,
					ups_url=arguments.ups_url,
					ups_service_code='12',
					customer_id=arguments.customer_id,
					weight_val=cartweight,
					weight_uom=arguments.weight_uom,
					package_width=arguments.package_width,
					package_length=arguments.package_length,
					package_height=arguments.package_height
					)>
				<!--- if numeric rate is not returned, handle error string --->
				<cfif len(trim(rateValue)) and not isNumeric(rateValue)>
					<cfset calcValue = trim(rateValue)>
				</cfif>
			</cfcase>
			<!--- UPS NEXT DAY --->
			<cfcase value="upsnextdaycalc">
				<!--- lookup ups rate, passing arguments through --->
				<cfset rateValue = CWgetUpsRate(
					ups_license=arguments.ups_access_license,
					ups_userid=arguments.ups_userid,
					ups_password=arguments.ups_password,
					ups_url=arguments.ups_url,
					ups_service_code='01',
					customer_id=arguments.customer_id,
					weight_val=cartweight,
					weight_uom=arguments.weight_uom,
					package_width=arguments.package_width,
					package_length=arguments.package_length,
					package_height=arguments.package_height
					)>
				<!--- if numeric rate is not returned, handle error string --->
				<cfif len(trim(rateValue)) and not isNumeric(rateValue)>
					<cfset calcValue = trim(rateValue)>
				</cfif>
			</cfcase>
			<!--- FedEx GROUND --->
			<cfcase value="fedexgroundcalc">
				<!--- lookup ups rate, passing arguments through --->
				<cfset rateValue = CWgetFedexRate(
					fedex_access_key=arguments.fedex_access_key,
					fedex_password=arguments.fedex_password,
					fedex_account_number=arguments.fedex_account_number,
					fedex_meternumber=arguments.fedex_meternumber,
					fedex_url=arguments.fedex_url,
					fedex_service='FEDEX_GROUND',
					customer_id=arguments.customer_id,
					weight_val=cartweight,
					weight_uom=arguments.weight_uom,
					package_width=arguments.package_width,
					package_length=arguments.package_length,
					package_height=arguments.package_height
					)>
				<!--- if numeric rate is not returned, handle error string --->
				<cfif len(trim(rateValue)) and not isNumeric(rateValue)>
					<cfset calcValue = trim(rateValue)>
				</cfif>
			</cfcase>
			<!--- FedEx PRIORITY OVERNIGHT --->
<!---			<cfcase value="fedexpriorityovernightcalc">
				<!--- lookup ups rate, passing arguments through --->
				<cfset rateValue = CWgetFedexRate(
					fedex_access_key=arguments.fedex_access_key,
					fedex_password=arguments.fedex_password,
					fedex_account_number=arguments.fedex_account_number,
					fedex_meternumber=arguments.fedex_meternumber,
					fedex_url=arguments.fedex_url,
					fedex_service='PRIORITY_OVERNIGHT',
					customer_id=arguments.customer_id,
					weight_val=cartweight,
					weight_uom=arguments.weight_uom
					)>
				<!--- if numeric rate is not returned, handle error string --->
				<cfif len(trim(rateValue)) and not isNumeric(rateValue)>
					<cfset calcValue = trim(rateValue)>
				</cfif>
			</cfcase> --->
			<!--- FedEx STANDARD OVERNIGHT --->
			<cfcase value="fedexstandardovernightcalc">
				<!--- lookup ups rate, passing arguments through --->
				<cfset rateValue = CWgetFedexRate(
					fedex_access_key=arguments.fedex_access_key,
					fedex_password=arguments.fedex_password,
					fedex_account_number=arguments.fedex_account_number,
					fedex_meternumber=arguments.fedex_meternumber,
					fedex_url=arguments.fedex_url,
					fedex_service='STANDARD_OVERNIGHT',
					customer_id=arguments.customer_id,
					weight_val=cartweight,
					weight_uom=arguments.weight_uom,
					package_width=arguments.package_width,
					package_length=arguments.package_length,
					package_height=arguments.package_height
					)>
					
				<!--- if numeric rate is not returned, handle error string --->
				<cfif len(trim(rateValue)) and not isNumeric(rateValue)>
					<cfset calcValue = trim(rateValue)>
				</cfif>
			</cfcase>
			<!--- FedEx FIRST OVERNIGHT --->
<!---			<cfcase value="fedexfirstovernightcalc">
				<!--- lookup ups rate, passing arguments through --->
				<cfset rateValue = CWgetFedexRate(
					fedex_access_key=arguments.fedex_access_key,
					fedex_password=arguments.fedex_password,
					fedex_account_number=arguments.fedex_account_number,
					fedex_meternumber=arguments.fedex_meternumber,
					fedex_url=arguments.fedex_url,
					fedex_service='FIRST_OVERNIGHT',
					customer_id=arguments.customer_id,
					weight_val=cartweight,
					weight_uom=arguments.weight_uom
					)>
				<!--- if numeric rate is not returned, handle error string --->
				<cfif len(trim(rateValue)) and not isNumeric(rateValue)>
					<cfset calcValue = trim(rateValue)>
				</cfif>
			</cfcase>--->
			<!--- FedEx TWO DAY --->
			<cfcase value="fedex2daycalc">
				<!--- lookup ups rate, passing arguments through --->
				<cfset rateValue = CWgetFedexRate(
					fedex_access_key=arguments.fedex_access_key,
					fedex_password=arguments.fedex_password,
					fedex_account_number=arguments.fedex_account_number,
					fedex_meternumber=arguments.fedex_meternumber,
					fedex_url=arguments.fedex_url,
					fedex_service='FEDEX_2_DAY',
					customer_id=arguments.customer_id,
					weight_val=cartweight,
					weight_uom=arguments.weight_uom,
					package_width=arguments.package_width,
					package_length=arguments.package_length,
					package_height=arguments.package_height
					)>
				<!--- if numeric rate is not returned, handle error string --->
				<cfif len(trim(rateValue)) and not isNumeric(rateValue)>
					<cfset calcValue = trim(rateValue)>
				</cfif>
			</cfcase>
			<!--- FedEx EXPRESS SAVER --->
<!---			<cfcase value="fedexexpresssavercalc">
				<!--- lookup ups rate, passing arguments through --->
				<cfset rateValue = CWgetFedexRate(
					fedex_access_key=arguments.fedex_access_key,
					fedex_password=arguments.fedex_password,
					fedex_account_number=arguments.fedex_account_number,
					fedex_meternumber=arguments.fedex_meternumber,
					fedex_url=arguments.fedex_url,
					fedex_service='FEDEX_EXPRESS_SAVER',
					customer_id=arguments.customer_id,
					weight_val=cartweight,
					weight_uom=arguments.weight_uom
					)>
				<!--- if numeric rate is not returned, handle error string --->
				<cfif len(trim(rateValue)) and not isNumeric(rateValue)>
					<cfset calcValue = trim(rateValue)>
				</cfif>
			</cfcase>--->
			<!--- USPS FIRST CLASS --->
			<cfcase value="uspsfirstclasscalc">
				<!--- lookup usps rate, passing arguments through --->
				<cfset rateValue = CWgetUspsRate(
					usps_userid=arguments.usps_userid,
					usps_password=arguments.usps_password,
					usps_url=arguments.usps_url,
					usps_service='FIRST CLASS',
					customer_id=arguments.customer_id,
					weight_val=cartweight,
					weight_uom=arguments.weight_uom,
					package_width=arguments.package_width,
					package_length=arguments.package_length,
					package_height=arguments.package_height,
					package_girth=arguments.package_girth
					)>
				<!--- if numeric rate is not returned, handle error string --->
				<cfif len(trim(rateValue)) and not isNumeric(rateValue)>
					<cfset calcValue = trim(rateValue)>
				</cfif>
			</cfcase>
			<!--- USPS PRIORITY --->
			<cfcase value="uspsprioritycalc">
				<!--- lookup usps rate, passing arguments through --->
				<cfset rateValue = CWgetUspsRate(
					usps_userid=arguments.usps_userid,
					usps_password=arguments.usps_password,
					usps_url=arguments.usps_url,
					usps_service='PRIORITY',
					customer_id=arguments.customer_id,
					weight_val=cartweight,
					weight_uom=arguments.weight_uom,
					package_width=arguments.package_width,
					package_length=arguments.package_length,
					package_height=arguments.package_height,
					package_girth=arguments.package_girth
					)>
				<!--- if numeric rate is not returned, handle error string --->
				<cfif len(trim(rateValue)) and not isNumeric(rateValue)>
					<cfset calcValue = trim(rateValue)>
				</cfif>
			</cfcase>
			<!--- USPS EXPRESS --->
			<cfcase value="uspsexpresscalc">
				<cfset rateValue = CWgetUspsRate(
					usps_userid=arguments.usps_userid,
					usps_password=arguments.usps_password,
					usps_url=arguments.usps_url,
					usps_service='EXPRESS',
					customer_id=arguments.customer_id,
					weight_val=cartweight,
					weight_uom=arguments.weight_uom,
					package_width=arguments.package_width,
					package_length=arguments.package_length,
					package_height=arguments.package_height,
					package_girth=arguments.package_girth
					)>
				<cfif len(trim(rateValue)) and not isNumeric(rateValue)>
					<cfset calcValue = trim(rateValue)>
				</cfif>
			</cfcase> 
			<!--- USPS PARCEL POST --->
			<cfcase value="uspsparcelcalc">
				<!--- lookup usps rate, passing arguments through --->
				<cfset rateValue = CWgetUspsRate(
					usps_userid=arguments.usps_userid,
					usps_password=arguments.usps_password,
					usps_url=arguments.usps_url,
					usps_service='PARCEL',
					customer_id=arguments.customer_id,
					weight_val=cartweight,
					weight_uom=arguments.weight_uom,
					package_width=arguments.package_width,
					package_length=arguments.package_length,
					package_height=arguments.package_height,
					package_girth=arguments.package_girth
					)>
				<!--- if numeric rate is not returned, handle error string --->
				<cfif len(trim(rateValue)) and not isNumeric(rateValue)>
					<cfset calcValue = trim(rateValue)>
				</cfif>
			</cfcase>
			<!--- DEFAULT (localcalc) --->
			<!--- DEFAULT (localcalc) --->
			<!--- DEFAULT (localcalc) --->
			<cfdefaultcase>
				<!--- get the range rate --->
				<cfif arguments.range_type neq 'none'>
					<cfset rangeValue = methodQuery.ship_range_amount>
				</cfif>
			</cfdefaultcase>
		</cfswitch>
		
		<!--- attempt fallback lookup from ranges --->
		<!--- if error message returned from a live lookup, and not in test mode --->
		<cfif calctype neq 'localcalc' and not application.cw.appTestModeEnabled>		
		<!--- get ship method and range rate with default range_type --->
		<cfset methodQuery = CWgetShipMethodDetails(
			ship_method_id=arguments.ship_method_id,
			cart_id=arguments.cart_id,
			range_type=application.cw.shipChargeBasedOn,
			ship_country_id=arguments.ship_country_id,
			cart_weight=cartweight,
			cart_total=carttotal,
			match_range=true,
			localcalc_only=false
			)>			
			<!--- set range value if applied --->
			<cfif isNumeric(methodQuery.ship_range_amount) and methodQuery.ship_range_amount gte 0>
				<cfset rangeValue = methodQuery.ship_range_amount>
				<cfset rateValue = 0>			
				<cfset calcValue = rangeValue>	
			<!--- if no shipping value returned, use original string --->
			<cfelse>	
				<cfset calcValue = trim(calcValue)>
			</cfif>
		</cfif>
		<!--- /end fallback from ranges --->
		
		<!--- add range or rate value to combined base rate subtotal (defaults 0, set above) --->
		<cfif isNumeric(rangeValue) and isNumeric(rateValue)>
			<cfset shipSubCalc = baseShipRate + rangeValue + rateValue>
		<cfelse>
			<cfset shipSubCalc = baseShipRate>
		</cfif>
		<!--- if using shipping locale extension --->
		<cfif arguments.charge_extension>
			<!--- look up extension by region id --->
			<cfset extensionRate = CWgetShipExtension(arguments.ship_region_id)>
			<cfset extensionCost = CWcalculateTax(shipSubCalc, extensionRate)>
			<cfset shipSubCalc = shipSubCalc + extensionCost>
		</cfif>

		<!--- handle ship discount percentages if amount not defined --->
		<cfif isDefined('shipcart.carttotals.shiporderdiscountpercent')
			and shipcart.carttotals.shiporderdiscountpercent gt 0
			and arguments.discount_amount eq 0>
			<!--- get rounded amount --->
			<cfset arguments.discount_amount = min(shipSubCalc,round((shipSubCalc * shipcart.carttotals.shiporderdiscountpercent/100)*100)/100)>
		</cfif>

		<!--- subtract any cart shipping discounts from total --->
		<cfset shipSubCalc = shipSubCalc - arguments.discount_amount>
		<!--- round to 2 places --->
		<cfif isNumeric(shipSubCalc) and isNumeric(calcValue)>
			<cfset calcValue = round(shipSubCalc*100)/100>
		</cfif>
		<!--- cannot be less than 0 --->
		<cfif calcValue lt 0>
			<cfset calcValue = 0>
		</cfif>
		<!--- handle errors --->
		<cfcatch>
			<cfset calcValue = 'Rate Lookup Offline'>
		</cfcatch>
	</cftry>

	<!--- return a numeric value with discounts applied, or a string (e.g. an error message) --->
	<cfif isNumeric(calcValue)>
		<cfset calcReturn = calcValue>
	<!--- if calculation returns an error, display the error --->
	<cfelse>
		<cfset calcReturn = trim(calcValue)>
	</cfif>
	<cfreturn calcReturn>
</cffunction>

<!--- // ---------- Get Shipping Extension for stateprov ---------- // --->
<cffunction name="CWgetShipExtension"
	access="public"
	output="false"
	returntype="numeric"
	hint="Look up stateprov shipping extension by ID">

	<cfargument name="stateprov_id" required="true" type="numeric"
		hint="ID of the stateprov to look up - pass in 0 to select all IDs">

	<cfset var rsSelectStateProv = ''>
	<cfset var returnVal = 0>
	<!--- look up stateprov --->
	<cfquery name="rsSelectStateProv" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT stateprov_ship_ext
	FROM cw_stateprov
	WHERE stateprov_id = <cfqueryparam value="#arguments.stateprov_id#" cfsqltype="cf_sql_integer">
	</cfquery>
	<!--- if a valid rate was found --->
	<cfif rsSelectStateProv.recordCount gt 0 and isNumeric(rsSelectStateProv.stateprov_ship_ext)>
		<cfset returnVal = rsSelectStateProv.stateprov_ship_ext>
		<!--- default to 0 if no match --->
	<cfelse>
		<cfset returnval = 0>
	</cfif>
	<cfreturn returnval>
</cffunction>

<!--- // ---------- // Get Shipping Method(s) Details (w/ optional customer cart information) // ---------- // --->
<cffunction name="CWgetShipMethodDetails"
	access="public"
	output="false"
	returntype="query"
	hint="returns query of shipping methods"
	>

	<cfargument name="cart_id"
		required="false"
		default="0"
		type="any"
		hint="ID of the customer's cart, to filter available methods">

	<cfargument name="ship_country_id"
		required="false"
		default="#session.cwclient.cwShipCountryID#"
		type="any"
		hint="ID of the customer's shipping country">

	<cfargument name="range_type"
		required="false"
		default="#application.cw.shipChargeBasedOn#"
		type="string"
		hint="Charge shipping ranges based on (none|weight|subtotal)">

	<cfargument name="ship_method_id"
		required="false"
		default="0"
		type="numeric"
		hint="Filter to a specific method's details by ID">

	<cfargument name="cart_weight"
		required="false"
		default="0"
		type="numeric"
		hint="Used if cart ID is not provided">

	<cfargument name="cart_total"
		required="false"
		default="0"
		type="numeric"
		hint="Used if cart ID is not provided">

	<cfargument name="match_range"
		required="false"
		default="true"
		type="boolean"
		hint="Match only a specific range based on amount (rather than simply getting min/max for a method),
		useful for debugging, required for price lookups">

	<cfargument name="localcalc_only"
		required="false"
		default="true"
		type="boolean"
		hint="Match only localcalc methods if looking up ranges. Pass in as false for fallback to ranges when remote lookups fail.">

	<cfset var shipcart = cwGetCart(arguments.cart_id)>
	<cfset var rsShipMethods = ''>
	<cfset var rangeValue = 0>

	<!--- get cart weight, total --->
	<cfif arguments.cart_id neq 0>
		<cfif arguments.range_type eq 'weight'>
			<cfset rangeValue = shipcart.carttotals.shipweight>
		<cfelseif arguments.range_type eq 'subtotal'>
			<cfset rangeValue = shipcart.carttotals.shipsubtotal>
		</cfif>
		<!--- if cart ID not provided, get from other arguments --->
	<cfelse>
		<cfif arguments.range_type eq 'weight'>
			<cfset rangeValue = arguments.cart_weight>
		<cfelseif arguments.range_type eq 'subtotal'>
			<cfset rangeValue = arguments.cart_total>
		</cfif>
	</cfif>
	<!--- if not using ranges --->
	<cfif arguments.range_type is 'none'>
		<cfquery name="rsShipMethods" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT
		m.ship_method_id,
		m.ship_method_name,
		m.ship_method_rate,
		c.ship_method_country_country_id,
		m.ship_method_sort,
		m.ship_method_calctype,
		m.ship_method_archive
	FROM cw_ship_methods m,
		cw_ship_method_countries c
	WHERE
		c.ship_method_country_country_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.ship_country_id#">
	AND c.ship_method_country_method_id = m.ship_method_id
	<cfif arguments.ship_method_id gt 0>
	AND m.ship_method_id = <cfqueryparam value="#arguments.ship_method_id#" cfsqltype="cf_sql_integer">
	</cfif>
	AND NOT ship_method_archive = 1
	ORDER BY
	ship_method_sort, ship_method_name
</cfquery>
		<!--- if using ranges, limit methods with a matching range --->
	<cfelse>
		<cfquery name="rsShipMethods" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT
		Min(r.ship_range_from) AS min_range_from,
		Max(r.ship_range_to) AS max_range_to,
		m.ship_method_id,
		m.ship_method_name,
		m.ship_method_rate,
		r.ship_range_amount,
		r.ship_range_from,
		r.ship_range_to,
		c.ship_method_country_country_id,
		m.ship_method_sort,
		m.ship_method_calctype,
		m.ship_method_archive
	FROM
		(cw_ship_method_countries c
		INNER JOIN cw_ship_methods m
		ON c.ship_method_country_method_id = m.ship_method_id)
		LEFT JOIN cw_ship_ranges r
		ON m.ship_method_id = r.ship_range_method_id
	<!--- if looking up price by range, return only a single range --->
	<cfif arguments.match_range>
	WHERE (r.ship_range_from <= <cfqueryparam cfsqltype="cf_sql_float" value="#rangeValue#">
		AND r.ship_range_to >= <cfqueryparam cfsqltype="cf_sql_float" value="#rangeValue#">)
		<cfif arguments.localcalc_only eq true>OR NOT m.ship_method_calctype = 'localcalc'</cfif>
	</cfif>
	GROUP BY
		m.ship_method_id,
		m.ship_method_name,
		c.ship_method_country_country_id,
		m.ship_method_sort,
		m.ship_method_archive,
		m.ship_method_rate,
		m.ship_method_calctype,
		r.ship_range_amount,
		r.ship_range_from,
		r.ship_range_to
	HAVING (
			((Min(r.ship_range_from) <= <cfqueryparam cfsqltype="cf_sql_float" value="#rangeValue#">)
			AND (Max(r.ship_range_to) >= <cfqueryparam cfsqltype="cf_sql_float" value="#rangeValue#">)
			AND (c.ship_method_country_country_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.ship_country_id#">)
			) 
			<cfif arguments.localcalc_only eq true>OR (NOT m.ship_method_calctype = 'localcalc' AND c.ship_method_country_country_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.ship_country_id#">)</cfif>
			)
		<cfif arguments.ship_method_id gt 0>
		AND m.ship_method_id = <cfqueryparam value="#arguments.ship_method_id#" cfsqltype="cf_sql_integer">
		</cfif>
		AND NOT (m.ship_method_archive = 1)
	ORDER BY
		m.ship_method_sort,
		m.ship_method_id,
		m.ship_method_name,
		c.ship_method_country_country_id,
		m.ship_method_archive,
		m.ship_method_rate,
		m.ship_method_calctype,
		r.ship_range_amount,
		Min(r.ship_range_from),
		Max(r.ship_range_to)
</cfquery>
	</cfif>
	<!--- /end if using ranges --->
	<cfreturn rsShipMethods>
</cffunction>

<!--- // ---------- // Get shipping method calculation type by ID // ---------- // --->
<cffunction name="CWgetShipMethodCalctype"
	access="public"
	output="false"
	returntype="string"
	hint="lookup shipping method calctype based on ID"
	>
		
	<cfargument name="ship_method_id"
		required="true"
		default="0"
		type="numeric"
		hint="the method ID to look up">
		
	<cfquery name="rsShipMethodName" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT ship_method_calctype
	FROM cw_ship_methods
	WHERE ship_method_id = <cfqueryparam value="#arguments.ship_method_id#" cfsqltype="cf_sql_integer">
</cfquery>
	<cfreturn rsShipMethodName.ship_method_calctype>
</cffunction>

<!--- // ---------- // Get shipping method name by ID // ---------- // --->
<cffunction name="CWgetShipMethodName"
	access="public"
	output="false"
	returntype="string"
	hint="lookup shipping method name based on ID"
	>
		
	<cfargument name="ship_method_id"
		required="true"
		default="0"
		type="numeric"
		hint="the method ID to look up">
		
	<cfquery name="rsShipMethodName" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT ship_method_name
	FROM cw_ship_methods
	WHERE ship_method_id = <cfqueryparam value="#arguments.ship_method_id#" cfsqltype="cf_sql_integer">
</cfquery>
	<cfreturn rsShipMethodName.ship_method_name>
</cffunction>

<!--- // ---------- // UPS Lookup function // ---------- // --->
<cffunction name="CWgetUpsRate"
	access="public"
	output="false"
	returntype="string"
	hint="Gets UPS shipping rate, returns numeric value or error string"
	>
		
	<cfargument name="ups_license"
		required="true"
		default=""
		type="string"
		hint="UPS License Number">

	<cfargument name="ups_userid"
		required="true"
		default=""
		type="string"
		hint="UPS User ID">

	<cfargument name="ups_password"
		required="true"
		default=""
		type="string"
		hint="UPS Password">

	<cfargument name="ups_url"
		required="false"
		default="https://onlinetools.ups.com/ups.app/xml/Rate"
		type="string"
		hint="UPS Server Address">

	<cfargument name="ups_service_code"
		required="false"
		default="01"
		type="string"
		hint="eg UPS Ground = 03">

	<cfargument name="customer_id"
		required="false"
		default="0"
		type="string"
		hint="A customer ID to use for lookup of address values">

	<cfargument name="weight_val"
		required="false"
		default="1"
		type="numeric"
		hint="a numeric weight for this shipment">

	<cfargument name="weight_uom"
		required="false"
		default="lbs"
		type="string"
		hint="the unit of measurement for weight values (lbs|kgs)">
		
	<cfargument name="package_length"
		required="false" 
		default="14"
		type="numeric">

	<cfargument name="package_width"
		required="false" 
		default="18"
		type="numeric">
		
	<cfargument name="package_height"
		required="false" 
		default="9"
		type="numeric">		

		<!--- DEBUG: uncomment to test server availability, should return "Rate" for server name --->
		<!---
			<cfhttp url="https://wwwcie.ups.com/ups.app/xml/Rate" method="GET">
			<cfdump var="#cfhttp.filecontent#">
			<cfabort>
			--->
		<cfset var customerQuery = ''>
		<cfset var rateValue = 0>
		<cfset var xmlData = structNew()>
		<cfparam name="application.cw.companyShipState" default="#application.cw.companyState#">	

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
		<!--- if customer found --->
		<cfif customerQuery.recordCount>
			<!--- set up ups vars --->
			<cfset xmlData.upslicense = trim(arguments.ups_license)>
			<cfset xmlData.upsuserid = trim(arguments.ups_userid)>
			<cfset xmlData.upspassword = trim(arguments.ups_password)>
			<cfset xmlData.upsurl = trim(arguments.ups_url)>
			<cfset xmlData.upsservicecode= trim(arguments.ups_service_code)>
			<cfset xmlData.customerid = trim(arguments.customer_id)>
			<!--- weight --->
			<cfif isNumeric(arguments.weight_val) and round(arguments.weight_val) gt 0>
				<cfset xmlData.shipweight = round(arguments.weight_val)>
			<cfelse>
				<cfset xmlData.shipweight = 1>
			</cfif>
			<cfset xmlData.shipweightuom = trim(arguments.weight_uom)>
			<!--- delivery address --->
			<cfset xmlData.shipcompany = customerQuery.customer_ship_company>
			<cfset xmlData.shipname = customerQuery.customer_ship_name>
			<cfset xmlData.shipphone = customerQuery.customer_phone>
			<cfset xmlData.shipaddress1 = customerQuery.customer_ship_address1>
			<cfset xmlData.shipaddress2 = customerQuery.customer_ship_address2>
			<cfset xmlData.shipcity = customerQuery.customer_ship_city>
			<cfset xmlData.shipstate = customerQuery.stateprov_name>
			<cfset xmlData.shipcountry = customerQuery.country_code>
			<cfif xmlData.shipcountry is 'US'>
				<cfset xmlData.shippostcode = left(trim(customerQuery.customer_ship_zip),5)>
			<cfelse>
				<cfset xmlData.shippostcode = customerQuery.customer_ship_zip>
			</cfif>
			<!--- ship from address --->
			<cfset xmlData.fromname = application.cw.companyName>
			<cfset xmlData.fromphone = application.cw.companyPhone>
			<cfset xmlData.fromaddress1 = application.cw.companyAddress1>
			<cfset xmlData.fromaddress2 = application.cw.companyAddress2>
			<cfset xmlData.fromcity = application.cw.companyCity>
			<cfset xmlData.fromstate = application.cw.companyShipState>
			<cfset xmlData.fromcountry = application.cw.companyShipCountry>
			<cfset xmlData.frompostcode = application.cw.companyZip>
			<!--- measurements --->
			<cfset xmlData.packageLength = arguments.package_length>
			<cfset xmlData.packageWidth = arguments.package_width>
			<cfset xmlData.packageHeight = arguments.package_height>
			<!--- assemble xml --->
			<cfsavecontent variable="xmlStr">
	<cfoutput>
	<?xml version="1.0" ?>
	<AccessRequest xml:lang='en-US'>
		<AccessLicenseNumber>
			#xmlData.upslicense#
		</AccessLicenseNumber>
		<UserId>
			#xmlData.upsuserid#
		</UserId>
		<Password>
			#xmlData.upspassword#
		</Password>
	</AccessRequest>
	<?xml version="1.0" ?>
	<RatingServiceSelectionRequest>
		<Request>
			<TransactionReference>
				<CustomerContext>
					Rate Request
				</CustomerContext>
				<XpciVersion>
					1.0
				</XpciVersion>
			</TransactionReference>
			<RequestAction>
				Rate
			</RequestAction>
			<RequestOption>
				Rate
			</RequestOption>
		</Request>
		<!--- pickup info: code type 01 = daily pickup, 03 = customer counter --->
		<PickupType>
			<Code>
				01
			</Code>
		</PickupType>
		<Shipment>
			<Description>
				UPS Shipping
			</Description>
			<!--- company info --->
			<Shipper>
				<Address>
					<AddressLine1>
						<![CDATA[#xmlData.fromAddress1#]]>
					</AddressLine1>
					<AddressLine2>
						<![CDATA[#xmlData.fromAddress2#]]>
					</AddressLine2>
					<City>
						<![CDATA[#xmlData.fromCity#]]>
					</City>
					<StateProvinceCode>
						<![CDATA[#xmlData.fromState#]]>
					</StateProvinceCode>
					<PostalCode>
						<![CDATA[#xmlData.fromPostCode#]]>
					</PostalCode>
					<CountryCode>
						<![CDATA[#xmlData.fromCountry#]]>
					</CountryCode>
				</Address>
			</Shipper>
			<!--- customer info --->
			<ShipTo>
				<CompanyName>
					<![CDATA[#xmlData.shipCompany#]]>
				</CompanyName>
				<AttentionName>
					<![CDATA[#xmlData.shipName#]]>
				</AttentionName>
				<PhoneNumber>
					<![CDATA[#xmlData.shipPhone#]]>
				</PhoneNumber>
				<Address>
					<AddressLine1>
						<![CDATA[#xmlData.shipAddress1#]]>
					</AddressLine1>
					<AddressLine2>
						<![CDATA[#xmlData.shipAddress2#]]>
					</AddressLine2>
					<City>
						<![CDATA[#xmlData.shipCity#]]>
					</City>
					<PostalCode>
						<![CDATA[#xmlData.shipPostCode#]]>
					</PostalCode>
					<CountryCode>
						<![CDATA[#xmlData.shipCountry#]]>
					</CountryCode>
				</Address>
			</ShipTo>
			<!--- shipping from address --->
			<ShipFrom>
				<CompanyName>
					<![CDATA[#xmlData.fromName#]]>
				</CompanyName>
				<PhoneNumber>
					<![CDATA[#xmlData.fromPhone#]]>
				</PhoneNumber>
				<Address>
					<AddressLine1>
						<![CDATA[#xmlData.fromAddress1#]]>
					</AddressLine1>
					<AddressLine2>
						<![CDATA[#xmlData.fromAddress2#]]>
					</AddressLine2>
					<City>
						<![CDATA[#xmlData.fromCity#]]>
					</City>
					<StateProvinceCode>
						<![CDATA[#xmlData.fromState#]]>
					</StateProvinceCode>
					<PostalCode>
						<![CDATA[#xmlData.fromPostCode#]]>
					</PostalCode>
					<CountryCode>
						<![CDATA[#xmlData.fromCountry#]]>
					</CountryCode>
				</Address>
			</ShipFrom>
			<Service>
				<Code>
					#xmlData.upsServiceCode#
				</Code>
			</Service>
			<Package>
				<PackagingType>
					<Code>
						<!--- 02 = package, 00 = unknown --->
						02
					</Code>
				</PackagingType>
				<!--- average large box dimensions provided,
					can be altered as needed --->
				<Dimensions>
					<!--- uom can be IN|CM --->
					<UnitOfMeasurement>
						<Code>
						IN
						</Code>
					</UnitOfMeasurement>
					<Length>
						#xmlData.packageLength#
					</Length>
					<Width>
						#xmlData.packageWidth#
					</Width>
					<Height>
						#xmlData.packageHeight#
					</Height>
				</Dimensions>
				<Description>
					Rate
				</Description>
				<PackageWeight>
					<UnitOfMeasurement>
						<Code>
							#xmlData.shipweightuom#
						</Code>
					</UnitOfMeasurement>
					<Weight>
						#xmlData.shipweight#
					</Weight>
				</PackageWeight>
			</Package>
			<ShipmentServiceOptions />
		</Shipment>
	</RatingServiceSelectionRequest>

	</cfoutput>
	</cfsavecontent>

			<!--- send xml request --->
			<cfhttp url="#xmlData.UPSurl#" port="443" method ="POST" throwonerror="yes">
				<cfhttpparam name="name" type="XML" value="#xmlStr#">
			</cfhttp>
			<!--- handle result --->
			<cfset xmlResponse = XmlParse(CFHTTP.FileContent)>
			<!--- if response is success code (1) --->
			<cfif xmlResponse.RatingServiceSelectionResponse.Response.ResponseStatusCode.xmlText eq 1>
				<!--- set the rate value as provided --->
				<cfset rateValue = xmlResponse.RatingServiceSelectionResponse.RatedShipment[1].totalCharges.monetaryValue.xmlText>
				<!--- if not success, get message --->
			<cfelse>
				<!--- show full error/reason in test mode --->
				<cfif application.cw.appTestModeEnabled>
					<cfset rateValue = 'UPS Rate Unavailable - Reason:' & xmlResponse.RatingServiceSelectionResponse.Response.Error.ErrorDescription.xmlText>
				<cfelse>
					<cfset rateValue = 'UPS Lookup Unavailable'>
				</cfif>
			</cfif>
			<!--- if no cartweaver customer is found --->
		<cfelse>
			<cfset rateValue = 'Address Data Unavailable'>
		</cfif>
		<cfcatch>
			<cfset rateValue = 'UPS Lookup Offline'>
		</cfcatch>
	</cftry>
	<cfreturn rateValue>
</cffunction>
<!--- END UPS --->

<!--- // ---------- // FedEx Lookup function // ---------- //  --->
<cffunction name="CWgetFedexRate"
	access="public"
	output="false"
	returntype="string"
	hint="Gets FedEx shipping rate, returns numeric value or error string"
	>
		
	<cfargument name="fedex_access_key"
		required="true"
		default=""
		type="string"
		hint="FedEx Access Key">

	<cfargument name="fedex_password"
		required="true"
		default=""
		type="string"
		hint="FedEx Password">

	<cfargument name="fedex_account_number"
		required="true"
		default=""
		type="string"
		hint="FedEx Account Number">

	<cfargument name="fedex_meternumber"
		required="true"
		default=""
		type="string"
		hint="FedEx Meter Number">

	<cfargument name="fedex_url"
		required="false"
		default="https://gateway.fedex.com:443/GatewayDC"
		type="string"
		hint="FedEx Server Address">

	<cfargument name="fedex_service"
		required="false"
		default="FEDEX_GROUND"
		type="string"
		hint="eg FEDEX_GROUND">

	<cfargument name="customer_id"
		required="false"
		default="0"
		type="string"
		hint="A customer ID to use for lookup of address values">

	<cfargument name="weight_val"
		required="false"
		default="1"
		type="numeric"
		hint="a numeric weight for this shipment">

	<cfargument name="weight_uom"
		required="false"
		default="LB"
		type="string"
		hint="the unit of measurement for weight values (lbs|kgs)">
		
	<cfargument name="package_length"
		required="false" 
		default="14"
		type="numeric">

	<cfargument name="package_width"
		required="false" 
		default="18"
		type="numeric">
		
	<cfargument name="package_height"
		required="false" 
		default="9"
		type="numeric">	
				
	<cfset var customerQuery = ''>
	<cfset var rateValue = 0>
	<cfset var xmlData = structNew()>
	<cfparam name="application.cw.companyShipState" default="#application.cw.companyState#">	
	
	<!--- determine unit of measure --->
	<cfif (LCase(weight_uom) is "lbs")><cfset weight_uom = "LB"></cfif>
	<cfif (LCase(weight_uom) is "kgs")><cfset weight_uom = "KG"></cfif>
	<cfif (LCase(weight_uom) is "oz")><cfset weight_uom = "OZ"></cfif>
	<cfif (LCase(weight_uom) is "g")><cfset weight_uom = "G"></cfif>
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
				cw_stateprov.stateprov_code,
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
		<!--- if customer found --->
		<cfif customerQuery.recordCount>
			<!--- set up fedex vars --->
			<cfset xmlData.fedexAccessKey = trim(arguments.fedex_access_key)>
			<cfset xmlData.fedexPassword = trim(arguments.fedex_password)>
			<cfset xmlData.fedexAccountNumber = trim(arguments.fedex_account_number)>
			<cfset xmlData.fedexMeterNumber = trim(arguments.fedex_meternumber)>
			<cfset xmlData.fedexURL = trim(arguments.fedex_url)>
			<cfset xmlData.fedexService= trim(arguments.fedex_service)>
			<cfset xmlData.customerid = trim(arguments.customer_id)>
			<!--- weight --->
			<cfif isNumeric(arguments.weight_val) and round(arguments.weight_val) gt 0>
				<cfset xmlData.shipweight = round(arguments.weight_val)>
			<cfelse>
				<cfset xmlData.shipweight = 1>
			</cfif>
			<cfset xmlData.shipweightuom = trim(arguments.weight_uom)>
			<!--- delivery address --->
			<cfset xmlData.shipcompany = customerQuery.customer_ship_company>
			<cfset xmlData.shipname = customerQuery.customer_ship_name>
			<cfset xmlData.shipphone = customerQuery.customer_phone>
			<cfset xmlData.shipaddress1 = customerQuery.customer_ship_address1>
			<cfset xmlData.shipaddress2 = customerQuery.customer_ship_address2>
			<cfset xmlData.shipcity = customerQuery.customer_ship_city>
			<cfset xmlData.shipstate = customerQuery.stateprov_code>
			<cfset xmlData.shipcountry = customerQuery.country_code>
			<cfif xmlData.shipcountry is 'US'>
				<cfset xmlData.shippostcode = left(trim(customerQuery.customer_ship_zip),5)>
			<cfelse>
				<cfset xmlData.shippostcode = customerQuery.customer_ship_zip>
			</cfif>
			<!--- ship from address --->
			<cfset xmlData.fromname = application.cw.companyName>
			<cfset xmlData.fromphone = application.cw.companyPhone>
			<cfset xmlData.fromaddress1 = application.cw.companyAddress1>
			<cfset xmlData.fromaddress2 = application.cw.companyAddress2>
			<cfset xmlData.fromcity = application.cw.companyCity>
			<cfset xmlData.fromstate = application.cw.companyShipState>
			<cfset xmlData.fromcountry = application.cw.companyShipCountry>
			<cfset xmlData.frompostcode = application.cw.companyZip>
			<!--- measurements --->
			<cfset xmlData.packageLength = arguments.package_length>
			<cfset xmlData.packageWidth = arguments.package_width>
			<cfset xmlData.packageHeight = arguments.package_height>
			<!--- assemble xml --->
			<cfset gmt=getTimeZoneInfo()>
            <cfset timezone=gmt.utcHourOffset>
            <cfif timezone eq 0>
                <cfset timezone="+00">
            <cfelseif timezone gt 0>
                <cfif timezone lt 10>
                    <cfset timezone = "0"&timezone>
                </cfif>
                <cfset timezone="+"&timezone>
            <cfelse>
                <cfif timezone gt -10>
                    <cfset timezone = "-0"&Abs(timezone)>
                </cfif>
            </cfif>
            <cfset timezone=timezone&":">
            <cfif gmt.utcMinuteOffset lt 10>
                <cfset timezone = timezone&"0">
            </cfif>
            <cfset timezone = timezone&gmt.utcMinuteOffset>
            <cfset fedexDate = DateFormat(Now(), 'yyyy-mm-dd') & "T" &DateFormat(Now(), 'HH:mm:ss+00:00')>
			<cfsavecontent variable="xmlStr">
				<cfoutput><?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v10="http://fedex.com/ws/rate/v10">
	<soapenv:Header/>
	<soapenv:Body>
		<v10:RateRequest>
			<v10:WebAuthenticationDetail>
				<v10:UserCredential>
					<v10:Key>#xmlData.fedexAccessKey#</v10:Key>
					<v10:Password>#xmlData.fedexPassword#</v10:Password>
				</v10:UserCredential>
			</v10:WebAuthenticationDetail>
			<v10:ClientDetail>
				<v10:AccountNumber>#xmlData.fedexAccountNumber#</v10:AccountNumber>
				<v10:MeterNumber>#xmlData.fedexMeterNumber#</v10:MeterNumber>
			</v10:ClientDetail>
			<v10:TransactionDetail>
				<v10:CustomerTransactionId><![CDATA[#session.cwclient.cwCartID#]]></v10:CustomerTransactionId>
			</v10:TransactionDetail>
			<v10:Version>
				<v10:ServiceId>crs</v10:ServiceId>
				<v10:Major>10</v10:Major>
				<v10:Intermediate>0</v10:Intermediate>
				<v10:Minor>0</v10:Minor>
			</v10:Version>
			<v10:ReturnTransitAndCommit>true</v10:ReturnTransitAndCommit>
			<v10:RequestedShipment>
				<v10:ShipTimestamp>#fedexDate#</v10:ShipTimestamp>
				<v10:DropoffType>REGULAR_PICKUP</v10:DropoffType>
				<v10:ServiceType>#xmlData.fedexService#</v10:ServiceType>
				<v10:PackagingType>YOUR_PACKAGING</v10:PackagingType>
				<v10:Shipper>
					<v10:Contact>
						<v10:CompanyName><![CDATA[#xmlData.fromName#]]></v10:CompanyName>
						<v10:PhoneNumber><![CDATA[#xmlData.fromPhone#]]></v10:PhoneNumber>
					</v10:Contact>
					<v10:Address>
						<v10:City><![CDATA[#xmlData.fromCity#]]></v10:City>
						<v10:StateOrProvinceCode><![CDATA[#xmlData.fromState#]]></v10:StateOrProvinceCode>
						<v10:PostalCode><![CDATA[#xmlData.fromPostCode#]]></v10:PostalCode>
						<v10:CountryCode><![CDATA[#xmlData.fromCountry#]]></v10:CountryCode>
					</v10:Address>
				</v10:Shipper>
				<v10:Recipient>
					<v10:Contact>
						<v10:PersonName><![CDATA[#xmlData.shipName#]]></v10:PersonName>
						<v10:CompanyName><![CDATA[#xmlData.shipCompany#]]></v10:CompanyName>
						<v10:PhoneNumber><![CDATA[#xmlData.shipPhone#]]></v10:PhoneNumber>
					</v10:Contact>
					<v10:Address>
						<v10:City><![CDATA[#xmlData.shipCity#]]></v10:City>
						<v10:StateOrProvinceCode><![CDATA[#xmlData.shipState#]]></v10:StateOrProvinceCode>
						<v10:PostalCode><![CDATA[#xmlData.shipPostCode#]]></v10:PostalCode>
						<v10:CountryCode><![CDATA[#xmlData.shipCountry#]]></v10:CountryCode>
					</v10:Address>
				</v10:Recipient>
				<v10:ShippingChargesPayment>
					<v10:PaymentType>SENDER</v10:PaymentType>
					<v10:Payor>
						<v10:AccountNumber>#xmlData.fedexAccountNumber#</v10:AccountNumber>
						<v10:CountryCode><![CDATA[#xmlData.fromCountry#]]></v10:CountryCode>
					</v10:Payor>
				</v10:ShippingChargesPayment>
				<v10:RateRequestTypes>ACCOUNT</v10:RateRequestTypes>
				<v10:PackageCount>1</v10:PackageCount>
				<v10:RequestedPackageLineItems>
					<v10:SequenceNumber>1</v10:SequenceNumber>
					<v10:GroupPackageCount>1</v10:GroupPackageCount>
					<v10:Weight>
						<v10:Units>#xmlData.shipweightuom#</v10:Units>
						<v10:Value>#xmlData.shipweight#</v10:Value>
					</v10:Weight>
					<v10:Dimensions>
						<v10:Length>#xmlData.packageLength#</v10:Length>
						<v10:Width>#xmlData.packageWidth#</v10:Width>
						<v10:Height>#xmlData.packageHeight#</v10:Height>
						<v10:Units>IN</v10:Units>
					</v10:Dimensions>
				</v10:RequestedPackageLineItems>
			</v10:RequestedShipment>
		</v10:RateRequest>
	</soapenv:Body>
</soapenv:Envelope>
	</cfoutput>
	</cfsavecontent>

			<!--- send xml request --->
			<cfhttp url="#xmlData.fedexURL#" port="443" method ="post" result="fedexResponse">
				<cfhttpparam name="name" type="XML" value="#trim(xmlStr)#">
			</cfhttp>
				 
			<!--- handle result --->
            <cfset xmlText = Replace(Replace(fedexResponse.fileContent, "soapenv:", "soap_", "all"), "v10:", "v10_", "all")>
			<cfset xmlResponse = XmlParse(xmlText)>

				<!--- uncomment for advanced debugging --->
				 <!--- 
 				 <cfdump var="#xmlStr#">
				 <cfdump var="#xmlText#">
				 <textarea rows="45" cols="180"><cfoutput>#fedexResponse.fileContent#</cfoutput></textarea>
				 <cfabort>
				 --->

			<!--- if the ratereply is returned --->
			<cfif IsDefined("xmlResponse.soap_envelope.soap_body.v10_RateReply")>
            	<cfset response = xmlResponse.soap_envelope.soap_body.v10_RateReply>
				<!--- if response is success code (1) --->
                <cfif IsDefined("response.v10_RateReplyDetails")>
                	<cfset cheapest = -1>
					<!--- if response is an array --->
                    <cfif isArray("response.v10_RateReplyDetails")>
                    	<!--- array of replies --->
                        <cfloop collection="response.v10_RateReplyDetails" item="rates">
                        	<cfif IsArray("rates.v10_RatedShipmentDetails")>
                            	<cfloop collection="response.v10_RateReplyDetails" item="details">
                                	<cfif IsDefined("details.v10_ShipmentRateDetail.v10_TotalNetCharge.v10_Amount")>
                                    	<cfset myCharge = details.v10_ShipmentRateDetail.v10_TotalNetCharge.v10_Amount.xmlText>
                                        <cfif IsDefined("details.v10_ShipmentRateDetail.v10_TotalRebates.v10_Amount.xmlText")>
                                        	<cfset myCharge = myCharge - details.v10_ShipmentRateDetail.v10_TotalRebates.v10_Amount.xmlText>
                                        </cfif>
                                        <cfif cheapest lt 0 OR myCharge lt cheapest>
                                        	<cfset cheapest = myCharge>
                                        </cfif>
                                    </cfif>
                                </cfloop>
							<cfelse>
								<cfset details = response.v10_RateReplyDetails.v10_RatedShipmentDetails>
                                <cfif IsDefined("details.v10_ShipmentRateDetail.v10_TotalNetCharge.v10_Amount")>
                                    <cfset myCharge = details.v10_ShipmentRateDetail.v10_TotalNetCharge.v10_Amount.xmlText>
                                    <cfif IsDefined("details.v10_ShipmentRateDetail.v10_TotalRebates.v10_Amount.xmlText")>
                                        <cfset myCharge = myCharge - details.v10_ShipmentRateDetail.v10_TotalRebates.v10_Amount.xmlText>
                                    </cfif>
                                    <cfif cheapest lt 0 OR myCharge lt cheapest>
                                        <cfset cheapest = myCharge>
                                    </cfif>
                                </cfif>
                            </cfif>
                        </cfloop>
					<!--- if response is not an array, use full response --->	
                    <cfelse>
                    	<cfset rates = response.v10_RateReplyDetails>
                       	<cfif IsArray("rates.v10_RatedShipmentDetails")>
                           	<cfloop collection="rates.v10_RatedShipmentDetails" item="details">
								<cfif IsDefined("details.v10_ShipmentRateDetail.v10_TotalNetCharge.v10_Amount")>
                                    <cfset myCharge = details.v10_ShipmentRateDetail.v10_TotalNetCharge.v10_Amount.xmlText>
                                    <cfif IsDefined("details.v10_ShipmentRateDetail.v10_TotalRebates.v10_Amount.xmlText")>
                                        <cfset myCharge = myCharge - details.v10_ShipmentRateDetail.v10_TotalRebates.v10_Amount.xmlText>
                                    </cfif>
                                    <cfif cheapest lt 0 OR myCharge lt cheapest>
                                        <cfset cheapest = myCharge>
                                    </cfif>
                                </cfif>
                            </cfloop>
                        <cfelse>
                        	<cfset details = rates.v10_RatedShipmentDetails>
							<cfif IsDefined("details.v10_ShipmentRateDetail.v10_TotalNetCharge.v10_Amount")>
                                <cfset myCharge = details.v10_ShipmentRateDetail.v10_TotalNetCharge.v10_Amount.xmlText>
                                <cfif IsDefined("details.v10_ShipmentRateDetail.v10_TotalRebates.v10_Amount.xmlText")>
                                    <cfset myCharge = myCharge - details.v10_ShipmentRateDetail.v10_TotalRebates.v10_Amount.xmlText>
                                </cfif>
                                <cfif cheapest lt 0 OR myCharge lt cheapest>
                                    <cfset cheapest = myCharge>
                                </cfif>
                            </cfif>
                        </cfif>
                    </cfif>
					<!--- /end if response is array --->
					
                    <!--- set the rate value as provided --->
                    <cfif cheapest > 0>
                    	<cfset rateValue = cheapest>
                    </cfif>
                
				<cfelse>
                	<cfset rateValue = "FedEx Rate Unavailable">
					<!--- show full error/reason in test mode --->
					<cfif application.cw.appTestModeEnabled>
	                    <cfif IsDefined("response.v10_HighestSeverity") AND UCase(response.v10_HighestSeverity.xmlText) is "ERROR">
	                    	<cfset rateValue = response.v10_Notifications.v10_Message.xmlText>
	                    <cfelse>
	                    	<cfset rateValue = "">
	                        <cfif IsDefined(response[1])>
	                        	<cfloop collection="response" item="error">
	                            	<cfif rateValue neq ""><cfset rateValue = rateValue & "<br />Reason: "></cfif>
	                            	<cfset rateValue = rateValue & error.v10_Notifications.v10_Message.xmlText>
	                            </cfloop>
	                        </cfif>
	                    </cfif>
                    </cfif>
					<!--- /end full error response --->

                </cfif>
				<!--- /end if response is success code (1) --->

			<!--- if no ratereply is available --->
            <cfelse>
                <cfset rateValue = "FedEx Lookup Unavailable">
				<!--- attempt to add other messages if available --->
				<cftry>
					<cfset rateValue = ratevalue & "<br>&nbsp;&nbsp;#trim(xmlResponse.soap_Envelope.soap_Body.v10_RateReply.v10_Notifications[1].v10_Message.xmlText)#">
					<cfcatch></cfcatch>
				</cftry>
				<cftry>
						<cfset rateValue = ratevalue & "<br>&nbsp;&nbsp;#trim(xmlResponse.soap_Envelope.soap_Body.v10_RateReply.v10_Notifications[2].v10_Message.xmlText)#">
					<cfcatch></cfcatch>
				</cftry>
            </cfif>
			<!--- /end if rate reply --->
			
			<!--- if no cartweaver customer is found --->
		<cfelse>
			<cfset rateValue = 'Address Data Unavailable'>
		</cfif>
		<cfcatch>
			<cfset rateValue = 'FedEx Lookup Offline'>
		</cfcatch>
	</cftry>
	<cfreturn rateValue>
</cffunction>
<!--- END FEDEX --->	

<!--- // ---------- // USPS (U.S Postal Service) Lookup function // ---------- // --->
<cffunction name="CWgetUspsRate"
	access="public"
	output="false"
	returntype="string"
	hint="Gets USPS shipping rate, returns numeric value or error string"
	>
		
	<cfargument name="usps_userid"
		required="true"
		default=""
		type="string"
		hint="USPS User ID">

	<cfargument name="usps_password"
		required="true"
		default=""
		type="string"
		hint="USPS Password">

	<cfargument name="usps_url"
		required="false"
		default="http://production.shippingapis.com/ShippingAPI.dll"
		type="string"
		hint="USPS Server Address">

	<cfargument name="usps_service"
		required="false"
		default="FIRST CLASS"
		type="string"
		hint="eg FIRST CLASS,EXPRESS,PRIORITY,PARCEL">

	<cfargument name="customer_id"
		required="false"
		default="0"
		type="string"
		hint="A customer ID to use for lookup of address values">		

	<cfargument name="weight_val"
		required="false"
		default="1"
		type="numeric"
		hint="a numeric weight for this shipment">

	<cfargument name="weight_uom"
		required="false"
		default="lbs"
		type="string"
		hint="the unit of measurement for weight values (lbs|kgs)">

	<cfargument name="usps_rate_type"
		required="false"
		default="RateV4"
		type="string"
		hint="">

	<!--- measurements can be passed in, only applies to some methods --->
	<cfargument name="package_width"
		required="false" 
		default="10"
		type="numeric"
		hint="in inches">

	<cfargument name="package_length"
		required="false" 
		default="12"
		type="numeric"
		hint="in inches">

	<cfargument name="package_height"
		required="false" 
		default="7"
		type="numeric"
		hint="in inches">

	<cfargument name="package_girth"
		required="false" 
		default="46"
		type="numeric"
		hint="in inches">
							
		<cfset var customerQuery = ''>
		<cfset var rateValue = 0>
		<cfset var xmlData = structNew()>
		<cfset var demoXML = ''>
		
		<cfparam name="application.cw.companyShipState" default="#application.cw.companyState#">	

		<!--- DEBUG: uncomment to test server availability with sample XML from usps --->
		<!---
		<cfset demoXML = '<#trim(arguments.usps_rate_type)#Request USERID="#application.cw.uspsuserID#">
				<Package ID="1">
					<Service>FIRST CLASS</Service>
					<FirstClassMailType>PARCEL</FirstClassMailType>
					<ZipOrigination>10027</ZipOrigination>
					<ZipDestination>20500</ZipDestination>
					<Pounds>0</Pounds>
					<Ounces>8</Ounces>
					<Container>VARIABLE</Container>
					<Size>LARGE</Size>
					<Width>15</Width>
					<Length>10</Length>
					<Height>15</Height>
					<Girth>55</Girth>
					<Machinable>TRUE</Machinable>
				</Package>
			</RateV4Request>'>
			<cfhttp url="http://production.shippingapis.com/ShippingAPI.dll" method="post" timeout="3" throwonerror="true">
				<cfhttpparam encoded="no" type="formfield" name="api" value="#trim(arguments.usps_rate_type)#">
				<cfhttpparam encoded="no" type="formfield" name="xml" value='#demoXML#'>
			</cfhttp>
			<cfdump var="#arguments#">
			<cfdump var="#cfhttp.filecontent#">
			<cfabort>
			--->
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
		<!--- if customer found --->
		<cfif customerQuery.recordCount>
			<!--- set up usps vars --->
			<cfset xmlData.uspsuserid = trim(arguments.usps_userid)>
			<cfset xmlData.uspspassword = trim(arguments.usps_password)>
			<cfset xmlData.uspsurl = trim(arguments.usps_url)>
			<cfset xmlData.uspsratetype = trim(arguments.usps_rate_type)>
			<cfset xmlData.uspsservice = trim(arguments.usps_service)>
			<cfset xmlData.customerid = trim(arguments.customer_id)>
			<!--- weight --->
			<cfif isNumeric(arguments.weight_val) and round(arguments.weight_val) gt 0>
				<cfset xmlData.shipweight = round(arguments.weight_val)>
			<cfelse>
				<cfset xmlData.shipweight = 1>
			</cfif>
			<cfset xmlData.shipweightuom = trim(arguments.weight_uom)>
			<!--- delivery address --->
			<cfset xmlData.shipcompany = customerQuery.customer_ship_company>
			<cfset xmlData.shipname = customerQuery.customer_ship_name>
			<cfset xmlData.shipphone = customerQuery.customer_phone>
			<cfset xmlData.shipaddress1 = customerQuery.customer_ship_address1>
			<cfset xmlData.shipaddress2 = customerQuery.customer_ship_address2>
			<cfset xmlData.shipcity = customerQuery.customer_ship_city>
			<cfset xmlData.shipstate = customerQuery.stateprov_name>
			<cfset xmlData.shipcountry = customerQuery.country_code>
			<cfif xmlData.shipcountry is 'US'>
				<cfset xmlData.shippostcode = left(trim(customerQuery.customer_ship_zip),5)>
			<cfelse>
				<cfset xmlData.shippostcode = customerQuery.customer_ship_zip>
			</cfif>
			<!--- ship from address --->
			<cfset xmlData.fromname = application.cw.companyName>
			<cfset xmlData.fromphone = application.cw.companyPhone>
			<cfset xmlData.fromaddress1 = application.cw.companyAddress1>
			<cfset xmlData.fromaddress2 = application.cw.companyAddress2>
			<cfset xmlData.fromcity = application.cw.companyCity>
			<cfset xmlData.fromstate = application.cw.companyShipState>
			<cfset xmlData.fromcountry = application.cw.companyShipCountry>
			<cfset xmlData.frompostcode = application.cw.companyZip>
			<!--- first class can only be 13 oz --->
			<cfif xmlData.uspsservice is 'FIRST CLASS' and xmlData.shipweight gt 13/16>
				<cfset xmlData.uspsservice = 'PRIORITY'>
			</cfif>
			<!--- usps weight is pounds and ounces --->
			<cfif xmlData.shipweightuom is 'kgs'>
				<cfset xmlData.shipweight = xmlData.shipweight * 2.20462>
			</cfif>
			<!--- break down lbs and oz --->
			<cfset xmlData.lbs = int(xmlData.shipweight)>
			<cfif xmlData.lbs lt xmlData.shipweight>
				<cfset xmlData.oz = int((xmlData.shipweight - xmlData.lbs)/.0625) + 1>
			<cfelse>
				<cfset xmlData.oz = 0>
			</cfif>
			<!--- measurements --->
			<cfset xmlData.packageLength = arguments.package_length>
			<cfset xmlData.packageWidth = arguments.package_width>
			<cfset xmlData.packageHeight = arguments.package_height>
			<cfset xmlData.packageGirth = arguments.package_girth>
			
			<!--- assemble xml --->
			<cfsavecontent variable="xmlStr">
			<cfoutput>
			<RateV4Request USERID="#xmlData.uspsuserid#">
			<Revision>2</Revision>
				<Package ID="1">
					<Service>#xmlData.uspsservice#</Service>
					<cfif xmlData.uspsservice contains 'FIRST'>
					<FirstClassMailType>PARCEL</FirstClassMailType>
					</cfif>
					<ZipOrigination>#xmlData.frompostcode#</ZipOrigination>
					<ZipDestination>#xmlData.shippostcode#</ZipDestination>
					<Pounds>#xmlData.lbs#</Pounds>
					<Ounces>#xmlData.oz#</Ounces>
					<cfif xmlData.uspsservice contains 'PRIORITY'>
						<Container></Container>
						<Size>REGULAR</Size>
					<cfelse>
						<Container>VARIABLE</Container>
						<Size>LARGE</Size>
						<Width>#xmlData.packageWidth#</Width>
						<Length>#xmlData.packageLength#</Length>
						<Height>#xmlData.packageHeight#</Height>
						<Girth>#xmlData.packageGirth#</Girth>
					</cfif>
					<Machinable>TRUE</Machinable>
				</Package>
			</RateV4Request>
			</cfoutput>
			</cfsavecontent>
			<!--- DEBUG: show xml being sent --->
			<!--- 
			<cfoutput>
				<textarea cols="45" rows="45">
				#xmlStr#
				</textarea>
			</cfoutput>
			 --->
			<!--- send xml request --->
			<cfhttp url="#xmlData.USPSurl#" method="post" throwonerror="yes">
				<cfhttpparam encoded="no" type="formfield" name="api" value="#trim(arguments.usps_rate_type)#">
				<cfhttpparam encoded="no" type="formfield" name="xml" value='#trim(xmlStr)#'>
			</cfhttp>
			<!--- DEBUG: show full response in readable format --->			
			<!--- 
			<cfdump var="#xmlParse(cfhttp.filecontent)#">
			<cfdump var="#arguments#">
			<cfabort>
			 --->
			<!--- handle result --->
			<cfset xmlResponse = XmlParse(CFHTTP.FileContent)>
			<!--- DEBUG: uncomment to show response --->
			<!--- <cfdump var="#xmlResponse#"><cfabort> --->
			<!--- if response is successful --->
			<cfif isDefined('xmlResponse.RateV4Response.Package.Postage.Rate.XmlText') and xmlResponse.RateV4Response.Package.Postage.Rate.XmlText>
				<!--- set the rate value as provided --->
				<cfset rateValue = xmlResponse.RateV4Response.Package.Postage.Rate.XmlText>
				<!--- if not success, get message --->
			<cfelse>
				<!--- show full error/reason in test mode --->
				<cfif application.cw.appTestModeEnabled and
					isDefined('xmlResponse.RateV4Response.Package.Error.Description.XmlText')>
					<cfset rateValue = 'USPS Rate Unavailable - Reason:' & xmlResponse.RateV4Response.Package.Error.Description.XmlText>
				<cfelse>
					<cfset rateValue = 'USPS Lookup Unavailable'>
				</cfif>
			</cfif>
			<!--- if no cartweaver customer is found --->
		<cfelse>
			<cfset rateValue = 'Address Data Unavailable'>
		</cfif>
		<cfcatch>
			<cfset rateValue = 'USPS Lookup Offline'>
		</cfcatch>
	</cftry>
	<cfreturn rateValue>
</cffunction>
<!--- END USPS --->

</cfsilent>