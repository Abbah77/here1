import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

// Feature Screens - Adjusted relative paths
import '../../../../features/chat/views/screens/chat_list_screen.dart';
import '../../../../features/feed/views/screens/feed_screen.dart';
import '../../../../features/profile/views/screens/profile_screen.dart';

// Core & Shared
import 'package:here/core/providers/theme_provider.dart';
import 'package:here/shared/widgets/sync_status_widget.dart';

class MainScreen extends HookConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hook: Controller for the PageView
    final pageController = usePageController();
    // Hook: Local state for active tab
    final currentIndex = useState(0);
    final theme = Theme.of(context);
    
    // Memoized list of screens to prevent unnecessary rebuilds
    final screens = useMemoized(() => [
      const FeedScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ]);

    return PopScope(
      // Allow pop only if on the first tab
      canPop: currentIndex.value == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentIndex.value != 0) {
          // If on another tab, back button returns to Feed
          pageController.animateToPage(
            0, 
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeInOut
          );
          currentIndex.value = 0;
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true, // Allows smooth content flow
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: theme.brightness == Brightness.dark 
                ? SystemUiOverlayStyle.light 
                : SystemUiOverlayStyle.dark,
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: SyncStatusWidget(),
              ),
            ], 
          ),
        ),
        body: PageView(
          controller: pageController,
          onPageChanged: (index) {
            currentIndex.value = index;
            // Native-feeling haptic feedback on swipe
            HapticFeedback.selectionClick();
          },
          children: screens,
        ),
        bottomNavigationBar: _buildBottomNavBar(
          context, 
          currentIndex.value, 
          pageController
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(
    BuildContext context, 
    int currentIndex, 
    PageController pageController,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.05),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavBarItem(
                icon: Icons.home_rounded,
                label: 'Feed',
                isSelected: currentIndex == 0,
                onTap: () => _animateToPage(pageController, 0),
              ),
              _NavBarItem(
                icon: Icons.chat_bubble_rounded,
                label: 'Chats',
                isSelected: currentIndex == 1,
                onTap: () => _animateToPage(pageController, 1),
              ),
              _NavBarItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: currentIndex == 2,
                onTap: () => _animateToPage(pageController, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _animateToPage(PageController controller, int page) {
    controller.animateToPage(
      page, 
      duration: const Duration(milliseconds: 400), 
      curve: Curves.elasticOut // Stylish modern bounce
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Ensures the whole area is tappable
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? activeColor : theme.iconTheme.color?.withOpacity(0.4),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}