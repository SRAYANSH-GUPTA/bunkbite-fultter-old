import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/owner_provider.dart';
import 'create_canteen_sheet.dart';

class OwnerCanteenSelectorSheet extends ConsumerWidget {
  const OwnerCanteenSelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerState = ref.watch(ownerProvider);
    final canteens = ownerState.myCanteens;
    final selectedCanteen = ownerState.selectedCanteen;

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Canteen',
                style: GoogleFonts.urbanist(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (canteens.isEmpty && !ownerState.isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No canteens found',
                      style: GoogleFonts.urbanist(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Create your first canteen to get started',
                      style: GoogleFonts.urbanist(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: canteens.length,
                itemBuilder: (context, index) {
                  final canteen = canteens[index];
                  final isSelected = selectedCanteen?.id == canteen.id;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      ref.read(ownerProvider.notifier).selectCanteen(canteen);
                      Navigator.pop(context);
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0x1AF62F56)
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.store,
                        color: isSelected
                            ? const Color(0xFFF62F56)
                            : Colors.grey,
                      ),
                    ),
                    title: Text(
                      canteen.name,
                      style: GoogleFonts.urbanist(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFFF62F56) : null,
                      ),
                    ),
                    subtitle: Text(
                      canteen.place,
                      style: GoogleFonts.urbanist(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFFF62F56),
                          )
                        : null,
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Close selector and open creator
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const CreateCanteenSheet(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF62F56),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'Create New Canteen',
                style: GoogleFonts.urbanist(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
