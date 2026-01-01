import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileMenuDrawer extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final ValueChanged<String> onMenuItemTapped;

  const ProfileMenuDrawer({
    super.key,
    required this.onClose,
    required this.onMenuItemTapped,
  });

  @override
  ConsumerState<ProfileMenuDrawer> createState() => _ProfileMenuDrawerState();
}

class _ProfileMenuDrawerState extends ConsumerState<ProfileMenuDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeMenu() async {
    await _animationController.reverse();
    widget.onClose();
  }

  void _handleMenuItemTap(String route) {
    _closeMenu();
    Future.delayed(const Duration(milliseconds: 200), () {
      widget.onMenuItemTapped(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = screenWidth * 0.75;

    return GestureDetector(
      onTap: _closeMenu,
      child: Stack(
        children: [
          // Dimmed background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  color: Colors.black.withOpacity(0.5 * _animationController.value),
                );
              },
            ),
          ),

          // Right-side menu panel
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: menuWidth,
            child: SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping inside menu
                child: Container(
                  color: Colors.white,
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Close button
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.black),
                            onPressed: _closeMenu,
                          ),
                        ),

                        // Profile header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.grey[300],
                                child: const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'ShapeOurSpace',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Contractor',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Menu items
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _MenuItemTile(
                                  icon: Icons.dashboard_outlined,
                                  label: 'Contractor Dashboard',
                                  onTap: () => _handleMenuItemTap('contractor_dashboard'),
                                ),
                                _MenuItemTile(
                                  icon: Icons.home_work_outlined,
                                  label: 'Turnkey Dashboard',
                                  onTap: () => _handleMenuItemTap('turnkey_dashboard'),
                                ),
                                _MenuItemTile(
                                  icon: Icons.check_circle_outline,
                                  label: 'Successful Bids',
                                  onTap: () => _handleMenuItemTap('successful_bids'),
                                ),
                                _MenuItemTile(
                                  icon: Icons.track_changes_outlined,
                                  label: 'Track Project',
                                  onTap: () => _handleMenuItemTap('track_project'),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(
                            color: Colors.grey[300],
                            height: 24,
                            thickness: 1,
                          ),
                        ),

                        // Logout button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _MenuItemTile(
                            icon: Icons.logout,
                            label: 'Log out',
                            isLogout: true,
                            onTap: () => _handleMenuItemTap('logout'),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLogout;

  const _MenuItemTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.red : Colors.black87,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isLogout ? Colors.red : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
