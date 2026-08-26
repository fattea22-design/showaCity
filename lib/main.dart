import 'package:flutter/material.dart';
import 'domain/city_game.dart';
import 'domain/game_domain.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '昭和から令和の街',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xffc96b3b),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xfffff8ef),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    home: const CityHome(),
  );
}

class CityHome extends StatefulWidget {
  const CityHome({super.key});
  @override
  State<CityHome> createState() => _CityHomeState();
}

class _CityHomeState extends State<CityHome> {
  final game = CityGame.newGame();
  int? selectedX;
  int? selectedY;
  int page = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${_eraLabel(game.era)}の町'),
      actions: [
        _resourceChip(
          Icons.monetization_on,
          '${game.save.coins}',
          Colors.amber,
        ),
        _resourceChip(Icons.diamond, '${game.save.gems}', Colors.blue),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final city = page == 0 ? _cityGrid() : _secondaryPage();
          final panel = _panel();
          return constraints.maxWidth >= 600
              ? Row(
                  children: [
                    Expanded(child: city),
                    SizedBox(width: 300, child: panel),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: city),
                    SizedBox(height: 190, child: panel),
                  ],
                );
        },
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: page,
      onDestinationSelected: (index) => setState(() => page = index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: '街'),
        NavigationDestination(icon: Icon(Icons.flag), label: 'ミッション'),
        NavigationDestination(icon: Icon(Icons.store), label: 'ショップ'),
      ],
    ),
  );

  Widget _cityGrid() => InteractiveViewer(
    minScale: .7,
    maxScale: 2.5,
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xffdcebd7),
        borderRadius: BorderRadius.circular(24),
      ),
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      child: Center(
        child: GridView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: CityGame.width,
          ),
          itemCount: CityGame.width * CityGame.height,
          itemBuilder: (context, index) {
            final x = index % CityGame.width;
            final y = index ~/ CityGame.width;
            final building = game.save.buildings
                .where((value) => value['x'] == x && value['y'] == y)
                .firstOrNull;
            return GestureDetector(
              onTap: () => setState(() {
                selectedX = x;
                selectedY = y;
              }),
              child: Card(
                color: selectedX == x && selectedY == y
                    ? const Color(0xffffd66b)
                    : building == null
                    ? const Color(0xffcfe3c8)
                    : _buildingColor(building['id'] as String),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: building == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.grass, color: Colors.green),
                              Text('空き地'),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _buildingIcon(building['id'] as String),
                                size: 28,
                              ),
                              Text(
                                _buildingLabel(building['id'] as String),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Lv.${building['level']}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _panel() => Padding(
    padding: const EdgeInsets.all(10),
    child: ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(Icons.people, '人口', '${game.population}'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                Icons.trending_up,
                '毎時',
                '${game.incomePerHour}',
              ),
            ),
          ],
        ),
        Text(
          selectedX == null ? '街の区画をタップして建物を選択' : '選択中: ${selectedX! + 1}区画目',
        ),
        Wrap(
          spacing: 4,
          children: CityGame.buildings
              .where((building) => building.era.index <= game.era.index)
              .map(
                (building) => ElevatedButton(
                  onPressed: selectedX == null
                      ? null
                      : () => setState(
                          () => game.place(building, selectedX!, selectedY!),
                        ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_buildingLabel(building.id)),
                      Text(building.id),
                      Text('${building.baseCost}🪙'),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        ElevatedButton(
          onPressed: selectedX == null
              ? null
              : () => setState(() => game.upgrade(selectedX!, selectedY!)),
          child: const Text('選択建物を強化'),
        ),
        ElevatedButton(
          onPressed: () => setState(() => game.collectIdle(DateTime.now())),
          child: const Text('放置収益を回収'),
        ),
        if (game.era != Era.reiwa)
          ElevatedButton(
            onPressed: () => setState(game.advanceEra),
            child: const Text('次の時代へ'),
          ),
      ],
    ),
  );

  Widget _secondaryPage() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: page == 1
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag, size: 56, color: Colors.orange),
                SizedBox(height: 12),
                Text(
                  'ミッション',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('最初の建物を建てよう  ✓\n街を少しずつ大きくしよう'),
              ],
            )
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store, size: 56, color: Colors.orange),
                SizedBox(height: 12),
                Text(
                  'ショップ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('ジェム 25個\n購入機能はApp Store接続時に利用できます'),
              ],
            ),
    ),
  );

  String _buildingLabel(String id) => switch (id) {
    'nagaya' => '長屋',
    'dagashiya' => '駄菓子屋',
    'kissa' => '喫茶店',
    'karaoke' => 'カラオケ',
    'tower' => '高層住宅',
    _ => id,
  };

  Widget _resourceChip(IconData icon, String value, Color color) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(value),
    ),
  );

  Widget _statCard(IconData icon, String label, String value) => Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepOrange),
          const SizedBox(width: 8),
          Text('$label\n$value'),
        ],
      ),
    ),
  );

  String _eraLabel(Era era) => switch (era) {
    Era.showa => '昭和',
    Era.heisei => '平成',
    Era.reiwa => '令和',
  };

  IconData _buildingIcon(String id) => switch (id) {
    'nagaya' || 'tower' => Icons.home,
    'dagashiya' || 'kissa' => Icons.storefront,
    'karaoke' => Icons.music_note,
    _ => Icons.location_city,
  };

  Color _buildingColor(String id) => switch (id) {
    'nagaya' => const Color(0xfff3d6ad),
    'dagashiya' => const Color(0xffffb3a7),
    'kissa' => const Color(0xffd7c2e8),
    'karaoke' => const Color(0xffb9d9f2),
    'tower' => const Color(0xffc6d6e8),
    _ => Colors.white,
  };
}
