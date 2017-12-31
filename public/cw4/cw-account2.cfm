<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-account.cfm
File Date: 2012-12-04
Description: manages login, account information and order history
==========================================================
--->
<!--- if accounts are not enabled, send user to cart page --->
<cfif not application.cw.customerAccountEnabled>
	<cflocation url="#request.cwpage.urlShowCart#" addtoken="no">
</cfif>
<!--- customerID needed to handle account / billing --->
<cfparam name="session.cwclient.cwCustomerID" default="0">
<!--- customer type for advanced wholesal/retail mods --->
<cfparam name="session.cwclient.cwCustomerType" default="2">
<!--- customer name for 'logged in as' link --->
<cfparam name="session.cwclient.cwCustomerName" default="">
<!--- list of recently viewed products --->
<cfparam name="session.cwclient.cwProdViews" default="">
<!--- errors from forms being submitted --->
<cfparam name="request.cwpage.formErrors" default="">
<!--- content to show (account|orders|details|products|views) --->
<cfparam name="request.cwpage.viewMode" default="account">
<cfparam name="url.view" default="#request.cwpage.viewMode#">
<!--- order details --->
<cfparam name="url.order" default="0">
<!--- spacer between navigation links --->
<cfset linkDelim = "&nbsp;&nbsp;&bull;&nbsp;&nbsp;">
<!--- clean up form and url variables --->
<cfinclude template="cwapp/inc/cw-inc-sanitize.cfm">
<!--- CARTWEAVER REQUIRED FUNCTIONS --->
<cfinclude template="cwapp/inc/cw-inc-functions.cfm">
<!--- form and link actions --->
<cfparam name="request.cwpage.hrefUrl" default="#CWtrailingChar(trim(application.cw.appCwStoreRoot))##request.cw.thisPage#">
<!--- if not logged in, persist account view --->
<cfif session.cwclient.cwCustomerID eq 0 or session.cwclient.cwCustomerType eq 0
	or (isDefined('session.cwclient.cwCustomerCheckout') and session.cwclient.cwCustomerCheckout is 'guest')>
	<cfset request.cwpage.viewmode = 'account'>
<cfelse>
	<cfset request.cwpage.viewmode = url.view>
</cfif>
<cfparam name="request.cwpage.downloadsEnabled" default="#application.cw.appDownloadsEnabled#">
<!--- empty list, used to prevent duplicate links below --->
<cfset dlSkus = ''>

<cfset downloadsQuery = CWselectCustomerDownloads(session.cwclient.cwCustomerID)>
<!--- if customer has no downloadable items, downloads are not enabled for this page --->
<cfif downloadsQuery.recordCount lt 1>
	<cfset request.cwpage.downloadsEnabled = false>
</cfif>
</cfsilent>
<!--- /////// START OUTPUT /////// --->
<!--- breadcrumb navigation --->
<cfmodule template="cwapp/mod/cw-mod-searchnav.cfm"
	search_type="breadcrumb"
	separator=" &raquo; "
	end_label="My Account"
	all_categories_label=""
	all_secondaries_label=""
	all_products_label=""
	>
<!--- customer account info--->
<div id="CWaccount" class="CWcontent">
	<h1>Account Information</h1>
	<!--- login section --->
	<div class="CWformSection">
		<!--- if not logged in --->
		<cfif session.cwclient.cwCustomerID is 0 or session.cwclient.cwCustomerType is 0
			or (isDefined('session.cwclient.cwCustomerCheckout') and session.cwclient.cwCustomerCheckout is 'guest')>
			<h3 class="CWformSectionTitle">Returning Customers: Log In</h3>
			<!--- login form --->
			<cfmodule template="cwapp/mod/cw-mod-formlogin.cfm">
			<!--- if logged in --->
		<cfelse>
			<h3 class="CWformSectionTitle">Account Options</h3>
			<cfif len(trim(session.cwclient.cwCustomerName))>
				<div class="sideSpace headSpace">
					<p>Logged in as
					<cfoutput>#session.cwclient.cwCustomerName#</cfoutput>&nbsp;&nbsp;
					<!--- logout link --->
					<span class="smallPrint"><cfoutput><a href="#request.cwpage.hrefUrl#?logout=1">Not your account?</a></cfoutput></span>
					</p>
					<!--- switch view links --->
					<cfoutput>
						<p class="CWlinks">
							<a href="#request.cwpage.hrefUrl#?view=account"<cfif request.cwpage.viewmode eq 'account'> class="currentLink"</cfif>>Account Details</a>#linkDelim#<a href="#request.cwpage.hrefUrl#?view=orders"<cfif request.cwpage.viewmode eq 'orders' or request.cwpage.viewmode eq 'details'> class="currentLink"</cfif>>Order History</a>#linkDelim#<a href="#request.cwpage.hrefUrl#?view=products"<cfif request.cwpage.viewmode eq 'products'> class="currentLink"</cfif>>Purchased Items</a>
							<cfif request.cwpage.downloadsEnabled>#linkDelim#<a href="#request.cwpage.hrefUrl#?view=downloads"<cfif request.cwpage.viewmode eq 'downloads'> class="currentLink"</cfif>>Downloads</a></cfif>
							<cfif len(trim(session.cwclient.cwProdViews))>#linkDelim#<a href="#request.cwpage.hrefUrl#?view=views"<cfif request.cwpage.viewmode eq 'views'> class="currentLink"</cfif>>Recently Viewed Items</a></cfif>
						</p>
					</cfoutput>
				</div>
			</cfif>
		</cfif>
		<!--- /end if logged in --->
	</div>
	<!--- /end login section --->
	<!--- customer account section --->
	<div class="CWformSection">
		<!--- content switch, based on url view --->
		<cfswitch expression="#request.cwpage.viewmode#">
			<!--- ORDER HISTORY --->
			<cfcase value="orders">
				<!--- QUERY: get orders by customer id --->
				<cfset ordersQuery = CWquerySelectOrders(customer_id = session.cwclient.cwCustomerID)>
				<h3 class="CWformSectionTitle">Order History</h3>
				<!--- if orders exist --->
				<cfif ordersQuery.recordCount gt 0>
					<table id="CWcustomerTable" class="CWformTable">
						<tbody>
							<cfloop query="ordersQuery">
								<!--- QUERY: get products in order --->
								<cfset skusQuery = CWquerySelectOrderDetails(ordersQuery.order_id)>
								<!--- header w/ date --->
								<tr>
									<th colspan="3">
									<h3><cfoutput>Date: #LSdateFormat(ordersQuery.order_date,application.cw.globalDateMask)#&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Order ID:#ordersQuery.order_id#</cfoutput></h3>
									</th>
								</tr>
								<!--- order details --->
								<tr>
									<!--- order total --->
									<cfoutput>
										<td style="width:140px;">
											<strong>Order Total:</strong>
											<br>#lsCurrencyFormat(ordersQuery.order_total)#
											<br><br>&raquo;&nbsp;<a href="#request.cwpage.hrefUrl#?view=details&order=#ordersQuery.order_id#">Order Details</a>
										</td>
										<!--- ship to / status --->
										<td style="width:170px;">
											<cfif order_status gt 4>
										        <strong>Status:</strong>
												<br>#ordersQuery.shipstatus_name#
											<cfelseif order_status eq 4>
												<strong>Shipped To:</strong>
												<br>#ordersQuery.order_ship_name#
												<cfif len(trim(ordersQuery.order_company))>
													<br>#ordersQuery.order_company#
												</cfif>
												<br>#ordersQuery.order_address1#
												<cfif len(trim(ordersQuery.order_address2))>
													<br>#ordersQuery.order_address2#
												</cfif>
												<br>#ordersQuery.order_city#, #ordersQuery.order_state# #ordersQuery.order_zip#
											<cfelse>
												<strong>Status:</strong>
												<br>Processing, #ordersQuery.shipstatus_name#
											</cfif>
										</td>
									</cfoutput>
									<!--- products --->
									<td>
										<cfset dlOK = false>
										<cfset dlMessage = ''>
										<cfif request.cwpage.downloadsEnabled>
											<!--- if sku has a download attached --->
											<cfif len(trim(skusQuery.sku_download_id))>
											<!--- check for download from this order: Cartweaver Digital Downloads --->
											<cfset downloadCheck = CWcheckCustomerDownload(
																		skusQuery.sku_id,
																		session.cwclient.cwCustomerID,
																		ordersQuery.order_id
																		)>
												<!--- if 0 is returned, no limit, no message --->
												<cfif downloadCheck is '0'>
													<cfset dlOK = true>
												<!--- if other number returned, create message --->
												<cfelseif isNumeric(downloadCheck)>
													<cfset dlMessage = downloadCheck & ' downloads remaining'>
													<cfset dlOK = true>
												<!--- if a "0-" error message is returned, no dl available, show text string --->
												<cfelseif left(downloadCheck,2) is '0-'>
													<cfset dlMessage = listRest(downloadCheck,'-')>
												</cfif>
											</cfif>
											<!--- /end download sku check --->
										</cfif>									
										<cfif skusQuery.recordCount>
											<strong>Products:</strong>
											<br>
											<cfoutput query="skusQuery" group="ordersku_unique_id">
												<a class="CWlink" href="#request.cwpage.urlDetails#?product=#product_id#">#product_name#</a>
												<cfif dlOK>&nbsp;
													<span class="smallPrint">
													<cfmodule template="cwapp/mod/cw-mod-downloadlink.cfm"
													sku_id="#skusQuery.sku_id#"
													customer_id="#session.cwclient.cwCustomerID#"
													show_file_size="true"
													show_file_name="false"
													show_file_version="false"
													show_last_version="false"
													show_last_date="false"
													show_remaining="false"
													>
													</span>
												</cfif>
												<br>
											</cfoutput>
										</cfif>
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
					<!--- if no orders --->
				<cfelse>
					<p class="sideSpace">No orders found for <cfif len(trim(session.cwclient.cwCustomerName))>customer '<cfoutput>#session.cwclient.cwCustomerName#</cfoutput>'<cfelse>this account</cfif>.</p>
				</cfif>
			</cfcase>
			<!--- ORDER DETAILS --->
			<cfcase value="details">
				<!--- QUERY: get order details based on ID in url --->
				<cfset orderQuery = CWquerySelectOrderDetails(order_id=url.order) />
				<h3 class="CWformSectionTitle">Order Details<cfif orderQuery.recordCount gt 0>&nbsp;&nbsp;<span class="smallPrint"><cfoutput>Date: #LSdateFormat(orderQuery.order_date,application.cw.globalDateMask)#&nbsp;&nbsp;Order ID: #orderQuery.order_id#</cfoutput></span></cfif></h3>
				<!--- if order is found --->
				<cfif orderQuery.recordCount gt 0>
					<!--- display order contents, passing in order query from above --->
					<div class="headSpace sideSpace">
						<cfmodule template="cwapp/mod/cw-mod-orderdisplay.cfm"
							order_query="#orderQuery#"
							display_mode="summary"
							show_images="#application.cw.appDisplayCartImage#"
							show_sku="#application.cw.appDisplayCartSku#"
							show_options="true"
							link_products="true"
							>
					</div>
					<!--- no order found --->
				<cfelse>
					<p>Invalid Order ID</p>
				</cfif>
				<p class="sideSpace">&raquo;&nbsp;<a href="<cfoutput>#request.cwpage.hrefUrl#</cfoutput>?view=orders">View All Past Orders</a></p>
				<p>&nbsp;</p>
			</cfcase>
			<!--- PRODUCT HISTORY --->
			<cfcase value="products">
				<h3 class="CWformSectionTitle">Purchased Items</h3>
				<!--- QUERY: get products by customer id --->
				<cfset productsQuery = CWgetProductsByCustomer(customer_id=session.cwclient.cwCustomerID)>
				<!--- if orders exist --->
				<cfif productsQuery.recordCount gt 0>
					<div class="headSpace">
					</div>
					<table id="CWcustomerTable" class="CWformTable">
						<tbody>
							<cfoutput query="productsQuery" group="product_id">
								<!--- get image for item ( add to cart item info )--->
								<cfif application.cw.appDisplayCartImage>
									<cfset itemImg = CWgetImage(product_id=productsQuery.product_ID,image_type=4,default_image=application.cw.appImageDefault)>
								<cfelse>
									<cfset itemImg = ''>
								</cfif>
								<cfif productsQuery.product_on_web neq 0 and productsQuery.product_archive neq 1>
									<tr>
										<cfif application.cw.appDisplayCartImage>
											<td class="CWimgCell">
												<!--- product image --->
												<cfif len(trim(itemImg))>
													<div class="CWcartImage">
														<a href="#request.cwpage.urlDetails#?product=#productsQuery.product_id#" title="View Product"><img src="#itemImg#" alt="#productsQuery.product_name#"></a>
													</div>
												</cfif>
											</td>
										</cfif>
										<td class="CWproductNameCell">
											<strong><a class="CWlink smallPrint" href="#request.cwpage.urlDetails#?product=#product_id#">#product_name#</a></strong>
										</td>
										<td>
											<p class="smallPrint">Order ID: <a href="#request.cwpage.hrefUrl#?view=details&order=#productsQuery.order_id#">#productsQuery.order_id#</a></p>
										</td>
										<td>
											<p class="smallPrint">Date: #LSdateFormat(productsQuery.order_date,application.cw.globalDateMask)#</p>
										</td>
									</tr>
								</cfif>
							</cfoutput>
						</tbody>
					</table>
					<!--- if no orders --->
				<cfelse>
					<p class="sideSpace">No products found for <cfif len(trim(session.cwclient.cwCustomerName))>customer '<cfoutput>#session.cwclient.cwCustomerName#</cfoutput>'<cfelse>this account</cfif>.</p>
				</cfif>
			</cfcase>
			<!--- DOWNLOADS --->
			<cfcase value="downloads">
				<h3 class="CWformSectionTitle">Downloads</h3>
				<!--- if orders exist --->
				<cfif downloadsQuery.recordCount gt 0>
					<div class="headSpace">
					</div>
					<table id="CWcustomerTable" class="CWformTable">
						<tbody>
						<cfoutput query="downloadsQuery" group="product_id">
							<cfif downloadsQuery.product_on_web neq 0 and downloadsQuery.product_archive neq 1>
								<tr>
									<td style="width:223px;">
										<strong><a class="CWlink smallPrint" href="#request.cwpage.urlDetails#?product=#product_id#">#product_name#</a></strong>
									</td>
									<td>
										<cfif request.cwpage.downloadsEnabled>
										<!--- ungroup query output to loop each sku --->
										<cfoutput>
										<cfset dlOK = false>
										<cfset dlMessage = ''>
											<!--- if sku has a download attached --->
											<cfif len(trim(downloadsQuery.sku_download_id)) and not listFind(dlSkus,downloadsQuery.sku_id)>
												<!--- check for download from this order: Cartweaver Digital Downloads --->
												<cfset downloadCheck = CWcheckCustomerDownload(
																		downloadsQuery.sku_id,
																		session.cwclient.cwCustomerID,
																		downloadsQuery.order_id
																		)>
												<!--- if 0 is returned, no limit, no message --->
												<cfif downloadCheck is '0'>
													<cfset dlOK = true>
												<!--- if other number returned, create message --->
												<cfelseif isNumeric(downloadCheck)>
													<cfset dlMessage = downloadCheck & ' downloads remaining'>
													<cfset dlOK = true>
												<!--- if a "0-" error message is returned, no dl available, show text string --->
												<cfelseif left(downloadCheck,2) is '0-'>
													<cfset dlMessage = listRest(downloadCheck,'-')>
												</cfif>
											</cfif>
											<!--- if download is ok, show link--->
											<cfif dlOK>
												<!--- expand dl data, show message --->
												<span class="cwDlLink">
												<cfmodule template="cwapp/mod/cw-mod-downloadlink.cfm"
												sku_id="#downloadsQuery.sku_id#"
												customer_id="#session.cwclient.cwCustomerID#"
												download_text="Download File:"
												>
												<br>
												</span>
											<cfelseif len(trim(dlMessage))>
														<cfset dlData = CWgetCustomerDownloadData(downloadsQuery.sku_id,session.cwclient.cwCustomerID)>
														#trim(dlMessage)#
														<cfif len(trim(downloadsQuery.sku_download_version))>
														<br>Current Version: #downloadsQuery.sku_download_version#
														</cfif>
														<br><span class="smallPrint">
												  		<!--- last download date --->
														<cfif isDate(dlData.date)>Last Download: #lsDateFormat(dldata.date)#</cfif>
														<!--- last download version --->
														<cfif len(trim(dlData.version))> Version: #trim(dldata.version)#</cfif>
														</span>
											</cfif>
											<!--- add to list of skus already shown --->
											<cfset dlSkus = listAppend(dlSkus,downloadsQuery.sku_id)>
										<!--- end grouped output --->
										</cfoutput>
										</cfif>
										<!--- /end if downloads enabled --->
									</td>
									<td>
										<p class="smallPrint">Order ID: <a href="#request.cwpage.hrefUrl#?view=details&order=#downloadsQuery.order_id#">#downloadsQuery.order_id#</a>
										<br>Date: #LSdateFormat(downloadsQuery.order_date,application.cw.globalDateMask)#</p>
									</td>
								</tr>
							</cfif>
						</cfoutput>
						</tbody>
					</table>
					<!--- if no orders --->
				<cfelse>
					<p class="sideSpace">No downloads found for <cfif len(trim(session.cwclient.cwCustomerName))>customer '<cfoutput>#session.cwclient.cwCustomerName#</cfoutput>'<cfelse>this account</cfif>.</p>
				</cfif>
			</cfcase>			
			<!--- PRODUCT VIEWS --->
			<cfcase value="views">
				<h3 class="CWformSectionTitle">Recently Viewed Items</h3>
				<div class="headSpace"></div>
				<cfloop list="#session.cwclient.cwProdViews#" index="pp">
					<!--- show the product include --->
					<div class="CWrecentProduct">
						<cfmodule
							template="cwapp/mod/cw-mod-productpreview.cfm"
							product_id="#pp#"
							add_to_cart="#application.cw.appDisplayListingAddToCart#"
							show_description="false"
							show_image="true"
							show_price="false"
							image_class="CWimgRecent"
							image_position="above"
							title_position="below"
							details_link_text=""
							>
					</div>
				</cfloop>
				<div class="CWclear"></div>
			</cfcase>
			<!--- CUSTOMER INFO FORM (default) --->
			<cfdefaultcase>
				<!--- heading / submit button text for logged in vs. new customer --->
				<cfif session.cwclient.cwCustomerID is 0 OR session.cwclient.cwCustomerType is 0
					or (isDefined('session.cwclient.cwCustomerCheckout') and session.cwclient.cwCustomerCheckout is 'guest')>
					<h3 class="CWformSectionTitle">New Customers: Complete Details Below</h3>
					<cfset submitButtonText = "Create Account&nbsp;&raquo;">
				<cfelse>
					<h3 class="CWformSectionTitle">Address &amp; Account Details</h3>
					<cfset submitButtonText = "Save Changes&nbsp;&raquo;">
				</cfif>
				<cfmodule template="cwapp/mod/cw-mod-formcustomer2.cfm"
					success_url="#request.cwpage.hrefUrl#"
					submit_value="#submitButtonText#">
			</cfdefaultcase>
		</cfswitch>
		<!--- /end alerts --->
	</div>
	<!--- /end customer account section --->
</div>
<!--- page end / debug --->
<cfinclude template="cwapp/inc/cw-inc-pageend.cfm">