// Order: Big Utilities, PSUs & Recognized Global/Indian OEMs
const UTILITY_PLAYER_RULES = [
  { player: 'UPPCL', keywords: ['uppcl', 'puvvnl', 'mvvnl', 'dvvnl', 'pvvnl', 'uttar pradesh power corporation'] },
  { player: 'POWERGRID', keywords: ['power grid corporation', 'powergrid', 'pgcil', 'power grid corp'] },
  { player: 'NTPC', keywords: ['ntpc limited', 'ntpc green', 'ntpc ltd', 'ntpc'] },
  { player: 'Tata Power', keywords: ['tata power', 'tpddl', 'tpsodl', 'tpnodl', 'tpwodl', 'tpcodl', 'tata power renewable', 'tata power solar'] },
  { player: 'Adani Power', keywords: ['adani power', 'adani green', 'adani electricity', 'aeml', 'adani energy solutions'] },
  { player: 'Siemens', keywords: ['siemens energy', 'siemens limited', 'siemens india', 'siemens transformer', 'siemens gis', 'siemens grid', 'siemens'] },
  { player: 'ABB', keywords: ['abb india', 'abb power', 'abb switchgear', 'abb substation', 'abb rtu', 'abb scada', 'abb'] },
  { player: 'Schneider', keywords: ['schneider electric', 'schneider grid', 'schneider smart grid', 'schneider switchgear', 'schneider energy', 'schneider power'] },
  { player: 'Hitachi Energy', keywords: ['hitachi energy', 'hitachi energy india', 'hitachi hvdc', 'hitachi power grid', 'hitachi scada', 'hitachi'] },
  { player: 'BHEL', keywords: ['bhel', 'bharat heavy electricals', 'bhel turbine', 'bhel boiler', 'bhel transformer', 'bhel substation'] },
  { player: 'L&T Power', keywords: ['larsen & toubro', 'l&t power', 'l&t transmission', 'l&t substation', 'l&t energy', 'l&t construction', 'l&t', 'larsen'] },
  { player: 'GE Vernova', keywords: ['ge vernova', 'ge power india', 'ge grid solutions', 'ge power', 'ge t&d india', 'ge t&d', 'ge vernova india'] },
  { player: 'CG Power', keywords: ['cg power', 'crompton greaves', 'cg power and industrial', 'cg power & industrial'] },
  { player: 'KEC International', keywords: ['kec international', 'kec transmission', 'rpg group kec', 'kec'] },
  { player: 'Kalpataru (KPIL)', keywords: ['kalpataru projects', 'kpil', 'kalpataru power transmission', 'kalpataru'] },
  { player: 'Sterlite Power', keywords: ['sterlite power', 'sterlite grid', 'sterlite transmission', 'sterlite'] },
  { player: 'Toshiba', keywords: ['toshiba transmission', 'toshiba energy', 'toshiba t&d india', 'toshiba'] },
  { player: 'Mitsubishi Electric', keywords: ['mitsubishi electric india', 'mitsubishi power', 'mitsubishi switchgear', 'mitsubishi'] },
  { player: 'Apar Industries', keywords: ['apar industries', 'apar conductor', 'apar transformer oil', 'apar'] },
  { player: 'Polycab', keywords: ['polycab india', 'polycab wires', 'polycab cables', 'polycab'] },
  { player: 'Havells', keywords: ['havells india', 'havells switchgear', 'havells industrial', 'havells'] },
  { player: 'Secure Meters', keywords: ['secure meters', 'secure smart meter', 'secure meter'] },
  { player: 'Genus Power', keywords: ['genus power infrastructures', 'genus smart meter', 'genus power', 'genus'] },
  { player: 'HPL Electric', keywords: ['hpl electric & power', 'hpl electric', 'hpl meter', 'hpl switchgear'] },
  { player: 'SEL (Schweitzer)', keywords: ['schweitzer engineering laboratories', 'sel relay', 'sel-411l', 'sel-751'] },
  { player: 'Eaton', keywords: ['eaton power', 'eaton grid', 'eaton electrical india'] },
  { player: 'Delta Electronics', keywords: ['delta electronics india', 'delta power solutions', 'delta inverter'] },
  { player: 'Waaree Energies', keywords: ['waaree energies', 'waaree solar', 'waaree module'] },
  { player: 'Suzlon Energy', keywords: ['suzlon energy', 'suzlon wind', 'suzlon turbine'] },
  { player: 'Inox Wind', keywords: ['inox wind', 'inox clean energy', 'inox green'] },
  { player: 'Premier Energies', keywords: ['premier energies', 'premier solar'] },
  { player: 'Goldi Solar', keywords: ['goldi solar', 'goldi modules'] },
  { player: 'Vikram Solar', keywords: ['vikram solar'] },
  { player: 'Reliance Power', keywords: ['reliance power', 'reliance infra', 'reliance new energy', 'rpower'] },
  { player: 'SECI', keywords: ['solar energy corporation of india', 'seci'] },
  { player: 'MSEDCL', keywords: ['msedcl', 'mahadiscom', 'mahagenco', 'mahatransco'] },
  { player: 'BESCOM', keywords: ['bescom', 'kptcl', 'kpcl', 'hescom', 'mescom'] },
  { player: 'TANGEDCO', keywords: ['tangedco', 'tantransco'] },
  { player: 'JSW Energy', keywords: ['jsw energy', 'jsw neo'] },
  { player: 'Torrent Power', keywords: ['torrent power'] },
  { player: 'NHPC', keywords: ['nhpc limited', 'nhpc ltd', 'nhpc'] },
  { player: 'CESC', keywords: ['cesc limited', 'cesc kolkata', 'cesc'] },
  { player: 'SJVN', keywords: ['sjvn limited', 'sjvn ltd', 'sjvn'] },
  { player: 'IREDA', keywords: ['ireda', 'indian renewable energy development agency'] },
  { player: 'REC/PFC', keywords: ['rec limited', 'pfc limited', 'power finance corporation', 'rural electrification corp'] }
];

const CITY_RULES = [
  { city: 'Delhi / NCR', state: 'Delhi', discom: 'BSES / TPDDL', aliases: ['delhi', 'new delhi', 'noida', 'greater noida', 'gurugram', 'gurgaon', 'ghaziabad', 'faridabad', 'derc', 'bses', 'tpddl', 'delhi transco'] },
  { city: 'Mumbai', state: 'Maharashtra', discom: 'MSEDCL / Adani', aliases: ['mumbai', 'navi mumbai', 'thane', 'best undertaking', 'tata power mumbai', 'adani electricity', 'merc'] },
  { city: 'Bengaluru', state: 'Karnataka', discom: 'BESCOM', aliases: ['bengaluru', 'bangalore', 'bescom', 'kptcl', 'kerc', 'hescom', 'mescom'] },
  { city: 'Hyderabad', state: 'Telangana', discom: 'TSSPDCL', aliases: ['hyderabad', 'secunderabad', 'tsspdcl', 'tsnpdcl', 'tstransco', 'tsgenco'] },
  { city: 'Chennai', state: 'Tamil Nadu', discom: 'TANGEDCO', aliases: ['chennai', 'tangedco', 'tantransco', 'tamil nadu power', 'tnerc'] },
  { city: 'Kolkata', state: 'West Bengal', discom: 'CESC / WBSEDCL', aliases: ['kolkata', 'calcutta', 'cesc', 'wbsedcl', 'wbsetcl', 'wberc'] },
  { city: 'Jaipur', state: 'Rajasthan', discom: 'JVVNL', aliases: ['jaipur', 'jvvnl', 'jdvvnl', 'avvnl', 'rvunl', 'rvpnl', 'rajasthan discom'] },
  { city: 'Lucknow', state: 'Uttar Pradesh', discom: 'UPPCL', aliases: ['lucknow', 'uppcl', 'mvvnl', 'pvvnl', 'puvvnl', 'dvvnl', 'kanpur power', 'varanasi power', 'up electricity', 'bulandshahr', 'meerut', 'agra'] },
  { city: 'Ahmedabad', state: 'Gujarat', discom: 'Torrent / GUVNL', aliases: ['ahmedabad', 'surat', 'vadodara', 'torrent power', 'guvnl', 'ugvcl', 'dgvcl', 'pgvcl', 'mgvcl'] },
  { city: 'Patna', state: 'Bihar', discom: 'NBPDCL / SBPDCL', aliases: ['patna', 'bihar power', 'nbpdcl', 'sbpdcl', 'bsptcl'] },
  { city: 'Chandigarh', state: 'Punjab & Haryana', discom: 'PSPCL / DHBVN', aliases: ['chandigarh', 'pspcl', 'pstcl', 'dhbvn', 'uhbvn'] },
  { city: 'Bhopal', state: 'Madhya Pradesh', discom: 'MPPKVVCL', aliases: ['bhopal', 'indore', 'mppkvvcl', 'mpmkvvcl', 'mppmcl', 'mptransco'] },
  { city: 'Bhubaneswar', state: 'Odisha', discom: 'TPCODL', aliases: ['bhubaneswar', 'cuttack', 'optcl', 'gridco', 'tpcodl', 'tpwodl', 'tpnodl', 'tpsodl'] },
  { city: 'Pune', state: 'Maharashtra', discom: 'MSEDCL', aliases: ['pune', 'pimpri', 'mahadiscom pune', 'pune power'] },
  { city: 'Kochi', state: 'Kerala', discom: 'KSEB', aliases: ['kochi', 'thiruvananthapuram', 'kseb', 'ksebl'] },
  { city: 'Guwahati', state: 'Assam', discom: 'APDCL', aliases: ['guwahati', 'assam power', 'apdcl', 'aegcl'] },
  { city: 'Meerut', state: 'Uttar Pradesh', discom: 'UPPCL', aliases: ['meerut', 'uppcl', 'pvvnl'] },
  { city: 'Bulandshahr', state: 'Uttar Pradesh', discom: 'UPPCL', aliases: ['bulandshahr', 'uppcl', 'pvvnl'] },
  { city: 'Agra', state: 'Uttar Pradesh', discom: 'UPPCL', aliases: ['agra', 'uppcl', 'dvvnl'] },
  { city: 'Noida', state: 'Uttar Pradesh', discom: 'UPPCL', aliases: ['noida', 'uppcl', 'pvvnl'] },
  { city: 'Moradabad', state: 'Uttar Pradesh', discom: 'UPPCL', aliases: ['moradabad', 'uppcl', 'pvvnl'] },
  { city: 'Mathura', state: 'Uttar Pradesh', discom: 'UPPCL', aliases: ['mathura', 'uppcl', 'dvvnl'] },
  { city: 'Ghaziabad', state: 'Uttar Pradesh', discom: 'UPPCL', aliases: ['ghaziabad', 'uppcl', 'pvvnl'] },
  { city: 'Gautam Buddha Nagar', state: 'Uttar Pradesh', discom: 'UPPCL', aliases: ['gautam buddha nagar', 'uppcl', 'pvvnl'] },
  { city: 'Greater Noida', state: 'Uttar Pradesh', discom: 'UPPCL', aliases: ['greater noida', 'uppcl', 'pvvnl'] },
  { city: 'Jewar', state: 'Uttar Pradesh', discom: 'UPPCL', aliases: ['jewar', 'uppcl', 'pvvnl'] },
  { city: 'Khurja', state: 'Uttar Pradesh', discom: 'UPPCL', aliases: ['khurja', 'uppcl', 'pvvnl'] },
];

const STATE_RULES = [
  { state: 'Uttar Pradesh', aliases: ['uttar pradesh', 'up discom', 'uppcl', 'puvvnl', 'mvvnl', 'dvvnl', 'pvvnl', 'lucknow', 'noida', 'kanpur', 'varanasi', 'bulandshahr', 'meerut', 'agra', 'prayagraj'] },
  { state: 'Maharashtra', aliases: ['maharashtra', 'msedcl', 'mahagenco', 'mahatransco', 'mumbai', 'pune', 'nagpur', 'best undertaking', 'mahadiscom'] },
  { state: 'Gujarat', aliases: ['gujarat', 'guvnl', 'ugvcl', 'dgvcl', 'pgvcl', 'mgvcl', 'gseb', 'torrent power', 'ahmedabad'] },
  { state: 'Tamil Nadu', aliases: ['tamil nadu', 'tangedco', 'tantransco', 'chennai', 'coimbatore', 'madurai'] },
  { state: 'Karnataka', aliases: ['karnataka', 'bescom', 'hescom', 'mescom', 'cesc mysore', 'kptcl', 'kpcl', 'bengaluru', 'bangalore'] },
  { state: 'Telangana', aliases: ['telangana', 'tsspdcl', 'tsnpdcl', 'tstransco', 'tsgenco', 'hyderabad'] },
  { state: 'Andhra Pradesh', aliases: ['andhra pradesh', 'apspdcl', 'apepdcl', 'apcerc', 'aptransco', 'apgenco', 'visakhapatnam'] },
  { state: 'Rajasthan', aliases: ['rajasthan', 'jvvnl', 'avvnl', 'jdvvnl', 'rvunl', 'rvpnl', 'jaipur', 'jodhpur', 'bikaner'] },
  { state: 'Madhya Pradesh', aliases: ['madhya pradesh', 'mpseb', 'mppkvvcl', 'mppmcl', 'bhopal', 'indore'] },
  { state: 'West Bengal', aliases: ['west bengal', 'wbsedcl', 'wbsetcl', 'cesc kolkata', 'kolkata'] },
  { state: 'Delhi', aliases: ['delhi', 'new delhi', 'bses rajdhani', 'bses yamuna', 'tpddl', 'derc', 'delhi transco'] },
  { state: 'Punjab', aliases: ['punjab', 'pspcl', 'pstcl', 'ludhiana', 'amritsar'] },
  { state: 'Haryana', aliases: ['haryana', 'dhbvn', 'uhbvn', 'hvpn', 'gurugram', 'faridabad'] },
  { state: 'Odisha', aliases: ['odisha', 'gridco', 'optcl', 'tata power odisha', 'tpsodl', 'tpnodl', 'tpwodl', 'tpcodl', 'bhubaneswar'] },
  { state: 'Kerala', aliases: ['kerala', 'kseb', 'ksebl', 'kochi', 'thiruvananthapuram'] },
  { state: 'Bihar', aliases: ['bihar', 'nbpdcl', 'sbpdcl', 'bsptcl', 'patna'] },
  { state: 'Assam', aliases: ['assam', 'apdcl', 'aegcl', 'apgcl', 'guwahati'] },
  { state: 'Himachal Pradesh', aliases: ['himachal pradesh', 'hpsebl', 'hppcl', 'shimla'] },
  { state: 'Uttarakhand', aliases: ['uttarakhand', 'upcl', 'ptcul', 'ujvnl', 'dehradun'] },
  { state: 'Jammu & Kashmir', aliases: ['jammu & kashmir', 'j&k', 'jkpdd', 'jpdcl', 'opdcl'] },
  { state: 'Jharkhand', aliases: ['jharkhand', 'jbvnl', 'jusnl', 'ranchi'] },
  { state: 'Chhattisgarh', aliases: ['chhattisgarh', 'cspdcl', 'csptcl', 'cspgcl', 'raipur'] },
];

const STATE_DISCOM_DIRECTORY = {
  'Uttar Pradesh': [
    { code: 'UPPCL', name: 'UP Power Corporation (State-wide)' },
    { code: 'PUVVNL', name: 'Purvanchal Vidyut Vitaran (Varanasi/Prayagraj)' },
    { code: 'MVVNL', name: 'Madhyanchal Vidyut Vitaran (Lucknow/Ayodhya)' },
    { code: 'PVVNL', name: 'Paschimanchal Vidyut Vitaran (Meerut/Noida)' },
    { code: 'DVVNL', name: 'Dakshinanchal Vidyut Vitaran (Agra/Aligarh)' },
    { code: 'KESCO', name: 'Kanpur Electricity Supply Co.' },
    { code: 'NPCL', name: 'Noida Power Company Limited' }
  ],
  'Delhi': [
    { code: 'BRPL', name: 'BSES Rajdhani Power Limited' },
    { code: 'BYPL', name: 'BSES Yamuna Power Limited' },
    { code: 'TPDDL', name: 'Tata Power Delhi Distribution' },
    { code: 'NDMC', name: 'New Delhi Municipal Council' }
  ],
  'Maharashtra': [
    { code: 'MSEDCL', name: 'Mahavitaran (MSEDCL)' },
    { code: 'Adani Electricity', name: 'Adani Electricity Mumbai (AEML)' },
    { code: 'Tata Power Mumbai', name: 'Tata Power Mumbai Distribution' },
    { code: 'BEST', name: 'BEST Undertaking Mumbai' }
  ],
  'Gujarat': [
    { code: 'GUVNL', name: 'Gujarat Urja Vikas Nigam' },
    { code: 'UGVCL', name: 'Uttar Gujarat Vij Company' },
    { code: 'DGVCL', name: 'Dakshin Gujarat Vij Company' },
    { code: 'MGVCL', name: 'Madhya Gujarat Vij Company' },
    { code: 'PGVCL', name: 'Paschim Gujarat Vij Company' },
    { code: 'Torrent Power', name: 'Torrent Power (Ahmedabad/Surat)' }
  ],
  'Karnataka': [
    { code: 'BESCOM', name: 'Bangalore Electricity Supply (BESCOM)' },
    { code: 'MESCOM', name: 'Mangalore Electricity Supply (MESCOM)' },
    { code: 'HESCOM', name: 'Hubli Electricity Supply (HESCOM)' },
    { code: 'GESCOM', name: 'Gulbarga Electricity Supply (GESCOM)' },
    { code: 'CHESCOM', name: 'Chamundeshwari Electricity (CESC)' }
  ],
  'Tamil Nadu': [
    { code: 'TANGEDCO', name: 'Tamil Nadu Gen & Dist Corp (TANGEDCO)' }
  ],
  'Telangana': [
    { code: 'TSSPDCL', name: 'Southern Power Distribution Telangana' },
    { code: 'TSNPDCL', name: 'Northern Power Distribution Telangana' }
  ],
  'Andhra Pradesh': [
    { code: 'APSPDCL', name: 'Southern Power Distribution AP' },
    { code: 'APEPDCL', name: 'Eastern Power Distribution AP' },
    { code: 'APCPDCL', name: 'Central Power Distribution AP' }
  ],
  'Rajasthan': [
    { code: 'JVVNL', name: 'Jaipur Vidyut Vitran Nigam' },
    { code: 'AVVNL', name: 'Ajmer Vidyut Vitran Nigam' },
    { code: 'JdVVNL', name: 'Jodhpur Vidyut Vitran Nigam' }
  ],
  'Madhya Pradesh': [
    { code: 'MPMKVVCL', name: 'Madhya Kshetra (Bhopal/Gwalior)' },
    { code: 'MPPKVVCL-West', name: 'Paschim Kshetra (Indore/Ujjain)' },
    { code: 'MPPKVVCL-East', name: 'Poorv Kshetra (Jabalpur/Rewa)' }
  ],
  'Punjab': [
    { code: 'PSPCL', name: 'Punjab State Power Corporation' }
  ],
  'Haryana': [
    { code: 'DHBVN', name: 'Dakshin Haryana Bijli Vitran (Gurugram)' },
    { code: 'UHBVN', name: 'Uttar Haryana Bijli Vitran (Panchkula)' }
  ],
  'West Bengal': [
    { code: 'WBSEDCL', name: 'West Bengal State Electricity Distribution' },
    { code: 'CESC', name: 'CESC Limited (Kolkata & Howrah)' }
  ],
  'Bihar': [
    { code: 'NBPDCL', name: 'North Bihar Power Distribution' },
    { code: 'SBPDCL', name: 'South Bihar Power Distribution' }
  ],
  'Odisha': [
    { code: 'TPCODL', name: 'Tata Power Central Odisha' },
    { code: 'TPWODL', name: 'Tata Power Western Odisha' },
    { code: 'TPNODL', name: 'Tata Power Northern Odisha' },
    { code: 'TPSODL', name: 'Tata Power Southern Odisha' }
  ],
  'Kerala': [
    { code: 'KSEB', name: 'Kerala State Electricity Board (KSEBL)' }
  ],
  'Assam': [
    { code: 'APDCL', name: 'Assam Power Distribution Company' }
  ],
  'Uttarakhand': [
    { code: 'UPCL', name: 'Uttarakhand Power Corporation' }
  ],
  'Himachal Pradesh': [
    { code: 'HPSEBL', name: 'Himachal Pradesh State Electricity Board' }
  ],
  'Jharkhand': [
    { code: 'JBVNL', name: 'Jharkhand Bijli Vitran Nigam' }
  ],
  'Chhattisgarh': [
    { code: 'CSPDCL', name: 'Chhattisgarh State Power Distribution' }
  ],
  'Jammu & Kashmir': [
    { code: 'JPDCL', name: 'Jammu Power Distribution Corporation' },
    { code: 'KPDCL', name: 'Kashmir Power Distribution Corporation' }
  ],
  'Goa': [
    { code: 'GED', name: 'Goa Electricity Department' }
  ]
};

const DISCOM_RULES = [
  // Uttar Pradesh
  { discom: 'PUVVNL', keywords: ['puvvnl', 'purvanchal vidyut', 'varanasi discom', 'prayagraj discom'] },
  { discom: 'MVVNL', keywords: ['mvvnl', 'madhyanchal vidyut', 'lucknow discom', 'ayodhya discom'] },
  { discom: 'PVVNL', keywords: ['pvvnl', 'paschimanchal vidyut', 'meerut discom', 'noida power discom'] },
  { discom: 'DVVNL', keywords: ['dvvnl', 'dakshinanchal vidyut', 'agra discom', 'aligarh discom'] },
  { discom: 'KESCO', keywords: ['kesco', 'kanpur electricity supply'] },
  { discom: 'NPCL', keywords: ['npcl', 'noida power company'] },
  { discom: 'UPPCL', keywords: ['uppcl', 'uttar pradesh power corporation', 'up discom'] },

  // Delhi
  { discom: 'BRPL', keywords: ['brpl', 'bses rajdhani', 'rajdhani power'] },
  { discom: 'BYPL', keywords: ['bypl', 'bses yamuna', 'yamuna power'] },
  { discom: 'TPDDL', keywords: ['tpddl', 'tata power delhi'] },
  { discom: 'NDMC', keywords: ['ndmc power', 'ndmc electricity'] },

  // Maharashtra
  { discom: 'MSEDCL', keywords: ['msedcl', 'mahadiscom', 'mahavitaran'] },
  { discom: 'Adani Electricity', keywords: ['adani electricity', 'aeml', 'adani electricity mumbai'] },
  { discom: 'Tata Power Mumbai', keywords: ['tata power mumbai', 'tata power distribution mumbai'] },
  { discom: 'BEST', keywords: ['best undertaking', 'best electricity', 'best mumbai'] },

  // Gujarat
  { discom: 'UGVCL', keywords: ['ugvcl', 'uttar gujarat vij'] },
  { discom: 'DGVCL', keywords: ['dgvcl', 'dakshin gujarat vij'] },
  { discom: 'MGVCL', keywords: ['mgvcl', 'madhya gujarat vij'] },
  { discom: 'PGVCL', keywords: ['pgvcl', 'paschim gujarat vij'] },
  { discom: 'Torrent Power', keywords: ['torrent power', 'torrent power ahmedabad', 'torrent power surat'] },
  { discom: 'GUVNL', keywords: ['guvnl', 'gujarat urja vikas'] },

  // Karnataka
  { discom: 'BESCOM', keywords: ['bescom', 'bangalore electricity supply', 'bengaluru discom'] },
  { discom: 'MESCOM', keywords: ['mescom', 'mangalore electricity supply'] },
  { discom: 'HESCOM', keywords: ['hescom', 'hubli electricity supply'] },
  { discom: 'GESCOM', keywords: ['gescom', 'gulbarga electricity supply'] },
  { discom: 'CHESCOM', keywords: ['chescom', 'cesc mysore', 'chamundeshwari electricity'] },

  // Tamil Nadu
  { discom: 'TANGEDCO', keywords: ['tangedco', 'tamil nadu generation and distribution', 'tantransco'] },

  // Telangana
  { discom: 'TSSPDCL', keywords: ['tsspdcl', 'southern power distribution telangana', 'hyderabad power'] },
  { discom: 'TSNPDCL', keywords: ['tsnpdcl', 'northern power distribution telangana', 'warangal power'] },

  // Andhra Pradesh
  { discom: 'APSPDCL', keywords: ['apspdcl', 'southern power distribution ap'] },
  { discom: 'APEPDCL', keywords: ['apepdcl', 'eastern power distribution ap', 'visakhapatnam power'] },
  { discom: 'APCPDCL', keywords: ['apcpdcl', 'central power distribution ap', 'vijayawada power'] },

  // Rajasthan
  { discom: 'JVVNL', keywords: ['jvvnl', 'jaipur vidyut vitran', 'jaipur discom'] },
  { discom: 'AVVNL', keywords: ['avvnl', 'ajmer vidyut vitran', 'ajmer discom'] },
  { discom: 'JdVVNL', keywords: ['jdvvnl', 'jodhpur vidyut vitran', 'jodhpur discom'] },

  // Madhya Pradesh
  { discom: 'MPMKVVCL', keywords: ['mpmkvvcl', 'madhya kshetra vidyut', 'bhopal discom'] },
  { discom: 'MPPKVVCL-West', keywords: ['mppkvvcl indore', 'paschim kshetra vidyut', 'indore discom'] },
  { discom: 'MPPKVVCL-East', keywords: ['mppkvvcl jabalpur', 'poorv kshetra vidyut', 'jabalpur discom'] },

  // Punjab & Haryana
  { discom: 'PSPCL', keywords: ['pspcl', 'punjab state power corp', 'punjab electricity board'] },
  { discom: 'DHBVN', keywords: ['dhbvn', 'dakshin haryana bijli', 'gurugram power'] },
  { discom: 'UHBVN', keywords: ['uhbvn', 'uttar haryana bijli', 'panchkula power'] },

  // West Bengal
  { discom: 'WBSEDCL', keywords: ['wbsedcl', 'west bengal state electricity distribution'] },
  { discom: 'CESC', keywords: ['cesc kolkata', 'cesc limited', 'cesc howrah'] },

  // Bihar
  { discom: 'NBPDCL', keywords: ['nbpdcl', 'north bihar power distribution'] },
  { discom: 'SBPDCL', keywords: ['sbpdcl', 'south bihar power distribution', 'patna discom'] },

  // Odisha
  { discom: 'TPCODL', keywords: ['tpcodl', 'tata power central odisha', 'bhubaneswar discom'] },
  { discom: 'TPWODL', keywords: ['tpwodl', 'tata power western odisha', 'sambalpur discom'] },
  { discom: 'TPNODL', keywords: ['tpnodl', 'tata power northern odisha', 'balasore discom'] },
  { discom: 'TPSODL', keywords: ['tpsodl', 'tata power southern odisha', 'berhampur discom'] },

  // Other States
  { discom: 'KSEB', keywords: ['kseb', 'ksebl', 'kerala state electricity board'] },
  { discom: 'APDCL', keywords: ['apdcl', 'assam power distribution', 'guwahati discom'] },
  { discom: 'UPCL', keywords: ['upcl', 'uttarakhand power corporation', 'dehradun discom'] },
  { discom: 'HPSEBL', keywords: ['hpsebl', 'himachal pradesh state electricity board'] },
  { discom: 'JBVNL', keywords: ['jbvnl', 'jharkhand bijli vitran', 'ranchi discom'] },
  { discom: 'CSPDCL', keywords: ['cspdcl', 'chhattisgarh state power distribution', 'raipur discom'] },
  { discom: 'JPDCL', keywords: ['jpdcl', 'jammu power distribution'] },
  { discom: 'KPDCL', keywords: ['kpdcl', 'kashmir power distribution', 'srinagar power'] },
  { discom: 'GED', keywords: ['goa electricity department', 'goa power'] }
];

const CATEGORY_RULES = [
  {
    category: 'generation',
    keywords: [
      'thermal power', 'hydro power', 'nuclear power', 'coal stock', 'generation capacity',
      'power plant', 'thermal plant', 'hydroelectric', 'ntpc', 'nhpc', 'genco', 'turbine',
      'megawatt', 'gigawatt', 'mw capacity', 'gw capacity', 'pumped storage', 'psp',
      'captive power', 'boiler', 'power generation', 'power generator',
      'generation unit', 'capacity addition', 'lignite', 'sasan ultra', 'bhel'
    ]
  },
  {
    category: 'transmission',
    keywords: [
      'transmission', 'substation', 'power grid', 'powergrid', 'gis substation', 'hvdc',
      'posoco', 'grid-india', 'sldc', 'rldc', 'nldc', 'transmission line', 'inter-regional',
      'ists', 'ctu', 'stu', 'grid frequency', 'wheeling', 'grid stability', 'national grid',
      'green energy corridor', 'grid connectivity', 'transmission tower', '765 kv', '400 kv',
      'grid synchronization', 'islanding scheme', 'power evacuation', 'transformer', 'switchgear'
    ]
  },
  {
    category: 'distribution',
    keywords: [
      'discom', 'distribution company', 'electricity bill', 'smart meter', 'smart metering',
      'power cut', 'load shedding', 'at&c loss', 'feeder', 'distribution transformer',
      'rdss', 'tariff revision', 'power tariff', 'power supply', 'consumer tariff', 'amisp',
      'power theft', 'distribution utility', 'bescom', 'msedcl', 'uppcl', 'tangedco',
      'billing efficiency', 'commercial loss', 'power outage', 'electricity supply', 'smart grid'
    ]
  },
  {
    category: 'renewables',
    keywords: [
      'solar power', 'wind power', 'renewable energy', 'solar park', 'rooftop solar',
      'bess', 'battery energy storage', 'green hydrogen', 'pm-surya ghar', 'pm-kusum',
      'almm', 'floating solar', 'hybrid power', 'green ammonia', 'seci', 'ireda', 'mnre',
      'clean energy', 'solar module', 'wind turbine', 'round the clock renewable', 'rtc power'
    ]
  },
  {
    category: 'policy',
    keywords: [
      'cerc', 'serc', 'ministry of power', 'electricity act', 'tariff policy', 'open access',
      'general network access', 'gna', 'power market', 'iex', 'pxil', 'hpx', 'banking of power',
      'rpo', 'renewable purchase obligation', 'late payment surcharge', 'lps rules',
      'resource adequacy', 'national electricity plan', 'nep'
    ]
  },
  {
    category: 'tenders',
    keywords: [
      'power tender', 'solar tender', 'wind tender', 'substation tender', 'transmission tender',
      'discom tender', 'tariff-based competitive bidding', 'tbcb', 'seci tender', 'epc power',
      'epc contract for power', 'meter tender', 'smart meter tender', 'feeder tender',
      'bess tender', 'battery storage tender', 'power procurement', 'e-bidding for power',
      'renewable tender', 'grid tender', 'transformer tender', 'ntpc tender', 'powergrid tender'
    ]
  },
  {
    category: 'scada',
    keywords: [
      'substation automation', 'sas', 'rtu', 'remote terminal unit', 'dms',
      'distribution management system', 'smart grid automation', 'opgw', 'optical ground wire',
      'sldc scada', 'psdf', 'smart utilities', 'automated grid', 'wide area monitoring',
      'wams', 'phasor measurement', 'pmu', 'iec 60870', 'iec 60870-5-104', 'iec 60870-5-101',
      'iec 104', 'iec 101', 'iec 61850', 'dnp3', 'modbus', 'opc ua', 'iccp', 'tase.2',
      'goose messaging', 'load dispatch communication', 'grid telecommunication',
      'uppcl scada', 'telecontrol', 'grid automation', 'power scada', 'scada'
    ]
  }
];

const IRRELEVANT_PATTERNS = [
  /\bpower play\b/i,
  /\bpowerlifting\b/i,
  /\bhorsepower\b/i,
  /\bbox office power\b/i,
  /\bstar power\b/i,
  /\bpower struggle\b/i,
  /\bpolitical power\b/i,
  /\bcoming to power\b/i,
  /\bgrip on power\b/i,
  /\bpower punch\b/i,
  /\bpower ballad\b/i,
  /\bpower nap\b/i,
  /\bpower couple\b/i,
  /\bpower packed performance\b/i,
  /\bcracker factory\b/i,
  /\bUkraine\b/i,
  /\bRussia\b/i,
  /\bCanada\b/i,
  /\bUnited States\b/i,
  /\bEurope\b/i,
  /\bAustralia\b/i,
  /\bGaza\b/i,
  /\bIsrael\b/i,
  /\bmissile\b/i,
  /\bNifty\b/i,
  /\bSensex\b/i,
  /\bstocks lead\b/i,
  /\bshare price\b/i,
  /\bcricket\b/i,
  /\bfootball\b/i,
  /\bipl\b/i,
  /\bmatch\b/i,
  /\btrophy\b/i,
  /\btennis\b/i,
  /\bbadminton\b/i,
  /\bmovie\b/i,
  /\bfilm\b/i,
  /\bactor\b/i,
  /\bactress\b/i,
  /\bcinema\b/i,
  /\bcelebrity\b/i,
  /\bbollywood\b/i,
  /\bhollywood\b/i,
  /\btrailer\b/i,
  /\belection rally\b/i,
  /\bvote bank\b/i,
  /\bopposition leader\b/i,
  /\bpolitical party\b/i,
  /\bmurder\b/i,
  /\barrested for\b/i,
  /\brobbery\b/i,
  /\bkidnap\b/i,
  /\bgang\b/i,
  /\bgold price\b/i,
  /\bsilver price\b/i,
  /\bcrypto\b/i,
  /\bbitcoin\b/i,
  /\bethereum\b/i,
  /\bmutual fund\b/i,
  /\bportfolio\b/i,
  /\bpetrol price\b/i,
  /\bdiesel price\b/i,
  /\baviation\b/i,
  /\bflight\b/i,
  /\bhighway\b/i,
  /\bexpressway\b/i,
  /\bliquor\b/i,
  /\balcohol\b/i
];

const CORE_POWER_ANCHORS = [
  'power', 'electricity', 'electric', 'grid', 'substation', 'discom', 'transco',
  'genco', 'transformer', 'switchgear', 'feeder', 'smart meter', 'tariff',
  'transmission', 'generator', 'turbine', 'solar', 'wind', 'hydro', 'nuclear',
  'thermal plant', 'bess', 'battery energy storage', 'megawatt', 'gigawatt',
  'kwh', 'mwh', '765 kv', '400 kv', '220 kv', '132 kv', 'cerc', 'serc',
  'uppcl', 'bescom', 'msedcl', 'tangedco', 'ntpc', 'powergrid', 'nhpc', 'bhel',
  'siemens energy', 'abb india', 'schneider electric', 'hitachi energy',
  'green hydrogen', 'scada', 'iec 61850', 'iec 60870', 'opgw', 'amisp', 'rdss'
];

// Keywords used by the Phase 1 Feed Ranking Algorithm to boost underserved verticals
const HIGH_VALUE_KEYWORDS = [
  'transformer', 'scada', 'smart grid', 'substation', 'discom',
  'at&c', 'automation', 'artificial intelligence', ' oem', 'siemens',
  'abb', 'hitachi', 'schneider', 'ge vernova', 'l&t', 'larsen', 'bhel',
  'transmission', 'distribution', 'switchgear', 'insulator', 'rtu',
  'iec 61850', 'grid controller', 'posoco', 'grid-india'
];

module.exports = {
  UTILITY_PLAYER_RULES,
  CITY_RULES,
  STATE_RULES,
  STATE_DISCOM_DIRECTORY,
  DISCOM_RULES,
  CATEGORY_RULES,
  IRRELEVANT_PATTERNS,
  CORE_POWER_ANCHORS,
  HIGH_VALUE_KEYWORDS,
};
