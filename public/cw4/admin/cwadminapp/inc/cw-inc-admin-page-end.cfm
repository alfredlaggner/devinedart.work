<cfif IsDefined("session.cw.debug") and session.cw.debug eq "true">
<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-page-end.cfm
File Date: 2012-02-01
Description: shows debugging output in admin pages
==========================================================
--->
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
<cfif isdefined("application.cw.debugClient") and application.cw.debugClient eq true>
<cfset session.cw.debugList = listAppend(session.cw.debugList,'Client')>
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
<div class="clear"></div>
<!--- SHOW DEBUG OUTPUT --->
<div id="CWdebugWrapper">
<!--- help link --->
<div id="CWdebugHelp">
	<a href="http://help.cartweaver.com/CW4_Docs_AdminHelp/index.cfm?pagename=<cfoutput>#request.cwpage.helpFileName#</cfoutput>" class="zoomHelp" rel="external" title="Help for this page">
	<img width="16" height="16" align="absmiddle" alt="Help for this page" src="img/cw-help.png">
	</a>
</div>
<!--- turn off debugging / show top of page --->
<cfif isDefined('request.cw.baseDebugLink')>
	<strong><a class="controlButton" href="config-settings.cfm?group_ID=10">Debug Settings</a></strong>
	<strong><a class="controlButton" href="#">Scroll Up</a></strong>
	<strong><a class="controlButton" href="<cfoutput>#request.cw.baseDebugLink#</cfoutput>">Turn Off Debugging</a></strong>
</cfif>
<a name="debug-top" class="debugAnchorLink"></a>
<h1>DEBUGGING OUTPUT</h1>
<div class="clear"></div>
<!--- loop list, show debug cfdumps --->
<div class="inner">
	<cfif request.cwpage.showDump>
		<cfoutput>#request.cwpage.debugAnchors#</cfoutput>
	</cfif>
	<cfloop list="#session.cw.debugList#" index="dd">
		<cfif len(trim(dd))>
			<cfset dd=trim(dd)>
			<cfoutput><a name="debug-#dd#" class="debugAnchorLink"></a></cfoutput>
			<cfoutput><h1>#dd#
			<span class="smallPrint">( <a href="##debug-top">top</a> )</span>
			</h1></cfoutput>
			<cfset dumpVar = evaluate(dd)>
			<cfdump var="#dumpVar#" label="#dd#" expand="#request.cwpage.showDump#">
		</cfif>
	</cfloop>
	<cfoutput>#request.cwpage.debugAnchors#</cfoutput>
	<!--- /END Inner Div --->
</div>
<!--- /END Debug Wrapper --->
</div>
</cfif>
<!--- Throw Error for testing --->
<cfif isDefined('url.throw') and url.throw eq application.cw.storePassword>
<div class="clear"></div>
<cfset throwError = xxx.yyy>
</cfif>
