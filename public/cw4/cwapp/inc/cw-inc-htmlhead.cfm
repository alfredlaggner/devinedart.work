<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-htmlhead.cfm
File Date: 2012-02-01
Description: inserts global scripts and assets into page head
via ColdFusion's "onRequestStart" method (see Application.cfc)
==========================================================
--->
<cfsavecontent variable="cwhtmlhead">
<!--- jQuery library file - must be loaded in page head before any other jQuery --->
<cfoutput><script type="text/javascript" src="#request.cw.assetSrcDir#js/jquery-1.7.1.min.js"></script></cfoutput>
<!--- global scripts for Cartweaver --->
<cfinclude template="cw-inc-scripts.cfm">
<!--- core css, handles layout and structure, imports theme/cw-theme.css
	  (uncomment to apply globally for cw pages) --->
<!---
<cfoutput><link href="#request.cw.assetSrcDir#css/cw-core.css" rel="stylesheet" type="text/css"></cfoutput>
--->
</cfsavecontent>
<cfhtmlhead text="#cwhtmlhead#">
</cfsilent>