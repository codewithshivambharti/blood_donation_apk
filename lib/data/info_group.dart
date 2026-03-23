class InfoGroup {
  final int id;
  final String title;
  final List<String> info;

  const InfoGroup({
    required this.id,
    required this.title,
    required this.info,
  });

  static const List<InfoGroup> whoCanDonate = [
    InfoGroup(
      id: 0,
      title: 'Blood Donors:',
      info: _conditions,
    ),
    InfoGroup(
      id: 1,
      title: 'You should not donate blood if:',
      info: _doNotDonateIf,
    ),
    InfoGroup(
      id: 2,
      title: 'Wait 6 months before donation if:',
      info: _wait6MonthsIf,
    ),
    InfoGroup(
      id: 3,
      title: 'Wait 12 months before donation:',
      info: _wait12MonthsIf,
    ),
  ];
}

const List<String> _conditions = [
  'Must be in good general health',
  'Must be at least 18 years old and no more than 65. After the age of 60, donors require the approval of a transfusion medicine physician',
  'Must weigh at least 50 kg',
  'Must not be at risk of transmitting blood-borne diseases',
  'Must have a hemoglobin or hematocrit level of: 13.5–18 g/dl (0.40%) for a man, or 12.5–16 g/dl (0.38%) for a woman',
  'Must have a systolic blood pressure of 100–140 mmHg and a diastolic blood pressure of 60–90 mmHg',
  'Must have a pulse rate of 60–100 bpm (beats per minute)',
  'Must have a temperature below 37.6°C',
  'Must have a platelet count above 150×10⁹/L',
];

const List<String> _doNotDonateIf = [
  'You have ever taken drugs',
  'Your partner takes drugs',
  'You are HIV positive',
  'You are a male who has had sexual contact with another male',
  'Your partner is HIV positive',
  'You have more than one sexual partner',
  'You think your partner engages in risky sexual behaviour',
];

const List<String> _wait6MonthsIf = [
  'You have had casual partners',
  'You have changed sexual partners',
];

const List<String> _wait12MonthsIf = [
  'After a tattoo or ear/body piercing',
  'After a scarification (except if therapeutic)',
  'After acupuncture treatment unless strictly personal-use or single-use needles were used',
  'If you have been cut with a potentially contaminated object (e.g. a shared razor blade)',
  'If you have had prolonged contact with damaged skin contaminated with secretions or blood',
  'If you have been injured with a dirty needle',
  'In the case of a human bite',
  'After surgery or endoscopic evaluation',
];