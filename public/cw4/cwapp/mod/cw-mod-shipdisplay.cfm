<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-mod-shipdisplay.cfm
File Date: 2012-12-29
Description: creates and displays shipping details and selection options
NOTES:
Variables for each shipping method are set within that method's configuration file
All options are assembled and tracked in cw-func-init.cfm
==========================================================
--->
<!--- display mode (totals | select) --->
<cfparam name="attributes.display_mode" default="select">
<!--- edit shipping url (not used for select mode - blank = not shown) --->
<cfparam name="attributes.edit_ship_url" default="#request.cw.thisPage#?shipreset=1">
<!--- show customer shipping address --->
<cfparam name="attributes.show_address" default="true">
<!--- edit address url (blank = not shown) --->
<cfparam name="attributes.edit_address_url" default="#request.cw.thisPage#?custreset=1">
<!--- get customer struct if not passed in --->
<cfparam name="attributes.customer_data" default="">
<!--- global functions --->
<cfinclude template="../inc/cw-inc-functions.cfm">
<!--- clean up form and url variables --->
<cfinclude template="../inc/cw-inc-sanitize.cfm">
<!--- page for form base action --->
<cfparam name="request.cwpage.hrefUrl" default="#CWtrailingChar(trim(application.cw.appCwStoreRoot))##request.cw.thisPage#">
<!--- GET CUSTOMER INFO --->
<cfif attributes.show_address is true>
	<!--- if customer data not passed in, get it here --->
	<cfif not isStruct(attributes.customer_data)>
		<!--- global queries--->
		<cfif not isDefined('variables.CWquerySelectProductDetails')>
			<cfinclude template="../func/cw-func-query.cfm">
		</cfif>
		<!--- customer functions--->
		<cfif not isDefined('variables.CWgetCustomer')>
			<cfinclude template="../func/cw-func-customer.cfm">
		</cfif>
		<cfset CWcustomer = CWgetCustomer(session.cwclient.cwCustomerID)>
	<cfelse>
		<cfset CWcustomer = attributes.customer_data>
	</cfif>
</cfif>
<!--- cart is a cart structure from CWcart function --->
<cfparam name="session.cwclient.cwCartID" default="1">
<cfparam name="attributes.cart" default="#CWgetcart()#">
<cfparam name="attributes.cart.carttotals.shiporderdiscounts" default="0">
<!--- HANDLE SHIPPING FORM SUBMISSION --->
<cfparam name="session.cw.confirmShipID" default="0">
<cfparam name="session.cw.confirmShipName" default="">
<cfparam name="session.cw.confirmShip" default="false">
<cfif isDefined('form.selectShip') and form.selectShip neq 0>
	<cfset session.cw.confirmShipID = form.selectShip>
	<cfset session.cw.confirmShipName = CWgetShipMethodName(form.selectShip)>
	<cfset session.cw.confirmShip = true>
	<!--- refresh page --->
	<cflocation url="#request.cw.thisPageQS#" addtoken="no">
</cfif>
<!--- if shipreset exists in url, remove marker for selection --->
<cfif isDefined('url.shipreset') and len(trim(url.shipreset))>
	<cfset session.cw.confirmShip = false>
	<cfset session.cw.confirmShipID = 0>
	<cfset session.cw.confirmShipName = ''>
	<cfset session.cwclient.cwShipTotal = 0>
<!--- if shipconfirm exists in url, set method --->
<cfelseif isDefined('url.shipconfirm') and isNumeric(url.shipconfirm)>
	<cfset session.cw.confirmShipID = url.shipconfirm>
	<cfset session.cw.confirmShip = true>	
	<cflocation url="#request.cw.thisPage#" addtoken="no">
</cfif>
<!--- QUERY: get all available shipping methods --->
<cfset allShipMethods = CWgetShipMethodDetails(cart_id=session.cwclient.cwCartID)>
<!--- QUERY: get valid shipping options, set session values --->
<cfset shipMethodsQuery = CWgetShipMethodDetails(cart_id=session.cwclient.cwCartID,ship_method_id=session.cw.confirmShipID)>
<!--- if no methods available, set null values into session --->
<cfif shipMethodsQuery.recordCount is 0>
	<cfset session.cw.confirmShip = false>
	<cfset session.cw.confirmShipID = 0>
	<cfset session.cw.confirmShipName = ''>
	<cfset session.cwclient.cwShipTotal = 0>
	<cfset shipVal = 0>
	<!--- if only one method, set method id, trigger 'totals' mode --->
<cfelseif shipMethodsQuery.recordCount is 1>
	<cfset session.cw.confirmShipID = shipMethodsQuery.ship_method_id>
	<cfset session.cw.confirmShipName = shipMethodsQuery.ship_method_name>
	<!--- skip the single method (auto-confirm) --->
	<cfif isDefined('application.cw.shipDisplaySingleMethod') and application.cw.shipDisplaySingleMethod neq true>
		<cfset session.cw.confirmShip = true>
	</cfif>
</cfif>
<!--- get shipping total if method is confirmed --->
<cfif session.cw.confirmShip eq true OR (isDefined('session.cw.confirmShipID') and session.cw.confirmShipID gt 0)>
	<!--- if we don't have a valid rate yet --->
	<cfif not (isDefined('session.cwclient.cwShipTotal') and session.cwclient.cwShipTotal gt 0 and session.cw.confirmShip gt 0)>
		<cfset shipVal = CWgetShipRate(
		ship_method_id=session.cw.confirmShipID,
		cart_id=session.cwclient.cwCartID,
		calc_type=shipMethodsQuery.ship_method_calctype
		)>
	<cfelse>
		<cfset shipVal = session.cwclient.cwShipTotal>
	</cfif>	
	<!--- reset value of client var --->
	<cfif isNumeric(shipVal)>
		<cfset session.cwclient.cwShipTotal = shipVal>
	<cfelse>
		<cfset session.cwclient.cwShipTotal = 0>
	</cfif>
</cfif>
<!--- if customer has specified shipping, or no ship methods are
available (nothing to select), show totals mode  --->
<cfif (isDefined('session.cw.confirmShipID') and session.cw.confirmShipID gt 0)
	OR shipMethodsQuery.recordCount is 0>
	<cfset attributes.display_mode = 'totals'>
</cfif>
<!--- fallback value for selection --->
<cfset request.cwpage.shipOk = false>
<cfset request.cwpage.shipPass = false>
</cfsilent>
<!--- /// START OUTPUT /// --->
<!--- ADDRESS INFO --->
<cfif attributes.show_address>
<p>
<!--- edit address link --->
<cfif len(trim(attributes.edit_address_url))>
<span class="CWeditLink">&raquo;&nbsp;<a href="<cfoutput>#attributes.edit_address_url#</cfoutput>">Edit Address</a></span>
</cfif>
	<cfoutput>
		<!--- address text --->
		<span class="label">Shipping To:</span>
		#cwcustomer.shipname#
		<br>
		<span class="label">&nbsp;</span>
		#cwcustomer.shipaddress1#
		<cfif len(trim(cwcustomer.shipaddress2))>
		<br>
		<span class="label">&nbsp;</span>
		#cwcustomer.shipaddress2#
		</cfif>
		<br>
		<span class="label">&nbsp;</span>
		#cwcustomer.shipcity#, #cwcustomer.shipstateprovname#
		<br>
		<span class="label">&nbsp;</span>
		#cwcustomer.shipcountry#
		<br>
		<span class="label">&nbsp;</span>
		#cwcustomer.shipzip#
	</cfoutput>
</p>
</cfif>
<!--- /end address --->
<!--- TOTALS --->
<cfif attributes.display_mode is 'totals'>
	<h3 class="CWformTitle"><cfif isDefined('session.cw.confirmShipID') and session.cw.confirmShipID gt 0 and shipMethodsQuery.recordCount gt 1>Shipping Method Selected<cfelse>Shipping Details</cfif></h3>
	<!--- allow continue link for passthrough --->
	<cfif isDefined('shipVal') and shipVal lt .01>
		<cfset session.cw.confirmShip = true>
		<cfset request.cwpage.shipPass = true>
	</cfif>
	<cfif isDefined('shipVal')>
		<!--- shipval (shipping total) set above --->
		<p>
		<!--- link to change selection --->
		<cfif len(trim(attributes.edit_ship_url)) and allShipMethods.recordCount gt 1>
			<span class="CWeditLink">&raquo;&nbsp;<a href="<cfoutput>#attributes.edit_ship_url#"</cfoutput>>Change Shipping</a></span>
		</cfif>
		<cfif len(trim(session.cw.confirmShipName))>
			<span class="label">Shipping via:</span> <cfoutput>#session.cw.confirmShipName#</cfoutput>
		</cfif>
		</p>
		<p class="clear">
		<span class="label"><strong>Shipping Total:</strong></span>
		<!--- ship value --->
		<strong>
		<cfif isNumeric(shipVal)>
			<cfoutput>#lsCurrencyFormat(shipVal,'local')#</cfoutput>
		<cfelse>
			<cfoutput>#trim(shipVal)#</cfoutput>
		</cfif>
		</strong>
		</p>
	</cfif>
	<!--- link to continue if there's only one ship method, or passthrough allowed --->
	<cfif (len(trim(attributes.edit_ship_url)) and shipMethodsQuery.recordCount eq 1) or request.cwpage.shipPass is true>
		<div class="center top40 bottom40">
			<a id="CWlinkSkipShip" class="CWcheckoutLink" href="<cfoutput>#request.cw.thisPage#?shipconfirm=#session.cw.confirmShipID#</cfoutput>" style="">Continue&nbsp;&raquo;</a>
		</div>
	</cfif>
	<!--- SELECT (default) --->
<cfelse>
	<h3 class="CWformTitle">Select Shipping Method</h3>
	<form id="CWformShipSelection" class="CWvalidate" action="<cfoutput>#request.cwpage.hrefUrl#</cfoutput>" method="post">
		<cfoutput query="shipMethodsQuery" group="ship_method_id">
			<cfset shipVal = CWgetShipRate(
			ship_method_id=shipMethodsQuery.ship_method_id,
			cart_id=session.cwclient.cwCartID,
			calc_type=shipMethodsQuery.ship_method_calctype
			)>
			<!--- hide method if errors exist --->
			<cfif isNumeric(shipVal) or application.cw.appTestModeEnabled is true>
			<cfset request.cwpage.shipOk = true>
			<div class="CWshipOption">
				<label>
				<!--- hidden link, shown with javascript --->
				<a href="##" class="CWselectLink" style="display:none;">Select</a>
				<input type="radio" name="selectShip" class="required" value="#ship_method_id#" <cfif isDefined('session.cw.confirmShip') and session.cw.confirmShip eq ship_method_id>checked="checked"</cfif>>
				<!--- shipping type --->
				<span class="CWshipName">#ship_method_name#</span>
				<!--- shipping rate --->
				<span class="CWshipOptionAmount">
					<cfif isNumeric(shipVal) AND shipVal gt 0>
						#lsCurrencyFormat(shipVal,'local')#
					<cfelseif shipVal eq 0>
						Free Shipping
					<cfelse>
						#shipVal#
					</cfif>
				</span>
				</label>
			</div>
			</cfif>			
		</cfoutput>
		<!--- submit button, hidden with javascript --->
		<div class="center CWclear top40">
			<input type="submit" class="CWformButton" id="CWshippingSelectSubmit" value="Submit Selection&nbsp;&raquo;">
		</div>
	</form>

	<!--- if all available methods are throwing errors --->
	<cfif not request.cwpage.shipOk is true>
		<p class="clear"><span class="label"><strong>Rate Unavailable:</strong></span>
		<strong><cfoutput>#lsCurrencyFormat(0,'local')#</cfoutput></strong></p>
		<!--- link to continue --->
		<div class="center top40 bottom40">
			<a id="CWlinkSkipShip" class="CWcheckoutLink" href="<cfoutput>#request.cw.thisPage#?shipconfirm=#session.cw.confirmShipID#</cfoutput>" style="">Continue&nbsp;&raquo;</a>
		</div>
	</cfif>
	<!--- /end error handling --->	

	<cfsavecontent variable="shipselectjs">
	<!--- javascript for selection --->
	<script type="text/javascript">
	jQuery(document).ready(function(){
	// replace radio buttons with links
	jQuery('#CWformShipSelection').find('input:radio').each(function(){
		jQuery(this).hide().siblings('a.CWselectLink').show();
	});
	// clicking link submits form
	jQuery('#CWformShipSelection .CWcheckoutLink').show().click(function(){
		jQuery('form#CWFormShipSelection').submit();
		return false;
	});
	// hide submit button
	jQuery('#CWshippingSelectSubmit').hide();
	// form submits on click of anything in label
	jQuery('#CWformShipSelection .CWshipOption > *').css('cursor','pointer').click(function(){
		jQuery(this).find('input:radio').prop('checked','checked');
		jQuery(this).parents('form').submit();
		return false;
	});
	});
	</script>
	</cfsavecontent>
	<cfhtmlhead text="#shipselectjs#">
</cfif>