import 'menu_item_model.dart';

class Canteen {
  final String id;
  final String name;
  final String place;
  final String ownerId;
  final bool isOpen;
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
    required this.openingTime,
    required this.closingTime,
    this.image,
    required this.menu,
  });

  bool get isCurrentlyOpen {
    if (!isOpen) return false;

    try {
      final now = DateTime.now();
      // Parse Opening Time "09:00"
      final openParts = openingTime.split(':');
      final openH = int.parse(openParts[0]);
      final openM = int.parse(openParts[1]);
      final openDate = DateTime(now.year, now.month, now.day, openH, openM);

      // Parse Closing Time "21:00"
      final closeParts = closingTime.split(':');
      final closeH = int.parse(closeParts[0]);
      final closeM = int.parse(closeParts[1]);
      final closeDate = DateTime(now.year, now.month, now.day, closeH, closeM);

      return now.isAfter(openDate) && now.isBefore(closeDate);
    } catch (e) {
      // Fallback if formatting fails
      return isOpen;
    }
  }

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
      'openingTime': openingTime,
      'closingTime': closingTime,
      'image': image,
      'menu': menu.map((e) => e.toJson()).toList(),
    };
  }
}
