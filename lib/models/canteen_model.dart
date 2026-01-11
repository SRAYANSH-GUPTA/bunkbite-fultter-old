import 'menu_item_model.dart';

class Canteen {
  final String id;
  final String name;
  final String place;
  final String ownerId;
  final bool isOpen;
  final bool isCurrentlyOpen; // From backend API
  final String openingTime;
  final String closingTime;
  final String? image;
  final List<MenuItem> menu;

  Canteen({
    required this.id,
    required this.name,
    required this.place,
    required this.ownerId,
    required this.isOpen,
    required this.isCurrentlyOpen,
    required this.openingTime,
    required this.closingTime,
    this.image,
    required this.menu,
  });

  factory Canteen.fromJson(Map<String, dynamic> json) {
    var menuList = json['menu'] as List?;
    List<MenuItem> items = menuList != null
        ? menuList.map((i) => MenuItem.fromJson(i)).toList()
        : [];

    dynamic ownerData = json['ownerId'];
    String ownerIdStr = '';
    if (ownerData is Map) {
      ownerIdStr = ownerData['_id'] ?? '';
    } else if (ownerData is List && ownerData.isNotEmpty) {
      ownerIdStr = ownerData[0] is Map
          ? ownerData[0]['_id']
          : ownerData[0].toString();
    } else {
      ownerIdStr = ownerData?.toString() ?? '';
    }

    dynamic imageData = json['image'];
    String imageStr = '';
    if (imageData is Map) {
      imageStr = imageData['url'] ?? '';
    } else if (imageData is List && imageData.isNotEmpty) {
      imageStr = imageData[0] is Map
          ? (imageData[0]['url'] ?? '')
          : imageData[0].toString();
    } else {
      imageStr = imageData?.toString() ?? '';
    }

    return Canteen(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      place: json['place'] ?? '',
      ownerId: ownerIdStr,
      isOpen: json['isOpen'] ?? true,
      isCurrentlyOpen: json['isCurrentlyOpen'] ?? false,
      openingTime: json['openingTime'] ?? '09:00',
      closingTime: json['closingTime'] ?? '21:00',
      image: imageStr,
      menu: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'place': place,
      'ownerId': ownerId,
      'isOpen': isOpen,
      'isCurrentlyOpen': isCurrentlyOpen,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'image': image,
      'menu': menu.map((e) => e.toJson()).toList(),
    };
  }
}
