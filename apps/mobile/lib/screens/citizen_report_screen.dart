import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';

/// Screen M-14: Citizen Report Screen
class CitizenReportScreen extends StatelessWidget {
  const CitizenReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LabelLensColors.surface1,
      appBar: AppBar(
        backgroundColor: LabelLensColors.brandPrimary,
        foregroundColor: Colors.white,
        title: const Text('Report Violation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LabelLensSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(LabelLensSpacing.s6),
              decoration: BoxDecoration(
                color: LabelLensColors.surface0,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LabelLensColors.statusFailBorder),
              ),
              child: const Column(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 48, color: LabelLensColors.statusFail),
                  SizedBox(height: 12),
                  Text('Help us enforce LMPC rules.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Your identity remains confidential.',
                      style: TextStyle(fontSize: 13, color: LabelLensColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: LabelLensSpacing.s6),

            const Text('1. Photo of Product Label', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: LabelLensColors.surface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LabelLensColors.surface3, style: BorderStyle.solid),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: LabelLensColors.textTertiary),
                  SizedBox(height: 8),
                  Text('Tap to take photo', style: TextStyle(color: LabelLensColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(height: LabelLensSpacing.s6),

            const Text('2. What is wrong?', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: LabelLensColors.surface0,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LabelLensColors.surface3),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Select issue type...'),
                  items: const [
                    DropdownMenuItem(value: 'mrp', child: Text('MRP missing or tampered')),
                    DropdownMenuItem(value: 'qty', child: Text('Net quantity missing')),
                    DropdownMenuItem(value: 'contact', child: Text('No consumer care details')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) {},
                ),
              ),
            ),
            const SizedBox(height: LabelLensSpacing.s6),

            const Text('3. Location (Auto-detected)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: LabelLensColors.brandSecondary, size: 20),
                const SizedBox(width: 8),
                const Text('Sadar Bazaar, Delhi (Accuracy: 12m)'),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('Edit')),
              ],
            ),
            const SizedBox(height: LabelLensSpacing.s6),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: LabelLensColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
