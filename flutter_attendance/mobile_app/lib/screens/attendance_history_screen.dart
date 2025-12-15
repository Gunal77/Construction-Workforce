import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/attendance_card.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/pagination_widget.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({
    super.key,
    this.onBackPressed,
  });

  final VoidCallback? onBackPressed;

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<dynamic> _records = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadAttendanceRecords();
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final records = await ApiService().fetchMyAttendance();
      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
          _isRefreshing = false;
          _currentPage = 1; // Reset to first page when data reloads
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _records = [];
        });
        _showMessage(
          error is ApiException ? error.message : 'Failed to load records',
        );
      }
    }
  }

  Future<void> _refreshRecords() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadAttendanceRecords();
  }

  List<dynamic> _getPaginatedRecords() {
    if (_records.isEmpty) return [];
    if (_records.length <= _itemsPerPage) return _records;
    
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    if (startIndex >= _records.length) return [];
    
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _records.length);
    return _records.sublist(startIndex, endIndex);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: CustomAppBar(
        title: 'Attendance History',
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
            onPressed: _isRefreshing ? null : _refreshRecords,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _records.isEmpty
              ? RefreshIndicator(
                  onRefresh: _refreshRecords,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: AppTheme.textColor.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No attendance records found',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textColor.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pull down to refresh',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.textColor.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshRecords,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _getPaginatedRecords().length,
                          itemBuilder: (context, index) {
                            final paginatedRecords = _getPaginatedRecords();
                            if (index >= paginatedRecords.length) {
                              return const SizedBox.shrink();
                            }
                            final record = paginatedRecords[index];
                            if (record is! Map<String, dynamic>) {
                              return const SizedBox.shrink();
                            }
                            return AttendanceCard(
                              record: record,
                              onTap: () {
                                // Handle tap if needed
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    if (_records.length > _itemsPerPage)
                      PaginationWidget(
                        currentPage: _currentPage,
                        totalPages: (_records.length / _itemsPerPage).ceil(),
                        onPageChanged: (page) {
                          setState(() {
                            _currentPage = page;
                          });
                        },
                        totalItems: _records.length,
                        itemsPerPage: _itemsPerPage,
                        startIndex: (_currentPage - 1) * _itemsPerPage,
                      ),
                  ],
                ),
    );
  }
}

