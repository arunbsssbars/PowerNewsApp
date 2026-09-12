const RSS_FEEDS = [
  // Premier Power Sector Publications
  { source: 'Power Line Magazine', url: 'https://powerline.net.in/feed/', isStrictPowerFeed: true },
  { source: 'Power Line Generation', url: 'https://powerline.net.in/category/generation/feed/', isStrictPowerFeed: true },
  { source: 'Power Line Transmission', url: 'https://powerline.net.in/category/transmission/feed/', isStrictPowerFeed: true },
  { source: 'Power Line Distribution', url: 'https://powerline.net.in/category/distribution/feed/', isStrictPowerFeed: true },
  { source: 'Power Line Finance & Policy', url: 'https://powerline.net.in/category/finance/feed/', isStrictPowerFeed: true },
  { source: 'Power Line Intelligence', url: 'https://news.google.com/rss/search?q=site:powerline.net.in&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: true },
  { source: 'PIB Ministry of Power', url: 'https://www.pib.gov.in/RssMain.aspx?ModId=6&Lang=1', isStrictPowerFeed: true },
  { source: 'PIB Ministry of Power Press Releases', url: 'https://news.google.com/rss/search?q=site:pib.gov.in+(%22Ministry+of+Power%22+OR+%22Power+Ministry%22+OR+NTPC+OR+PGCIL)&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: true },
  { source: 'Mercom India Clean Energy', url: 'https://mercomindia.com/feed/', isStrictPowerFeed: true },
  { source: 'ETEnergyWorld Power', url: 'https://energy.economictimes.indiatimes.com/rss/power', isStrictPowerFeed: true },
  { source: 'ETEnergyWorld Renewables', url: 'https://energy.economictimes.indiatimes.com/rss/renewable', isStrictPowerFeed: true },

  // Well-Established National & Financial Newspapers
  { source: 'Economic Times Power', url: 'https://economictimes.indiatimes.com/industry/energy/power/rssfeeds/13358311.cms', isStrictPowerFeed: true },
  { source: 'Economic Times Renewables', url: 'https://economictimes.indiatimes.com/industry/renewables/rssfeeds/80517789.cms', isStrictPowerFeed: true },
  { source: 'The Hindu Business & Energy', url: 'https://news.google.com/rss/search?q=site:thehindu.com+(electricity+OR+"power+grid"+OR+DISCOM+OR+UPPCL+OR+"solar+power"+OR+substation)&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: true },
  { source: 'Business Standard Energy', url: 'https://news.google.com/rss/search?q=site:business-standard.com+("power+sector"+OR+electricity+OR+substation+OR+DISCOM+OR+CERC+OR+NTPC)&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: true },
  { source: 'Times of India Power', url: 'https://news.google.com/rss/search?q=site:timesofindia.indiatimes.com+("power+tariff"+OR+DISCOM+OR+"power+cut"+OR+"smart+meter"+OR+UPPCL+OR+BESCOM)&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: true },
  { source: 'Financial Express Energy', url: 'https://news.google.com/rss/search?q=site:financialexpress.com+("power+sector"+OR+electricity+OR+"transmission+line"+OR+solar+OR+BESS)&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: true },
  { source: 'LiveMint Power & Utilities', url: 'https://news.google.com/rss/search?q=site:livemint.com+("power+sector"+OR+"electricity+grid"+OR+DISCOM+OR+"renewable+energy")&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: true },

  // Specialized Grid, SCADA & Industry Feeds
  { source: 'Smart Utilities & SCADA', url: 'https://news.google.com/rss/search?q=SCADA+automation+(UPPCL+OR+UP+OR+India)+power+grid+communication+substation+"IEC+60870"&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: true },
  { source: 'Saur Energy & Mercom Grid IT', url: 'https://news.google.com/rss/search?q=(SCADA+OR+"automated+grid"+OR+"Smart+Utilities"+OR+OPGW+OR+PSDF+OR+"IEC+60870"+OR+"IEC+61850")+India+power&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: true },
  { source: 'Power Line Grid Automation', url: 'https://news.google.com/rss/search?q="Power+Line"+(SCADA+OR+automation+OR+IT-OT+OR+RDSS+OR+DMS+OR+OPGW)&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: true },
  { source: 'India Power Sector News', url: 'https://news.google.com/rss/search?q=India+power+sector+OR+electricity+grid+OR+substation+OR+DISCOM+OR+CERC&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },
  { source: 'India Solar & Renewable Grid', url: 'https://news.google.com/rss/search?q=India+solar+power+OR+wind+energy+OR+BESS+OR+SECI+tender&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },
  { source: 'India DISCOMs & Tariffs', url: 'https://news.google.com/rss/search?q=India+smart+meter+OR+DISCOM+tariff+OR+power+cut+OR+RDSS&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },

  // Big Player & OEM Feeds (Siemens, ABB, Schneider, BHEL, L&T, Hitachi, etc.)
  { source: 'Power Engineering & OEMs', url: 'https://news.google.com/rss/search?q=Siemens+Energy+India+OR+ABB+India+power+OR+Schneider+Electric+India+grid+OR+Hitachi+Energy+India&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },
  { source: 'BHEL & L&T Power Grid', url: 'https://news.google.com/rss/search?q=BHEL+power+plant+OR+LT+transmission+substation+OR+GE+Vernova+India+grid&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },
  { source: 'Smart Metering & Telemetry OEMs', url: 'https://news.google.com/rss/search?q=("Secure+Meters"+OR+"Genus+Power"+OR+"smart+meter"+OR+"HPL+Electric")+India+power&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },
  { source: 'Uttar Pradesh Power & UPPCL', url: 'https://news.google.com/rss/search?q=Uttar+Pradesh+UPPCL+OR+Lucknow+power+cut+OR+electricity+tariff+OR+smart+meter+OR+UPERC&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },
  { source: 'POWERGRID News', url: 'https://news.google.com/rss/search?q=POWERGRID+OR+PGCIL+transmission+substation+India&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },
  { source: 'NTPC & Gencos', url: 'https://news.google.com/rss/search?q=NTPC+power+plant+OR+NTPC+Green+Energy+OR+thermal+hydro&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },
  { source: 'SECI & Tenders', url: 'https://news.google.com/rss/search?q=SECI+solar+tender+OR+ISTS+bidding+OR+NHPC+renewable&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },

  // City-Specific Outlets
  { source: 'Delhi & NCR Power Feed', url: 'https://news.google.com/rss/search?q=Delhi+power+tariff+OR+BSES+OR+TPDDL+OR+power+cut&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },
  { source: 'Maharashtra & Mumbai Power', url: 'https://news.google.com/rss/search?q=Maharashtra+MSEDCL+OR+Mumbai+electricity+tariff+OR+Adani+Electricity+OR+Mahagenco&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },
  { source: 'Karnataka & Bengaluru Power', url: 'https://news.google.com/rss/search?q=Bengaluru+BESCOM+OR+Karnataka+electricity+tariff+OR+power+cut+OR+KPTCL&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },
  { source: 'Telangana & Hyderabad Power', url: 'https://news.google.com/rss/search?q=Hyderabad+TSSPDCL+OR+Telangana+power+tariff+OR+TSTRANSCO&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },
  { source: 'Tamil Nadu & Chennai Power', url: 'https://news.google.com/rss/search?q=Chennai+TANGEDCO+OR+Tamil+Nadu+power+cut+OR+electricity+tariff&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },
  { source: 'Rajasthan & Jaipur Power', url: 'https://news.google.com/rss/search?q=Rajasthan+solar+park+OR+JVVNL+OR+Jaipur+electricity+tariff&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },
  { source: 'Gujarat Power & GUVNL', url: 'https://news.google.com/rss/search?q=Gujarat+GUVNL+OR+Torrent+Power+Ahmedabad+OR+solar+park&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: false },
];

const ALL_PREWARM_QUERIES = [
  // Major OEMs & Equipment Manufacturers
  'BHEL power plant substation India',
  'Hitachi Energy India grid transformer',
  'Siemens Energy India substation switchgear',
  'ABB India power grid relay',
  'Schneider Electric India smart grid',
  'Larsen Toubro power transmission substation',
  'GE Vernova India grid solutions',
  'Secure Meters smart metering India',
  'Genus Power smart meter India',
  'Genus Power Infrastructures smart meter',
  'CG Power transformer India',
  'KEC International transmission tower India',
  'Kalpataru Projects transmission line India',
  'Sterlite Power transmission India',
  'Toshiba India transmission distribution',
  'Mitsubishi Electric India switchgear',
  'Apar Industries conductor India',
  'Polycab cables India power',
  'Havells switchgear India industrial',
  'Waaree solar module India',
  'Suzlon wind energy India',
  'Inox Wind turbine India',
  'Vikram Solar panel India',
  'Premier Energies solar India',
  'Eaton power grid India',
  'Delta Electronics inverter India',
  'SEL relay protection India',

  // Central Utilities & PSUs
  'NTPC power plant generation India',
  'POWERGRID transmission substation India',
  'NHPC hydropower India',
  'SJVN renewable energy India',
  'SECI solar wind tender India',
  'IREDA renewable finance India',
  'REC Limited PFC power finance India',

  // Private Power Utilities
  'Tata Power distribution renewable India',
  'Adani Power green energy India',
  'Adani Electricity Mumbai distribution',
  'JSW Energy renewable India',
  'Torrent Power Gujarat distribution',
  'Reliance Power new energy India',
  'Greenko pumped storage India',
  'ReNew Power renewable India',

  // State DISCOMs — North India
  'UPPCL smart meter UP electricity tariff',
  'MVVNL PVVNL PUVVNL DVVNL Uttar Pradesh power',
  'PSPCL Punjab electricity tariff power cut',
  'DHBVN UHBVN Haryana electricity tariff',
  'JBVNL Jharkhand power distribution',
  'NBPDCL SBPDCL Bihar electricity',
  'HPSEBL Himachal Pradesh electricity',
  'UPCL Uttarakhand power',
  'JPDCL KPDCL Jammu Kashmir electricity',

  // State DISCOMs — West India
  'MSEDCL Maharashtra electricity tariff discom',
  'GUVNL UGVCL DGVCL Gujarat solar power',
  'CSPDCL Chhattisgarh power distribution',
  'MPPKVVCL MPMKVVCL Madhya Pradesh electricity',

  // State DISCOMs — South India
  'TANGEDCO Tamil Nadu power tariff',
  'TSSPDCL TSNPDCL Telangana electricity Hyderabad',
  'APSPDCL APEPDCL Andhra Pradesh power',
  'BESCOM KPTCL Karnataka electricity Bengaluru',
  'KSEB Kerala power electricity',

  // State DISCOMs — East India
  'WBSEDCL CESC West Bengal electricity Kolkata',
  'TPCODL TPWODL TPNODL TPSODL Odisha power',
  'APDCL Assam power distribution',

  // City-level Power News
  'Delhi BSES TPDDL power cut tariff DERC',
  'Mumbai Adani Electricity tariff power outage',
  'Bengaluru BESCOM power cut electricity bill',
  'Hyderabad TSSPDCL electricity tariff load shedding',
  'Chennai TANGEDCO power cut tariff',
  'Kolkata CESC electricity tariff power',
  'Jaipur JVVNL Rajasthan solar power',
  'Lucknow UPPCL power meter tariff',
  'Ahmedabad Torrent Power GUVNL electricity',
  'Pune MSEDCL electricity tariff',

  // Thematic / Technology
  'RDSS smart metering India distribution reform',
  'BESS battery storage India grid',
  'Green Hydrogen India electrolyser power',
  'PM Surya Ghar rooftop solar India',
  'HVDC transmission India powergrid',
  'GIS substation India 765kV 400kV',
  'IEC 61850 SCADA automation India substation',
  'CERC SERC tariff order electricity regulation India',
  'Open access electricity India IEX',
  'Solar park SECI tender auction India',
  'Wind energy offshore onshore India tender'
];

module.exports = {
  RSS_FEEDS,
  ALL_PREWARM_QUERIES,
};
