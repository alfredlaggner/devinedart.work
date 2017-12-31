<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: product-files.cfm
File Date: 2012-08-25
Description: Handles downloadable file viewing and management
==========================================================
--->
<!--- time out the page if it takes too long - avoid server overload --->
<cfsetting requesttimeout="9000">
<!--- GLOBAL INCLUDES --->
<!--- global queries--->
<cfinclude template="cwadminapp/func/cw-func-adminqueries.cfm">
<!--- global functions--->
<cfinclude template="cwadminapp/func/cw-func-admin.cfm">
<cfinclude template="cwadminapp/func/cw-func-download.cfm">
<!--- PAGE PERMISSIONS --->
<cfset request.cwpage.accessLevel = CWauth("manager,merchant,developer")>
<!--- PAGE PARAMS --->
<cfparam name="application.cw.adminProductPaging" default="1">
<cfparam name="application.cw.adminRecordsPerPage" default="30">
<!--- default values for seach/sort--->
<cfparam name="url.pagenumresults" type="integer" default="1">
<cfparam name="url.search" type="string" default="">
<cfparam name="url.find" type="string" default="">
<cfparam name="url.maxrows" type="numeric" default="#application.cw.adminRecordsPerPage#">
<cfparam name="url.sortby" type="string" default="fileInUse">
<cfparam name="url.sortdir" type="string" default="desc">
<!--- default values for display --->
<cfset request.cwpage.filePath = CWcreateDownloadPath()>
<!--- QUERY: get Files in specified directory --->
<cfdirectory action="list" directory="#request.cwpage.filePath#" name="filesQuery" recurse="true" type="file">
<!--- QUERY: get All active filenames related to any product --->
<cfset skuFilesQuery = CWquerySelectSkuFiles()>
<!--- QUERY: get only unique filenames --->
<cfquery dbtype="query" name="usedFilesQuery">
SELECT DISTINCT sku_download_id
FROM skuFilesQuery
</cfquery>
<!--- set up lists of filenames used for output --->
<cfset request.cwpage.allFileNames = valueList(filesQuery.name)>
<cfset request.cwpage.usedFileNames = ''>
<cfset request.cwpage.idleFileNames = ''>
<!--- create our display query w/ file and product info --->
<cfset fileInfoQuery = queryNew("fileName,fileKey,fileDate,fileSize,fileUrl,fileType,fileProducts,fileInUse","varchar,varchar,date,decimal,varchar,varchar,varchar,bit")>

<!--- loop found files, set up info query --->
<cfoutput query="filesQuery">
	<!--- set up some info about this file --->
	<cfset dl.fileKey = name>
	<cfset dl.fileType = listLast(name,'.')>
	<cfset dl.fileDate = datelastModified>
	<cfset dl.fileSize = size>
	<!--- is the file in use? --->
	<cfset dl.fileSkus = ''>
	<cfif listFindNoCase(valueList(usedFilesQuery.sku_download_id), dl.fileKey)>
		<cfset dl.inUse = true>
		<!--- if so get the products and skus it is being used on --->
		<cfquery dbtype="query" name="getFileSkus">
		SELECT *
		FROM skuFilesQuery
		WHERE sku_download_id = '#dl.filekey#'
		</cfquery>
		<!--- add file sku info to query --->
		<cfloop query="getFileSkus">
			<cfset dl.fileSkus = listAppend(dl.fileSkus,'#getFileSkus.product_id#|#getFileSkus.product_name# [#getFileSkus.sku_merchant_sku_id#]')>
		</cfloop>
		<cfset dl.fileUrl = CWcreateDownloadUrl(sku_id=listFirst(valueList(getfileSkus.sku_id)),downloads_page='product-file-preview.cfm')>
		<cfset dl.fileName = listFirst(valueList(getfileSkus.sku_download_file))>
		<cfset request.cwpage.usedFileNames = listAppend(request.cwpage.usedFileNames,dl.fileName)>
		<!--- if not in use --->
	<cfelse>
		<cfset dl.inUse = false>
		<cfset dl.fileUrl = ''>
		<cfset dl.fileName = name>
		<cfset request.cwpage.idleFileNames = listAppend(request.cwpage.idleFileNames,dl.fileName)>
	</cfif>
	<!--- end if in use --->

	<!--- add data to display query --->
	<cfset temp = queryAddRow(fileInfoQuery)>
	<cfset temp = querySetCell(fileInfoQuery,'fileName',dl.fileName)>
	<cfset temp = querySetCell(fileInfoQuery,'fileKey',dl.fileKey)>
	<cfset temp = querySetCell(fileInfoQuery,'fileType',dl.fileType)>
	<cfset temp = querySetCell(fileInfoQuery,'fileDate',dl.fileDate)>
	<cfset temp = querySetCell(fileInfoQuery,'filesize',dl.fileSize)>
	<cfset temp = querySetCell(fileInfoQuery,'fileUrl',dl.fileUrl)>
	<cfset temp = querySetCell(fileInfoQuery,'fileProducts',dl.fileSkus)>
	<cfset temp = querySetCell(fileInfoQuery,'fileInUse',dl.inUse)>
</cfoutput>
<!--- end create info query --->

<!--- QUERY: make sortable --->
<cfset fileInfoQuery = CWsortableQuery(fileInfoQuery)>


<!--- BASE URL --->
<!--- get the vars to keep by omitting the ones we don't want repeated --->
<cfset varsToKeep = CWremoveUrlVars("sortby,sortdir,pagenumresults,userconfirm,useralert,dellist,delidle,delorig,delall,userid")>
<!--- create the base url out of serialized url variables--->
<cfset request.cwpage.baseUrl = CWserializeUrl(varsToKeep,request.cw.thisPage)>

<!--- /////// --->
<!--- DELETE FILES --->
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
	<cfset delCt = 0>
	<!--- if deleting only originals (delorig) --->
	<cfloop list="#request.cwpage.deleteList#" index="dd">
		<cftry>
			<cfset delFile = trim(dd)>
				<!--- set up the file to delete --->
				<cfset delDir = CWcreateDownloadPath()>
				<cfif application.cw.appDownloadsFileExtDirs>
					<cfset delExt = listLast(dd,'.')>
					<cfset delDir = cwTrailingChar(delDir) & delExt>
					<cfset delSrc = cwTrailingChar(delDir) & delFile>
				</cfif>
				<!--- if the file exists, delete it --->
				<cfif fileExists(delSrc)>
					<cffile action="delete" file="#delSrc#">
					<cfset delCt = delCt + 1>
				</cfif>
			<!--- remove from any skus using this file ID --->
			<cfset deleteSkuFileData = CWqueryDeleteSkuFile(download_key=delFile)>
			<!--- handle errors --->
			<cfcatch>
				<cfset CWpageMessage("alert","Error: #cfcatch.message# #cfcatch.detail#")>
			</cfcatch>
		</cftry>
	</cfloop>
	<cfif delCt gt 0>
		<cfif delCt is 1><cfset s = ''><cfelse><cfset s = 's'></cfif>
		<cfset CWpageMessage("confirm","#delCt# file#s# deleted")>
		<cflocation url="#request.cwpage.baseUrl#&userconfirm=#CWurlSafe(request.cwpage.userConfirm)#&useralert=#CWurlSafe(request.cwpage.userAlert)#" addtoken="no">
	</cfif>
</cfif>
<!--- /////// --->
<!--- /END DELETE IMAGES --->
<!--- /////// --->
<!--- SUBHEADING --->
<cfsavecontent variable="request.cwpage.subhead">
<cfoutput>
Files Uploaded: #filesQuery.recordCount#&nbsp;&nbsp;
In Use: #listLen(request.cwpage.usedFileNames)#&nbsp;&nbsp;
Not In Use: #listLen(request.cwpage.idleFileNames)#&nbsp;&nbsp;
File Path: #request.cwpage.filePath#
</cfoutput>
</cfsavecontent>
<!--- PAGE SETTINGS --->
<!--- Page Browser Window Title --->
<cfset request.cwpage.title = "Manage Product Files">
<!--- Page Main Heading <h1> --->
<cfset request.cwpage.heading1 = "File Management">
<!--- Page Subheading (instructions) <h2> --->
<cfset request.cwpage.heading2 = request.cwpage.subhead>
<!--- current menu marker --->
<cfset request.cwpage.currentNav = 'product-files.cfm'>
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
					clickConfirm = confirm("Warning: file in use!\nThis file will be unassigned for " + prodCt + " " + prodWord + ".\nContinue?");
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
// containsNoCase function courtesy Rick Strahl:
// http://www.west-wind.com/weblog/posts/519980.aspx
$.expr[":"].containsNoCase = function(el, i, m) {
    var search = m[3];
    if (!search) return false;
    return eval("/" + search + "/i").test(jQuery(el).text());
};
// file search box
jQuery('#fileSearchBox').keyup(function(){
// use lowercase version of input string, to match classes on table rows (see 'tr' below)
var searchText = jQuery(this).val().toLowerCase();
// if blank, show all rows again
if (searchText == ''){
jQuery('#fileControlTable tbody tr').show();
}
// or filter all rows
else
{
// hide all rows, show the rows that match
jQuery('#fileControlTable tbody tr').hide();
// works for matching text or class
jQuery("#fileControlTable tbody tr:containsNoCase('"+searchText+"')").show();
//jQuery("#fileControlTable tbody tr:containsNoCase('"+ jQuery(this).val()+"')").show();
jQuery("#fileControlTable tbody tr[class*='"+ jQuery(this).val()+"']").show();
jQuery("#fileControlTable tbody tr a:containsNoCase('"+ jQuery(this).val()+"')").parents('tr').show();
}
});
// end file search

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
					<cfif len(trim(request.cwpage.heading2))><cfoutput><h2>#trim(request.cwpage.heading2)#</h2></cfoutput></cfif>
					<!--- user alerts --->
					<cfinclude template="cwadminapp/inc/cw-inc-admin-alerts.cfm">
					<!-- Page Content Area -->
					<div id="CWadminContent">
						<!-- //// PAGE CONTENT ////  -->
						<!--- FILES TABLE --->
						<!--- if no records found, show message --->
						<cfif NOT filesQuery.recordCount>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p>&nbsp;</p>
							<p><strong>No files found.</strong></p>
						<cfelse>
							<!--- form submits to same page --->
							<form action="<cfoutput>#request.cwpage.baseUrl#</cfoutput>" name="imgForm" id="imgForm" method="post" class="CWobserve">
								<div class="CWadminControlWrap productFileControls">
									<!--- delete unused (idle) files --->
									<cfoutput>
									<a class="CWbuttonLink" href="#request.cwpage.baseUrl#&delidle=true&userid=#cookie.cftoken#" onclick="return confirm('This will delete all stored files not connected with any products.\n( #listLen(request.cwpage.idleFileNames)# found )\nContinue?')">Delete Unused</a>
									</cfoutput>
									<!--- delete all files --->
									<cfif listFindNoCase('merchant,developer',request.cwpage.accessLevel)>
										<cfoutput>
										<a class="CWbuttonLink" href="#request.cwpage.baseUrl#&delall=true&userid=#cookie.cftoken#" onclick="return confirm('This will ALL stored product files and cannot be undone.\n( #filesQuery.recordCount# found )\nContinue?')">Delete ALL</a>
										</cfoutput>
									</cfif>
									<!--- search --->
									<label for="fileSearchBox">Search: <input id="fileSearchBox" type="text" size="24" id="fileSearchBox" value=""></label>
									<!--- delete selected --->
									<input type="submit" class="submitButton" value="Delete Selected" id="DelSelected" onclick="return warn();">
								</div>
								<div style="clear:right;"></div>
								<!--- hidden field verifies logged in user is the same one trying to post the deletion --->
								<input type="hidden" value="<cfoutput>#cookie.cftoken#</cfoutput>" name="deleteSelected">
								<!--- if we have some records to show --->
								<table id="fileControlTable" class="CWsort" summary="<cfoutput>#request.cwpage.baseUrl#</cfoutput>">
									<thead>
									<tr class="sortRow">
										<th class="filename">File</th>
										<th class="fileType">Type</th>
										<th class="fileDate">Modified</th>
										<th class="noSort">Products/Skus</th>
										<th class="fileSize">Size</th>
										<th class="noSort" width="50">Delete</th>
										<th class="fileInUse" width="50">In Use</th>
									</tr>
									</thead>
									<tbody>
									<!--- OUTPUT THE FILES --->
									<cfoutput query="fileInfoQuery">
									<!--- shade the used files --->
									<cfif fileInUse is true>
										<cfset rowClass = 'CWrowEven'>
									<cfelse>
										<cfset rowClass = 'CWrowOdd'>
									</cfif>
									<!--- row has class of used or not used (odd/even)  --->
									<tr class="#rowClass# #lcase(filename)#">
										<!--- file --->
										<td class="noLink noHover">
											<cfif len(trim(fileUrl))>
												<a href="#fileUrl#" title="View/Download File">#fileName#</a>
											<cfelse>
												#fileName#
											</cfif>
										</td>
										<!--- type --->
										<td class="noLink noHover">
											#fileType#
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
												<a href="product-details.cfm?productid=#prodID#&showtab=4" title="View Product">#prodName#</a><br>
											</cfloop>
										</td>
										<!--- size --->
										<td class="noLink noHover"><cfif isNumeric(fileSize)>#numberFormat(fileSize/1000,'_,___')&'&nbsp;kb'#<cfelse>(N/A)</cfif></td>
										<!--- delete --->
										<td style="text-align:center;">
											<input type="checkbox" name="dellist" id="confirmBox#currentRow#"
											class="formCheckbox delBox<cfif not fileInUse>idleBox</cfif>" value="#fileKey#"
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
						<!--- /END FILES TABLE --->
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