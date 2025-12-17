'use client';

import { Employee, AttendanceRecord } from '@/lib/api';
import { Clock, CheckCircle2 } from 'lucide-react';

interface RecentCheckInsProps {
  workers: Employee[];
  attendanceRecords: AttendanceRecord[];
}

export default function RecentCheckIns({ workers, attendanceRecords }: RecentCheckInsProps) {
  const today = new Date().toISOString().split('T')[0];
  const expectedCheckInHour = 7;
  const expectedCheckInMinute = 0;

  // Get today's check-ins
  const todayCheckIns = attendanceRecords
    .filter((record) => {
      const recordDate = new Date(record.check_in_time).toISOString().split('T')[0];
      return recordDate === today;
    })
    .map((record) => {
      // Match by email since user_id references users.id, not employees.id
      const worker = workers.find((w) => 
        w.email && record.user_email?.toLowerCase() === w.email.toLowerCase()
      );
      if (!worker) return null;

      const checkInTime = new Date(record.check_in_time);
      const expectedTime = new Date(checkInTime);
      expectedTime.setHours(expectedCheckInHour, expectedCheckInMinute, 0, 0);
      expectedTime.setDate(checkInTime.getDate());

      const isLate = checkInTime > expectedTime;

      return {
        worker,
        checkInTime,
        isLate,
        record,
      };
    })
    .filter((item): item is NonNullable<typeof item> => item !== null)
    .sort((a, b) => b.checkInTime.getTime() - a.checkInTime.getTime())
    .slice(0, 10);

  const lateCount = todayCheckIns.filter((item) => item.isLate).length;

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-2">
          <Clock className="h-5 w-5 text-gray-600" />
          <h3 className="text-lg font-semibold text-gray-800">
            Recent Check-ins Today
          </h3>
        </div>
        {lateCount > 0 && (
          <span className="px-2 py-1 text-xs font-medium bg-orange-100 text-orange-800 rounded-full">
            {lateCount} Late
          </span>
        )}
      </div>
      <div className="space-y-3">
        {todayCheckIns.length === 0 ? (
          <p className="text-sm text-gray-500 text-center py-4">
            No check-ins today
          </p>
        ) : (
          todayCheckIns.map((item) => {
            const hours = item.checkInTime.getHours();
            const minutes = item.checkInTime.getMinutes();
            const ampm = hours >= 12 ? 'PM' : 'AM';
            const displayHours = hours % 12 || 12;
            const timeString = `${displayHours}:${String(minutes).padStart(2, '0')} ${ampm}`;

            return (
              <div
                key={item.record.id}
                className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
              >
                <div className="flex items-center space-x-3">
                  <CheckCircle2
                    className={`h-5 w-5 ${
                      item.isLate ? 'text-orange-600' : 'text-green-600'
                    }`}
                  />
                  <div>
                    <p className="font-medium text-gray-900">
                      {item.worker.name}
                    </p>
                    <p className="text-sm text-gray-600">{timeString}</p>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  {item.isLate && (
                    <span className="px-2 py-1 text-xs font-medium bg-orange-100 text-orange-800 rounded-full">
                      LATE
                    </span>
                  )}
                  <span
                    className={`px-2 py-1 text-xs font-medium rounded-full ${
                      item.isLate
                        ? 'bg-orange-100 text-orange-800'
                        : 'bg-green-100 text-green-800'
                    }`}
                  >
                    {item.isLate ? 'Late Check-in' : 'Checked In'}
                  </span>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}

