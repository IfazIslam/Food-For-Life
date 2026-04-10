import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _changeName(String uid, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.primaryGreen,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Update Full Name',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter new name',
                  filled: true,
                  fillColor: const Color(0xFFF5F7F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.badge_outlined,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (ctrl.text.trim().isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update({'name': ctrl.text.trim()});
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Update Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    final ctrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: AppTheme.primaryGreen,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'New password (min 6 chars)',
                  filled: true,
                  fillColor: const Color(0xFFF5F7F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.password_outlined,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (ctrl.text.trim().length >= 6) {
                      try {
                        await FirebaseAuth.instance.currentUser?.updatePassword(
                          ctrl.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Password updated successfully"),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted)
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  child: const Text(
                    'Update Password',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeLocation(String uid, String currentState) async {
    final ctrl = TextEditingController(text: currentState);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.primaryGreen,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Update Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Changing your location will update which food donations you see in your feed.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter your State/City (e.g. New York)',
                  filled: true,
                  fillColor: const Color(0xFFF5F7F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.map_outlined,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (ctrl.text.trim().isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update({'addressState': ctrl.text.trim()});
                      if (context.mounted) Navigator.pop(context);
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Location updated! Your feed will now show local donations.",
                            ),
                          ),
                        );
                    }
                  },
                  child: const Text(
                    'Save Location',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text("Not logged in"));

          return CustomScrollView(
            slivers: [
              // ── Modern Header ────────────────────────────────────
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: const Color(0xFF2E7D52),
                title: const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1B5E3B), Color(0xFF57AB74)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          const Icon(
                            Icons.settings_suggest_rounded,
                            color: Colors.white24,
                            size: 60,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),

                  _buildSectionTitle("ACCOUNT"),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.person_rounded,
                        title: "Change Full Name",
                        subtitle: user.name,
                        onTap: () => _changeName(user.uid, user.name),
                      ),
                      _SettingsTile(
                        icon: Icons.location_on_rounded,
                        title: "Change Location",
                        subtitle: user.addressState,
                        onTap: () =>
                            _changeLocation(user.uid, user.addressState),
                      ),
                      _SettingsTile(
                        icon: Icons.lock_rounded,
                        title: "Update Password",
                        subtitle: "Change your account access",
                        onTap: _changePassword,
                      ),
                    ],
                  ),

                  _buildSectionTitle("PREFERENCES & INFO"),
                  _SettingsCard(
                    children: [
                      const _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: "App Version",
                        subtitle: "1.0.1 (Stable)",
                        showChevron: false,
                      ),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        title: "Terms & Privacy",
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.share_rounded,
                        title: "Tell a Friend",
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _SettingsCard(
                    color: Colors.red.shade50,
                    children: [
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        iconColor: Colors.red,
                        textColor: Colors.red,
                        title: "Logout Account",
                        showChevron: false,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Logout"),
                              content: const Text(
                                "Are you sure you want to sign out?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Stay"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Logout"),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            // Mark offline BEFORE signing out
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid != null) {
                              await FirebaseFirestore.instance.collection('users').doc(uid).update({
                                'isOnline': false,
                                'lastSeen': FieldValue.serverTimestamp(),
                              });
                            }
                            await FirebaseAuth.instance.signOut();
                            if (mounted) context.go('/login');
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      "Made with ❤️ for Food for Life",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (e, s) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final Color? color;
  const _SettingsCard({required this.children, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color? textColor;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor = AppTheme.primaryGreen,
    this.textColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: textColor ?? AppTheme.textMain,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12))
          : null,
      trailing: showChevron
          ? const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.grey,
            )
          : null,
      onTap: onTap,
    );
  }
}
