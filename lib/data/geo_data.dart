class CountryInfo {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const CountryInfo({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

const List<CountryInfo> countryList = [
  CountryInfo(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
  CountryInfo(name: 'Nepal', code: 'NP', dialCode: '+977', flag: '🇳🇵'),
  CountryInfo(name: 'Bhutan', code: 'BT', dialCode: '+975', flag: '🇧🇹'),
  CountryInfo(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
  CountryInfo(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
  CountryInfo(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
  CountryInfo(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
  CountryInfo(name: 'United Arab Emirates', code: 'AE', dialCode: '+971', flag: '🇦🇪'),
  CountryInfo(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬'),
  CountryInfo(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
  CountryInfo(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
  CountryInfo(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
  CountryInfo(name: 'New Zealand', code: 'NZ', dialCode: '+64', flag: '🇳🇿'),
  CountryInfo(name: 'Switzerland', code: 'CH', dialCode: '+41', flag: '🇨🇭'),
  CountryInfo(name: 'Italy', code: 'IT', dialCode: '+39', flag: '🇮🇹'),
  CountryInfo(name: 'Spain', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
  CountryInfo(name: 'Netherlands', code: 'NL', dialCode: '+31', flag: '🇳🇱'),
  CountryInfo(name: 'Norway', code: 'NO', dialCode: '+47', flag: '🇳🇴'),
  CountryInfo(name: 'Sweden', code: 'SE', dialCode: '+46', flag: '🇸🇪'),
  CountryInfo(name: 'Denmark', code: 'DK', dialCode: '+45', flag: '🇩🇰'),
  CountryInfo(name: 'Thailand', code: 'TH', dialCode: '+66', flag: '🇹🇭'),
  CountryInfo(name: 'Indonesia', code: 'ID', dialCode: '+62', flag: '🇮🇩'),
  CountryInfo(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '🇲🇾'),
  CountryInfo(name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
  CountryInfo(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
  CountryInfo(name: 'Israel', code: 'IL', dialCode: '+972', flag: '🇮🇱'),
  CountryInfo(name: 'Saudi Arabia', code: 'SA', dialCode: '+966', flag: '🇸🇦'),
  CountryInfo(name: 'Qatar', code: 'QA', dialCode: '+974', flag: '🇶🇦'),
];

const List<String> indianStatesAndUTs = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
  'Andaman and Nicobar Islands',
  'Chandigarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi (NCT)',
  'Jammu and Kashmir',
  'Ladakh',
  'Lakshadweep',
  'Puducherry',
];

const List<String> nepalRegions = [
  'Bagmati (Kathmandu / Lalitpur)',
  'Gandaki (Pokhara / Annapurna)',
  'Karnali',
  'Koshi (Everest / Lukla)',
  'Lumbini',
  'Madhesh',
  'Sudurpashchim',
];

const List<String> bhutanRegions = [
  'Thimphu',
  'Paro',
  'Punakha',
  'Wangdue Phodrang',
  'Chhukha (Phuentsholing)',
  'Bumthang',
  'Trongsa',
  'Haa',
];

const Map<String, List<String>> stateCitiesMap = {
  // Himalayan neighbors
  'Nepal': ['Kathmandu', 'Pokhara', 'Lalitpur', 'Bharatpur', 'Lukla', 'Namche Bazaar', 'Chitwan', 'Nagarkot', 'Bandipur'],
  'Bhutan': ['Thimphu', 'Paro', 'Punakha', 'Phuentsholing', 'Jakhar', 'Wangdue Phodrang', 'Haa'],
  'Tibet': ['Lhasa', 'Shigatse', 'Gyantse', 'Chamdo', 'Nyingchi', 'Tingri'],

  // Indian States & UTs
  'Uttarakhand': ['Dehradun', 'Haridwar', 'Rishikesh', 'Nainital', 'Mussoorie', 'Haldwani', 'Roorkee', 'Almora', 'Kedarnath', 'Badrinath', 'Joshimath', 'Sankri', 'Auli', 'Chopta', 'Uttarkashi', 'Pithoragarh', 'Ranikhet'],
  'Himachal Pradesh': ['Shimla', 'Manali', 'Dharamshala', 'Kullu', 'Mandi', 'Solan', 'Chamba', 'Dalhousie', 'Spiti (Kaza)', 'Kasol', 'Jibhi', 'Bir Billing', 'Kalpa', 'Sangla', 'McLeod Ganj'],
  'Ladakh': ['Leh', 'Kargil', 'Nubra Valley (Diskit)', 'Zanskar (Padum)', 'Pangong Tso', 'Tso Moriri', 'Hemis', 'Alchi', 'Turtuk'],
  'Jammu and Kashmir': ['Srinagar', 'Jammu', 'Anantnag', 'Baramulla', 'Gulmarg', 'Pahalgam', 'Sonamarg', 'Katras', 'Doda'],
  'Jammu & Kashmir': ['Srinagar', 'Jammu', 'Anantnag', 'Baramulla', 'Gulmarg', 'Pahalgam', 'Sonamarg', 'Katras', 'Doda'],
  'Sikkim': ['Gangtok', 'Namchi', 'Geyzing', 'Mangan', 'Pelling', 'Lachung', 'Lachen', 'Ravangla', 'Yuksom'],
  'Arunachal Pradesh': ['Itanagar', 'Naharlagun', 'Pasighat', 'Tawang', 'Ziro', 'Bomdila', 'Tezu', 'Changlang', 'Dirang', 'Mechuka', 'Along'],
  'Assam': ['Guwahati', 'Silchar', 'Dibrugarh', 'Jorhat', 'Nagaon', 'Tinsukia', 'Tezpur', 'Bongaigaon', 'Kaziranga', 'Majuli'],
  'Meghalaya': ['Shillong', 'Tura', 'Jowai', 'Nongpoh', 'Cherrapunji (Sohra)', 'Dawki', 'Mawlynnong', 'Nongriat'],
  'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung', 'Tuensang', 'Wokha', 'Mon', 'Khonoma', 'Dzukou'],
  'Manipur': ['Imphal', 'Churachandpur', 'Thoubal', 'Bishnupur', 'Ukhrul', 'Loktak'],
  'Mizoram': ['Aizawl', 'Lunglei', 'Saiha', 'Champhai', 'Reiek'],
  'Tripura': ['Agartala', 'Udaipur', 'Dharmanagar', 'Kailashahar', 'Unakoti'],
  'West Bengal': ['Kolkata', 'Howrah', 'Darjeeling', 'Siliguri', 'Asansol', 'Durgapur', 'Kalimpong', 'Mirik', 'Kurseong', 'Sundarbans'],
  'Kerala': ['Kochi', 'Thiruvananthapuram', 'Kozhikode', 'Munnar', 'Wayanad', 'Alappuzha (Alleppey)', 'Varkala', 'Kumarakom', 'Thekkady', 'Thrissur', 'Kollam'],
  'Karnataka': ['Bengaluru', 'Mysuru', 'Coorg (Madikeri)', 'Chikkamagaluru', 'Hampi', 'Gokarna', 'Mangaluru', 'Hubballi', 'Udupi'],
  'Goa': ['Panaji', 'Margao', 'Vasco da Gama', 'Mapusa', 'Ponda', 'Calangute', 'Palolem', 'Arambol'],
  'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Lonavala', 'Mahabaleshwar', 'Alibaug', 'Kolhapur', 'Chhatrapati Sambhajinagar'],
  'Rajasthan': ['Jaipur', 'Udaipur', 'Jodhpur', 'Jaisalmer', 'Pushkar', 'Mount Abu', 'Bikaner', 'Ajmer', 'Ranthambore', 'Chittorgarh'],
  'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Rann of Kutch (Bhuj)', 'Gir National Park', 'Dwarka', 'Somnath'],
  'Tamil Nadu': ['Chennai', 'Ooty', 'Kodaikanal', 'Madurai', 'Coimbatore', 'Rameshwaram', 'Kanyakumari', 'Tiruchirappalli', 'Yercaud'],
  'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Tirupati', 'Araku Valley', 'Guntur', 'Kurnool', 'Rajahmundry'],
  'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar'],
  'Uttar Pradesh': ['Varanasi', 'Agra', 'Lucknow', 'Prayagraj', 'Ayodhya', 'Mathura', 'Noida', 'Vrindavan'],
  'Bihar': ['Patna', 'Gaya', 'Bodh Gaya', 'Bhagalpur', 'Muzaffarpur', 'Nalanda', 'Rajgir'],
  'Madhya Pradesh': ['Bhopal', 'Indore', 'Gwalior', 'Khajuraho', 'Ujjain', 'Jabalpur', 'Kanha', 'Bandhavgarh', 'Pachmarhi'],
  'Punjab': ['Amritsar', 'Ludhiana', 'Jalandhar', 'Patiala', 'Bathinda'],
  'Haryana': ['Gurugram', 'Faridabad', 'Panchkula', 'Ambala', 'Kurukshetra'],
  'Chhattisgarh': ['Raipur', 'Bhilai', 'Bilaspur', 'Bastar (Jagdalpur)', 'Chitrakote'],
  'Jharkhand': ['Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Netarhat'],
  'Odisha': ['Bhubaneswar', 'Puri', 'Cuttack', 'Konark', 'Chilika'],
  'Andaman and Nicobar Islands': ['Port Blair', 'Havelock Island (Swaraj Dweep)', 'Neil Island (Shaheed Dweep)', 'Diglipur'],
  'Chandigarh': ['Chandigarh'],
  'Delhi (NCT)': ['New Delhi', 'Old Delhi', 'South Delhi', 'Central Delhi'],
  'Puducherry': ['Puducherry', 'Auroville'],
  'Lakshadweep': ['Kavaratti', 'Agatti', 'Bangaram'],
  'Dadra and Nagar Haveli and Daman and Diu': ['Daman', 'Diu', 'Silvassa'],
};

// 17 Experience-Oriented Specialties (Requirement 13)
const List<String> experienceSpecialties = [
  'Art and Creativity',
  'Food and Culinary Experience',
  'Nature and Wilderness',
  'Wellness and Mindfulness',
  'Culture and Traditional Experiences',
  'Local Life and Community',
  'Wildlife and Conservation',
  'Farming and Rural Life Experiences',
  'Adventure and Outdoor Activities',
  'Science and Discovery',
  'Photography and Visual Storytelling',
  'Festivals and Celebrations',
  'History and Heritage',
  'Water and Coastal Experiences',
  'Unique and Unusual Experiences',
  'Social and Shared Experiences',
  'Sustainability and Regenerative Experiences',
];

const Map<String, String> stateZoneMap = {
  // Northeast
  'Assam': 'Northeast',
  'Meghalaya': 'Northeast',
  'Arunachal Pradesh': 'Northeast',
  'Sikkim': 'Northeast',
  'Nagaland': 'Northeast',
  'Manipur': 'Northeast',
  'Mizoram': 'Northeast',
  'Tripura': 'Northeast',
  'Nepal': 'Northeast',
  'Bhutan': 'Northeast',

  // North
  'Himachal Pradesh': 'North',
  'Uttarakhand': 'North',
  'Ladakh': 'North',
  'Jammu and Kashmir': 'North',
  'Jammu & Kashmir': 'North',
  'Punjab': 'North',
  'Haryana': 'North',
  'Rajasthan': 'North',
  'Uttar Pradesh': 'North',
  'Delhi (NCT)': 'North',
  'Chandigarh': 'North',

  // South
  'Kerala': 'South',
  'Tamil Nadu': 'South',
  'Karnataka': 'South',
  'Goa': 'South',
  'Andhra Pradesh': 'South',
  'Telangana': 'South',
  'Puducherry': 'South',
  'Lakshadweep': 'South',
  'Andaman and Nicobar Islands': 'South',

  // West
  'Maharashtra': 'West',
  'Gujarat': 'West',
  'Dadra and Nagar Haveli and Daman and Diu': 'West',
  'Madhya Pradesh': 'West',
  'Chhattisgarh': 'West',
  'Bihar': 'Northeast',
  'West Bengal': 'Northeast',
  'Jharkhand': 'Northeast',
  'Odisha': 'South',
};

String getZoneForState(String? state) {
  if (state == null || state.trim().isEmpty) return 'North';
  return stateZoneMap[state.trim()] ?? 'North';
}
