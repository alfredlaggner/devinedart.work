<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-func-init.cfm
File Date: 2013-01-28
Description: handles initialization functions for the Cartweaver application
Values are set for each page request, and for the cart application
To reset the application variables, log in to the Cartweaver admin
as a developer-level user and click the "Reset" link
==========================================================
--->

<!--- // ---------- // CWinitApplication: initialize application scope variables, runs at application startup or reset  // ---------- // --->
<cffunction name="CWinitApplication"
	access="public"
	output="false"
	returntype="void"
	hint="Creates application scope variables"
	>

	<cfargument name="fullReset"
			required="false"
			default="false"
			type="boolean"
			hint="If set to true, forces reset of all application variables regardless of login status - use for manual reset">

	<cfset var i = ''>
	<cfset var ii = ''>
	<cfset var loopCt = ''>
	<cfset var temp = ''>
	
	<!--- set store/company information in application variables --->
	<cflock type="exclusive" scope="application" timeout="10" throwontimeout="no">
		<!--- RESET CW APPLICATION VARIABLES --->
		<cfparam name="URL.resetapplication" type="string" default="">
		<cfparam name="application.cw.debugPassword" type="string" default="">
		<cfparam name="request.cwpage.userAlert" default="">
		<cfparam name="request.cwpage.categoryID" default="0">
		<cfparam name="request.cwpage.secondaryID" default="0">
		<!--- reset application.cw if key variable (site url) does not exist,
		 	  or if logged in as admin and url.resetapplication=[debugPassword]--->
		<cfif (not isDefined('application.cw.appSiteUrlHttp'))
			OR arguments.fullReset eq true
			OR (
			URL.resetapplication eq application.cw.debugPassword
			and isDefined('session.cw.loggedIn') and session.cw.loggedIn is '1'
			and isDefined('session.cw.accessLevel') and	listFindNoCase('developer,merchant',session.cw.accessLevel)
			)>
			<!--- turn off debugging --->
			<cfif isDefined('session.cw.debug')>
				<cfset session.cw.debug = 'false'>
			</cfif>
			<!--- reset admin nav caching --->
			<cfset session.cw.adminNav = ''>
			<!--- get all configuration settings from the database --->
			<cftry>
			<cfquery name="configQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
				SELECT config_variable, config_value FROM cw_config_items ORDER BY config_variable
			</cfquery>
			<!--- if this query throws an error, we cannot set up the CW database. Message is shown to customer. --->
			<cfcatch>
				<p>Error: Database Unavailable<br>Please refer to the Cartweaver installation instructions, and verify the database and data connection are set up correctly.</p>
				<cfabort>
			</cfcatch>
			</cftry>
			<!--- clear out application.cw, except specified settings --->
			<cfset variables.persistedVars = 'dsn,dsnUsername,dsnPassword,appIncludePath,dbok'>
			<cfloop collection="#application.cw#" item="i">
				<cfif not listFindNoCase(variables.persistedVars,i)>
					<cfset structDelete(application.cw,i)>
				</cfif>
			</cfloop>
			<!--- set all configuration values as application variables --->
			<cfloop query="configQuery">
				<cftry>
					<cfset application.cw[configQuery.config_variable] = trim(configQuery.config_value)>
					<cfcatch>
						<!--- any variable with error shows alert--->
						<cfset request.cwpage.userAlert = request.cwpage.userAlert & 'Error with variable #configQuery.config_variable#: #cfcatch.message#<br>'>
					</cfcatch>
				</cftry>
			</cfloop>
			<!--- marker for confirmation message --->
			<cfset request.cwpageReset = true>
			<!--- debugging password --->
			<cfset application.cw.storePassword = application.cw.debugPassword>
			<!--- set up root file path --->
			<cfset application.cw.siteRoot = '/'>
			<cfset application.cw.siteRootPath = replaceNoCase(expandPath(application.cw.siteRoot), '\','/','all')>	
			<cfif right(application.cw.siteRootPath,1) neq '/'>
				<cfset application.cw.siteRoothPath = application.cw.siteRootPath & '/'>
			</cfif>
			<!--- verify developer email is valid, or use company email --->
			<cfif application.cw.developerEmail eq '' or not isValid('email',application.cw.developerEmail)>
				<cfset application.cw.developerEmail = application.cw.companyEmail>
			</cfif>
			<!--- SET DEFAULT COUNTRY --->
			<cfquery name="rsCWDefaultCountry" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
				SELECT country_id FROM cw_countries WHERE country_default_country = 1
			</cfquery>
			<cfif rsCWDefaultCountry.recordCount gt 0>
				<cfset application.cw.defaultCountryID = rsCWDefaultCountry.country_id>
			<cfelse>
				<cfset application.cw.defaultCountryID = 0>
			</cfif>
			<!--- DATABASE TYPES: manage SQL differences used in query functions --->
			<cfparam name="application.cw.appDbType" default="mySQL">
			<!--- ms access --->
			<cfif application.cw.appDbType is 'MSAccess' or application.cw.appDbType is 'MSAccessJet'>
				<cfset application.cw.sqlLower = 'lcase'>
				<cfset application.cw.sqlUpper = 'ucase'>
				<!--- mysql, mssql --->
			<cfelse>
				<cfset application.cw.sqlLower = 'lower'>
				<cfset application.cw.sqlUpper = 'uppper'>
			</cfif>
			<!--- SITE URLS --->
			<!--- clean up application URL variables --->
			<cfif not (isValid('url',application.cw.appSiteUrlHttp) and left(application.cw.appSiteUrlHttp,5) eq 'http:')>
				<cfset application.cw.appSiteUrlHttp = 'http://' & cgi.server_name>
			</cfif>
			<!--- add trailing slash to http and https urls --->
			<cfif right(application.cw.appSiteUrlHttp,1) neq "/">
				<cfset application.cw.appSiteUrlHttp = application.cw.appSiteUrlHttp & "/">
			</cfif>
			<cfif len(trim(application.cw.appSiteUrlHttps)) and right(application.cw.appSiteUrlHttps,1) neq "/">
				<cfset application.cw.appSiteUrlHttps = application.cw.appSiteUrlHttps & "/">
			</cfif>
			<!--- remove trailing slash from storeroot, for use below --->
			<cfif left(application.cw.appCwstoreRoot,1) is '/' and len(trim(application.cw.appCwstoreRoot)) gt 1>
				<cfset variables.urlRoot = right(application.cw.appCwStoreRoot,len(application.cw.appCwstoreRoot)-1)>
			<cfelseif application.cw.appCwstoreRoot is '/'>
				<cfset variables.urlRoot = ''>
			<cfelse>
				<cfset variables.urlRoot = application.cw.appCwstoreRoot>
			</cfif>
			<!--- SECURE / STANDARD FULL URLS --->
			<!--- CHECKOUT and ACCOUNT pages use HTTPS, if an https address is provided in the admin (site setup > global settings) --->
			<cfif isValid('url',application.cw.appSiteUrlHttps) and left(application.cw.appSiteUrlHttps,6) eq 'https:'>
				<!--- verify checkout page is not already a full url --->
				<cfif REFindNoCase('http[s]?\:\/\/',application.cw.appPageCheckOut) eq 0>
					<!--- add the prefix and any additional path, resulting in https:// url for the checkout page --->
					<cfset application.cw.appPageCheckoutUrl = application.cw.appSiteUrlHttps & variables.urlRoot & application.cw.appPageCheckOut>
				</cfif>
				<!--- verify account page is not already a full url --->
				<cfif REFindNoCase('http[s]?\:\/\/',application.cw.appPageAccount) eq 0>
					<!--- add the prefix and any additional path, resulting in https:// url for the account page --->
					<cfset application.cw.appPageAccountUrl = application.cw.appSiteUrlHttps & variables.urlRoot & application.cw.appPageAccount>
				</cfif>
			<!--- if no https url is provided, set the remaining URLs with http address --->			
			<cfelse>
				<cfset application.cw.appPageCheckoutUrl = application.cw.appSiteUrlHttp & variables.urlRoot & application.cw.appPageCheckOut>
				<cfset application.cw.appPageAccountUrl = application.cw.appSiteUrlHttp & variables.urlRoot & application.cw.appPageAccount>
			</cfif>
			<!--- ALL OTHER PAGES use HTTP --->
			<!---
			NOTE: these are available in the application scope as full urls at any time, but not enforced
			(instead, non-ssl redirection is handled with a global isSecure() function)
			to override relative links in your store, set the values of the corresponding request.cwpage variables for these pages in CWinitRequest()
			--->
			<cfif REFindNoCase('http[s]?\:\/\/',application.cw.appPageResults) eq 0>
				<cfset application.cw.appPageResultsUrl = application.cw.appSiteUrlHttp & variables.urlRoot & application.cw.appPageResults>
			<cfelse>
				<cfset application.cw.appPageResultsUrl = application.cw.appPageResults>
			</cfif>
			<cfif REFindNoCase('http[s]?\:\/\/',application.cw.appPageDetails) eq 0>
				<cfset application.cw.appPageDetailsUrl = application.cw.appSiteUrlHttp & variables.urlRoot & application.cw.appPageDetails>
			<cfelse>	
				<cfset application.cw.appPageDetailsUrl = application.cw.appPageDetails>
			</cfif>
			<cfif REFindNoCase('http[s]?\:\/\/',application.cw.appPageShowCart) eq 0>
				<cfset application.cw.appPageShowCartUrl = application.cw.appSiteUrlHttp & variables.urlRoot & application.cw.appPageShowCart>
			<cfelse>	
				<cfset application.cw.appPageShowCartUrl = application.cw.appPageShowCart>
			</cfif>
			<cfif REFindNoCase('http[s]?\:\/\/',application.cw.appPageConfirmOrder) eq 0>
				<cfset application.cw.appPageConfirmOrderUrl = application.cw.appSiteUrlHttp & variables.urlRoot & application.cw.appPageConfirmOrder>
			<cfelse>	
				<cfset application.cw.appPageConfirmOrderUrl = application.cw.appPageConfirmOrder>
			</cfif>
			<!--- PRODUCTS: store product details in application scope --->
			<cfset temp = CWinitProductData()>
			<!--- SKUS: store sku data in application scope --->
			<cfset temp = CWinitSkuData()>
			<!--- CATEGORIES: store category names, IDs in application scope --->
			<cfset temp = CWinitCategoryData(1)>
			<!--- SECONDARY CATEGORIES: store category names, IDs in application scope --->
			<cfset temp = CWinitCategoryData(2)>
			<!--- SHIPPING METHODS: if no active ship methods, turn shipping off globally --->
			<cfif application.cw.shipEnabled>
				<cfquery name="shipMethodsQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
					SELECT m.ship_method_id, c.ship_method_country_country_id
					FROM cw_ship_methods m, cw_ship_method_countries c, cw_countries co
					WHERE c.ship_method_country_method_id = m.ship_method_id
					and co.country_id = c.ship_method_country_country_id
					and not m.ship_method_archive = 1
					and not co.country_archive = 1
				</cfquery>
				<cfif shipMethodsQuery.recordCount lt 1>
					<cfset application.cw.shipEnabled = false>
				</cfif>
			</cfif>
			<!--- PAYMENT METHODS --->
			<!--- set up array for payment options --->
			<cfset variables.authoptions = arrayNew(1)>
			<!--- set up list of possible values --->
			<cfset variables.authConfigOptions = ''>
			<!--- set up list of active IDs --->
			<cfset variables.authMethods = ''>
			<!--- get auth methods from directory --->
			<cfif left(application.cw.appCWContentDir,1) is '/'>
				<cfset variables.contentDir = right(application.cw.appCWContentDir,len(application.cw.appCWContentDir)-1)>
			<cfelse>
				<cfset variables.contentDir = application.cw.appCWContentDir>
			</cfif>
			<cfif not right(variables.contentDir,'1') is '/'>
				<cfset variables.contentDir = variables.contentDir & '/'>
			</cfif>
			<cfset variables.authDirectory = application.cw.siteRootPath & variables.contentDir & 'cwapp/auth'>
			<cfset application.cw.authDirectory = variables.authDirectory>
			<!--- show warning if directory unavailable --->
			<cfif not directoryExists(application.cw.authDirectory)>
				<cfset request.cwpage.userAlert = request.cwpage.userAlert & 'WARNING: Unable to open payment methods directory: #variables.authDirectory#  <br>'>
				<cfif isDefined('session.cw.accessLevel') and session.cw.accessLevel is 'developer'>
					<cfset request.cwpage.userAlert = request.cwpage.userAlert & 'Adjust setting for CW Content Path: #application.cw.appCWcontentDir#<br>'>
				</cfif>
			<cfelse>
			<!--- get all available files in auth directory --->
			<cfdirectory action="list" directory="#variables.authDirectory#" name="listAuthFiles" filter="*.cfm">
			<!--- loop files --->
			<cfset loopCt = 1>
			<cfloop query="listAuthFiles">
				<!--- invoke file as cfmodule to get payment info --->
				<cfmodule template="../auth/#listAuthFiles.Name#"
					auth_mode="config">
				<!--- data about this payment method is returned in the 'CWauthMethod' scope --->
				<cfif isDefined('CWauthMethod')>
					<!--- add filename to struct --->
					<cfset CWauthMethod.methodFileName = listAuthFiles.name>
					<!--- add key array value to struct --->
					<cfset CWauthMethod.methodID = listAuthFiles.currentRow>
					<!--- add struct to array --->
					<cfset variables.authOptions[loopCt] = CWauthMethod>
					<!--- save possible values for paymentMethods config variable --->
					<cfset variables.optionSet = CWauthMethod.methodName & '|' & CWauthMethod.methodFileName>
					<cfset variables.authConfigOptions = listAppend(variables.authConfigOptions,variables.optionSet,chr(13))>
					<!--- increment the counter --->
					<cfset loopCt = loopCt + 1>
				</cfif>
			</cfloop>
			</cfif>
			<!--- set the array of payment options data into application scope --->
			<cfset application.cw.authMethodData = variables.authOptions>
			<!--- set the possible values of the config item "paymentMethods" --->
			<cfquery datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
				UPDATE cw_config_items SET config_possibles = '#variables.authConfigOptions#' WHERE config_variable = 'paymentMethods'
			</cfquery>
			<!--- compare to active options list, removing others --->
			<cfloop array="#application.cw.authMethodData#" index="i">
				<!--- if filename matches selected config value, add to list of active options --->
				<cfif listFindNoCase(application.cw.paymentMethods,i.methodFileName)>
					<cfset variables.authmethods = listAppend(variables.authmethods,i.methodID)>
				</cfif>
			</cfloop>
			<!--- save active methods to application scope --->
			<cfset application.cw.authMethods = variables.authMethods>
			<!--- delete temp variables --->
			<cfset structDelete(variables,'authMethods')>
			<cfset structDelete(variables,'authConfigOptions')>
			<cfset structDelete(variables,'persistedVars')>
			<!--- DEFAULTS FOR CONFIG VARIABLES (application.cw.xxx) --->
			<cfinclude template="../inc/cw-inc-configdefaults.cfm">
			
			<!--- PLUGINS --->			
			<cfset variables.pluginDirectory = application.cw.siteRootPath & variables.contentDir & 'plugins'>
			<cfset variables.listPluginDirs = arrayNew(1)>
			<cfset variables.listPluginConfigs = arrayNew(1)>
			<cfset application.cw.pluginDirectory = variables.pluginDirectory>
			<cfif directoryExists(application.cw.pluginDirectory)>
				<!--- get all available files in plugin directory --->
				<cfdirectory action="list" directory="#variables.pluginDirectory#" name="listPluginFiles" filter="config.cfm" recurse="true">
				<!--- loop files --->
				<cfset loopCt = 1>
				<cfloop query="listPluginFiles">
					<cfset variables.listPluginDirs[loopCt] = listLast(replace(listPluginFiles.directory,'\','/','all'),'/')>
					<cfset variables.listPluginConfigs[loopCt] = listPluginFiles.directory & '/' & listPluginFiles.name>
				</cfloop>
			</cfif>
			<!--- /end if plugin directory exists --->	
			<!--- set directory names into array --->
			<cfset application.cw.pluginDirectories = variables.listPluginDirs>
			<!--- set full config file paths into array --->
			<cfset application.cw.pluginConfigs = variables.listPluginConfigs>
		</cfif>		
	</cflock>
</cffunction>

<!--- // ---------- // CWinitRequest : initialize request scope variables, runs on every page request  // ---------- // --->
<cffunction name="CWinitRequest"
	access="public"
	output="false"
	returntype="void"
	hint="Run on each page request. Creates request scope variables, manages recent products and continue shopping links"
	>

	<cfset var temp = ''>
	<cfset var pageCt = 0>
	<cfset var prodCt = 0>
	<cfset var viewProdCt = 0>
	<cfset var viewSaveCt = 0>
	<cfset var cc = 0>
	<cfset var pp = 0>
	<cfset var vv = 0>
	<cfset var i = 0>
	<cfset var varName = ''>
	<cfset var returnUrlQS = ''>
	
	<!--- VERIFY APPLICATION VARS HAVE BEEN SET --->
	<cfif not isDefined('application.cw.appCwAdminDir')>
		<cfset temp = CWinitApplication(fullreset=true)>
	</cfif>
	<!--- GLOBAL FILE/PATH VARIABLES  --->
	<!--- current page filename : request.cw.thisPage (can be overridden with request.path) --->
	<cfif isDefined('request.path')>
		<cfset request.cw.thisPage = listLast(request.path,'/')>
	<cfelse>
		<cfset request.cw.thisPage = GetFileFromPath(GetTemplatePath())>
	</cfif>
	
	<!--- current page filename with query string : request.cw.thisPageQS --->
	<cfset request.cw.thisPageQS = CWcleanUrl(request.cw.thisPage,cgi.query_string)>
	<!--- default logout url --->
	<cfparam name="request.cwpage.logoutUrl" default="#request.cw.thisPageQS#">
	<!--- get page context for URL lookup and secure redirection --->
	<cfset request.cw.requestContext = getPageContext().getRequest()>
	<!--- if page is not a required secure page, redirect back to http --->
	<cfset request.cw.sslPages = "#application.cw.appPageCheckout#,#application.cw.appPageAccount#">
	<!--- entire page url: request.cw.thisUrl --->
	<cfset  request.cw.thisUrl = toString(request.cw.requestContext.GetRequestUrl())>
	<!--- current directory url: request.cw.thisDir --->
	<cfset request.cw.thisDir = left(request.cw.thisUrl, len(request.cw.thisUrl) - len(listLast(request.cw.thisUrl,'/')))>
	<cfif not right(request.cw.thisDir,1) is '/'>
		<cfset request.cw.thisDir = request.cw.thisDir & '/'>
	</cfif>
	<!--- append query string to url variable --->
	<cfif len(cgi.query_string )>
		<cfset request.cw.thisUrl = CWcleanUrl(request.cw.thisUrl,cgi.query_string)>
	</cfif>	
	<!--- current directory name: request.cw.thisDirName --->
	<cfset request.cw.thisDirName = listLast(left(request.cw.thisDir, len(request.cw.thisDir)-1), '/')>
	<!--- admin directory name: request.cw.adminDirName --->
	<cfset request.cw.adminDirName = listLast(replace(application.cw.appCwAdminDir,'/',',','all'))>
	<!--- src directory for scripts, other relative assets --->
	<cfparam name="application.cw.appCWassetsDir" default="cw4">
	<cfif right(application.cw.appCWassetsDir,1) is '/'>
		<cfset request.cw.assetSrcDir = application.cw.appCWassetsDir>
	<cfelse>
		<cfset request.cw.assetSrcDir = application.cw.appCWassetsDir & '/'>
	</cfif>
	<!--- if enabled, force https on secure-only pages (checkout, account) --->
	<cfif isDefined('application.cw.appHttpRedirectEnabled') and application.cw.appHttpRedirectEnabled eq true>
			<!---
	 	   IMPORTANT: This process handles redirection between the http and https prefixes, forcing selected pages to be https only, while others are http only.
	 	   Actual creation of https-prefixed links within the store is handled by the checkout URL in the request scope below. 
	 	   This function does not provide SSL protection, which is handled by an SSL certificate installed on the server.
	 	   TO EXTEND HTTPS COVERAGE WITHIN YOUR SITE:
	 	   Add other pages to the request.cw.sslPages variable, as a comma-delimited list (no spaces), to allow use of https without redirection
	 	   or disable the admin setting appHttpRedirectEnabled to turn this off completely.
		 	--->
		<!--- check for https in use - cgi values may vary between servers, so multiple flags are checked here --->
		<cfif left(application.cw.appSiteUrlHttps,6) eq 'https:'
					and listFindNoCase(request.cw.sslPages,request.cw.thisPage)
					and not (request.cw.requestContext.isSecure()
					or cgi.https is 'on'
					or cgi.server_port_secure is '1')>
			<!--- if page is being requested via http, send to https version of same address  --->
			<cflocation url="https://#request.cw.requestContext.getServerName()##request.cw.requestContext.getRequestURI()#?#request.cw.requestContext.getQueryString()#" addtoken="false">
		<!--- for non-https pages, check for https in use - cgi values may vary between servers, so multiple flags are checked here --->
		<cfelseif not listFindNoCase(request.cw.sslPages,request.cw.thisPage) 
					and (request.cw.requestContext.isSecure()
					or cgi.https is 'on'
					or cgi.server_port_secure is '1')
					and request.cw.thisDirName neq request.cw.adminDirName>
			<!--- if page is being requested securely, send to http version of same address  --->
			<cflocation url="http://#request.cw.requestContext.getServerName()##request.cw.requestContext.getRequestURI()#?#request.cw.requestContext.getQueryString()#" addtoken="false">
		</cfif>
	</cfif>	
	<!--- SET LOCALE --->
	<cftry>
		<cfset SetLocale('#application.cw.globalLocale#')>
		<cfcatch>
			<cfset SetLocale('English (US)')>
		</cfcatch>
	</cftry>
	<!--- LOCALE SETTINGS for js currency format --->
	<cfif not (isDefined('application.cw.currencySymbol') and len(trim(application.cw.currencySymbol)))>
		<!--- CURRENCY : store currency details in application scope --->
		<cfset temp = CWinitCurrencyData()>
	</cfif>
	<!--- DEFAULT REQUEST VARS --->
	<!--- ADMIN ONLY --->
	<cfif request.cw.thisDirName eq request.cw.adminDirName>
		<!--- Page Browser Window Title --->
		<cfparam name="request.cwpage.title" default="Store Administration">
		<!--- Page Main Heading <h1> --->
		<cfparam name="request.cwpage.heading1" default="Store Administration">
		<!--- Page Subheading (instructions) <h2> --->
		<cfparam name="request.cwpage.heading2" default="Manage Store Options">
		<!--- location for view site link --->
		<cfparam name="request.cwpage.viewSiteUrl" default="#application.cw.appPageResultsUrl#">
		<!--- view site text --->
		<cfparam name="request.cwpage.viewSiteText" default="View Site">
		<!--- id for menu item to mark current --->
		<cfparam name="request.cwpage.currentNav" default="#listLast(cgi.script_name,'/')#">
		<!--- prefix for relative image path from admin to images dir (default "../") --->
		<cfparam name="request.cwpage.adminImgPrefix" default="../">
	<!--- FRONT END ONLY (site pages, not admin) --->
	<cfelse>
		<!--- page browser title --->
		<cfparam name="request.cwpage.title" default="#application.cw.companyName#">
		<!--- prefix for relative links to admin (default "" - not used) --->
		<cfparam name="request.cwpage.adminUrlPrefix" default="">
	</cfif>
	<!--- /END ADMIN/FRONT END ONLY --->
		<!--- STORE PAGES --->
		<cfloop list="Results,Details,ShowCart,Checkout,ConfirmOrder,Account,Search,Download" index="pp">
		<cftry>
			<cfparam name="request.cwpage.url#trim(pp)#" default="#trim(application.cw.appCwStoreRoot)##evaluate('application.cw.appPage#trim(pp)#')#">
			<cfcatch>
				<cfparam name="request.cwpage.url#trim(pp)#" default="">
			</cfcatch>
		</cftry>
		</cfloop>
		<!--- SECURE PAGES --->
		<!--- if the Secure URL is different than the Site URL, the full https address will be used for the checkout page and account page --->
		<cfif isDefined('application.cw.appPageCheckoutUrl') and isValid('Url',application.cw.appPageCheckoutUrl)>
			<cfset request.cwpage.urlCheckout = application.cw.appPageCheckoutUrl>
		</cfif>
		<cfif isDefined('application.cw.appPageAccountUrl') and isValid('Url',application.cw.appPageAccountUrl)>
			<cfset request.cwpage.urlAccount = application.cw.appPageAccountUrl>
		</cfif>
	<!--- CONFIRM COMPLETED ORDERS (for payments that don't return user to confirmation page automatically) --->
	<cfif request.cw.thisDirName neq request.cw.adminDirName
			and (isDefined('application.cw.appOrderForceConfirm') and application.cw.appOrderForceConfirm eq true)
			and (isDefined('session.cwclient.cwCompleteOrderID') and session.cwclient.cwCompleteOrderID neq '0')
			and not (isDefined('application.cw.appTestModeEnabled') and application.cw.appTestModeEnabled eq true)
				and	not (
					request.cw.thisPage eq request.cwpage.urlCheckout
					or request.cw.thisPage eq request.cwpage.urlConfirmOrder
					or request.cw.thisPage eq listLast(request.cwpage.urlCheckout,'/')
					or request.cw.thisPage eq listLast(request.cwpage.urlConfirmOrder,'/')
					or request.cw.thisPage eq 'reset.cfm'
					)>
		<cflocation url="#request.cwpage.urlConfirmOrder#" addtoken="no">
	</cfif>
	<!--- CHECK FOR COOKIES --->
	<cfif isBoolean(URLSessionFormat('true')) is 'NO'
		and (request.cw.thisPage eq listLast(request.cwpage.urlCheckout,'/')
			or request.cw.thisPage eq listLast(request.cwpage.urlShowCart,'/')
			or request.cw.thisPage eq listLast(request.cwpage.urlAccount,'/')
		)>
		<cfset request.cwpage.userAlert = request.cwpage.userAlert & 'Note: cookies must be enabled in your browser for proper cart functionality<br>'>
	</cfif>
	<!--- COOKIES EXPIRATION DATE--->
	<cfif application.cw.appCookieTerm eq 0>
		<cfset request.cw.cookieExpire = 'NOW'>
	<cfelseif isNumeric(application.cw.appCookieTerm)>
		<cfset request.cw.cookieExpire = createTimeSpan(0,application.cw.appCookieTerm,0,0)>
	<cfelse>
		<cfset request.cw.cookieExpire = 'NEVER'>
	</cfif>
		<!--- COOKIE VARS OVERWRITE BLANKS IN SESSION --->
		<cfif application.cw.appCookieTerm neq 0>
			<!--- vars not to write to session --->
			<cfset request.cw.noCookieSessionVars = 'cfid,cftoken,sessionid,jsessionid,urltoken,cwUserName,cwCustomerType,cwOrderTotal,cwShipCountryID,cwShipregionID,cwShipTotal,cwShipTaxTotal,cwTaxCountryID,cwTaxRegionID,cwTaxTotal,discountApplied,discountPromoCode'>
			<cfloop collection="#cookie#" item="cc">
				<cftry>
					<cfset varName = "session.cwclient.#cc#">
					<!--- if cwclient variable does not already exist --->
					<cfif len(trim(cc))
						and not listFindNoCase(request.cw.noCookieSessionVars,cc)
					    and len(trim(evaluate("cookie.#cc#")))
					    and not left(cc,1) is '_'
	   					and not cc contains 'cfauthorization'
						and	not (isDefined(varName) and len(trim(evaluate(varname))))>
						<!--- create session.cwclient var --->
						<cfset session.cwclient[cc] = evaluate("cookie.#cc#")>
					</cfif>
					<cfcatch>
						<!--- if debugging is on, output any errors to the page --->
						<cfif IsDefined("session.cw.debug") and session.cw.debug eq "true">
							<cfdump var="#cfcatch#" label="Cookie Error">
						</cfif>
						<!--- else fail silently on error --->
					</cfcatch>
				</cftry>
			</cfloop>
		</cfif>
		<!--- CART ID --->
		<!--- set blank cookie if none exists (actual cookie value is set in cw-inc-pageend) --->
		<cfif not isDefined('cookie.cwCartID')>
			<cfcookie name="CWcartID" value="0" expires="#request.cw.cookieExpire#">
		</cfif>
		<!--- client cart ID can be set by cookie, or by putting cart ID in url --->
		<cfparam name="url.cart" default="#cookie.cwCartID#">
		<cfparam name="session.cwclient.cwCartID" default="#url.cart#">
		<!--- set user country default --->
		<cfif application.cw.taxUseDefaultCountry>
			<cfparam name="session.cwclient.cwTaxCountryID" default="#application.cw.defaultCountryID#">
		</cfif>
		<!--- if we have a cookie or url value saved --->
		<cfif url.cart neq 0>
			<cfset session.cwclient.cwCartID = url.cart>
			<!--- prevent shipcost transfer if changing cart ids,
				  remove stored shipping value if it exists --->
			<cfif isDefined('session.cwclient.shiptotal') and session.cwclient.cwCartID neq 0 and session.cwclient.cwCartID neq url.cart>
				<cfset structDelete(session.cwclient,shiptotal)>
			</cfif>
			<!--- if not in url, and not defined in client, set new --->
		<cfelseif session.cwclient.cwCartID eq 0>
			<cfset session.cwclient.cwCartID = dateFormat(now(),'yyyymmdd') & timeFormat(now(),'hhss') & RandRange(11111,99999)>
		</cfif>
		<!--- TRACK PAGE VIEWS --->
		<!--- set number of page views to save: this can be altered here --->
		<cfset viewSaveCt = 10>
		<!--- set number of product views to save: this is set in admin --->
		<cfset viewProdCt = application.cw.appDisplayProductViews>
		<!--- if not already defined --->
		<cfif not isDefined('session.cw.pageViews') OR not len(trim(session.cw.pageViews))>
			<!--- set the current page as first item in list --->
			<cfset session.cw.pageViews = request.cw.thisPageQS>
			<!--- add the current page to the list --->
		<cfelse>
			<!--- if not the same page as last view (refreshing) --->
			<cfif not listLast(session.cw.pageViews) is request.cw.thisPageQS>
				<!--- save previous page --->
				<cfset session.cw.pagePrev = listLast(session.cw.pageViews)>
				<!--- save current page to list --->
				<cfset session.cw.pageViews = listAppend(session.cw.pageViews,request.cw.thisPageQS)>
			</cfif>
			<!--- only save the last xx pages --->
			<cfset pageCt = listLen(session.cw.pageViews)>
			<cfif pageCt gt viewSaveCt>
				<cfset delCt = pageCt - viewSaveCt>
				<cfloop from="1" to="#delCt#" index="ii">
					<cfset session.cw.pageViews = listDeleteAt(session.cw.pageViews,ii,",")>
				</cfloop>
			</cfif>
		</cfif>
		<!--- /end page views --->
		<!--- DISCOUNTS --->
		<!--- add discounts from user's session into page request --->
		<cfparam name="session.cwclient.discountApplied" default="">
		<cfparam name="session.cwclient.discountPromoCode" default="">
		<cfif application.cw.discountsEnabled>
			<cfset request.cwpage.discountsapplied = session.cwclient.discountApplied>			
		<!--- if discounts not active, set these values as null --->
		<cfelse>
			<cfset request.cwpage.discountsapplied = ''>
		</cfif>
		<!--- /end discounts --->
		<!--- CONTINUE SHOPPING URL --->
		<!--- if previous page url is stored, and matches results/details admin preference, use the previous url --->
		<cfset request.cwpage.continueShopping = application.cw.appActionContinueShopping>
		<cfif isDefined('session.cw.pagePrev') and len(trim(session.cw.pagePrev))
			and listFirst(session.cw.pagePrev,'?') neq application.cw.appPageShowCart
			and (
				(request.cwpage.continueShopping eq 'results' and listFirst(session.cw.pagePrev,'?') eq application.cw.appPageResults)
				OR
				(request.cwpage.continueShopping eq 'details' and listFirst(session.cw.pagePrev,'?') eq application.cw.appPageDetails)
			)>
			<cfset request.cwpage.returnUrl = session.cw.pagePrev>
		<!--- if a matching previous page not stored, use client history to determine continue shopping address --->
		<cfelse>
			<cfset returnurlqs=''>
			<!--- set up string for category , subcat and product --->
			<cfif isDefined('session.cw.prodPrev') and isNumeric(session.cw.prodPrev)>
				<cfset returnurlqs = returnurlqs & 'product=#session.cw.prodPrev#&'>
			</cfif>
			<cfif isDefined('session.cw.productCatPrev') and isNumeric(session.cw.productCatPrev)>
				<cfset returnurlqs = returnurlqs & 'category=#session.cw.productCatPrev#&'>
			</cfif>
			<cfif isDefined('session.cw.productSecPrev') and isNumeric(session.cw.productSecPrev)>
				<cfset returnurlqs = returnurlqs & 'secondary=#session.cw.productSecPrev#&'>
			</cfif>
			<cfif len(trim(returnurlqs))>
				<cfset returnUrlQS = '?#trim(returnurlqs)#'>
			</cfif>
			<cfif isDefined ('url.product') and isNumeric(url.product) and url.product gt 0>
				<cfset request.cwpage.productID = url.product>
			<cfelse>
				<cfset request.cwpage.productID = 0>
			</cfif>
			<cfswitch expression="#request.cwpage.continueShopping#">
				<cfcase value="results">
					<!--- get the most recent results page view  --->
					<cfloop list="#session.cw.pageViews#" index="vv">
						<cfif vv contains application.cw.appPageResults>
							<cfset request.cwpage.returnUrl = trim(vv)>
							<cfbreak>
						</cfif>
					</cfloop>
					<cfif not (isDefined('request.cwpage.returnUrl') and len(trim(request.cwpage.returnUrl)))>
						<cfset request.cwpage.returnUrl = request.cwpage.urlResults>
					</cfif>
				</cfcase>
				<cfcase value="details">
				<!--- get the most recent details page view --->
					<cfloop list="#session.cw.pageViews#" index="vv">
						<cfif vv contains application.cw.appPageDetails
						and not vv contains 'product=#request.cwpage.productID#'>
							<cfset request.cwpage.returnUrl = trim(vv)>
							<cfbreak>
						</cfif>
					</cfloop>
					<cfif not (isDefined('request.cwpage.returnUrl') and len(trim(request.cwpage.returnUrl)))>
						<cfset request.cwpage.returnUrl = request.cwpage.urlDetails & '?product=#request.cwpage.productID#&category=#request.cwpage.categoryID#&secondary=#request.cwpage.secondaryID#'>
					</cfif>
				</cfcase>
				<cfcase value="home">
					<cfset request.cwpage.returnUrl = application.cw.appSiteUrlHttp>
				</cfcase>
			</cfswitch>
		</cfif>
		<!--- returnurl in url overrides --->
		<cfif isDefined('url.returnurl') and len(trim(url.returnurl))
		 		and (
		 			listFirst(url.returnurl,'?') eq application.cw.appPageDetails
		 			OR listFirst(url.returnurl,'?') eq application.cw.appPageResults
		 			)
		 		>
			 <cftry>
				<cfset request.cwpage.returnUrl = urlDecode(trim(url.returnurl))>
				<cfset request.cwpage.returnUrl = replace(request.cwpage.returnUrl,"<","","all")>
				<cfset request.cwpage.returnUrl = replace(request.cwpage.returnUrl,"&lt;","","all")>
				<cfset request.cwpage.returnUrl = replace(request.cwpage.returnUrl,">","","all")>
				<cfset request.cwpage.returnUrl = replace(request.cwpage.returnUrl,"&gt;","","all")>
				<cfset request.cwpage.returnUrl = replace(request.cwpage.returnUrl,"'","","all")>
				<cfset request.cwpage.returnUrl = replace(request.cwpage.returnUrl,'"','','all')>
				<cfset request.cwpage.returnUrl = replace(request.cwpage.returnUrl,';','','all')>
				<cfcatch>
					<cfset request.cwpage.returnUrl = request.cwpage.urlResults>
				</cfcatch>
			</cftry>
		</cfif>
		<!--- /end continue shopping url --->
		<!--- save product info (if available) --->
		<!--- category --->
		<cfparam name="session.cw.productCatCurrent" default="0">
		<cfif isDefined ('url.category') and isNumeric(url.category) and url.category gt 0>
			<!--- if not already previous category --->
			<cfif not isDefined('session.cw.productCatPrev') OR url.category neq session.cw.productCatCurrent>
				<!--- save the previous entry --->
				<cfset session.cw.productCatPrev = session.cw.productCatCurrent>
				<!--- replace with current --->
				<cfset session.cw.productCatCurrent = url.category>
			</cfif>
		</cfif>
		<!--- secondary --->
		<cfparam name="session.cw.productSecCurrent" default="0">
		<cfif isDefined ('url.secondary') and isNumeric(url.secondary) and url.secondary gt 0>
			<!--- if not already previous secondary --->
			<cfif not isDefined('session.cw.productSecPrev') OR url.secondary neq session.cw.productSecCurrent>
				<!--- save the previous entry --->
				<cfset session.cw.productSecPrev = session.cw.productSecCurrent>
				<!--- replace with current --->
				<cfset session.cw.productSecCurrent = url.secondary>
			</cfif>
		</cfif>
		<!--- product ID --->
		<cfif isDefined ('url.product') and isNumeric(url.product) and url.product gt 0>
			<!--- if not already defined --->
			<cfif not isDefined('session.cwclient.cwProdViews') OR not len(trim(session.cwclient.cwProdViews))>
				<!--- set the current page as first item in list --->
				<cfset session.cwclient.cwProdViews = url.product>
				<!--- add the current page to the list --->
			<cfelse>
				<!--- save previous id --->
				<cfset session.cw.prodPrev = listFirst(session.cwclient.cwProdViews)>
				<!--- if not already in the list --->
				<cfif not listFindNoCase(session.cwclient.cwProdViews, url.product)>
					<!--- save current page to list
						- prepend adds it to front of list for showing reverse view order --->
					<cfset session.cwclient.cwProdViews = listPrepend(session.cwclient.cwProdViews,url.product)>
					<!--- if it is already in the list, move to front --->
				<cfelse>
					<cfset session.cwclient.cwProdViews = listDeleteAt(session.cwclient.cwProdViews,ListFind(session.cwclient.cwProdViews,url.product))>
					<cfset session.cwclient.cwProdViews = listPrepend(session.cwclient.cwProdViews,url.product)>
				</cfif>
			</cfif>
		</cfif>
		<!--- only save the first xx products --->
		<cfif isDefined('session.cwclient.cwProdViews') and listLen(session.cwclient.cwProdViews) gt 0>
			<cfset prodCt = listLen(session.cwclient.cwProdViews)>
			<!--- if the list is longer than the desired number of saved products --->
			<cfif prodCt gt viewProdCt>
				<!--- add 1 before deleting : see cw-inc-footer for display
				      and 1 more in case current page is in the list, can still show requested number --->
				<cfset delStart = viewProdCt + 2>
				<cfloop from="#delStart#" to="#prodCt#" index="ii">
					<cfset session.cwclient.cwProdViews = listDeleteAt(session.cwclient.cwProdViews,delStart,",")>
				</cfloop>
			</cfif>
		<!--- if none exist, create blank list placeholder --->
		<cfelse>
			<cfset session.cwclient.cwProdViews = ''>
		</cfif>
		<!--- /end product info --->
		<!--- PRODUCT VIEWS (COOKIE) --->
		<cftry>
			<!--- only applies to front end --->
			<cfif request.cw.thisDirName neq request.cw.adminDirName>
				<!--- if no products, read cookie in if it exists already --->
				<cfif listLen(session.cwclient.cwProdViews) is 0 and isDefined('cookie.cwProdViews')>
					<cfset session.cwclient.cwProdViews = cookie.cwProdViews>
				</cfif>
			</cfif>
		<cfcatch><!--- fails silently, no error thrown ---></cfcatch>
		</cftry>
		<!--- sort preferences --->
		<cfif isDefined('url.sortby') and len(trim(url.sortby))>
			<cfset session.cwclient.cwProductSortBy = trim(url.sortby)>
		</cfif>
		<cfif isDefined('url.sortdir') and len(trim(url.sortdir))>
			<cfset session.cwclient.cwProductSortDir = trim(url.sortdir)>
		</cfif>
		<cfif isDefined('url.perpage') and isNumeric(url.perpage)>
			<cfset session.cwclient.cwProductPerPage = url.perpage>
		</cfif>
	<!--- LOG OUT --->
	<cfif (isDefined('url.logout') and url.logout is 1)
		or (isDefined('request.cwpage.logout') and request.cwpage.logout is 1)>
		<!--- persist cart id to cookie--->
		<cfif isdefined('session.cwclient.cwCartID') and session.cwclient.cwCartID neq 0>
			<cfcookie name="cwcartid" value="#session.cwclient.cwCartID#">
		</cfif>
		<!--- if previously logged in, show message --->
		<cfif isDefined('session.cwclient.cwCustomerID') and session.cwclient.cwCustomerID neq 0
		 and not (isDefined('session.cwclient.cwCustomerCheckout') and session.cwclient.cwCustomerCheckout eq 'guest')>
			<cfset request.cwpage.userAlert = request.cwpage.userAlert & 'Log Out Successful'>
		</cfif>
		<!--- clear "cw" scope, including all cart confirmations--->
		<cfloop list="authType,confirmAuthPref,confirmCart,confirmAddress,confirmShip,confirmShipName,confirmOrder,confirmShipID" index="cc">
			<cfset structDelete(session.cw,trim(cc))>
		</cfloop>
		<!--- clear "cwclient" scope, including session authentication - automatically clears any corresponding cookies (set to null/expired in pageend) --->
		<cfloop list="cwCustomerName,cwCustomerID,cwCustomerType,cwOrderTotal,cwShipTaxTotal,cwShipTotal,cwTaxTotal,cwShipCountryID,cwShipRegionID,cwTaxCountryID,cwTaxRegionID" index="cc">
			<cfset structDelete(session.cwclient,trim(cc))>
		</cfloop>
		<!--- unset customer ID cookie --->
		<cfcookie name="cwCustomerID" value="" expires="NOW">
	</cfif>
	<!--- DEBUGGING OUTPUT --->
	<cfif isDefined("URL.debug")
		and application.cw.debugEnabled eq 'true'>
		<!--- if password matches and user is logged in --->
		<cfif URL.debug eq application.cw.storePassword
			and  isDefined('session.cw.loggedIn') and session.cw.loggedIn is '1'
			and isDefined('session.cw.accessLevel') and listFindNoCase('developer,merchant',session.cw.accessLevel)
			and (
			not isDefined('session.cw.debug') OR session.cw.debug eq 'false'
			)
			and not (
			isDefined('url.resetapplication')
			and url.resetapplication eq application.cw.storePassword
			)>
			<cfset session.cw.debug = "true">
		<cfelse>
			<cfset session.cw.debug = "false">
		</cfif>
		<!--- if debugging is turned off and we don't already have value set --->
	<cfelseif application.cw.debugEnabled eq 'false'
			and not
			(isDefined('session.cw.debug') and session.cw.debug eq 'false')
			>
		<cfset session.cw.debug = "false">
	</cfif>
	<!--- request.cw.now is timestamp with offset applied --->
	<cfset request.cw.now = dateAdd('h',application.cw.globalTimeOffset,now())>
	
	<!--- PLUGINS --->
	<cfif not (structKeyExists(application.cw,'pluginDirectories') and isArray(application.cw.pluginDirectories))>
		<cfset application.cw.pluginDirectories = arrayNew(1)>
	</cfif>
	
	<cfif arrayLen(application.cw.pluginDirectories) gt 0>
		<!--- include plugin 'config.cfm' files --->
		<cfloop from="1" to="#arrayLen(application.cw.pluginDirectories)#" index="i">
			<cftry>
				<cfinclude template="../../plugins/#application.cw.pluginDirectories[i]#/config.cfm">
			<cfcatch></cfcatch>
			</cftry>
		</cfloop>
	</cfif>
	<!--- /end plugins --->

	</cffunction>

<!--- // ---------- // Refresh Product Data // ---------- // --->
<cffunction name="CWinitProductData"
			access="public"
			output="false"
			returntype="void"
			hint="Reloads product data in application.cw.productData"
			>

	<cfset var productsQuery = ''>
	<cfset var productDetails = structNew()>
	<cfset var appProducts = structNew()>
	<cfset var appProductData = structNew()>
	<cfset var temp = ''>
	<cfset var ii = ''>

		<cfquery name="productsQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			SELECT product_id,product_merchant_product_id,product_name,product_description,product_preview_description,product_sort,product_on_web,product_archive,product_ship_charge,product_tax_group_id,product_date_modified,product_special_description,product_keywords,product_out_of_stock_message,product_custom_info_label FROM cw_products ORDER BY product_id
		</cfquery>

		<cfoutput query="productsQuery">
			<cfif isNumeric(product_id)>
				<cfset appProducts[product_id] = product_name>
				<cfset productDetails = structNew()>						
				<cfloop list="#productsQuery.columnList#" index="ii">
					<cfset temp = evaluate('productsQuery.#trim(ii)#')>
					<cfset productDetails[ii] = temp>
				</cfloop>
				<cfset appProductData[product_id] = productDetails>
			</cfif>
		</cfoutput>

		<cfset application.cw.listProducts = appProducts>
		<cfset application.cw.productsQuery = productsQuery>
		<cfset application.cw.productData = appProductData>

</cffunction>

<!--- // ---------- // Refresh Sku Data // ---------- // --->
<cffunction name="CWinitSkuData"
			access="public"
			output="false"
			returntype="void"
			hint="Reloads sku data in application.cw.skuData"
			>

	<cfset var appSkus = structNew()>
	<cfset var appSkuData = structNew()>
	<cfset var skusQuery = ''>
	<cfset var skuDetails = structNew()>	
	<cfset var temp = ''>
	<cfset var ii = ''>

 		<cfquery name="skusQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
			SELECT sku_id,sku_merchant_sku_id,sku_product_id,sku_price,sku_weight,sku_stock,sku_on_web,sku_sort,sku_alt_price,sku_ship_base FROM cw_skus s
		</cfquery>

		<cfoutput query="skusQuery">
			<cfif isNumeric(sku_id)>
				<cfset appSkus[sku_id] = sku_merchant_sku_id>
				<cfset skuDetails = structNew()>						
				<cfloop list="#skusQuery.columnList#" index="ii">
					<cfset temp = evaluate('skusQuery.#trim(ii)#')>
					<cfset skuDetails[ii] = temp>
				</cfloop>
				<cfset appSkuData[sku_id] = skuDetails>
			</cfif>	
		</cfoutput>

		<cfset application.cw.listSkus = appSkus>
		<cfset application.cw.skusQuery = skusQuery>
		<cfset application.cw.skuData = appSkuData>

</cffunction>

<!--- // ---------- // Refresh Category Data // ---------- // --->
<cffunction name="CWinitCategoryData"
			access="public"
			output="false"
			returntype="void"
			hint="Reloads category data in application.cw.listCategories|listSubcategories"
			>

	<cfargument name="categoryType"
			required="false" 
			default="0"
			type="numeric"
			hint="1=primary categories,2=secondary,0=both">

		<cfset var appCats = structNew()>
		<cfset var appSubCats = structNew()>

		<!--- CATEGORIES: store category names, IDs in application scope --->
		<cfif arguments.categoryType eq 0 or arguments.categoryType eq 1>
			<cfquery name="catsQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
				SELECT category_name AS name, category_ID AS ID FROM cw_categories_primary ORDER BY category_ID
			</cfquery>
			<cfoutput query="catsQuery">
				<cfset appCats[ID] = name>
			</cfoutput>
			<cfset application.cw.listCategories = appCats>
		</cfif>
		
		<!--- SECONDARY CATEGORIES: store category names, IDs in application scope --->
		<cfif arguments.categoryType eq 0 or arguments.categoryType eq 2>
			<cfquery name="subcatsQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
				SELECT secondary_name AS name, secondary_ID AS ID FROM cw_categories_secondary ORDER BY secondary_ID
			</cfquery>
			<cfoutput query="subcatsQuery">
				<cfset appSubCats[ID] = name>
			</cfoutput>
			<cfset application.cw.listSubcategories = appSubCats>
		</cfif>

</cffunction>

<!--- // ---------- // Refresh Currency Data // ---------- // --->
<cffunction name="CWinitCurrencyData"
			access="public"
			output="false"
			returntype="void"
			hint="Reloads currency data for site locale"
			>

	<cfset var manager = ''>
	<cfset var cfLocale = ''>
	<cfset var javaLocale = ''>
	<cfset var currency = ''>
	<cfset var symbols = ''>
	<cfset var currencyPattern = ''>

		<cftry>
			<!--- railo handles this function differently --->
			<cfswitch expression="#server.coldfusion.productName#">
				<cfcase value="railo">
					<cfset cfLocale = getLocale()>
					<cfset currency = createObject("java", "java.text.DecimalFormat").getCurrencyInstance(cfLocale)>			
				</cfcase>
				<cfdefaultcase>
					<cfset manager = createObject("java", "coldfusion.runtime.locale.CFLocaleMgr").getMgr()>
					<cfset cfLocale = manager.getCFLocale(GetLocale())>
					<cfset javaLocale = cfLocale.GetJavaLocaleObj()>
					<cfset currency = createObject("java", "java.text.DecimalFormat").getCurrencyInstance(javaLocale)>
				</cfdefaultcase>
			</cfswitch>
			<!--- get currency symbol values for the request url --->
			<cfset symbols = currency.getDecimalFormatSymbols()>
			<cfset currencyPattern = currency.toLocalizedPattern()>
			<cfset application.cw.currencyPrecedes = currencyPattern.indexOf(javacast("int", 164)) lte 0>
			<cfset application.cw.currencySymbol = symbols.getCurrencySymbol()>
			<cfset application.cw.currencyDecimal = symbols.getDecimalSeparator()>
			<cfset application.cw.currencyGroup = symbols.getGroupingSeparator()>
			<!--- clean up yes/no value for js true|false format --->
			<cfif application.cw.currencyPrecedes is 'NO'>
				<cfset application.cw.currencyPrecedes = 'false'>
			<cfelse>
				<cfset application.cw.currencyPrecedes = 'true'>
			</cfif>
			<!--- get currency space separator --->
			<cfif lsCurrencyFormat('1234.56','local') contains ' #application.cw.currencySymbol#'
			or lsCurrencyFormat('1234.56','local') contains '#application.cw.currencySymbol# '>
				<cfset application.cw.currencySpace = ' '>
			<cfelse>
				<cfset application.cw.currencySpace = ''>
			</cfif>
			<!--- set defaults on error --->
			<cfcatch>
				<cfset application.cw.currencyPrecedes = 'false'>
				<cfset application.cw.currencySymbol = ''>
				<cfset application.cw.currencyDecimal = '.'>
				<cfset application.cw.currencyGroup = ','>
				<cfset application.cw.currencySpace = ''>
			</cfcatch>
		</cftry>
		
</cffunction>

<!--- // ---------- // Clean URL // ---------- // --->
<cffunction name="CWcleanURL" access="public" returntype="string" output="false"
hint="Sanitize a URL against XSS">

	<cfargument name="base_url" type="string" required="false" default="#request.cw.thisPage#"
				hint="query string to parse variables from">

	<cfargument name="parse_qs" type="string" required="false" default="#cgi.script_name#"
				hint="query string to parse variables from">

<cfset var cleanUrl = ''>
<cfset var qsVarList = ''>
<cfset var newItem = ''>
<cfset var varName = ''>
<cfset var urlVarName = ''>
<cfset var varVal = ''>
<cfset var i = ''>
<cfset var varCt = 0>
<cfset var QSadd = ''>
<cfset var persistQS = ''>
<cfset var loopCt = 1>

	<!--- list all vars --->
	<cfloop list="#arguments.parse_qs#" index="i" delimiters="&">
		<cfset varName = reReplaceNoCase(listFirst(i,'='),"[^a-zA-Z0-9-..]","","all")>
		<cfset varVal = reReplaceNoCase(listLast(i,'='),"[<>\(\);]","","all")>
		<!--- avoid duplicates --->
		<cfif not listFindNoCase(qsVarList,varName)>
			<cfset qsVarList = listAppend(qsVarlist,varName)>
			<!--- eliminate errant value setting --->
			<cftry>
				<cfset urlVarName = "url.#trim(varName)#">
				<!--- prevent from breaking on missing vars --->
				<cfparam name="#urlvarname#" default="" type="string">
				<cfset QSadd = varName & '=' & varVal>
				<cfif not loopCt eq 1>
					<cfset QSadd = '&' & QSadd>
				</cfif>
				<cfset persistQS = persistQS & QSadd>
			<cfcatch></cfcatch>
			</cftry>
		<cfset loopCt = loopCt + 1>		
		</cfif>
	</cfloop>
	
	<!--- set the base url --->
	<cfif len(trim(arguments.base_url))>
		<cfset cleanUrl = trim(arguments.base_url) & '?'>
	</cfif>
	<cfset cleanUrl = replace(cleanUrl & persistQS,'?&','?')>
		
<cfreturn cleanUrl>
</cffunction>
</cfsilent>