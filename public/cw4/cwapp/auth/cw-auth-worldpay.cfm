<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-auth-worldpay.cfm
File Date: 2012-07-09
Description: WorldPay payment processing

NOTE: Setting up accounts and integrating with third party processors is not
a supported feature of Cartweaver. For information and support concerning
payment processors contact the appropriate processor tech support web site or
personnel. Cartweaver includes this integration code as a courtesy with no
guarantee or warranty expressed or implied. Payment processors may make changes
to their protocols or practices that may affect the code provided here.
If so, updates and modifications are the sole responsibility of the user.

Additional WorldPay options:
(at the time of this revision, the WorldPay transaction variables are listed here)
http://www.worldpay.com/support/bg/index.php?page=development&sub=integration&subsub=requirements&c=UK
================================================================
RETURN VARIABLES: paymenttransid, paymenttransresponse, paymentstatus
Values: Transaction ID, Gateway Response Message, Payment Status (approved|denied|none(no response))
These are returned to the containing page or template
in the request.trans scope, e.g. 'request.trans.paymentTransID'
--->

<!--- /// CONFIGURATION / SETUP /// --->
<!--- CWauth Payment Configuration --->

<!--- USER SETTINGS  [ START ] ==================================================== --->
<!--- ============================================================================= --->
	<!--- WORLDPAY SETTINGS --->
		<!--- Enter WorldPay Install ID for this site --->
		<cfset settings.worldpayID = 'xxxxxxxxxxxx'>
		<!--- Enter Currency Code (USD, AUD, CAD, EUR, GBP, JPY... all ISO codes)--->
		<cfset settings.currencyCode = 'GBP'>
        <!--- NOTE: to suppress the display of currency drop down at WorldPay send hideCurrency = true --->
		<!--- WorldPay Test Status: set this to "100" to test, "0" to go live  --->
		<cfset settings.testmode = '100'>
		<!--- Order Description: sent to worldpay as transaction desc --->
		<cfset settings.orderDescription = 'Order Details'>
		<!--- URL to Post To --->
			<!--- LIVE ACCOUNTS URL (use for active transactions once worldpay is configured) --->
			<!---
			<cfset settings.authurl = 'https://select.worldpay.com/wcc/purchase'>
			 --->
			<!--- TESTING URL (use for testing transactions) --->
			<cfset settings.authurl = 'https://secure-test.wp3.rbsworldpay.com/wcc/purchase'>
	<!--- OPTIONAL PAYMENT METHOD VARIABLES --->
		<!--- method image: an optional logo url (relative or full url) associated with this payment option at checkout
			  e.g. /images/mylogo.jpg or https://www.example.com/images/mylogo.jpg
			  Note: be sure to use https prefix if linking to remote image  --->
		<cfset settings.methodImg = ''>
		<!--- shippay message: optional message shown to customer on shipping selection --->
		<cfset settings.methodSelectMessage = 'Pay securely using WorldPay'>
		<!--- submit message: optional message shown to customer on final order submission --->
		<cfset settings.methodSubmitMessage = 'Click Place Order to pay securely at WorldPay'>
		<!--- confirm message: optioal message shown to customer after order is approved --->
		<cfset settings.methodConfirmMessage = 'Thanks for using WorldPay for your transaction'>
	<!--- SUBMIT TEXT --->
		<!--- submit button value --->
		<cfset settings.submitText = '&raquo;&nbsp;Click to Pay with WorldPay'>
		<!--- processing/loading message --->
		<cfset settings.loadingText = 'Submitting to WorldPay...'>
<!--- ============================================================================ --->
<!--- USER SETTINGS [ END ] ====================================================== --->

<!--- METHOD SETTINGS : do not change --->
	<!--- method name: the user-friendly name shown for this payment option at checkout --->
	<cfset settings.methodName = 'WorldPay'>
	<!--- method type: processor (off-site processing), gateway (integrated credit card form) --->
	<cfset settings.methodType = 'processor'>
	<!--- key field: transaction variable specific to this payment method --->
	<cfset settings.methodTransKeyField = "form.transId">
	<!--- default processing values --->
	<cfparam name="form.fieldNames" default="">
	<!--- order functions --->
	<cfif not isDefined('variables.CWsaveOrder')>
		<cfinclude template="../func/cw-func-order.cfm">
	</cfif>
	<!--- mail functions --->
	<cfif not isDefined('variables.CWsendMail')>
		<cfinclude template="../func/cw-func-mail.cfm">
	</cfif>
	<!--- formatting functions --->
	<cfif not isDefined('variables.CWtime')>
		<cfinclude template="../func/cw-func-global.cfm">
	</cfif>
	<!--- clean up form and url variables --->
	<cfinclude template="../inc/cw-inc-sanitize.cfm">
	<!--- defaults for processing below --->
	<cfparam name="attributes.trans_data" default="">
	<cfparam name="attributes.auth_mode" default="">
	<cfparam name="request.trans.errorMessage" default="">
</cfsilent>
<!--- CONFIG MODE --->
<!--- CONFIG DATA : Auth_Mode "config" --->
<!--- CONFIG MODE --->
<!--- if called as a cfmodule in 'config mode', provide configuration data as 'CWauthMethod' struct --->
<cfif isDefined('attributes.auth_mode') and attributes.auth_mode is 'config'>
	<!--- clear scope from previous file operations (in case of multiple payment methods in use) --->
	<cfset caller.CWauthMethod = structNew()>
	<!--- these values get parsed into application.cw.authMethodData (add more here to have them available sitewide) --->
	<cfset caller.CWauthMethod.methodName = settings.methodName>
	<cfset caller.CWauthMethod.methodType = settings.methodType>
	<cfset caller.CWauthMethod.methodImg = settings.methodImg>
	<cfset caller.CWauthMethod.methodSelectMessage = settings.methodSelectMessage>
	<cfset caller.CWauthMethod.methodSubmitMessage = settings.methodSubmitMessage>
	<cfset caller.CWauthMethod.methodConfirmMessage = settings.methodConfirmMessage>
	<cfset caller.CWauthMethod.methodTransKeyField = settings.methodTransKeyField>
<!--- CAPTURE MODE --->
<!--- CAPTURE MODE : Auth_Mode "capture" : Form for submission to off-site processor --->
<!--- CAPTURE MODE --->
<!--- if called as cfmodule in 'process' mode, process order --->
<cfelseif isDefined('attributes.auth_mode') and attributes.auth_mode is 'capture'>
	<!--- verify transaction data is ok --->
	<cfif not isStruct(attributes.trans_data)>
		<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage,'Payment Data Incomplete')>
	<!--- if data is ok, run processing --->
	<cfelse>
		<!--- simplify to 'tdata' struct --->
		<cfset tdata = attributes.trans_data>
		<!--- defaults for transaction data --->
		<!--- customer --->
		<cfparam name="tdata.customerid" default="" type="string">
		<cfparam name="tdata.customercompany" default="" type="string">
		<cfparam name="tdata.customeremail" default="" type="string">
		<cfparam name="tdata.customerphone" default="" type="string">
		<cfparam name="tdata.customeraddress1" default="" type="string">
		<cfparam name="tdata.customeraddress2" default="" type="string">
		<cfparam name="tdata.customercity" default="" type="string">
		<cfparam name="tdata.customerstate" default="" type="string">
		<cfparam name="tdata.customerzip" default="" type="string">
		<cfparam name="tdata.customercountry" default="" type="string">
			<!--- country codes need a little handling (use GB instead of UK, and as a default) --->
			<cfif tdata.customerCountry is "UK">
				<cfset tdata.transactioncountry = "GB">
			<cfelseif tdata.customerCountry is "">
				<cfset tdata.transactioncountry = "GB">
			<cfelse>
				<cfset tdata.transactioncountry = tdata.customerCountry>
			</cfif>
		<!--- order/payment --->
		<cfparam name="tdata.orderid" default="" type="string">
		<cfparam name="tdata.paymentamount" default="0" type="numeric">
	</cfif>
	<!--- /end if data ok --->
	<!--- wp transaction form with hidden inputs --->
	<cfoutput>
		<form action="#trim(settings.authUrl)#" id="CWformWorldPayProcess" method="post">
			<div>
				<input type="hidden" name="instId" value="#settings.worldpayID#">
				<input type="hidden" name="testMode" value="#settings.testmode#">
				<input type="hidden" name="currency" value="#settings.currencyCode#">
				<input type="hidden" name="desc" value="#settings.orderDescription#">
				<input type="hidden" name="hideCurrency" value="true">
				<!--- cart details --->
				<input type="hidden" name="cartId" value="#tdata.orderid#">
				<input type="hidden" name="amount" value="#numberFormat(tdata.paymentAmount,'_.__')#">
				<!--- customer info fields --->
				<input type="hidden" name="name" value="#tdata.customerNameFirst# #tdata.customerNameLast#">
				<input type="hidden" name="address" value="#tdata.customerAddress1# #tdata.customerAddress2#, #tdata.customerCity#">
				<input type="hidden" name="postcode" value="#tdata.customerZip#">
				<input type="hidden" name="country" value="#tdata.transactionCountry#">
				<input type="hidden" name="phone" value="#tdata.customerphone#">
				<input type="hidden" name="email" value="#tdata.customerEmail#">
			</div>
			<div>
				<!--- submit button --->
				<div class="center top40 bottom40">
				<input name="submit" id="worldpay_submit" type="submit" class="CWformButton" value="<cfoutput>#settings.submitText#</cfoutput>">
				<!--- submit link : javascript replaces button with this link --->
				<a style="display:none;" href="##" class="CWcheckoutLink" id="CWlinkAuthSubmit">#settings.submitText#</a>
				<br>
					<div style="display:none;" id="ppLoading">
						<img style="margin-top:35px;" src="#request.cw.assetSrcDir#css/theme/cw-loading-wide.gif" height="15" width="128">
					</div>
				</div>
			</div>
		</form>
	</cfoutput>
	<!--- javascript for form display & function --->
	<cfsavecontent variable="wpFormjs">
	<script type="text/javascript">
	jQuery(document).ready(function(){
		// hide standard button
		jQuery('#worldpay_submit').hide();
		// show link, change text
		jQuery('#CWlinkAuthSubmit').text('<cfoutput>#settings.loadingText#</cfoutput>').show();
		// add loading graphic below button
		jQuery('#ppLoading').show();
		// clicking link submits form
		jQuery('#CWlinkAuthSubmit').click(function(){
			jQuery('#worldpay_submit').trigger('click');
		});
		// auto submit the form by triggering a click of the submit button
		jQuery('#worldpay_submit').delay('300').trigger('click');
	});
	</script>
	</cfsavecontent>
	<cfhtmlhead text="#wpFormjs#">
	<!--- /end CAPTURE mode --->
<!--- PROCESS MODE --->
<!--- PROCESS MODE (form post from WorldPay callback) --->
<!--- PROCESS MODE --->
<!--- verify form post with transid from wp --->
<cfelseif isDefined('attributes.auth_mode') and attributes.auth_mode is 'process'>
	<!--- create list of form values for response text --->
	<cfset request.trans.paymentTransResponse = "">
	<cfloop list="#form.fieldnames#" index="ff">
		<cfset request.trans.paymentTransResponse = request.trans.paymentTransResponse & ff & '=' & evaluate('form.#ff#') & chr(13)>
	</cfloop>
	<!--- add heading to response data --->
	<cfset request.trans.paymentTransResponse = 'WorldPay Form Values: ' & chr(13) & '===' & chr(13) & request.trans.paymentTransResponse>
	<!--- set values into page request --->
	<cfset request.trans.orderID = trim(form.cartId)>
	<cfset request.trans.paymentamount = form.amount>
	<cfset request.trans.paymentTransID = form.transId>
	<!--- take action based on response from worldpay (Y|C|unknown)--->
	<cfswitch expression="#form.transStatus#">
		<!--- if order is VERIFIED --->
		<cfcase value="Y">
		<cfset request.trans.paymentStatus = 'approved'>
			<!--- QUERY: check for duplicate transaction (payment) --->
			<cfset transQuery = CWqueryGetTransaction(request.trans.paymentTransID)>
			<!--- if Duplicate Transaction exists, we have a duplicate post --->
				<cfif transQuery.recordCount gt 0>
				<!--- set error message --->
					<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Duplicate Payment - Verify Order Balance With Merchant')>
				<!--- if Not a Duplicate --->
				<cfelse>
					<!--- QUERY: Verify Order Exists by ID ('cartId' from worldpay) --->
					<cfset orderQuery = CWquerySelectOrderDetails(order_id=request.trans.orderID)>
						<!--- if order is valid --->
						<cfif orderQuery.recordCount>
							<!--- verify payment amount not greater than order total --->
							<cfif orderQuery.order_total gte request.trans.paymentamount>
								<!--- payment is ok, save payment --->
									<cftry>
										<!--- QUERY: insert payment to database,
										returns payment id if successful, or 0-based message if not
										--->
										<cfset insertedPayment = CWsavePayment(
										order_id = request.trans.orderID,
										payment_method = settings.methodname,
										payment_type = settings.methodtype,
										payment_amount = request.trans.paymentamount,
										payment_status = 'approved',
										payment_trans_id = request.trans.paymentTransID,
										payment_trans_response = request.trans.paymentTransResponse
										)>
										<!--- if an error is returned --->
										<cfif left(insertedPayment,2) eq '0-'>
											<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Payment Insertion Error: #replace(insertedPayment,'0-','')#')>
										<!--- if no error, update order status, handle remaining balance --->
										<cfelse>
											<!--- get transactions related to this order (including the one just inserted) --->
											<cfset orderPaymentTotal = round(CWorderPaymentTotal(request.trans.orderID)*100)/100>
											<!--- set balance due --->
											<cfset request.trans.orderBalance =  orderQuery.order_total - orderPaymentTotal>
											<!--- if order is paid in full (0 or less) --->
											<cfif request.trans.orderBalance lte 0>
												<!--- QUERY: update order status to paid in full (3) --->
												<cfset updateOrderStatus = CWqueryUpdateOrder(order_id=request.trans.orderID,order_status=3)>
												<!--- SEND EMAIL TO CUSTOMER --->
												<!--- build the order details content --->
												<cfif not (isDefined('application.cw.mailSendPaymentCustomer') and application.cw.mailSendPaymentCustomer is false)>
													<cfset mailBody = CWtextOrderDetails(order_id=request.trans.orderID, show_payments=true)>
													<cfsavecontent variable="mailContent">
													<cfoutput>#application.cw.mailDefaultOrderPaidIntro#
													#chr(13)##chr(13)#
													#mailBody#
													#chr(13)##chr(13)#
													#application.cw.mailDefaultOrderPaidEnd#
													</cfoutput>
													</cfsavecontent>
													<!--- send the content to the customer --->
													<cfset confirmationResponse = CWsendMail(mailContent, 'Payment Confirmation',orderQuery.customer_email)>
												</cfif>	
												<!--- SEND EMAIL TO MERCHANT --->
												<cfif not (isDefined('application.cw.mailSendPaymentMerchant') and application.cw.mailSendPaymentMerchant is false)>
													<cfsavecontent variable="merchantMailContent">
													<cfoutput>
													An payment has been processed at #application.cw.companyName#
													#chr(10)##chr(13)#
													#mailBody#
													#chr(10)##chr(13)#
													Log in to manage this order and view payment details: #cwTrailingChar(application.cw.appSiteUrlHttp)##cwLeadingChar(application.cw.appCwAdminDir,'remove')#
													</cfoutput>
													</cfsavecontent>
													<!--- send to merchant --->
													<cfset confirmationResponse = CWsendMail(merchantMailContent, 'Payment Notification: #request.trans.orderID#',application.cw.companyEmail)>
												</cfif>
												<!--- /end send email --->
											<!--- if a balance is still owed after a payment was made--->
											<cfelseif request.trans.orderBalance gt 0>
												<!--- QUERY: update order status to partial payment (2) --->
												<cfset updateOrderStatus = CWqueryUpdateOrder(order_id=request.trans.orderID,order_status=2)>
												<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Balance of #lsCurrencyFormat(request.trans.orderBalance,'local')# due')>
											</cfif>
											<!--- /end balance due check --->
										</cfif>
										<!--- /end insertion error check --->
										<cfcatch>
											<!--- capture any errors from processing --->
											<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Payment Insertion Error: #cfcatch.detail#')>
										</cfcatch>
									</cftry>
							<!--- /end valid payment --->
							<!--- if payment is over order, we have a mismatch --->
							<cfelse>
								<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Invalid Payment Amount')>
							</cfif>
							<!--- /end verify payment amount --->
						<!--- if order is invalid (no matching order by ID) --->
						<cfelse>
							<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Invalid Payment - No Matching Order, Payment Not Applied')>
						</cfif>
						<!--- /end if order is valid --->
				</cfif>
				<!--- /end duplicate yes/no --->
		</cfcase>
		<!--- /end value=verified --->
		<!--- if order is INVALID --->
		<cfcase value="C">
				<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Authorization Failure - Unable to verify payment.')>
				<cfset request.trans.paymentStatus = 'denied'>
		</cfcase>
		<!--- /end value=invalid --->
		<!--- if order is UNKNOWN --->
		<cfdefaultcase>
				<cfset request.trans.errorMessage = listAppend(request.trans.errorMessage, 'Authorization Error - Unknown payment status response.')>
				<cfset request.trans.paymentStatus = 'none'>
		</cfdefaultcase>
		<!--- /end value=unknown --->
	</cfswitch>
	<!--- /end switch for worldpay response --->
	<!--- IF ERRORS: notify admin of any errors --->
	<cfif len(trim(request.trans.errorMessage))>
		<cfoutput>
		<cfsavecontent variable="mailContent">
		The following errors were reported while processing an attempted WorldPay payment:#chr(13)#
		===#chr(13)#
		Order: #request.trans.orderID##chr(13)#
		Transaction ID:#request.trans.paymentTransID##chr(13)#
		===#chr(13)#
		<cfloop list="#request.trans.errorMessage#" index="ee">
		#ee##chr(13)#
		</cfloop>
		===#chr(13)#
		#request.trans.paymentTransResponse#
		===#chr(13)#
		Order Details:#chr(13)#
		#CWtextOrderDetails(request.trans.orderID)#
		</cfsavecontent>
		</cfoutput>
		<!--- send the error message to the site admin --->
		<cfif isDefined('application.cw.developerEmail') and isValid('email',application.cw.developerEmail)>
			<cfset confirmationResponse = CWsendMail(mailContent, 'WorldPay Processing Error',application.cw.developerEmail)>
		</cfif>
		<!--- /end send email --->
	</cfif>
	<!--- /end if errors --->
	<!--- prevent processor callback from triggering further response from our page --->
	<cfabort>
	<!--- /END PROCESS MODE --->
</cfif>