// Tajweed curriculum for the reading of Ḥafṣ ʿan ʿĀṣim.
// Examples are taken from the surahs included in the app.

class LessonExample {
  final String ar;
  final String tr; // may contain tajweed markup
  final String ref;
  final String note;
  const LessonExample(this.ar, this.tr, this.ref, this.note);
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int answer;
  final String explain;
  const QuizQuestion(this.question, this.options, this.answer, this.explain);
}

class Lesson {
  final String id;
  final String group;
  final String title;
  final String summary;
  final List<String> paragraphs;
  final String? letters;
  final List<LessonExample> examples;
  final List<QuizQuestion> quiz;
  const Lesson({
    required this.id,
    required this.group,
    required this.title,
    required this.summary,
    required this.paragraphs,
    this.letters,
    required this.examples,
    required this.quiz,
  });
}

const kLessonGroups = ['Foundations', 'Nūn sākinah and tanwīn', 'More rules'];

const List<Lesson> kLessons = [
  Lesson(
    id: 'harakat',
    group: 'Foundations',
    title: 'Short vowels and sukūn',
    summary: 'The marks that tell you which vowel to say.',
    paragraphs: [
      'Arabic is written with consonants. Small marks above or below a letter tell you which short vowel to say.',
      'Fatḥah, a short line above, gives an a sound: بَ ba. Kasrah, a short line below, gives an i sound: بِ bi. Ḍammah, a small wāw above, gives a u sound: بُ bu.',
      'Sukūn, a small circle above, means the letter has no vowel. You close on it, as in أَبْ, ab.',
      'Each short vowel lasts one count. Keep it short and crisp: stretching a short vowel can change the meaning of a word.',
    ],
    letters: 'بَ   بِ   بُ   بْ',
    examples: [
      LessonExample('قُلْ', 'qul', 'Al-Ikhlāṣ 112:1', 'Ḍammah on qāf, sukūn on lām.'),
      LessonExample('خَلَقَ', 'khalaqa', 'Al-ʿAlaq 96:2', 'Three fatḥahs: kha-la-qa.'),
      LessonExample('لَمْ يَلِدْ', 'lam yali{Q:d}', 'Al-Ikhlāṣ 112:3',
          'Fatḥah, kasrah and sukūn across two words.'),
    ],
    quiz: [
      QuizQuestion('Which mark gives an i sound?',
          ['Fatḥah', 'Kasrah', 'Ḍammah', 'Sukūn'], 1,
          'Kasrah is the short line below the letter.'),
      QuizQuestion('What does a sukūn tell you?', [
        'Stretch the letter',
        'The letter has no vowel',
        'Double the letter',
        'Add an n sound',
      ], 1, 'A sukūn means you close on the letter without a vowel.'),
      QuizQuestion('How long is a short vowel?',
          ['One count', 'Two counts', 'Four counts', 'Six counts'], 0,
          'Short vowels are one count. Long vowels are two or more.'),
    ],
  ),
  Lesson(
    id: 'long_vowels',
    group: 'Foundations',
    title: 'Long vowels (natural madd)',
    summary: 'ā, ī and ū, held for two counts.',
    paragraphs: [
      'A short vowel followed by its matching letter becomes long: fatḥah with alif gives ā, kasrah with yāʾ gives ī, and ḍammah with wāw gives ū.',
      'This natural lengthening, madd ṭabīʿī, lasts two counts: about twice as long as a short vowel.',
      'A small upright alif above a letter also gives ā, as in الرَّحْمَٰنِ, ar-raḥmān.',
      'In the transliteration, a line over a vowel (ā, ī, ū) marks it as long.',
    ],
    letters: 'بَا   بِي   بُو',
    examples: [
      LessonExample('مَالِكِ', 'māliki', 'Al-Fātiḥah 1:4', 'Fatḥah with alif gives ā.'),
      LessonExample('الرَّحِيمِ', 'ar-raḥīm', 'Al-Fātiḥah 1:3', 'Kasrah with yāʾ gives ī.'),
      LessonExample('الْقُبُورِ', 'al-qubūr', 'Al-ʿĀdiyāt 100:9', 'Ḍammah with wāw gives ū.'),
    ],
    quiz: [
      QuizQuestion('Which letter lengthens a kasrah?',
          ['Alif', 'Wāw', 'Yāʾ', 'Hamzah'], 2, 'Kasrah with yāʾ gives a long ī.'),
      QuizQuestion('How many counts is natural madd?', ['1', '2', '4', '6'], 1,
          'Natural madd is two counts.'),
      QuizQuestion('In māliki, which vowel is long?', [
        'The a after m',
        'The i after l',
        'The i after k',
        'None of them',
      ], 0, 'The alif after the mīm lengthens its fatḥah: mā-li-ki.'),
    ],
  ),
  Lesson(
    id: 'shaddah_tanwin',
    group: 'Foundations',
    title: 'Shaddah and tanwīn',
    summary: 'Doubled letters and the extra n at the end of a word.',
    paragraphs: [
      'A shaddah, a small w-shaped mark, doubles a letter. The first half closes one syllable and the second opens the next: رَبِّ is rab-bi, not ra-bi.',
      'Tanwīn is a doubled vowel mark at the end of a word. It adds an n sound: ـً an, ـٍ in, ـٌ un. So أَحَدٌ is aḥadun.',
      'When you stop on a word with tanwīn, the n is dropped. Tanwīn with fatḥah becomes a long ā (afwājā); the others become a sukūn (aḥad).',
      'What happens to the n of tanwīn when you carry on into the next word is covered in the nūn sākinah lessons.',
    ],
    letters: 'بٌّ   بً   بٍ   بٌ',
    examples: [
      LessonExample('رَبِّ', 'rabbi', 'Al-Fātiḥah 1:2', 'The shaddah doubles the bāʾ.'),
      LessonExample('أَحَدٌ', 'aḥa{Q:d}', 'Al-Ikhlāṣ 112:1',
          'Read aḥadun when continuing, aḥad when stopping.'),
      LessonExample('أَفْوَاجًا', 'afwājā', 'An-Naṣr 110:2',
          'Tanwīn with fatḥah becomes ā when you stop.'),
    ],
    quiz: [
      QuizQuestion('What does a shaddah do?', [
        'Lengthens a vowel',
        'Doubles the letter',
        'Makes the letter silent',
        'Adds an n',
      ], 1, 'A shaddah means the letter is said twice, closing one syllable and opening the next.'),
      QuizQuestion('How is أَحَدٌ read when you stop on it?',
          ['aḥadun', 'aḥadan', 'aḥad', 'aḥadā'], 2,
          'At a stop, tanwīn with ḍammah becomes a sukūn.'),
      QuizQuestion('At a stop, tanwīn with fatḥah becomes…',
          ['a long ā', 'an n', 'nothing', 'a short a'], 0,
          'This is sometimes called madd ʿiwaḍ, and lasts two counts.'),
    ],
  ),
  Lesson(
    id: 'sun_moon',
    group: 'Foundations',
    title: 'Sun and moon letters',
    summary: 'When the l of al- is said and when it disappears.',
    paragraphs: [
      'The word for "the", al-, behaves in two ways depending on the letter that follows it.',
      'Before a moon letter the lām is pronounced: al-falaq, al-ḥamd. The moon letters are ا ب ج ح خ ع غ ف ق ك م و ه ي.',
      'Before a sun letter the lām is silent and the next letter is doubled: ash-shams, an-nās, ar-raḥmān. The sun letters are ت ث د ذ ر ز س ش ص ض ط ظ ل ن.',
      'In the muṣḥaf, a sun letter after al- carries a shaddah and the lām has no mark. That is your visual cue.',
    ],
    examples: [
      LessonExample('الْفَلَقِ', 'al-falaq', 'Al-Falaq 113:1', 'Moon letter: the lām is pronounced.'),
      LessonExample('النَّاسِ', 'an-nās', 'An-Nās 114:1',
          'Sun letter: the lām is silent and the nūn is doubled.'),
      LessonExample('الرَّحِيمِ', 'ar-raḥīm', 'Al-Fātiḥah 1:3', 'Sun letter rāʾ.'),
    ],
    quiz: [
      QuizQuestion('Is ق a sun letter or a moon letter?', ['Sun', 'Moon'], 1,
          'Qāf is a moon letter, so the lām is pronounced: al-qamar.'),
      QuizQuestion('How is الشَّمْس read?',
          ['al-shams', 'ash-shams', 'a-shams', 'als-hams'], 1,
          'Shīn is a sun letter: the lām disappears and the shīn doubles.'),
      QuizQuestion('In the muṣḥaf, what shows a sun letter?', [
        'A sukūn on the lām',
        'A shaddah on the letter and no mark on the lām',
        'A madd sign',
        'A small circle on the alif',
      ], 1, 'No mark on the lām means it is silent; the shaddah shows the doubling.'),
    ],
  ),
  Lesson(
    id: 'izhar',
    group: 'Nūn sākinah and tanwīn',
    title: 'Iẓhār: saying the n clearly',
    summary: 'Before the six throat letters.',
    paragraphs: [
      'A nūn with sukūn (نْ) or a tanwīn is followed by some letter. Depending on that letter, one of four rules applies: iẓhār, idghām, iqlāb or ikhfāʾ. This lesson covers the first.',
      'Iẓhār means "making clear". Before the six throat letters ء ه ع ح غ خ, say the n clearly, without an extra hum.',
      'These letters are made far back in the throat, so the nasal sound has no chance to blend into them.',
      'In this app iẓhār is left uncoloured: a plain n is simply read as n.',
    ],
    letters: 'ء   ه   ع   ح   غ   خ',
    examples: [
      LessonExample('مِنْ عَلَقٍ', 'min ʿala{Q:q}', 'Al-ʿAlaq 96:2', 'Nūn before ʿayn.'),
      LessonExample('مَنْ خَفَّتْ', 'man khaffat', 'Al-Qāriʿah 101:8', 'Nūn before khāʾ.'),
      LessonExample('نَارٌ حَامِيَةٌ', 'nārun ḥāmiyah', 'Al-Qāriʿah 101:11', 'Tanwīn before ḥāʾ.'),
    ],
    quiz: [
      QuizQuestion('How many iẓhār letters are there?', ['4', '6', '15', '2'], 1,
          'The six throat letters: ء ه ع ح غ خ.'),
      QuizQuestion('In مِنْ عَلَقٍ the n is…',
          ['hidden', 'merged', 'said clearly', 'turned into m'], 2,
          'ʿAyn is a throat letter, so the n is clear.'),
      QuizQuestion('Which of these is a throat letter?', ['ب', 'ع', 'ت', 'ل'], 1,
          'ʿAyn is made in the middle of the throat.'),
    ],
  ),
  Lesson(
    id: 'idgham',
    group: 'Nūn sākinah and tanwīn',
    title: 'Idghām: merging',
    summary: 'Before ي ر م ل و ن, the n merges into the next letter.',
    paragraphs: [
      'Idghām means "merging". When a nūn sākinah or tanwīn is followed, at the start of the next word, by one of the six letters ي ر م ل و ن (remembered as yarmalūn), the n disappears into that letter.',
      'With ي ن م و the merge keeps a nasal hum of two counts. This is idghām with ghunnah, shown in purple: khayrun min is read khayrum-min.',
      'With ل and ر there is no hum at all. This is idghām without ghunnah, shown in grey: waylun li-kulli is read waylul-likulli.',
      'Idghām only happens across two words. Inside a single word, such as dunyā, the n stays clear.',
      'A mīm sākinah before another mīm also merges with a hum, as in ʿalayhim-muʾṣadah. Two letters made in the same place can merge too, as in ʿabadtum, read ʿabattum.',
    ],
    letters: 'ي   ر   م   ل   و   ن',
    examples: [
      LessonExample('خَيْرٌ مِّنْ', 'khayru{Dg:m-m}in', 'Al-Qadr 97:3', 'Tanwīn into mīm, with a hum.'),
      LessonExample('فَمَن يَعْمَلْ', 'fama{Dg:y-y}aʿmal', 'Az-Zalzalah 99:7', 'Nūn into yāʾ, with a hum.'),
      LessonExample('وَيْلٌ لِّكُلِّ', 'waylu{Dn:l-l}ikulli', 'Al-Humazah 104:1', 'Tanwīn into lām, no hum.'),
      LessonExample('أَن رَّآهُ', 'a{Dn:r-r}aʾāhu', 'Al-ʿAlaq 96:7', 'Nūn into rāʾ, no hum.'),
    ],
    quiz: [
      QuizQuestion('Which letters merge without a hum?',
          ['ي و', 'ل ر', 'م ن', 'ب ت'], 1, 'Lām and rāʾ take the n completely, with no ghunnah.'),
      QuizQuestion('How is خَيْرٌ مِّنْ read?',
          ['khayrun min', 'khayrum-min', 'khayrul-min', 'khayr min'], 1,
          'The tanwīn merges into the mīm with a two-count hum.'),
      QuizQuestion('Does idghām happen inside a single word?',
          ['Yes, always', 'No, only across two words'], 1,
          'Inside one word, as in dunyā, the n is said clearly.'),
    ],
  ),
  Lesson(
    id: 'iqlab',
    group: 'Nūn sākinah and tanwīn',
    title: 'Iqlāb: changing to m',
    summary: 'Before bāʾ, the n becomes a hidden m.',
    paragraphs: [
      'When a nūn sākinah or tanwīn meets bāʾ, the n changes into an m sound.',
      'Close the lips lightly, as for m, and hold a nasal hum for two counts before the b.',
      'In the muṣḥaf this is usually shown by a small mīm written above the nūn, or in place of the second tanwīn mark.',
      'It can happen inside one word (layunbadhanna) or across two words (min baʿdi).',
    ],
    letters: 'ب',
    examples: [
      LessonExample('مِن بَعْدِ', 'mi{B:m} baʿdi', 'Al-Bayyinah 98:4', 'Nūn before bāʾ, across two words.'),
      LessonExample('لَيُنبَذَنَّ', 'layu{B:m}badha{G:nn}a', 'Al-Humazah 104:4', 'Inside one word.'),
      LessonExample('لَنَسْفَعًا بِالنَّاصِيَةِ', 'lanasfaʿa{B:m} bi{G:n-n}āṣiyah', 'Al-ʿAlaq 96:15',
          'The n before bāʾ.'),
    ],
    quiz: [
      QuizQuestion('Iqlāb happens before which letter?', ['ب', 'م', 'ن', 'ل'], 0,
          'Only bāʾ causes iqlāb.'),
      QuizQuestion('The n changes into…', ['l', 'm', 'nothing', 'a clear n'], 1,
          'The lips close lightly for an m with a hum.'),
      QuizQuestion('How long is the hum?', ['None', '2 counts', '4 counts', '6 counts'], 1,
          'Like all ghunnah, it lasts two counts.'),
    ],
  ),
  Lesson(
    id: 'ikhfa',
    group: 'Nūn sākinah and tanwīn',
    title: 'Ikhfāʾ: hiding',
    summary: 'Before the remaining 15 letters, the n is hidden.',
    paragraphs: [
      'Before the remaining 15 letters, a nūn sākinah or tanwīn is "hidden": the tip of the tongue does not press for the n.',
      'Instead, the sound flows through the nose for two counts while the mouth gets ready for the next letter.',
      'The 15 letters are ت ث ج د ذ ز س ش ص ض ط ظ ف ق ك.',
      'The hum takes on the colour of the following letter: fuller before heavy letters like ص and ق, lighter before light letters like ت and س.',
    ],
    letters: 'ت ث ج د ذ ز س ش ص ض ط ظ ف ق ك',
    examples: [
      LessonExample('مِن شَرِّ', 'mi{I:n} sharri', 'Al-Falaq 113:2', 'Nūn before shīn.'),
      LessonExample('أَنزَلْنَاهُ', 'a{I:n}zalnāhu', 'Al-Qadr 97:1', 'Inside one word, before zāy.'),
      LessonExample('مِن كُلِّ أَمْرٍ', 'mi{I:n} kulli amr', 'Al-Qadr 97:4', 'Before kāf.'),
      LessonExample('نَارًا ذَاتَ', 'nāra{I:n} dhāta', 'Al-Masad 111:3', 'Tanwīn before dhāl.'),
    ],
    quiz: [
      QuizQuestion('How many ikhfāʾ letters are there?', ['6', '4', '15', '1'], 2,
          'Everything that is not an iẓhār, idghām or iqlāb letter.'),
      QuizQuestion('In ikhfāʾ, the tongue…', [
        'presses firmly for the n',
        'does not press for the n',
        'turns the n into m',
        'drops the n with no sound',
      ], 1, 'The n is hidden in the nose, not dropped.'),
      QuizQuestion('Which is an ikhfāʾ letter?', ['ع', 'ش', 'ل', 'ب'], 1,
          'Shīn is one of the fifteen.'),
    ],
  ),
  Lesson(
    id: 'meem',
    group: 'More rules',
    title: 'Mīm sākinah',
    summary: 'Three rules for a mīm with sukūn.',
    paragraphs: [
      'A mīm with sukūn (مْ) has three rules of its own.',
      'Ikhfāʾ shafawī: before bāʾ, close the lips lightly and hum for two counts, as in tarmīhim bi-ḥijārah.',
      'Idghām shafawī: before another mīm, merge the two with a hum, as in ʿalayhim-muʾṣadah.',
      'Iẓhār shafawī: before every other letter, say the m clearly and briefly. Take extra care before ف and و, which are also made with the lips: lam yalid wa lam yūlad.',
    ],
    letters: 'مْ',
    examples: [
      LessonExample('تَرْمِيهِم بِحِجَارَةٍ', 'tarmīhi{Is:m} biḥijārah', 'Al-Fīl 105:4', 'Ikhfāʾ shafawī.'),
      LessonExample('عَلَيْهِم مُّؤْصَدَةٌ', 'ʿalayhi{Dg:m-m}uʾṣadah', 'Al-Humazah 104:8', 'Idghām shafawī.'),
      LessonExample('أَلَمْ تَرَ', 'alam tara', 'Al-Fīl 105:1', 'Iẓhār shafawī: the m is said clearly.'),
    ],
    quiz: [
      QuizQuestion('A mīm sākinah before bāʾ is…',
          ['iẓhār', 'ikhfāʾ shafawī', 'idghām without hum', 'qalqalah'], 1,
          'The lips close lightly with a hum.'),
      QuizQuestion('Before another mīm, the two mīms…', [
        'merge with a hum',
        'are both said separately',
        'become n',
        'are silent',
      ], 0, 'This is idghām shafawī.'),
      QuizQuestion('Before fāʾ, the mīm is…',
          ['hidden', 'merged', 'said clearly', 'turned into f'], 2,
          'Iẓhār shafawī. Take care not to hide it.'),
    ],
  ),
  Lesson(
    id: 'ghunnah',
    group: 'More rules',
    title: 'Ghunnah on nūn and mīm with shaddah',
    summary: 'A two-count hum through the nose.',
    paragraphs: [
      'Ghunnah is a nasal hum made through the nose.',
      'Whenever a nūn or mīm carries a shaddah (نّ مّ), hold it with a ghunnah for two counts.',
      'You will meet it constantly: inna, thumma, an-nās, jahannam, ḥammālah.',
      'A quick check: pinch your nose while holding the sound. If the sound stops, you are making ghunnah.',
    ],
    letters: 'نّ   مّ',
    examples: [
      LessonExample('إِنَّ', 'i{G:nn}a', 'Al-ʿAṣr 103:2', 'Nūn with shaddah.'),
      LessonExample('ثُمَّ', 'thu{G:mm}a', 'At-Takāthur 102:4', 'Mīm with shaddah.'),
      LessonExample('مِنَ الْجِنَّةِ وَالنَّاسِ', 'minal-ji{G:nn}ati wa{G:n-n}{Ma:ā}s', 'An-Nās 114:6',
          'Two ghunnahs in one ayah.'),
    ],
    quiz: [
      QuizQuestion('Ghunnah comes from…',
          ['the throat', 'the lips', 'the nose', 'the tongue'], 2,
          'The sound passes through the nasal passage, al-khayshūm.'),
      QuizQuestion('How long is ghunnah on نّ?',
          ['1 count', '2 counts', '4 counts', '6 counts'], 1, 'Two counts.'),
      QuizQuestion('Which word has ghunnah?', ['قُلْ', 'ثُمَّ', 'أَحَدٌ', 'خَلَقَ'], 1,
          'The mīm in thumma carries a shaddah.'),
    ],
  ),
  Lesson(
    id: 'qalqalah',
    group: 'More rules',
    title: 'Qalqalah: the echo',
    summary: 'A small bounce on ق ط ب ج د.',
    paragraphs: [
      'Five letters, ق ط ب ج د, are remembered by the phrase quṭbu jad.',
      'When one of them has a sukūn, release it with a small bounce so it is not swallowed: iqraʾ, not ik-raʾ.',
      'Minor qalqalah happens in the middle of a word or phrase. Major qalqalah happens when you stop on the letter, and the bounce is clearer: al-falaq, aḥad.',
      'Do not add a vowel after the bounce. It should not sound like aḥadu or al-falaqa.',
    ],
    letters: 'ق   ط   ب   ج   د',
    examples: [
      LessonExample('اقْرَأْ', 'i{Q:q}raʾ', 'Al-ʿAlaq 96:1', 'Minor, in the middle of a word.'),
      LessonExample('قُلْ هُوَ اللَّهُ أَحَدٌ', 'qul huwal-lāhu aḥa{Q:d}', 'Al-Ikhlāṣ 112:1', 'Major, at a stop.'),
      LessonExample('الْفَلَقِ', 'al-fala{Q:q}', 'Al-Falaq 113:1', 'Major, at a stop.'),
      LessonExample('مَطْلَعِ الْفَجْرِ', 'ma{Q:ṭ}laʿil-fa{Q:j}r', 'Al-Qadr 97:5', 'Both kinds in one phrase.'),
    ],
    quiz: [
      QuizQuestion('Which is not a qalqalah letter?', ['ق', 'د', 'ك', 'ط'], 2,
          'Kāf is not one of quṭbu jad.'),
      QuizQuestion('Qalqalah happens when the letter has…',
          ['a fatḥah', 'a sukūn', 'a shaddah', 'tanwīn'], 1,
          'Only a still letter bounces.'),
      QuizQuestion('Where is qalqalah strongest?', [
        'At the start of a word',
        'When stopping on the letter',
        'Before a hamzah',
        'It is always the same',
      ], 1, 'Stopping gives the major qalqalah.'),
    ],
  ),
  Lesson(
    id: 'madd',
    group: 'More rules',
    title: 'The madd family',
    summary: 'When long vowels stretch beyond two counts.',
    paragraphs: [
      'Natural madd lasts two counts. Some long vowels are stretched further, depending on what comes after them.',
      'Madd muttaṣil (red): a long vowel followed by a hamzah in the same word, as in jāʾa and as-samāʾ. Four or five counts, and required.',
      'Madd munfaṣil (orange): a long vowel at the end of one word followed by a hamzah at the start of the next, as in innā anzalnāhu and wa mā adrāka. In the common reading of Ḥafṣ it is four or five counts. Whatever length you choose, keep it consistent.',
      'Madd ʿāriḍ lis-sukūn (gold): when you stop on a word, a long vowel just before the last letter may be two, four or six counts, as in al-ʿālamīn. The soft sounds ay and aw behave the same way at a stop (madd līn): quraysh, khawf.',
      'Madd lāzim (dark red): a long vowel followed by a permanent sukūn or shaddah in the same word. Always six counts, as in aḍ-ḍāllīn.',
      'Keep your counts steady and even, like the beat of a slow clock.',
    ],
    examples: [
      LessonExample('جَاءَ', 'j{Mw:ā}ʾa', 'An-Naṣr 110:1', 'Muttaṣil: long vowel and hamzah in one word.'),
      LessonExample('إِنَّا أَنزَلْنَاهُ', 'i{G:nn}{Mj:ā} a{I:n}zalnāhu', 'Al-Qadr 97:1',
          'Munfaṣil: the hamzah starts the next word.'),
      LessonExample('الْعَالَمِينَ', 'al-ʿālam{Ma:ī}n', 'Al-Fātiḥah 1:2', 'ʿĀriḍ lis-sukūn when stopping.'),
      LessonExample('وَلَا الضَّالِّينَ', 'wa laḍ-ḍ{Ml:ā}ll{Ma:ī}n', 'Al-Fātiḥah 1:7',
          'Lāzim (six counts), then ʿāriḍ at the stop.'),
    ],
    quiz: [
      QuizQuestion('A long vowel and a hamzah in the same word is…',
          ['munfaṣil', 'muttaṣil', 'lāzim', 'natural'], 1,
          'Muttaṣil means joined: both are in one word.'),
      QuizQuestion('How long is madd lāzim?', ['2', '4', '5', '6'], 3,
          'Always six counts.'),
      QuizQuestion('Stopping on نَسْتَعِينُ, the ī may be…', [
        'only 2 counts',
        '2, 4 or 6 counts',
        'silent',
        '1 count',
      ], 1, 'This is madd ʿāriḍ lis-sukūn.'),
    ],
  ),
  Lesson(
    id: 'heavy_light',
    group: 'More rules',
    title: 'Heavy and light letters',
    summary: 'Tafkhīm and tarqīq.',
    paragraphs: [
      'Seven letters are always heavy (tafkhīm): خ ص ض غ ط ق ظ, remembered as khuṣṣa ḍaghṭin qiẓ. Raise the back of the tongue and let the sound fill the mouth.',
      'Most other letters are light (tarqīq): keep the tongue low.',
      'Rāʾ is usually heavy with fatḥah or ḍammah (rabbi, ar-rūḥ) and light with kasrah (rijāl).',
      'The lām in the name Allah is heavy after fatḥah or ḍammah (qul huwal-lāhu, naṣrul-lāhi) and light after kasrah (bismil-lāhi).',
      'Alif follows the letter before it: heavy after a heavy letter (ṭā, qā), light after a light one (bā, mā).',
    ],
    letters: 'خ   ص   ض   غ   ط   ق   ظ',
    examples: [
      LessonExample('الصَّمَدُ', 'aṣ-ṣamad', 'Al-Ikhlāṣ 112:2', 'Heavy ṣād.'),
      LessonExample('هُوَ اللَّهُ', 'huwal-lāhu', 'Al-Ikhlāṣ 112:1', 'Heavy lām after ḍammah.'),
      LessonExample('بِسْمِ اللَّهِ', 'bismil-lāhi', 'Al-Fātiḥah 1:1', 'Light lām after kasrah.'),
    ],
    quiz: [
      QuizQuestion('Which letter is always heavy?', ['ق', 'ك', 'س', 'ت'], 0,
          'Qāf is one of khuṣṣa ḍaghṭin qiẓ.'),
      QuizQuestion('The lām of Allah in بِسْمِ اللَّهِ is…', ['heavy', 'light'], 1,
          'It comes after a kasrah, so it is light.'),
      QuizQuestion('Rāʾ with fatḥah is usually…', ['heavy', 'light'], 0,
          'Fatḥah and ḍammah make rāʾ heavy.'),
    ],
  ),
  Lesson(
    id: 'stopping',
    group: 'More rules',
    title: 'Stopping and pause marks',
    summary: 'What changes when you stop, and the small signs in the text.',
    paragraphs: [
      'You may stop at the end of any ayah. When you stop, the last vowel is dropped and the letter takes a sukūn.',
      'Tanwīn with fatḥah becomes a long ā (tawwābā). A tāʾ marbūṭah (ة) becomes h (al-qāriʿah).',
      'Small marks inside long ayat guide you. م means you must stop. لا means do not stop here. ج means stopping and continuing are both fine. صلى means continuing is better. قلى means stopping is better. Three dots placed twice mean stop at one of the two places, not both.',
      'In this app the transliteration of long ayat pauses at these marks, shown with a full stop.',
    ],
    examples: [
      LessonExample('الْقَارِعَةُ', 'al-qāriʿah', 'Al-Qāriʿah 101:1', 'Tāʾ marbūṭah becomes h.'),
      LessonExample('تَوَّابًا', 'tawwābā', 'An-Naṣr 110:3', 'Tanwīn with fatḥah becomes ā.'),
      LessonExample('لَمْ يَلِدْ وَلَمْ يُولَدْ', 'lam yali{Q:d} wa lam yūla{Q:d}', 'Al-Ikhlāṣ 112:3',
          'The final letter takes a sukūn.'),
    ],
    quiz: [
      QuizQuestion('Stopping on تَوَّابًا you say…',
          ['tawwāban', 'tawwābā', 'tawwāb', 'tawwābun'], 1,
          'Tanwīn with fatḥah becomes a long ā at a stop.'),
      QuizQuestion('ة at a stop becomes…', ['t', 'h', 'silent', 'n'], 1,
          'Tāʾ marbūṭah is read as h when you stop.'),
      QuizQuestion('The mark لا means…', [
        'you must stop',
        'do not stop here',
        'stopping is better',
        'stop anywhere',
      ], 1, 'Stopping there would break the meaning.'),
    ],
  ),
];

Lesson? lessonById(String id) {
  for (final l in kLessons) {
    if (l.id == id) return l;
  }
  return null;
}

// ------------------------------------------------------------ the alphabet

class ArabicLetter {
  final String letter;
  final String name;
  final String sound;
  final String hint;
  final int zone; // index into kMakharij
  const ArabicLetter(this.letter, this.name, this.sound, this.hint, this.zone);
}

const List<ArabicLetter> kAlphabet = [
  ArabicLetter('ا', 'alif', 'ā', 'Carries a long ā after fatḥah, or a hamzah at the start of a word.', 0),
  ArabicLetter('ب', 'bāʾ', 'b', 'As in "bed". Both lips.', 3),
  ArabicLetter('ت', 'tāʾ', 't', 'A light t, tongue tip behind the upper teeth.', 2),
  ArabicLetter('ث', 'thāʾ', 'th', 'As in "think". Tongue tip between the teeth.', 2),
  ArabicLetter('ج', 'jīm', 'j', 'As in "jam". Middle of the tongue.', 2),
  ArabicLetter('ح', 'ḥāʾ', 'ḥ', 'A breathy h from the middle of the throat, like fogging a mirror.', 1),
  ArabicLetter('خ', 'khāʾ', 'kh', 'As in Scottish "loch". Top of the throat. Always heavy.', 1),
  ArabicLetter('د', 'dāl', 'd', 'A light d, tongue tip behind the upper teeth.', 2),
  ArabicLetter('ذ', 'dhāl', 'dh', 'As in "this". Tongue tip between the teeth.', 2),
  ArabicLetter('ر', 'rāʾ', 'r', 'A tapped r with the tongue tip. Heavy or light depending on its vowel.', 2),
  ArabicLetter('ز', 'zāy', 'z', 'As in "zoo".', 2),
  ArabicLetter('س', 'sīn', 's', 'As in "sun". A light s.', 2),
  ArabicLetter('ش', 'shīn', 'sh', 'As in "ship". Middle of the tongue.', 2),
  ArabicLetter('ص', 'ṣād', 'ṣ', 'A heavy s, with the back of the tongue raised.', 2),
  ArabicLetter('ض', 'ḍād', 'ḍ', 'A heavy d made with the side of the tongue against the upper molars.', 2),
  ArabicLetter('ط', 'ṭāʾ', 'ṭ', 'A heavy t, with the back of the tongue raised.', 2),
  ArabicLetter('ظ', 'ẓāʾ', 'ẓ', 'A heavy dh, tongue tip between the teeth.', 2),
  ArabicLetter('ع', 'ʿayn', 'ʿ', 'A squeezed sound from the middle of the throat. No English equivalent.', 1),
  ArabicLetter('غ', 'ghayn', 'gh', 'Like a French r, from the top of the throat. Always heavy.', 1),
  ArabicLetter('ف', 'fāʾ', 'f', 'Upper teeth on the inside of the lower lip.', 3),
  ArabicLetter('ق', 'qāf', 'q', 'A deep k from the very back of the tongue. Always heavy.', 2),
  ArabicLetter('ك', 'kāf', 'k', 'As in "kite", a little further forward than qāf.', 2),
  ArabicLetter('ل', 'lām', 'l', 'A light l, except in the name Allah after fatḥah or ḍammah.', 2),
  ArabicLetter('م', 'mīm', 'm', 'Both lips, with a nasal quality.', 3),
  ArabicLetter('ن', 'nūn', 'n', 'Tongue tip with a nasal quality.', 2),
  ArabicLetter('ه', 'hāʾ', 'h', 'A light h from the deepest part of the throat.', 1),
  ArabicLetter('و', 'wāw', 'w / ū', 'As in "wet". Also carries a long ū after ḍammah.', 3),
  ArabicLetter('ي', 'yāʾ', 'y / ī', 'As in "yes". Also carries a long ī after kasrah.', 2),
];

class MakhrajZone {
  final String name;
  final String arabic;
  final String where;
  final String letters;
  final List<String> details;
  const MakhrajZone(this.name, this.arabic, this.where, this.letters, this.details);
}

const List<MakhrajZone> kMakharij = [
  MakhrajZone('Al-Jawf', 'الجوف', 'The open space of the mouth and throat', 'ا و ي', [
    'The long vowels ā, ī and ū have no fixed contact point. The sound flows through the open mouth and ends when the breath ends.',
  ]),
  MakhrajZone('Al-Ḥalq', 'الحلق', 'The throat', 'ء ه ع ح غ خ', [
    'Deepest part: ء hamzah and ه hāʾ.',
    'Middle: ع ʿayn and ح ḥāʾ.',
    'Nearest the mouth: غ ghayn and خ khāʾ.',
  ]),
  MakhrajZone('Al-Lisān', 'اللسان', 'The tongue', 'ق ك ج ش ي ض ل ن ر ط د ت ص س ز ظ ذ ث', [
    'Back of the tongue: ق qāf (furthest back) and ك kāf.',
    'Middle of the tongue: ج jīm, ش shīn, ي yāʾ.',
    'Side of the tongue against the upper molars: ض ḍād.',
    'Front edges and tip: ل lām, ن nūn, ر rāʾ.',
    'Tip against the gum behind the upper teeth: ط ṭāʾ, د dāl, ت tāʾ.',
    'Tip near the lower teeth, with a whistling sound: ص ṣād, س sīn, ز zāy.',
    'Tip between the teeth: ظ ẓāʾ, ذ dhāl, ث thāʾ.',
  ]),
  MakhrajZone('Ash-Shafatān', 'الشفتان', 'The lips', 'ف ب م و', [
    'Upper teeth on the inner lower lip: ف fāʾ.',
    'Both lips together: ب bāʾ and م mīm.',
    'Lips rounded without closing: و wāw.',
  ]),
  MakhrajZone('Al-Khayshūm', 'الخيشوم', 'The nasal passage', 'نّ مّ', [
    'The home of ghunnah: the hum of nūn and mīm, strongest when they carry a shaddah or are hidden.',
  ]),
];
