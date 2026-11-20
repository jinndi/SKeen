// https://raw.githubusercontent.com/jinndi/SKeen/sub-store/sing-box-config.js#type=0&name=Подписка&outbound=📂proxy🔖🚫ru|🇷🇺|мос|мск|msk|санкт|spb📂ru🔖ru|🇷🇺|мос|мск|msk|санкт|spb📂torrent🔖torrent|✅|vless📂games🔖hys|hy2|tuic|🇷🇺📂ai🔖🇩🇪|🇳🇱|de|nl📂🌍 auto🔖🚫ru|🇷🇺|мос|мск|msk|санкт|spb📂🇷🇺 auto🔖ru|🇷🇺|мос|мск|msk|санкт|spb

// Все 249 записей ISO 3166-1 из Википедии, в порядке исходного списка.
const COUNTRY_RULES = [
  { tag: "🇦🇺 Australia", flag: "🇦🇺", name: "Australia", codes: ["au","aus"], patternAliases: "australia|австралия|canberra|канберра", patternCodes: [], patternCodePatterns: ["(?:(?<![a-z])(?<!port-)au(?![a-z])|(?:^|[^a-z])aus(?:$|[^a-z]))"] },
  { tag: "🇦🇹 Austria", flag: "🇦🇹", name: "Austria", codes: ["at","aut"], patternAliases: "austria|австрия|vienna|вена" },
  { tag: "🇦🇿 Azerbaijan", flag: "🇦🇿", name: "Azerbaijan", codes: ["az","aze"], patternAliases: "azerbaijan|азербайджан|baku|баку" },
  { tag: "🇦🇽 Åland Islands", flag: "🇦🇽", name: "Åland Islands", codes: ["ax","ala"], patternAliases: "åland islands|аландские о-ва|mariehamn|мариехамн" },
  { tag: "🇦🇱 Albania", flag: "🇦🇱", name: "Albania", codes: ["al","alb"], patternAliases: "albania|албания|tirana|тирана" },
  { tag: "🇩🇿 Algeria", flag: "🇩🇿", name: "Algeria", codes: ["dz","dza"], patternAliases: "algeria|алжир|algiers" },
  { tag: "🇻🇮 U.S. Virgin Islands", flag: "🇻🇮", name: "U.S. Virgin Islands", codes: ["vi","vir"], patternAliases: "u.s. virgin islands|charlotte amalie|шарлотта-амалия" },
  { tag: "🇦🇸 American Samoa", flag: "🇦🇸", name: "American Samoa", codes: ["as","asm"], patternAliases: "american samoa|американское самоа|pago pago|паго-паго" },
  { tag: "🇦🇮 Anguilla", flag: "🇦🇮", name: "Anguilla", codes: ["ai","aia"], patternAliases: "anguilla|ангилья|the valley|вэлли" },
  { tag: "🇦🇴 Angola", flag: "🇦🇴", name: "Angola", codes: ["ao","ago"], patternAliases: "angola|ангола|luanda|луанда", patternCodes: [], patternCodePatterns: ["(?<![\\p{L}\\p{N}])(?:ao|ago)(?![\\p{L}\\p{N}])"] },
  { tag: "🇦🇩 Andorra", flag: "🇦🇩", name: "Andorra", codes: ["ad","and"], patternAliases: "andorra|андорра|andorra la vella|андорра-ла-вьеха" },
  { tag: "🇦🇶 Antarctica", flag: "🇦🇶", name: "Antarctica", codes: ["aq","ata"], patternAliases: "antarctica|антарктида" },
  { tag: "🇦🇬 Antigua & Barbuda", flag: "🇦🇬", name: "Antigua & Barbuda", codes: ["ag","atg"], patternAliases: "antigua & barbuda|антигуа и барбуда|st. john's|сент-джонс" },
  { tag: "🇦🇷 Argentina", flag: "🇦🇷", name: "Argentina", codes: ["ar","arg"], patternAliases: "argentina|аргентина|buenos aires|буэнос-айрес" },
  { tag: "🇦🇲 Armenia", flag: "🇦🇲", name: "Armenia", codes: ["am","arm"], patternAliases: "armenia|армения|yerevan|ереван" },
  { tag: "🇦🇼 Aruba", flag: "🇦🇼", name: "Aruba", codes: ["aw","abw"], patternAliases: "aruba|аруба|oranjestad|ораньестад" },
  { tag: "🇦🇫 Afghanistan", flag: "🇦🇫", name: "Afghanistan", codes: ["af","afg"], patternAliases: "afghanistan|афганистан|kabul|кабул" },
  { tag: "🇧🇸 Bahamas", flag: "🇧🇸", name: "Bahamas", codes: ["bs","bhs"], patternAliases: "bahamas|багамы|nassau|нассау" },
  { tag: "🇧🇩 Bangladesh", flag: "🇧🇩", name: "Bangladesh", codes: ["bd","bgd"], patternAliases: "bangladesh|бангладеш|dhaka|дакка" },
  { tag: "🇧🇧 Barbados", flag: "🇧🇧", name: "Barbados", codes: ["bb","brb"], patternAliases: "barbados|барбадос|bridgetown|бриджтаун" },
  { tag: "🇧🇭 Bahrain", flag: "🇧🇭", name: "Bahrain", codes: ["bh","bhr"], patternAliases: "bahrain|бахрейн|manama|манама" },
  { tag: "🇧🇿 Belize", flag: "🇧🇿", name: "Belize", codes: ["bz","blz"], patternAliases: "belize|белиз|belmopan|бельмопан" },
  { tag: "🇧🇾 Belarus", flag: "🇧🇾", name: "Belarus", codes: ["by","blr"], patternAliases: "belarus|беларусь|minsk|минск" },
  { tag: "🇧🇪 Belgium", flag: "🇧🇪", name: "Belgium", codes: ["be","bel"], patternAliases: "belgium|бельгия|brussels|брюссель" },
  { tag: "🇧🇯 Benin", flag: "🇧🇯", name: "Benin", codes: ["bj","ben"], patternAliases: "benin|бенин|porto-novo|порто-ново" },
  { tag: "🇧🇲 Bermuda", flag: "🇧🇲", name: "Bermuda", codes: ["bm","bmu"], patternAliases: "bermuda|бермудские о-ва|hamilton|гамильтон" },
  { tag: "🇧🇬 Bulgaria", flag: "🇧🇬", name: "Bulgaria", codes: ["bg","bgr"], patternAliases: "bulgaria|болгария|sofia|софия" },
  { tag: "🇧🇴 Bolivia", flag: "🇧🇴", name: "Bolivia", codes: ["bo","bol"], patternAliases: "bolivia|боливия|la paz|ла-пас" },
  { tag: "🇧🇶 Caribbean Netherlands", flag: "🇧🇶", name: "Caribbean Netherlands", codes: ["bq","bes"], patternAliases: "caribbean netherlands|бонэйр, синт-эстатиус и саба" },
  { tag: "🇧🇦 Bosnia & Herzegovina", flag: "🇧🇦", name: "Bosnia & Herzegovina", codes: ["ba","bih"], patternAliases: "bosnia & herzegovina|босния и герцеговина|sarajevo|сараево" },
  { tag: "🇧🇼 Botswana", flag: "🇧🇼", name: "Botswana", codes: ["bw","bwa"], patternAliases: "botswana|ботсвана|gaborone|габороне" },
  { tag: "🇧🇷 Brazil", flag: "🇧🇷", name: "Brazil", codes: ["br","bra"], patternAliases: "brazil|бразилия|brasilia|бразилиа" },
  { tag: "🇮🇴 British Indian Ocean Territory", flag: "🇮🇴", name: "British Indian Ocean Territory", codes: ["io","iot"], patternAliases: "british indian ocean territory|британская территория в индийском океане" },
  { tag: "🇻🇬 British Virgin Islands", flag: "🇻🇬", name: "British Virgin Islands", codes: ["vg","vgb"], patternAliases: "british virgin islands|road town|роуд-таун" },
  { tag: "🇧🇳 Brunei", flag: "🇧🇳", name: "Brunei", codes: ["bn","brn"], patternAliases: "brunei|бруней|bandar seri begawan|бандар-сери-бегаван" },
  { tag: "🇧🇫 Burkina Faso", flag: "🇧🇫", name: "Burkina Faso", codes: ["bf","bfa"], patternAliases: "burkina faso|буркина-фасо|ouagadougou|уагадугу" },
  { tag: "🇧🇮 Burundi", flag: "🇧🇮", name: "Burundi", codes: ["bi","bdi"], patternAliases: "burundi|бурунди|bujumbura|бужумбура" },
  { tag: "🇧🇹 Bhutan", flag: "🇧🇹", name: "Bhutan", codes: ["bt","btn"], patternAliases: "bhutan|бутан|thimphu|тхимпху" },
  { tag: "🇻🇺 Vanuatu", flag: "🇻🇺", name: "Vanuatu", codes: ["vu","vut"], patternAliases: "vanuatu|вануату|port vila|порт-вила" },
  { tag: "🇻🇦 Vatican City", flag: "🇻🇦", name: "Vatican City", codes: ["va","vat"], patternAliases: "vatican city|ватикан" },
  { tag: "🇬🇧 United Kingdom", flag: "🇬🇧", name: "United Kingdom", codes: ["gb","gbr","uk"], patternAliases: "united kingdom|великобритания|london|лондон" },
  { tag: "🇭🇺 Hungary", flag: "🇭🇺", name: "Hungary", codes: ["hu","hun"], patternAliases: "hungary|венгрия|budapest|будапешт" },
  { tag: "🇻🇪 Venezuela", flag: "🇻🇪", name: "Venezuela", codes: ["ve","ven"], patternAliases: "venezuela|венесуэла|caracas|каракас" },
  { tag: "🇺🇲 U.S. Outlying Islands", flag: "🇺🇲", name: "U.S. Outlying Islands", codes: ["um","umi"], patternAliases: "u.s. outlying islands" },
  { tag: "🇹🇱 Timor-Leste", flag: "🇹🇱", name: "Timor-Leste", codes: ["tl","tls"], patternAliases: "timor-leste|восточный тимор|dili|дили" },
  { tag: "🇻🇳 Vietnam", flag: "🇻🇳", name: "Vietnam", codes: ["vn","vnm"], patternAliases: "vietnam|вьетнам|hanoi|ханой" },
  { tag: "🇬🇦 Gabon", flag: "🇬🇦", name: "Gabon", codes: ["ga","gab"], patternAliases: "gabon|габон|libreville|либревиль" },
  { tag: "🇭🇹 Haiti", flag: "🇭🇹", name: "Haiti", codes: ["ht","hti"], patternAliases: "haiti|гаити|port-au-prince|порт-о-пренс" },
  { tag: "🇬🇾 Guyana", flag: "🇬🇾", name: "Guyana", codes: ["gy","guy"], patternAliases: "guyana|гайана|georgetown|джорджтаун" },
  { tag: "🇬🇲 Gambia", flag: "🇬🇲", name: "Gambia", codes: ["gm","gmb"], patternAliases: "gambia|гамбия|banjul|банджул" },
  { tag: "🇬🇭 Ghana", flag: "🇬🇭", name: "Ghana", codes: ["gh","gha"], patternAliases: "ghana|гана|accra|аккра" },
  { tag: "🇬🇵 Guadeloupe", flag: "🇬🇵", name: "Guadeloupe", codes: ["gp","glp"], patternAliases: "guadeloupe|гваделупа|basse-terre|бас-тер" },
  { tag: "🇬🇹 Guatemala", flag: "🇬🇹", name: "Guatemala", codes: ["gt","gtm"], patternAliases: "guatemala|гватемала|guatemala city|гватемала-сити" },
  { tag: "🇬🇫 French Guiana", flag: "🇬🇫", name: "French Guiana", codes: ["gf","guf"], patternAliases: "french guiana|французская гвиана|cayenne|кайенна" },
  { tag: "🇬🇳 Guinea", flag: "🇬🇳", name: "Guinea", codes: ["gn","gin"], patternAliases: "conakry|конакри|guinea-conakry|republic of guinea|гвинея-конакри", patternExtras: ["(?<!papua new )(?<!equatorial )(?<![\\p{L}\\p{N}])guinea(?!-bissau)(?![\\p{L}\\p{N}])","(?<!новая )(?<!экваториальная )(?<![\\p{L}\\p{N}])гвинея(?!-бисау)(?![\\p{L}\\p{N}])"] },
  { tag: "🇬🇼 Guinea-Bissau", flag: "🇬🇼", name: "Guinea-Bissau", codes: ["gw","gnb"], patternAliases: "guinea-bissau|гвинея-бисау|bissau|бисау" },
  { tag: "🇩🇪 Germany", flag: "🇩🇪", name: "Germany", codes: ["de","deu"], patternAliases: "germany|германия|berlin|берлин|франкфурт|frankfurt", patternCodes: [], patternCodePatterns: ["(?:(?<![a-z])(?<!santa fe )(?<!fort-)de(?![a-z])|(?:^|[^a-z])deu(?:$|[^a-z]))"] },
  { tag: "🇬🇬 Guernsey", flag: "🇬🇬", name: "Guernsey", codes: ["gg","ggy"], patternAliases: "guernsey|гернси|saint peter port|сент-питер-порт" },
  { tag: "🇬🇮 Gibraltar", flag: "🇬🇮", name: "Gibraltar", codes: ["gi","gib"], patternAliases: "gibraltar|гибралтар" },
  { tag: "🇭🇳 Honduras", flag: "🇭🇳", name: "Honduras", codes: ["hn","hnd"], patternAliases: "honduras|гондурас|tegucigalpa|тегусигальпа" },
  { tag: "🇭🇰 Hong Kong SAR China", flag: "🇭🇰", name: "Hong Kong SAR China", codes: ["hk","hkg"], patternAliases: "hong kong sar china|гонконг (сар)|hong kong|гонконг" },
  { tag: "🇬🇩 Grenada", flag: "🇬🇩", name: "Grenada", codes: ["gd","grd"], patternAliases: "grenada|гренада|st george's|сент-джорджес" },
  { tag: "🇬🇱 Greenland", flag: "🇬🇱", name: "Greenland", codes: ["gl","grl"], patternAliases: "greenland|гренландия|nuuk|нуук" },
  { tag: "🇬🇷 Greece", flag: "🇬🇷", name: "Greece", codes: ["gr","grc"], patternAliases: "greece|греция|athens|афины" },
  { tag: "🇬🇪 Georgia", flag: "🇬🇪", name: "Georgia", codes: ["ge","geo"], patternAliases: "грузия|tbilisi|тбилиси", patternExtras: ["(?<!south )(?<![\\p{L}\\p{N}])georgia(?![\\p{L}\\p{N}])"] },
  { tag: "🇬🇺 Guam", flag: "🇬🇺", name: "Guam", codes: ["gu","gum"], patternAliases: "guam|гуам|hagatna|хагатна" },
  { tag: "🇩🇰 Denmark", flag: "🇩🇰", name: "Denmark", codes: ["dk","dnk"], patternAliases: "denmark|дания|copenhagen|копенгаген" },
  { tag: "🇯🇪 Jersey", flag: "🇯🇪", name: "Jersey", codes: ["je","jey"], patternAliases: "jersey|джерси|saint helier|сент-хелиер" },
  { tag: "🇩🇯 Djibouti", flag: "🇩🇯", name: "Djibouti", codes: ["dj","dji"], patternAliases: "djibouti|джибути" },
  { tag: "🇩🇲 Dominica", flag: "🇩🇲", name: "Dominica", codes: ["dm","dma"], patternAliases: "dominica|доминика|roseau|розо" },
  { tag: "🇩🇴 Dominican Republic", flag: "🇩🇴", name: "Dominican Republic", codes: ["do","dom"], patternAliases: "dominican republic|доминиканская республика|santo domingo|санто-доминго" },
  { tag: "🇨🇩 Congo - Kinshasa", flag: "🇨🇩", name: "Congo - Kinshasa", codes: ["cd","cod"], patternAliases: "congo - kinshasa|конго - киншаса|kinshasa|киншаса" },
  { tag: "🇪🇬 Egypt", flag: "🇪🇬", name: "Egypt", codes: ["eg","egy"], patternAliases: "egypt|египет|cairo|каир" },
  { tag: "🇿🇲 Zambia", flag: "🇿🇲", name: "Zambia", codes: ["zm","zmb"], patternAliases: "zambia|замбия|lusaka|лусака" },
  { tag: "🇪🇭 Western Sahara", flag: "🇪🇭", name: "Western Sahara", codes: ["eh","esh"], patternAliases: "western sahara|западная сахара|laayoune|эль-аюн" },
  { tag: "🇿🇼 Zimbabwe", flag: "🇿🇼", name: "Zimbabwe", codes: ["zw","zwe"], patternAliases: "zimbabwe|зимбабве|harare|хараре" },
  { tag: "🇮🇱 Israel", flag: "🇮🇱", name: "Israel", codes: ["il","isr"], patternAliases: "israel|израиль", patternExtras: ["(?<!east )(?<![\\p{L}\\p{N}])jerusalem(?![\\p{L}\\p{N}])","(?<!восточный )(?<![\\p{L}\\p{N}])иерусалим(?![\\p{L}\\p{N}])"] },
  { tag: "🇮🇳 India", flag: "🇮🇳", name: "India", codes: ["in","ind"], patternAliases: "india|индия|new delhi|нью-дели" },
  { tag: "🇮🇩 Indonesia", flag: "🇮🇩", name: "Indonesia", codes: ["id","idn"], patternAliases: "indonesia|индонезия|jakarta|джакарта" },
  { tag: "🇯🇴 Jordan", flag: "🇯🇴", name: "Jordan", codes: ["jo","jor"], patternAliases: "jordan|иордания|amman|амман" },
  { tag: "🇮🇶 Iraq", flag: "🇮🇶", name: "Iraq", codes: ["iq","irq"], patternAliases: "iraq|ирак|baghdad|багдад" },
  { tag: "🇮🇷 Iran", flag: "🇮🇷", name: "Iran", codes: ["ir","irn"], patternAliases: "iran|иран|tehran|тегеран" },
  { tag: "🇮🇪 Ireland", flag: "🇮🇪", name: "Ireland", codes: ["ie","irl"], patternAliases: "ireland|ирландия|dublin|дублин" },
  { tag: "🇮🇸 Iceland", flag: "🇮🇸", name: "Iceland", codes: ["is","isl"], patternAliases: "iceland|исландия|reykjavik|рейкъявик" },
  { tag: "🇪🇸 Spain", flag: "🇪🇸", name: "Spain", codes: ["es","esp"], patternAliases: "испания|madrid|мадрид", patternExtras: ["(?<!of )(?<![\\p{L}\\p{N}])spain(?![\\p{L}\\p{N}])"] },
  { tag: "🇮🇹 Italy", flag: "🇮🇹", name: "Italy", codes: ["it","ita"], patternAliases: "italy|италия|rome|рим|milan|милан" },
  { tag: "🇾🇪 Yemen", flag: "🇾🇪", name: "Yemen", codes: ["ye","yem"], patternAliases: "yemen|йемен|sana'a|сана" },
  { tag: "🇨🇻 Cape Verde", flag: "🇨🇻", name: "Cape Verde", codes: ["cv","cpv"], patternAliases: "cape verde|кабо-верде|praia|прая" },
  { tag: "🇰🇿 Kazakhstan", flag: "🇰🇿", name: "Kazakhstan", codes: ["kz","kaz"], patternAliases: "kazakhstan|казахстан|astana|астана" },
  { tag: "🇰🇾 Cayman Islands", flag: "🇰🇾", name: "Cayman Islands", codes: ["ky","cym"], patternAliases: "cayman islands|о-ва кайман|george town" },
  { tag: "🇰🇭 Cambodia", flag: "🇰🇭", name: "Cambodia", codes: ["kh","khm"], patternAliases: "cambodia|камбоджа|phnom penh|пномпень" },
  { tag: "🇨🇲 Cameroon", flag: "🇨🇲", name: "Cameroon", codes: ["cm","cmr"], patternAliases: "cameroon|камерун|yaoundé|яунде" },
  { tag: "🇨🇦 Canada", flag: "🇨🇦", name: "Canada", codes: ["ca","can"], patternAliases: "canada|канада|ottawa|оттава" },
  { tag: "🇶🇦 Qatar", flag: "🇶🇦", name: "Qatar", codes: ["qa","qat"], patternAliases: "qatar|катар|doha|доха" },
  { tag: "🇰🇪 Kenya", flag: "🇰🇪", name: "Kenya", codes: ["ke","ken"], patternAliases: "kenya|кения|nairobi|найроби" },
  { tag: "🇨🇾 Cyprus", flag: "🇨🇾", name: "Cyprus", codes: ["cy","cyp"], patternAliases: "cyprus|кипр|nicosia|никосия" },
  { tag: "🇰🇬 Kyrgyzstan", flag: "🇰🇬", name: "Kyrgyzstan", codes: ["kg","kgz"], patternAliases: "kyrgyzstan|киргизия|bishkek|бишкек" },
  { tag: "🇰🇮 Kiribati", flag: "🇰🇮", name: "Kiribati", codes: ["ki","kir"], patternAliases: "kiribati|кирибати|bairiki|тарава" },
  { tag: "🇹🇼 Taiwan", flag: "🇹🇼", name: "Taiwan", codes: ["tw","twn"], patternAliases: "taiwan|тайвань|taipei|тайбэй" },
  { tag: "🇰🇵 North Korea", flag: "🇰🇵", name: "North Korea", codes: ["kp","prk"], patternAliases: "north korea|кндр|pyongyang|пхеньян" },
  { tag: "🇨🇳 China", flag: "🇨🇳", name: "China", codes: ["cn","chn"], patternAliases: "китай|beijing|пекин", patternExtras: ["(?<!sar )(?<![\\p{L}\\p{N}])china(?![\\p{L}\\p{N}])"] },
  { tag: "🇨🇨 Cocos (Keeling) Islands", flag: "🇨🇨", name: "Cocos (Keeling) Islands", codes: ["cc","cck"], patternAliases: "cocos (keeling) islands|кокосовые о-ва|west island|уэст-айленд" },
  { tag: "🇨🇴 Colombia", flag: "🇨🇴", name: "Colombia", codes: ["co","col"], patternAliases: "colombia|колумбия|santa fe de bogotá|богота" },
  { tag: "🇰🇲 Comoros", flag: "🇰🇲", name: "Comoros", codes: ["km","com"], patternAliases: "comoros|коморы|moroni|морони" },
  { tag: "🇨🇷 Costa Rica", flag: "🇨🇷", name: "Costa Rica", codes: ["cr","cri"], patternAliases: "costa rica|коста-рика|san josé|сан-хосе" },
  { tag: "🇨🇮 Côte d’Ivoire", flag: "🇨🇮", name: "Côte d’Ivoire", codes: ["ci","civ"], patternAliases: "côte d’ivoire|кот-д’ивуар|yamoussoukro|ямусукро" },
  { tag: "🇨🇺 Cuba", flag: "🇨🇺", name: "Cuba", codes: ["cu","cub"], patternAliases: "cuba|куба|havana|гавана" },
  { tag: "🇰🇼 Kuwait", flag: "🇰🇼", name: "Kuwait", codes: ["kw","kwt"], patternAliases: "kuwait|кувейт|kuwait city|эль-кувейт" },
  { tag: "🇨🇼 Curaçao", flag: "🇨🇼", name: "Curaçao", codes: ["cw","cuw"], patternAliases: "curaçao|кюрасао|willemstad|виллемстад" },
  { tag: "🇱🇦 Laos", flag: "🇱🇦", name: "Laos", codes: ["la","lao"], patternAliases: "laos|лаос|vientiane|вьентьян", patternCodes: [], patternCodePatterns: ["(?:(?:^|[^a-z])la(?! paz| vella)(?:$|[^a-z])|(?:^|[^a-z])lao(?:$|[^a-z]))"] },
  { tag: "🇱🇻 Latvia", flag: "🇱🇻", name: "Latvia", codes: ["lv","lva"], patternAliases: "latvia|латвия|riga|рига" },
  { tag: "🇱🇸 Lesotho", flag: "🇱🇸", name: "Lesotho", codes: ["ls","lso"], patternAliases: "lesotho|лесото|maseru|масеру" },
  { tag: "🇱🇷 Liberia", flag: "🇱🇷", name: "Liberia", codes: ["lr","lbr"], patternAliases: "liberia|либерия|monrovia|монровия" },
  { tag: "🇱🇧 Lebanon", flag: "🇱🇧", name: "Lebanon", codes: ["lb","lbn"], patternAliases: "lebanon|ливан|beirut|бейрут" },
  { tag: "🇱🇾 Libya", flag: "🇱🇾", name: "Libya", codes: ["ly","lby"], patternAliases: "libya|ливия|tripoli|триполи" },
  { tag: "🇱🇹 Lithuania", flag: "🇱🇹", name: "Lithuania", codes: ["lt","ltu"], patternAliases: "lithuania|литва|vilnius|вильнюс" },
  { tag: "🇱🇮 Liechtenstein", flag: "🇱🇮", name: "Liechtenstein", codes: ["li","lie"], patternAliases: "liechtenstein|лихтенштейн|vaduz|вадуц" },
  { tag: "🇱🇺 Luxembourg", flag: "🇱🇺", name: "Luxembourg", codes: ["lu","lux"], patternAliases: "luxembourg|люксембург" },
  { tag: "🇲🇺 Mauritius", flag: "🇲🇺", name: "Mauritius", codes: ["mu","mus"], patternAliases: "mauritius|маврикий|port louis|порт-луи" },
  { tag: "🇲🇷 Mauritania", flag: "🇲🇷", name: "Mauritania", codes: ["mr","mrt"], patternAliases: "mauritania|мавритания|nouakchott|нуакшот" },
  { tag: "🇲🇬 Madagascar", flag: "🇲🇬", name: "Madagascar", codes: ["mg","mdg"], patternAliases: "madagascar|мадагаскар|antananarivo|антананариву" },
  { tag: "🇾🇹 Mayotte", flag: "🇾🇹", name: "Mayotte", codes: ["yt","myt"], patternAliases: "mayotte|майотта|mamoudzou|мамудзу" },
  { tag: "🇲🇴 Macao SAR China", flag: "🇲🇴", name: "Macao SAR China", codes: ["mo","mac"], patternAliases: "macao sar china|макао (сар)|macau|макао" },
  { tag: "🇲🇰 North Macedonia", flag: "🇲🇰", name: "North Macedonia", codes: ["mk","mkd"], patternAliases: "north macedonia|северная македония|skopje|скопье" },
  { tag: "🇲🇼 Malawi", flag: "🇲🇼", name: "Malawi", codes: ["mw","mwi"], patternAliases: "malawi|малави|lilongwe|лилонгве" },
  { tag: "🇲🇾 Malaysia", flag: "🇲🇾", name: "Malaysia", codes: ["my","mys"], patternAliases: "malaysia|малайзия|kuala lumpur|куала-лумпур" },
  { tag: "🇲🇱 Mali", flag: "🇲🇱", name: "Mali", codes: ["ml","mli"], patternAliases: "mali|мали|bamako|бамако" },
  { tag: "🇲🇻 Maldives", flag: "🇲🇻", name: "Maldives", codes: ["mv","mdv"], patternAliases: "maldives|мальдивы|male'|мале" },
  { tag: "🇲🇹 Malta", flag: "🇲🇹", name: "Malta", codes: ["mt","mlt"], patternAliases: "malta|мальта|valletta|валлетта" },
  { tag: "🇲🇦 Morocco", flag: "🇲🇦", name: "Morocco", codes: ["ma","mar"], patternAliases: "morocco|марокко|rabat|рабат" },
  { tag: "🇲🇶 Martinique", flag: "🇲🇶", name: "Martinique", codes: ["mq","mtq"], patternAliases: "martinique|мартиника|fort-de-france|фор-де-франс" },
  { tag: "🇲🇭 Marshall Islands", flag: "🇲🇭", name: "Marshall Islands", codes: ["mh","mhl"], patternAliases: "marshall islands|маршалловы о-ва|majuro|далап-улига-даррит" },
  { tag: "🇲🇽 Mexico", flag: "🇲🇽", name: "Mexico", codes: ["mx","mex"], patternAliases: "mexico|мексика|mexico city|мехико" },
  { tag: "🇫🇲 Micronesia", flag: "🇫🇲", name: "Micronesia", codes: ["fm","fsm"], patternAliases: "micronesia|федеративные штаты микронезии|palikir|паликир" },
  { tag: "🇲🇿 Mozambique", flag: "🇲🇿", name: "Mozambique", codes: ["mz","moz"], patternAliases: "mozambique|мозамбик|maputo|мапуту" },
  { tag: "🇲🇩 Moldova", flag: "🇲🇩", name: "Moldova", codes: ["md","mda"], patternAliases: "moldova|молдова|chisinau|кишинев" },
  { tag: "🇲🇨 Monaco", flag: "🇲🇨", name: "Monaco", codes: ["mc","mco"], patternAliases: "monaco|монако" },
  { tag: "🇲🇳 Mongolia", flag: "🇲🇳", name: "Mongolia", codes: ["mn","mng"], patternAliases: "mongolia|монголия|ulaanbaatar|улан-батор" },
  { tag: "🇲🇸 Montserrat", flag: "🇲🇸", name: "Montserrat", codes: ["ms","msr"], patternAliases: "montserrat|монтсеррат|plymouth|плимут" },
  { tag: "🇲🇲 Myanmar (Burma)", flag: "🇲🇲", name: "Myanmar (Burma)", codes: ["mm","mmr"], patternAliases: "myanmar (burma)|мьянма (бирма)|nay pyi taw|нейпьидо" },
  { tag: "🇳🇦 Namibia", flag: "🇳🇦", name: "Namibia", codes: ["na","nam"], patternAliases: "namibia|намибия|windhoek|виндхук" },
  { tag: "🇳🇷 Nauru", flag: "🇳🇷", name: "Nauru", codes: ["nr","nru"], patternAliases: "nauru|науру|yaren|ярен" },
  { tag: "🇳🇵 Nepal", flag: "🇳🇵", name: "Nepal", codes: ["np","npl"], patternAliases: "nepal|непал|kathmandu|катманду" },
  { tag: "🇳🇪 Niger", flag: "🇳🇪", name: "Niger", codes: ["ne","ner"], patternAliases: "niger|нигер|niamey|ниамей" },
  { tag: "🇳🇬 Nigeria", flag: "🇳🇬", name: "Nigeria", codes: ["ng","nga"], patternAliases: "nigeria|нигерия|abuja|абуджа" },
  { tag: "🇳🇱 Netherlands", flag: "🇳🇱", name: "Netherlands", codes: ["nl","nld"], patternAliases: "amsterdam|амстердам", patternExtras: ["(?<!caribbean )(?<![\\p{L}\\p{N}])netherlands(?![\\p{L}\\p{N}])","(?<!карибские )(?<![\\p{L}\\p{N}])нидерланды(?![\\p{L}\\p{N}])"] },
  { tag: "🇳🇮 Nicaragua", flag: "🇳🇮", name: "Nicaragua", codes: ["ni","nic"], patternAliases: "nicaragua|никарагуа|managua|манагуа" },
  { tag: "🇳🇺 Niue", flag: "🇳🇺", name: "Niue", codes: ["nu","niu"], patternAliases: "niue|ниуэ|alofi|алофи" },
  { tag: "🇳🇿 New Zealand", flag: "🇳🇿", name: "New Zealand", codes: ["nz","nzl"], patternAliases: "new zealand|новая зеландия|wellington|веллингтон" },
  { tag: "🇳🇨 New Caledonia", flag: "🇳🇨", name: "New Caledonia", codes: ["nc","ncl"], patternAliases: "new caledonia|новая каледония|noumea|нумеа" },
  { tag: "🇳🇴 Norway", flag: "🇳🇴", name: "Norway", codes: ["no","nor"], patternAliases: "norway|норвегия|oslo|осло" },
  { tag: "🇦🇪 United Arab Emirates", flag: "🇦🇪", name: "United Arab Emirates", codes: ["ae","are"], patternAliases: "united arab emirates|оаэ|abu dhabi|абу-даби" },
  { tag: "🇴🇲 Oman", flag: "🇴🇲", name: "Oman", codes: ["om","omn"], patternAliases: "oman|оман|muscat|маскат" },
  { tag: "🇧🇻 Bouvet Island", flag: "🇧🇻", name: "Bouvet Island", codes: ["bv","bvt"], patternAliases: "bouvet island|о-в буве" },
  { tag: "🇮🇲 Isle of Man", flag: "🇮🇲", name: "Isle of Man", codes: ["im","imn"], patternAliases: "isle of man|о-в мэн|douglas|дуглас" },
  { tag: "🇨🇰 Cook Islands", flag: "🇨🇰", name: "Cook Islands", codes: ["ck","cok"], patternAliases: "cook islands|о-ва кука|avarua|аваруа" },
  { tag: "🇳🇫 Norfolk Island", flag: "🇳🇫", name: "Norfolk Island", codes: ["nf","nfk"], patternAliases: "norfolk island|о-в норфолк" },
  { tag: "🇨🇽 Christmas Island", flag: "🇨🇽", name: "Christmas Island", codes: ["cx","cxr"], patternAliases: "christmas island|о-в рождества|flying fish cove|флайинг-фиш-коув" },
  { tag: "🇵🇳 Pitcairn Islands", flag: "🇵🇳", name: "Pitcairn Islands", codes: ["pn","pcn"], patternAliases: "pitcairn islands|о-ва питкэрн|adamstown|адамстаун" },
  { tag: "🇸🇭 St. Helena", flag: "🇸🇭", name: "St. Helena", codes: ["sh","shn"], patternAliases: "st. helena|о-в св. елены|jamestown|джеймстаун" },
  { tag: "🇵🇰 Pakistan", flag: "🇵🇰", name: "Pakistan", codes: ["pk","pak"], patternAliases: "pakistan|пакистан|islamabad|исламабад" },
  { tag: "🇵🇼 Palau", flag: "🇵🇼", name: "Palau", codes: ["pw","plw"], patternAliases: "palau|палау|koror|корор" },
  { tag: "🇵🇸 Palestinian Territories", flag: "🇵🇸", name: "Palestinian Territories", codes: ["ps","pse"], patternAliases: "palestinian territories|палестинские территории|east jerusalem|восточный иерусалим" },
  { tag: "🇵🇦 Panama", flag: "🇵🇦", name: "Panama", codes: ["pa","pan"], patternAliases: "panama|панама|panama city" },
  { tag: "🇵🇬 Papua New Guinea", flag: "🇵🇬", name: "Papua New Guinea", codes: ["pg","png"], patternAliases: "papua new guinea|папуа — новая гвинея|port moresby|порт-морсби" },
  { tag: "🇵🇾 Paraguay", flag: "🇵🇾", name: "Paraguay", codes: ["py","pry"], patternAliases: "paraguay|парагвай|asunción|асунсьон" },
  { tag: "🇵🇪 Peru", flag: "🇵🇪", name: "Peru", codes: ["pe","per"], patternAliases: "peru|перу|lima|лима" },
  { tag: "🇵🇱 Poland", flag: "🇵🇱", name: "Poland", codes: ["pl","pol"], patternAliases: "poland|польша|warsaw|варшава" },
  { tag: "🇵🇹 Portugal", flag: "🇵🇹", name: "Portugal", codes: ["pt","prt"], patternAliases: "portugal|португалия|lisbon|лиссабон" },
  { tag: "🇵🇷 Puerto Rico", flag: "🇵🇷", name: "Puerto Rico", codes: ["pr","pri"], patternAliases: "puerto rico|пуэрто-рико|san juan|сан-хуан", patternCodes: [], patternCodePatterns: ["(?<![\\p{L}\\p{N}])(?:pr|pri)(?![\\p{L}\\p{N}])"] },
  { tag: "🇨🇬 Congo - Brazzaville", flag: "🇨🇬", name: "Congo - Brazzaville", codes: ["cg","cog"], patternAliases: "congo - brazzaville|конго - браззавиль|brazzaville|браззавиль" },
  { tag: "🇰🇷 South Korea", flag: "🇰🇷", name: "South Korea", codes: ["kr","kor"], patternAliases: "south korea|южная корея|республика корея|seoul|сеул" },
  { tag: "🇷🇪 Réunion", flag: "🇷🇪", name: "Réunion", codes: ["re","reu"], patternAliases: "réunion|реюньон|saint-denis|сен-дени" },
  { tag: "🇷🇺 Russia", flag: "🇷🇺", name: "Russia", codes: ["ru","rus"], patternAliases: "russia|россия|moscow|москва|мск|msk|spb", patternCodes: [], patternCodePatterns: ["(?:^|[^a-z])(?:ru|rus)(?:$|[^a-z])"] },
  { tag: "🇷🇼 Rwanda", flag: "🇷🇼", name: "Rwanda", codes: ["rw","rwa"], patternAliases: "rwanda|руанда|kigali|кигали" },
  { tag: "🇷🇴 Romania", flag: "🇷🇴", name: "Romania", codes: ["ro","rou"], patternAliases: "romania|румыния|bucharest|бухарест" },
  { tag: "🇸🇻 El Salvador", flag: "🇸🇻", name: "El Salvador", codes: ["sv","slv"], patternAliases: "el salvador|сальвадор|san salvador|сан-сальвадор" },
  { tag: "🇼🇸 Samoa", flag: "🇼🇸", name: "Samoa", codes: ["ws","wsm"], patternAliases: "apia|апиа", patternExtras: ["(?<!american )(?<![\\p{L}\\p{N}])samoa(?![\\p{L}\\p{N}])","(?<!американское )(?<![\\p{L}\\p{N}])самоа(?![\\p{L}\\p{N}])"] },
  { tag: "🇸🇲 San Marino", flag: "🇸🇲", name: "San Marino", codes: ["sm","smr"], patternAliases: "san marino|сан-марино" },
  { tag: "🇸🇹 São Tomé & Príncipe", flag: "🇸🇹", name: "São Tomé & Príncipe", codes: ["st","stp"], patternAliases: "são tomé & príncipe|сан-томе и принсипи|sao tome|сан-томе", patternCodes: [], patternCodePatterns: ["(?:(?:^|[^a-z.])st(?! george)(?:$|[^a-z.])|(?:^|[^a-z.])stp(?:$|[^a-z.]))"] },
  { tag: "🇸🇦 Saudi Arabia", flag: "🇸🇦", name: "Saudi Arabia", codes: ["sa","sau"], patternAliases: "saudi arabia|саудовская аравия|riyadh|эр-рияд" },
  { tag: "🇲🇵 Northern Mariana Islands", flag: "🇲🇵", name: "Northern Mariana Islands", codes: ["mp","mnp"], patternAliases: "northern mariana islands|северные марианские о-ва|saipan|сайпан" },
  { tag: "🇸🇨 Seychelles", flag: "🇸🇨", name: "Seychelles", codes: ["sc","syc"], patternAliases: "seychelles|сейшельские о-ва|victoria|виктория" },
  { tag: "🇧🇱 St. Barthélemy", flag: "🇧🇱", name: "St. Barthélemy", codes: ["bl","blm"], patternAliases: "st. barthélemy|сен-бартелеми|gustavia|густавия" },
  { tag: "🇲🇫 St. Martin", flag: "🇲🇫", name: "St. Martin", codes: ["mf","maf"], patternAliases: "st. martin|сен-мартен|marigot|мариго" },
  { tag: "🇵🇲 St. Pierre & Miquelon", flag: "🇵🇲", name: "St. Pierre & Miquelon", codes: ["pm","spm"], patternAliases: "st. pierre & miquelon|сен-пьер и микелон|saint-pierre|сен-пьер" },
  { tag: "🇸🇳 Senegal", flag: "🇸🇳", name: "Senegal", codes: ["sn","sen"], patternAliases: "senegal|сенегал|dakar|дакар" },
  { tag: "🇻🇨 St. Vincent & Grenadines", flag: "🇻🇨", name: "St. Vincent & Grenadines", codes: ["vc","vct"], patternAliases: "st. vincent & grenadines|сент-винсент и гренадины|kingstown|кингстаун" },
  { tag: "🇰🇳 St. Kitts & Nevis", flag: "🇰🇳", name: "St. Kitts & Nevis", codes: ["kn","kna"], patternAliases: "st. kitts & nevis|сент-китс и невис|basseterre|бастерр" },
  { tag: "🇱🇨 St. Lucia", flag: "🇱🇨", name: "St. Lucia", codes: ["lc","lca"], patternAliases: "st. lucia|сент-люсия|castries|кастри" },
  { tag: "🇷🇸 Serbia", flag: "🇷🇸", name: "Serbia", codes: ["rs","srb"], patternAliases: "serbia|сербия|belgrade|белград" },
  { tag: "🇸🇬 Singapore", flag: "🇸🇬", name: "Singapore", codes: ["sg","sgp"], patternAliases: "singapore|сингапур" },
  { tag: "🇸🇽 Sint Maarten", flag: "🇸🇽", name: "Sint Maarten", codes: ["sx","sxm"], patternAliases: "sint maarten|синт-мартен|philipsburg|филипсбург" },
  { tag: "🇸🇾 Syria", flag: "🇸🇾", name: "Syria", codes: ["sy","syr"], patternAliases: "syria|сирия|damascus|дамаск" },
  { tag: "🇸🇰 Slovakia", flag: "🇸🇰", name: "Slovakia", codes: ["sk","svk"], patternAliases: "slovakia|словакия|bratislava|братислава" },
  { tag: "🇸🇮 Slovenia", flag: "🇸🇮", name: "Slovenia", codes: ["si","svn"], patternAliases: "slovenia|словения|ljubljana|любляна" },
  { tag: "🇸🇧 Solomon Islands", flag: "🇸🇧", name: "Solomon Islands", codes: ["sb","slb"], patternAliases: "solomon islands|соломоновы о-ва|honiara|хониара" },
  { tag: "🇸🇴 Somalia", flag: "🇸🇴", name: "Somalia", codes: ["so","som"], patternAliases: "somalia|сомали|mogadishu|могадишу" },
  { tag: "🇸🇩 Sudan", flag: "🇸🇩", name: "Sudan", codes: ["sd","sdn"], patternAliases: "khartoum|хартум", patternExtras: ["(?<!south )(?<![\\p{L}\\p{N}])sudan(?![\\p{L}\\p{N}])","(?<!южный )(?<![\\p{L}\\p{N}])судан(?![\\p{L}\\p{N}])"] },
  { tag: "🇸🇷 Suriname", flag: "🇸🇷", name: "Suriname", codes: ["sr","sur"], patternAliases: "suriname|суринам|paramaribo|парамарибо" },
  { tag: "🇺🇸 United States", flag: "🇺🇸", name: "United States", codes: ["us","usa"], patternAliases: "united states|соединенные штаты|washington, d.c.|вашингтон|сша|америк|new york|йорк" },
  { tag: "🇸🇱 Sierra Leone", flag: "🇸🇱", name: "Sierra Leone", codes: ["sl","sle"], patternAliases: "sierra leone|сьерра-леоне|freetown|фритаун" },
  { tag: "🇹🇯 Tajikistan", flag: "🇹🇯", name: "Tajikistan", codes: ["tj","tjk"], patternAliases: "tajikistan|таджикистан|dushanbe|душанбе" },
  { tag: "🇹🇭 Thailand", flag: "🇹🇭", name: "Thailand", codes: ["th","tha"], patternAliases: "thailand|таиланд|bangkok|бангкок" },
  { tag: "🇹🇿 Tanzania", flag: "🇹🇿", name: "Tanzania", codes: ["tz","tza"], patternAliases: "tanzania|танзания|dodoma|додома" },
  { tag: "🇹🇨 Turks & Caicos Islands", flag: "🇹🇨", name: "Turks & Caicos Islands", codes: ["tc","tca"], patternAliases: "turks & caicos islands|тёркс и кайкос|cockburn town|кокберн-таун" },
  { tag: "🇹🇬 Togo", flag: "🇹🇬", name: "Togo", codes: ["tg","tgo"], patternAliases: "togo|того|lomé|ломе" },
  { tag: "🇹🇰 Tokelau", flag: "🇹🇰", name: "Tokelau", codes: ["tk","tkl"], patternAliases: "tokelau|токелау|atafu|атафу" },
  { tag: "🇹🇴 Tonga", flag: "🇹🇴", name: "Tonga", codes: ["to","ton"], patternAliases: "tonga|тонга|nuku'alofa|нукуалофа" },
  { tag: "🇹🇹 Trinidad & Tobago", flag: "🇹🇹", name: "Trinidad & Tobago", codes: ["tt","tto"], patternAliases: "trinidad & tobago|тринидад и тобаго|port of spain|порт-оф-спейн" },
  { tag: "🇹🇻 Tuvalu", flag: "🇹🇻", name: "Tuvalu", codes: ["tv","tuv"], patternAliases: "tuvalu|тувалу|fongafale|фонгафале" },
  { tag: "🇹🇳 Tunisia", flag: "🇹🇳", name: "Tunisia", codes: ["tn","tun"], patternAliases: "tunisia|тунис|tunis" },
  { tag: "🇹🇲 Turkmenistan", flag: "🇹🇲", name: "Turkmenistan", codes: ["tm","tkm"], patternAliases: "turkmenistan|туркменистан|ashgabat|ашхабад" },
  { tag: "🇹🇷 Turkey", flag: "🇹🇷", name: "Turkey", codes: ["tr","tur"], patternAliases: "turkey|türkiye|турция|ankara|анкара|istanbul|стамбул" },
  { tag: "🇺🇬 Uganda", flag: "🇺🇬", name: "Uganda", codes: ["ug","uga"], patternAliases: "uganda|уганда|kampala|кампала" },
  { tag: "🇺🇿 Uzbekistan", flag: "🇺🇿", name: "Uzbekistan", codes: ["uz","uzb"], patternAliases: "uzbekistan|узбекистан|tashkent|ташкент" },
  { tag: "🇺🇦 Ukraine", flag: "🇺🇦", name: "Ukraine", codes: ["ua","ukr"], patternAliases: "ukraine|украина|kiev|киев" },
  { tag: "🇼🇫 Wallis & Futuna", flag: "🇼🇫", name: "Wallis & Futuna", codes: ["wf","wlf"], patternAliases: "wallis & futuna|уоллис и футуна|mata-utu|мата-уту" },
  { tag: "🇺🇾 Uruguay", flag: "🇺🇾", name: "Uruguay", codes: ["uy","ury"], patternAliases: "uruguay|уругвай|montevideo|монтевидео" },
  { tag: "🇫🇴 Faroe Islands", flag: "🇫🇴", name: "Faroe Islands", codes: ["fo","fro"], patternAliases: "faroe islands|фарерские о-ва|torshavn|торсхавн" },
  { tag: "🇫🇯 Fiji", flag: "🇫🇯", name: "Fiji", codes: ["fj","fji"], patternAliases: "fiji|фиджи|suva|сува" },
  { tag: "🇵🇭 Philippines", flag: "🇵🇭", name: "Philippines", codes: ["ph","phl"], patternAliases: "philippines|филиппины|manila|манила" },
  { tag: "🇫🇮 Finland", flag: "🇫🇮", name: "Finland", codes: ["fi","fin"], patternAliases: "finland|финляндия|helsinki|хельсинки" },
  { tag: "🇫🇰 Falkland Islands", flag: "🇫🇰", name: "Falkland Islands", codes: ["fk","flk"], patternAliases: "falkland islands|фолклендские о-ва|stanley|стэнли" },
  { tag: "🇫🇷 France", flag: "🇫🇷", name: "France", codes: ["fr","fra"], patternAliases: "франция|paris|париж", patternExtras: ["(?<!de-)(?<![\\p{L}\\p{N}])france(?![\\p{L}\\p{N}])"] },
  { tag: "🇵🇫 French Polynesia", flag: "🇵🇫", name: "French Polynesia", codes: ["pf","pyf"], patternAliases: "french polynesia|французская полинезия|papeete|папеэте" },
  { tag: "🇹🇫 French Southern Territories", flag: "🇹🇫", name: "French Southern Territories", codes: ["tf","atf"], patternAliases: "french southern territories|французские южные территории" },
  { tag: "🇭🇲 Heard & McDonald Islands", flag: "🇭🇲", name: "Heard & McDonald Islands", codes: ["hm","hmd"], patternAliases: "heard & mcdonald islands|о-ва херд и макдональд" },
  { tag: "🇭🇷 Croatia", flag: "🇭🇷", name: "Croatia", codes: ["hr","hrv"], patternAliases: "croatia|хорватия|zagreb|загреб" },
  { tag: "🇨🇫 Central African Republic", flag: "🇨🇫", name: "Central African Republic", codes: ["cf","caf"], patternAliases: "central african republic|центрально-африканская республика|bangui|банги" },
  { tag: "🇹🇩 Chad", flag: "🇹🇩", name: "Chad", codes: ["td","tcd"], patternAliases: "chad|чад|n'djamena|нджамена" },
  { tag: "🇲🇪 Montenegro", flag: "🇲🇪", name: "Montenegro", codes: ["me","mne"], patternAliases: "montenegro|черногория|podgorica|подгорица" },
  { tag: "🇨🇿 Czechia", flag: "🇨🇿", name: "Czechia", codes: ["cz","cze"], patternAliases: "czechia|чехия|prague|прага" },
  { tag: "🇨🇱 Chile", flag: "🇨🇱", name: "Chile", codes: ["cl","chl"], patternAliases: "chile|чили|santiago|сантьяго" },
  { tag: "🇨🇭 Switzerland", flag: "🇨🇭", name: "Switzerland", codes: ["ch","che"], patternAliases: "switzerland|швейцария|berne|берн|zurich|цюрих|geneva|женева" },
  { tag: "🇸🇪 Sweden", flag: "🇸🇪", name: "Sweden", codes: ["se","swe"], patternAliases: "sweden|швеция|stockholm|стокгольм" },
  { tag: "🇸🇯 Svalbard & Jan Mayen", flag: "🇸🇯", name: "Svalbard & Jan Mayen", codes: ["sj","sjm"], patternAliases: "svalbard & jan mayen|шпицберген и ян-майен|longyearbyen|лонгйир" },
  { tag: "🇱🇰 Sri Lanka", flag: "🇱🇰", name: "Sri Lanka", codes: ["lk","lka"], patternAliases: "sri lanka|шри-ланка|colombo|коломбо" },
  { tag: "🇪🇨 Ecuador", flag: "🇪🇨", name: "Ecuador", codes: ["ec","ecu"], patternAliases: "ecuador|эквадор|quito|кито" },
  { tag: "🇬🇶 Equatorial Guinea", flag: "🇬🇶", name: "Equatorial Guinea", codes: ["gq","gnq"], patternAliases: "equatorial guinea|экваториальная гвинея|malabo|малабо" },
  { tag: "🇪🇷 Eritrea", flag: "🇪🇷", name: "Eritrea", codes: ["er","eri"], patternAliases: "eritrea|эритрея|asmara|асмэра" },
  { tag: "🇸🇿 Eswatini", flag: "🇸🇿", name: "Eswatini", codes: ["sz","swz"], patternAliases: "eswatini|эсватини|mbabane|мбабане" },
  { tag: "🇪🇪 Estonia", flag: "🇪🇪", name: "Estonia", codes: ["ee","est"], patternAliases: "estonia|эстония|tallinn|таллинн|таллин" },
  { tag: "🇪🇹 Ethiopia", flag: "🇪🇹", name: "Ethiopia", codes: ["et","eth"], patternAliases: "ethiopia|эфиопия|addis ababa|аддис-абеба" },
  { tag: "🇿🇦 South Africa", flag: "🇿🇦", name: "South Africa", codes: ["za","zaf"], patternAliases: "south africa|южно-африканская республика|pretoria|претория" },
  { tag: "🇬🇸 South Georgia & South Sandwich Islands", flag: "🇬🇸", name: "South Georgia & South Sandwich Islands", codes: ["gs","sgs"], patternAliases: "south georgia & south sandwich islands|южная георгия и южные сандвичевы о-ва|king edward point|кинг-эдвард-пойнт" },
  { tag: "🇸🇸 South Sudan", flag: "🇸🇸", name: "South Sudan", codes: ["ss","ssd"], patternAliases: "south sudan|южный судан|juba|джуба" },
  { tag: "🇯🇲 Jamaica", flag: "🇯🇲", name: "Jamaica", codes: ["jm","jam"], patternAliases: "jamaica|ямайка|kingston|кингстон" },
  { tag: "🇯🇵 Japan", flag: "🇯🇵", name: "Japan", codes: ["jp","jpn"], patternAliases: "japan|япония|tokyo|токио" }
]

// Список хранит только буквальные алиасы; границы и коды добавляются один раз при сборке.
function escapeCountryPatternLiteral(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}

function createCountryPattern(country) {
  const aliases = country.patternAliases.split('|').filter(Boolean)
  const patternParts = [escapeCountryPatternLiteral(country.flag)]

  if (aliases.length) {
    const aliasPattern = aliases.map(escapeCountryPatternLiteral).join('|')
    patternParts.push(`(?<![\\p{L}\\p{N}])(?:${aliasPattern})(?![\\p{L}\\p{N}])`)
  }

  patternParts.push(...(country.patternExtras || []))
  patternParts.push(...(country.patternCodePatterns || []))

  const patternCodes = country.patternCodes ?? (country.patternCodePatterns?.length ? [] : country.codes)
  if (patternCodes.length) {
    patternParts.push(`(?:^|[^a-z])(?:${patternCodes.join('|')})(?:$|[^a-z])`)
  }

  return new RegExp(patternParts.join('|'), 'iu')
}

COUNTRY_RULES.forEach(country => {
  country.pattern = createCountryPattern(country)
})

const COUNTRY_CATALOG = createCountryCatalog()
const COUNTRY_BY_FLAG = new Map(COUNTRY_CATALOG.map(country => [country.flag, country]))
const COUNTRY_BY_ENGLISH_NAME = new Map(
  COUNTRY_CATALOG.map(country => [country.name.toLowerCase(), country])
)
const COUNTRY_BY_ISO_CODE = new Map()
COUNTRY_RULES.forEach(country => {
  // В COUNTRY_RULES первые два кода — ISO alpha-2 и alpha-3; остальные, если есть, — дополнительные алиасы.
  country.codes.slice(0, 2).forEach(code => COUNTRY_BY_ISO_CODE.set(code.toLowerCase(), country))
})

// Логирование начала выполнения
log(`🚀 Начало работы скрипта распределения нод`)

// 1. Получение входных параметров из Sub-Store
let { type, name, fileName, outbound, includeUnsupportedProxy, url } = $arguments

// Получение входных параметров из Sub-Store
const entries = [
  ['type', type],
  ['name', name],
  ['fileName', fileName],
  ['outbound', outbound],
  ['includeUnsupportedProxy', includeUnsupportedProxy],
  ['url', url],
]

const isPresent = (val) => val !== undefined && val !== null && !(typeof val === 'string' && val.trim() === '')

const formattedParams = entries
  .filter(([, val]) => isPresent(val))
  .map(([key, val]) => `${key}: ${val}`)
  .join(', ')

log(`Входные параметры -> ${formattedParams || 'нет'}`)

if (!isPresent(outbound)) {
  throw new Error('Параметр outbound обязателен и не задан')
}

if (![name, fileName, url].some(isPresent)) {
  throw new Error('Необходимо указать хотя бы один из параметров: name, fileName или url')
}

// Определение типа подписки: 'collection' (комбинированная) или 'subscription' (одиночная)
type = /^1$|col|кол/i.test(type) ? 'collection' : 'subscription'

// Выбор парсера (JSON5, если поддерживается средой, иначе стандартный JSON)
const parser = ProxyUtils.JSON5 || JSON
log(`① Парсинг конфигурации с помощью ${ProxyUtils.JSON5 ? 'JSON5' : 'JSON'}`)

let config
try {
  // Считываем исходный шаблон конфигурации sing-box
  config = parser.parse($content ?? $files[0])
} catch (e) {
  log(`${e.message ?? e}`)
  throw new Error(`Ошибка: Конфигурационный файл шаблона имеет невалидный формат ${ProxyUtils.JSON5 ? 'JSON5' : 'JSON'}`)
}

log(`② Загрузка узлов подписки`)

let proxies = []
let outbounds = []
let endpoints = []
let data = {}
let dataFile = {}

// Загрузка нод из URL или из сохраненной подписки в Sub-Store
if (url) {
  log(`Чтение подписки напрямую из URL: ${url}`)
  try {
    data = parser.parse(await produceArtifact({
      name,
      type,
      platform: 'sing-box',
      produceOpts: {
        'include-unsupported-proxy': includeUnsupportedProxy,
      },
      subscription: {
        name,
        url,
        source: 'remote',
      },
    }))
  } catch (e) {
    log(`${e.message ?? e}`)
    throw new Error(`Не удалось загрузить подписку из URL '${url}'. Проверьте формат, требование к HWID и User-Agent.`)
  }
} else {
  log(`Загрузка подписки "${name}" (тип: ${type === 'collection' ? 'коллекция' : 'одиночная'})`)
  try {
    data = parser.parse(await produceArtifact({
      name,
      type,
      platform: 'sing-box',
      produceOpts: {
        'include-unsupported-proxy': includeUnsupportedProxy,
      },
    }))
  } catch (e) {
    log(`${e.message ?? e}`)
    throw new Error(`Не удалось загрузить подписку '${name}'. Проверьте формат, требование к HWID и User-Agent.`)
  }
}

if (fileName){
  try {
    dataFile = parser.parse(await produceArtifact({
      name: fileName,
      type: 'file',
      platform: 'sing-box',
      produceOpts: {
        'include-unsupported-proxy': includeUnsupportedProxy,
      },
    }))
  } catch (e) {
    log(`${e.message ?? e}`)
    throw new Error(`Не удалось загрузить файл '${fileName}'. Проверьте имя и формат файла.`)
  }
}

// Слияние полученного ответа в массивы outbounds и endpoints
outbounds = [...dataFile.outbounds ?? [], ...data.outbounds ?? []]
endpoints = [...dataFile.endpoints ?? [], ...data.endpoints ?? []]

// Объединяем outbounds и endpoints в один общий массив прокси
proxies = [...outbounds, ...endpoints]
log(`Загружено: ${outbounds.length} узлов (outbounds), ${endpoints.length} эндпоинтов (endpoints)`)

// Теги из шаблона резервируем, но не изменяем. При совпадениях переименовываем
// только пришедшие узлы, чтобы не было коллизий ни с шаблоном, ни друг с другом.
const occupiedTags = collectConfigTagDefinitions(config)
const renamedProxyTags = normalizeProxyTags(proxies, occupiedTags)
if (renamedProxyTags > 0) {
  log(`Переименовано совпадающих тегов узлов: ${renamedProxyTags} (добавлен числовой постфикс через дефис)`)
}

log(`③ Разбор правил фильтрации и группировки (outbound)`)

// Один объект правила хранит отдельно группу, узлы и страны.
const outboundRules = (outbound || '')
  .split('📂')
  .map(rule => rule.trim())
  .filter(Boolean)
  .map(parseOutboundRule)

outboundRules.forEach(rule => {
  if (!rule.includeNodes) {
    log(`Правило: добавление нод в outbound 📂 ${rule.groupRegex} отключено через 🔖🚫`)
  } else {
    log(`Правило: Ноды, подходящие под 🔖 ${rule.nodePattern}, будут вставлены в outbound 📂 ${rule.groupRegex}`)
  }
})

log(`④ Распределение нод по группам`)

// Если в конфиге нет массива outbounds, создаем его
if (!Array.isArray(config.outbounds)) {
  config.outbounds = []
}

// Запоминаем исходный порядок элементов групп до добавления входящих нод.
const templateGroupOutbounds = new Map(
  config.outbounds.map(group => [
    group,
    Array.isArray(group.outbounds) ? [...group.outbounds] : [],
  ])
)

// Каждое правило независимо добавляет подходящие обычные узлы в совпавшие группы.
const nodeTagsByRule = new Map()
config.outbounds.forEach(group => {
  outboundRules.forEach(rule => {
    if (!rule.groupRegex.test(group.tag)) return
    if (!Array.isArray(group.outbounds)) group.outbounds = []

    if (!nodeTagsByRule.has(rule)) {
      nodeTagsByRule.set(rule, rule.includeNodes ? getTags(proxies, rule.nodeMatcher) : [])
    }
    const tags = nodeTagsByRule.get(rule)
    log(`Группа 📂 "${group.tag}" совпала с ${rule.groupRegex}. Добавлено нод: ${tags.length}`)
    group.outbounds.push(...tags)
  })
})

log(`⑤ Поиск стран и создание urltest-групп`)

addFlagCountries(COUNTRY_CATALOG, proxies)
const detectedCountries = COUNTRY_CATALOG
  .map(country => ({
    ...country,
    tags: proxies.filter(proxy => countryMatchesTag(country, proxy.tag)).map(proxy => proxy.tag),
  }))
  .filter(country => country.tags.length > 0)
const countriesByNodeTag = new Map()
detectedCountries.forEach(country => {
  country.tags.forEach(tag => {
    if (!countriesByNodeTag.has(tag)) countriesByNodeTag.set(tag, [])
    countriesByNodeTag.get(tag).push(country)
  })
})
const countriesWithEnoughNodes = detectedCountries.filter(country => country.tags.length >= 2)
const ambiguousSingletonTags = new Set(detectedCountries
  .filter(country =>
    country.tags.length === 1 && countriesByNodeTag.get(country.tags[0]).length > 1
  )
  .map(country => country.tags[0]))
const selectedSingletonCountries = detectedCountries.filter(country =>
  country.tags.length === 1 &&
  countriesByNodeTag.get(country.tags[0]).length === 1 &&
  outboundRules.some(rule => rule.countryFilter(country))
)
const selectedCountries = countriesWithEnoughNodes.filter(country =>
  outboundRules.some(rule => rule.countryFilter(country))
)
const generatedCountryTags = new Set()
selectedCountries.forEach(country => {
  country.groupTag = createUniqueTag(country.tag, occupiedTags)
  generatedCountryTags.add(country.groupTag)
})

if (countriesWithEnoughNodes.length === 0) {
  log(`Ни для одной страны не найдено минимум 2 узла по её паттерну; страновые urltest-группы не создаются`)
} else {
  log(`Стран с 2+ совпавшими узлами: ${countriesWithEnoughNodes.length}; разрешено правилами outbound: ${selectedCountries.length}`)
  selectedCountries.forEach(country => {
    // Не добавляем одну страновую группу повторно, если шаблон/правила запускались повторно.
    if (config.outbounds.some(item => item.tag === country.groupTag)) {
      log(`Группа "${country.groupTag}" уже существует в шаблоне — пропускаем динамическое создание`)
      return
    }

    config.outbounds.push({
      tag: country.groupTag,
      type: 'urltest',
      outbounds: country.tags,
      interval: '10m',
      tolerance: 75,
      idle_timeout: '30m0s',
    })
    log(`Создана группа urltest "${country.groupTag}" (${country.tags.length} узлов)`)
  })
}

if (selectedSingletonCountries.length > 0) {
  log(`Стран с одной однозначно распознанной нодой, разрешенных правилами outbound: ${selectedSingletonCountries.length}`)
}
if (ambiguousSingletonTags.size > 0) {
  log(`Не добавлено однозначно по стране нод, совпавших с паттернами нескольких стран: ${ambiguousSingletonTags.size}`)
}

// Добавляем выбранные страновые urltest-группы и одиночные ноды в selector-группы.
// Фильтр стран 🌐 независим от фильтра обычных узлов 🔖.
if (generatedCountryTags.size > 0 || selectedSingletonCountries.length > 0) {
  config.outbounds.forEach(group => {
    if (group.type !== 'selector' || !Array.isArray(group.outbounds)) return

    const matchingRules = outboundRules.filter(rule => rule.groupRegex.test(group.tag))
    if (matchingRules.length === 0) return

    const countryGroupRefs = []
    matchingRules.forEach(rule => {
      selectedCountries.forEach(country => {
        if (
          rule.countryFilter(country) &&
          generatedCountryTags.has(country.groupTag) &&
          !countryGroupRefs.includes(country.groupTag)
        ) {
          countryGroupRefs.push(country.groupTag)
        }
      })
    })

    const singletonNodeRefs = []
    matchingRules.forEach(rule => {
      selectedSingletonCountries.forEach(country => {
        const tag = country.tags[0]
        if (rule.countryFilter(country) && !singletonNodeRefs.includes(tag)) {
          singletonNodeRefs.push(tag)
        }
      })
    })

    if (countryGroupRefs.length > 0 || singletonNodeRefs.length > 0) {
      const templateRefs = templateGroupOutbounds.get(group) ?? []
      const nodeRefs = group.outbounds.slice(templateRefs.length)
      const existingNodeRefs = new Set(nodeRefs)
      const newSingletonNodeRefs = singletonNodeRefs.filter(tag => !existingNodeRefs.has(tag))
      group.outbounds = [
        ...templateRefs,
        ...countryGroupRefs,
        ...nodeRefs,
        ...newSingletonNodeRefs,
      ]
      countryGroupRefs.forEach(tag =>
        log(`После элементов шаблона в selector "${group.tag}" добавлена страновая группа "${tag}"`)
      )
      newSingletonNodeRefs.forEach(tag =>
        log(`Одна нода страны "${tag}" добавлена напрямую в selector "${group.tag}"`)
      )
    }
  })
}

log(`⑥ Проверка на пустые группы`)

// Резервный профиль прямого соединения для остальных пустых групп
const compatible_outbound = {
  tag: createUniqueTag('🔌 DIRECT', occupiedTags),
  type: 'direct',
}

let compatible

config.outbounds.forEach(outbound => {
  if (!['selector', 'urltest'].includes(outbound.type)) return
  if (!Array.isArray(outbound.outbounds)) {
    outbound.outbounds = []
  }

  // Каждая заранее заданная selector/urltest-группа должна остаться непустой,
  // даже если для нее не было правила outbound или подходящих узлов.
  if (outbound.outbounds.length === 0) {
    if (!compatible) {
      config.outbounds.push(compatible_outbound)
      compatible = true
    }
    log(`⚠️ Группа 📂 "${outbound.tag}" пуста! Вставляем заглушку (${compatible_outbound.tag} / direct)`)
    outbound.outbounds.push(compatible_outbound.tag)
  }
})

// Добавляем все прокси-серверы и эндпоинты в конец итогового конфига
config.outbounds.push(...outbounds)
if (!Array.isArray(config.endpoints)) {
  config.endpoints = []
}
config.endpoints.push(...endpoints)

// Сохраняем итоговую конфигурацию в формате JSON
$content = JSON.stringify(config, null, 2)

// ================= ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =================

// Дополняет встроенные паттерны всеми регионами, которые доступны через Intl,
// а флаги из тегов распознает напрямую как пары Regional Indicator.
function createCountryCatalog() {
  const catalogByCode = new Map()
  COUNTRY_RULES.forEach(country => {
    country.aliases = []
    country.codes.filter(code => code.length === 2).forEach(code => catalogByCode.set(code, country))
  })

  try {
    if (typeof Intl !== 'undefined' && typeof Intl.DisplayNames === 'function') {
      const englishNames = new Intl.DisplayNames(['en'], { type: 'region' })
      const russianNames = new Intl.DisplayNames(['ru'], { type: 'region' })
      const staticNames = new Set(COUNTRY_RULES.map(country => country.name.toLowerCase()))
      const generatedByName = new Map()

      for (let first = 65; first <= 90; first++) {
        for (let second = 65; second <= 90; second++) {
          const code = String.fromCharCode(first, second).toLowerCase()
          const englishName = englishNames.of(code.toUpperCase())
          const russianName = russianNames.of(code.toUpperCase())
          if (
            !englishName ||
            englishName.toLowerCase() === code ||
            /unknown region/i.test(englishName)
          ) continue

          const existing = catalogByCode.get(code)
          if (existing) {
            existing.aliases.push(englishName, russianName)
            continue
          }

          const normalizedName = englishName.toLowerCase()
          if (staticNames.has(normalizedName)) continue
          if (generatedByName.has(normalizedName)) {
            generatedByName.get(normalizedName).codes.push(code)
            continue
          }

          const flag = countryFlagFromCode(code)
          const country = {
            tag: `${flag} ${englishName}`,
            flag,
            name: englishName,
            codes: [code],
            aliases: [englishName, russianName].filter(Boolean),
            pattern: null,
          }
          catalogByCode.set(code, country)
          generatedByName.set(normalizedName, country)
        }
      }
    }
  } catch (e) {
    log(`Intl.DisplayNames недоступен; будут использованы встроенные паттерны и флаги`)
  }

  return [...new Set(catalogByCode.values())]
}

function addFlagCountries(catalog, proxies) {
  const knownFlags = new Set(catalog.map(country => country.flag))
  proxies.forEach(proxy => {
    extractCountryFlags(proxy.tag).forEach(flag => {
      if (knownFlags.has(flag)) return

      const code = countryCodeFromFlag(flag)
      const name = code.toUpperCase()
      const country = {
        tag: `${flag} ${name}`,
        flag,
        name,
        codes: [code],
        aliases: [],
        pattern: null,
      }
      catalog.push(country)
      COUNTRY_BY_FLAG.set(flag, country)
      knownFlags.add(flag)
    })
  })
}

function countryFlagFromCode(code) {
  return String.fromCodePoint(...Array.from(code.toUpperCase(), char =>
    0x1f1e6 + char.charCodeAt(0) - 65
  ))
}

function countryCodeFromFlag(flag) {
  return Array.from(flag, char =>
    String.fromCharCode(char.codePointAt(0) - 0x1f1e6 + 65)
  ).join('').toLowerCase()
}

function extractCountryFlags(value) {
  const points = Array.from(String(value ?? ''), char => char.codePointAt(0))
  const flags = []
  for (let index = 0; index < points.length - 1; index++) {
    if (
      points[index] >= 0x1f1e6 && points[index] <= 0x1f1ff &&
      points[index + 1] >= 0x1f1e6 && points[index + 1] <= 0x1f1ff
    ) {
      flags.push(String.fromCodePoint(points[index], points[index + 1]))
      index++
    }
  }
  return flags
}

function countryMatchesTag(country, value) {
  const tag = String(value ?? '')
  // Для встроенных стран pattern — источник истины; fallback нужен только для Intl/неизвестных флагов.
  if (country.pattern) return country.pattern.test(tag)
  if (tag.includes(country.flag)) return true

  const normalizedTag = tag.toLowerCase()
  if ((country.aliases || []).some(alias => alias && normalizedTag.includes(alias.toLowerCase()))) {
    return true
  }

  return (country.nodeCodes || country.codes).some(code =>
    new RegExp(`(?:^|[^a-z0-9])${code}(?:$|[^a-z0-9])`, 'i').test(tag)
  )
}

function collectConfigTagDefinitions(value, tags = new Set()) {
  if (Array.isArray(value)) {
    value.forEach(item => collectConfigTagDefinitions(item, tags))
  } else if (value && typeof value === 'object') {
    Object.entries(value).forEach(([key, child]) => {
      if (key === 'tag') {
        const definitions = Array.isArray(child) ? child : [child]
        definitions.forEach(tag => {
          if (typeof tag === 'string') tags.add(tag)
        })
      }
      collectConfigTagDefinitions(child, tags)
    })
  }
  return tags
}

function normalizeProxyTags(proxies, occupiedTags) {
  const templateTags = new Set(occupiedTags)
  const firstTagByOriginal = new Map()
  let renamedCount = 0

  proxies.forEach(proxy => {
    const originalTag = String(proxy.tag ?? 'proxy')
    const uniqueTag = createUniqueTag(originalTag, occupiedTags)
    if (!firstTagByOriginal.has(originalTag)) {
      firstTagByOriginal.set(originalTag, uniqueTag)
    }
    if (proxy.tag !== uniqueTag) renamedCount++
    proxy.tag = uniqueTag
  })

  // Сохраняем связи между узлами (например, detour), если переименовали их теги.
  proxies.forEach(proxy => {
    if (
      typeof proxy.detour === 'string' &&
      !templateTags.has(proxy.detour) &&
      firstTagByOriginal.has(proxy.detour)
    ) {
      proxy.detour = firstTagByOriginal.get(proxy.detour)
    }
    if (Array.isArray(proxy.outbounds)) {
      proxy.outbounds = proxy.outbounds.map(tag =>
        !templateTags.has(tag) ? firstTagByOriginal.get(tag) ?? tag : tag
      )
    }
  })

  return renamedCount
}

// При совпадении добавляет числовой постфикс через дефис: -1, -2 и далее.
function createUniqueTag(baseTag, occupiedTags) {
  let tag = baseTag
  let suffix = 1
  while (occupiedTags.has(tag)) {
    tag = `${baseTag}-${suffix++}`
  }

  occupiedTags.add(tag)
  return tag
}

// Разбор фильтра стран из правила outbound: включение или исключение через 🚫.
function parseCountryFilter(value) {
  const raw = String(value ?? '').trim()
  if (!raw) return () => true
  if (raw === '🚫') return () => false

  const [includePart = '', excludePart = ''] = raw.split('🚫')
  const includes = includePart.split(/[|,]/).map(normalizeCountryToken).filter(Boolean)
  const excludes = excludePart.split(/[|,]/).map(normalizeCountryToken).filter(Boolean)

  const matches = (country, tokens) => tokens.some(token =>
    token === normalizeCountryToken(country.flag) ||
    token === normalizeCountryToken(country.name) ||
    (country.aliases || []).some(alias => token === normalizeCountryToken(alias)) ||
    country.codes.includes(token)
  )

  const knownTokens = new Set(COUNTRY_RULES.flatMap(country => [
    normalizeCountryToken(country.flag),
    normalizeCountryToken(country.name),
    ...country.codes.map(normalizeCountryToken),
  ]))
  COUNTRY_CATALOG.forEach(country => {
    knownTokens.add(normalizeCountryToken(country.flag))
    knownTokens.add(normalizeCountryToken(country.name))
    country.codes.forEach(code => knownTokens.add(normalizeCountryToken(code)))
    ;(country.aliases || []).forEach(alias => knownTokens.add(normalizeCountryToken(alias)))
  })
  const unknownTokens = [...includes, ...excludes].filter(token => !knownTokens.has(token))
  if (unknownTokens.length > 0) {
    log(`⚠️ Неизвестные значения фильтра стран outbound: ${unknownTokens.join(', ')}`)
  }

  return country =>
    (includes.length === 0 || matches(country, includes)) &&
    !matches(country, excludes)
}

function normalizeCountryToken(value) {
  return String(value ?? '').trim().toLowerCase()
}

// Фильтрация тегов по смешанному matcher: country-токены или обычное регулярное выражение.
function getTags(proxies, matcher) {
  return (matcher ? proxies.filter(proxy => matcher(proxy.tag)) : proxies).map(proxy => proxy.tag)
}

// Форматированный вывод логов в консоль Sub-Store
function log(v) {
  console.log(`[📦 sing-box] ${v}`)
}

// Разбирает одно правило на независимые фильтры группы, узлов и стран.
function parseOutboundRule(ruleText) {
  const [groupAndNodes, countryPattern] = ruleText.split('🌐')
  const hasNodeMarker = groupAndNodes.includes('🔖')
  const [groupPattern, nodePattern = '.*'] = groupAndNodes.split('🔖')
  const includeNodes = !(hasNodeMarker && nodePattern.trim() === '🚫')

  return {
    groupRegex: createOutboundRegExp(groupPattern),
    nodePattern: nodePattern.trim(),
    nodeMatcher: includeNodes ? createTagMatcher(nodePattern) : null,
    includeNodes,
    countryFilter: parseCountryFilter(countryPattern),
  }
}

// В 🔖 точные флаг/ISO-код проверяются как страна; остальные варианты остаются regex.
function createTagMatcher(tagPattern) {
  const [includePart = '', excludePart = ''] = String(tagPattern).split('🚫')
  const includeClean = includePart.trim()
  const excludeClean = excludePart.trim()
  const includeMatcher = includeClean ? createTagExpressionMatcher(includeClean) : null
  const excludeMatcher = excludeClean ? createTagExpressionMatcher(excludeClean) : null

  return value => {
    const tag = String(value ?? '')
    return (!includeMatcher || includeMatcher(tag)) &&
      (!excludeMatcher || !excludeMatcher(tag))
  }
}

function createTagExpressionMatcher(expression) {
  const countryMatchers = []
  const regexAlternatives = []

  splitTopLevelAlternatives(expression).forEach(alternative => {
    const countryMatcher = createCountryTagMatcher(alternative.trim())
    if (countryMatcher) {
      countryMatchers.push(countryMatcher)
    } else {
      regexAlternatives.push(alternative)
    }
  })

  const regex = regexAlternatives.length
    ? new RegExp(`(?:${regexAlternatives.join('|')})`, 'i')
    : null

  return value =>
    countryMatchers.some(matcher => matcher(value)) ||
    Boolean(regex && regex.test(value))
}

function createCountryTagMatcher(token) {
  if (!token) return null

  const country = COUNTRY_BY_ISO_CODE.get(token.toLowerCase())
  if (country) return value => countryMatchesTag(country, value)

  const countryByName = COUNTRY_BY_ENGLISH_NAME.get(token.toLowerCase())
  if (countryByName) return value => countryMatchesTag(countryByName, value)

  if (isCountryFlagToken(token)) {
    return value => {
      const flaggedCountry = COUNTRY_BY_FLAG.get(token)
      return Boolean(flaggedCountry && countryMatchesTag(flaggedCountry, value))
    }
  }

  return null
}

function isCountryFlagToken(value) {
  const points = Array.from(value, char => char.codePointAt(0))
  return points.length === 2 &&
    points.every(point => point >= 0x1f1e6 && point <= 0x1f1ff)
}

// Делит только верхнеуровневые альтернативы, не затрагивая `|` внутри групп,
// символьных классов или escaped-выражений.
function splitTopLevelAlternatives(pattern) {
  const alternatives = []
  let start = 0
  let depth = 0
  let inCharacterClass = false
  let escaped = false

  for (let index = 0; index < pattern.length; index++) {
    const char = pattern[index]
    if (escaped) {
      escaped = false
      continue
    }
    if (char === '\\') {
      escaped = true
      continue
    }
    if (inCharacterClass) {
      if (char === ']') inCharacterClass = false
      continue
    }
    if (char === '[') {
      inCharacterClass = true
    } else if (char === '(') {
      depth++
    } else if (char === ')') {
      depth = Math.max(0, depth - 1)
    } else if (char === '|' && depth === 0) {
      alternatives.push(pattern.slice(start, index))
      start = index + 1
    }
  }

  alternatives.push(pattern.slice(start))
  return alternatives
}

// Создание Регулярного Выражения для имени группы (📂 селектора) sing-box
function createOutboundRegExp(outboundPattern) {
  return new RegExp(outboundPattern, 'i')
}
