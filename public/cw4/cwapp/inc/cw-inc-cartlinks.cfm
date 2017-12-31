<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-cartlinks.cfm
File Date: 2012-09-10
Description: shows cart and customer account links on cart-related pages
NOTES:
cw-mod-customerlinks is called twice with varying options to
create the left/ right link grouping. This can be modified at will.
The returnUrl attribute is passed through to the cart,
for continue shopping link on cart page.
==========================================================
--->
</cfsilent>
<div class="CWcartInfo CWcontent">
<br />
<br /><br />
	<!--- if order has been placed, but not cleared from client scope,
		  hide cart/customer links on processing pages --->
	<cfif NOT (
				(request.cw.thisPage eq listLast(request.cwpage.urlCheckout,'/') or request.cw.thisPage eq listLast(request.cwpage.urlConfirmOrder,'/'))
				AND isDefined('session.cwclient.cwCompleteOrderID')
				AND session.cwclient.cwCompleteOrderID neq '0'
			)>
			<!--- determine whether cart total includes tax --->
			<cfif application.cw.taxDisplayOnProduct>
				<cfset request.cwpage.totals_tax_type = application.cw.taxCalctype>
			<cfelse>
				<cfset request.cwpage.totals_tax_type = 'none'>
			</cfif>
			<!--- cart links --->
			<cfmodule template="../mod/cw-mod-customerlinks.cfm"
					  return_url="#request.cwpage.returnUrl#"
					  show_item_count="true"
					  show_cart_total="true"
					  show_view_cart="true"
					  show_loggedinas="false"
					  show_account="false"
					  show_checkout="true"
					  element_id="CWcartLinks"
					  tax_calc_method="#request.cwpage.totals_tax_type#"
					  	>
			<!--- log in / logged in as - not shown on confirmation page --->
			<cfif application.cw.customerAccountEnabled
			AND NOT request.cw.thisPage eq listLast(request.cwpage.urlConfirmOrder,'/')>
				<cfmodule template="../mod/cw-mod-customerlinks.cfm"
						  show_login="true"
						  show_logout="true"
						  logout_url="#request.cwpage.logoutUrl#"
						  show_loggedinas="true"
					      show_account="true"
						  element_id="CWaccountLinks"
						  	>
			</cfif>
	<!--- message for checkout page --->
	<cfelseif request.cw.thisPage eq listLast(request.cwpage.urlCheckout,'/')>
		<p>Additional information or payment may be required. Complete the checkout process below</p>
	<cfelseif request.cw.thisPage eq listLast(request.cwpage.urlConfirmOrder,'/')>
		<!--- message for confirmation page may be shown here --->
	</cfif>
	<!--- /end hide content --->
	<div class="CWclear"></div>
</div>