import 'package:flutter_test/flutter_test.dart';
import 'package:salah_companion/data/quran.dart';
import 'package:salah_companion/ui/tajweed.dart';

void main() {
  test('Tajweed markup parses into coloured and plain parts', () {
    final parts = parseTajweed('qul huwal-lāhu aḥa{Q:d}');
    expect(parts.length, 2);
    expect(parts.last.rule, 'Q');
    expect(plainTransliteration('i{G:nn}{Mj:ā} a{I:n}zalnāhu'), 'innā anzalnāhu');
  });

  test('Every rule code used in the Quran data is defined', () {
    final codes = RegExp(r'\{([A-Za-z]+):');
    for (final s in kSurahs) {
      for (final a in [kBasmalah, ...s.ayat]) {
        for (final m in codes.allMatches(a.tr)) {
          expect(kRuleByCode.containsKey(m.group(1)), isTrue,
              reason: 'Unknown rule ${m.group(1)} in ${s.name}');
        }
      }
    }
  });

  test('Surah ayah counts', () {
    const expected = {
      1: 7, 95: 8, 96: 19, 97: 5, 98: 8, 99: 8, 100: 11, 101: 11, 102: 8, 103: 3,
      104: 9, 105: 5, 106: 4, 107: 7, 108: 3, 109: 6, 110: 3, 111: 5, 112: 4, 113: 5, 114: 6,
    };
    expect(kSurahs.length, expected.length);
    for (final s in kSurahs) {
      expect(s.ayat.length, expected[s.number], reason: s.name);
    }
  });
}
