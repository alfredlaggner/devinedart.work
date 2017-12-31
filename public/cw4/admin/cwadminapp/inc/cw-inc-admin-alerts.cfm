<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-alerts.cfm
File Date: 2012-06-05
Description: handles alerts for admin pages, based on URL and/or request vars
NOTE:
important messages can be persisted through session.cw.useralert or session.cw.userconfirm
==========================================================
--->

<!--- alert for default email --->
<cfif isDefined('application.cw.appTestModeEnabled') and not application.cw.appTestModeEnabled eq true>
	<cfif isDefined('application.cw.companyemail') AND application.cw.companyemail contains "@cartweaver">
		<cfset CWpageMessage('alert','Please change your <a href="config-settings.cfm?group_ID=3">company email</a>. It is currently set to the Cartweaver default value.')>
	</cfif>
</cfif>
<!--- alert for application reset --->
<cfif isDefined('request.cwpageReset') and request.cwpageReset>
	<cfset CWpageMessage('confirm','Application Reset Complete')>
</cfif>
<!--- Handle any session alerts --->
<cfif isDefined('session.cw.useralert') and len(trim(session.cw.useralert))>
	<cfset CWpageMessage('alert',session.cw.useralert)>
</cfif>
<cfif isDefined('session.cw.userconfirm') and len(trim(session.cw.userconfirm))>
	<cfset CWpageMessage('confirm',session.cw.userconfirm)>
</cfif>
<!--- Handle any URL alerts --->
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
<cfif (isDefined('request.cwpage.userConfirm') AND not isArray(request.cwpage.userConfirm))>
	<cfset origStrTemp = trim(request.cwpage.userConfirm)>
	<cfset request.cwpage.userConfirm = arrayNew(1)>
	<cfset arrayAppend(request.cwpage.userConfirm,origStrTemp)>
<cfelseif not isDefined('request.cwpage.userConfirm')>
	<cfset request.cwpage.userConfirm = arrayNew(1)>
</cfif>
<!--- loop the  alert arrays, creating output --->
<cfsavecontent variable="request.cwpage.displayAlert">
<cfloop array="#request.cwpage.userAlert#" index="aa">
	<cfif len(trim(aa))><div><cfoutput>#replace(aa,',','<br>','all')#</cfoutput></div></cfif>
</cfloop>
<cfloop array="#request.cwpage.userConfirm#" index="cc">
	<cfif len(trim(cc))><div class="confirm"><cfoutput>#replace(cc,',','<br>','all')#</cfoutput></div></cfif>
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
<!--- link to close the alert area --->
<cfset closeAlertLink = '<a href="##" id="closeAlertLink"><img src="img/cw-close-window.png" alt="Hide Alert"></a>'>
</cfsilent>
<!-- admin alert - message shown to user
NOTE: keep on one line for cross-browser script support -->
<div id="CWadminAlert" class="alert" <cfif not len(trim(request.cwpage.displayAlert))>style="display:none;"</cfif>><cfoutput>#closeAlertLink##trim(request.cwpage.displayAlert)#</cfoutput></div>
<!--- if no javascript, show alert --->
<noscript>
<div id="CWadminAlertNoScript" class="alert">
	Scripts disabled: enable browser JavaScript to use this application
</div>
</noscript>