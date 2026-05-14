// test/services/exchange_rate_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/models/exchange_rate.dart';


void main() {
  late ExchangeRateService service;

  setUp(() {
    service = ExchangeRateService();
  });

  group('ExchangeRateService Math Tests', () {
    setUp(() {
      // Seed the service with mock rates
      service.updateRates([
        ExchangeRate(code: 'EUR', rateToBase: 0.9, timestamp: DateTime.now()), // 1 USD = 0.9 EUR
        ExchangeRate(code: 'KES', rateToBase: 120.0, timestamp: DateTime.now()), // 1 USD = 120 KES
      ]);
    });

    test('convert returns original amount if codes are identical', () {
      expect(service.convert(amount: 100, fromCode: 'USD', toCode: 'USD'), 100);
    });

    test('convert correctly calculates EUR to KES', () {
      // Logic: 
      // 100 EUR -> USD (100 / 0.9 = 111.11 USD)
      // 111.11 USD -> KES (111.11 * 120 = 13,333.33)
      final result = service.convert(amount: 100, fromCode: 'EUR', toCode: 'KES');
      expect(result, closeTo(13333.33, 0.01));
    });

    test('toBase correctly converts KES to USD', () {
      // 120 KES -> 1 USD
      expect(service.toBase(120, 'KES'), 1.0);
    });

    test('fromBase correctly converts USD to EUR', () {
      // 1 USD -> 0.9 EUR
      expect(service.fromBase(1, 'EUR'), 0.9);
    });

    test('fallback returns original amount if rate is missing', () {
      // 'GBP' is not in our mock cache
      expect(service.toBase(100, 'GBP'), 100);
    });
  });
}