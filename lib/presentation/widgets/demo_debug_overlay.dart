import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/repositories/trip_repository.dart';
import '../../core/constants.dart';
import '../../core/metrics.dart';

/// Demo overlay that shows backend integration status and token metrics
class DemoDebugOverlay extends StatefulWidget {
  final Widget child;
  final TripRepository repository;

  const DemoDebugOverlay({
    super.key,
    required this.child,
    required this.repository,
  });

  @override
  State<DemoDebugOverlay> createState() => _DemoDebugOverlayState();
}

class _DemoDebugOverlayState extends State<DemoDebugOverlay> {
  bool _showOverlay = false;
  bool _isOnline = false;
  bool _isBackendHealthy = false;
  TokenMetrics? _lastMetrics;
  int _totalRequests = 0;
  int _totalTokens = 0;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final isOnline = await widget.repository.agentApi.isOnline();
      final isHealthy = await widget.repository.agentApi.healthCheck();
      
      setState(() {
        _isOnline = isOnline;
        _isBackendHealthy = isHealthy;
      });
    } catch (e) {
      setState(() {
        _isOnline = false;
        _isBackendHealthy = false;
      });
    }
  }

  void _updateMetrics(TokenMetrics metrics) {
    setState(() {
      _lastMetrics = metrics;
      _totalRequests++;
      _totalTokens += metrics.totalTokens;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Debug toggle button
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 10,
          child: FloatingActionButton.small(
            heroTag: 'debug_toggle',
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _showOverlay = !_showOverlay;
              });
            },
            backgroundColor: _isOnline && _isBackendHealthy 
                ? Colors.green 
                : Colors.red,
            child: Icon(
              _showOverlay ? Icons.close : Icons.info_outline,
              color: Colors.white,
            ),
          ),
        ),

        // Debug overlay
        if (_showOverlay)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 10,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.bug_report,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Demo Debug Info',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Backend Status
                  _buildStatusRow(
                    'Backend URL',
                    ApiConstants.backendBaseUrl,
                    Colors.blue,
                  ),
                  _buildStatusRow(
                    'Online Status',
                    _isOnline ? 'Connected' : 'Offline',
                    _isOnline ? Colors.green : Colors.red,
                  ),
                  _buildStatusRow(
                    'Backend Health',
                    _isBackendHealthy ? 'Healthy' : 'Unavailable',
                    _isBackendHealthy ? Colors.green : Colors.red,
                  ),
                  
                  const Divider(color: Colors.grey),
                  
                  // Token Metrics
                  _buildMetricsRow('Total Requests', '$_totalRequests'),
                  _buildMetricsRow('Total Tokens Used', '$_totalTokens'),
                  
                  if (_lastMetrics != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last Request:',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildMetricsRow('Prompt', '${_lastMetrics!.promptTokens}'),
                    _buildMetricsRow('Completion', '${_lastMetrics!.completionTokens}'),
                    _buildMetricsRow('Total', '${_lastMetrics!.totalTokens}'),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _checkStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'Refresh',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _totalRequests = 0;
                              _totalTokens = 0;
                              _lastMetrics = null;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Demo helper to register metrics updates
mixin DemoMetricsMixin<T extends StatefulWidget> on State<T> {
  void registerMetricsCallback(TokenMetrics metrics) {
    // Find the debug overlay in the widget tree and update metrics
    final overlay = context.findAncestorStateOfType<_DemoDebugOverlayState>();
    overlay?._updateMetrics(metrics);
  }
}
