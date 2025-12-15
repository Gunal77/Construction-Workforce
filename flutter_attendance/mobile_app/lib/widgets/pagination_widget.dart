import 'package:flutter/material.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final int totalItems;
  final int itemsPerPage;
  final int startIndex;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.totalItems,
    required this.itemsPerPage,
    required this.startIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final maxVisiblePages = isMobile ? 5 : 7;

        return Container(
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: isMobile ? 4 : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Page info
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Showing ${startIndex + 1} - ${(startIndex + itemsPerPage).clamp(0, totalItems)} of $totalItems',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: isMobile ? 11 : null,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Pagination controls - scrollable on mobile
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // First page button
                    _buildIconButton(
                      icon: Icons.first_page,
                      onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
                      tooltip: 'First page',
                      isMobile: isMobile,
                    ),
                    // Previous page button
                    _buildIconButton(
                      icon: Icons.chevron_left,
                      onPressed: currentPage > 1
                          ? () => onPageChanged(currentPage - 1)
                          : null,
                      tooltip: 'Previous page',
                      isMobile: isMobile,
                    ),
                    // Page numbers
                    ..._buildPageNumbers(context, maxVisiblePages, isMobile),
                    // Next page button
                    _buildIconButton(
                      icon: Icons.chevron_right,
                      onPressed: currentPage < totalPages
                          ? () => onPageChanged(currentPage + 1)
                          : null,
                      tooltip: 'Next page',
                      isMobile: isMobile,
                    ),
                    // Last page button
                    _buildIconButton(
                      icon: Icons.last_page,
                      onPressed: currentPage < totalPages
                          ? () => onPageChanged(totalPages)
                          : null,
                      tooltip: 'Last page',
                      isMobile: isMobile,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    required bool isMobile,
  }) {
    return IconButton(
      icon: Icon(icon, size: isMobile ? 18 : 24),
      iconSize: isMobile ? 18 : 24,
      padding: EdgeInsets.all(isMobile ? 4 : 8),
      constraints: BoxConstraints(
        minWidth: isMobile ? 32 : 40,
        minHeight: isMobile ? 32 : 40,
      ),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  List<Widget> _buildPageNumbers(BuildContext context, int maxVisiblePages, bool isMobile) {
    final pagesToShow = totalPages > maxVisiblePages ? maxVisiblePages : totalPages;
    final pageWidgets = <Widget>[];

    for (int index = 0; index < pagesToShow; index++) {
      int pageNumber;
      if (totalPages <= maxVisiblePages) {
        pageNumber = index + 1;
      } else {
        // Show first, last, and pages around current
        if (currentPage <= 3) {
          pageNumber = index + 1;
          if (index == pagesToShow - 1 && totalPages > maxVisiblePages) {
            pageWidgets.add(_buildEllipsis(isMobile));
            continue;
          }
        } else if (currentPage >= totalPages - 2) {
          if (index == 0 && totalPages > maxVisiblePages) {
            pageWidgets.add(_buildEllipsis(isMobile));
            continue;
          }
          pageNumber = totalPages - (pagesToShow - 1) + index;
        } else {
          if (index == 0 || index == pagesToShow - 1) {
            pageWidgets.add(_buildEllipsis(isMobile));
            continue;
          }
          pageNumber = currentPage - (pagesToShow ~/ 2) + index;
        }
      }

      final isCurrentPage = pageNumber == currentPage;
      pageWidgets.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4),
          child: InkWell(
            onTap: () => onPageChanged(pageNumber),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 12,
                vertical: isMobile ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: isCurrentPage
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$pageNumber',
                style: TextStyle(
                  color: isCurrentPage
                      ? Colors.white
                      : Colors.grey.shade700,
                  fontWeight: isCurrentPage
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return pageWidgets;
  }

  Widget _buildEllipsis(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4),
      child: Text(
        '...',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 12 : 14,
        ),
      ),
    );
  }
}

