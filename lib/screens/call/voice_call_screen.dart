import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'dart:async';

class VoiceCallScreen extends StatefulWidget {
  final String channelId;
  final String calleeName;
  final bool isIncoming;
  final RtcEngine engine;
  final VoidCallback onCallEnded;

  const VoiceCallScreen({
    super.key,
    required this.channelId,
    required this.calleeName,
    required this.isIncoming,
    required this.engine,
    required this.onCallEnded,
  });

  @override
  _VoiceCallScreenState createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isConnected = false;
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupEventHandlers();
    _joinChannel();
  }

  void _setupEventHandlers() {
    widget.engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _isConnected = true);
          _startCallTimer();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() => _isConnected = true);
          _startCallTimer();
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          _endCall();
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          _endCall();
        },
      ),
    );
  }

  Future<void> _joinChannel() async {
    await widget.engine.joinChannel(
      token:
          '', // Use empty string for testing, implement token generation for production
      channelId: widget.channelId,
      uid: 0,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration = Duration(seconds: timer.tick);
      });
    });
  }

  void _endCall() {
    _callTimer?.cancel();
    widget.onCallEnded();
    Navigator.pop(context);
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    widget.engine.muteLocalAudioStream(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    widget.engine.setEnableSpeakerphone(_isSpeakerOn);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    _isConnected ? 'Connected' : 'Calling...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.calleeName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isConnected) ...[
                    SizedBox(height: 8),
                    Text(
                      _formatDuration(_callDuration),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Avatar
            Expanded(
              child: Center(
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.blue[600],
                  child: Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Call controls
            Container(
              padding: EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _isMuted ? Colors.white : Colors.white24,
                    child: IconButton(
                      icon: Icon(
                        _isMuted ? Icons.mic_off : Icons.mic,
                        color: _isMuted ? Colors.black : Colors.white,
                      ),
                      onPressed: _toggleMute,
                    ),
                  ),

                  // End call button
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.red,
                    child: IconButton(
                      icon: Icon(Icons.call_end, color: Colors.white, size: 30),
                      onPressed: _endCall,
                    ),
                  ),

                  // Speaker button
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        _isSpeakerOn ? Colors.white : Colors.white24,
                    child: IconButton(
                      icon: Icon(
                        _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                        color: _isSpeakerOn ? Colors.black : Colors.white,
                      ),
                      onPressed: _toggleSpeaker,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }
}
