// lib/main.dart
// Improved "Rabari Samaj" single-file Flutter app (Option C)
// Features:
// - Splash screen with animation
// - Centralized theme (light/dark)
// - Bottom navigation (7 tabs)
// - Global search (News, Jobs, Sakha)
// - Marriage application form saved locally via shared_preferences
// - 120 placeholder Sakha names (replace easily with real ones)
// - URL launcher with error handling
// - Comments for future Firestore integration and assets

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart'; // optional

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RabariApp());
}

// ------------------------ RabariApp ------------------------
class RabariApp extends StatefulWidget {
  @override
  State<RabariApp> createState() => _RabariAppState();
}

class _RabariAppState extends State<RabariApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      primarySwatch: createMaterialColor(const Color(0xFF800000)), // maroon
      colorScheme: ColorScheme.fromSwatch().copyWith(
        secondary: const Color(0xFFD4AF37), // gold
      ),
      textTheme: GoogleFonts.notoSansTextTheme(), // optional nice font
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    final darkTheme = ThemeData.dark().copyWith(
      colorScheme: ColorScheme.dark().copyWith(secondary: const Color(0xFFD4AF37)),
      textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),
    );

    return MaterialApp(
      title: 'Rabari Samaj',
      debugShowCheckedModeBanner: false,
      theme: baseTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: SplashWrapper(
        onThemeToggle: () {
          setState(() {
            _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
          });
        },
      ),
    );
  }
}

// ------------------------ SplashWrapper ------------------------
// Shows animated splash, then MainPage
class SplashWrapper extends StatefulWidget {
  final VoidCallback onThemeToggle;
  SplashWrapper({required this.onThemeToggle});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _controller.forward();
    // Simulate loading (e.g., initialize local DB or Firebase here)
    Future.delayed(const Duration(milliseconds: 1400), () {
      setState(() => _done = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_done) {
      return Scaffold(
        body: Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
            child: SplashLogo(),
          ),
        ),
      );
    } else {
      return MainPage(onThemeToggle: widget.onThemeToggle);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ------------------------ SplashLogo ------------------------
class SplashLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Try to load asset; if missing, fallback to Icon
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Builder(builder: (c) {
          // You should add assets/images/logo.png to your project.
          // If not present, icon is shown.
          try {
            return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
          } catch (_) {
            return Container(
              color: Theme.of(c).colorScheme.primary,
              child: Center(
                child: Icon(Icons.group, size: 72, color: Colors.white),
              ),
            );
          }
        }),
      ),
    );
  }
}

// ------------------------ MainPage ------------------------
class MainPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  MainPage({required this.onThemeToggle});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = <Widget>[
    NewsScreen(),
    RulesScreen(),
    OriginScreen(),
    JobsScreen(),
    SakhaScreen(),
    MarriageScreen(),
    TempleScreen(),
  ];

  static final List<String> _titles = [
    'સમાસાર',
    'કાયદા',
    'ઉત્પત્તિ',
    'નોકરી',
    '120 સાખ',
    'બેસણું',
    'મંદિર'
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  Future<void> _openSearch() async {
    final results = await showSearch<SearchResult>(
      context: context,
      delegate: GlobalSamajSearchDelegate(),
    );

    // If user tapped a result, navigate accordingly
    if (results != null) {
      if (results.type == SearchType.news) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetail(results.payload as Map<String, String>)));
      } else if (results.type == SearchType.job) {
        // Show job detail dialog
        final job = results.payload as Map<String, String>;
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: Text(job['title'] ?? ''),
                  content: Text('Qualification: ${job['qual'] ?? ''}\nLast Date: ${job['lastDate'] ?? ''}'),
                ));
      } else if (results.type == SearchType.sakha) {
        final name = results.payload as String;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected sakha: $name')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _titles[_selectedIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: _openSearch),
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.onThemeToggle,
            tooltip: 'Toggle theme',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF800000), Color(0xFF4A0000)]),
          ),
        ),
      ),
      body: AnimatedSwitcher(duration: Duration(milliseconds: 300), child: _screens[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey[600],
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'સમાસાર'),
          BottomNavigationBarItem(icon: Icon(Icons.rule_folder), label: 'કાયદા'),
          BottomNavigationBarItem(icon: Icon(Icons.history_edu), label: 'ઉત્પત્તિ'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'નોકરી'),
          BottomNavigationBarItem(icon: Icon(Icons.format_list_numbered), label: '120 સાખ'),
          BottomNavigationBarItem(icon: Icon(Icons.family_restroom), label: 'બેસણું'),
          BottomNavigationBarItem(icon: Icon(Icons.temple_hindu), label: 'મંદિર'),
        ],
      ),
      floatingActionButton: _selectedIndex == 5
          ? FloatingActionButton.extended(
              icon: Icon(Icons.send),
              label: Text('Saved Apps'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SavedApplicationsScreen())),
            )
          : null,
    );
  }
}

// ------------------------ Search infrastructure ------------------------
enum SearchType { news, job, sakha }

class SearchResult {
  final SearchType type;
  final Object payload;
  SearchResult(this.type, this.payload);
}

class GlobalSamajSearchDelegate extends SearchDelegate<SearchResult> {
  // In a real app, fetch these from DB or API
  final List<Map<String, String>> news = DataRepository.news;
  final List<Map<String, String>> jobs = DataRepository.jobs;
  final List<String> sakhas = DataRepository.sakha120;

  @override
  String get searchFieldLabel => 'Search news, jobs, sakha...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context);
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [if (query.isNotEmpty) IconButton(onPressed: () => query = '', icon: Icon(Icons.clear))];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) {
    final results = _searchAll(query);
    return _resultsList(context, results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = _searchAll(query);
    return _resultsList(context, results);
  }

  List<SearchResult> _searchAll(String q) {
    final lower = q.toLowerCase();
    final List<SearchResult> res = [];
    if (q.isEmpty) return res;
    for (final n in news) {
      if ((n['title'] ?? '').toLowerCase().contains(lower) || (n['content'] ?? '').toLowerCase().contains(lower)) {
        res.add(SearchResult(SearchType.news, n));
      }
    }
    for (final j in jobs) {
      if ((j['title'] ?? '').toLowerCase().contains(lower) || (j['qual'] ?? '').toLowerCase().contains(lower)) {
        res.add(SearchResult(SearchType.job, j));
      }
    }
    for (final s in sakhas) {
      if (s.toLowerCase().contains(lower)) {
        res.add(SearchResult(SearchType.sakha, s));
      }
    }
    return res;
  }

  Widget _resultsList(BuildContext context, List<SearchResult> results) {
    if (results.isEmpty) {
      return Center(child: Text('No results'));
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => Divider(height: 1),
      itemBuilder: (context, i) {
        final r = results[i];
        if (r.type == SearchType.news) {
          final n = r.payload as Map<String, String>;
          return ListTile(
            leading: Icon(Icons.article_outlined),
            title: Text(n['title'] ?? ''),
            subtitle: Text(n['date'] ?? ''),
            onTap: () => close(context, r),
          );
        } else if (r.type == SearchType.job) {
          final j = r.payload as Map<String, String>;
          return ListTile(
            leading: Icon(Icons.work_outline),
            title: Text(j['title'] ?? ''),
            subtitle: Text(j['qual'] ?? ''),
            onTap: () => close(context, r),
          );
        } else {
          final s = r.payload as String;
          return ListTile(
            leading: Icon(Icons.person),
            title: Text(s),
            onTap: () => close(context, r),
          );
        }
      },
    );
  }
}

// ------------------------ DataRepository (local data) ------------------------
class DataRepository {
  // Sample news - replace with real dynamic data or Firestore
  static final List<Map<String, String>> news = [
    {
      'title': 'Samaj Meeting at Bhavan',
      'date': '28 Nov 2025',
      'content': 'Annual meeting will discuss samaj activities and upcoming festival plans.'
    },
    {
      'title': 'Festival Mela Photos Uploaded',
      'date': '15 Nov 2025',
      'content': 'Photos from the recent mela are available in Gallery.'
    },
  ];

  // Sample jobs - replace with real jobs
  static final List<Map<String, String>> jobs = [
    {
      'title': 'Primary School Teacher (Taluka)',
      'qual': 'B.Ed required',
      'lastDate': '10 Dec 2025',
      'apply': 'https://example.com/apply'
    },
    {
      'title': 'Clerical Staff (Gram Panchayat)',
      'qual': '10+2',
      'lastDate': '05 Dec 2025',
      'apply': 'https://example.com/apply2'
    },
  ];

  // 120 placeholder sakha names — replace with real names as needed.
  static final List<String> sakha120 = List.generate(120, (i) => 'Sakha ${i + 1}');
}

// ------------------------ 1) News Screen ------------------------
class NewsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final news = DataRepository.news;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SectionTitle(title: 'સમાસાર'),
        const SizedBox(height: 8),
        ...news.map((n) => Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Icon(Icons.article_outlined),
                title: Text(n['title'] ?? ''),
                subtitle: Text(n['date'] ?? ''),
                trailing: Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetail(n))),
              ),
            )),
      ],
    );
  }
}

class NewsDetail extends StatelessWidget {
  final Map<String, String> news;
  NewsDetail(this.news);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(news['title'] ?? 'News'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(news['date'] ?? '', style: TextStyle(color: Colors.grey[700])),
          SizedBox(height: 12),
          Text(news['content'] ?? ''),
        ]),
      ),
    );
  }
}

// ------------------------ 2) Rules Screen ------------------------
class RulesScreen extends StatelessWidget {
  final Map<String, String> rules = {
    'Marriage Rules': '1) Matching gotra rules\n2) Consent process\n3) Respect elders and customs.',
    'General Conduct': 'Respect elders, participate in samaj events, follow cleanliness rules',
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SectionTitle(title: 'કાયદા'),
        const SizedBox(height: 8),
        ...rules.entries.map((e) => Card(
              child: ListTile(title: Text(e.key), subtitle: Text(e.value)),
            )),
      ],
    );
  }
}

// ------------------------ 3) Origin Screen ------------------------
class OriginScreen extends StatelessWidget {
  final String originText = '''
રબારી સમાજની ઉત્પત્તિ અને ઇતિહાસ:

રબારી સમાજ પરંપરાગત પશુપાલક સમાજ છે. તેઓ ગાય-ભેંસ અને અન્ય પશુઓ સાથે સંકળાયેલા રહ્યા છે. પ્રદેશ અને ઐતિહાસિક પરિસ્થિતિઓ મુજબ રબારી સમાજના રહેઠાણમાં ફેરફાર થયા.

(આ જગ્યામાં તમે વધારે વર્ણન, પરિવારચિત્રો અને તસવીરો ઉમેરી શકો.)
''';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle(title: 'ઉત્પત્તિ'),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            'https://picsum.photos/800/300?image=60',
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loading) => loading == null ? child : Container(height: 180, child: Center(child: CircularProgressIndicator())),
            errorBuilder: (_, __, ___) => Container(height: 180, color: Colors.grey[300], child: Center(child: Icon(Icons.broken_image))),
          ),
        ),
        const SizedBox(height: 12),
        Text(originText),
      ]),
    );
  }
}

// ------------------------ 4) Jobs Screen ------------------------
class JobsScreen extends StatelessWidget {
  final List<Map<String, String>> jobs = DataRepository.jobs;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: jobs.length,
      itemBuilder: (context, i) {
        final job = jobs[i];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(job['title'] ?? ''),
            subtitle: Text('${job['qual'] ?? ''} • Last Date: ${job['lastDate'] ?? ''}'),
            trailing: ElevatedButton(
              child: Text('Apply'),
              onPressed: () => _openApply(context, job['apply']),
            ),
          ),
        );
      },
    );
  }

  void _openApply(BuildContext context, String? urlString) async {
    if (urlString == null) return;
    final uri = Uri.tryParse(urlString);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid URL')));
      return;
    }
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot open link')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening link')));
    }
  }
}

// ------------------------ 5) Sakha Screen ------------------------
class SakhaScreen extends StatefulWidget {
  @override
  State<SakhaScreen> createState() => _SakhaScreenState();
}

class _SakhaScreenState extends State<SakhaScreen> {
  final List<String> sakhas = DataRepository.sakha120;
  List<String> filtered = [];

  @override
  void initState() {
    super.initState();
    filtered = List.from(sakhas);
  }

  void _search(String q) {
    setState(() {
      if (q.trim().isEmpty) {
        filtered = List.from(sakhas);
      } else {
        filtered = sakhas.where((s) => s.toLowerCase().contains(q.toLowerCase())).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          onChanged: _search,
          decoration: InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search 120 સાખ...', border: OutlineInputBorder()),
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          itemBuilder: (context, i) => Card(
            child: ListTile(title: Text(filtered[i])),
          ),
        ),
      ),
    ]);
  }
}

// ------------------------ 6) Marriage Screen + Form ------------------------
class MarriageScreen extends StatefulWidget {
  @override
  State<MarriageScreen> createState() => _MarriageScreenState();
}

class _MarriageScreenState extends State<MarriageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _detailsCtl = TextEditingController();
  bool _saving = false;

  Future<void> _saveApplication() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('applications') ?? [];
    final entry = '${DateTime.now().toIso8601String()}|${_nameCtl.text}|${_phoneCtl.text}|${_detailsCtl.text}';
    existing.add(entry);
    await prefs.setStringList('applications', existing);

    setState(() => _saving = false);
    _nameCtl.clear();
    _phoneCtl.clear();
    _detailsCtl.clear();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Application saved locally.')));
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _detailsCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle(title: 'બેસણું (Marriage Info)'),
        const SizedBox(height: 8),
        Text('Fill the form below to apply for marriage / seating. This saves locally.'),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _nameCtl,
              decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().length < 7) ? 'Enter valid phone' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailsCtl,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(labelText: 'Additional details', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            _saving
                ? CircularProgressIndicator()
                : Row(children: [
                    Expanded(child: ElevatedButton.icon(icon: Icon(Icons.save), label: Text('Save Application'), onPressed: _saveApplication)),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                        icon: Icon(Icons.list),
                        label: Text('View Saved'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SavedApplicationsScreen()))),
                  ])
          ]),
        ),
      ]),
    );
  }
}

// Screen to view saved marriage applications (local)
class SavedApplicationsScreen extends StatefulWidget {
  @override
  State<SavedApplicationsScreen> createState() => _SavedApplicationsScreenState();
}

class _SavedApplicationsScreenState extends State<SavedApplicationsScreen> {
  List<String> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('applications') ?? [];
    setState(() {
      _items = list.reversed.toList(); // newest first
      _loading = false;
    });
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('applications');
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('All saved applications removed.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Applications'),
        actions: [IconButton(icon: Icon(Icons.delete_forever), onPressed: _items.isEmpty ? null : _clearAll)],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text('No saved applications'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final parts = _items[i].split('|');
                    final date = parts.length > 0 ? parts[0] : '';
                    final name = parts.length > 1 ? parts[1] : '';
                    final phone = parts.length > 2 ? parts[2] : '';
                    final details = parts.length > 3 ? parts[3] : '';
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.person),
                        title: Text(name),
                        subtitle: Text('Phone: $phone\nDetails: $details\nDate: $date'),
                      ),
                    );
                  },
                ),
    );
  }
}

// ------------------------ 7) Temple Screen ------------------------
class TempleScreen extends StatelessWidget {
  final List<Map<String, String>> temples = [
    {'name': 'Main Samaj Temple', 'address': 'Samaj Bhavan, Village', 'timings': '6:00 AM - 9:00 PM', 'phone': '+91 98765 43210'},
    {'name': 'Shree Ranchhodji Temple', 'address': 'Near Bus Stand', 'timings': '5:00 AM - 8:00 PM', 'phone': '+91 91234 56789'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: temples.length,
      itemBuilder: (context, i) {
        final t = temples[i];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Icon(Icons.temple_hindu),
            title: Text(t['name'] ?? ''),
            subtitle: Text('${t['address'] ?? ''}\nTimings: ${t['timings'] ?? ''}'),
            isThreeLine: true,
            trailing: IconButton(icon: Icon(Icons.map), onPressed: () => _openMap(context, t['address'])),
            onTap: () => _openContact(context, t['phone']),
          ),
        );
      },
    );
  }

  void _openContact(BuildContext context, String? phone) {
    if (phone == null || phone.isEmpty) return;
    showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                  ListTile(leading: Icon(Icons.phone), title: Text(phone), onTap: () => Navigator.pop(context)),
                ]),
              ),
            ));
  }

  void _openMap(BuildContext context, String? address) async {
    if (address == null || address.isEmpty) return;
    final query = Uri.encodeComponent(address);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot open maps')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening maps')));
    }
  }
}

// ------------------------ Small UI Helpers ------------------------
class SectionTitle extends StatelessWidget {
  final String title;
  SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
  }
}

// ------------------------ Utilities ------------------------

// A small helper to create MaterialColor from single color
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;
  for (int i = 1; i < 10; i++) strengths.add(0.1 * i);
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}
