'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { UserCog, Search, Eye } from 'lucide-react';

interface Supervisor {
  id: string;
  name: string;
  email: string;
  phone?: string;
  created_at: string;
  is_active: boolean;
  project_count: number;
}

export default function SupervisorsPage() {
  const router = useRouter();
  const [supervisors, setSupervisors] = useState<Supervisor[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [searchInput, setSearchInput] = useState('');

  useEffect(() => {
    fetchSupervisors();
  }, []);

  const fetchSupervisors = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await fetch('/api/proxy/supervisors', {
        credentials: 'include',
      });

      if (!response.ok) {
        throw new Error('Failed to fetch supervisors');
      }

      const data = await response.json();
      setSupervisors(data.supervisors || []);
    } catch (err: any) {
      console.error('Error fetching supervisors:', err);
      setError(err.message || 'Failed to load supervisors');
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = () => {
    setSearchQuery(searchInput);
  };

  const handleClearSearch = () => {
    setSearchInput('');
    setSearchQuery('');
  };

  const filteredSupervisors = supervisors.filter((supervisor) => {
    if (!searchQuery) return true;
    const query = searchQuery.toLowerCase();
    return (
      supervisor.name?.toLowerCase().includes(query) ||
      supervisor.email?.toLowerCase().includes(query) ||
      supervisor.phone?.toLowerCase().includes(query)
    );
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading supervisors...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Supervisors</h1>
          <p className="text-gray-600 mt-1">Manage and view supervisor details</p>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Search */}
      <div className="bg-white rounded-lg border border-gray-200 p-4">
        <div className="flex gap-2">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  handleSearch();
                }
              }}
              placeholder="Search supervisors by name, email, or phone..."
              className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            />
          </div>
          <button
            onClick={handleSearch}
            className="px-4 py-2.5 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors flex items-center gap-2 whitespace-nowrap"
          >
            <Search className="h-5 w-5" />
            <span>Search</span>
          </button>
          {searchQuery && (
            <button
              onClick={handleClearSearch}
              className="px-4 py-2.5 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors flex items-center gap-2 whitespace-nowrap"
            >
              <span>Clear</span>
            </button>
          )}
        </div>
      </div>

      {/* Supervisors Grid */}
      {filteredSupervisors.length === 0 ? (
        <div className="bg-white rounded-lg border border-gray-200 p-12 text-center">
          <UserCog className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <p className="text-gray-500">
            {searchQuery ? 'No supervisors found matching your search' : 'No supervisors found'}
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredSupervisors.map((supervisor) => (
            <div
              key={supervisor.id}
              className="bg-white rounded-lg border border-gray-200 p-6 hover:border-primary-300 hover:shadow-md transition-all"
            >
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="h-12 w-12 rounded-full bg-primary-100 flex items-center justify-center">
                    <UserCog className="h-6 w-6 text-primary-600" />
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900">{supervisor.name}</h3>
                    <p className="text-sm text-gray-500">{supervisor.email}</p>
                  </div>
                </div>
                <Link
                  href={`/supervisors/${supervisor.id}`}
                  className="p-2 text-gray-600 hover:text-primary-600 hover:bg-primary-50 rounded-lg transition-colors"
                  title="View Details"
                >
                  <Eye className="h-5 w-5" />
                </Link>
              </div>

              <div className="space-y-2">
                {supervisor.phone && (
                  <div className="flex items-center gap-2 text-sm text-gray-600">
                    <span>📞</span>
                    <span>{supervisor.phone}</span>
                  </div>
                )}
                <div className="flex items-center gap-2 text-sm">
                  <span className="text-gray-600">Projects:</span>
                  <span className="font-semibold text-primary-600">{supervisor.project_count}</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-500">
                  <span>Joined:</span>
                  <span>{new Date(supervisor.created_at).toLocaleDateString()}</span>
                </div>
                <div className="pt-2">
                  <span
                    className={`px-2 py-1 text-xs font-semibold rounded-full ${
                      supervisor.is_active
                        ? 'bg-green-100 text-green-800'
                        : 'bg-gray-100 text-gray-800'
                    }`}
                  >
                    {supervisor.is_active ? 'Active' : 'Inactive'}
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Count */}
      {filteredSupervisors.length > 0 && (
        <p className="text-sm text-gray-600 text-center">
          Showing {filteredSupervisors.length} of {supervisors.length} supervisors
        </p>
      )}
    </div>
  );
}

