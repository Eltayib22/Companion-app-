// Adhkar with their counts and the hadith collections that report them.
// Wording follows the commonly used texts (as collected in Ḥiṣn al-Muslim).
// English renderings are approximate meanings.

import 'quran.dart';

class Dhikr {
  final String ar;
  final String tr;
  final String en;
  final int count;
  final String source;
  const Dhikr(this.ar, this.tr, this.en, this.count, this.source);
}

class AdhkarSet {
  final String id;
  final String title;
  final String when;
  final List<Dhikr> items;
  const AdhkarSet(this.id, this.title, this.when, this.items);

  int get totalCount => items.fold(0, (a, d) => a + d.count);
}

final RegExp _markup = RegExp(r'\{[A-Za-z]+:([^}]*)\}');
String _plain(String s) => s.replaceAllMapped(_markup, (m) => m.group(1)!);

Dhikr _surahDhikr(int number, String name, String source) {
  final s = surahByNumber(number)!;
  final ar = [kBasmalah.ar, ...s.ayat.map((a) => a.ar)].join('  ۝  ');
  final tr = [kBasmalah.tr, ...s.ayat.map((a) => a.tr)].map(_plain).join(' · ');
  final en = s.ayat.map((a) => a.en).join(' ');
  return Dhikr(ar, tr, 'Sūrat $name: $en', 3, source);
}

const Dhikr _ayatAlKursi = Dhikr(
  'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
  'allāhu lā ilāha illā huwal-ḥayyul-qayyūm. lā taʾkhudhuhū sinatuw-wa lā nawm. lahū mā fis-samāwāti wa mā fil-arḍ. man dhal-ladhī yashfaʿu ʿindahū illā bi-idhnih. yaʿlamu mā bayna aydīhim wa mā khalfahum. wa lā yuḥīṭūna bishayʾim-min ʿilmihī illā bimā shāʾ. wasiʿa kursiyyuhus-samāwāti wal-arḍ. wa lā yaʾūduhū ḥifẓuhumā. wa huwal-ʿaliyyul-ʿaẓīm.',
  'Allah: there is no god but Him, the Ever-Living, the Sustainer of all. Neither drowsiness nor sleep overtakes Him. To Him belongs whatever is in the heavens and the earth. Who could intercede with Him except by His permission? He knows what is before them and what is behind them, and they grasp nothing of His knowledge except what He wills. His Seat extends over the heavens and the earth, and preserving them does not tire Him. He is the Most High, the Supreme. (Al-Baqarah 2:255)',
  1,
  'Ayat al-Kursī. Reported by an-Nasāʾī (as-Sunan al-Kubrā) and al-Ḥākim',
);

const Dhikr _sayyidulIstighfar = Dhikr(
  'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَىٰ عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي، فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
  'allāhumma anta rabbī lā ilāha illā ant. khalaqtanī wa ana ʿabduk, wa ana ʿalā ʿahdika wa waʿdika mastaṭaʿt. aʿūdhu bika min sharri mā ṣanaʿt. abūʾu laka biniʿmatika ʿalayya, wa abūʾu bidhanbī, faghfir lī, fa-innahū lā yaghfirudh-dhunūba illā ant.',
  'O Allah, You are my Lord; there is no god but You. You created me and I am Your servant, and I hold to Your covenant and promise as best I can. I seek refuge in You from the evil of what I have done. I acknowledge Your blessings upon me and I acknowledge my sin, so forgive me, for no one forgives sins except You.',
  1,
  'The best way to seek forgiveness. Reported by al-Bukhārī',
);

const Dhikr _bismillahLaYadurr = Dhikr(
  'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
  'bismil-lāhil-ladhī lā yaḍurru maʿasmihī shayʾun fil-arḍi wa lā fis-samāʾ, wa huwas-samīʿul-ʿalīm.',
  'In the name of Allah, with whose name nothing on earth or in the heavens can cause harm. He is the All-Hearing, the All-Knowing.',
  3,
  'Reported by Abū Dāwūd and at-Tirmidhī',
);

const Dhikr _raditu = Dhikr(
  'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا',
  'raḍītu billāhi rabbā, wa bil-islāmi dīnā, wa bimuḥammadin ṣallal-lāhu ʿalayhi wa sallama nabiyyā.',
  'I am content with Allah as my Lord, Islam as my way of life, and Muhammad, peace and blessings be upon him, as my Prophet.',
  3,
  'Reported by Abū Dāwūd and at-Tirmidhī',
);

const Dhikr _yaHayy = Dhikr(
  'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَىٰ نَفْسِي طَرْفَةَ عَيْنٍ',
  'yā ḥayyu yā qayyūmu biraḥmatika astaghīth. aṣliḥ lī shaʾnī kullah, wa lā takilnī ilā nafsī ṭarfata ʿayn.',
  'O Ever-Living, O Sustainer of all, I call on Your mercy for help. Set right all my affairs, and do not leave me to myself even for the blink of an eye.',
  1,
  'Reported by an-Nasāʾī (as-Sunan al-Kubrā) and al-Ḥākim',
);

const Dhikr _afini = Dhikr(
  'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَٰهَ إِلَّا أَنْتَ',
  'allāhumma ʿāfinī fī badanī, allāhumma ʿāfinī fī samʿī, allāhumma ʿāfinī fī baṣarī, lā ilāha illā ant.',
  'O Allah, keep my body well. O Allah, keep my hearing well. O Allah, keep my sight well. There is no god but You.',
  3,
  'Reported by Abū Dāwūd',
);

const Dhikr _subhanWaBihamdihi = Dhikr(
  'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
  'subḥānal-lāhi wa biḥamdih.',
  'Glory be to Allah, and praise be to Him.',
  100,
  'Reported by Muslim',
);

const Dhikr _tahlil10 = Dhikr(
  'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
  'lā ilāha illal-lāhu waḥdahū lā sharīka lah, lahul-mulku wa lahul-ḥamd, wa huwa ʿalā kulli shayʾin qadīr.',
  'There is no god but Allah alone, with no partner. His is the dominion and His is the praise, and He has power over all things.',
  10,
  'Reported by an-Nasāʾī; al-Bukhārī and Muslim report it 100 times a day',
);

AdhkarSet morningAdhkar() => AdhkarSet(
      'morning',
      'Morning adhkar',
      'After Fajr, until the sun is well up',
      [
        _ayatAlKursi,
        _surahDhikr(112, 'al-Ikhlāṣ', 'Reported by Abū Dāwūd and at-Tirmidhī'),
        _surahDhikr(113, 'al-Falaq', 'Reported by Abū Dāwūd and at-Tirmidhī'),
        _surahDhikr(114, 'an-Nās', 'Reported by Abū Dāwūd and at-Tirmidhī'),
        const Dhikr(
          'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَٰذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَٰذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
          'aṣbaḥnā wa aṣbaḥal-mulku lillāh, wal-ḥamdu lillāh, lā ilāha illal-lāhu waḥdahū lā sharīka lah, lahul-mulku wa lahul-ḥamdu wa huwa ʿalā kulli shayʾin qadīr. rabbi asʾaluka khayra mā fī hādhal-yawmi wa khayra mā baʿdah, wa aʿūdhu bika min sharri mā fī hādhal-yawmi wa sharri mā baʿdah. rabbi aʿūdhu bika minal-kasali wa sūʾil-kibar. rabbi aʿūdhu bika min ʿadhābin fin-nāri wa ʿadhābin fil-qabr.',
          'We have reached the morning, and all dominion belongs to Allah. Praise be to Allah. There is no god but Allah alone, with no partner; His is the dominion and His is the praise, and He has power over all things. My Lord, I ask You for the good of this day and what comes after it, and I seek refuge in You from the evil of this day and what comes after it. My Lord, I seek refuge in You from laziness and the hardships of old age. My Lord, I seek refuge in You from punishment in the Fire and in the grave.',
          1,
          'Reported by Muslim',
        ),
        const Dhikr(
          'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
          'allāhumma bika aṣbaḥnā, wa bika amsaynā, wa bika naḥyā, wa bika namūtu, wa ilaykan-nushūr.',
          'O Allah, by You we reach the morning and by You we reach the evening, by You we live and by You we die, and to You is the rising.',
          1,
          'Reported by at-Tirmidhī',
        ),
        _sayyidulIstighfar,
        _bismillahLaYadurr,
        _raditu,
        _afini,
        _yaHayy,
        _tahlil10,
        _subhanWaBihamdihi,
      ],
    );

AdhkarSet eveningAdhkar() => AdhkarSet(
      'evening',
      'Evening adhkar',
      'After ʿAṣr, until after Maghrib',
      [
        _ayatAlKursi,
        _surahDhikr(112, 'al-Ikhlāṣ', 'Reported by Abū Dāwūd and at-Tirmidhī'),
        _surahDhikr(113, 'al-Falaq', 'Reported by Abū Dāwūd and at-Tirmidhī'),
        _surahDhikr(114, 'an-Nās', 'Reported by Abū Dāwūd and at-Tirmidhī'),
        const Dhikr(
          'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَٰذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَٰذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
          'amsaynā wa amsal-mulku lillāh, wal-ḥamdu lillāh, lā ilāha illal-lāhu waḥdahū lā sharīka lah, lahul-mulku wa lahul-ḥamdu wa huwa ʿalā kulli shayʾin qadīr. rabbi asʾaluka khayra mā fī hādhihil-laylati wa khayra mā baʿdahā, wa aʿūdhu bika min sharri mā fī hādhihil-laylati wa sharri mā baʿdahā. rabbi aʿūdhu bika minal-kasali wa sūʾil-kibar. rabbi aʿūdhu bika min ʿadhābin fin-nāri wa ʿadhābin fil-qabr.',
          'We have reached the evening, and all dominion belongs to Allah. Praise be to Allah. There is no god but Allah alone, with no partner; His is the dominion and His is the praise, and He has power over all things. My Lord, I ask You for the good of this night and what comes after it, and I seek refuge in You from the evil of this night and what comes after it. My Lord, I seek refuge in You from laziness and the hardships of old age. My Lord, I seek refuge in You from punishment in the Fire and in the grave.',
          1,
          'Reported by Muslim',
        ),
        const Dhikr(
          'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ',
          'allāhumma bika amsaynā, wa bika aṣbaḥnā, wa bika naḥyā, wa bika namūtu, wa ilaykal-maṣīr.',
          'O Allah, by You we reach the evening and by You we reach the morning, by You we live and by You we die, and to You is the final return.',
          1,
          'Reported by at-Tirmidhī',
        ),
        _sayyidulIstighfar,
        _bismillahLaYadurr,
        _raditu,
        _afini,
        _yaHayy,
        const Dhikr(
          'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
          'aʿūdhu bikalimātil-lāhit-tāmmāti min sharri mā khalaq.',
          'I seek refuge in the perfect words of Allah from the evil of what He has created.',
          3,
          'Reported by Muslim and at-Tirmidhī',
        ),
        _subhanWaBihamdihi,
      ],
    );

AdhkarSet afterPrayerAdhkar({required bool takbir34}) => AdhkarSet(
      'after_prayer',
      'After prayer',
      'Straight after each obligatory prayer',
      [
        const Dhikr('أَسْتَغْفِرُ اللَّهَ', 'astaghfirul-lāh.',
            'I seek Allah’s forgiveness.', 3, 'Reported by Muslim'),
        const Dhikr(
          'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
          'allāhumma antas-salāmu wa minkas-salām, tabārakta yā dhal-jalāli wal-ikrām.',
          'O Allah, You are Peace and from You comes peace. Blessed are You, Possessor of majesty and honour.',
          1,
          'Reported by Muslim',
        ),
        _ayatAlKursi,
        const Dhikr('سُبْحَانَ اللَّهِ', 'subḥānal-lāh.', 'Glory be to Allah.',
            33, 'Reported by Muslim'),
        const Dhikr('الْحَمْدُ لِلَّهِ', 'al-ḥamdu lillāh.',
            'All praise belongs to Allah.', 33, 'Reported by Muslim'),
        Dhikr('اللَّهُ أَكْبَرُ', 'allāhu akbar.', 'Allah is the Greatest.',
            takbir34 ? 34 : 33, 'Reported by Muslim'),
        if (!takbir34)
          const Dhikr(
            'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
            'lā ilāha illal-lāhu waḥdahū lā sharīka lah, lahul-mulku wa lahul-ḥamd, wa huwa ʿalā kulli shayʾin qadīr.',
            'There is no god but Allah alone, with no partner. His is the dominion and His is the praise, and He has power over all things. (This completes one hundred.)',
            1,
            'Reported by Muslim',
          ),
      ],
    );

AdhkarSet adhkarById(String id, {required bool takbir34}) {
  switch (id) {
    case 'morning':
      return morningAdhkar();
    case 'evening':
      return eveningAdhkar();
    default:
      return afterPrayerAdhkar(takbir34: takbir34);
  }
}

class TasbihPreset {
  final String ar;
  final String tr;
  final String en;
  const TasbihPreset(this.ar, this.tr, this.en);
}

const List<TasbihPreset> kTasbihPresets = [
  TasbihPreset('سُبْحَانَ اللَّهِ', 'subḥānal-lāh', 'Glory be to Allah'),
  TasbihPreset('الْحَمْدُ لِلَّهِ', 'al-ḥamdu lillāh', 'All praise belongs to Allah'),
  TasbihPreset('اللَّهُ أَكْبَرُ', 'allāhu akbar', 'Allah is the Greatest'),
  TasbihPreset('لَا إِلَٰهَ إِلَّا اللَّهُ', 'lā ilāha illal-lāh', 'There is no god but Allah'),
  TasbihPreset('أَسْتَغْفِرُ اللَّهَ', 'astaghfirul-lāh', 'I seek Allah’s forgiveness'),
  TasbihPreset('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', 'subḥānal-lāhi wa biḥamdih',
      'Glory be to Allah and praise be to Him'),
  TasbihPreset('لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      'lā ḥawla wa lā quwwata illā billāh', 'There is no power or strength except through Allah'),
  TasbihPreset('اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ', 'allāhumma ṣalli ʿalā muḥammad',
      'O Allah, send blessings upon Muhammad'),
];
