<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-mod-formlogin.cfm
File Date: 2012-08-25
Description: customer login form, handles login processing
==========================================================
--->

<cfparam name="session.cwclient.cwCustomerID" default="0">
<cfparam name="form.login_username" default="">
<cfparam name="form.login_password" default="">
<cfparam name="form.pw_email" default="">
<cfparam name="form.login_remember" default="">
<!--- show login or 'get password' forms ( login | pw ) --->
<cfparam name="url.mode" default="login">
<cfparam name="attributes.form_mode" default="#url.mode#">
<!--- page to relocate to on success --->
<cfparam name="attributes.success_url" default="#request.cw.thisPage#">
<!--- heading for form markup --->
<cfparam name="attributes.form_heading" default="Customer Login">
<!--- message to show when password has been found --->
<cfparam name="attributes.pw_message" default="Password has been sent to the email address provided">
<!--- use the 'remember me' checkbox (boolean) --->
<cfparam name="attributes.remember_me" default="#application.cw.customerRememberMe#">
<!--- load the checkbox already checked (boolean) --->
<cfparam name="attributes.remember_me_checked" default="#form.login_remember#">
<!--- custom errors can be passed in here --->
<cfset request.cwpage.loginErrors = ''>
<!--- global functions --->
<cfinclude template="../inc/cw-inc-functions.cfm">
<!--- clean up form and url variables --->
<cfinclude template="../inc/cw-inc-sanitize.cfm">
<!--- page for form base action --->
<cfparam name="request.cwpage.hrefUrl" default="#CWtrailingChar(trim(application.cw.appCwStoreRoot))##request.cw.thisPage#">
<!--- page for form to post to --->
<cfparam name="attributes.form_action" default="#request.cwpage.hrefUrl#">
<!--- base url for switching modes --->
<cfset loginVarsToKeep = CWremoveUrlVars("mode")>
<cfset baseLoginUrl = CWserializeUrl(loginVarsToKeep,request.cw.thisPage)>
<cfif baseLoginUrl contains "=">
	<cfset baseLoginUrl = baseLoginUrl & "&">
</cfif>
<!--- HANDLE FORM SUBMISSION --->
<!--- LOGIN FORM --->
<cfif (isDefined('form.login_username') and not form.login_username is "") and (isDefined('form.login_password') and not form.login_password is "")>
	<!--- validate required fields (server side validation controlled here - each field contains rules for javascript validation separately) --->
	<cfset requiredTextFields = 'login_username,login_password'>
	<cfloop list="#requiredTextFields#" index="ff">
		<!--- verify some content exists for each field --->
		<cfif NOT len(trim(#form[ff]#)) and not listFindNoCase(request.cwpage.loginerrors,ff)>
			<cfset request.cwpage.loginerrors = listAppend(request.cwpage.loginErrors,ff)>
		</cfif>
	</cfloop>
	<!--- if errors exist --->
	<cfif len(request.cwpage.loginErrors)>
		<!--- if no errors, run login function --->
	<cfelse>
		<!--- QUERY: get username and pw --->
		<cfset loginQuery = CWqueryCustomerLogin(trim(form.login_username),trim(form.login_password))>
		<!--- if matched, login successful --->
		<cfif loginQuery.recordCount is 1>
			<cfset session.cwclient.cwCustomerID = loginQuery.customer_id>
			<cfset session.cwclient.cwCustomerName = loginQuery.customer_username>
			<cfset session.cwclient.cwCustomerCheckout = 'account'>
			<!--- QUERY: get customer billing region and country --->
			<cfset customerQuery = CWquerySelectCustomerDetails(session.cwclient.cwCustomerID)>
			<!--- set customer type into session --->
			<cfif isNumeric(customerQuery.customer_type_id)>
				<cfset session.cwclient.cwcustomertype = customerQuery.customer_type_id>
			<cfelse>
				<cfset session.cwclient.cwcustomertype = '1'>
			</cfif>
			<!--- QUERY: get customer shipping region and country --->
			<cfset shippingQuery = CWquerySelectCustomerShipping(session.cwclient.cwCustomerID)>
			<!--- set customer tax region, ship region --->
			<cfset customerTaxRegionQuery = CWquerySelectStateProvDetails(customerQuery.stateprov_id)>
			<cfset customerShipRegionQuery = CWquerySelectStateProvDetails(shippingQuery.stateprov_id)>
				<cfif application.cw.taxChargeBasedOn eq 'billing'>
				<cfif customerTaxRegionQuery.recordCount gt 0>
					<cfset session.cwclient.cwTaxRegionID = customerTaxRegionQuery.stateprov_id>
					<cfset session.cwclient.cwTaxCountryID = customerTaxRegionQuery.stateprov_country_id>
				</cfif>
				</cfif>
				<cfif customerShipRegionQuery.recordCount gt 0>
					<cfset session.cwclient.cwShipRegionID = customerShipRegionQuery.stateprov_id>
					<cfset session.cwclient.cwShipCountryID = customerShipRegionQuery.stateprov_country_id>
					<cfif application.cw.taxChargeBasedOn eq 'shipping'>
						<cfset session.cwclient.cwTaxRegionID = customerShipRegionQuery.stateprov_id>
						<cfset session.cwclient.cwTaxCountryID = customerShipRegionQuery.stateprov_country_id>
					</cfif>
				</cfif>
				<!--- Store username inside a cookie if remember me was checked --->
				<cfif attributes.remember_me>
					<cfif isDefined("form.login_remember") and form.login_remember neq ''>
						<cfcookie name="CWusername" value="#form.login_username#" expires="never">
						<!--- Else, clean any existing cookie --->
					<cfelse>
						<cfcookie name="CWusername" value="" expires="now">
					</cfif>
				</cfif>
			<!--- redirect to avoid reposting --->
			<cflocation url="#attributes.success_url#" addtoken="no">
		<cfelse>
			<!--- if no match --->
			<cfset session.cwclient.cwCustomerID = 0>
			<cfset structDelete(session.cwclient,'customerName')>
			<cfset request.cwpage.loginErrors = 'login_username,login_password'>
			<cfset CWpageMessage("alert","Error: login not recognized")>
			<cfset attributes.remember_me_checked = false>
		</cfif>
		<!--- / end login match y/n --->
	</cfif>
	<!--- / end login validation errors --->
</cfif>
<!--- / end login form handling --->
<!--- PASSWORD FORM --->
<cfif isDefined('form.pw_email') and len(trim(form.pw_email))>
	<!--- validate email --->
	<cfif not isValid('email',form.pw_email) and not listFindNoCase(request.cwpage.loginerrors,'pw_email')>
		<cfset request.cwpage.loginerrors = listAppend(request.cwpage.loginErrors,'pw_email')>
	</cfif>
	<!--- if errors exist --->
	<cfif len(request.cwpage.loginErrors)>
		<!--- set error for email address --->
		<cfset CWpageMessage("alert","Error: Email must be a valid address")>
		<!--- if no errors, run login function --->
	<cfelse>
		<!--- QUERY: get username and pw --->
		<cfset pwQuery = CWqueryCustomerLookup(customer_email=trim(form.pw_email))>
		<!--- if matched, login successful --->
		<cfif pwQuery.recordCount is 1>
			<!--- send message: compile contents --->
			<cfset mailBody = CWtextPasswordReminder(customer_id=pwQuery.customer_id,login_url=request.cw.thisUrl)>
			<cfsavecontent variable="mailContent">
			<cfoutput>#application.cw.mailDefaultPasswordSentIntro#
			#chr(10)##chr(13)#
			#chr(10)##chr(13)#
			#mailBody#
			#chr(10)##chr(13)#
			#chr(10)##chr(13)#
			#application.cw.mailDefaultPasswordSendEnd#
			</cfoutput>
			</cfsavecontent>
			<!--- send the content to the customer, get response from the function --->
			<cfset messageResponse = CWsendMail(
				mail_body=mailContent,
				mail_subject='Your #application.cw.companyName# Account Information',
				mail_address_list=pwQuery.customer_email)>
			<!--- if there is any problem sending the message, add the response to the page message --->
			<cfif messageResponse contains 'error'>
				<cfset CWpageMessage("alert","#messageResponse#")>
				<!--- second line of error - adding separately shows on a new line --->
				<cfset CWpageMessage("alert","Contact Customer Service for assistance")>
				<cfset request.cwpage.loginErrors = 'pw_email'>
				<!--- if no error is returned --->
			<cfelse>
				<!--- save temporary client (cookie) variable to show password sent --->
				<cfset session.cwclient.cwPwsent = trim(form.pw_email)>
				<!--- set up url to redirect to --->
				<cfsavecontent variable="pwSuccessUrl">
					<cfoutput>#attributes.success_url#<cfif not attributes.success_url contains '?'>?<cfelse>&</cfif>mode=pw</cfoutput>
				</cfsavecontent>
				<!--- redirect user --->
				<cflocation url="#trim(pwSuccessUrl)#" addtoken="no">
			</cfif>
			<!--- /end if error returned from mail function --->
			<!--- if no match, reset client cookie vars, show alert --->
		<cfelse>
			<cfset session.cwclient.cwCustomerID = 0>
			<cfset structDelete(session.cwclient,'customerName')>
			<cfset request.cwpage.loginErrors = 'pw_email'>
			<cfset CWpageMessage("alert","Error: email address not recognized")>
		</cfif>
		<!--- / end email query match y/n --->
	</cfif>
	<!--- / end email validation errors --->
</cfif>
<!--- /end password form handling --->
<!--- if using cookies, set blank value as default --->
<cfif application.cw.appCookieTerm neq 0>
	<cfif not isdefined("cookie.cwUsername")>
		<cfcookie name="CWusername" value="" expires="NOW">
	<cfelseif form.login_username eq ''>
		<cfset form.login_username = cookie.cwUsername>
	</cfif>
</cfif>
</cfsilent>
<!--- //////////// --->
<!--- START OUTPUT --->
<!--- //////////// --->
<form class="CWvalidate" id="CWformLogin" name="CWformLogin" method="post" action="<cfoutput>#attributes.form_action#<cfif not attributes.form_action contains '?'>?<cfelse>&</cfif>mode=#attributes.form_mode#</cfoutput>">
	<!--- login form --->
	<cfif attributes.form_mode is 'login'>
		<table class="CWformTable" id="loginFormTable">
			<tr class="headerRow">
				<th colspan="2">
					<cfif len(trim(attributes.form_heading))>
						<h3><cfoutput>#attributes.form_heading#</cfoutput></h3>
					</cfif>
					<!--- ALERTS: capture any login form errors --->
					<cfif len(trim(request.cwpage.loginErrors))>
						<div class="CWalertBox validationAlert" id="customerFormAlert">
							<!--- default alert --->
							<cfif not isArray(request.cwpage.userAlert) OR NOT arrayLen(request.cwpage.userAlert)>
								<div class="alertText">Error: Complete all required information</div>
							<cfelse>
								<cfloop array="#request.cwpage.userAlert#" index="aa">
									<cfif len(trim(aa))>
										<div class="alertText">
											<cfoutput>#replace(aa,'<br>','','all')#</cfoutput>
										</div>
									</cfif>
								</cfloop>
							</cfif>
							<div class="alertText centered smallPrint"><a href="<cfoutput>#baseLoginUrl#</cfoutput>mode=pw">Recover Password</a></div>
						</div>
					</cfif>
				</th>
			</tr>
			<!--- username --->
			<tr>
				<th class="label required">Username</th>
				<td>
					<input name="login_username" class="{required:true}<cfif request.cwpage.loginErrors contains 'login_username'> warning</cfif>" title="Username is required" size="20" maxlength="254" type="text" id="login_username" value="<cfoutput>#form.login_username#</cfoutput>">
				</td>
			</tr>
			<!--- password --->
			<tr>
				<th class="label required">Password</th>
				<td>
					<input name="login_password" class="{required:true}<cfif request.cwpage.loginErrors contains 'login_password'> warning</cfif>" title="Password is required" size="20" maxlength="254" type="password" id="login_password" value="<cfoutput>#form.login_password#</cfoutput>">
				</td>
			</tr>
			<!--- customer message --->
            <tr>
            	<td colspan="2">
					<p class="center smallPrint"><em>Note: username and password are case sensitive</em></p>
                </td>
            </tr>
			<!--- remember me --->
			<cfif attributes.remember_me>
			<tr>
				<td colspan="2">
					<p class="center">
					<input type="checkbox" name="login_remember" value="true"<cfif attributes.remember_me_checked eq 'true' OR (isDefined('cookie.cwUsername') and len(trim(cookie.cwUsername)))> checked="checked"</cfif>> Remember Me
					</p>
				</td>
			</tr>
			</cfif>
			<!--- submit --->
			<tr>
				<td colspan="2" style="text-align:center;">
					<input name="login_submit" type="submit" class="CWformButtonSmall" id="login_submit" value="Log In">
				</td>
			</tr>
			<!--- password link--->
			<tr>
				<td colspan="2" style="text-align:center;">
					<div class="centered smallPrint">
						<a href="<cfoutput>#baseLoginUrl#</cfoutput>mode=pw">Recover Password</a>
					</div>
				</td>
			</tr>
		</table>
		<!--- forgot password form --->
	<cfelse>
		<table class="CWformTable" id="loginFormTable">
			<tr class="headerRow">
				<th colspan="2">
					<h3>Recover Password</h3>
					<!--- ALERTS: capture any password form errors --->
					<cfif len(trim(request.cwpage.loginErrors)) or isDefined('session.cwclient.cwPwSent')>
						<div class="CWalertBox validationAlert" id="customerFormAlert">
							<!--- default alert --->
							<cfif isDefined('session.cwclient.cwPwSent') and len(trim(session.cwclient.cwPwSent))>
								<div class="alertText">Password has been sent to <cfoutput>#trim(session.cwclient.cwPwSent)#</cfoutput></div>
								<div class="alertText centered smallPrint"><a href="<cfoutput>#baseLoginUrl#</cfoutput>mode=login">Return to Login</a></div>
								<!--- remove client variable, message only shown once --->
							<cfset structDelete(session.cwclient,'cwPwSent')>
							<cfelseif isArray(request.cwpage.userAlert) AND arrayLen(request.cwpage.userAlert)>
								<cfloop array="#request.cwpage.userAlert#" index="aa">
									<cfif len(trim(aa))>
										<div class="alertText"><cfoutput>#replace(aa,'<br>','','all')#</cfoutput></div>
									</cfif>
								</cfloop>
							<cfelseif len(trim(request.cwpage.userAlert))>
								<div class="alertText">Error: Email must be a valid email</div>
							</cfif>
						</div>
					</cfif>
				</th>
			</tr>
			<!--- email --->
			<tr>
				<th class="label required">Email Address</th>
				<td>
					<input name="pw_email" class="{required:true, email:true}<cfif request.cwpage.loginErrors contains 'pw_email'> warning</cfif>" title="Email Address is required" size="20" maxlength="254" type="text" id="pw_email" value="<cfoutput>#form.pw_email#</cfoutput>">
				</td>
			</tr>
			<!--- submit --->
			<tr>
				<td colspan="2" style="text-align:center;">
					<input name="pw_submit" type="submit" class="CWformButtonSmall" id="pw_submit" value="Send Password">
				</td>
			</tr>
			<!--- login link--->
			<tr>
				<td colspan="2" style="text-align:center;">
					<div class="centered smallPrint">
						<a href="<cfoutput>#baseLoginUrl#</cfoutput>mode=login">Return to Login</a>
					</div>
				</td>
			</tr>
		</table>
	</cfif>
	<!--- /end mode --->
	<div class="CWclear"></div>
</form>