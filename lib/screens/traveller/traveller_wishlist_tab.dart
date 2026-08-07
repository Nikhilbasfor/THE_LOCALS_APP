import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/wishlist_model.dart';
import '../../repositories/wishlist_repository.dart';
import '../../theme/app_colors.dart';
import 'experience_detail_screen.dart';
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
      body: StreamBuilder<List<WishlistModel>>(
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
                  const Text('Save your favorite Himalayan itineraries to view them later.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: wishlists.length,
            itemBuilder: (context, index) {
              final item = wishlists[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () async {
                    final exp = await expRepo.getExperienceById(item.experienceId);
                    if (exp != null && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ExperienceDetailScreen(experience: exp)),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.imageUrl.isNotEmpty ? item.imageUrl : 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(width: 80, height: 80, color: AppColors.travellerForestDark),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.experienceTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              if (item.location.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.place, size: 12, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(item.location, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              const SizedBox(height: 6),
                              Text('₹${item.price.toInt()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () {
                            wishlistRepo.removeFromWishlist(item.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
