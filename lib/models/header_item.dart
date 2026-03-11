class HeaderItem {
  String key;
  String value;

  HeaderItem({required this.key, required this.value});

  // Convert to JSON Map
  Map<String, dynamic> toJson() => {'key': key, 'value': value};

  // Create from JSON Map
  factory HeaderItem.fromJson(Map<String, dynamic> json) => 
      HeaderItem(key: json['key'] ?? '', value: json['value'] ?? '');
}