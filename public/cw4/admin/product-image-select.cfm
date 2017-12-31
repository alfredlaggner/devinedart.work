<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: product-image-select.cfm
File Date: 2012-05-01
Description: Allows preview/selection of images and sets
the name of the image in the records of the selected product.
Included via iFrame into product-details.cfm image upload areas
==========================================================
--->
<!--- time out the page if it takes too long - avoid server overload --->
<cfsetting requesttimeout="9000">
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- BASE URL --->
<!--- for this page the base url is the standard current page variable --->
<cfset request.cwpage.baseUrl = request.cw.thisPage>
<!--- set up the upload group to insert filename to --->
<cfparam name="url.uploadgroup" default="1" type="numeric">
<cfset request.groupNo = url.uploadgroup>
<!--- variable to show list of image thumbnails y/n --->
<!--- (note: the preview thumbnail is always shown on the product form) --->
<cfparam name="url.showimages" type="boolean" default="#application.cw.adminProductImageSelectorThumbsEnabled#">
<!--- set up base folder locations --->
<!--- parent URL must end with a trailing slash, i.e. "../Assets/" --->
<cfparam name="url.previewfolder" type="string" default="admin_preview">
<!--- list folder is passed in based on smallest image size from product form --->
<cfparam name="url.listfolder" type="string" default="admin_preview">
<cfset request.imgParentUrl = "#request.cwpage.adminImgPrefix##application.cw.appImagesDir#/">
<cfset request.imgParentPath = expandPath(request.imgParentUrl)>
<cfset request.imgSelectPath = request.imgParentPath & '#url.listfolder#/'>
<cfset imgDir = request.imgParentUrl & '#url.previewfolder#/'>
<!--- get images --->
<cfdirectory action="list" directory="#request.imgSelectPath#" name="SelectImageList">
</cfsilent>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head>
		<title>Product Image Selector</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<link href="css/cw-layout.css" rel="stylesheet" type="text/css">
		<link href="theme/<cfoutput>#application.cw.adminThemeDirectory#</cfoutput>/cw-admin-theme.css" rel="stylesheet" type="text/css">
		<!-- admin javascript -->
		<cfinclude template="cwadminapp/inc/cw-inc-admin-scripts.cfm">
		<!--- javascript --->
		<script type="text/javascript">
		jQuery(document).ready(function(){
		// set up referring image function
			var callingInputID = '#Image<cfoutput>#request.groupNo#</cfoutput>';
			// this function puts a value in an element on the parent page
			var $insertFunction= function(elementVar,textVar){
			//debug: alert text to insert, or element being targeted
			//alert(elementVar);
			//alert(textVar);
			jQuery(elementVar,parent.document.body).val(textVar);
			};
		// end referring input function

		// select image from list (dropdown)
		jQuery('#imageSelect').change(function(){
			var filenameString = jQuery(this).attr('value');
			var showImgUrl = '<cfoutput>#imgDir#</cfoutput>' + filenameString;
			// call the function, insert the filename to the calling input
			$insertFunction(callingInputID,filenameString);
			// show the image
			jQuery('#selectPreviewImg').show().attr('src',showImgUrl).attr('alt',showImgUrl);
		});
		// end select image list
		<cfif url.showimages>
				// select image link
				jQuery('#imageListTableWrap a.imgSelect').click(function(){
				var filenameString = jQuery(this).attr('href');
				var showImgUrl = '<cfoutput>#imgDir#</cfoutput>' + filenameString;
				// call the function, insert the filename to the calling input
				$insertFunction(callingInputID,filenameString);
				jQuery(this).parents('tr').addClass('currentImg').siblings('tr').removeClass('currentImg');
				return false;
				});
				// end select image link
				// image search box
				jQuery('#imageSearchBox').keyup(function(){
				// use lowercase version of input string, to match classes on table rows (see 'tr' below)
				var searchText = jQuery(this).val().toLowerCase();
				// if blank, show all rows again
				if (searchText == ''){
				jQuery('#imageListTable tr').show().removeClass('currentImg');
				}
				// or filter all rows
				else
				{
				// hide all rows, show the rows that match
				jQuery('#imageListTable tr').hide().removeClass('currentImg');
				jQuery("#imageListTable tr[class*='"+searchText+"']").show().removeClass('currentImg');
				}
				});
				// end image search
				// clicking anywhere in row same as clicking link
				jQuery('#imageListTable tr td').click(function(){
				jQuery(this).children('a:first').click();
				});
				// end click anywhere in row
				// image size links
				jQuery('#imgSizeControlUp').click(function(){
				var sizeTo = jQuery(this).attr('rel');
				jQuery('#imageListTableWrap a.imgSelect img').css('max-width', sizeTo + 'px').parents('td').css('width',sizeTo + 'px');
				if (sizeTo <= 160) {
				jQuery('#imgSizeControlDown').attr('rel',sizeTo/2);
				};
				if (sizeTo < 160){
				var altSize = sizeTo * 2;
				jQuery(this).attr('rel',altSize);
				};
				return false;
				});
				jQuery('#imgSizeControlDown').click(function(){
				var sizeTo = jQuery(this).attr('rel');
				jQuery('#imageListTableWrap a.imgSelect img').css('max-width', sizeTo + 'px').parents('td').css('width',sizeTo + 'px');
				if (sizeTo > 20) {
				jQuery('#imgSizeControlUp').attr('rel',sizeTo);
				};
				if (sizeTo > 20){
				var altSize = sizeTo / 2;
				jQuery(this).attr('rel',altSize);
				};
				return false;
				});
				// end image size links
			</cfif>
			// toggle between list or table view
			jQuery('#showImgTableLink').click(function(){
			jQuery('#imageSelectWrap').hide();
			jQuery('#imageSearchWrap').show();
			jQuery('#imageListTableWrap').show();
			return false;
			});
			jQuery('#showImgListLink').click(function(){
			jQuery('#imageSelectWrap').show();
			jQuery('#imageSearchWrap').hide();
			jQuery('#imageListTableWrap').hide();
			return false;
			});
			// end toggle list/table
			
			});
		</script>
	</head>
	<body id="CWimageSelectWrap">
		<p>Select an Image <cfif session.cw.debug><span class="smallPrint">Directory: <cfoutput>#imgDir#</cfoutput></span></cfif></p>
		<!--- SELECT LIST --->
		<form id="CWimageSelectForm" name="CWimageSelectForm" onsubmit="return false">
			<!-- image selector -->
			<span id="imageSelectWrap" <cfif url.showimages>style="display:none;"</cfif>>
				Choose:
				<select id="imageSelect" name="imageSelect" onkeyup="this.blur();this.focus();">
					<cfoutput query="selectImageList">
					<cfif type eq "File" and isImageFile(expandpath('#imgDir##name#'))
						AND (not isDefined('application.cw.appImageDefault') OR (not name eq application.cw.appImageDefault))>
						<option value="#name#">#name#</option>
					</cfif>
					</cfoutput>
				</select>
				<cfif url.showimages>
					&nbsp;&nbsp;<a class="smallPrint" id="showImgTableLink" href="##">Show Images</a>
				</cfif>
				<!--- the preview image --->
				<div>
					<cfoutput><img src="" alt="" class="productImagePreview" id="selectPreviewImg" style="display:none;"></cfoutput>
				</div>
			</span>
			<!-- image search, hidden on load -->
			<span id="imageSearchWrap" <cfif NOT url.showimages>style="display:none;"</cfif>>
				Size:&nbsp;&nbsp;&nbsp;<a href="#" rel="80" id="imgSizeControlUp"><img src="img/cw-size-up.png" alt="enlarge images"></a>
				&nbsp;<a rel="20" href="#" id="imgSizeControlDown"><img src="img/cw-size-down.png" alt="reduce images"></a>
				&nbsp;&nbsp;&nbsp;&nbsp;Search: <input id="imageSearchBox" name="imageSearchBox" size="15" value="">
				&nbsp;&nbsp;<a class="smallPrint" id="showImgListLink" href="##">Simple List</a>
			</span>
		</form>
		<!--- TABLE with thumbnails --->
		<div id="imageListTableWrap" <cfif NOT url.showimages>style="display:none;"</cfif>>
			<table class="CWformTable narrow" id="imageListTable">
				<cfoutput query="selectImageList">
				<cfif type eq "File" and isImageFile(expandpath('#imgDir##name#'))
					AND (not isDefined('application.cw.appImageDefault') OR (not name eq application.cw.appImageDefault))>
					<!-- row has class matching lower-case value of image name -->
					<tr class="#lcase(name)#">
						<td style="width:40px;">
							<a class="imgSelect" href="#name#">
							<img src="#imgDir##name#" alt="#name#"></a>
						</td>
						<td style="padding:3px 10px;">
							<a class="imgSelect" href="#name#">#name#</a>
						</td>
					</tr>
				</cfif>
				</cfoutput>
			</table>
		</div>
		<!-- hidden loading graphic -->
		<div id="loadingGraphic" style="display:none;padding:20px;">
			<img src="img/cw-loading-graphic.gif">
		</div>
	</body>
</html>