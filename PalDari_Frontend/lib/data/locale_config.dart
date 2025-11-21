// 필요하면 국가도 여기서 같이 관리
const kCountries = <String>[
  '말레이시아','한국','일본','미국','캐나다','호주','영국','독일','프랑스',
];

// ✅ 전역 고정 언어 목록 (라벨/코드)
const kLanguages = <Map<String, String>>[
  {'label': '전체',   'code': 'all'},
  {'label': '한국어', 'code': 'ko'},
  {'label': '영어',   'code': 'en'},
  {'label': '일본어', 'code': 'ja'},
  {'label': '프랑스어','code': 'fr'},
  {'label': '독일어', 'code': 'de'},
  {'label': '말레이어','code': 'ms'},
];

// label ↔ code 헬퍼
String langLabelOf(String code) =>
    kLanguages.firstWhere((e) => e['code']==code, orElse: ()=>{'label':'전체'})['label']!;
String langCodeOf(String label) =>
    kLanguages.firstWhere((e) => e['label']==label, orElse: ()=>{'code':'all'})['code']!;
