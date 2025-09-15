import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/expenses_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  DateTime? _purchaseDate;
  File? _receiptImage;
  bool _isSubmitting = false;
  bool _isLoadingHistory = false;
  List<Map<String, dynamic>> _expenses = [];

  @override
  void dispose() {
    _itemNameController.dispose();
    _costController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadHistory(initial: true);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        _purchaseDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source, imageQuality: 85);
    if (xfile != null) {
      setState(() => _receiptImage = File(xfile.path));
    }
  }

  Future<void> _loadHistory({bool initial = false}) async {
    setState(() => _isLoadingHistory = true);
    try {
      final employeeId = await StorageService.getEmployeeId();
      if (employeeId == null || employeeId.isEmpty) return;
      final items = await ExpensesService.listMyExpenses(
        employeeId: employeeId,
      );
      if (mounted) setState(() => _expenses = items);
    } catch (e) {
      if (!initial) _showSnack('Failed to load expenses: $e');
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_purchaseDate == null) {
      _showSnack('Please select purchase date');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final employeeId = await StorageService.getEmployeeId();
      if (employeeId == null || employeeId.isEmpty) {
        throw Exception('Employee ID not found');
      }

      String? imageUrl;
      if (_receiptImage != null) {
        imageUrl = await ExpensesService.uploadReceiptImage(
          employeeId: employeeId,
          imageFile: _receiptImage!,
        );
      }

      final cost =
          double.tryParse(_costController.text.replaceAll(',', '')) ?? 0;
      await ExpensesService.submitExpense(
        itemName: _itemNameController.text.trim(),
        purchaseDate: _purchaseDate!,
        cost: cost,
        imageUrl: imageUrl,
        employeeId: employeeId,
      );

      if (mounted) {
        _showSnack('Expense submitted successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnack('Failed to submit: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDate(DateTime d) => d.toIso8601String().split('T')[0];

  Widget _buildH4(BuildContext context, String text) {
    final style =
        Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ) ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w700);
    return Text(text, style: style);
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Claim')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildH4(context, 'Claim expenses'),
                const SizedBox(height: 12),

                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _itemNameController,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            label: 'Item or service',
                            hint: 'e.g., Charger cable',
                            icon: Icons.shopping_bag_rounded,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter item name'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          onTap: _pickDate,
                          decoration: _inputDecoration(
                            label: 'Purchase date',
                            hint: 'YYYY-MM-DD',
                            icon: Icons.event_rounded,
                            suffix: IconButton(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_today_rounded),
                              tooltip: 'Pick date',
                            ),
                          ),
                          validator: (_) =>
                              _purchaseDate == null ? 'Select a date' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _costController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration(
                            label: 'Amount',
                            hint: 'e.g., 350',
                            icon: Icons.currency_rupee_rounded,
                          ).copyWith(prefixText: '₹ '),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Enter cost';
                            final parsed = double.tryParse(
                              v.replaceAll(',', ''),
                            );
                            if (parsed == null || parsed <= 0) {
                              return 'Enter valid cost';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Receipt Image',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_receiptImage != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _receiptImage!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            height: 140,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 36,
                                  color: Theme.of(context).hintColor,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No receipt selected',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context).hintColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_rounded),
                                label: const Text('Camera'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_rounded),
                                label: const Text('Gallery'),
                              ),
                            ),
                            if (_receiptImage != null) ...[
                              const SizedBox(width: 12),
                              IconButton(
                                tooltip: 'Remove',
                                onPressed: () =>
                                    setState(() => _receiptImage = null),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildH4(context, 'Recent expenses'),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _isLoadingHistory
                          ? null
                          : () => _loadHistory(),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isLoadingHistory)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_expenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'No expenses yet',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final e = _expenses[index];
                      final title = (e['item_name'] ?? e['itemName'] ?? '')
                          .toString();
                      final dateStr =
                          (e['purchase_date'] ?? e['purchaseDate'] ?? '')
                              .toString();
                      final amount = (e['cost'] ?? e['amount'] ?? 0).toString();
                      final status = (e['status'] ?? 'pending').toString();
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.receipt_rounded),
                          ),
                          title: Text(title.isEmpty ? 'Expense' : title),
                          subtitle: Text(dateStr),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹ $amount',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              _buildStatusChip(status),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String statusRaw) {
    final s = statusRaw.toLowerCase();
    Color bg;
    Color fg;
    String label;
    switch (s) {
      case 'approved':
        bg = Colors.green.withOpacity(0.12);
        fg = Colors.green.shade700;
        label = 'Approved';
        break;
      case 'rejected':
        bg = Colors.red.withOpacity(0.12);
        fg = Colors.red.shade700;
        label = 'Rejected';
        break;
      default:
        bg = Colors.orange.withOpacity(0.12);
        fg = Colors.orange.shade700;
        label = 'Pending';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12)),
    );
  }
}
