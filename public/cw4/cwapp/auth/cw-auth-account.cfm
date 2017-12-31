<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-auth-account.cfm
File Date: 2012-02-01
Description: Creates functionality to process the order and show confirmation.
Bypasses any actual financial transaction, stores the order as complete / paid in full (or as pending, with modification below).
Use, updates and modifications of this file as a payment option are the sole responsibility of the user.

Custom validation, response messages and more can be injected in several locations - see processing code below.
( Tip: copy and rename this file in the cwapp/auth/ directory, then customize the new copy.
It will automatically appear in the Cartweaver Admin as a selectable payment option.)

NOTE: Setting up accounts and integrating with third party processors is not
a supported feature of Cartweaver. For information and support concerning
payment processors contact the appropriate processor tech support web site or
personnel. Cartweaver includes this integration code as a courtesy with no
guarantee or warranty expressed or implied. Payment processors may make changes
to their protocols or practices that may affect the code provided here.
If so, updates and modifications are the sole responsibility of the user.

================================================================
RETURN VARIABLES:
request.trans.paymentTransID,
request.trans.paymentTransResponse,
request.trans.paymentStatus

Values:
Transaction ID,
Transaction Response Message,
Payment Status (approved|denied|none(no response))

These are returned to the containing page or template
in the request scope, e.g. '#request.trans.paymentTransID#'
--->

<!--- /// CONFIGURATION / SETUP /// --->
<!--- CWauth Payment Configuration --->

<!--- USER SETTINGS  [ START ] ==================================================== --->
<!--- ============================================================================= --->

	<!--- OPTIONAL PAYMENT METHOD VARIABLES --->
		<!--- method image: an optional logo url (relative or full url) associated with this payment option at checkout  --->
		<cfset settings.methodImg = ''>
		<!--- shippay message: optional message shown to customer on shipping selection --->
		<cfset settings.methodSelectMessage = 'Charge to Account'>
		<!--- submit message: optional message shown to customer on final order submission --->
		<cfset settings.methodSubmitMessage = 'This order will be submitted without payment and held on file, pending direct payment or debit of your account.'>
		<!--- confirm message: optioal message shown to customer after order is approved --->
		<cfset settings.methodConfirmMessage = 'Thank You.'>

<!--- ============================================================================ --->
<!--- USER SETTINGS [ END ] ====================================================== --->

<!--- METHOD SETTINGS : do not change --->
	<!--- method name: the user-friendly name shown for this payment option at checkout --->
	<cfset settings.methodName = 'In-Store Account'>
	<!--- method type: processor (off-site processing), gateway (integrated credit card form), account (in-store account) --->
	<cfset settings.methodType = 'account'>

<!--- CONFIG DATA : These variables are returned to the calling page in the "CWauthMethod" scope --->
<!--- if called as a cfmodule in 'config mode', provide configuration data as a ColdFusion struct --->
<cfif isDefined('attributes.auth_mode') and attributes.auth_mode is 'config'>
	<!--- clear scope from previous file operations (in case of multiple payment methods in use) --->
	<cfset caller.CWauthMethod = structNew()>
	<cfset caller.CWauthMethod.methodName = settings.methodName>
	<cfset caller.CWauthMethod.methodType = settings.methodType>
	<cfset caller.CWauthMethod.methodImg = settings.methodImg>
	<cfset caller.CWauthMethod.methodSelectMessage = settings.methodSelectMessage>
	<cfset caller.CWauthMethod.methodSubmitMessage = settings.methodSubmitMessage>
	<cfset caller.CWauthMethod.methodConfirmMessage = settings.methodConfirmMessage>
<!--- PROCESS ORDER --->
<!--- if called as cfmodule in 'process' mode, process order --->
<cfelseif isDefined('attributes.auth_mode') and attributes.auth_mode is 'process'>
	<cfparam name="attributes.trans_data" default="">
	<!--- verify transaction data is ok --->
	<cfif not isStruct(attributes.trans_data)>
		<cfset request.trans.errorMessage = 'Payment Data Incomplete'>
	<!--- if data is ok, run processing --->
	<cfelse>
		<!--- simplify to 'tdata' struct --->
		<cfset tdata = attributes.trans_data>
		<cfparam name="tdata.customerid" default="" type="string">
	<cftry>
	<!--- RETURN THESE VARIABLES --->
		<cfset request.trans.paymenttransstatus = 'approved'>
		<cfset request.trans.paymentTransID = 'ACCT:' & tdata.customerid>
		<cfset request.trans.paymentTransResponse = 'Order charged to account'>
		<cfset request.trans.paymentStatus = request.trans.paymenttransstatus>
	<cfcatch>
		<cfset request.trans.errorMessage = 'Processing Error - Transaction Incomplete'>
	</cfcatch>
	</cftry>
	<!--- WIPE TRANSACTION DATA --->
		<cfset structClear(settings)>
		<cfset structClear(tdata)>
	</cfif>
	<!--- /end if transaction data is ok --->
<!--- /END PROCESS ORDER MODE --->
</cfif>
<!--- /END MODE SELECTION --->
</cfsilent>