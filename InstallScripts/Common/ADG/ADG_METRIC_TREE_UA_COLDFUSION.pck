<?xml version="1.0" encoding="iso-8859-1"?>
<Package PackName="ADG_METRIC_TREE_UA_COLDFUSION" Type="INTERNAL" Version="6.4.0.0" SupportedServer="ALL" Display="ADG Metric Tree for UA COLDFUSION" Description="" DatabaseKind="KB_CENTRAL">
	<Include>
	</Include>
	<Exclude>
	</Exclude>
	<Install>		
		<Step Type="DATA" File="AdgMetrics_CF_70x.xml" Model="..\CentralModelColdFusion.xml" Scope="CFMetrics">
		</Step>
	</Install>
	<Update>
    </Update>
	<Refresh>
		<Step Type="DATA" File="AdgMetrics_CF_70x.xml" Model="..\CentralModelColdFusion.xml" Scope="CFMetrics">
		</Step>
	</Refresh>
	<Remove>
	</Remove>
</Package>