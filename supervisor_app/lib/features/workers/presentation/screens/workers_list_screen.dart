import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workers_providers.dart';
import '../../../../data/models/worker_model.dart';
import '../../../../core/utils/error_message_helper.dart';
import '../widgets/assign_project_dialog.dart';
import '../../../../shared/widgets/pagination_widget.dart';
import '../../../../shared/widgets/searchable_dropdown.dart';
import 'worker_detail_screen.dart';

class WorkersListScreen extends ConsumerStatefulWidget {
  const WorkersListScreen({super.key});

  @override
  ConsumerState<WorkersListScreen> createState() => _WorkersListScreenState();
}

class _WorkersListScreenState extends ConsumerState<WorkersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _roleFilter;
  String? _projectFilter;
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WorkerModel> _getFilteredWorkers(List<WorkerModel> workers) {
    var filtered = workers;

    // Search filter
    final searchQuery = _searchController.text.toLowerCase().trim();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((worker) {
        final nameMatch = worker.name.toLowerCase().contains(searchQuery);
        final emailMatch = worker.email?.toLowerCase().contains(searchQuery) ?? false;
        final roleMatch = worker.role?.toLowerCase().contains(searchQuery) ?? false;
        return nameMatch || emailMatch || roleMatch;
      }).toList();
    }

    // Role filter
    if (_roleFilter != null && _roleFilter!.isNotEmpty) {
      filtered = filtered.where((worker) => worker.role == _roleFilter).toList();
    }

    // Project filter
    if (_projectFilter != null && _projectFilter!.isNotEmpty) {
      filtered = filtered.where((worker) => worker.projectId == _projectFilter).toList();
    }

    return filtered;
  }

  List<String> _getUniqueRoles(List<WorkerModel> workers) {
    final roles = workers
        .where((w) => w.role != null && w.role!.isNotEmpty)
        .map((w) => w.role!)
        .toSet()
        .toList()
      ..sort();
    return roles;
  }

  List<WorkerModel> _getUniqueProjects(List<WorkerModel> workers) {
    final projectIds = workers
        .where((w) => w.projectId != null && w.projectId!.isNotEmpty)
        .map((w) => w.projectId!)
        .toSet()
        .toList();
    return workers.where((w) => projectIds.contains(w.projectId)).toList();
  }

  List<WorkerModel> _getPaginatedWorkers(List<WorkerModel> workers) {
    if (workers.isEmpty) return [];
    if (workers.length <= _itemsPerPage) return workers;
    
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    if (startIndex >= workers.length) return [];
    
    final endIndex = (startIndex + _itemsPerPage).clamp(0, workers.length);
    return workers.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workersProvider);

    return workersAsync.when(
      data: (allWorkers) {
        if (allWorkers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No workers assigned',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Workers will appear here once assigned',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final filteredWorkers = _getFilteredWorkers(allWorkers);
        final paginatedWorkers = _getPaginatedWorkers(filteredWorkers);
        final totalPages = (filteredWorkers.length / _itemsPerPage).ceil();
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
                        labelText: 'Search workers',
                        hintText: 'Search by name, email, or role',
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
                    // Role filter
                    SearchableDropdown<String>(
                      label: 'Role',
                      hint: 'All Roles',
                      value: _roleFilter,
                      prefixIcon: const Icon(Icons.work_outline),
                      searchHint: 'Search roles...',
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Roles', overflow: TextOverflow.ellipsis),
                        ),
                        ..._getUniqueRoles(allWorkers).map(
                          (role) => DropdownMenuItem<String>(
                            value: role,
                            child: Text(role, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _roleFilter = value;
                          _currentPage = 1;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Project filter
                    SearchableDropdown<String>(
                      label: 'Project',
                      hint: 'All Projects',
                      value: _projectFilter,
                      prefixIcon: const Icon(Icons.folder_outlined),
                      searchHint: 'Search projects...',
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Projects', overflow: TextOverflow.ellipsis),
                        ),
                        ..._getUniqueProjects(allWorkers).map(
                          (worker) => DropdownMenuItem<String>(
                            value: worker.projectId,
                            child: Text(
                              worker.projectName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _projectFilter = value;
                          _currentPage = 1;
                        });
                      },
                    ),
                    if (_roleFilter != null || _projectFilter != null || _searchController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _roleFilter = null;
                              _projectFilter = null;
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
            // Workers list
            Expanded(
              child: filteredWorkers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No workers found',
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
                        ref.invalidate(workersProvider);
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: paginatedWorkers.length,
                              itemBuilder: (context, index) {
                                final worker = paginatedWorkers[index];
                                return _WorkerCard(worker: worker);
                              },
                            ),
                          ),
                          if (filteredWorkers.length > _itemsPerPage)
                            PaginationWidget(
                              currentPage: _currentPage,
                              totalPages: totalPages,
                              onPageChanged: (page) {
                                setState(() {
                                  _currentPage = page;
                                });
                              },
                              totalItems: filteredWorkers.length,
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
        // Print error for debugging
        print('Workers error: $error');
        print('Error type: ${error.runtimeType}');
        print('Stack: $stack');
        
        // Extract user-friendly error message
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
                  'Error loading workers',
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
                    ref.invalidate(workersProvider);
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

class _WorkerCard extends StatelessWidget {
  final WorkerModel worker;

  const _WorkerCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            worker.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          worker.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (worker.role != null) 
              Text(
                'Role: ${worker.role}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              'Project: ${worker.projectName}',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            if (worker.email != null) 
              Text(
                'Email: ${worker.email}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.work_outline, size: 20),
              tooltip: 'Assign Project',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AssignProjectDialog(
                    workerId: worker.id,
                    currentProjectId: worker.projectId,
                  ),
                );
              },
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerDetailScreen(workerId: worker.id),
            ),
          );
        },
      ),
    );
  }
}
