import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/wishlist_model.dart';
import '../../repositories/wishlist_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/spring_interactions.dart';
import '../../widgets/travel_pattern_background.dart';
import 'experience_detail_modal.dart';
import '../../repositories/experience_repository.dart';

class TravellerWishlistTab extends StatelessWidget {
  const TravellerWishlistTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final wishlistRepo = WishlistRepository();
    final expRepo = ExperienceRepository();

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          backgroundColor: AppColors.travellerForestDark,
          title: const Text('MY SAVED JOURNEYS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.favorite_border, size: 64, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text('Please log in to view your wishlist', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.travellerForestDark,
        title: const Text('MY SAVED JOURNEYS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        elevation: 0,
      ),
      body: TravelPatternBackground(
        child: StreamBuilder<List<WishlistModel>>(
          stream: wishlistRepo.getUserWishlistStream(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.travellerForestDark));
            }

            final wishlists = snapshot.data ?? [];

            if (wishlists.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.travellerLightMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_outline, size: 48, color: AppColors.travellerForestDark),
                    ),
                    const SizedBox(height: 16),
                    const Text('Your Wishlist is Empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                    const SizedBox(height: 8),
                    const Text('Save your favorite expedition itineraries to view them later.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              );
            }

          return ListView.builder(
            physics: bespokeBouncingScrollPhysics,
            padding: const EdgeInsets.all(16),
            itemCount: wishlists.length,
            itemBuilder: (context, index) {
              final item = wishlists[index];
              return SpringCard(
                scaleDown: 0.98,
                borderRadius: 16,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12.0),
                border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.7)),
                onTap: () async {
                  final exp = await expRepo.getExperienceById(item.experienceId);
                  if (exp != null && context.mounted) {
                    ExperienceDetailModal.show(context, exp);
                  }
                },
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl.isNotEmpty ? item.imageUrl : 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(width: 80, height: 80, color: AppColors.travellerForestDark.withValues(alpha: 0.1)),
                        errorWidget: (_, _, _) => Container(width: 80, height: 80, color: AppColors.travellerForestDark),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.experienceTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.travellerForestDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (item.location.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.place, size: 12, color: AppColors.brandOrange),
                                const SizedBox(width: 4),
                                Text(item.location, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          const SizedBox(height: 6),
                          Text('₹${item.price.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brandGreen)),
                        ],
                      ),
                    ),
                    SpringTapFeedback(
                      scaleDown: 0.85,
                      onTap: () {
                        wishlistRepo.removeFromWishlist(item.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, color: Colors.red, size: 20),
                      ),
                    ),
                  ],
                ),
              ).staggeredEntrance(index: index);
            },
          );
        },
      ),
    ),
  );
}

}
