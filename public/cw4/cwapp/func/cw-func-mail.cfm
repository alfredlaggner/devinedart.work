<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-func-mail.cfm
File Date: 2012-10-17
Description: handles all email (cfmail) functions for the Cartweaver application
==========================================================
Usage:
Invoke the function with the text for a message, the subject,
and a list of "to" addresses (or a single address)
Message body text will automatically be converted to create the html version,
with linked URLs, when sending in multipart format
Global options for header, footer, plain text or html, are managed in Cartweaver admin
CSS message styles are in a separate function below

Example:
<cfsavecontent variable="messageText"> Save some text here to send as a message </cfsavecontent>
<cfset sendmail = CWsendMail(messageText,"Message Subject Here","sendto@addresshere.com")>

Note:
The functions below handle individual aspects of the mail compilation and delivery process,
and can be invoked separately for custom usage.
--->

<!--- set global mail variables --->
<cfscript>
variables.mailserver = application.cw.mailSmtpServer;
variables.mailuser = application.cw.mailSmtpUsername;
variables.mailpw = application.cw.mailSmtpPassword;
variables.mailmultipart = application.cw.mailmultipart;
variables.mailfrom = application.cw.companyemail;
variables.mailcompany = application.cw.companyName;
variables.mailadmin = application.cw.developeremail;
variables.mailheadtext = application.cw.mailheadtext;
variables.mailfoottext = application.cw.mailfoottext;
variables.mailheadhtml = application.cw.mailheadhtml;
variables.mailfoothtml = application.cw.mailfoothtml;
variables.mailcss = CWmailCss();
variables.mailtime = dateAdd('h',application.cw.globalTimeOffset,now());
variables.mailTimeStamp = dateFormat(variables.mailTime,application.cw.globalDateMask) & ' ' & timeFormat(variables.mailTime,'short');
</cfscript>

<!--- // ---------- // CWsendMail : Send email message(s) // ---------- // --->
<cffunction name="CWsendMail"
			access="public"
			output="false"
			returntype="string"
			hint="Sends multipart or plain text email to provided recipients, returns success or error message"
			>

	<cfargument name="mail_body"
			required="true"
			type="string"
			hint="The main contents of the message (text)">

	<cfargument name="mail_subject"
			required="true"
			type="string"
			hint="The subject of the email message">

	<cfargument name="mail_address_list"
			required="true"
			type="string"
			hint="Comma separated list of email addresses">

<cfset var mailResults = ''>
<cfset var mailCt = 0>
<cfset var s = ''>

<!--- set up mail contents --->
<cfset mailcontent = CWmailContents(trim(arguments.mail_body),trim(arguments.mail_subject))>

<!--- loop address list, delivering mail and tracking success or errors --->
<cfloop list="#arguments.mail_address_list#" index="aa">
<cftry>

<!--- verify mail valid --->
<cfif isValid('email',trim(aa))>
	<cfif len(trim(variables.mailserver))>
		<cfmail from="#variables.mailCompany# <#variables.mailFrom#>" to="#aa#" subject="#trim(arguments.mail_subject)#" server="#variables.mailserver#" username="#variables.mailUser#" password="#variables.mailPw#" failto="#variables.mailAdmin#">
		<!--- multipart message (html/text) --->
		<cfif variables.mailmultipart eq true>
				<!--- text part --->
			<cfmailpart type="text">
			<cfoutput>#mailcontent.messagetext#</cfoutput>
			</cfmailpart>
				<!--- html part --->
			<cfmailpart type="html">
			<cfoutput>#mailcontent.messagehtml#</cfoutput>
			</cfmailpart>
				<!--- plain text only --->
		<cfelse>
			<cfoutput>#mailcontent.messagetext#</cfoutput>
		</cfif>
		</cfmail>

	<!--- if server not specified, use shorter attributes --->
	<cfelse>
		<cfmail from="#variables.mailCompany# <#variables.mailFrom#>" to="#aa#" subject="#trim(arguments.mail_subject)#" failto="#variables.mailAdmin#">
		<!--- multipart message (html/text) --->
		<cfif variables.mailmultipart eq true>
				<!--- text part --->
			<cfmailpart type="text">
			<cfoutput>#mailcontent.messagetext#</cfoutput>
			</cfmailpart>
				<!--- html part --->
			<cfmailpart type="html">
			<cfoutput>#mailcontent.messagehtml#</cfoutput>
			</cfmailpart>
				<!--- plain text only --->
		<cfelse>
			<cfoutput>#mailcontent.messagetext#</cfoutput>
		</cfif>
		</cfmail>
	</cfif>

<!--- if email address is not valid --->
<cfelse>
<cfthrow detail="#aa# is not a valid email address">
</cfif>
<cfset mailCt = mailCt + 1>
<!--- catch errors, add error to results --->
<cfcatch>
<cfset mailResults = listAppend(mailResults,'Error with address: #aa#')>
</cfcatch>
</cftry>
</cfloop>

<!--- add success message with number sent --->
<cfif mailCt gt 0>
	<cfif mailCt is 1>
		<cfset s = ''>
		<cfelse>
		<cfset s = 's'>
	</cfif>
	<cfset mailResults = listPrepend(mailResults, '#mailCt# message#s# sent')>
</cfif>
<!--- return the results as a string --->
<cfreturn mailResults>
</cffunction>

<!--- // ---------- // CWmailContents : assembles email message from provided components // ---------- // --->
<cffunction name="CWmailContents"
	access="public"
	output="false"
	returntype="struct"
	hint="Returns a two part struct with text/html content"
	>

	<cfargument name="mail_body"
			required="true"
			type="string"
			hint="The main contents of the message (text)">

	<cfargument name="mail_subject"
			required="true"
			type="string"
			hint="The subject of the email message">

<cfset var mailBodyText = arguments.mail_body>
<cfset var mailMessageText = ''>
<cfset var mailBodyHtml = CWhtmlText(mailBodyText)>
<cfset var mailMessageHTML = ''>
<cfset var lineBr = chr(13)>

<!--- TEXT --->
<!--- TEXT --->
<!--- TEXT --->
<!--- assemble message parts, header and footer if they exist, watching for cfmail line spacing --->
<cfsavecontent variable="mailMessageText"><cfoutput>
<cfif len(trim(variables.mailHeadText))>#variables.mailHeadText#
#linebr#</cfif>
#mailBodyText#
<cfif len(trim(variables.mailFootText))>#linebr#
#variables.mailFootText#</cfif>
#linebr#
Sent: #variables.mailTimeStamp##lineBr#
</cfoutput></cfsavecontent>
<!--- / end text --->
<!--- / end text --->
<!--- / end text --->

<!--- HTML --->
<!--- HTML --->
<!--- HTML --->
<cfif variables.mailmultipart>
<cfsavecontent variable="mailMessageHtml"><cfoutput>
<div id="wrapper">
<table id="mailcontent" cellpadding="0" cellspacing="0" align="center">
<!--- header --->
<cfif len(trim(variables.mailHeadHtml))><tr>
<td id="header">
#variables.mailHeadHtml#
</td>
</tr></cfif>
<tr>
<td class="content">
#mailBodyHtml#
</td>
</tr>
<!--- footer --->
<cfif len(trim(variables.mailFootHtml))><tr>
<td id="footer">
#variables.mailFootHtml#
</td>
</tr></cfif>
<!--- TimeStamp --->
<tr>
<td id="footnotes">
<p class="timestamp">Sent: #variables.mailTimeStamp#</p>
</td>
</tr>
</table>
<!--- / end wrapper div --->
</div>
</cfoutput></cfsavecontent>
<!--- add head and body sections (assume both missing if no <head> tag is present) --->
	<cfif not mailMessageHtml contains '<head>'>
<!--- add meta tags to message --->
	<cfsavecontent variable="variables.mailHtmlMeta">
<meta content="<cfoutput>#variables.mailcompany# #variables.mailtimestamp#</cfoutput>">
<meta http-equiv="Content-type" content="text/html; charset=us-ascii">
</cfsavecontent>
<!--- also add css to body (some mail services strip off the 'head') --->
		<cfset mailMessageHtml =  '<head>' & '<title>#arguments.mail_subject#</title>' & variables.mailHtmlMeta & '</head><body>' & variables.mailcss & mailMessageHtml & '</body>' >
	</cfif>
<!--- wrap in html tags --->
	<cfif not mailMessageHtml contains '<html>'>
		<cfset mailMessageHtml =  '<html>' & mailMessageHtml & '</html>'>
	</cfif>
<!--- add doctype  --->
	<cfif not mailMessageHtml contains '!DOCTYPE'>
		<cfset mailMessageHtml =  '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">' & mailMessageHtml>
	</cfif>
</cfif>
<!--- / end html --->
<!--- / end html --->
<!--- / end html --->

<!--- return a struct with two blocks of content --->
<cfset mailcontent = structNew()>
<cfset mailcontent.messageText = mailmessageText>
<cfset mailcontent.messageHtml = mailmessageHtml>
<cfreturn mailcontent>

</cffunction>

<!--- // ---------- // CWmailCss : contains inline styles to be applied to html formatted email // ---------- // --->
<cffunction name="CWmailCss"
			access="public"
			output="false"
			returntype="any"
			hint="Returns a block of css styles for email messages"
			>

<cfset var mailcss = ''>
<cfsavecontent variable="mailcss">
<style type="text/css" media="screen">
* {
padding: 0;
margin: 0;
}
html {
font-size: 62.5%;
}
/* --------- text align center on body works for older IE centering ---*/
body {
margin: 0;
padding: 0;
font-family: Verdana, Arial, Helvetica, sans-serif;
text-align: center;
line-height: 1;
background: #F5f5f5;
}
/* ------ WRAPPER:------- */
#wrapper {
margin: 12px auto;
width: 480px;
text-align:center;
}
/* ----------- MAIN TABLE text align left fixes text within body which is centered ----------*/
table#mailcontent{
border-collapse:collapse;
text-align:left;
width:480px;
}
table#mailcontent td{
border:0;
padding:0 28px;
}
/* ---------- STANDARD TEXT ---------*/
p, ul{
font-size: 11px;
margin: 5px 0 10px 0;
line-height: 15px;
font-family: Verdana, Arial, Helvetica, sans-serif;
color: #232323;
text-align: left;
}

/* ----------- HEADER ----------*/
table#mailcontent td#header {
text-align: center;
background-color: #e3e8ec;
color:#232323;
padding:0;
}
table#mailcontent td#header a {
text-decoration: none;
}
table#mailcontent td#header p {
margin:0;
text-align:center;
padding:0;
}
table#mailcontent td#header h1,
table#mailcontent td#header h2{
text-align:center;
color:#232323;
}
table#mailcontent td#header a:link,
table#mailcontent td#header a:visited,
table#mailcontent td#header a:hover,
table#mailcontent td#header a:active{
text-decoration:none;
color:#004080;
}

/*------- CONTENT -------*/
table#mailcontent td.content {
background-color: #FFFFFF;
padding-top:12px;
padding-bottom:12px;
}
p.timestamp {
text-align: center;
font-size: 10px;
color: #FFFFFF;
}
p.sentinfo {
text-align: left;
font-size: 10px;
font-style: italic;
margin-left: 28px;
color: #f9f9f9;
line-height:1.4em;
}
h1 {
font-size: 16px;
color: #232323;
margin:0;
line-height:1.2em;
text-align:left;
}
h2 {
font-size: 18px;
color: #232323;
margin: 8px 0 8px 0;
padding-bottom: 4px;
line-height:1.2em;
text-align:left;
}
h3 {
font-size: 12px;
font-weight:bold;
color: #232323;
margin: 8px 0 8px 0;
padding-bottom: 4px;
line-height:1.2em;
text-align:left;
}
h3 a:link, h3 a:visited, h3 a:active, h3 a:hover{
color: #004080;
}
/*------- FOOTER -------*/
#footer {
text-align: center;
padding: 4px 0;
background-color: #e3e8ec;
}
#footer p {
text-align: center;
}
</style>
</cfsavecontent>
<cfreturn mailcss>
</cffunction>

<!--- // ---------- // CWhtmlText : translate plain text into html with links for multipart email messages // ---------- // --->
<cffunction name="CWhtmlText"
			access="public"
			output="false"
			returntype="string"
			hint="Returns a block of html-formatted text"
			>
	<cfargument name="text_content"
			required="true"
			default=""
			type="string"
			hint="The text content to translate to HTML">

	<cfset var tempText = ''>
	<cfset var cleanText = ''>

	<cfset tempText = reReplaceNoCase(text_content,"(http://)?(\w+([\.\-]\w+)+\.[a-z]{2,4}(/\w+([\-\./]\w+)*(\?\w+([\-\./\%\&\##\=]\w+)*)?)?)","<a href='http://\2' >\2</a>","all")>
	<cfset tempText = reReplaceNoCase(tempText,"[\n\r]","<br>","all")>
	<cfset tempText = reReplaceNoCase('<br>' & tempText & '<br><br>',"<br>(.*)<br><br>","<p>\1</p>","all")>
	<cfset cleanText = replaceNoCase(tempText,'<br><br>','<br>','all')>
  <cfreturn cleanText>
</cffunction>

<!--- // ---------- Email Contents : construct order details for email confirmation ---------- // --->
<cffunction name="CWtextOrderDetails"
			access="public"
			output="false"
			returntype="string"
			hint="Returns a block of content containing order and product details"
			>

	<cfargument name="order_id"
			required="true"
			default="0"
			type="string"
			hint="The order ID to look up">

	<cfargument name="show_payments"
			required="false"
			default="false"
			type="boolean"
			hint="Show payment info (if payments exist)">

	<cfargument name="show_tax_id"
			required="false"
			default="#application.cw.taxDisplayID#"
			type="boolean"
			hint="Show tax/vat number on order confirmation">


<cfset var orderQuery = ''>
<cfset var optionsQuery = ''>
<cfset var paymentsQuery = ''>
<cfset var orderDetails = ''>
<cfset var linebr = chr(13)>
<cfset var orderDownloads = false>

<cfquery name="orderQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
SELECT
	ss.shipstatus_name,
	o.*,
	c.customer_first_name,
	c.customer_last_name,
	c.customer_id,
	c.customer_email,
	p.product_name,
	p.product_id,
	p.product_custom_info_label,
	p.product_out_of_stock_message,
	s.sku_id,
	s.sku_merchant_sku_id,
	s.sku_download_id,
	sm.ship_method_name,
	os.ordersku_sku,
	os.ordersku_unique_id,
	os.ordersku_quantity,
	os.ordersku_unit_price,
	os.ordersku_sku_total,
	os.ordersku_tax_rate,
	os.ordersku_discount_amount,
	(o.order_total - (o.order_tax + o.order_shipping + o.order_shipping_tax)) as order_SubTotal
FROM (
	cw_products p
	INNER JOIN cw_skus s
	ON p.product_id = s.sku_product_id)
	INNER JOIN ((cw_customers c
		INNER JOIN (cw_order_status ss
			RIGHT JOIN (cw_ship_methods sm
				RIGHT JOIN cw_orders o
				ON sm.ship_method_id = o.order_ship_method_id)
			ON ss.shipstatus_id = o.order_status)
		ON c.customer_id = o.order_customer_id)
		INNER JOIN cw_order_skus os
		ON o.order_id = os.ordersku_order_id)
	ON s.sku_id = os.ordersku_sku
WHERE o.order_id = <cfqueryparam value="#arguments.order_id#" cfsqltype="cf_sql_varchar">
ORDER BY
	p.product_name,
	s.sku_sort,
	s.sku_merchant_sku_id
</cfquery>

<!--- if including payments --->
<cfif arguments.show_payments>
	<cfquery name="paymentsQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT *
	FROM cw_order_payments
	WHERE order_id = <cfqueryparam value="#arguments.order_id#" cfsqltype="cf_sql_varchar">
	</cfquery>
</cfif>

<cfif orderQuery.recordCount>
<cfsavecontent variable="orderDetails">
<cfoutput>
Order ID: #orderQuery.order_id#<cfif arguments.show_tax_id and len(trim(application.cw.taxIDNumber))>#linebr#
#application.cw.taxSystemLabel# ID: #trim(application.cw.taxIDNumber)#</cfif>

Ship To
====================
#orderQuery.order_ship_name##lineBr#
<cfif len(trim(orderQuery.order_company))>#orderQuery.order_company##lineBr#</cfif>
#orderQuery.order_address1##lineBr#
<cfif len(trim(orderQuery.order_address2))>#orderQuery.order_address2##lineBr#</cfif>
#orderQuery.order_city#, #orderQuery.order_state##lineBr##orderQuery.order_zip#
#orderQuery.order_country#
#lineBr#</cfoutput>
Order Contents
====================
<cfoutput query="orderQuery" group="ordersku_unique_id">
<cfsilent>
<!--- set flag for download text if any downloadable items exist --->
<cfif len(trim(orderQuery.sku_download_id))>
	<cfset orderDownloads = true>
</cfif>
<cfquery name="optionsQuery" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
		SELECT cw_option_types.optiontype_name, cw_options.option_name
		FROM (cw_option_types
		INNER JOIN cw_options
		ON (cw_option_types.optiontype_id = cw_options.option_type_id)
		AND (cw_option_types.optiontype_id	= cw_options.option_type_id))
		INNER JOIN cw_sku_options
		ON cw_options.option_id	= cw_sku_options.sku_option2option_id
		WHERE cw_sku_options.sku_option2sku_id=#orderQuery.ordersku_sku#
		ORDER BY cw_option_types.optiontype_name, cw_options.option_sort
	</cfquery>
<!--- content below is formatted for cfmail --->
</cfsilent>
<cfif currentRow gt 1>#linebr#</cfif>
#orderQuery.product_name# (#orderQuery.sku_merchant_sku_id#)<cfloop query="optionsQuery">#lineBr##optionsQuery.optiontype_name#: #optionsQuery.option_name#
</cfloop>
Quantity: #orderQuery.ordersku_quantity#
Price: #lsCurrencyFormat(orderQuery.ordersku_unit_price,'local')#
<cfif application.cw.discountDisplayLineItem and orderQuery.ordersku_discount_amount gt 0>
Discount: #lsCurrencyFormat(orderQuery.ordersku_discount_amount,'local')#</cfif>
<cfif application.cw.taxDisplayLineItem and orderQuery.ordersku_tax_rate gt 0>
#application.cw.taxSystemLabel#: #lsCurrencyFormat(orderQuery.ordersku_tax_rate,'local')#</cfif>
Item Total: #lsCurrencyFormat(orderQuery.ordersku_sku_total,'local')##linebr##linebr#
</cfoutput><cfoutput>
Order Totals
====================
Subtotal: #lsCurrencyFormat(orderQuery.order_SubTotal+orderQuery.order_discount_total,'local')#
<cfif orderQuery.order_discount_total gt 0>
Discounts: - #lsCurrencyFormat(orderQuery.order_discount_total,'local')#</cfif>
<cfif orderQuery.order_tax gt 0>
#application.cw.taxSystemLabel#: #lsCurrencyFormat(orderQuery.order_tax,'local')#</cfif>
Shipping<cfif len(trim(orderquery.ship_method_name))> (#orderQuery.ship_method_name#)</cfif>: #lsCurrencyFormat(orderQuery.order_shipping + orderQuery.order_ship_discount_total,'local')#
<cfif orderQuery.order_ship_discount_total gt 0>
Shipping Discount: - #lsCurrencyFormat(orderQuery.order_ship_discount_total,'local')#</cfif>
<cfif orderQuery.order_shipping_tax gt 0>
Shipping #application.cw.taxSystemLabel#: #lsCurrencyFormat(orderQuery.order_shipping_tax,'local')#</cfif>#linebr#
ORDER TOTAL: #lsCurrencyFormat(orderQuery.order_total,'local')#
<cfif orderQuery.order_status eq 4>
Shipped: #DateFormat(orderQuery.order_ship_date,application.cw.globalDateMask)#
<cfif orderQuery.order_ship_tracking_id neq "">
Tracking Number: #orderQuery.order_ship_tracking_id#
</cfif>
</cfif><!--- /end if shipped --->
</cfoutput>
<cfif arguments.show_payments and paymentsQuery.recordCount> <!--- if showing payments --->
<cfoutput>#linebr#</cfoutput>
Payment Details
==================== <cfoutput query="paymentsQuery">
Payment Method: #payment_method#
Amount: #lsCurrencyFormat(payment_amount,'local')##linebr#</cfoutput>
</cfif><!--- /end payments --->
<!--- ordercomments ---><cfif len(trim(orderquery.order_comments))><cfoutput>
Order Comments:#lineBr#====================
#orderQuery.order_comments#
#lineBr#</cfoutput></cfif>
<!--- download text ---><cfif orderDownloads and application.cw.appDownloadsEnabled and listFind(application.cw.appDownloadStatusCodes,orderQuery.order_status) and isDefined('application.cw.appPageAccountUrl')>
<cfoutput>#lineBr##lineBr#Downloads:#lineBr#</cfoutput>====================
Log in to your account at <cfoutput>#application.cw.appPageAccountUrl#</cfoutput> to download your purchased items.
</cfif><!--- /end download text --->
</cfsavecontent>
</cfif>
<!--- /end if order exists --->
<!--- trim extra whitespace --->
<cfset orderText = lineBr & lineBr & trim(orderDetails) & lineBr & lineBr>
<!--- return text --->
<cfreturn orderText>
</cffunction>

<!--- // ---------- // Customer Password Email // ---------- // --->
<cffunction name="CWtextPasswordReminder"
			access="public"
			output="false"
			returntype="string"
			hint="Compiles cfmail content for password reminder email - ID and login url are required"
			>

	<cfargument name="customer_id"
			required="true"
			type="string"
			hint="ID of the customer to look up and deliver email to">

	<cfargument name="login_url"
			required="true"
			type="string"
			hint="ID of the customer to look up and deliver email to">

	<!--- company info for footer, defaults to application globals --->
	<cfargument name="company_name"
			required="false"
			default="#application.cw.companyName#"
			type="string"
			hint="Company name for footer of message - omitted if empty ('') ">

	<cfargument name="company_email"
			required="false"
			default="#application.cw.companyEmail#"
			type="string"
			hint="Company email for footer of message - omitted if empty ('') ">

	<cfargument name="company_phone"
			required="false"
			default="#application.cw.companyPhone#"
			type="string"
			hint="Company phone number for footer of message - omitted if empty ('') ">

	<cfargument name="company_url"
			required="false"
			default="#application.cw.companyUrl#"
			type="string"
			hint="Company phone number for footer of message - omitted if empty ('') ">

	<cfset var messageText = ''>
	<cfset var messageContent = ''>
	<cfset var rsPasswordLookup = ''>
	<cfset var linebr = chr(13)>

	<cfif len(trim(arguments.customer_id)) and arguments.customer_id neq 0>

	<!--- QUERY: get customer details --->
	<cfquery name="rsPasswordLookup" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT customer_id, customer_email, customer_username, customer_password
	FROM cw_customers
	WHERE customer_ID = <cfqueryparam value="#arguments.customer_id#" cfsqltype="cf_sql_varchar">
	</cfquery>

<cfsavecontent variable="messageContent">
<cfoutput>

username: #rsPasswordLookup.customer_username##chr(10)#
Password: #rsPasswordLookup.customer_password##linebr#
Log in to your account here:#linebr#
#arguments.login_url##linebr#
---
<cfif len(trim(arguments.company_name))>#arguments.company_name##linebr#</cfif>
<cfif len(trim(arguments.company_email))>#arguments.company_email##linebr#</cfif>
<cfif len(trim(arguments.company_url))>#arguments.company_url##linebr#</cfif>
<cfif len(trim(arguments.company_phone))>#arguments.company_phone##linebr#</cfif>
</cfoutput>
</cfsavecontent>

	</cfif>

	<!--- trim extra whitespace --->
	<cfset messageText = trim(messageContent)>
	<!--- return text --->
	<cfreturn messageText>

</cffunction>

</cfsilent>