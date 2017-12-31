<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-checkout.cfm
File Date: 2014-07-01
Description:displays multi-step checkout process
NOTES: 
Variable "request.cwpage.currentStep" controls which content is visible to the user,
and triggers loading of the current step
Variable "request.cwpage.postToProcessor" controls action in final step.
- If true, this means order has been submitted using an external processor (e.g. PayPal),
and triggers submission of the processor's payment form, sending the customer to the processor for payment.
- Default is false, which shows the submit order form and submit order button.
Payment processing files are stored in cwapp/auth/ and are read dynamically into the application memory.
The payment method(s) available are selectable in the Cartweaver admin.
Specific code within each processing file contains values specific to that payment method or Gateway,
including messages shown to the user during the checkout process, and an optional logo or image for each method.
STEP IDS are used to target active steps in the process
Step 1 (#step1) - select new account or login
Step 2 (#step2) - address/user/billing/shipping info
Step 3 (#step3) - select shipping method, show selected method
Step 4 (#step4) - review and confirm order
Step 5 (#step5) - select payment method (if applicable) and/or submit payment
- also handles gateway responses, and secondary submission to processor if needed
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
<!--- customerID needed to handle account / billing --->
<cfparam name="session.cwclient.cwCustomerID" default="0">
<!--- default totals used between checkout steps --->
<cfparam name="session.cwclient.cwShipTotal" default="0">
<cfparam name="session.cwclient.cwOrderTotal" default="0">
<!--- customer name for 'logged in as' link --->
<cfparam name="session.cwclient.cwCustomerName" default="">
<!--- var for type of checkout = guest / account --->
<cfparam name="session.cwclient.cwCustomerCheckout" default="account">
<!--- errors from forms being submitted --->
<cfparam name="request.cwpage.formErrors" default="">
<!--- if order has been placed, hide initial steps --->
<cfparam name="request.cwpage.orderFinal" default="false">
<!--- if true, order has been placed, show processor payment form in final step --->
<cfparam name="request.cwpage.postToProcessor" default="false">
<!--- show shipping (can be turned off with additional logic such as single method) --->
<cfparam name="request.cwpage.shipDisplay" default="#application.cw.shipEnabled#">
<!--- default payment type --->
<cfparam name="session.cw.authType" default="">
<!--- customer message entered with order --->
<cfparam name="session.cw.order_message" default="">
<cfparam name="form.order_message" default="#session.cw.order_message#">
<cfparam name="request.cwpage.orderMessage" default="#form.order_message#">
<!--- ignore payment, used for 0 balance orders --->
<cfparam name="request.cwpage.bypassPayment" default="false">
<cfif not len(trim(session.cwclient.cwCustomerID))>
	<cfset session.cwclient.cwCustomerID = 0>
</cfif>
<!--- clean up form and url variables --->
<cfinclude template="cwapp/inc/cw-inc-sanitize.cfm">
<!--- CARTWEAVER REQUIRED FUNCTIONS --->
<cfinclude template="cwapp/inc/cw-inc-functions.cfm">
<!--- form and link actions --->
<cfparam name="request.cwpage.hrefUrl" default="#CWtrailingChar(trim(application.cw.appCwStoreRoot))##request.cw.thisPage#">
<!--- confirm and submit page url --->
<cfparam name="request.cwpage.placeOrderUrl" default="#CWtrailingChar(trim(application.cw.appCwStoreRoot))##request.cw.thisPage#">
<!--- discount defaults --->
<cfparam name="session.cwclient.discountPromoCode" default="">
<cfparam name="session.cwclient.discountApplied" default="">
<!--- IF ORDER IS COMPLETE AND PAID IN FULL, send to confirmation page --->
<cfif isDefined('session.cwclient.cwCompleteOrderID') and session.cwclient.cwCompleteOrderID neq 0
and CWorderStatus(session.cwclient.cwCompleteOrderID) gt 2>
<cflocation url="#request.cwpage.urlConfirmOrder#?orderid=#session.cwclient.cwCompleteOrderID#" addtoken="no">
<!--- IF ORDER IS COMPLETE but not paid in full, disable all but final step, change 'submit' button text --->
<cfelseif isDefined('session.cwclient.cwCustomerID') and session.cwclient.cwCustomerID neq 0
	AND isDefined('session.cwclient.cwCompleteOrderID') and session.cwclient.cwCompleteOrderID neq 0
	AND isDefined('session.cw.confirmOrder') and session.cw.confirmOrder is true
	>
	<cfset request.cwpage.orderFinal = true>
	<cfset request.cwpage.currentStep = 5>
	<cfset request.cwpage.submitValue = 'Submit Payment&nbsp;&raquo;'>
	<!--- if order is not complete, use default text --->
<cfelse>
	<cfset request.cwpage.submitValue = 'Place Order&nbsp;&raquo;'>
</cfif>
<!--- if authreset exists in url, remove marker for selection --->
<cfif isDefined('url.authreset') and url.authreset eq 1
	and listLen(application.cw.authMethods) gt 1>
	<cfset session.cw.authPref = 0>
	<cfset session.cw.confirmAuthPref = false>
	<cfset session.cw.confirmOrder = false>
</cfif>
<!--- PROCESS ORDER --->
<!--- PROCESS ORDER --->
<!--- PROCESS ORDER --->
<!--- if error set by confirmation page (e.g. balance due), add to transaction alerts for final step --->
<cfif isDefined('session.cw.paymentAlert') and len(trim(session.cw.paymentAlert))>
	<cfparam name="request.trans.errorMessage" default="">
	<cfset request.trans.errorMessage = listPrepend(request.trans.errorMessage,session.cw.paymentAlert)>
</cfif>
<!--- IF SUBMITTED: check for hidden field in order submission form, should match id of client submitting order --->
<cfif isDefined('form.customer_submit_conf') AND form.customer_submit_conf eq session.cwclient.cwCustomerID>
	<!--- get cart structure --->
	<cfset processcart = CWgetCart()>
	<!--- only process a valid cart - if order has been placed and page is refreshed, or user comes 'back' from offsite gateway, no cart totals will be available --->
	<!--- NOTE: when auto-confirm is enabled, user will be taken to 'no payment applied' screen and order will remain status 'pending' --->
	<cfif isDefined('processcart.carttotals.total') and isNumeric(processcart.carttotals.total)>
		<!--- shipping totals --->
		<cfif isDefined('session.cwclient.cwShipCountryID') and session.cwclient.cwShipCountryID gt 0 AND application.cw.shipEnabled>
			<cfif isDefined('session.cw.confirmShipID') and session.cw.confirmShipID gt 0>
				<!--- if we don't have a valid rate stored yet --->
				<cfif not (isDefined('session.cwclient.cwShipTotal') and session.cwclient.cwShipTotal gt 0)>
					<cfset shipVal = CWgetShipRate(
					ship_method_id=session.cw.confirmShipID,
					cart_id=session.cwclient.cwCartID
					)>
				<cfelse>
					<cfset shipVal = session.cwclient.cwShipTotal>
				</cfif>
			<cfelse>
				<cfset shipVal = 0>
			</cfif>
			<!--- reset value of client var --->
			<cfif isNumeric(shipVal)>
				<cfset session.cwclient.cwShipTotal = shipVal>
			<cfelse>
				<cfset session.cwclient.cwShipTotal = 0>
			</cfif>
			<!--- set cart shipping total --->
			<cfif isNumeric(shipVal)>
				<cfset processcart.carttotals.shipping = lsNumberFormat(shipVal,'9.99')>
			<cfelse>
				<cfset processcart.carttotals.shipping = 0>
			</cfif>
			<!--- /end shipping total --->
			<!--- shipping tax --->
			<cfif application.cw.taxChargeOnShipping and application.cw.taxCalctype is 'localtax'>
				<cfset shipTaxVal = CWgetShipTax(
									country_id=session.cwclient.cwShipCountryID,
									region_id=session.cwclient.cwShipRegionID,
									taxable_total=processcart.carttotals.shipping,
									cart=processcart
									)>
			<!--- if defined from whole cart tax function in request scope --->
			<cfelseif isDefined('request.cwpage.cartShipTaxTotal') and request.cwpage.cartShipTaxTotal gt 0>
				<cfset shipTaxVal = request.cwpage.cartShipTaxTotal>
			<cfelse>
				<cfset shipTaxVal = 0>
			</cfif>
			<cfset processcart.carttotals.shippingTax = lsNumberFormat(shipTaxVal,'9.99')>
			<!--- /end shipping tax --->
			<!--- add shipping amounts to cart total --->
			<cfset processcart.carttotals.total = processcart.carttotals.total + processcart.carttotals.shipping + processcart.carttotals.shippingTax>
		</cfif>
		<!--- /end shipping totals --->
		<!--- process the order, passing in the cart contents --->
		<cfmodule template="cwapp/mod/cw-mod-orderprocess.cfm"
		cart="#processcart#"
		form_data="#form#"
		>
		<!--- if errors are returned by order processing --->
		<cfif isDefined('request.trans.errorMessage') and len(trim(request.trans.errorMessage))>
			<cfset request.cwpage.currentStep = 5>
		</cfif>
		<!--- /end processing errors --->
		<!--- if errors are returned by form validation --->
		<cfif isDefined('request.trans.formerrors') and len(trim(request.trans.formerrors))>
			<cfset request.cwpage.formErrors = request.trans.formerrors>
			<cfset request.cwpage.currentStep = 5>
		</cfif>
		<!--- /end form errors --->
		<!--- if using processor payment type, or if order was inserted, this will be 'true' from the orderprocess function above --->
		<cfif isDefined('session.cwclient.cwCustomerID') and session.cwclient.cwCustomerID neq 0
			AND (
			(isDefined('request.cwpage.postToProcessor') and request.cwpage.postToProcessor is true)
			OR (isDefined('request.trans.orderInserted') and request.trans.orderInserted is true)
			)>
			<!--- set order as final, to hide initial content while still showing step headings --->
			<cfset request.cwpage.orderFinal = true>
			<cfset request.cwpage.currentStep = 5>
		</cfif>
	<!--- if cart is invalid --->
	<cfelse>
		<!--- redirect user to show cart page --->
		<cflocation url="#request.cwpage.urlShowCart#" addtoken="no">
	</cfif>
</cfif>
<!--- /END PROCESS ORDER --->
<!--- step-approval defaults --->
<cfparam name="session.cw.confirmAddress" default="false">
<cfparam name="session.cw.confirmShip" default="false">
<cfparam name="session.cw.confirmAuthPref" default="false">
<cfparam name="session.cw.confirmCart" default="false">
<!--- client order confirmed is set to true below, *after* both shipping and payment options have been set --->
<cfparam name="session.cw.confirmOrder" default="false">
<!--- if cart is confirmed, mark in user's session --->
<cfif isDefined('url.cartconfirm') and url.cartconfirm is 1>
	<cfset session.cw.confirmCart = true>
</cfif>
<!--- PROMO CODES --->
<cfif isDefined('form.promocode')>
	<!--- remove marker for order confirmed in checkout --->
	<cfset session.cw.confirmCart = false>
</cfif>
<!--- VERIFY AT LEAST ONE CHECKOUT METHOD EXISTS: bypassed in 'test mode' --->
<cfif ((not isDefined('application.cw.authMethods')) OR application.cw.authMethods is '')
	and not (isDefined('application.cw.appTestModeEnabled') and application.cw.appTestModeEnabled is true)>
	<cfset session.cw.authPref = ''>
	<cfset session.cw.confirmAuthPref = false>
<!---  confirm payment selection from client memory (in case of repeat payments) --->
<cfelseif (not isDefined('session.cw.authPref') or (session.cw.authpref eq 0 and (session.cwclient.cwOrderTotal + session.cwclient.cwShipTotal gt 0)))
	and (isDefined('session.cwclient.cwCustomerAuthPref') and session.cwclient.cwCustomerAuthPref gt 0)
	and listFind(application.cw.authMethods,session.cwclient.cwCustomerAuthPref)
	>
	<!--- set in session memory, mark confirmed --->
	<cfset session.cw.authPref = session.cwclient.cwCustomerAuthPref>
	<cfset session.cw.confirmAuthPref = true>
<!--- if method already set --->
<cfelseif isDefined('session.cw.authPref') and isDefined('session.cwclient.cwCustomerAuthPref')
	and session.cw.authPref eq session.cwclient.cwCustomerAuthPref
	and listFind(application.cw.authMethods,session.cwclient.cwCustomerAuthPref)
	>
	<cfset session.cw.confirmAuthPref = true>
	<!--- if only one method exists --->
<cfelseif listLen(application.cw.authMethods) eq 1
	and session.cwclient.cwShipTotal + session.cwclient.cwOrderTotal gt 0>
	<cfset session.cw.authPref = application.cw.authMethods>
	<cfset session.cw.confirmAuthPref = true>
	<!--- set client variable for payment type --->
	<cfset session.cwclient.cwCustomerAuthPref = session.cw.authPref>
	<!--- if no auth methods exist --->
<cfelseif listLen(application.cw.authMethods) lt 1
	or (session.cwclient.cwShipTotal + session.cwclient.cwOrderTotal lte 0)>
	<cfset session.cw.authPref = 0>
	<cfset session.cw.confirmAuthPref = true>
	<!--- set client variable for no payment --->
	<cfset session.cwclient.cwCustomerAuthPref = 0>
<cfelse>
	<cfset session.cw.confirmAuthPref = false>
</cfif>
<!--- GET CUSTOMER DETAILS --->
<cfset CWcustomer = CWgetCustomer(session.cwclient.cwCustomerID)>
<!--- GET CART --->
<cfif isdefined('session.cwclient.cwCartID') and session.cwclient.cwCartID neq 0>
	<cfset cwcart = CWgetCart()>
<cfelseif isdefined('cookie.cwCartID') and cookie.cwCartID neq 0>
	<cfset session.cwclient.cwCartID = cookie.cwCartID>
	<cfset cwcart = CWgetCart()>
<cfelse>
	<cfset session.cwclient.cwCartID = 0>
	<cfset cwcart = CWgetCart()>
</cfif>
<!--- if cart is empty, and order has not been completed, redirect user to show cart page --->
<cfif arrayLen(cwcart.cartitems) eq 0
	AND NOT (
		isDefined('session.cwclient.cwCompleteOrderID') and session.cwclient.cwCompleteOrderID neq 0
		AND isDefined('cwcart.carttotals.total') and cwcart.carttotals.total gt 0
		)>
	<cflocation url="#request.cwpage.urlShowCart#" addtoken="no">
</cfif>
<!--- if all items are 'no shipping' bypass shipping step --->
<cfif request.cwpage.shipDisplay is true>
	<!--- set to false as default --->
	<cfset request.cwpage.shipDisplay = false>
	<!--- set back to true if any item matches --->
	<cfloop from="1" to="#arrayLen(cwcart.cartItems)#" index="i">
		<cfif cwcart.cartItems[i].shipEnabled is true>
			<cfset request.cwpage.shipDisplay = true>
			<cfbreak>
		</cfif>
	</cfloop>
<cfelse>
	<cfset session.cw.confirmShip = true>	
</cfif>
<!--- if client login, address, shipping, cart and payment are all confirmed, mark orderconfirmed in session memory --->
<cfif session.cwclient.cwCustomerID neq '0'
	and session.cw.confirmAddress eq true
	and (request.cwpage.shipDisplay eq false or session.cw.confirmShip eq true)
	and session.cw.confirmCart eq true
	and session.cw.confirmAuthPref eq true>
	<cfset session.cw.confirmOrder = true>
<cfelse>
	<cfset session.cw.confirmOrder = false>
</cfif>
<!--- if cart total is 0, bypass payment --->
<cfif cwcart.carttotals.total lte 0 and session.cwclient.cwShipTotal lte 0>
	<cfset session.cw.authPref = 0>
	<cfset session.cwclient.cwCustomerAuthPref = 0>
	<cfset request.cwpage.bypasspayment = true>
<!--- if other confirmations are set, confirm the order, allow submission --->
	<cfif session.cwclient.cwCustomerID neq '0'
		and session.cw.confirmAddress eq true
		and session.cw.confirmShip eq true
		and session.cw.confirmCart eq true>
		<cfset session.cw.confirmAuthPref = true>
		<cfset session.cw.confirmOrder = true>
	</cfif>
</cfif>

<!---
CURRENT STEP:
MANAGE AVAILABLE STEPS IN THE CHECKOUT PROCESS
--->
<!--- default first step --->
<cfparam name="request.cwpage.currentStep" default="1">
<!--- if not logged in or using guest checkout, show first step --->
<cfif application.cw.customerAccountEnabled
	and session.cwclient.cwCustomerID eq 0 and not isDefined('url.account')
	and not session.cw.confirmOrder and not isDefined('form.customer_email')>
	<cfset request.cwpage.currentStep = 1>
<!--- if logged in, or submitting customer form, show second step --->
<cfelseif (session.cwclient.cwCustomerID neq 0 or isDefined('form.customer_email'))
	and request.cwpage.currentStep lte 1>
	<cfset request.cwpage.currentStep = 2>
	<!--- if accounts are not enabled, set client var, skip login step --->
<cfelseif application.cw.customerAccountEnabled neq true>
	<cfset session.cwclient.cwCustomerCheckout = 'guest'>
	<!--- advance to step 2 --->
	<cfif request.cwpage.currentStep lte 1>
		<cfset request.cwpage.currentStep = 2>
	</cfif>
	<!--- if accounts are enabled, but optional, and account=0/1 is in url --->
<cfelseif application.cw.customerAccountEnabled eq true
	and application.cw.customerAccountRequired eq false
	and isDefined('url.account') and (url.account eq 0 or url.account eq 1)>
	<!--- advance to step 2 --->
	<cfif request.cwpage.currentStep lte 1>
		<cfset request.cwpage.currentStep = 2>
		<!--- if selecting to turn accounts off --->
		<cfif url.account eq 0>
			<cfset session.cwclient.cwCustomerCheckout = 'guest'>
		<!--- if turning on after selecting guest previously --->
		<cfelse>
			<cfset session.cwclient.cwCustomerCheckout = 'account'>
		</cfif>
	</cfif>
</cfif>

<!--- if shipping is reset, show shipping step --->
<cfif isDefined('url.shipreset') and url.shipreset eq 1>
	<cfset session.cwclient.cwShipTotal = 0>
	<cfset session.cw.confirmShip = false>
	<cfset structDelete(session.cw,'confirmShipID')>
	<cfset structDelete(session.cw,'confirmShipName')>
	<cfif request.cwpage.shipDisplay is true>
		<cfset request.cwpage.currentStep = 3>
	<cfelse>
		<cfset request.cwpage.currentStep = 2>
	</cfif>
<!--- if shipping confirmed, show next step --->
<cfelseif (request.cwpage.shipDisplay is false or (isDefined('session.cw.confirmShipID') and session.cw.confirmShipID gt 0)
or 	(session.cwclient.cwShipTotal eq 0 and session.cw.confirmShip is true and isDefined('session.cw.confirmShipID') and session.cw.confirmShipID is 0)) 
	and session.cw.confirmShip eq true and session.cw.confirmAddress eq true and request.cwpage.currentStep lte 4>
	<cfset request.cwpage.currentStep = 4>
</cfif>
<!--- if address is reset --->
<cfif isDefined('url.custreset') and url.custreset eq 1>
	<cfif session.cwclient.cwCustomerID eq 0>
		<cfset request.cwpage.currentStep = 1>
	<cfelse>
		<cfset request.cwpage.currentStep = 2>
	</cfif>
	<cfset session.cw.confirmAddress = false>
<!--- if address confirmed, show third step --->
<cfelseif session.cwclient.cwCustomerID neq '0' AND session.cw.confirmAddress eq true AND request.cwpage.currentStep lte 3>
	<cfif request.cwpage.shipDisplay is true>
		<cfset request.cwpage.currentStep = 3>
	<cfelse>
		<cfset request.cwpage.currentStep = 4>
	</cfif>
</cfif>
<!--- if not using shipping, advance to fourth step --->
<cfif request.cwpage.shipDisplay is false and request.cwpage.currentStep eq 3 and isDefined('session.cw.confirmShip') and session.cw.confirmShip is true>
	<cfset request.cwpage.currentStep = 4>
</cfif>
<!--- if address, shipping and cart are all confirmed --->
<cfif session.cwclient.cwCustomerID neq '0' and (request.cwpage.shipDisplay is false or session.cw.confirmShip eq true) and session.cw.confirmAddress eq true and session.cw.confirmCart eq true>
	<cfset request.cwpage.currentStep = 5>
</cfif>
<!--- /END SET CURRENT STEP --->
<!--- set up checkout steps in breadcrumb nav --->
<cfif request.cwpage.orderFinal>
	<cfsavecontent variable="checkoutSteps"> : <strong>Submit Payment</strong></cfsavecontent>
<cfelse>
	<cfsavecontent variable="checkoutSteps"> : <cfinclude template="cwapp/inc/cw-inc-checkoutsteps.cfm"></cfsavecontent>
</cfif>
</cfsilent>
<!--- /////// START OUTPUT /////// --->
<!--- breadcrumb navigation: indicate current step of process (section opened on page load)
		note: javascript is 0-based (0 = first step) --->
<cfmodule template="cwapp/mod/cw-mod-searchnav.cfm"
search_type="breadcrumb"
separator=" &raquo; "
end_label="Check Out#checkoutSteps#"
all_categories_label=""
all_secondaries_label=""
all_products_label=""
>
<!--- show login form --->
<div id="CWcheckout" class="CWcontent">
	<h1>Check Out</h1>
	<!--- AT LEAST ONE NUMERIC PAYMENT METHOD ID MUST EXIST --->
	<cfif isDefined('application.cw.authMethods') AND trim(application.cw.authMethods) is not '' and isNumeric(listFirst(application.cw.authMethods))
		OR (isDefined('application.cw.appTestModeEnabled') and application.cw.appTestModeEnabled is true)>
	<!--- LOGIN / NEW ACCOUNT: STEP 1 --->
	<cfif application.cw.customerAccountEnabled>
		<div class="CWformSection" id="step1">
			<h3 class="CWformSectionTitle CWactiveSection">New / Returning Customer</h3>
			<cfif request.cwpage.orderFinal eq false>
				<!--- login section --->
				<div class="CWstepSection">
					<!--- if not logged in --->
					<cfif (not isDefined('session.cwclient.cwCustomerID') or not isDefined('session.cwclient.cwCustomerType') or session.cwclient.cwCustomerID is 0 or session.cwclient.cwCustomerType is 0)
						or (isDefined('session.cwclient.cwCustomerCheckout') and session.cwclient.cwCustomerCheckout is 'guest')>
						<!--- NEW CUSTOMERS INFO --->
						<div class="halfLeft">
							<h3 class="CWformTitle">NEW CUSTOMERS: Enter Details Below to Check Out</h3>
							<div class="center top40">
								<!--- if accounts are enabled but not required --->
								<cfif application.cw.customerAccountRequired neq true>
									<!--- if resetting from url, create a link to switch back --->
									<cfif isDefined('url.account') and url.account eq 0>
										<div class="CWcheckoutLinkWrap"><a id="CWlinkResetLogin" class="CWcheckoutLink" href="<cfoutput>#request.cwpage.hrefUrl#?account=1</cfoutput>" style="">Create Account&nbsp;&raquo;</a></div>
									<cfelse>
										<!--- this link shows the next step w/ no page reload (default) --->
										<div class="CWcheckoutLinkWrap"><a id="CWlinkSkipLogin" class="CWcheckoutLink" href="#" style="">Create Account&nbsp;&raquo;</a></div>
									</cfif>
									<div class="CWcheckoutLinkWrap"><a id="CWlinkGuestLogin" class="CWcheckoutLink" href="<cfoutput>#request.cwpage.hrefUrl#?account=0&logout=1</cfoutput>" style="">Guest Checkout&nbsp;&raquo;</a></div>
									<!--- if accounts are required --->
								<cfelse>
									<a id="CWlinkSkipLogin" class="CWcheckoutLink" href="#" style="">Check Out&nbsp;&raquo;</a>
								</cfif>
							</div>
						</div>
						<!--- LOGIN FORM --->
						<cfmodule template="cwapp/mod/cw-mod-formlogin.cfm"
						form_heading="RETURNING CUSTOMERS: Log In">
					<!--- if logged in --->
					<cfelseif len(trim(session.cwclient.cwCustomerName))>
						<h3 class="CWformTitle">Verify Address Details Below</h3>
						<div class="sideSpace">
							<p>Logged in as
							<cfoutput>#session.cwclient.cwCustomerName#</cfoutput>&nbsp;&nbsp;
							<!--- logout link --->
							<span class="smallPrint"><cfoutput><a href="#request.cwpage.hrefUrl#?logout=1">Not your account?</a></cfoutput></span>
							</p>
						</div>
					</cfif>
					<!--- /end if logged in --->
				</div>
			</cfif>
			<!--- /end if orderFinal --->
		</div>
	</cfif>
	<!--- /END LOGIN/NEW ACCOUNT: STEP 1--->
	<!--- CUSTOMER INFO: STEP 2 START --->
	<div class="CWformSection" id="step2">
		<!--- customer account section --->
		<cfif session.cw.confirmAddress eq true
			OR isDefined('form.customer_email')
			OR session.cwclient.cwCustomerID neq '0'
			OR (isDefined('url.account') and (url.account eq 1 OR url.account eq 0))
			OR application.cw.customerAccountEnabled neq 'true'>
			<cfset altClass = " CWactiveSection">
		<cfelse>
			<cfset altClass = "">
		</cfif>
		<h3 class="CWformSectionTitle
		<cfoutput>#altclass#</cfoutput>">Address &amp; Account Details</h3>
		<cfif request.cwpage.orderFinal eq false>
			<!--- CUSTOMER INFO FORM --->
			<!--- if account is enabled but not required, user can switch with link to url w/account=0 --->
			<cfif application.cw.customerAccountEnabled eq true
				and application.cw.customerAccountRequired eq false
				and isDefined('url.account') and url.account eq 0
				and not (isDefined('session.cwclient.cwCustomerCheckout') and session.cwclient.cwCustomerCheckout is 'account')>
				<cfset showAccount = false>
				<cfset formAction = request.cwpage.hrefUrl>
				<!--- show customer account fields if customer is new (not logged in),
				or is logged in as checkouttype = 'account --->
			<cfelseif application.cw.customerAccountEnabled
				AND (session.cwclient.cwCustomerID eq 0
				OR	(isDefined('url.account') and url.account is 1)
				OR (isDefined('session.cwclient.cwCustomerCheckout') and session.cwclient.cwCustomerCheckout is 'account')
				)>
				<cfset showAccount = true>
				<cfset formAction = request.cwpage.hrefUrl & '?account=1'>
			<cfelse>
				<cfset showAccount = false>
				<cfset formAction = request.cwpage.hrefUrl>
			</cfif>
			<div class="CWstepSection">
				<cfmodule template="cwapp/mod/cw-mod-formcustomer.cfm"
				submit_value="Confirm &amp; Continue&nbsp;&raquo;"
				success_url="#request.cwpage.hrefUrl#"
				form_action=""
				show_account_info="#showAccount#"
				>
			</div>
		</cfif>
		<!--- /end if orderFinal --->
	</div>
	<!--- /END CUSTOMER INFO: STEP 2 --->
	<!--- SHIPPING METHOD: STEP 3 START --->
	<cfif request.cwpage.shipDisplay>
		<div class="CWformSection" id="step3">
			<h3 class="CWformSectionTitle<cfif session.cw.confirmAddress eq true AND session.cwclient.cwCustomerID neq '0'> CWactiveSection</cfif>">Shipping Details</h3>
			<!--- SHIPPING OPTIONS AND DETAILS --->
			<cfif request.cwpage.orderFinal eq false>
				<div class="CWstepSection">
					<cfif request.cwpage.currentStep gt 1>
						<cfset shipCart = CWgetCart()>
						<!--- SHIPPING DETAILS --->
							<!--- shipping selection / total --->
							<cfmodule template="cwapp/mod/cw-mod-shipdisplay.cfm"
							cart="#shipcart#"
							customer_data="#CWcustomer#"
							show_address="false"
							>
						<div class="CWclear"></div>
						<!--- /end shipping selection --->
					</cfif>
				</div>
			</cfif>
			<!--- /end if orderFinal --->
		</div>
	</cfif>
	<!--- /end if shipping enabled --->
	<!--- /END SHIPPING METHOD: STEP 3 --->
	<!--- CONFIRM CART: STEP 4 START --->
	<div class="CWformSection" id="step4">
		<h3 class="CWformSectionTitle<cfif request.cwpage.currentStep gte 4> CWactiveSection</cfif>">Confirm Order</h3>
		<cfif request.cwpage.orderFinal eq false>
			<div class="CWstepSection">
				<cfif request.cwpage.currentStep gt 3>
					<!--- cart summary --->
					<div class="sideSpace">
						<cfmodule template="cwapp/mod/cw-mod-cartdisplay.cfm"
						cart="#CWcart#"
						display_mode="summary"
						product_order="#application.cw.appDisplayCartOrder#"
						show_images="#application.cw.appDisplayCartImage#"
						show_sku="#application.cw.appDisplayCartSku#"
						show_options="true"
						show_continue="false"
						show_total_row="false"
						link_products="false"
						edit_cart_url=""
						>
					</div>
					<div class="halfLeft">
						<div class="center top40 bottom40">
							<a id="CWlinkConfirmCart" class="CWcheckoutLink" href="<cfoutput>#request.cwpage.hrefUrl#?cartconfirm=1</cfoutput>" style="">Continue&nbsp;&raquo;</a>
						</div>
					</div>
					<div class="halfRight">
						<h3 class="CWformTitle">Order Totals</h3>
						<cfmodule template="cwapp/mod/cw-mod-cartdisplay.cfm"
						display_mode="totals"
						cart="#CWcart#"
						show_payment_total="true"
						>
					</div>
				</cfif>
			</div>
		</cfif>
		<div class="CWclear"></div>
	</div>
	<!--- /END CONFIRM CART: STEP 4 --->
	<!--- SUBMIT ORDER: STEP 5 START --->
	<div class="CWformSection" id="step5">
		<cfif listLen(application.cw.authMethods) gt 0 and request.cwpage.bypassPayment is false>
			<cfset stepTitle="Submit Payment">
		<cfelse>
			<cfset stepTitle="Submit Order">
		</cfif>
		<h3 class="CWformSectionTitle<cfif request.cwpage.currentStep gte 5> CWactiveSection</cfif>"><cfoutput>#stepTitle#</cfoutput></h3>
		<div class="CWstepSection">
			<cfif request.cwpage.currentStep gte 5>
				<!--- CHECKOUT INFO --->
				<div class="CWclear"></div>
				<!--- display any processing errors here --->
				<cfif isDefined('request.trans.formerrors') and len(trim(request.trans.formerrors))
					OR isDefined('request.trans.errorMessage') and len(trim(request.trans.errorMessage))>
					<div class="CWalertBox alertText">
						<cfif isDefined('request.trans.formerrors') and len(trim(request.trans.formerrors))>
							Error: Missing or Invalid Information<br>
						</cfif>
						<cfloop list="#request.trans.errorMessage#" index="mm">
							<cfoutput>#mm#</cfoutput><br>
						</cfloop>
					</div>
				</cfif>
				<!--- /end processing errors --->
				<div class="halfLeft">				
					<!--- IF BOTH PAYMENT METHOD AND SHIPPING METHOD ARE SET --->
					<cfif session.cw.confirmOrder eq true
						and not (
						isDefined('url.authreset') and listLen(application.cw.authMethods) gte 2
						)>
						
						<!--- SUBMIT ORDER (DEFAULT): if submitting order, show form (w/ credit card inputs if using a gateway) --->
						<cfif request.cwpage.postToProcessor eq false>
							<cfif request.cwpage.bypassPayment neq true>
								<!--- non-visible instance of the payment module included here to handle setting selection--->
								<cfmodule template="cwapp/mod/cw-mod-paymentdisplay.cfm"
								submit_url=""
								selected_title=""
								edit_auth_url=""
								show_auth_logo="false"
								show_auth_name="false"
								>
							</cfif>							
							<!--- order submission form --->
							<form name="CWformOrderSubmit" id="CWformOrderSubmit" class="CWvalidate" method="post" action="<cfoutput>#request.cwpage.hrefUrl#</cfoutput>">
								<!--- show submit order message
								and, if auth type is 'gateway', show credit card inputs --->
								<cfif request.cwpage.bypassPayment neq true>
									<!--- credit card fields / submission message ('capture' mode) --->
									<cfmodule template="cwapp/mod/cw-mod-paymentdisplay.cfm"
									display_mode="capture"
									submit_url="#request.cwpage.hrefUrl#"
									edit_auth_url=""
									>
								</cfif>
								<div class="CWclear">
									<!--- order comments --->
									<div class="center">
										<h3 class="CWformTitle">Additional Comments or Instructions</h3>
										<textarea name="order_message" id="order_message" rows="3" cols="35"><cfoutput>#trim(request.cwpage.orderMessage)#</cfoutput></textarea>
									</div>
									<!--- submit button --->
									<div class="center top40 bottom40">
										<input name="order_submit" id="order_submit" type="submit" class="CWformButton" value="<cfoutput>#request.cwpage.submitValue#</cfoutput>">
										<!--- submit link : javascript replaces button with this link --->
										<a style="display:none;" href="#" class="CWcheckoutLink" id="CWlinkOrderSubmit"><cfoutput>#request.cwpage.submitValue#</cfoutput></a>											</div>
									<div class="headSpace"></div>
								</div>
								<!--- hidden fields --->
								<input type="hidden" name="customer_shippref" value="<cfoutput>#session.cw.confirmShip#</cfoutput>">
								<input type="hidden" name="customer_submit_conf" value="<cfoutput>#session.cwclient.cwCustomerID#</cfoutput>">
								<div class="CWclear"></div>
							</form>
						<!--- POST TO PROCESSOR (paypal, etc, after order has been submitted) --->
						<cfelseif isDefined('session.cw.authType') AND session.cw.authType is 'processor'
							AND isDefined('session.cw.authpref') and session.cw.authpref gt 0
							AND isDefined('session.cw.authprefname') and session.cw.authprefname neq ''>
							<!--- verify payment file exists --->
							<cfparam name="application.cw.authMethodData[session.cw.authpref].methodFilename" default="">
							<cfparam name="application.cw.authMethodData[session.cw.authpref].methodName" default="">
							<cfset request.trans.authfilename = application.cw.authMethodData[session.cw.authpref].methodfilename>
							<cfset request.trans.authmethodname = application.cw.authMethodData[session.cw.authpref].methodname>
							<!--- verify auth file exists, and is same as expected in user's session --->
							<cfset authDirectory = application.cw.siteRootPath & cwLeadingChar(cwTrailingChar(application.cw.appCwContentDir),'remove') & 'cwapp/auth/'>
							<cfset authFilePath = authDirectory & request.trans.authfilename>
							<!--- if file is ok, and authpref is same as user selection, invoke the auth include --->
							<cfif fileExists(authFilePath)
								AND request.trans.authmethodname eq session.cw.authprefname>
								<!--- invoke payment file in 'capture' mode (shows submission form) --->
								<cfmodule template="cwapp/auth/#request.trans.authfilename#"
								auth_mode="capture"
								trans_data="#request.trans.data#"
								>
								<!--- clear any stored promo codes --->
								<cfset session.cwclient.discountApplied = ''>
								<cfset session.cwclient.discountPromoCode = ''>
								<!--- set marker for clearing of cart --->
								<cfset request.clearCart = true>
								<!--- WIPE DATA - clear transaction data from request scope --->
								<cfset clearData = structClear(request.trans.data)>
								<cfset clearData = structClear(request.data)>
							</cfif>
							<!--- /end if file ok --->
						</cfif>
						<!--- /end POST TO PROCESSOR or SUBMIT ORDER --->
						<!--- IF PAYMENT METHOD IS NOT SET --->
					<cfelse>
						<!--- payment display --->
						<cfmodule template="cwapp/mod/cw-mod-paymentdisplay.cfm"
						submit_url="#request.cwpage.hrefUrl#"
						selected_title=""
						bypass_payment="#request.cwpage.bypassPayment#"
						>
					</cfif>
				</div>
				<!--- ORDER TOTALS / PAYMENT DETAILS --->
				<div class="halfRight">
					<!--- cart totals / details --->
					<h3 class="CWformTitle">Order Totals</h3>
					<!--- cart display: show totals only --->
					<cfmodule template="cwapp/mod/cw-mod-cartdisplay.cfm"
					display_mode="totals"
					cart="#CWgetcart()#"
					edit_cart_url=""
					show_payment_total="true"
					>
					<!--- payment display: show payment selection --->
					<cfif session.cw.confirmOrder eq true
						and not (isDefined('url.authreset') and listLen(application.cw.authMethods) gte 2)
						and not request.cwpage.bypassPayment
						>
						<cfmodule template="cwapp/mod/cw-mod-paymentdisplay.cfm"
						submit_url="#request.cwpage.hrefUrl#"
						selected_title=""
						>
					</cfif>
				</div>
				<div class="CWclear"></div>
			</cfif>
			<div class="CWclear"></div>
		</div>
	</div>
	<!--- /END SUBMIT ORDER: STEP 5 --->
	<!--- IF NO PAYMENT METHODS EXIST --->
	<cfelse>
		<div class="CWconfirmBox confirmText">
			Checkout Process Offline<br>Payment transaction options for this store are currently unavailable.<br>We apologize for the inconvenience, and are working to correct the problem.
			<cfif isDefined('application.cw.authDirectory') and not directoryExists(application.cw.authDirectory) 
			and isDefined('session.cw.loggedIn') and session.cw.loggedIn is '1'
			and isDefined('session.cw.accessLevel') and listFindNoCase('developer,merchant',session.cw.accessLevel)>
				<br><br>Error: unable to open payment method include directory "<cfoutput>#application.cw.authDirectory#</cfoutput>"
			</cfif>
		</div>
		<!--- SEND MAIL TO DEVELOPER --->
		<cfsavecontent variable="mailContent">
			CHECKOUT PROCESS OFFLINE
			
			Payment transactions for this site are currently offline.
			No orders or payments can be accepted until the problem is resolved.
			
			<cfif isDefined('application.cw.authDirectory') and not directoryExists(application.cw.authDirectory)>Error: unable to open payment method include directory "#application.cw.authDirectory#"</cfif>

			For troubleshooting, reset the application from within the store admin, check the paths in your global settings, and verify at least one active checkout method is available.
			(This warning message can be bypassed for development by placing the store in "Test Mode")
		</cfsavecontent>
		<cfset temp = CWsendMail(mailContent, 'Checkout Process Offline',application.cw.developerEmail)>
	</cfif>
	<!--- /end check for at least one payment method --->
</div>
<!-- /end #CWcheckout -->
<!--- clear out the stored cart if marker is set --->
<cfif isDefined('session.cwclient.cwCartID')
		and isDefined('request.clearCart')
		and request.clearCart is true>
	<cfset clearCart = CWclearCart(session.cwclient.cwCartID)>
</cfif>
<cfsavecontent variable="checkoutjs">
<!--- test credit card info for 'test mode' --->
<cfif isDefined('application.cw.appTestModeEnabled') and application.cw.appTestModeEnabled is true>
<script type="text/javascript">
jQuery(document).ready(function(){
	jQuery('#customer_cardnumber').val('4007000000027');
	jQuery('#customer_cardtype').val('visa');
	jQuery('#customer_cardname').val('Test User');
	jQuery('#customer_cardexpm').val('12');
	jQuery('#customer_cardexpy').val('2016');
	jQuery('#customer_cardccv').val('999');
//end jQuery
});
</script>
</cfif>
<!--- javascript for checkout steps --->
<script type="text/javascript">
jQuery(document).ready(function(){
	// close steps on page load, attach click function for section headings
	jQuery('.CWstepSection').hide().siblings('.CWactiveSection').css('cursor','pointer').click(function(){
		if (jQuery(this).next('.CWstepSection').is(':hidden')){
		jQuery(this).next('.CWstepSection:hidden').slideDown(220);
		} else {
		jQuery(this).next('.CWstepSection:visible').slideUp(220);
		}
	});
	// open the current step
		var curStepId = 'step' + <cfoutput>#request.cwpage.currentStep#</cfoutput>;
	jQuery('#CWcheckout  #' + curStepId + ' .CWstepSection').slideDown(220);
	// function to show/hide each step
	// usage: $toggleSteps([parent id of div to close e.g. 'step1'],[parent id of div to open e.g. 'step2']);
	var $toggleSteps = function(prevStep,nextStep){
		jQuery('#CWcheckout #' + prevStep + ' .CWstepSection').slideUp(220);
		jQuery('#CWcheckout #' + nextStep + ' .CWstepSection').slideDown(220).siblings('.CWformSectionTitle').addClass('CWactiveSection');
		// connect to checkout steps breadcrumb links
		var stepClass = jQuery('#CWcheckout .CWstepSection #' + nextStep).parents('.CWformSection').attr('id');
		jQuery('#CWcheckoutStepLinks span.' + stepClass + ' a').addClass('currentLink');
	};
	// add headings to steps
	jQuery('#CWcheckout .CWformSectionTitle').each(function(index){
		var stepNum = index + 1;
		var stepCounter = '<span class="CWstepCounter">' + stepNum + '</span>';
		jQuery(this).prepend(stepCounter);
	});
	<cfif not request.cwpage.orderFinal>
		// activate dynamic checkout step links
		jQuery('#CWcheckoutStepLinks a').click(function(){
		var stepID = jQuery(this).parents('span').attr('class');
		if( jQuery(this).hasClass('currentLink') == true){
		jQuery('#' + stepID).siblings('div').find('.CWstepSection').slideUp(220);
		jQuery('#' + stepID).find('.CWstepSection').slideDown(220);
		}
		return false;
		});
	</cfif>
	// new customer continue button
	jQuery('#CWlinkSkipLogin').click(function(){
	$toggleSteps('step1','step2');
	return false;
	});
	// show submit link instead of button
	jQuery('#order_submit').hide();
	jQuery('#CWlinkOrderSubmit').show().click(function(){
	jQuery('form#CWformOrderSubmit').submit();
	return false;
	});
	// process form submission errors (list of errant form element IDs)
	<cfif isDefined('request.cwpage.formErrors') AND len(trim(request.cwpage.formErrors))>
		<cfloop list="#request.cwpage.formErrors#" index="ee">
			jQuery('#CWformOrderSubmit').find('#<cfoutput>#ee#</cfoutput>').addClass('warning');
		</cfloop>
	</cfif>
	});
</script>
</cfsavecontent>
<cfhtmlhead text="#checkoutjs#">
<!--- page end / debug --->
<cfinclude template="cwapp/inc/cw-inc-pageend.cfm">