import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _livingInCtrl = TextEditingController();
  final _introCtrl = TextEditingController();

  // === Dropdown data & mapping ===
  // 국적: code -> label(한국어 표기)
  static const Map<String, String> _countryOptions = {
    'KR': '대한민국',
    'JP': '일본',
    'CN': '중국',
    'MY': '말레이시아',
    'US': '미국',
    'CA': '캐나다',
    'GB': '영국',
  };
  // 언어: code -> native label
  static const Map<String, String> _languageOptions = {
    'ko': '한국어',
    'ja': '日本語',
    'zh': '中文',
    'ms': 'Bahasa Melayu',
    'en_US': 'English (US)',
    'en_GB': 'English (UK)',
  };

  // 선택값(코드 저장)
  String? _gender;     // 'MALE' | 'FEMALE' | 'OTHER' | null
  String? _country;    // 'KR' | 'JP' | ... | null
  String? _language;   // 'ko' | 'ja' | ... | null
  DateTime? _birthdate;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthState>();
      if (!auth.isLoggedIn) {
        if (mounted) Navigator.pushReplacementNamed(context, '/');
        return;
      }

      // 서버 최신값 가져오기
      await auth.fetchProfileBasic();

      final p = auth.profile ?? {};
      setState(() {
        // gender
        final g = (p['gender'] as String? ?? '').trim();
        _gender = g.isEmpty ? null : g;

        // birthdate (yyyy-MM-dd)
        final bd = (p['birthdate'] as String?);
        if (bd != null && bd.trim().isNotEmpty) {
          try {
            _birthdate = DateTime.parse(bd);
          } catch (_) {}
        }

        // livingIn / introduction
        _livingInCtrl.text = (p['livingIn'] as String?)?.trim() ?? '';
        _introCtrl.text = (p['introduction'] as String?)?.trim() ?? '';

        // country: 서버가 코드 또는 라벨로 줄 수 있으니 양방향 매핑
        final rawCountry = (p['country'] as String?)?.trim();
        _country = _toCountryCode(rawCountry);

        // language: 서버가 코드 또는 라벨로 줄 수 있으니 양방향 매핑
        final rawLang = (p['language'] as String?)?.trim();
        _language = _toLanguageCode(rawLang);
      });
    });
  }

  @override
  void dispose() {
    _livingInCtrl.dispose();
    _introCtrl.dispose();
    super.dispose();
  }

  // ===== 매핑 유틸 =====
  String? _toCountryCode(String? value) {
    if (value == null || value.isEmpty) return null;
    // 이미 코드면 그대로
    if (_countryOptions.containsKey(value)) return value;
    // 라벨을 코드로 역탐색
    final found = _countryOptions.entries
        .firstWhere(
          (e) => e.value == value,
      orElse: () => const MapEntry('', ''),
    )
        .key;
    return found.isEmpty ? null : found;
  }

  String? _toLanguageCode(String? value) {
    if (value == null || value.isEmpty) return null;
    if (_languageOptions.containsKey(value)) return value;
    final found = _languageOptions.entries
        .firstWhere(
          (e) => e.value == value,
      orElse: () => const MapEntry('', ''),
    )
        .key;
    return found.isEmpty ? null : found;
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final initial = _birthdate ?? DateTime(now.year - 20, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthdate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final ok = await context.read<AuthState>().updateProfileBasic(
      gender: _gender,
      birthdate: _birthdate,
      // 서버에는 코드 값을 저장 (원하면 라벨로 바꿔서 보내도 됨)
      country: _country,         // 예: 'KR'
      livingIn: _livingInCtrl.text.trim(),
      language: _language,       // 예: 'ko'
      introduction: _introCtrl.text.trim(),
    );

    setState(() => _loading = false);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내 정보가 저장되었습니다.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 실패. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFFFF7F1);
    const orange = Color(0xFFF29D52);
    const brown = Color(0xFF734124);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: brown),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        centerTitle: true,
        title: const Text(
          '내 정보 수정',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // 성별
                        DropdownButtonFormField<String>(
                          value: _gender,
                          items: const [
                            DropdownMenuItem(value: 'MALE',   child: Text('남성')),
                            DropdownMenuItem(value: 'FEMALE', child: Text('여성')),
                            DropdownMenuItem(value: 'OTHER',  child: Text('기타/선택안함')),
                          ],
                          decoration: const InputDecoration(
                            labelText: '성별',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => setState(() => _gender = v),
                        ),
                        const SizedBox(height: 12),

                        // 생년월일
                        Row(
                          children: [
                            Expanded(
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: '생년월일',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _birthdate == null
                                      ? '미설정'
                                      : '${_birthdate!.year}-${_birthdate!.month.toString().padLeft(2, '0')}-${_birthdate!.day.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _pickBirthdate,
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: const Text('선택'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 국적 (드롭다운)
                        DropdownButtonFormField<String>(
                          value: _country,
                          items: _countryOptions.entries
                              .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                              .toList(),
                          decoration: const InputDecoration(
                            labelText: '국적(출신 국가)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => setState(() => _country = v),
                        ),
                        const SizedBox(height: 12),

                        // 거주지 (텍스트) + 예시
                        TextFormField(
                          controller: _livingInCtrl,
                          decoration: const InputDecoration(
                            labelText: '현재 거주지',
                            hintText: '예: 인천 미추홀구 학익동',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 사용 언어 (드롭다운 / native labels)
                        DropdownButtonFormField<String>(
                          value: _language,
                          items: _languageOptions.entries
                              .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                              .toList(),
                          decoration: const InputDecoration(
                            labelText: '사용 언어',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => setState(() => _language = v),
                        ),
                        const SizedBox(height: 12),

                        // 소개
                        TextFormField(
                          controller: _introCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: '자기소개',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 저장 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _loading ? null : _save,
                            child: _loading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Text('저장'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
