<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-functions.cfm
File Date: 2012-07-20
Description: includes all required functions for cartweaver pages
NOTE: more may be inserted, do not change the order of the default included function files
==========================================================
--->
<cftry>
	<!--- init functions --->
	<cfif not isDefined('variables.CWinitRequest')>
		<cfinclude template="../func/cw-func-init.cfm">
	</cfif>
	<!--- global functions--->
	<cfif not isDefined('variables.CWtime')>
		<cfinclude template="../func/cw-func-global.cfm">
	</cfif>
	<!--- global queries--->
	<cfif not isDefined('variables.CWquerySelectProductDetails')>
		<cfinclude template="../func/cw-func-query.cfm">
	</cfif>
	<!--- shipping functions--->
	<cfif not isDefined('variables.CWgetShipRate')>
		<cfinclude template="../func/cw-func-shipping.cfm">
	</cfif>
	<!--- tax functions--->
	<cfif not isDefined('variables.CWgetShipTax')>
		<cfinclude template="../func/cw-func-tax.cfm">
	</cfif>
	<!--- cart functions--->
	<cfif not isDefined('variables.CWgetCart')>
		<cfinclude template="../func/cw-func-cart.cfm">
	</cfif>
	<!--- product functions--->
	<cfif not isDefined('variables.CWgetProduct')>
		<cfinclude template="../func/cw-func-product.cfm">
	</cfif>
	<!--- order functions --->
	<cfif not isDefined('variables.CWsaveOrder')>
		<cfinclude template="../func/cw-func-order.cfm">
	</cfif>
	<!--- discount functions --->
	<cfif not isDefined('variables.CWgetSkuDiscountData')>
		<cfinclude template="../func/cw-func-discount.cfm">
	</cfif>
	<!--- customer functions--->
	<cfif not isDefined('variables.CWgetCustomer')>
		<cfinclude template="../func/cw-func-customer.cfm">
	</cfif>
	<!--- mail functions --->
	<cfif not isDefined('variables.CWsendMail')>
		<cfinclude template="../func/cw-func-mail.cfm">
	</cfif>
	<!--- download functions --->
	<cfif not isDefined('variables.CWcreateDownloadURL')>
		<cfinclude template="../func/cw-func-download.cfm">
	</cfif>
<cfcatch>
<cfset request.cwpage.functionError = 'Functions Error: ' & cfcatch.message>
</cfcatch>
</cftry>
</cfsilent>
<!--- show error if any exists --->
<cfif isDefined('request.cwpage.functionError')>
<cfoutput>#request.cwpage.functionError#</cfoutput>
<cfabort>
</cfif>