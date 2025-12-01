'use client';

import { Employee } from '@/lib/api';
import { Mail, Phone } from 'lucide-react';

interface WorkerCardProps {
  worker: Employee;
  onClick?: () => void;
}

export default function WorkerCard({ worker, onClick }: WorkerCardProps) {
  // Determine role tag
  const roleTag = worker.role?.toLowerCase().includes('supervisor') 
    ? 'supervisor' 
    : 'staff';

  return (
    <div
      onClick={onClick}
      className="bg-white rounded-lg border border-gray-200 p-5 hover:border-primary-300 hover:shadow-md transition-all cursor-pointer"
    >
      <div className="flex items-start justify-between mb-3">
        <h3 className="text-lg font-semibold text-gray-900">{worker.name}</h3>
        <span
          className={`px-2 py-1 text-xs font-medium rounded-full ${
            roleTag === 'supervisor'
              ? 'bg-blue-100 text-blue-800'
              : 'bg-green-100 text-green-800'
          }`}
        >
          {roleTag}
        </span>
      </div>
      {worker.role && (
        <div className="mb-2">
          <span className="text-xs font-medium text-primary-600 bg-primary-50 px-2 py-1 rounded">
            {worker.role}
          </span>
        </div>
      )}
      <div className="space-y-2">
        {worker.email && (
          <div className="flex items-center space-x-2 text-sm text-gray-600">
            <Mail className="h-4 w-4 text-gray-400" />
            <span>{worker.email}</span>
          </div>
        )}
        {worker.phone && (
          <div className="flex items-center space-x-2 text-sm text-gray-600">
            <Phone className="h-4 w-4 text-gray-400" />
            <span>{worker.phone}</span>
          </div>
        )}
      </div>
    </div>
  );
}

