<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-func-global.cfm
File Date: 2013-01-08
Description: global Cartweaver functions
==========================================================
--->

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

<cfreturn ArrayToList(Arguments.query_object.getMetadata().getColumnLabels())>

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
	<cfset var QSadd = ''>
	<cfset var persistUrl = ''>
	<cfset var persistQS = ''>
	<cfset var loopCt = 0>
	<cfset var urlVarName = ''>

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
			<cftry>
				<cfset urlVarName = "url.#trim(vv)#">
				<!--- this param keeps from breaking on missing vars --->
				<cfparam name="#urlvarname#" default="" type="string">
				<cfset QSadd = vv & '=' & evaluate(urlvarname)>
				<cfif not loopCt eq 1>
					<cfset QSadd = '&' & QSadd>
				</cfif>
				<cfset persistQS = persistQS & QSadd>
			<cfcatch></cfcatch>
			</cftry>
		<cfset loopCt = loopCt + 1>
		</cfloop>
	<cfset persistUrl = replace(persistUrl & persistQS,'?&','?')>
	</cfif>
<!--- /END if we have vars --->

<cfreturn persistUrl>
</cffunction>

<!--- // ---------- Remove URL Variables from Persisted URL: CWremoveUrlVars()---------- // --->
<!---
EXAMPLE:
<cfset urlString = "cheese=1&crackers=2&apples=3&oranges=4&pizza=5&sandwiches=6">
<cfset skipVars = 'crackers,pizza'>
(variables to remove)
SHOW ON PAGE:
these are the vars:<br>
<cfoutput>#CWremoveUrlVars(skipVars, urlstring)#</cfoutput><br><br>
get another list with the values:<br>
<cfoutput>#CWremoveUrlVars(skipVars,urlstring,'vals')#</cfoutput>
--->
<cffunction name="CWremoveUrlVars" access="public" returntype="string" output="false"
hint="Returns a comma separated list of url variables, removing values, and ignoring specified vars">

	<cfargument name="omit_list" type="string" required="false" default=""
				hint="list of variables to leave out of the list">
	<cfargument name="parse_url" type="string" required="false" default="#cgi.QUERY_STRING#"
				hint="query string to parse variables from">
	<cfargument name="return_content" type="string" required="false" default="vars"
				hint="return the variable names (vars) or the values (vals)">

<cfset var qsVarList = ''>
<cfset var newItem = ''>
<cfset var varName = ''>
<cfset var varVal = ''>

	<cfloop list="#arguments.parse_url#" index="vv" delimiters="&">
		<cfset varName = reReplaceNoCase(listFirst(vv,'='),"[^a-zA-Z0-9-..]","","all")>
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

<!--- // ---------- // Create Navigation Menu from Listed Array of Links and URLs // ---------- // --->
<!---
NOTES:
The first part of each string is a numeric 'group' for nested lists
Any content within the link text in brackets [] is replaced with a <span> tag for css targeting

EXAMPLE:
group no.|url|link text
<cfsavecontent variable="page_list">
1|index.cfm|Home,
2|about.cfm|About Us,
2|about-1.cfm|Subpage 1,
2|about-2.cfm|Subpage 2
</cfsavecontent>
<cfset navMenu = CWcreateNav(urlList=page_list,current_url=request.cw.thisPageQS)>
<cfoutput>#navMenu#</cfoutput>
 --->

<cffunction name="CWcreateNav"
			access="public"
			output="false"
			returntype="string"
			hint="Builds a nested html unordered list from a series of links and related data"
			>

	<cfargument name="page_list"
			required="true"
			type="string"
			hint="the list of urls and text labels: see example">

	<cfargument name="current_url"
			required="false"
			default="#request.cw.thisPageQS#"
			type="any"
			hint="the link to mark as the current link in the menu">

	<cfargument name="nav_id"
			required="false"
			default=""
			type="any"
			hint="the id of the menu markup ul">

	<cfargument name="count_delimiters"
			required="false"
			default="<span>(,)</span>"
			type="any"
			hint="A list consisting of two strings, wrapped around the numeric product count when shown">

	<cfargument name="list_delimiter"
			required="false"
			default=","
			type="any"
			hint="The delimiter separating line items in the raw nav content">

	<cfargument name="show_link_titles"
			required="false"
			default="true"
			type="boolean"
			hint="If false, the navigation links will have no title attribute">

	<cfargument name="nav_class"
			required="false"
			default="CWnav"
			type="any"
			hint="the class of the menu markup ul">

	<cfset var navHTML = ''>
	<cfset var firstChild = 1>
	<cfset var isStarted = 0>
	<cfset var thisLink = ''>
	<cfset var thisLinkGroup = ''>
	<cfset var lastItem = 0>
	<cfset var nextItem = ''>
	<cfset var nextCount = 0>
	<cfset var selectedGroup = ''>
	<cfset var newLinkText = ''>
	<cfset var thisLinkText = ''>
	<cfset var thisTitleText = ''>
	<cfset var thisClass = ''>
	<cfset var qsList = ''>
	<cfset var linkLeader = ''>

<!--- clean trailing delimiter from page list--->
<cfif right(trim(arguments.page_list),1) is trim(arguments.list_delimiter)>
	<cfset arguments.page_list = left(trim(arguments.page_list),len(trim(arguments.page_list))-1)>
</cfif>

<!--- clean trailing ? from provided url --->
<cfif right(trim(arguments.current_url),1) is '?'>
	<cfset arguments.current_url = left(trim(arguments.current_url),len(trim(arguments.current_url))-1)>
</cfif>

<!--- if current url has a query string, remove unwanted vars --->
<cfif arguments.current_url contains '?' and len(listLast(arguments.current_url, '?'))>
<!--- get value of category / secondary from url (remove product from querystring) --->
<cfset qsVars = CWremoveUrlVars('product,addedid','#listLast(arguments.current_url, '?')#')>
<cfset qsVals = CWremoveUrlVars('product,addedid','#listLast(arguments.current_url, '?')#','vals')>
<cfset arguments.current_url = CWserializeUrl(qsVars,listFirst(arguments.current_url,'?'))>
</cfif>

<!--- set up menu html --->
<cfsavecontent variable="navHTML">
<!--- create dynamic 'on' states by looking at the URL of the current page OR current page 'currentNav' variable --->
<cfoutput>
	<cfset linkCount = 1>
	<cfset loopCt = 1>
	<!--- set length of menu for closing final link --->
	<cfset menuLen = listLen(arguments.page_list,"^")>
	<!--- loop the list, find selected group--->
	<cfloop list="#arguments.page_list#" index="pl" delimiters="#arguments.list_delimiter#">
		<cfif listLen(trim(pl),'|') gte 3>
			<!--- get the link --->
			<cfset thisLink=trim(listgetat(pl, 2, '|'))>
			<cfset thisLinkgroup=trim(listFirst(pl, '|'))>
			<cfif (not isDefined('arguments.current_url') and trim(listLast(cgi.SCRIPT_NAME,'/')) is trim(thisLink))
				OR (isDefined('arguments.current_url') and trim(arguments.current_url) is trim(thisLink))>
				<cfset selectedgroup=thisLinkgroup>
			</cfif>
		<cfset loopCt = loopCt + 1>
		</cfif>
	</cfloop>
	<!--- loop the list, create links --->
<ul class="#trim(arguments.nav_class)#"<cfif len(trim(arguments.nav_id))> id="#trim(arguments.nav_id)#"</cfif>>
	<cfloop list="#arguments.page_list#" index="pl" delimiters="#arguments.list_delimiter#">
		<!--- if a valid link --->
		<cfif listLen(trim(pl),'|') gte 3>
			<cfsilent>
			<cfset thisLinkcount=trim(listFirst(pl, '|'))>
			<cfset thisLink=trim(listgetat(pl, 2, '|'))>
			<cfset newLinkText=trim(listLast(pl,'|'))>
			<cfset thisLinkText = replaceList(newLinkText,'[,]','#arguments.count_delimiters#')>
			<cfset thisTitleText = trim(listFirst(newLinkText,'['))>
			<!--- get the counter for the next item --->
			<cfif menuLen gt linkCount>
				<cfset nextItem = listGetAt(arguments.page_list,linkCount+1,'^')>
				<cfset nextCount= trim(listFirst(nextItem, '|'))>
			<cfelse>
				<cfset nextCount = 0>
				<cfset lastItem = 1>
			</cfif>
			<!--- set up the class for each link --->
			<cfif linkCount eq 1>
				<cfset thisClass = "firstLink">
			<cfelse>
				<cfset thisClass="">
			</cfif>
			<cfif (selectedgroup eq thisLinkcount and thisLinkcount neq lastLinkcount)>
				<cfset thisClass = thisClass & ' currentLink'>
			</cfif>

			<!--- if this is the first link of the menu --->
			<cfif isstarted eq 0>
			<cfset linkLeader = '<li>'>
				<cfset isstarted = 1>
			<!--- all other links --->
			<cfelse>
				<!--- if in the same group, create a sublink --->
				<cfif thislinkcount eq lastlinkcount>
					<!--- if the primary sublink --->
					<cfif firstChild eq 1>
						<cfset linkLeader = '<ul><li>'>
						<cfset firstChild=0>
					<!--- if not the first sublink --->
					<cfelse>
						<cfset linkLeader = '</li><li>'>
					</cfif>
					<!--- /end if first sublink --->
				<!--- if not in same group, and not the primary link, close full list --->
				<cfelseif firstChild eq 0>
						<cfset linkLeader = '</li></ul></li><li>'>
					<cfset firstChild = 1>
				<!--- if not in same group, and it is the primary link  --->
				<cfelseif firstChild eq 1>
						<cfset linkLeader = '</li><li>'>
				</cfif>
				<!--- /end if in same group --->
			</cfif>
			<!--- end first link/other links --->

			<!--- set current nav link --->
			<cfif isDefined('arguments.current_url') and NOT thisClass contains 'currentLink'>
				<!--- if link matches currentlink variable , add marker class --->
				<cfif trim(arguments.current_url) is trim(thisLink)>
					<cfset thisClass = thisClass & ' currentLink'>
				</cfif>
			</cfif>
			</cfsilent>
			<!--- create the link --->
			#linkLeader#<a href="#thisLink#"<cfif len(trim(thisClass))> class="#trim(thisClass)#"</cfif><cfif arguments.show_link_titles> title="#thisTitleText#"</cfif>>#thisLinkText#</a>
			<cfset lastlinkcount = thislinkcount>
		</cfif>
		<!--- if last link --->
		<cfif linkCount eq menuLen and firstchild eq 0>
						</li>
					</ul>
		</cfif>
		<!--- #linkCount# --->
		<cfset linkCount = linkCount + 1>
		<!--- /end if valid link --->
</cfloop>
</li>
</ul>
<!-- end list -->
</cfoutput>
</cfsavecontent>

<cfreturn navHTML>

</cffunction>

<!--- // ---------- // Create Horizontal Links from Listed Array of Links and URLs // ---------- // --->
<!---
NOTES:
The first part of each string is a numeric 'group' for nested lists
See CWcreateNav function for example of links formatting
 --->

<cffunction name="CWcreateLinks"
			access="public"
			output="false"
			returntype="string"
			hint="Builds a nested html unordered list from a series of links and related data"
			>

	<cfargument name="page_list"
			required="true"
			type="string"
			hint="the list of urls and text labels: see example">

	<cfargument name="current_category"
			required="false"
			default="0"
			type="any"
			hint="the category to mark as the current link in the menu">

	<cfargument name="current_secondary"
			required="false"
			default="0"
			type="any"
			hint="the secondary category to mark as the current link in the menu">

	<cfargument name="link_delimiter"
			required="false"
			default=" | "
			type="any"
			hint="the character to use between links">

	<cfargument name="count_delimiters"
			required="false"
			default="<span>(,)</span>"
			type="any"
			hint="A list consisting of two strings, wrapped around the numeric product count when shown">

	<cfargument name="list_delimiter"
			required="false"
			default=","
			type="any"
			hint="The delimiter separating line items in the raw nav content">

	<cfargument name="show_link_titles"
			required="false"
			default="true"
			type="boolean"
			hint="If false, the navigation links will have no title attribute">

	<cfset var navHTML = ''>
	<cfset var firstParent = 1>
	<cfset var firstChild = 0>
	<cfset var lastChild = 0>
	<cfset var isStarted = 0>
	<cfset var thisLink = ''>
	<cfset var thisLinkGroup = ''>
	<cfset var selectedGroup = ''>
	<cfset var newLinkText = ''>
	<cfset var thisLinkText = ''>
	<cfset var thisTitleText = ''>
	<cfset var thisClass = ''>

	<cfset var linkCt = 1>
	<cfset var loopCt = 1>
	<cfset var totalLinks = listLen(arguments.page_list,",")>

<!--- set up menu html --->
<cfsavecontent variable="navHTML">
<cfoutput>
	<!--- loop the list, find selected group--->
	<cfloop list="#arguments.page_list#" index="pl" delimiters="#arguments.list_delimiter#">
		<cfif listLen(trim(pl),'|') gte 3>
			<!--- get the link --->
			<cfset thisLink=trim(listgetat(pl, 2, '|'))>
			<cfset thisLinkgroup=trim(listFirst(pl, '|'))>
			<cfif (not isDefined('arguments.current_url') and trim(listLast(cgi.SCRIPT_NAME,'/')) is trim(thisLink))
				OR (isDefined('arguments.current_url') and trim(arguments.current_url) is trim(thisLink))>
				<cfset selectedgroup=thisLinkgroup>
			</cfif>
		<cfset loopCt = loopCt + 1>
		</cfif>
	</cfloop>
<div class="CWlinksNav">
	<!--- loop the list, create links --->
	<div class="CWlinks">
		<cfloop list="#arguments.page_list#" index="pl" delimiters="#arguments.list_delimiter#">
			<cfif listLen(trim(pl),'|') gte 3>
				<cfsilent>
				<cfset thisLinkcount=trim(listFirst(pl, '|'))>
				<cfset thisLink=trim(listgetat(pl, 2, '|'))>
				<cfset newLinkText=trim(listLast(pl,'|'))>
				<cfset thisLinkText = replaceList(newLinkText,'[,]','#arguments.count_delimiters#')>
				<cfset thisTitleText = trim(listFirst(newLinkText,'['))>

				<!--- set up the class for each link --->
				<cfif linkCt eq 1>
					<cfset thisClass = "firstLink">
				<cfelse>
					<cfset thisClass="">
				</cfif>

				<cfif arguments.current_category gt 0
				and thisLink contains 'category=#arguments.current_category#'
				and NOT thisClass contains 'currentLink'
				and NOT thisLink contains 'secondary='>
					<cfset thisClass = thisClass & ' currentLink'>
				<cfelseif arguments.current_secondary gt 0
				and thisLink contains 'secondary=#arguments.current_secondary#'
				and not thisClass contains 'currentLink'>
					<cfset thisClass = thisClass & ' currentLink'>
				<cfelseif arguments.current_category eq 0
				and thisLink contains listLast(request.cwpage.urlResults,'/')
				and NOT thisLink contains 'category='
				and NOT thisLink contains 'secondary='>
					<cfset thisClass = thisClass & ' currentLink'>
				</cfif>


				</cfsilent>

				<cfif isstarted eq 0>
						<cfset isstarted = 1>
					<cfelse>
						<cfif thislinkcount eq lastlinkcount>
							<cfif firstChild eq 1>
									<cfset firstChild=0>
									<cfset firstParent=1>
								</cfif>
						<cfelseif firstParent eq 1 and firstChild eq 0>
							</div><div class="CWlinks">
								<cfif not thisClass contains 'firstlink'>
								<cfset thisClass = thisClass & " firstLink">
								</cfif>
							<!--- prevent false flag of first link --->
							<cfif arguments.current_secondary gt 0>
							<cfset thisClass = replace(thisClass,'currentLink','')>
							</cfif>
							<cfset firstChild = 1>
						</cfif>
				</cfif>

	<cfif thisLinkCount eq lastLinkCount>
	#arguments.link_delimiter#
	</cfif>
	<cfset lastlinkcount = thislinkcount>
	<cfset linkCt = linkCt + 1>
	<a href="#thisLink#" class="CWlink <cfif len(trim(thisClass))> #trim(thisClass)#</cfif>"<cfif arguments.show_link_titles> title="#thisTitleText#"</cfif>>#thisLinkText#</a>
	</cfif>
	</cfloop>
	</div>
</div>
<!-- /end CWlinksNav -->
</cfoutput>
</cfsavecontent>

<cfreturn navHTML>

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

<!--- // ---------- Make a List Random: CWrandomList() ---------- // --->
<!---
EXAMPLE:
<cfset rsProductsSearch = CWrandomList(myList,5)>
--->
<!--- // ---------- //  // ---------- // --->
<cffunction name="CWlistRandom"
			access="public"
			output="false"
			returntype="string"
			hint="randomly shuffles a list and returns a select number of unique results"
			>

	<cfargument name="list_string"
			required="true"
			default=""
			type="string"
			hint="the list to shuffle">
	<cfargument name="max_items"
			required="false"
			default="0"
			type="numeric"
			hint="number of items to return - if 0, all results are returned">

<cfset var returnCt = 0>
<cfset var listStr = 0>
<cfset var returnList = ''>
<cfset var loopCt = 0>
<cfset var ii = ''>
<!--- determine number of results to return --->
<cfif arguments.max_items eq 0>
	<cfset returnCt = listLen(list_string)>
<cfelse>
	<cfset returnCt = arguments.max_items>
</cfif>

<!--- shorten list var --->
<cfset listStr = trim(arguments.list_string)>
	<!--- scope the loop index --->
	<cfloop list="#listStr#" index="ii">
		<!--- determine number of items to return --->
		<cfif loopCt lt returnCt>
			<!--- get an item at random from the old list --->
			<cfset listIndex = randRange(1,listLen(listStr))>
			<cfset listItem = listGetAt(listStr,listIndex)>
			<!--- add the item to the new list --->
			<cfset returnList = listAppend(returnList,listItem)>
			<!--- delete the item from the old list --->
			<cfset listStr = listDeleteAt(listStr,listIndex)>
		</cfif>
		<cfset loopCt = loopCt + 1>
	</cfloop>

<cfreturn returnList>

</cffunction>

<!--- // ---------- Clean Numeric Query Values: CWsqlNumber() ---------- // --->
<!---
Remove commas from numbers for MySQL
--->
<cffunction name="CWsqlNumber" returntype="numeric">
	<cfargument name="clean_number" type="string">

	<cfset var safeNumber = Replace(clean_number, ",",".","all")>

	<cfif safenumber gt 0>
	<cfreturn safeNumber>
	<cfelse>
	<cfreturn 0>
	</cfif>

</cffunction>

<!--- // ---------- Escape HTML characters: CWsafeHTML() ---------- // --->
<!---
DESCRIPTION: converts some html to htmlentities, prevent cross-site scripting (xss)
--->
<cffunction name="CWsafeHTML" output="false" returntype="string">
	<cfargument name="clean_string" type="string" hint="string to convert">

	<cfset var cleanString = Replace(arguments.clean_string,"<","&lt;","all")>
		<cfset cleanString = Replace(cleanString,">","&gt;","all")>
		<cfset cleanString = Replace(cleanString,'"',"&quot;","all")>
		<cfset cleanString = Replace(cleanString,chr(10),"<br>","all")>
		<cfset cleanString = Replace(cleanString,"@@","","all")>
		<cfset cleanString = Replace(cleanString,";","","all")>

	<cfreturn cleanString>
</cffunction>

<!--- // ---------- Remove Escaped HTML characters, used for search based on url string: CWremoveEncoded() ---------- // --->
<cffunction name="CWremoveEncoded" output="false" returntype="string">
	<cfargument name="clean_string" type="string" hint="string to convert">

	<cfset var cleanString = Replace(arguments.clean_string,"&lt","","all")>
		<cfset cleanString = Replace(cleanString,"&gt","","all")>
		<cfset cleanString = Replace(cleanString,"&quot","","all")>
		<cfset cleanString = Replace(cleanString,"<br>","","all")>
		<cfset cleanString = Replace(cleanString,";","","all")>
		<!--- remove multiple whitespaces --->
		<cfset cleanString = Replace(cleanString,"   "," ","all")>
		<cfset cleanString = Replace(cleanString,"  "," ","all")>

	<cfreturn trim(cleanString)>
</cffunction>

<!--- // ---------- Remove HTML characters: CWcleanString() ---------- // --->
<!---
DESCRIPTION: completely removes unwanted characters from html strings
--->
<cffunction name="CWcleanString" output="false" returntype="string">
	<cfargument name="clean_string" type="string" hint="string to convert" required="true">
	<cfargument name="replace_char" type="string" hint="character to use as replacement" default="" required="false">

	<cfset var cleanString = Replace(arguments.clean_string,"<",arguments.replace_char,"all")>
		<cfset cleanString = Replace(cleanString,">",arguments.replace_char,"all")>
		<cfset cleanString = Replace(cleanString,'"',arguments.replace_char,"all")>
		<cfset cleanString = Replace(cleanString, chr(10),arguments.replace_char,"all")>
		<cfset cleanString = Replace(cleanString, "@@",arguments.replace_char,"all")>
		<cfset cleanString = Replace(cleanString, ";",arguments.replace_char,"all")>

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
	<cfset returnStr = arrayToList(arguments.convert_val,'<br>')>
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

		<cfset var alertArray = ''>
		<cfset  var cleanString = CWsafeHTML(arguments.message_string)>

		<!--- if alert type --->
		<cfif arguments.message_type is 'alert'>
			<cfif isDefined('request.cwpage.userAlert') and isArray(request.cwpage.userAlert)>
			<cfset alertArray = request.cwpage.userAlert>
			<cfelse>
			<cfset alertArray = arrayNew(1)>
			</cfif>
		<cfset arrayAppend(alertArray,trim(cleanstring))>
		<cfset request.cwpage.userAlert = alertArray>
		<!--- if confirm type --->
		<cfelseif arguments.message_type is 'confirm'>
			<cfif isDefined('request.cwpage.userConfirm') and isArray(request.cwpage.userConfirm)>
			<cfset alertArray = request.cwpage.userConfirm>
			<cfelse>
			<cfset alertArray = arrayNew(1)>
			</cfif>
		<cfset arrayAppend(alertArray,trim(cleanstring))>

		<cfset request.cwpage.userConfirm = alertArray>
		</cfif>

</cffunction>

<!--- // ---------- // CWtime : calculate any time  value with global offset // ---------- // --->
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

	<cfset newTime = dateAdd('h',arguments.offset_val,arguments.time_str)>
	<cfreturn newTime>
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

</cfsilent>