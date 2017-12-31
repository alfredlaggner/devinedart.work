<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-scripts.cfm
File Date: 2012-12-13
Description:
Manages jQuery and other javascript functions for pages of Cartweaver admin
==========================================================
--->
<!--- params for optional scripts --->
<cfparam name="request.cwpage.isFormPage" default="true">
<cfparam name="request.cwpage.isTablePage" default="true">
<!--- param for functions below --->
<cfparam name="url.sortby" type="string" default="">
<cfparam name="url.sortdir" type="string" default="Asc">
<!--- date mask --->
<cfif isDefined('variables.CWlocaleDateMask')>
	<cfset request.cw.localeDateMask = CWlocaleDateMask()>
<cfelse>
	<cfset request.cw.localeDateMask = 'yyyy-mm-dd'>
</cfif>
<!--- datepicker script only allows specific date masks --->
<cfif left(request.cw.localeDateMask,1) is 'm'>
	<cfset request.cw.scriptDateMask = 'mm/dd/yyyy'>
<cfelseif left(request.cw.localeDateMask,1) is 'd'>
	<cfset request.cw.scriptDateMask = 'dd/mm/yyyy'>
<cfelse>
	<cfset request.cw.scriptDateMask = 'yyyy-mm-dd'>
</cfif>
</cfsilent>
<!--- if no javascript available, hide all content --->
<noscript>
<style type="text/css">
	#CWadminContent,#CWadminNavUL,#CWadminDashboard{display:none;}
</style>
</noscript>
<!-- jQuery - load first -->
<script  src="js/jquery-1.7.1.min.js" type="text/javascript"></script>
<!--- form pages - load form scripts --->
<cfif request.cwpage.isFormPage>
<script src="js/jquery.metadata.js" type="text/javascript"></script>
<script src="js/jquery.validate.js" type="text/javascript"></script>
<script src="js/jquery.datemethods.js" type="text/javascript"></script>
<script src="js/jquery.datepicker.js" type="text/javascript"></script>
<link href="css/cw-datepicker.css" rel="stylesheet" type="text/css">
</cfif>
<!--- table pages - load table scripts --->
<cfif request.cwpage.isTablePage>
<cfinclude template="cw-inc-admin-script-tablesort.cfm">
</cfif>
<!--- start script --->

<!--- MENU / TABS --->
<script type="text/javascript">
$(document).ready(function(){
// ADMIN MENU - navigation menu behavior for CW admin
	// create and insert the dropLink to each top nav link
	var dropLinkEl = '<a href="#" class="dropLink"></a>';
	jQuery(dropLinkEl).insertBefore('#CWadminNavUL > li > a');
	jQuery('#CWadminNavUL > li > a.dropLink').each(function(){
		// get href and class of sibling link
		var dropHref = jQuery(this).siblings('a').attr('href');
		var dropClass = jQuery(this).siblings('a').attr('class');
		// assign the href and class of the sibling link
		jQuery(this).attr('href',dropHref).addClass(dropClass);
	});
	// set up dropLink function
	jQuery('#CWadminNavUL > li > a.dropLink').click(function(event){
		// this link's parent
		var parentEl = jQuery(this).parent('li');
		// this link's submenu (if it exists)
		var childList = jQuery(parentEl).children('ul');
			// show/hide the submenu
			jQuery(childList).slideToggle(100);
			// change the class on the clicked link
			jQuery(this).toggleClass('open');
			// close others
			jQuery(parentEl).siblings('li').children('a').removeClass('open').siblings('ul').slideUp(100);
			event.stopPropagation();
			return false;
	});
	// current link highlighting
	jQuery('#CWadminNavUL > li > ul > li > a.currentLink')
	// add the lead characters
	.prepend('&diams;')
	// open the parent link
	.parents('#CWadminNavUL > li').addClass('currentLink').addClass('open');
	// show the parent link's sublist
	jQuery('#CWadminNavUL > li > a.currentLink').addClass('open').parents('li').addClass('currentSection').children('ul').slideDown('fast');
// TABS - click to show each tab
	// function to show a given tab
	var $setTab = function(tabID){
		jQuery('#CWadminTabWrapper div.CWtabBox div.tabDiv').hide();
		jQuery(tabID).show().find('input[type=text]:first').focus();
		jQuery('#CWadminTabWrapper ul.CWtabList').show();
		// return page to top if on admin home page
		<cfif request.cw.thisPage contains 'admin-home'>
			jQuery( 'html, body' ).animate( { scrollTop: 0 }, 0 );
		</cfif>
	};
	// show first tab on page load
	jQuery('#CWadminTabWrapper ul.CWtabList > li:first > a').addClass('currentTab');
	// function: click tab link to show tab area
	jQuery('#CWadminTabWrapper ul.CWtabList > li > a').click(function(e){
		var url = document.location.toString();
		// prevent scrolling
		e.preventDefault();
		$setTab(jQuery(this).attr('href'));
		jQuery('#CWadminTabWrapper ul.CWtabList > li > a').removeClass('currentTab');
		jQuery(this).addClass('currentTab');
		// return page to top
		<cfif request.cw.thisPage contains 'admin-home' or request.cw.thisPage contains 'product-details' or request.cw.thisPage contains 'discount-details'>
			if( (url.match('#tab')) || (!(url.match('#'))) ){
				jQuery( 'html, body' ).animate( { scrollTop: 0 }, 0 );
			}
		</cfif>
		return false;
	});
	// show tabs by named anchor or url variable
	var $showAnchorTab = function(){
		var url = document.location.toString();
		   //if URL contains an anchor
		  if (url.match('#tab')) {
		    var anchor = '#' + url.split('#')[1];
		    jQuery('#CWadminTabWrapper ul.CWtabList > li > a[href="' + anchor + '"]').trigger('click');
			jQuery( 'html, body' ).animate( { scrollTop: 0 }, 0 );
		  }
		  <!--- if no anchor, parse out showtab from url --->
		<cfif isDefined('url.showtab') AND isNumeric(url.showtab)>
		  else {
				jQuery('#CWadminTabWrapper ul.CWtabList > li:nth-child(<cfoutput>#url.showtab#</cfoutput>) > a').click();
			  // if the url does not already contain an anchor, scroll to top
	    		if(!(url.match('#'))){
					jQuery( 'html, body' ).animate( { scrollTop: 0 }, 0 );
	    		};
			}
		</cfif>
	};
	// end show tabs function
	$showAnchorTab();
});
</script>
<!--- GENERAL ADMIN SCRIPTS --->
<script type="text/javascript">
jQuery(document).ready(function(){
<!--- ALL PAGES - global functions  --->
// BROWSER CHECK: javascript alert for invalid browser (checks for box model not supported, or IE6)
	if ((!(jQuery.support.boxModel == true))||(jQuery.browser.msie && jQuery.browser.version == 6)){
		jQuery('#CWadminAlert').show().prepend('Browser version not supported: some functions may be disabled');
	};
// EXTERNAL LINKS: open rel=external links in new window
    jQuery('a[rel="external"]').addClass("external").click( function() {
        window.open( jQuery(this).attr('href'),'extWin');
        return false;
    });
// ADMIN ALERTS - close alert box by clicking icon
	jQuery('#closeAlertLink').click(function(){
	jQuery('#CWadminAlert').empty().hide();
	return false;
	});
// FOCUS FIELD with class 'focusField'
	jQuery('#CWadminContent form input.focusField').focus();
	// SEARCH FORMS - show/hide behavior
	//on load, change search link text, show the form, hide the advanced areas,
	//if not a details page, focus on the first input, ready to type
	jQuery('#showSearchFormLink').text('Advanced Search').parents('form').show().children('.advanced').hide()
	<cfif not request.cw.thisPage contains 'details.cfm'>.siblings('input:first').focus()</cfif>
	;
	// on clicking the link
	jQuery('#showSearchFormLink').click(function(){
	jQuery(this).parents('form').show().children('input:first').focus().siblings('.advanced').show();
		jQuery(this).hide();
		return false;
	});
	// if searching, keep this open w/ a simulated click
	<cfif isDefined('url.search') and url.search eq 'search'
	or isDefined('url.searchc') and url.searchc neq 0
	or isDefined('url.searchsc') and url.searchsc neq 0>
	jQuery('#showSearchFormLink').click();
	</cfif>
// DATE SELECTOR - datepicker function applied to text inputs with specified class
// demos for datepicker options are here: http://www.kelvinluck.com/assets/jquery/datePicker/v2/demo/index.html

// set first day of week ( 0 = sunday )
Date.firstDayOfWeek = 0;
// date formatting can be set here
Date.format = '<cfoutput>#request.cw.scriptDateMask#</cfoutput>';
//Date.format = 'yyyy-mm-dd';
// regular datepicker
<cfset request.cw.now = dateAdd('h',application.cw.globalTimeOffset,now())>
	jQuery('#CWadminContent form input.date_input').datePicker(
		{
		startDate: '<cfoutput>#LSdateFormat('01/01/2000',request.cw.scriptDateMask)#</cfoutput>',
		endDate: '<cfoutput>#LSdateFormat(dateAdd('yyyy',1,request.cw.now),'#request.cw.scriptDateMask#')#</cfoutput>'
		}
	);
// past only: limited to previous dates, start/end date related (order search)
	jQuery('#CWadminContent form input.date_input_past').datePicker(
		{
		startDate: '<cfoutput>#LSdateFormat('01/01/2000',request.cw.scriptDateMask)#</cfoutput>',
		endDate: (new Date()).asString()
		}
	);
// future only: limited to future dates, start/end date related (order search)
	jQuery('#CWadminContent form input.date_input_future').datePicker(
		{
		startDate: '<cfoutput>#LSdateFormat(dateAdd('d',-1,request.cw.now),request.cw.scriptDateMask)#</cfoutput>',
		endDate: '<cfoutput>#LSdateFormat(dateAdd('yyyy',2,request.cw.now),'#request.cw.scriptDateMask#')#</cfoutput>'
		}
	);
	jQuery('#selectStartDate').bind(
		'dpClosed',
		function(e, selectedDates)
		{
			var d = selectedDates[0];
			if (d) {
				d = new Date(d);
				jQuery('#selectEndDate').dpSetStartDate(d.asString());
			}
		}
	);
	jQuery('#selectEndDate').bind(
		'dpClosed',
		function(e, selectedDates)
		{
			var d = selectedDates[0];
			if (d) {
				d = new Date(d);
				jQuery('#selectStartDate').dpSetEndDate(d.asString());
			}
		}
	);
// put the calendar icon into the links
jQuery('#CWadminContent form a.dp-choose-date').text('').html('<img src="img/cw-date.png">');

<!--- config settings pages --->
<cfif request.cw.thisPage contains 'config-settings'>
 	// hide localtax tax rows if other selection made
 	<cfif application.cw.taxCalctype is not 'localtax'>
		<cfset hideConfigItems = 'taxSystem,taxChargeBasedOn,taxUseDefaultCountry,taxDisplayOnProduct'>
	<cfelse>
		<cfset hideConfigItems = 'avalaraID,avalaraKey,avalaraUrl,avalaraCompanyCode,avalaraDefaultCode,avalaraDefaultShipCode,taxLookupSendErrors,taxErrorEmail'>
	</cfif>
		<cfloop list="#hideConfigItems#" index="i">
		jQuery('tr.config-<cfoutput>#i#</cfoutput>').hide();
		</cfloop>
</cfif>
<!--- /end config settings pages --->
<!--- config item pages --->
<cfif request.cw.thisPage contains 'config-item-details' or request.cw.thisPage contains 'config-group-details'>
		// select input type changes visible rows
			// hide variable rows
			 jQuery('#possiblesRow, #sizeRow, #rowsRow').hide();
			// build function by type
			var $changeType = function(){
				// show all rows, then hide the unused ones below
				if (jQuery('#config_type').val() !== ''){
				var typeStr = jQuery('#config_type').val();
					// hide possibles
					if (typeStr == 'text' || typeStr == 'textarea' || typeStr == 'number' || typeStr == 'texteditor' || typeStr == 'boolean'){
					 jQuery('#possiblesRow').hide();
					};
					// hide size
					if (typeStr == 'select' || typeStr == 'radio' || typeStr == 'checkboxgroup' || typeStr == 'boolean' || typeStr == 'multiselect'){
					 jQuery('#sizeRow').hide();
					};
					// hide rows
					if (typeStr == 'select' || typeStr == 'radio' || typeStr == 'checkboxgroup' || typeStr == 'boolean' || typeStr == 'text' || typeStr == 'number'){
					 jQuery('#rowsRow').hide();
					};
					if (typeStr == 'select' || typeStr == 'radio' || typeStr == 'checkboxgroup' || typeStr == 'boolean' || typeStr == 'multiselect'){
					 jQuery('#valueRow').hide();
					};
					// hide required option
					if (typeStr == 'texteditor' || typeStr == 'boolean'){
					 jQuery('#requiredRow').hide();
					};
					// set default size values
					if (typeStr == 'text'){
					 	jQuery('#config_size').val('35');
					}
					if (typeStr == 'number'){
					 	jQuery('#config_size').val('5');
					}
					if (typeStr == 'multiselect'){
					 	jQuery('#config_rows').val('5');
					}
					if (typeStr == 'textarea' || typeStr == 'texteditor'){
					 	jQuery('#config_size').val('45');
					 	jQuery('#config_rows').val('5');
					}
				};
			};
			// run on page load, and when input is changed
			jQuery('#addNewForm tr').show();
			$changeType();
			jQuery('#config_type').change(function(){
			jQuery('#addNewForm tr').show();
			$changeType();
			});
		<cfif request.cw.thisPage contains 'config-group-details'>
			// reorder items link
			var orderLink = '<div class="smallPrint" id="configReset" style="float:right;padding-right:60px;"><a href="#" class="configResetLink">Reset Sort Numbering</a></div>';
			jQuery('#UpdateConfigItems').before(orderLink);
			// function to reset order
			var $resetOrder = function(formId){
				var sortInputs = jQuery('#' + formId + ' input.sort');
				jQuery(sortInputs).each(function(index){
					// index starts at 0, add 1 to get value
					jQuery(this).val(index+1);
				});
			};
			// click link to reset provided form by ID
			jQuery('#configReset .configResetLink').click(function(){
				$resetOrder('recordForm');
				return false;
			});
		</cfif>
</cfif>
<!--- /end config items pages --->
<!--- TABLE PAGES --->
<cfif request.cwpage.isTablePage and 1 is 2>
// TABLE ROW STRIPING
jQuery('#CWadminContent table.CWstripe tr:odd').not('.headerRow,.sortRow').addClass('CWrowOdd');
jQuery('#CWadminContent table.CWstripe tr:even').not('.headerRow,.sortRow').addClass('CWrowEven');

// CELL HOVER effect on form table cells containing links, inputs or selects
jQuery('#CWadminContent table td a, #CWadminContent table td input, #CWadminContent table td select, #CWadminContent table td textarea').parent('td').not('.noHover').hover(
	function(){
		// do not apply to disabled checkboxes
		if(
		(!(jQuery(this).children('input[type=checkbox]').attr('disabled') == true))
		&&
		// only apply if input is type 'text' (i.e. not hidden), or is a select,
		// or if we have a link in the cell
		(
			(jQuery(this).children('input').attr('type')=='text')
			||
			(jQuery(this).children('select').length > 0)
			||
			(jQuery(this).children('textarea').length > 0)
			||
			(jQuery(this).children('a').length > 0)
		)
		){
		jQuery('hoverCell').removeClass('hoverCell');
		jQuery(this).addClass('hoverCell').css('cursor','pointer');
		}
	},
	function(){
	jQuery(this).removeClass('hoverCell');
	}
	);

// PRODUCTLINK - click any part of cell on same row, skips image containers
jQuery('#CWadminContent table td a.productLink').parent('td').parent('tr').children('td').not(':has(img)').not('.noLink').click(function(){
	jQuery(this).parent('tr').children('td').find('a.productLink').each(function(){ window.location = this.href; });
}).hover(
	function(){
		var linkTitle = jQuery(this).parent('tr').children('td').find('a.productLink').attr('title');
		jQuery(this).attr('title',linkTitle);
		if(!(jQuery(this).children('input[type=checkbox]').attr('disabled') == true)){
		jQuery(this).css('cursor','pointer').addClass('hoverCell');
		}
	},
	function(){
	jQuery(this).removeClass('hoverCell');
	}
	);
// DETAILSLINK - click any part of cell , skips form input containers
jQuery('#CWadminContent table td a.detailsLink').parent('td').parent('tr').children('td').not(':has(input),:has(select),:has(textarea)').not('.noLink').click(function(event){
	event.stopPropagation();
	var linkTo = jQuery(this).parent('tr').children('td').find('a[class*=detailsLink]').attr('href');
	window.location = linkTo;
}).hover(
	function(){
		var linkTitle = jQuery(this).parent('tr').children('td').find('a.detailsLink').attr('title');
		jQuery(this).attr('title',linkTitle);
		if(!(jQuery(this).children('input[type=checkbox]').attr('disabled') == true)){
		jQuery(this).css('cursor','pointer').addClass('hoverCell');
		}
	},
	function(){
	jQuery(this).removeClass('hoverCell');
	}
	);
// COLUMNLINK - used for icons in tables, click any part of parent cell
jQuery('#CWadminContent table tr td a.columnLink').parent('td').not('.noLink').click(function(event){
	event.stopPropagation();
	jQuery(this).find('a.columnLink').each(function(){ window.location = this.href; });
}).hover(
	function(){
		var linkTitle = jQuery(this).find('a.columnLink').attr('title');
		jQuery(this).attr('title',linkTitle);
		if(!(jQuery(this).children('input[type=checkbox]').attr('disabled') == true)){
		jQuery(this).css('cursor','pointer').addClass('hoverCell');
		}
	},
	function(){
	jQuery(this).removeClass('hoverCell');
	}
	);
// INPUT CELLS - inputs in form table cells - click any part of cell
jQuery('#CWadminContent form table td input[type=text], #CWadminContent form table td textarea, #CWadminContent form table td select').parents('td').click(function(event){
	if(jQuery(event.target).is('td')){
		// calendar datepicker link - click any part of cell
		if(jQuery(this).children('a.dp-choose-date').length == 1){
			jQuery(this).children('a.dp-choose-date').click();
		// input, textarea, select
		} else {
		jQuery(this).children('input:first, textarea:first').select();
		jQuery(this).children('select:first').focus();
		}
	};
});
</cfif>
<!--- /END TABLE PAGES --->
<!--- FORM PAGES --->
<cfif request.cwpage.isFormPage> 
// TABINDEX - set tabindex on all visible form elements
// on-page forms, index = 1
jQuery('#CWadminPage form').not('.updateSKU').each(function() {
	var tabindex = 1;
	jQuery(this).find('input,select,textarea,a').each(function() {
	var $inputEl = jQuery(this);
	if ($inputEl.is(':visible')) {
	$inputEl.attr('tabindex', tabindex);
	}
	});
});
// navigation menu links, index = 3
jQuery('#CWadminNavUL a').each(function() {
	var tabindex = 3;
	jQuery(this).find('a').each(function() {
	var $inputEl = jQuery(this);
	if ($inputEl.is(':visible')) {
	$inputEl.attr('tabindex', tabindex);
	}
	});
});
// search forms, index = 5
jQuery('div.CWadminControlWrap form').each(function() {
	var tabindex = 5;
	jQuery(this).find('input,select,textarea,a').each(function() {
	var $inputEl = jQuery(this);
	if ($inputEl.is(':visible')) {
	$inputEl.attr('tabindex', tabindex);
	}
	});
});

// SUBMIT BUTTONS - submits defined form element on same page
jQuery('#CWadminContent form input.submitButton').click(function(){
	// use rel attribute to select form ID
	var targetFormID = jQuery(this).attr('rel');
	jQuery('form#' + targetFormID).submit();
});
// VALIDATION
// put the error box inside any button wrappers
jQuery('#CWadminContent form.CWvalidate div.CWformButtonWrap, #CWadminContent #addSkuForm div.CWformButtonWrap').prepend('<div class="alert" style="display:none;"></div>');
// validate forms with CWvalidate class
jQuery('#CWadminContent form.CWvalidate').validate({
	focusInvalid:false,
	onkeyup:false,
	onblur:false,
	errorClass:"warning",
	errorLabelContainer:"#CWadminAlert",
	 // handle showing number of invalids above submit button
	 showErrors: function(errorMap, errorList) {
	 	//debug: alert number of invalid fields found
	 	//alert(this.numberOfInvalids());
	 	if (this.numberOfInvalids() > 0){
	 		jQuery('#CWadminAlert div').remove();
	 		// move to top of page
	 		jQuery( 'html, body' ).animate( { scrollTop: 0 }, 0 );
	 			var errorText = 'error';
			 	if (this.numberOfInvalids() > 1){errorText = 'errors';}
			 	// show the errors inside the button wrapper
					jQuery('form.CWvalidate div.CWformButtonWrap .alert').show().html(this.numberOfInvalids() + ' ' + errorText + ', see above');
				// show the errors in the alert box
					this.defaultShowErrors();
				} else {
					jQuery('form.CWvalidate div.CWformButtonWrap .alert').empty().hide();
					jQuery('form.CWvalidate .warning').removeClass('warning');
					jQuery('#CWadminAlert label.warning').remove();
					if(jQuery('#CWadminAlert').html() == ''){jQuery('#CWadminAlert').hide();}
				}
		}
	// end handle invalids
	});
// validate SKU form
jQuery('#CWadminContent #addSkuForm').validate({
	focusInvalid:false,
	onkeyup:false,
	onblur:false,
	errorClass:"warning",
	errorLabelContainer:"#CWadminAlert",
	 // handle showing number of invalids above submit button
	 showErrors: function(errorMap, errorList) {
	 	//debug: alert number of invalid fields found
	 	// alert(this.numberOfInvalids());
	 	if (this.numberOfInvalids() > 0){
	 		jQuery('#CWadminAlert div').remove();
	 		// move to top of page
	 		jQuery( 'html, body' ).animate( { scrollTop: 0 }, 0 );
	 			var errorText = 'error';
			 	if (this.numberOfInvalids() > 1){errorText = 'errors';}
			 	// show the errors inside the button wrapper
					jQuery('#addSkuForm div.CWformButtonWrap div.alert').show().html(this.numberOfInvalids() + ' ' + errorText + ', see above');
				// show the errors in the alert box
					this.defaultShowErrors();
				} else {
					jQuery('#addSkuForm div.CWformButtonWrap div.alert').empty().hide();
					jQuery('#addSkuForm .warning').removeClass('warning');
					jQuery('#CWadminAlert label.warning').remove();
					jQuery('#CWadminAlert a#closeAlertLink').remove();
					if($.trim(jQuery('#CWadminAlert').html()) == ''){
						jQuery('#CWadminAlert').hide();
					}
				}
		}
	// end handle invalids
	});
// END VALIDATION

// SORT INPUTS - remove trailing .0
jQuery('#CWadminContent form input.sort').each(function(){
	var cleanVal = jQuery(this).val() * 1;
	jQuery(this).val(cleanVal);
});

// RADIOGROUP CHECKBOXES - only one in a group can be selected
	// groupName - use 'rel' attribute to assign grouping
	// isChecked - use true val to deselect others in group
var $radioBoxes = function(groupName,isChecked){
	//assemble the group name
	if(groupName != null){
		var groupEl = 'input[rel=' + groupName + ']';
		// if isChecked is passed in as true, deselect the relatives
		if (isChecked == true){
		jQuery(groupEl).prop('checked',false);
		};
	}
};
// when clicking any grouped checkbox, call the function above
jQuery('#CWadminContent form input.radioGroup').click(function(){
	var isChecked = false;
	if (jQuery(this).prop('checked')==true){
	isChecked = true;
	};
	$radioBoxes(jQuery(this).attr('rel'),isChecked);
	// check the original box
	jQuery(this).prop('checked',isChecked);
	});

// CHECKALL CHECKBOXES
	// controls all checkboxes with class matching 'rel' attribute
jQuery('#CWadminContent form input.checkAll, #CWadminContent form a.checkAllLink').click(function(){
	var checkClass = jQuery(this).attr('rel');
	//assemble the group name
	var groupEl = 'input[class*=' + checkClass + ']';
	//alert(groupEl);
	var isChecked = false;
	if (jQuery(this).prop('checked')==true){
	isChecked = true;
	};
	//alert(isChecked);
	jQuery(groupEl).each(function(){
		if (jQuery(this).attr('disabled')!=true){
		jQuery(this).prop('checked',isChecked);
		// handle radioGroup siblings
			if((jQuery(this).hasClass('radioGroup')==true) && (isChecked==true) ){
		$radioBoxes(jQuery(this).attr('rel'),isChecked);
		jQuery(this).prop('checked',isChecked);
			}

		};
	});
});

// CHECKBOXES in form table cells - click any part of cell
// checkbox labels css
jQuery('#CWadminContent form label:has(input[type=checkbox])').css('cursor','pointer').children('input[type=checkbox]').css('cursor','pointer');
// handle disabled checkboxes separately
jQuery('#CWadminContent form label:has(input[disabled=true])').css('cursor','default').children('input[disabled=true]').css('cursor','default');
jQuery('#CWadminContent form td:has(input[disabled=true])').css('cursor','default').children('input[disabled=true]').css('cursor','default');
// if a cell is clicked, trigger the checkbox
jQuery('#CWadminContent form input[type=checkbox]').parent('td').not('.noLink').click(function(event){
	// only run function if not disabled and the click was on the parent cell
	if ((!(jQuery(this).children('input[type=checkbox]').attr('disabled') == true))&&(jQuery(event.target).is('td'))){
			// if grouping, set up the rel value for the group
			var groupRel = jQuery(this).children('input[type=checkbox]').attr('rel');
				// if already checked, uncheck this box (uncheck others if grouped)
				if (jQuery(this).children('input[type=checkbox]').attr('checked') == true){
				$radioBoxes(groupRel,false);
				jQuery(this).children('input[type=checkbox]').prop('checked', false);
				// check this box (uncheck others if grouped)
				} else {
				$radioBoxes(groupRel,true);
				jQuery(this).children('input[type=checkbox]').trigger('click');
				//jQuery(this).children('input[type=checkbox]').prop('checked',true);
				};
	};
}).hover(
	function(){
		// hover if input not disabled
		if(!(jQuery(this).children('input[type=checkbox]').attr('disabled') == true)){
		jQuery(this).css('cursor','pointer').addClass('hoverCell');
		}
	},
	function(){
	jQuery(this).removeClass('hoverCell');
	}
	);
</cfif>
<!--- /END FORM PAGES --->

});
</script>

<!--- REGULAR JS FUNCTIONS --->
<cfif request.cwpage.isFormPage>
<script type="text/javascript">

//misc validation functions --------- //

// CHECK VALUE - return default value to empty input
// give your input any default value, and call with onblur="checkValue(this)"
function checkValue(inputName){
if (inputName.value == ''){
inputName.value = inputName.defaultValue;
};
}

// EXTRACT NUMERIC - allow numeric input only
// invoke like this:  onkeyup="extractNumeric(this,2,true)"
// thanks to http://www.mredkj.com/tutorials/validate2.html
function extractNumeric(obj,decimalPlaces,allowNegative) {
var out = obj.value;
// set defaults
if(decimalPlaces == null){
var decimalPlaces = 0;
};
if(allowNegative == null){
var allowNegative = false;
};
	// check for correct formatting
	var reg0Str = '[0-9]*';
	if (decimalPlaces > 0) {
		reg0Str += '\\<cfoutput>#application.cw.currencyDecimal#</cfoutput>?[0-9]{0,' + decimalPlaces + '}';
	} else if (decimalPlaces < 0) {
		reg0Str += '\\<cfoutput>#application.cw.currencyDecimal#</cfoutput>?[0-9]*';
	}
	reg0Str = allowNegative ? '^-?' + reg0Str : '^' + reg0Str;
	reg0Str = reg0Str + '$';
	var reg0 = new RegExp(reg0Str);
	if (reg0.test(out)) return true;

	// first replace all non numbers
	var reg1Str = '[^0-9' + (decimalPlaces != 0 ? '<cfoutput>#application.cw.currencyDecimal#</cfoutput>' : '') + (allowNegative ? '-' : '') + ']';
	var reg1 = new RegExp(reg1Str, 'g');
	out = out.replace(reg1, '');

	if (allowNegative) {
		// replace extra negative
		var hasNegative = out.length > 0 && out.charAt(0) == '-';
		var reg2 = /-/g;
		out = out.replace(reg2, '');
		if (hasNegative) out = '-' + out;
	}

	if (decimalPlaces != 0) {
		var reg3 = /\<cfoutput>#application.cw.currencyDecimal#</cfoutput>/g;
		var reg3Array = reg3.exec(out);
		if (reg3Array != null) {
			// keep only first occurrence of . or ,
			// and the number of places specified by decimalPlaces or the entire string if decimalPlaces < 0
			var reg3Right = out.substring(reg3Array.index + reg3Array[0].length);
			reg3Right = reg3Right.replace(reg3, '');
			reg3Right = decimalPlaces > 0 ? reg3Right.substring(0, decimalPlaces) : reg3Right;
			out = out.substring(0,reg3Array.index) + '<cfoutput>#application.cw.currencyDecimal#</cfoutput>' + reg3Right;
		}
	}
	obj.value = out;
    obj.focus();
};
//end misc validation functions--- //
</script>
</cfif>