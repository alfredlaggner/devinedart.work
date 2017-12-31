<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-admin-sanitize.cfm
File Date: 2012-05-03
Description: cleans up all form and url variables for processing
==========================================================
--->
<!--- verify only included once in any page --->
<cfif not (isDefined('request.cwpage.sanitized') and request.cwpage.sanitized is true)>
<cfif not isDefined('variables.cwSafeHTML')>
	<cfinclude template="../func/cw-func-admin.cfm">
</cfif>
	<!--- remove unwanted content from form and url variables --->
	<cfif isDefined('form.fieldnames')>
		<!--- clean up form submissions --->
		<cfloop list="#form.fieldnames#" index="f">
			<!--- bypass cleanup of admin editor fields --->
			<cfif application.cw.adminEditorEnabled 
			and not(application.cw.adminEditorProductDescrip and listFindNoCase('product_description,product_preview_description,product_special_description',f))
			and not(application.cw.adminEditorCategoryDescrip and (lcase(f) contains 'category_description' or lcase(f) contains 'secondary_description'))
			and not(lcase(f) contains 'config_value')
			>
				<!--- clean up each value --->
				<cfset form[f] = Replace(form[f],"<","&lt;","all")>
				<cfset form[f] = Replace(form[f],">","&gt;","all")>
				<cfset form[f] = Replace(form[f],'"',"&quot;","all")>
			</cfif>
		</cfloop>
	</cfif>
	<cfset urlvars = CWremoveUrlVars(returncontent='vars')>
	<cfif listLen('urlvars')>
		<!--- clean up url variables --->
		<cfloop list="#urlvars#" index="v">
			<!--- skip errors for variables with unformed values --->
			<cftry>
				<!--- clean up each value --->
				<cfset url[v] = CWsafeHTML(url[v])>
				<cfcatch>
				</cfcatch>
			</cftry>
		</cfloop>
	</cfif>
<cfset request.cwpage.sanitized = true>
</cfif>
<!--- /end only include once --->
</cfsilent>