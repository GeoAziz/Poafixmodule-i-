import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../screens/call/voice_call_screen.dart';
import '../screens/call/video_call_screen.dart';
import '../screens/call/incoming_call_screen.dart';
import 'websocket_service.dart';
import 'notification_service.dart';

class CallService {
  static const String agoraAppId = 'YOUR_AGORA_APP_ID'; // Replace with your Agora App ID
  
  final WebSocketService _webSocketService = WebSocketService();
  final NotificationService _notificationService = NotificationService();
  
  RtcEngine? _engine;
  bool _isCallActive = false;
  String? _currentChannelId;
  BuildContext? _context;

  // Initialize Agora engine
  Future<void> initialize(BuildContext context) async {
    _context = context;
    
    if (agoraAppId.isEmpty || agoraAppId == 'YOUR_AGORA_APP_ID') {
      print('⚠️ Agora App ID not configured. Using fallback phone dialer.');
      return;
    }

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _setupCallEventHandlers();
      print('✅ Agora engine initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Agora: $e');
    }
  }

  void _setupCallEventHandlers() {
    _webSocketService.socket.on('incoming_call', (data) {
      _handleIncomingCall(data);
    });

    _webSocketService.socket.on('call_ended', (data) {
      _handleCallEnded();
    });

    _webSocketService.socket.on('call_declined', (data) {
      _handleCallDeclined();
    });
  }

  // Initiate a call
  Future<void> initiateCall({
    required String calleeId,
    required String calleeName,
    required bool isVideoCall,
  }) async {
    if (_isCallActive) {
      _showMessage('Another call is already in progress');
      return;
    }

    // Check if Agora is available, otherwise fallback to phone dialer
    if (_engine == null) {
      await _fallbackToPhoneDialer(calleeId, calleeName);
      return;
    }

    try {
      // Request permissions
      if (isVideoCall) {
        await _requestVideoCallPermissions();
      } else {
        await _requestAudioPermissions();
      }

      final channelId = 'call_${DateTime.now().millisecondsSinceEpoch}';
      
      // Notify the other user via WebSocket
      _webSocketService.emit('initiate_call', {
        'calleeId': calleeId,
        'calleeName': calleeName,
        'channelId': channelId,
        'isVideoCall': isVideoCall,
      });

      // Navigate to call screen
      if (isVideoCall) {
        _navigateToVideoCall(channelId, calleeName, false);
      } else {
        _navigateToVoiceCall(channelId, calleeName, false);
      }

      setState(() {
        _isCallActive = true;
        _currentChannelId = channelId;
      });

    } catch (e) {
      _showMessage('Failed to initiate call: $e');
    }
  }

  // Handle incoming call
  void _handleIncomingCall(Map<String, dynamic> data) {
    if (_isCallActive) {
      // Decline the call if another call is active
      _webSocketService.emit('decline_call', {
        'callerId': data['callerId'],
        'reason': 'busy',
      });
      return;
    }

    if (_context != null) {
      Navigator.push(
        _context!,
        MaterialPageRoute(
          builder: (context) => IncomingCallScreen(
            callerName: data['callerName'] ?? 'Unknown',
            callerId: data['callerId'],
            channelId: data['channelId'],
            isVideoCall: data['isVideoCall'] ?? false,
            onAccept: () => _acceptCall(data),
            onDecline: () => _declineCall(data['callerId']),
          ),
        ),
      );
    }
  }

  // Accept incoming call
  Future<void> _acceptCall(Map<String, dynamic> callData) async {
    try {
      final isVideoCall = callData['isVideoCall'] ?? false;
      
      if (isVideoCall) {
        await _requestVideoCallPermissions();
      } else {
        await _requestAudioPermissions();
      }

      // Notify caller that call was accepted
      _webSocketService.emit('accept_call', {
        'callerId': callData['callerId'],
        'channelId': callData['channelId'],
      });

      setState(() {
        _isCallActive = true;
        _currentChannelId = callData['channelId'];
      });

      // Navigate to appropriate call screen
      if (isVideoCall) {
        _navigateToVideoCall(
          callData['channelId'],
          callData['callerName'] ?? 'Unknown',
          true,
        );
      } else {
        _navigateToVoiceCall(
          callData['channelId'],
          callData['callerName'] ?? 'Unknown',
          true,
        );
      }

    } catch (e) {
      _showMessage('Failed to accept call: $e');
    }
  }

  // Decline incoming call
  void _declineCall(String callerId) {
    _webSocketService.emit('decline_call', {
      'callerId': callerId,
      'reason': 'declined',
    });
  }

  // End current call
  Future<void> endCall() async {
    if (!_isCallActive || _currentChannelId == null) return;

    try {
      await _engine?.leaveChannel();
      
      _webSocketService.emit('end_call', {
        'channelId': _currentChannelId,
      });

      setState(() {
        _isCallActive = false;
        _currentChannelId = null;
      });

    } catch (e) {
      print('Error ending call: $e');
    }
  }

  // Handle call ended
  void _handleCallEnded() {
    setState(() {
      _isCallActive = false;
      _currentChannelId = null;
    });
    
    if (_context != null) {
      Navigator.popUntil(_context!, (route) => route.isFirst);
    }
  }

  // Handle call declined
  void _handleCallDeclined() {
    _showMessage('Call declined');
    _handleCallEnded();
  }

  // Fallback to system phone dialer
  Future<void> _fallbackToPhoneDialer(String calleeId, String calleeName) async {
    showDialog(
      context: _context!,
      builder: (context) => AlertDialog(
        title: Text('Call $calleeName'),
        content: Text('Video calling is not available. Would you like to make a phone call instead?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // You would need to get the actual phone number from user profile
              await _makePhoneCall('+254700000000'); // Placeholder
            },
            child: Text('Call'),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showMessage('Cannot make phone call');
    }
  }

  // Request permissions
  Future<void> _requestAudioPermissions() async {
    await [Permission.microphone].request();
  }

  Future<void> _requestVideoCallPermissions() async {
    await [Permission.microphone, Permission.camera].request();
  }

  // Navigation helpers
  void _navigateToVoiceCall(String channelId, String calleeName, bool isIncoming) {
    if (_context != null) {
      Navigator.push(
        _context!,
        MaterialPageRoute(
          builder: (context) => VoiceCallScreen(
            channelId: channelId,
            calleeName: calleeName,
            isIncoming: isIncoming,
            engine: _engine!,
            onCallEnded: endCall,
          ),
        ),
      );
    }
  }

  void _navigateToVideoCall(String channelId, String calleeName, bool isIncoming) {
    if (_context != null) {
      Navigator.push(
        _context!,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            channelId: channelId,
            calleeName: calleeName,
            isIncoming: isIncoming,
            engine: _engine!,
            onCallEnded: endCall,
          ),
        ),
      );
    }
  }

  void setState(VoidCallback fn) => fn();

  void _showMessage(String message) {
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Cleanup
  void dispose() {
    _engine?.release();
  }
}