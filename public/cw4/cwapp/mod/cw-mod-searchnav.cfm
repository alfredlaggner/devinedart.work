<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-mod-searchnav.cfm
File Date: 2012-08-25
Description: shows navigation menu or search form for product catalog
NOTES:
Searchtype options include:
- List: shows nested <ul><li> markup, used for navigation menus
- Links: shows rows of <a> links, used for store navigation links
- Form: shows search form, which can be submitted to search products on results page
- Breadcrumb: creates breadcrumb style navigation
==========================================================
--->

<!--- default url variables for search selections --->
<cfparam name="url.keywords" default="">
<cfparam name="url.category" default="0">
<cfparam name="url.category" default="0">
<cfparam name="url.secondary" default="0">
<cfparam name="url.product" default="0">
<!--- determines the type of search or navigation to display
	List | Links | Form | Breadcrumb --->
<cfparam name="attributes.search_type" default="Links">
<!--- form action / menu target page (default = product listings main page)--->
<cfparam name="attributes.action_page" default="#request.cwpage.urlResults#">
<!--- show empty categories (no products) --->
<cfparam name="attributes.show_empty" default="#application.cw.appDisplayEmptyCategories#">
<!--- show secondary categories --->
<cfparam name="attributes.show_secondary" default="true">
<!--- relate secondary categories to primary cats --->
<cfparam name="attributes.relate_cats" default="#application.cw.appEnableCatsRelated#">
<!--- for horizontal links, the separator is placed between all category links --->
<cfparam name="attributes.separator" default=" | ">
<!--- link to show as current (blank = CW automated) --->
<cfparam name="attributes.current_url" default="#request.cw.thisPageQS#">
<!--- text for 'all items' link (blank = not shown) --->
<cfparam name="attributes.all_categories_label" default="All Products">
<!--- label for all secondary categories link (blank = not shown )--->
<cfparam name="attributes.all_secondaries_label" default="All">
<!--- label for all products link in breadcrumb nav (blank = not shown )--->
<cfparam name="attributes.all_products_label" default="All Items">
<!--- text item tagged on to end of menu, overridden by search keywords --->
<cfparam name="attributes.end_label" default="">
<!--- show number of products in each category --->
<cfparam name="attributes.show_product_count" default="true">
<!--- for list or links type, formatted url/labels to insert before --->
<cfparam name="attributes.prepend_links" default="">
<!--- for list or links type, formatted url/labels to insert after --->
<cfparam name="attributes.append_links" default="">
<!--- id applied to menu <ul> --->
<cfparam name="attributes.menu_id" default="">
<!--- class applied to menu <ul> --->
<cfparam name="attributes.menu_class" default="">
<!--- Form Search Options--->
<!--- form id applied to the search <form> tag --->
<cfparam name="attributes.form_id" default="CWproductSearch">
<!--- show form keyword field --->
<cfparam name="attributes.form_keywords" default="false">
<!---  default text entered in the keyword search field --->
<cfparam name="attributes.form_keywords_text" default="Search Products">
<!--- category list in form --->
<cfparam name="attributes.form_category" default="false">
<!--- text for the first entry in the category list --->
<cfparam name="attributes.form_category_label" default="All #application.cw.adminLabelCategories#">
<!--- show secondary category list in form --->
<cfparam name="attributes.form_secondary" default="false">
<!--- text for the first entry in the secondary category list --->
<cfparam name="attributes.form_secondary_label" default="All #application.cw.adminLabelSecondaries#">
<!---  text for the search button --->
<cfparam name="attributes.form_button_label" default="Search">
<!--- for breadcrumb type, insert leading nav elements --->
<cfparam name="attributes.prepend_breadcrumb" default="<a href='#request.cwpage.urlResults#' class='CWlink'>Store</a>">
<!--- global functions --->
<cfinclude template="../inc/cw-inc-functions.cfm">
<!--- clean up form and url variables --->
<cfinclude template="../inc/cw-inc-sanitize.cfm">
<!---  if submitted, set the value for the keywordslabel to the submitted value --->
<cfif len(trim(url.keywords))>
	<cfset attributes.form_keywords_text = CWcleanString(trim(url.keywords))>
</cfif>
<!--- If no value was supplied for the buttonlabel, then set it to Search --->
<cfif attributes.form_button_label eq "">
	<cfset attributes.form_button_label = "Search">
</cfif>
<cfparam name="request.cwpage.categoryID" default="#url.category#">
<cfparam name="request.cwpage.secondaryID" default="#url.secondary#">
<cfparam name="request.cwpage.productID" default="#url.product#">
<cfparam name="request.cwpage.allCount" default="0">
<!--- clean up &lt; and &gt; in visible attributes --->
<cfset findCharsList = "&lt;,&gt;">
<cfset replaceCharsList = "<,>">
<cfset attributes.separator = replaceList(attributes.separator, findCharsList, replaceCharsList)>
<cfset attributes.prepend_links = trim(replace(attributes.prepend_links,',','^','all'))>

<!---  flag for relating secondaries --->
<cfif attributes.relate_cats
	AND(
	(attributes.search_type eq 'form'
	and attributes.form_secondary)
	OR
	(attributes.search_type neq 'form'
	and attributes.show_secondary)
	)>
	<cfset attributes.relate_cats = true>
</cfif>
<!--- starting values for list functions --->
<cfset lastLinkcount=0>
<cfset selectedgroup = 0>
<cfset isstarted = 0>
<cfset firstParent=1>
<cfset firstChild=1>
<!--- QUERY: get categories --->
<cfset categoryQuery = CWquerySelectCategories(show_empty=attributes.show_empty)>
<cfif attributes.show_secondary or attributes.form_secondary>
	<!--- QUERY: get secondaries --->
	<cfset secondaryQuery = CWquerySelectSecondaries(show_empty=attributes.show_empty, relate_cats=attributes.relate_cats)>
</cfif>
</cfsilent>
<!--- START OUTPUT--->
<cfprocessingdirective suppresswhitespace="yes">
<!--- ///  BEGIN SEARCH TYPE SELECTION  ///  --->
<cfswitch expression="#attributes.search_type#">
	<!--- LIST - nested ul/li markup --->
	<cfcase value="list">
		<cfsilent>
		<cfsavecontent variable="menuPages">
			<cfif len(trim(attributes.prepend_links))>
				<cfoutput>#trim(attributes.prepend_links)#</cfoutput><cfif not right(trim(attributes.prepend_links),1) is "^">^</cfif>
			</cfif>
			<!--- ***AM removed ALL PRODUCTS LINK *** link for all categories 
			<cfif len(trim(attributes.all_categories_label))>
			<cfoutput>0|#attributes.action_page#|#trim(attributes.all_categories_label)#^</cfoutput>
			</cfif>--->

			<cfoutput query="categoryQuery">
			#category_id#|#attributes.action_page#?category=#category_id#|#category_name#<cfif attributes.show_product_count> [#categoryQuery.catprodCount#]</cfif>^
			<!--- show secondary menu --->
			<cfif attributes.show_secondary>
				<cfif len(trim(attributes.all_secondaries_label))>
				#category_id#|#attributes.action_page#?category=#category_id#|#trim(attributes.all_secondaries_label)#<cfif attributes.show_product_count> [#categoryQuery.catprodCount#]</cfif>^
				</cfif>
				<cfif attributes.relate_cats>
					<cfquery dbtype="query" name="relateQuery">
					SELECT *
					FROM secondaryQuery
					WHERE category_id = #categoryQuery.category_id#
					</cfquery>
					<cfloop query="relateQuery">
					#relateQuery.category_id#|#attributes.action_page#?category=#category_id#&secondary=#relateQuery.secondary_id#|#relateQuery.secondary_name#<cfif attributes.show_product_count> [#relateQuery.catprodCount#]</cfif>^
					</cfloop>
				<cfelse>
					<!--- if not related --->
					<cfloop query="secondaryQuery">
					#categoryQuery.category_id#|#attributes.action_page#?category=#categoryQuery.category_id#&secondary=#secondaryQuery.secondary_id#|#secondaryQuery.secondary_name#<cfif attributes.show_product_count> [#secondaryQuery.catprodCount#]</cfif>^
					</cfloop>
				</cfif>
				</cfif>
			</cfoutput>
			<cfif len(trim(attributes.append_links))>
			<cfoutput>#trim(attributes.append_links)#</cfoutput>
			</cfif>
		</cfsavecontent>
		</cfsilent>
		<!--- pass page list to menu markup function --->
		<cfset displayList = CWcreateNav(page_list=menuPages,current_url=attributes.current_url,nav_id=attributes.menu_id,nav_class=attributes.menu_class,list_delimiter='^')>
		<cfoutput>#displayList#</cfoutput>
	</cfcase>
	<!--- /END LIST --->
	<!--- LINKS - horizontal display of <a> elements with separator --->
	<cfcase value="links">
		<cfsilent>
		<cfset linkCt = 1000>
		<cfsavecontent variable="menuPages">
		<cfif len(trim(attributes.prepend_links))>
			<cfoutput>#trim(attributes.prepend_links)#</cfoutput><cfif not right(trim(attributes.prepend_links),1) is "^">^</cfif>
		</cfif>
		<!--- link for all categories --->
		<cfif len(trim(attributes.all_categories_label))>
		<cfoutput>1|#attributes.action_page#|#trim(attributes.all_categories_label)#^</cfoutput>
		</cfif>
		<!--- top level links --->
		<cfoutput query="categoryQuery">
		<cfset request.cwpage.allCount = 0>
		1|#attributes.action_page#?category=#category_id#|#category_name#<cfif attributes.show_product_count> [#categoryQuery.catprodCount#]</cfif>^
		<!--- set count for current category 'all' link --->
		<cfif request.cwpage.categoryID eq categoryQuery.category_id AND len(trim(attributes.all_secondaries_label)) and attributes.show_product_count>
			<cfset request.cwpage.allCount = categoryQuery.catProdCount>
		</cfif>
		</cfoutput>
		<!--- secondary links (not shown for related links in 'all' cat) --->
		<cfif attributes.show_secondary
			and not (attributes.relate_cats eq true and request.cwpage.categoryID eq 0)>
			<cfoutput>
			<cfif len(trim(attributes.all_secondaries_label))>
			2|#attributes.action_page#<cfif request.cwpage.categoryID neq 0>?category=#request.cwpage.categoryID#</cfif>|#trim(attributes.all_secondaries_label)#<cfif attributes.show_product_count> [#request.cwpage.allCount#]</cfif>^
			</cfif>
				<cfif attributes.relate_cats>
					<cfquery dbtype="query" name="relateQuery">
					SELECT *
					FROM secondaryQuery
						<cfif request.cwpage.categoryID neq 0>
						WHERE category_id = #request.cwpage.categoryID#
						</cfif>
					</cfquery>
					<cfloop query="relateQuery">
					2|#attributes.action_page#?<cfif request.cwpage.categoryID neq 0>category=#relateQuery.category_id#&</cfif>secondary=#relateQuery.secondary_id#|#relateQuery.secondary_name#<cfif attributes.show_product_count> [#relateQuery.catprodCount#]</cfif>^
					<cfset linkCt = linkCt + 1>
					</cfloop>
				<cfelse>
					<!--- if not related --->
					<cfloop query="secondaryQuery">
					2|#attributes.action_page#?secondary=#secondaryQuery.secondary_id#|#secondaryQuery.secondary_name#<cfif attributes.show_product_count> [#secondaryQuery.catprodCount#]</cfif>^
					<cfset linkCt = linkCt + 1>
					</cfloop>
				</cfif>
			</cfoutput>
		</cfif>
		<cfif len(trim(attributes.append_links))><cfoutput>#trim(attributes.append_links)#</cfoutput></cfif>
	</cfsavecontent>
	</cfsilent>
	<!--- pass page list to menu markup function --->
	<cfset displayList = CWcreateLinks(page_list=menuPages,current_category=request.cwpage.categoryID,current_secondary=request.cwpage.secondaryID,link_delimiter=attributes.separator,list_delimiter='^')>
	<cfoutput>#displayList#</cfoutput>
	</cfcase>
	<!--- / END LINKS --->
	<!--- FORM - search form with optional elements --->
	<cfcase value="form">
		<form name="<cfoutput>#attributes.form_id#</cfoutput>" id="<cfoutput>#attributes.form_id#</cfoutput>" method="get" action="<cfoutput>#attributes.action_page#</cfoutput>">
			<!--- category --->
			<cfif attributes.form_category>
				<select name="category" id="<cfoutput>#attributes.form_id#</cfoutput>-category">
					<cfif len(trim(attributes.form_category_label))>
						<option value="0" class="search0">
							<cfoutput>#trim(attributes.form_category_label)#</cfoutput>
						</option>
					</cfif>
					<!--- populate dropdown with results of category query --->
					<cfoutput query="categoryQuery">
						<option value="#categoryQuery.category_id#" class="search#categoryQuery.category_id#"<cfif isDefined('request.cwpage.categoryID') and categoryQuery.category_id eq request.cwpage.categoryID> selected="selected"</cfif>>
						#categoryQuery.category_name#<cfif attributes.show_product_count> (#categoryQuery.catprodCount#)</cfif>
						</option>
					</cfoutput>
				</select>
			</cfif>
			<!--- secondary --->
			<cfif attributes.form_secondary>
				<select name="secondary" id="<cfoutput>#attributes.form_id#</cfoutput>-secondary">
					<!--- if label provided, show initial value --->
					<cfif len(trim(attributes.form_secondary_label))>
						<option value="0" selected="selected" class="search0"><cfoutput>#trim(attributes.form_secondary_label)#</cfoutput></option>
					</cfif>
					<!--- populate dropdown with results of secondary query  --->
					<cfoutput query="secondaryQuery">
						<!--- if id is valid --->
						<cfif secondaryQuery.secondary_id gt 0>
							<!--- if relating categories to secondaries, add class for selection script --->
							<option value="#secondaryQuery.secondary_id#"
							<cfif isDefined('secondaryQuery.category_id') and secondaryQuery.category_id gt 0> class="search#secondaryQuery.category_id#"</cfif>
							<cfif isDefined('request.cwpage.secondaryID') and secondaryQuery.secondary_id eq request.cwpage.secondaryID> selected="selected"</cfif>>#secondaryQuery.secondary_name#<cfif attributes.show_product_count> (#secondaryQuery.catprodCount#)</cfif>
							</option>
						</cfif>
					</cfoutput>
				</select>
			</cfif>
			<!--- keywords --->
			<cfif attributes.form_keywords>
				<input name="keywords" id="<cfoutput>#attributes.form_id#</cfoutput>-keywords" type="text" size="35" value="<cfoutput>#CWremoveEncoded(attributes.form_keywords_text)#</cfoutput>" onFocus="if(this.value == defaultValue){this.value=''}">
			</cfif>
			<input name="" type="submit" class="CWformButton" value="<cfoutput>Find It Fast!</cfoutput>">
		</form>
		<!--- script for related selections --->
		<cfset formScriptvar = 'request.cwpage.#attributes.form_id#FormScript'>
		<cfif not isDefined(#formScriptVar#)>
			<cfsavecontent variable="#formScriptVar#">
				<script type="text/javascript">
				jQuery(document).ready(function(){
					// form parent element (by id provided in attributes)
					var form_parent = '#<cfoutput>#attributes.form_id#</cfoutput>';
					// on submit, empty keywords value, remove duplicate secondaries
					jQuery(form_parent).submit(function(){
						<!--- only remove if it is not the results of a search --->
						<cfif not (len(trim(url.keywords)) and trim(url.keywords) eq attributes.form_keywords_text)>
							if (jQuery('#<cfoutput>#attributes.form_id#</cfoutput>-keywords').val() == '<cfoutput>#attributes.form_keywords_text#</cfoutput>'){
								jQuery('#<cfoutput>#attributes.form_id#</cfoutput>-keywords').val('');
							};
						</cfif>
						jQuery('#<cfoutput>#attributes.form_id#</cfoutput>-secondary-temp').remove('');
					});
				<!--- if relating secondaries to main level categories --->
				<cfif attributes.relate_cats and not isDefined("request.productCatsScript")>
					// related selections: create hidden copy of secondary select element
					jQuery(form_parent + ' #<cfoutput>#attributes.form_id#</cfoutput>-secondary').clone().appendTo(form_parent).attr('id','<cfoutput>#attributes.form_id#</cfoutput>-secondary-temp').hide();
					// function to restore secondary options matching a given class
					var $restoreSeconds = function(selectList,matchClass){
							var temp_id = jQuery(selectList).attr('id') + '-temp';
							var temp_select = jQuery(form_parent + ' #<cfoutput>#attributes.form_id#</cfoutput>-secondary-temp');
							jQuery(temp_select).find('option.' + matchClass).each(function(){
								jQuery(this).clone().appendTo(jQuery(form_parent + ' #<cfoutput>#attributes.form_id#</cfoutput>-secondary'));
							});
					};
					// function to reset all secondary options
					var $resetSeconds = function(selectList,matchClass){
							var temp_id = jQuery(selectList).attr('id') + '-temp';
							var temp_select = jQuery(form_parent + ' #<cfoutput>#attributes.form_id#</cfoutput>-secondary-temp');
							jQuery(temp_select).find('option').each(function(){
								jQuery(this).clone().appendTo(jQuery(form_parent + ' #<cfoutput>#attributes.form_id#</cfoutput>-secondary'));
							});
					};
					// hide non-matching secondaries on changing main category selection
					jQuery(form_parent + ' ' + '#<cfoutput>#attributes.form_id#</cfoutput>-category').change(function(){
						// class to match
						var keepClass = jQuery(this).find('option:selected').attr('class');
						// remove all options
						jQuery(form_parent + ' ' + '#<cfoutput>#attributes.form_id#</cfoutput>-secondary').children('option').remove();
							// reset all
							if (keepClass == 'search0'){
								$resetSeconds(this);
							// reset matching only
							} else {
								// restore default option
								$restoreSeconds(this,'search0');
								// restore matching
								$restoreSeconds(this,keepClass);
							};
					});
					// end hide non-matching secondaries
					// trigger change on page load
					jQuery(form_parent + ' ' + '#<cfoutput>#attributes.form_id#</cfoutput>-category').trigger('change');
					</cfif>
				});
				</script>
			</cfsavecontent>
			<cfhtmlhead text="#evaluate(formscriptvar)#">
		</cfif>
	</cfcase>
	<!--- / END FORM --->
	<!--- BREADCRUMB - category, secondary, product  --->
	<cfcase value="breadcrumb">
		<!--- category --->
		<cfif request.cwpage.categoryID gt 0>
			<cfsavecontent variable="catUrl">
				<cfoutput>#attributes.action_page#?category=#request.cwpage.categoryID#</cfoutput>
			</cfsavecontent>
			<!--- if we have the category name --->
			<cfif isDefined('request.cwpage.categoryName') AND len(trim(request.cwpage.categoryName))>
				<cfset catName = trim(request.cwpage.categoryName)>
				<!--- if no name, get it --->
			<cfelse>
				<cfset catQuery = CWquerySelectCatDetails(request.cwpage.categoryID)>
				<cfset catName = trim(catQuery.category_name)>
			</cfif>
			<!--- create the link --->
			<cfset catLink = '<a href="#catUrl#" class="CWlink" title="">#catName#</a>'>
			<!--- if no category is defined --->
		<cfelse>
			<!--- if using all categories link --->
			<cfif len(trim(attributes.all_categories_label))>
				<cfsavecontent variable="catUrl">
					<cfoutput>#attributes.action_page#</cfoutput>
				</cfsavecontent>
				<cfset catName = trim(attributes.all_categories_label)>
				<cfset catLink = '<a href="#catUrl#" class="CWlink" title="">#catName#</a>'>
			<cfelse>
				<cfset catLink = ''>
			</cfif>
		</cfif>
		<!--- secondary --->
		<cfif request.cwpage.secondaryID gt 0>
			<cfsavecontent variable="secondUrl">
				<cfoutput>#attributes.action_page#?<cfif request.cwpage.categoryID gt 0>category=#request.cwpage.categoryID#&</cfif>secondary=#request.cwpage.secondaryID#</cfoutput>
			</cfsavecontent>
			<!--- if we have the secondary name --->
			<cfif isDefined('request.cwpage.secondaryName') AND len(trim(request.cwpage.secondaryName))>
				<cfset secondName = trim(request.cwpage.secondaryName)>
				<!--- if no name, get it --->
			<cfelse>
				<cfset secondQuery = CWquerySelectSecondaryCatDetails(request.cwpage.secondaryID)>
				<cfset secondName = trim(secondQuery.secondary_name)>
			</cfif>
			<!--- create the link --->
			<cfset secondLink = '<a href="#secondUrl#" class="CWlink" title="">#secondName#</a>'>
			<!--- if no secondary ID defined --->
		<cfelse>
			<!--- if using all secondaries link and a category is defined --->
			<cfif len(trim(attributes.all_secondaries_label)) and request.cwpage.categoryID gt 0>
				<cfsavecontent variable="secondUrl">
					<cfoutput>#attributes.action_page#?category=#request.cwpage.categoryID#</cfoutput>
				</cfsavecontent>
				<cfset secondLink = '<a href="#secondUrl#" class="CWlink" title="">#attributes.all_secondaries_label#</a>'>
			<cfelse>
				<cfset secondLink = ''>
			</cfif>
		</cfif>
		<!--- product --->
		<cfif request.cwpage.productID gt 0>
			<!--- if we have the product name --->
			<cfif isDefined('request.cwpage.productName') AND len(trim(request.cwpage.productName))>
				<cfset prodName = trim(request.cwpage.productName)>
				<!--- if no name, get it --->
			<cfelse>
				<cfset prodQuery = CWquerySelectProductDetails(request.cwpage.productID)>
				<cfset prodName = trim(prodQuery.product_name)>
			</cfif>
			<!--- if no product ID defined --->
		<cfelse>
			<cfif len(trim(attributes.all_products_label)) AND request.cwpage.secondaryID gt 0>
				<cfset prodName = trim(attributes.all_products_label)>
			<cfelse>
				<cfset prodName = ''>
			</cfif>
		</cfif>
		<!--- if searching by keyword --->
		<cfif isDefined('request.cwpage.keywords') and len(trim(request.cwpage.keywords))>
			<cfset endLabel = 'Searching for &quot;' & CWremoveEncoded(CWcleanString(request.cwpage.keywords)) & '&quot;'>
		<cfelse>
			<cfset endLabel = '#attributes.end_label#'>
		</cfif>
		<!--- build the structure --->
		<cfsavecontent variable="navMarkup">
			<cfoutput>
				<cfif len(trim(attributes.prepend_breadcrumb))>#attributes.separator##trim(attributes.prepend_breadcrumb)#</cfif><cfif len(trim(catLink))>#attributes.separator##catLink#</cfif><cfif len(trim(secondLink)) and attributes.show_secondary>#attributes.separator##secondLink#</cfif><cfif len(trim(prodName))>#attributes.separator##prodName#</cfif><cfif len(trim(endLabel))>#attributes.separator##endLabel#</cfif>
			</cfoutput>
		</cfsavecontent>
		<!--- output the breadcrumb nav --->
		<cfif len(trim(navMarkup))>
			<div class="CWbreadcrumb"><cfoutput>#trim(navMarkup)#</cfoutput></div>
		</cfif>
	</cfcase>
	<!--- / END BREADCRUMB --->
</cfswitch>
</cfprocessingdirective>