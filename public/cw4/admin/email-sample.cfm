<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: order-email.cfm
File Date: 2012-02-01
Description: Displays order email confirmation message contents
==========================================================
--->
<!--- GLOBAL INCLUDES --->
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- include the mail functions --->
<cfinclude template="#request.cwpage.cwapppath#func/cw-func-mail.cfm">
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("any")>
<!--- PAGE PARAMS --->
<cfparam name="url.orderid" default="">
<!--- build sample email --->
<cfsavecontent variable="sampleContent">
<cfoutput>#application.cw.mailDefaultOrderReceivedIntro#</cfoutput>

[SAMPLE ORDER CONTENTS - DEMO ONLY]
Order ID: 1111161122-FC4E

Ship To
====================
Wanda Buymore
1234 st
some town, Alabama
99999 United States

Order Contents
====================
Digital Point & Shoot Camera (DigitalPoint-n-Shoot-Blue)
Color: Blue
Quantity: 1
Price: $125.00
Item Total: $125.00


LawnPower Ride Lawn Mower (SKU: LawnPower Riding-6y)
Color: Yellow
HP: 6 HP
Quantity: 1
Price: $899.00
Item Total: $899.00


Order Totals
====================
Subtotal: $1,024.00
Shipping (UPS Ground): $17.21

ORDER TOTAL: $1,041.21

<cfoutput>#application.cw.mailDefaultOrderReceivedEnd#</cfoutput>

</cfsavecontent>
<cfsavecontent variable="sampleSubject">
Email Message Subject Shown Here
</cfsavecontent>

<cfset mailContent = CWmailContents(sampleContent,sampleSubject)>
</cfsilent>

<!--- show contents as HTML page --->
<cfoutput>#mailcontent.messageHtml#</cfoutput>
