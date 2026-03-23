import '../medical_center.dart';

const List<MedicalCenter> hospitals = [
  // ── Delhi ─────────────────────────────────────────────────────────────────
  MedicalCenter(
    name: 'All India Institute of Medical Sciences (AIIMS)',
    phoneNumbers: ['011-26588500'],
    location: 'New Delhi',
    latitude: 28.568900,
    longitude: 77.209900,
  ),
  MedicalCenter(
    name: 'Safdarjung Hospital',
    phoneNumbers: ['011-26730000'],
    location: 'New Delhi',
    latitude: 28.570500,
    longitude: 77.200600,
  ),
  MedicalCenter(
    name: 'Ram Manohar Lohia Hospital',
    phoneNumbers: ['011-23404000'],
    location: 'New Delhi',
    latitude: 28.624600,
    longitude: 77.208300,
  ),
  MedicalCenter(
    name: 'Apollo Hospital',
    phoneNumbers: ['011-26925858'],
    location: 'Sarita Vihar, New Delhi',
    latitude: 28.530600,
    longitude: 77.291100,
  ),
  MedicalCenter(
    name: 'Fortis Hospital',
    phoneNumbers: ['011-42776222'],
    location: 'Vasant Kunj, New Delhi',
    latitude: 28.521400,
    longitude: 77.158600,
  ),

  // ── Mumbai ────────────────────────────────────────────────────────────────
  MedicalCenter(
    name: 'KEM Hospital',
    phoneNumbers: ['022-24107000'],
    location: 'Parel, Mumbai',
    latitude: 19.000500,
    longitude: 72.841200,
  ),
  MedicalCenter(
    name: 'Lilavati Hospital',
    phoneNumbers: ['022-26751000'],
    location: 'Bandra, Mumbai',
    latitude: 19.050500,
    longitude: 72.826900,
  ),
  MedicalCenter(
    name: 'Tata Memorial Hospital',
    phoneNumbers: ['022-24177000'],
    location: 'Parel, Mumbai',
    latitude: 19.000300,
    longitude: 72.842300,
  ),
  MedicalCenter(
    name: 'Hinduja Hospital',
    phoneNumbers: ['022-24452222'],
    location: 'Mahim, Mumbai',
    latitude: 19.038900,
    longitude: 72.839200,
  ),
  MedicalCenter(
    name: 'Breach Candy Hospital',
    phoneNumbers: ['022-23667888'],
    location: 'Breach Candy, Mumbai',
    latitude: 18.971500,
    longitude: 72.806400,
  ),

  // ── Bangalore ─────────────────────────────────────────────────────────────
  MedicalCenter(
    name: 'Manipal Hospital',
    phoneNumbers: ['080-25024444'],
    location: 'HAL Airport Road, Bangalore',
    latitude: 12.959100,
    longitude: 77.648400,
  ),
  MedicalCenter(
    name: 'Narayana Health City',
    phoneNumbers: ['080-71222222'],
    location: 'Bommasandra, Bangalore',
    latitude: 12.836700,
    longitude: 77.676200,
  ),
  MedicalCenter(
    name: 'Fortis Hospital Bangalore',
    phoneNumbers: ['080-66214444'],
    location: 'Bannerghatta Road, Bangalore',
    latitude: 12.888400,
    longitude: 77.597800,
  ),
  MedicalCenter(
    name: 'Victoria Hospital',
    phoneNumbers: ['080-26706000'],
    location: 'Chamrajpet, Bangalore',
    latitude: 12.963700,
    longitude: 77.571000,
  ),

  // ── Chennai ───────────────────────────────────────────────────────────────
  MedicalCenter(
    name: 'Apollo Hospital Chennai',
    phoneNumbers: ['044-28290200'],
    location: 'Greams Road, Chennai',
    latitude: 13.058200,
    longitude: 80.254600,
  ),
  MedicalCenter(
    name: 'Government General Hospital',
    phoneNumbers: ['044-25305000'],
    location: 'Park Town, Chennai',
    latitude: 13.082700,
    longitude: 80.274500,
  ),
  MedicalCenter(
    name: 'MIOT International',
    phoneNumbers: ['044-42002288'],
    location: 'Manapakkam, Chennai',
    latitude: 13.010200,
    longitude: 80.175500,
  ),

  // ── Hyderabad ─────────────────────────────────────────────────────────────
  MedicalCenter(
    name: 'Nizam\'s Institute of Medical Sciences',
    phoneNumbers: ['040-23489000'],
    location: 'Punjagutta, Hyderabad',
    latitude: 17.425600,
    longitude: 78.448200,
  ),
  MedicalCenter(
    name: 'Apollo Hospital Hyderabad',
    phoneNumbers: ['040-23607777'],
    location: 'Jubilee Hills, Hyderabad',
    latitude: 17.430500,
    longitude: 78.408200,
  ),
  MedicalCenter(
    name: 'Yashoda Hospital',
    phoneNumbers: ['040-45674567'],
    location: 'Secunderabad, Hyderabad',
    latitude: 17.448200,
    longitude: 78.498700,
  ),

  // ── Kolkata ───────────────────────────────────────────────────────────────
  MedicalCenter(
    name: 'SSKM Hospital',
    phoneNumbers: ['033-22044444'],
    location: 'AJC Bose Road, Kolkata',
    latitude: 22.536600,
    longitude: 88.344400,
  ),
  MedicalCenter(
    name: 'Apollo Gleneagles Hospital',
    phoneNumbers: ['033-23201400'],
    location: 'Canal Circular Road, Kolkata',
    latitude: 22.580700,
    longitude: 88.399400,
  ),
  MedicalCenter(
    name: 'Fortis Hospital Kolkata',
    phoneNumbers: ['033-66284444'],
    location: 'Anandapur, Kolkata',
    latitude: 22.517300,
    longitude: 88.397700,
  ),

  // ── Ahmedabad ─────────────────────────────────────────────────────────────
  MedicalCenter(
    name: 'Civil Hospital Ahmedabad',
    phoneNumbers: ['079-22681111'],
    location: 'Asarwa, Ahmedabad',
    latitude: 23.054400,
    longitude: 72.604600,
  ),
  MedicalCenter(
    name: 'Sterling Hospital',
    phoneNumbers: ['079-40011000'],
    location: 'Gurukul Road, Ahmedabad',
    latitude: 23.047200,
    longitude: 72.530500,
  ),
  MedicalCenter(
    name: 'Apollo Hospital Ahmedabad',
    phoneNumbers: ['079-66701800'],
    location: 'Bhat, Ahmedabad',
    latitude: 23.107100,
    longitude: 72.628800,
  ),

  // ── Pune ──────────────────────────────────────────────────────────────────
  MedicalCenter(
    name: 'Sassoon General Hospital',
    phoneNumbers: ['020-26128000'],
    location: 'Pune Station, Pune',
    latitude: 18.518700,
    longitude: 73.869700,
  ),
  MedicalCenter(
    name: 'Ruby Hall Clinic',
    phoneNumbers: ['020-26163391'],
    location: 'Wanowrie, Pune',
    latitude: 18.495900,
    longitude: 73.899500,
  ),
  MedicalCenter(
    name: 'KEM Hospital Pune',
    phoneNumbers: ['020-26120255'],
    location: 'Rasta Peth, Pune',
    latitude: 18.519800,
    longitude: 73.874200,
  ),
];