class ServiceType {
  static const List<Map<String, String>> all = [
    {'display': 'Handyman', 'value': 'handyman'},
    {'display': 'Plumbing', 'value': 'plumbing'},
    {'display': 'Electrical', 'value': 'electrical'},
    {'display': 'Mechanic', 'value': 'mechanic'},
    {'display': 'Cleaning', 'value': 'cleaning'},
    {'display': 'Moving', 'value': 'moving'},
    {'display': 'Painting', 'value': 'painting'},
    {'display': 'Pest Control', 'value': 'pest_control'},
    {'display': 'Carpentry', 'value': 'carpentry'},
    {'display': 'Landscaping', 'value': 'landscaping'},
  ];

  static List<String> get values => all.map((type) => type['value']!).toList();
  static List<String> get displays =>
      all.map((type) => type['display']!).toList();

  static String getDisplayName(String value) {
    final service = all.firstWhere(
      (type) => type['value'] == value,
      orElse: () => {'display': value, 'value': value},
    );
    return service['display']!;
  }
}
