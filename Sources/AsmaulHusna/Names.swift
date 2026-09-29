import Foundation

/// One entry of the 99 Beautiful Names.
/// `ar` = Arabic (with harakat), `tr` = transliteration in English letters,
/// `te` = transliteration in Telugu letters, `en`/`ta` = short meaning (EN/TE).
struct Husna: Identifiable, Hashable {
    let id: Int
    let ar: String
    let tr: String
    let te: String
    let en: String
    let ta: String

    init(_ id: Int, _ ar: String, _ tr: String, _ te: String, _ en: String, _ ta: String) {
        self.id = id; self.ar = ar; self.tr = tr; self.te = te; self.en = en; self.ta = ta
    }

    /// Vocative stem in Arabic (definite article removed) — used to build "يَا …".
    var vocAr: String {
        if id == 85 { return "ذَا الْجَلَالِ وَالْإِكْرَامِ" }
        guard ar.hasPrefix("اَل") else { return ar }
        var s = String(ar.dropFirst(3))
        if s.hasPrefix("ْ") { s = String(s.dropFirst(1)) }
        return s
    }

    /// Vocative stem in English letters ("Ar-Rahman" → "Rahman").
    var vocTr: String {
        if id == 85 { return "Dhul-Jalali wal-Ikram" }
        let parts = tr.split(separator: "-", maxSplits: 1).map(String.init)
        if parts.count == 2,
           ["Ar", "Al", "As", "An", "Ad", "Ash", "Az", "At"].contains(parts[0]) {
            return parts[1]
        }
        return tr
    }

    /// Vocative stem in Telugu letters ("అర్-రహ్మాన్" → "రహ్మాన్").
    var vocTe: String {
        if id == 85 { return te }
        let parts = te.split(separator: "-").map(String.init)
        return parts.count > 1 ? parts[parts.count - 1] : te
    }

    // MARK: Short dua built from the name ("Ya <Name>, forgive me and have mercy on me")

    var duaAr: String { "يَا \(vocAr) ٱغْفِرْ لِي وَٱرْحَمْنِي" }
    var duaTr: String { "Yā \(vocTr), ighfir lī wa-rḥamnī" }
    var duaTe: String { "యా \(vocTe), ఇగ్ఫిర్ లీ వర్హమ్నీ" }
    var duaEn: String { "O \(en.lowercasedFirst), forgive me and have mercy on me." }
    var duaTa: String { "\(ta), నాకు క్షమించి కరుణించు" }

    // MARK: Hadith / Qur'an attached to the name

    var hadith: Hadith { HadithBank.forName(id) }
}

struct Hadith: Hashable {
    let text: String      // Arabic
    let meaning: String   // English
    let source: String
}

enum HadithBank {
    /// Authentic narrations and Qur'anic verses, cycled through the list.
    /// Where no sound narration is specifically tied to a name, one of these
    /// well-known texts about the Beautiful Names is shown instead.
    static let pool: [Hadith] = [
        Hadith(text: "إِنَّ لِلَّهِ تِسْعَةً وَتِسْعِينَ اسْمًا، مِائَةٌ إِلَّا وَاحِدًا، مَنْ أَحْصَاهَا دَخَلَ الْجَنَّةَ",
               meaning: "Allah has ninety-nine names — one hundred minus one. Whoever enumerates them will enter Paradise.",
               source: "Sahih al-Bukhari 5007 · Sahih Muslim 2682"),
        Hadith(text: "وَلِلَّهِ الْأَسْمَاءُ الْحُسْنَىٰ فَادْعُوهُ بِهَا",
               meaning: "To Allah belong the best names, so call on Him thereby.",
               source: "Qur'an 7:180"),
        Hadith(text: "اللَّهُمَّ لَكَ الْحَمْدُ وَأَنْتَ حَمِيلُهُ، لَا مَانِعَ لِمَا أَعْطَيْتَ وَلَا مُعْطِيَ لِمَا مَنَعْتَ",
               meaning: "O Allah, to You belongs all praise, and You are its possessor. None can withhold what You give, and none can give what You withhold.",
               source: "Sahih al-Bukhari 844 · Sahih Muslim 3004"),
        Hadith(text: "اللَّهُ طَيِّبٌ لَا يَقْبَلُ إِلَّا طَيِّبًا",
               meaning: "Allah is Pure and accepts only what is pure.",
               source: "Sahih Muslim 1015"),
        Hadith(text: "إِنَّ اللَّهَ لَطِيفٌ يُحِبُّ اللَّطِيفَ فِي أَمْرِهِ كُلِّهِ",
               meaning: "Allah is Gentle and loves gentleness in all of His matters.",
               source: "Sunan Abi Dawud 5273 · Jami' at-Tirmidhi 2165"),
        Hadith(text: "وَاللَّهُ يَسْتَغْفِرُ لِمَنْ يَشَاءُ، وَاللَّهُ غَفُورٌ رَحِيمٌ",
               meaning: "And Allah forgives whom He wills, and Allah is Forgiving and Merciful.",
               source: "Qur'an 48:10"),
        Hadith(text: "ادْعُ اللَّهَ وَأَنْتَ مُوقِنٌ بِالِإِجَابَةِ",
               meaning: "Call upon Allah while certain of being answered.",
               source: "Jami' at-Tirmidhi 3244"),
        Hadith(text: "إِنَّ عِبَادِي لَيْسَ لَكَ عَلَيْهِمْ سُلْطَانٌ، إِلَّا مَنِ اتَّبَعَكَ مِنَ الْمُشْرِكِينَ",
               meaning: "You have no authority over My servants except those who follow you among the polytheists.",
               source: "Qur'an 15:42"),
        Hadith(text: "اللَّهُ فِي عَوْنِ الْعَبْدِ مَا كَانَ الْعَبْدُ فِي عَوْنِ أَخِيهِ",
               meaning: "Allah is in the help of a servant as long as the servant is in the help of his brother.",
               source: "Sahih Muslim 2699"),
        Hadith(text: "وَمَا خَلَقْتُ الْجِنَّ وَالْإِنْسَ إِلَّا لِيَعْبُدُونِ",
               meaning: "I did not create the jinn and mankind except to worship Me.",
               source: "Qur'an 51:56"),
        Hadith(text: "اللَّهُ عَجِيزٌ عَنْ كُلِّ شَيْءٍ غَيْرَ أَنَّهُ يَسْتَجِيبُ لِلْمُضْطَرِّ",
               meaning: "Allah is above every need of anything, yet He answers the one in distress.",
               source: "Sunan at-Tirmidhi 3391 (hasan)"),
        Hadith(text: "وَعِنْدَهُ مَفَاتِحُ الْغَيْبِ لَا يَعْلَمُهَا إِلَّا هُوَ",
               meaning: "And with Him are the keys of the unseen; none knows them except Him.",
               source: "Qur'an 6:59"),
        Hadith(text: "إِنَّ اللَّهَ كَتَبَ الْإِحْسَانَ عَلَى كُلِّ شَيْءٍ",
               meaning: "Allah has prescribed excellence (ihsan) in all things.",
               source: "Sahih Muslim 1955"),
        Hadith(text: "وَلَنَبْلُوَنَّكُمْ بِشَيْءٍ مِنَ الْخَوْفِ وَالْجُوعِ وَنَقْصٍ مِنَ الْأَمْوَالِ وَالْأَنْفُسِ وَالثَّمَرَاتِ، وَبَشِّرِ الصَّابِرِينَ",
               meaning: "We shall certainly test you with fear, hunger, loss of wealth, lives and fruits — but give glad tidings to the patient.",
               source: "Qur'an 2:155"),
        Hadith(text: "وَقُلِ اعْمَلُوا فَسَيَرَى اللَّهُ عَمَلَكُمْ وَرَسُولُهُ وَالْمُؤْمِنُونَ",
               meaning: "Say: act, for Allah will see your deeds, and so will His Messenger and the believers.",
               source: "Qur'an 9:105")
    ]

    /// Names with a directly related narration or verse.
    static let overrides: [Int: Hadith] = [
        1: pool[1], 2: pool[5],
        3: pool[2], 4: pool[3],
        14: pool[5], 17: pool[2],
        29: pool[12], 30: pool[4],
        34: pool[5], 35: pool[12],
        44: pool[6], 67: pool[0],
        68: pool[0], 80: pool[5],
        93: pool[1], 94: pool[1],
        99: pool[13]
    ]

    static func forName(_ id: Int) -> Hadith {
        if let h = overrides[id] { return h }
        return pool[id % pool.count]
    }
}

enum Names {
    static let all: [Husna] = [
        Husna(1, "اَلرَّحْمَٰنُ", "Ar-Rahman", "అర్-రహ్మాన్", "The Most Merciful", "అత్యంత కరుణగలవాడు"),
        Husna(2, "اَلرَّحِيمُ", "Ar-Raheem", "అర్-రహీమ్", "The Most Compassionate", "క్షమించే దయామయుడు"),
        Husna(3, "اَلْمَلِكُ", "Al-Malik", "అల్-మాలిక్", "The Sovereign King", "అధిపతి, రాజు"),
        Husna(4, "اَلْقُدُّوسُ", "Al-Quddus", "అల్-ఖుద్దూస్", "The Most Holy", "పరిశుద్ధుడు"),
        Husna(5, "اَلسَّلَامُ", "As-Salam", "అస్-సలామ్", "The Source of Peace", "శాంతి ప్రదాత"),
        Husna(6, "اَلْمُؤْمِنُ", "Al-Mu'min", "అల్-ముఅ్మిన్", "The Granter of Security", "భద్రత కల్పించేవాడు"),
        Husna(7, "اَلْمُهَيْمِنُ", "Al-Muhaymin", "అల్-ముహైమిన్", "The Guardian", "రక్షకుడు"),
        Husna(8, "اَلْعَزِيزُ", "Al-Aziz", "అల్-అజీజ్", "The Almighty", "సర్వశక్తిమంతుడు"),
        Husna(9, "اَلْجَبَّارُ", "Al-Jabbar", "అల్-జబ్బార్", "The Compeller", "బలవంతుని చేసేవాడు"),
        Husna(10, "اَلْمُتَكَبِّرُ", "Al-Mutakabbir", "అల్-ముతకబ్బిర్", "The Supreme in Pride", "గర్వకరమైనవాడు"),
        Husna(11, "اَلْخَالِقُ", "Al-Khaliq", "అల్-ఖాలిక్", "The Creator", "సృష్టికర్త"),
        Husna(12, "اَلْبَارِئُ", "Al-Bari'", "అల్-బారి", "The Maker from nothing", "నిర్మాత"),
        Husna(13, "اَلْمُصَوِّرُ", "Al-Musawwir", "అల్-ముస్వ్వీర్", "The Fashioner", "రూపశిల్పి"),
        Husna(14, "اَلْغَافِرُ", "Al-Ghaffar", "అల్-ఘాఫిర్", "The Great Forgiver", "గొప్ప క్షమాశీలుడు"),
        Husna(15, "اَلْقَهَّارُ", "Al-Qahhar", "అల్-ఖహ్హార్", "The All-Subduer", "అధీనపరిచేవాడు"),
        Husna(16, "اَلْوَهَّابُ", "Al-Wahhab", "అల్-వహ్హాబ్", "The Bestower", "ఉచితంగా ఇచ్చేవాడు"),
        Husna(17, "اَلرَّزَّاقُ", "Ar-Razzaq", "అర్-రజ్జాక్", "The Provider", "సంపద ప్రదాత"),
        Husna(18, "اَلْفَتَّاحُ", "Al-Fattah", "అల్-ఫత్తాహ్", "The Opener of victory", "విజయం ఇచ్చేవాడు"),
        Husna(19, "اَلْعَلِيمُ", "Al-Alim", "అల్-అలీమ్", "The All-Knowing", "సర్వజ్ఞుడు"),
        Husna(20, "اَلْقَابِضُ", "Al-Qabidh", "అల్-ఖాబిధ్", "The Withholder", "అటంకం కలిగించేవాడు"),
        Husna(21, "اَلْبَاسِطُ", "Al-Basit", "అల్-బాసిత్", "The Extender", "విస్తరింపజేసేవాడు"),
        Husna(22, "اَلْخَافِضُ", "Al-Khafidh", "అల్-ఖాఫిధ్", "The Abaser", "తగ్గించేవాడు"),
        Husna(23, "اَلرَّافِعُ", "Ar-Rafi", "అర్-రాఫి", "The Exalter", "ఉన్నతుని చేసేవాడు"),
        Husna(24, "اَلْمُعِزُّ", "Al-Mu'izz", "అల్-ముఇజ్", "The Honourer", "గౌరవించేవాడు"),
        Husna(25, "اَلْمُذِلُّ", "Al-Mudhill", "అల్-ముధిల్", "The Humiliator", "అవమానించేవాడు"),
        Husna(26, "اَلسَّمِيعُ", "As-Sami", "అస్-సమీ", "The All-Hearing", "సర్వశ్రోత"),
        Husna(27, "اَلْبَصِيرُ", "Al-Basir", "అల్-బసీర్", "The All-Seeing", "సర్వదర్శి"),
        Husna(28, "اَلْحَكَمُ", "Al-Hakam", "అల్-హకమ్", "The Judge", "న్యాయాధిపతి"),
        Husna(29, "اَلْعَدْلُ", "Al-Adl", "అల్-అద్ల్", "The Utterly Just", "న్యాయమైనవాడు"),
        Husna(30, "اَللَّطِيفُ", "Al-Latif", "అల్-లతీఫ్", "The Subtle and Kind", "సూక్ష్మజ్ఞుడు"),
        Husna(31, "اَلْخَبِيرُ", "Al-Khabir", "అల్-ఖబీర్", "The Fully Aware", "ఎరిగినవాడు"),
        Husna(32, "اَلْحَلِيمُ", "Al-Halim", "అల్-హలీమ్", "The Forbearing", "ఓర్వగలవాడు"),
        Husna(33, "اَلْعَظِيمُ", "Al-Azim", "అల్-అజీమ్", "The Magnificent", "మహానుభవుడు"),
        Husna(34, "اَلْغَفُورُ", "Al-Ghafur", "అల్-ఘఫూర్", "The Forgiving", "క్షమించేవాడు"),
        Husna(35, "اَلشَّكُورُ", "Ash-Shakur", "అష్-శకూర్", "The Appreciative", "కృతజ్ఞత గలవాడు"),
        Husna(36, "اَلْعَلِيُّ", "Al-Ali", "అల్-అలీ", "The Most High", "అత్యున్నతుడు"),
        Husna(37, "اَلْكَبِيرُ", "Al-Kabir", "అల్-కబీర్", "The Most Great", "అతి గొప్పవాడు"),
        Husna(38, "اَلْحَفِيظُ", "Al-Hafiz", "అల్-హఫీజ్", "The Preserver", "కాపాడేవాడు"),
        Husna(39, "اَلْمُقِيتُ", "Al-Muqit", "అల్-ముకీత్", "The Sustainer", "పోషించేవాడు"),
        Husna(40, "اَلْحَسِيبُ", "Al-Hasib", "అల్-హసీబ్", "The Reckoner", "లెక్కించేవాడు"),
        Husna(41, "اَلْجَلِيلُ", "Al-Jalil", "అల్-జలీల్", "The Majestic", "మహిమాన్వితుడు"),
        Husna(42, "اَلْكَرِيمُ", "Al-Karim", "అల్-కరీమ్", "The Most Generous", "ఉదారుడు"),
        Husna(43, "اَلرَّقِيبُ", "Ar-Raqib", "అర్-రఖీబ్", "The Watchful", "నిశితంగా చూసేవాడు"),
        Husna(44, "اَلْمُجِيبُ", "Al-Mujib", "అల్-ముజీబ్", "The Responsive", "ప్రార్థన వినేవాడు"),
        Husna(45, "اَلْوَاسِعُ", "Al-Wasi", "అల్-వాసి", "The All-Encompassing", "సర్వవ్యాపి"),
        Husna(46, "اَلْحَكِيمُ", "Al-Hakim", "అల్-హకీమ్", "The All-Wise", "ప్రజ్ఞావంతుడు"),
        Husna(47, "اَلْوَدُودُ", "Al-Wadud", "అల్-వదూద్", "The Loving", "ప్రేమించేవాడు"),
        Husna(48, "اَلْمَجِيدُ", "Al-Majid", "అల్-మజీద్", "The Glorious", "కీర్తి గలవాడు"),
        Husna(49, "اَلْبَاعِثُ", "Al-Ba'th", "అల్-బఅస్", "The Resurrector", "పునరుత్థానకర్త"),
        Husna(50, "اَلشَّهِيدُ", "Ash-Shahid", "అష్-షహీద్", "The Witness", "సాక్షి"),
        Husna(51, "اَلْحَقُّ", "Al-Haqq", "అల్-హక్క్", "The Absolute Truth", "సత్యస్వరూపి"),
        Husna(52, "اَلْوَكِيلُ", "Al-Wakil", "అల్-వకీల్", "The Trustee", "పరమాధికారి"),
        Husna(53, "اَلْقَوِيُّ", "Al-Qawiyy", "అల్-ఖవ్వీ", "The Strong", "బలవంతుడు"),
        Husna(54, "اَلْمَتِينُ", "Al-Matin", "అల్-మతీన్", "The Firm", "దృఢుడు"),
        Husna(55, "اَلْوَلِيُّ", "Al-Waliyy", "అల్-వలీ", "The Protecting Friend", "రక్షక మిత్రుడు"),
        Husna(56, "اَلْحَمِيدُ", "Al-Hamid", "అల్-హమీద్", "The Praiseworthy", "స్తుతనీయుడు"),
        Husna(57, "اَلْمُحْصِي", "Al-Muhsi", "అల్-ముహ్సీ", "The Enumerator of all", "సంఖ్యాజ్ఞుడు"),
        Husna(58, "اَلْمُبْدِئُ", "Al-Mubdi'", "అల్-ముబ్ది", "The Originator", "ఆరంభకర్త"),
        Husna(59, "اَلْمُعِيدُ", "Al-Mu'id", "అల్-ముఇద్", "The Restorer", "పునరుద్ధరించేవాడు"),
        Husna(60, "اَلْمُحْيِي", "Al-Muhyi", "అల్-ముహ్యీ", "The Giver of Life", "ప్రాణప్రదాత"),
        Husna(61, "اَلْمُمِيتُ", "Al-Mumit", "అల్-ముమీత్", "The Bringer of Death", "మరణకర్త"),
        Husna(62, "اَلْحَيُّ", "Al-Hayy", "అల్-హయ్", "The Ever-Living", "చిరంజీవి"),
        Husna(63, "اَلْقَيُّومُ", "Al-Qayyum", "అల్-ఖయ్యూమ్", "The Self-Subsisting", "ఆధారమైనవాడు"),
        Husna(64, "اَلْوَاجِدُ", "Al-Wajid", "అల్-వాజిద్", "The Perceiver", "లభించేవాడు"),
        Husna(65, "اَلْمَاجِدُ", "Al-Majid", "అల్-మాజిద్", "The Illustrious", "వైభవమైనవాడు"),
        Husna(66, "اَلْوَاحِدُ", "Al-Wahid", "అల్-వాహిద్", "The One", "ఏకైకుడు"),
        Husna(67, "اَلْأَحَدُ", "Al-Ahad", "అల్-అహద్", "The Unique", "అద్వితీయుడు"),
        Husna(68, "اَلصَّمَدُ", "As-Samad", "అస్-సమద్", "The Eternal Refuge", "శాశ్వత ఆశ్రయం"),
        Husna(69, "اَلْقَادِرُ", "Al-Qadir", "అల్-ఖాదిర్", "The Capable", "సమర్థుడు"),
        Husna(70, "اَلْمُقْتَدِرُ", "Al-Muqtadir", "అల్-ముఖ్తదిర్", "The Omnipotent", "సర్వశక్తిమంతుడు"),
        Husna(71, "اَلْمُقَدِّمُ", "Al-Muqaddim", "అల్-ముఖ్దిమ్", "The Expediter", "ముందుకు నడిపించేవాడు"),
        Husna(72, "اَلْمُؤَخِّرُ", "Al-Mu'akhkhir", "అల్-ముఅఖ్ఖిర్", "The Delayer", "వెనక్కు నెట్టేవాడు"),
        Husna(73, "اَلْأَوَّلُ", "Al-Awwal", "అల్-అవ్వల్", "The First", "మొదటివాడు"),
        Husna(74, "اَلْآخِرُ", "Al-Akhir", "అల్-అఖిర్", "The Last", "చివరివాడు"),
        Husna(75, "اَلظَّاهِرُ", "Az-Zahir", "అజ్-జాహిర్", "The Manifest", "ప్రకటితుడు"),
        Husna(76, "اَلْبَاطِنُ", "Al-Batin", "అల్-బాతిన్", "The Hidden", "అంతరంగజ్ఞుడు"),
        Husna(77, "اَلْوَالِي", "Al-Wali", "అల్-వాలీ", "The Governor", "పాలకుడు"),
        Husna(78, "اَلْمُتَعَالِي", "Al-Muta'ali", "అల్-ముతఅల్లీ", "The Self-Exalted", "స్వయం ఉన్నతుడు"),
        Husna(79, "اَلْبَرُّ", "Al-Barr", "అల్-బర్ర్", "The Source of Goodness", "దయామయుడు"),
        Husna(80, "اَلتَّوَّابُ", "At-Tawwab", "అత్-తవ్వాబ్", "Accepter of Repentance", "పశ్చాత్తాపం స్వీకరించేవాడు"),
        Husna(81, "اَلْمُنْتَقِمُ", "Al-Muntaqim", "అల్-ముంతఖిమ్", "The Avenger", "ప్రతిఫలం ఇచ్చేవాడు"),
        Husna(82, "اَلْعَفُوُّ", "Al-Afuww", "అల్-అఫువ్వ్", "The Pardoner", "పూర్తిగా క్షమించేవాడు"),
        Husna(83, "اَلرَّءُوفُ", "Ar-Ra'uf", "అర్-రఊఫ్", "The Most Kind", "అత్యంత దయగలవాడు"),
        Husna(84, "مَالِكُ الْمُلْكِ", "Malik-ul-Mulk", "మాలికుల్ ముల్క్", "Master of the Kingdom", "రాజ్యాధిపతి"),
        Husna(85, "ذُو الْجَلَالِ وَالْإِكْرَامِ", "Dhul-Jalali wal-Ikram", "జూల్ జలాలి వల్ ఇక్రామ్", "Lord of Majesty and Bounty", "మహిమా గౌరవాల ప్రభువు"),
        Husna(86, "اَلْمُقْسِطُ", "Al-Muqsit", "అల్-ముఖ్సిత్", "The Equitable", "సమదర్శి"),
        Husna(87, "اَلْجَامِعُ", "Al-Jami", "అల్-జామి", "The Gatherer", "సమీకరించేవాడు"),
        Husna(88, "اَلْغَنِيُّ", "Al-Ghani", "అల్-ఘనీ", "The Self-Sufficient", "స్వయం సంపన్నుడు"),
        Husna(89, "اَلْمُغْنِي", "Al-Mughni", "అల్-ముఘ్నీ", "The Enricher", "ఐశ్వర్యమిచ్చేవాడు"),
        Husna(90, "اَلْمَانِعُ", "Al-Mani", "అల్-మాని", "The Withholder of harm", "నిరోధించేవాడు"),
        Husna(91, "اَلضَّارُ", "Ad-Darr", "అద్-దార్", "The Distresser", "హాని కలిగించేవాడు"),
        Husna(92, "اَلنَّافِعُ", "An-Nafi", "అన్-నాఫి", "The Benefactor", "మేలు చేసేవాడు"),
        Husna(93, "اَلنُّورُ", "An-Nur", "అన్-నూర్", "The Light", "వెలుగు"),
        Husna(94, "اَلْهَادِي", "Al-Hadi", "అల్-హాదీ", "The Guide", "మార్గదర్శి"),
        Husna(95, "اَلْبَدِيعُ", "Al-Badi", "అల్-బాది", "The Incomparable Creator", "అనుపమ సృష్టికర్త"),
        Husna(96, "اَلْبَاقِي", "Al-Baqi", "అల్-బాకీ", "The Everlasting", "శాశ్వతుడు"),
        Husna(97, "اَلْوَارِثُ", "Al-Warith", "అల్-వారిస్", "The Inheritor", "వారసుడు"),
        Husna(98, "اَلرَّشِيدُ", "Ar-Rashid", "అర్-రషీద్", "Guide to the Right Path", "సన్మార్గదర్శి"),
        Husna(99, "اَلصَّبُورُ", "As-Sabur", "అస్-సబూర్", "The Patient", "ఓర్వగలవాడు")
    ]

    static func byId(_ id: Int) -> Husna {
        all[min(max(id, 1), 99) - 1]
    }
}

private extension String {
    var lowercasedFirst: String {
        guard let f = first else { return self }
        return f.lowercased() + dropFirst()
    }
}
