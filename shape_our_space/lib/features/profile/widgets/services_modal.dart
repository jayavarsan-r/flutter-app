import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/provider_profile_model.dart';
import '../providers/profile_provider.dart';

class ServicesModal extends ConsumerStatefulWidget {
  const ServicesModal({super.key});

  @override
  ConsumerState<ServicesModal> createState() => _ServicesModalState();
}

class _ServicesModalState extends ConsumerState<ServicesModal> {
  final List<TextEditingController> nameControllers = [];
  final List<TextEditingController> priceControllers = [];
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _addServiceRow();
    _addServiceRow();
  }

  void _addServiceRow() {
    setState(() {
      nameControllers.add(TextEditingController());
      priceControllers.add(TextEditingController());
    });
  }

  void _removeServiceRow(int index) {
    setState(() {
      nameControllers[index].dispose();
      priceControllers[index].dispose();
      nameControllers.removeAt(index);
      priceControllers.removeAt(index);
    });
  }

  Future<void> _submitServices() async {
    final services = <Service>[];
    for (int i = 0; i < nameControllers.length; i++) {
      if (nameControllers[i].text.isNotEmpty && priceControllers[i].text.isNotEmpty) {
        services.add(Service(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          name: nameControllers[i].text,
          price: priceControllers[i].text,
        ));
      }
    }

    if (services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one service with name and price')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      ref.read(servicesProvider.notifier).addMultipleServices(services);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Services created successfully')),
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
  void dispose() {
    for (var controller in nameControllers) {
      controller.dispose();
    }
    for (var controller in priceControllers) {
      controller.dispose();
    }
    super.dispose();
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
                    'Services',
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
              ...List.generate(nameControllers.length, (index) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Service ${index + 1}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: nameControllers[index],
                                decoration: InputDecoration(
                                  hintText: 'Add service',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  suffixIcon: index == nameControllers.length - 1
                                      ? Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: IconButton(
                                            icon: const Icon(Icons.add_circle, color: Color(0xFF1E40AF), size: 20),
                                            onPressed: isSubmitting ? null : _addServiceRow,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        )
                                      : null,
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
                                'Price',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: priceControllers[index],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'Rs.',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  suffixIcon: index > 1
                                      ? Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 18),
                                            onPressed: isSubmitting ? null : () => _removeServiceRow(index),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (index < nameControllers.length - 1) const SizedBox(height: 12),
                  ],
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitServices,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    isSubmitting ? 'Creating...' : 'Create Services',
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
