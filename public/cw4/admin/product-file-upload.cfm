<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: product-file-upload.cfm
File Date: 2012-08-25
Description: Uploads files to the appropriate server location and sets
the name of the file in the input of the sku form.
Included via iFrame into product-details.cfm sku file upload areas
Important Notes:
(CFFILE)
Some hosts choose to disable CFFILE functions.
If this is the case this upload page will not function and
files will have to be uploaded by other means.
==========================================================
--->
<!--- time out the page if it takes too long - avoid server overload --->
<cfsetting requesttimeout="9000">
<!--- max file size --->
<cfset maxSizeKB = application.cw.appDownloadsMaxKb>
<cfset MaxSize = MaxSizeKB * 1024>
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<cfinclude template="cwadminapp/func/cw-func-download.cfm">
<!--- default upload --->
<cfparam name="url.uploadSku" default="0">
<cfparam name="request.cwpage.skuID" default="#url.uploadSku#">
<cfparam name="request.cwpage.fileExtDirs" default="#application.cw.appDownloadsFileExtDirs#">
<cfparam name="request.cwpage.maskFilenames" default="#application.cw.appDownloadsMaskFilenames#">
<cfparam name="newFileName" default="">
<cfparam name="newFileID" default="">
<!--- file types to allow --->
<cfparam name="application.cw.appDownloadsFileTypes" default="">
<cfset request.cwpage.acceptedMimeList = 'application/octet-stream,' & trim(application.cw.appDownloadsFileTypes)>
<!--- handle errors and confirmations --->
<cfset request.uploadError = "">
<cfset request.uploadSuccess = "">
<!--- BASE URL --->
<!--- for this page the base url is the standard current page variable --->
<cfset request.cwpage.baseUrl = request.cw.thisPage & '?uploadSku=#request.cwpage.skuID#'>
<!--- function: create parent path based on download settings --->
<cfset request.fileParentPath = CWcreateDownloadPath()>
<!--- temp path --->
<cfset request.fileTempPath = request.fileParentPath & 'temp/'>

<!--- UPLOAD FILE --->
<cfif isDefined('form.frmAction') and form.frmAction is 'upload'>
	<!--- Check for file size as reported by the HTTP header--->
	<cfif cgi.content_length eq "">
		<cfset request.uploadError = "Your browser reported a badly-formed HTTP header. This could be caused by an error, a bug in your browser or the settings on your proxy/firewall">
	<cfelseif Val(cgi.content_length) gt MaxSize>
		<cfset request.uploadError = "The selected file's size is greater than " & MaxSizeKB & " kilobytes which is the maximum size allowed, please select another file or adjust your settings">
	</cfif>
	<!--- if no errors --->
	<cfif not len(trim(request.uploaderror))>
		<cftry>
			<!--- make the parent folder if not exists --->
			<cfif not directoryExists("#request.fileParentPath#")>
				<cfdirectory action="create" directory="#request.fileParentPath#">
			</cfif>
			<!--- put file in /temp/ directory --->
			<cfif not directoryExists("#request.fileTempPath#")>
				<cfdirectory action="create" directory="#request.fileTempPath#">
			</cfif>
			<!--- upload the file --->
			<cffile action="upload" filefield="skuFilename" destination="#request.fileTempPath#" nameconflict="makeunique" accept="#request.cwpage.acceptedMimeList#">
			<!--- if renamed at upload, renaming is automatic, show warning --->
			<cfif cffile.fileWasRenamed>
				<cfset request.uploadRenamed = 'Duplicate filename exists, file was renamed'>
			</cfif>
			<!--- clean up the filename --->
			<!--- replace whitespace characters with "-" --->
			<cfset newFilename = rereplace(cffile.serverfile,"[\s]","-","ALL")>
			<!--- remove apostrophes and other unwanteds, leave space , hyphen and dot --->
			<cfset newFilename = rereplace(newFilename,"[^a-zA-Z0-9-..]","","ALL")>
			<!--- the file extension --->
			<cfset fileExt = trim(listlast(newFileName,'.'))>
			<!--- set up file location --->
			<cfif request.cwpage.fileExtDirs and len(fileExt)>
				<cfset request.fileUploadPath = request.fileParentPath & fileExt>
				<!--- create needed directory if it doesn't already exist --->
				<cfif not directoryExists("#request.fileUploadPath#")>
					<cfdirectory action="create" directory="#request.fileUploadPath#">
				</cfif>
			<cfelse>
				<cfset request.fileUploadPath = request.fileParentPath>
			</cfif>
			<cfset request.fileUploadPath = cwTrailingChar(request.fileUploadPath)>

			<!--- if file with new name already exists, add datetimestamp to filename, show warning --->
			<cfif fileExists(request.fileUploadPath & newFileName) and not newFileName eq cffile.serverfile>
				<cfset request.uploadRenamed = 'Duplicate filename exists, file was renamed'>
				<cfset fileTimeStamp = dateformat(now(),'yyyymmdd') & timeformat(now(),'hhmmss')>
				<cfset newFilename = listFirst(newFilename,'.') & '-' & fileTimeStamp & '.' & fileExt>
			</cfif>
			<!--- file id --->
			<cfif request.cwpage.maskFilenames>
				<cfset newFileID = createUUID() & '.' & fileExt>
			<cfelse>
				<cfset newFileID = newFileName>
			</cfif>
			<!--- rename original if needed --->
			<cfif not newFileID eq cffile.serverfile>
				<cffile action="rename" destination="#request.fileTempPath##newFileID#" source="#request.fileTempPath##cffile.ServerFile#">
			</cfif>
			<!--- the raw, renamed file --->
			<cfset rawFile = "#request.fileTempPath##newFileID#">
			<!--- move file to final location --->
			<cffile action="move" destination="#request.fileUploadPath##newFileID#" source="#request.fileTempPath##newFileID#">
			<!--- if we still have no errors here, set up the confirmation --->
			<!--- if filename was changed, append show message --->
			<cfif isDefined('request.uploadRenamed')>
				<cfset request.uploadSuccess = request.uploadRenamed>
			<cfelse>
				<!--- if the file was uploaded without being changed --->
				<cfset request.uploadSuccess = "The file #newFileName# was uploaded">
			</cfif>
			<!--- add message to save changes --->
			<cfset request.uploadSuccess = request.uploadSuccess & '<br><em>Save SKU to apply file change</em>'>
			<cfset request.savedFileName = newFileName>
			<cfset request.uploadedFileName = newFileID>
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
				<cfif session.cw.debug>
					<div class="smallPrint"> Root Path: #request.fileUploadPath#<br>File ID: #newFileID#</div>
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
		<title>Product File Upload</title>
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
				<cfif isDefined('request.savedFileName') and len(trim(request.savedFileName))>
				// set up variables for the input on the calling page, and filename value to insert
				var callingInputID = '#sku_download_file-<cfoutput>#request.cwpage.skuID#</cfoutput>';
				var filenameString = '<cfoutput>#request.savedFileName#</cfoutput>';
				var callingDownloadInputID = '#sku_download_id-<cfoutput>#request.cwpage.skuID#</cfoutput>';
				var fileIDString = '<cfoutput>#request.uploadedFileName#</cfoutput>';
				// this function puts a value in a form element on the parent page
				var $insertFunction= function(elementVar,textVar){
				jQuery(elementVar,parent.document.body).val(textVar);
				};
				// call the function, insert the filename to the calling input
				$insertFunction(callingInputID,filenameString);
				$insertFunction(callingDownloadInputID,fileIDString);
			</cfif>
			// end parent input value
			});
		</script>
	</head>
	<body id="CWfileUploadWrap">
		<!--- if not submitting a form --->
		<cfif NOT isDefined('form.frmAction')>
			<!--- UPLOAD FORM --->
			<form name="CWfileUploadForm" id="CWfileUploadForm" action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" enctype="multipart/form-data" method="post">
				<table class="CWformTable narrow">
					<tr>
						<th class="label">Upload a File</th>
						<td>
							<input name="skuFileName" class="CWfileInput" id="newFileName" type="file">
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
			</cfif>
			<!--- /END error or success --->
		</cfif>
		<!--- /END if image was uploaded --->
	</body>
</html>