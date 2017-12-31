<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-mod-formcustomer.cfm
File Date: 2012-11-17
Description: creates and displays customer information form, handles updates
==========================================================
--->

<cfparam name="session.cwclient.cwCustomerID" default="0">
<cfparam name="session.cwclient.cwCustomerType" default="0">
<cfparam name="session.cwclient.cwCustomerName" default="">
<cfparam name="session.cwclient.cwShipRegionID" default="0">
<cfparam name="session.cwclient.cwShipCountryID" default="0">
<cfparam name="session.cwclient.cwTaxRegionID" default="0">
<cfparam name="session.cwclient.cwTaxCountryID" default="0">
<cfparam name="session.cwclient.cwCustomerCheckout" default="account">
<!--- page to relocate to on success (if blank, go to same page) --->
<cfparam name="attributes.success_url" default="#request.cwpage.urlShowCart#">
<cfif not len(trim(attributes.success_url))>
	<cfset attributes.success_url = request.cw.thisPage>
</cfif>
<!--- text on submit button --->
<cfparam name="attributes.submit_value" default="Submit Details&nbsp;&raquo;">
<!--- persist confirmation status in session --->
<cfparam name="attributes.mark_confirmed" default="true">
<cfparam name="session.cw.confirmAddress" default="false">
<!--- show username/pw fields --->
<cfparam name="attributes.show_account_info" default="true">
<!--- show shipping fields --->
<cfparam name="application.cw.shipDisplayInfo" default="true">
<cfparam name="application.cw.shipEnabled" default="true">
<cfif application.cw.shipEnabled>
<cfset request.cwpage.shipDisplayInfo = application.cw.shipDisplayInfo>
<cfelse>
<cfset request.cwpage.shipDisplayInfo = false>
</cfif>
<cfparam name="application.cw.appDisplayCountryType" default="single">
<!--- customer guest account --->
<cfparam name="request.cwpage.customerGuest" default="0">
<!--- check for duplicate username / pw --->
<cfparam name="request.cwpage.dupCheck" default="true">
<!--- country/state display type (single|split) --->
<cfparam name="request.cwpage.stateSelectType" default="#application.cw.appDisplayCountryType#">
<!--- custom errors can be passed in here --->
<cfset request.cwpage.formErrors = ''>
<!--- global functions --->
<cfinclude template="../inc/cw-inc-functions.cfm">
<!--- clean up form and url variables --->
<cfinclude template="../inc/cw-inc-sanitize.cfm">
<!--- page for form base action --->
<cfparam name="request.cwpage.hrefUrl" default="#CWtrailingChar(trim(application.cw.appCwStoreRoot))##request.cw.thisPage#">
<!--- page for form to post to --->
<cfparam name="attributes.form_action" default="#request.cwpage.hrefUrl#">
<!--- HANDLE FORM SUBMISSION --->
<cfif isDefined('form.customer_email')>
	<!--- validate required fields (server side validation controlled here - each field contains rules for javascript validation separately) --->
	<cfset requiredTextFields = 'customer_first_name,customer_last_name,customer_phone,customer_address1,customer_city,customer_billing_state,customer_zip'>
	<!--- shipping fields, if used --->
	<cfif request.cwpage.shipDisplayInfo>
		<cfset requiredTextFields = listAppend(requiredTextFields,'customer_ship_name,customer_ship_address1,customer_ship_city,customer_ship_state,customer_ship_zip')>
	</cfif>
	<!--- validate username and pw if accounts are enabled --->
	<cfif attributes.show_account_info>
		<cfset requiredTextFields = listAppend(requiredTextFields,'customer_username,customer_password')>
	</cfif>
	<cfloop list="#requiredTextFields#" index="ff">
		<!--- verify some content exists for each field --->
		<cfif not (isDefined('form.#trim(ff)#') and len(trim(#form[trim(ff)]#))) and not listFindNoCase(request.cwpage.formErrors,trim(ff))>
			<cfset request.cwpage.formErrors = listAppend(request.cwpage.formErrors,trim(ff))>
		</cfif>
	</cfloop>
	<!--- validate email --->
	<cfif not isValid('email',form.customer_email) and not listFindNoCase(request.cwpage.formErrors,'customer_email')>
		<cfset request.cwpage.formErrors = listAppend(request.cwpage.formErrors,'customer_email')>
		<cfset CWpageMessage("alert","Error: Email must be a valid email address")>
	</cfif>
	<!--- validate customer account fields --->
	<cfif attributes.show_account_info eq false>
		<!--- bypass duplicate  --->
		<cfset request.cwpage.dupCheck = false>
		<!--- bypass account info w/ default username/pw --->
		<!--- username defaults to email address --->
		<cfif not len(trim(form.customer_username))>
			<cfset form.customer_username = form.customer_email>
		</cfif>
		<!--- password defaults to random number --->
		<cfif not len(trim(form.customer_password))>
			<cfset pwVal = randRange(1000000,9999999)>
			<cfset form.customer_password = pwVal>
			<cfset form.customer_password2 = pwVal>
		</cfif>
		<!--- if using account info, validate each field --->
	<cfelse>
		<!--- validate username length --->
		<cfif not len(trim(form.customer_username)) gt 5>
			<cfset request.cwpage.formErrors = listAppend(request.cwpage.formErrors,'customer_username')>
			<cfset CWpageMessage("alert","Error: Username must be at least 6 characters")>
		</cfif>
		<!--- validate password length --->
		<cfif not len(trim(form.customer_username)) gt 5>
			<cfset request.cwpage.formErrors = listAppend(request.cwpage.formErrors,'customer_password')>
			<cfset CWpageMessage("alert","Error: Password must be at least 6 characters")>
		</cfif>
		<!--- validate password confirmation --->
		<cfif not (
			len(trim(form.customer_password))
			and trim(form.customer_password) eq trim(form.customer_password2)
			)>
			<cfset request.cwpage.formErrors = listAppend(request.cwpage.formErrors,'customer_password2')>
			<cfset CWpageMessage("alert","Error: Password confirmation must match password")>
		</cfif>
	</cfif>
	<!--- if no errors exist --->
	<cfif not len(request.cwpage.formErrors)>
		<!--- record submission in customer's session --->
		<cfset session.cw.confirmAddress = true>
			<!--- replace shipping values with customer values if not using shipping --->
			<cfif not request.cwpage.shipDisplayInfo>
				<cfset form.customer_ship_name = form.customer_first_name & ' ' & form.customer_last_name>
				<cfset form.customer_ship_company = form.customer_company>
				<cfset form.customer_ship_address1 = form.customer_address1>
				<cfset form.customer_ship_address2 = form.customer_address2>
				<cfset form.customer_ship_city = form.customer_city>
				<cfset form.customer_ship_state = form.customer_billing_state>
				<cfset form.customer_ship_zip = form.customer_zip>
			</cfif>
		<!--- if logged in, run update instead of insert --->
		<cfif session.cwclient.cwCustomerID is not 0>
		<!--- skip duplicate check if accounts are not required, and not changing username or user type --->
		<cfif isDefined('application.cw.customerAccountRequired') and application.cw.customerAccountRequired eq false
				and form.customer_username eq session.cwclient.cwCustomerName
				and form.customer_type_id eq session.cwclient.cwCustomerType
				and form.customer_type_id neq 0>
			<cfset request.cwpage.dupCheck = false>
		<cfelse>
			<cfset request.cwpage.dupCheck = attributes.show_account_info>
		</cfif>
			<!--- /////// --->
			<!--- UPDATE CUSTOMER --->
			<!--- /////// --->
			<!--- QUERY: update customer record (all customer form variables) --->
			<cfset updateCustomerID = CWqueryUpdateCustomer(
				session.cwclient.cwCustomerID,
				form.customer_type_id,
				form.customer_first_name,
				form.customer_last_name,
				form.customer_email,
				form.customer_username,
				form.customer_password,
				form.customer_company,
				form.customer_phone,
				form.customer_phone_mobile,
				form.customer_address1,
				form.customer_address2,
				form.customer_city,
				form.customer_billing_state,
				form.customer_zip,
				form.customer_ship_name,
				form.customer_ship_company,
				form.customer_ship_address1,
				form.customer_ship_address2,
				form.customer_ship_city,
				form.customer_ship_state,
				form.customer_ship_zip,
				request.cwpage.dupCheck
				)>
			<!--- the query function above checks for duplicate fields,
			      if results starts with 0-, a dup field was found --->
			<cfif left(updateCustomerID,2) eq '0-'>
				<cfset dupField = listLast(updateCustomerID,'-')>
				<cfset CWpageMessage("alert","Error: #dupField# already exists")>
				<cfset request.cwpage.formErrors = listAppend(request.cwpage.formErrors,'customer_#dupField#')>
				<!--- no errors, update complete, return to page --->
			<cfelse>
				<cfset CWpageMessage("confirm","Customer Updated")>
				<!--- get region (stateprov) details --->
				<cfset customerTaxRegionQuery = CWquerySelectStateProvDetails(form.customer_billing_state)>
				<cfset customerShipRegionQuery = CWquerySelectStateProvDetails(form.customer_ship_state)>
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
				<cfset session.cwclient.cwCustomerName = trim(form.customer_username)>
				<cfset session.cwclient.cwCustomerType = trim(form.customer_type_id)>
				<!--- remove guest status if not on checkout page --->
				<cfif request.cw.thisPage neq listLast(request.cwpage.urlCheckout,'/')>
					<cfset session.cwclient.cwCustomerCheckout = 'account'>
				</cfif>
				<!--- reset ship total, since ship address may have changed --->
				<cfset session.cwclient.cwShipTotal = 0>
				<cflocation url="#attributes.success_url#" addtoken="no">
			</cfif>
			<!--- /END duplicate/error check --->
			<!--- /////// --->
			<!--- /END UPDATE CUSTOMER --->
			<!--- /////// --->
			<!--- if not logged in, add new customer --->
		<cfelse>
			<!--- /////// --->
			<!--- ADD NEW CUSTOMER --->
			<!--- /////// --->
			<!--- set boolean variable for customer guest yes/no --->
			<cfif session.cwclient.cwCustomerCheckout eq 'guest'>
				<cfset request.cwpage.customerGuest = 1>
			<cfelse>
				<cfset request.cwpage.customerGuest = 0>
			</cfif>
			<!--- QUERY: Add new customer (all customer form variables) --->
			<!--- this query returns the customer id, or an error like '0-fieldname' --->
			<cfset newCustomerID = CWqueryInsertCustomer(
									form.customer_type_id,
									form.customer_first_name,
									form.customer_last_name,
									form.customer_email,
									form.customer_username,
									form.customer_password,
									form.customer_company,
									form.customer_phone,
									form.customer_phone_mobile,
									form.customer_address1,
									form.customer_address2,
									form.customer_city,
									form.customer_billing_state,
									form.customer_zip,
									form.customer_ship_name,
									form.customer_ship_company,
									form.customer_ship_address1,
									form.customer_ship_address2,
									form.customer_ship_city,
									form.customer_ship_state,
									form.customer_ship_zip,
									request.cwpage.dupCheck,
									request.cwpage.customerGuest
									)>
			<!--- if no error returned from insert query --->
			<cfif not left(newCustomerID,2) eq '0-'>
				<!--- set client vars --->
				<cfset session.cwclient.cwCustomerID = newCustomerID>
				<cfif not request.cwpage.customerGuest eq 1>
					<cfset session.cwclient.cwCustomerType = form.customer_type_id>
				</cfif>
				<cfset session.cwclient.cwCustomerName = trim(form.customer_username)>
				<!--- get region (stateprov) details --->
				<cfset customerTaxRegionQuery = CWquerySelectStateProvDetails(form.customer_billing_state)>
				<cfset customerShipRegionQuery = CWquerySelectStateProvDetails(form.customer_ship_state)>
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
				<cfset session.cwclient.cwCustomerName = trim(form.customer_username)>
				<!--- update complete: return to page --->
				<cfset CWpageMessage("confirm","Customer Added")>
				<cflocation url="#attributes.success_url#" addtoken="no">
				<!--- if we have an insert error, show message, do not insert --->
			<cfelse>
				<cfset dupField = listLast(newCustomerID,'-')>
				<cfset CWpageMessage("alert","Error: #dupField# already exists")>
				<cfset request.cwpage.formErrors = listAppend(request.cwpage.formErrors,'customer_#dupField#')>
			</cfif>
			<!--- /END duplicate/error check --->
			<!--- /////// --->
			<!--- /END ADD NEW CUSTOMER --->
			<!--- /////// --->
		</cfif>
		<!--- /end if customer logged in --->
	</cfif>
	<!--- /end if no errors --->
</cfif>
<!--- /end if form submitted --->
<!--- QUERY: get customer details--->
<cfset customerQuery = CWquerySelectCustomerDetails(session.cwclient.cwCustomerID)>
<!--- QUERY: get customer's shipping info (customer id)--->
<cfset shippingQuery = CWquerySelectCustomerShipping(session.cwclient.cwCustomerID)>
<!--- QUERY: get all states / countries --->
<cfset statesQuery = CWquerySelectStates()>
<!--- setting this to 0 hides the customer types dropdown --->
<cfset typesQuery.recordCount = 0>
<!--- uncomment the line below, and remove the line above, to show customer type selection --->
<!--- QUERY: get all customer types --->
<!--- <cfset typesQuery = CWquerySelectCustomerTypes()> --->
<!--- params for all form fields - if new entry, customer query returns blank values for all fields --->
<cfif not isNumeric(customerQuery.customer_type_id)>
	<cfset customer_type = 1>
<cfelse>
	<cfset customer_type = customerQuery.customer_type_id>
</cfif>
<cfparam name="form.customer_type_id" default="#customer_type#">
<cfparam name="form.customer_first_name" default="#customerQuery.customer_first_name#">
<cfparam name="form.customer_last_name" default="#customerQuery.customer_last_name#">
<cfparam name="form.customer_email" default="#customerQuery.customer_email#">
<cfparam name="form.customer_username" default="#customerQuery.customer_username#">
<cfparam name="form.customer_password" default="#customerQuery.customer_password#">
<cfparam name="form.customer_password2" default="#customerQuery.customer_password#">
<cfparam name="form.customer_company" default="#customerQuery.customer_company#">
<cfparam name="form.customer_phone" default="#customerQuery.customer_phone#">
<cfparam name="form.customer_phone_mobile" default="#customerQuery.customer_phone_mobile#">
<cfparam name="form.customer_address1" default="#customerQuery.customer_address1#">
<cfparam name="form.customer_address2" default="#customerQuery.customer_address2#">
<cfparam name="form.customer_city" default="#customerQuery.customer_city#">
<cfparam name="form.customer_billing_state" default="#customerQuery.stateprov_id#">
<cfparam name="form.customer_billing_country_id" default="#customerQuery.country_id#">
<cfparam name="form.customer_zip" default="#customerQuery.customer_zip#">
<cfparam name="form.customer_ship_name" default="#customerQuery.customer_ship_name#">
<cfparam name="form.customer_ship_company" default="#customerQuery.customer_ship_company#">
<cfparam name="form.customer_ship_address1" default="#customerQuery.customer_ship_address1#">
<cfparam name="form.customer_ship_address2" default="#customerQuery.customer_ship_address2#">
<cfparam name="form.customer_ship_city" default="#customerQuery.customer_ship_city#">
<cfparam name="form.customer_ship_state" default="#shippingQuery.stateprov_id#">
<cfparam name="form.customer_ship_country_id" default="#shippingQuery.country_id#">
<cfparam name="form.customer_ship_zip" default="#customerQuery.customer_ship_zip#">
<!--- determine selected country if using split country/state lists --->
<cfif form.customer_billing_country_id gt 0>
	<cfset request.cwpage.selectedCountry = form.customer_billing_country_id>
<cfelseif isDefined('application.cw.defaultCountryID') and application.cw.defaultCountryID gt 0>
	<cfset request.cwpage.selectedCountry = application.cw.defaultCountryID>
<cfelse>
	<cfset request.cwpage.selectedCountry = 0>
</cfif>
<!--- selected shipping country --->
<cfif form.customer_ship_country_id gt 0>
	<cfset request.cwpage.selectedShipCountry = form.customer_ship_country_id>
<cfelseif isDefined('application.cw.defaultCountryID') and application.cw.defaultCountryID gt 0>
	<cfset request.cwpage.selectedShipCountry = application.cw.defaultCountryID>
<cfelseif isDefined('request.cwpage.selectedCountry') and request.cwpage.selectedCountry gt 0>
	<cfset request.cwpage.selectedShipCountry = 0>
</cfif>
<!--- javascript for form, includes 'same as billing' checkbox function --->
<cfif not isDefined('request.cwpage.customerFormScript')>
	<cfsavecontent variable="request.cwpage.customerFormScript">
		<script type="text/javascript">
		jQuery(document).ready(function(){
			<cfif request.cwpage.shipDisplayInfo eq true>
			// reset list of shipping states from reserve element
			var $resetShipState = function(){
				jQuery('#customer_ship_state').remove();
				jQuery('#customer_ship_state_reserve').clone(true).show().insertBefore('#customer_ship_state_reserve').attr('name','customer_ship_state').attr('id','customer_ship_state');
			};
			// copy billing info to shipping
			jQuery('span#sameAs').show();
			jQuery('#copyInfo').click(function(){
			// if checking the box
			if (jQuery(this).prop('checked')==true){
				// get values of shipping
				var valName = jQuery('#customer_first_name').val() + ' ' + jQuery('#customer_last_name').val();
				var valCo = jQuery('#customer_company').val();
				var valAddr1 = jQuery('#customer_address1').val();
				var valAddr2 = jQuery('#customer_address2').val();
				var valCity = jQuery('#customer_city').val();
				var valCountry = jQuery('#customer_billing_country_id').val();
				var valState = jQuery('#customer_billing_state').val();
				var valZip = jQuery('#customer_zip').val();
				var valCountryText = jQuery('#CWcustomerBillingCountry').text();
				// copy to billing, remove functionality
				jQuery('#customer_ship_name').val(valName).attr('readonly','readonly').addClass('inputNull');
				jQuery('#customer_ship_company').val(valCo).attr('readonly','readonly').addClass('inputNull');
				jQuery('#customer_ship_address1').val(valAddr1).attr('readonly','readonly').addClass('inputNull');
				jQuery('#customer_ship_address2').val(valAddr2).attr('readonly','readonly').addClass('inputNull');
				jQuery('#customer_ship_city').val(valCity).attr('readonly','readonly').addClass('inputNull');
				jQuery('#customer_ship_zip').val(valZip).attr('readonly','readonly').addClass('inputNull');
				jQuery('#CWcustomerShippingCountry').text(valCountryText);
				// remove remaining state dropdown options
				<cfif request.cwpage.stateSelectType is 'split'>
					$resetShipState();
					jQuery('#customer_ship_country_id').val(valCountry).attr('readonly','readonly').addClass('inputNull').trigger('change');
				<cfelse>
					jQuery('#customer_ship_state').clone(true).hide().insertAfter('#customer_ship_state').attr('name','customer_ship_state_reserve').attr('id','customer_ship_state_reserve');
					jQuery('#customer_ship_country_id').val(valCountry).attr('readonly','readonly').addClass('inputNull');
					jQuery('#customer_ship_state').val(valState).find('option').not(':selected').remove();
					jQuery('#customer_ship_state option').unwrap();
					jQuery('#customer_ship_state optgroup').remove();
				</cfif>
					jQuery('#customer_ship_state').val(valState).attr('readonly','readonly').addClass('inputNull');
				// if the box is NOT checked
				} else {
				// restore functionality
				jQuery(this).parents('table').find('.inputNull').removeAttr('readonly').removeClass('inputNull');
				// restore original dropdown
				$resetShipState();
				var valState = jQuery('#customer_billing_state').val();
				jQuery('#customer_ship_state').val(valState);
				<cfif request.cwpage.stateSelectType is 'split'>
				$setShipState();
				</cfif>
			}
			});
			// monitor changes after same as billing box checked
			var $copyData = function(billField,shipField){
				if (jQuery('#copyInfo').prop('checked')==true){
					var billVal = jQuery(billField).val();
					jQuery(shipField).val(billVal);
				}
			};
				jQuery('#customer_company').keyup(function(){
					$copyData(this,'#customer_ship_company');
				});
				jQuery('#customer_address1').keyup(function(){
					$copyData(this,'#customer_ship_address1');
				});
				jQuery('#customer_address2').keyup(function(){
					$copyData(this,'#customer_ship_address2');
				});
				jQuery('#customer_city').keyup(function(){
					$copyData(this,'#customer_ship_city');
				});
				jQuery('#customer_billing_state').keyup(function(){
					$copyData(this,'#customer_ship_state');
				});
				jQuery('#customer_zip').keyup(function(){
					$copyData(this,'#customer_ship_zip');
				});
				// name gets special treatment
				jQuery('#customer_first_name').keyup(function(){
					if (jQuery('#copyInfo').prop('checked')==true){
						var valName = jQuery('#customer_first_name').val() + ' ' + jQuery('#customer_last_name').val();
						jQuery('#customer_ship_name').val(valName);
					}
				});
				jQuery('#customer_last_name').keyup(function(){
					if (jQuery('#copyInfo').prop('checked')==true){
						var valName = jQuery('#customer_first_name').val() + ' ' + jQuery('#customer_last_name').val();
						jQuery('#customer_ship_name').val(valName);
					}
				});
				// state dropdown
					<cfif request.cwpage.stateSelectType is 'split'>
						var $setShipState = function(){
							var valState = jQuery('#customer_billing_state').val();
							var valCountry = jQuery('#customer_ship_country_id').val();
							var keepClass = 'optCS-' + valCountry;
							jQuery('#customer_ship_state').find('option').not('.' + keepClass).remove();
							if (jQuery('#copyInfo').prop('checked')==true){
								$resetShipState();
								jQuery('#customer_ship_state').val(valState).attr('readonly','readonly').addClass('inputNull');
							}
						};
						jQuery('#customer_ship_country_id').change(function(){
								var countryID = jQuery(this).val();
								var keepClass = 'optCS-' + countryID;
								$resetShipState();
								jQuery('#customer_ship_state').find('option').not('.' + keepClass).remove();
								if (jQuery('#copyInfo').prop('checked')==true){
									jQuery('#customer_ship_state').attr('readonly','readonly').addClass('inputNull');
								}
						});
						jQuery('#customer_billing_state').change(function(){
							$setShipState();
						});
						jQuery('#customer_billing_state_reserve').change(function(){
							$setShipState();
						});
					<cfelse>
						// state dropdown
						jQuery('#customer_billing_state').change(function(){
							var countryText = jQuery('#customer_billing_state option:selected').parents('optgroup').attr('label');
							jQuery('#CWcustomerBillingCountry').text(countryText);
							if (jQuery('#copyInfo').prop('checked')==true){
								jQuery('#customer_ship_state').remove();
								jQuery('#customer_ship_state_reserve').clone(true).show().insertBefore('#customer_ship_state_reserve').attr('name','customer_ship_state').attr('id','customer_ship_state');
								var valState = jQuery('#customer_billing_state').val();
								jQuery('#customer_ship_state').val(valState).attr('readonly','readonly').addClass('inputNull').find('option').not(':selected').remove();
								jQuery('#customer_ship_state option').unwrap();
								jQuery('#customer_ship_state optgroup').remove();
								jQuery('#CWcustomerShippingCountry').text(countryText);
							}
						});
						jQuery('#customer_ship_state').change(function(){
							var countryText = jQuery('#customer_ship_state option:selected').parents('optgroup').attr('label');
							jQuery('#CWcustomerShippingCountry').text(countryText);
						});

					</cfif>
					<!--- /end if split or single country list --->
				</cfif>
				<!--- /end if shipping shown --->
				<cfif request.cwpage.stateSelectType is 'split'>
					jQuery('#customer_billing_country_id').change(function(){
						var countryID = jQuery(this).find('option:selected').attr('value');
						var keepClass = 'optCB-' + countryID;
						var valState = jQuery('#customer_billing_state').val();
						jQuery('#customer_billing_state').remove();
						jQuery('#customer_billing_state_reserve').clone(true).show().insertBefore('#customer_billing_state_reserve').attr('name','customer_billing_state').attr('id','customer_billing_state');
						jQuery('#customer_billing_state').find('option').not('.' + keepClass).remove();
						if (jQuery('#copyInfo').prop('checked')==true){
							jQuery('#customer_ship_country_id').val(countryID).trigger('change');
							jQuery('#customer_ship_state').val(valState);
						};
					});
				</cfif>
			// show submit link instead of button
			jQuery('#customer_submit').hide();
			jQuery('#CWlinkCustomer').show().click(function(){
				jQuery('form#CWformCustomer').submit();
				return false;
			});
		});
		</script>
</cfsavecontent>
	<cfhtmlhead text="#request.cwpage.customerFormScript#">
</cfif>
</cfsilent>
<!--- //////////// --->
<!--- START OUTPUT --->
<!--- //////////// --->
<form class="CWvalidate" id="CWformCustomer" name="CWformCustomer" method="post" action="<cfoutput>#attributes.form_action#</cfoutput>">
<!--- ALERTS: capture any customer form errors --->
<cfif len(trim(request.cwpage.formErrors))>
	<div class="CWalertBox validationAlert" id="customerFormAlert">
		<!--- if form errors exist, but other alerts do not, show default alert --->
		<cfif  not isArray(request.cwpage.userAlert)
			OR arrayLen(request.cwpage.userAlert) eq 0
			OR (isArray(request.cwpage.userAlert) AND arrayLen(request.cwpage.userAlert) eq 1 AND request.cwpage.userAlert[1] eq '') >
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
	</div>
</cfif>
<!--- customer details table --->
<table class="CWformTable">
	<tr>
		<td class="customerInfo" id="contactCell" colspan="2">
			<!--- contact details --->
			<table class="CWformTable">
				<tr class="headerRow">
					<th colspan="2"><h3>Contact Details</h3></th>
				</tr>
				<tr>
					<th class="label required">First Name</th>
					<td>
						<input name="customer_first_name" class="{required:true}<cfif request.cwpage.formErrors contains 'customer_first_name'> warning</cfif>" title="First Name is required" size="20" maxlength="254" type="text" id="customer_first_name" value="<cfoutput>#form.customer_first_name#</cfoutput>">
					</td>
				</tr>
				<tr>
					<th class="label required">Last Name</th>
					<td>
						<input name="customer_last_name" class="{required:true}<cfif request.cwpage.formErrors contains 'customer_last_name'> warning</cfif>" title="Last Name is required" size="20" maxlength="254" type="text" id="customer_last_name" value="<cfoutput>#form.customer_last_name#</cfoutput>">
					</td>
				</tr>
				<tr>
					<th class="label required">Email</th>
					<td>
						<input type="text" class="{required:true,email:true}<cfif request.cwpage.formErrors contains 'customer_email'> warning</cfif>" title="Valid Email is required"  size="20" maxlength="254" name="customer_email" id="customer_email" value="<cfoutput>#form.customer_email#</cfoutput>">
					</td>
				</tr>
				<tr>
					<th class="label required">Phone</th>
					<td>
						<input type="text" class="{required:true}<cfif request.cwpage.formErrors contains 'customer_phone'> warning</cfif>" title="Phone Number is required" size="14" maxlength="20" name="customer_phone" id="customer_phone" value="<cfoutput>#form.customer_phone#</cfoutput>">
					</td>
				</tr>
				<tr>
					<th class="label">Mobile</th>
					<td>
						<input type="text" size="14" maxlength="14" name="customer_phone_mobile" id="customer_phone_mobile" value="<cfoutput>#form.customer_phone_mobile#</cfoutput>">
					</td>
				</tr>
			</table>
			<!--- /end contact details --->
			<!--- username / password --->
			<cfif attributes.show_account_info>
				<table class="CWformTable" id="customerAccount">
					<tr class="headerRow">
						<th colspan="2"><h3>Customer Account</h3></th>
					</tr>
					<!--- if we have more than one type, show the selector --->
					<cfif typesQuery.recordCount gt 1>
						<tr>
							<th class="label">Customer Type</th>
							<td>
								<select name="customer_type_id" id="customer_type_id">
									<cfoutput query="typesQuery">
										<option value="#customer_type_id#"<cfif typesQuery.customer_type_id eq form.customer_type_id> selected="selected"</cfif>>#customer_type_name#</option>
									</cfoutput>
								</select>
							</td>
						</tr>
						<!--- if only one type exists, use this by default --->
					<cfelse>
						<input type="hidden" name="customer_type_id" id="customer_type_id" value="<cfoutput>#form.customer_type_id#</cfoutput>">
					</cfif>
					<!--- /end customer type --->
					<tr>
						<th class="label required">Username</th>
						<td>
							<input name="customer_username" class="{required:true,minlength:6}<cfif request.cwpage.formErrors contains 'customer_username'> warning</cfif>" title="Username is required (min. length 6)" size="20" maxlength="254" type="text" id="customer_username" value="<cfoutput>#form.customer_username#</cfoutput>">
							<span class="smallPrint">&nbsp;&nbsp;(min. 6)</span>
						</td>
					</tr>
					<tr>
						<th class="label required">Password</th>
						<td>
							<input name="customer_password" class="{required:true,minlength:6}<cfif request.cwpage.formErrors contains 'customer_password'> warning</cfif>" title="Password is required (min. length 6)" size="20" maxlength="254" type="password" id="customer_password" value="<cfoutput>#form.customer_password#</cfoutput>">
							<span class="smallPrint">&nbsp;&nbsp;(min. 6)</span>
						</td>
					</tr>
					<tr>
						<th class="label required">Confirm Password</th>
						<td>
							<input name="customer_password2" class="{required:true,equalTo:'#customer_password'}<cfif request.cwpage.formErrors contains 'customer_password2'> warning</cfif>" title="Password must match" size="20" maxlength="254" type="password" id="customer_password2" value="<cfoutput>#form.customer_password2#</cfoutput>">
						</td>
					</tr>
				</table>
			<cfelse>
				<!--- if account info is not shown, use hidden fields --->
				<div<cfif request.cwpage.shipDisplayInfo> style="padding-top:135px;"</cfif> class="clear">
					<!--- hidden inputs --->
					<input name="customer_username" type="hidden" id="customer_username_hidden" value="<cfoutput>#form.customer_username#</cfoutput>">
					<input name="customer_password" type="hidden" id="customer_password_hidden" value="<cfoutput>#form.customer_password#</cfoutput>">
					<input name="customer_password2" type="hidden" id="customer_password2_hidden" value="<cfoutput>#form.customer_password2#</cfoutput>">
					<input type="hidden" name="customer_type_id" id="customer_type_id" value="<cfoutput>#form.customer_type_id#</cfoutput>">
				</div>
			</cfif>
			<!--- /end username/pw --->
			<!--- SUBMIT BUTTON --->
			<div class="CWclear">
			</div>
			<div class="center top40">
				<input id="customer_submit" name="customer_submit" type="submit" class="CWformButton" value="<cfoutput>#attributes.submit_value#</cfoutput>">
				<!--- submit link : javascript replaces button with this link --->
				<a style="display:none;" href="#" class="CWcheckoutLink" id="CWlinkCustomer"><cfoutput>#attributes.submit_value#</cfoutput></a>
			</div>
		</td>
		<td class="customerInfo" id="shippingCell" colspan="2">
			<!--- billing info --->
			<table class="CWformTable">
				<tr class="headerRow">
					<th colspan="2"><h3>Billing Information</h3></th>
				</tr>
				<tr>
					<th class="label">Company</th>
					<td>
						<input type="text" size="20" maxlength="254" name="customer_company" id="customer_company" value="<cfoutput>#form.customer_company#</cfoutput>">
					</td>
				</tr>
				<tr>
					<th class="label required">Address</th>
					<td>
						<input type="text" class="{required:true}<cfif request.cwpage.formErrors contains 'customer_address1'> warning</cfif>" size="20" maxlength="254" title="Billing Address is required"  name="customer_address1" id="customer_address1" value="<cfoutput>#form.customer_address1#</cfoutput>">
						<br>
						<br>
						<input type="text" name="customer_address2" size="20" maxlength="254" id="customer_address2" value="<cfoutput>#form.customer_address2#</cfoutput>">
					</td>
				</tr>
				<tr>
					<th class="label required">City</th>
					<td>
						<input type="text" name="customer_city" size="20" maxlength="254" id="customer_city" class="{required:true}<cfif request.cwpage.formErrors contains 'customer_city'> warning</cfif>" title="Billing City is required" value="<cfoutput>#form.customer_city#</cfoutput>">
					</td>
				</tr>
				<!--- country/state separated --->
				<cfif request.cwpage.stateSelectType is 'split'>
					<tr>
						<th class="label required">Country</th>
						<td>
							<!--- country value for selection of stateprov below, not individually validated or inserted --->
							<select name="customer_billing_country_id" id="customer_billing_country_id"<cfif request.cwpage.formErrors contains 'customer_billing_state'>	class="warning"</cfif>>
							<cfoutput query="statesQuery" group="country_name">
								<option value="#country_id#"<cfif request.cwpage.selectedCountry eq country_id> selected="selected"</cfif>>#country_name#</option>
							</cfoutput>
							</select>
						</td>
					</tr>
					<tr>
						<th class="label required">State/Prov</th>
						<td>
							<!--- customer state, restricted by country --->
							<select name="customer_billing_state" id="customer_billing_state"<cfif request.cwpage.formErrors contains 'customer_billing_state'>	class="warning"</cfif>>
							<cfoutput query="statesQuery" group="country_name">
									<cfoutput>
										<cfif request.cwpage.selectedCountry neq 0 and statesQuery.country_id eq request.cwpage.selectedCountry>
											<option value="#stateprov_id#"<cfif statesQuery.stateprov_id eq customerQuery.stateprov_id OR statesQuery.stateprov_id eq form.customer_billing_state> selected="selected"</cfif>>#left(stateprov_name,35)#</option>
										</cfif>
									</cfoutput>
									<!--- default for selection --->
									<cfif request.cwpage.selectedCountry eq 0>
										<option value="" selected="selected">--</option>
									</cfif>
							</cfoutput>
							</select>
							<!--- hidden element used for jQuery DOM manipulation --->
							<select name="" style="display:none;" id="customer_billing_state_reserve">
							<cfoutput query="statesQuery" group="country_id">
									<cfoutput>
										<option class="optCB-#country_id#" value="#stateprov_id#">#left(stateprov_name,35)#</option>
									</cfoutput>
							</cfoutput>
							</select>
						</td>
					</tr>
				<!--- single list country/state output --->
				<cfelse>
					<tr>
						<th class="label required">State/Prov</th>
						<td>
							<select name="customer_billing_state" id="customer_billing_state"<cfif request.cwpage.formErrors contains 'customer_billing_state'>	class="warning"</cfif>>
							<cfoutput query="statesQuery" group="country_name">
								<optgroup label="#country_name#">
									<cfoutput>
										<option value="#stateprov_id#"<cfif statesQuery.stateprov_id eq customerQuery.stateprov_id OR statesQuery.stateprov_id eq form.customer_billing_state> selected="selected"</cfif>>#left(stateprov_name,35)#</option>
									</cfoutput>
								</optgroup>
							</cfoutput>
							</select>
						</td>
					</tr>
					<!--- only show country if a saved record exists --->
					<cfif customerQuery.recordCount>
						<tr>
							<th class="label required">Country</th>
							<td class="CWtextCell">
								<span id="CWcustomerBillingCountry"><cfoutput>#customerQuery.country_name#</cfoutput></span>
							</td>
						</tr>
					</cfif>
					<!--- /end country --->
				</cfif>
				<!--- /end separated or single lists --->
				<tr>
					<th class="label required">Post Code/Zip</th>
					<td>
						<input type="text" name="customer_zip" id="customer_zip" class="{required:true}<cfif request.cwpage.formErrors contains 'customer_zip'> warning</cfif>" title="Billing Post Code is required" value="<cfoutput>#form.customer_zip#</cfoutput>" size="8" maxlength="20">
					</td>
				</tr>
			</table>
			<!--- /end billing info --->
			<!--- shipping info --->
			<cfif request.cwpage.shipDisplayInfo>
				<table class="CWformTable">
					<tr class="headerRow">
						<th colspan="2">
							<h3>
								Shipping Information
								<!--- the same-as checkbox is hidden unless javascript enabled --->
								<span class="smallPrint" id="sameAs" style="display:none;"><input type="checkbox" id="copyInfo">&nbsp;Same as Billing</span>
							</h3>
						</th>
					</tr>
					<tr>
						<th class="label required">Ship To (Name)</th>
						<td>
							<input name="customer_ship_name" id="customer_ship_name" class="{required:true}<cfif request.cwpage.formErrors contains 'customer_ship_name'> warning</cfif>" title="Ship To (name) is required" type="text" size="20" maxlength="254" value="<cfoutput>#form.customer_ship_name#</cfoutput>">
						</td>
					</tr>
					<tr>
						<th class="label">Company</th>
						<td>
							<input type="text" size="20" maxlength="254" name="customer_ship_company" id="customer_ship_company" value="<cfoutput>#form.customer_ship_company#</cfoutput>">
						</td>
					</tr>
					<tr>
						<th class="label required">Address</th>
						<td>
							<input type="text" name="customer_ship_address1" id="customer_ship_address1" class="{required:true}<cfif request.cwpage.formErrors contains 'customer_ship_address1'> warning</cfif>" size="20" maxlength="254" title="Shipping Address is required" value="<cfoutput>#form.customer_ship_address1#</cfoutput>">
							<br>
							<br>
							<input type="text" name="customer_ship_address2" id="customer_ship_address2" size="20" maxlength="254" value="<cfoutput>#form.customer_ship_address2#</cfoutput>">
						</td>
					</tr>
					<tr>
						<th class="label required">City</th>
						<td>
							<input type="text" name="customer_ship_city" id="customer_ship_city" class="{required:true}<cfif request.cwpage.formErrors contains 'customer_ship_city'> warning</cfif>" size="20" maxlength="254" title="Shipping City is required" value="<cfoutput>#form.customer_ship_city#</cfoutput>">
						</td>
					</tr>
					<!--- country/state separated --->
					<cfif request.cwpage.stateSelectType is 'split'>
						<tr>
							<th class="label required">Country</th>
							<td>
								<!--- country value for selection of stateprov below, not individually validated or inserted --->
								<select name="customer_ship_country_id" id="customer_ship_country_id"<cfif request.cwpage.formErrors contains 'customer_ship_state'> class="warning"</cfif>>
								<cfoutput query="statesQuery" group="country_name">
									<option value="#country_id#"<cfif request.cwpage.selectedShipCountry eq country_id> selected="selected"</cfif>>#country_name#</option>
								</cfoutput>
								</select>
							</td>
						</tr>
						<tr>
							<th class="label required">State/Prov</th>
							<td>
								<!--- customer state, restricted by country --->
								<select name="customer_ship_state" id="customer_ship_state"<cfif request.cwpage.formErrors contains 'customer_ship_state'> class="warning"</cfif>>
								<cfoutput query="statesQuery" group="country_name">
									<cfoutput>
										<cfif request.cwpage.selectedShipCountry neq 0 and statesQuery.country_id eq request.cwpage.selectedShipCountry>
											<option class="optCS-#country_id#" value="#stateprov_id#"<cfif statesQuery.stateprov_id eq shippingQuery.stateprov_id OR statesQuery.stateprov_id eq form.customer_ship_state> selected="selected"</cfif>>#left(stateprov_name,35)#</option>
										</cfif>
									</cfoutput>
									<!--- default for selection --->
									<cfif request.cwpage.selectedShipCountry eq 0>
										<option value="" selected="selected">--</option>
									</cfif>
								</cfoutput>
								</select>
								<!--- hidden element used for jQuery DOM manipulation --->
								<select name="" style="display:none;" id="customer_ship_state_reserve">
								<cfoutput query="statesQuery" group="country_id">
									<cfoutput>
										<option class="optCS-#country_id#" value="#stateprov_id#">#left(stateprov_name,35)#</option>
									</cfoutput>
								</cfoutput>
								</select>
							</td>
						</tr>
					<!--- single list country/state output --->
					<cfelse>
						<tr>
							<th class="label required">State/Prov</th>
							<td>
								<select name="customer_ship_state" id="customer_ship_state"<cfif request.cwpage.formErrors contains 'customer_ship_state'> class="warning"</cfif>>
								<cfoutput query="statesQuery" group="country_name">
									<optgroup label="#country_name#">
										<cfoutput>
											<option value="#stateprov_id#"<cfif statesQuery.stateprov_id eq shippingQuery.stateprov_id OR statesQuery.stateprov_id eq form.customer_ship_state> selected="selected"</cfif>>#left(stateprov_name,35)#</option>
										</cfoutput>
									</optgroup>
								</cfoutput>
								</select>
							</td>
						</tr>
						<!--- only show country if a saved record exists --->
						<cfif shippingQuery.recordCount>
							<tr>
								<th class="label required">Country</th>
								<td class="CWtextCell">
									<span id="CWcustomerShippingCountry"><cfoutput>#shippingQuery.country_name#</cfoutput></span>
								</td>
							</tr>
						</cfif>
						<!--- /end country --->
					</cfif>
					<!--- /end separated or single lists --->
					<tr>
						<th class="label required">Post Code/Zip</th>
						<td>
							<input type="text" name="customer_ship_zip" id="customer_ship_zip" class="{required:true}<cfif request.cwpage.formErrors contains 'customer_ship_zip'> warning</cfif>" title="Shipping Post Code is required"value="<cfoutput>#form.customer_ship_zip#</cfoutput>" size="8" maxlength="20">
						</td>
					</tr>
				</table>
			</cfif>
			<!--- /end if displaying shipping info --->
		</td>
		<!--- /END cutomer address info --->
	</tr>
	<!--- /END billing shipping --->
</table>
<div class="CWclear"></div>
</form>