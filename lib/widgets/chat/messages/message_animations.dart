// widgets/message_animations.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../data/models/chat_message.dart';

class MessageAnimations {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _waveController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  late Animation<Offset> slideAnimation;
  late Animation<double> scaleAnimation;
  late Animation<double> fadeAnimation;
  late Animation<double> waveAnimation;
  late Animation<double> shimmerAnimation;
  late Animation<double> pulseAnimation;
  late Animation<double> rotationAnimation;

  late Listenable combinedAnimation;

  final TickerProvider _vsync;

  MessageAnimations(this._vsync) {
    _setupAnimations();
  }

  void _setupAnimations() {
    // Entry animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: _vsync,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: _vsync,
    );

    // Audio wave animation
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: _vsync,
    );

    // Shimmer effect for sending messages
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: _vsync,
    );

    // Pulse animation for interactive elements
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: _vsync,
    );

    // Rotation for loading states
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: _vsync,
    );

    _createAnimations();
  }

  void _createAnimations() {
    // Combined animation for main bubble
    combinedAnimation = Listenable.merge([
      _slideController,
      _scaleController,
      _pulseController,
    ]);

    // Fade animation
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    // Scale animation with bounce
    scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Wave animation for audio
    waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    // Shimmer animation
    shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation
    pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Rotation animation
    rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
  }

  void setSlideDirection(bool isUser) {
    slideAnimation = Tween<Offset>(
      begin: isUser 
          ? const Offset(0.3, 0) 
          : const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void startEntryAnimation(ChatMessage message, bool isPlaying) {
    setSlideDirection(message.isUser);
    
    Future.delayed(Duration(milliseconds: message.isUser ? 0 : 100), () {
      _slideController.forward();
      _scaleController.forward();
    });

    // Start shimmer for sending messages
    if (message.status == MessageStatus.sending) {
      _shimmerController.repeat();
    }

    // Start wave animation for playing audio
    if (isPlaying && message.isVoice) {
      _waveController.repeat(reverse: true);
    }
  }

  void handleStateChanges(
    ChatMessage newMessage,
    ChatMessage oldMessage,
    bool isPlaying,
    bool wasPlaying,
  ) {
    // Handle audio playback state changes
    if (isPlaying != wasPlaying && newMessage.isVoice) {
      if (isPlaying) {
        _waveController.repeat(reverse: true);
        _pulseController.repeat(reverse: true);
      } else {
        _waveController.stop();
        _pulseController.stop();
        _waveController.reset();
        _pulseController.reset();
      }
    }

    // Handle message status changes
    if (newMessage.status != oldMessage.status) {
      if (newMessage.status == MessageStatus.sending) {
        _shimmerController.repeat();
      } else {
        _shimmerController.stop();
      }
      
      if (newMessage.status == MessageStatus.failed) {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  void startRotation() {
    _rotationController.repeat();
  }

  void stopRotation() {
    _rotationController.stop();
    _rotationController.reset();
  }

  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _waveController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
  }
}