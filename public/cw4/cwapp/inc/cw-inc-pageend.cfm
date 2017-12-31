<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-pageend.cfm
File Date: 2012-09-05
Description: sets cookie values, shows debugging output in store pages
==========================================================
--->
</cfsilent>
<!--- SET COOKIES --->
<cfparam name="application.cw.appCookieTerm" default="">
<!--- if using cookies --->
<cfif application.cw.appCookieTerm neq 0>
	<!--- set all variables in 'session.cwclient' into cookie scope --->
	<cfif isDefined('session.cwclient')>
	<!--- vars not to write to cookies (defaulted here, hardcoded in cw-func-init) --->
	<cfparam name="request.cw.noCookieSessionVars" default="cfid,cftoken,sessionid,jsessionid,urltoken,cwUserName,cwCustomerType,cwOrderTotal,cwShipCountryID,cwShipregionID,cwShipTotal,cwShipTaxTotal,cwTaxCountryID,cwTaxRegionID,cwTaxTotal,cwPwSent,discountApplied,discountPromoCode">
	<cfloop collection="#session.cwclient#" item="cc">
		<cftry>
			<cfif not listFindNoCase(request.cw.noCookieSessionVars,cc)>
				<cfset cookieVal = evaluate('session.cwclient.#cc#')>
				<cfif len(trim(cookieVal))>
					<cfcookie name="#cc#" value="#cookieVal#" expires="#request.cw.cookieExpire#">
				<cfelse>
					<cfcookie name="#cc#" value="" expires="NOW">
				</cfif>
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
</cfif>
<!--- DEBUG OUTPUT --->
<!--- session.cw.debug is controlled in init functions for page request --->
<cfif IsDefined("session.cw.debug") and session.cw.debug eq "true">
	<cfsilent>
		<!--- BASE LINK FOR DEBUG ON/OFF --->
		<!--- debug link url --->
		<cfset resetVarsToKeep = CWremoveUrlVars("debug,userConfirm,userAlert,resetapplication")>
		<cfset request.cw.baseString = CWserializeUrl(resetVarsToKeep, request.cw.thisPage)>
		<cfset request.cw.baseDebugLink = request.cw.baseString & '&debug=' & application.cw.storePassword>
	<cfif isDefined('application.cw.debugDisplayExpanded') and application.cw.debugDisplayExpanded is 1>
	<cfset request.cwpage.showDump = true>
	<cfelse>
	<cfset request.cwpage.showDump = false>
	</cfif>
	<!--- set up list of variables to show --->
	<cfset session.cw.debugList = ''>
	<cfif isdefined("application.cw.debugLocal") and application.cw.debugLocal eq true>
	<cfset session.cw.debugList = listAppend(session.cw.debugList,'Variables')>
	</cfif>
	<cfif isdefined("application.cw.debugSession") and application.cw.debugSession eq true>
	<cfset session.cw.debugList = listAppend(session.cw.debugList,'Session')>
	</cfif>
	<cfif isdefined("application.cw.debugApplication") and application.cw.debugApplication eq true>
	<cfset session.cw.debugList = listAppend(session.cw.debugList,'Application')>
	</cfif>
	<cfif isdefined("application.cw.debugForm") and application.cw.debugForm eq true>
	<cfset session.cw.debugList = listAppend(session.cw.debugList,'Form')>
	</cfif>
	<cfif isdefined("application.cw.debugUrl") and application.cw.debugUrl eq true>
	<cfset session.cw.debugList = listAppend(session.cw.debugList,'URL')>
	</cfif>
	<cfif isdefined("application.cw.debugRequest") and application.cw.debugRequest eq true>
	<cfset session.cw.debugList = listAppend(session.cw.debugList,'Request')>
	</cfif>
	<cfif isdefined("application.cw.debugCookies") and application.cw.debugCookies eq true>
	<cfset session.cw.debugList = listAppend(session.cw.debugList,'Cookie')>
	</cfif>
	<cfif isdefined("application.cw.debugCGI") and application.cw.debugCGI eq true>
	<cfset session.cw.debugList = listAppend(session.cw.debugList,'CGI')>
	</cfif>
	<cfif isdefined("application.cw.debugServer") and application.cw.debugServer eq true>
	<cfset session.cw.debugList = listAppend(session.cw.debugList,'Server')>
	</cfif>
	<!--- debugging anchor links - jump to each section directly if shown expanded--->
	<cfsavecontent variable="request.cwpage.debugAnchors">
	<p class="debugAnchors">
	<!--- anchor links to each section --->
	<cfloop list="#session.cw.debugList#" index="dd">
	<cfset dd=trim(dd)>
	<cfoutput><a href="##debug-#dd#">#dd#</a></cfoutput>
	</cfloop>
	</p>
	</cfsavecontent>
	</cfsilent>
	<!--- SHOW DEBUG OUTPUT --->
	<div id="CWdebugWrapper" class="CWcontent">
	<!--- turn off debugging / show top of page --->
	<a name="debug-top" class="debugAnchorLink"></a>
	<!--- loop list, show debug cfdumps --->
	<div class="inner">
	<h1>DEBUGGING OUTPUT</h1>
		<cfif request.cwpage.showDump>
			<cfoutput>#request.cwpage.debugAnchors#</cfoutput>
		</cfif>
		<strong><a class="controlButton" href="<cfoutput>#request.cw.baseDebugLink#</cfoutput>">Turn Off Debugging</a></strong>
		<cfloop list="#session.cw.debugList#" index="dd">
			<cfif len(trim(dd))>
				<cfset dd=trim(dd)>
				<cfoutput><a name="debug-#dd#" class="debugAnchorLink"></a></cfoutput>
				<cfoutput><h1 class="clear">#dd#
				<span class="smallPrint">( <a href="##debug-top">top</a> )</span>
				</h1></cfoutput>
				<cfset dumpVar = evaluate(dd)>
				<cfdump var="#dumpVar#" label="#dd#" expand="#request.cwpage.showDump#">
			</cfif>
		</cfloop>
		<!--- /END Inner Div --->
	</div>
	<div class="CWclear"></div>
	<!--- /END Debug Wrapper --->
	</div>
</cfif>