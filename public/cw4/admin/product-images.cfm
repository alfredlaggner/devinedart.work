<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: product-images.cfm
File Date: 2013-02-10
Description: Handles image file viewing and management
Note:
CW stores a default preview thumbnail in the admin_preview folder
This is the directory we search for the list below. A different directory
may be passed in via the url.
Original images are stored in /orig/ - if size or storage are a concern,
these can be safely deleted via FTP with no harm to this page's functions
==========================================================
--->
<!--- time out the page if it takes too long - avoid server overload --->
<cfsetting requesttimeout="9000">
<!--- GLOBAL INCLUDES --->
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("manager,merchant,developer")>
<!--- ADMIN CONTROLS --->
<cfparam name="request.cwpage.imageTypeDelete" default="false">	
<!--- PAGE PARAMS --->
<cfparam name="application.cw.adminProductPaging" default="1">
<cfparam name="application.cw.adminRecordsPerPage" default="30">
<cfparam name="url.sortby" type="string" default="imagetype_sortorder">
<cfparam name="url.sortdir" type="string" default="asc">
<!--- interface mode (list|type) --->
<cfparam name="url.mode" default="list">
<!--- default values for seach/sort--->
<cfparam name="url.pagenumresults" type="integer" default="1">
<cfparam name="url.search" type="string" default="">
<cfparam name="url.find" type="string" default="">
<cfparam name="url.maxrows" type="numeric" default="#application.cw.adminRecordsPerPage#">
<cfparam name="url.sortby" type="string" default="fileName">
<cfparam name="url.sortdir" type="string" default="asc">
<!--- defaults for add new type --->
<cfparam name="url.name" default="">	
<cfparam name="url.width" default="0">	
<cfparam name="url.height" default="0">	
<cfparam name="url.folder" default="">	
<!--- default values for display --->
<cfparam name="ImagePath" default="">
<cfparam name="ImageSRC" default="">
<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,pagenumresults,userconfirm,useralert,dellist,delidle,delorig,delall,userid,mode,addgroup,deltype,delgroup,addto,width,height,name,folder")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
<!--- image types only available to developer --->
<cfif url.mode is 'type' and session.cw.accessLevel is not 'developer'>
	<cflocation url="#request.cwpage.baseUrl#mode=list" addtoken="no">
</cfif>
<!--- link for mode switch --->
<cfparam name="request.cwpage.viewLink" default="">
<!--- PROCESSING FOR PAGE MODE --->
<cfswitch expression="#url.mode#">
	<!--- IMAGE TYPES/SIZES --->
	<cfcase value="type">
	<!--- QUERY: get all image types --->
	<cfset imageTypesQuery = CWquerySelectImageTypes()>
		<cfset request.cwpage.subhead = 'Manage image sizes &amp; dimensions'>
		<cfset request.cwpage.viewLink='<a href="#request.cwpage.baseUrl#&mode=list">View Image List</a> <a href="config-settings.cfm?group_ID=14">Global Image Settings</a>'>
		<cfset request.cwpage.groupCt = arrayMax(listToArray(valueList(imageTypesQuery.imagetype_upload_group)))>
		<!--- /////// --->
		<!--- UPDATE IMAGE TYPES  --->
		<!--- /////// --->
		<cfif isDefined('form.imagetype_idlist') and listLen(form.imagetype_idlist)>
			<cfset loopCt = 1>
			<cfset updateCt = 0>
			<cfloop list="#form.imagetype_idlist#" index="id">
			<!--- verify numeric sort order --->
			<cfif NOT isNumeric(#form["imagetype_sortorder#loopCt#"]#)>
				<cfset #form["imagetype_sortorder#loopCt#"]# = 0>
			</cfif>
			<!--- QUERY: update imagetype record --->
			<cftry>
			<!--- clean up folder name --->
			<cfset cleanFolder = rereplace(form["imagetype_folder#loopCt#"],"[^a-zA-Z0-9_]","_","ALL")>
			<cfset cleanFolder = rereplace(cleanFolder,"[\s]","_","ALL")>
			<cfset updateType = CWqueryUpdateImageType(
					imagetype_id = #form["imagetype_id#loopCt#"]#,
					imagetype_upload_group = #form["imagetype_upload_group#loopCt#"]#,
					imagetype_sortorder = #form["imagetype_sortorder#loopCt#"]#,
					imagetype_max_width = #form["imagetype_max_width#loopCt#"]#,
					imagetype_max_height = #form["imagetype_max_height#loopCt#"]#,
					imagetype_name = '#form["imagetype_name#loopCt#"]#',
					imagetype_folder = cleanFolder
					)>
			<cfset updateCt = updateCt + 1>
			<!--- handle errors --->
			<cfcatch>
				<cfset CWpageMessage("alert","Image Type Update Error #cfcatch.detail#")>
			</cfcatch>
			</cftry>
			<cfset loopCt = loopCt + 1>
			</cfloop>
			<!--- get the vars to keep by omitting the ones we don't want repeated --->
			<cfset varsToKeep = CWremoveUrlVars("userconfirm,useralert")>
			<!--- set up the base url --->
			<cfset request.cwpage.relocateUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>
			<!--- return to page as submitted, clearing form scope --->
			<cflocation url="#request.cwpage.relocateUrl#&userconfirm=#CWurlSafe('Changes Saved')#&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
		</cfif>
		<!--- /////// --->
		<!--- /END UPDATE IMAGE TYPES  --->
		<!--- /////// --->
		<!--- /////// --->
		<!--- NEW IMAGE GROUP --->
		<!--- /////// --->
		<cfif isDefined('url.addgroup') and url.addgroup is 1>
			<cfset request.cwpage.newGroupID = request.cwpage.groupCt + 1>
			<!--- duplicate group 1 image settings --->
			<cfquery dbtype="query" name="initGroupQuery">
			SELECT *
			FROM imageTypesQuery
			WHERE imagetype_upload_group = 1
			ORDER BY imagetype_id
			</cfquery>
			<cfoutput query="initGroupQuery">
				<cfif not isNumeric(imagetype_max_width)><cfset imagetype_max_width = 0></cfif>
				<cfif not isNumeric(imagetype_max_height)><cfset imagetype_max_height = 0></cfif>
				<cfif not isNumeric(imagetype_crop_width)><cfset imagetype_crop_width = 0></cfif>
				<cfif not isNumeric(imagetype_crop_height)><cfset imagetype_crop_height = 0></cfif>
				<cfset insertType = CWqueryInsertImageType(request.cwpage.newGroupID,imagetype_name,imagetype_sortorder,imagetype_folder,imagetype_max_width,imagetype_max_height,imagetype_crop_width,imagetype_crop_height,imagetype_user_edit)>
			</cfoutput>
			<!--- refresh page to avoid duplication --->
			<cfset CWpageMessage("confirm","Image Upload Group Added")>
			<cflocation url="#request.cwpage.baseUrl#&mode=type&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
		</cfif>
		<!--- /////// --->
		<!--- /END NEW IMAGE GROUP --->
		<!--- /////// --->		
		<!--- /////// --->
		<!--- DELETE IMAGE GROUP --->
		<!--- /////// --->
		<cfif isDefined('url.delgroup') and isNumeric(url.delgroup) and url.delgroup gt 1>
			<cfset delTypesQuery = CWquerySelectImageTypes(url.delgroup)>
			<cfoutput query="delTypesQuery">
				<!--- remove all types in this group, and associated image relationships --->
				<cfset delType = CWqueryDeleteImageType(delTypesQuery.imagetype_id,true)>
			</cfoutput>
			<!--- refresh page to avoid duplication --->
			<cfset CWpageMessage("confirm","Image Upload Group Deleted")>
			<cflocation url="#request.cwpage.baseUrl#&mode=type&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
		</cfif>
		<!--- /////// --->
		<!--- /END DELETE IMAGE GROUP --->
		<!--- /////// --->
		<!--- /////// --->
		<!--- DELETE IMAGE TYPE --->
		<!--- /////// --->
		<cfif isDefined('url.deltype') and isNumeric(url.deltype) and url.deltype gt 1>
			<!--- remove this image type, and associated image relationships --->
			<cfset delType = CWqueryDeleteImageType(url.deltype,true)>
			<!--- refresh page to avoid duplication --->
			<cfset CWpageMessage("confirm","Image Type Deleted")>
			<cflocation url="#request.cwpage.baseUrl#&mode=type&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
		</cfif>
		<!--- /////// --->
		<!--- /END DELETE IMAGE TYPE--->
		<!--- /////// --->
		<!--- /////// --->
		<!--- ADD IMAGE TYPE--->
		<!--- /////// --->
		<cfif isDefined('url.addto') and isNumeric(url.addto) and listFind(valueList(imageTypesQuery.imagetype_id),url.addto)>
			<cfif url.width gt 0 and url.height gt 0 and len(trim(url.folder)) and len(trim(url.name))>
				<!--- clean up folder name --->
				<cfset cleanFolder = rereplace(url.folder,"[^a-zA-Z0-9_]","_","ALL")>
				<cfset cleanFolder = rereplace(cleanFolder,"[\s]","_","ALL")>
				<!--- add type to group --->
				<cfset addType = CWqueryInsertImageType(url.addto,url.name,0,cleanFolder,url.width,url.height,0,0)>
				<!--- refresh page to avoid duplication --->
				<cfset CWpageMessage("confirm","Image Type Added")>
				<cflocation url="#request.cwpage.baseUrl#&mode=type&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#" addtoken="no">
			<cfelse>
				<cfset CWpageMessage("alert","Error: all values must be provided")>
				<cflocation url="#request.cwpage.baseUrl#&mode=type&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
			</cfif>

		</cfif>
		<!--- /////// --->
		<!--- /END ADD IMAGE TYPE--->
		<!--- /////// --->
	</cfcase>
	<cfdefaultcase>
	<!--- LIST VIEW --->
		<!--- variable to show image thumbnails in list view --->
		<cfparam name="url.showimages" type="boolean" default="#application.cw.adminProductImageSelectorThumbsEnabled#">
		<!--- set up base folder locations --->
		<!--- use this directory to show image preview in list --->
		<cfparam name="url.previewfolder" type="string" default="admin_preview">
		<!--- use this directory to link to original uploaded files  --->
		<cfset request.origFolder = "orig">
		<!--- list folder can be passed in through URL: CW uses the default 'admin preview' to check all images --->
		<cfparam name="url.listfolder" type="string" default="admin_preview">
		<!--- parent URL must end with a trailing slash, i.e. "#request.cwpage.adminImgPrefix##application.cw.appImagesDir#/" --->
		<cfset request.imgParentUrl = "#request.cwpage.adminImgPrefix##application.cw.appImagesDir#/">
		<cfset request.imgParentPath = expandPath(request.imgParentUrl)>
		<!--- the directory to pull preview images from --->
		<cfset request.imgPreviewDir = request.imgParentUrl & '#url.previewfolder#/'>
		<!--- the folder to look at to build our list --->
		<cfset request.imgListPath = request.imgParentPath & '#url.listfolder#/'>
		<!--- the folder to look in for original images --->
		<cfset request.imgOrigPath = request.imgParentPath & '#request.origfolder#/'>
		<!--- the directory to pull original images from --->
		<cfset request.imgOrigDir = request.imgParentUrl & '#request.origFolder#/'>
		<!--- QUERY: get Images in specified preview directory --->
		<cfdirectory action="list" directory="#request.imgListPath#" name="imagesQuery">
		<!--- QUERY: get Images in specified original directory --->
		<cfdirectory action="list" directory="#request.imgOrigPath#" name="origQuery">
		<!--- QUERY: get All active filenames related to any product --->
		<cfset productImagesQuery = CWquerySelectProductImages()>
		<!--- QUERY: get only unique preview filenames --->
		<cfquery dbtype="query" name="imagesQuery">
		SELECT *
		FROM imagesQuery
		WHERE NOT name = '#application.cw.appImageDefault#'
		</cfquery>
		<!--- QUERY: get only unique original filenames --->
		<cfquery dbtype="query" name="origQuery">
		SELECT *
		FROM origQuery
		WHERE NOT name = '#application.cw.appImageDefault#'
		</cfquery>
		<!--- QUERY: get only unique image filenames --->
		<cfquery dbtype="query" name="usedImagesQuery">
		SELECT DISTINCT product_image_filename
		FROM productImagesQuery
		</cfquery>
		<!--- set up lists of filenames used for output --->
		<cfset request.cwpage.allFileNames = valueList(imagesQuery.name)>
		<cfset request.cwpage.origFileNames = valueList(origQuery.name)>
		<cfset request.cwpage.usedFileNames = ''>
		<cfset request.cwpage.idleFileNames = ''>
		<!--- set up lists of user levels that can delete originals --->
		<cfset request.cwpage.deleteOrigLevels = 'developer'>
		<cfif isDefined('application.cw.adminImagesMerchantDeleteOrig') and application.cw.adminImagesMerchantDeleteOrig is true>
			<cfset request.cwpage.deleteOrigLevels = listAppend(request.cwpage.deleteOrigLevels,'merchant')>
		</cfif>
		<!--- create our display query w/ image and product info --->
		<cfset imageInfoQuery = queryNew("fileName,fileDate,origSrc,origSize,origUrl,previewUrl,fileProducts,fileInUse","varchar,date,varchar,decimal,varchar,varchar,varchar,bit")>
		<!--- loop the cfdirectory and insert specific info --->
		<cfoutput query="imagesQuery">
		<!--- only deal with known file types, and protect default image --->
		<cfif listFindNoCase('jpg,jpeg,pjpeg,pjpg,gif,png,tiff,bmp',listLast(name,'.'))
			AND (not isDefined('application.cw.appImageDefault') OR name neq application.cw.appImageDefault)>
			<!--- set up some info about this image --->
			<cfset img.fileName = name>
			<cfset img.fileDate = datelastModified>
			<cfset img.previewFileSize = numberFormat(size/1000,'_.__')&'&nbsp;kb'>
			<!--- if the original image exists --->
			<cfif listFindNoCase(request.cwpage.origFileNames, img.filename)>
				<!--- get info about original --->
				<cfset img.origSrc = "#request.imgOrigPath##img.filename#">
				<cfset img.origSize = getFileInfo(img.origSrc).size>
				<cfset img.origUrl = "#request.imgOrigDir##img.filename#">
			<cfelse>
				<cfset img.origSrc = "">
				<cfset img.origSize = "">
				<cfset img.origUrl = "">
			</cfif>
			<!--- set up preview url --->
			<cfset img.previewUrl = "#request.imgPreviewDir##img.filename#">
			<!--- end original image info --->
			<!--- is the image in use? --->
			<cfset img.fileProducts = ''>
			<cfif listFindNoCase(valueList(usedImagesQuery.product_image_filename), img.filename)>
				<cfset img.inUse = true>
				<!--- if so get the products it is being used on --->
				<cfquery dbtype="query" name="imageProds">
				SELECT DISTINCT product_image_product_id as prodID
				FROM productImagesQuery
				WHERE product_image_filename = '#img.filename#'
				</cfquery>
				<!--- get the names for each product ID found --->
				<cfloop list="#valueList(imageProds.prodID)#" index="pp">
					<cfset prodQuery = CWquerySelectProductDetails(pp)>
					<cfset img.fileProducts = listAppend(img.fileProducts,'#pp#|#prodQuery.product_name#')>
				</cfloop>
				<cfset request.cwpage.usedFileNames = listAppend(request.cwpage.usedFileNames,img.fileName)>
				<!--- if not in use --->
			<cfelse>
				<cfset img.inUse = false>
				<cfset request.cwpage.idleFileNames = listAppend(request.cwpage.idleFileNames,img.fileName)>
			</cfif>
			<!--- end if in use --->
			<!--- add data to display query --->
			<cfset temp = queryAddRow(imageInfoQuery)>
			<cfset temp = querySetCell(imageInfoQuery,'fileName',img.fileName)>
			<cfset temp = querySetCell(imageInfoQuery,'fileDate',img.fileDate)>
			<cfset temp = querySetCell(imageInfoQuery,'origSrc',img.origSrc)>
			<cfset temp = querySetCell(imageInfoQuery,'origsize',img.origSize)>
			<cfset temp = querySetCell(imageInfoQuery,'origUrl',img.origUrl)>
			<cfset temp = querySetCell(imageInfoQuery,'previewUrl',img.previewUrl)>
			<cfset temp = querySetCell(imageInfoQuery,'fileProducts',img.fileProducts)>
			<cfset temp = querySetCell(imageInfoQuery,'fileInUse',img.inUse)>
		</cfif>
		<!--- /end file type check --->
		</cfoutput>
		<!--- end create info query --->
		<!--- QUERY: make sortable --->
		<cfset imageInfoQuery = CWsortableQuery(imageInfoQuery)>
		<!--- /////// --->
		<!--- DELETE IMAGES --->
		<!--- /////// --->
		<cfset request.cwpage.deleteList = ''>
		<!--- delete by form --->
		<cfparam name="form.dellist" default="">
		<cfif isDefined('form.deleteSelected') and form.deleteSelected eq cookie.cftoken>
			<cfset request.cwpage.deleteList = trim(form.dellist)>
		</cfif>
		<!--- delete unused / original --->
		<cfparam name="url.delidle" default="">
		<cfparam name="url.delorig" default="">
		<cfparam name="url.userid" default="">
		<!--- verify user posting the url is the user logged in --->
		<cfif url.delidle is 'true' and url.userid eq cookie.cftoken>
			<cfset request.cwpage.deleteList = request.cwpage.idleFileNames>
		</cfif>
		<cfif url.delorig is 'true' and url.userid eq cookie.cftoken>
			<cfset request.cwpage.deleteList = request.cwpage.origFileNames>
		</cfif>
		<!--- delete ALL - only for developer --->
		<cfparam name="url.delall" default="">
		<cfparam name="url.userid" default="">
		<!--- verify user posting the url is the user logged in --->
		<cfif listFindNoCase('merchant,developer',request.cwpage.accessLevel)
			AND url.delall is 'true'
			AND url.userid eq cookie.cftoken>
			<cfset request.cwpage.deleteList = request.cwpage.allFileNames>
		</cfif>
		<!--- if we have a list of at least one filename --->
		<cfif len(trim(request.cwpage.deletelist))>
			<!--- if deleting only originals (delorig) --->
			<cfif url.delorig is 'true'>
				<cfset dirsList = request.origFolder>
				<!--- if deleting from all locations (standard delete) --->
			<cfelse>
				<!--- set up the list of directories to delete from --->
				<!--- get all image directories --->
				<cfset imgDirsQuery = CWquerySelectImageTypes()>
				<!--- get unique list of folder names --->
				<cfquery name="imgDirs" dbtype="query">
					SELECT DISTINCT imagetype_folder
					FROM imgDirsQuery
				</cfquery>
				<!--- set up list of directories to look in --->
				<cfset dirsList = valueList(imgDirs.imagetype_folder)>
				<!--- add  our defaults for original and preview images --->
				<cfset dirsList = listAppend(dirsList, '#request.origFolder#,#url.previewfolder#')>
			</cfif>
			<cfset delCt = 0>
			<cfloop list="#request.cwpage.deleteList#" index="dd">
				<cftry>
					<cfset delFile = trim(dd)>
					<!--- don't allow default file to be deleted --->
					<cfif NOT isDefined('application.cw.appImageDefault')
						OR application.cw.appImageDefault neq delFile>
						<!--- delete the actual files from the server --->
						<cfloop list="#dirsList#" index="ff">
							<!--- set up the image file to delete --->
							<cfset delSrc = request.imgParentPath & ff & '/' &  dd>
							<!--- if the file exists, delete it --->
							<cfif fileExists(delSrc)>
								<cffile action="delete" file="#delSrc#">
							</cfif>
						</cfloop>
					</cfif>
					<!--- / end protect default file --->
					<!--- delete all rel product/image records with this filename --->
					<!--- not if deleting only originals (delorig) --->
					<cfif not  url.delorig is 'true'>
						<cfset deleteImgFileRel = CWqueryDeleteProductImageFile(dd)>
					</cfif>
					<cfset delCt = delCt + 1>
					<!--- handle errors --->
					<cfcatch>
						<cfset CWpageMessage("alert","Error: #cfcatch.message# #cfcatch.detail#")>
					</cfcatch>
				</cftry>
			</cfloop>
			<cfif delCt gt 0>
				<cfif delCt is 1><cfset s = ''><cfelse><cfset s = 's'></cfif>
				<cfset CWpageMessage("confirm","#delCt# image#s# deleted")>
				<cflocation url="#request.cwpage.baseUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
			</cfif>
		</cfif>
		<!--- /////// --->
		<!--- /END DELETE IMAGES --->
		<!--- /////// --->
		<!--- SUBHEADING --->
		<cfsavecontent variable="request.cwpage.subhead">
		<cfoutput>
		Images Uploaded: #imagesQuery.recordCount#&nbsp;&nbsp;
		In Use: #listLen(request.cwpage.usedFileNames)#&nbsp;&nbsp;
		Not In Use: #listLen(request.cwpage.idleFileNames)#&nbsp;&nbsp;
		</cfoutput>
		</cfsavecontent>
		<!--- link to edit image types --->
		<cfif session.cw.accessLevel is 'developer'>
			<cfset request.cwpage.viewLink='<a href="#request.cwpage.baseUrl#&mode=type">Manage Image Sizes &amp; Upload Options</a>'>
		</cfif>
	<!--- /end list view --->
	</cfdefaultcase>
</cfswitch>
<!--- /end mode --->
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Manage Product Images">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "Image Management">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = request.cwpage.subhead>
<!--- current menu marker --->
<cfif url.mode is 'list'>
	<cfset request.cwpage.currentNav = 'product-images.cfm'>
<cfelse>
	<cfset request.cwpage.currentNav = 'product-images.cfm?mode=#url.mode#'>
</cfif>
<!--- load form scripts --->
<cfset request.cwpage.isFormPage = 1>
<!--- load table scripts --->
<cfset request.cwpage.isTablePage = 1>
</cfsilent>
<!--- START OUTPUT --->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head>
		<cfoutput>
		<title>#application.cw.companyName# : #request.cwpage.title#</title>
		</cfoutput>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<!-- admin styles -->
		<link href="css/cw-layout.css" rel="stylesheet" type="text/css">
		<link href="theme/<cfoutput>#application.cw.adminThemeDirectory#</cfoutput>/cw-admin-theme.css" rel="stylesheet" type="text/css">
		<!-- admin javascript -->
		<cfinclude template="cwadminapp/inc/cw-inc-admin-scripts.cfm">
		<!--- fancybox --->
		<link href="js/fancybox/jquery.fancybox.css" rel="stylesheet" type="text/css">
		<script type="text/javascript" src="js/fancybox/jquery.fancybox.pack.js"></script>
		<!--- PAGE JAVASCRIPT --->
		<script type="text/javascript">
			// this takes the ID of a checkbox, the number to show in the alert
			function confirmDelete(boxID,prodCt){
			// if this cat has products
				if (prodCt > 0){
					if (prodCt > 1){var prodWord = 'products'}else{var prodWord = 'product'};
				var confirmBox = '#'+ boxID;
					// if the box is checked and prodToggle is true
					if( jQuery(confirmBox).is(':checked') ){
					clickConfirm = confirm("Warning: image in use!\nThis image will be unassigned for " + prodCt + " " + prodWord + ".\nContinue?");
					// if confirm is returned false
					if(!clickConfirm){
						jQuery(confirmBox).prop('checked','');
					};

					};
					// end if checked
				};
				// end if prodct
			};

// alert for delete selected button
	function warn() {
	    var deleteBoxes = jQuery('input[name^="dellist"]');
	    var numberChecked = 0;
	    for (var i=0; i<deleteBoxes.length; i++) {
	         if (deleteBoxes[i].checked) { numberChecked += 1; }
	    }
	    if (numberChecked > 0){
	    			if (numberChecked > 1){var fileWord = 'files'}else{var fileWord = 'file'};
	    return confirm("Delete " + numberChecked+ " " + fileWord + " and unassign for all products?");
	    }else{
	    alert('No files selected');
	    return false;
	    }
	};
// end script

// page jQuery
jQuery(document).ready(function(){
	// fancybox
		jQuery('a.zoomImg').each(function(){
			jQuery(this).fancybox({
			'titlePosition': 'inside',
			'padding': 3,
			'overlayShow': true,
			'showCloseButton': true,
			'hideOnOverlayClick':true,
			'hideOnContentClick': true
			});
		});
// containsNoCase function courtesy Rick Strahl:
// http://www.west-wind.com/weblog/posts/519980.aspx
$.expr[":"].containsNoCase = function(el, i, m) {
    var search = m[3];
    if (!search) return false;
    return eval("/" + search + "/i").test(jQuery(el).text());
};
// image search box
jQuery('#imageSearchBox').keyup(function(){
// use lowercase version of input string, to match classes on table rows (see 'tr' below)
var searchText = jQuery(this).val().toLowerCase();
// if blank, show all rows again
if (searchText == ''){
jQuery('#imageControlTable tbody tr').show();
}
// or filter all rows
else
{
// hide all rows, show the rows that match
jQuery('#imageControlTable tbody tr').hide();
// works for matching text or class
jQuery("#imageControlTable tbody tr:containsNoCase('"+searchText+"')").show();
//jQuery("#imageControlTable tbody tr:containsNoCase('"+ jQuery(this).val()+"')").show();
jQuery("#imageControlTable tbody tr[class*='"+ jQuery(this).val()+"']").show();
jQuery("#imageControlTable tbody tr a:containsNoCase('"+ jQuery(this).val()+"')").parents('tr').show();
}
});
// end image search

// add new type row
jQuery("tr.addTypeRow").hide();
jQuery("a.CWaddShowLink").click(function(){
	var tableID = jQuery(this).attr('rel');
	var relRow = 'table#' + tableID + ' tr.addTypeRow';
	jQuery(this).hide();
	jQuery(relRow).show();
	return false;
	});
// add new type submit link
jQuery("a.CWaddTypeLink").click(function(){
	var n = jQuery(this).attr('rel');
	var name = jQuery('#imagetype_name_new' + n).val();
	var width = jQuery('#imagetype_max_width_new' + n).val();
	var height = jQuery('#imagetype_max_height_new' + n).val();
	var folder = jQuery('#imagetype_folder_new' + n).val();
	var base = '<cfoutput>#request.cwpage.baseUrl#</cfoutput>&mode=type';
	var newStr = '';
	newStr = base + '&addto=' + n + '&name=' + name + '&width=' + width + '&height=' + height + '&folder=' + folder; 
	window.location.replace(newStr);
	return false;
	});
	// prevent submission on some fields with enter key
	$('.noSubmit').keypress(function(e){
	    if ( e.which == 13 ) {
	    	$(this).parents('td').siblings('td').find('a.CWaddTypeLink').trigger('click');
	    	}
	    //or...
	    if ( e.which == 13 ) e.preventDefault();
	});
	// warn about folder name changes
	$('.folderName').one("focus",function(){
		alert('Changing folder name can have undesired effects. Proceed with caution.');
		return false;
		});
});
// end script
</script>
	</head>
	<!--- body gets a class to match the filename --->
	<body <cfoutput>class="#listFirst(request.cw.thisPage, '.')#"</cfoutput>>
		<div id="CWadminWrapper">
			<!-- Navigation Area -->
			<div id="CWadminNav">
				<div class="CWinner">
					<cfinclude template="cwadminapp/inc/cw-inc-admin-nav.cfm">
				</div>
				<!-- /end CWinner -->
			</div>
			<!-- /end CWadminNav -->
			<!-- Main Content Area -->
			<div id="CWadminPage">
				<!-- inside div to provide padding -->
				<div class="CWinner">
					<!--- page start content / dashboard --->
					<cfinclude template="cwadminapp/inc/cw-inc-admin-page-start.cfm">
					<cfif len(trim(request.cwpage.heading1))><cfoutput><h1>#trim(request.cwpage.heading1)#</h1></cfoutput></cfif>
					<cfif len(trim(request.cwpage.heading2))><cfoutput><h2>#trim(request.cwpage.heading2)##request.cwpage.viewLink#</h2></cfoutput></cfif>
					<!--- user alerts --->
					<cfinclude template="cwadminapp/inc/cw-inc-admin-alerts.cfm">
					<!-- Page Content Area -->
					<div id="CWadminContent">
						<!-- //// PAGE CONTENT ////  -->
						<cfswitch expression="#url.mode#">
							<!--- IMAGE TYPES/SIZES --->
							<cfcase value="type">
								<p class="subText">Each upload group creates an image input on the <a href="product-details.cfm?showtab=3">product details</a> page.
								<br>Images uploaded to each input will be resized to the dimensions for the group, as shown below.
								<br>Folders that do not already exist on the server will be created when the first image is uploaded.<br>
								<br><em>Note: when adjusting sizes, existing images will not be affected.</em></p>
								<form action="<cfoutput>#request.cwpage.baseUrl#&mode=#url.mode#</cfoutput>" name="imgTypesForm" id="imgTypesForm" method="post" class="CWobserve">
								<!--- Container table --->
								<table class="CWinfoTable wide">
									<thead>
									<tr class="headerRow">
										<th>Image Upload Options <span class="smallPrint"><strong>(<cfoutput>#request.cwpage.groupCt#</cfoutput> Active Upload Groups)</strong></span></th>
									</tr>
									</thead>
									<tbody>
										<tr>
										<td>
										<!--- submit button --->
										<div class="CWadminControlWrap productImageControls">
											<input name="UpdateImageTypes" type="submit" class="CWformButton submitButton" id="UpdateImageTypes" value="Save Changes">
											<a class="CWbuttonLink" id="addGroupLink" href="<cfoutput>#request.cwpage.baseUrl#&mode=#url.mode#&addgroup=1</cfoutput>">Add New Upload Group</a>
										<div style="clear:right;"></div>
										</div>
										<!--- /END submit button --->
										<!--- if no records found, show message --->
										<cfif NOT imageTypesQuery.recordCount>
											<cfoutput>
											<p>&nbsp;</p>
											<p>&nbsp;</p>
											<p>&nbsp;</p>
											<p><strong>No image dimensions available</strong><br><br></p></cfoutput>
										<cfelse>
										<!--- SHOW IMAGE TYPES --->
										<cfset loopCt = 1>
										<cfset groupCt = 1>
										<cfoutput query="imageTypesQuery" group="imagetype_upload_group">
										<p>&nbsp;</p>
										<h3>Image Upload #groupCt#</h3>
										<table class="CWinfoTable formTable" id="imageGroupTable#groupCt#">
											<thead>
												<tr>
													<th style="width:30px;text-align:center;">ID</th>
													<th>Admin Label</th>
													<th>Max. Width</th>
													<th>Max. Height</th>
													<th>Folder Name</th>
													<cfif request.cwpage.imageTypeDelete is true>
														<th width="85" style="text-align:center;">
															<cfif imagetype_upload_group neq 1>
																<a class="CWbuttonLink" href="#request.cwpage.baseUrl#&mode=type&delgroup=#imagetype_upload_group#" onclick="return confirm('This will permanently detach all instances of these image types from all products, and the upload option for this group will be removed from the product details page.\n\n(Actual image files will not be affected)\nContinue?')">Delete</a>
															</cfif>
														</th>
													</cfif>
												</tr>
											</thead>
											<tbody>
												<!--- nested output ungroups records --->
												<cfoutput>
												<cfif imagetype_user_edit eq 1>
													<tr>
														<td style="padding-right:16px;text-align:right;">#imagetype_id#</td>
														<td>
															<!--- admin label --->
															<input name="imagetype_name#loopCt#" size="17" type="text" id="imagetype_name#loopCt#" value="#imagetype_name#">
															<!--- hidden inputs --->			
															<input type="hidden" name="imagetype_idlist" value="#imagetype_id#">
															<input type="hidden" name="imagetype_id#loopCt#" value="#imagetype_id#">
															<!--- setting this to groupCt keeps the groups ordered --->
															<input type="hidden" name="imagetype_upload_group#loopCt#" value="#groupCt#">
															<input type="hidden" name="imagetype_sortorder#loopCt#" value="#imagetype_sortorder#">
														</td>
														<!--- w/h--->
														<td><input name="imagetype_max_width#loopCt#" type="text" size="5" value="#imagetype_max_width#" onkeyup="extractNumeric(this,0,true);"></td>
														<td><input name="imagetype_max_height#loopCt#" type="text" size="5" value="#imagetype_max_height#" onkeyup="extractNumeric(this,0,true);"></td>
														<!--- folder name  --->
														<td><input name="imagetype_folder#loopCt#" class="folderName" type="text" size="21" value="#imagetype_folder#"></td>
														<cfif request.cwpage.imageTypeDelete is true>
															<td style="text-align:center;">
															<cfif imagetype_id gt 6>
																<a class="CWbuttonLink" href="#request.cwpage.baseUrl#&mode=type&deltype=#imagetype_id#" onclick="return confirm('This will permanently detach all instances of this image type from all products.\n\n(Actual image files will not be affected)\nContinue?')">Delete</a>
															<cfelse>
																<span class="smallPrint">n/a</span>
															</cfif>
															</td>
														</cfif>
														</tr>
													<cfset loopCt = loopCt + 1>
												</cfif>
												</cfoutput>	
												<tr class="addTypeRow">
												<td></td>
													<!--- admin label --->
												<td><input name="imagetype_name_new#imagetype_upload_group#" class="noSubmit" size="11" type="text" id="imagetype_name_new#imagetype_upload_group#" value=""></td>
												<!--- w/h--->
												<td><input name="imagetype_max_width_new#imagetype_upload_group#" class="noSubmit" type="text" size="5" id="imagetype_max_width_new#imagetype_upload_group#" value="0" onkeyup="extractNumeric(this,0,true);"></td>
												<td><input name="imagetype_max_height_new#imagetype_upload_group#" class="noSubmit" type="text" size="5" id="imagetype_max_height_new#imagetype_upload_group#" value="0" onkeyup="extractNumeric(this,0,true);"></td>
												<!--- folder name  --->
												<td><input name="imagetype_folder_new#imagetype_upload_group#" class="noSubmit" type="text" size="21" id="imagetype_folder_new#imagetype_upload_group#" value=""></td>
												<td style="text-align:center;">
													<a class="CWbuttonLink CWaddTypeLink" href="##" rel="#imagetype_upload_group#">Add</a>
												</td>												
												</tr>
											</tbody>
										</table>
										
											<cfif request.cwpage.imageTypeDelete is true>
												<p><a href="##" class="CWaddShowLink" rel="imageGroupTable#groupCt#">Add New</a></p>
											<cfelseif imagetype_upload_group gt 1>
												<a class="CWbuttonLink" style="margin-left:10px;" href="#request.cwpage.baseUrl#&mode=type&delgroup=#imagetype_upload_group#" onclick="return confirm('This will permanently detach all instances of these image types from all products, and the upload option for this group will be removed from the product details page.\n\n(Actual image files will not be affected)\nContinue?')">Delete Group</a>
												
											</cfif>
											
										<cfset groupCt = groupCt + 1>
										</cfoutput>
										<div class="CWadminControlWrap productImageControls">
											<input name="UpdateImageTypes" type="submit" class="CWformButton submitButton" id="UpdateImageTypes2" value="Save Changes">
										<div style="clear:right;"></div>
										</div>
										<span class="smallPrint" style="float:right;">
												<br><br>Note: changes made here will not affect previously uploaded images
										</span>
										</cfif>
										<!--- /end if records found --->
										</td>
									</tr>
								</tbody>
								</table>
								</form>
								<!--- /end image types/sizes --->
							</cfcase>
							<!--- IMAGES TABLE --->
							<cfdefaultcase>
								<!--- if no records found, show message --->
								<cfif NOT imagesQuery.recordCount>
									<p>&nbsp;</p>
									<p>&nbsp;</p>
									<p>&nbsp;</p>
									<p><strong>No images found.</strong></p>
								<cfelse>
									<!--- form submits to same page --->
									<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" name="imgForm" id="imgForm" method="post" class="CWobserve">
										<div class="CWadminControlWrap productImageControls">
											<!--- delete originals: if developer (or merchant if allowed) --->
											<cfif listFindNoCase(request.cwpage.deleteOrigLevels,request.cwpage.accessLevel)>
												<cfoutput><a class="CWbuttonLink deleteButton" href="#request.cwpage.baseUrl#&delorig=true&userid=#cookie.cftoken#" onclick="return confirm('This will delete all stored original-size images.\nProduct display will not be altered, but original images will no longer be available.\n( #listLen(request.cwpage.origFileNames)# found )\nContinue?')">Delete Originals</a></cfoutput>
											</cfif>
											<!--- delete unused (idle) images --->
											<cfoutput>
											<a class="CWbuttonLink" href="#request.cwpage.baseUrl#&delidle=true&userid=#cookie.cftoken#" onclick="return confirm('This will delete all stored images not connected with any products.\n( #listLen(request.cwpage.idleFileNames)# found )\nContinue?')">Delete Unused</a>
											</cfoutput>
											<!--- delete all images --->
											<cfif listFindNoCase('merchant,developer',request.cwpage.accessLevel)>
												<cfoutput>
												<a class="CWbuttonLink" href="#request.cwpage.baseUrl#&delall=true&userid=#cookie.cftoken#" onclick="return confirm('This will delete ALL stored product images and cannot be undone.\n( #imagesQuery.recordCount# found )\nContinue?')">Delete ALL</a>
												</cfoutput>
											</cfif>
											<!--- search --->
											<label for="imageSearchBox">Search: <input id="imageSearchBox" type="text" size="24" id="#imageSearchBox" value=""></label>
											<!--- delete selected --->
											<input type="submit" class="submitButton" value="Delete Selected" id="DelSelected" onclick="return warn();">
										</div>
										<div style="clear:right;"></div>
										<!--- hidden field verifies logged in user is the same one trying to post the deletion --->
										<input type="hidden" value="<cfoutput>#cookie.cftoken#</cfoutput>" name="deleteSelected">
										<!--- if we have some records to show --->
										<table id="imageControlTable" class="CWsort" summary="<cfoutput>
											#request.cwpage.baseUrl#</cfoutput>">
											<thead>
											<tr class="sortRow">
												<th class="noSort" width="80" style="text-align:center;">Image</th>
												<th class="filename">File</th>
												<th class="fileDate">Modified</th>
												<th class="noSort">Products</th>
												<th class="origsize">Size</th>
												<th class="noSort" width="50">Delete</th>
												<th class="fileInUse" width="50">In Use</th>
											</tr>
											</thead>
											<tbody>
											<!--- OUTPUT THE IMAGES --->
											<cfoutput query="imageInfoQuery">
											<!--- shade the used images --->
											<cfif fileInUse is true>
												<cfset rowClass = 'CWrowEven'>
											<cfelse>
												<cfset rowClass = 'CWrowOdd'>
											</cfif>
											<!--- row has class of used or not used (odd/even)  --->
											<tr class="#rowClass# #lcase(filename)#">
												<!--- image --->
												<td style="text-align:center;" class="imageCell noLink noHover">
													<cfif len(trim(origSrc)) AND fileExists(origSrc)>
														<a href="#origUrl#" title="#CWstringFormat(fileName)#: Original Image" class="zoomImg"><img src="#previewUrl#" alt="image thumbnail"></a>
													<cfelse>
														<img src="#previewUrl#" alt="image thumbnail">
													</cfif>
												</td>
												<!--- file --->
												<td class="noLink noHover">
													<cfif len(trim(origSrc)) AND fileExists(origSrc)>
														<a href="#origUrl#" title="#CWstringFormat(fileName)#: Original Image" class="detailsLink zoomImg">#fileName#</a>
													<cfelse>
														#fileName#
													</cfif>
												</td>
												<!--- modified --->
												<td class="noLink noHover">
													#LSdateFormat(fileDate,application.cw.globalDateMask)#
													<br>#timeFormat(fileDate,'short')#
												</td>
												<!--- products --->
												<td class="noLink noHover">
													<cfset prodCt = 0>
													<cfset prodIDlist = ''>
													<cfloop list="#fileProducts#" index="pp">
														<cfset prodId = listFirst(pp,'|')>
														<cfset prodIDlist = listAppend(prodIDlist,prodID)>
														<cfset prodName = listLast(pp,'|')>
														<cfset prodCt = prodCt + 1>
														<a href="product-details.cfm?productid=#prodID#&showtab=3" title="View Product">#prodName#</a><br>
													</cfloop>
												</td>
												<!--- size --->
												<td class="noLink noHover"><cfif isNumeric(origSize)>#numberFormat(origSize/1000,'_,___')&'&nbsp;kb'#<cfelse>(N/A)</cfif></td>
												<!--- delete --->
												<td style="text-align:center;">
													<input type="checkbox" name="dellist" id="confirmBox#currentRow#"
													class="formCheckbox delBox<cfif not fileInUse>idleBox</cfif>" value="#filename#"
													onclick="confirmDelete('confirmBox#currentRow#',#prodCt#)">
												</td>
												<!--- in use --->
												<td class="noLink"><cfif fileInUse>Yes<cfelse>No</cfif></td>
											</tr>
											</cfoutput>
											</tbody>
										</table>
									</form>
								</cfif>
								<!--- /END IMAGES TABLE --->
							</cfdefaultcase>
						</cfswitch>
					</div>
					<!-- /end Page Content -->
				</div>
				<!-- /end CWinner -->
			</div>
			<!--- page end content / debug --->
			<cfinclude template="cwadminapp/inc/cw-inc-admin-page-end.cfm">
			<!-- /end CWadminPage-->
			<div class="clear"></div>
		</div>
		<!-- /end CWadminWrapper -->
	</body>
</html>