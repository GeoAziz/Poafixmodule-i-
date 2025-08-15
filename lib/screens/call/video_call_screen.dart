import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'dart:async';

class VideoCallScreen extends StatefulWidget {
  final String channelId;
  final String calleeName;
  final bool isIncoming;
  final RtcEngine engine;
  final VoidCallback onCallEnded;

  const VideoCallScreen({
    super.key,
    required this.channelId,
    required this.calleeName,
    required this.isIncoming,
    required this.engine,
    required this.onCallEnded,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final bool _isMuted = false;
  final bool _isVideoEnabled = true;
  final bool _isFrontCamera = true;
  bool _isConnected = false;
  bool _showControls = true;
  int? _remoteUid;
  Timer? _callTimer;
  Timer? _hideControlsTimer;
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupEventHandlers();
    _joinChannel();
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _setupEventHandlers() {
    widget.engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _isConnected = true);
          _startCallTimer();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
            _isConnected = true;
          });
          _startCallTimer();
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() => _remoteUid = null);
          _endCall();
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          _endCall();
        },
      ),
    );
  }

  Future<void> _joinChannel() async {
    await widget.engine.enableVideo();
    await widget.engine.startPreview();
    
    await widget.engine.joinChannel(
      token: '', // Use proper token for production
      channelId: widget.channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration = Duration(seconds: timer.tick);
      });
    });
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _endCall() {
    widget.engine.leaveChannel();
    widget.onCallEnded();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: const Center(
        child: Text(
          'Video Call Screen',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}