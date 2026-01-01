import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/provider_profile_model.dart';
import '../../../core/services/api_client.dart';

/// Enhanced profile state to include API loading and error states
class ProfileState {
  final ProviderProfile? profile;
  final List<Project> projects;
  final List<PricingPackage> pricingPackages;
  final bool isLoading;
  final bool isLoadingProfile;
  final bool isLoadingProjects;
  final bool isLoadingPricing;
  final String? error;
  final String? avatarUrl;
  final String? heroImageUrl;
  final String? about;
  final double? rating;
  final int? reviewsCount;
  final String? yearsExperience;

  ProfileState({
    this.profile,
    this.projects = const [],
    this.pricingPackages = const [],
    this.isLoading = false,
    this.isLoadingProfile = true,
    this.isLoadingProjects = true,
    this.isLoadingPricing = true,
    this.error,
    this.avatarUrl,
    this.heroImageUrl,
    this.about,
    this.rating,
    this.reviewsCount,
    this.yearsExperience,
  });

  ProfileState copyWith({
    ProviderProfile? profile,
    List<Project>? projects,
    List<PricingPackage>? pricingPackages,
    bool? isLoading,
    bool? isLoadingProfile,
    bool? isLoadingProjects,
    bool? isLoadingPricing,
    String? error,
    String? avatarUrl,
    String? heroImageUrl,
    String? about,
    double? rating,
    int? reviewsCount,
    String? yearsExperience,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      projects: projects ?? this.projects,
      pricingPackages: pricingPackages ?? this.pricingPackages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingProfile: isLoadingProfile ?? this.isLoadingProfile,
      isLoadingProjects: isLoadingProjects ?? this.isLoadingProjects,
      isLoadingPricing: isLoadingPricing ?? this.isLoadingPricing,
      error: error,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      about: about ?? this.about,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      yearsExperience: yearsExperience ?? this.yearsExperience,
    );
  }
}

/// Enhanced profile notifier with API integration
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ApiClient _apiClient;

  ProfileNotifier(this._apiClient) : super(ProfileState()) {
    _loadProfileData();
  }

  /// Load all profile data from backend with parallel requests
  Future<void> _loadProfileData() async {
    state = state.copyWith(
      isLoadingProfile: true,
      isLoadingProjects: true,
      isLoadingPricing: true,
      error: null,
    );
    
    try {
      final token = await _apiClient.getToken();
      if (token == null) {
        state = state.copyWith(
          isLoadingProfile: false,
          isLoadingProjects: false,
          isLoadingPricing: false,
        );
        return;
      }

      final results = await Future.wait([
        _apiClient.getProviderProfile().catchError((e) => <String, dynamic>{}),
        _apiClient.getProviderPricing().catchError((e) => <dynamic>[]),
        _apiClient.getPortfolioProjects().catchError((e) => <dynamic>[]),
      ]);

      final profileData = results[0] as Map<String, dynamic>;
      final pricingList = (results[1] as List).cast<Map<String, dynamic>>();
      final portfolioList = (results[2] as List).cast<Map<String, dynamic>>();

      print('[v0] Profile loaded: ${profileData.keys}');
      print('[v0] Pricing count: ${pricingList.length}');
      print('[v0] Projects count: ${portfolioList.length}');

      final pricingPackages = pricingList.map((p) {
        return PricingPackage.fromJson(p);
      }).toList();

      final projects = portfolioList.map((p) {
        return Project.fromJson(p);
      }).toList();

      final profile = ProviderProfile.fromJson(profileData);

      state = state.copyWith(
        isLoadingProfile: false,
        isLoadingProjects: false,
        isLoadingPricing: false,
        profile: profile,
        pricingPackages: pricingPackages,
        projects: projects,
        avatarUrl: profileData['avatarUrl'],
        heroImageUrl: profileData['heroImageUrl'],
        about: profileData['about'],
        rating: (profileData['rating'] as num?)?.toDouble(),
        reviewsCount: profileData['reviewsCount'],
        yearsExperience: profileData['yearsExperience'],
      );
    } catch (e) {
      print('[v0] Profile load error: $e');
      state = state.copyWith(
        isLoadingProfile: false,
        isLoadingProjects: false,
        isLoadingPricing: false,
        error: e.toString(),
      );
    }
  }

  /// Reload profile data manually
  Future<void> reloadProfileData() async {
    await _loadProfileData();
  }

  /// Update hero image (profile banner)
  void updateHeroImage(String newImageUrl) {
    state = state.copyWith(
      heroImageUrl: newImageUrl,
      profile: state.profile?.copyWith(heroImageUrl: newImageUrl),
    );
  }

  /// Add new project to backend and local state with image upload
  Future<bool> addProject({
    required String title,
    required String description,
    required List<dynamic> imageFiles,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // First upload images to backend (which uploads to Cloudinary)
      print('[v0] Uploading ${imageFiles.length} images via backend');
      final imageUrls = await _apiClient.uploadImages(imageFiles);
      print('[v0] Received ${imageUrls.length} Cloudinary URLs');
      
      // Then create the project with Cloudinary URLs
      final result = await _apiClient.addPortfolioProject(
        title: title,
        description: description,
        images: imageUrls,
      );

      final newProject = Project.fromJson(result);

      state = state.copyWith(
        isLoading: false,
        projects: [...state.projects, newProject],
      );
      return true;
    } catch (e) {
      print('[v0] Add project error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Delete project from backend and local state
  Future<bool> deleteProject(String projectId) async {
    try {
      await _apiClient.deletePortfolioProject(projectId);
      state = state.copyWith(
        projects: state.projects.where((p) => p.id != projectId).toList(),
      );
      return true;
    } catch (e) {
      print('[v0] Delete project error: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Add pricing package to backend and local state
  Future<bool> addPricingPackage({
    required String pricingType,
    required List<String> services,
    required double price,
    required String unit,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _apiClient.addPricing(
        pricingType: pricingType,
        services: services,
        price: price,
        unit: unit,
      );

      final newPackage = PricingPackage(
        title: pricingType,
        price: '₹$price/$unit',
        features: services,
      );

      state = state.copyWith(
        isLoading: false,
        pricingPackages: [...state.pricingPackages, newPackage],
      );
      return true;
    } catch (e) {
      print('[v0] Add pricing error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Delete pricing package from backend and local state
  Future<bool> deletePricingPackage(String packageId) async {
    try {
      await _apiClient.deletePricing(packageId);
      return true;
    } catch (e) {
      print('[v0] Delete pricing error: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update pricing packages list
  void updatePricingPackages(List<PricingPackage> packages) {
    state = state.copyWith(pricingPackages: packages);
  }
}

/// Profile provider with API integration
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileNotifier(apiClient);
});

class ProjectsNotifier extends StateNotifier<List<Project>> {
  ProjectsNotifier()
      : super([
          Project(
            id: '1',
            imageUrl:
                'https://images.unsplash.com/photo-1578500494198-246f612d03b3?w=300&h=300&fit=crop',
          ),
          Project(
            id: '2',
            imageUrl:
                'https://images.unsplash.com/photo-1578500494198-246f612d03b3?w=300&h=300&fit=crop',
          ),
          Project(
            id: '3',
            imageUrl:
                'https://images.unsplash.com/photo-1578500494198-246f612d03b3?w=300&h=300&fit=crop',
          ),
          Project(
            id: '4',
            imageUrl:
                'https://images.unsplash.com/photo-1578500494198-246f612d03b3?w=300&h=300&fit=crop',
          ),
        ]);

  void addProject(Project project) {
    state = [...state, project];
  }

  void removeProject(String projectId) {
    state = state.where((p) => p.id != projectId).toList();
  }

  void updateProject(String projectId, String newImageUrl) {
    state = state.map((p) {
      if (p.id == projectId) {
        return Project(
          id: p.id,
          imageUrl: newImageUrl,
          title: p.title,
        );
      }
      return p;
    }).toList();
  }
}

final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, List<Project>>((ref) {
  return ProjectsNotifier();
});

class ServicesNotifier extends StateNotifier<List<Service>> {
  ServicesNotifier() : super([]);

  void addService(Service service) {
    state = [...state, service];
  }

  void addMultipleServices(List<Service> services) {
    state = [...state, ...services];
  }

  void removeService(String serviceId) {
    state = state.where((s) => s.id != serviceId).toList();
  }
}

final servicesProvider = StateNotifierProvider<ServicesNotifier, List<Service>>((ref) {
  return ServicesNotifier();
});
