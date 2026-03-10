import 'package:flutter/material.dart';
import '../../../models/currency.dart';


typedef CurrencySelectedCallback = void Function(Currency currency);

class CurrencyPicker extends StatefulWidget {
  final Currency? initialCurrency;
  final CurrencySelectedCallback onCurrencySelected;
  final bool showFlags;

  const CurrencyPicker({
    super.key,
    this.initialCurrency,
    required this.onCurrencySelected,
    this.showFlags = true,
  });

  @override
  State<CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<CurrencyPicker> {
  late Currency _selectedCurrency;
  List<Currency> _filteredCurrencies = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.initialCurrency ?? Currency.currencies.first;
    _filteredCurrencies = Currency.currencies;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() => _filteredCurrencies = Currency.currencies);
    } else {
      setState(() {
        _filteredCurrencies = Currency.currencies.where((currency) {
          return currency.code.toLowerCase().contains(query) ||
                 currency.name.toLowerCase().contains(query) ||
                 currency.symbol.toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Currency'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search currencies...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            
            // Currency list
            Expanded(
              child: _filteredCurrencies.isEmpty
                  ? const Center(
                      child: Text('No currencies found'),
                    )
                  : ListView.builder(
                      itemCount: _filteredCurrencies.length,
                      itemBuilder: (context, index) {
                        final currency = _filteredCurrencies[index];
                        final isSelected = currency.code == _selectedCurrency.code;
                        
                        return _CurrencyListItem(
                          currency: currency,
                          isSelected: isSelected,
                          showFlag: widget.showFlags,
                          onTap: () {
                            setState(() => _selectedCurrency = currency);
                            widget.onCurrencySelected(currency);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onCurrencySelected(_selectedCurrency);
            Navigator.pop(context);
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}

class _CurrencyListItem extends StatelessWidget {
  final Currency currency;
  final bool isSelected;
  final bool showFlag;
  final VoidCallback onTap;

  const _CurrencyListItem({
    required this.currency,
    required this.isSelected,
    required this.showFlag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: showFlag
          ? CircleAvatar(
              backgroundColor: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHigh,
              child: Text(
                currency.flag,
                style: const TextStyle(fontSize: 20),
              ),
            )
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  currency.symbol,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
      title: Text(
        currency.code,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(currency.name),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}

// Convenience function to show currency picker
Future<Currency?> showCurrencyPicker({
  required BuildContext context,
  Currency? initialCurrency,
  bool showFlags = true,
}) async {
  Currency? selectedCurrency;
  
  await showDialog(
    context: context,
    builder: (context) => CurrencyPicker(
      initialCurrency: initialCurrency,
      showFlags: showFlags,
      onCurrencySelected: (currency) {
        selectedCurrency = currency;
      },
    ),
  );
  
  return selectedCurrency;
}