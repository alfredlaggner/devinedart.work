<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-mod-productpaging.cfm
File Date: 2012-11-29
Description: shows number of products found and pagination links for product listings
==========================================================
--->

<!--- clean up form and url variables --->
<cfinclude template="../inc/cw-inc-sanitize.cfm">
<cfparam name="request.cwpage.resultsMaxRows" default="#application.cw.appDisplayPerPage#">
<cfparam name="attributes.paging_var" default="page">
<cfparam name="url.#attributes.paging_var#" default="1">
<cfparam name="attributes.current_page" default="#URL[attributes.paging_var]#">
<cfparam name="attributes.base_url" default="#cgi.script_name#">
<cfparam name="attributes.show_all" default="false">
<cfparam name="attributes.results_per_page" default="#request.cwpage.resultsMaxRows#">
<cfparam name="attributes.total_records" default="0">
<cfparam name="attributes.show_page_numbers" default="true">
<cfparam name="attributes.max_links" default="#application.cw.appDisplayPageLinksMax#">
<!--- leave these blank to omit --->
<cfparam name="attributes.all_link_text" default="(Show All)">
<cfparam name="attributes.all_page_text" default="(Show #attributes.results_per_page# per page)">
<cfparam name="attributes.prev_link_text" default="&laquo;&nbsp;Previous">
<cfparam name="attributes.next_link_text" default="Next&nbsp;&raquo;">
<cfparam name="attributes.link_delimiter" default=" | ">
<cfparam name="attributes.before_current_page" default="<strong>">
<cfparam name="attributes.after_current_page" default="</strong>">
<!--- show all can be turned off with global setting --->
<cfif isDefined('application.cw.productShowAll') and application.cw.productShowAll is false>
	<cfset attributes.all_link_text = ''>
</cfif>
<cfif not attributes.base_url contains '?'>
	<cfset attributes.base_url = attributes.base_url & '?'>
<cfelseif attributes.base_url contains "=" and not right(attributes.base_url,1) is '&'>
	<cfset attributes.base_url = attributes.base_url & '&'>
</cfif>
<!--- total pages available --->
<cfset totalPages = ceiling(attributes.total_records/attributes.results_per_page)>
</cfsilent>
<div class="CWproductPaging">
<!--- number of products --->
 <p class="CWsearchCount">[ <cfoutput><strong>#attributes.total_records#</strong></cfoutput> ] Item<cfif attributes.total_records neq 1>s<cfelse>&nbsp;</cfif></p>
<!--- paging links: only show if more than 1 page of products being shown --->
	<cfif totalPages gt 1 OR attributes.show_all>
		<p class="CWpagingLinks">
		<!--- if not showing all, show links --->
		<cfif not attributes.show_all>
			<!--- display "Previous" link --->
			<cfif len(trim(attributes.prev_link_text))>
			<span class="CWpagingPrev">
				<cfif attributes.current_page gt 1>
					<cfoutput><a href="#attributes.base_url##attributes.paging_var#=#Max(DecrementValue(attributes.current_page),1)#">#trim(attributes.prev_link_text)#</a>#attributes.link_delimiter#</cfoutput>
				<cfelse>
					<cfoutput>#trim(attributes.prev_link_text)#</cfoutput>
				</cfif>
			</span>
			</cfif>
			<!--- display Page Numbers --->
			<cfif attributes.show_page_numbers>
				<!--- centerpage (1/2 of total links shown) --->
				<cfset centerPage = ceiling((attributes.max_links + 1) /2)>
				<!--- start page --->
				<cfif attributes.current_page lt attributes.max_links>
					<cfset startPage = 1>
				<cfelse>
					<cfset startPage = max(1, (attributes.current_page - attributes.max_links + centerPage))>
				</cfif>
				<!--- end page --->
				<cfset endPage = min((startPage + attributes.max_links - 1),totalPages)>
				<span class="CWpagingNumbers">
				<!--- loop through links to provided numbered navigation --->
				<cfloop from="#startPage#" to="#endPage#" index="pageNum">
					<cfif pageNum eq attributes.current_page>
						<cfoutput>#attributes.before_current_page##pageNum##attributes.after_current_page#</cfoutput>
					<cfelse>
						<cfoutput><a href="#attributes.base_url##attributes.paging_var#=#pageNum#">#pageNum#</a></cfoutput>
					</cfif>
					<cfif pageNum neq totalPages or (pageNum eq totalPages and len(trim(attributes.next_link_text)))>
						<cfoutput>#attributes.link_delimiter#</cfoutput>
					</cfif>
				</cfloop>
				</span>
			</cfif>
			<!--- display "Next" link --->
			<cfif len(trim(attributes.next_link_text))>
			<span class="CWpagingNext">
				<cfif attributes.current_page lt totalPages>
					<cfoutput><a href="#attributes.base_url##attributes.paging_var#=#min(incrementValue(attributes.current_page),totalPages)#">#trim(attributes.next_link_text)#</a></cfoutput>
				<cfelse>
					<cfoutput>#trim(attributes.next_link_text)#</cfoutput>
				</cfif>
			</span>
			</cfif>
			<!--- display "All" link --->
			<cfif len(trim(attributes.all_link_text))>
				<cfoutput><a class="CWpagingAll" href="#attributes.base_url#showall=1">#trim(attributes.all_link_text)#</a></cfoutput>
			</cfif>
		<!--- if showing all --->
		<cfelse>
			<!--- display "Paging" link --->
			<cfif len(trim(attributes.all_page_text))>
					<cfoutput><a class="CWpagingAll" href="#attributes.base_url#showall=0">#trim(attributes.all_page_text)#</a></cfoutput>
			</cfif>
		<!--- /end if show all --->
		</cfif>
		</p>
	</cfif>
</div>