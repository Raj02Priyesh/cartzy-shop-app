import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../state/auth_provider.dart';
import '../widgets/common.dart';
import 'address_form_screen.dart';
import 'auth_screen.dart';
import 'orders_screen.dart';
import 'wishlist_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: ListView(
          children: [
            const SizedBox(height: 40),
            EmptyState(
              icon: Icons.account_circle_outlined,
              title: 'Sign in to $appName',
              message: 'Track orders, save addresses and keep your wishlist.',
              actionLabel: 'Sign in',
              onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen(), fullscreenDialog: true)),
            ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthScreen(startWithSignup: true), fullscreenDialog: true),
                ),
                child: const Text('New here? Create an account'),
              ),
            ),
            const SizedBox(height: 24),
            const _AboutTile(),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                      style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text(user.email, style: theme.textTheme.bodySmall),
                        if (user.phone != null && user.phone!.isNotEmpty) Text('+91 ${user.phone}', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(tooltip: 'Edit profile', icon: const Icon(Icons.edit_outlined), onPressed: () => _editProfile(context)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('My orders'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: const Text('Wishlist'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WishlistScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Saved addresses'),
                  subtitle: Text('${auth.addresses.length} saved'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _AddressesScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _AboutTile(),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final name = TextEditingController(text: auth.user?.name);
    final phone = TextEditingController(text: auth.user?.phone);
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profile'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(labelText: 'Mobile number', prefixText: '+91 ', counterText: ''),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  return value.isEmpty || RegExp(r'^[6-9]\d{9}$').hasMatch(value) ? null : 'Enter a valid 10-digit number';
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) {
      try {
        await auth.updateProfile(name: name.text, phone: phone.text);
        if (context.mounted) showMessage(context, 'Profile updated');
      } catch (e) {
        if (context.mounted) showMessage(context, '$e');
      }
    }
    // The controllers are not disposed here: the dialog may still be animating closed.
  }
}

class _AddressesScreen extends StatelessWidget {
  const _AddressesScreen();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved addresses')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add address'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressFormScreen())),
      ),
      body: auth.addresses.isEmpty
          ? const EmptyState(icon: Icons.location_off_outlined, title: 'No saved addresses', message: 'Add one now to check out faster.')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: auth.addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = auth.addresses[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: Text(a.street),
                    subtitle: Text(a.oneLine),
                    trailing: a.id == null
                        ? null
                        : IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              try {
                                await context.read<AuthProvider>().removeAddress(a.id!);
                              } catch (e) {
                                if (context.mounted) showMessage(context, '$e');
                              }
                            },
                          ),
                  ),
                );
              },
            ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About this app'),
          subtitle: const Text('A Flutter demo store on a Node.js + MongoDB API'),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: appName,
            applicationVersion: '1.0.0',
            applicationIcon: Icon(Icons.shopping_bag_rounded, color: Theme.of(context).colorScheme.primary, size: 40),
            children: const [
              Text('A portfolio demo by Priyesh Raj. Products, prices and orders are sample data — no real payments are taken.'),
            ],
          ),
        ),
      );
}
