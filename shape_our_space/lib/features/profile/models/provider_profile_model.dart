class ProviderProfile {
  final String id;
  final String companyName;
  final String location;
  final String about;
  final double rating;
  final int reviewsCount;
  final String yearsExperience;
  final String heroImageUrl;
  final String avatarUrl;
  final List<PricingPackage> pricingPackages;

  ProviderProfile({
    required this.id,
    required this.companyName,
    required this.location,
    required this.about,
    required this.rating,
    required this.reviewsCount,
    required this.yearsExperience,
    required this.heroImageUrl,
    required this.avatarUrl,
    required this.pricingPackages,
  });

  ProviderProfile copyWith({
    String? id,
    String? companyName,
    String? location,
    String? about,
    double? rating,
    int? reviewsCount,
    String? yearsExperience,
    String? heroImageUrl,
    String? avatarUrl,
    List<PricingPackage>? pricingPackages,
  }) {
    return ProviderProfile(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      location: location ?? this.location,
      about: about ?? this.about,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pricingPackages: pricingPackages ?? this.pricingPackages,
    );
  }

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    return ProviderProfile(
      id: json['_id'] ?? json['id'] ?? '',
      companyName: json['companyName'] ?? 'Your Company',
      location: json['location'] ?? 'Unknown',
      about: json['about'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: json['reviewsCount'] ?? 0,
      yearsExperience: json['yearsExperience']?.toString() ?? '0',
      heroImageUrl: json['heroImageUrl'] ?? json['bannerImage'] ?? '/placeholder.svg?height=200&width=400',
      avatarUrl: json['avatarUrl'] ?? json['profileImage'] ?? '/placeholder.svg?height=200&width=200',
      pricingPackages: const [],
    );
  }
}

class PricingPackage {
  final String title;
  final String price;
  final List<String> features;

  PricingPackage({
    required this.title,
    required this.price,
    required this.features,
  });

  factory PricingPackage.fromJson(Map<String, dynamic> json) {
    return PricingPackage(
      title: json['pricingType'] ?? 'Package',
      price: '₹${json['price'] ?? 0}/${json['unit'] ?? 'sq ft'}',
      features: List<String>.from(json['services'] ?? []),
    );
  }
}

class Project {
  final String id;
  final String imageUrl;
  final String? title;

  Project({
    required this.id,
    required this.imageUrl,
    this.title,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List?;
    return Project(
      id: json['_id'] ?? json['id'] ?? '',
      imageUrl: images != null && images.isNotEmpty ? images.first : '/placeholder.svg?height=300&width=300',
      title: json['title'] ?? 'Project',
    );
  }
}

class Service {
  final String id;
  final String name;
  final String price;

  Service({
    required this.id,
    required this.name,
    required this.price,
  });
}

// Mock data
final mockProviderProfile = ProviderProfile(
  id: '1',
  companyName: 'John Doe Architects',
  location: 'Jakhan, Dehradun',
  about: 'John Doe Architects is a visionary design firm based in Dehradun, specializing in sustainable and modern residential and commercial projects. With over 15 years of experience, we transform concepts into stunning realities, focusing on client satisfaction and innovative design solutions. Our portfolio ranges from bespoke homes to large-scale commercial complexes, all designed with meticulous attention to detail and environmental consciousness.',
  rating: 4.9,
  reviewsCount: 125,
  yearsExperience: '15+ Years Experience',
  heroImageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
  avatarUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=200',
  pricingPackages: [
    PricingPackage(
      title: 'Basic Design Package',
      price: '₹40/sq ft',
      features: [
        'Conceptual Design & Layout Planning',
        '2D Floor Plans & Elevations',
        'Material Selection Consultation',
        'Up to 2 Revisions',
      ],
    ),
  ],
);
