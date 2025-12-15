import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';

class CheckInOutScreen extends StatefulWidget {
  const CheckInOutScreen({
    super.key,
    this.onBackPressed,
  });

  final VoidCallback? onBackPressed;

  @override
  State<CheckInOutScreen> createState() => _CheckInOutScreenState();
}

class _CheckInOutScreenState extends State<CheckInOutScreen> {
  final _latController = TextEditingController();
  final _longController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _isCheckingIn = false;
  bool _isCheckingOut = false;
  XFile? _selectedImage;

  @override
  void dispose() {
    _latController.dispose();
    _longController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (error) {
      _showMessage('Unable to capture image');
    }
  }

  Future<void> _handleCheckIn() async {
    final lat = double.tryParse(_latController.text.trim());
    final long = double.tryParse(_longController.text.trim());

    if (_selectedImage == null) {
      _showMessage('Please select an image before checking in');
      return;
    }
    if (lat == null || long == null) {
      _showMessage('Please provide valid latitude and longitude');
      return;
    }

    setState(() {
      _isCheckingIn = true;
    });

    try {
      await ApiService().checkIn(
        imageFile: File(_selectedImage!.path),
        latitude: lat,
        longitude: long,
      );
      if (mounted) {
        _showSuccessMessage('Check-in successful');
        setState(() {
          _selectedImage = null;
        });
        _latController.clear();
        _longController.clear();
      }
    } catch (error) {
      _showMessage(error is ApiException ? error.message : 'Check-in failed');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }

  Future<void> _handleCheckOut() async {
    setState(() {
      _isCheckingOut = true;
    });

    try {
      await ApiService().checkOut();
      if (mounted) {
        _showSuccessMessage('Check-out successful');
      }
    } catch (error) {
      _showMessage(error is ApiException ? error.message : 'Check-out failed');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: CustomAppBar(
        title: 'Check In / Check Out',
        showBackButton: widget.onBackPressed != null,
        leading: widget.onBackPressed != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: widget.onBackPressed,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _selectedImage = null;
                _latController.clear();
                _longController.clear();
              });
            },
            tooltip: 'Clear',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Location Input Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Location',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _latController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Latitude',
                              prefixIcon: const Icon(Icons.north),
                              filled: true,
                              fillColor: AppTheme.backgroundColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _longController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Longitude',
                              prefixIcon: const Icon(Icons.east),
                              filled: true,
                              fillColor: AppTheme.backgroundColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Image Selection Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.image,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Photo',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_selectedImage != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(_selectedImage!.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    CustomButton(
                      onPressed: _pickImageFromCamera,
                      text: 'Camera',
                      icon: Icons.camera_alt,
                      isOutlined: true,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Check In Button
            CustomButton(
              onPressed: _isCheckingIn ? null : _handleCheckIn,
              text: 'Check In',
              icon: Icons.login,
              isLoading: _isCheckingIn,
              width: double.infinity,
              height: 56,
            ),
            const SizedBox(height: 16),
            // Check Out Button
            CustomButton(
              onPressed: _isCheckingOut ? null : _handleCheckOut,
              text: 'Check Out',
              icon: Icons.logout,
              isLoading: _isCheckingOut,
              backgroundColor: AppTheme.secondaryColor,
              width: double.infinity,
              height: 56,
            ),
            const SizedBox(height: 24),
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Make sure to provide accurate location and a clear photo for check-in.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textColor.withOpacity(0.7),
                      ),
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
}

