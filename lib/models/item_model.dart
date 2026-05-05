class ItemModel {
  final String id;
  final String type; // 'lost' or 'found'
  final String title;
  final String description;
  final String category;
  final String location;
  final String imageUrl;
  final String postedBy;
  final String posterName;
  final String posterPhone;
  final DateTime createdAt;
  final bool isResolved;
  final String itemStatus; // 'Active', 'Claimed_Pending', 'Recovered', 'Archived'

  ItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.imageUrl,
    required this.postedBy,
    required this.posterName,
    required this.posterPhone,
    required this.createdAt,
    this.isResolved = false,
    this.itemStatus = 'Active',
  });

  factory ItemModel.fromMap(Map<String, dynamic> map, String docId) {
    return ItemModel(
      id: docId,
      type: map['type'] ?? 'lost',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      postedBy: map['postedBy'] ?? '',
      posterName: map['posterName'] ?? '',
      posterPhone: map['posterPhone'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      isResolved: map['isResolved'] ?? false,
      itemStatus: map['itemStatus'] ?? 'Active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'imageUrl': imageUrl,
      'postedBy': postedBy,
      'posterName': posterName,
      'posterPhone': posterPhone,
      'createdAt': createdAt,
      'isResolved': isResolved,
      'itemStatus': itemStatus,
    };
  }
}
