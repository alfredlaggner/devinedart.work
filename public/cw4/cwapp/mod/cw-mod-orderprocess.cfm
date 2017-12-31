<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-mod-orderprocess.cfm
File Date: 2012-11-17
Description: processes order and manages interaction with various payment methods
==========================================================
--->

<!--- customer cart --->
<cfparam name="attributes.cart" default="">
<cfparam name="attributes.cart.carttotals.total" default="0">
<cfparam name="attributes.cart.carttotals.shipping" default="0">
<cfparam name="attributes.cart.carttotals.shippingtax" default="0">
<cfparam name="attributes.cart.carttotals.discountids" default="0">
<cfparam name="attributes.cart.carttotals.cartdiscounts" default="0">
<cfparam name="attributes.cart.carttotals.shipdiscounts" default="0">
<!--- submission data from form --->
<cfparam name="attributes.form_data" default="">
<!--- defaults for form values --->
<cfparam name="attributes.form_data.order_message" default="">
<cfparam name="attributes.form_data.customer_submit_conf" default="0">
<cfparam name="attributes.form_data.customer_cardname" default="">
<cfparam name="attributes.form_data.customer_cardnumber" default="">
<cfparam name="attributes.form_data.customer_cardtype" default="">
<cfparam name="attributes.form_data.customer_cardexpm" default="">
<cfparam name="attributes.form_data.customer_cardexpy" default="">
<cfparam name="attributes.form_data.customer_cardccv" default="">
<cfparam name="attributes.form_data.fieldnames" default="">
<!--- defaults for session values --->
<cfparam name="session.cw.authpref" default="">
<cfparam name="session.cw.authprefname" default="">
<cfparam name="session.cw.authType" default="none">
<cfparam name="session.cw.confirmShipID" default="0">
<!--- defaults for client scope values --->
<cfparam name="session.cwclient.cwCustomerID" default="0">
<cfparam name="session.cwclient.cwCustomerCheckout" default="account">
<!--- default list of error fields --->
<cfset request.trans.formErrors = ''>
<!--- default confirmation message --->
<cfset request.trans.confirmMessage = ''>
<!--- default error message --->
<cfset request.trans.errorMessage = ''>
<!--- global functions --->
<cfinclude template="../inc/cw-inc-functions.cfm">
<!--- clean up form and url variables --->
<cfinclude template="../inc/cw-inc-sanitize.cfm">
<!--- VALIDATE DATA PASSED IN --->
<!--- VERIFY CUSTOMER ID IS VALUD, AND CUSTOMER EXISTS --->
<cfif len(trim(session.cwclient.cwCustomerID)) is 0 OR trim(session.cwclient.cwCustomerID) is 0>
	<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Invalid Customer ID - Please Log In to continue')>
<!--- VERIFY CUSTOMER ID IS SAME AS PASSED VIA CART TRANSACTION --->
<cfelseif attributes.form_data.customer_submit_conf neq session.cwclient.cwCustomerID>
	<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Invalid Customer ID - Please verify account details')>
<!--- VERIFY TRANSACTION ELEMENTS - cart, customer, order total --->
<cfelse>
	<!--- QUERY: get customer details--->
	<cfset CWcustomer = CWgetCustomer(session.cwclient.cwCustomerID)>
	<!--- verify customer ID available in database --->
	<cfif not (isStruct(CWcustomer) AND len(trim(CWcustomer.customerID)))>
		<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Invalid Customer ID - Please Log In to continue')>
	</cfif>
	<!--- verify cart is a valid structure, with products --->
	<cfif not isStruct(attributes.cart)>
		<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Invalid Cart')>
	<cfelseif not arrayLen(attributes.cart.cartitems) gt 0>
		<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Cart is Empty')>
	</cfif>
	<!--- verify order total is available, and numeric (0 is allowed) --->
	<cfif not (isDefined('attributes.cart.carttotals.total') AND isNumeric(attributes.cart.carttotals.total))>
		<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Invalid Order Total')>
	</cfif>
	<!--- verify data (form values collection) is a valid structure --->
	<cfif not (isStruct(attributes.form_data) and len(trim(attributes.form_data.fieldnames)))>
		<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Invalid Form Submission')>
	</cfif>
</cfif>
<!--- TRANSACTION VARIABLE DEFAULTS --->
<!--- order id: actual id generated at insert to db --->
<cfparam name="request.trans.orderID" default="0">
<!--- payment id: database id of payment transaction, generated on success --->
<cfparam name="request.trans.paymentTransID" default="0">
<!--- payment method, captured from session scope (set on payment method selection) --->
<cfparam name="request.trans.paymentMethod" default="#session.cw.authprefname#">
<!--- payment method id, captured from session --->
<cfparam name="request.trans.paymentAuthID" default="#session.cw.authpref#">
<!--- payment type, captured from session --->
<cfparam name="request.trans.paymentType" default="#session.cw.authType#">
<!--- payment amount (default is order total) --->
<cfparam name="request.trans.paymentAmount" default="#attributes.cart.carttotals.total#">
<!--- payment status (none|approved|denied) --->
<cfparam name="request.trans.paymentStatus" default="none">
<!--- transaction id, returned from processor --->
<cfparam name="request.trans.paymentTransID" default="">
<!--- transaction response message or code (if applicable) from processor --->
<cfparam name="request.trans.paymentTransResponse" default="">
<!--- order approved for insertion (set to true on validation)  --->
<cfparam name="request.trans.orderapproved" default="false">
<!--- order inserted to database (set to true on insert)  --->
<cfparam name="request.trans.orderinserted" default="false">
<!--- order total --->
<cfparam name="request.trans.ordertotal" default="#attributes.cart.carttotals.total#">
<!--- order balance due --->
<cfparam name="request.trans.orderbalance" default="#attributes.cart.carttotals.total#">
<!--- data passed to payment include --->
<cfset request.trans.data = structNew()>
<!--- defaults for payment file info --->
<cfif request.trans.paymentauthID gt 0>
	<cfparam name="application.cw.authMethodData[request.trans.paymentauthID].methodfilename" default="">
	<cfparam name="application.cw.authMethodData[request.trans.paymentauthID].methodname" default="">
	<cfparam name="application.cw.authMethodData[request.trans.paymentauthID].methodconfirmmessage" default="">
</cfif>
<!--- IF ATTRIBUTES ARE VALID --->
<!--- if no error has been generated so far, run processing --->
<cfif not len(trim(request.trans.errorMessage))>
	<!--- set form data into request variable --->
	<cfset request.data = attributes.form_data>
	<!--- GATEWAY VALIDATION --->
	<!--- if using 'gateway', validate all required form fields --->
	<cfif session.cw.authType is 'gateway'>
		<!--- delete form data scope --->
		<cfset attributes.form_data = ''>
		<!--- CARD HOLDER NAME : required --->
		<cfif not len(trim(request.data.customer_cardname))>
			<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Card Holder Name must be provided')>
			<cfset request.trans.formerrors = listAppend(request.trans.formerrors, 'customer_cardname')>
		</cfif>
		<!--- CARD TYPE : required, must be valid card type --->
		<!--- QUERY: match submitted value against active card types --->
		<cfset creditCardsQuery = CWquerySelectCreditCards(request.data.customer_cardtype)>
		<cfif not (len(trim(request.data.customer_cardtype)) and creditCardsQuery.recordCount eq 1)>
			<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Card Type must be selected')>
			<cfset request.trans.formerrors = listAppend(request.trans.formerrors, 'customer_cardtype')>
		</cfif>
		<!--- CARD NUMBER : required, numeric only, varying lengths --->
		<cfif NOT (len(trim(request.data.customer_cardNumber)) and isNumeric(trim(request.data.customer_cardNumber)))>
			<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Credit Card Number invalid or missing')>
			<cfset request.trans.formerrors = listAppend(request.trans.formerrors, 'customer_cardnumber')>
			<!--- valid amex length --->
		<cfelseif request.data.customer_cardtype is 'amex' and len(trim(request.data.customer_cardNumber)) neq 15>
			<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Invalid Amex Number')>
			<cfset request.trans.formerrors = listAppend(request.trans.formerrors, 'customer_cardnumber')>
			<!--- valid visa, other length --->
		<cfelseif request.data.customer_cardtype is 'visa' and NOT
			(len(trim(request.data.customer_cardNumber)) eq 13 OR len(trim(request.data.customer_cardNumber)) eq 16)>
			<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Invalid Visa Number')>
			<cfset request.trans.formerrors = listAppend(request.trans.formerrors, 'customer_cardnumber')>
			<!--- all others --->
		<cfelseif request.data.customer_cardtype neq 'visa' AND request.data.customer_cardtype neq 'amex'
			AND len(trim(request.data.customer_cardNumber)) neq 16>
			<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Invalid Card Number')>
			<cfset request.trans.formerrors = listAppend(request.trans.formerrors, 'customer_cardnumber')>
		</cfif>
		<!--- EXPIRATION DATE --->
		<cfif NOT (len(trim(request.data.customer_cardExpm)) eq 2 and isNumeric(trim(request.data.customer_cardExpm))
			AND request.data.customer_cardExpM gt 0 AND request.data.customer_cardExpM lt 13)>
			<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Invalid Expiration Date (month)')>
			<cfset request.trans.formerrors = listAppend(request.trans.formerrors, 'customer_cardexpm')>
		</cfif>
		<cfif NOT (len(trim(request.data.customer_cardExpy)) eq 4 and isNumeric(trim(request.data.customer_cardExpy)))>
			<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Invalid Expiration Date (year)')>
			<cfset request.trans.formerrors = listAppend(request.trans.formerrors, 'customer_cardexpm')>
		</cfif>
		<!--- compare expiration date to current month/year --->
		<cfif isNumeric(request.data.customer_cardExpy) and isNumeric(request.data.customer_cardExpm)>
			<cfset cardMY = dateFormat(trim(request.data.customer_cardexpy) & '-' & trim(request.data.customer_cardexpm) & '-' & '01','yyyy-mm-dd')>
		<cfelse>
			<cfset cardMY = 00>
		</cfif>
		<cfset minMY = dateFormat(dateAdd('m',-1,CWtime()),'yyyy-mm-dd')>
		<cfif not cardMY gt minMY>
			<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Card Expiration Date has passed')>
			<cfset request.trans.formerrors = listAppend(request.trans.formerrors, 'customer_cardexpm,customer_cardexpy')>
		</cfif>
		<!--- CCV --->
		<cfif NOT (len(trim(request.data.customer_cardccv)) and isNumeric(trim(request.data.customer_cardccv)))>
			<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Credit Card CCV code invalid or missing')>
			<cfset request.trans.formerrors = listAppend(request.trans.formerrors, 'customer_cardccv')>
		<!--- valid amex length --->
		<cfelseif request.data.customer_cardtype is 'amex' and len(trim(request.data.customer_cardccv)) neq 4>
			<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Invalid Amex CCV')>
			<cfset request.trans.formerrors = listAppend(request.trans.formerrors, 'customer_cardccv')>
		<!--- valid visa, other length --->
		<cfelseif request.data.customer_cardtype is not 'amex' and len(trim(request.data.customer_cardccv)) neq 3>
			<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Invalid CCV code')>
			<cfset request.trans.formerrors = listAppend(request.trans.formerrors, 'customer_cardccv')>
		</cfif>
	</cfif>
	<!--- /END GATEWAY VALIDATION --->
	<!--- handle customer comments --->
	<cftry>
	<cfif isDefined('request.data.order_message')>
		<!--- if customer comments have changed --->
		<cfif isDefined('session.cw.order_message') and trim(request.data.order_message) neq trim(session.cw.order_message)>
			<!--- QUERY: update order with new comments --->
			<cfset updateOrder = CWqueryUpdateOrder(order_id=session.cwclient.cwCompleteOrderID,order_message=request.data.order_message)>
		</cfif>
		<!--- set message into session scope --->
		<cfset session.cw.order_message = trim(request.data.order_message)>
	</cfif>
	<cfcatch>
		<cfset session.cw.order_message = ''>
	</cfcatch>
	</cftry>
	<!--- IF NO ERRORS FROM VALIDATION --->
	<!--- if no validation error and no form errors --->
	<cfif not len(trim(request.trans.errorMessage)) AND not len(trim(request.trans.formerrors))>
		<!--- MARK THE ORDER AS APPROVED --->
		<!--- status 1: order placed, no payment --->
		<cfset request.trans.orderStatus = 1>
		<!--- result: used for in-page procesing:
		value 'approved' allows order to be saved below --->
		<cfset request.trans.orderapproved = true>
		<!--- CHECK FOR DUPLICATE SUBMISSION --->
		<!--- if a submitted order id is not in the user's session (avoid duplicates on retry of payment, or partial payment) --->
		<cfif not (isDefined('session.cwclient.cwCompleteOrderID') AND CWorderStatus(session.cwclient.cwCompleteOrderID) gt 0)>
			<!--- create new order ID --->
			<cfset request.trans.orderID = dateFormat(cwtime(),'yymmdd') & timeFormat(cwtime(),'HHMM') & '-' & left(replace(session.cwclient.cwCustomerID,'-','','all'),4)>
			<!--- SAVE ORDER --->
			<cfif request.trans.orderapproved>
				<!--- QUERY: INSERT ORDER to database, returns order id if successful
				(attributes: order ID, order status code, transaction ID, cart structure,
				customer data structure, shipping method id, order comments)
				--->
				<cftry>
					<cfset insertedOrder = CWsaveOrder(
					order_id = request.trans.orderID,
					order_status = request.trans.orderStatus,
					cart = attributes.cart,
					customer = CWcustomer,
					ship_method = session.cw.confirmShipID,
					message = request.data.order_message,
					checkout_type = session.cwclient.cwCustomerCheckout
					)>
				<!--- if no errors from order insertion --->
				<cfif left(insertedOrder,2) neq '0-'>
					<!--- SEND EMAIL TO CUSTOMER --->
					<!--- build the order details content --->
					<cfset mailBody = CWtextOrderDetails(request.trans.orderID)>
					<cfif not (isDefined('application.cw.mailSendOrderCustomer') and application.cw.mailSendOrderCustomer is false)>
						<cfsavecontent variable="mailContent">
						<cfoutput>#application.cw.mailDefaultOrderReceivedIntro#
						#chr(10)##chr(13)#
						#mailBody#
						#chr(10)##chr(13)#
						#application.cw.mailDefaultOrderReceivedEnd#
						</cfoutput>
						</cfsavecontent>
						<!--- send the content to the customer --->
						<cfset confirmationResponse = CWsendMail(mailContent, 'Order Confirmation',CWcustomer.email)>
					</cfif>
					<!--- SEND EMAIL TO MERCHANT --->
					<cfif not (isDefined('application.cw.mailSendOrderMerchant') and application.cw.mailSendOrderMerchant is false)>
						<cfsavecontent variable="merchantMailContent">
						<cfoutput>
						An order has been placed at #application.cw.companyName#:
						#chr(10)##chr(13)#
						#mailBody#
						#chr(10)##chr(13)#
						Log in to manage this order: #cwTrailingChar(application.cw.appSiteUrlHttp)##cwLeadingChar(application.cw.appCwAdminDir,'remove')#
						</cfoutput>
						</cfsavecontent>
						<!--- send to merchant --->
						<cfset confirmationResponse = CWsendMail(merchantMailContent, 'Order Notification: #request.trans.orderID#',application.cw.companyEmail)>
					</cfif>
					<!--- /end send email --->
				<!--- if insertion returns an error --->
				<cfelse>
					<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Unable to process order')>
				</cfif>
					<cfcatch>
						<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Unable to process order: #cfcatch.detail#')>
					</cfcatch>
				</cftry>
				<!--- if returned string matches order ID, insertion was successful --->
				<cfif insertedOrder eq request.trans.orderID>
					<cfset request.trans.orderInserted = true>
					<!--- store order id in session --->
					<cfset session.cwclient.cwCompleteOrderID = request.trans.orderID>
					<!--- message set for user --->
					<cfset request.trans.confirmMessage = listAppend(request.trans.confirmMessage,'Order Approved')>
					<!--- if an error is returned by order insertion --->
				<cfelseif insertedOrder contains '0-'>
					<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, listRest(insertedOrder,'-'))>
					<!--- if any other error occurs --->
				<cfelse>
					<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Unable to process order')>
				</cfif>
				<!--- /end if returned string ok --->
			</cfif>
			<!--- /end if order approved --->
		<!--- if order already exists in session --->
		<cfelse>
			<!--- pass order id values through to request scope --->
			<cfset request.trans.orderID = session.cwclient.cwCompleteOrderID>
			<cfset request.trans.orderInserted = true>
		</cfif>
		<!--- /end if order already exists --->
		<!--- verify payment: get transactions related to this order --->
		<cfset orderPayments = round(CWorderPaymentTotal(request.trans.orderID)*100)/100>

		<!--- set balance due --->
		<cfset request.trans.orderBalance =  request.trans.ordertotal - orderPayments>
		<!--- if balance due is 0, skip payment --->
		<cfif request.trans.orderbalance eq 0>
			<cfset session.cw.authType eq 'none'>
		</cfif>
	</cfif>
	<!--- /end if no validation or form errors --->
</cfif>
<!--- /end if no data error --->
<!--- PROCESS PAYMENT --->
<!--- PROCESS PAYMENT --->
<!--- PROCESS PAYMENT --->
<!--- if order was inserted, and we still have no errors (and payment method exists) --->
<cfif request.trans.orderinserted and not len(trim(request.trans.errorMessage))
		and request.trans.paymentauthID gt 0>
	<!--- verify amount due: get transactions related to this order --->
	<cfset orderPayments = CWorderPaymentTotal(request.trans.orderID)>
	<!--- if some payments have been made --->
	<cfif orderPayments gt 0>
		<!--- set balance due --->
		<cfset request.trans.orderBalance =  request.trans.ordertotal - orderPayments>
		<!--- if balance due is less than submitted amount, pay lower amount --->
		<cfif request.trans.orderBalance lt request.trans.paymentAmount and request.trans.orderBalance gt 0>
			<cfset request.trans.paymentAmount = request.trans.orderBalance>
		</cfif>
	</cfif>
	<!--- COLLECT FORM DATA INTO STRUCT --->
	<!--- order values --->
	<cfset request.trans.data.orderID = request.trans.orderID>
	<cfset request.trans.data.paymentAmount = numberFormat(request.trans.paymentAmount,'__.__')>
	<!--- customer values --->
	<cfset request.trans.data.customerID = session.cwclient.cwCustomerID>
	<cfset request.trans.data.customerNameFirst = CWcustomer.firstname>
	<cfset request.trans.data.customerNameLast = CWcustomer.lastname>
	<cfset request.trans.data.customerCompany = CWcustomer.company>
	<cfset request.trans.data.customerPhone = CWcustomer.phone>
	<cfset request.trans.data.customerEmail = CWcustomer.email>
	<cfset request.trans.data.customerAddress1 = CWcustomer.address1>
	<cfset request.trans.data.customerAddress2 = CWcustomer.address2>
	<cfset request.trans.data.customerCity = CWcustomer.city>
	<cfset request.trans.data.customerState = CWcustomer.stateprovcode>
	<cfset request.trans.data.customerZip = CWcustomer.zip>
	<cfset request.trans.data.customerCountry = CWcustomer.countrycode>
	<!--- shipping values --->
	<cfset request.trans.data.customerShipName = CWcustomer.shipname>
	<cfset request.trans.data.customerShipCompany = CWcustomer.shipcompany>
	<cfset request.trans.data.customerShipPhone = CWcustomer.phone>
	<cfset request.trans.data.customerShipEmail = CWcustomer.email>
	<cfset request.trans.data.customerShipAddress1 = CWcustomer.shipaddress1>
	<cfset request.trans.data.customerShipAddress2 = CWcustomer.shipaddress2>
	<cfset request.trans.data.customerShipCity = CWcustomer.shipcity>
	<cfset request.trans.data.customerShipState = CWcustomer.shipstateprovcode>
	<cfset request.trans.data.customerShipCountry = CWcustomer.shipcountrycode>
	<cfset request.trans.data.customerShipZip = CWcustomer.shipzip>
	<!--- payment method - get info from stored application structure --->
	<cfset request.trans.authfilename = application.cw.authMethodData[request.trans.paymentauthID].methodfilename>
	<!--- verify auth file exists, and is same as expected in user's session --->
	<cfset authDirectory = application.cw.siteRootPath & cwLeadingChar(cwTrailingChar(application.cw.appCwContentDir),'remove') & 'cwapp/auth/'>
	<cfset authFilePath = authDirectory & request.trans.authfilename>
	<cfif not (fileExists(authFilePath) AND application.cw.authMethodData[request.trans.paymentauthID].methodName eq request.trans.paymentmethod)>
		<cfset session.cw.authType eq 'none'>
		<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Payment Connection Unavailable')>
	</cfif>
	<!--- credit card values --->
	<cfif session.cw.authType is 'gateway'>
		<cfset request.trans.data.cardname = request.data.customer_cardname>
		<cfset request.trans.data.cardnumber = request.data.customer_cardnumber>
		<cfset request.trans.data.cardtype = request.data.customer_cardtype>
		<cfset request.trans.data.cardexpm = request.data.customer_cardexpm>
		<cfset request.trans.data.cardexpy = request.data.customer_cardexpy>
		<cfset request.trans.data.cardccv = request.data.customer_cardccv>
	</cfif>
		<!--- IF NO ERRORS to this point, run processing --->
	<cfif not len(trim(request.trans.errorMessage))>
		<!--- PROCESSOR  (e.g. PayPal - offsite transactions) --->
		<cfif session.cw.authType is 'processor'>
			<!--- set variable used on containing page (checkout final step) --->
			<cfset request.cwpage.postToProcessor = true>
			<!--- GATEWAY (e.g. Authorize.net - in-page credit card transactions) --->
			<!--- ACCOUNT (also handle in-store account options this way) --->
		<cfelseif session.cw.authType is 'gateway' or session.cw.authType is 'account'>
			<!--- invoke payment file as cfmodule, passing in payment info structure --->
			<cfmodule template="../auth/#request.trans.authfilename#"
			auth_mode="process"
			trans_data="#request.trans.data#"
			>
			<!--- IF GATEWAY TRANSACTION IS OK --->
			<!--- if transaction ID exists, and payment was successful, redirect to confirmation page (if not already redirected by payment file) --->
			<cfif request.trans.paymentStatus is 'approved' AND len(trim(request.trans.paymentTransID))>
				<!--- capture any errors related to insertion --->
				<cftry>
					<!--- QUERY: insert payment to database,
					returns payment id if successful, or 0-based message if not
					--->
					<cfset insertedPayment = CWsavePayment(
					order_id = request.trans.orderID,
					payment_method = request.trans.paymentMethod,
					payment_type = request.trans.paymentType,
					payment_amount = request.trans.paymentAmount,
					payment_status = request.trans.paymentStatus,
					payment_trans_id = request.trans.paymentTransID,
					payment_trans_response = request.trans.paymentTransResponse
					)>
					<!--- if an error is returned --->
					<cfif left(insertedPayment,2) eq '0-'>
						<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Payment Insertion Error: #replace(insertedPayment,'0-','')#')>
						<!--- if no error --->
					<cfelse>
						<!--- get transactions related to this order (including the one just inserted) --->
						<cfset orderPaymentTotal = round(CWorderPaymentTotal(request.trans.orderID)*100)/100>
						<!--- set balance due --->
						<cfset request.trans.orderBalance =  request.trans.ordertotal - orderPaymentTotal>
						<!--- if order is paid in full (less than 1 cent) --->
						<cfif request.trans.orderBalance lt 0.01>
							<!--- QUERY: update order status to paid in full (3) --->
							<cfset updateOrderStatus = CWqueryUpdateOrder(order_id=request.trans.orderID,order_status=3)>
							<!--- if using avatax, post order xml to confirm payment --->
							<cfif application.cw.taxCalctype is 'avatax' and request.trans.ordertotal gt 0
								and isDefined('CWcustomer.stateprovnexus') and CWcustomer.stateprovnexus is 1>
								<cfset request.trans.orderXmlData = CWpostAvalaraTax(request.trans.orderID)>
							</cfif>
							<!--- build the order details content --->
							<cfset mailBody = CWtextOrderDetails(order_id=request.trans.orderID,show_payments=true)>
							<!--- SEND EMAIL TO CUSTOMER --->
							<cfif application.cw.mailSendPaymentCustomer>
								<cfsavecontent variable="mailContent">
								<cfoutput>#application.cw.mailDefaultOrderPaidIntro#
								#chr(13)##chr(13)#
								#mailBody#
								#chr(13)##chr(13)#
								#application.cw.mailDefaultOrderPaidEnd#
								</cfoutput>
								</cfsavecontent>
								<!--- send the content to the customer --->
								<cfset confirmationResponse = CWsendMail(mailContent, 'Payment Confirmation',CWcustomer.email)>
							</cfif>
							<!--- SEND EMAIL TO MERCHANT --->
							<cfif application.cw.mailSendPaymentMerchant>
								<cfsavecontent variable="merchantMailContent">
								<cfoutput>
								A payment has been processed at #application.cw.companyName#
								#chr(10)##chr(13)#
								#mailBody#
								#chr(10)##chr(13)#
								Log in to manage this order and view payment details: #cwTrailingChar(application.cw.appSiteUrlHttp)##cwLeadingChar(application.cw.appCwAdminDir,'remove')#</cfoutput>
								</cfsavecontent>
								<!--- send to merchant --->
								<cfset confirmationResponse = CWsendMail(merchantMailContent, 'Payment Notification: #request.trans.orderID#',application.cw.companyEmail)>
							</cfif>
							<!--- /end send email --->
							<!--- send user to confirmation page --->
							<cflocation url="#request.cwpage.urlConfirmOrder#?orderid=#request.trans.orderID#" addtoken="no">
							<!--- if a balance is still owed after a payment was made--->
						<cfelseif request.trans.orderBalance gt .009>
							<!--- QUERY: update order status to partial payment (2) --->
							<cfset updateOrderStatus = CWqueryUpdateOrder(order_id=request.trans.orderID,order_status=2)>
							<cfset balanceDueMessage = "Insufficient funds available - balance of #lsCurrencyFormat(request.trans.orderBalance,'local')# due. <br>Please use another payment method to complete your order.">
							<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, trim(balanceDueMessage))>
						</cfif>
						<!--- /end balance due check --->
					</cfif>
					<!--- /end insertion error check --->
					<cfcatch>
						<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Payment Insertion Error: Do Not Resubmit')>
					</cfcatch>
				</cftry>
				<!--- if transaction was denied --->
			<cfelseif request.trans.paymentStatus is 'denied'>
				<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Transaction Declined - No Payment Processed')>
				<!--- if transaction is skipped --->
			<cfelseif request.trans.paymentStatus is 'none'>
				<!--- if order balance is 0, redirect to confirmation --->
				<cfif request.trans.orderBalance eq 0>
					<!--- send user to confirmation page --->
					<cflocation url="#request.cwpage.urlConfirmOrder#" addtoken="no">
					<!--- if a balance is still owed --->
				<cfelse>
					<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Invalid Authentication - No Payment Processed')>
					<cfif len(trim(request.trans.paymentTransResponse))>
						<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, trim(request.trans.paymentTransResponse))>
					</cfif>
				</cfif>
			</cfif>
			<!--- WIPE DATA - clear transaction data from request scope --->
			<cfset clearData = structClear(request.trans.data)>
			<cfset clearData = structClear(request.data)>
			<!--- NO PAYMENT METHOD (or, no balance due) --->
		<cfelseif session.cw.authType is 'none'>
			<!--- since we have no errors here, if payment type is none, order is done --->
			<cflocation url="#request.cwpage.urlConfirmOrder#" addtoken="no">
		</cfif>
	</cfif>
	<!--- /END PROCESS PAYMENT --->
<!--- if no payment method exists (payments not required) --->
<cfelseif request.trans.paymentauthID eq 0>
	<!--- set status to 'paid in full' --->
	<cfset updateOrderStatus = CWqueryUpdateOrder(order_id=request.trans.orderID,order_status=3)>
	<cflocation url="#request.cwpage.urlConfirmOrder#?orderid=#request.trans.orderID#" addtoken="no">
</cfif>
<!--- /end if no error message - process payment --->
</cfsilent>