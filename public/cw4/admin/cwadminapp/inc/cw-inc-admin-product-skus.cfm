<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-product-skus.cfm
File Date: 2012-05-23
Description: Manages skus as an include for product-details.cfm
==========================================================
NOTE:
Product / SKU actions are handled in the parent template, "product-details.cfm"

--->
<!--- default values from ProductForm page, used for processing --->
<cfparam name="request.listProductOptions" default="">
<cfparam name="skusQuery" type="query" default="">
<cfparam name="productOptionsRelQuery" type="query" default="">
<!--- mode can be passed in via url, or request scope, to override application setting --->
<cfparam name="url.skumode" default="#application.cw.adminSkuEditMode#">
<cfparam name="request.cwpage.adminSkuEditMode" default="#url.skumode#">
<!--- downloads enabled: shorten for easy reference, request scope can be overridden per instance --->
<cfset request.cwpage.ddok = application.cw.appDownloadsEnabled>
<!--- set up the url for saving skus --->
<cfset varsToKeep = CWremoveUrlVars("showtab,useralert,userconfirm,sortby,sortdir,skuMode")>
<cfset request.cwpage.skuUrl = CWserializeUrl(varsToKeep,request.cw.thisPage) & '&showtab=4'>
</cfsilent>
<!--- sort the query --->
<cfset skusQuery = CWsortableQuery(skusQuery)>
<!--- SKU JAVASCRIPT --->
<cfsavecontent variable="skuFormScript">
<script type="text/javascript">
		jQuery(document).ready(function(){
			// text and numeric inputs in the new sku form
			jQuery('#addSkuForm :input').change(function(){
			 	if(jQuery(this).val()!='' && jQuery(this).val()!='0' && jQuery(this).val()!=jQuery(this)[0].defaultValue){
				jQuery(this).addClass('changed');
			 	} else {
			 	jQuery(this).removeClass('changed');
			 	jQuery(this).removeClass('changed');
			 	}
			}).keyup(function(){
			 	jQuery(this).trigger('change');
			});
			// inputs in the edit sku form
			jQuery('form.updateSKU :input').change(function(){
			var defval = jQuery(this)[0].defaultValue;
			if (jQuery(this).val()!=defval){
				jQuery(this).addClass('changed');
			} else {
			 	jQuery(this).removeClass('changed');
			}
			}).keyup(function(){
			 	jQuery(this).trigger('change');
			});
			// selects in the edit sku form
			jQuery('form.updateSKU select').change(function(){
			var defval = jQuery(this).find('option[defaultSelected=true]').val();
			if (jQuery(this).val()!=defval){
				jQuery(this).addClass('changed');
			} else {
			 	jQuery(this).removeClass('changed');
			}
			}).keyup(function(){
			 	jQuery(this).trigger('change');
			});
			// list view
	<cfif request.cwpage.adminSkuEditMode is 'list'>
		jQuery('tr.optionsRow').hide(); jQuery('a.showOptions').click(function(){
		jQuery(this).parents('tr').next('tr.optionsRow').toggle();
		return false;
		});
		jQuery('a.showOptions').parent('td').click(function(){
		jQuery(this).find('a.showOptions').click();
		});
	</cfif>
<!--- javascript for file uploads --->
// upload file
		jQuery('a.showFileUploader').click(function(){
			var thisSrcUrl = jQuery(this).attr('href');
			jQuery(this).parents('td').find('div.fileUpload').show().children('iframe').attr('src',thisSrcUrl);
			jQuery(this).parents('td').find('div.alert').hide();
			return false;
		});
		// end upload file

		// select file
		jQuery('a.showFileSelector').click(function(){
			var thisSrcUrl = jQuery(this).attr('href');
			jQuery(this).parents('td').find('div.fileUpload').show().children('iframe').attr('src',thisSrcUrl);
			jQuery(this).parents('td').find('div.alert').hide();
			return false;
		});
		// end select file

		// clear file
		jQuery('img.clearFileLink').click(function(){
			jQuery(this).parents().siblings('input.fileInput').val('').siblings('img.productFilePreview').attr('src','');
			jQuery(this).parents('td').find('div.fileUpload').hide().children('iframe').attr('src','');
			jQuery(this).parents('td').find('div.alert').hide();
			return false;
		});
		// end clear file
	});
</script>
</cfsavecontent>
<cfhtmlhead text="#skuFormScript#">
<!--- if we have some options (we can make more skus),
or if we have no options and no skus yet (we can make 1 sku)  --->
<cfif (request.listProductOptions neq "" OR
	(request.listProductOptions eq "" AND skusQuery.recordCount LT 1))>
	<div class="CWformButtonWrap">
		<a id="showNewSkuFormLink" href="#" class="CWbuttonLink">Add New SKU</a>
		<a id="hideNewSkuFormLink" href="#" class="CWbuttonLink">Cancel New SKU</a>
	</div>
	<div class="clear">&nbsp;</div>
	<!--- NEW SKU FORM : loads hidden until link is clicked (or simulated click) --->
	<!-- SKU FORM -->
	<form name="addSkuForm" id="addSkuForm" class="CWSKUvalidate" method="post" action="<cfoutput>#request.cwpage.skuUrl#&skumode=#url.skumode#&sortby=#url.sortby#&sortdir=#url.sortdir#</cfoutput>" style="display:none;">
		<!-- NEW SKU TABLE -->
		<table class="CWformTable wide">
			<!-- table header -->
			<tr>
				<th>
					Add New SKU
				</th>
			</tr>
			<tr>
				<!-- table body -->
				<td>
					<!-- form container -->
					<table class="wide">
						<!-- form headers --->
						<tr class="headerRow">
							<th>SKU Name</th>
							<th>On Web</th>
							<th valign="top">Price</th>
							<cfif application.cw.adminProductAltPriceEnabled>
								<th valign="top">
									<cfoutput>#application.cw.adminLabelProductAltPrice#</cfoutput>
								</th>
							</cfif>
							<th valign="top">Sort</th>
							<th valign="top">Weight</th>
							<th valign="top">Ship Cost</th>
							<th valign="top">Stock</th>
						</tr>
						<!-- form inputs -->
						<tr>
							<!-- sku Merchant ID (part number) -->
							<td>
								<input name="sku_merchant_sku_id" type="text" size="17" value="<cfoutput>#form.sku_merchant_sku_id#</cfoutput>" class="required" title="SKU Name is required">
							</td>
							<!-- show on web yes/no -->
							<td>
								<select name="sku_on_web" id="sku_on_web">
									<cfif isDefined('form.sku_on_web') AND form.sku_on_web IS 0>
										<option value="1" >Yes</option>
										<option value="0" selected="selected">No</option>
									<cfelse>
										<option value="1" selected="selected">Yes</option>
										<option value="0">No</option>
									</cfif>
								</select>
							</td>
							<!-- price -->
							<td valign="top">
								<cfif not isNumeric(form.sku_price) and not form.sku_price is ''>
								<cfset form.sku_price = 0>
								</cfif>
								<input name="sku_price" type="text" value="<cfoutput>#form.sku_price#</cfoutput>" size="6"  maxlength="12" class="required"  title="SKU Price is required" onkeyup="extractNumeric(this,2,false);"  onblur="checkValue(this);">
							</td>
							<!-- alt price -->
							<cfif application.cw.adminProductAltPriceEnabled>
								<td valign="top">
									<input name="sku_alt_price" type="text" value="<cfoutput>#form.sku_alt_price#</cfoutput>" size="6"maxlength="12" class="required"  title="SKU <cfoutput>#application.cw.adminLabelProductAltPrice#</cfoutput> is required"  onkeyup="extractNumeric(this,2,false);"  onblur="checkValue(this);">
								</td>
							</cfif>
							<!-- sort -->
							<td valign="top">
								<input name="sku_sort" type="text" class="sort" value="<cfoutput>#form.sku_sort#</cfoutput>" size="5" maxlength="7" class="required" title="SKU Sort is required" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
							</td>
							<!-- weight -->
							<td valign="top">
								<input name="sku_weight" type="text" value="<cfoutput>#form.sku_weight#</cfoutput>" size="5" maxlength="7" class="required" title="SKU Weight is required" onkeyup="extractNumeric(this,2,false);" onblur="checkValue(this);">
							</td>
							<!-- ship base -->
							<td valign="top">
								<input name="sku_ship_base" type="text" value="<cfoutput>#form.sku_ship_base#</cfoutput>" size="6"maxlength="12" class="required" title="SKU Ship Cost is required"  onkeyup="extractNumeric(this,2,false);" onblur="checkValue(this);">
							</td>
							<!-- stock -->
							<td valign="top">
								<input name="sku_stock" type="text" value="<cfoutput>#form.sku_stock#</cfoutput>" size="5" maxlength="7" class="required"  title="SKU Stock is required" onkeyup="extractNumeric(this,0,true);" onblur="checkValue(this);">
							</td>
						</tr>
						<!-- /end form inputs -->
					</table>
					<!-- / end form container -->
					<!-- SKU OPTIONS -->
					<cfif productOptionsRelQuery.recordCount>
						<!-- sku options container -->
						<table class="CWformTable">
							<tr class="headerRow">
								<th colspan="2">
									SKU Options
								</th>
							</tr>
							<!--- output options, 1 per row --->
							<cfoutput query="productOptionsRelQuery" group="optiontype_name">
							<tr>
								<th class="label">#optiontype_name#:</th>
								<td>
									<cfsilent>
									<cfparam name="intChosenOption" default="0">
									<!--- Get options from form submission if there is one--->
									<cfif IsDefined('form.sku_id')>
										<cfloop collection="#FORM#" item="FormItem">
											<cfif FormItem eq "selOption" & currentRow>
												<cfset intChosenOption = FORM[FormItem]>
												<cfbreak>
											</cfif>
										</cfloop>
									</cfif>
									</cfsilent>
									<select name="selOption#currentRow#">
										<!--- additional cfoutput here cascades the grouped output --->
										<cfoutput>
										<option value="#productOptionsRelQuery.option_id#"#IIf(intChosenOption eq productOptionsRelQuery.option_id,DE(' selected'),DE(''))#>#productOptionsRelQuery.option_name#</option>
										</cfoutput>
									</select>
								</td>
							</tr>
							</cfoutput>
						</table>
					</cfif>
					<!--- file upload --->
					<cfif request.cwpage.ddok>
					<!--- build link for file uploader or selector --->
					<cfset fileUploadUrl="product-file-upload.cfm?uploadSku=0">
					<!--- set up file preview link if file exists --->
					<cfoutput>
					<table class="CWformTable wide">
						<tbody>
							<tr class="headerRow">
								<th colspan="2">File Management</th>
							</tr>
							<tr>
								<th class="label">
									SKU Download File:
								</th>
								<!--- file upload field / content area--->
								<td class="noHover">
									<input name="sku_download_file" id="sku_download_file-0" type="text" value="" class="fileInput" size="40">
									<!--- links w/ file upload field --->
									<span class="fieldLinks">
									<!--- ICON: upload file--->
									<a href="#fileUploadUrl#" title="Upload file" class="showFileUploader"><img src="img/cw-image-upload.png" alt="Upload file" class="iconLink"></a>
									<!--- ICON: clear filename field --->
									<img src="img/cw-delete.png" title="Clear file field" class="iconLink clearFileLink">
									</span>
									<!--- file content area --->
									<div class="productFileContent">
										<!--- file uploader --->
										<div class="fileUpload" style="display:none;">
											<iframe width="460" height="94" frameborder="no" scrolling="false">
											</iframe>
										</div>
									</div>
								<!--- hidden input for file download id --->
								<input name="sku_download_id" id="sku_download_id-0" type="hidden" value="">
								</td>
							</tr>
							<tr>
								<th class="label">
									Download Limit (0 = no limit):
								</th>
								<td class="noHover">
									<input name="sku_download_limit" type="text" value="#application.cw.appDownloadsLimitDefault#" size="5" maxlength="7" onkeyup="extractNumeric(this,0,true)" onblur="checkValue(this);">
								</td>
							</tr>
							<tr>
								<th class="label">
									File Version (optional):
								</th>
								<td class="noHover">
									<input name="sku_download_version" type="text" size="10" value="">
								</td>
							</tr>
						</tbody>
					</table>
					</cfoutput>
					</cfif>
					<!--- /end file upload --->
				</td>
			</tr>
		</table>
		<!--- end sku options output --->
		<div class="CWformButtonWrap">
			<input name="AddSKU" id="AddSKUbutton" type="submit" class="submitButton" value="Add New SKU">
		</div>
		<!--- hidden field for adding new vs. updating in processing code --->
		<input name="newsku" type="hidden" value="1">
		<!--- hidden field for product id --->
		<input name="sku_product_id" type="hidden" id="ProductID" value="<cfoutput>#url.productid#</cfoutput>">
	</form>
<cfelse>
	<div class="confirm">
		<br>
		<strong>&nbsp;&nbsp;No Options: only one sku allowed for this product</strong>
		<br>
		<br>
	</div>
</cfif>
<!--- end if we have some options --->
<!--- /////////////////////////////////////////////////// --->
<!--- /////////////// EXISTING SKUS ///////////////////// --->
<!--- /////////////////////////////////////////////////// --->
<!-- EXISTING SKUS -->

<cfif skusQuery.recordCount>
	<!--- if we have existing skus --->
	<!--- LIST VIEW --->
	<cfif request.cwpage.adminSkuEditMode is 'list'>
		<!--- form for updating all skus at once --->
		<form method="post" name="updateSKU" class="updateSKU CWobserve" action="<cfoutput>#request.cwpage.skuUrl#&skumode=#url.skumode#&sortby=#url.sortby#&sortdir=#url.sortdir#</cfoutput>">
			<input name="sku_product_id" type="hidden" value="<cfoutput>#skusQuery.sku_product_id#</cfoutput>">
			<input name="sku_editmode" type="hidden" value="<cfoutput>#request.cwpage.adminSkuEditMode#</cfoutput>">
			<cfif application.cw.adminSkuEditModeLink or listFindNoCase('developer',session.cw.accessLevel)>
				<cfoutput>
				<a href="#request.cwpage.skuUrl#&skumode=standard" class="CWbuttonLink SKUviewLink">Expanded View</a>
				</cfoutput>
			</cfif>
			<!--- save button --->
			<input name="UpdateSKUbutton" ID="UpdateSKUbutton" type="submit" class="submitButton updateSKU" value="Save Changes">
			<div class="clear"></div>
			<table class="CWsort CWstripe CWformTable" summary="<cfoutput>#request.cwpage.skuUrl#&skumode=#url.skumode#</cfoutput>">
				<thead>
				<tr class="headerRow sortRow">
					<th class="sku_merchant_sku_id">SKU</th>
					<th class="sku_on_web">On Web</th>
					<th class="sku_price">Price</th>
					<cfif application.cw.adminProductAltPriceEnabled>
						<th class="sku_alt_price"><cfoutput>#application.cw.adminLabelProductAltPrice#</cfoutput></th>
					</cfif>
					<th class="sku_sort">Sort</th>
					<th class="sku_weight">Weight</th>
					<th class="sku_ship_base">Ship Cost</th>
					<th class="sku_stock">Stock</th>
					<th class="noSort" style="text-align:center;width:80px;">
						<input type="checkbox" name="all0" class="checkAll" rel="all0" id="relProdAll0">Delete
					</th>
				</tr>
				</thead>
				<tbody>
				<!--- loop skus query --->
				<cfset rowCt = 0>
				<cfset disabledCt = 0>
				<cfloop query="skusQuery">
					<cfset rowCt = rowCt + 1>
					<cfsilent>
					<!--- QUERY: get SKU options --->
					<cfset skuOptionsQuery = CWquerySelectSkuOptions(skusQuery.sku_id)>
					<!--- set up a list of sku options --->
					<cfset listSkuOptions = valueList(skuOptionsQuery.sku_option2option_id)>
					<!--- QUERY: check for orders on this SKU --->
					<cfset ordersQuery = CWqueryCountSkuOrders(skusQuery.sku_id)>
					<cfif ordersQuery>
						<cfset HasOrders = 1>
						<cfset DisabledText = " disabled=""disabled""">
					<cfelse>
						<cfset HasOrders = 0>
						<cfset DisabledText = "">
					</cfif>
					</cfsilent>
					<!--- handle error if sku cannot be deleted --->
					<cfif IsDefined ('request.cantDeleteSKU')>
						<cfif url.delete_sku_id eq "#skusQuery.sku_id#">
							<div class="alert">
								<cfoutput>#request.cantDeleteSKU#</cfoutput>
							</div>
						</cfif>
					</cfif>
					<!--- SKU DETAILS --->
					<tr>
						<td>
							<cfoutput>#skusQuery.sku_merchant_sku_id#</cfoutput>
							<cfif productOptionsRelQuery.recordCount or request.cwpage.ddok>
								<br>
								<a class="showOptions smallPrint" href="#">Options</a>
							</cfif>
						</td>
						<!-- on web -->
						<td>
							<select name="<cfoutput>sku_on_web#rowCt#</cfoutput>" id="<cfoutput>sku_on_web#rowCt#</cfoutput>">
								<cfif skusQuery.sku_on_web IS not 0>
									<option value="1" selected="selected">
									Yes
									<option value="0">
									No
								<cfelse>
									<option value="1" >
									Yes
									<option value="0" selected="selected">
									No
								</cfif>
							</select>
						</td>
						<!-- price -->
						<td>
							<input name="<cfoutput>sku_price#rowCt#</cfoutput>" type="text" value="<cfoutput>#LSNumberFormat(skusQuery.sku_price, "9.99")#</cfoutput>" size="5" maxlength="12" onblur="checkValue(this);" onKeyUp="extractNumeric(this,2,false);">
						</td>
						<!-- alt price -->
						<cfif application.cw.adminProductAltPriceEnabled>
							<td>
								<input name="<cfoutput>sku_alt_price#rowCt#</cfoutput>" type="text" value="<cfoutput>#LSNumberFormat(skusQuery.sku_alt_price, "9.99")#</cfoutput>" size="5" maxlength="12" onblur="checkValue(this);" onKeyUp="extractNumeric(this,2,false);">
							</td>
						</cfif>
						<!-- sort -->
						<td>
							<input name="<cfoutput>sku_sort#rowCt#</cfoutput>" class="sort" type="text" value="<cfoutput>#skusQuery.sku_sort#</cfoutput>" size="2" maxlength="7" onkeyup="extractNumeric(this,2,true);" onblur="checkValue(this);">
						</td>
						<!-- weight-->
						<td>
							<input name="<cfoutput>sku_weight#rowCt#</cfoutput>" type="text" value="<cfoutput>#skusQuery.sku_weight#</cfoutput>" size="3" maxlength="7" onblur="checkValue(this);" onKeyUp="extractNumeric(this,2,false);">
						</td>
						<!-- ship base -->
						<td>
							<input name="<cfoutput>sku_ship_base#rowCt#</cfoutput>" type="text" value="<cfoutput>#LSNumberFormat(skusQuery.sku_ship_base, "9.99")#</cfoutput>" size="5"maxlength="7" onblur="checkValue(this);" onKeyUp="extractNumeric(this,2,false);">
						</td>
						<!-- stock-->
						<td>
							<input name="<cfoutput>sku_stock#rowCt#</cfoutput>" type="text" value="<cfoutput>#skusQuery.sku_stock#</cfoutput>" size="2" maxlength="7" onkeyup="extractNumeric(this,0,true)" onblur="checkValue(this);">
						</td>
						<!--- delete checkbox --->
						<td style="text-align: center;" width="80">
							<cfif NOT HasOrders eq 1>
								<cfoutput><input type="checkbox" name="Deletesku_id#rowCt#" value="#SkusQuery.sku_id#" class="all0 formCheckbox"</cfoutput>>
							<cfelse>
								<cfset disabledCt = disabledCt + 1>
							</cfif>
							<!--- hidden id fields --->
							<input name="<cfoutput>sku_id#rowCt#</cfoutput>" type="hidden" value="<cfoutput>#skusQuery.sku_id#</cfoutput>">
							<input name="sku_id" type="hidden" value="<cfoutput>#skusQuery.sku_id#</cfoutput>">
						</td>
					</tr>
					<!-- SKU OPTIONS -->
					<!--- if we have some product options to show --->
					<cfif productOptionsRelQuery.recordCount or request.cwpage.ddok>
						<tr class="optionsRow">
							<td colspan="9">
								<cfif productOptionsRelQuery.recordCount>
									<!-- sku options container -->
									<table class="CWformTable">
										<tr class="headerRow">
											<th colspan="2">SKU Options</th>
										</tr>
										<!--- show options, 1 per row --->
										<cfif not HasOrders>
											<cfoutput query="productOptionsRelQuery" group="optiontype_name">
											<tr>
												<th class="label noSort">#optiontype_name#</th>
												<td>
													<select name="selOption#currentRow#_#rowCt#"#DisabledText#>
														<!--- additional cfoutput here cascades the grouped output --->
														<cfoutput>
														<cfif ListFind(listSKUOptions,productOptionsRelQuery.option_id,",") neq 0>
															<option value="#productOptionsRelQuery.option_id#" selected="selected">#productOptionsRelQuery.option_name#</option>
														<cfelse>
															<option value="#productOptionsRelQuery.option_id#">#productOptionsRelQuery.option_name#</option>
														</cfif>
														</cfoutput>
													</select>
												</td>
											</tr>
											</cfoutput>
										<cfelse>
											<cfoutput query="productOptionsRelQuery" group="optiontype_name">
											<tr>
												<th class="label">#optiontype_name#:</th>
												<td>
													<cfoutput>
													<cfif ListFind(listSKUOptions,productOptionsRelQuery.option_id,",") neq 0>
														#productOptionsRelQuery.option_name#
														<input type="hidden" value="#productOptionsRelQuery.option_id#" name="selOption#currentRow#_#rowCt#" id="selOption#currentRow#">
													</cfif>
													</cfoutput>
												</td>
											</tr>
											</cfoutput>
										</cfif>
									</table>
								</cfif>
								<!-- end product options -->
								<!--- file upload --->
								<cfif request.cwpage.ddok>
								<cfparam name="skusQuery.sku_download_file" default="">
								<cfparam name="skusQuery.sku_download_id" default="">
								<cfparam name="skusQuery.sku_download_limit" default="">
								<cfparam name="skusQuery.sku_download_version" default="">
								<!--- build link for file uploader or selector --->
								<cfset fileUploadUrl="product-file-upload.cfm?uploadSku=#skusQuery.sku_id#">
								<cfset fileSelectUrl="product-file-select.cfm?uploadSku=#skusQuery.sku_id#">
								<!--- set up file preview link if file exists --->
								<cfoutput>
								<table class="CWformTable wide">
									<tbody>
										<tr class="headerRow">
											<th colspan="2">File Management</th>
										</tr>
										<tr>
											<th class="label">
												SKU Download File:
												<!--- file preview link --->
												<cfif len(trim(CWcreateDownloadURL(skusQuery.sku_id)))
													and len(trim(skusQuery.sku_download_file))>
												<!--- if the file does not exist, the createdownloadurl function will return ''--->
												<div class="smallPrint">
														<a href="#CWcreateDownloadURL(skusQuery.sku_id,'product-file-preview.cfm')#" rel="external">Download File</a>
												</div>
												</cfif>
											</th>
											<!--- file upload field / content area--->
											<td class="noHover">
												<input name="sku_download_file#rowCt#" id="sku_download_file-#skusQuery.sku_id#" type="text" value="#skusQuery.sku_download_file#" class="fileInput" size="40">
												<!--- links w/ file upload field --->
												<span class="fieldLinks">
												<!--- ICON: upload file--->
												<a href="#fileUploadUrl#" title="Upload file" class="showFileUploader"><img src="img/cw-image-upload.png" alt="Upload file" class="iconLink"></a>
												<!--- ICON: clear filename field --->
												<img src="img/cw-delete.png" title="Clear file field" class="iconLink clearFileLink">
												</span>
												<!--- if a file name is recorded, but file is not available, show error warning --->
												<cfif len(trim(skusQuery.sku_download_file)) AND NOT len(trim(CWcreateDownloadURL(skusQuery.sku_id)))>
													<div class="alert">File not available</div>
												</cfif>
												<!--- file content area --->
												<div class="productFileContent">
													<!--- file uploader --->
													<div class="fileUpload" style="display:none;">
														<iframe width="460" height="94" frameborder="no" scrolling="false">
														</iframe>
													</div>
												</div>
											<!--- hidden input for file download id --->
											<input name="sku_download_id#rowCt#" id="sku_download_id-#skusQuery.sku_id#" type="hidden" value="#skusQuery.sku_download_id#">
											</td>
										</tr>
										<tr>
											<th class="label">
												Download Limit (0 = no limit):
											</th>
											<td class="noHover">
												<input name="sku_download_limit#rowCt#" type="text" value="#skusQuery.sku_download_limit#" size="5" maxlength="7" onkeyup="extractNumeric(this,0,true)" onblur="checkValue(this);">
											</td>
										</tr>
										<tr>
											<th class="label">
												File Version (optional):
											</th>
											<td class="noHover">
												<input name="sku_download_version#rowCt#" type="text" size="10" value="#skusQuery.sku_download_version#">
											</td>
										</tr>
									</tbody>
								</table>
								</cfoutput>
								</cfif>
								<!--- /end file upload --->								
								<cfif HasOrders eq 1>
									<span class="smallprint">
										<br>
										&nbsp;&nbsp;Note: orders placed, cannot change options
										<br>
									</span>
								</cfif>
							</td>
						</tr>
					</cfif>
					<!--- end if we have some options --->
				</cfloop>
			</table>
			<!--- show message explaining disabled checkboxes --->
			<cfif disabledCt>
				<span style="float: right;" class="smallPrint">Note:&nbsp;&nbsp;skus with associated orders cannot be deleted</span>
			</cfif>
			<!--- the tab to return to when this form is submitted: changed dynamically when clicking on various tabs --->
			<input name="returnTab" class="returnTab" type="hidden" value="1">
		</form>
		<!--- / END LIST VIEW --->
		<!--- STANDARD VIEW --->
	<cfelse>
				<cfif application.cw.adminSkuEditModeLink or listFindNoCase('developer',session.cw.accessLevel)>
					<cfoutput>
					<a href="#request.cwpage.skuUrl#&skumode=list" class="CWbuttonLink SKUviewLink">List View</a>
					</cfoutput>
				</cfif>
			<div class="clear"></div>
		<table class="CWformTable wide">
			<tr class="headerRow">
				<th>
					Current SKUs for Product '<cfoutput>#request.cwpage.productName#</cfoutput>'
				</th>
			</tr>
			<!--- loop skus query --->
			<cfloop query="skusQuery">
				<cfsilent>
				<!--- QUERY: get SKU options --->
				<cfset skuOptionsQuery = CWquerySelectSkuOptions(skusQuery.sku_id)>
				<!--- set up a list of sku options --->
				<cfset listSKUOptions = valueList(skuOptionsQuery.sku_option2option_id)>
				<!--- QUERY: check for orders on this SKU --->
				<cfset ordersQuery = CWqueryCountSKUOrders(skusQuery.sku_id)>
				<cfif ordersQuery>
					<cfset HasOrders = 1>
					<cfset DisabledText = " disabled=""disabled""">
				<cfelse>
					<cfset HasOrders = 0>
					<cfset DisabledText = "">
				</cfif>
				</cfsilent>
				<!-- SKU Name  -->
				<tr>
					<td>
						<table class="CWskuTable wide">
							<tr class="headerRow">
								<th>
									<cfoutput>
									SKU: <a name="#skusQuery.sku_id#">#skusQuery.sku_merchant_sku_id#</a>
									</cfoutput>
								</th>
							</tr>
							<!-- SKU FORM -->
							<tr>
								<td>
									<form method="post" name="updateSKU" class="updateSKU" action="<cfoutput>#request.cwpage.skuUrl#&skumode=#url.skumode#</cfoutput>">
										<!--- handle error if sku cannot be deleted --->
										<cfif IsDefined ('request.cantDeleteSKU')>
											<cfif url.delete_sku_id eq "#skusQuery.sku_id#">
												<div class="alert">
													<cfoutput>#request.cantDeleteSKU#</cfoutput>
												</div>
											</cfif>
										</cfif>
										<!-- SKU FORM Container -->
										<table class="CWformTable">
											<!-- form headers -->
											<tr class="headerRow">
												<th>On Web</th>
												<th>Price</th>
												<cfif application.cw.adminProductAltPriceEnabled>
													<th valign="top">
														<cfoutput>#application.cw.adminLabelProductAltPrice#</cfoutput>
													</th>
												</cfif>
												<th>Sort</th>
												<th>Weight</th>
												<th>Ship Cost</th>
												<th>Stock</th>
											</tr>
											<!-- form inputs -->
											<tr>
												<!-- on web -->
												<td>
													<select name="sku_on_web" id="sku_on_web">
														<cfif skusQuery.sku_on_web IS not 0>
															<option value="1" selected="selected">
															Yes
															<option value="0">
															No
														<cfelse>
															<option value="1" >
															Yes
															<option value="0" selected="selected">
															No
														</cfif>
													</select>
												</td>
												<!-- price -->
												<td>
													<input name="sku_price" type="text" value="<cfoutput>#LSNumberFormat(skusQuery.sku_price, "9.99")#</cfoutput>" size="6"maxlength="12" onblur="checkValue(this);" onKeyUp="extractNumeric(this,2,false);">
												</td>
												<!-- alt price -->
												<cfif application.cw.adminProductAltPriceEnabled>
													<td>
														<input name="sku_alt_price" type="text" value="<cfoutput>#LSNumberFormat(skusQuery.sku_alt_price, "9.99")#</cfoutput>" size="6" maxlength="12" onblur="checkValue(this);" onKeyUp="extractNumeric(this,2,false);">
													</td>
												</cfif>
												<!-- sort -->
												<td>
													<input name="sku_sort" class="sort" type="text" value="<cfoutput>#skusQuery.sku_sort#</cfoutput>" size="5" maxlength="7" onblur="checkValue(this);" onKeyUp="extractNumeric(this,2,true);">
												</td>
												<!-- weight-->
												<td>
													<input name="sku_weight" type="text" value="<cfoutput>#skusQuery.sku_weight#</cfoutput>" size="5" maxlength="7" onblur="checkValue(this);" onKeyUp="extractNumeric(this,2,false);">
												</td>
												<!-- ship base -->
												<td>
													<input name="sku_ship_base" type="text" value="<cfoutput>#LSNumberFormat(skusQuery.sku_ship_base, "9.99")#</cfoutput>" size="6"maxlength="7" onblur="checkValue(this);" onKeyUp="extractNumeric(this,2,false);">
												</td>
												<!-- stock-->
												<td>
													<input name="sku_stock" type="text" value="<cfoutput>#skusQuery.sku_stock#</cfoutput>" size="5" maxlength="7" onkeyup="extractNumeric(this,0,true)" onblur="checkValue(this);">
												</td>
											</tr>
											<!-- end inputs -->
										</table>
										<!-- end sku form container -->
										<!-- SKU OPTIONS -->
										<!--- if we have some product options to show --->
										<cfif productOptionsRelQuery.recordCount>
											<!-- sku options container -->
											<table class="CWformTable">
												<tr class="headerRow">
													<th colspan="2">SKU Options</th>
												</tr>
												<!--- show options, 1 per row --->
												<cfif not HasOrders>
													<cfoutput query="productOptionsRelQuery" group="optiontype_name">
													<tr>
														<th class="label">#optiontype_name#:</th>
														<td>
															<select name="selOption#currentRow#"#DisabledText#>
																<!--- additional cfoutput here cascades the grouped output --->
																<cfoutput>
																<cfif ListFind(listSKUOptions,productOptionsRelQuery.option_id,",") neq 0>
																	<option value="#productOptionsRelQuery.option_id#" selected="selected">#productOptionsRelQuery.option_name#</option>
																<cfelse>
																	<option value="#productOptionsRelQuery.option_id#">#productOptionsRelQuery.option_name#</option>
																</cfif>
																</cfoutput>
															</select>
														</td>
													</tr>
													</cfoutput>
												<cfelse>
													<cfoutput query="productOptionsRelQuery" group="optiontype_name">
													<tr>
														<th class="label">#optiontype_name#:</th>
														<td>
															<cfoutput>
															<cfif ListFind(listSKUOptions,productOptionsRelQuery.option_id,",") neq 0>
																#productOptionsRelQuery.option_name#
																<input type="hidden" value="#productOptionsRelQuery.option_id#" name="selOption#currentRow#" id="selOption#currentRow#">
															</cfif>
															</cfoutput>
														</td>
													</tr>
													</cfoutput>
												</cfif>
											</table>
											<!-- end product options -->
										</cfif>
										<!--- end if we have some options --->
										<!--- file upload --->
										<cfif request.cwpage.ddok>
										<cfparam name="skusQuery.sku_download_file" default="">
										<cfparam name="skusQuery.sku_download_id" default="">
										<cfparam name="skusQuery.sku_download_limit" default="">
										<cfparam name="skusQuery.sku_download_version" default="">
										<!--- build link for file uploader or selector --->
										<cfset fileUploadUrl="product-file-upload.cfm?uploadSku=#skusQuery.sku_id#">
										<cfset fileSelectUrl="product-file-select.cfm?uploadSku=#skusQuery.sku_id#">
										<!--- set up file preview link if file exists --->
										<cfoutput>
										<table class="CWformTable wide">
											<tbody>
												<tr class="headerRow">
													<th colspan="2">File Management</th>
												</tr>
												<tr>
													<th class="label">
														SKU Download File:
														<!--- file preview link --->
														<cfif len(trim(CWcreateDownloadURL(skusQuery.sku_id)))
															and len(trim(skusQuery.sku_download_file))>
														<!--- if the file does not exist, the createdownloadurl function will return ''--->
														<div class="smallPrint">
																<a href="#CWcreateDownloadURL(skusQuery.sku_id,'product-file-preview.cfm')#" rel="external">Download File</a>
														</div>
														</cfif>
													</th>
													<!--- file upload field / content area--->
													<td class="noHover">
														<input name="sku_download_file" id="sku_download_file-#skusQuery.sku_id#" type="text" value="#skusQuery.sku_download_file#" class="fileInput" size="40">
														<!--- links w/ file upload field --->
														<span class="fieldLinks">
														<!--- ICON: upload file--->
														<a href="#fileUploadUrl#" title="Upload file" class="showFileUploader"><img src="img/cw-image-upload.png" alt="Upload file" class="iconLink"></a>
														<!--- ICON: clear filename field --->
														<img src="img/cw-delete.png" title="Clear file field" class="iconLink clearFileLink">
														</span>
														<!--- if a file name is recorded, but file is not available, show error warning --->
														<cfif len(trim(skusQuery.sku_download_file)) AND NOT len(trim(CWcreateDownloadURL(skusQuery.sku_id)))>
															<div class="alert">File not available</div>
														</cfif>
														<!--- file content area --->
														<div class="productFileContent">
															<!--- file uploader --->
															<div class="fileUpload" style="display:none;">
																<iframe width="460" height="94" frameborder="no" scrolling="false">
																</iframe>
															</div>
														</div>
													<!--- hidden input for file download id --->
													<input name="sku_download_id" id="sku_download_id-#skusQuery.sku_id#" type="hidden" value="#skusQuery.sku_download_id#">
													</td>
												</tr>
												<tr>
													<th class="label">
														Download Limit (0 = no limit):
													</th>
													<td class="noHover">
														<input name="sku_download_limit" type="text" value="#skusQuery.sku_download_limit#" size="5" maxlength="7" onkeyup="extractNumeric(this,0,true)" onblur="checkValue(this);">
													</td>
												</tr>
												<tr>
													<th class="label">
														File Version (optional):
													</th>
													<td class="noHover">
														<input name="sku_download_version" type="text" size="10" value="#skusQuery.sku_download_version#">
													</td>
												</tr>
											</tbody>
										</table>
										</cfoutput>
										</cfif>
										<!--- /end file upload --->
										<cfif HasOrders eq 1>
											<span class="smallprint">
												<br>
												&nbsp;&nbsp;Note: orders placed, cannot delete
												<br>
											</span>
										</cfif>
										<!--- Sku Form Buttons --->
										<div class="CWformButtonWrap">
											<!--- delete sku --->
											<cfoutput>
											<cfif NOT HasOrders>
												<a class="CWbuttonLink" href="#request.cw.thisPage#?deletesku=#skusQuery.sku_id#&productid=#detailsQuery.product_id#&showtab=4" onClick="return confirm('Delete this SKU? (This is permanent)')">Delete SKU</a>
											</cfif>
											</cfoutput>
											<!--- copy sku --->
											<cfif  (listProductOptions neq "" OR (listProductOptions eq "" AND skusQuery.recordCount LT 1))>
												<a class="skuDupLink CWbuttonLink" href="#">Copy Sku</a>
											</cfif>
											<!--- save button --->
											<input name="updateSKU" type="submit" class="submitButton updateSKU" value="Save SKU">
										</div>
										<cfif  (listProductOptions neq "" OR (listProductOptions eq "" AND skusQuery.recordCount LT 1))>
											<div id="skuDup" style="display:none;">
												<label>New SKU Name</label>
												<input type="text" size="25" name="sku_merchant_sku_id" value="">
												<input name="AddSKU" type="submit" class="CWformButton" value="Duplicate SKU">
											</div>
										</cfif>
										<p>&nbsp;</p>
										<input name="sku_product_id" type="hidden" value="<cfoutput>#skusQuery.sku_product_id#</cfoutput>">
										<input name="sku_id" type="hidden" value="<cfoutput>#skusQuery.sku_id#</cfoutput>">
										<input name="sku_editmode" type="hidden" value="<cfoutput>#request.cwpage.adminSkuEditMode#</cfoutput>">
										<!--- the tab to return to when this form is submitted: changed dynamically when clicking on various tabs --->
										<input name="returnTab" class="returnTab" type="hidden" value="1">
									</form>
								</td>
							</tr>
						</table>
					</td>
				</tr>
			</cfloop>
			<!-- /end list vs. standard view --->
		</table>
	</cfif>
</cfif>
<!--- /end if we have SKUs --->
<!-- force the outer container open -->
<div class="clear"></div>