import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/experience_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/experience_repository.dart';
import '../../theme/app_colors.dart';

class CreateEditItineraryScreen extends StatefulWidget {
  final ExperienceModel? experience;

  const CreateEditItineraryScreen({super.key, this.experience});

  @override
  State<CreateEditItineraryScreen> createState() => _CreateEditItineraryScreenState();
}

class _CreateEditItineraryScreenState extends State<CreateEditItineraryScreen> {
  final ExperienceRepository _expRepo = ExperienceRepository();
  final AuthRepository _authRepo = AuthRepository();

  // 3-Step Wizard:
  // 0 = Basics & Photos
  // 1 = Day-by-Day Plan (Activities, Stays, Inclusions)
  // 2 = PDF Brochure & Logistics
  int _currentStep = 0;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _isUploadingPdf = false;
  String _pdfUrl = '';
  String _pdfName = '';

  // Form Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _priceController = TextEditingController();
  final _meetingPointController = TextEditingController();
  final _meetingPointMapsUrlController = TextEditingController();
  final _cancellationPolicyController = TextEditingController();
  final _termsAndConditionsController = TextEditingController();
  final _permitsRequiredController = TextEditingController();

  final _imageUrlInputController = TextEditingController();
  final _pdfUrlInputController = TextEditingController();
  final _packingInputController = TextEditingController();
  final _inclusionInputController = TextEditingController();
  final _exclusionInputController = TextEditingController();

  String _selectedCategory = 'Trekking';
  String _selectedFitnessLevel = 'Moderate';
  String _selectedBestSeason = 'Spring & Autumn';
  int _durationDays = 1;
  int _durationNights = 0;
  int _maxGroupSize = 10;

  List<String> _galleryImages = [];
  List<String> _thingsToCarry = [];
  List<String> _inclusions = [];
  List<String> _exclusions = [];
  List<ItineraryDay> _days = [];

  // Route Pins (preserved from existing itineraries)
  final List<RoutePin> _routePins = [];

  static const List<String> categories = [
    'Trekking',
    'Heritage',
    'Cultural',
    'Adventure',
    'Spiritual',
    'Culinary',
    'Wildlife',
  ];

  static const List<String> allCountries = [
    'India',
    'Nepal',
    'Bhutan',
    'Sri Lanka',
    'Thailand',
    'Indonesia',
    'Vietnam',
    'Japan',
    'United Arab Emirates',
    'Georgia',
    'Turkey',
    'Switzerland',
    'United Kingdom',
    'United States',
    'Canada',
    'Australia',
    'New Zealand',
    'Kenya',
    'Tanzania',
    'Iceland',
    'Norway',
    'Peru',
    'Maldives',
    'Malaysia',
    'Singapore',
  ];

  static const List<String> allStatesAndRegions = [
    // 28 Indian States
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
    // 8 Union Territories
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi (NCT)',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
    // Popular Trekking & Expedition Regions
    'Bagmati (Nepal)',
    'Gandaki / Pokhara (Nepal)',
    'Karnali (Nepal)',
    'Everest Region / Khumbu (Nepal)',
    'Annapurna Region (Nepal)',
    'Thimphu / Paro (Bhutan)',
  ];

  static const List<String> fitnessLevels = [
    'Easy',
    'Moderate',
    'Difficult',
    'Extreme',
  ];

  static const List<String> seasons = [
    'Spring & Autumn',
    'Summer (May - Jul)',
    'Monsoon (Jul - Sep)',
    'Winter (Dec - Feb)',
    'All Year Round',
  ];

  // Cyan & Navy Theme Constants
  static const Color navyBlue = Color(0xFF1B365D);
  static const Color cyanAccent = Color(0xFF00B4D8);
  static const Color cyanLightBg = Color(0xFFE0F7FA);
  static const Color softPageBg = Color(0xFFF4F7FA);

  @override
  void initState() {
    super.initState();
    if (widget.experience != null) {
      final exp = widget.experience!;
      _titleController.text = exp.title;
      _descController.text = exp.description;
      _countryController.text = exp.country.isNotEmpty ? exp.country : 'India';
      _cityController.text = exp.city;
      _stateController.text = exp.state;
      _priceController.text = exp.price > 0 ? exp.price.toInt().toString() : '';
      _meetingPointController.text = exp.meetingPoint;
      _meetingPointMapsUrlController.text = exp.meetingPointMapsUrl;
      _cancellationPolicyController.text = exp.cancellationPolicy;
      _termsAndConditionsController.text = exp.termsAndConditions;
      _permitsRequiredController.text = exp.permitsRequired;

      _selectedCategory = exp.category.isNotEmpty ? exp.category : 'Trekking';
      _selectedFitnessLevel = exp.fitnessLevel.isNotEmpty ? exp.fitnessLevel : 'Moderate';
      _selectedBestSeason = exp.bestSeason.isNotEmpty ? exp.bestSeason : 'Spring & Autumn';
      _durationDays = exp.durationDays > 0 ? exp.durationDays : 1;
      _durationNights = exp.durationNights;
      _maxGroupSize = exp.maxGroupSize > 0 ? exp.maxGroupSize : 10;

      _galleryImages = List.from(exp.images);
      _pdfUrl = exp.pdfUrl;
      _pdfName = exp.pdfName;
      if (_pdfName.isEmpty && _pdfUrl.isNotEmpty) {
        _pdfName = 'Itinerary_Document.pdf';
      }
      _thingsToCarry = List.from(exp.thingsToCarry);
      _inclusions = List.from(exp.inclusions);
      _exclusions = List.from(exp.exclusions);
      _days = List.from(exp.days);
      for (final day in _days) {
        _routePins.addAll(day.routePins);
      }
    } else {
      _days = [
        ItineraryDay(
          dayNumber: 1,
          dayTitle: 'Arrival & Expedition Briefing',
          accommodation: 'Local Homestay / Eco Lodge',
          accommodationMapsUrl: '',
          mealsIncluded: const ['Dinner'],
          transportInfo: 'Pickup from hub',
          activities: [
            TimelineItem(
              time: '02:00 PM',
              activityTitle: 'Welcome, Orientation & Route Briefing',
              location: 'Base Camp',
              description: 'Meet your local host, inspect equipment, and review safety guidelines.',
            ),
          ],
        ),
      ];
      _inclusions = [
        'Certified local host and trail safety guides',
        'All homestay / camp accommodations',
        'Traditional meals and mountain tea',
        'Inner Line Permits and forest passes',
      ];
      _exclusions = [
        'Personal trekking gear and backpack',
        'Personal travel & medical insurance',
        'Entry tickets and personal emergency expenses',
      ];
      _thingsToCarry = [
        'Sturdy trekking boots with ankle support',
        'Warm fleece jacket & rain poncho',
        'Headlamp / flashlight with batteries',
        'Reusable 1L water bottle',
        'Personal medication & first-aid',
        'Valid Government ID proof',
      ];
      _durationDays = 1;
      _durationNights = 0;
    }
  }

  // ---------------------------------------------------------------------------
  // DAY OPERATIONS
  // ---------------------------------------------------------------------------
  ItineraryDay _copyDay(
    ItineraryDay day, {
    int? dayNumber,
    String? title,
    String? accommodation,
    String? accommodationPlaceId,
    String? accommodationMapsUrl,
    List<String>? mealsIncluded,
    String? transportInfo,
    String? overnightStay,
    List<TimelineItem>? activities,
    List<String>? highlights,
    List<RoutePin>? routePins,
  }) {
    return ItineraryDay(
      dayNumber: dayNumber ?? day.dayNumber,
      dayTitle: title ?? day.dayTitle,
      accommodation: accommodation ?? day.accommodation,
      accommodationPlaceId: accommodationPlaceId ?? day.accommodationPlaceId,
      accommodationMapsUrl: accommodationMapsUrl ?? day.accommodationMapsUrl,
      mealsIncluded: mealsIncluded ?? day.mealsIncluded,
      transportInfo: transportInfo ?? day.transportInfo,
      overnightStay: overnightStay ?? day.overnightStay,
      hasOvernightStay: day.hasOvernightStay,
      activities: activities ?? day.activities,
      highlights: highlights ?? day.highlights,
      routePins: routePins ?? day.routePins,
    );
  }

  void _addDay() {
    setState(() {
      final nextDayNum = _days.length + 1;
      _days.add(
        ItineraryDay(
          dayNumber: nextDayNum,
          dayTitle: 'Expedition Day $nextDayNum',
          accommodation: 'Homestay / Alpine Tents',
          accommodationMapsUrl: '',
          mealsIncluded: const ['Breakfast', 'Dinner'],
          transportInfo: 'Trek on foot',
          activities: [
            TimelineItem(
              time: '08:00 AM',
              activityTitle: 'Morning Exploration',
              location: 'Trailhead',
              description: 'Begin daily trek and cultural discovery with local guide.',
            ),
          ],
        ),
      );
      if (_durationDays < nextDayNum) {
        _durationDays = nextDayNum;
      }
    });
  }

  void _removeDay(int idx) {
    if (_days.length <= 1) return;
    setState(() {
      _days.removeAt(idx);
      // Renumber remaining days
      for (int i = 0; i < _days.length; i++) {
        _days[i] = _copyDay(_days[i], dayNumber: i + 1);
      }
      if (_durationDays > _days.length) {
        _durationDays = _days.length;
      }
    });
  }

  void _toggleDayMeal(int dayIdx, String meal) {
    final day = _days[dayIdx];
    final currentMeals = List<String>.from(day.mealsIncluded);
    if (currentMeals.contains(meal)) {
      currentMeals.remove(meal);
    } else {
      currentMeals.add(meal);
    }
    setState(() {
      _days[dayIdx] = _copyDay(day, mealsIncluded: currentMeals);
    });
  }

  void _addActivityToDay(int dayIdx) {
    final day = _days[dayIdx];
    final currentActivities = List<TimelineItem>.from(day.activities);
    currentActivities.add(
      TimelineItem(
        time: '12:00 PM',
        activityTitle: '',
        location: '',
        description: '',
      ),
    );
    setState(() {
      _days[dayIdx] = _copyDay(day, activities: currentActivities);
    });
  }

  void _removeActivityFromDay(int dayIdx, int actIdx) {
    final day = _days[dayIdx];
    final currentActivities = List<TimelineItem>.from(day.activities);
    if (actIdx < currentActivities.length) {
      currentActivities.removeAt(actIdx);
      setState(() {
        _days[dayIdx] = _copyDay(day, activities: currentActivities);
      });
    }
  }

  void _updateActivityField(
    int dayIdx,
    int actIdx, {
    String? time,
    String? title,
    String? location,
    String? desc,
  }) {
    final day = _days[dayIdx];
    final currentActivities = List<TimelineItem>.from(day.activities);
    if (actIdx >= currentActivities.length) return;
    final act = currentActivities[actIdx];
    currentActivities[actIdx] = TimelineItem(
      time: time ?? act.time,
      activityTitle: title ?? act.activityTitle,
      location: location ?? act.location,
      description: desc ?? act.description,
      imageUrl: act.imageUrl,
      highlight: act.highlight,
      subtext: act.subtext,
      instruction: act.instruction,
    );
    setState(() {
      _days[dayIdx] = _copyDay(day, activities: currentActivities);
    });
  }

  Future<void> _selectActivityTime(int dayIdx, int actIdx) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted || picked == null) return;
    final formatted = picked.format(context);
    _updateActivityField(dayIdx, actIdx, time: formatted);
  }

  // ---------------------------------------------------------------------------
  // INCLUSIONS & EXCLUSIONS & THINGS TO CARRY
  // ---------------------------------------------------------------------------
  void _addInclusion() {
    final text = _inclusionInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _inclusions.add(text);
        _inclusionInputController.clear();
      });
    }
  }

  void _addExclusion() {
    final text = _exclusionInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _exclusions.add(text);
        _exclusionInputController.clear();
      });
    }
  }

  void _addThingToCarry() {
    final text = _packingInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _thingsToCarry.add(text);
        _packingInputController.clear();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // IMAGE & PDF UPLOAD
  // ---------------------------------------------------------------------------
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final fileName = 'itinerary_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('itineraries').child('gallery').child(fileName);

      final bytes = await pickedFile.readAsBytes();
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      if (mounted) {
        setState(() {
          _galleryImages.add(downloadUrl);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded from phone successfully!'), backgroundColor: AppColors.brandGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _galleryImages.add(pickedFile.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image added locally: ${pickedFile.name}'), backgroundColor: navyBlue),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _pickAndUploadPdf() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (file == null) return;

      final bytes = await file.xFile.readAsBytes();

      setState(() => _isUploadingPdf = true);

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9.-]'), '_')}';
      final ref = FirebaseStorage.instance.ref().child('itineraries').child('pdfs').child(fileName);

      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'application/pdf'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      if (mounted) {
        setState(() {
          _pdfUrl = downloadUrl;
          _pdfName = file.name;
          _isUploadingPdf = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Itinerary PDF "${file.name}" uploaded successfully!'),
            backgroundColor: AppColors.brandGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload PDF: $e'), backgroundColor: AppColors.brandRed),
        );
      }
    }
  }

  void _showSamplePdfDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf, color: navyBlue, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sample Itinerary PDF Reference',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: navyBlue),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Based on the 19-Page "Hornbill Festival & Nagaland Magic" Guide Brochure:',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                _buildSampleSectionCard(
                  'Pages 1–9: Cover, Brief & Day-by-Day Flow',
                  '• Cover: Dates, 6N/7D duration, Dimapur/Kohima pickup & drop, hosts @thelocals_exp.\n'
                  '• Brief Itinerary: Day 1 Arrival to Day 7 Departure overview.\n'
                  '• Detailed Plan: Day 1-7 activities, Dzukou Valley trek, Kohima War Memorial, Khonoma village, and overnight hotel/camp stays.',
                ),
                const SizedBox(height: 8),
                _buildSampleSectionCard(
                  'Page 10: Inclusions & Exclusions Checklist',
                  '• Included: Tempo Traveller vehicle, 6-night stay, breakfasts, captains, local guides, sightseeing entry.\n'
                  '• Excluded: Extra meals, personal insurance, festival passes (₹100-300), tips, emergency costs.',
                ),
                const SizedBox(height: 8),
                _buildSampleSectionCard(
                  'Page 11: Cost Per Person & Booking Terms',
                  '• Double sharing: ₹52,999/- | Triple sharing: ₹48,999/-\n'
                  '• Booking advance: ₹20,000/- per head, balance 15 days before trip.\n'
                  '• Strict cancellation policy: Non-refundable for confirmed slots.',
                ),
                const SizedBox(height: 8),
                _buildSampleSectionCard(
                  'Pages 12–19: Packing List, Rules & FAQs',
                  '• Things to Carry: Trek pants, fleece, thermals, rain poncho, headlamp, power banks.\n'
                  '• Terms & Manners: Vehicle rules, no-litter policy, alcohol bans.\n'
                  '• FAQs: Inner Line Permits (ILP), safety, mobile network, and ATM info.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: navyBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleSectionCard(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: softPageBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: navyBlue)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 11, color: AppColors.textMain, height: 1.35)),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.brandGreen),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.textMain),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold, color: navyBlue)),
                  TextSpan(text: desc, style: const TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SAVE & PUBLISH HANDLER
  // ---------------------------------------------------------------------------
  Future<void> _handleSave() async {
    final user = _authRepo.currentUser;
    if (user == null) return;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter journey title.'), backgroundColor: AppColors.brandRed),
      );
      return;
    }

    // Check if at least one format is provided (either PDF attached OR Day-by-Day schedule created)
    final bool hasDays = _days.any((d) => d.dayTitle.trim().isNotEmpty || d.activities.isNotEmpty);
    final bool hasPdf = _pdfUrl.isNotEmpty;

    if (!hasDays && !hasPdf) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No Itinerary Provided', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: const Text(
            'You haven\'t created a Day-by-Day schedule or attached an Itinerary PDF brochure yet.\n\nWe recommend providing at least one format so travellers understand the expedition plan.\n\nDo you want to submit anyway?',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Go Back')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandGreen),
              child: const Text('Submit Anyway', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isSaving = true);

    try {
      final profile = await _authRepo.getUserProfile(user.uid);

      if (_days.isNotEmpty && _routePins.isNotEmpty) {
        final firstDay = _days.first;
        _days[0] = ItineraryDay(
          dayNumber: firstDay.dayNumber,
          dayTitle: firstDay.dayTitle,
          accommodation: firstDay.accommodation,
          accommodationPlaceId: firstDay.accommodationPlaceId,
          accommodationMapsUrl: firstDay.accommodationMapsUrl,
          mealsIncluded: firstDay.mealsIncluded,
          transportInfo: firstDay.transportInfo,
          overnightStay: firstDay.overnightStay,
          activities: firstDay.activities,
          highlights: firstDay.highlights,
          routePins: List.from(_routePins),
        );
      }

      final expToSave = ExperienceModel(
        id: widget.experience?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        guideId: user.uid,
        guideName: profile?.name ?? 'Local Guide',
        guidePhone: profile?.phone ?? '',
        guideExperienceYears: profile?.experienceYears ?? 2,
        country: _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : 'India',
        state: _stateController.text.trim(),
        city: _cityController.text.trim(),
        category: _selectedCategory,
        fitnessLevel: _selectedFitnessLevel,
        bestSeason: _selectedBestSeason,
        price: double.tryParse(_priceController.text) ?? 0.0,
        durationDays: _durationDays,
        durationNights: _durationNights,
        maxGroupSize: _maxGroupSize,
        meetingPoint: _meetingPointController.text.trim(),
        meetingPointMapsUrl: _meetingPointMapsUrlController.text.trim(),
        cancellationPolicy: _cancellationPolicyController.text.trim(),
        termsAndConditions: _termsAndConditionsController.text.trim(),
        permitsRequired: _permitsRequiredController.text.trim(),
        pdfUrl: _pdfUrl,
        pdfName: _pdfName.isNotEmpty ? _pdfName : (_pdfUrl.isNotEmpty ? 'Itinerary_Document.pdf' : ''),
        images: _galleryImages,
        thingsToCarry: _thingsToCarry,
        inclusions: _inclusions,
        exclusions: _exclusions,
        days: _days,
        status: 'pending',
      );

      await _expRepo.saveItinerary(expToSave);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Itinerary submitted to admin for approval!'),
          backgroundColor: AppColors.brandGreen,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('permission-denied')
          ? 'Permission Denied: Update Firebase Rules in Console for "itineraries" collection.'
          : 'Error: ${e.toString()}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.brandRed, duration: const Duration(seconds: 5)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _meetingPointController.dispose();
    _meetingPointMapsUrlController.dispose();
    _cancellationPolicyController.dispose();
    _termsAndConditionsController.dispose();
    _permitsRequiredController.dispose();
    _imageUrlInputController.dispose();
    _pdfUrlInputController.dispose();
    _packingInputController.dispose();
    _inclusionInputController.dispose();
    _exclusionInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softPageBg,
      appBar: AppBar(
        backgroundColor: navyBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.experience != null ? 'THE LOCALS · EDIT ITINERARY' : 'THE LOCALS · CREATE ITINERARY',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 3-Step Wizard Navigation Header Bar
            Container(
              color: navyBlue,
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
              child: Row(
                children: [
                  _buildStepTab(0, '1. Basics & Photos', Icons.badge_outlined),
                  const SizedBox(width: 6),
                  _buildStepTab(1, '2. Day-by-Day Plan', Icons.calendar_month_outlined),
                  const SizedBox(width: 6),
                  _buildStepTab(2, '3. PDF & Logistics', Icons.picture_as_pdf_outlined),
                ],
              ),
            ),

            // Scrollable Content Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildStepContent(),
              ),
            ),

            // Bottom Sticky Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _currentStep--),
                      icon: const Icon(Icons.arrow_back_ios, size: 14),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: navyBlue,
                        side: const BorderSide(color: navyBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  else
                    const SizedBox(),
                  
                  if (_currentStep == 0)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _currentStep = 1),
                      icon: const Text('Next: Day-by-Day Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                      label: const Icon(Icons.arrow_forward_ios, size: 14),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    )
                  else if (_currentStep == 1)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _currentStep = 2),
                      icon: const Text('Next: PDF & Logistics', style: TextStyle(fontWeight: FontWeight.bold)),
                      label: const Icon(Icons.arrow_forward_ios, size: 14),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(_isSaving ? 'Submitting...' : 'Submit Itinerary to Admin', style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTab(int stepIndex, String title, IconData icon) {
    final bool isActive = _currentStep == stepIndex;
    final bool isCompleted = _currentStep > stepIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentStep = stepIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? cyanAccent : (isCompleted ? Colors.white24 : Colors.white10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? Colors.cyanAccent : Colors.transparent),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCompleted ? Icons.check_circle : icon,
                size: 15,
                color: isActive ? navyBlue : Colors.white,
              ),
              const SizedBox(height: 3),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? navyBlue : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1BasicsAndMedia();
      case 1:
        return _buildStep2DayByDayPlan();
      case 2:
        return _buildStep3PdfAndLogistics();
      default:
        return const SizedBox();
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1: BASICS, PRICING & MEDIA
  // ---------------------------------------------------------------------------
  Widget _buildStep1BasicsAndMedia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Basic Itinerary Details', Icons.directions_walk),
              const SizedBox(height: 14),
              _buildTextField(
                key: const ValueKey('input_journey_title'),
                controller: _titleController,
                label: 'Journey Title',
                hint: 'e.g. Kedarkantha Summit Winter Trek',
                icon: Icons.title,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown<String>(
                      label: 'Category',
                      value: _selectedCategory,
                      icon: Icons.category,
                      items: categories,
                      onChanged: (val) => setState(() => _selectedCategory = val ?? _selectedCategory),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSearchablePickerField(
                      label: 'Country',
                      hint: 'e.g. India, Nepal, Bhutan',
                      icon: Icons.public,
                      controller: _countryController,
                      options: allCountries,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildSearchablePickerField(
                      label: 'State / Region',
                      hint: 'e.g. Uttarakhand, Himachal, Bagmati',
                      icon: Icons.map_outlined,
                      controller: _stateController,
                      options: allStatesAndRegions,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PlaceSearchField(
                      key: const ValueKey('input_city'),
                      controller: _cityController,
                      label: 'City / Base Hub',
                      hint: 'Search city... e.g. Manali, Pokhara, Leh',
                      icon: Icons.location_city,
                      onPlaceSelected: (item) {
                        final pName = item['name'] ?? '';
                        if (pName.isNotEmpty) {
                          setState(() => _cityController.text = pName);
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (_cityController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cyanLightBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: cyanAccent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pin_drop, size: 14, color: navyBlue),
                          const SizedBox(width: 4),
                          Text(
                            'Base Hub: ${_cityController.text}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: navyBlue),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        final query = '${_cityController.text}, ${_stateController.text}, ${_countryController.text}'.trim();
                        final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: navyBlue.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map, size: 14, color: navyBlue),
                            SizedBox(width: 4),
                            Text('View on Google Maps 🗺️', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: navyBlue)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),
        _buildCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Pricing, Duration & Difficulty', Icons.payments),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildTextField(
                      key: const ValueKey('input_price'),
                      controller: _priceController,
                      label: 'Price / Person (₹)',
                      hint: 'e.g. 5000',
                      icon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _durationDays,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: AppColors.textMain, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Days',
                        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
                      ),
                      items: List.generate(30, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text('$d Days'))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _durationDays = val;
                            while (_days.length < val) {
                              _days.add(ItineraryDay(
                                dayNumber: _days.length + 1,
                                dayTitle: 'Expedition Day ${_days.length + 1}',
                                accommodation: 'Homestay / Alpine Tents',
                                accommodationMapsUrl: '',
                                mealsIncluded: const ['Breakfast', 'Dinner'],
                                activities: [],
                              ));
                            }
                            if (_days.length > val) {
                              _days = _days.sublist(0, val);
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _durationNights,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: AppColors.textMain, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Nights',
                        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
                      ),
                      items: List.generate(30, (i) => i).map((n) => DropdownMenuItem(value: n, child: Text('$n Nights'))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _durationNights = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown<String>(
                      label: 'Fitness Level',
                      value: _selectedFitnessLevel,
                      icon: Icons.fitness_center,
                      items: fitnessLevels,
                      onChanged: (val) => setState(() => _selectedFitnessLevel = val ?? _selectedFitnessLevel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown<String>(
                      label: 'Best Season',
                      value: _selectedBestSeason,
                      icon: Icons.wb_sunny,
                      items: seasons,
                      onChanged: (val) => setState(() => _selectedBestSeason = val ?? _selectedBestSeason),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        _buildCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Overview Story & Photos', Icons.collections),
              const SizedBox(height: 14),
              _buildTextField(
                key: const ValueKey('input_journey_desc'),
                controller: _descController,
                label: 'Itinerary Story & Description',
                hint: 'Describe the journey highlights, scenery, trail difficulty & culture...',
                icon: Icons.description,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              
              const Text('Add Itinerary Photos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: navyBlue)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                      icon: _isUploadingImage
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.photo_library, size: 18),
                      label: Text(_isUploadingImage ? 'Uploading...' : 'Pick from Phone Storage', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      key: const ValueKey('input_image_url'),
                      controller: _imageUrlInputController,
                      label: 'Or Enter Image URL',
                      hint: 'https://images.unsplash.com/...',
                      icon: Icons.link,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: navyBlue,
                      side: const BorderSide(color: navyBlue),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final url = _imageUrlInputController.text.trim();
                      if (url.isNotEmpty) {
                        setState(() {
                          _galleryImages.add(url);
                          _imageUrlInputController.clear();
                        });
                      }
                    },
                    child: const Text('Add URL', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_galleryImages.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: softPageBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
                  child: const Center(
                    child: Text('No photos added yet. Upload from phone gallery or enter image URL.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                  itemCount: _galleryImages.length,
                  itemBuilder: (context, idx) {
                    final imgUrl = _galleryImages[idx];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imgUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _galleryImages.removeAt(idx)),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(color: Color(0xB3000000), shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                        if (idx == 0)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: cyanAccent, borderRadius: BorderRadius.circular(4)),
                              child: const Text('COVER', style: TextStyle(color: navyBlue, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: DAY-BY-DAY PLAN, ACTIVITIES & INCLUSIONS
  // ---------------------------------------------------------------------------
  Widget _buildStep2DayByDayPlan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Helper Banner with "Skip to PDF" Option
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cyanLightBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cyanAccent.withValues(alpha: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: navyBlue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Day-by-Day Schedule Builder',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: navyBlue),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Add daily schedule, lodging, meals & activities. If you have a prepared PDF brochure, you can skip this step or do both!',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => setState(() => _currentStep = 2),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Skip to PDF Upload ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: navyBlue)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Day Cards Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Day-by-Day Itinerary (${_days.length} Days)', Icons.calendar_month),
            ElevatedButton.icon(
              onPressed: _addDay,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: navyBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List of Day Cards
        Column(
          children: List.generate(_days.length, (idx) {
            final day = _days[idx];
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cyanAccent.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day Title Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: navyBlue, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            'DAY ${day.dayNumber}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        if (_days.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.brandRed, size: 20),
                            onPressed: () => _removeDay(idx),
                            tooltip: 'Remove Day ${day.dayNumber}',
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      key: ValueKey('input_day_title_${day.dayNumber}'),
                      initialValue: day.dayTitle,
                      label: 'Day Title',
                      hint: 'e.g. Day ${day.dayNumber}: Arrival & Trek Kickoff',
                      icon: Icons.today,
                      onChanged: (val) => _days[idx] = _copyDay(day, title: val),
                    ),
                    const SizedBox(height: 12),

                    // Accommodation / Lodging Field
                    _AccommodationField(
                      key: ValueKey('input_accommodation_day_${day.dayNumber}'),
                      day: day,
                      onDayUpdated: (updatedDay) {
                        setState(() {
                          _days[idx] = updatedDay;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Meals Included Multi-Select Chips
                    const Text('Meals Included:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: navyBlue)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ['Breakfast', 'Lunch', 'Dinner', 'Evening Tea & Snacks'].map((meal) {
                        final isSelected = day.mealsIncluded.contains(meal);
                        return FilterChip(
                          label: Text(meal, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : AppColors.textMain)),
                          selected: isSelected,
                          selectedColor: AppColors.brandGreen,
                          backgroundColor: softPageBg,
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          onSelected: (_) => _toggleDayMeal(idx, meal),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Activities Timeline
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Activity Timeline (${day.activities.length}):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: navyBlue)),
                        TextButton.icon(
                          onPressed: () => _addActivityToDay(idx),
                          icon: const Icon(Icons.add_circle_outline, size: 14, color: navyBlue),
                          label: const Text('Add Activity', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: navyBlue)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (day.activities.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(color: softPageBg, borderRadius: BorderRadius.circular(8)),
                        child: const Text('No activity slots added yet. Tap "Add Activity" above.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: day.activities.length,
                        itemBuilder: (ctx, actIdx) {
                          final act = day.activities[actIdx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: softPageBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _selectActivityTime(idx, actIdx),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: cyanLightBg,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: navyBlue.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time_filled, size: 13, color: navyBlue),
                                            const SizedBox(width: 4),
                                            Text(
                                              act.time.isNotEmpty ? act.time : 'Set Time ⏰',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: navyBlue),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: act.activityTitle,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMain, fontWeight: FontWeight.bold),
                                        decoration: const InputDecoration(
                                          hintText: 'Activity title...',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(),
                                          fillColor: Colors.white,
                                          filled: true,
                                        ),
                                        onChanged: (val) => _updateActivityField(idx, actIdx, title: val),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.brandRed),
                                      onPressed: () => _removeActivityFromDay(idx, actIdx),
                                      tooltip: 'Remove',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: act.location,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMain),
                                        decoration: const InputDecoration(
                                          hintText: 'Location / Spot',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          border: OutlineInputBorder(),
                                          fillColor: Colors.white,
                                          filled: true,
                                        ),
                                        onChanged: (val) => _updateActivityField(idx, actIdx, location: val),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: act.description,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMain),
                                        decoration: const InputDecoration(
                                          hintText: 'Brief description / instructions',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          border: OutlineInputBorder(),
                                          fillColor: Colors.white,
                                          filled: true,
                                        ),
                                        onChanged: (val) => _updateActivityField(idx, actIdx, desc: val),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 16),

        // Inclusions & Exclusions & Things to Carry Checklist
        _buildCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Inclusions, Exclusions & Packing List', Icons.checklist),
              const SizedBox(height: 14),

              // Inclusions
              const Text('What\'s Included:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: navyBlue)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _inclusions.map((item) => Chip(
                  label: Text(item, style: const TextStyle(fontSize: 11)),
                  backgroundColor: const Color(0xFFECFDF5),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => setState(() => _inclusions.remove(item)),
                )).toList(),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _inclusionInputController,
                      label: 'Add Included Item',
                      hint: 'e.g. Certified local guide, permits...',
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addInclusion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Exclusions
              const Text('What\'s Excluded:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: navyBlue)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _exclusions.map((item) => Chip(
                  label: Text(item, style: const TextStyle(fontSize: 11)),
                  backgroundColor: const Color(0xFFFEF2F2),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => setState(() => _exclusions.remove(item)),
                )).toList(),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _exclusionInputController,
                      label: 'Add Excluded Item',
                      hint: 'e.g. Personal gear, airfare...',
                      icon: Icons.cancel_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addExclusion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Things to Carry
              const Text('Things to Carry / Packing List:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: navyBlue)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _thingsToCarry.map((item) => Chip(
                  label: Text(item, style: const TextStyle(fontSize: 11)),
                  backgroundColor: const Color(0xFFFFFBEB),
                  side: const BorderSide(color: Color(0xFFF59E0B)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => setState(() => _thingsToCarry.remove(item)),
                )).toList(),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _packingInputController,
                      label: 'Add Packing Item',
                      hint: 'e.g. Trekking shoes, powerbank...',
                      icon: Icons.backpack_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addThingToCarry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: PDF UPLOAD, NOTICE REQUIREMENTS & LOGISTICS
  // ---------------------------------------------------------------------------
  Widget _buildStep3PdfAndLogistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NOTICE CARD
        _buildCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cyanLightBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline, color: navyBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ITINERARY BROCHURE & PDF NOTICE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: navyBlue,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Guides can upload their official Itinerary brochure PDF. Travellers can download and view this document directly.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildRequirementItem('1. Day-by-Day Schedule & Stays', 'Arrival, daily activities, trek hours, and overnight stay points.'),
              _buildRequirementItem('2. Inclusions & Exclusions', 'Vehicles, stays, meals, captains vs personal expenses & festival passes.'),
              _buildRequirementItem('3. Cost & Booking Payment Details', 'Double / Triple sharing rates, seat advance amount, and bank/GPay details.'),
              _buildRequirementItem('4. Things to Carry (Packing List)', 'Trekking shoes, warm fleece, thermals, luggage limit, and power banks.'),
              _buildRequirementItem('5. Terms & Cancellation Policy', 'Strict non-refundable cancellation policy, vehicle rules, and conduct.'),
              _buildRequirementItem('6. Mountain Manners, Trivia & FAQs', 'Permit requirements (ILP), network coverage, cash advice, and host bios.'),
              
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showSamplePdfDialog,
                  icon: const Icon(Icons.visibility, size: 16, color: navyBlue),
                  label: const Text('View Sample PDF Format Reference', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: navyBlue)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: navyBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // DIRECT PDF UPLOAD BOX
        _buildCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Official Itinerary Brochure (PDF)', Icons.picture_as_pdf),
              const SizedBox(height: 6),
              const Text('Travellers will read and download this verified document directly from your listing.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 14),

              if (_pdfUrl.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pdfName.isNotEmpty ? _pdfName : 'Itinerary_Document.pdf',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF065F46)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                const Text('✓ PDF verified and attached to listing', style: TextStyle(fontSize: 11, color: Color(0xFF047857))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse(_pdfUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Open / Preview PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => setState(() {
                              _pdfUrl = '';
                              _pdfName = '';
                            }),
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.brandRed),
                            label: const Text('Remove', style: TextStyle(fontSize: 12, color: AppColors.brandRed)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.brandRed),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: softPageBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 40, color: navyBlue),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload Itinerary PDF from Device',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: navyBlue),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'PDF brochure will be directly downloadable by travellers',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _isUploadingPdf ? null : _pickAndUploadPdf,
                        icon: _isUploadingPdf
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.upload_file, size: 18),
                        label: Text(_isUploadingPdf ? 'Uploading PDF...' : 'Select PDF File', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navyBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('OR ENTER DIRECT PDF URL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              key: const ValueKey('input_pdf_url_field'),
                              controller: _pdfUrlInputController,
                              label: 'PDF Download Link',
                              hint: 'https://.../itinerary.pdf',
                              icon: Icons.link,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navyBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              final url = _pdfUrlInputController.text.trim();
                              if (url.isNotEmpty) {
                                setState(() {
                                  _pdfUrl = url;
                                  _pdfName = 'Attached_Itinerary.pdf';
                                  _pdfUrlInputController.clear();
                                });
                              }
                            },
                            child: const Text('Attach', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // LOGISTICS & MEETING SPOT
        _buildCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Logistics & Meeting Spot', Icons.place),
              const SizedBox(height: 14),
              _PlaceSearchField(
                key: const ValueKey('meeting_point_place_search_field'),
                label: 'Meeting Point Address / Pickup Spot',
                hint: 'Type location... e.g. Dimapur Airport, Kohima City Center',
                icon: Icons.place,
                controller: _meetingPointController,
                onPlaceSelected: (item) {
                  final pName = item['name'] ?? '';
                  if (pName.isNotEmpty) {
                    _meetingPointController.text = pName;
                    if (_meetingPointMapsUrlController.text.isEmpty) {
                      _meetingPointMapsUrlController.text =
                          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(pName)}';
                    }
                  }
                },
              ),
              const SizedBox(height: 10),
              _buildTextField(
                key: const ValueKey('input_meeting_maps_url'),
                controller: _meetingPointMapsUrlController,
                label: 'Google Maps Link / Directions URL (Auto-filled or Custom)',
                hint: 'https://maps.google.com/?q=...',
                icon: Icons.map,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final urlStr = _meetingPointMapsUrlController.text.trim().isNotEmpty
                        ? _meetingPointMapsUrlController.text.trim()
                        : (_meetingPointController.text.trim().isNotEmpty
                            ? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_meetingPointController.text.trim())}'
                            : '');
                    if (urlStr.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a meeting point address or maps link first')),
                      );
                      return;
                    }
                    final uri = Uri.parse(urlStr);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.directions, size: 16, color: navyBlue),
                  label: const Text('Test on Google Maps 🗺️', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: navyBlue)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: navyBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // SUMMARY CARD
        _buildCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Summary & Submit to Admin', Icons.verified),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(color: softPageBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: cyanAccent)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleController.text.isNotEmpty ? _titleController.text : 'Journey Title Preview',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyBlue),
                    ),
                    const SizedBox(height: 4),
                    Text('Location: ${_cityController.text}, ${_stateController.text}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    Text('Duration: $_durationDays Days / $_durationNights Nights · Base Price: ₹${_priceController.text}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          _days.any((d) => d.dayTitle.trim().isNotEmpty) ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 15,
                          color: _days.any((d) => d.dayTitle.trim().isNotEmpty) ? AppColors.brandGreen : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text('Day Schedule: ${_days.length} Days Built', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _pdfUrl.isNotEmpty ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 15,
                          color: _pdfUrl.isNotEmpty ? AppColors.brandGreen : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _pdfUrl.isNotEmpty ? 'PDF Brochure: ${_pdfName.isNotEmpty ? _pdfName : 'Attached'}' : 'PDF Brochure: None attached (Optional if Days added)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _pdfUrl.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                            color: _pdfUrl.isNotEmpty ? AppColors.brandGreen : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(label: Text(_selectedCategory), backgroundColor: cyanLightBg),
                        const SizedBox(width: 6),
                        Chip(label: Text(_selectedFitnessLevel), backgroundColor: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: cyanLightBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: navyBlue, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: navyBlue),
        ),
      ],
    );
  }

  Widget _buildTextField({
    Key? key,
    TextEditingController? controller,
    String? initialValue,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    assert(controller == null || initialValue == null, 'Cannot provide both controller and initialValue at the same time');
    return TextFormField(
      key: key,
      controller: controller,
      initialValue: initialValue,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textMain, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26, fontSize: 12),
        prefixIcon: Icon(icon, color: navyBlue, size: 18),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: navyBlue, width: 1.5)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required IconData icon,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      initialValue: value,
      dropdownColor: Colors.white,
      style: const TextStyle(color: AppColors.textMain, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        prefixIcon: Icon(icon, color: navyBlue, size: 18),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: navyBlue, width: 1.5)),
      ),
      items: items.map((i) => DropdownMenuItem<T>(value: i, child: Text(i.toString(), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _showSearchablePicker({
    required String title,
    required List<String> options,
    required TextEditingController controller,
    String hint = 'Search or enter custom...',
  }) async {
    final searchController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.trim();
            final filtered = options
                .where((o) => o.toLowerCase().contains(query.toLowerCase()))
                .toList();
            final isExactMatch = options
                .any((o) => o.toLowerCase() == query.toLowerCase());

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: navyBlue,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: navyBlue, size: 20),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  setModalState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: softPageBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                  ),
                  if (query.isNotEmpty && !isExactMatch)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: InkWell(
                        onTap: () {
                          setState(() => controller.text = query);
                          Navigator.of(ctx).pop();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: cyanLightBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cyanAccent),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle, color: navyBlue, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Use custom: "$query"',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: navyBlue,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: navyBlue, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const Divider(height: 12),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = controller.text.toLowerCase() == item.toLowerCase();
                        return ListTile(
                          dense: true,
                          title: Text(
                            item,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? navyBlue : Colors.black87,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: cyanAccent, size: 20)
                              : null,
                          onTap: () {
                            setState(() => controller.text = item);
                            Navigator.of(ctx).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchablePickerField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required List<String> options,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.textMain, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26, fontSize: 12),
        prefixIcon: Icon(icon, color: navyBlue, size: 18),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: navyBlue, size: 20),
          tooltip: 'Browse list',
          onPressed: () => _showSearchablePicker(
            title: label,
            options: options,
            controller: controller,
            hint: 'Search $label or type custom...',
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: navyBlue, width: 1.5),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ACCOMMODATION / LODGING FIELD WIDGET
// -----------------------------------------------------------------------------
class _AccommodationField extends StatefulWidget {
  final ItineraryDay day;
  final ValueChanged<ItineraryDay> onDayUpdated;

  const _AccommodationField({
    super.key,
    required this.day,
    required this.onDayUpdated,
  });

  @override
  State<_AccommodationField> createState() => _AccommodationFieldState();
}

class _AccommodationFieldState extends State<_AccommodationField> {
  static const Color _navyBlue = Color(0xFF1B365D);

  late final TextEditingController _nameController;
  late final TextEditingController _mapsUrlController;
  List<Map<String, String>> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.day.accommodation);
    _mapsUrlController = TextEditingController(text: widget.day.accommodationMapsUrl);
  }

  @override
  void didUpdateWidget(covariant _AccommodationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.day.accommodation != _nameController.text) {
      _nameController.text = widget.day.accommodation;
    }
    if (widget.day.accommodationMapsUrl != _mapsUrlController.text) {
      _mapsUrlController.text = widget.day.accommodationMapsUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mapsUrlController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().length < 2) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final keys = [
        "AIzaSyCT8GU_dkAkoLlxhkb9TFc0vQasOHeAFxA",
        "AIzaSyBDNeSC26NH00lIuxZQA_GaBDXcicywdM4",
      ];

      for (final apiKey in keys) {
        try {
          final url = Uri.parse(
            'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&types=lodging&key=$apiKey',
          );
          final response = await http.get(url);
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['status'] == 'OK' && data['predictions'] != null) {
              final List predictions = data['predictions'];
              final results = predictions.take(5).map<Map<String, String>>((p) {
                final structured = p['structured_formatting'];
                final mainText = structured != null ? structured['main_text'] ?? '' : p['description'] ?? '';
                final secondaryText = structured != null ? structured['secondary_text'] ?? '' : '';
                return {
                  'name': mainText.toString(),
                  'address': secondaryText.toString(),
                  'placeId': (p['place_id'] ?? '').toString(),
                  'fullDescription': (p['description'] ?? '').toString(),
                };
              }).toList();

              if (mounted) {
                setState(() {
                  _suggestions = results;
                  _isLoading = false;
                });
              }
              return;
            }
          }
        } catch (e) {
          debugPrint('Accommodation search error: $e');
        }
      }

      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
    });
  }

  void _selectSuggestion(Map<String, String> item) {
    final name = item['name'] ?? '';
    final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(item['fullDescription'] ?? name)}';
    _nameController.text = name;
    _mapsUrlController.text = mapsUrl;

    widget.onDayUpdated(ItineraryDay(
      dayNumber: widget.day.dayNumber,
      dayTitle: widget.day.dayTitle,
      accommodation: name,
      accommodationPlaceId: item['placeId'] ?? '',
      accommodationMapsUrl: mapsUrl,
      mealsIncluded: widget.day.mealsIncluded,
      transportInfo: widget.day.transportInfo,
      overnightStay: widget.day.overnightStay,
      hasOvernightStay: widget.day.hasOvernightStay,
      activities: widget.day.activities,
      highlights: widget.day.highlights,
      routePins: widget.day.routePins,
    ));

    setState(() => _suggestions = []);
  }

  void _notifyUpdated() {
    final name = _nameController.text.trim();
    final mapsUrl = _mapsUrlController.text.trim().isNotEmpty
        ? _mapsUrlController.text.trim()
        : (name.isNotEmpty ? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(name)}' : '');

    widget.onDayUpdated(ItineraryDay(
      dayNumber: widget.day.dayNumber,
      dayTitle: widget.day.dayTitle,
      accommodation: name,
      accommodationPlaceId: widget.day.accommodationPlaceId,
      accommodationMapsUrl: mapsUrl,
      mealsIncluded: widget.day.mealsIncluded,
      transportInfo: widget.day.transportInfo,
      overnightStay: widget.day.overnightStay,
      hasOvernightStay: widget.day.hasOvernightStay,
      activities: widget.day.activities,
      highlights: widget.day.highlights,
      routePins: widget.day.routePins,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          style: const TextStyle(fontSize: 12, color: AppColors.textMain, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Stay / Accommodation (e.g. Hotel, Homestay, Alpine Tents)',
            labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            hintText: 'Search or type hotel, camp, or homestay...',
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 11),
            prefixIcon: const Icon(Icons.hotel, color: _navyBlue, size: 16),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _navyBlue)),
                  )
                : (_nameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14, color: Colors.grey),
                        onPressed: () {
                          _nameController.clear();
                          _mapsUrlController.clear();
                          _notifyUpdated();
                        },
                      )
                    : null),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _navyBlue, width: 1.5)),
          ),
          onChanged: (val) {
            _onSearchChanged(val);
            _notifyUpdated();
          },
        ),

        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Column(
              children: _suggestions.map((item) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.hotel, size: 16, color: _navyBlue),
                  title: Text(item['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: item['address']!.isNotEmpty ? Text(item['address']!, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)) : null,
                  onTap: () => _selectSuggestion(item),
                );
              }).toList(),
            ),
          ),
        ],

        if (_nameController.text.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _mapsUrlController,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMain),
                  decoration: InputDecoration(
                    hintText: 'Stay Google Maps link (Auto or Custom)',
                    hintStyle: const TextStyle(fontSize: 10, color: Colors.black26),
                    prefixIcon: const Icon(Icons.map, size: 14, color: _navyBlue),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.black12)),
                  ),
                  onChanged: (_) => _notifyUpdated(),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () async {
                  final url = _mapsUrlController.text.trim().isNotEmpty
                      ? _mapsUrlController.text.trim()
                      : (_nameController.text.trim().isNotEmpty
                          ? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_nameController.text.trim())}'
                          : '');
                  if (url.isNotEmpty) {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 12, color: _navyBlue),
                label: const Text('Map 📍', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _navyBlue)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _navyBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// PLACE SEARCH FIELD (FOR BASE CITY & MEETING SPOT)
// -----------------------------------------------------------------------------
class _PlaceSearchField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final void Function(Map<String, String> place) onPlaceSelected;

  const _PlaceSearchField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.onPlaceSelected,
  });

  @override
  State<_PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<_PlaceSearchField> {
  final FocusNode _focusNode = FocusNode();
  List<Map<String, String>> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().length < 2) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final keys = [
        "AIzaSyCT8GU_dkAkoLlxhkb9TFc0vQasOHeAFxA",
        "AIzaSyBDNeSC26NH00lIuxZQA_GaBDXcicywdM4",
      ];

      for (final apiKey in keys) {
        try {
          final url = Uri.parse(
            'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$apiKey',
          );
          final response = await http.get(url);
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['status'] == 'OK' && data['predictions'] != null) {
              final List predictions = data['predictions'];
              final results = predictions.take(5).map<Map<String, String>>((p) {
                final structured = p['structured_formatting'];
                final mainText = structured != null ? structured['main_text'] ?? '' : p['description'] ?? '';
                final secondaryText = structured != null ? structured['secondary_text'] ?? '' : '';
                return {
                  'name': mainText.toString(),
                  'address': secondaryText.toString(),
                  'placeId': (p['place_id'] ?? '').toString(),
                  'fullDescription': (p['description'] ?? '').toString(),
                };
              }).toList();

              if (mounted) {
                setState(() {
                  _suggestions = results;
                  _isLoading = false;
                });
              }
              return;
            }
          }
        } catch (e) {
          debugPrint('Place search API error: $e');
        }
      }

      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
    });
  }

  void _selectSuggestion(Map<String, String> item) {
    widget.controller.text = item['fullDescription'] ?? item['name'] ?? '';
    widget.onPlaceSelected(item);
    setState(() {
      _suggestions = [];
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          focusNode: _focusNode,
          controller: widget.controller,
          style: const TextStyle(fontSize: 13, color: AppColors.textMain),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            hintText: widget.hint,
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 12),
            prefixIcon: Icon(widget.icon, color: const Color(0xFF1B365D), size: 18),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B365D))),
                  )
                : (widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                        onPressed: () {
                          widget.controller.clear();
                          setState(() => _suggestions = []);
                        },
                      )
                    : null),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1B365D), width: 1.5)),
          ),
          onChanged: _onSearchChanged,
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Column(
              children: _suggestions.map((item) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place, size: 18, color: Color(0xFF1B365D)),
                  title: Text(item['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: item['address']!.isNotEmpty ? Text(item['address']!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)) : null,
                  onTap: () => _selectSuggestion(item),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
