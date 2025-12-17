'use client';

import { Employee, AttendanceRecord } from '@/lib/api';
import { ArrowRight, CheckCircle2 } from 'lucide-react';

interface RecentCheckOutsProps {
  workers: Employee[];
  attendanceRecords: AttendanceRecord[];
}

export default function RecentCheckOuts({ workers, attendanceRecords }: RecentCheckOutsProps) {
  const today = new Date().toISOString().split('T')[0];

  // Get today's check-outs
  const todayCheckOuts = attendanceRecords
    .filter((record) => {
      if (!record.check_out_time) return false;
      const recordDate = new Date(record.check_out_time).toISOString().split('T')[0];
      return recordDate === today;
    })
    .map((record) => {
      // Match by email since user_id references users.id, not employees.id
      const worker = workers.find((w) => 
        w.email && record.user_email?.toLowerCase() === w.email.toLowerCase()
      );
      if (!worker || !record.check_out_time) return null;

      const checkOutTime = new Date(record.check_out_time);

      return {
        worker,
        checkOutTime,
        record,
      };
    })
    .filter((item): item is NonNullable<typeof item> => item !== null)
    .sort((a, b) => b.checkOutTime.getTime() - a.checkOutTime.getTime())
    .slice(0, 10);

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
      <div className="flex items-center space-x-2 mb-4">
        <ArrowRight className="h-5 w-5 text-gray-600" />
        <h3 className="text-lg font-semibold text-gray-800">
          Recent Check-outs Today
        </h3>
      </div>
      <div className="space-y-3">
        {todayCheckOuts.length === 0 ? (
          <p className="text-sm text-gray-500 text-center py-4">
            No check-outs today
          </p>
        ) : (
          todayCheckOuts.map((item) => {
            const hours = item.checkOutTime.getHours();
            const minutes = item.checkOutTime.getMinutes();
            const ampm = hours >= 12 ? 'PM' : 'AM';
            const displayHours = hours % 12 || 12;
            const timeString = `${displayHours}:${String(minutes).padStart(2, '0')} ${ampm}`;

            return (
              <div
                key={item.record.id}
                className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
              >
                <div className="flex items-center space-x-3">
                  <CheckCircle2 className="h-5 w-5 text-blue-600" />
                  <div>
                    <p className="font-medium text-gray-900">
                      {item.worker.name}
                    </p>
                    <p className="text-sm text-gray-600">{timeString}</p>
                  </div>
                </div>
                <span className="px-2 py-1 text-xs font-medium bg-blue-100 text-blue-800 rounded-full">
                  Checked Out
                </span>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}

