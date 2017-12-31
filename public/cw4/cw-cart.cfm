<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-cart.cfm
File Date: 2012-02-01
Description: shows items in cart with all related functions
NOTES:
Uses cart.carttotals.itemcount (as 'itemcount' var) to determine display
Variable session.cwclient.cwCartID is set in cw-func-init and stored in a cookie in cw-inc-pageend
==========================================================
--->
<!--- set headers to prevent browser cache issues --->
<cfset gmt=getTimeZoneInfo()>
<cfset gmt=gmt.utcHourOffset>
<cfif gmt eq 0>
	<cfset gmt="">
<cfelseif gmt gt 0>
	<cfset gmt="+"&gmt>
</cfif>
<cfheader name="Expires" value="#dateFormat(now(), 'ddd, dd mmm yyyy')# #timeFormat(now(), 'HH:mm:ss')# GMT#gmt#">
<cfheader name="Pragma" value="no-cache">
<cfheader name="Cache-Control" value="no-cache, no-store, proxy-revalidate, must-revalidate">
<!--- cartID is set in CW init functions, default here just in case --->
<cfparam name="session.cwclient.cwCartID" default="0">
<!--- customerID needed to handle account / billing --->
<cfparam name="session.cwclient.cwCustomerID" default="0">
<!--- tax location settings --->
<cfparam name="session.cwclient.cwTaxRegionID" default="0">
<cfparam name="session.cwclient.cwTaxCountryID" default="0">
<!--- discount defaults --->
<cfparam name="session.cwclient.discountPromoCode" default="">
<cfparam name="session.cwclient.discountApplied" default="">
<!--- country can be set by default in admin, client selection/login overrides --->
<cfif not (isDefined('session.cwclient.cwTaxCountryID') and isNumeric(session.cwclient.cwTaxCountryID) and session.cwclient.cwTaxCountryID gt 0)
      and application.cw.taxUseDefaultCountry is true>
	<cfset session.cwclient.cwTaxCountryID = application.cw.defaultCountryID>
</cfif>
<!--- only show tax totals if a country is defined --->
<cfif session.cwclient.cwTaxCountryID eq 0>
	<cfset request.cwpage.showTax = false>
<cfelse>
	<cfset request.cwpage.showTax = true>
</cfif>
<!--- page variables - request scope can be overridden per product as needed
params w/ default values are in application.cfc --->
<cfparam name="request.cwpage.cartHeading" default="">
<cfparam name="request.cwpage.cartText" default="">
<!--- check out page (skip address if already submitted) --->
<cfparam name="request.cwpage.checkoutHref" default="#request.cwpage.urlCheckout#">
<cfif isDefined('session.cw.confirmAddress') AND session.cw.confirmAddress>
	<cfset request.cwpage.checkoutHref = request.cwpage.urlCheckout>
</cfif>
<!--- clean up form and url variables --->
<cfinclude template="cwapp/inc/cw-inc-sanitize.cfm">
<!--- CARTWEAVER REQUIRED FUNCTIONS --->
<cfinclude template="cwapp/inc/cw-inc-functions.cfm">
<!--- // GET CART DETAILS // --->
<cfset cwcart = CWgetCart()>
<!--- simple var for number of items in cart --->
<cfset itemcount = cwcart.carttotals.itemCount>
</cfsilent>
<!--- /////// START OUTPUT /////// --->
<!--- breadcrumb navigation --->
<cfmodule template="cwapp/mod/cw-mod-searchnav.cfm"
search_type="breadcrumb"
separator=" &raquo; "
end_label="View Cart"
all_categories_label=""
all_secondaries_label=""
all_products_label=""
>
<!--- show cart details --->
<div id="CWcart" class="CWcontent">
	<h1>Shopping Cart</h1>
	<!--- if items exist in the cart (if cart does not exist this will be 0) --->
	<cfif itemcount gt 0>
		<!--- subheading --->
		<cfif len(trim(request.cwpage.cartHeading))>
			<cfoutput><h2>#request.cwpage.cartHeading#</h2></cfoutput>
		</cfif>
		<!--- text above cart table --->
		<cfif len(trim(request.cwpage.cartText))>
			<div>
				<cfoutput>#request.cwpage.cartText#</cfoutput>
			</div>
		</cfif>
		<!--- CART TABLE AND UPDATE FORM --->
		<cfmodule template="cwapp/mod/cw-mod-cartdisplay.cfm"
		cart="#CWcart#"
		display_mode="showcart"
		product_order="#application.cw.appDisplayCartOrder#"
		show_images="#application.cw.appDisplayCartImage#"
		show_sku="#application.cw.appDisplayCartSku#"
		show_options="true"
		show_continue="true"
		link_products="true"
		show_tax_total="#request.cwpage.showTax#"
		>
		<!--- CHECKOUT BUTTON --->
		<cfoutput><p class="CWright"><a href="#request.cwpage.checkoutHref#" class="CWcheckoutLink" id="CWlinkCheckout">Check Out&nbsp;&raquo;</a></p></cfoutput>
		<!--- if no products, show message with links --->
	<cfelse>
		<div class="CWconfirmBox confirmText">
			Cart is Empty
			<cfif application.cw.customerAccountEnabled>
				<br>
				<!--- link to log in / my account --->
				<cfif isDefined('session.cwclient.cwCustomerID') and session.cwclient.cwCustomerID neq '0'><cfset loginLinkText = 'Go to your account'><cfelse><cfset loginLinkText = 'Log in'></cfif>
				<a href="<cfoutput>#request.cwpage.urlAccount#</cfoutput>">
				<cfoutput>#loginLinkText#</cfoutput>
				</a> to see previously purchased items
			</cfif>
			<br>
			<!--- search link --->
			<cfif len(trim(request.cwpage.urlSearch))>
				<span class="smallPrint">
					<a href="<cfoutput>#request.cwpage.urlSearch#</cfoutput>">Search for Products</a>
				</span>
			</cfif>
			<!--- continue shopping link --->
			<cfif isDefined('request.cwpage.returnUrl')>
				<span class="smallPrint">
					<cfif len(trim(request.cwpage.returnUrl))>&nbsp;&nbsp;&bull;&nbsp;&nbsp;</cfif><a href="<cfoutput>#request.cwpage.returnUrl#</cfoutput>">Return to Store</a>
				</span>
			</cfif>
		</div>
		<!--- clear stored values related to cart --->
		<cftry>
			<cfset structDelete(session.cw,'cartAlert')>
			<cfset structDelete(session.cw,'cartConfirm')>
			<cfcatch></cfcatch>
		</cftry>
	</cfif>
	<!-- clear floated content -->
	<div class="CWclear"></div>
</div>
<!-- / end #CWcart -->
<!--- recently viewed products --->
<cfinclude template="cwapp/inc/cw-inc-recentview.cfm">
<!--- page end / debug --->
<cfinclude template="cwapp/inc/cw-inc-pageend.cfm">