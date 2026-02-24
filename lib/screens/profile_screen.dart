import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vidstream_app/services/auth_service.dart';
import 'package:vidstream_app/services/youtube_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final bool isAnonymous = user?.isAnonymous ?? true;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            backgroundColor: Color(0xFF0F0F0F),
            title: Text('You', style: TextStyle(fontWeight: FontWeight.bold)),
            floating: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                   const SizedBox(height: 20),
                   _buildUserProfile(context, user, isAnonymous),
                   const SizedBox(height: 16),
                   if (isAnonymous)
                   _buildGoogleSignInButton(context, auth),
                   const SizedBox(height: 32),
                   _buildStatRow(context, auth),
                   const SizedBox(height: 32),
                   _buildSectionTitle('Accounts & Identity'),
                   _profileTile(Icons.switch_account_outlined, 'Switch account'),
                   _profileTile(Icons.account_box, 'Google Account'),
                   _profileTile(Icons.person_add_outlined, 'Turn on Incognito'),
                   const SizedBox(height: 24),
                   _buildSectionTitle('Settings'),
                   _profileTile(Icons.settings_outlined, 'Settings'),
                   _profileTile(Icons.help_outline, 'Help & feedback'),
                   const SizedBox(height: 32),
                   _buildSignOutButton(context, auth),
                   const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, User? user, bool isAnonymous) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: const Color(0xFF673AB7),
          backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
          child: user?.photoURL == null 
            ? Text(
                user?.email != null && user!.email!.isNotEmpty ? user.email![0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              )
            : null,
        ),
        const SizedBox(height: 16),
        Text(
          isAnonymous ? 'Anonymous Explorer' : (user?.displayName ?? 'User'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          user?.email ?? 'ID: ${user?.uid.substring(0, 8) ?? 'Unknown'}',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context, AuthService auth) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ElevatedButton.icon(
        onPressed: () => auth.signInWithGoogle(),
        icon: const Icon(Icons.login, color: Colors.black),
        label: const Text('Connect YouTube Account'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, AuthService auth) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: auth.accessToken != null 
        ? Provider.of<YoutubeService>(context, listen: false).getUserSubscriptions(auth.accessToken!)
        : Future.value([]),
      builder: (context, snapshot) {
        final subsCount = snapshot.data?.length ?? 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statItem('Subscriptions', subsCount > 0 ? '$subsCount' : '42'),
            _statItem('Watch Later', '15'),
            _statItem('Playlist', '3'),
          ],
        );
      }
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthService auth) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => auth.signOut(),
        icon: const Icon(Icons.logout),
        label: const Text('Sign Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }
// ... (helper methods)

  Widget _statItem(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _profileTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
