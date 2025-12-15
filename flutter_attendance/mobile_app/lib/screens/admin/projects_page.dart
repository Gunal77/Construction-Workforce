import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/project.dart';
import '../../services/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/searchable_dropdown.dart';
import 'admin_login.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({
    super.key,
    this.onBackPressed,
  });

  final VoidCallback? onBackPressed;

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final ApiService _apiService = ApiService();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  final TextEditingController _searchController = TextEditingController();
  List<Project> _projects = [];
  List<Project> _filteredProjects = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  String? _statusFilter; // 'active', 'completed', null for all
  String? _locationFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final projects = await _apiService.fetchProjects();
      if (mounted) {
        setState(() {
          _projects = projects;
          _isLoading = false;
          _currentPage = 1; // Reset to first page when data reloads
        });
        _applyFilters();
      }
    } catch (error) {
      final message = error is ApiException
          ? error.message
          : 'Failed to load projects';
      if (mounted) {
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final descriptionController = TextEditingController();
    final budgetController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name *',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    hintText: 'Enter project description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: budgetController,
                  decoration: const InputDecoration(
                    labelText: 'Budget (SGD)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 1000000',
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    startDate == null
                        ? 'Start Date'
                        : _dateFormat.format(startDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setDialogState(() => startDate = date);
                    }
                  },
                ),
                ListTile(
                  title: Text(
                    endDate == null ? 'End Date' : _dateFormat.format(endDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setDialogState(() => endDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Project name is required')),
                  );
                  return;
                }

                double? budget;
                if (budgetController.text.trim().isNotEmpty) {
                  budget = double.tryParse(budgetController.text.trim());
                  if (budget == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid budget amount')),
                    );
                    return;
                  }
                }

                try {
                  await _apiService.createProject(
                    name: nameController.text.trim(),
                    location: locationController.text.trim().isEmpty
                        ? null
                        : locationController.text.trim(),
                    startDate: startDate,
                    endDate: endDate,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    budget: budget,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    _loadProjects();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Project created successfully')),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error is ApiException
                              ? error.message
                              : 'Failed to create project',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(Project project) async {
    final nameController = TextEditingController(text: project.name);
    final locationController = TextEditingController(text: project.location ?? '');
    final descriptionController = TextEditingController(text: project.description ?? '');
    final budgetController = TextEditingController(
      text: project.budget != null ? project.budget!.toStringAsFixed(0) : '',
    );
    DateTime? startDate = project.startDate;
    DateTime? endDate = project.endDate;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    hintText: 'Enter project description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: budgetController,
                  decoration: const InputDecoration(
                    labelText: 'Budget (SGD)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 1000000',
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    startDate == null
                        ? 'Start Date'
                        : _dateFormat.format(startDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setDialogState(() => startDate = date);
                    }
                  },
                ),
                ListTile(
                  title: Text(
                    endDate == null ? 'End Date' : _dateFormat.format(endDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setDialogState(() => endDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Project name is required')),
                  );
                  return;
                }

                double? budget;
                if (budgetController.text.trim().isNotEmpty) {
                  budget = double.tryParse(budgetController.text.trim());
                  if (budget == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid budget amount')),
                    );
                    return;
                  }
                }

                try {
                  await _apiService.updateProject(
                    id: project.id,
                    name: nameController.text.trim(),
                    location: locationController.text.trim().isEmpty
                        ? null
                        : locationController.text.trim(),
                    startDate: startDate,
                    endDate: endDate,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    budget: budget,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    _loadProjects();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Project updated successfully')),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error is ApiException
                              ? error.message
                              : 'Failed to update project',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteProject(project.id);
        if (mounted) {
          _loadProjects();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project deleted successfully')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error is ApiException
                    ? error.message
                    : 'Failed to delete project',
              ),
            ),
          );
        }
      }
    }
  }

  void _applyFilters() {
    var filtered = List<Project>.from(_projects);

    // Search filter
    final searchQuery = _searchController.text.toLowerCase().trim();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((project) {
        final nameMatch = project.name.toLowerCase().contains(searchQuery);
        final locationMatch = project.location?.toLowerCase().contains(searchQuery) ?? false;
        final descMatch = project.description?.toLowerCase().contains(searchQuery) ?? false;
        return nameMatch || locationMatch || descMatch;
      }).toList();
    }

    // Status filter
    if (_statusFilter != null) {
      filtered = filtered.where((project) {
        final isCompleted = project.endDate != null &&
            project.endDate!.isBefore(DateTime.now());
        if (_statusFilter == 'active') {
          return !isCompleted;
        } else if (_statusFilter == 'completed') {
          return isCompleted;
        }
        return true;
      }).toList();
    }

    // Location filter
    if (_locationFilter != null && _locationFilter!.isNotEmpty) {
      filtered = filtered.where((project) {
        return project.location?.toLowerCase() == _locationFilter!.toLowerCase();
      }).toList();
    }

    setState(() {
      _filteredProjects = filtered;
      _currentPage = 1; // Reset to first page when filters change
    });
  }

  List<String> _getUniqueLocations() {
    final locations = _projects
        .where((p) => p.location != null && p.location!.isNotEmpty)
        .map((p) => p.location!)
        .toSet()
        .toList()
      ..sort();
    return locations;
  }

  List<Project> _getPaginatedProjects() {
    if (_filteredProjects.isEmpty) return [];
    if (_filteredProjects.length <= _itemsPerPage) return _filteredProjects;
    
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    if (startIndex >= _filteredProjects.length) return [];
    
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredProjects.length);
    return _filteredProjects.sublist(startIndex, endIndex);
  }

  String _formatBudget(double? budget) {
    if (budget == null) return '';
    if (budget >= 1000000) {
      return '\$${(budget / 1000000).toStringAsFixed(1)}M';
    } else if (budget >= 1000) {
      return '\$${(budget / 1000).toStringAsFixed(1)}K';
    }
    return _currencyFormat.format(budget);
  }

  Widget _buildBodyContent() {
    final children = <Widget>[
      // Filters Section
      Card(
        elevation: 2,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_alt, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search projects',
                  hintText: 'Search by name, location, or description',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              // Status filter
              DropdownButtonFormField<String>(
                value: _statusFilter,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Status',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Status', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem<String>(
                    value: 'active',
                    child: Text('Active', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem<String>(
                    value: 'completed',
                    child: Text('Completed', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _statusFilter = value;
                  });
                  _applyFilters();
                },
              ),
              const SizedBox(height: 12),
              // Location filter
              SearchableDropdown<String>(
                label: 'Location',
                hint: 'All Locations',
                value: _locationFilter,
                prefixIcon: const Icon(Icons.location_on_outlined),
                searchHint: 'Search locations...',
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Locations', overflow: TextOverflow.ellipsis),
                  ),
                  ..._getUniqueLocations().map(
                    (location) => DropdownMenuItem<String>(
                      value: location,
                      child: Text(location, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _locationFilter = value;
                  });
                  _applyFilters();
                },
              ),
              if (_statusFilter != null || _locationFilter != null || _searchController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _statusFilter = null;
                        _locationFilter = null;
                        _searchController.clear();
                      });
                      _applyFilters();
                    },
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear Filters'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      // Projects list
      Expanded(
        child: _filteredProjects.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _projects.isEmpty
                          ? 'No projects found'
                          : 'No projects match the filters',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _projects.isEmpty
                          ? 'Tap the + button to create your first project'
                          : 'Try adjusting your filters',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadProjects,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _getPaginatedProjects().length,
                  itemBuilder: (context, index) {
                    final paginatedProjects = _getPaginatedProjects();
                    if (index >= paginatedProjects.length) {
                      return const SizedBox.shrink();
                    }
                    final project = paginatedProjects[index];
                    final isCompleted = project.endDate != null &&
                        project.endDate!.isBefore(DateTime.now());
                    final isActive = !isCompleted;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () => _showEditDialog(project),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.green.shade50
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.folder,
                                      color: isActive
                                          ? Colors.green.shade600
                                          : Colors.grey.shade600,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          project.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Colors.green.shade50
                                                : Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isActive ? 'ACTIVE' : 'COMPLETED',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: isActive
                                                      ? Colors.green.shade700
                                                      : Colors.grey.shade700,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 10,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton(
                                    icon: const Icon(Icons.more_vert),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: const Row(
                                          children: [
                                            Icon(Icons.edit, size: 20),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                        onTap: () {
                                          Future.delayed(
                                            Duration.zero,
                                            () => _showEditDialog(project),
                                          );
                                        },
                                      ),
                                      PopupMenuItem(
                                        child: const Row(
                                          children: [
                                            Icon(Icons.delete,
                                                size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete',
                                                style:
                                                    TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                        onTap: () {
                                          Future.delayed(
                                            Duration.zero,
                                            () => _deleteProject(project),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (project.description != null &&
                                  project.description!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  project.description!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.grey.shade700,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    if (project.location != null &&
                                        project.location!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Icon(Icons.location_on_outlined,
                                                size: 18,
                                                color: Colors.grey.shade600),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                project.location!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: Colors.grey.shade700,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (project.budget != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Icon(Icons.attach_money,
                                                size: 18,
                                                color: Colors.grey.shade600),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Budget: ${_formatBudget(project.budget)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (project.startDate != null ||
                                        project.endDate != null)
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today_outlined,
                                              size: 18,
                                              color: Colors.grey.shade600),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              project.startDate != null &&
                                                      project.endDate != null
                                                  ? '${_dateFormat.format(project.startDate!)} - ${_dateFormat.format(project.endDate!)}'
                                                  : project.startDate != null
                                                      ? 'From ${_dateFormat.format(project.startDate!)}'
                                                      : project.endDate != null
                                                          ? 'Until ${_dateFormat.format(project.endDate!)}'
                                                          : '',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: Colors.grey.shade700,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    ];

    if (_filteredProjects.length > _itemsPerPage) {
      children.add(
        PaginationWidget(
          currentPage: _currentPage,
          totalPages: (_filteredProjects.length / _itemsPerPage).ceil(),
          onPageChanged: (page) {
            setState(() {
              _currentPage = page;
            });
          },
          totalItems: _filteredProjects.length,
          itemsPerPage: _itemsPerPage,
          startIndex: (_currentPage - 1) * _itemsPerPage,
        ),
      );
    }

    return Column(
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBackPressed != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: widget.onBackPressed,
              )
            : null,
        title: const Text(
          'Projects',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _loadProjects,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await _apiService.clearAdminSession();
              if (!mounted) return;
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                (route) => false,
              );
            },
            tooltip: 'Log out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProjects,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildBodyContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        tooltip: 'Add Project',
        child: const Icon(Icons.add),
      ),
    );
  }
}
