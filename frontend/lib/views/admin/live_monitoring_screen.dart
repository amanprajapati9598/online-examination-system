import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/teacher_provider.dart';

class LiveMonitoringScreen extends StatefulWidget {
  const LiveMonitoringScreen({super.key});

  @override
  State<LiveMonitoringScreen> createState() => _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState extends State<LiveMonitoringScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchLiveMonitor();
    
    // Auto-refresh active sessions every 8 seconds (Short polling simulation)
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      _fetchLiveMonitor();
    });
  }

  void _fetchLiveMonitor() {
    Provider.of<TeacherProvider>(context, listen: false).fetchActiveExams();
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TeacherProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Proctor Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLiveMonitor,
          )
        ],
      ),
      body: tp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tp.activeExams.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off_outlined, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No active examination sessions ongoing right now.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tp.activeExams.length,
                  itemBuilder: (context, index) {
                    final session = tp.activeExams[index];
                    final tabAlert = session.tabSwitchesCount > 0;
                    final fsAlert = session.fullscreenExitsCount > 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  session.examTitle ?? 'Assessment',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ONGOING',
                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            _buildInfoRow('Student Name', session.studentName ?? 'Anonymous'),
                            _buildInfoRow('Student Email', session.studentEmail ?? ''),
                            _buildInfoRow('Started Time', session.startTime.toString().substring(0, 19)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildInfractionBadge('Tab Switches: ${session.tabSwitchesCount}', tabAlert),
                                const SizedBox(width: 8),
                                _buildInfractionBadge('Fullscreen Exits: ${session.fullscreenExitsCount}', fsAlert),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInfractionBadge(String label, bool isAlert) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAlert ? Colors.red.withOpacity(0.08) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isAlert ? Colors.redAccent.withOpacity(0.3) : Colors.transparent),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isAlert ? Colors.redAccent : Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
