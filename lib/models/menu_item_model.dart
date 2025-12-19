class MenuItem {
  final String id;
  final String name;
  final double price;
  final int availableQuantity;
  final String? image;
  final String category;
  final String description;

  final String canteenId; // Added for cart/reorder logic

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.availableQuantity,
    required this.canteenId,
    this.category = 'General',
    this.description = '',
    this.image,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['_id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      availableQuantity: json['availableQuantity'] ?? 0,
      canteenId: json['canteenId'] ?? '', // Handle if missing
      category: json['category'] ?? 'General',
      description: json['description'] ?? '',
      image: json['image'] is Map
          ? json['image']['url'] // Handle if image is object
          : json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'availableQuantity': availableQuantity,
      'category': category,
      'description': description,
      'image': image,
    };
  }
}
