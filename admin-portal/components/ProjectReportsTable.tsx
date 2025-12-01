'use client';

import Table from './Table';

interface ProjectReport {
  id: string;
  name: string;
  startDate?: string;
  status: string;
  workers: number;
  totalHours: number;
  budget: number | null;
  spent: number | null;
  completion: number | null;
}

interface ProjectReportsTableProps {
  data: ProjectReport[];
}

// Format currency in millions
function formatCurrency(value: number): string {
  if (value >= 1000000) {
    return `$${(value / 1000000).toFixed(1)}M`;
  } else if (value >= 1000) {
    return `$${(value / 1000).toFixed(1)}K`;
  }
  return `$${value.toLocaleString()}`;
}

// Format date
function formatDate(dateString: string | undefined): string {
  if (!dateString) return '';
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', { 
    month: 'short', 
    day: 'numeric', 
    year: 'numeric' 
  });
}

export default function ProjectReportsTable({ data }: ProjectReportsTableProps) {
  const columns = [
    {
      key: 'name',
      header: 'Project Name',
      render: (item: ProjectReport) => (
        <div>
          <span className="font-medium text-gray-900">{item.name}</span>
          {item.startDate && (
            <p className="text-xs text-gray-500 mt-0.5">
              Started {formatDate(item.startDate)}
            </p>
          )}
        </div>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (item: ProjectReport) => {
        let bgColor = 'bg-blue-100';
        let textColor = 'text-blue-800';
        
        if (item.status === 'COMPLETED') {
          bgColor = 'bg-green-100';
          textColor = 'text-green-800';
        } else if (item.status === 'ON HOLD') {
          bgColor = 'bg-orange-100';
          textColor = 'text-orange-800';
        }
        
        return (
          <span
            className={`px-3 py-1 text-xs font-semibold rounded-full ${bgColor} ${textColor}`}
          >
            {item.status}
          </span>
        );
      },
    },
    {
      key: 'workers',
      header: 'Staffs',
      render: (item: ProjectReport) => (
        <span className="text-gray-900">{item.workers}</span>
      ),
    },
    {
      key: 'totalHours',
      header: 'Total Hours',
      render: (item: ProjectReport) => (
        <span className="text-gray-900">{item.totalHours.toLocaleString()}</span>
      ),
    },
    {
      key: 'budget',
      header: 'Budget',
      render: (item: ProjectReport) => (
        <span className="text-gray-900">
          {item.budget ? formatCurrency(item.budget) : 'N/A'}
        </span>
      ),
    },
    {
      key: 'spent',
      header: 'Spent',
      render: (item: ProjectReport) => (
        <span className="text-gray-900">
          {item.spent ? formatCurrency(item.spent) : 'N/A'}
        </span>
      ),
    },
    {
      key: 'completion',
      header: 'Completion',
      render: (item: ProjectReport) => {
        if (item.completion === null) return <span className="text-gray-400">N/A</span>;
        return (
          <div className="flex items-center space-x-3">
            <div className="flex-1 bg-gray-200 rounded-full h-2 min-w-[100px]">
              <div
                className="bg-primary-600 h-2 rounded-full transition-all"
                style={{ width: `${item.completion}%` }}
              />
            </div>
            <span className="text-sm font-medium text-gray-900 min-w-[40px]">
              {item.completion}%
            </span>
          </div>
        );
      },
    },
  ];

  return (
    <Table
      columns={columns}
      data={data}
      keyExtractor={(item) => item.id}
      emptyMessage="No project reports available"
    />
  );
}
