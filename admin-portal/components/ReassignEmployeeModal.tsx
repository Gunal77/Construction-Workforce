'use client';

import { useState, useEffect } from 'react';
import { X, User, Calendar, Building2, AlertCircle, CheckCircle2, Loader2 } from 'lucide-react';
import { projectsAPI, ProjectEmployee, Project } from '@/lib/api';

interface ReassignEmployeeModalProps {
  isOpen: boolean;
  onClose: () => void;
  employee: ProjectEmployee | null;
  currentProjectId: string;
  currentProjectName: string;
  onReassignSuccess: () => void;
}

export default function ReassignEmployeeModal({
  isOpen,
  onClose,
  employee,
  currentProjectId,
  currentProjectName,
  onReassignSuccess,
}: ReassignEmployeeModalProps) {
  const [projects, setProjects] = useState<Project[]>([]);
  const [selectedProjectId, setSelectedProjectId] = useState('');
  const [newStartDate, setNewStartDate] = useState('');
  const [loading, setLoading] = useState(false);
  const [reassigning, setReassigning] = useState(false);
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');

  // Fetch all projects on open
  useEffect(() => {
    if (isOpen && employee) {
      fetchProjects();
      // Set default start date to tomorrow
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      setNewStartDate(tomorrow.toISOString().split('T')[0]);
    }
  }, [isOpen, employee]);

  const fetchProjects = async () => {
    try {
      setLoading(true);
      const response = await projectsAPI.getAll();
      // Filter out current project and get projects array
      const allProjects = response.projects || response || [];
      const filteredProjects = allProjects.filter(
        (p: Project) => p.id !== currentProjectId
      );
      setProjects(filteredProjects);
    } catch (err: any) {
      console.error('Error fetching projects:', err);
      setError('Failed to load projects');
    } finally {
      setLoading(false);
    }
  };

  const handleReassign = async () => {
    if (!employee || !selectedProjectId || !newStartDate) {
      setError('Please select a project and start date');
      return;
    }

    if (selectedProjectId === currentProjectId) {
      setError('Cannot reassign to the same project');
      return;
    }

    // Validate start date is not in the past
    const startDate = new Date(newStartDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    if (startDate < today) {
      setError('Start date cannot be in the past');
      return;
    }

    try {
      setReassigning(true);
      setError('');
      setSuccessMessage('');

      // Call reassignment API
      await projectsAPI.reassignEmployee(
        currentProjectId,
        employee.employee_id,
        selectedProjectId,
        newStartDate
      );

      const selectedProject = projects.find(p => p.id === selectedProjectId);
      const projectName = selectedProject?.name || 'the new project';
      
      setSuccessMessage(
        `✅ Employee reassigned successfully! They will start on ${new Date(newStartDate).toLocaleDateString()} in ${projectName}.`
      );

      // Notify parent and close after delay
      setTimeout(() => {
        onReassignSuccess();
        handleClose();
      }, 2000);
    } catch (err: any) {
      console.error('Error reassigning employee:', err);
      setError(err.response?.data?.message || 'Failed to reassign employee');
    } finally {
      setReassigning(false);
    }
  };

  const handleClose = () => {
    setSelectedProjectId('');
    setNewStartDate('');
    setError('');
    setSuccessMessage('');
    onClose();
  };

  if (!isOpen || !employee) return null;

  // Calculate end date for current assignment (one day before new start date)
  const currentEndDate = newStartDate
    ? (() => {
        const endDate = new Date(newStartDate);
        endDate.setDate(endDate.getDate() - 1);
        return endDate.toISOString().split('T')[0];
      })()
    : null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
              <User className="h-6 w-6 text-primary-600" />
              Reassign Employee
            </h2>
            <p className="text-sm text-gray-600 mt-1">
              Move employee to a different project
            </p>
          </div>
          <button
            onClick={handleClose}
            disabled={reassigning}
            className="text-gray-400 hover:text-gray-600 transition-colors disabled:opacity-50"
          >
            <X className="h-6 w-6" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6">
          {/* Employee Details (Read-only) */}
          <div className="mb-6 bg-gray-50 border border-gray-200 rounded-lg p-4">
            <h3 className="text-sm font-semibold text-gray-700 mb-3">Employee Details</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">Name</label>
                <p className="text-sm font-medium text-gray-900">{employee.employee_name || 'N/A'}</p>
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">Email</label>
                <p className="text-sm text-gray-700">{employee.employee_email || 'N/A'}</p>
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">Role / Trade</label>
                <p className="text-sm text-gray-700">{employee.employee_role || 'N/A'}</p>
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">Current Project</label>
                <p className="text-sm font-medium text-gray-900">{currentProjectName}</p>
              </div>
              {employee.assignment_start_date && employee.assignment_end_date && (
                <>
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1">Current Assignment Period</label>
                    <p className="text-sm text-gray-700">
                      {new Date(employee.assignment_start_date).toLocaleDateString()} - {new Date(employee.assignment_end_date).toLocaleDateString()}
                    </p>
                  </div>
                </>
              )}
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

          {/* Reassignment Form */}
          <div className="space-y-6">
            {/* Select New Project */}
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-2">
                <Building2 className="inline h-4 w-4 mr-1" />
                Select New Project <span className="text-red-600">*</span>
              </label>
              {loading ? (
                <div className="flex items-center justify-center py-4">
                  <Loader2 className="h-5 w-5 animate-spin text-primary-600" />
                  <span className="ml-2 text-sm text-gray-600">Loading projects...</span>
                </div>
              ) : (
                <select
                  value={selectedProjectId}
                  onChange={(e) => {
                    setSelectedProjectId(e.target.value);
                    setError('');
                  }}
                  className={`w-full px-4 py-2.5 border-2 rounded-lg focus:ring-2 focus:ring-primary-500 transition-colors ${
                    error && !selectedProjectId
                      ? 'border-red-500 bg-red-50'
                      : 'border-gray-300 focus:border-primary-500'
                  }`}
                  required
                >
                  <option value="">-- Select a project --</option>
                  {projects.map((project) => (
                    <option key={project.id} value={project.id}>
                      {project.name} {project.location ? `(${project.location})` : ''}
                    </option>
                  ))}
                </select>
              )}
              {projects.length === 0 && !loading && (
                <p className="mt-2 text-sm text-gray-500 italic">
                  No other projects available for reassignment
                </p>
              )}
            </div>

            {/* New Assignment Start Date */}
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-2">
                <Calendar className="inline h-4 w-4 mr-1" />
                New Assignment Start Date <span className="text-red-600">*</span>
              </label>
              <input
                type="date"
                value={newStartDate}
                onChange={(e) => {
                  setNewStartDate(e.target.value);
                  setError('');
                }}
                min={new Date().toISOString().split('T')[0]}
                className={`w-full px-4 py-2.5 border-2 rounded-lg focus:ring-2 focus:ring-primary-500 transition-colors ${
                  error && !newStartDate
                    ? 'border-red-500 bg-red-50'
                    : 'border-gray-300 focus:border-primary-500'
                }`}
                required
              />
              <p className="mt-2 text-xs text-gray-600">
                Current assignment will end on: <span className="font-semibold">
                  {currentEndDate ? new Date(currentEndDate).toLocaleDateString() : 'N/A'}
                </span>
              </p>
            </div>

            {/* Info Box */}
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
              <h4 className="text-sm font-semibold text-blue-900 mb-2">What happens:</h4>
              <ul className="text-xs text-blue-800 space-y-1 list-disc list-inside">
                <li>Current assignment will end one day before the new start date</li>
                <li>New assignment will begin on the selected start date</li>
                <li>Employee will be automatically moved to the new project</li>
              </ul>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end gap-3 p-6 border-t border-gray-200 bg-gray-50">
          <button
            onClick={handleClose}
            disabled={reassigning}
            className="px-6 py-2.5 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-100 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Cancel
          </button>
          <button
            onClick={handleReassign}
            disabled={reassigning || !selectedProjectId || !newStartDate || selectedProjectId === currentProjectId}
            className="px-6 py-2.5 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
            title={
              selectedProjectId === currentProjectId
                ? 'Cannot reassign to the same project'
                : !selectedProjectId || !newStartDate
                ? 'Please select a project and start date'
                : 'Reassign employee'
            }
          >
            {reassigning ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin" />
                Reassigning...
              </>
            ) : (
              <>
                <User className="h-4 w-4" />
                Reassign Employee
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}

