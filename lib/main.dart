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
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
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
  final game = CityGame();
  int? selectedX;
  int? selectedY;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${game.era.name.toUpperCase()} 街づくり'),
      actions: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('🪙 ${game.save.coins}  💎 ${game.save.gems}'),
        ),
      ],
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final city = _cityGrid();
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
                  ? Colors.amber.shade200
                  : Colors.green.shade100,
              child: Center(
                child: Text(
                  building?['id'] as String? ?? '空地',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _panel() => Padding(
    padding: const EdgeInsets.all(10),
    child: ListView(
      children: [
        Text('人口 ${game.population} / 時給 ${game.incomePerHour}'),
        Wrap(
          spacing: 4,
          children: CityGame.buildings
              .map(
                (building) => ElevatedButton(
                  onPressed: selectedX == null
                      ? null
                      : () => setState(
                          () => game.place(building, selectedX!, selectedY!),
                        ),
                  child: Text(building.id),
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
}
