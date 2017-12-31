<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-script-editor.cfm
File Date: 2012-02-01
Description: Inserts text editor javascript into head of calling page
==========================================================
--->
</cfsilent>
<!--- Text Editor Javascript --->
<cfsavecontent variable="RTEContent">
<!-- Load TinyMCE -->
<!-- see http://wiki.moxiecode.com/index.php/ for full TinyMCE options and documentation -->
<script type="text/javascript" src="js/jquery.tinymce.js"></script>
<script type="text/javascript">
	jQuery().ready(function() {
		jQuery('textarea.textEdit').tinymce({
			// Location of TinyMCE script
			script_url : 'js/tiny_mce/tiny_mce.js',
			// General options
			theme : "advanced",
			plugins : "safari,table,advlink,iespell,preview,searchreplace,paste,fullscreen",
			// TinyMCE Default plugins - see plugins reference here: http://wiki.moxiecode.com/index.php/TinyMCE:Plugins
			// plugins: "safari,pagebreak,style,layer,table,save,advhr,advimage,advlink,emotions,iespell,inlinepopups,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,fullscreen,noneditable,visualchars,nonbreaking,xhtmlxtras,template", --->
			// Theme options
			theme_advanced_buttons1 : "bold,italic,underline,strikethrough,|<cfif len(trim(application.cw.adminEditorCss))>,styleselect</cfif>,justifyleft,justifycenter,justifyright,|,code,preview,fullscreen",
			theme_advanced_buttons2 : "cut,copy,paste,pastetext,pasteword,selectall,|,search,replace,|,bullist,numlist,|,undo,redo,|,link,unlink,|,iespell",
			theme_advanced_buttons3 : "",
			// TinyMCE Defaults
			//	theme_advanced_buttons1 : "save,newdocument,|,bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,styleselect,formatselect,fontselect,fontsizeselect",
			//	theme_advanced_buttons2 : "cut,copy,paste,pastetext,pasteword,|,search,replace,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,anchor,image,cleanup,help,code,|,insertdate,inserttime,preview,|,forecolor,backcolor",
			//	theme_advanced_buttons3 : "tablecontrols,|,hr,removeformat,visualaid,|,sub,sup,|,charmap,emotions,iespell,media,advhr,|,print,|,ltr,rtl,|,fullscreen",
			//	theme_advanced_buttons4 : "insertlayer,moveforward,movebackward,absolute,|,styleprops,|,cite,abbr,acronym,del,ins,attribs,|,visualchars,nonbreaking,template,pagebreak",
			theme_advanced_toolbar_location : "top",
			theme_advanced_toolbar_align : "left",
			theme_advanced_statusbar_location : "bottom",
			theme_advanced_resizing : true,
			width : "420",
			// Description content stylesheet (your site css, or cartweaver-supplied css file)
			<cfif len(trim(application.cw.adminEditorCss))>
			content_css : "../<cfoutput>#application.cw.adminEditorCss#</cfoutput>",
			</cfif>
			// clean up pasted code
            paste_auto_cleanup_on_paste : true,
            paste_remove_styles: true,
            paste_remove_styles_if_webkit: true,
            paste_strip_class_attributes: true,
            convert_urls : false
		});
	// end jQuery
	});
</script>
<!-- /TinyMCE -->
</cfsavecontent>
<cfhtmlhead text="#RTEcontent#">