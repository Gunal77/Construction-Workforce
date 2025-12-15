import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/projects_providers.dart';
import '../../../../data/models/project_model.dart';
import '../../../../core/utils/error_message_helper.dart';
import '../../../../shared/widgets/pagination_widget.dart';
import '../../../../shared/widgets/searchable_dropdown.dart';
import 'project_detail_screen.dart';

class ProjectsListScreen extends ConsumerStatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  ConsumerState<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends ConsumerState<ProjectsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _statusFilter;
  String? _locationFilter;
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProjectModel> _getFilteredProjects(List<ProjectModel> projects) {
    var filtered = projects;

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
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      filtered = filtered.where((project) {
        final isActive = project.isActive;
        if (_statusFilter == 'active') {
          return isActive;
        } else if (_statusFilter == 'inactive') {
          return !isActive;
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

    return filtered;
  }

  List<String> _getUniqueLocations(List<ProjectModel> projects) {
    final locations = projects
        .where((p) => p.location != null && p.location!.isNotEmpty)
        .map((p) => p.location!)
        .toSet()
        .toList()
      ..sort();
    return locations;
  }

  List<ProjectModel> _getPaginatedProjects(List<ProjectModel> projects) {
    if (projects.isEmpty) return [];
    if (projects.length <= _itemsPerPage) return projects;
    
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    if (startIndex >= projects.length) return [];
    
    final endIndex = (startIndex + _itemsPerPage).clamp(0, projects.length);
    return projects.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);

    return projectsAsync.when(
      data: (allProjects) {
        if (allProjects.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No projects assigned',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final filteredProjects = _getFilteredProjects(allProjects);
        final paginatedProjects = _getPaginatedProjects(filteredProjects);
        final totalPages = (filteredProjects.length / _itemsPerPage).ceil();
        final startIndex = (_currentPage - 1) * _itemsPerPage;

        return Column(
          children: [
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
                                  setState(() {
                                    _searchController.clear();
                                    _currentPage = 1;
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      onChanged: (_) {
                        setState(() {
                          _currentPage = 1;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Status filter
                    SearchableDropdown<String>(
                      label: 'Status',
                      hint: 'All Status',
                      value: _statusFilter,
                      prefixIcon: const Icon(Icons.flag_outlined),
                      searchHint: 'Search status...',
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
                          value: 'inactive',
                          child: Text('Inactive', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _statusFilter = value;
                          _currentPage = 1;
                        });
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
                        ..._getUniqueLocations(allProjects).map(
                          (location) => DropdownMenuItem<String>(
                            value: location,
                            child: Text(location, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _locationFilter = value;
                          _currentPage = 1;
                        });
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
                              _currentPage = 1;
                            });
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
              child: filteredProjects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No projects found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(projectsProvider);
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: paginatedProjects.length,
                              itemBuilder: (context, index) {
                                final project = paginatedProjects[index];
                                return _ProjectCard(project: project);
                              },
                            ),
                          ),
                          if (filteredProjects.length > _itemsPerPage)
                            PaginationWidget(
                              currentPage: _currentPage,
                              totalPages: totalPages,
                              onPageChanged: (page) {
                                setState(() {
                                  _currentPage = page;
                                });
                              },
                              totalItems: filteredProjects.length,
                              itemsPerPage: _itemsPerPage,
                              startIndex: startIndex,
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        final errorMessage = ErrorMessageHelper.getUserFriendlyMessage(error);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading projects',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    errorMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(projectsProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isActive = project.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(projectId: project.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (project.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        project.location!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
              if (project.startDate != null || project.endDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${project.startDate != null ? dateFormat.format(project.startDate!) : 'TBD'} - ${project.endDate != null ? dateFormat.format(project.endDate!) : 'Ongoing'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
              if (project.budget != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Budget: \$${NumberFormat('#,###').format(project.budget!.toInt())}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
