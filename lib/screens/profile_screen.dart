import 'dart:ui';
import 'package:flutter/material.dart';
import '../config.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(top: -80, left: -40, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFD4AF37).withValues(alpha: 0.12), Colors.transparent])))),
          Positioned(bottom: -60, right: -60, child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFE8C547).withValues(alpha: 0.08), Colors.transparent])))),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text('My Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFF5F0E8), letterSpacing: -0.5)),
                const SizedBox(height: 6),
                const Text('Manage your personal information and account settings.', style: TextStyle(fontSize: 14, color: Color(0xFFB0A890), height: 1.4)),
                const SizedBox(height: 28),
                _buildProfileHeader(),
                const SizedBox(height: 28),
                _buildStatsRow(),
                const SizedBox(height: 28),
                const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFF5F0E8))),
                const SizedBox(height: 14),
                _buildInfoCard(icon: Icons.email_rounded, title: 'Email Address', value: AppConfig.userEmail, color: const Color(0xFFD4AF37)),
                const SizedBox(height: 10),
                _buildInfoCard(icon: Icons.phone_rounded, title: 'Phone Number', value: AppConfig.userPhone, color: const Color(0xFFE8C547)),
                const SizedBox(height: 28),
                const Text('Account Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFF5F0E8))),
                const SizedBox(height: 14),
                _buildSettingsCard(icon: Icons.notifications_none_rounded, title: 'Notifications', subtitle: 'Manage your notification preferences', color: const Color(0xFFE8C547), onTap: () => _showComingSoon(context, 'Notifications')),
                const SizedBox(height: 10),
                _buildSettingsCard(icon: Icons.privacy_tip_rounded, title: 'Privacy', subtitle: 'Control your data and privacy', color: const Color(0xFFF5E0A0), onTap: () => _showComingSoon(context, 'Privacy')),
                const SizedBox(height: 10),
                _buildSettingsCard(icon: Icons.security_rounded, title: 'Security', subtitle: 'Password and authentication', color: const Color(0xFF4299E1), onTap: () => _showComingSoon(context, 'Security')),
                const SizedBox(height: 32),
                _buildSignOutButton(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF141414).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.4))),
          child: Row(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFD4AF37), Color(0xFFE8C547)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8C547).withValues(alpha: 0.5), width: 2),
                ),
                child: const Center(child: Icon(Icons.person_rounded, size: 36, color: Colors.white)),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppConfig.userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFF5F0E8))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFD4AF37).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3))),
                      child: const Text('Active Account', style: TextStyle(fontSize: 11, color: Color(0xFFF5E0A0), fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF3A3020).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFFE8C547))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard('Reports', '0', Icons.description_rounded, const Color(0xFF4299E1)),
        const SizedBox(width: 10),
        _statCard('Models', '0', Icons.psychology_rounded, const Color(0xFFE8C547)),
        const SizedBox(width: 10),
        _statCard('Accuracy', '--', Icons.trending_up_rounded, const Color(0xFF4CAF50)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.15))),
            child: Column(
              children: [
                Icon(icon, size: 22, color: color.withValues(alpha: 0.8)),
                const SizedBox(height: 8),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value, required Color color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF141414).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.4))),
          child: Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withValues(alpha: 0.6)]), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 22, color: Colors.white)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFB0A890))),
                    const SizedBox(height: 4),
                    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFF5F0E8))),
                  ],
                ),
              ),
              Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.copy_rounded, size: 16, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF141414).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.4))),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withValues(alpha: 0.6)]), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 22, color: Colors.white)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFF5F0E8))),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFFB0A890))),
                    ],
                  ),
                ),
                Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext ctx) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFF4A1A1A).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF56565).withValues(alpha: 0.2))),
          child: TextButton.icon(
            onPressed: () => _showSignOutDialog(ctx),
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFF56565), size: 20),
            label: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFF56565))),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF141414),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFF3A3020), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.construction_rounded, size: 28, color: Color(0xFFE8C547))),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF5F0E8))),
            const SizedBox(height: 8),
            const Text('This feature is coming soon.', style: TextStyle(color: Color(0xFFB0A890), fontSize: 14)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
                child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF141414),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFF4A1A1A), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.logout_rounded, size: 28, color: Color(0xFFF56565))),
            const SizedBox(height: 16),
            const Text('Sign Out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF5F0E8))),
            const SizedBox(height: 8),
            const Text('Are you sure you want to sign out?', style: TextStyle(color: Color(0xFFB0A890), fontSize: 14)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out successfully'), backgroundColor: Color(0xFFD4AF37), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))), duration: Duration(seconds: 2)),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF56565), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
                child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFB0A890))),
            ),
          ],
        ),
      ),
    );
  }
}
