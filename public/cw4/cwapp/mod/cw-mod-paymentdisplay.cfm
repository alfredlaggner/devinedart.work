<!--- only show or run processing if at least one payment method is selected in admin settings --->
<cfif isDefined('application.cw.authMethods') AND listLen(application.cw.authMethods) gt 0>
<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-mod-paymentdisplay.cfm
File Date: 2012-11-30
Description: creates and displays payment options, or credit card form for input
Parses information from files in the directory: cwapp/auth/
based on selections made in the Admin (see "Payment Settings")
NOTES:
Payment options and associated configuration data are stored as an array, application.cw.authMethods
==========================================================
--->

<!--- display mode (select|capture) --->
<cfparam name="attributes.display_mode" default="select">
<!--- default for list of available methods --->
<cfparam name="application.cw.authMethods" default="">
<!--- edit shipping url (not used for select mode - blank = not shown at all) --->
<cfparam name="attributes.edit_auth_url" default="#request.cw.thisPage#?authreset=1">
<!--- heading for selected method (in confirmation/submit order display) --->
<cfparam name="attributes.selected_title" default="Payment Method Selected">
<!--- heading for credit card form --->
<cfparam name="attributes.form_title" default="Enter Credit Card Information">
<!--- heading for payment method selector --->
<cfparam name="attributes.option_title" default="Select Payment Method">
<!--- show logos if they exist in the auth file --->
<cfparam name="attributes.show_auth_logo" default="true">
<!--- if no logo exists, or show logo is false, show name of payment method --->
<cfparam name="attributes.show_auth_name" default="true">
<!--- bypass payment, used in case of no-cost orders --->
<cfparam name="attributes.bypass_payment" default="false">

<!--- defaults for cc form --->
<cfparam name="form.customer_cardname" default="">
<cfparam name="form.customer_cardtype" default="">
<cfparam name="form.customer_cardnumber" default="">
<cfparam name="form.customer_cardexpm" default="">
<cfparam name="form.customer_cardexpy" default="">
<cfparam name="form.customer_cardccv" default="">
<!--- default list of cc input errors --->
<cfparam name="request.cwpage.formErrors" default="">
<!--- global functions --->
<cfinclude template="../inc/cw-inc-functions.cfm">
<!--- clean up form and url variables --->
<cfinclude template="../inc/cw-inc-sanitize.cfm">
<!--- if only one payment option, preselect this method --->
<cfif listLen(application.cw.authMethods) eq 1>
	<cfset session.cw.authPref = application.cw.authMethods>
	<cfset session.cw.confirmAuthPref = true>
	<!--- set client variable for payment type --->
	<cfset session.cwclient.cwCustomerAuthPref = session.cw.authPref>
<!--- HANDLE PAYMENT SELECTION SUBMISSION --->
<cfelseif isDefined('form.authPref') AND form.authPref gt 0>
	<!--- set in session memory, mark confirmed --->
	<cfset session.cw.authPref = form.authPref>
	<cfset session.cw.confirmAuthPref = true>
	<!--- set client variable for payment type --->
	<cfset session.cwclient.cwCustomerAuthPref = session.cw.authPref>
	<!--- redirect to clear form variables --->
	<cflocation url="#request.cw.thisPageQS#" addtoken="no">
</cfif>
<!--- if authreset exists in url, clear previously selected values --->
<cfif isDefined('url.authreset') and url.authreset eq 1
and listLen(application.cw.authMethods) gte 2>
	<cfset session.cw.authPref = 0>
	<cfset session.cw.authPrefName = ''>
	<cfset session.cw.confirmAuthPref = false>
	<cfset session.cwclient.cwCustomerAuthPref = 0>
</cfif>
</cfsilent>

<!--- only run if not bypassing payment --->
<cfif attributes.bypass_payment is false>
<!--- IF PAYMENT METHOD IS SELECTED in session, and id is in list of active options --->
<cfif isDefined('session.cw.authPref')
	and isNumeric(session.cw.authPref)
	and session.cw.authPref gt 0
	and listFind(application.cw.authMethods,session.cw.authPref)>
		<!--- the id of the auth method is stored in the user's session --->
		<cfset authID = session.cw.authPref>
		<!--- defaults for auth method settings --->
		<cfparam name="application.cw.authMethodData[authID].methodID" default="0">
		<cfparam name="application.cw.authMethodData[authID].methodName" default="">
		<cfparam name="application.cw.authMethodData[authID].methodType" default="none">
		<cfparam name="application.cw.authMethodData[authID].methodImg" default="">
		<cfparam name="application.cw.authMethodData[authID].methodSelectMessage" default="">
		<cfparam name="application.cw.authMethodData[authID].methodSubmitMessage" default="">
		<!--- look up details based on authMethodData stored in application scope --->
		<cfset CWauth.methodID = application.cw.authMethodData[authID].methodID>
		<cfset CWauth.methodName = application.cw.authMethodData[authID].methodName>
		<cfset CWauth.methodType = application.cw.authMethodData[authID].methodType>
		<cfset CWauth.methodImg = application.cw.authMethodData[authID].methodImg>
		<cfset CWauth.methodSelectMessage = application.cw.authMethodData[authID].methodSelectMessage>
		<cfset CWauth.methodSubmitMessage = application.cw.authMethodData[authID].methodSubmitMessage>
		<!--- payment selection details in customer session --->
		<cfset session.cw.authType = cwauth.methodtype>
		<cfset session.cw.authPrefName = cwauth.methodname>
		<cfset session.cw.confirmAuthPref = true>
		<!--- CAPTURE MODE --->
		<!--- CAPTURE MODE (credit card form) --->
		<!--- CAPTURE MODE --->
		<cfif attributes.display_mode eq 'capture'>
			<!--- submit order message --->
			<cfif len(trim(CWauth.methodSubmitMessage)) AND session.cw.confirmAuthPref eq true>
				<p class="CWformMessage CWclear"><cfoutput>#trim(CWauth.methodSubmitMessage)#</cfoutput></p>
			</cfif>
			<!--- if gateway payment type, show credit card inputs  --->
			<cfif CWauth.methodType is 'gateway'>
				<!--- QUERY: get credit cards available --->
				<cfset creditCardsQuery = CWquerySelectCreditCards()>
				<!--- CREDIT CARD INPUT FORM --->
				<!--- credit card form elements --->
				<table class="CWformTable">
					<tbody>
						<tr class="headerRow">
							<th colspan="2">
							<cfif len(trim(attributes.form_title))>
								<h3 class="CWformTitle"><cfoutput>#attributes.form_title#</cfoutput></h3>
							</cfif>
							</th>
						</tr>
						<!--- card holder name --->
						<tr>
						<th class="label required">Card Holder Name</th>
						<td>
							<input name="customer_cardname" id="customer_cardname" class="{required:true}<cfif listFindNoCase(request.cwpage.formErrors,'customer_cardname')> warning</cfif>" type="text" size="35" value="<cfoutput>#form.customer_cardname#</cfoutput>" title="Enter Card Holder Name">
						</td>
						</tr>
						<!--- card type --->
						<tr>
						<th class="label required">Card Type</th>
						<td>
							<select name="customer_cardtype" id="customer_cardtype" class="{required:true}<cfif listFindNoCase(request.cwpage.formErrors,'customer_cardtype')> warning</cfif>" title="Select Credit Card Type">
								<option value="">-- Select --</option>
								<cfoutput query="creditCardsQuery">
									<option value="#creditcard_code#"<cfif form.customer_cardtype eq creditcard_code> selected="selected"</cfif>>#creditcard_name#</option>
								</cfoutput>
							</select>
						</td>
						</tr>
						<!--- card number (value not persisted) --->
						<tr>
						<th class="label required">Card Number</th>
						<td>
							<input name="customer_cardnumber" id="customer_cardnumber" class="{required:true,minlength:13,maxlength:19}<cfif listFindNoCase(request.cwpage.formErrors,'customer_cardnumer')> warning</cfif>" type="text" size="24" maxlength="19" value="" title="Enter Card Numer" onkeyup="extractNumeric(this,0,false)" autocomplete="off">
						</td>
						</tr>
						<!--- expiration --->
						<tr>
						<th class="label required">Expiration Date</th>
						<td>
							Month <select name="customer_cardexpm" id="customer_cardexpm" class="{required:true}<cfif listFindNoCase(request.cwpage.formErrors,'customer_cardexpm')> warning</cfif>" title="Select Expiration Month">
										<option value="" selected="selected">--</option>
										 <cfloop from="01" to="12" index="mm">
											<option value="<cfoutput>#numberFormat(mm,'09')#</cfoutput>"><cfoutput>#numberFormat(mm,'09')#</cfoutput></option>
										</cfloop>
								</select>
							Year <select name="customer_cardexpy" id="customer_cardexpy" class="{required:true}<cfif listFindNoCase(request.cwpage.formErrors,'customer_cardexpy')> warning</cfif>" title="Select Expiration Year">
										<option value="" selected="selected">--</option>
										 <cfloop from="#dateformat(now(),'yyyy')#" to="#dateFormat(dateAdd('yyyy',8,now()),'yyyy')#" index="yy">
											<option value="<cfoutput>#numberFormat(yy,'0009')#</cfoutput>"><cfoutput>#numberFormat(yy,'0009')#</cfoutput></option>
										</cfloop>
								</select>
						</td>
						</tr>
						<!--- ccv code --->
						<tr>
						<th class="label required">CCV Code</th>
						<td>
							<input name="customer_cardccv" id="customer_cardccv" class="{required:true,minlength:3,maxlength:4}<cfif listFindNoCase(request.cwpage.formErrors,'customer_cardccv')> warning</cfif>" type="text" size="5" maxlength="4" value="" title="Enter Card CCV Code" onkeyup="extractNumeric(this,0,false)" autocomplete="off">
							<a id="CWccvLink" class="CWlink" style="display:none" href="#">What's this?</a>
							<div id="CWccvExplain" style="display:none;">
							<cfoutput><img alt="" src="#request.cw.assetSrcDir#theme/ccv-location.gif"></cfoutput>
								<a href="#" id="CWccvClose">Close Window</a>
							</div>
						</td>
						</tr>
					</tbody>
				</table>
				<!--- /end credit card form --->
				<cfsavecontent variable="ccformjs">
					<script type="text/javascript">
					jQuery(document).ready(function(){
						// show ccv link, create popup
						jQuery('#CWccvLink').show().click(function(){
							jQuery('#CWccvExplain').toggle();
								return false;
						});
						// close window with click anywhere
						jQuery('#CWccvClose').click(function(){
							jQuery('#CWccvExplain').toggle();
								return false;
						}).parents('#CWccvExplain').click(function(){
							jQuery(this).toggle();
						});
					});
					</script>
				</cfsavecontent>
				<cfhtmlhead text="#ccformjs#">
			</cfif>
			<!--- /end if gateway --->
		<!--- /end CAPTURE mode --->
		<!--- SELECT MODE w/ authpref selected: display of option --->
		<!--- if a method is selected, and not using 'capture' mode, show the selected method here --->
		<cfelse>
		<cfoutput>
		<cfif len(trim(attributes.selected_title))>
			<h3 class="CWformTitle">#attributes.selected_title#</h3>
		</cfif>
			<!--- only create markup if some element exists --->
			<cfif (len(trim(attributes.edit_auth_url)) and listLen(application.cw.authmethods) gt 1)
			OR (len(trim(CWauth.methodImg)) and attributes.show_auth_logo)
			OR attributes.show_auth_name
			>
				<div class="CWpaymentOption">
					<p>
					<cfif len(trim(attributes.edit_auth_url)) and listLen(application.cw.authmethods) gt 1>
						<span class="CWeditLink">&raquo;&nbsp;<a href="<cfoutput>#attributes.edit_auth_url#"</cfoutput>>Change Method</a></span>
					</cfif>
					<!--- logo / image --->
					<cfif len(trim(CWauth.methodImg)) and attributes.show_auth_logo>
						<span class="CWpaymentLogo">
						<img src="#CWauth.methodImg#" alt="#CWauth.methodName#" class="CWpaymentImage"><br>
						</span>
					<!--- if no logo, show name --->
					<cfelseif attributes.show_auth_name>
						<span class="CWpaymentName">
						#CWauth.methodName#
						</span>
					</cfif>
					</p>
				</div>
			</cfif>
		</cfoutput>
		</cfif>
		<!--- /end SELECT mode --->
<!--- IF NO PAYMENT METHOD SELECTED (not in user's session) --->
<cfelse>
	<!--- clear value in case bogus value exists --->
	<cfset session.cwclient.cwCustomerAuthPref = 0>
	<cfset session.cw.authPref = 0>
	<cfset session.cw.confirmAuthPref = false>
	<cfset session.cw.authType = 'none'>
	<!--- show payment selection system --->
	<cfif len(trim(attributes.option_title))>
		<h3 class="CWformTitle"><cfoutput>#attributes.option_title#</cfoutput></h3>
	</cfif>
	<!--- if more than one method is available, show form for payment selection --->
	<form id="CWformPaymentSelection" action="<cfoutput>#request.cw.thisPage#</cfoutput>" method="post" class="CWvalidate">
	<!--- show output for each option --->
	<cfloop list="#application.cw.authMethods#" index="i">
		<cfparam name="application.cw.authMethodData[i].methodID" default="">
		<cfparam name="application.cw.authMethodData[i].methodName" default="">
		<cfparam name="application.cw.authMethodData[i].methodType" default="">
		<cfparam name="application.cw.authMethodData[i].methodImg" default="">
		<cfparam name="application.cw.authMethodData[i].methodSelectMessage" default="">
		<cfset CWauth.methodID = application.cw.authMethodData[i].methodID>
		<cfset CWauth.methodName = application.cw.authMethodData[i].methodName>
		<cfset CWauth.methodType = application.cw.authMethodData[i].methodType>
		<cfset CWauth.methodImg = application.cw.authMethodData[i].methodImg>
		<cfset CWauth.methodSelectMessage = application.cw.authMethodData[i].methodSelectMessage>
		<cfoutput>
			<!--- create container for each element w/ related info --->
			<div class="CWpaymentOption">
			<!--- payment info message --->
			<cfif len(trim('CWauth.methodSelectMessage')) AND session.cw.confirmAuthPref eq false>
				<p class="CWformMessage CWclear"><cfoutput>#trim(CWauth.methodSelectMessage)#</cfoutput></p>
			</cfif>
			<label>
			<!--- hidden link, shown with javascript --->
			<a href="##" class="CWselectLink" style="display:none;">Select</a>
			<input type="radio" name="authpref" class="required" value="#CWauth.methodID#" <cfif isDefined('session.cw.authPref') and session.cw.authPref is CWauth.methodID>checked="checked"</cfif>>
			<span class="CWpaymentName">
			#CWauth.methodName#
			</span>
			<!--- logo / image --->
			<cfif len(trim(CWauth.methodImg))>
			<span class="CWpaymentLogo">
			<img src="#CWauth.methodImg#" alt="#CWauth.methodName#" class="CWpaymentImage"><br>
			</span>
			</cfif>
			</label>
			</div>
		</cfoutput>
	</cfloop>
	<!--- submit button, hidden with javascript (options submit on click) --->
	<div class="center CWclear top40">
		<input type="submit" class="CWformButton" id="CWpaymentSelectSubmit" value="Submit Selection&nbsp;&raquo;">
	</div>
	</form>
	<div class="CWclear"></div>
		<!--- javascript for selection --->
		<cfsavecontent variable="paymentselectjs">
		<script type="text/javascript">
		jQuery(document).ready(function(){
			// replace radio buttons with links
			jQuery('#CWformPaymentSelection').find('input:radio').each(function(){
				jQuery(this).hide().siblings('.CWselectLink').show();
			});
			// clicking link submits form
			jQuery('#CWformPaymentSelection a.CWselectLink').click(function(){
				jQuery(this).siblings('input:radio').prop('checked','checked');
				jQuery(this).parents('form').submit();
				return false;
			});
			// checkout link submits form (for validation)
			jQuery('#CWformPaymentSelection a.CWcheckoutLink').click(function(){
				jQuery('form#CWformPaymentSelection').submit();
				return false;
			});
			// hide submit button
			jQuery('#CWpaymentSelectSubmit').hide();
			// form submits on click of anything in label
			jQuery('#CWformPaymentSelection .CWpaymentOption > *').css('cursor','pointer').click(function(){
				jQuery(this).parents('.CWpaymentOption').find('input:radio').prop('checked','checked').parents('form').submit();
				return false;
			});
		});
		</script>
		</cfsavecontent>
		<cfhtmlhead text="#paymentselectjs#">
	<!--- /end payment options --->
</cfif>
<!--- /end IF METHOD SELECTED --->
</cfif>
<!--- /end if bypass_payment = false --->
</cfif>
<!--- /end if payment methods exist --->