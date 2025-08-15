import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/enhanced_call_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerId;
  final String callerName;
  final String callerPhone;
  final String? callerAvatar;
  final bool isVideoCall;
  final EnhancedCallService callService;

  const IncomingCallScreen({
    super.key,
    required this.callerId,
    required this.callerName,
    required this.callerPhone,
    this.callerAvatar,
    this.isVideoCall = false,
    required this.callService,
  });

  @override
  _IncomingCallScreenState createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _avatarController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _avatarAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for call indication
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Avatar animation
    _avatarController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _avatarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.elasticOut),
    );
    _avatarController.forward();

    // Vibrate on incoming call
    _startCallVibration();
  }

  void _startCallVibration() {
    // Add vibration pattern for incoming call
    HapticFeedback.heavyImpact();
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _acceptCall() {
    HapticFeedback.lightImpact();
    widget.callService.acceptCall();
    Navigator.of(context).pop(true);
  }

  void _rejectCall() {
    HapticFeedback.mediumImpact();
    widget.callService.rejectCall();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade900.withValues(alpha: 0.8),
                Colors.black87,
              ],
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 60),
              
              // Call type indicator
              Text(
                widget.isVideoCall ? 'Incoming Video Call' : 'Incoming Call',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
              
              SizedBox(height: 40),
              
              // Caller avatar with animation
              AnimatedBuilder(
                animation: _avatarAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _avatarAnimation.value,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 75,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: widget.callerAvatar != null
                                  ? NetworkImage(widget.callerAvatar!)
                                  : null,
                              child: widget.callerAvatar == null
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey.shade600,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              
              SizedBox(height: 40),
              
              // Caller name
              Text(
                widget.callerName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 8),
              
              // Caller phone
              Text(
                widget.callerPhone,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),
              
              Spacer(),
              
              // Call action buttons
              Padding(
                padding: EdgeInsets.all(40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Reject call button
                    GestureDetector(
                      onTap: _rejectCall,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    
                    // Accept call button
                    GestureDetector(
                      onTap: _acceptCall,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.call,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
