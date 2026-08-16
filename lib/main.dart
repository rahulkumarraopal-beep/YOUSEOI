import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const YouSeoApp());
}

class YouSeoApp extends StatelessWidget {
  const YouSeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YouSEO',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.red,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.red,
      ),
      themeMode: ThemeMode.system,
      home: const YouSeoHome(),
    );
  }
}

class VideoInfo {
  final String id;
  final String title;
  final String description;
  final String channel;
  final String thumbnail;
  final int views;
  final int likes;
  final int comments;
  final List<String> tags;

  const VideoInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.channel,
    required this.thumbnail,
    required this.views,
    required this.likes,
    required this.comments,
    required this.tags,
  });
}

class YouSeoHome extends StatefulWidget {
  const YouSeoHome({super.key});

  @override
  State<YouSeoHome> createState() => _YouSeoHomeState();
}

class _YouSeoHomeState extends State<YouSeoHome> {
  final urlController = TextEditingController();

  // Testing के लिए अपनी YouTube Data API v3 key डालें.
  // Production APK में API key सीधे रखना सुरक्षित नहीं है.
  static const String apiKey = 'YOUR_YOUTUBE_API_KEY';

  VideoInfo? video;
  bool loading = false;
  String error = '';

  List<String> keywords = [];
  List<String> titleSuggestions = [];

  int seoScore = 0;

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  String? extractVideoId(String url) {
    final patterns = [
      RegExp(r'youtu\.be/([A-Za-z0-9_-]{11})'),
      RegExp(r'youtube\.com/watch\?v=([A-Za-z0-9_-]{11})'),
      RegExp(r'youtube\.com/shorts/([A-Za-z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([A-Za-z0-9_-]{11})'),
      RegExp(r'youtube\.com/live/([A-Za-z0-9_-]{11})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url.trim());

      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  Future<void> analyzeVideo() async {
    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
      error = '';
      video = null;
      keywords = [];
      titleSuggestions = [];
      seoScore = 0;
    });

    try {
      final id = extractVideoId(urlController.text);

      if (id == null) {
        throw Exception('सही YouTube Video URL डालें।');
      }

      if (apiKey == 'YOUR_YOUTUBE_API_KEY') {
        throw Exception(
          'पहले main.dart में अपनी YouTube API Key डालें।',
        );
      }

      final uri = Uri.parse(
        'https://www.googleapis.com/youtube/v3/videos'
        '?part=snippet,statistics'
        '&id=$id'
        '&key=$apiKey',
      );

      final response = await http.get(uri);

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          data['error']?['message'] ?? 'YouTube API error',
        );
      }

      if (data['items'] == null || data['items'].isEmpty) {
        throw Exception('Video नहीं मिला।');
      }

      final item = data['items'][0];
      final snippet = item['snippet'] ?? {};
      final statistics = item['statistics'] ?? {};

      final rawTags = snippet['tags'] ?? [];

      final tags = (rawTags as List)
          .map((e) => e.toString())
          .toList();

      final result = VideoInfo(
        id: id,
        title: snippet['title'] ?? '',
        description: snippet['description'] ?? '',
        channel: snippet['channelTitle'] ?? '',
        thumbnail:
            snippet['thumbnails']?['high']?['url'] ??
            snippet['thumbnails']?['default']?['url'] ??
            '',
        views: int.tryParse(
              '${statistics['viewCount'] ?? 0}',
            ) ??
            0,
        likes: int.tryParse(
              '${statistics['likeCount'] ?? 0}',
            ) ??
            0,
        comments: int.tryParse(
              '${statistics['commentCount'] ?? 0}',
            ) ??
            0,
        tags: tags,
      );

      setState(() {
        video = result;
        keywords = generateKeywords(result);
        titleSuggestions = generateTitles(result);
        seoScore = calculateSeoScore(result);
      });
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  List<String> generateKeywords(VideoInfo video) {
    final cleaned = video.title
        .toLowerCase()
        .replaceAll(
          RegExp(
            r'[^\p{L}\p{N}\s]',
            unicode: true,
          ),
          ' ',
        );

    final words = cleaned
        .split(RegExp(r'\s+'))
        .where((word) => word.length >= 3);

    final result = <String>[];

    for (final word in words) {
      if (!result.contains(word)) {
        result.add(word);
      }
    }

    for (final tag in video.tags) {
      final lower = tag.toLowerCase();

      if (!result.contains(lower)) {
        result.add(lower);
      }
    }

    return result.take(30).toList();
  }

  List<String> generateTitles(VideoInfo video) {
    if (video.title.isEmpty) {
      return [];
    }

    return [
      '${video.title} | Complete Guide',
      '${video.title} | Full Details',
      '${video.title} | Everything You Need To Know',
      '${video.title} | Latest Update',
      '${video.title} | Explained in Hindi',
    ];
  }

  int calculateSeoScore(VideoInfo video) {
    int score = 0;

    if (video.title.isNotEmpty) {
      score += 20;
    }

    if (video.title.length >= 30 &&
        video.title.length <= 70) {
      score += 10;
    }

    if (video.description.isNotEmpty) {
      score += 15;
    }

    if (video.description.length >= 100) {
      score += 10;
    }

    if (video.tags.isNotEmpty) {
      score += 20;
    }

    if (video.tags.length >= 5) {
      score += 10;
    }

    if (video.thumbnail.isNotEmpty) {
      score += 5;
    }

    if (video.tags.any(
      (tag) => video.title
          .toLowerCase()
          .contains(tag.toLowerCase()),
    )) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  String formatNumber(int number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    }

    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }

    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }

    return '$number';
  }

  void copyText(String text) {
    Clipboard.setData(
      ClipboardData(text: text),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'YouSEO',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'YouTube SEO Analyzer',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 6),

              const Text(
                'अपने YouTube video का SEO analyze करें।',
              ),

              const SizedBox(height: 20),

              TextField(
                controller: urlController,
                keyboardType: TextInputType.url,
                onSubmitted: (_) => analyzeVideo(),
                decoration: InputDecoration(
                  labelText: 'YouTube Video Link',
                  hintText:
                      'https://youtube.com/watch?v=XXXXXXXXXXX',
                  prefixIcon:
                      const Icon(Icons.link),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      loading ? null : analyzeVideo,
                  icon: const Icon(
                    Icons.analytics,
                  ),
                  label: Text(
                    loading
                        ? 'Analyzing...'
                        : 'Analyze Video',
                  ),
                ),
              ),

              if (error.isNotEmpty) ...[
                const SizedBox(height: 16),

                Card(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer,
                  child: Padding(
                    padding:
                        const EdgeInsets.all(14),
                    child: Text(error),
                  ),
                ),
              ],

              if (loading) ...[
                const SizedBox(height: 30),

                const Center(
                  child:
                      CircularProgressIndicator(),
                ),
              ],

              if (video != null) ...[
                const SizedBox(height: 20),

                buildVideoCard(),

                const SizedBox(height: 16),

                buildScoreCard(),

                const SizedBox(height: 16),

                buildStatistics(),

                const SizedBox(height: 16),

                buildTitle(),

                const SizedBox(height: 16),

                buildTitleSuggestions(),

                const SizedBox(height: 16),

                buildDescription(),

                const SizedBox(height: 16),

                buildTags(),

                const SizedBox(height: 16),

                buildKeywords(),

                const SizedBox(height: 16),

                buildHashtags(),
              ],

              const SizedBox(height: 30),

              const Center(
                child: Text(
                  'YouSEO • YouTube SEO Analyzer',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildVideoCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          if (video!.thumbnail.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                video!.thumbnail,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) =>
                        const Center(
                  child: Icon(
                    Icons
                        .image_not_supported,
                    size: 50,
                  ),
                ),
              ),
            ),

          Padding(
            padding:
                const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  video!.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(video!.channel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildScoreCard() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'SEO SCORE',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: 125,
              height: 125,
              child: Stack(
                alignment:
                    Alignment.center,
                children: [
                  SizedBox(
                    width: 125,
                    height: 125,
                    child:
                        CircularProgressIndicator(
                      value:
                          seoScore / 100,
                      strokeWidth: 12,
                    ),
                  ),

                  Text(
                    '$seoScore',
                    style:
                        const TextStyle(
                      fontSize: 30,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Text(
              seoScore >= 80
                  ? 'Excellent SEO'
                  : seoScore >= 60
                      ? 'Good SEO'
                      : seoScore >= 40
                          ? 'Average SEO'
                          : 'Needs Improvement',
              style:
                  const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: statCard(
            Icons.visibility,
            'Views',
            formatNumber(
              video!.views,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: statCard(
            Icons.thumb_up,
            'Likes',
            formatNumber(
              video!.likes,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: statCard(
            Icons.comment,
            'Comments',
            formatNumber(
              video!.comments,
            ),
          ),
        ),
      ],
    );
  }

  Widget statCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 5,
        ),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 5),
            Text(
              value,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            Text(
              title,
              style:
                  const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget section(
    String title,
    IconData icon,
    Widget child,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            child,
          ],
        ),
      ),
    );
  }

  Widget buildTitle() {
    return section(
      'Video Title',
      Icons.title,
      Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            video!.title,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          TextButton.icon(
            onPressed: () =>
                copyText(video!.title),
            icon:
                const Icon(Icons.copy),
            label:
                const Text('Copy Title'),
          ),
        ],
      ),
    );
  }

  Widget buildTitleSuggestions() {
    return section(
      'SEO Title Suggestions',
      Icons.auto_awesome,
      Column(
        children:
            titleSuggestions.map(
          (title) {
            return ListTile(
              contentPadding:
                  EdgeInsets.zero,
              title: Text(title),
              trailing:
                  IconButton(
                icon:
                    const Icon(
                  Icons.copy,
                ),
                onPressed: () =>
                    copyText(title),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget buildDescription() {
    return section(
      'Description',
      Icons.description,
      Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            video!.description.isEmpty
                ? 'No description available.'
                : video!.description,
            maxLines: 12,
            overflow:
                TextOverflow.ellipsis,
          ),

          TextButton.icon(
            onPressed: () =>
                copyText(
              video!.description,
            ),
            icon:
                const Icon(Icons.copy),
            label: const Text(
              'Copy Description',
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTags() {
    return section(
      'YouTube Tags (${video!.tags.length})',
      Icons.sell,
      video!.tags.isEmpty
          ? const Text(
              'इस video में public tags उपलब्ध नहीं हैं।',
            )
          : Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      video!.tags.map(
                    (tag) {
                      return Chip(
                        label:
                            Text(tag),
                      );
                    },
                  ).toList(),
                ),

                TextButton.icon(
                  onPressed: () =>
                      copyText(
                    video!.tags.join(
                      ', ',
                    ),
                  ),
                  icon: const Icon(
                    Icons.copy,
                  ),
                  label: const Text(
                    'Copy All Tags',
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildKeywords() {
    return section(
      'SEO Keywords',
      Icons.key,
      Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                keywords.map(
              (keyword) {
                return Chip(
                  label:
                      Text(keyword),
                );
              },
            ).toList(),
          ),

          TextButton.icon(
            onPressed: () =>
                copyText(
              keywords.join(', '),
            ),
            icon:
                const Icon(Icons.copy),
            label:
                const Text(
              'Copy Keywords',
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHashtags() {
    final hashtags = keywords
        .take(15)
        .map(
          (keyword) =>
              '#${keyword.replaceAll(RegExp(r'\s+'), '')}',
        )
        .toList();

    return section(
      'Hashtags',
      Icons.tag,
      Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            hashtags.join(' '),
            style:
                const TextStyle(
              height: 1.6,
            ),
          ),

          TextButton.icon(
            onPressed: () =>
                copyText(
              hashtags.join(' '),
            ),
            icon:
                const Icon(Icons.copy),
            label:
                const Text(
              'Copy Hashtags',
            ),
          ),
        ],
      ),
    );
  }
}
