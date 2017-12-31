<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: countries.cfm
File Date: 2012-11-18
Description: Displays Countries and State/Province management options
==========================================================
--->
<!--- GLOBAL INCLUDES --->
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("merchant,developer")>
<!--- PAGE PARAMS --->
<!--- default value for active or archived view--->
<cfparam name="url.view" type="string" default="active">
<!--- default form values --->
<cfparam name="form.country_id" type="numeric" default="0">
<cfparam name="form.stateprov_code" type="string" default="">
<cfparam name="form.stateprov_name" type="string" default="">
<cfparam name="form.country_sort" type="numeric" default="1">
<cfparam name="form.country_name" type="string" default="">
<!--- default for error handling --->
<cfparam name="request.cwpage.errormessage" default="">
<!--- list of null region names to skip during lookups --->
<cfparam name="request.cwpage.nullRegionNames" default='"none","all"'>
<!--- defaults for display loops/counters --->
<cfparam name="CheckStateList" default="0">
<cfparam name="UsedStateList" default="0">
<cfparam name="UsedShippingMethodList" default="0">
<cfparam name="UsedCountryList" default="0">
<cfparam name="CustomerCountryList" default="0">
<cfparam name="CustomerStateList" default="0">
<cfset countryCounter = 0>
<cfset stateCounter = 0>
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("view,userconfirm,useralert,clickadd,country")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- ACTIVE VS. ARCHIVED --->
<cfif url.view contains 'arch'>
	<cfset request.cwpage.viewType = 'Archived'>
	<cfset request.cwpage.recordsArchived = 1>
	<cfset request.cwpage.subHead = 'Archived Countries are not shown in the store'>
<cfelse>
	<cfset request.cwpage.viewType = 'Active'>
	<cfset request.cwpage.recordsArchived = 0>
	<cfset request.cwpage.subHead = 'Manage active Countries and Regions, or add a new Country'>
</cfif>
<!--- QUERY: Get all available countries for dropdown selection on add new form --->
<cfset countriesQuery = CWquerySelectCountries(request.cwpage.recordsarchived)>
<!--- QUERY: Get all states and countries (active/archived) --->
<cfset statesQuery = CWquerySelectCountryStates(request.cwpage.recordsarchived)>
<cfset iCountryList = ValueList(statesQuery.country_id)>
<!--- QUERY: get all states with a user-defined code --->
<cfset countryIdsQuery = CWquerySelectStateCountryIDs()>
<cfif countryIDsQuery.recordCount>
	<cfset CheckStateList = ValueList(countryIdsQuery.stateprov_country_id)>
</cfif>
<!--- QUERY: get all ship methods that have orders --->
<cfset usedShipMethodsQuery = CWquerySelectOrderShipMethods()>
<cfif usedShipMethodsQuery.RecordCount gt 0>
	<cfset UsedShippingMethodList = ValueList(usedShipMethodsQuery.order_ship_method_id)>
</cfif>
<!--- QUERY: get all states with customer record matches --->
<cfset usedStatesQuery = CWquerySelectCustomerStates()>
<cfif usedStatesQuery.recordCount gt 0>
	<cfset UsedStateList = ValueList(usedStatesQuery.customer_state_stateprov_id)>
</cfif>
<!--- QUERY: get all shipping method countries with orders attached (ids to omit) --->
<cfset usedCountriesQuery = CWquerySelectShipCountries(UsedShippingMethodList)>
<cfif usedCountriesQuery.recordCount>
	<cfset usedCountryList = valueList(usedCountriesQuery.ship_method_country_country_id)>
</cfif>
<!--- QUERY: get all states/countries with customer address matches --->
<cfset customerStatesQuery = CWquerySelectCustomerCountries()>
<cfif customerStatesQuery.RecordCount>
	<cfset CustomerCountryList = ValueList(customerStatesQuery.stateprov_country_id)>
	<cfset CustomerStateList = ValueList(customerStatesQuery.customer_state_stateprov_id)>
</cfif>
<!--- /////// --->
<!--- ADD NEW COUNTRY / REGION --->
<!--- /////// --->
<!--- if submitting the 'add new' form (region name not blank)  --->
<cfif len(trim(form.stateprov_name)) and request.cwpage.recordsArchived eq 0>
	<!--- ADD NEW COUNTRY --->
	<cfif len(trim(form.country_name))>
		<!--- QUERY: insert new country (name, code, sort order, archived, default)--->
		<cfset newCountryID = CWqueryInsertCountry(
		trim(form.country_name),
		trim(form.stateprov_code),
		form.country_sort,
		0,
		0
		)>
		<!--- if no error returned from insert query --->
		<cfif not left(newCountryID,2) eq '0-'>
			<!--- set up confirmation message --->
			<cfset CWpageMessage("confirm","Country '#form.country_name#' Added")>
			<cfset request.cwpage.newCountryID = newCountryID>
			<!--- if we have an insert error, show message, do not insert --->
		<cfelse>
			<cfset request.cwpage.errorMessage = listLast(newCountryID,'-')>
			<cfset CWpageMessage("alert",request.cwpage.errorMessage)>
			<cfset url.clickadd = 1>
		</cfif>
		<!--- end duplicate error check --->
		<!--- if not adding a new country --->
	<cfelse>
		<cfset request.cwpage.newCountryID = form.country_id>
	</cfif>
	<!--- /END country insert --->
	<!--- ADD NEW REGION --->
	<!--- if no error from country insert, continue with region insert --->
	<cfif not len(trim(request.cwpage.errormessage))>
		<!--- if region is 'none' or 'all', add a placeholder record --->
		<cfif form.stateprov_name is 'All' OR form.stateprov_name is 'None' OR form.stateprov_name is ''>
			<!--- QUERY: insert stateprov record (name, code, country ID) --->
			<cfset newRegionID = CWqueryInsertStateProv(
			'All',
			'All',
			request.cwpage.newCountryID
			)>
			<!--- if not none or all, add an actual record --->
		<cfelse>
			<!--- QUERY: insert stateprov record (name, code, country ID) --->
			<cfset newRegionID = CWqueryInsertStateProv(
			trim(form.stateprov_name),
			trim(form.stateprov_code),
			request.cwpage.newCountryID
			)>
			<!--- QUERY: archive any placeholder regions for this country (archive y/n, country ID, name, code to match) --->
			<cfset archiveRegion = CWqueryArchiveStateProv(
			1,
			request.cwpage.newCountryID,
			request.cwpage.nullRegionNames,
			''
			)>
		</cfif>
		<!--- end placeholder or actual record --->
		<!--- if no error returned from insert query --->
		<cfif not left(newRegionID,2) eq '0-'>
			<!--- set up confirmation message --->
			<cfset CWpageMessage("confirm","Region '#form.stateprov_name#' Added")>
			<!--- if we have an insert error, show message, do not insert --->
		<cfelse>
			<cfset CWpageMessage("alert",listLast(newRegionID,'-'))>
			<cfset url.clickadd = 1>
		</cfif>
		<!--- end duplicate error check --->
	</cfif>
	<!--- / END ADD NEW REGION--->
	<!--- if no error, return showing message to clear form fields --->
	<cfif not len(trim(request.cwpage.errormessage))>
		<cflocation url="#request.cwpage.baseUrl#&country=#request.cwpage.newCountryID#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&clickadd=1" addtoken="no">
	</cfif>
</cfif>
<!--- /////// --->
<!--- /END ADD NEW REGION --->
<!--- /////// --->
<!--- /////// --->
<!--- UPDATE/DELETE REGIONS --->
<!--- /////// --->
<!--- look for at least one valid ID field --->
<cfif isDefined('form.country_id1')>
	<cfset loopCt = 1>
	<cfset updateStPrvCt = 0>
	<cfset updateCountryCt = 0>
	<cfset deleteStPrvCt = 0>
	<cfset deleteCountryCt = 0>
	<cfset archiveStPrvCt = 0>
	<cfset archiveCountryCt = 0>
	<cfset activeStPrvCt = 0>
	<cfset activeCountryCt = 0>
	<!--- Loop through all of the submitted states --->
	<cfloop from="1" to="#form.stateCounter#" index="id">
		<cfset stateID = Evaluate("form.stateprov_id#id#")>
		<!--- DELETE REGION --->
		<cfif IsDefined(Evaluate(DE("form.stprv_Delete#id#")))>
			<!--- QUERY: delete associated tax regions --->
			<cfset deleteTaxRegions = CWqueryDeleteTaxRegion(stateID)>
			<!--- QUERY: delete the state --->
			<cfset deleteStateProv = CWqueryDeleteStateProv(stateID)>
			<!--- increment the delete counter --->
			<cfset deleteStPrvCt = deleteStPrvCt + 1>
			<!--- UPDATE REGION if not deleting --->
		<cfelse>
			<!--- if marked for archiving --->
			<cfif IsDefined(Evaluate(DE("form.stateprov_archive#id#")))>
				<cfset archiveRecord = 1>
			<cfelse>
				<cfset archiveRecord = 0>
			</cfif>
			<!--- /end if archiving --->
			<!--- QUERY: determine previous active/archive status of region --->
			<cfset regionPrevArchive = CWquerySelectStateProvDetails(stateID,'','')>
			<cfif regionPrevArchive.stateprov_archive is 1>
				<cfset prevArchive = 1>
			<cfelse>
				<cfset prevArchive = 0>
			</cfif>
			<!--- param for tax nexus --->
			<cfparam name="form.stateprov_nexus#id#" default="0">
			<!---  QUERY: update the region (id, name, code, archive)--->
			<cfset updatedStateProvID = CWqueryUpdateStateProv(
			stateID,
			evaluate("form.stateprov_name#id#"),
			evaluate("form.stateprov_code#id#"),
			archiveRecord,
			evaluate("form.stateprov_nexus#id#")
			)>
			<!--- if no error returned from update query --->
			<cfif not left(updatedStateProvID,2) eq '0-'>
				<!--- increment archive/active counters --->
				<cfif prevArchive is 1 AND archiveRecord is 0>
					<cfset activeStPrvCt = activeStPrvCt + 1>
				<cfelseif prevArchive is 0 AND archiveRecord is 1>
					<cfset archiveStPrvCt = archiveStPrvCt + 1>
				<cfelse>
					<!--- increment the update counter --->
					<cfset updateStPrvCt = updateStPrvCt + 1>
				</cfif>
				<!--- if we have an insert error, show message, do not insert --->
			<cfelse>
				<cfset CWpageMessage("alert",listLast(updatedStateProvID,'-'))>
				<cfset url.clickadd = 1>
			</cfif>
			<!--- end duplicate error check --->
		</cfif>
		<!--- end delete / update --->
	</cfloop>
	<!--- UPDATE COUNTRIES --->
	<!--- Loop through all of the submitted countries --->
	<cfloop from="1" to="#form.countryCounter#" index="id">
		<cfset countryID = evaluate("form.country_id#id#")>
		<!--- DELETE COUNTRY --->
		<cfif IsDefined(evaluate(DE("form.country_Delete#id#")))>
			<!--- QUERY: get list of states for this country (stateprov ID, stateprov Name, stateprov Code, country ID) --->
			<cfset stateListQuery = CWquerySelectStateProvDetails(0,'','',countryID)>
			<!--- if we have states for this country --->
			<cfif stateListQuery.recordCount>
				<cfset deleteStates = valueList(stateListQuery.stateprov_id)>
				<!--- delete all states --->
				<cfloop list="#deleteStates#" index="stID">
					<cfset deleteStateProv = CWqueryDeleteStateProv(stID)>
					<!--- increment counter --->
					<cfset deleteStPrvCt = deleteStPrvCt + 1>
				</cfloop>
			</cfif>
			<!--- /end if we have states --->
			<!--- QUERY: delete tax regions associated with deleted country (record id, state id, country id) --->
			<cfset deleteTaxRegion = CWqueryDeleteTaxRegion(0,0,countryID)>
			<!--- QUERY: get number of states related to this country --->
			<cfset countStates = CWquerySelectStateProvDetails(0,'','',countryID)>
			<!--- QUERY: delete all states related to this country (record ID, country ID) --->
			<cfset deleteStateProv = CWqueryDeleteStateProv(0,countryID)>
			<cfset deleteStPrvCt = deleteStPrvCt + countStates.recordCount>
			<!--- QUERY:  get ship ranges list for deletion (country ID, archived ) --->
			<cfset shipRangesQuery = CWquerySelectShippingCountryRanges(countryID,2)>
			<cfset deletelist = valueList(shipRangesQuery.ship_range_id)>
			<!--- QUERY: delete ship ranges for country --->
			<cfloop list="#deleteList#" index="delID">
				<cfset deleteShipRange = CWqueryDeleteShippingRange(delID)>
			</cfloop>
			<!--- QUERY: get ship methods ID list for deletion (country ID, archived)--->
			<cfset shipMethodsQuery = CWquerySelectShippingMethods(countryID,2)>
			<cfset deleteList = valueList(shipMethodsQuery.ship_method_id)>
			<!--- QUERY: delete ship methods for country --->
			<cfloop list="#deleteList#" index="delID">
				<cfset deleteShipMethod = CWqueryDeleteShippingMethod(delID)>
			</cfloop>
			<!--- QUERY: delete the actual country --->
			<cfset deleteCountry = CWqueryDeleteCountry(countryID)>
			<cfset deleteCountryCt = deleteCountryCt + 1>
			<cfif isDefined("form.defCountry") AND form.defCountry eq countryID>
				<cfset application.cw.defaultCountryID = 0>
			</cfif>
			<!--- /end Delete country --->
		<cfelse>
			<!--- UPDATE COUNTRY --->
			<cfparam name="form.country_archive#id#" default="#request.cwpage.recordsarchived#">
			<!--- default country y/n --->
			<cfif IsDefined("form.defCountry") AND form.defCountry eq countryID>
				<cfset DefaultCountry = 1>
			<cfelse>
				<cfset DefaultCountry = 0>
			</cfif>
			<!--- SET APPLICATION VARIABLE FOR DEFAULT COUNTRY --->
			<cfif application.cw.defaultCountryID neq countryID AND DefaultCountry is 1>
			<cfset application.cw.defaultCountryID = evaluate(countryID)>
			<cfset CWpageMessage("confirm","Default Country Set")>
			</cfif>
			<!--- QUERY: update country (id, name, code, archive y/n, sort, default y/n) --->
			<cfset updatedCountryID = CWqueryUpdateCountry(
			countryID,
			evaluate("form.country_name#id#"),
			evaluate("form.country_code#id#"),
			evaluate("form.country_archive#id#"),
			evaluate("form.country_sort#id#"),
			defaultCountry
			)>
			<!--- if no error returned from update query --->
			<cfif not left(updatedCountryID,2) eq '0-'>
				<!--- increment archive/active counters --->
				<cfif request.cwpage.recordsArchived is 1 AND evaluate("form.country_archive#id#") is 0>
					<cfset activeCountryCt = activeCountryCt + 1>
				<cfelseif request.cwpage.recordsArchived is 0 AND evaluate("form.country_archive#id#") is 1>
					<cfset archiveCountryCt = archiveCountryCt + 1>
				<cfelse>
					<!--- increment update counter--->
					<cfset updateCountryCt = updateCountryCt + 1>
				</cfif>
				<!--- if we have an insert error, show message, do not insert --->
			<cfelse>
				<cfset CWpageMessage("alert",listLast(updatedCountryID,'-'))>
				<cfset url.clickadd = 1>
			</cfif>
			<!--- end duplicate error check --->
			<cfif IsDefined("form.defCountry") AND form.defCountry eq countryID>
				<cfset application.cw.defaultCountryID = countryID >
			</cfif>
		</cfif>
		<!--- end delete/update --->
	</cfloop>
	<!--- handle placeholder regions --->
	<!--- QUERY: get all countries with stateprovs active --->
	<cfset activeCountries = CWquerySelectUserStateProvCountries()>
	<!--- set up list of country IDs --->
	<cfset countryIDlist = valueList(activeCountries.country_id)>
	<!--- QUERY: archive placeholder state for countries not in active list (archive, country IDs, name, code, omit) --->
	<cfset archiveRegion = CWqueryArchiveStateProv(1,countryIDlist,'','All,None',0)>
	<!--- QUERY: unarchive placeholder state for remaining countries (archive, country IDs, name, code, omit) --->
	<cfset unarchiveRegion = CWqueryArchiveStateProv(1,countryIDlist,'','All,None',countryIDlist)>
	<!--- get the vars to keep by omitting the ones we don't want repeated --->
	<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert,country")>
	<!--- set up the base url --->
	<cfset request.cwpage.relocateUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
	<!--- save confirmation text --->
	<cfset CWpageMessage("confirm","Changes Saved")>
	<!--- save alert text --->
	<cfsavecontent variable="request.cwpage.userAlertText">
		<cfoutput>
			<cfif archiveStPrvCt gt 0>
				,<cfoutput>#archiveStPrvCt# Region<cfif archiveStPrvCt gt 1>s</cfif> Archived</cfoutput>
			</cfif>
			<cfif activeStPrvCt gt 0>
				,<cfoutput>#activeStPrvCt# Region<cfif activeStPrvCt gt 1>s</cfif> Activated</cfoutput>
			</cfif>
			<cfif deleteStPrvCt gt 0>
				,<cfoutput>#deleteStPrvCt# Region<cfif deleteStPrvCt gt 1>s</cfif> Deleted</cfoutput>
			</cfif>
			<cfif archiveCountryCt gt 0>
				,<cfoutput>#archiveCountryCt# Countr<cfif archiveCountryCt gt 1>ies<cfelse>y</cfif> Archived</cfoutput>
			</cfif>
			<cfif activeCountryCt gt 0>
				,<cfoutput>#activeCountryCt# Countr<cfif activeCountryCt gt 1>ies<cfelse>y</cfif> Activated</cfoutput>
			</cfif>
			<cfif deleteCountryCt gt 0>
				,<cfoutput>#deleteCountryCt# Countr<cfif deleteCountryCt gt 1>ies<cfelse>y</cfif> Deleted</cfoutput>
			</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfloop list="#request.cwpage.userAlertText#" index="i">
		<cfif len(trim(i))>
			<cfset CWpageMessage("alert",i)>
		</cfif>
	</cfloop>
	<!--- return to page as submitted, clearing form scope --->
	<cfif deleteCountryCt gt 0 OR (isDefined("url.country") AND isDefined('form.country_archive1') AND form.country_archive1 eq 1)>
		<cfset request.cwpage.relocateUrl = request.cwpage.relocateUrl & '&country=0'>
	<cfelseif isDefined("url.country")>
		<cfset request.cwpage.relocateUrl = request.cwpage.relocateUrl & '&country=' & url.country>
	</cfif>
	<cflocation url="#request.cwpage.relocateUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END UPDATE/DELETE REGIONS --->
<!--- /////// --->
<!--- default country --->
<cfif not isDefined('url.country') and isDefined('application.cw.defaultCountryID')>
	<cfset url.country =  application.cw.defaultCountryID>
</cfif>
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title
<title>
--->
<cfset request.cwpage.title = "Manage Countries and Regions">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Countries and Regions Management">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = request.cwpage.subhead>
<!--- current menu marker --->
<cfset request.cwpage.currentNav = request.cw.thisPage>
<!--- load form scripts --->
<cfset request.cwpage.isformPage = 1>
<!--- load table scripts --->
<cfset request.cwpage.isTablePage = 1>
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
		<!--- PAGE JAVASCRIPT --->
		<script type="text/javascript">
		jQuery(document).ready(function(){
			// add new show-hide
			jQuery('form#addNewform').hide();
			jQuery('a#showAddNewformLink').click(function(){
				jQuery(this).hide();
				jQuery('form#addNewform').show().find('input.focusField').focus();
				return false;
			});
			// auto-click the link if adding
			<cfif isDefined('url.clickadd')>
				jQuery('a#showAddNewformLink').click();
			</cfif>
			// change country with select
			jQuery('#countrySel').change(function(){
			 	var newUrl = jQuery(this).find('option:selected').attr('value');
			 	window.location = newUrl;
			});
			// add country form input swap
			jQuery('#addCountryLink').click(function(){
				jQuery('#country_id').hide();
				jQuery('#country_name').show().attr('disabled',false).parents('td').siblings('td').children('#stateprov_name').attr('value','All').attr('defaultValue','All');
				jQuery('#stateprov_name').parents('td').hide();
				jQuery('#stateprov_name_label').hide();
				jQuery(this).hide().siblings('a').show();
				return false;
			});
			jQuery('#hideCountryLink').click(function(){
				jQuery('#country_id').show();
				jQuery('#country_name').hide().attr('disabled',true).parents('td').siblings('td').children('#stateprov_name').attr('value','').attr('defaultValue','');
				jQuery('#stateprov_name').parents('td').show();
				jQuery('#stateprov_name_label').show();
				jQuery(this).hide().siblings('a').show();
				return false;
			});
			// don't allow default country to be archived
			jQuery('input.archiveCountry').click(function(){
				var isChecked = false;
				if (jQuery(this).prop('checked')==true){
				isChecked = true;
			};
			// if sibling radio is checked, no click is allowed
			if (jQuery(this).parent('td').parent('tr').find('input[type=radio]').prop('checked')==true){
				if (isChecked == true){
					// show message, uncheck box
					alert('Default country cannot be archived\nChoose a new default country first');
					jQuery(this).prop('checked',false);
					}
				};
			});
			// don't allow archived country to be set as default
			jQuery('input[name="defCountry"]').click(function(){
				if (jQuery(this).prop('checked')==true){
					if (jQuery(this).parent('td').parent('tr').find('input.archiveCountry').prop('checked')==true){
					alert('Archived country cannot be set as default\nUncheck archive box for this country first');
					jQuery(this).prop('checked',false);
					};
				};
			});

			});
		</script>
		<!--- /END PAGE JAVASCRIPT --->
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
					<!-- Admin Alert - message shown to user -->
					<cfinclude template="cwadminapp/inc/cw-inc-admin-alerts.cfm">
					<!-- Page Content Area -->
					<div id="CWadminContent">
						<!-- //// PAGE CONTENT ////  -->
						<!--- LINKS FOR VIEW TYPE --->
						<div class="CWadminControlWrap">
							<strong>
							<cfif url.view eq 'arch'>
								<a href="<cfoutput>#request.cw.thisPage#</cfoutput>">View Active</a>
							<cfelse>
								<a href="<cfoutput>#request.cw.thisPage#</cfoutput>?view=arch">View Archived</a>
								<!--- link for add-new form --->
								<cfif request.cwpage.recordsArchived is 0>
									&nbsp;&nbsp;<a class="CWbuttonLink" id="showAddNewformLink" href="#">Add New Country / Region</a>
								</cfif>
							</cfif>
							</strong>
						</div>
						<!--- /END LINKS FOR VIEW TYPE --->
						<!--- /////// --->
						<!--- ADD NEW COUNTRY --->
						<!--- /////// --->
						<cfif request.cwpage.recordsArchived is 0>
							<!--- form --->
							<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" class="CWvalidate" name="addNewform" id="addNewform" method="post">
								<p>&nbsp;</p>
								<h3>Add New Country / Region</h3>
								<table class="CWinfoTable wide">
									<thead>
									<tr>
										<th width="250">Country Name</th>
										<th id="stateprov_name_label">Region Name</th>
										<th>Code</th>
										<th>Sort</th>
									</tr>
									</thead>
									<tbody>
									<tr>
										<!--- location --->
										<td style="text-align:center">
											<div>
												<select name="country_id" id="country_id">
													<cfoutput query="countriesQuery">
													<option value="#country_id#"<cfif country_id eq url.country> selected="selected"</cfif>>#country_name#</option>
													</cfoutput>
												</select>
												<!--- new country  --->
												<input name="country_name" type="text" size="18" maxlength="100" class="required" title="Country Name is required" id="country_name" style="display:none;"  disabled="disabled" value="<cfoutput>#form.country_name#</cfoutput>">
												<a href="#" id="addCountryLink">Add New</a>
												<a href="#" id="hideCountryLink" style="display:none;">Cancel</a>
											</div>
											<br>
											<input name="SubmitAdd" type="submit" class="CWformButton" id="SubmitAdd" value="Save New Region">
										</td>
										<!--- region name--->
										<td><input name="stateprov_name" type="text" size="28" maxlength="100" class="required" value="<cfoutput>#form.stateprov_name#</cfoutput>" title="Region Name is required" id="stateprov_name" onblur="checkValue(this)"> </td>
										<!--- region code--->
										<td><input name="stateprov_code" type="text" size="5" maxlength="35" class="required" value="<cfoutput>#form.stateprov_code#</cfoutput>" title="Code is required" id="stateprov_code"> </td>
										<!--- sort order --->
										<td>
											<input name="country_sort" type="text" id="country_sort" size="4" maxlength="7" class="required sort" title="Sort order is required" value="<cfoutput>#form.country_sort#</cfoutput>" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
										</td>
									</tr>
									</tbody>
								</table>
							</form>
							<p>&nbsp;</p>
						</cfif>
						<!--- /////// --->
						<!--- /END ADD NEW COUNTRY --->
						<!--- /////// --->
						<!--- /////// --->
						<!--- EDIT RECORDS --->
						<!--- /////// --->
						<form action="<cfoutput>#request.cwpage.baseUrl#&view=#url.view#&country=#url.country#</cfoutput>" name="recordform" id="recordform" method="post" class="CWobserve">
							<!--- if no records found, show message --->
							<cfif not statesQuery.recordCount>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p>&nbsp;</p>
								<p><strong>No <cfoutput>#request.cwpage.viewtype#</cfoutput> Countries available.</strong> <br><br></p>
								<!--- if records found --->
							<cfelse>
								<!--- output records --->
								<!--- Container table --->
								<table class="CWinfoTable wide">
									<thead>
									<tr class="headerRow">
										<th><cfoutput>#request.cwpage.viewType# Countries<cfif not request.cwpage.recordsArchived>/Regions</cfif></cfoutput></th>
									</tr>
									</thead>
									<tbody>
									<tr>
										<td>
											<!--- country selection --->
											<cfif not request.cwpage.recordsArchived>
											<label>&nbsp;&nbsp;Manage Country:
											<select name="countrySel" id="countrySel">
												<cfoutput><option value="#request.cw.thisPage#?country=0">All Countries</option></cfoutput>
												<cfoutput query="statesQuery" group="country_id">
													<option value="#request.cw.thisPage#?country=#country_id#"<cfif url.country eq country_id> selected="selected"</cfif>>#country_name#</option>
												</cfoutput>
											</select>
											</label>
											</cfif>
											<!--- submit button --->
											<input name="SubmitUpdate" type="submit" class="CWformButton" id="SubmitUpdate" value="Save Changes">
											<div style="clear:right;"></div>
											<!--- country table --->
											<!--- output countries and states --->
											<cfoutput query="statesQuery" group="country_id">
											<cfif url.country is 0 or url.country eq country_id or request.cwpage.recordsArchived>
											<cfset countryCounter = countryCounter + 1>
											<table class="CWinfoTable">
												<tr class="headerRow">
													<th width="<cfif request.cwpage.recordsArchived>280<cfelse>200</cfif>"><h3>#country_name#</h3></th>
													<th width="100">Sort</th>
													<cfif not request.cwpage.recordsArchived>
													<th width="80">Default</th>
													</cfif>
													<th width="80">Delete</th>
													<th width="80"><cfif request.cwpage.recordsArchived>Activate<cfelse>Archive</cfif></th>
												</tr>
												<tr>
													<!--- country code --->
													<td style="text-align:right;">
														Code: <input type="text" name="country_code#countryCounter#" value="#country_code#" size="8" onblur="checkValue(this)">
														<!--- hidden ID field --->
														&nbsp;&nbsp;&nbsp;ID: #country_id#
														<input name="country_id#countryCounter#" type="hidden" size="2" id="country_id#countryCounter#" value="#country_id#">
														<!--- country name --->
														<input type="hidden" name="country_name#countryCounter#" value="#country_name#" size="25">
													</td>
													<!--- sort --->
													<td>
														<input name="country_sort#countryCounter#" type="text" value="#country_sort#" size="3" class="sort" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
													</td>
													<cfif not request.cwpage.recordsArchived>
													<!--- default radio --->
													<td style="text-align:center">
														<input name="defCountry" type="radio" <cfif country_default_country eq 1 and country_id eq application.cw.defaultCountryID>checked="checked" </cfif>class="formRadio" value="#country_id#">
													</td>
													</cfif>
													<!--- delete --->
													<td style="text-align:center">
														<input name="country_Delete#countryCounter#" value="1" type="checkbox" class="formCheckbox radioGroup" rel="group#currentrow#"
														<cfif ListFind(CheckStateList,country_id) neq 0 OR ListFind(UsedCountryList,country_id) neq 0 OR ListFind(CustomerCountryList,country_id) neq 0> disabled="disabled"</cfif>>
													</td>
													<!--- archive --->
													<td style="text-align:center">
														<input name="country_archive#countryCounter#" value="<cfif request.cwpage.recordsArchived>0<cfelse>1</cfif>" type="checkbox" class="formCheckbox radioGroup archiveCountry" rel="group#currentrow#"
														<cfif ListFind(CustomerCountryList,country_id) neq 0 and request.cwpage.recordsarchived neq 1>onclick="if(this.checked) return confirm('This country has customers associated with it. Are you sure you want to archive?')"</cfif>>
													</td>
												</tr>
												<!--- only show states for active countries --->
												<cfif request.cwpage.recordsArchived neq 1>
													<tr>
														<td colspan="5">
															<cfset haveActiveState = False>
															<cfset stateTable = "">
															<cfif ListValueCount(iCountryList,country_id) gt 1>
																<cfsavecontent variable="stateTable">
																<table class="formTable infoTable CWstripe">
																	<tr class="sortRow">
																		<th width="200">Region Name</th>
																		<th width="90">Code</th>
																		<th>Ship Ext</th>
																		<cfif application.cw.taxCalctype is 'avatax'><th>Nexus</th></cfif>
																		<th>Delete</th>
																		<th>Archive</th>
																	</tr>
																	<cfoutput>
																	<cfif stateprov_code neq 'none' and stateprov_code neq 'all'>
																		<cfif stateprov_archive neq 1 AND haveActiveState eq False>
																			<cfset haveActiveState = True>
																		</cfif>
																		<cfset stateCounter = stateCounter + 1>
																		<tr>
																			<td><input type="text" name="stateprov_name#stateCounter#" value="#stateprov_name#" size="18"></td>
																			<td>
																				<input type="hidden" name="stateprov_id#stateCounter#" value="#stateprov_id#">
																				<input type="text" name="stateprov_code#stateCounter#" value="#stateprov_code#" size="6">
																			</td>
																			<td>#stateprov_ship_ext#%</td>
																			<cfif application.cw.taxCalctype is 'avatax'>
																				<td style="text-align:center">
																					<input type="checkbox" class="formCheckbox radioGroup" name="stateprov_nexus#stateCounter#"<cfif statesQuery.stateprov_nexus is 1> checked="checked"</cfif> value="1">
																				</td>
																			</cfif>
																			<td style="text-align:center">
																				<input type="checkbox" class="formCheckbox radioGroup checkAllDel#country_id#" name="stprv_Delete#stateCounter#" rel="sp#stateprov_id#" value="1"
																				<cfif ListFind(UsedStateList,stateprov_id) neq 0 OR ListFind(CustomerStateList,stateprov_id)> disabled="disabled"</cfif>>
																			</td>
																			<td style="text-align:center"><input type="checkbox" class="formCheckbox radioGroup checkAllArch#country_id#" name="stateprov_archive#stateCounter#" rel="sp#stateprov_id#" value="1"<cfif stateprov_archive eq 1> checked="checked"</cfif>
																				<cfif ListFind(CustomerStateList,stateprov_id) neq 0>onclick="if(this.checked) return confirm('This state has customers associated with it. Are you sure you want to archive?')"</cfif>>
																			</td>
																		</tr>
																	</cfif>
																	</cfoutput>
																</table>
																</cfsavecontent>
															</cfif>
															<cfif NOT haveActiveState>
																There are no active states for this country
															</cfif>
															#stateTable#
														<!--- /end archived/active --->
														</td>
													</tr>
												</cfif>
											</table>
											</cfif>
											</cfoutput>
											<!--- submit button --->
											<input name="SubmitUpdate" type="submit" class="CWformButton SubmitUpdate" value="Save Changes">
											<!--- hidden counter fields --->
											<input type="hidden" name="countryCounter" value="<cfoutput>#countryCounter#</cfoutput>">
											<input type="hidden" name="stateCounter" value="<cfoutput>#stateCounter#</cfoutput>">
											<!--- if we have disabled delete boxes, explain --->
											<span class="smallPrint" style="float:right;">
												Note: countries or regions with associated customer records cannot be deleted
											</span>
										</td>
									</tr>
									</tbody>
								</table>
								<!--- end records table --->
							</cfif>
							<!--- /end country id --->
						</form>
					</div>
					<!-- /end Page Content -->
					<div class="clear"></div>
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