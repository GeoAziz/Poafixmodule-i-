import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      title: 'Credit Card',
      icon: Icons.credit_card,
      isSelected: true,
    ),
    PaymentMethod(
      title: 'PayPal',
      icon: Icons.payment,
      isSelected: false,
    ),
    PaymentMethod(
      title: 'Google Pay',
      icon: Icons.g_mobiledata,
      isSelected: false,
    ),
    PaymentMethod(
      title: 'Apple Pay',
      icon: Icons.apple,
      isSelected: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Payment Methods'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _paymentMethods.length,
                itemBuilder: (context, index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _paymentMethods[index].isSelected
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _paymentMethods[index].isSelected
                            ? Colors.blue
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          for (var method in _paymentMethods) {
                            method.isSelected = false;
                          }
                          _paymentMethods[index].isSelected = true;
                        });
                      },
                      leading: Icon(
                        _paymentMethods[index].icon,
                        color: _paymentMethods[index].isSelected
                            ? Colors.blue
                            : Colors.grey,
                        size: 32,
                      ),
                      title: Text(
                        _paymentMethods[index].title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: _paymentMethods[index].isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.blue,
                            )
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Handle payment processing
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentMethod {
  final String title;
  final IconData icon;
  bool isSelected;

  PaymentMethod({
    required this.title,
    required this.icon,
    required this.isSelected,
  });
}
