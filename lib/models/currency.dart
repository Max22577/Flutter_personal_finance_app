class Currency {
  final String code;
  final String symbol;
  final String name;
  final String flag; 
  final String locale; 
  final int decimalDigits;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
    this.locale = 'sw_KE',
    this.decimalDigits = 2,
  });

  // Factory method to create Currency from code
  factory Currency.fromCode(String code) {
    return currencies.firstWhere(
      (currency) => currency.code == code,
      orElse: () => currencies.first,
    );
  }

  // List of supported currencies
  static final List<Currency> currencies = [
    Currency(
      code: 'USD',
      symbol: '\$',
      name: 'US Dollar',
      flag: '🇺🇸',
      locale: 'en_US',
    ),
    Currency(
      code: 'EUR',
      symbol: '€',
      name: 'Euro',
      flag: '🇪🇺',
      locale: 'de_DE',
    ),
    Currency(
      code: 'GBP',
      symbol: '£',
      name: 'British Pound',
      flag: '🇬🇧',
      locale: 'en_GB',
    ),
    Currency(
      code: 'JPY',
      symbol: '¥',
      name: 'Japanese Yen',
      flag: '🇯🇵',
      locale: 'ja_JP',
      decimalDigits: 0,
    ),
    Currency(
      code: 'CAD',
      symbol: 'C\$',
      name: 'Canadian Dollar',
      flag: '🇨🇦',
      locale: 'en_CA',
    ),
    Currency(
      code: 'AUD',
      symbol: 'A\$',
      name: 'Australian Dollar',
      flag: '🇦🇺',
      locale: 'en_AU',
    ),
    Currency(
      code: 'CHF',
      symbol: 'CHF',
      name: 'Swiss Franc',
      flag: '🇨🇭',
      locale: 'de_CH',
    ),
    Currency(
      code: 'CNY',
      symbol: '¥',
      name: 'Chinese Yuan',
      flag: '🇨🇳',
      locale: 'zh_CN',
    ),
    Currency(
      code: 'KSh',
      symbol: 'KSh',
      name: 'Kenyan Shilling',
      flag: '🇰🇪',
      locale: 'sw_KE',
    ),
    Currency(
      code: 'INR',
      symbol: '₹',
      name: 'Indian Rupee',
      flag: '🇮🇳',
      locale: 'en_IN',
    ),
    Currency(
      code: 'MXN',
      symbol: '\$',
      name: 'Mexican Peso',
      flag: '🇲🇽',
      locale: 'es_MX',
    ),
    Currency(
      code: 'BRL',
      symbol: 'R\$',
      name: 'Brazilian Real',
      flag: '🇧🇷',
      locale: 'pt_BR',
    ),
    Currency(
      code: 'ZAR',
      symbol: 'R',
      name: 'South African Rand',
      flag: '🇿🇦',
      locale: 'en_ZA',
    ),
    Currency(
      code: 'NGN',
      symbol: '₦',
      name: 'Nigerian Naira',
      flag: '🇳🇬',
      locale: 'en_NG',
    ),
    Currency(
      code: 'GHS',
      symbol: 'GH₵',
      name: 'Ghanaian Cedi',
      flag: '🇬🇭',
      locale: 'en_GH',
    ),
    Currency(
      code: 'EGP',
      symbol: 'E£',
      name: 'Egyptian Pound',
      flag: '🇪🇬',
      locale: 'ar_EG',
    ),
  ];

  // Get currency by code
  static Currency getCurrency(String code) {
    return currencies.firstWhere(
      (currency) => currency.code == code,
      orElse: () => currencies.first,
    );
  }

  // Get currency names list
  static List<String> getCurrencyCodes() {
    return currencies.map((currency) => currency.code).toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$code - $name';
}