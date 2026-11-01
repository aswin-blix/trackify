import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/glass_card.dart';
import 'firebase_bootstrap.dart';
import 'household_models.dart';
import 'household_service.dart';
import 'household_sync.dart';

/// Sign in, create or join a household, see members and the invite code.
class HouseholdScreen extends ConsumerStatefulWidget {
  const HouseholdScreen({super.key});

  @override
  ConsumerState<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends ConsumerState<HouseholdScreen> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (success != null) _toast(success);
    } on HouseholdException catch (e) {
      _toast(e.message);
    } catch (e, s) {
      AppLogger.e('HouseholdScreen', 'Action failed', e, s);
      _toast('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8365D)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Text(
                    'Shared Tracking',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (!FirebaseBootstrap.available) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        physics: const BouncingScrollPhysics(),
        children: [
          _Card(
            title: 'Not available in this build',
            icon: Icons.cloud_off_rounded,
            color: const Color(0xFF636E72),
            child: Text(
              'Shared tracking needs a Firebase project. Add '
              'android/app/google-services.json and rebuild the app. '
              'See docs/SHARED_TRACKING_SETUP.md for the steps.\n\n'
              'Everything else in $kAppName keeps working offline.',
              style: _bodyStyle(context),
            ),
          ),
        ],
      );
    }

    final auth = ref.watch(authUserProvider);
    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Auth error: $e')),
      data: (user) =>
          user == null ? _signedOut(context) : _signedIn(context, user),
    );
  }

  // ─── Signed out ────────────────────────────────────────────────────────────

  Widget _signedOut(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        _Card(
          title: 'Track together',
          icon: Icons.people_alt_rounded,
          color: const Color(0xFF6C63FF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bullet('One household, one shared ledger and budget.'),
              _Bullet(
                  'Both of you add expenses from your own phones. Every entry shows who added it.'),
              _Bullet('Works offline. Changes sync when you are back online.'),
              _Bullet(
                  'Only transactions, categories and the budget are shared. Receipts and bank SMS never leave this phone.'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(
                            () async {
                              await ref
                                  .read(householdServiceProvider)
                                  .signInWithGoogle();
                            },
                            success: 'Signed in',
                          ),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.login_rounded),
                  label: const Text('Continue with Google'),
                ),
              ),
            ],
          ),
        ).animate(delay: 60.ms).fadeIn(duration: 350.ms),
      ],
    );
  }

  // ─── Signed in ─────────────────────────────────────────────────────────────

  Widget _signedIn(BuildContext context, User user) {
    final settings = ref.watch(settingsProvider);
    final children = <Widget>[
      _AccountCard(
        user: user,
        busy: _busy,
        onSignOut: () async {
          final inHousehold = settings.householdId != null;
          if (inHousehold &&
              !await _confirm(
                'Sign out?',
                'This phone stops syncing with the household until you sign in again. Your data stays on the phone.',
                'Sign out',
              )) {
            return;
          }
          await _run(
            () => ref.read(householdServiceProvider).signOut(),
            success: 'Signed out',
          );
        },
      ).animate(delay: 40.ms).fadeIn(duration: 350.ms),
      const SizedBox(height: 16),
    ];

    if (settings.householdId == null) {
      children.addAll(_noHousehold(context));
    } else {
      children.addAll(_inHousehold(context, user));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      physics: const BouncingScrollPhysics(),
      children: children,
    );
  }

  List<Widget> _noHousehold(BuildContext context) {
    return [
      _Card(
        title: 'Start a household',
        icon: Icons.home_rounded,
        color: const Color(0xFF00B87C),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your existing entries on this phone become the shared ledger. You get a code to invite your partner.',
              style: _bodyStyle(context),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Household name',
                hintText: 'e.g. Home',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(
                          () async {
                            await ref
                                .read(householdServiceProvider)
                                .createHousehold(_nameCtrl.text);
                          },
                          success: 'Household created',
                        ),
                icon: const Icon(Icons.add_home_rounded),
                label: const Text('Create household'),
              ),
            ),
          ],
        ),
      ).animate(delay: 80.ms).fadeIn(duration: 350.ms),
      const SizedBox(height: 16),
      _Card(
        title: 'Join with a code',
        icon: Icons.key_rounded,
        color: const Color(0xFFFF8E53),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the 6-character code from your partner. Entries already on this phone are added to the shared ledger.',
              style: _bodyStyle(context),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\- ]')),
              ],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
              decoration: const InputDecoration(
                labelText: 'Invite code',
                hintText: 'ABC123',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(
                          () async {
                            await ref
                                .read(householdServiceProvider)
                                .joinHousehold(_codeCtrl.text);
                            _codeCtrl.clear();
                          },
                          success: 'Joined household',
                        ),
                icon: const Icon(Icons.group_add_rounded),
                label: const Text('Join household'),
              ),
            ),
          ],
        ),
      ).animate(delay: 120.ms).fadeIn(duration: 350.ms),
    ];
  }

  List<Widget> _inHousehold(BuildContext context, User user) {
    final hhAsync = ref.watch(householdProvider);
    final hh = hhAsync.value;
    final sync = ref.read(householdSyncProvider);

    if (hh == null) {
      return [
        _Card(
          title: 'Loading household…',
          icon: Icons.sync_rounded,
          color: const Color(0xFF0984E3),
          child: hhAsync.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Text(
                  'The household could not be loaded. Check your connection, or leave and join again.',
                  style: _bodyStyle(context),
                ),
        ),
        const SizedBox(height: 16),
        _leaveButton(context),
      ];
    }

    return [
      _Card(
        title: hh.name,
        icon: Icons.home_rounded,
        color: const Color(0xFF00B87C),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invite code', style: _bodyStyle(context)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    hh.inviteCode,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: hh.inviteCode));
                    _toast('Code copied');
                  },
                ),
                IconButton(
                  tooltip: 'Share',
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () => SharePlus.instance.share(ShareParams(
                    text:
                        'Join my $kAppName household "${hh.name}" with code ${hh.inviteCode}. '
                        'Open $kAppName → Settings → Shared Tracking → Join with a code.',
                  )),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Anyone with this code can join and see the shared ledger. Share it only with your partner.',
              style: _bodyStyle(context),
            ),
            const SizedBox(height: 12),
            StreamBuilder<SyncStatus>(
              stream: sync.statusStream,
              initialData: sync.status,
              builder: (ctx, snap) =>
                  _SyncLine(status: snap.data ?? sync.status),
            ),
          ],
        ),
      ).animate(delay: 80.ms).fadeIn(duration: 350.ms),
      const SizedBox(height: 16),
      _Card(
        title: 'Members',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF6C63FF),
        child: Column(
          children: [
            for (final m in hh.members)
              _MemberRow(
                member: m,
                isYou: m.uid == user.uid,
                isOwner: m.uid == hh.ownerUid,
              ),
            if (!hh.isShared)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Waiting for your partner to join with the code above.',
                  style: _bodyStyle(context),
                ),
              ),
          ],
        ),
      ).animate(delay: 120.ms).fadeIn(duration: 350.ms),
      const SizedBox(height: 16),
      _Card(
        title: 'What is shared',
        icon: Icons.privacy_tip_rounded,
        color: const Color(0xFF0984E3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Bullet(
                'Transactions, categories, currency and the monthly budget.'),
            _Bullet(
                'Not shared: receipt photos, bank SMS, app lock, reminders.'),
            _Bullet('Either member can edit or delete any entry.'),
          ],
        ),
      ).animate(delay: 160.ms).fadeIn(duration: 350.ms),
      const SizedBox(height: 16),
      _leaveButton(context),
    ];
  }

  Widget _leaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE8365D),
          side: const BorderSide(color: Color(0xFFE8365D)),
        ),
        onPressed: _busy
            ? null
            : () async {
                if (!await _confirm(
                  'Leave household?',
                  'This phone keeps a copy of everything so far but stops sharing new entries. Your partner keeps the shared ledger.',
                  'Leave',
                )) {
                  return;
                }
                await _run(
                  () => ref.read(householdServiceProvider).leaveHousehold(),
                  success: 'Left household',
                );
              },
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Leave household'),
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 350.ms);
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

TextStyle _bodyStyle(BuildContext context) => GoogleFonts.plusJakartaSans(
      fontSize: 13,
      height: 1.4,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
    );

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _Card({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: _bodyStyle(context))),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final User user;
  final bool busy;
  final VoidCallback onSignOut;

  const _AccountCard({
    required this.user,
    required this.busy,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : 'Google account';
    final photo = user.photoURL;
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            child: photo == null
                ? Icon(Icons.person_rounded,
                    color: Theme.of(context).colorScheme.primary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                if (user.email != null)
                  Text(
                    user.email!,
                    style: _bodyStyle(context),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: busy ? null : onSignOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final HouseholdMember member;
  final bool isYou;
  final bool isOwner;

  const _MemberRow({
    required this.member,
    required this.isYou,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final photo = member.photoUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primary.withValues(alpha: 0.15),
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            child: photo == null
                ? Text(member.initial,
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, color: primary))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.name,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          if (isOwner) _Chip('Owner', const Color(0xFFFF8E53)),
          if (isYou) ...[
            const SizedBox(width: 6),
            _Chip('You', primary),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _SyncLine extends StatelessWidget {
  final SyncStatus status;

  const _SyncLine({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      SyncStatus.live => (
          'Live · syncing',
          const Color(0xFF00B87C),
          Icons.cloud_done_rounded
        ),
      SyncStatus.connecting => (
          'Connecting… changes sync when online',
          const Color(0xFF0984E3),
          Icons.cloud_sync_rounded
        ),
      SyncStatus.error => (
          'Sync problem · will retry',
          const Color(0xFFE8365D),
          Icons.cloud_off_rounded
        ),
      SyncStatus.off => (
          'Sync paused',
          const Color(0xFF636E72),
          Icons.cloud_off_rounded
        ),
    };
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
