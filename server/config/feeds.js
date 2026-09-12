const RSS_FEEDS = [
  // Premier Power Sector Publications
  { source: 'Power Line Magazine', url: 'https://powerline.net.in/feed/', isStrictPowerFeed: true },
  { source: 'Power Line Generation', url: 'https://powerline.net.in/category/generation/feed/', isStrictPowerFeed: true },
  { source: 'Power Line Transmission', url: 'https://powerline.net.in/category/transmission/feed/', isStrictPowerFeed: true },
  { source: 'Power Line Distribution', url: 'https://powerline.net.in/category/distribution/feed/', isStrictPowerFeed: true },
  { source: 'Power Line Finance & Policy', url: 'https://powerline.net.in/category/finance/feed/', isStrictPowerFeed: true },
  { source: 'Power Line Intelligence', url: 'https://news.google.com/rss/search?q=site:powerline.net.in&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: true },
  { source: 'PIB Ministry of Power', url: 'https://news.google.com/rss/search?q=site:pib.gov.in+(%22Ministry+of+Power%22+OR+%22Power+Ministry%22+OR+NTPC+OR+PGCIL+OR+REC+OR+PFC)&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: true },
  { source: 'PIB Renewable Energy (MNRE)', url: 'https://news.google.com/rss/search?q=site:pib.gov.in+(%22Ministry+of+New+and+Renewable+Energy%22+OR+MNRE+OR+SECI)&hl=en-IN&gl=IN&ceid=IN:en', isStrictPowerFeed: true },
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
  // 1. Grid OEMs & High-Voltage Equipment
  '(BHEL OR "Hitachi Energy" OR Siemens OR ABB OR Schneider OR "GE Vernova" OR "L&T") (substation OR transformer OR grid OR power) India',
  // 2. Transmission Lines, EPC & Cable Infrastructure
  '("Sterlite Power" OR "KEC International" OR Kalpataru OR "CG Power" OR Apar OR Polycab OR Havells) (transmission OR conductor OR cables OR substation) India',
  // 3. Smart Metering & National AMI Rollout
  '("Secure Meters" OR "Genus Power" OR "HPL Electric" OR RDSS) (smart meter OR AMI OR prepaid meter) India',
  // 4. Solar Modules & Wind Turbine OEMs
  '(Waaree OR Suzlon OR "Inox Wind" OR "Vikram Solar" OR "Premier Energies") (solar OR wind OR turbine OR module) India',
  // 5. Central Power PSUs & Public Financing
  '(NTPC OR POWERGRID OR NHPC OR SJVN OR SECI OR IREDA OR PFC OR REC) (power OR renewable OR transmission OR tariff) India',
  // 6. Major Private Utilities & IPPs
  '("Tata Power" OR "Adani Power" OR "Adani Energy Solutions" OR "JSW Energy" OR "Torrent Power" OR "Reliance Power" OR Greenko OR ReNew) (power OR solar OR wind OR discom) India',
  // 7. North India State DISCOMs
  '(UPPCL OR MVVNL OR PVVNL OR PUVVNL OR DVVNL OR PSPCL OR DHBVN OR UHBVN) (electricity OR tariff OR power cut) India',
  // 8. West India State DISCOMs
  '(MSEDCL OR Mahagenco OR GUVNL OR UGVCL OR DGVCL OR CSPDCL OR MPPKVVCL) (electricity OR tariff OR discom) India',
  // 9. South India State DISCOMs
  '(TANGEDCO OR TSSPDCL OR TSNPDCL OR APSPDCL OR BESCOM OR KPTCL OR KSEB) (electricity OR power tariff OR discom) India',
  // 10. East & Central State DISCOMs
  '(WBSEDCL OR CESC OR TPCODL OR TPWODL OR TPNODL OR TPSODL OR APDCL OR JBVNL) (electricity OR power distribution) India',
  // 11. Metro City Power Utilities & Supply
  '(Delhi BSES OR TPDDL OR "Adani Electricity Mumbai" OR "CESC Kolkata" OR "BESCOM Bengaluru") (power cut OR electricity tariff OR bill)',
  // 12. Battery Energy Storage (BESS) & Pumped Hydro
  '("BESS" OR "battery energy storage" OR "pumped storage") (power grid OR CEA OR SECI) India',
  // 13. Green Hydrogen & Clean Energy Transition
  '("Green Hydrogen" OR electrolyser OR "National Green Hydrogen Mission") (power OR energy OR MNRE) India',
  // 14. PM Surya Ghar & Decentralized Rooftop Solar
  '("PM Surya Ghar" OR "rooftop solar" OR "solar park") (subsidy OR installation OR DISCOM) India',
  // 15. Grid Automation, SCADA, HVDC & GIS Substations
  '(HVDC OR "765 kV" OR "400 kV" OR "GIS substation" OR "IEC 61850" OR SCADA OR automation) (grid OR POWERGRID OR substation) India',
  // 16. Power Markets & Electricity Regulations
  '(CERC OR SERC OR "tariff order" OR "General Network Access" OR "Open Access" OR IEX) (electricity OR power) India',
];

module.exports = {
  RSS_FEEDS,
  ALL_PREWARM_QUERIES,
};
