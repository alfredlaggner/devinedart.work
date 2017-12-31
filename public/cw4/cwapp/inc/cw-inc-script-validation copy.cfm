<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-script-validation.cfm
File Date: 2012-02-01
Description: manages jQuery form validation
NOTES:
individual validation messages can be set for each form below
see http://docs.jquery.com/Plugins/Validation/validate#toptions for jquery validation options
==========================================================
--->
</cfsilent>
<script type="text/javascript">
jQuery(document).ready(function(){
	// VALIDATION
	// validate forms that have class="CWvalidate"
	jQuery('form.CWvalidate').each(function(){
	var alertID = jQuery(this).attr('id');
	jQuery(this).append('<div class="CWalertBox alertText validationAlert" style="display:none;"></div><div class="CWclear"></div>');
	});
	// handle select box changes
	jQuery('form.CWvalidate select').change(function(){
		jQuery(this).blur();
	});
	// set default options for validation
	jQuery.validator.setDefaults({
		focusInvalid:true,
		onkeyup:false,
		onblur:true,
		errorClass:"warning",
		errorElement:"span",
		errorPlacement: function(error, element) {
			// give the sibling label the warning class
			// insert error markup above the label
			jQuery(element).siblings('label').addClass('warning')
			// uncomment next line to show error messages above each field
			//.before(error)
			;
		   },
		 showErrors: function(errorMap, errorList) {
		 	// target the current form with this.currentForm
		 	//jQuery(this.currentForm).hide();
		 	if (this.numberOfInvalids() > 0){
		 		// dynamic message depending on form ID
		 		var formID = jQuery(this.currentForm).attr('id');
				if (formID == 'CWformCustomer'){
					var validationMessage = 'Complete all required information';
				} else if (formID == 'CWformLogin') {
					var validationMessage = '';
				} else if (formID == 'CWformOrderSubmit') {
					var validationMessage = 'Complete all required information';
				} else if (formID == 'CWformAddToCartWindow') {
					var validationMessage = 'Select at least one item';
				} else {
					var validationMessage = 'Complete your selection above';
				};
				// only show validation message if text is provided
						if (!(validationMessage == '')){
						jQuery(this.currentForm).children('.validationAlert:first').show().html(validationMessage);
						};
					// show the errors
						this.defaultShowErrors();
					// if everything is ok, reset the validation
					} else {
						//alert('Selection OK!');
						jQuery(this.currentForm).children('div.validationAlert').empty().hide();
						jQuery(this.currentForm).children('span.warning').remove();
						jQuery(this.currentForm).children('.warning').removeClass('warning');
					}
			}
		// end showErrors
		});
	jQuery('form.CWvalidate').each(function(){
		jQuery(this).validate();
	});
	// end form validation
});
</script>