import 'package:intl/intl.dart';

final _rupees = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _date = DateFormat('d MMM yyyy');
final _dateTime = DateFormat('d MMM yyyy, h:mm a');

String formatPrice(num value) => _rupees.format(value);
String formatDate(DateTime value) => _date.format(value.toLocal());
String formatDateTime(DateTime value) => _dateTime.format(value.toLocal());
