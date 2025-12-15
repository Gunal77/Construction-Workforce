import 'package:flutter/material.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Widget? prefixIcon;
  final String? searchHint;
  final bool isExpanded;

  const SearchableDropdown({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.prefixIcon,
    this.searchHint,
    this.isExpanded = true,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  bool _isOpen = false;
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _closeDropdown();
    _searchController.dispose();
    super.dispose();
  }

  void _closeDropdown() {
    if (_isOpen) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() {
        _isOpen = false;
        _searchController.clear();
      });
    }
  }

  void _rebuildOverlay() {
    if (!_isOpen || _overlayEntry == null) return;
    _overlayEntry!.markNeedsBuild();
  }

  List<DropdownMenuItem<T>> get _filteredItems {
    if (_searchController.text.isEmpty) {
      return widget.items;
    }
    final query = _searchController.text.toLowerCase();
    return widget.items.where((item) {
      final text = item.child is Text
          ? (item.child as Text).data?.toLowerCase() ?? ''
          : item.child.toString().toLowerCase();
      return text.contains(query);
    }).toList();
  }

  String? get _selectedLabel {
    if (widget.value == null) return widget.hint ?? 'Select an option';
    final selectedItem = widget.items.firstWhere(
      (item) => item.value == widget.value,
      orElse: () => widget.items.first,
    );
    if (selectedItem.child is Text) {
      return (selectedItem.child as Text).data;
    }
    return widget.hint ?? 'Select an option';
  }

  void _showDropdown() {
    if (_isOpen) return;
    
    final overlay = Overlay.of(context);
    final renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = MediaQuery.of(context).padding;
    
    // Calculate available space below the button
    final spaceBelow = screenHeight - offset.dy - size.height - padding.bottom - 100;
    final spaceAbove = offset.dy - padding.top - 50;
    
    // Use space below if available, otherwise use space above
    final useSpaceBelow = spaceBelow > 150 || spaceBelow > spaceAbove;
    final availableHeight = (useSpaceBelow ? spaceBelow : spaceAbove).clamp(150.0, 300.0);
    
    _overlayEntry = OverlayEntry(
      builder: (context) {
        final filteredItems = _filteredItems;
        return Stack(
          children: [
            // Full screen tap detector to close dropdown
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeDropdown,
                child: Container(color: Colors.transparent),
              ),
            ),
            // Dropdown content
            Positioned(
              left: offset.dx,
              top: useSpaceBelow ? offset.dy + size.height + 4 : null,
              bottom: useSpaceBelow ? null : screenHeight - offset.dy + 4,
              width: screenWidth - offset.dx - 16,
              child: GestureDetector(
                onTap: () {}, // Prevent tap from closing dropdown
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: availableHeight,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search field
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: widget.searchHint ?? 'Search...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              isDense: true,
                            ),
                            onChanged: (_) => _rebuildOverlay(),
                          ),
                        ),
                        const Divider(height: 1),
                        // Options list
                        Flexible(
                          child: filteredItems.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'No options found',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: filteredItems.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredItems[index];
                                    final isSelected = item.value == widget.value;
                                    return InkWell(
                                      onTap: () {
                                        widget.onChanged?.call(item.value);
                                        _closeDropdown();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        color: isSelected
                                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                                            : Colors.transparent,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: item.child,
                                            ),
                                            if (isSelected)
                                              Icon(
                                                Icons.check,
                                                size: 20,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    
    overlay.insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isOpen) {
          _closeDropdown();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.label!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          GestureDetector(
            onTap: () {
              if (_isOpen) {
                _closeDropdown();
              } else {
                _showDropdown();
              }
            },
            child: InputDecorator(
              key: _buttonKey,
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: widget.prefixIcon,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.value != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          widget.onChanged?.call(null);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    Icon(
                      _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              child: Text(
                _selectedLabel ?? '',
                style: TextStyle(
                  color: widget.value != null
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

