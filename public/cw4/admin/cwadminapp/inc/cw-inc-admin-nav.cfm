<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-nav.cfm
File Date: 2012-04-01
Description: Creates admin navigation menu markup
Add to navList section below to modify the menu
==========================================================
--->
<!--- //////////// --->
<!--- Edit this list to add/remove menu links  --->
<!--- //////////// --->
<cfparam name="session.cw.accessLevel" default="">
<cfparam name="session.cw.adminNav" default="">
<!--- build navigation, store in session --->
<cfif not len(session.cw.adminNav)>
<!--- note : starting number groups sub-lists --->
<cfsavecontent variable="request.cwpage.navList">
<!--- HOME MENU --->
	1|admin-home.cfm|Admin Home,
	1|admin-home.cfm|Site Overview,
<!--- PRODUCTS MENU --->
<cfif listFindNoCase('developer,merchant,manager',session.cw.accessLevel)>
	2|products.cfm|Products,
	2|products.cfm|Active Products,
	2|products.cfm?view=arch|Archived Products,
	2|product-details.cfm|Add New Product,
	2|product-images.cfm|Product Images,
	2|product-files.cfm|Product Files,
	<cfif listFindNoCase('developer',session.cw.accessLevel)>
	2|product-images.cfm?mode=type|Image Setup,
	</cfif>
</cfif>
<!--- ORDERS MENU --->
	3|orders.cfm|Orders,
	3|orders.cfm|All Orders,
	<cfoutput>#CWqueryNavOrders(3)#</cfoutput>
<!--- CUSTOMERS MENU --->
	4|customers.cfm|Customers,
	4|customers.cfm|Manage Customers,
<cfif listFindNoCase('developer,merchant,manager',session.cw.accessLevel)>
	4|customer-details.cfm|Add New Customer,
	<cfif listFindNoCase('developer,merchant',session.cw.accessLevel)>
		4|customer-types.cfm|Manage Customer Types,
	</cfif>
<!--- CATEGORIES MENU --->
	5|categories-main.cfm|Categories,
	5|categories-main.cfm|<cfoutput>#application.cw.adminLabelCategories#</cfoutput>,
	5|categories-main.cfm?clickadd=1|Add New <cfoutput>#listFirst(application.cw.adminLabelCategory, ' ')#</cfoutput>,
	5|categories-secondary.cfm|<cfoutput>#application.cw.adminLabelSecondaries#</cfoutput>,
	5|categories-secondary.cfm?clickadd=1|Add New <cfoutput>#listFirst(application.cw.adminLabelSecondary, ' ')#</cfoutput>,
<!--- OPTIONS MENU --->
	6|options.cfm|Options,
	6|options.cfm|Manage Options,
	6|option-details.cfm|Add New Option Group,
<!--- DISCOUNTS MENU --->
	<cfif application.cw.discountsEnabled and listFindNoCase('developer,merchant',session.cw.accessLevel)>
	7|discounts.cfm|Discounts,
	7|discounts.cfm|Active Discounts,
	7|discounts.cfm?view=arch|Archived Discounts,
	7|discount-details.cfm|Add New Discount,
	</cfif>
</cfif>
<!--- SHIPPING / TAX MENU --->
<cfif listFindNoCase('developer,merchant',session.cw.accessLevel)>
	8|ship-methods.cfm|Shipping/<cfoutput>#application.cw.taxSystemLabel#</cfoutput>,
	8|countries.cfm|Countries/Regions,
	<cfif NOT (isDefined('application.cw.taxsystem') AND application.cw.taxSystem neq 'groups')>
	8|ship-extensions.cfm|Locale Extensions,
	<cfelse>
	8|ship-extensions.cfm|Ship/<cfoutput>#application.cw.taxSystemLabel#</cfoutput> Extensions,
	</cfif>
	8|ship-methods.cfm|Shipping Methods,
	8|ship-ranges.cfm|Shipping Ranges,
	<cfif session.cw.accessLevel is 'developer'>
	8|ship-status.cfm|Ship / Order Status,
	8|config-settings.cfm?group_id=6|Shipping Settings,
	8|config-settings.cfm?group_id=5|<cfoutput>#application.cw.taxSystemLabel#</cfoutput> Settings,
	</cfif>
	<cfif NOT (isDefined('application.cw.taxsystem') AND application.cw.taxSystem neq 'groups')>
	8|tax-groups.cfm|<cfoutput>#application.cw.taxSystemLabel#</cfoutput> Groups,
	<cfif application.cw.taxCalctype eq 'localTax'>8|tax-regions.cfm|<cfoutput>#application.cw.taxSystemLabel#</cfoutput> Regions,</cfif>
	</cfif>
<!--- STORE SETTINGS --->
	9|config-settings.cfm?group_id=3|Store Settings,
	9|config-settings.cfm?group_id=3|Company Info,
	9|credit-cards.cfm|Credit Cards,
	<cfif session.cw.accessLevel is 'developer'>
	9|config-settings.cfm?group_id=11|Discount Settings,
	</cfif>
	9|config-settings.cfm?group_id=6|Shipping Settings,
	9|config-settings.cfm?group_id=5|<cfoutput>#application.cw.taxSystemLabel#</cfoutput> Settings,
<!--- ADMIN SETTINGS --->
	<cfif session.cw.accessLevel is 'developer'>
	10|config-settings.cfm?group_id=7|Admin Settings,
	<cfelse>
	10|admin-users.cfm|Admin Users,
	</cfif>
	10|admin-users.cfm|Admin Users,
	<cfif session.cw.accessLevel is 'developer'>
	10|config-settings.cfm?group_id=7|Admin Controls,
	10|config-settings.cfm?group_id=15|Admin Widgets,
	10|config-settings.cfm?group_id=24|Product Admin,
	</cfif>
<!--- CUSTOM VARIABLES --->
<!--- if logged in as developer, top level link goes to 'config groups' --->
	<cfif session.cw.accessLevel is 'developer'>
	11|config-groups.cfm|Site Setup,
	11|config-groups.cfm|Configuration Variables,
	<cfif isDefined('application.cw.appDataDeleteEnabled') and application.cw.appDataDeleteEnabled>11|db-handler.cfm?mode=testdata|Delete Test Data,</cfif>
	<!--- if logged in as merchant, top level link is first available group --->
	<cfelse>
		<!--- QUERY: function creates top level link for config section
		(Nav Counter, IDs to Omit, number of rows to return) --->
		<cfoutput>#CWqueryNavConfig(11,'3,5,6,7,11,15,24',1)#</cfoutput>
	</cfif>
	<!--- create the rest of the config menu --->
	<!--- QUERY: function creates custom  settings links for config menu
	(Nav Counter, IDs to Omit) --->
		<cfoutput>#CWqueryNavConfig(11,'3,5,6,7,11,15,24')#</cfoutput>
</cfif>
<!--- end user level check --->
</cfsavecontent>
<!--- store nav page list in session --->
<cfset session.cw.adminNav = request.cwpage.navList>
	<!--- if already in session, add to page request --->
	<cfelse>
<cfset request.cwpage.navList = session.cw.adminNav>
</cfif>

<!--- starting values for list functions --->
<cfset lastLinkcount=0>
<cfset selectedgroup = 0>
<cfset isstarted = 0>
<cfset firstParent=1>
<cfset firstChild=1>

</cfsilent>
<!--- START OUTPUT--->
<!--- admin logo --->
<a href="admin-home.cfm" title=""><img src="img/cw-logo.png" alt="Admin Home" width="180" id="imgLogo"></a>
<!--- //////////// --->
<!--- Do Not Edit Beyond This Point --->
<!--- //////////// --->
<!--- create dynamic 'on' states by looking at the URL of the current page OR current page 'currentNav' variable --->
<cfoutput>
<ul id="CWadminNavUL">
	<cfset linkCt = 1>
	<!--- loop the list, find selected group--->
	<cfloop list="#request.cwpage.navList#" index="pl">
		<cfif len(trim(pl))>
			<cfset thisLink=trim(listgetat(pl, 2, '|'))>
			<cfset thisLinkgroup=trim(listFirst(pl, '|'))>
			<cfif (not isDefined('request.cwpage.currentNav') AND trim(listLast(cgi.SCRIPT_NAME,'/')) is trim(thisLink))
				OR (isDefined('request.cwpage.currentNav') AND trim(request.cwpage.currentNav) is trim(thisLink))>
				<cfset selectedgroup=thisLinkgroup>
			</cfif>
		</cfif>
	</cfloop>
	<!--- loop the list, create links --->
	<cfloop list="#request.cwpage.navList#" index="pl">
		<cfif len(trim(pl))>
			<cfsilent>
			<cfset thisLinkcount=trim(listFirst(pl, '|'))>
			<cfset thisLink=trim(listgetat(pl, 2, '|'))>
			<cfset thisLinkText=trim(listLast(pl,'|'))>
			<!--- set up the class for each link --->
			<cfif linkCt eq 1>
				<cfset thisClass = "firstLink">
			<cfelse>
				<cfset thisClass="">
			</cfif>
			<cfif (selectedgroup eq thisLinkcount and thisLinkcount neq lastLinkcount)>
				<cfset thisClass="#thisClass# currentLink">
			</cfif>
			</cfsilent>
			<cfif isstarted eq 0>
				<li>
					<cfset isstarted = 1>
				<cfelse>
					<cfif thislinkcount eq lastlinkcount>
						<cfif firstChild eq 1>
							<ul>
								<li>
									<cfset firstChild=0>
									<cfset firstParent=1>
								<cfelse>
								</li>
								<li>
							</cfif>
						<cfelseif firstParent eq 1 and firstChild eq 0>
						</li>
					</ul>
			</li>
			<li>
				<cfset firstChild = 1>
			<cfelseif firstParent eq 1 and firstChild eq 1>
			</li>
			<li>
		</cfif>
</cfif>
<cfif isDefined('request.cwpage.currentNav') AND trim(request.cwpage.currentNav) is trim(thisLink)
	AND NOT thisClass contains 'currentLink'>
	<cfset thisClass = thisClass & ' currentLink'>
</cfif>
<a href="#thisLink#" <cfif len(trim(thisClass))>class="#trim(thisClass)#"</cfif>>
#thisLinkText#</a>
<cfset lastlinkcount = thislinkcount>
</cfif>
<cfset linkCt = linkCt + 1>
</cfloop>
</li>
</ul>
</cfoutput>
</li>
</ul>
