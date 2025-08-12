import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'websocket_service.dart';
import '../screens/call/incoming_call_screen.dart';
import '../screens/call/video_call_screen.dart';
import '../screens/call/voice_call_screen.dart';

// Data classes
class IncomingCallData {
  final String callerId;
  final String callerName;
  final String channelId;
  final bool isVideoCall;
  final String? bookingId;

  IncomingCallData({
    required this.callerId,
    required this.callerName,
    required this.channelId,
    required this.isVideoCall,
    this.bookingId,
  });
}

// Removed duplicate CallState enum. Only the complete CallState enum below is used.

class EnhancedCallService {
  // Store the latest incoming call data for public methods
  IncomingCallData? _incomingCallData;
  static final EnhancedCallService _instance = EnhancedCallService._internal();
  factory EnhancedCallService() => _instance;
  EnhancedCallService._internal();

  RtcEngine? _engine;
  final WebSocketService _webSocketService = WebSocketService();
  BuildContext? _context;

  // Call state
  bool _isCallActive = false;
  bool _isIncomingCall = false;
  String? _currentChannelId;
  String? _currentCallerId;
  String? _currentCallerName;
  bool _isVideoCall = false;

  // Audio/Video state
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerEnabled = false;

  // Streams
  final _callStateController = StreamController<CallState>.broadcast();
  final _incomingCallController =
      StreamController<IncomingCallData>.broadcast();

  Stream<CallState> get callStateStream => _callStateController.stream;
  Stream<IncomingCallData> get incomingCallStream =>
      _incomingCallController.stream;

  // Agora App ID - Replace with your actual Agora App ID
  static const String agoraAppId = "YOUR_AGORA_APP_ID";

  Future<void> initialize(BuildContext context) async {
    _context = context;
    await _initializeAgora();
    _setupWebSocketListeners();
  }

  Future<void> _initializeAgora() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('Successfully joined channel: ${connection.channelId}');
            _callStateController.add(CallState.connected);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('Remote user joined: $remoteUid');
            _callStateController.add(CallState.remoteUserJoined);
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            print('Remote user left: $remoteUid');
            _callStateController.add(CallState.remoteUserLeft);
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            print('Left channel');
            _callStateController.add(CallState.ended);
          },
          onError: (ErrorCodeType err, String msg) {
            print('Agora error: $err - $msg');
            _callStateController.add(CallState.error);
          },
        ),
      );
    } catch (e) {
      print('Error initializing Agora: $e');
    }
  }

  void _setupWebSocketListeners() {
    // Listen for incoming calls
    _webSocketService.socket.on('incoming_call', (data) {
      _handleIncomingCall(data);
    });

    // Listen for call acceptance
    _webSocketService.socket.on('call_accepted', (data) {
      _handleCallAccepted(data);
    });

    // Listen for call rejection/decline
    _webSocketService.socket.on('call_declined', (data) {
      _handleCallDeclined(data);
    });

    // Listen for call ended
    _webSocketService.socket.on('call_ended', (data) {
      _handleCallEnded();
    });

    // Listen for call busy
    _webSocketService.socket.on('call_busy', (data) {
      _showMessage('User is busy');
      _callStateController.add(CallState.busy);
    });
  }

  // Initiate call
  Future<void> initiateCall({
    required String receiverId,
    required String receiverName,
    required bool isVideoCall,
    String? bookingId,
  }) async {
    try {
      if (_isCallActive) {
        _showMessage('Another call is already in progress');
        return;
      }

      // Request permissions
      if (isVideoCall) {
        await _requestVideoCallPermissions();
      } else {
        await _requestAudioPermissions();
      }

      final channelId = 'call_${DateTime.now().millisecondsSinceEpoch}';

      // Emit call initiation
      _webSocketService.emit('initiate_call', {
        'receiverId': receiverId,
        'receiverName': receiverName,
        'isVideoCall': isVideoCall,
        'channelId': channelId,
        'bookingId': bookingId,
      });

      setState(() {
        _currentChannelId = channelId;
        _isVideoCall = isVideoCall;
        _isCallActive = true;
      });

      _callStateController.add(CallState.calling);

      // Navigate to appropriate call screen
      if (isVideoCall) {
        _navigateToVideoCall(channelId, receiverName, false);
      } else {
        _navigateToVoiceCall(channelId, receiverName, false);
      }
    } catch (e) {
      _showMessage('Failed to initiate call: $e');
      _callStateController.add(CallState.error);
    }
  }

  // Handle incoming call
  void _handleIncomingCall(Map<String, dynamic> callData) async {
    // Store for public access
    _incomingCallData = IncomingCallData(
      callerId: callData['callerId'],
      callerName: callData['callerName'] ?? 'Unknown',
      channelId: callData['channelId'],
      isVideoCall: callData['isVideoCall'] ?? false,
      bookingId: callData['bookingId'],
    );
    if (_isCallActive) {
      // Send busy signal
      _webSocketService.emit('call_busy', {
        'callerId': callData['callerId'],
      });
      return;
    }

    setState(() {
      _isIncomingCall = true;
      _currentCallerId = callData['callerId'];
      _currentCallerName = callData['callerName'] ?? 'Unknown';
      _currentChannelId = callData['channelId'];
      _isVideoCall = callData['isVideoCall'] ?? false;
    });

    // Play ringtone and vibrate
    _playRingtone();
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [500, 1000], repeat: 0);
    }

    final incomingData = IncomingCallData(
      callerId: callData['callerId'],
      callerName: callData['callerName'] ?? 'Unknown',
      channelId: callData['channelId'],
      isVideoCall: callData['isVideoCall'] ?? false,
      bookingId: callData['bookingId'],
    );

    _incomingCallController.add(incomingData);

    // Show incoming call screen
    if (_context != null) {
      Navigator.push(
        _context!,
        MaterialPageRoute(
          builder: (context) => IncomingCallScreen(
            callerId: incomingData.callerId,
            callerName: incomingData.callerName,
            callerPhone:
                incomingData.callerId, // Using callerId as phone for now
            isVideoCall: incomingData.isVideoCall,
            callService: this,
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

      // Stop ringtone and vibration
      _stopRingtone();
      Vibration.cancel();

      // Notify caller that call was accepted
      _webSocketService.emit('accept_call', {
        'callerId': callData['callerId'],
        'channelId': callData['channelId'],
      });

      setState(() {
        _isCallActive = true;
        _isIncomingCall = false;
        _currentChannelId = callData['channelId'];
        _isVideoCall = isVideoCall;
      });

      _callStateController.add(CallState.connecting);

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
      _callStateController.add(CallState.error);
    }
  }

  // Decline incoming call
  void _declineCall(String callerId) {
    _stopRingtone();
    Vibration.cancel();

    _webSocketService.emit('decline_call', {
      'callerId': callerId,
      'reason': 'declined',
    });

    setState(() {
      _isIncomingCall = false;
      _currentCallerId = null;
      _currentCallerName = null;
      _currentChannelId = null;
    });

    _callStateController.add(CallState.declined);
  }

  // End current call
  Future<void> endCall() async {
    if (!_isCallActive || _currentChannelId == null) return;

    try {
      await _engine?.leaveChannel();

      _webSocketService.emit('end_call', {
        'channelId': _currentChannelId,
      });

      _resetCallState();
      _callStateController.add(CallState.ended);
    } catch (e) {
      print('Error ending call: $e');
    }
  }

  // Join Agora channel
  Future<void> joinChannel(String channelId, {int? uid}) async {
    try {
      await _engine?.joinChannel(
        token:
            '', // Use empty string for testing, implement token server for production
        channelId: channelId,
        uid: uid ?? 0,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      print('Error joining channel: $e');
      _callStateController.add(CallState.error);
    }
  }

  // Audio controls
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _engine?.muteLocalAudioStream(_isMuted);
    _callStateController.add(CallState.audioToggled);
  }

  Future<void> toggleSpeaker() async {
    _isSpeakerEnabled = !_isSpeakerEnabled;
    await _engine?.setEnableSpeakerphone(_isSpeakerEnabled);
    _callStateController.add(CallState.speakerToggled);
  }

  // Video controls
  Future<void> toggleVideo() async {
    _isVideoEnabled = !_isVideoEnabled;
    await _engine?.muteLocalVideoStream(!_isVideoEnabled);
    _callStateController.add(CallState.videoToggled);
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
    _callStateController.add(CallState.cameraSwitched);
  }

  // Permission requests
  Future<void> _requestAudioPermissions() async {
    await [Permission.microphone].request();
  }

  Future<void> _requestVideoCallPermissions() async {
    await [Permission.microphone, Permission.camera].request();
  }

  // Navigation helpers
  void _navigateToVideoCall(
      String channelId, String participantName, bool isIncoming) {
    if (_context != null && _engine != null) {
      Navigator.push(
        _context!,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            channelId: channelId,
            calleeName: participantName,
            isIncoming: isIncoming,
            engine: _engine!,
            onCallEnded: () => endCall(),
          ),
        ),
      );
    }
  }

  void _navigateToVoiceCall(
      String channelId, String participantName, bool isIncoming) {
    if (_context != null && _engine != null) {
      Navigator.push(
        _context!,
        MaterialPageRoute(
          builder: (context) => VoiceCallScreen(
            channelId: channelId,
            calleeName: participantName,
            isIncoming: isIncoming,
            engine: _engine!,
            onCallEnded: () => endCall(),
          ),
        ),
      );
    }
  }

  // Audio management
  void _playRingtone() {
    FlutterRingtonePlayer().playRingtone();
  }

  void _stopRingtone() {
    FlutterRingtonePlayer().stop();
  }

  // Call state management
  void _handleCallAccepted(Map<String, dynamic> data) {
    _callStateController.add(CallState.accepted);
  }

  void _handleCallDeclined(Map<String, dynamic> data) {
    _showMessage('Call was declined');
    _resetCallState();
    _callStateController.add(CallState.declined);
  }

  void _handleCallEnded() {
    _resetCallState();
    _callStateController.add(CallState.ended);

    if (_context != null) {
      Navigator.popUntil(_context!, (route) => route.isFirst);
    }
  }

  void _resetCallState() {
    setState(() {
      _isCallActive = false;
      _isIncomingCall = false;
      _currentChannelId = null;
      _currentCallerId = null;
      _currentCallerName = null;
      _isVideoCall = false;
      _isMuted = false;
      _isVideoEnabled = true;
      _isSpeakerEnabled = false;
    });
  }

  void setState(VoidCallback fn) {
    fn();
  }

  void _showMessage(String message) {
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Getters
  bool get isCallActive => _isCallActive;
  bool get isIncomingCall => _isIncomingCall;
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerEnabled => _isSpeakerEnabled;
  String? get currentChannelId => _currentChannelId;
  String? get currentCallerName => _currentCallerName;
  bool get isVideoCall => _isVideoCall;

  void dispose() {
    _engine?.release();
    _callStateController.close();
    _incomingCallController.close();
  }
}

// Call state enum
enum CallState {
  idle,
  calling,
  connecting,
  connected,
  ended,
  declined,
  busy,
  error,
  remoteUserJoined,
  remoteUserLeft,
  accepted,
  audioToggled,
  videoToggled,
  speakerToggled,
  cameraSwitched,
}

// Public methods for external use - Add these to EnhancedCallService class
extension EnhancedCallServicePublic on EnhancedCallService {
  // Accept incoming call - public method
  Future<void> acceptCall() async {
    if (_incomingCallData != null) {
      await _acceptCall({
        'callerId': _incomingCallData!.callerId,
        'callerName': _incomingCallData!.callerName,
        'channelId': _incomingCallData!.channelId,
        'isVideoCall': _incomingCallData!.isVideoCall,
        'bookingId': _incomingCallData!.bookingId,
      });
    }
  }

  // Reject incoming call - public method
  Future<void> rejectCall() async {
    if (_incomingCallData != null) {
      // Use _declineCall instead of undefined _rejectCall
      _declineCall(_incomingCallData!.callerId);
    }
  }
}
