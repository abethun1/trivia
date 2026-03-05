import 'package:flutter/material.dart';
import '../widgets/app_background.dart';

class StatsCardColorScreen extends StatefulWidget {
  final String initialColorHex;

  const StatsCardColorScreen({
    super.key,
    required this.initialColorHex,
  });

  @override
  State<StatsCardColorScreen> createState() => _StatsCardColorScreenState();
}

class _StatsCardColorScreenState extends State<StatsCardColorScreen> {
  final List<String> colorOptions = const [
    '#7D798A',
    '#6B7280',
    '#4B5563',
    '#9CA3AF',
    '#A78BFA',
    '#C4B5FD',
    '#F9A8D4',
    '#FCA5A5',
    '#FDBA74',
    '#FDE68A',
    '#86EFAC',
    '#6EE7B7',
    '#67E8F9',
    '#93C5FD',
    '#34D399',
    '#22D3EE',
  ];

  late String selectedHex;

  @override
  void initState() {
    super.initState();
    selectedHex = widget.initialColorHex;
  }

  Color parseHexColor(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length != 6) return const Color(0xFF7D798A);
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return const Color(0xFF7D798A);
    return Color(0xFF000000 | value);
  }

  Future<void> confirmSelection() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Card Color"),
          content: const Text("Use this color for your dashboard stats card?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      Navigator.pop(context, selectedHex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Pick Stats Card Color"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: parseHexColor(selectedHex),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 6,
                        offset: Offset(0, 3),
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Rank: Bronze"),
                      Text("Top Category: Math"),
                      Text("Correct Answers: 0"),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: colorOptions.length,
                    itemBuilder: (context, index) {
                      final hex = colorOptions[index];
                      final isSelected = hex == selectedHex;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedHex = hex;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: parseHexColor(hex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: confirmSelection,
                    child: const Text("Confirm"),
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
