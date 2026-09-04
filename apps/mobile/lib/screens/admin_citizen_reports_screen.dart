import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';

class AdminCitizenReportsScreen extends StatelessWidget {
  const AdminCitizenReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data matching web CitizenReportsPage
    final reports = [
      { 'id': 'REP-8492', 'type': 'Expired Product', 'desc': 'Found expired milk in aisle 4', 'status': 'NEW', 'date': '26 Aug 2026, 14:30' },
      { 'id': 'REP-8491', 'type': 'Missing MRP', 'desc': 'Soap bar without price tag', 'status': 'IN_PROGRESS', 'date': '25 Aug 2026, 11:20' },
      { 'id': 'REP-8490', 'type': 'Misleading Claim', 'desc': 'Says 100% juice but ingredients show 10%', 'status': 'RESOLVED', 'date': '24 Aug 2026, 09:15' },
    ];

    return Scaffold(
      backgroundColor: LabelLensColors.surface1,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.7),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text('Citizen Reports', style: TextStyle(color: LabelLensColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 100, right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 250, height: 250, decoration: BoxDecoration(color: LabelLensColors.statusWarn.withOpacity(0.15), shape: BoxShape.circle)),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: LabelLensSpacing.s4, vertical: 8),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final r = reports[index];
                      final isNew = r['status'] == 'NEW';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isNew ? LabelLensColors.brandPrimary.withOpacity(0.3) : Colors.white.withOpacity(0.5)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(r['id']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: LabelLensColors.textSecondary)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isNew ? LabelLensColors.statusFail.withOpacity(0.1) : LabelLensColors.surface2,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      r['status']!,
                                      style: TextStyle(
                                        color: isNew ? LabelLensColors.statusFail : LabelLensColors.textSecondary,
                                        fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber, size: 20, color: LabelLensColors.brandSecondary),
                                  const SizedBox(width: 8),
                                  Text(r['type']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: LabelLensColors.textPrimary)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(r['desc']!, style: const TextStyle(color: LabelLensColors.textSecondary, fontSize: 14)),
                              const SizedBox(height: 16),
                              Container(height: 1, color: LabelLensColors.surface3.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14, color: LabelLensColors.textTertiary),
                                  const SizedBox(width: 4),
                                  Text(r['date']!, style: const TextStyle(fontSize: 12, color: LabelLensColors.textTertiary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
