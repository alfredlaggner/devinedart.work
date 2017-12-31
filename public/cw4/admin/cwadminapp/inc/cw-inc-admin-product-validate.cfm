<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-product-validate.cfm
File Date: 2012-02-01
Description: Here we validate the data submitted in the product form.
If the data fits the required parameters we send continue on with
the transaction. If not we halt the transaction and pass back error
messages to be displayed by the calling template.
==========================================================
--->
<cfinclude template="../func/cw-func-admin.cfm">
<!--- We either updated or added a new product --->
<cfif IsDefined("form.action")>
	<cfif form.action eq "AddProduct" AND form.product_merchant_product_id eq "">
		<cfset request.cwpage.addProductError = ListAppend(request.cwpage.addProductError,"Product ID is required")>
	</cfif>
	<cfif form.product_name eq "">
		<cfset request.cwpage.addProductError = ListAppend(request.cwpage.addProductError,"Product Name is required")>
	</cfif>
	<cfif NOT IsNumeric(form.product_sort)>
		<cfset form.product_sort = 0>
		<cfset request.cwpage.addProductError = ListAppend(request.cwpage.addProductError,"Sort Order must be numeric")>
	</cfif>
	<cfif len(trim(request.cwpage.addProductError))>
		<cfloop list="#request.cwpage.addProductError#" index="ll">
			<cfset CWpageMessage("alert",ll)>
		</cfloop>
	</cfif>
</cfif>
<!--- If we're adding a new sku --->
<cfif IsDefined("form.addSKU")>
	<cfif form.sku_merchant_sku_id eq "">
		<cfset request.cwpage.addSKUError = ListAppend(request.cwpage.addSKUError,"SKU Name is required")>
	</cfif>
	<cfif NOT IsNumeric(form.sku_price)>
		<cfset request.cwpage.addSKUError = ListAppend(request.cwpage.addSKUError,"Valid Price is required")>
	</cfif>
	<cfif NOT IsNumeric(form.sku_ship_base)>
		<cfset request.cwpage.addSKUError = ListAppend(request.cwpage.addSKUError,"Ship Base must be numeric")>
	</cfif>
	<cfif NOT IsNumeric(form.sku_sort)>
		<cfset form.sku_sort = 0>
		<cfset request.cwpage.addSKUError = ListAppend(request.cwpage.addSKUError,"SKU Sort Order must be numeric")>
	</cfif>
	<cfif NOT IsNumeric(form.sku_weight)>
		<cfset form.sku_weight = 0>
		<cfset request.cwpage.addSKUError = ListAppend(request.cwpage.addSKUError,"SKU Weight must be numeric")>
	</cfif>
	<cfif NOT IsNumeric(form.sku_stock)>
		<cfset form.sku_stock = 0>
		<cfset request.cwpage.addSKUError = ListAppend(request.cwpage.addSKUError,"SKU Stock must be numeric")>
	</cfif>
	<cfif len(trim(request.cwpage.addSKUError))>
		<cfloop list="#request.cwpage.addSKUError#" index="ll">
			<cfset CWpageMessage("alert",ll)>
		</cfloop>
	</cfif>
</cfif>
</cfsilent>