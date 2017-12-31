<cfsilent>
<!---
==========================================================
Application: Cartweaver 4 ColdFusion
Copyright 2002 - 2013, All Rights Reserved
Developer: Application Dynamics, Inc. | Cartweaver.com
Licensing: http://www.cartweaver.com/eula
Support: http://www.cartweaver.com/support
==========================================================
File: cw-inc-checkoutsteps.cfm
File Date: 2012-02-01
Description: creates graduated visual links representing steps for checkout process
Indicator variable = 'request.cwpage.currentStep', set in CW checkout include
==========================================================
--->
	<!--- characters shown between links --->
	<cfset separator = ' &gt; '>
	<cfparam name="request.cwpage.currentStep" default="0">
	<cfparam name="request.cwpage.shipDisplay" default="#application.cw.shipEnabled#">
	<cfparam name="session.cwclient.cwCustomerID" default="0">
</cfsilent>
<cfoutput>
	<span id="CWcheckoutStepLinks">
		<cfif application.cw.customerAccountEnabled>
		<!--- STEP 1: select new account/login --->
		<span id="CWcheckoutStep1" class="step1">
		<a href="<cfoutput>#request.cw.thisPage#</cfoutput>"<cfif request.cwpage.currentStep gte 1> class="currentLink"</cfif>>Login/Register</a>
		</span>
		#separator#
		</cfif>
		<!--- STEP 2: user/billing/shipping info --->
		<span id="CWcheckoutStep2" class="step2">
		<a href="<cfoutput>#request.cw.thisPage#</cfoutput>"<cfif request.cwpage.currentStep gte 2> class="currentLink"</cfif>>Address<cfif application.cw.customerAccountEnabled>/Account<cfelse> Details</cfif></a>
		</span>
		#separator#
		<!--- STEP 3: select shipping method --->
		<cfif request.cwpage.shipDisplay>
		<span id="CWcheckoutStep3" class="step3">
		<a href="<cfoutput>#request.cw.thisPage#</cfoutput>"<cfif request.cwpage.currentStep gte 3> class="currentLink"</cfif>>Shipping</a>
		</span>
		#separator#
		</cfif>
		<!--- STEP 4: review and confirm order--->
		<span id="CWcheckoutStep4" class="step4">
		<a href="<cfoutput>#request.cw.thisPage#</cfoutput>"<cfif request.cwpage.currentStep gte 4> class="currentLink"</cfif>>Review &amp; Confirm</a>
		</span>
		#separator#
		<!--- STEP 5: select / submit payment --->
		<span id="CWcheckoutStep5" class="step5">
		<a href="<cfoutput>#request.cw.thisPage#</cfoutput>"<cfif request.cwpage.currentStep gte 5> class="currentLink"</cfif>>Submit Order</a>
		</span>
	</span>
</cfoutput>