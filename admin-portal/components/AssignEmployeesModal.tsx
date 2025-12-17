'use client';

import { useState, useEffect } from 'react';
import { X, Search, Users, AlertCircle, CheckCircle2 } from 'lucide-react';
import { projectsAPI, Employee } from '@/lib/api';

interface AssignEmployeesModalProps {
  isOpen: boolean;
  onClose: () => void;
  projectId: string;
  projectName: string;
  onAssignSuccess: () => void;
}

export default function AssignEmployeesModal({
  isOpen,
  onClose,
  projectId,
  projectName,
  onAssignSuccess,
}: AssignEmployeesModalProps) {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [selectedEmployeeIds, setSelectedEmployeeIds] = useState<Set<string>>(new Set());
  const [searchQuery, setSearchQuery] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(false);
  const [assigning, setAssigning] = useState(false);
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [dateError, setDateError] = useState('');
  const [attemptedSubmit, setAttemptedSubmit] = useState(false);
  const pageLimit = 10;

  // Fetch available employees
  useEffect(() => {
    if (isOpen) {
      fetchEmployees();
    }
  }, [isOpen, searchQuery, currentPage]);

  const fetchEmployees = async () => {
    try {
      setLoading(true);
      setError('');
      const data = await projectsAPI.getAvailableEmployees(projectId, {
        search: searchQuery,
        page: currentPage,
        limit: pageLimit,
      });
      setEmployees(data.employees || []);
      setTotalPages(data.totalPages || 1);
    } catch (err: any) {
      console.error('Error fetching employees:', err);
      setError('Failed to load employees');
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = () => {
    setCurrentPage(1);
    fetchEmployees();
  };

  const handleToggleEmployee = (employeeId: string, isAssignedElsewhere: boolean) => {
    if (isAssignedElsewhere) return; // Don't allow selecting employees assigned elsewhere

    const newSelected = new Set(selectedEmployeeIds);
    if (newSelected.has(employeeId)) {
      newSelected.delete(employeeId);
    } else {
      newSelected.add(employeeId);
    }
    setSelectedEmployeeIds(newSelected);
  };

  const handleAssign = async () => {
    setAttemptedSubmit(true);
    
    // Validate employee selection
    if (selectedEmployeeIds.size === 0) {
      setError('Please select at least one employee');
      return;
    }

    // Validate dates - MANDATORY
    if (!startDate || !endDate) {
      setDateError('Both Start Date and End Date are required');
      setError('Please fill in the assignment period before assigning employees');
      return;
    }

    // Validate end date is after start date
    if (new Date(endDate) < new Date(startDate)) {
      setDateError('End Date must be after Start Date');
      setError('Invalid date range');
      return;
    }

    try {
      setAssigning(true);
      setError('');
      setSuccessMessage('');
      setDateError('');

      const response = await projectsAPI.assignEmployees(
        projectId,
        Array.from(selectedEmployeeIds),
        {
          start_date: startDate,
          end_date: endDate,
        }
      );

      // Show confirmation with dates
      const startFormatted = new Date(startDate).toLocaleDateString();
      const endFormatted = new Date(endDate).toLocaleDateString();
      const employeeCount = selectedEmployeeIds.size;
      const employeeText = employeeCount === 1 ? 'employee' : 'employees';
      
      setSuccessMessage(
        `✅ ${employeeCount} ${employeeText} assigned from ${startFormatted} to ${endFormatted}`
      );
      setSelectedEmployeeIds(new Set());
      setStartDate('');
      setEndDate('');
      setAttemptedSubmit(false);
      
      // Refresh the list
      await fetchEmployees();
      
      // Notify parent component
      setTimeout(() => {
        onAssignSuccess();
        handleClose();
      }, 2000);
    } catch (err: any) {
      console.error('Error assigning employees:', err);
      setError(err.response?.data?.message || 'Failed to assign employees');
    } finally {
      setAssigning(false);
    }
  };

  const handleClose = () => {
    setSelectedEmployeeIds(new Set());
    setSearchQuery('');
    setCurrentPage(1);
    setStartDate('');
    setEndDate('');
    setError('');
    setSuccessMessage('');
    setDateError('');
    setAttemptedSubmit(false);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
              <Users className="h-6 w-6 text-primary-600" />
              Assign Employees
            </h2>
            <p className="text-sm text-gray-600 mt-1">
              Project: <span className="font-semibold">{projectName}</span>
            </p>
          </div>
          <button
            onClick={handleClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X className="h-6 w-6" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6">
          {/* Assignment Date Range - REQUIRED */}
          <div className={`mb-6 rounded-lg p-4 border-2 ${
            attemptedSubmit && (!startDate || !endDate)
              ? 'bg-red-50 border-red-300'
              : 'bg-blue-50 border-blue-200'
          }`}>
            <div className="flex items-center gap-2 mb-3">
              <h4 className="text-sm font-semibold text-gray-900">
                📅 Assignment Period
              </h4>
              <span className="px-2 py-0.5 bg-red-100 text-red-700 text-xs font-semibold rounded">
                Required
              </span>
            </div>
            
            {dateError && (
              <div className="mb-3 bg-red-100 border border-red-300 text-red-700 px-3 py-2 rounded text-sm flex items-start gap-2">
                <AlertCircle className="h-4 w-4 flex-shrink-0 mt-0.5" />
                <span>{dateError}</span>
              </div>
            )}
            
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-900 mb-1">
                  Start Date <span className="text-red-600">*</span>
                </label>
                <input
                  type="date"
                  value={startDate}
                  onChange={(e) => {
                    setStartDate(e.target.value);
                    setDateError('');
                    setError('');
                  }}
                  className={`w-full px-3 py-2 border-2 rounded-lg focus:ring-2 focus:ring-primary-500 transition-colors ${
                    attemptedSubmit && !startDate
                      ? 'border-red-500 bg-red-50'
                      : 'border-gray-300 focus:border-primary-500'
                  }`}
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-900 mb-1">
                  End Date <span className="text-red-600">*</span>
                </label>
                <input
                  type="date"
                  value={endDate}
                  onChange={(e) => {
                    setEndDate(e.target.value);
                    setDateError('');
                    setError('');
                  }}
                  min={startDate || undefined}
                  className={`w-full px-3 py-2 border-2 rounded-lg focus:ring-2 focus:ring-primary-500 transition-colors ${
                    attemptedSubmit && !endDate
                      ? 'border-red-500 bg-red-50'
                      : 'border-gray-300 focus:border-primary-500'
                  }`}
                  required
                />
              </div>
            </div>
            
            {startDate && endDate && (
              <div className="mt-3 bg-white border border-blue-200 rounded px-3 py-2">
                <p className="text-sm font-medium text-blue-900">
                  ⏱️ Duration: {new Date(startDate).toLocaleDateString()} - {new Date(endDate).toLocaleDateString()}
                </p>
              </div>
            )}
            
            {(!startDate || !endDate) && (
              <p className="mt-2 text-xs text-gray-600 italic">
                Please select both start and end dates to proceed with assignment
              </p>
            )}
          </div>

          {/* Search */}
          <div className="mb-6">
            <div className="flex gap-2">
              <div className="flex-1 relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      handleSearch();
                    }
                  }}
                  placeholder="Search by name, email, or role..."
                  className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                />
              </div>
              <button
                onClick={handleSearch}
                className="px-4 py-2.5 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors whitespace-nowrap"
              >
                Search
              </button>
            </div>
          </div>

          {/* Messages */}
          {error && (
            <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg flex items-start gap-2">
              <AlertCircle className="h-5 w-5 flex-shrink-0 mt-0.5" />
              <span>{error}</span>
            </div>
          )}

          {successMessage && (
            <div className="mb-4 bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg flex items-start gap-2">
              <CheckCircle2 className="h-5 w-5 flex-shrink-0 mt-0.5" />
              <span>{successMessage}</span>
            </div>
          )}

          {/* Selected Count */}
          {selectedEmployeeIds.size > 0 && (
            <div className="mb-4 bg-primary-50 border border-primary-200 text-primary-700 px-4 py-3 rounded-lg">
              <span className="font-semibold">{selectedEmployeeIds.size}</span> employee(s) selected
            </div>
          )}

          {/* Employee List */}
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="text-gray-500">Loading employees...</div>
            </div>
          ) : employees.length === 0 ? (
            <div className="text-center py-12">
              <Users className="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <p className="text-gray-500">
                {searchQuery ? 'No employees found matching your search' : 'No employees available'}
              </p>
            </div>
          ) : (
            <div className="space-y-2">
              {employees.map((employee) => {
                const isSelected = selectedEmployeeIds.has(employee.id);
                const isAssignedElsewhere = employee.is_assigned && !employee.is_assigned_to_current_project;
                const isAssignedHere = employee.is_assigned_to_current_project;

                return (
                  <div
                    key={employee.id}
                    className={`border rounded-lg p-4 transition-all ${
                      isAssignedHere
                        ? 'bg-gray-50 border-gray-200 opacity-60'
                        : isSelected
                        ? 'bg-primary-50 border-primary-300'
                        : isAssignedElsewhere
                        ? 'bg-yellow-50 border-yellow-200'
                        : 'bg-white border-gray-200 hover:border-primary-300'
                    }`}
                  >
                    <div className="flex items-start gap-3">
                      {/* Checkbox */}
                      <input
                        type="checkbox"
                        checked={isSelected}
                        onChange={() => handleToggleEmployee(employee.id, isAssignedElsewhere || isAssignedHere)}
                        disabled={isAssignedElsewhere || isAssignedHere}
                        className={`mt-1 h-5 w-5 rounded border-gray-300 text-primary-600 focus:ring-primary-500 ${
                          (isAssignedElsewhere || isAssignedHere) ? 'cursor-not-allowed opacity-50' : 'cursor-pointer'
                        }`}
                      />

                      {/* Employee Info */}
                      <div className="flex-1">
                        <div className="flex items-start justify-between">
                          <div>
                            <h4 className="font-semibold text-gray-900">{employee.name}</h4>
                            {employee.email && (
                              <p className="text-sm text-gray-600">{employee.email}</p>
                            )}
                            {employee.role && (
                              <span className="inline-block mt-1 px-2 py-1 text-xs font-medium bg-gray-100 text-gray-700 rounded">
                                {employee.role}
                              </span>
                            )}
                          </div>

                          {/* Status Badges */}
                          <div className="flex flex-col gap-1 items-end">
                            {isAssignedHere && (
                              <span className="px-3 py-1 text-xs font-semibold bg-gray-200 text-gray-700 rounded-full whitespace-nowrap">
                                Already Assigned Here
                              </span>
                            )}
                            {isAssignedElsewhere && (
                              <span className="px-3 py-1 text-xs font-semibold bg-yellow-200 text-yellow-800 rounded-full whitespace-nowrap">
                                Assigned to: {employee.assigned_project_name}
                              </span>
                            )}
                            {!employee.is_assigned && (
                              <span className="px-3 py-1 text-xs font-semibold bg-green-100 text-green-700 rounded-full whitespace-nowrap">
                                Available
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between mt-6 pt-6 border-t border-gray-200">
              <button
                onClick={() => setCurrentPage((prev) => Math.max(1, prev - 1))}
                disabled={currentPage === 1}
                className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                Previous
              </button>
              <span className="text-sm text-gray-600">
                Page {currentPage} of {totalPages}
              </span>
              <button
                onClick={() => setCurrentPage((prev) => Math.min(totalPages, prev + 1))}
                disabled={currentPage === totalPages}
                className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                Next
              </button>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end gap-3 p-6 border-t border-gray-200">
          <button
            onClick={handleClose}
            className="px-6 py-2.5 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors"
            disabled={assigning}
          >
            Cancel
          </button>
          <button
            onClick={handleAssign}
            disabled={assigning || selectedEmployeeIds.size === 0 || !startDate || !endDate}
            className="px-6 py-2.5 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
            title={
              !startDate || !endDate
                ? 'Please select assignment dates first'
                : selectedEmployeeIds.size === 0
                ? 'Please select at least one employee'
                : 'Assign selected employees'
            }
          >
            {assigning ? (
              <>
                <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent" />
                Assigning...
              </>
            ) : (
              <>Assign Selected ({selectedEmployeeIds.size})</>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}

