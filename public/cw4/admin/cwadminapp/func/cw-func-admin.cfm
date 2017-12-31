<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-func-admin.cfm
File Date: 2012-06-05
Description: Global functions for CW admin
==========================================================
--->

<!--- // ---------- Restrict Access to Admin Pages: CWauth() ---------- // --->
<!---
EXAMPLE:
<cfset request.cwpage.access = CWauth("merchant,developer")>
--->
<cffunction name="CWauth" access="public" returntype="string" output="false"
hint="Redirects user if access level does not match, or returns user's level">

	<cfargument name="allowed_levels" type="string" required="true"
				hint="The list of access levels to allow - pass in 'any' to allow all">
	<cfargument name="redirect_url" type="string" required="false" default="index.cfm"
				hint="The URL to redirect to">

<cfset var userlevel = ''>
<!--- check if user is logged in, access level defined, and permitted --->
<cfif isDefined('session.cw.accessLevel')
		AND isDefined('session.cw.loggedIn')
		AND (
			arguments.allowed_levels contains 'any'
				OR
			listFindNoCase(arguments.allowed_levels,trim(session.cw.accessLevel))
			)
		>
<cfset userLevel = session.cw.accessLevel>
<!--- if not ok, redirect --->
<cfelse>
	<cflocation url="#trim(arguments.redirect_url)#" addtoken="false">
</cfif>

<cfreturn userLevel>
</cffunction>

<!--- // ---------- List Columns in a Query: CWlistQueryColumns() ---------- // --->
<!---
EXAMPLE:
<cfset queryName = 'myQuery'>
<cfoutput>#CWlistQueryColumns(myQuery)#</cfoutput>">
--->
<cffunction name="CWlistQueryColumns" access="public" returntype="string" output="false"
hint="Returns a comma-delimited list of columns in a query in correct order and case">

	<cfargument name="query_object" type="query" required="true"
				hint="A query to fetch column names from">

	<cfset var returnList = ''>

				<!--- railo handles this function differently --->
				<cfswitch expression="#server.coldfusion.productName#">
					<cfcase value="railo">
						<cfset returnList = arguments.query_object.getColumnlist(false)>
					</cfcase>
					<cfdefaultcase>
						<cfset returnlist = ArrayToList(Arguments.query_object.getMetadata().getColumnLabels())>
					</cfdefaultcase>
				</cfswitch>

	<cfreturn returnList>

</cffunction>

<!--- // ---------- Serialize URL Variables: CWserializeUrl() ---------- // --->
<!---
EXAMPLE:
<cfset varsToKeep = "searchby,matchtype,find,maxrows,sortby,sortdir">
<cfset pageUrl = "#cgi.script_Name#">
<cfset theLink = CWserializeUrl(varsToKeep,pageUrl)>
<cfoutput>#theLink#</cfoutput>
--->
<cffunction name="CWserializeUrl" access="public" returntype="string" output="false"
hint="Returns a serialized string of url variables, with specific values persisted">

	<cfargument name="var_list" type="string" required="true"
				hint="list of variables to persist (others are dropped)">

	<cfargument name="base_url" type="string" required="false" default=""
				hint="A base url w/ no query string">

	<cfset var varCt = len(trim(arguments.var_list))>

	<!--- set the base for our url --->
	<cfif len(trim(arguments.base_url))>
	<cfset persistUrl = trim(arguments.base_url) & '?'>
	<cfelse>
	<cfset persistUrl = ''>
	</cfif>
	<!--- if we have some vars to work with --->
	<cfif varCt>
	<cfset persistQS = ''>
	<cfset loopCt = 1>
		<!--- loop the list --->
		<cfloop list="#arguments.var_list#" index="vv">
		<cfset urlVarName = "url.#trim(vv)#">
		<!--- this param keeps from breaking on missing vars --->
		<cfparam name="#urlvarname#" default="" type="string">
		<cfset QSadd = vv & '=' & evaluate(urlvarname)>
		<cfif not loopCt eq 1>
		<cfset QSadd = '&' & QSadd>
		</cfif>
		<cfset persistQS = persistQS & QSadd>
		<cfset loopCt = loopCt + 1>
		</cfloop>
	<cfset persistUrl = persistUrl & persistQS>
	</cfif>
<!--- /END if we have vars --->

<cfreturn persistUrl>
</cffunction>

<!--- // ---------- Remove URL Variables from Persisted URL: CWremoveUrlVars()---------- // --->
<!---
EXAMPLE:
<cfset urlString = "mypage.cfm?cheese=1&crackers=2&apples=3&oranges=4&pizza=5&sandwiches=6">
(url default is current page, can also be just a query string)
<cfset skipVars = 'crackers,pizza'>
(variables to remove)
SHOW ON PAGE:
these are the vars:<br>
<cfoutput>#CWremoveUrlVars(skipVars)#</cfoutput><br><br>
get another list with the values:<br>
<cfoutput>#CWremoveUrlVars(skipVars,'#urlstring#','vals')#</cfoutput>
--->
<cffunction name="CWremoveUrlVars" access="public" returntype="string" output="false"
hint="Returns a comma separated list of url variables, removing values, and ignoring specified vars">

	<cfargument name="omit_list" type="string" required="false" default=""
				hint="list of variables to leave out of the list">
	<cfargument name="parse_url" type="string" required="false" default="#cgi.QUERY_STRING#"
				hint="url to parse variables from, can be a full url or just a query string (anything before '?' is removed)">
	<cfargument name="return_content" type="string" required="false" default="vars"
				hint="return the variable names (vars) or the values (vals)">

<cfset var qsVarList = ''>
<cfset var varname = ''>
<cfset var varval = ''>
<cfset var newitem = ''>

	<cfloop list="#listLast(arguments.parse_url,'?')#" index="vv" delimiters="&">
		<cfset varName = listFirst(vv,'=')>
		<cfset varVal = listLast(vv,'=')>
		<!--- if not an omitted value --->
		<cfif not listFindNoCase(omit_list,varname)>
		<!--- if showing values --->
				<cfif arguments.return_content eq 'vals'>
					<cfset newItem = varVal>
				<cfelse>
		<!--- otherwise, default = show vars as a list --->
					<cfset newItem = varName>
				</cfif>
		<!--- avoid duplicates --->
			<cfif not listFindNoCase(qsVarList,newItem)>
			<cfset qsVarList = listAppend(qsVarlist,newItem)>
			</cfif>
		</cfif>
	</cfloop>

<cfreturn QSvarList>
</cffunction>

<!--- // ---------- Make a Query Sortable: CWsortableQuery() ---------- // --->
<!---
EXAMPLE:
<cfset rsProductsSearch = CWsortableQuery(rsProductsSearch) >
--->
<cffunction name="CWsortableQuery" access="public" returntype="query" output="false"
hint="Adds dynamic Order By and Direction to any query">

	<cfargument name="sort_query" required="true"
				hint="a query to be sorted">

	<cfargument name="sort_dir" required="false" default="asc"
				hint="the direction to sort asc/desc, overridden by url">

	<!--- use CWlistQueryColumns function to get the correct column list, with case and order --->
	<cfset var queryCols = "#CWlistQueryColumns(arguments.sort_query)#">
	<cfset var colList = ''>

	<!--- aggregate functions ( i.e. MAX() ) don't work here --->
	<cfif queryCols contains 'MAX('>
	<cfloop list="#queryCols#" index="cc">
	<cfif not cc contains 'MAX('>
	<cfset colList = listAppend(colList,trim(cc))>
	</cfif>
	</cfloop>
	<cfset queryCols = colList>
	</cfif>
	<!--- default is sort by the first column ascending, if not given in page or url --->
	<cfparam name="url.sortby" default="listFirst(queryCols)" type="string">
	<!--- determine order to be used --->
	<cfparam name="url.sortdir" default="#arguments.sort_dir#" type="string">

	<!--- note: in event of error, default query passed through unsorted --->
	<cfparam name="sortedQuery" default="#arguments.sort_query#">
			<!--- block hack attempts --->
			<cfif listFindNoCase(queryCols,url.sortby)>
				<cfquery dbtype="query" name="sortedQuery">
				SELECT #queryCols#,
				lower(#trim(url.sortby)#)
				as sortcol
				FROM arguments.sort_query
				ORDER BY sortcol <cfif url.sortdir eq 'asc' OR url.sortdir eq 'desc'>#url.sortdir#</cfif>
				</cfquery>
			<cfelse>
				<cfquery dbtype="query" name="sortedQuery">
				SELECT *
				FROM arguments.sort_query
				</cfquery>
			</cfif>

<cfreturn sortedQuery>
</cffunction>

<!--- // ---------- Create Form Inputs: CWformField() ---------- // --->
<cffunction name="CWformField" access="public" returntype="string" output="false"
			hint="Generates a dynamic form input">

	<!--- type and name are required --->
	<cfargument name="field_type" type="string" required="true"
				hint="Type of input element - boolean/text/number/radio/checkbox/textarea/texteditor/select/multiselect">
	<cfargument name="field_name" type="string" required="true"
				hint="Name of input element">
	<!--- others are optional --->
	<cfargument name="field_id" type="string" required="false" default="#arguments.field_name#"
				hint="ID for input element">
	<cfargument name="field_label" type="string" required="false" default=""
				hint="Label for input element - used for validation titles">
	<cfargument name="field_value" type="string" required="false" default=""
				hint="Displayed value of input element">
	<cfargument name="field_options" type="string" required="false" default=""
				hint="Selections for radio, checkbox or select elements">
	<cfargument name="field_class" type="string" required="false" default=""
				hint="The css class for this element">
	<cfargument name="field_size" type="numeric" required="false" default="35"
				hint="Size for text elements, columns for textareas">
	<cfargument name="field_rows" type="numeric" required="false" default="5"
				hint="Number of rows for textareas, number of visible items for multiselect">

	<cfset var formField = ''>

	<cfset var formFieldTitle = arguments.field_label>
	<!--- email fields --->
	<cfif arguments.field_class contains 'email'>
	<cfset formFieldTitle = formFieldTitle & ' must be a valid email address'>
	<!--- required fields --->
	<cfelseif arguments.field_class contains 'required'>
	<cfset formFieldTitle = formFieldTitle & ' is required'>
	</cfif>

	<cfsavecontent variable="formField">
	<cfoutput>
		<cfswitch expression="#arguments.field_type#">
			<!--- single checkbox yes/no --->
			<cfcase value="boolean">
				<input name="#arguments.field_name#" id="#arguments.field_id#" type="checkbox" class="#arguments.field_class# formCheckbox" value="true"<cfif arguments.field_value eq true> checked="checked"</cfif> title="#formFieldTitle#">
			</cfcase>
			<!--- radio --->
			<cfcase value="radio">
				<cfloop list="#arguments.field_options#" index="NameValuePair" delimiters="#chr(13)##chr(10)#">
					<!--- remove commas from values --->
					<cfset nameValuePair = replace(nameValuePair,',','','all')>
					<div class="checkboxWrap">
					<input name="#arguments.field_name#" id="#arguments.field_id#-#arguments.field_value#" type="radio" class="#arguments.field_class# formRadio" value="#listLast(NameValuePair, "|")#"<cfif ListFind(field_value, ListLast(NameValuePair, "|"))> checked="checked"</cfif> title="#formFieldTitle#">
					#ListFirst(NameValuePair, "|")#
					</div>
				</cfloop>
			</cfcase>
			<!--- checkbox array --->
			<cfcase value="checkboxgroup">
				<cfloop list="#arguments.field_options#" index="NameValuePair" delimiters="#Chr(13)##Chr(10)#">
					<!--- remove commas from values --->
					<cfset nameValuePair = replace(nameValuePair,',','','all')>
					<div class="checkboxWrap">
					<input name="#arguments.field_name#" id="#arguments.field_id#-#arguments.field_value#" type="checkbox" class="#arguments.field_class# formCheckbox" value="#ListLast(NameValuePair, "|")#"<cfif ListFind(field_value, ListLast(NameValuePair, "|"))> checked="checked"</cfif> title="#formFieldTitle#">
					#ListFirst(NameValuePair, "|")#
					</div>
				</cfloop>
			</cfcase>
			<!--- textarea --->
			<cfcase value="textarea">
				<textarea name="#arguments.field_name#" id="#arguments.field_id#" class="#arguments.field_class#" cols="#arguments.field_size#" rows="#arguments.field_rows#" title="#formFieldTitle#">#field_value#</textarea>
			</cfcase>
			<!--- texteditor rich text area --->
			<cfcase value="texteditor">
				<textarea name="#arguments.field_name#" cols="#arguments.field_size#" rows="#arguments.field_rows#" id="#arguments.field_id#" class="#arguments.field_class# textEdit" title="#formFieldTitle#">#field_value#</textarea>
			</cfcase>
			<!--- select --->
			<cfcase value="select,multiselect">
				<select name="#arguments.field_name#"  id="#arguments.field_id#"<cfif arguments.field_type is "multiselect"> multiple="multiple" size="#arguments.field_rows#"</cfif> class="#arguments.field_class#" title="#formFieldTitle#">
					<cfloop list="#arguments.field_options#" index="NameValuePair" delimiters="#Chr(13)##Chr(10)#">
					<!--- remove commas from values --->
					<cfset nameValuePair = replace(nameValuePair,',','','all')>
						<option value="#ListLast(NameValuePair, "|")#"<cfif ListFind(field_value, ListLast(NameValuePair, "|"))> selected="selected"</cfif>>#ListFirst(NameValuePair,"|")#</option>
					</cfloop>
				</select>
			</cfcase>
			<!--- numeric input --->
			<cfcase value="number">
				<input type="text" id="#arguments.field_id#" name="#arguments.field_name#" class="#arguments.field_class#" value="#arguments.field_value#" size="#arguments.field_size#" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);" title="#formFieldTitle#">
			</cfcase>
			<!--- text input (default) --->
			<cfdefaultcase>
				<input type="text" id="#arguments.field_id#" name="#arguments.field_name#" class="#arguments.field_class#" value="#htmlEditFormat(arguments.field_value)#" size="#arguments.field_size#" title="#formFieldTitle#">
			</cfdefaultcase>
		</cfswitch>
	</cfoutput>
	</cfsavecontent>

<cfreturn formField>
	</cffunction>

<!--- // ---------- Get Product Image Path: CWgetImage() ---------- // --->
<!---
DESCRIPTION: This function returns an image path based on product id and
	image type
ARGUMENTS
productID: Integer product id from the database.
ImageID: Type of image required (integer key representing large, thumbnail, etc).
RETURNS
A string with the image location.
--->
<cffunction name="CWgetImage">
	<cfargument name="product_id" required="true">
	<cfargument name="image_id" required="true">
	<cfargument name="image_scaleto" required="false" default="0" hint="images are resized to this dimension">

	<cfset var rs = "">

	<!--- Query the database and return a url to an image, if it exists --->
	<cfquery name="rs" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
	SELECT cw_product_images.product_image_filename, cw_image_types.imagetype_folder
	FROM cw_image_types
	INNER JOIN cw_product_images
	ON cw_image_types.imagetype_id = cw_product_images.product_image_imagetype_id
	WHERE cw_product_images.product_image_product_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.product_id#">
	AND cw_product_images.product_image_imagetype_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.image_id#">
	</cfquery>

	<cfif rs.RecordCount neq 0>
		<!--- Process the image --->
		<cfset imageSRC = rs.imagetype_folder & '/' & rs.product_image_filename>
		<cfset imagePath = "">
		<cfset localPath = expandPath('#request.cwpage.adminImgPrefix##application.cw.appImagesDir#/')>
		<cfif FileExists(localPath & imageSRC)>
			<cfif arguments.image_scaleto gt 0>
			<cftry>
			<cfimage action="info" source="#localPath##imageSrc#" structName="imgInfo">
			<cfimage action="read" name="srcImage" source="#localPath##imageSrc#">
			<cfif imgInfo.height gt arguments.image_scaleto OR imgInfo.width gt arguments.image_scaleto>
			<cfset imageSetAntialiasing(srcImage, "on")>
			<cfset imageScaleToFit(srcImage, #arguments.image_scaleto#, #arguments.image_scaleto#, "highestQuality")>
			<cfimage action="write" overwrite="true" destination="#localPath##imageSrc#" source="#srcImage#">
			</cfif>
			<cfcatch></cfcatch>
			</cftry>
			</cfif>

		<cfreturn imagePath & imageSRC>
		<cfelse>
		<cfreturn "">
		</cfif>
	<cfelse>
		<!--- There's no related image, return an empty string --->
		<cfreturn "">
	</cfif>

</cffunction>

<!--- // ---------- Show Image: CWdisplayImage() ---------- // --->
<!---
DESCRIPTION: This function returns an image complete with image tag
	with alt attribute based on product id and image type
ARGUMENTS
productID: Integer product id from the database.
ImageID: Type of image required (integer key representing large, thumbnail, etc).
altText: Alternate text for the image, or blank if none.
noImageText: Text to display if image doesn't exist, if any.
class: optional css class.
noImageText: optional element id.
RETURNS
A string with the image location.
--->
<cffunction name="CWdisplayImage">
	<cfargument name="product_id">
	<cfargument name="image_id">
	<cfargument name="alt_text" default="">
	<cfargument name="noimage_text" default="">
	<cfargument name="class" default="">
	<cfargument name="id" default="">
	<cfargument name="image_scaleto" required="false" default="0" hint="images are resized to this dimension">

	<cfset var displayImage = "">
	<cfset var imageSRC = CWgetImage(arguments.product_id, arguments.image_id, arguments.image_scaleto)>
	<cfset var altText = ''>

	<cfif arguments.class neq "">
		<cfset arguments.class = ' class="#arguments.class#"'>
	</cfif>
	<cfif arguments.id neq "">
		<cfset arguments.id = ' id="#arguments.id#"'>
	</cfif>
	<cfset arguments.alt_text = Replace(arguments.alt_text, '"','&quot;','all')>

	<cfif ImageSRC neq "">
		<cfset DisplayImage = '<img src="#imagesrc#" alt="#arguments.alt_text#"#arguments.class##arguments.id#>'>
	<cfelse>
		<cfset DisplayImage = arguments.noimage_text>
	</cfif>

	<cfreturn DisplayImage>
</cffunction>

<!--- // ---------- Clean Numeric Query Values: CWsqlNumber() ---------- // --->
<!---
Remove commas from numbers for MySQL
--->
<cffunction name="CWsqlNumber" returntype="numeric">
	<cfargument name="clean_number" type="string">

	<cfset var safeNumber = Replace(arguments.clean_number, ",",".","all")>

	<cfif safenumber gt 0>
	<cfreturn safeNumber>
	<cfelse>
	<cfreturn 0>
	</cfif>

</cffunction>

<!--- // ---------- Escape HTML characters: CWsafeHTML() ---------- // --->
<!---
DESCRIPTION: converts some html to htmlentities
--->
<cffunction name="CWsafeHTML" output="false" returntype="string">
	<cfargument name="convert_string" type="string" hint="string to convert">

	<cfset var cleanString = Replace(arguments.convert_string,"<","&lt;","all")>
	<cfset cleanString = Replace(cleanString,">","&gt;","all")>
	<cfset cleanString = Replace(cleanString,'"',"&quot;","all")>
	<cfset cleanString = Replace(cleanString, chr(10),"<br>","all")>

	<cfreturn cleanString>
</cffunction>

<!--- // ---------- Clean up characters for javascript: CWstringFormat() ---------- // --->
<!---
 Replace characters for Javascript, similar to jsStringFormat
 only without the problem of double quotes
 --->
<cffunction name="CWstringFormat" output="false" returntype="string">
	<cfargument name="clean_string" type="string" hint="string to convert">

	<cfset var cleanString = arguments.clean_string>
	<cfset cleanString = CWsafeHTML(cleanString)>
	<cfset cleanString = Replace(cleanString,"'","\'","all")>

	<cfreturn cleanString>
</cffunction>

<!--- // ---------- Clean up characters for URL: CWurlSafe()---------- // --->
<cffunction name="CWurlSafe"
			access="public"
			output="false"
			returntype="string"
			hint="Turns array or string into url safe string"
			>

<cfargument name="convert_val"
		required="true"
		default=""
		type="any"
		hint="String or array to convert">

<cfset var returnStr = ''>
<cfset var returnStrClean = ''>

	<cfif isArray(arguments.convert_val) and arrayLen(arguments.convert_val)>
		<cfset returnStr = arrayToList(arguments.convert_val)>
	<cfelse>
		<cfset returnStr = trim(arguments.convert_val)>
	</cfif>

	<cfset returnStrClean = urlEncodedFormat(returnStr)>

<cfreturn returnStrClean>

</cffunction>

<!--- // ---------- Messages and Alerts: CWpageMessage() ---------- // --->
<cffunction name="CWpageMessage"
			access="public"
			output="false"
			returntype="void"
			hint="Manages request.cwpage.userAlert and request.cwpage.userConfirm admin messages"
			>

	<cfargument name="message_type"
			required="true"
			default="alert"
			type="string"
			hint="alert or confirm">

	<cfargument name="message_string"
			required="true"
			default=""
			type="string"
			hint="the message">

			<cfset var alertArray = arrayNew(1)>

		<!--- if alert type --->
		<cfif arguments.message_type is 'alert'>
			<cfif isDefined('request.cwpage.userAlert') and isArray(request.cwpage.userAlert)>
			<cfset alertArray = request.cwpage.userAlert>
			<cfelse>
			<cfset alertArray = arrayNew(1)>
			</cfif>
		<cfset arrayAppend(alertArray,trim(arguments.message_string))>
		<cfset request.cwpage.userAlert = alertArray>
		<!--- if confirm type --->
		<cfelseif arguments.message_type is 'confirm'>
			<cfif isDefined('request.cwpage.userConfirm') and isArray(request.cwpage.userConfirm)>
			<cfset alertArray = request.cwpage.userConfirm>
			<cfelse>
			<cfset alertArray = arrayNew(1)>
			</cfif>
		<cfset arrayAppend(alertArray,trim(arguments.message_string))>

		<cfset request.cwpage.userConfirm = alertArray>
		</cfif>

</cffunction>

<!--- // ---------- // Time Offset: CWtime() // ---------- // --->
<cffunction name="CWtime"
			access="public"
			output="false"
			returntype="string"
			hint="Returns a time value altered by global time offset value"
			>

<cfargument name="time_str"
		required="false"
		default="#now()#"
		type="string"
		hint="Time value to alter">

<cfargument name="offset_val"
		required="false"
		default="#application.cw.globalTimeOffset#"
		type="numeric"
		hint="The amount to offset the global time, in hours (decimals/signed allowed)">

<cfset var newTime = ''>
<cfset newTime = dateAdd('h',arguments.offset_val,arguments.time_str)>

<cfreturn newTime>
</cffunction>

<!--- // ---------- // Get date mask for any locale: CWlocaleDateMask() // ---------- // --->
<cffunction name="CWlocaleDateMask"
			access="public"
			output="false"
			returntype="string"
			hint="Returns a datemask for the specified locale"
			>

	<cfargument name="locale"
			required="false"
			default="#getLocale()#"
			type="any"
			hint="the locale to look up, defaults to global locale setting">

	<cfset var locales = ''>
	<cfset var masks = ''>
	<cfset var returnMask = ''>
	<cfset var defaultMask = 'yyyy-mm-dd'>

	<cfsavecontent variable="locales">
    Dutch (Belgian),Dutch (Standard),English (Australian),English (Canadian),English (New Zealand),English (UK),English (US),French (Belgian),French (Canadian),French (Standard),French (Swiss),German (Austrian),German (Standard),German (Swiss),Italian (Standard),Italian (Swiss),Norwegian (Bokmal),Norwegian (Nynorsk),Portuguese (Brazilian),Portuguese (Standard),Spanish (Mexican),Spanish (Modern),Spanish (Standard),Swedish
	</cfsavecontent>
	<cfsavecontent variable="masks">
	d/mm/yyyy,d-m-yyyy,d/mm/yyyy,dd/mm/yyyy,d/mm/yyyy,dd/mm/yyyy,m/d/yyyy,d/mm/yyyy,yyyy-mm-dd,dd/mm/yyyy,dd.mm.yyyy,dd.mm.yyyy,dd.mm.yyyy,dd.mm.yyyy,dd/mm/yyyy,dd.mm.yyyy,dd.mm.yyyy,dd.mm.yyyy,d/m/yyyy,dd-mm-yyyy,dd/mm/yyyy,dd/mm/yyyy,dd/mm/yyyy,yyyy-mm-dd
	</cfsavecontent>

	<cfif len(trim(arguments.locale))>
		<cfset maskPos = listFindNoCase(locales,trim(arguments.locale))>
		<cfif maskPos gt 0>
			<cfset returnMask = listGetAt(trim(masks),maskPos)>
		<cfelse>
			<cfset returnMask = defaultMask>
		</cfif>
	</cfif>

	<cfreturn returnMask>

</cffunction>

<!--- // ---------- // Set installation timestamp on first page request: CWsetInstallationDate()// ---------- // --->
<cffunction name="CWsetInstallationDate"
			access="public"
			output="false"
			returntype="void"
			hint="Sets a timestamp for first admin login, if not already set."
			>

<cfset var setDate = ''>

<cfquery name="setDate" datasource="#application.cw.dsn#" username="#application.cw.dsnUsername#" password="#application.cw.dsnPassword#">
UPDATE cw_config_items
SET config_value = #CWtime()#
WHERE config_variable = 'appInstallationDate'
AND (config_value = ''
	OR config_value = NULL)
</cfquery>

</cffunction>

<!--- // ---------- // CWtrailingChar : add or remove a trailing '/' or other character from any string, without duplicates // ---------- // --->
<cffunction name="CWtrailingChar"
			access="public"
			output="false"
			returntype="string"
			hint="add or remove a trailing character(s) from any string, avoiding duplicates"
			>

<cfargument name="textString"
		required="true"
		type="string"
		hint="the string to start with">

<cfargument name="action"
		required="false"
		default="add"
		type="string"
		hint="add|remove">

<cfargument name="char"
		required="false"
		default="/"
		type="string"
		hint="The character(s) to add or remove">

<cfargument name="process_empty"
		required="false"
		default="false"
		type="boolean"
		hint="if false, no action is performed when the textString is null or empty">

<cfset var returnStr = trim(arguments.textString)>
<cfset var charStr = trim(arguments.char)>
<cfset var strLen = len(charStr)>

<cfif len(returnStr) OR arguments.process_empty>
	<!--- add the char(s) if the string does not already end with it --->
	<cfif arguments.action is 'add' and right(returnStr,strLen) is not charStr>
		<cfset returnStr = returnStr & charStr>
	<!--- remove the chars, if the string ends with it --->
	<cfelseif arguments.action is 'remove' and right(returnStr,strLen) is charStr>
		<cfset returnStr = left(returnStr, len(returnStr)-strLen)>
	</cfif>
</cfif>

<cfreturn returnStr>

</cffunction>

<!--- // ---------- // CWleadingChar : add or remove a leading '/' or other character from any string, without duplicates // ---------- // --->
<cffunction name="CWleadingChar"
			access="public"
			output="false"
			returntype="string"
			hint="add or remove a leading character(s) from any string, avoiding duplicates"
			>

<cfargument name="textString"
		required="true"
		type="string"
		hint="the string to start with">

<cfargument name="action"
		required="false"
		default="add"
		type="string"
		hint="add|remove">

<cfargument name="char"
		required="false"
		default="/"
		type="string"
		hint="The character(s) to add or remove">

<cfargument name="process_empty"
		required="false"
		default="false"
		type="boolean"
		hint="if false, no action is performed when the textString is null or empty">

<cfset var returnStr = trim(arguments.textString)>
<cfset var charStr = trim(arguments.char)>
<cfset var strLen = len(charStr)>

<cfif len(returnStr) OR arguments.process_empty>
	<!--- add the char(s) if the string does not already end with it --->
	<cfif arguments.action is 'add' and left(returnStr,strLen) is not charStr>
		<cfset returnStr = charStr & returnStr>
	<!--- remove the chars, if the string ends with it --->
	<cfelseif arguments.action is 'remove' and left(returnStr,strLen) is charStr>
		<cfset returnStr = right(returnStr, len(returnStr)-strLen)>
	</cfif>
</cfif>

<cfreturn returnStr>

</cffunction>