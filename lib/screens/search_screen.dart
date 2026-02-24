import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:vidstream_app/models/video.dart';
import 'package:vidstream_app/services/youtube_service.dart';
import 'package:vidstream_app/services/firestore_service.dart';
import 'package:vidstream_app/widgets/video_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  List<Video> _searchResults = [];
  String? _nextPageToken;
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _errorMessage;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore &&
        !_isLoading &&
        _nextPageToken != null) {
      _loadMoreResults();
    }
  }
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _errorMessage = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final service = Provider.of<YoutubeService>(context, listen: false);
      final result = await service.searchVideos(query);
      
      if (mounted) {
        setState(() {
          _searchResults = result['videos'];
          _nextPageToken = result['nextPageToken'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to search videos. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreResults() async {
    setState(() => _isFetchingMore = true);
    try {
      final service = Provider.of<YoutubeService>(context, listen: false);
      final result = await service.searchVideos(_searchController.text, pageToken: _nextPageToken);
      if (mounted) {
        setState(() {
          _searchResults.addAll(result['videos']);
          _nextPageToken = result['nextPageToken'];
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Search YouTube...',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : const Icon(Icons.search, size: 20, color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          int crossAxisCount = 1;
          if (width > 1200) {
            crossAxisCount = 4;
          } else if (width > 900) {
            crossAxisCount = 3;
          } else if (width > 600) {
            crossAxisCount = 2;
          }

          return _buildBody(firestoreService, crossAxisCount);
        },
      ),
    );
  }

  Widget _buildBody(FirestoreService firestoreService, int crossAxisCount) {
    if (_isLoading) {
      return _buildSkeletonGrid(crossAxisCount);
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 16),
            const Text(
              'Search for your favorite videos',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 16),
            const Text('No results found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(12.0),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 0,
            childAspectRatio: 0.8,
          ),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final video = _searchResults[index];
            return VideoCard(
              video: video,
              onTap: () => context.push('/player', extra: video),
              onWatchLater: () {
                firestoreService.addToWatchLater(video);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to Watch Later'), behavior: SnackBarBehavior.floating),
                );
              },
            );
          },
        ),
        if (_isFetchingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildSkeletonGrid(int crossAxisCount) {
    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 0,
        childAspectRatio: 0.8,
      ),
      itemCount: 8,
      itemBuilder: (context, index) => const VideoCardSkeleton(),
    );
  }
}
