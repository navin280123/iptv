import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'player_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<dynamic> _allChannels = [];
  List<dynamic> _filteredChannels = [];
  
  List<String> _categories = ['All'];
  List<String> _languages = ['All'];
  List<String> _countries = ['All'];
  
  String _selectedCategory = 'All';
  String _selectedLanguage = 'All';
  String _selectedCountry = 'All';
  
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Dark IPTV theme colors
  static const Color _bgColor = Color(0xFF0D0D14);
  static const Color _surfaceColor = Color(0xFF1A1A2E);
  static const Color _cardColor = Color(0xFF16213E);
  static const Color _accentColor = Color(0xFF9C27B0);
  static const Color _accentLight = Color(0xFFCE93D8);
  static const Color _textPrimary = Color(0xFFE8EAF6);
  static const Color _textSecondary = Color(0xFF7986CB);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fetchChannels();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredChannels = _allChannels.where((channel) {
        final name = (channel['name'] ?? '').toString().toLowerCase();
        final cat = (channel['parsed_category'] ?? '').toString().toLowerCase();
        final lang = (channel['parsed_language'] ?? '').toString().toLowerCase();
        final country = (channel['parsed_country'] ?? '').toString().toLowerCase();

        final matchesSearch = query.isEmpty || name.contains(query) || cat.contains(query);
        final matchesCategory = _selectedCategory == 'All' || cat == _selectedCategory.toLowerCase();
        final matchesLanguage = _selectedLanguage == 'All' || lang == _selectedLanguage.toLowerCase();
        final matchesCountry = _selectedCountry == 'All' || country == _selectedCountry.toLowerCase();

        return matchesSearch && matchesCategory && matchesLanguage && matchesCountry;
      }).toList();
    });
  }

  String _extractCategory(dynamic channel) {
    if (channel['categories'] is List && (channel['categories'] as List).isNotEmpty) {
      return (channel['categories'] as List).first.toString();
    }
    return channel['category']?.toString() ?? 'general';
  }

  String _extractLanguage(dynamic channel) {
    if (channel['languages'] is List && (channel['languages'] as List).isNotEmpty) {
      return (channel['languages'] as List).first.toString();
    }
    return channel['language']?.toString() ?? 'unknown';
  }

  String _extractCountry(dynamic channel) {
    return channel['country']?.toString() ?? 'unknown';
  }

  Future<void> _fetchChannels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final channelsResponse = await http.get(Uri.parse('https://iptv-org.github.io/api/channels.json'));
      final streamsResponse = await http.get(Uri.parse('https://iptv-org.github.io/api/streams.json'));

      if (channelsResponse.statusCode == 200 && streamsResponse.statusCode == 200) {
        final List<dynamic> channelsData = json.decode(channelsResponse.body);
        final List<dynamic> streamsData = json.decode(streamsResponse.body);

        Map<String, String> channelStreams = {};
        for (var stream in streamsData) {
          if (stream['channel'] != null && stream['url'] != null) {
            channelStreams[stream['channel']] = stream['url'];
          }
        }

        List<dynamic> activeChannels = [];
        Set<String> cats = {};
        Set<String> langs = {};
        Set<String> countries = {};

        for (var channel in channelsData) {
          if (channel['id'] != null && channelStreams.containsKey(channel['id'])) {
            channel['stream_url'] = channelStreams[channel['id']];
            
            final cat = _extractCategory(channel);
            final lang = _extractLanguage(channel);
            final country = _extractCountry(channel);

            channel['parsed_category'] = cat;
            channel['parsed_language'] = lang;
            channel['parsed_country'] = country;
            
            cats.add(cat);
            langs.add(lang);
            countries.add(country);
            
            activeChannels.add(channel);
          }
        }

        final sortedCats = cats.toList()..sort();
        final sortedLangs = langs.toList()..sort();
        final sortedCountries = countries.toList()..sort();

        setState(() {
          _allChannels = activeChannels;
          _filteredChannels = activeChannels;
          _categories = ['All', ...sortedCats];
          _languages = ['All', ...sortedLangs];
          _countries = ['All', ...sortedCountries];
          
          _selectedCategory = 'All';
          _selectedLanguage = 'All';
          _selectedCountry = 'All';
          _isLoading = false;
        });
        _fadeController.forward();
      } else {
        setState(() {
          _errorMessage = 'Failed to load channels.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            if (!_isLoading && _errorMessage.isEmpty) _buildFiltersRow(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accentColor, Color(0xFF3F51B5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.live_tv_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IPTV Stream',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (!_isLoading && _errorMessage.isEmpty)
                Text(
                  '${_filteredChannels.length} channels live',
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _fetchChannels,
            icon: const Icon(Icons.refresh_rounded, color: _textSecondary),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isSearching ? _accentColor.withOpacity(0.6) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onTap: () => setState(() => _isSearching = true),
          onSubmitted: (_) => setState(() => _isSearching = false),
          style: const TextStyle(color: _textPrimary, fontSize: 15),
          cursorColor: _accentLight,
          decoration: InputDecoration(
            hintText: 'Search channels or categories...',
            hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: _textSecondary, size: 22),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: _textSecondary, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _isSearching = false);
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          _buildDropdown('Category', _categories, _selectedCategory, (val) {
            setState(() => _selectedCategory = val!);
            _applyFilters();
          }),
          const SizedBox(width: 8),
          _buildDropdown('Language', _languages, _selectedLanguage, (val) {
            setState(() => _selectedLanguage = val!);
            _applyFilters();
          }),
          const SizedBox(width: 8),
          _buildDropdown('Country', _countries, _selectedCountry, (val) {
            setState(() => _selectedCountry = val!);
            _applyFilters();
          }),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String selectedValue, ValueChanged<String?> onChanged) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: selectedValue == 'All' ? _surfaceColor : _accentColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selectedValue == 'All' ? Colors.transparent : _accentColor.withOpacity(0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          dropdownColor: _surfaceColor,
          icon: Icon(Icons.keyboard_arrow_down_rounded, 
            color: selectedValue == 'All' ? _textSecondary : _accentLight, 
            size: 20
          ),
          style: TextStyle(
            color: selectedValue == 'All' ? _textSecondary : _textPrimary, 
            fontSize: 13, 
            fontWeight: selectedValue == 'All' ? FontWeight.normal : FontWeight.w600
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item == 'All' ? label : item.toUpperCase()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: _accentLight,
                backgroundColor: _surfaceColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Loading channels...', style: TextStyle(color: _textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.signal_wifi_bad_rounded, color: _textSecondary, size: 56),
              const SizedBox(height: 16),
              const Text('Unable to load channels', style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_errorMessage, style: const TextStyle(color: _textSecondary, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchChannels,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredChannels.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: _textSecondary, size: 52),
            SizedBox(height: 12),
            Text('No channels found', style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Try a different search or filter', style: TextStyle(color: _textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _filteredChannels.length,
        itemBuilder: (context, index) => _buildChannelCard(_filteredChannels[index]),
      ),
    );
  }

  Widget _buildChannelCard(dynamic channel) {
    final name = channel['name'] ?? 'Unknown Channel';
    final category = channel['parsed_category'] ?? 'general';
    final language = channel['parsed_language'] ?? 'unknown';
    final country = channel['parsed_country'] ?? 'unknown';
    final logo = channel['logo']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              channelName: name,
              streamUrl: channel['stream_url'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: _accentColor.withOpacity(0.15),
              highlightColor: _accentColor.withOpacity(0.05),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerScreen(
                      channelName: name,
                      streamUrl: channel['stream_url'],
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Logo / avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: logo.isNotEmpty
                          ? Image.network(
                              logo,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _fallbackIcon(),
                            )
                          : _fallbackIcon(),
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildBadge(category.toUpperCase(), _accentColor.withOpacity(0.15), _accentLight),
                                const SizedBox(width: 6),
                                if (language != 'unknown') ...[
                                  _buildBadge(language.toUpperCase(), Colors.blue.withOpacity(0.15), Colors.blue[300]!),
                                  const SizedBox(width: 6),
                                ],
                                if (country != 'unknown')
                                  _buildBadge(country.toUpperCase(), Colors.green.withOpacity(0.15), Colors.green[300]!),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Play button
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_accentColor, Color(0xFF3F51B5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _fallbackIcon() {
    return const Center(
      child: Icon(Icons.live_tv_rounded, color: _textSecondary, size: 28),
    );
  }
}
