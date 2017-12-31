<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: config-settings.cfm
File Date: 2012-09-01
Description: Creates dynamic 'config' form for custom application settings
These settings and related form elements are managed via config-groups.cfm
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
<!--- default group ID --->
<cfparam name="url.group_id" default="0">
<!--- current record params --->
<cfparam name="request.cwpage.groupName" default="">
<cfparam name="request.cwpage.currentRecord" default="#url.group_id#">
<cfparam name="request.cwpage.userAlert" default="">
<cfparam name="request.cwpage.userConfirm" default="">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,userconfirm,useralert,clickadd,resetapplication")>
<!--- create the base url for sorting out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- QUERY: get config group details --->
<cfset configGroupQuery = CWquerySelectConfigGroupDetails(url.group_id,'')>
<!--- QUERY: get config items in this group --->
<cfset itemsQuery = CWquerySelectConfigItems(url.group_id)>
<!--- set page variables --->
<cfset request.cwpage.groupName = configGroupQuery.config_group_name>
<!--- if developer, show link to edit config group --->
<cfif request.cwpage.accessLevel is 'developer'>
	<cfset request.cwpage.groupdetailslink = ' &nbsp; <a href="config-group-details.cfm?group_id=#url.group_id#">Edit Config Group</a>'>
<cfelse>
	<cfset request.cwpage.groupdetailslink = ''>
</cfif>
<!--- use rich text editor  y/n --->
<cfparam name="request.cwpage.rte" default="0">
<cfif valueList(itemsQuery.config_type) contains 'texteditor' AND application.cw.adminEditorEnabled is not 0>
	<cfset rteFields = ''>
	<cfset request.cwpage.rte = 1>
</cfif>
<!--- Only allow developer is showadmin is not 1 in config group query --->
<cfif configGroupQuery.config_group_show_merchant neq 1
	AND NOT listFindNoCase('developer',request.cwpage.accessLevel)>
	<cfset request.cwpage.userDenied = 1>
</cfif>
<!--- config items form --->
<cfparam name="form.config_name" default="">
<cfparam name="form.config_variable" default="">
<cfparam name="form.config_value" default="">
<!--- /////// --->
<!--- UPDATE CONFIG ITEMS --->
<!--- /////// --->
<!--- look for at least one valid ID field --->
<cfif isDefined('form.config_ID1')>
	<cfset loopCt = 1>
	<cfset updateCt = 0>
	<cfset deleteCt = 0>
	<!--- loop record ids, handle each one as needed --->
	<cfloop list="#form.recordIDlist#" index="ID">
		<!--- UPDATE RECORDS --->
		<!--- param value for checkboxes --->
		<cfparam name="form['config_value#loopct#']" default="0">
		<!--- QUERY: update config item (
		item ID, group ID, variable, name, value, type, description,
		possibles, showmerchant, sort)--->
		<cfset updateRecordID = CWqueryUpdateConfigItem(
		#form["config_ID#loopct#"]#,
		#request.cwpage.currentRecord#,
		#form["config_variable#loopct#"]#,
		#form["config_name#loopct#"]#,
		#form["config_value#loopct#"]#
		)>
		<!--- if an error is returned from update query --->
		<cfif left(updateRecordID,2) eq '0-'>
			<cfset errorMsg = listLast(updateRecordID,'-')>
			<cfset CWpageMessage("alert",errorMsg)>
			<!--- if no error --->
		<cfelse>
			<!--- create application variable  --->
			<cfset application.cw[form["config_variable#loopct#"]] = form["config_value#loopct#"] >
			<!--- update complete: continue processing --->
			<cfset updateCt = updateCt + 1>
		</cfif>
		<!--- end error check --->
		<cfset loopCt = loopCt + 1>
	</cfloop>
	<!--- set mandatory tax settings if not localtax --->
	<cfif isDefined('application.cw.taxCalctype') and application.cw.taxCalctype is not 'localTax'>
		<cfset setTaxRequirements = CWsetNonLocalTaxOptions()>
		<cfset CWpageMessage("alert","Note: Tax settings adjusted to match #application.cw.taxCalctype# requirements")>
	</cfif>
	<!--- get the vars to keep by omitting the ones we don't want repeated --->
	<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert,method,resetapplication")>
	<!--- set up the base url --->
	<cfset request.cwpage.relocateUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
	<!--- save confirmation text --->
	<cfsavecontent variable="request.cwpage.userConfirmText">
	<cfif updateCt gt 0><cfoutput>#request.cwpage.groupName#</cfoutput> Update Complete</cfif>
	</cfsavecontent>
	<cfset CWpageMessage("confirm",request.cwpage.userConfirmText)>
	<!--- return to page as submitted, clearing form scope --->
	<cflocation url="#request.cwpage.relocateUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&useralert=#CWurlSafe(request.cwpage.userAlert)#&resetapplication=#application.cw.storePassword#" addtoken="no">
</cfif>
<!--- /////// --->
<!--- /END UPDATE CONFIG ITEMS --->
<!--- /////// --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Manage Config Group">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Site Settings: #request.cwpage.groupName#">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 =  "Manage application controls and other custom settings#request.cwpage.groupdetailslink#">
<!--- current menu marker --->
<cfset request.cwpage.currentNav = "#request.cw.thisPage#?group_id=#request.cwpage.currentRecord#">
<!--- load form scripts --->
<cfset request.cwpage.isFormPage = 1>
<!--- load table scripts --->
<cfset request.cwpage.isTablePage = 0>
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
			// show help in config items list
			jQuery('#recordForm a.showHelpLink').click(function(){
				jQuery(this).parents('tr').next('tr.helpText').toggle();
				return false;
				}).parents('th').css('cursor','pointer').click(function(){
				jQuery(this).children('a').click();
				});
			// avatax admin console link
			<cfif url.group_id is 5 and application.cw.taxCalctype is 'avatax'>
				var avaTaxUrl = 'https://admin-<cfif application.cw.avalaraUrl contains "development">development<cfelse>avatax</cfif>.avalara.net/login.aspx';
				var avaTaxLink = '<a href="' + avaTaxUrl + '" target="_blank" title="' + avaTaxUrl + '">AvaTax Admin Console</a>';
				jQuery(avaTaxLink).appendTo('h3 + p.subText').css('margin-left','400px');
			</cfif>
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
						<!--- if a valid record is not found --->
						<cfif not configGroupQuery.recordCount is 1 OR isDefined('request.cwpage.userDenied')>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>Invalid selection. Choose a different page from the admin menu.</p>
							<!--- if a group record is found --->
						<cfelse>
							<!--- /////// --->
							<!--- UPDATE CONFIG ITEMS --->
							<!--- /////// --->
							<p>&nbsp;</p>
							<h3><cfoutput>#request.cwpage.groupName#</cfoutput></h3>
							<cfif len(trim(configGroupQuery.config_group_description))>
								<p class="subText"><cfoutput>#configGroupQuery.config_group_description#</cfoutput></p>
							</cfif>
							<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" name="recordForm" id="recordForm" method="post" class="CWobserve CWvalidate">
								<table class="CWstripe CWformTable wide">
									<!--- output form fields --->
									<tbody>
									<cfoutput query="itemsQuery">
									<!--- if the field name is valid --->
									<cfif len(trim(itemsQuery.config_name)) and len(trim(itemsQuery.config_variable))>
										<cfsilent>
										<!--- create per-item values  --->
										<cfset fieldType = itemsQuery.config_type>
										<cfset fieldName = "config_value#currentRow#">
										<cfset fieldID = fieldName>
										<!--- vat/tax labels get special treatment --->
										<cfif request.cwpage.currentRecord is 5 and not itemsQuery.config_variable eq 'taxSystemLabel'>
											<cfset fieldLabel = replaceNoCase(itemsQuery.config_name,'Tax',application.cw.taxSystemLabel,'all')>
										<cfelse>
											<cfset fieldLabel = itemsQuery.config_name>
										</cfif>
										<cfset fieldValue = itemsQuery.config_value>
										<cfset fieldOptions = itemsQuery.config_possibles>
										<cfset fieldHelp = itemsQuery.config_description>
										<!--- required fields --->
										<cfif itemsQuery.config_required eq true>
											<cfset fieldClass = 'required'>
										<cfelse>
											<cfset fieldClass = ''>
										</cfif>
										<!--- email fields --->
										<cfif right(itemsQuery.config_name,5) is 'email'>
											<cfset fieldClass = fieldClass & ' email'>
										</cfif>
										<cfset fieldSize = itemsQuery.config_size>
										<cfset fieldRows = itemsQuery.config_rows>
										<!--- set up list of text editor fields --->
										<cfif config_type is 'texteditor' and request.cwpage.rte>
											<cfset rteFields = listAppend(rteFields,fieldName)>
										</cfif>

										<!--- CUSTOM FIELDS can be managed here, reference config_variable value --->

										<!--- Get Themes : Admin style directory --->
										<cfif itemsQuery.config_variable is 'adminThemeDirectory'>
											<!--- get directories within admin/theme --->
											<cfdirectory name="getThemes" action="list" directory="#expandPath('theme')#" type="dir" recurse="false">
											<cfsavecontent variable = "fieldOptions">
												<!--- set up list of theme names for selection --->
											<cfloop query="getThemes">#getThemes.name#|#getThemes.name##chr(13)#</cfloop>
											</cfsavecontent>
										</cfif>

										<!--- FormField function creates field by type --->
										<cfset inputEl = CWformField(
										fieldType,
										fieldName,
										fieldID,
										fieldLabel,
										fieldValue,
										trim(fieldOptions),
										fieldClass,
										fieldSize,
										fieldRows
										)>
										</cfsilent>
										<tr class="config-#itemsQuery.config_variable#">
											<th class="label iconCell" title="#trim(itemsQuery.config_description)#">
												<!--- help link --->
												<cfif len(trim(itemsQuery.config_description))>
													<a href="##" class="showHelpLink"><img width="16" height="16" align="absmiddle" alt="" title="#CWstringFormat(itemsquery.config_description)#" src="img/cw-help.png"></a>
												</cfif>
												<!--- label --->
												#fieldLabel#
												<!--- hidden form inputs --->
												<input type="hidden" name="configItem#CurrentRow#" value="#itemsQuery.config_id#">
												<input type="hidden" name="config_Name#CurrentRow#" value="#itemsQuery.config_name#">
												<input type="hidden" name="config_Variable#CurrentRow#" value="#itemsQuery.config_variable#">
												<input type="hidden" name="config_ID#CurrentRow#" value="#itemsQuery.config_id#">
												<input type="hidden" name="config_show_merchant#CurrentRow#" value="#itemsQuery.config_show_merchant#">
												<input name="recordIDlist" type="hidden" value="#itemsQuery.config_ID#">
											</th>
											<!--- show the form input here --->
											<td>#inputEl#</td>
										</tr>
										<tr class="helpText config-#itemsQuery.config_variable#">
											<td colspan="2">
												<!--- hidden help text --->
												<div>
													<p><strong>#itemsQuery.config_description#</strong>
													<cfif listFindNoCase('merchant,developer',request.cwpage.accessLevel)>
														<br>(application.cw.#itemsQuery.config_variable#)
													</cfif>
													</p>
												</div>
											</td>
										</tr>
									</cfif>
									<!--- / end valid name check --->
									</cfoutput>
									</tbody>
								</table>
								<!--- submit button - save changes --->
								<input name="SubmitUpdate" type="submit" class="submitButton" id="UpdateConfigItems" value="Save Changes">
							</form>
							<!--- RTE rich text editor fields --->
							<cfif request.cwpage.rte>
								<cfinclude template="cwadminapp/inc/cw-inc-admin-script-editor.cfm">
							</cfif>
							<!--- /////// --->
							<!--- /END UPDATE CONFIG ITEMS --->
							<!--- /////// --->
						</cfif>
						<!--- /end valid config group record --->
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