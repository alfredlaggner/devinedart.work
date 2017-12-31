<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-script-tablesort.cfm
File Date: 2012-02-01
Description:
Manages jQuery-based sortable html tables, creates linked headers with sort markup as needed
==========================================================
--->
<cfparam name="url.sortby" type="string" default="">
<cfparam name="url.sortdir" type="string" default="">
</cfsilent>
<!--- CW TABLESORTER: add links to <th> text with jQuery, then sort with CF --->
<script type="text/javascript">
jQuery(document).ready(function(){
var CWsortLink = function(th, baseurl){
	var linkCol = jQuery(th).attr('class');
	var linkText = jQuery(th).text();
	// set up the base url
	if (!(baseurl.indexOf('?') > 0)) {
		baseurl = baseurl + '?';
	};
	// dynamic sortby
	var currentsortby = <cfoutput>'#url.sortby#'</cfoutput>;
	var currentsortdir = <cfoutput>'#url.sortdir#'</cfoutput>;
	var	linksortdir = 'asc';
	//alert(currentsortdir + ' <cfoutput>#url.sortdir#</cfoutput>');
	// debug: show current sortby & sortdir
	//alert(currentsortby + ' ' + currentsortdir);
	// if the current sort by is this column, reverse asc/desc from current
	if ((currentsortby == linkCol) && (currentsortdir == 'asc')){
	// add class for currentRow
			jQuery(th).removeClass('headerSortDown').removeClass('header').addClass('headerSortUp');
			linksortdir = 'desc';
	} else if ((currentsortby == linkCol) && (currentsortdir == 'desc')){
		// add class for currentRow
			//alert(currentsortby + ' ' + currentsortdir);
			jQuery(th).removeClass('headerSortUp').removeClass('header').addClass('headerSortDown');
	};
		// debug: show which column is currently sorted
		//alert(currentsortby + ' ' + currentsortdir);
	// dynamic href here
	var linkHref = baseurl + '&sortby=' + linkCol + '&sortdir=' + linksortdir;
	var thLinkWrap = '<a href="'  + linkHref +   '" title="Sort by '+ linkText + ' ' + linksortdir +  '">' + linkText +  '</a>';
	jQuery(th).empty().html(thLinkWrap).addClass('header');
	// debug: show table columns and text in a series of js alerts
	//alert(linkCol + ' ' + linkText);
};
// add the links to the table headers
jQuery('table.CWsort').each(function(){
var baseurl = jQuery(this).attr('summary');
// debug: show base url
//alert(baseurl);
jQuery(this).find('.sortRow > th:not(".noSort")').each(function(){
	// make sure we skip headers with no class at all
if (!(jQuery(this).attr('class') == '')){
	// run the function
	CWsortLink(this,baseurl);
	// add noSort to no class headers, for css styling
} else {
	jQuery(this).addClass('noSort');
};
});
});
// click anywhere on the cell to trigger the link inside
jQuery('table.CWsort tr.sortRow th').click(function(event){
	if(jQuery(event.target).is('th')){
  jQuery(this).find('a').each(function(){ window.location = this.href; });
  event.stopPropagation();
   };
});

});
</script>