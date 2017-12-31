<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-alerts.cfm
File Date: 2012-08-25
Description: handles customer alerts for store pages, based on URL and/or request vars
NOTE: important messages can be persisted through session.cw.userAlert or session.cw.userConfirm
==========================================================
--->
	<!--- global functions--->
	<cfif not isDefined('variables.CWtime')>
		<cfinclude template="../func/cw-func-global.cfm">
	</cfif>
	<!--- alert for application reset --->
	<cfif isDefined('request.cwpageReset') and request.cwpageReset
		and isDefined('session.cw.loggedIn') and session.cw.loggedIn is '1'
		and isDefined('session.cw.accessLevel') and	listFindNoCase('developer,merchant',session.cw.accessLevel)>
		<cfset CWpageMessage('confirm','Application Reset Complete')>
	</cfif>
	<!--- handle any session alerts --->
	<cfif isDefined('session.cw.userAlert') and len(trim(session.cw.userAlert))>
		<cfset CWpageMessage('alert',session.cw.userAlert)>
		<cfset session.cw.userAlert = ''>
	</cfif>
	<cfif isDefined('session.cw.userConfirm') and len(trim(session.cw.userConfirm))>
		<cfset CWpageMessage('confirm',session.cw.userConfirm)>
		<cfset session.cw.userConfirm = ''>
	</cfif>
	<!--- handle any URL alerts --->
	<cfif isDefined('url.useralert') and len(trim(url.useralert))>
		<cfset CWpageMessage('alert',url.useralert)>
	</cfif>
	<cfif isDefined('url.userconfirm') and len(trim(url.userconfirm))>
		<cfset CWpageMessage('confirm',url.userconfirm)>
	</cfif>
	<!--- force alert to array from string --->
	<cfif (isDefined('request.cwpage.userAlert') AND not isArray(request.cwpage.userAlert))>
		<cfset origStrTemp = trim(request.cwpage.userAlert)>
		<cfset request.cwpage.userAlert = arrayNew(1)>
		<cfset arrayAppend(request.cwpage.userAlert,origStrTemp)>
	<cfelseif not isDefined('request.cwpage.userAlert')>
		<cfset request.cwpage.userAlert = arrayNew(1)>
	</cfif>
	<!--- force confirmation to array from string --->
	<cfif (isDefined('request.cwpage.userConfirm')
		   AND not isArray(request.cwpage.userConfirm))>
		<cfset origStrTemp = trim(request.cwpage.userConfirm)>
		<cfset request.cwpage.userConfirm = arrayNew(1)>
		<cfset arrayAppend(request.cwpage.userConfirm,origStrTemp)>
	<cfelseif not isDefined('request.cwpage.userConfirm')>
		<cfset request.cwpage.userConfirm = arrayNew(1)>
	</cfif>
	<!--- loop the  alert arrays, creating output --->
	<cfsavecontent variable="request.cwpage.displayAlert">
		<cfloop array="#request.cwpage.userAlert#" index="aa">
			<cfset aa = replace(aa,'<br>','','all')>
			<cfset aa = replace(aa,'&lt;','<','all')>
			<cfset aa = replace(aa,'&lt','<','all')>
			<cfset aa = replace(aa,'&gt;','>','all')>
			<cfset aa = replace(aa,'&gt','>','all')>
			<cfset aa = replace(aa,'&quot;','"','all')>
			<cfset aa = replace(aa,'&quot','"','all')>
			<cfif len(trim(aa))><div class="alertText"><cfoutput>#aa#</cfoutput></div></cfif>
		</cfloop>
		<cfloop array="#request.cwpage.userConfirm#" index="cc">
			<cfset cc = replace(cc,'<br>','','all')>
			<cfset cc = replace(cc,'&lt;','<','all')>
			<cfset cc = replace(cc,'&lt','<','all')>
			<cfset cc = replace(cc,'&gt;','>','all')>
			<cfset cc = replace(cc,'&gt','>','all')>
			<cfset aa = replace(aa,'&quot;','"','all')>
			<cfset aa = replace(aa,'&quot','"','all')>
			<cfif len(trim(cc))><div class="confirmText"><cfoutput>#cc#</cfoutput></div></cfif>
		</cfloop>
	</cfsavecontent>
		
	<!--- if we have an alert, scroll page to top so it is shown --->
	<cfif len(trim(request.cwpage.displayAlert))>
	<script type="text/javascript">
	jQuery(document).ready(function(){
	// scroll to top if showing alerts
	  	jQuery("html").scrollTop(0);
	});
	</script>
	</cfif>
</cfsilent>
<!-- user alert - message shown to user
	NOTE: keep on one line for cross-browser script support -->
<div id="CWuserAlert" class="fadeOut CWcontent"<cfif not len(trim(request.cwpage.displayAlert))> style="display:none;"</cfif>><cfoutput>#trim(request.cwpage.displayAlert)#</cfoutput></div>