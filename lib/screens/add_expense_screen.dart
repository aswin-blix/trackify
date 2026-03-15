import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/expense_provider.dart';
import '../utils/constants.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  String _amount = '0';
  bool _isExpense = true;
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String _notes = '';

  @override
  void initState() {
    super.initState();
    // Default to first category
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final categories = Provider.of<ExpenseProvider>(context, listen: false).categories;
       if (categories.isNotEmpty) {
         setState(() {
           _selectedCategory = categories.first;
         });
       }
    });
  }

  void _onNumpadTap(String value) {
    setState(() {
      if (value == 'backspace') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (value == '.') {
        if (!_amount.contains('.')) {
          _amount += '.';
        }
      } else {
        if (_amount == '0') {
          _amount = value;
        } else {
          // Limit decimal places to 2
          if (_amount.contains('.')) {
             final split = _amount.split('.');
             if (split.length > 1 && split[1].length >= 2) {
               return; 
             }
          }
          _amount += value;
        }
      }
    });
  }

  Future<void> _saveTransaction() async {
    final double amountValue = double.tryParse(_amount) ?? 0.0;
    if (amountValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount greater than 0.')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category.')));
      return;
    }

    final newTransaction = TransactionModel(
      amount: amountValue,
      date: _selectedDate,
      isExpense: _isExpense,
      categoryId: _selectedCategory!.id!,
      notes: _notes.isNotEmpty ? _notes : null,
    );

    await Provider.of<ExpenseProvider>(context, listen: false).addTransaction(newTransaction);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: _saveTransaction,
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  _buildTypeSwitcher(),
                  const SizedBox(height: 32),
                  _buildAmountDisplay(),
                  const SizedBox(height: 32),
                  _buildInputsGrid(),
                ],
              ),
            ),
          ),
          _buildNumpad(),
        ],
      ),
    );
  }

  Widget _buildTypeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isExpense = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isExpense ? Theme.of(context).scaffoldBackgroundColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isExpense
                      ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Expense',
                  style: TextStyle(
                    color: _isExpense ? Theme.of(context).colorScheme.primary : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isExpense = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isExpense ? Theme.of(context).scaffoldBackgroundColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: !_isExpense
                      ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Income',
                  style: TextStyle(
                    color: !_isExpense ? Theme.of(context).colorScheme.primary : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Column(
      children: [
        const Text('Amount', style: TextStyle(color: Colors.grey, fontSize: 18)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('\$', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 40, fontWeight: FontWeight.bold)),
            Text(
              _amount,
              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, letterSpacing: -1.5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputsGrid() {
    return Column(
      children: [
        _buildCategorySelector(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDatePicker()),
            const SizedBox(width: 16),
            Expanded(child: _buildWalletSelector()), 
          ],
        ),
        const SizedBox(height: 16),
        _buildNotesField(),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final categories = Provider.of<ExpenseProvider>(context).categories;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            child: Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CATEGORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                DropdownButtonHideUnderline(
                  child: DropdownButton<CategoryModel>(
                    isExpanded: true,
                    value: _selectedCategory,
                    icon: const Icon(Icons.expand_more, color: Colors.grey),
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                         _selectedCategory = val;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: const Icon(Icons.calendar_today, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(
                    "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: const Icon(Icons.account_balance_wallet, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ACCOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                const Text(
                  "Main Bank", // Mocked for now to match UI design
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: const Icon(Icons.notes, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text('NOTES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                TextField(
                  onChanged: (val) => _notes = val,
                  decoration: const InputDecoration(
                    hintText: 'Add details...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  minLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad() {
    final keys = [
      '1', '2', '3', 
      '4', '5', '6', 
      '7', '8', '9', 
      '.', '0', 'backspace'
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final keyStr = keys[index];
          
          if (keyStr == 'backspace') {
            return InkWell(
              onTap: () => _onNumpadTap(keyStr),
              borderRadius: BorderRadius.circular(12),
              child: const Center(
                child: Icon(Icons.backspace, color: Colors.grey),
              ),
            );
          }

          return InkWell(
            onTap: () => _onNumpadTap(keyStr),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                keyStr,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}
