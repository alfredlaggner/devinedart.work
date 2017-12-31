<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-scripts.cfm
File Date: 2012-02-01
Description: manages javascript functions for Cartweaver application
==========================================================
--->
</cfsilent>
<!--- form validation functions --->
<cfoutput>
<script src="#request.cw.assetSrcDir#js/jquery.metadata.js" type="text/javascript"></script>
<script src="#request.cw.assetSrcDir#js/jquery.validate.js" type="text/javascript"></script>
<script src="#request.cw.assetSrcDir#js/jquery.calculation.js" type="text/javascript"></script>
</cfoutput>
<!--- FORM VALIDATION: in separate script file --->
<cfinclude template="cw-inc-script-validation.cfm">
<!--- fancybox javascript  --->
<cfoutput><script src="#request.cw.assetSrcDir#js/fancybox/jquery.fancybox.pack.js" type="text/javascript"></script></cfoutput>
<!--- fancybox css required for proper function --->
<cfoutput><link href="#request.cw.assetSrcDir#js/fancybox/jquery.fancybox.css" rel="stylesheet" type="text/css"></cfoutput>
<!--- start script --->
<script type="text/javascript">
jQuery(document).ready(function(){
	// total quantities (for table product option type)
	jQuery('form#CWformAddToCart input.qty').keyup(function(){
		var sumVal = jQuery('form#CWformAddToCart input.qty').sum();
		jQuery('form#CWformAddToCart input#totalQty').val(sumVal);
	});
	// warning boxes fade out
	jQuery('.fadeOut').delay(2750).fadeOut(500);
	// cart confirmation coloring
	window.setTimeout(function(){jQuery('tr.cartConfirm').removeClass('cartConfirm');}, 2750);
	window.setTimeout(function(){jQuery('tr.stockAlert').removeClass('stockAlert');}, 2750);
	// CHECKALL CHECKBOXES
	// controls all checkboxes with class matching 'rel' attribute
	jQuery('input.checkAll, a.checkAllLink').click(function(){
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
	 // PRODUCT OPTIONS WINDOW (via add to cart function)
		var $optionLinkHandler = function(elem){
			// get url, remove quantity
			var origLink = jQuery(elem).siblings('a.selOptions:hidden');
			var origHref = jQuery(origLink).attr('href');
			var cleanHref = origHref.replace(/&intqty([\S])+/g,"");
			// qty box value
			var origQty = jQuery(elem).siblings('input.qty').val();
			var newHref = cleanHref + '&intqty=' + origQty;
			// add new url to link, trigger click
		jQuery(elem).next('a.selOptions:hidden').attr('href',newHref).trigger('click');
		};
		// clicking button triggers hidden fancybox link
		jQuery('input.CWaddButton').click(function(){
			$optionLinkHandler(this);
			//return false;
		});
		// submitting form (enter key in qty box) triggers hidden fancybox link
		jQuery('form.CWqtyForm').submit(function(){
			var fbButton = jQuery(this).find('input.CWaddButton');
			$optionLinkHandler(fbButton);
			jQuery('input.CWaddButton').unbind('click');
			return false;
		});
		// fancybox - see http://fancybox.net/api for available options
		jQuery('a.selOptions').each(function(){
			var windowHeight = jQuery(this).attr('rel');
			jQuery(this).fancybox({
			'titlePosition': 'inside',
			'margin': 4,
			'padding': 3,
			'overlayShow': true,
			'showCloseButton': true,
			'hideOnOverlayClick':true,
			'hideOnContentClick': false,
			'width':350,
			'height':parseInt(windowHeight),
			'autoDimensions':false,
			'showNavArrows':false
			});
		});
});
</script>
<!--- REGULAR JS FUNCTIONS --->
<script type="text/javascript">
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