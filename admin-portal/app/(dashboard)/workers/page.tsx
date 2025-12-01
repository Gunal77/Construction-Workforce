'use client';

import { useState, useEffect, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { employeesAPI, Employee } from '@/lib/api';
import Modal from '@/components/Modal';
import Input from '@/components/Input';
import WorkerCard from '@/components/WorkerCard';
import { Plus, Search, Trash2 } from 'lucide-react';

const ITEMS_PER_PAGE = 9;

export default function WorkersPage() {
  const router = useRouter();
  const [workers, setWorkers] = useState<Employee[]>([]);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [selectedWorker, setSelectedWorker] = useState<Employee | null>(null);
  const [error, setError] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState('name-asc');

  // Form state
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    role: '',
  });

  useEffect(() => {
    fetchWorkers();
  }, []);

  const fetchWorkers = async () => {
    try {
      setLoading(true);
      const response = await employeesAPI.getAll();
      setWorkers(response.employees || []);
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to fetch staffs');
    } finally {
      setLoading(false);
    }
  };

  const handleAddWorker = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    try {
      await employeesAPI.create(formData);
      setIsAddModalOpen(false);
      setFormData({ name: '', email: '', phone: '', role: '' });
      fetchWorkers();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to create staff');
    }
  };

  const handleDeleteWorker = async () => {
    if (!selectedWorker) return;

    try {
      await employeesAPI.delete(selectedWorker.id);
      setIsDeleteModalOpen(false);
      setSelectedWorker(null);
      fetchWorkers();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to delete staff');
    }
  };

  const handleViewWorker = (worker: Employee) => {
    router.push(`/workers/${worker.id}`);
  };

  // Filter and sort workers
  const filteredAndSortedWorkers = useMemo(() => {
    let filtered = workers;

    // Apply search filter
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(
        (worker) =>
          worker.name?.toLowerCase().includes(query) ||
          worker.email?.toLowerCase().includes(query) ||
          worker.phone?.toLowerCase().includes(query)
      );
    }

    // Apply sorting
    const sorted = [...filtered].sort((a, b) => {
      if (sortBy === 'name-asc') {
        return (a.name || '').localeCompare(b.name || '');
      } else if (sortBy === 'name-desc') {
        return (b.name || '').localeCompare(a.name || '');
      }
      return 0;
    });

    return sorted;
  }, [workers, searchQuery, sortBy]);

  // Paginate
  const paginatedWorkers = filteredAndSortedWorkers.slice(
    (currentPage - 1) * ITEMS_PER_PAGE,
    currentPage * ITEMS_PER_PAGE
  );

  const totalPages = Math.ceil(filteredAndSortedWorkers.length / ITEMS_PER_PAGE);
  const startIndex = (currentPage - 1) * ITEMS_PER_PAGE + 1;
  const endIndex = Math.min(currentPage * ITEMS_PER_PAGE, filteredAndSortedWorkers.length);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading workers...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-800">Staffs</h1>
          <p className="text-gray-600 mt-1">Manage construction staff</p>
        </div>
        <button
          onClick={() => setIsAddModalOpen(true)}
          className="flex items-center space-x-2 bg-primary-600 text-white px-4 py-2 rounded-lg hover:bg-primary-700 transition-colors"
        >
          <Plus className="h-5 w-5" />
          <span>Add Staff</span>
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Search and Filter Bar */}
      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center">
        <div className="flex-1 w-full">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value);
                setCurrentPage(1); // Reset to first page on search
              }}
              placeholder="Search by name, email, or phone..."
              className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-colors"
            />
          </div>
        </div>
        <div className="w-full sm:w-auto min-w-[150px]">
          <select
            value={sortBy}
            onChange={(e) => {
              setSortBy(e.target.value);
              setCurrentPage(1); // Reset to first page on sort
            }}
            className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-colors"
          >
            <option value="name-asc">Name (A-Z)</option>
            <option value="name-desc">Name (Z-A)</option>
          </select>
        </div>
      </div>

      {/* Pagination Info */}
      {filteredAndSortedWorkers.length > 0 && (
        <p className="text-sm text-gray-600">
          Showing {startIndex} - {endIndex} of {filteredAndSortedWorkers.length} staffs
        </p>
      )}

      {/* Workers Grid */}
      {loading ? (
        <div className="flex items-center justify-center h-64">
          <div className="text-gray-500">Loading staffs...</div>
        </div>
      ) : paginatedWorkers.length === 0 ? (
        <div className="bg-white rounded-lg border border-gray-200 p-12 text-center">
          <p className="text-gray-500">No staffs found</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {paginatedWorkers.map((worker) => (
            <WorkerCard
              key={worker.id}
              worker={worker}
              onClick={() => handleViewWorker(worker)}
            />
          ))}
        </div>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-center space-x-2">
          <button
            onClick={() => setCurrentPage((prev) => Math.max(1, prev - 1))}
            disabled={currentPage === 1}
            className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Previous
          </button>
          <span className="px-4 py-2 text-sm text-gray-600">
            Page {currentPage} of {totalPages}
          </span>
          <button
            onClick={() => setCurrentPage((prev) => Math.min(totalPages, prev + 1))}
            disabled={currentPage === totalPages}
            className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Next
          </button>
        </div>
      )}

      {/* Add Worker Modal */}
      <Modal
        isOpen={isAddModalOpen}
        onClose={() => {
          setIsAddModalOpen(false);
          setFormData({ name: '', email: '', phone: '', role: '' });
          setError('');
        }}
        title="Add Staff"
      >
        <form onSubmit={handleAddWorker} className="space-y-4">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded text-sm">
              {error}
            </div>
          )}

          <Input
            label="Name"
            type="text"
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            required
            placeholder="Enter staff name"
          />

          <Input
            label="Email"
            type="email"
            value={formData.email}
            onChange={(e) => setFormData({ ...formData, email: e.target.value })}
            placeholder="Enter email address"
          />

          <Input
            label="Phone"
            type="tel"
            value={formData.phone}
            onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
            placeholder="Enter phone number"
          />

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Role *
            </label>
            <select
              value={formData.role}
              onChange={(e) => setFormData({ ...formData, role: e.target.value })}
              required
              className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-colors"
            >
              <option value="">Select Role</option>
              <optgroup label="Senior Resident Engineer (SRE)">
                <option value="SRE(C&S)">SRE - Civil & Structural</option>
                <option value="SRE(M&E)">SRE - Mechanical & Electrical</option>
                <option value="SRE(C&S/M&E)">SRE - Civil & Structural / Mechanical & Electrical</option>
              </optgroup>
              <optgroup label="Resident Engineer (RE)">
                <option value="RE(C&S)">RE - Civil & Structural</option>
                <option value="RE(M&E)">RE - Mechanical & Electrical</option>
                <option value="RE(C&S/M&E)">RE - Civil & Structural / Mechanical & Electrical</option>
              </optgroup>
              <optgroup label="Resident Technical Officer (RTO)">
                <option value="RTO(C&S)">RTO - Civil & Structural</option>
                <option value="RTO(M&E)">RTO - Mechanical & Electrical</option>
                <option value="RTO(Archi)">RTO - Architectural</option>
              </optgroup>
              <optgroup label="Stand-in RTO">
                <option value="Stand-in RTO(C&S)">Stand-in RTO - Civil & Structural</option>
                <option value="Stand-in RTO(M&E)">Stand-in RTO - Mechanical & Electrical</option>
                <option value="Stand-in RTO(Archi)">Stand-in RTO - Architectural</option>
              </optgroup>
              <optgroup label="Other">
                <option value="RA">Resident Architect (RA)</option>
                <option value="Other">Other</option>
              </optgroup>
            </select>
          </div>

          <div className="flex justify-end space-x-3 pt-4">
            <button
              type="button"
              onClick={() => {
                setIsAddModalOpen(false);
                setFormData({ name: '', email: '', phone: '', role: '' });
                setError('');
              }}
              className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors"
            >
              Add Staff
            </button>
          </div>
        </form>
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={isDeleteModalOpen}
        onClose={() => {
          setIsDeleteModalOpen(false);
          setSelectedWorker(null);
        }}
        title="Delete Staff"
        size="sm"
      >
        <div className="space-y-4">
          <p className="text-gray-700">
            Are you sure you want to delete{' '}
            <span className="font-semibold">{selectedWorker?.name}</span>? This
            action cannot be undone.
          </p>
          <div className="flex justify-end space-x-3 pt-4">
            <button
              type="button"
              onClick={() => {
                setIsDeleteModalOpen(false);
                setSelectedWorker(null);
              }}
              className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={handleDeleteWorker}
              className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
            >
              Delete
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
