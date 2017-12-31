<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-app-cfcstart.cfc
File Date: 2012-02-01
Description:
Global ColdFusion application settings, used in Application.cfc
==========================================================
--->
<!--- unique application name - build dynamically from server + dsn --->
<cfset this.name = 'CW' & hash(replace((cgi.host_name & request.cwapp.datasourcename),'.','-','all'))>
<!--- time out settings for the overall application --->
<cfset this.applicationTimeout = createTimeSpan(0,0,60,0)>
<!--- activate sessions on the CF server --->
<cfset this.sessionManagement = true>
<!--- time out settings for individual sessions --->
<cfset this.sessionTimeout = createTimeSpan(0,0,30,0)>