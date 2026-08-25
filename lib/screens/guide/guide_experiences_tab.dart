import 'package:flutter/material.dart';
import '../../models/experience_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/experience_repository.dart';
import '../../theme/app_colors.dart';
import 'create_edit_itinerary_screen.dart';
import 'guide_experience_bookings_screen.dart';

class GuideExperiencesTab extends StatefulWidget {
  const GuideExperiencesTab({super.key});

  @override
  State<GuideExperiencesTab> createState() => _GuideExperiencesTabState();
}

class _GuideExperiencesTabState extends State<GuideExperiencesTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ExperienceRepository _expRepo = ExperienceRepository();
  final AuthRepository _authRepo = AuthRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authRepo.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Center(child: Text('Please sign in as guide.', style: TextStyle(color: AppColors.textMain))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: StreamBuilder<List<ExperienceModel>>(
        stream: _expRepo.getGuideExperiencesStream(user.uid, user.email),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.headerNavy));
          }

          final allExps = snapshot.data ?? [];
          final pendingExps = allExps.where((e) {
            final s = e.status.toLowerCase().trim();
            return s == 'pending' || s == 'changes_requested' || s.isEmpty;
          }).toList();
          final approvedExps = allExps.where((e) {
            final s = e.status.toLowerCase().trim();
            return s == 'approved' || s == 'published' || s == 'active';
          }).toList();
          final rejectedExps = allExps.where((e) {
            final s = e.status.toLowerCase().trim();
            return s == 'rejected' || s == 'revoked';
          }).toList();

          return Column(
            children: [
              // Tab Header
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.headerNavy,
                  labelColor: AppColors.headerNavy,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  tabs: [
                    Tab(text: 'APPROVED (${approvedExps.length})'),
                    Tab(text: 'REQUESTED (${pendingExps.length})'),
                    Tab(text: 'REJECTED (${rejectedExps.length})'),
                  ],
                ),
              ),

              // Tab Body Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ItineraryList(
                      list: approvedExps,
                      emptyMessage: 'No approved itineraries published yet.',
                    ),
                    _ItineraryList(
                      list: pendingExps,
                      emptyMessage: 'No requested itineraries waiting for admin approval.',
                    ),
                    _ItineraryList(
                      list: rejectedExps,
                      emptyMessage: 'No rejected itineraries.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.headerNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Itinerary', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateEditItineraryScreen(),
            ),
          );
        },
      ),
    );
  }
}

class _ItineraryList extends StatelessWidget {
  final List<ExperienceModel> list;
  final String emptyMessage;

  const _ItineraryList({required this.list, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final exp = list[idx];
        final hasFeedback = exp.rejectionReason.trim().isNotEmpty || exp.status == 'changes_requested';

        return Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${exp.durationDays}D / ${exp.durationNights}N · ₹${exp.price.toInt()}',
                      style: const TextStyle(color: AppColors.headerNavy, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    _StatusBadge(status: exp.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  exp.title,
                  style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exp.city}, ${exp.state}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),

                if (hasFeedback) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber.shade900),
                            const SizedBox(width: 6),
                            Text(
                              exp.status == 'changes_requested' ? 'ADMIN REQUESTED CHANGES' : 'ADMIN FEEDBACK',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                        if (exp.rejectionReason.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            exp.rejectionReason,
                            style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.people, size: 16, color: AppColors.headerNavy),
                      label: const Text('Guests', style: TextStyle(color: AppColors.headerNavy, fontSize: 12)),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GuideExperienceBookingsScreen(experience: exp),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasFeedback ? Colors.amber.shade800 : AppColors.headerNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(
                        hasFeedback ? 'Edit & Resubmit' : 'Edit Itinerary',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateEditItineraryScreen(experience: exp),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.statusPendingBg;
    Color text = AppColors.statusPendingText;
    String label = status;

    if (status == 'approved' || status == 'published' || status == 'active') {
      bg = AppColors.statusApprovedBg;
      text = AppColors.statusApprovedText;
      label = 'APPROVED';
    } else if (status == 'changes_requested') {
      bg = Colors.amber.shade100;
      text = Colors.amber.shade900;
      label = 'CHANGES REQUESTED';
    } else if (status == 'rejected' || status == 'revoked') {
      bg = AppColors.statusRevokedBg;
      text = AppColors.statusRevokedText;
      label = 'REJECTED';
    } else {
      label = 'PENDING APPROVAL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
