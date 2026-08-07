import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  // 3-Step Wizard: 0 = Basics & Media, 1 = Itinerary & Map, 2 = Logistics & Publish
  int _currentStep = 0;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  // Form Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _cityController = TextEditingController();
  final _priceController = TextEditingController();
  final _meetingPointController = TextEditingController();
  final _cancellationPolicyController = TextEditingController();
  final _permitsRequiredController = TextEditingController();

  final _imageUrlInputController = TextEditingController();
  final _packingInputController = TextEditingController();
  final _inclusionInputController = TextEditingController();
  final _exclusionInputController = TextEditingController();

  String _selectedState = 'Uttarakhand';
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

  // Google Maps Pins
  final List<RoutePin> _routePins = [];
  GoogleMapController? _mapController;

  static const List<String> indianStates = [
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
    'Andaman & Nicobar Islands',
    'Chandigarh',
    'Dadra & Nagar Haveli & Daman & Diu',
    'Delhi (NCT)',
    'Jammu & Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  static const List<String> categories = [
    'Trekking',
    'Heritage',
    'Cultural',
    'Adventure',
    'Spiritual',
    'Culinary',
    'Wildlife',
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
      _cityController.text = exp.city;
      _priceController.text = exp.price > 0 ? exp.price.toInt().toString() : '';
      _meetingPointController.text = exp.meetingPoint;
      _cancellationPolicyController.text = exp.cancellationPolicy;
      _permitsRequiredController.text = exp.permitsRequired;

      _selectedState = indianStates.contains(exp.state) ? exp.state : 'Uttarakhand';
      _selectedCategory = exp.category.isNotEmpty ? exp.category : 'Trekking';
      _selectedFitnessLevel = exp.fitnessLevel.isNotEmpty ? exp.fitnessLevel : 'Moderate';
      _selectedBestSeason = exp.bestSeason.isNotEmpty ? exp.bestSeason : 'Spring & Autumn';
      _durationDays = exp.durationDays > 0 ? exp.durationDays : 1;
      _durationNights = exp.durationNights;
      _maxGroupSize = exp.maxGroupSize > 0 ? exp.maxGroupSize : 10;

      _galleryImages = List.from(exp.images);
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
          dayTitle: '',
          accommodation: '',
          accommodationMapsUrl: '',
          activities: [],
        ),
      ];
      _durationDays = 1;
      _durationNights = 0;
    }
  }

  void _addNextDay() {
    setState(() {
      final nextNum = _days.length + 1;
      _days.add(
        ItineraryDay(
          dayNumber: nextNum,
          dayTitle: '',
          accommodation: '',
          accommodationMapsUrl: '',
          activities: [],
        ),
      );
      _durationDays = _days.length;
      if (_durationNights < _durationDays - 1) {
        _durationNights = _durationDays - 1;
      }
    });
  }

  void _removeDay(int index) {
    if (_days.length <= 1) return;
    setState(() {
      _days.removeAt(index);
      // Re-index remaining days
      for (int i = 0; i < _days.length; i++) {
        final d = _days[i];
        _days[i] = ItineraryDay(
          dayNumber: i + 1,
          dayTitle: d.dayTitle,
          accommodation: d.accommodation,
          accommodationPlaceId: d.accommodationPlaceId,
          accommodationMapsUrl: d.accommodationMapsUrl,
          activities: d.activities,
          highlights: d.highlights,
          routePins: d.routePins,
        );
      }
      _durationDays = _days.length;
      if (_durationNights >= _durationDays) {
        _durationNights = _durationDays > 0 ? _durationDays - 1 : 0;
      }
    });
  }

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
        // Fallback: use local path preview if Firebase Storage is unconfigured
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

  Future<void> _handleSave() async {
    final user = _authRepo.currentUser;
    if (user == null) return;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter journey title.'), backgroundColor: AppColors.brandRed),
      );
      return;
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
        state: _selectedState,
        city: _cityController.text.trim(),
        category: _selectedCategory,
        fitnessLevel: _selectedFitnessLevel,
        bestSeason: _selectedBestSeason,
        price: double.tryParse(_priceController.text) ?? 1500.0,
        durationDays: _durationDays,
        durationNights: _durationNights,
        maxGroupSize: _maxGroupSize,
        meetingPoint: _meetingPointController.text.trim(),
        cancellationPolicy: _cancellationPolicyController.text.trim(),
        permitsRequired: _permitsRequiredController.text.trim(),
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
    _cityController.dispose();
    _priceController.dispose();
    _meetingPointController.dispose();
    _cancellationPolicyController.dispose();
    _permitsRequiredController.dispose();
    _imageUrlInputController.dispose();
    _packingInputController.dispose();
    _inclusionInputController.dispose();
    _exclusionInputController.dispose();
    super.dispose();
  }

  Future<void> _selectActivityTime(BuildContext context, int dayIdx, int actIdx) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: navyBlue,
              onPrimary: Colors.white,
              onSurface: navyBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime = picked.format(context);
      setState(() {
        final currentTitle = _days[dayIdx].activities[actIdx].activityTitle;
        _days[dayIdx].activities[actIdx] = TimelineItem(
          time: formattedTime,
          activityTitle: currentTitle,
        );
      });
    }
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
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
              child: Row(
                children: [
                  _buildStepTab(0, '1. Basics & Media', Icons.badge_outlined),
                  const SizedBox(width: 6),
                  _buildStepTab(1, '2. Schedule & Map', Icons.map_outlined),
                  const SizedBox(width: 6),
                  _buildStepTab(2, '3. Logistics & Submit', Icons.verified_outlined),
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
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))
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
                  
                  if (_currentStep < 2)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _currentStep++),
                      icon: const Text('Next Step', style: TextStyle(fontWeight: FontWeight.bold)),
                      label: const Icon(Icons.arrow_forward_ios, size: 14),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                size: 16,
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
        return _buildStep2ItineraryAndMap();
      case 2:
        return _buildStep3LogisticsAndPublish();
      default:
        return const SizedBox();
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1: BASICS, PRICING & MEDIA (Decluttered & Overflow Fixed)
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
                    child: _buildDropdown<String>(
                      label: 'State',
                      value: _selectedState,
                      icon: Icons.map,
                      items: indianStates,
                      onChanged: (val) => setState(() => _selectedState = val ?? _selectedState),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _cityController,
                label: 'City / Base Region',
                hint: 'e.g. Sankri / Uttarkashi',
                icon: Icons.location_city,
              ),
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
              // NO OVERFLOW LAYOUT
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Price / Person (₹)',
                      hint: '1500',
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
                            // Adjust days list length to match dropdown
                            while (_days.length < val) {
                              _days.add(ItineraryDay(dayNumber: _days.length + 1, dayTitle: '', accommodation: '', activities: []));
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
              _buildSectionHeader('Overview & Gallery Photos', Icons.collections),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _descController,
                label: 'Itinerary Description',
                hint: 'Describe the journey highlights, scenery, trail difficulty & culture...',
                icon: Icons.description,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              
              // Upload Buttons: Storage Upload vs URL input
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
                            errorBuilder: (_, _, _) => Container(
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
  // STEP 2: DAY SCHEDULE & INTERACTIVE ROUTE MAP (Clean Hint Inputs, Dynamic Days)
  // ---------------------------------------------------------------------------
  Widget _buildStep2ItineraryAndMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Day-by-Day Schedule', Icons.calendar_today),
        const SizedBox(height: 6),
        const Text('Add daily title, lodging & activity items. Start with Day 1 and add days as needed.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 14),

        // List of Day Cards
        Column(
          children: List.generate(_days.length, (idx) {
            final day = _days[idx];
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cyanAccent.withOpacity(0.4))),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: navyBlue, borderRadius: BorderRadius.circular(6)),
                          child: Text('DAY ${day.dayNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                      initialValue: day.dayTitle,
                      label: 'Day Title',
                      hint: 'e.g. Day ${day.dayNumber}: Arrival & Trek Kickoff',
                      icon: Icons.today,
                      onChanged: (val) => _days[idx] = _copyDay(day, title: val),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      initialValue: day.accommodation,
                      label: 'Lodging / Accommodation Name',
                      hint: 'e.g. Mountain Homestay / Swiss Tents',
                      icon: Icons.hotel,
                      onChanged: (val) => _days[idx] = _copyDay(day, acc: val),
                    ),
                    const SizedBox(height: 14),

                    // Activities Timeline
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Activity Timeline:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: navyBlue)),
                        Text('${day.activities.length} Slots', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (day.activities.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(color: softPageBg, borderRadius: BorderRadius.circular(8)),
                        child: const Text('No activity slots added yet. Tap button below to add activity timing.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: day.activities.length,
                        itemBuilder: (ctx, actIdx) {
                          final act = day.activities[actIdx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => _selectActivityTime(context, idx, actIdx),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: cyanLightBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: navyBlue.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.access_time_filled, size: 14, color: navyBlue),
                                        const SizedBox(width: 6),
                                        Text(
                                          act.time.isNotEmpty ? act.time : 'Set Time ⏰',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: navyBlue),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: act.activityTitle,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMain),
                                    decoration: InputDecoration(
                                      hintText: 'Describe activity...',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    onChanged: (val) {
                                      day.activities[actIdx] = TimelineItem(time: act.time, activityTitle: val);
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.brandRed, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      day.activities.removeAt(actIdx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 16, color: navyBlue),
                      label: const Text('Add Activity Slot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: navyBlue)),
                      onPressed: () {
                        setState(() {
                          day.activities.add(TimelineItem(time: '09:00 AM', activityTitle: ''));
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ),

        // Add Day Button
        OutlinedButton.icon(
          onPressed: _addNextDay,
          icon: const Icon(Icons.add, color: navyBlue),
          label: Text('Add Day ${_days.length + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: navyBlue)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            side: const BorderSide(color: navyBlue, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('Interactive Route Builder (Map)', Icons.add_location_alt),
        const SizedBox(height: 6),
        const Text('Tap on map below to place route pins (Start, Stops & Highlights).', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 10),
        Container(
          height: 240,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: navyBlue, width: 1.5),
          ),
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(30.3165, 78.0322),
                  zoom: 9,
                ),
                onMapCreated: (controller) => _mapController = controller,
                onTap: (latLng) {
                  setState(() {
                    _routePins.add(
                      RoutePin(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: 'Pin ${_routePins.length + 1}',
                        type: _routePins.isEmpty ? 'start' : 'stop',
                        lat: latLng.latitude,
                        lng: latLng.longitude,
                      ),
                    );
                  });
                  _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
                },
                markers: _routePins
                    .map(
                      (p) => Marker(
                        markerId: MarkerId(p.id),
                        position: LatLng(p.lat, p.lng),
                        infoWindow: InfoWindow(title: p.name),
                      ),
                    )
                    .toSet(),
                polylines: {
                  if (_routePins.length > 1)
                    Polyline(
                      polylineId: const PolylineId('route_line'),
                      points: _routePins.map((p) => LatLng(p.lat, p.lng)).toList(),
                      color: navyBlue,
                      width: 4,
                    ),
                },
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(6)),
                  child: const Text('💡 Tap map to drop pins', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: navyBlue)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Pins Placed: ${_routePins.length}', style: const TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 13)),
            const Spacer(),
            if (_routePins.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _routePins.clear()),
                child: const Text('Clear Pins', style: TextStyle(color: AppColors.brandRed, fontSize: 12)),
              ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: LOGISTICS, INCLUSIONS & PUBLISH
  // ---------------------------------------------------------------------------
  Widget _buildStep3LogisticsAndPublish() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Inclusions & Exclusions', Icons.checklist_rtl),
              const SizedBox(height: 14),
              const Text('Inclusions (Included in trip package)', style: TextStyle(color: AppColors.brandGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _inclusionInputController,
                      label: 'Add Inclusion',
                      hint: 'e.g. Meals, Permits, Guide Fee',
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.brandGreen, size: 32),
                    onPressed: () {
                      if (_inclusionInputController.text.trim().isNotEmpty) {
                        setState(() {
                          _inclusions.add(_inclusionInputController.text.trim());
                          _inclusionInputController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _inclusions
                    .map((inc) => Chip(
                          backgroundColor: const Color(0xFFDCFCE7),
                          label: Text(inc, style: const TextStyle(fontSize: 12, color: Color(0xFF15803D))),
                          deleteIcon: const Icon(Icons.cancel, size: 14, color: Color(0xFF15803D)),
                          onDeleted: () => setState(() => _inclusions.remove(inc)),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 16),
              const Text('Exclusions (Not included in trip package)', style: TextStyle(color: AppColors.brandRed, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _exclusionInputController,
                      label: 'Add Exclusion',
                      hint: 'e.g. Personal Expenses, Insurance',
                      icon: Icons.highlight_off,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.brandRed, size: 32),
                    onPressed: () {
                      if (_exclusionInputController.text.trim().isNotEmpty) {
                        setState(() {
                          _exclusions.add(_exclusionInputController.text.trim());
                          _exclusionInputController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _exclusions
                    .map((exc) => Chip(
                          backgroundColor: const Color(0xFFFEE2E2),
                          label: Text(exc, style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
                          deleteIcon: const Icon(Icons.cancel, size: 14, color: Color(0xFFB91C1C)),
                          onDeleted: () => setState(() => _exclusions.remove(exc)),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        _buildCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Logistics & Meeting Spot', Icons.place),
              const SizedBox(height: 14),
              GooglePlaceAutoCompleteTextField(
                textEditingController: _meetingPointController,
                googleAPIKey: "YOUR_GOOGLE_MAPS_API_KEY",
                inputDecoration: InputDecoration(
                  labelText: 'Meeting Point Address / Pickup Spot (Uber Places Autocomplete)',
                  hintText: 'Type location... e.g. Dehradun Railway Station Gate 1',
                  prefixIcon: const Icon(Icons.place, color: navyBlue),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: navyBlue, width: 2)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                debounceTime: 600,
                countries: const ["in"],
                isScanText: false,
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  if (prediction.description != null && prediction.description!.isNotEmpty) {
                    setState(() {
                      _meetingPointController.text = prediction.description!;
                    });
                  }
                },
                itemClick: (Prediction prediction) {
                  if (prediction.description != null && prediction.description!.isNotEmpty) {
                    setState(() {
                      _meetingPointController.text = prediction.description!;
                      _meetingPointController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _meetingPointController.text.length),
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _packingInputController,
                      label: 'Add Packing Item',
                      hint: 'e.g. Waterproof Jacket, Thermals',
                      icon: Icons.backpack,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: navyBlue, size: 32),
                    onPressed: () {
                      final item = _packingInputController.text.trim();
                      if (item.isNotEmpty) {
                        setState(() {
                          _thingsToCarry.add(item);
                          _packingInputController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _thingsToCarry
                    .map((item) => Chip(
                          backgroundColor: cyanLightBg,
                          label: Text(item, style: const TextStyle(fontSize: 12, color: navyBlue)),
                          deleteIcon: const Icon(Icons.cancel, size: 14, color: navyBlue),
                          onDeleted: () => setState(() => _thingsToCarry.remove(item)),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
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
                    Text('Location: ${_cityController.text}, $_selectedState', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    Text('Duration: $_durationDays Days / $_durationNights Nights · Price: ₹${_priceController.text}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
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
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))
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

  ItineraryDay _copyDay(ItineraryDay d, {String? title, String? acc, String? mapsUrl}) {
    return ItineraryDay(
      dayNumber: d.dayNumber,
      dayTitle: title ?? d.dayTitle,
      accommodation: acc ?? d.accommodation,
      accommodationPlaceId: d.accommodationPlaceId,
      accommodationMapsUrl: mapsUrl ?? d.accommodationMapsUrl,
      activities: d.activities,
      highlights: d.highlights,
      routePins: d.routePins,
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
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
}
