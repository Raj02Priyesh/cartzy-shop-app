import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'core/api_client.dart';
import 'screens/main_shell.dart';
import 'services/catalog_service.dart';
import 'services/order_service.dart';
import 'state/auth_provider.dart';
import 'state/cart_provider.dart';
import 'state/wishlist_provider.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  final auth = AuthProvider(api)..restore();
  runApp(CartzyApp(api: api, auth: auth));
}

class CartzyApp extends StatelessWidget {
  const CartzyApp({super.key, required this.api, required this.auth});

  final ApiClient api;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: api),
        Provider(create: (_) => CatalogService(api)),
        Provider(create: (_) => OrderService(api)),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(api),
          update: (_, auth, cart) => cart!..onAuthChanged(auth.isLoggedIn),
        ),
        ChangeNotifierProxyProvider<AuthProvider, WishlistProvider>(
          create: (_) => WishlistProvider(api),
          update: (_, auth, wishlist) => wishlist!..onAuthChanged(auth.isLoggedIn),
        ),
      ],
      child: MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const MainShell(),
      ),
    );
  }
}
