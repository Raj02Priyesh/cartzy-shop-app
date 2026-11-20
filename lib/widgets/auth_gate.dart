import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/auth_screen.dart';
import '../state/auth_provider.dart';

/// Returns true if the user is signed in, opening the sign-in screen first if needed.
Future<bool> ensureSignedIn(BuildContext context) async {
  if (context.read<AuthProvider>().isLoggedIn) return true;
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const AuthScreen(), fullscreenDialog: true),
  );
  return result == true;
}
