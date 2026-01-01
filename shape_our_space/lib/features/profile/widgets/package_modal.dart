import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/provider_profile_model.dart';
import '../providers/profile_provider.dart';

class PackageModal extends ConsumerStatefulWidget {
  const PackageModal({super.key});

  @override
  ConsumerState<PackageModal> createState() => _PackageModalState();
}

class _PackageModalState extends ConsumerState<PackageModal> {
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final unitController = TextEditingController(text: 'sq ft');
  final List<TextEditingController> serviceControllers = [];
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    serviceControllers.add(TextEditingController());
    serviceControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    unitController.dispose();
    for (var controller in serviceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addServiceField() {
    setState(() {
      serviceControllers.add(TextEditingController());
    });
  }

  void _removeServiceField(int index) {
    setState(() {
      serviceControllers[index].dispose();
      serviceControllers.removeAt(index);
    });
  }

  Future<void> _submitPackage() async {
    if (titleController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and price')),
      );
      return;
    }

    final services = serviceControllers
        .where((c) => c.text.isNotEmpty)
        .map((c) => c.text)
        .toList();

    if (services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one service')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final price = double.tryParse(priceController.text) ?? 0.0;
      final success = await ref.read(profileProvider.notifier).addPricingPackage(
        pricingType: titleController.text,
        services: services,
        price: price,
        unit: unitController.text.isEmpty ? 'sq ft' : unitController.text,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Package created successfully')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create package')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Package',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Package Title',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'e.g., Basic Design Package',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Package Price',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'Enter price',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unit',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: unitController,
                          decoration: InputDecoration(
                            hintText: 'sq ft',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...List.generate(serviceControllers.length, (index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Service ${index + 1}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        if (index > 1)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _removeServiceField(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: serviceControllers[index],
                      decoration: InputDecoration(
                        hintText: 'Add services included in the package',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        suffixIcon: index == serviceControllers.length - 1
                            ? Padding(
                                padding: const EdgeInsets.all(8),
                                child: IconButton(
                                  icon: const Icon(Icons.add_circle, color: Color(0xFF1E40AF)),
                                  onPressed: isSubmitting ? null : _addServiceField,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (index < serviceControllers.length - 1) const SizedBox(height: 12),
                  ],
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitPackage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    isSubmitting ? 'Creating...' : 'Create Package',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
