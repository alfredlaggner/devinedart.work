<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: product-image-upload.cfm
File Date: 2013-02-26
Description: Uploads images to the appropriate folders and sets
the name of the image in the input of the product form.
Included via iFrame into product-details.cfm image upload areas
Important Notes:
(CFFILE)
Some hosts choose to disable CFFILE functions.
If this is the case this upload page will not function and
images will have to be uploaded by other means.
(CFIMAGE / CF8)
The image resizing functionality requires ColdFusion 8 or higher.
==========================================================
--->
<!--- time out the page if it takes too long - avoid server overload --->
<cfsetting requesttimeout="9000">
<!--- max image size --->
<cfset maxSizeKB = application.cw.adminProductImageMaxKb>
<cfset MaxSize = MaxSizeKB * 1024>
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- set up the upload group to upload to --->
<cfparam name="url.uploadgroup" default="1" type="numeric">
<cfset request.cwpage.inputGroupNo = url.uploadgroup>
<!--- prefix for relative image path from admin to images dir (default "../") --->
<cfparam name="request.cwpage.adminImgPrefix" default="../">
<!--- file types to allow --->
<cfset request.cwpage.acceptedMimeList = "image/jpeg, image/pjpeg, image/jpg, image/png, image/gif">
<!--- handle errors and confirmations --->
<cfset request.uploadError = "">
<cfset request.uploadSuccess = "">
<!--- BASE URL --->
<!--- for this page the base url is the standard current page variable --->
<cfset request.cwpage.baseUrl = request.cw.thisPage & '?uploadGroup=#request.cwpage.inputGroupNo#'>
<!--- QUERY: get the list of image types for this group --->
<cfset getGroupTypes = CWquerySelectImageTypes(request.cwpage.inputGroupNo)>
<!--- set up base folder locations --->
<!--- parent URL must end with a trailing slash, i.e. "../Assets/" --->
<cfparam name="url.previewfolder" type="string" default="admin_preview">
<cfset request.imgParentUrl = "#request.cwpage.adminImgPrefix##application.cw.appImagesDir#/">
<cfset request.imgParentPath = expandPath(request.imgParentUrl)>
<cfset request.imgOrigPath = request.imgParentPath & 'orig/'>
<cfset request.imgPreviewPath = request.imgParentPath & 'admin_preview/'>
<cfset imgDir = request.imgParentUrl & '#url.previewfolder#/'>

<!--- UPLOAD IMAGE --->
<cfif isDefined('form.frmAction') and form.frmAction is 'upload'>
	<!--- Check for file size as reported by the HTTP header--->
	<cfif cgi.content_length eq "">
		<cfset request.uploadError = "Your browser reported a badly-formed HTTP header. This could be caused by an error, a bug in your browser or the settings on your proxy/firewall">
	<cfelseif Val(cgi.content_length) gt MaxSize>
		<cfset request.uploadError = "The selected file's size is greater than " & MaxSizeKB & " kilobytes which is the maximum size allowed, please select another image and try again">
	</cfif>
	<!--- if no errors --->
	<cfif not len(trim(request.uploaderror))>
		<cftry>
			<!--- make the orig folder if not exists --->
			<cfif not directoryExists("#request.imgOrigPath#")>
				<cfdirectory action="create" directory="#request.imgOrigPath#">
			</cfif>
			<!--- upload the file --->
			<cffile action="upload" filefield="imagefileName" destination="#request.imgOrigPath#" nameconflict="makeunique" accept="#request.cwpage.acceptedMimeList#">
			<!--- if renamed at upload, renaming is automatic, show warning --->
			<cfif cffile.fileWasRenamed>
				<cfset request.uploadRenamed = 'Duplicate filename exists, file was renamed'>
			</cfif>
			<!--- clean up the filename --->
			<!--- replace whitespace characters with "-" --->
			<cfset imgFilename = rereplace(cffile.serverfile,"[\s]","-","ALL")>
			<!--- remove apostrophes and other unwanteds, leave space , hyphen and dot --->
			<cfset imgFilename = rereplace(imgFilename,"[^a-zA-Z0-9-..]","","ALL")>
			<!--- if file with new name already exists, add datetimestamp to filename, show warning --->
			<cfif fileExists('#request.imgOrigPath##imgFilename#') and not imgFileName eq cffile.serverfile>
				<cfset request.uploadRenamed = 'Duplicate filename exists, file was renamed'>
				<cfset imgTimeStamp = dateformat(now(),'yyyyddmm') & timeformat(now(),'hhmmss')>
				<cfset imgFilename = listFirst(imgFilename,'.') & '-' & imgTimeStamp & '.' & listLast(imgFilename,'.')>
			</cfif>
			<!--- rename original if needed --->
			<cfif not imgFileName eq cffile.serverfile>
				<cffile action="rename" destination="#request.imgOrigPath##imgFilename#" source="#request.imgOrigPath##cffile.ServerFile#">
			</cfif>
			<!--- the raw, renamed file --->
			<cfset rawFile = "#request.imgOrigPath##imgFilename#">
			<!--- Start image processing --->
			<!--- get image info --->
			<cfimage
			action="info"
			source="#rawfile#"
			structname="imageInfo"
			>
			<!--- establish starting dimensions --->
			<cfset rawW = imageInfo.width>
			<cfset rawH = imageInfo.height>
			<!--- add the admin_preview image to the image types query --->
			<cfset addRow = queryAddRow(getGroupTypes,1)>
			<cfset addCell = querySetCell(getGroupTypes,'imagetype_folder','admin_preview')>
			<cfset addCell = querySetCell(getGroupTypes,'imagetype_max_width','160')>
			<cfset addCell = querySetCell(getGroupTypes,'imagetype_max_height','240')>
			<!--- loop image types, make sizes --->
			<cfloop query="getGroupTypes">
				<!--- invoke raw image as an image object --->
				<cfimage name="photoRead" action="read" source="#rawFile#">			
				<!--- establish destination dimensions --->
				<cfset newW = getGroupTypes.imagetype_max_width>
				<cfset newH = getGroupTypes.imagetype_max_height>
				<!--- cropping dimensions --->
				<cfset cropW = getGroupTypes.imagetype_crop_width>
				<cfset cropH = getGroupTypes.imagetype_crop_height>
				<!--- allow for null crop values (0 = no cropping) --->
				<cfif not isNumeric(cropW)><cfset cropW = 0></cfif>
				<cfif not isNumeric(cropH)><cfset cropH = 0></cfif>
				<!--- set destination folder --->
				<cfset imgFolder ="#request.imgParentPath##getGroupTypes.imagetype_folder#/">
				<!--- give the file object a full path --->
				<cfset newPhoto = imgFolder & imgFileName>
				<!--- make the folder if not exists --->
				<cfif not directoryExists(imgFolder)>
					<cfdirectory action="create" directory="#imgFolder#">
				</cfif>
				<!--- IMAGE MANIPULATION --->
				<!--- cropping --->
				<cfif (cropW gt 0 and cropW lt rawW) or (cropH gt 0 and cropH lt rawH)>
					<!--- scale down to  smaller dimension--->
					<cfif rawW lt rawH>
						<cfset scaleW = cropW>
						<cfset scaleH = 9999>
					<cfelse>
						<cfset scaleW = 9999>
						<cfset scaleH = cropH>
					</cfif>
					<!--- set to crop dimension by shorter side, to fill space --->
					<cfset imageScaleToFit(photoRead,scaleW,scaleH)>
					<!--- get info (w/h) for resized image --->
					<cfimage action="info" source="#photoRead#" structname="scaleInfo">
					<!--- find center of crop area --->
					<cfset centerX = scaleInfo.width/2>
					<cfset centerY = scaleInfo.height/2>
					<!--- find x/y for top left of crop selection --->
					<cfset cropX = centerX - cropW/2>
					<cfset cropY = centerY - cropH/2>
					<!--- crop image --->
					<cfset imageCrop(photoRead,cropX,cropY,cropW,cropH)>
					<!--- write image, set quality (higher than .95 makes a large file size)--->
					<cfset imageWrite(photoRead,newPhoto,.95)>
					<!--- resize (scale to fit) - make images smaller only, no stretching/enlarging --->
					<cfelseif newW lt rawW OR newH lt rawH>
					<!--- resize the image to fit in the specified dimensions --->
					<cfset imageScaleToFit(photoRead,newW,newH)>
					<!--- write image, set quality (higher than .95 makes a large file size)--->
					<cfset imageWrite(photoRead,newPhoto,.95)>
				<!--- if no size change --->
				<cfelse>
					<cffile action="copy" source="#rawfile#" destination="#newphoto#">
				</cfif>

			</cfloop>
			<!--- /END loop sizes --->
			<!--- if we still have no errors here, set up the confirmation --->
			<!--- if filename was changed, append show message --->
			<cfif isDefined('request.uploadRenamed')>
				<cfset request.uploadSuccess = request.uploadRenamed>
			<cfelse>
				<!--- if the file was uploaded withou being changed --->
				<cfset request.uploadSuccess = "The image #imgFileName# was uploaded">
			</cfif>
			<!--- add message to save changes --->
			<cfset request.uploadSuccess = request.uploadSuccess & '<br><em>Save Product to apply image change</em>'>
			<cfset request.uploadedImageUrl = imgDir & imgFileName>
			<cfset request.uploadedFileName = imgFileName>
			<!--- if errors, parse out the message --->
			<cfcatch>
				<cfsavecontent variable="request.uploadError">
				<cfoutput>Error : #cfcatch.message#
				<cfif len(trim(cfcatch.detail)) AND session.cw.debug>
					<div class="smallPrint">
						#cfcatch.detail#<br><br>
						#cfcatch.tagContext[1].template#, line #cfcatch.tagContext[1].line#
					</div>
				</cfif>
				</cfoutput>
				</cfsavecontent>
			</cfcatch>
		</cftry>
	</cfif>
	<!--- end if no errors --->
</cfif>
<!--- end upload action --->
</cfsilent>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head>
		<title>Product Image Upload</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<link href="css/cw-layout.css" rel="stylesheet" type="text/css">
		<link href="theme/<cfoutput>#application.cw.adminThemeDirectory#</cfoutput>/cw-admin-theme.css" rel="stylesheet" type="text/css">
		<!-- admin javascript -->
		<cfinclude template="cwadminapp/inc/cw-inc-admin-scripts.cfm">
		<!--- javascript --->
		<script type="text/javascript">
			jQuery(document).ready(function(){
				// show loading graphic when submit button clicked
				jQuery('#CWfileSubmit').click(function(){
				jQuery(this).parents('form').hide().siblings('#loadingGraphic').show();
				});
				// end show loading graphic
				// put the value in the related input on the calling page
				<cfif isDefined('request.uploadedFileName') and len(trim(request.uploadedFileName))>
				// set up variables for the input on the calling page, and filename value to insert
				var callingInputID = '#Image<cfoutput>#request.cwpage.inputGroupNo#</cfoutput>';
				var filenameString = '<cfoutput>#request.uploadedFileName#</cfoutput>';
				// this function puts a value in a form element on the parent page
				var $insertFunction= function(elementVar,textVar){
				jQuery(elementVar,parent.document.body).val(textVar);
				};
				// call the function, insert the filename to the calling input
				$insertFunction(callingInputID,filenameString);
			</cfif>
			// end parent input value
			});
		</script>
	</head>
	<body id="CWimageUploadWrap">
		<!--- if not submitting a form --->
		<cfif NOT isDefined('form.frmAction')>
			<!--- UPLOAD FORM --->
			<form name="CWimageUploadForm" id="CWimageUploadForm" action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" enctype="multipart/form-data" method="post">
				<table class="CWformTable narrow">
					<tr>
						<th class="label">Upload an Image</th>
						<td>
							<input name="imageFileName" class="CWfileInput" id="imageFileName" type="file">
							<!--- hidden field for processing --->
							<input type="hidden" name="frmAction" value="upload">
						</td>
					</tr>
				</table>
				<span>
					<input type="submit" name="CWfileSubmit" class="CWformButton" id="CWfileSubmit" value="Start Upload">
				</span>
			</form>
			<!-- hidden loading graphic -->
			<div id="loadingGraphic" style="display:none;padding:20px;">
				<img src="img/cw-loading-graphic.gif">
			</div>
			<!--- if the form was submitted --->
		<cfelse>
			<!--- if we have an error --->
			<cfif len(trim(request.uploadError))>
				<div class="alert"><cfoutput>#request.uploadError#</cfoutput><br><a href="<cfoutput>#request.cw.thisPage#</cfoutput>" class="resetUpload">Try Again</a></div>
				<!--- if no error --->
			<cfelseif len(trim(request.uploadSuccess))>
				<div class="alert confirm"><cfoutput>#request.uploadSuccess#</cfoutput></div>
				<cfoutput><img src="#request.uploadedImageUrl#" class="productImagePreview"></cfoutput>
			</cfif>
			<!--- /END error or success --->
		</cfif>
		<!--- /END if image was uploaded --->
	</body>
</html>