<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-mod-cartweaver.cfm
File Date: 2012-09-05
Description: creates the cart and handles all product interaction

NOTES:
Pass in a product ID and structure of form variables,
with optional cart_action for update / delete
All logic for cart interaction is handled internally.
Line items in the cart are kept separate based on the unique ID,
which is made up of sku id and custom data ID (for personalization / custom info option).
If no custom data is provided, the sku ID is used for the unique ID.
// DEPENDENCIES
- uses query functions found in cw-func-cart.cfm
these query functions pass back record IDs and/or error messages
which are used to show the response to the customer
// ATTRIBUTES
- product_id: required for 'add' via selected options or table view.
integer ID of product to manage.
not required if sku_id is provided
- form_values: required if sku_id and sku_qty not provided.
structure of form values from 'add to cart' form,
or any struct with same variable names and values
- cart_action: optional. (add | update | delete) default is 'add'.
*	add (default): Add a SKU and quantity to the cart by passing in a structure
of form values or a sku_id and sku_qty (or lists of ids and quantities)
*	update: Update a SKU to a specific quantity in the cart as
defined by the sku_unique_id and sku_qty attributes. The sku_id is
required for the update action. Setting the quantity to 0 will
delete an item from the cart.
*	delete: Delete a SKU from the cart as defined by the sku_unique_id
attribute. The sku_unique_id is required for the delete action.
- sku_id (optional): The sku_id attribute passes either a specific SKU ID
or a comma delimited list of SKU IDs. The default is 0 if the attribute is not provided.
- sku_unique_id (required for update/delete): Provides a list of items to manage for the update and delete cartactions
- sku_qty (optional): The sku_qty attribute passes either a single quantity
or a comma delimited list of quantities.
If the length of the quantity list does not match, the first value is used.
(e.g. pass in '2' to apply quantity of 2 to all listed sku ids)
Can also be ommitted for 'delete' or 'add', default for add is 1.
When updating the cart, if 0 is passed, the SKU is deleted from the cart.
- sku_custom_info (optional): A string to apply to all skus being added to the cart,
such as personalized products.
- redirect: A url to send the user to after action is performed. Leave blank for no redirection.
// RESPONSE and ERRORS
- errors and confirmation messages to be displayed to the user are generated in the 'request.cwpage' scope.
see params below for items available
// TIPS & TRICKS
- to show all items in the cart at any point, call this function with a cart ID: CWgetCartItems()
example: <cfdump var="#CWgetCartItems(session.cwclient.cwCartID)#">  will dump all contents of cart to page,
with CWgetCartItems as a query object. This is useful for development or debugging.
==========================================================
--->

<!--- default sku id and product id are 0 --->
<cfparam name="attributes.product_id" default="0">
<!--- default form items collection: renamed to 'productData' for processing --->
<cfparam name="attributes.form_values" default="">
<!--- default action --->
<cfparam name="attributes.cart_action" default="add">
<!--- sku_id can be a list, or single ID --->
<cfparam name="attributes.sku_id" default="0">
<!--- qty can be a list, or single, or omitted: default 1 if not provided --->
<cfparam name="attributes.sku_qty" default="1">
<!--- default for personalization (string) --->
<cfparam name="attributes.sku_custom_info" default="">
<!--- default for redirection --->
<cfparam name="attributes.redirect" default="">
<!--- show alerts after adding new products --->
<cfparam name="attributes.alert_added" default="true">
<!--- show alerts after removing products --->
<cfparam name="attributes.alert_removed" default="true">
<!--- reset promo codes in user's session --->
<cfparam name="attributes.reset_promo" default="false">
<!--- default error message --->
<cfparam name="request.cwpage.cartAlert" default="">
<!--- default success message --->
<cfparam name="request.cwpage.cartconfirm" default="">
<!--- default success list of sku IDs inserted --->
<cfparam name="request.cwpage.cartskusinserted" default="">
<!--- default for items added  --->
<cfparam name="request.cwpage.cartqtyinserted" default="0">
<!--- default for quantity available --->
<cfparam name="request.cwpage.cartStockOk" default="true">
<!--- default for sku validation --->
<cfparam name="request.cwpage.cartAddOk" default="true">
<!--- default message for invalid sku options --->
<cfparam name="request.cwpage.optionAlertText" default="Selection could not be verified">
<!--- default for list of quantity notices --->
<cfparam name="request.cwpage.stockalertids" default="">
<!--- default for quantity checking --->
<cfparam name="application.cw.appEnableBackOrders" default="true">
<!--- product data from form value structure --->
<cfset productData = attributes.form_values>
<!--- global functions --->
<cfinclude template="../inc/cw-inc-functions.cfm">
<!--- clean up form and url variables --->
<cfinclude template="../inc/cw-inc-sanitize.cfm">
<!--- start processing --->
<!--- // ADD TO CART // --->
<cfif attributes.cart_action is 'add'>
	<!--- defaults for post-processing --->
	<cfparam name="addsku.id" default="0">
	<cfparam name="addsku.qty" default="">
	<!--- validate product is active : will return false if id is 0, on web is no, or stock is less than 0 --->
	<cfset request.cwpage.cartStockOk = CWcartVerifyProduct(attributes.product_id,application.cw.appEnableBackOrders)>
	<!--- if product is ok, or ID not provided, continue processing --->
	<cfif request.cwpage.cartStockOk OR attributes.product_id is 0>
		<!--- DETERMINE ADD TO CART METHOD --->
		<!--- /////// --->
		<!--- MULTIPLE SKUS / TABLE (table display type, uses 'addSkus' field, product ID is required) --->
		<!--- /////// --->
		<cfif isDefined('productData.addSkus') and isNumeric(productData.addSkus)
			AND productData.addSkus gt 0 and attributes.product_id gt 0>
			<!--- loop addSkus counter field, insert sku id and qty --->
			<cfloop from="1" to="#productData.addskus#" index="ii">
				<!--- collect sku values in a struct, clear previous iteration --->
				<cfset addSku = structNew()>
				<!--- establish insertion values --->
				<cfparam name="productData.skuID#ii#" default="0">
				<cfset addSku.IDStr = "productData.skuID#ii#">
				<cfset addSku.ID = evaluate(addSku.IDStr)>
				<cfset addSku.QTY = evaluate('productData.qty#ii#')>
				<!--- QTY: if not provided, use 0 (skips insertion, avoids errors) --->
				<cfif NOT (isNumeric(addSku.qty) and addSku.qty gt 0)>
					<cfset addSku.QTY = 0>
				</cfif>
				<!--- handle custom info - write string to database (if quantity provided for adding product) --->
				<cfif isDefined('productData.customInfo') AND len(trim(productData.customInfo)) AND addSku.QTY gt 0>
					<!--- QUERY: inserts custom data to database, returns ID of saved data entry --->
					<cfset dataResponse = CWcartAddSkuData(addSku.ID,htmlEditFormat(trim(productData.customInfo)))>
					<!--- if the response is numeric, it is the ID for the inserted string --->
					<cfif isNumeric(dataResponse)>
						<!--- create the unique marker, combine sku id and custom data id --->
						<cfset addSku.uniqueID = addSku.id & '-' & dataResponse>
						<!--- if an error was returned --->
					<cfelse>
						<!--- add this error to messages shown to user, use sku ID for unique marker --->
						<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,'Custom value could not be saved')>
						<cfset addSku.uniqueID = addSku.id>
					</cfif>
					<!--- if no custom info given, use sku ID for unique marker--->
				<cfelse>
					<cfset addSku.UniqueID = addSku.ID>
				</cfif>
				<!--- QUERY:
				Insert SKU to Cart (sku id, unique custom string, quantity, check stock ) --->
				<!--- the insert function returns the SKU ID and the qty (cartresponse.message / cartresponse.qty) on success,
				or an error message (cartresponse.message) --->
				<cfset cartResponse = CWcartAddItem(sku_id=addSku.ID,sku_unique_id=addSku.uniqueID,sku_qty=addSku.Qty,ignore_stock=application.cw.appEnableBackOrders)>
				<!--- CREATE RESPONSE CONTENT --->
				<!--- if response is SKU ID, no error occurred, sku was inserted --->
				<cfif cartResponse.message eq addSku.ID>
					<!--- if quantity was returned, track sku ID and total insertions --->
					<cfif cartResponse.qty gt 0>
						<cfset request.cwpage.cartskusinserted = listAppend(request.cwpage.cartskusinserted,addSku.uniqueID)>
						<cfset request.cwpage.cartqtyinserted = request.cwpage.cartqtyinserted + cartResponse.qty>
					</cfif>
					<!--- if inserted amount was less than requested --->
					<cfif cartResponse.qty lt addSku.qty and application.cw.appEnableBackOrders neq true>
						<cfset alertMsg = 'Limited quantity: unable to add item'>
						<cfset adjMsg = 'Limited quantity: totals adjusted'>
						<cfset request.cwpage.stockalertids = listAppend(request.cwpage.stockalertids,addSku.uniqueID)>
						<cfif cartResponse.qty eq 0 and not request.cwpage.cartAlert contains alertMsg>
							<cfif attributes.alert_added>
								<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,alertMsg)>
							</cfif>
						<cfelseif not request.cwpage.cartAlert contains adjMsg>
							<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,adjMsg)>
						</cfif>
					</cfif>
					<!--- if error message returned instead of sku ID --->
				<cfelse>
					<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,trim(cartResponse.message))>
				</cfif>
				<!--- set up confirmation from inserted qty --->
				<cfif request.cwpage.cartqtyinserted gt 0>
					<cfset insertedCt = request.cwpage.cartqtyinserted>
					<cfif insertedCt eq 1><cfset s = ''><cfelse><cfset s = 's'></cfif>
					<cfset request.cwpage.cartconfirm = insertedCt & ' item#s# added to cart'>
					<!--- set flag for promo codes in user's session --->
					<cfset attributes.reset_promo = true>
				</cfif>
				<!--- /END RESPONSE CONTENT --->
			</cfloop>
			<!--- / end loop addSkus counter --->
			<!--- /END MULTIPLE SKUS / TABLE --->
			<!--- /////// --->
			<!--- LIST OF SKUS or SINGLE SKU --->
			<!--- /////// --->
		<cfelseif isDefined('attributes.sku_id') and attributes.sku_id neq 0>
			<!--- treate the sku id as a list, loop over it (even if single sku) --->
			<cfset listCt = 1>
			<cfloop list="#attributes.sku_id#" index="ii">
				<!--- sku id to insert --->
				<cfset addSku.ID = val(trim(ii))>
				<!--- quantity to insert --->
				<!--- if the qty was provided as a matching list --->
				<cfif listLen(attributes.sku_qty) eq listLen(attributes.sku_id)>
					<cfset addSku.qty = val(trim(listGetAt(attributes.sku_qty,listCt)))>
					<!--- if qty is one number, use that for all items --->
				<cfelseif listLen(attributes.sku_qty) eq 1>
					<cfset addSku.qty = listFirst(attributes.sku_qty)>
					<!--- if none of these, use default --->
				<cfelse>
					<cfset addSku.qty = 1>
				</cfif>
				<!--- handle custom info - write string to database if quantity provided --->
				<cfif len(trim(attributes.sku_custom_info)) AND addSku.QTY gt 0>
					<!--- QUERY: inserts custom data to database, returns ID of saved data entry --->
					<cfset dataResponse = CWcartAddSkuData(addSku.ID,htmlEditFormat(trim(attributes.sku_custom_info)))>
					<!--- if the response is numeric, it is the ID for the inserted string --->
					<cfif isNumeric(dataResponse)>
						<!--- create the unique marker, combine sku id and custom data id --->
						<cfset addSku.uniqueID = addSku.id & '-' & dataResponse>
						<!--- if an error was returned --->
					<cfelse>
						<!--- add this error to messages shown to user, use sku ID for unique marker --->
						<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,'Custom value could not be saved')>
						<cfset addSku.uniqueID = addSku.id>
					</cfif>
					<!--- if no custom info given, use sku ID for unique marker--->
				<cfelse>
					<cfset addSku.UniqueID = addSku.ID>
				</cfif>
				<!--- QUERY:
				Insert SKU to Cart (sku id, unique custom string, quantity, check stock ) --->
				<!--- the insert function returns the SKU ID and the qty (cartresponse.message / cartresponse.qty) on success,
				or an error message (cartresponse.message) --->
				<cfset cartResponse = CWcartAddItem(sku_id=addSku.ID,sku_unique_id=addSku.uniqueID,sku_qty=addSku.Qty,ignore_stock=application.cw.appEnableBackOrders)>
				<!--- CREATE RESPONSE CONTENT --->
				<!--- if response is SKU ID, no error occurred, sku was inserted --->
				<cfif cartResponse.message eq addSku.ID>
					<!--- if quantity was returned, track sku ID and total insertions --->
					<cfif cartResponse.qty gt 0>
						<cfset request.cwpage.cartskusinserted = listAppend(request.cwpage.cartskusinserted,addSku.uniqueID)>
						<cfset request.cwpage.cartqtyinserted = request.cwpage.cartqtyinserted + cartResponse.qty>
					</cfif>
					<!--- if inserted amount was less than requested --->
					<cfif cartResponse.qty lt addSku.qty and application.cw.appEnableBackOrders neq true>
						<cfset alertMsg = 'Limited quantity: unable to add item'>
						<cfset adjMsg = 'Limited quantity: totals adjusted'>
						<cfset request.cwpage.stockalertids = listAppend(request.cwpage.stockalertids,addSku.uniqueID)>
						<cfif cartResponse.qty eq 0 and not request.cwpage.cartAlert contains alertMsg>
							<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,alertMsg)>
						<cfelseif not request.cwpage.cartAlert contains adjMsg>
							<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,adjMsg)>
						</cfif>
					</cfif>
					<!--- if error message returned instead of sku ID --->
				<cfelse>
					<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,trim(cartResponse.message))>
				</cfif>
				<!--- set up confirmation from inserted qty --->
				<cfif request.cwpage.cartqtyinserted gt 0>
					<cfset insertedCt = request.cwpage.cartqtyinserted>
					<cfif insertedCt eq 1><cfset s = ''><cfelse><cfset s = 's'></cfif>
					<cfif attributes.alert_added>
						<cfset request.cwpage.cartconfirm = insertedCt & ' item#s# added to cart'>
					</cfif>
					<!--- set flag for promo codes in user's session --->
					<cfset attributes.reset_promo = true>
					<!--- if no qty and no message, we did not provide any qty --->
				<cfelseif cartresponse.message is ''>
					<cfset request.cwpage.cartAlert = 'Select a quantity for insertion'>
				</cfif>
				<!--- /END RESPONSE CONTENT --->
				<!--- advance the loop counter --->
				<cfset listCt = listCt + 1>
			</cfloop>
			<!--- /END LIST OF SKUS or SINGLE SKU --->
			<!--- /////// --->
			<!--- SINGLE SKU from OPTIONS / SELECT (standard 'select' display type, parses 'optionsel' fields) --->
			<!--- /////// --->
		<cfelse>
			<!--- loop through form_values, create list of option ids --->
			<cfset skuOptions = "">
			<cfloop collection="#productData#" item="fieldName">
				<!--- if the form field is one of our select menus, and the value is valid,
				add the option id to the list and increase the count --->
				<cfif Left(fieldName,9) eq 'optionsel' AND right(fieldName,4) neq 'temp'>
					<!--- if value was provided, add to list --->
					<cfif val(productData[fieldName]) gt 0>
						<cfset skuOptions = ListAppend(skuOptions, productData[fieldName])>
					<!--- if value is blank, flag with 0 for error below --->
					<cfelse>
						<cfset skuOptions = ListAppend(skuOptions,'0')>
					</cfif>
				</cfif>
			</cfloop>
			<!--- BLANK OPTIONS --->
			<cfif listFind(skuOptions,'0')>
				<!--- set message for user --->
				<cfset skuResponse = 'error'>
				<!--- NO OPTIONS: if no options provided, look up single sku for this product id --->
			<cfelseif skuOptions eq ''>
				<!--- QUERY: get single sku for this item --->
				<cfset skuResponse = CWcartGetSkuNoOptions(product_id=#attributes.product_id#)>
				<!--- OPTION LIST: if options provided, look up sku by option ids --->
			<cfelse>
				<!--- QUERY: get sku_id based on options  --->
				<cfset skuResponse = CWcartGetSkuByOptions(product_id=#attributes.product_id#,option_list=#skuOptions#)>
			</cfif>
			<!--- /end if sku options provided, or empty --->
			<!--- verify numeric, valid SKU id --->
			<cfif isNumeric(skuResponse)>
				<cfset addSku.ID = skuResponse>
			<!--- set message for invalid sku --->
			<cfelse>
				<cfif not listFindNocase(request.cwpage.cartAlert,request.cwpage.optionAlertText)>
					<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,request.cwpage.optionAlertText)>
				</cfif>
				<cfset request.cwpage.cartAddOk = false>
			</cfif>
			<!--- add to cart if sku ID is ok --->
			<cfif request.cwpage.cartAddOk>
			<!--- quantity: from productdata --->
			<cfif isDefined('productData.qty') and isNumeric(val(productData.qty))>
				<cfset addSku.qty = productData.qty>
			<cfelse>
				<cfset addSku.qty = 1>
			</cfif>
			<!--- handle custom info - write string to database if quantity provided --->
			<cfif isDefined('productData.customInfo') AND len(trim(productData.customInfo)) AND addSku.QTY gt 0>
				<!--- QUERY: inserts custom data to database, returns ID of saved data entry --->
				<cfset dataResponse = CWcartAddSkuData(addSku.ID,htmlEditFormat(trim(productData.customInfo)))>
				<!--- if the response is numeric, it is the ID for the inserted string --->
				<cfif isNumeric(dataResponse)>
					<!--- create the unique marker, combine sku id and custom data id --->
					<cfset addSku.uniqueID = addSku.id & '-' & dataResponse>
					<!--- if an error was returned --->
				<cfelse>
					<!--- add this error to messages shown to user, use sku ID for unique marker --->
					<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,'Custom value could not be saved')>
					<cfset addSku.uniqueID = addSku.id>
				</cfif>
				<!--- if no custom info given, use sku ID for unique marker--->
			<cfelse>
				<cfset addSku.UniqueID = addSku.ID>
			</cfif>
			<!--- QUERY:
			Insert SKU to Cart (sku id, unique custom string, quantity, check stock ) --->
			<!--- the insert function returns the SKU ID and the qty (cartresponse.message / cartresponse.qty) on success,
			or an error message (cartresponse.message) --->
			<cfset cartResponse = CWcartAddItem(sku_id=addSku.ID,sku_unique_id=addSku.uniqueID,sku_qty=addSku.Qty,ignore_stock=application.cw.appEnableBackOrders)>
			<!--- CREATE RESPONSE CONTENT --->
			<!--- if response is SKU ID, no error occurred, sku was inserted --->
			<cfif cartResponse.message eq addSku.ID>
				<!--- if quantity was returned, track sku ID and total insertions --->
				<cfif cartResponse.qty gt 0>
					<cfset request.cwpage.cartskusinserted = listAppend(request.cwpage.cartskusinserted,addSku.uniqueID)>
					<cfset request.cwpage.cartqtyinserted = request.cwpage.cartqtyinserted + cartResponse.qty>
				</cfif>
				<!--- if inserted amount was less than requested --->
				<cfif cartResponse.qty lt addSku.qty and cartResponse.message neq '0' and application.cw.appEnableBackOrders neq true>
					<cfset alertMsg = 'Limited quantity: unable to add item'>
					<cfset adjMsg = 'Limited quantity: totals adjusted'>
					<cfset request.cwpage.stockalertids = listAppend(request.cwpage.stockalertids,addSku.uniqueID)>
					<cfif cartResponse.qty eq 0 and not request.cwpage.cartAlert contains alertMsg>
						<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,alertMsg)>
					<cfelseif not request.cwpage.cartAlert contains adjMsg>
						<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,adjMsg)>
					</cfif>
				</cfif>
				<!--- if error message returned instead of sku ID --->
			<cfelse>
				<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,trim(cartResponse.message))>
			</cfif>
			<!--- set up confirmation from inserted qty --->
			<cfif request.cwpage.cartqtyinserted gt 0>
				<cfset insertedCt = request.cwpage.cartqtyinserted>
				<cfif insertedCt eq 1><cfset s = ''><cfelse><cfset s = 's'></cfif>
				<cfif attributes.alert_added>
					<cfset request.cwpage.cartconfirm = insertedCt & ' item#s# added to cart'>
				</cfif>
				<!--- set flag for promo codes in user's session --->
				<cfset attributes.reset_promo = true>
			<!--- if no qty and no message, we did not provide any qty --->
			<cfelseif cartresponse.message is ''>
				<cfset request.cwpage.cartAlert = 'Select a quantity for insertion'>
			</cfif>
			<!--- /END RESPONSE CONTENT --->
		</cfif>
		<!--- /end if request.cwpage.cartAddOk = true --->
		</cfif>
		<!--- /END SINGLE SKU from OPTIONS / SELECT --->
		<!--- if product stockOK returns false --->
	<cfelse>
		<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,'Product Unavailable')>
	</cfif>
	<!--- /end stock ok --->
<!--- / END ADD TO CART --->
<!--- // DELETE SKU FROM CART // --->
<cfelseif attributes.cart_action is 'delete'>
	<!--- treate the sku unique ids as a list, loop over it (even if single sku) --->
	<cfset listCt = 1>
	<cfparam name="request.cwpage.deletedCt" default="0">
	<cfloop list="#attributes.sku_unique_id#" index="ii">
		<!--- sku unique id to delete --->
		<cfset delSku.ID = trim(ii)>
		<!--- QUERY: remove item from cart, return string or message --->
		<cfset deleteItem = CWcartDeleteItem(sku_unique_id=delSku.ID)>
		<!--- if a message other than sku id is returned, show error message --->
		<cfif deleteItem neq trim(ii)>
			<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,deleteItem)>
			<!--- if id was returned, add to delete count --->
		<cfelse>
			<cfset request.cwpage.deletedCt = request.cwpage.deletedCt + 1>
		</cfif>
	</cfloop>
	<cfif request.cwpage.deletedCt gt 0>
		<cfif request.cwpage.deletedCt eq 1>
			<cfset s = ''>
		<cfelse>
			<cfset s = 's'>
		</cfif>
		<cfif attributes.alert_removed>
			<cfset request.cwpage.cartconfirm = '#request.cwpage.deletedCt# item#s# removed from cart'>
		</cfif>
		<!--- set flag for promo codes in user's session --->
		<cfset attributes.reset_promo = true>
	</cfif>
<!--- /END DELETE SKU --->
<!--- // UPDATE QUANTITY IN CART // --->
<cfelseif attributes.cart_action is 'update'>
	<!--- treate the sku unique id as a list, loop over it (even if single sku) --->
	<cfset listCt = 1>
	<cfparam name="request.cwpage.deletedCt" default="0">
	<cfloop list="#attributes.sku_unique_id#" index="ii">
		<cfset updateSku.uniqueID = ii>
		<!--- if qty is same, get from list --->
		<cfif listLen(attributes.sku_qty) eq listLen(attributes.sku_unique_id)>
			<cfset updateSku.qty = listGetAt(attributes.sku_qty,listCt)>
			<!--- otherwise use first number in list (i.e. if only number) --->
		<cfelse>
			<cfset updateSku.qty = listFirst(attributes.sku_qty)>
		</cfif>
		<!--- if qty is 0, delete --->
		<cfif updateSku.qty eq 0>
			<!--- QUERY: remove item from cart, return string or message --->
			<cfset deleteItem = CWcartDeleteItem(sku_unique_id=updateSKU.uniqueID)>
			<!--- if a message other than sku id is returned, show error message --->
			<cfif deleteItem neq updateSKU.uniqueID>
				<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,deleteItem)>
				<!--- if id was returned, add to delete count --->
			<cfelse>
				<cfset request.cwpage.deletedCt = request.cwpage.deletedCt + 1>
				<!--- set flag for promo codes in user's session --->
				<cfset attributes.reset_promo = true>		
			</cfif>
			<!--- if greater than 0, update the qty --->
		<cfelse>
			<!--- QUERY: update quantity in cart, return string or message --->
			<cfset cartResponse = CWcartUpdateItem(sku_unique_id=updateSKU.uniqueID,sku_qty=updateSKU.qty,ignore_stock=application.cw.appEnableBackOrders)>
			<!--- if a message other than sku id is returned, show error message --->
			<cfif cartResponse.message neq updateSKU.uniqueID and not cartResponse.qty eq ''>
				<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,'Unable to update item')>
			<cfelse>
				<!--- set flag for promo codes in user's session --->
				<cfset attributes.reset_promo = true>		
			</cfif>
			<!--- if quantity does not match, show alert --->
			<cfif cartResponse.qty lt updateSku.qty and not cartResponse.qty eq '' and application.cw.appEnableBackOrders neq true>
				<cfset adjMsg = 'Limited quantity: totals adjusted'>
				<cfif not request.cwpage.cartAlert contains adjMsg>
					<cfset request.cwpage.cartAlert = listAppend(request.cwpage.cartAlert,adjMsg)>
				</cfif>
				<cfset request.cwpage.stockalertids = listAppend(request.cwpage.stockalertids,updateSku.uniqueID)>
				<cfset session.cw.stockalertids = request.cwpage.stockalertids>
			</cfif>
		</cfif>
		<cfset listCt = listCt + 1>
	</cfloop>
	<!--- put alerts into session scope --->
	<cfif len(trim(request.cwpage.cartAlert))>
		<cfset session.cw.cartAlert = trim(request.cwpage.cartAlert)>
	</cfif>
	<cfif request.cwpage.deletedCt gt 0>
		<cfif request.cwpage.deletedCt eq 1>
			<cfset s = ''>
		<cfelse>
			<cfset s = 's'>
		</cfif>
		<cfif attributes.alert_removed>
			<cfset request.cwpage.cartconfirm = '#request.cwpage.deletedCt# item#s# removed from cart'>
		</cfif>
	</cfif>
</cfif>
<!--- /END UPDATE QUANTITY --->
<!--- RESET SESSION PROMO CODES --->
<cfif application.cw.discountsEnabled and attributes.reset_promo eq true and len(trim(session.cwclient.discountPromoCode))>
	<cftry>
		<cfset temp = CWresetSessionPromoCodes(session.cwclient.discountPromoCode,CWgetCart(cart_id=session.cwclient.cwCartID,set_discount_request=false))>
		<cfset request.cwpage.discountsapplied = session.cwclient.discountApplied>
		<cfcatch>
		</cfcatch>
	</cftry>	
</cfif>

<!--- redirect --->
<cfif len(trim(attributes.redirect))>
	<!--- pass alerts/confirmations into session --->
	<cfif isDefined('request.cwpage.cartconfirm') and len(trim(request.cwpage.cartconfirm))>
		<cfset session.cw.cartConfirm = trim(request.cwpage.cartconfirm)>
	</cfif>
	<cfif isDefined('request.cwpage.cartAlert') and len(trim(request.cwpage.cartAlert))>
		<cfset session.cw.cartAlert = trim(request.cwpage.cartAlert)>
	</cfif>
	<!--- clear values if going to cart --->
	<cfif attributes.redirect contains listLast(request.cwpage.urlShowCart,'/')>
		<cfset persistVars = ''>
		<!--- persist selection values if going to details page --->
	<cfelse>
		<cfset persistVars = 'product,category,secondary'>
	</cfif>
	<cfset redirectUrl = CWserializeUrl(persistVars, attributes.redirect)>
	<cfif redirectUrl contains "=">
		<cfset redirectUrl = redirectUrl & "&">
	</cfif>
	<cfif len(trim(request.cwpage.cartskusinserted))>
		<cfset redirectUrl = redirectUrl & 'addedid=' & request.cwpage.cartskusinserted>
	</cfif>
	<cfif len(trim(request.cwpage.stockalertids))>
		<cfset redirectUrl = redirectUrl & 'alertID=' & request.cwpage.stockalertids>
	</cfif>
	<!--- only redirect if the sku was valid --->
	<cfif request.cwpage.cartAddOk>
		<cflocation url="#redirectUrl#" addtoken="no">
	</cfif>
</cfif>
</cfsilent>