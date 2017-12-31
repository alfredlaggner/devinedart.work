<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-confirm.cfm
File Date: 2012-09-01
Description: displays order confirmation, runs post-transaction processing
NOTES:
Enable "test mode" in CW admin, to persist client/session variables for testing
Variable session.cwclient.cwCartID is set in cw-func-init.cfm
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
<!--- orderID --->
<cfparam name="session.cwclient.cwCompleteOrderID" default="0">
<!--- customerID needed to handle account / billing --->
<cfparam name="session.cwclient.cwCustomerID" default="0">
<!--- error message / confirmation from transaction --->
<cfparam name="request.trans.errorMessage" default="">
<cfparam name="request.trans.confirmMessage" default="">
<!--- page heading --->
<cfparam name="request.cwpage.confirmHeading" default="Order Confirmation">
<!--- show order details in page yes/no --->
<cfparam name="request.cwpage.displayOrderDetails" default="true">
<!--- url vars --->
<cfparam name="url.orderid" default="0">
<!--- mode (confirm:default/gateway|return:returning/processor|cancel:order cancelled) --->
<cfparam name="url.mode" default="confirm">
<!--- clean up form and url variables --->
<cfinclude template="cwapp/inc/cw-inc-sanitize.cfm">
<!--- CARTWEAVER REQUIRED FUNCTIONS --->
<cfinclude template="cwapp/inc/cw-inc-functions.cfm">
<!--- API CALLBACKS --->
<!--- HANDLE GATEWAY API RESPONSES (e.g. PayPal IPN) by key field:
loop available payment methods, check for key field present --->
<!--- do not process on 'return' mode from paypal, other processors --->
<cfif not url.mode is 'return'>
	<cfloop list="#application.cw.authMethods#" index="i">
		<cfparam name="application.cw.authMethodData[i].methodID" default="">
		<cfparam name="application.cw.authMethodData[i].methodName" default="">
		<cfparam name="application.cw.authMethodData[i].methodFileName" default="">
		<cfparam name="application.cw.authMethodData[i].methodType" default="">
		<cfparam name="application.cw.authMethodData[i].methodConfirmMessage" default="">
		<cfparam name="application.cw.authMethodData[i].methodTransKeyField" default="">
		<cfset CWauth.methodID = application.cw.authMethodData[i].methodID>
		<cfset CWauth.methodName = application.cw.authMethodData[i].methodName>
		<cfset CWauth.methodFileName = application.cw.authMethodData[i].methodFileName>
		<cfset CWauth.methodType = application.cw.authMethodData[i].methodType>
		<cfset CWauth.methodConfirmMessage = application.cw.authMethodData[i].methodConfirmMessage>
		<cfset CWauth.methodTransKeyField = application.cw.authMethodData[i].methodTransKeyField>
		<!--- Check for Key Field: if a variable matching the 'transkeyfield' exists, and has a value --->
		<cfif isDefined('#CWauth.methodTransKeyField#') and len(trim(evaluate(CWauth.methodTransKeyField)))>
		<cfset authDirectory = application.cw.siteRootPath & cwLeadingChar(cwTrailingChar(application.cw.appCwContentDir),'remove') & 'cwapp/auth'>
			<!--- invoke file as cfmodule in 'process' mode, process payment --->
			<cfmodule template="cwapp/auth/#CWauth.methodFileName#"
			auth_mode="process">
		</cfif>
		<!--- /end key field match / auth processing --->
	</cfloop>
	<!--- output email to developer in test mode --->
	<cftry>
		<cfif isDefined(application.cw.developerEmail) and isValid('email',application.cw.developerEmail)
		 and isDefined(application.cw.appTestModeEnabled) and application.cw.appTestModeEnabled is true>
		<cfsavecontent variable="mailcontent">
			<cfdump var="#form#" label="form">
			<cfdump var="#cgi#" label="cgi">
			<cfdump var="#application.cw.authMethodData#">
			<cfdump var="#request.trans#" label="request.trans - transaction details">
		</cfsavecontent>
		<cfset temp = CWsendMail(mailContent, 'running process',application.cw.developerEmail)>
		</cfif>
		<!--- additional debugging can be executed here, if there's any error with the email sending above --->
		<cfcatch></cfcatch>
	</cftry>
	<!--- /end test mode developer email --->
</cfif>
<!--- /end if not url.return --->
<!--- /END API CALLBACKS --->
<!--- CONFIRMATION --->
<!--- QUERY: get order details --->
<cfset orderQuery = CWquerySelectOrderDetails(order_id=session.cwclient.cwCompleteOrderID)>
<!--- IF ORDER IS VALID --->
<cfif orderQuery.recordCount gt 0 and orderQuery.order_id eq session.cwclient.cwCompleteOrderID>
	<!--- VERIFY ORDER STATUS --->
	<!--- CANCELLING ORDER: check for order cancelled via url (url must be in ID and client memory) --->
	<cfif trim(url.mode) eq 'cancel' and trim(url.orderid) eq session.cwclient.cwCompleteOrderID>
		<!--- prevent misuse of cancel via url: only cancel if order status allows (partial / pending only) --->
		<cfif orderQuery.order_status lt 3>
			<!--- QUERY: mark order status to cancelled --->
			<cfset updateOrder = CWqueryUpdateOrder(order_id=orderQuery.order_id,order_status=5)>
			<!--- refresh page to clear message and apply cancelled status --->
			<cflocation url="#request.cw.thisPage#?orderid=#url.orderid#" addtoken="no">
			<!--- if order was previously completed --->
		<cfelseif orderquery.order_status gte 3>
			<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'This order is being processed and cannot be cancelled.')>
			<cfset request.cwpage.displayOrderDetails = false>
		</cfif>
	<!--- CANCELLED PREVIOUSLY: check for cancelled status in db --->
	<cfelseif orderQuery.order_status is 5>
		<!--- add error message for user --->
		<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Payment Cancelled. Order will not be processed.')>
		<cfset request.cwpage.displayOrderDetails = false>
		<!--- require reconfirmation of order --->
		<cfset session.cw.confirmOrder = false>
		<cfset session.cw.confirmAuthPref = false>
		<cfset session.cw.confirmCart = false>
	<!--- PARTIAL PAYMENT: check for balance due / partial payment status --->
	<cfelseif orderQuery.order_status is 2>
		<!--- get transactions related to this order (including the one just inserted) --->
		<cfset orderPaymentTotal = CWorderPaymentTotal(orderQuery.order_id)>
		<!--- set balance due --->
		<cfset request.trans.orderBalance =  orderQuery.order_total - orderPaymentTotal>
		<cfset session.cw.paymentAlert = "Insufficient funds available - balance of #lsCurrencyFormat(request.trans.orderBalance,'local')# due. <br>Please use another payment method to complete your order.">
		<!--- redirect to payment page showing balance due --->
		<cflocation url="#request.cwpage.urlCheckout#" addtoken="no">
	<!--- PENDING: check for pending status (no payments applied) --->
	<cfelseif orderQuery.order_status is 1>
		<!--- add error message for user --->
		<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Order will be processed pending payment confirmation.')>
	<!--- ALL GOOD: CONFIRM ORDER (status ok, balance ok, not cancelling) --->
	<cfelse>
		<!--- check for payment preference in client memory --->
		<cfif isDefined('session.cwclient.cwCustomerAuthPref') and isNumeric(session.cwclient.cwCustomerAuthPref) and session.cwclient.cwCustomerAuthPref gt 0>
			<!--- get confirmation message for active payment method, add to customer confirmation --->
			<cfparam name="application.cw.authMethodData[session.cwclient.cwCustomerAuthPref].methodConfirmMessage" default="">
			<cfset request.trans.confirmMessage = listAppend(request.trans.confirmMessage,application.cw.authMethodData[session.cwclient.cwCustomerAuthPref].methodConfirmMessage)>
			<!--- if client auth pref is 0, but we got this far, no payments are required in the store - show generic message --->
		<cfelseif session.cwclient.cwCustomerAuthPref is 0>
			<cfset request.trans.confirmMessage = listAppend(request.trans.confirmMessage,'Thank you.')>
		</cfif>
	</cfif>
	<!--- /end status / cancel / balance due check --->
	<!--- /END VERIFY STATUS --->
<!--- IF ORDER IS NOT VALID --->
<!--- if client order id is invalid or does not exist, check for order id in URL
(refreshing or revisiting confirmation page after initial submission will trigger this) --->
<cfelse>
	<!--- QUERY: get order details --->
	<cfset orderQuery = CWquerySelectOrderDetails(order_id=url.orderid)>
	<!--- if an order is found --->
	<cfif orderQuery.recordCount gt 0>
		<!--- if order is completed, show custom message --->
		<cfif orderQuery.order_status gt 2>
			<cfset request.cwpage.confirmHeading = "Order Complete" >
			<cfset request.trans.confirmMessage = listAppend(request.trans.confirmMessage,"This transaction has been completed.")>
			<!--- hide order details --->
			<cfset request.cwpage.displayOrderDetails = false>
			<!--- if order is partial or pending, show generic 'processing' message --->
		<cfelse>
			<cfset request.cwpage.confirmHeading = "Order Processing" >
			<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'This order is being processed.')>
			<cfset request.cwpage.displayOrderDetails = false>
		</cfif>
	</cfif>
</cfif>
<!--- /END IF ORDER VALID --->
<!--- IF NO ORDER FOUND in url or client match --->
<cfif orderQuery.recordCount eq 0>
	<!--- set page heading --->
	<cfset request.cwpage.confirmHeading = "Invalid Order ID">
	<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Order Details Unavailable')>
	<!--- hide order details --->
	<cfset request.cwpage.displayOrderDetails = false>
</cfif>
<!--- / END IF NO ORDER FOUND --->
</cfsilent>
<!--- /////// START OUTPUT /////// --->
<!--- breadcrumb navigation --->
<cfmodule template="cwapp/mod/cw-mod-searchnav.cfm"
search_type="breadcrumb"
separator=" &raquo; "
end_label="Check Out : <strong>Order Processing</strong>"
all_categories_label=""
all_secondaries_label=""
all_products_label=""
>
<!--- confirmation content --->
<div id="CWconfirm" class="CWcontent">
	<h1><cfoutput>#request.cwpage.confirmHeading#</cfoutput></h1>
	<!--- MESSAGE DISPLAY: show error / confirmation messages here --->
	<cfif len(trim(request.trans.errorMessage)) OR len(trim(request.trans.confirmMessage))>
		<div class="CWconfirmBox">
			<!--- error messages --->
			<cfif len(trim(request.trans.errorMessage))>
				<cfloop list="#request.trans.errorMessage#" index="ee">
					<div class="alertText"><cfoutput>#ee#</cfoutput></div>
				</cfloop>
				<!--- show general message to accompany any errors --->
				<div class="confirmText">Contact us for assistance&nbsp;&nbsp;&bull;&nbsp;&nbsp;<a href="<cfoutput>#request.cwpage.urlResults#</cfoutput>">Return to store</a></div>
			</cfif>
			<!--- confirmation messages --->
			<cfif len(trim(request.trans.confirmMessage))>
				<cfloop list="#request.trans.confirmMessage#" index="ee">
					<div class="confirmText"><cfoutput>#ee#</cfoutput></div>
				</cfloop>
				<!--- if no errors (and order is paid in full) show general message --->
				<cfif not len(trim(request.trans.errorMessage))>
					<div class="confirmText">
						Your order will be processed shortly.
						<cfif application.cw.customerAccountEnabled
							and not (isdefined('session.cwclient.cwCustomerCheckout') and session.cwclient.cwCustomerCheckout is 'guest')>
							<br>
							<!--- link to log in / my account --->
							<cfset loginLinkText = 'Log in to your account'>
							<cfoutput><a href="#request.cwpage.urlAccount#">#trim(loginLinkText)#</a> to see order details.</cfoutput>
						</cfif>
					</div>
				</cfif>
			</cfif>
		</div>
	</cfif>
	<!--- /end message display --->
	<!--- SHOW ORDER CONTENTS--->
	<cfif request.cwpage.displayOrderDetails>
		<p><a href="javascript:window.print()">&raquo;&nbsp;Print This Page</a></p>
		<!--- display order contents, passing in order query from above --->
		<cfmodule template="cwapp/mod/cw-mod-orderdisplay.cfm"
		order_query="#orderQuery#"
		display_mode="summary"
		show_images="#application.cw.appDisplayCartImage#"
		show_sku="#application.cw.appDisplayCartSku#"
		show_options="true"
		>
	</cfif>
	<!--- ORDER PROCESS IS COMPLETE: CLEAR CART / ORDER CONTENTS --->
	<!--- delete all stored cart values (DISABLED IN TEST MODE) --->
	<cfif application.cw.appTestModeEnabled neq 'true'>
		<cfif isDefined('session.cwclient.cwCustomerID') and session.cwclient.cwCustomerID neq '0'>
			<cfset clearingID = true>
		<cfelse>
			<cfset clearingID = false>
		</cfif>
		<!--- show log out message if client was logged in --->
		<cfif clearingID eq true and application.cw.customerAccountEnabled eq true
			and not (isdefined('session.cwclient.cwCustomerCheckout')
			and session.cwclient.cwCustomerCheckout is 'guest')>
			<p>For added security, you have been logged out.</p>
		</cfif>
		<!--- if a cart id is in the session, clear out the cart --->
		<cfif isDefined('session.cwclient.cwCartID')>
			<cfset clearCart = CWclearCart(session.cwclient.cwCartID)>
		</cfif>
		<!--- clear CW session values --->
		<cfset structDelete(session,'cw')>
		<cfset structDelete(session,'cwclient')>
		<!--- clear cart-related cookie vars (set to null/expired) --->
		<cfif application.cw.appCookieTerm neq 0>
			<cfloop list="CWcartID,CWcustomerID,CWcompleteOrderID,CWorderTotal,CWtaxTotal,CWshipTotal,CWshipTaxTotal,discountPromoCode,discountApplied" index="cc">
				<cfcookie name="#trim(cc)#" value="" expires="NOW">
			</cfloop>
		</cfif>
	<!--- in test mode this data is not cleared, refresh confirmation page allowed --->
	<cfelse>
		<p><strong>TEST MODE ENABLED: STORED VALUES NOT CLEARED FROM SESSION / CLIENT</strong></p>
	</cfif>
	<!-- clear floated content -->
	<div class="CWclear"></div>
</div>
<!-- /end CWconfirm -->
<!--- page end / debug --->
<cfinclude template="cwapp/inc/cw-inc-pageend.cfm">