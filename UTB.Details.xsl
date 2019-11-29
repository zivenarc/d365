<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"  xmlns:utb="http://www.cargowise.com/Schemas/Universal/2011/11" 
								xmlns:msxsl="urn:schemas-microsoft-com:xslt"
								xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!-- Data format template -->
<xsl:template name="formatdate">
	 <xsl:param name="DateTimeStr" />

	 <xsl:variable name="datestr">
		 <xsl:value-of select="substring-before($DateTimeStr,'T')" />
	 </xsl:variable>

	 <xsl:variable name="mm">
		 <xsl:value-of select="substring($datestr,6,2)" />
	 </xsl:variable>

	 <xsl:variable name="dd">
		<xsl:value-of select="substring($datestr,9,2)" />
	 </xsl:variable>

	 <xsl:variable name="yyyy">
		<xsl:value-of select="substring($datestr,1,4)" />
	 </xsl:variable>

	 <xsl:value-of select="concat($dd,'/', $mm, '/', $yyyy)" />
</xsl:template>

<!-- Batch number node exists, but not filled in. Have to take it from the head section -->
<xsl:variable name="batch"><xsl:value-of select="utb:UniversalTransactionBatch/utb:TransactionBatch/utb:DataContext/utb:DataSourceCollection/utb:DataSource/utb:Key"/></xsl:variable>

<!-- Flatten the original file by posting journal -->
<xsl:variable name="FLAT">

	<xsl:for-each select="utb:UniversalTransactionBatch/utb:TransactionBatch/utb:TransactionCollection/utb:Transaction">
		<xsl:sort select="utb:TransactionType" order="descending"/>
		<xsl:variable name="transactionType"><xsl:value-of select="utb:Ledger"/><xsl:value-of select="utb:TransactionType"/></xsl:variable>
		<xsl:variable name="invoice"><xsl:value-of select="utb:Number"/></xsl:variable>
		<xsl:variable name="localClient"><xsl:value-of select="utb:LocalClient"/></xsl:variable>
		<xsl:variable name="arGroup"><xsl:value-of select="utb:ARAccountGroup/utb:Code"/></xsl:variable>
		<xsl:variable name="apGroup"><xsl:value-of select="utb:APAccountGroup/utb:Code"/></xsl:variable>
		<xsl:variable name="job"><xsl:value-of select="utb:Job/utb:Key"/></xsl:variable><!--Better to take it from the posting-->
		<xsl:variable name="position"><xsl:value-of select="position()"/></xsl:variable>
			<xsl:for-each select="utb:PostingJournalCollection">
				<xsl:for-each select="utb:PostingJournal">
					<Transaction>
						<Job><xsl:value-of select="utb:Job/utb:Key"/></Job>
						<TransactionType>
							<xsl:choose>
								<xsl:when test="$transactionType = 'JCACR' and utb:OSAmount &gt; 0">
									<xsl:text>JCACD</xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$transactionType"/>
								</xsl:otherwise>
							</xsl:choose>
						</TransactionType>
						<ApGroup><xsl:value-of select="$apGroup"/></ApGroup>
						<ArGroup><xsl:value-of select="$arGroup"/></ArGroup>
						<Party><xsl:value-of select="utb:Organization/utb:Key"/></Party>
						<!-- <LocalClient><xsl:value-of select="$localClient"/></LocalClient> -->
						<LocalClient><xsl:value-of select="../../utb:LocalClient"/></LocalClient>
						<Branch><xsl:value-of select="utb:Branch/utb:Code"/></Branch>
						<ItemCode><xsl:value-of select="utb:ChargeCode/utb:Code"/>-<xsl:value-of select="utb:Department/utb:Code"/></ItemCode>
						<GLAccount><xsl:value-of select="utb:GLAccount/utb:AccountCode"/></GLAccount>
						<OriginalBatchNumber><xsl:value-of select="utb:OriginalBatchNumber"/></OriginalBatchNumber>
						<OriginalBatchSequence><xsl:value-of select="utb:OriginalBatchSequence"/></OriginalBatchSequence>
						<BatchSequence><xsl:value-of select="utb:BatchSequence"/></BatchSequence>
						<Description><xsl:value-of select="utb:Description"/></Description>
						<Invoice><xsl:value-of select="$invoice"/></Invoice>
						<OSAmount><xsl:value-of select="utb:OSAmount"/></OSAmount>
						<OSCurrency><xsl:value-of select="utb:OSCurrency/utb:Code"/></OSCurrency>
						<LocalAmount><xsl:value-of select="utb:LocalAmount"/></LocalAmount>
						<xsl:choose>
							<xsl:when test="$transactionType = 'JCACR' and utb:WIPOrAccrualOSAmount != 0">
								<xsl:variable name="chargeAmount"><xsl:value-of select="utb:WIPOrAccrualOSAmount"/></xsl:variable>
								<ChargeAmount><xsl:value-of select="$chargeAmount"/></ChargeAmount>
								<ChargeCurrency><xsl:value-of select="utb:WIPOrAccrualOSCurrency"/></ChargeCurrency>
							</xsl:when>
							<xsl:otherwise>
								<xsl:variable name="chargeAmount"><xsl:value-of select="utb:OSAmount*(utb:OSAmount &gt;=0) - utb:OSAmount*(utb:OSAmount &lt; 0)"/></xsl:variable>
								<ChargeAmount><xsl:value-of select="$chargeAmount"/></ChargeAmount>
								<ChargeCurrency><xsl:value-of select="utb:OSCurrency/utb:Code"/></ChargeCurrency>
							</xsl:otherwise>
						</xsl:choose>
						<ChargeExchangeRate><xsl:value-of select="utb:ChargeExchangeRate"/></ChargeExchangeRate>
						<LocalCurrency><xsl:value-of select="utb:LocalCurrency/utb:Code"/></LocalCurrency>
						<AbsAmount><xsl:value-of select="utb:LocalAmount*(utb:LocalAmount &gt;=0) - utb:LocalAmount*(utb:LocalAmount &lt; 0)"/></AbsAmount>
						<!-- <sorter><xsl:value-of select="utb:Sequence"/></sorter> -->
					</Transaction>
				</xsl:for-each>
			</xsl:for-each>
    </xsl:for-each>
</xsl:variable>

<!-- Sort the transactions-->
<xsl:variable name="PRESORTED">
	<xsl:for-each select="msxsl:node-set($FLAT)/Transaction">
		<xsl:sort select="Job"/>
		<xsl:sort select="Party"/>
		<xsl:sort select="ItemCode"/>
		<xsl:sort select="ChargeAmount" data-type="number"/>
		<xsl:sort select="TransactionType" order="descending"/>
		
		<xsl:variable name="transactionType" select="TransactionType"/>
		<xsl:variable name="job" select="Job"/>
		<xsl:variable name="party" select="Party"/>
		<xsl:variable name="chargeAmount" select="ChargeAmount"/>
		<xsl:variable name="absAmount" select="AbsAmount"/>
		<xsl:variable name="itemCode" select="ItemCode"/>
		
		<Transaction>
			<xsl:copy-of select="*"/>
			<!-- Special sorter for same amounts in the same job -->
			<!-- <osSorter><xsl:value-of select="count(preceding-sibling::*[Job = $job][Party = $party][AbsAmount = $absAmount][TransactionType = $transactionType][ItemCode = $itemCode])"/></osSorter> -->
			<sorter><xsl:value-of select="concat(format-number(ChargeAmount,'#,##0.0000'),'-',count(preceding-sibling::*[Job = $job][Party = $party][ChargeAmount = $chargeAmount][TransactionType = $transactionType][ItemCode = $itemCode]))"/></sorter>
		</Transaction>
		<!-- <xsl:copy-of select="*"/> -->
	</xsl:for-each>
</xsl:variable>

<!-- Second sorting run -->
<xsl:variable name="SORTED">
	<xsl:for-each select="msxsl:node-set($PRESORTED)/Transaction[TransactionType = 'JCACR']">
		<xsl:sort select="BatchSequence" data-type="number"/>
		<xsl:copy-of select="."/>
	</xsl:for-each>
	<xsl:for-each select="msxsl:node-set($PRESORTED)/Transaction[TransactionType != 'JCACR']">
		<xsl:sort select="Job"/>
		<xsl:sort select="Party"/>
		<xsl:sort select="ItemCode"/>
		<xsl:sort select="sorter"/>
		<!-- <xsl:sort select="concat(format-number(AbsAmount,'#,##0.0000'),'-',osSorter)"/> -->
		<xsl:sort select="TransactionType" order="descending"/>
		<xsl:copy-of select="."/>
	</xsl:for-each>
</xsl:variable>

<!-- Template start -->
<xsl:template match="/utb:UniversalTransactionBatch">
<html>
<head>
	<title>UTB|<xsl:value-of select="$batch"/></title>
		<style>
			body{
				font-family: Calibri;
			}
			table{
				border-spacing: 0;
				border-collapse: collapse;
				width: 100%;
				font-size: 12px;
			}
			td, th{
				border: 1px solid gray;
				padding: 1px 3px;
			}
			.transaction th{
				background-color: gray;
				color: white;
			}
			.APINV{
				background-color: #0095ff;
				color: #fff;
			}
			.ARINV{
				background-color: maroon;
				color: #fff;
			}
			.posting th{
				background-color: silver;
				color: black;
			}
			.posting td{
				background-color: white;
			}
			.number{
				text-align: right;
			}
			em{
				color: blue;
			}
			.match{
				background-color: #9acd32;
			}
			.delete{
				background-color: red;
				color: white;
			}
			.arrowdown{
				position: relative;
				top: 14px;
				font-size: 22px;				
			}
			.negative{
				color: red;
			}
			.details td, .details th{
				border-color: DodgerBlue;
			}
			.details th{
				background-color: DodgerBlue;
				color:white;
			}
		</style>
	</head> 
<body>
   <h1>Universal transaction batch #<xsl:value-of select="$batch"/></h1>
   <p>Company <xsl:value-of select="utb:TransactionBatch/utb:DataContext/utb:Company/utb:Code"/> | Server <xsl:value-of select="utb:TransactionBatch/utb:DataContext/utb:ServerID"/></p>
   <table class="transaction">
		<thead>
			<tr>
				<th>#</th>
				<th>Job</th>
				<th title="Batch number">BN</th>
				<th title="Batch sequence">BS</th>
				<th title="Original batch number">OBN</th>
				<th title="Original batch sequence">OBS</th>
				<th>Party</th>
				<th>Tran.type</th>
				<th>Number</th>
				<th>Item</th>
				<th>Action</th>
				<th>Charge amount</th>
				<th>Currency</th>
				<th>Local amount</th>
				<th>Currency</th>
				<th>Sorter</th>
			</tr>
		</thead>
    <xsl:for-each select="msxsl:node-set($SORTED)/Transaction">
		<xsl:variable name="transaction"><xsl:value-of select="utb:Ledger"/><xsl:value-of select="utb:TransactionType"/></xsl:variable>
		<xsl:variable name="nextNode"><xsl:value-of select="(following-sibling::*[1])/TransactionType"/></xsl:variable>
		<xsl:variable name="nextJob"><xsl:value-of select="(following-sibling::*[1])/Job"/></xsl:variable>
		<xsl:variable name="nextVendor"><xsl:value-of select="(following-sibling::*[1])/Party"/></xsl:variable>
		<xsl:variable name="nextInvoice"><xsl:value-of select="(following-sibling::*[1])/Invoice"/></xsl:variable>
		<xsl:variable name="nextInvoiceAmount"><xsl:value-of select="(following-sibling::*[1])/ChargeAmount"/></xsl:variable>
		
		<xsl:variable name="prevNode"><xsl:value-of select="(preceding-sibling::*[1])/TransactionType"/></xsl:variable>
		<xsl:variable name="prevJob"><xsl:value-of select="(preceding-sibling::*[1])/Job"/></xsl:variable>
		<xsl:variable name="prevVendor"><xsl:value-of select="(preceding-sibling::*[1])/Party"/></xsl:variable>
		<xsl:variable name="prevInvoice"><xsl:value-of select="(preceding-sibling::*[1])/Invoice"/></xsl:variable>
		<xsl:variable name="prevInvoiceAmount"><xsl:value-of select="(preceding-sibling::*[1])/ChargeAmount"/></xsl:variable>
		<xsl:variable name="job"><xsl:value-of select="utb:Job/utb:Key"/></xsl:variable>
		<tr>
			<td><xsl:number value="position()" format="1" /></td>
			<td><xsl:value-of select="Job"/></td>
			<td><xsl:value-of select="$batch"/></td>
			<td><xsl:value-of select="BatchSequence"/></td>
			<td><xsl:value-of select="OriginalBatchNumber"/></td>
			<td><xsl:value-of select="OriginalBatchSequence"/></td>
			<td><xsl:value-of select="Party"/></td>
			<td>
				<xsl:attribute name="class"><xsl:value-of select="TransactionType"/></xsl:attribute>
				<xsl:value-of select="TransactionType"/>
			</td>
			<td><xsl:value-of select="Invoice"/></td>
			<td><xsl:value-of select="ItemCode"/></td>
			<xsl:choose>
					<xsl:when test="TransactionType = 'JCACD'">
						<xsl:choose>
									<!-- If next transaction is AP with matching vendor, job and amount - match PO with the invoice-->
									<xsl:when test="$nextNode = 'APINV' 
													and $nextVendor = Party
													and $nextJob = Job
													and $nextInvoiceAmount - ChargeAmount = 0">
										<td class="match">
											<xsl:if test="OSAmount - ChargeAmount !=0">
												<div>Update the PO Amount to <xsl:value-of select="ChargeCurrency"/><xsl:value-of select="ChargeAmount"/> and</div>
											</xsl:if>
										Match the Purchase order <strong><xsl:value-of select="Job"/>-<xsl:value-of select="OriginalBatchNumber"/>-<xsl:value-of select="OriginalBatchSequence"/></strong>
										with the invoice <strong><xsl:value-of select="$nextInvoice"/></strong><span class="arrowdown">&#10552;</span></td>
									</xsl:when>
									<xsl:otherwise>
									<!-- otherwise if the accrual is reversed, refer to the matching PO with Original Batch Number-->
										<td class="delete">
											Delete the Purchase order <xsl:value-of select="Job"/>-<xsl:value-of select="OriginalBatchNumber"/>-<xsl:value-of select="OriginalBatchSequence"/>
										</td>
									</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="TransactionType = 'JCACR'">
						<xsl:choose>
							<xsl:when test="OriginalBatchNumber = ''">
								<td><p>Create a Purchase order <strong><xsl:value-of select="Job"/>-<xsl:value-of select="$batch"/>-<xsl:value-of select="BatchSequence"/></strong></p>
									<div>
									<table class="posting">
										<tr><th>Amount</th><td><xsl:value-of select="ChargeCurrency"/><xsl:text> </xsl:text><xsl:value-of select="ChargeAmount"/></td></tr>
										<tr><th>FX rate</th><td><xsl:value-of select="1 div ChargeExchangeRate"/></td></tr>
										<tr><th>Item</th><td><xsl:value-of select="ItemCode"/></td></tr>
										<tr><th>Description</th><td><xsl:value-of select="Description"/></td></tr>
										<tr><th>Main account</th><td>Get from item <xsl:value-of select="ItemCode"/></td></tr>
										<tr><th>Department</th><td><em>To be translated by OpCo</em></td></tr>
										<tr><th>Product</th><td>Get from item <xsl:value-of select="ItemCode"/></td></tr>
										<tr><th>Division</th><td>Derive from product</td></tr>
										<tr><th>Location</th><td><em>To be translated by OpCo (<xsl:value-of select="Branch"/>)</em></td></tr>
										<tr><th>End customer</th><td><xsl:value-of select="LocalClient"/></td></tr>
										<tr><th>Local account</th><td><em>Default dimension</em></td></tr>
										<tr><th>Shipment</th><td><xsl:value-of select="Job"/></td></tr>
										<tr><th>Offset account</th><td>Vendor <xsl:value-of select="Party"/></td></tr>
										<xsl:if test="ApGroup = '103'"><tr><th>Intercompany</th><td><xsl:value-of select="Party"/></td></tr></xsl:if>
									</table>
									</div>
								</td>
							</xsl:when>
							<xsl:otherwise>
								<td>n/a</td>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="TransactionType = 'ARINV'">
						<td>Process <xsl:if test="ArGroup = '003'">Intercompany </xsl:if>Customer Invoice (O2C001)</td>
					</xsl:when>
					<xsl:when test="TransactionType = 'APINV'">
						<xsl:choose>
							<xsl:when test="$prevNode != 'JCACD' 
											or $prevVendor != Party
											or $prevJob != Job
											or $prevInvoiceAmount - ChargeAmount !=0">
								<td class="delete"><div>No matching accrual found</div>
									<div>Create a Purchase order <strong><xsl:value-of select="Job"/>-<xsl:value-of select="Invoice"/></strong></div>
									<div>
									<table class="posting">
										<tr><th>Item</th><td><xsl:value-of select="ItemCode"/></td></tr>
										<tr><th>Description</th><td><xsl:value-of select="Description"/></td></tr>
										<tr><th>Main account</th><td>Get from item <xsl:value-of select="ItemCode"/></td></tr>
										<tr><th>Department</th><td><em>To be translated by OpCo</em></td></tr>
										<tr><th>Product</th><td>Get from item <xsl:value-of select="ItemCode"/></td></tr>
										<tr><th>Division</th><td>Derive from product</td></tr>
										<tr><th>Location</th><td><em>To be translated by OpCo (<xsl:value-of select="Branch"/>)</em></td></tr>
										<tr><th>End customer</th><td><xsl:value-of select="LocalClient"/></td></tr>
										<tr><th>Local account</th><td><em>Default dimension</em></td></tr>
										<tr><th>Shipment</th><td><xsl:value-of select="Job"/></td></tr>
										<tr><th>Offset account</th><td>Vendor <xsl:value-of select="Party"/></td></tr>
										<xsl:if test="ApGroup = '103'"><tr><th>Intercompany</th><td><xsl:value-of select="Party"/></td></tr></xsl:if>
									</table>
									</div>
									<div>and match it with this invoice</div>
								</td>
							</xsl:when>
							<xsl:otherwise>
								<td><xsl:if test="ApGroup = '103'"><em>Create Intercompany invoice with <strong><xsl:value-of select="Party"/></strong> if not OCRd</em></xsl:if></td>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="TransactionType = 'APINV'">
						<td>Credited AP Inovice (to be paired with JCACR)</td>
					</xsl:when>
					<xsl:when test="ARCRD">
						<td>Credit customer invoice (TBA)</td>
					</xsl:when>
					<xsl:otherwise>
						<td>No action defined</td>
					</xsl:otherwise>
				</xsl:choose>
			<td>
				<xsl:attribute name="class">
					<xsl:if test="ChargeAmount &lt; 0">negative</xsl:if>
					number
				</xsl:attribute>
				<xsl:value-of select="format-number(ChargeAmount,'#,##0.00')"/>
			</td>
			<td><xsl:value-of select="ChargeCurrency"/></td>
			<td>
				<xsl:attribute name="class">
					<xsl:if test="LocalAmount &lt; 0">negative</xsl:if>
					number
				</xsl:attribute>
				<xsl:value-of select="format-number(LocalAmount,'#,##0.00')"/>
			</td>
			<td><xsl:value-of select="LocalCurrency"/></td>
			<td><xsl:value-of select="sorter"/></td>
		</tr>	
    </xsl:for-each>
	</table>
	
	<!-- Separate treatment for the customer invoices -->
	<h2>Customer invoices</h2>
	<xsl:for-each select="utb:TransactionBatch/utb:TransactionCollection/utb:Transaction[utb:Ledger='AR'][utb:TransactionType='INV']">
		<h3><xsl:value-of select="utb:Number"/> | 
			<xsl:value-of select="utb:OrganizationAddress/utb:CompanyName"/> | 
			<xsl:value-of select="utb:OSCurrency/utb:Code"/><xsl:text> </xsl:text>
			<xsl:value-of select="utb:OSTotal"/></h3>
		<table class="posting">
			<caption>Create a journal YSI</caption>
			<tr>
				<th rowspan="2">#</th>
				<th rowspan="2">Date</th>
				<th rowspan="2">Voucher</th>
				<th colspan="4">Main</th>
				<th rowspan="2">Debit</th>
				<th rowspan="2">Credit</th>
				<th colspan="4">Offset</th>
				<th rowspan="2">Currency</th>
				<th rowspan="2">Ex.rate</th>
				<th rowspan="2">Item ST Group</th>
				<th rowspan="2">ST Group</th>
			</tr>
			<tr>
				<th>Company</th>
				<th>Account type</th>
				<th>Account</th>
				<th>Description</th>
				<th>Company</th>
				<th>Account type</th>
				<th>Account</th>
				<th>Transaction text</th>
			</tr>
			<tr>
				<td>1</td>
				<td><xsl:call-template name="formatdate"><xsl:with-param name="DateTimeStr" select="utb:TransactionDate"/></xsl:call-template></td>
				<td><em>Assigned by D365</em></td>
				<td><em>From interface context</em></td>
				<td>Customer</td>
				<td><xsl:value-of select="utb:OrganizationAddress/utb:OrganizationCode"/></td>
				<td><xsl:value-of select="utb:Number"/></td>
				<td><xsl:attribute name="class">number</xsl:attribute><xsl:value-of select="utb:OSTotal"/></td>
				<td><xsl:attribute name="class">number</xsl:attribute>-</td>
				<td>Same</td>
				<td>Ledger</td>
				<td>n/a</td>
				<td>n/a</td>
				<td><xsl:value-of select="utb:OSCurrency/utb:Code"/></td>
				<td><xsl:attribute name="class">number</xsl:attribute><xsl:value-of select="1 div utb:ExchangeRate"/></td>
				<td>n/a</td>
				<td>n/a</td>
			</tr>
			<tr>
				<td colspan="8">
					<table class="posting">
					<caption>Invoice tab</caption>
						<tr>
							<th>Posting profile</th>
							<th>Invoice</th>
							<th>Document date</th>
							<th>Due date</th>
							<th>Payment terms</th>
							<th>Created by</th>
						</tr>
						<tr>
							<td><em>From customer MD</em></td>
							<td><xsl:value-of select="utb:Number"/></td>
							<td><xsl:call-template name="formatdate"><xsl:with-param name="DateTimeStr" select="utb:PostDate"/></xsl:call-template></td>
							<td><xsl:call-template name="formatdate"><xsl:with-param name="DateTimeStr" select="utb:DueDate"/></xsl:call-template></td>
							<td><em>From customer MD</em></td>
							<td><em>From translaion (<xsl:value-of select="utb:CreateUser"/>)</em></td>
						</tr>
					</table>
				</td>
				<td colspan="9"> </td>
			</tr>
			<xsl:for-each select="utb:PostingJournalCollection">
				<xsl:for-each select="utb:PostingJournal">
					<tr>
						<td><xsl:value-of select="position()+1"/></td>
						<td>same</td>
						<td>same</td>
						<td>same</td>
						<td>Ledger</td>
						<td>n/a</td>
						<td>n/a</td>
						<td><xsl:attribute name="class">number</xsl:attribute><xsl:value-of select="utb:ChargeTotalAmount"/></td>
						<td><xsl:attribute name="class">number</xsl:attribute>-</td>
						<td>same</td>
						<td>Ledger</td>
						<td><em>See details</em></td>
						<td><xsl:value-of select="utb:Description"/></td>
						<td><xsl:value-of select="utb:ChargeCurrency/utb:Code"/></td>
						<td><xsl:attribute name="class">number</xsl:attribute><xsl:value-of select="1 div utb:ChargeExchangeRate"/></td>
						<td><em>From translaion (<xsl:value-of select="utb:VATTaxID/utb:TaxCode"/>)</em></td>
						<td><em>Get from customer MD</em></td>
					</tr>
					<tr>
						<td colspan="8">
							<xsl:if test="utb:LocalGSTVATAmount != 0">
							<table class="posting">
								<tr>
									<td>Actual sales tax amount</td>
									<td class="number"><xsl:value-of select="utb:LocalGSTVATAmount"/></td>
								</tr>
							</table>
							</xsl:if>
						</td>
						<td colspan="9">
							<table class="posting">
								<caption>Financial dimensions</caption>
								<tr>
									<th>Account</th>
									<th>Department</th>
									<th>Product</th>
									<th>Division</th>
									<th>End customer</th>
									<th>Local account</th>
									<th>Location</th>
									<th>Shipment</th>
								</tr>
								<tr>
									<td><em>Get from item <xsl:value-of select="concat(utb:ChargeCode/utb:Code,'-',../../utb:Department/utb:Code)"/></em></td>
									<td><em>Translation by OpCo</em></td>
									<td><em>Get from item <xsl:value-of select="concat(utb:ChargeCode/utb:Code,'-',../../utb:Department/utb:Code)"/></em></td>
									<td><em>Derive from Product</em></td>
									<td><xsl:value-of select="../../utb:LocalClient"/></td>
									<td><em>Defaulted from main account</em></td>
									<!-- <td><xsl:value-of select="utb:GLAccount/utb:AccountCode"/></td> -->
									<td><em>Translation by OpCo (<xsl:value-of select="utb:Branch/utb:Code"/>)</em></td>
									<td><xsl:value-of select="utb:Job/utb:Key"/></td>
								</tr>
							</table>
						</td>
					</tr>
				</xsl:for-each>
			</xsl:for-each>
		</table>
	</xsl:for-each>
</body>
</html>
</xsl:template>
</xsl:stylesheet>

