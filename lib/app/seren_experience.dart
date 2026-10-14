import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

const _ink = Color(0xFF101715);
const _surface = Color(0xFF192320);
const _line = Color(0xFF34423D);
const _muted = Color(0xFFABB9B2);
const _white = Color(0xFFF5F7F3);
const _accent = Color(0xFFA8D7C6);

enum _Mood { focus, relax, sleep }

extension on _Mood {
  String get label => switch (this) {
    _Mood.focus => 'Focus',
    _Mood.relax => 'Relax',
    _Mood.sleep => 'Sleep',
  };

  String get subtitle => switch (this) {
    _Mood.focus => 'Clear sounds. A sharper mind.',
    _Mood.relax => 'Slow down. Breathe deeper.',
    _Mood.sleep => 'A calmer night. A brighter you.',
  };

  String get shortSubtitle => switch (this) {
    _Mood.focus => 'Boost productivity',
    _Mood.relax => 'Calm your mind',
    _Mood.sleep => 'Drift off easier',
  };

  IconData get icon => switch (this) {
    _Mood.focus => Icons.center_focus_strong_rounded,
    _Mood.relax => Icons.nightlight_round,
    _Mood.sleep => Icons.bed_outlined,
  };

  String get backgroundImage => switch (this) {
    _Mood.focus => 'assets/cover_iamge/forest_rain.png',
    _Mood.relax => 'assets/cover_iamge/sea_waves.png',
    _Mood.sleep => 'assets/cover_iamge/night_ambiance_cover_image.png',
  };

  Color get backgroundColor => switch (this) {
    _Mood.focus => const Color(0xFF071913),
    _Mood.relax => const Color(0xFF091925),
    _Mood.sleep => const Color(0xFF0B1322),
  };

  Color get accentColor => switch (this) {
    _Mood.focus => const Color(0xFFA7D1B8),
    _Mood.relax => const Color(0xFFA9D0E3),
    _Mood.sleep => const Color(0xFFB5C4E2),
  };
}

class _Sound {
  const _Sound(
    this.title,
    this.category,
    this.description,
    this.image,
    this.audio,
    this.moods,
  );

  final String title;
  final String category;
  final String description;
  final String image;
  final String audio;
  final Set<_Mood> moods;
}

const _sounds = <_Sound>[
  _Sound(
    'Ocean Waves',
    'Nature',
    'A steady rhythm to calm the mind.',
    'assets/cover_iamge/sea_waves.png',
    'assets/audio/sea_water.mp3',
    {_Mood.relax, _Mood.sleep},
  ),
  _Sound(
    'Forest Rain',
    'Nature',
    'Nature\'s rhythm. A calmer mind.',
    'assets/cover_iamge/forest_rain.png',
    'assets/audio/forest_rain.mp3',
    {_Mood.focus, _Mood.relax},
  ),
  _Sound(
    'White Noise',
    'Ambient',
    'A quiet space to think clearly.',
    'assets/cover_iamge/white_noise.png',
    'assets/audio/white_noise.mp3',
    {_Mood.focus, _Mood.sleep},
  ),
  _Sound(
    'Peaceful Piano',
    'Instrumental',
    'Soft melodies for a quiet moment.',
    'assets/cover_iamge/piano.png',
    'assets/audio/peaceful_piano.mp3',
    {_Mood.focus, _Mood.relax},
  ),
  _Sound(
    'Night Ambience',
    'Sleep',
    'Ease into rest with the sounds of night.',
    'assets/cover_iamge/night_ambiance_cover_image.png',
    'assets/audio/night_ambiance.mp3',
    {_Mood.relax, _Mood.sleep},
  ),
  _Sound(
    'Deep Focus',
    'Ambient',
    'A steady soundscape for uninterrupted concentration.',
    'assets/cover_iamge/white_noise.png',
    'assets/audio/deep_focus1.mp3',
    {_Mood.focus},
  ),
  _Sound(
    'Flow State',
    'Ambient',
    'Settle into a clear and productive rhythm.',
    'assets/cover_iamge/white_noise.png',
    'assets/audio/deep_focus2.mp3',
    {_Mood.focus},
  ),
  _Sound(
    'Quiet Work',
    'Ambient',
    'Subtle texture for calm, sustained attention.',
    'assets/cover_iamge/piano.png',
    'assets/audio/deep_focus3.mp3',
    {_Mood.focus},
  ),
  _Sound(
    'Clear Mind',
    'Ambient',
    'Create space for your next thoughtful session.',
    'assets/cover_iamge/white_noise.png',
    'assets/audio/deep_focus4.mp3',
    {_Mood.focus, _Mood.relax},
  ),
  _Sound(
    'Cafe Ambience',
    'Urban',
    'A gentle cafe hum for reading and creative work.',
    'assets/cover_iamge/piano.png',
    'assets/audio/coffee_place.mp3',
    {_Mood.focus, _Mood.relax},
  ),
  _Sound(
    'Coffee Shop',
    'Urban',
    'Warm background bustle without the distraction.',
    'assets/cover_iamge/piano.png',
    'assets/audio/coffee_place2.mp3',
    {_Mood.focus, _Mood.relax},
  ),
  _Sound(
    'Cozy Fireplace',
    'Home',
    'Soft crackling warmth for a slower evening.',
    'assets/cover_iamge/night_ambiance_cover_image.png',
    'assets/audio/fireplace_1.mp3',
    {_Mood.relax, _Mood.sleep},
  ),
  _Sound(
    'Evening Fireplace',
    'Home',
    'Wind down beside the steady glow of the fire.',
    'assets/cover_iamge/night_ambiance_cover_image.png',
    'assets/audio/fireplace_2.mp3',
    {_Mood.relax, _Mood.sleep},
  ),
  _Sound(
    'Mountain Stream',
    'Water',
    'Fresh running water for a peaceful reset.',
    'assets/cover_iamge/sea_waves.png',
    'assets/audio/mountain_stream.mp3',
    {_Mood.focus, _Mood.relax},
  ),
  _Sound(
    'Mountain Creek',
    'Water',
    'A quiet current moving through the hills.',
    'assets/cover_iamge/sea_waves.png',
    'assets/audio/mountain_stream_2.mp3',
    {_Mood.relax, _Mood.sleep},
  ),
  _Sound(
    'Outdoor Rain',
    'Nature',
    'Open-air rainfall to soften a busy mind.',
    'assets/cover_iamge/forest_rain.png',
    'assets/audio/outdoor_rain.mp3',
    {_Mood.relax, _Mood.sleep},
  ),
  _Sound(
    'Rain on Window',
    'Nature',
    'Gentle drops against the glass as the world slows.',
    'assets/cover_iamge/forest_rain.png',
    'assets/audio/rain_window.mp3',
    {_Mood.focus, _Mood.relax, _Mood.sleep},
  ),
  _Sound(
    'Deep Space',
    'Ambient',
    'A spacious atmosphere for deep rest and focus.',
    'assets/cover_iamge/night_ambiance_cover_image.png',
    'assets/audio/space_1.mp3',
    {_Mood.focus, _Mood.sleep},
  ),
  _Sound(
    'Cosmic Drift',
    'Ambient',
    'Float into a slower, quieter state of mind.',
    'assets/cover_iamge/night_ambiance_cover_image.png',
    'assets/audio/space_2.mp3',
    {_Mood.relax, _Mood.sleep},
  ),
  _Sound(
    'Starlight',
    'Ambient',
    'A dark, weightless soundscape for bedtime.',
    'assets/cover_iamge/night_ambiance_cover_image.png',
    'assets/audio/space_3.mp3',
    {_Mood.sleep},
  ),
  _Sound(
    'Celestial Calm',
    'Ambient',
    'Slow-moving tones for reflection and rest.',
    'assets/cover_iamge/night_ambiance_cover_image.png',
    'assets/audio/space_4.mp3',
    {_Mood.relax, _Mood.sleep},
  ),
  _Sound(
    'Flowing Stream',
    'Water',
    'A clear natural current to settle your thoughts.',
    'assets/cover_iamge/sea_waves.png',
    'assets/audio/stream_water.mp3',
    {_Mood.focus, _Mood.relax},
  ),
  _Sound(
    'Gentle Stream',
    'Water',
    'Rest beside a soft and unhurried stream.',
    'assets/cover_iamge/sea_waves.png',
    'assets/audio/stream_water1.mp3',
    {_Mood.relax, _Mood.sleep},
  ),
  _Sound(
    'Soft Wind',
    'Nature',
    'A light breeze to release tension and unwind.',
    'assets/cover_iamge/forest_rain.png',
    'assets/audio/wind.mp3',
    {_Mood.relax, _Mood.sleep},
  ),
  _Sound(
    'Soft White Noise',
    'Ambient',
    'A smooth veil of sound for focus or sleep.',
    'assets/cover_iamge/white_noise.png',
    'assets/audio/alt_white_noise.mp3',
    {_Mood.focus, _Mood.sleep},
  ),
  _Sound(
    'Deep White Noise',
    'Ambient',
    'A fuller noise bed to mask nearby distractions.',
    'assets/cover_iamge/white_noise.png',
    'assets/audio/alt_white_noise2.mp3',
    {_Mood.focus, _Mood.sleep},
  ),
];

_Sound _soundWithAudio(String audio) =>
    _sounds.firstWhere((sound) => sound.audio == audio);

class SerenExperience extends StatefulWidget {
  const SerenExperience({super.key});

  @override
  State<SerenExperience> createState() => _SerenExperienceState();
}

class _SerenExperienceState extends State<SerenExperience> {
  final _player = AudioPlayer();
  final _saved = <String>{};
  final _recent = <String>[];
  _Sound _selected = _sounds.first;
  _Mood? _category;
  int _tab = 0;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _showPlayer = false;
  String? _loadedAsset;
  Timer? _sleepTimer;
  int? _sleepMinutes;

  String get _libraryKey =>
      'saved_sounds_${Supabase.instance.client.auth.currentUser?.id ?? 'local'}';
  String get _recentKey =>
      'recent_sounds_${Supabase.instance.client.auth.currentUser?.id ?? 'local'}';

  @override
  void initState() {
    super.initState();
    unawaited(_loadPreferences());
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getStringList(_libraryKey) ?? const <String>[];
    final recent = preferences.getStringList(_recentKey) ?? const <String>[];
    if (mounted) {
      setState(() {
        _saved.addAll(saved);
        _recent.addAll(
          recent.where((audio) => _sounds.any((sound) => sound.audio == audio)),
        );
      });
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle(_Sound sound) async {
    if (_isLoading) return;
    if (_selected.audio != sound.audio) setState(() => _selected = sound);
    if (_loadedAsset == sound.audio && _isPlaying) {
      await _player.pause();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }
    if (_loadedAsset != sound.audio) {
      setState(() {
        _isLoading = true;
        _selected = sound;
        _isPlaying = false;
      });
      try {
        await _player.setAsset(sound.audio);
        await _player.setLoopMode(LoopMode.one);
        _loadedAsset = sound.audio;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This sound could not be loaded.')),
          );
        }
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isPlaying = true;
    });
    unawaited(_player.play());
  }

  void _openSound(_Sound sound) {
    if (_loadedAsset != sound.audio && _isPlaying) {
      unawaited(_player.pause());
    }
    setState(() {
      _selected = sound;
      _recent
        ..remove(sound.audio)
        ..insert(0, sound.audio);
      if (_recent.length > 3) _recent.removeRange(3, _recent.length);
      if (_loadedAsset != sound.audio) _isPlaying = false;
      _showPlayer = true;
    });
    unawaited(_persistRecent());
  }

  void _playAndOpen(_Sound sound) {
    _openSound(sound);
    unawaited(_toggle(sound));
  }

  void _toggleSaved(_Sound sound) {
    setState(() {
      if (!_saved.add(sound.audio)) _saved.remove(sound.audio);
    });
    unawaited(_persistSaved());
  }

  Future<void> _persistSaved() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_libraryKey, _saved.toList());
  }

  Future<void> _persistRecent() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_recentKey, _recent);
  }

  void _setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    setState(() => _sleepMinutes = minutes);
    if (minutes != null) {
      _sleepTimer = Timer(Duration(minutes: minutes), () async {
        await _player.pause();
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _sleepMinutes = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentSounds = _recent
        .map((audio) => _sounds.firstWhere((sound) => sound.audio == audio))
        .toList();
    final pages = [
      _PersonalHomeScreen(
        selected: _selected,
        isPlaying: _isPlaying,
        recent: recentSounds,
        onOpen: _openSound,
        onPlay: _playAndOpen,
        onExplore: () => setState(() => _tab = 1),
      ),
      _ExploreScreen(
        onOpen: _openSound,
        onPlay: _playAndOpen,
        playing: _isPlaying ? _selected.audio : null,
        category: _category,
        onCategory: (mood) => setState(() => _category = mood),
      ),
      _LibraryScreen(
        sounds: _sounds.where((sound) => _saved.contains(sound.audio)).toList(),
        onOpen: _openSound,
        onPlay: _playAndOpen,
        playing: _isPlaying ? _selected.audio : null,
        onExplore: () => setState(() => _tab = 1),
      ),
      const _ProfileScreen(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: Theme.of(context).copyWith(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: _ink,
          colorScheme: const ColorScheme.dark(
            primary: _accent,
            surface: _surface,
          ),
        ),
        child: Scaffold(
          backgroundColor: _ink,
          extendBody: true,
          body: Stack(
            children: [
              IndexedStack(index: _tab, children: pages),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_showPlayer,
                  child: AnimatedSlide(
                    offset: _showPlayer ? Offset.zero : const Offset(0, 1),
                    duration: const Duration(milliseconds: 440),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: _showPlayer ? 1 : 0,
                      duration: const Duration(milliseconds: 260),
                      child: _PlayerScreen(
                        sound: _selected,
                        playing: _isPlaying,
                        saved: _saved.contains(_selected.audio),
                        sleepMinutes: _sleepMinutes,
                        onClose: () => setState(() => _showPlayer = false),
                        onPlay: () => _toggle(_selected),
                        onSave: () => _toggleSaved(_selected),
                        onTimer: _setSleepTimer,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _showPlayer
              ? null
              : _DarkNavigation(
                  selected: _tab,
                  onTap: (index) => setState(() {
                    _tab = index;
                    _category = null;
                    _showPlayer = false;
                  }),
                ),
        ),
      ),
    );
  }
}

class _PlayerScreen extends StatelessWidget {
  const _PlayerScreen({
    required this.sound,
    required this.playing,
    required this.saved,
    required this.sleepMinutes,
    required this.onClose,
    required this.onPlay,
    required this.onSave,
    required this.onTimer,
  });

  final _Sound sound;
  final bool playing;
  final bool saved;
  final int? sleepMinutes;
  final VoidCallback onClose;
  final VoidCallback onPlay;
  final VoidCallback onSave;
  final ValueChanged<int?> onTimer;

  void _showTimer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Sleep timer', style: _sectionTitle),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              for (final minutes in <int?>[null, 15, 30, 60, 120])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    minutes == null
                        ? 'Off'
                        : minutes == 60
                        ? '1 hour'
                        : minutes == 120
                        ? '2 hours'
                        : '$minutes minutes',
                  ),
                  trailing: sleepMinutes == minutes
                      ? const Icon(Icons.check, color: _accent)
                      : null,
                  onTap: () {
                    onTimer(minutes);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final art = math.min(size.width * 0.56, 250.0);
    double? dragStartY;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => dragStartY = event.position.dy,
      onPointerUp: (event) {
        if (dragStartY != null && event.position.dy - dragStartY! > 90) {
          onClose();
        }
      },
      child: Material(
        color: _ink,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(sound.image, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0xD9091411)),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 490),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: onClose,
                              tooltip: 'Close player',
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 30,
                                color: _white,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: onSave,
                              tooltip: saved
                                  ? 'Remove from library'
                                  : 'Add to library',
                              icon: Icon(
                                saved
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: saved ? _accent : _white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: math.max(18, size.height * 0.045)),
                        Text(
                          sound.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _white,
                            fontSize: 29,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          sound.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _muted, fontSize: 14),
                        ),
                        SizedBox(height: math.max(26, size.height * 0.065)),
                        Container(
                          width: art,
                          height: art,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _accent, width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x664F967B),
                                blurRadius: 36,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(sound.image, fit: BoxFit.cover),
                          ),
                        ),
                        SizedBox(height: math.max(34, size.height * 0.065)),
                        _PlayCircle(playing: playing, onTap: onPlay, size: 72),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _PlayerTool(
                              icon: Icons.timer_outlined,
                              label: sleepMinutes == null
                                  ? 'Timer'
                                  : '$sleepMinutes min',
                              onTap: () => _showTimer(context),
                            ),
                            _PlayerTool(
                              icon: saved
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              label: saved ? 'Saved' : 'Save',
                              onTap: onSave,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerTool extends StatelessWidget {
  const _PlayerTool({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Icon(icon, color: _white, size: 25),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      ),
    ),
  );
}

class _DarkNavigation extends StatelessWidget {
  const _DarkNavigation({required this.selected, required this.onTap});

  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const items = <(IconData, String)>[
      (Icons.home_outlined, 'Home'),
      (Icons.explore_outlined, 'Explore'),
      (Icons.library_music_outlined, 'Library'),
      (Icons.person_outline_rounded, 'Profile'),
    ];
    return Container(
      height: 72 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF151C19),
        border: Border(top: BorderSide(color: _line, width: 0.6)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      items[i].$1,
                      size: 23,
                      color: i == selected ? _white : _muted,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      items[i].$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: i == selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: i == selected ? _white : _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PersonalHomeScreen extends StatelessWidget {
  const _PersonalHomeScreen({
    required this.selected,
    required this.isPlaying,
    required this.recent,
    required this.onOpen,
    required this.onPlay,
    required this.onExplore,
  });

  final _Sound selected;
  final bool isPlaying;
  final List<_Sound> recent;
  final ValueChanged<_Sound> onOpen;
  final ValueChanged<_Sound> onPlay;
  final VoidCallback onExplore;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return _DarkScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          Text(_greeting, style: _pageTitle),
          const SizedBox(height: 6),
          const Text(
            'Take a moment for yourself.',
            style: TextStyle(color: _muted, fontSize: 15),
          ),
          const SizedBox(height: 30),
          const Text('Continue Listening', style: _sectionTitle),
          const SizedBox(height: 12),
          _ContinueListeningCard(
            sound: selected,
            isPlaying: isPlaying,
            onOpen: () => onOpen(selected),
            onPlay: () => onPlay(selected),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              const Expanded(child: Text('For You', style: _sectionTitle)),
              TextButton(onPressed: onExplore, child: const Text('Explore')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _RecommendationCard(
                  title: 'Deep Focus',
                  subtitle: 'Clear the noise',
                  sound: _soundWithAudio('assets/audio/deep_focus1.mp3'),
                  onTap: () =>
                      onOpen(_soundWithAudio('assets/audio/deep_focus1.mp3')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RecommendationCard(
                  title: 'Evening Rain',
                  subtitle: 'Settle into calm',
                  sound: _sounds[1],
                  onTap: () => onOpen(_sounds[1]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text('Quick Start', style: _sectionTitle),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickStartButton(
                  icon: _Mood.focus.icon,
                  label: 'Focus',
                  duration: '30m',
                  onTap: () =>
                      onPlay(_soundWithAudio('assets/audio/deep_focus1.mp3')),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _QuickStartButton(
                  icon: _Mood.relax.icon,
                  label: 'Relax',
                  duration: '15m',
                  onTap: () => onPlay(_sounds[0]),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _QuickStartButton(
                  icon: _Mood.sleep.icon,
                  label: 'Sleep',
                  duration: 'Open',
                  onTap: () => onPlay(_sounds[4]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text('Recently Played', style: _sectionTitle),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            _EmptyRecent(onExplore: onExplore)
          else
            for (final sound in recent)
              _SoundRow(
                sound: sound,
                playing: isPlaying && selected.audio == sound.audio,
                onOpen: () => onOpen(sound),
                onPlay: () => onPlay(sound),
              ),
        ],
      ),
    );
  }
}

class _ContinueListeningCard extends StatelessWidget {
  const _ContinueListeningCard({
    required this.sound,
    required this.isPlaying,
    required this.onOpen,
    required this.onPlay,
  });

  final _Sound sound;
  final bool isPlaying;
  final VoidCallback onOpen;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF17231F),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset(
                  sound.image,
                  width: 74,
                  height: 74,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sound.title,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isPlaying ? 'Playing now' : 'Ready when you are',
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onPlay,
                tooltip: isPlaying ? 'Open player' : 'Play',
                icon: Icon(
                  isPlaying
                      ? Icons.graphic_eq_rounded
                      : Icons.play_arrow_rounded,
                ),
                color: _white,
                style: IconButton.styleFrom(backgroundColor: _line),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.title,
    required this.subtitle,
    required this.sound,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final _Sound sound;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(sound.image, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE807100E)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStartButton extends StatelessWidget {
  const _QuickStartButton({
    required this.icon,
    required this.label,
    required this.duration,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 94,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _accent, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: _white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                duration,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _line),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Your recent sounds will appear here.',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
        ),
        TextButton(onPressed: onExplore, child: const Text('Explore')),
      ],
    ),
  );
}

class _HomeScreen extends StatefulWidget {
  const _HomeScreen({
    required this.selected,
    required this.isPlaying,
    required this.onOpen,
    required this.onPlay,
    required this.onExplore,
  });

  final _Sound selected;
  final bool isPlaying;
  final VoidCallback onOpen;
  final VoidCallback onPlay;
  final VoidCallback onExplore;

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  VideoPlayerController? _video;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _video = VideoPlayerController.asset(
      'assets/Background_video/home_silk_loop.mp4',
    );
    unawaited(_initVideo());
  }

  Future<void> _initVideo() async {
    try {
      await _video!.initialize();
      await _video!.setVolume(0);
      await _video!.setLooping(true);
      await _video!.setPlaybackSpeed(0.7);
      if (!mounted) return;
      setState(() => _ready = true);
      if (widget.isPlaying) await _video!.play();
    } catch (_) {
      // The bundled still is always available when a platform video fails.
    }
  }

  @override
  void didUpdateWidget(covariant _HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready || oldWidget.isPlaying == widget.isPlaying) return;
    if (widget.isPlaying) {
      unawaited(_video!.play());
    } else {
      unawaited(_video!.pause());
    }
  }

  @override
  void dispose() {
    unawaited(_video?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final artSize = math.min(MediaQuery.sizeOf(context).width * 0.58, 240.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/Background_video/home_still.jpg',
          fit: BoxFit.cover,
        ),
        if (_ready)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _video!.value.size.width,
              height: _video!.value.size.height,
              child: VideoPlayer(_video!),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xB60D1815), Color(0xD4101917), Color(0xF2091210)],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 490),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 100),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'SEREN',
                          style: TextStyle(
                            letterSpacing: 3,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _accent,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: widget.onExplore,
                          tooltip: 'Explore sounds',
                          icon: const Icon(
                            Icons.explore_outlined,
                            color: _white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: math.max(18, height * 0.035)),
                    const Text(
                      'Find your quiet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 38,
                        color: _white,
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'A little space, just for you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: _muted),
                    ),
                    SizedBox(height: math.max(28, height * 0.055)),
                    InkWell(
                      onTap: widget.onOpen,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: artSize,
                        height: artSize,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _accent, width: 1.4),
                          boxShadow: const [
                            BoxShadow(color: Color(0x5578B7A3), blurRadius: 40),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            widget.selected.image,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.selected.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: _white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onOpen,
                          tooltip: 'Open player',
                          icon: const Icon(
                            Icons.open_in_full_rounded,
                            color: _accent,
                            size: 19,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.selected.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: _muted),
                    ),
                    const SizedBox(height: 30),
                    _PlayCircle(
                      playing: widget.isPlaying,
                      onTap: widget.onPlay,
                      size: 68,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExploreScreen extends StatefulWidget {
  const _ExploreScreen({
    required this.onOpen,
    required this.onPlay,
    required this.playing,
    required this.category,
    required this.onCategory,
  });

  final ValueChanged<_Sound> onOpen;
  final ValueChanged<_Sound> onPlay;
  final String? playing;
  final _Mood? category;
  final ValueChanged<_Mood?> onCategory;

  @override
  State<_ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<_ExploreScreen> {
  final _search = TextEditingController();
  final _scrollController = ScrollController();
  String _filter = 'All';
  bool _searching = false;

  @override
  void dispose() {
    _search.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final categorySounds = category == null
        ? _sounds
        : _sounds.where((sound) => sound.moods.contains(category)).toList();
    final filters = category == null
        ? const <String>['All']
        : <String>[
            'All',
            ...categorySounds.map((sound) => sound.category).toSet(),
          ];
    final visible = categorySounds.where((sound) {
      final matchesSearch = sound.title.toLowerCase().contains(
        _search.text.toLowerCase(),
      );
      return matchesSearch && (_filter == 'All' || sound.category == _filter);
    }).toList();
    return Stack(
      children: [
        if (category != null)
          Positioned.fill(child: _MoodBackdrop(mood: category)),
        _DarkScroll(
          controller: _scrollController,
          backgroundColor: category == null ? _ink : Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              if (category == null) ...[
                Row(
                  children: [
                    const Expanded(child: Text('Explore', style: _pageTitle)),
                    IconButton(
                      onPressed: () => setState(() => _searching = !_searching),
                      tooltip: 'Search sounds',
                      icon: const Icon(Icons.search_rounded, color: _white),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sounds for focus, relaxation, and everything in between.',
                  style: TextStyle(fontSize: 15, height: 1.4, color: _muted),
                ),
                const SizedBox(height: 22),
                if (_searching)
                  _SearchField(
                    controller: _search,
                    onChanged: () => setState(() {}),
                  ),
                if (_searching) const SizedBox(height: 18),
                Row(
                  children: [
                    for (final mood in _Mood.values)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: mood == _Mood.sleep ? 0 : 9,
                          ),
                          child: _MoodCard(
                            mood: mood,
                            onTap: () {
                              setState(() => _filter = 'All');
                              widget.onCategory(mood);
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text('All Sounds', style: _sectionTitle),
              ] else ...[
                IconButton(
                  onPressed: () => widget.onCategory(null),
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.zero,
                  tooltip: 'Back to Explore',
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: _white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 14),
                Icon(category.icon, size: 38, color: category.accentColor),
                const SizedBox(height: 14),
                Text(
                  category.label,
                  textAlign: TextAlign.center,
                  style: _pageTitle.copyWith(fontSize: 33),
                ),
                const SizedBox(height: 6),
                Text(
                  category.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted, fontSize: 15),
                ),
                const SizedBox(height: 26),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in filters)
                        Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: InkWell(
                            onTap: () => setState(() => _filter = filter),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  filter,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _filter == filter ? _white : _muted,
                                    fontWeight: _filter == filter
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: _filter == filter ? 38 : 0,
                                  height: 2,
                                  color: category.accentColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(color: _line, height: 1),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 10),
              for (final sound in visible)
                _SoundRow(
                  sound: sound,
                  playing: widget.playing == sound.audio,
                  onOpen: () => widget.onOpen(sound),
                  onPlay: () => widget.onPlay(sound),
                ),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 34),
                  child: Text(
                    'No sounds found.',
                    style: TextStyle(color: _muted),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LibraryScreen extends StatelessWidget {
  const _LibraryScreen({
    required this.sounds,
    required this.onOpen,
    required this.onPlay,
    required this.playing,
    required this.onExplore,
  });

  final List<_Sound> sounds;
  final ValueChanged<_Sound> onOpen;
  final ValueChanged<_Sound> onPlay;
  final String? playing;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return _DarkScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          const Text('Your Library', style: _pageTitle),
          const SizedBox(height: 5),
          const Text(
            'The sounds you keep close.',
            style: TextStyle(color: _muted, fontSize: 15),
          ),
          const SizedBox(height: 28),
          if (sounds.isEmpty) ...[
            const SizedBox(height: 40),
            const Icon(Icons.library_music_outlined, size: 50, color: _muted),
            const SizedBox(height: 16),
            const Text(
              'Your library is waiting.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: _white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Save a sound from the player to find it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onExplore,
              child: const Text('Explore sounds'),
            ),
          ] else
            for (final sound in sounds)
              _SoundRow(
                sound: sound,
                playing: playing == sound.audio,
                onOpen: () => onOpen(sound),
                onPlay: () => onPlay(sound),
              ),
        ],
      ),
    );
  }
}

class _DarkScroll extends StatelessWidget {
  const _DarkScroll({
    required this.child,
    this.controller,
    this.backgroundColor = _ink,
  });

  final Widget child;
  final ScrollController? controller;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 110),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodBackdrop extends StatelessWidget {
  const _MoodBackdrop({required this.mood});

  final _Mood mood;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: mood.backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.52,
              width: double.infinity,
              child: Image.asset(
                mood.backgroundImage,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                opacity: const AlwaysStoppedAnimation(0.3),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  mood.backgroundColor.withValues(alpha: 0.36),
                  mood.backgroundColor.withValues(alpha: 0.72),
                  mood.backgroundColor,
                ],
                stops: const [0, 0.38, 0.72],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.72),
                radius: 0.75,
                colors: [
                  mood.accentColor.withValues(alpha: 0.13),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _pageTitle = TextStyle(
  fontSize: 31,
  color: _white,
  fontWeight: FontWeight.w500,
);
const _sectionTitle = TextStyle(
  fontSize: 18,
  color: _white,
  fontWeight: FontWeight.w600,
);

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: (_) => onChanged(),
    autofocus: true,
    decoration: InputDecoration(
      hintText: 'Search sounds',
      prefixIcon: const Icon(Icons.search),
      filled: true,
      fillColor: _surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _line),
      ),
    ),
  );
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.mood, required this.onTap});
  final _Mood mood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (mood) {
      _Mood.focus => const Color(0xFF183129),
      _Mood.relax => const Color(0xFF203647),
      _Mood.sleep => const Color(0xFF273147),
    };
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 148),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _line, width: 0.6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(mood.icon, color: _white, size: 27),
              const SizedBox(height: 16),
              Text(
                mood.label,
                style: const TextStyle(
                  color: _white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                mood.shortSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoundRow extends StatelessWidget {
  const _SoundRow({
    required this.sound,
    required this.playing,
    required this.onOpen,
    required this.onPlay,
  });
  final _Sound sound;
  final bool playing;
  final VoidCallback onOpen;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: _surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _line.withValues(alpha: 0.55)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.asset(
                    sound.image,
                    width: 65,
                    height: 65,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sound.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        sound.category,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onPlay,
                  tooltip: playing ? 'Pause' : 'Play',
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _white,
                    size: 23,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _line,
                    side: const BorderSide(
                      color: Color(0xFF64716A),
                      width: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayCircle extends StatelessWidget {
  const _PlayCircle({
    required this.playing,
    required this.onTap,
    this.size = 68,
  });
  final bool playing;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: IconButton(
      onPressed: onTap,
      icon: Icon(
        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: size * 0.46,
        color: _white,
      ),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF183128),
        side: const BorderSide(color: Color(0xFF718D7D), width: 0.7),
      ),
    ),
  );
}

class _ProfileScreen extends StatefulWidget {
  const _ProfileScreen();
  @override
  State<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<_ProfileScreen> {
  String? _name;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();
      if (mounted) setState(() => _name = profile?['display_name'] as String?);
    } catch (_) {}
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not sign out. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name =
        _name ??
        user?.userMetadata?['display_name'] as String? ??
        user?.email?.split('@').first ??
        'Your account';
    return _DarkScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          const Text('Profile', style: _pageTitle),
          const SizedBox(height: 28),
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: _surface,
                child: Image.asset(
                  'assets/icons/branch.png',
                  width: 37,
                  height: 37,
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _line),
            ),
            child: const Row(
              children: [
                Icon(Icons.spa_outlined, color: _accent),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your quiet space',
                        style: TextStyle(
                          color: _white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your saved sounds are in Library.',
                        style: TextStyle(color: _muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Divider(color: _line),
          ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: _signOut,
            leading: const Icon(Icons.logout_rounded, color: _accent),
            title: const Text('Sign out', style: TextStyle(color: _white)),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ],
      ),
    );
  }
}
