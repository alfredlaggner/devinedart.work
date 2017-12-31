<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: admin-home.cfm
File Date: 2012-02-01
Description:
Default Home page for store admin area
==========================================================
--->
<!--- GLOBAL INCLUDES --->
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("any")>
<!--- define showtab to set up default tab display --->
<cfparam name="url.showtab" type="numeric" default="1">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("showtab,userconfirm,useralert,sortby,sortdir")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Store Administration">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Store Administration Main Page">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = "Select an option from the navigation menu or view system highlights below">
</cfsilent>
<!--- START OUTPUT --->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head>
		<cfoutput>
		<title>#application.cw.companyName# : #request.cwpage.title#</title>
		</cfoutput>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<!-- admin styles -->
		<link href="css/cw-layout.css" rel="stylesheet" type="text/css">
		<link href="theme/<cfoutput>#application.cw.adminThemeDirectory#</cfoutput>/cw-admin-theme.css" rel="stylesheet" type="text/css">
		<!-- admin javascript -->
		<cfinclude template="cwadminapp/inc/cw-inc-admin-scripts.cfm">
		<!--- jquery for form show/hide --->
		<script type="text/javascript">
		jQuery(document).ready(function(){
			jQuery('#showProductSearchLink').click(function(){
				jQuery('form#formProductSearch').show();
				jQuery(this).hide();
			});
			jQuery('#showOrderSearchLink').click(function(){
				jQuery('form#formOrderSearch').show();
				jQuery(this).hide();
			});
			jQuery('#showCustomerSearchLink').click(function(){
				jQuery('form#formCustomerSearch').show();
				jQuery(this).hide();
			});
		});
		// end jquery
		</script>
	</head>
	<!--- body gets a class to match the filename --->
	<body <cfoutput>class="#listFirst(request.cw.thisPage, '.')#"</cfoutput>>
		<div id="CWadminWrapper">
			<!-- Navigation Area -->
			<div id="CWadminNav">
				<div class="CWinner">
					<cfinclude template="cwadminapp/inc/cw-inc-admin-nav.cfm">
				</div>
				<!-- /end CWinner -->
			</div>
			<!-- /end CWadminNav -->
			<!-- Main Content Area -->
			<div id="CWadminPage">
				<!-- inside div to provide padding -->
				<div class="CWinner">
					<!--- page start content / dashboard --->
					<cfinclude template="cwadminapp/inc/cw-inc-admin-page-start.cfm">
					<cfif len(trim(request.cwpage.heading1))><cfoutput><h1>#trim(request.cwpage.heading1)#</h1></cfoutput></cfif>
					<cfif len(trim(request.cwpage.heading2))><cfoutput><h2>#trim(request.cwpage.heading2)#</h2></cfoutput></cfif>
					<!--- user alerts --->
					<cfinclude template="cwadminapp/inc/cw-inc-admin-alerts.cfm">
					<!-- Page Content Area -->
					<div id="CWadminContent">
						<!-- //// PAGE CONTENT ////  -->
						<!-- TABBED SEARCH LAYOUT -->
						<div id="CWadminHomeSearch">
							<div id="CWadminTabWrapper">
								<!-- TAB LINKS -->
								<ul class="CWtabList">
									<!--- product search --->
									<cfif request.cwpage.accessLevel is not 'service'>
										<cfif application.cw.adminWidgetSearchProducts>
											<li><a href="#tab1" title="Search Products">Search Products</a></li>
										</cfif>
									</cfif>
									<!--- order search --->
									<cfif application.cw.adminWidgetSearchOrders>
										<li><a href="#tab2" title="Search Orders">Search Orders</a></li>
									</cfif>
									<!--- customer search --->
									<cfif application.cw.adminWidgetSearchCustomers>
										<li><a href="#tab3" title="Search Customers">Search Customers</a></li>
									</cfif>
								</ul>
								<!--- WIDGETS --->
								<!--- SEARCH TABS --->
								<div class="CWtabBox">
									<!--- product search --->
									<cfif request.cwpage.accessLevel is not 'service'>
										<cfif application.cw.adminWidgetSearchProducts>
											<div id="tab1" class="tabDiv">
												<cfinclude template="cwadminapp/inc/cw-admin-widgets/cw-inc-admin-widget-search-products.cfm">
											</div>
										</cfif>
									</cfif>
									<!--- order search --->
									<cfif application.cw.adminWidgetSearchOrders>
										<div id="tab2" class="tabDiv">
											<cfinclude template="cwadminapp/inc/cw-admin-widgets/cw-inc-admin-widget-search-orders.cfm">
										</div>
									</cfif>
									<!--- cutomer search --->
									<cfif application.cw.adminWidgetSearchCustomers>
										<div id="tab3" class="tabDiv">
											<cfinclude template="cwadminapp/inc/cw-admin-widgets/cw-inc-admin-widget-search-customers.cfm">
										</div>
									</cfif>
								</div>
								<div class="clear"></div>
							</div>
						</div>
						<!--- /END SEARCH TABS --->
						<div class="clear"></div>
						<cfset request.cwpage.widgetCt = 0>
						<!--- recent orders --->
						<cfif application.cw.adminWidgetOrders>
							<cfinclude template="cwadminapp/inc/cw-admin-widgets/cw-inc-admin-widget-orders.cfm">
							<cfset request.cwpage.widgetCt = request.cwpage.widgetCt + 1>
						</cfif>
						<!--- top products--->
						<cfif request.cwpage.accessLevel is not 'service'>
							<cfif application.cw.adminWidgetProductsBestselling>
								<cfinclude template="cwadminapp/inc/cw-admin-widgets/cw-inc-admin-widget-products-bestselling.cfm">
								<cfset request.cwpage.widgetCt = request.cwpage.widgetCt + 1>
							</cfif>
						</cfif>
						<cfif request.cwpage.widgetCt is 2>
							<div class="clear"></div>
						</cfif>
						<!--- top customers --->
						<cfif application.cw.adminWidgetCustomers>
							<cfinclude template="cwadminapp/inc/cw-admin-widgets/cw-inc-admin-widget-customers.cfm">
							<cfset request.cwpage.widgetCt = request.cwpage.widgetCt + 1>
						</cfif>
						<cfif request.cwpage.widgetCt MOD 2 is 0>
							<div class="clear"></div>
						</cfif>
						<!--- recently added/modified products--->
						<cfif request.cwpage.accessLevel is not 'service'>
							<cfif application.cw.adminWidgetProductsRecent>
								<cfinclude template="cwadminapp/inc/cw-admin-widgets/cw-inc-admin-widget-products-recent.cfm">
								<cfset request.cwpage.widgetCt = request.cwpage.widgetCt + 1>
							</cfif>
						</cfif>
					</div>
					<!-- /end Page Content -->
				</div>
				<!-- /end CWinner -->
			</div>
			<!--- page end content / debug --->
			<cfinclude template="cwadminapp/inc/cw-inc-admin-page-end.cfm">
			<!-- /end CWadminPage-->
			<div class="clear"></div>
		</div>
		<!-- /end CWadminWrapper -->
	</body>
</html>