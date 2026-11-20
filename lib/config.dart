/// App-wide configuration.
///
/// The API base URL can be overridden at build time, e.g. to point at a local server:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
library;

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://cartzy-ecommerce-backend.onrender.com/api',
);

const String appName = 'Cartzy';

/// Public demo shopper seeded on the API (shopper role only; its password can't be changed).
const String demoEmail = 'demo@cartzy.app';
const String demoPassword = 'demo1234';
