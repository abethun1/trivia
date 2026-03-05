import 'package:flutter/material.dart';
import '../widgets/app_background.dart';
import '../widgets/profile_avatar.dart';

class AvatarColorScreen extends StatefulWidget {
  final String username;
  final String initialColorHex;

  const AvatarColorScreen({
    super.key,
    required this.username,
    required this.initialColorHex,
  });

  @override
  State<AvatarColorScreen> createState() => _AvatarColorScreenState();
}

class _AvatarColorScreenState extends State<AvatarColorScreen> {
  final List<String> colorOptions = const [
    '#D8B4FE',
    '#A78BFA',
    '#F9A8D4',
    '#FCA5A5',
    '#FDBA74',
    '#FDE68A',
    '#86EFAC',
    '#6EE7B7',
    '#67E8F9',
    '#93C5FD',
    '#C4B5FD',
    '#FBCFE8',
    '#D1D5DB',
    '#94A3B8',
    '#22D3EE',
    '#34D399',
  ];

  late String selectedHex;

  @override
  void initState() {
    super.initState();
    selectedHex = widget.initialColorHex;
  }

  Color parseHexColor(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length != 6) {
      return const Color(0xFFD8B4FE);
    }
    final value = int.tryParse(clean, radix: 16);
    if (value == null) {
      return const Color(0xFFD8B4FE);
    }
    return Color(0xFF000000 | value);
  }

  Future<void> confirmSelection() async {
    final shouldApply = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Avatar Color"),
          content: const Text("Use this color for your avatar?"),
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

    if (shouldApply == true && mounted) {
      Navigator.pop(context, selectedHex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Pick Avatar Color"),
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
            ProfileAvatar(
              username: widget.username,
              avatarPath: null,
              avatarStatus: 'approved',
              avatarColorHex: selectedHex,
              radius: 52,
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
