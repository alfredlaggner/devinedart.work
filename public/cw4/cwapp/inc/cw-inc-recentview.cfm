<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-recentview.cfm
File Date: 2012-02-01
Description: shows recently viewed products based on list in client scope
==========================================================
--->
<!--- default for output --->
<cfset recentLoopCt = 0>
<cfparam name="application.cw.appDisplayProductViews" default="0">
<!--- current page defaults --->
<cfparam name="url.product" default="0">
<cfparam name="request.cwpage.productID" default="#url.product#">
<!--- product function required for productAvailable lookup --->
<cfinclude template="cw-inc-functions.cfm">
</cfsilent>
<cfif isDefined('application.cw.appDisplayProductViews') and application.cw.appDisplayProductViews gt 0
	and isDefined('session.cwclient.cwProdViews') and len(trim(session.cwclient.cwProdViews))
	and trim(session.cwclient.cwProdViews) neq request.cwpage.productID>
	<div class="CWproductRecentProducts CWcontent">
		<h3>Recently Viewed:</h3>
		<cfloop list="#session.cwclient.cwProdViews#" index="pp">
			<!--- don't show current product --->
			<cfif pp neq request.cwpage.productID and recentLoopCt lt application.cw.appDisplayProductViews>
				<cfif CWproductAvailable(pp)>
				<!--- show the product include --->
				<cfmodule
					template="../mod/cw-mod-productpreview.cfm"
					product_id="#pp#"
					add_to_cart="false"
					show_description="false"
					show_image="true"
					show_price="false"
					image_class="CWimgRecent"
					image_position="above"
					title_position="above"
					details_link_text="&raquo; details"
					>
				<cfset recentLoopCt = recentLoopCt + 1>
				</cfif>
			</cfif>
		</cfloop>
		<div class="CWclear"></div>
	</div>
</cfif>