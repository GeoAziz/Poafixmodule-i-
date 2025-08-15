import 'package:flutter/material.dart';
import '../services/service_service.dart';

const List<String> kServiceTypes = [
  'Plumbing',
  'Electrical',
  'Painting',
  'Cleaning',
  'Carpentry',
  'Gardening',
  'Appliance Repair',
  'Pest Control',
  'Masonry',
  'Mechanic',
  'Moving'
];
const List<String> kDurations = [
  '30 min',
  '1 hour',
  '2 hours',
  '3 hours',
  '4 hours',
  'Half day',
  'Full day'
];

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyServiceScreen(),
    );
  }

  // The following class should not be nested inside MyApp
}

class MyServiceScreen extends StatefulWidget {
  const MyServiceScreen({super.key});

  @override
  _MyServiceScreenState createState() => _MyServiceScreenState();
}

class _MyServiceScreenState extends State<MyServiceScreen>
    with TickerProviderStateMixin {
  Future<void> _editService(int index) async {
    final service = _services[index];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SimpleServiceDialog(
        initial: service,
        isEdit: true,
      ),
    );
    if (result != null) {
      final newList = List<Map<String, dynamic>>.from(_services);
      newList[index] = result;
      try {
        await _serviceService.updateProviderServices(newList);
        await _fetchServices();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Service updated')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update service: $e')),
        );
      }
    }
  }

  Future<void> _adjustPrice(int index) async {
    final service = _services[index];
    final priceController = TextEditingController(text: service['price'] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Price'),
        content: TextFormField(
          controller: priceController,
          decoration: InputDecoration(
            labelText: 'New Price (KES)',
            hintText: 'e.g. 2000',
          ),
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter price';
            if (double.tryParse(v.trim()) == null)
              return 'Enter a valid number';
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pop(priceController.text.trim()),
            child: Text('Update'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final newList = List<Map<String, dynamic>>.from(_services);
      newList[index]['price'] = result;
      try {
        await _serviceService.updateProviderServices(newList);
        await _fetchServices();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Price updated')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update price: $e')),
        );
      }
    }
  }

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final ServiceService _serviceService = ServiceService();
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final services = await _serviceService.getProviderServices();
      setState(() {
        _services = services;
        _loading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = 'Failed to load services.';
        _loading = false;
      });
    }
  }

  Future<void> _addService() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SimpleServiceDialog(),
    );
    if (result != null &&
        result['name'] != null &&
        result['name'].trim().isNotEmpty) {
      final newList = List<Map<String, dynamic>>.from(_services);
      if (newList.any((s) => s['name'] == result['name'].trim())) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Service already exists.')),
        );
        return;
      }
      newList.add(result);
      try {
        await _serviceService.updateProviderServices(newList);
        await _fetchServices();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add service: $e')),
        );
      }
    }
  }

  Future<void> _removeService(int index) async {
    final serviceName = _services[index]['name'] ?? '';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove Service'),
        content: Text('Are you sure you want to remove "$serviceName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Remove'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final newList = List<Map<String, dynamic>>.from(_services)
        ..removeAt(index);
      try {
        await _serviceService.updateProviderServices(newList);
        await _fetchServices();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Service removed')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove service: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Services'),
            IconButton(
              icon: Icon(Icons.add_circle_outline),
              onPressed: _addService,
            ),
          ],
        ),
        backgroundColor: Colors.green,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _services.isEmpty
                  ? Center(child: Text('No services yet. Tap + to add.'))
                  : SlideTransition(
                      position: _slideAnimation,
                      child: ListView.builder(
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final service = _services[index];
                          return Dismissible(
                            key: ValueKey(service['name'] ?? index),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              color: Colors.redAccent,
                              child: Icon(Icons.delete,
                                  color: Colors.white, size: 32),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Remove Service'),
                                  content: Text(
                                      'Are you sure you want to remove "${service['name']}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: Text('Remove'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) => _removeService(index),
                            child: SimpleServiceCard(
                              service: service,
                              onEdit: () => _editService(index),
                              onAdjustPrice: () => _adjustPrice(index),
                              onDelete: () => _removeService(index),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class SimpleServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback? onEdit;
  final VoidCallback? onAdjustPrice;
  final VoidCallback? onDelete;
  const SimpleServiceCard(
      {super.key,
      required this.service,
      this.onEdit,
      this.onAdjustPrice,
      this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(15),
        title: Text(
          service['name'] ?? '',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((service['description'] ?? '').isNotEmpty)
              Text(service['description'], style: TextStyle(fontSize: 14)),
            if ((service['price'] ?? '').toString().isNotEmpty)
              Text('Price: KES ${service['price']}',
                  style: TextStyle(fontSize: 14)),
            if ((service['duration'] ?? '').isNotEmpty)
              Text('Duration: ${service['duration']}',
                  style: TextStyle(fontSize: 14)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) {
            if (value == 'edit' && onEdit != null) onEdit!();
            if (value == 'price' && onAdjustPrice != null) onAdjustPrice!();
            if (value == 'delete' && onDelete != null) onDelete!();
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text('Edit Service')),
            PopupMenuItem(value: 'price', child: Text('Adjust Price')),
            PopupMenuItem(value: 'delete', child: Text('Delete Service')),
          ],
        ),
      ),
    );
  }
}

class SimpleServiceDialog extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final bool isEdit;
  const SimpleServiceDialog({Key? key, this.initial, this.isEdit = false})
      : super(key: key);
  @override
  State<SimpleServiceDialog> createState() => _SimpleServiceDialogState();
}

class _SimpleServiceDialogState extends State<SimpleServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedServiceType;
  String? _selectedDuration;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _selectedServiceType = widget.initial?['name'] ?? null;
    _descController =
        TextEditingController(text: widget.initial?['description'] ?? '');
    _priceController =
        TextEditingController(text: widget.initial?['price'] ?? '');
    _selectedDuration = widget.initial?['duration'] ?? null;
  }

  @override
  void dispose() {
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Service' : 'Add Service'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedServiceType,
                decoration: InputDecoration(labelText: 'Service Name'),
                items: kServiceTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedServiceType = val),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Select service' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText:
                      'Describe the service, e.g. "Fix leaking kitchen sink"',
                ),
                maxLines: 2,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter description' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Quotation / Price (KES)',
                  hintText: 'e.g. 2000',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter price';
                  if (double.tryParse(v.trim()) == null)
                    return 'Enter a valid number';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedDuration,
                decoration: InputDecoration(labelText: 'Estimated Duration'),
                items: kDurations
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedDuration = val),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Select duration' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _selectedServiceType ?? '',
                'description': _descController.text.trim(),
                'price': _priceController.text.trim(),
                'duration': _selectedDuration ?? '',
              });
            }
          },
          child: Text(widget.isEdit ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
