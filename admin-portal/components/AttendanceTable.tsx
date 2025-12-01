'use client';

import { AttendanceRecord } from '@/lib/api';
import Table from './Table';

interface AttendanceTableProps {
  data: AttendanceRecord[];
}

export default function AttendanceTable({ data }: AttendanceTableProps) {
  const columns = [
    {
      key: 'user_email',
      header: 'Staff',
      render: (item: AttendanceRecord) => (
        <span className="font-medium">{item.user_email || 'N/A'}</span>
      ),
    },
    {
      key: 'check_in_time',
      header: 'Check In',
      render: (item: AttendanceRecord) => {
        const date = new Date(item.check_in_time);
        return date.toLocaleString('en-US', {
          year: 'numeric',
          month: '2-digit',
          day: '2-digit',
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit',
          hour12: true,
        });
      },
    },
    {
      key: 'check_out_time',
      header: 'Check Out',
      render: (item: AttendanceRecord) => {
        if (!item.check_out_time) return 'Not checked out';
        const date = new Date(item.check_out_time);
        return date.toLocaleString('en-US', {
          year: 'numeric',
          month: '2-digit',
          day: '2-digit',
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit',
          hour12: true,
        });
      },
    },
    {
      key: 'status',
      header: 'Status',
      render: (item: AttendanceRecord) => (
        <span
          className={`px-2 py-1 text-xs font-medium rounded-full ${
            item.check_out_time
              ? 'bg-green-100 text-green-800'
              : 'bg-yellow-100 text-yellow-800'
          }`}
        >
          {item.check_out_time ? 'Completed' : 'Active'}
        </span>
      ),
    },
  ];

  return (
    <Table
      columns={columns}
      data={data}
      keyExtractor={(item) => item.id}
      emptyMessage="No recent attendance activity"
    />
  );
}

