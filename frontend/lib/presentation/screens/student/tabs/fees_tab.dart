import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../providers/student_provider.dart';
import '../../../widgets/components.dart';
import '../../../../core/theme/design_system.dart';

class FeesTab extends StatefulWidget {
  const FeesTab({super.key});

  @override
  State<FeesTab> createState() => _FeesTabState();
}

class _FeesTabState extends State<FeesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchFees();
    });
  }

  void _showSubmitPaymentModal(BuildContext context, double remainingAmount) {
    final amountController = TextEditingController();
    Uint8List? selectedImageBytes;
    String? selectedFilename;
    bool isUploading = false;
    String? modalError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImage() async {
              try {
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  // 5 MB limit check
                  if (bytes.length > 5 * 1024 * 1024) {
                    setModalState(() {
                      modalError = 'File size exceeds maximum limit of 5 MB.';
                    });
                    return;
                  }
                  setModalState(() {
                    selectedImageBytes = bytes;
                    selectedFilename = image.name;
                    modalError = null;
                  });
                }
              } catch (e) {
                setModalState(() {
                  modalError = 'Error selecting image: $e';
                });
              }
            }

            Future<void> submit() async {
              final text = amountController.text.trim();
              if (text.isEmpty) {
                setModalState(() => modalError = 'Please enter payment amount.');
                return;
              }
              final amount = double.tryParse(text);
              if (amount == null || amount <= 0) {
                setModalState(() => modalError = 'Please enter a valid positive amount.');
                return;
              }
              if (remainingAmount > 0 && amount > remainingAmount) {
                setModalState(() => modalError = 'Payment amount exceeds remaining annual fee (₹${remainingAmount.toStringAsFixed(0)}).');
                return;
              }
              if (selectedImageBytes == null || selectedFilename == null) {
                setModalState(() => modalError = 'Please select a payment screenshot proof.');
                return;
              }

              setModalState(() {
                isUploading = true;
                modalError = null;
              });

              final provider = context.read<StudentProvider>();
              final errorMsg = await provider.submitPayment(
                amount,
                selectedImageBytes!,
                selectedFilename!,
              );

              if (context.mounted) {
                if (errorMsg != null) {
                  setModalState(() {
                    isUploading = false;
                    modalError = errorMsg;
                  });
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment recorded successfully!'),
                      backgroundColor: FTColors.success,
                    ),
                  );
                }
              }
            }

            return Container(
              padding: EdgeInsets.only(
                top: FTSpacing.lg,
                left: FTSpacing.lg,
                right: FTSpacing.lg,
                bottom: MediaQuery.of(context).viewInsets.bottom + FTSpacing.lg,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: FTSpacing.md),
                    Text(
                      'Submit Payment Proof',
                      style: FTTypography.heading3.copyWith(color: FTColors.textPrimary),
                    ),
                    const SizedBox(height: FTSpacing.xs),
                    Text(
                      'Upload your payment screenshot to update fee records.',
                      style: FTTypography.bodySmall.copyWith(color: FTColors.textSecondary),
                    ),
                    const SizedBox(height: FTSpacing.md),
                    if (modalError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(FTSpacing.sm),
                        decoration: BoxDecoration(
                          color: FTColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          modalError!,
                          style: FTTypography.bodySmall.copyWith(color: FTColors.error),
                        ),
                      ),
                      const SizedBox(height: FTSpacing.md),
                    ],
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      enabled: !isUploading,
                      decoration: const InputDecoration(
                        labelText: 'Amount Paid (₹)',
                        hintText: 'e.g. 5000',
                        prefixIcon: Icon(Icons.currency_rupee, color: FTColors.primary),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: FTSpacing.md),
                    Text('Payment Screenshot', style: FTTypography.label),
                    const SizedBox(height: FTSpacing.xs),
                    InkWell(
                      onTap: isUploading ? null : pickImage,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedImageBytes != null ? FTColors.primary : Colors.grey.shade400,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: selectedImageBytes != null ? FTColors.primaryLight.withValues(alpha: 0.2) : Colors.grey.shade50,
                        ),
                        child: selectedImageBytes != null
                            ? Stack(
                                children: [
                                  Center(
                                    child: Image.memory(
                                      selectedImageBytes!,
                                      fit: BoxFit.contain,
                                      height: 110,
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.white,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                        onPressed: () {
                                          setModalState(() {
                                            selectedImageBytes = null;
                                            selectedFilename = null;
                                          });
                                        },
                                      ),
                                    ),
                                  )
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_photo_alternate, size: 36, color: FTColors.primary),
                                  const SizedBox(height: FTSpacing.xs),
                                  Text(
                                    'Select Screenshot (JPG, PNG - Max 5MB)',
                                    style: FTTypography.bodySmall.copyWith(color: FTColors.primary),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: FTSpacing.lg),
                    ElevatedButton(
                      onPressed: isUploading ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FTColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isUploading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                SizedBox(width: 10),
                                Text('Uploading payment proof...', style: TextStyle(color: Colors.white)),
                              ],
                            )
                          : Text('Submit Payment', style: FTTypography.button.copyWith(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProofDialog(BuildContext context, String proofUrl, String amount, String date, String time) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Payment Proof', style: FTTypography.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₹$amount', style: FTTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            Text('Date: $date', style: FTTypography.bodySmall),
            if (time.isNotEmpty) Text('Time: $time', style: FTTypography.bodySmall),
            const SizedBox(height: FTSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                proofUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  padding: const EdgeInsets.all(FTSpacing.md),
                  color: Colors.grey.shade200,
                  child: const Row(
                    children: [
                      Icon(Icons.broken_image, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Screenshot proof image unavailable'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();

    if (provider.isLoading && provider.feeSummary == null) {
      return const Center(child: FTLoading());
    }

    final summary = provider.feeSummary;
    final double annualFee = (summary?['annualFee'] as num?)?.toDouble() ?? 15000.0;
    final double paidAmount = (summary?['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final double remainingAmount = (summary?['remainingAmount'] as num?)?.toDouble() ?? (annualFee - paidAmount);
    final String statusStr = summary?['status']?.toString() ?? (paidAmount >= annualFee ? 'PAID' : (paidAmount > 0 ? 'PARTIALLY_PAID' : 'PENDING'));
    final String cycleStart = summary?['feeCycleStart']?.toString() ?? '';
    final String cycleEnd = summary?['feeCycleEnd']?.toString() ?? '';

    Color statusColor;
    String statusLabel;
    switch (statusStr) {
      case 'PAID':
        statusColor = FTColors.success;
        statusLabel = 'PAID';
        break;
      case 'PARTIALLY_PAID':
        statusColor = FTColors.warning;
        statusLabel = 'PARTIALLY PAID';
        break;
      default:
        statusColor = FTColors.error;
        statusLabel = 'PENDING';
        break;
    }

    final payments = provider.fees;

    return RefreshIndicator(
      onRefresh: () => provider.fetchFees(),
      child: ListView(
        padding: const EdgeInsets.all(FTSpacing.md),
        children: [
          FTCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My Fees', style: FTTypography.heading3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        statusLabel,
                        style: FTTypography.label.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (cycleStart.isNotEmpty && cycleEnd.isNotEmpty) ...[
                  const SizedBox(height: FTSpacing.xs),
                  Text(
                    'Fee Cycle: $cycleStart – $cycleEnd',
                    style: FTTypography.bodySmall.copyWith(color: FTColors.textSecondary),
                  ),
                ],
                const SizedBox(height: FTSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat('Annual Fee', '₹${annualFee.toStringAsFixed(0)}'),
                    _buildStat('Paid', '₹${paidAmount.toStringAsFixed(0)}', color: FTColors.success),
                    _buildStat('Remaining', '₹${remainingAmount.toStringAsFixed(0)}',
                        color: remainingAmount > 0 ? FTColors.warning : FTColors.textPrimary),
                  ],
                ),
                const SizedBox(height: FTSpacing.sm),
                FTProgressIndicator(
                  value: annualFee > 0 ? (paidAmount / annualFee).clamp(0.0, 1.0) : 0,
                  color: FTColors.primary,
                ),
                const SizedBox(height: FTSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: remainingAmount <= 0
                        ? null
                        : () => _showSubmitPaymentModal(context, remainingAmount),
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: Text(
                      remainingAmount <= 0 ? 'Annual Fee Fully Paid' : 'Upload Payment Proof',
                      style: FTTypography.button.copyWith(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FTColors.primary,
                      disabledBackgroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FTSpacing.lg),
          Text('Payment History', style: FTTypography.heading3),
          const SizedBox(height: FTSpacing.sm),
          if (payments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(FTSpacing.xl),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long, size: 48, color: FTColors.textSecondary),
                    const SizedBox(height: FTSpacing.sm),
                    Text(
                      'No payment records submitted yet.',
                      style: FTTypography.body.copyWith(color: FTColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ...payments.map((p) {
              final double amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
              final String date = p['paymentDateFormatted'] ?? p['paymentDate'] ?? '';
              final String time = p['paymentTimeFormatted'] ?? '';
              final String proofUrl = p['proofUrl'] ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: FTSpacing.sm),
                child: FTCard(
                  padding: const EdgeInsets.all(FTSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(FTSpacing.xs),
                        decoration: const BoxDecoration(
                          color: FTColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle, color: FTColors.primary),
                      ),
                      const SizedBox(width: FTSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₹${amount.toStringAsFixed(0)}',
                                style: FTTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: FTSpacing.xxs),
                            Text('$date ${time.isNotEmpty ? "• $time" : ""}',
                                style: FTTypography.bodySmall.copyWith(color: FTColors.textSecondary)),
                          ],
                        ),
                      ),
                      if (proofUrl.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => _showProofDialog(context, proofUrl, amount.toStringAsFixed(0), date, time),
                          icon: const Icon(Icons.image, size: 16),
                          label: const Text('View Proof'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: FTColors.primary,
                            side: const BorderSide(color: FTColors.primary),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FTTypography.bodySmall),
        const SizedBox(height: FTSpacing.xxs),
        Text(value,
            style: FTTypography.bodyLarge
                .copyWith(color: color ?? FTColors.textPrimary, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
