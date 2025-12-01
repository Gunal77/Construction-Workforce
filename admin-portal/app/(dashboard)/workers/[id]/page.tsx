'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { employeesAPI, attendanceAPI, projectsAPI, Employee, AttendanceRecord, Project } from '@/lib/api';
import Card from '@/components/Card';
import Table from '@/components/Table';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { ArrowLeft, Mail, Phone, Briefcase, Calendar, MapPin, Clock, CheckCircle, XCircle, RefreshCw } from 'lucide-react';

export default function WorkerDetailsPage() {
  const params = useParams();
  const router = useRouter();
  const workerId = params.id as string;

  const [worker, setWorker] = useState<Employee | null>(null);
  const [attendanceRecords, setAttendanceRecords] = useState<AttendanceRecord[]>([]);
  const [assignedProject, setAssignedProject] = useState<Project | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (workerId) {
      fetchWorkerDetails();
    }
  }, [workerId]);

  // Fetch attendance after worker details are loaded (so we have email)
  useEffect(() => {
    if (worker) {
      fetchAttendanceHistory();
    }
  }, [worker]);

  const fetchWorkerDetails = async () => {
    try {
      setLoading(true);
      setError('');
      
      // Try to fetch by ID first
      try {
        const response = await employeesAPI.getById(workerId);
        if (response.employee) {
          setWorker(response.employee);
          // Fetch project details if project_id exists
          if (response.employee.project_id) {
            try {
              const projectResponse = await projectsAPI.getById(response.employee.project_id);
              if (projectResponse.project) {
                setAssignedProject(projectResponse.project);
              }
            } catch (projectErr) {
              console.error('Error fetching project:', projectErr);
              // If project fetch fails, use the project info from employee if available
              if (response.employee.projects) {
                setAssignedProject(response.employee.projects as any);
              }
            }
          } else if (response.employee.projects) {
            // Use project info from employee object if available
            setAssignedProject(response.employee.projects as any);
          }
          return;
        }
      } catch (idErr) {
        console.log('Fetch by ID failed, trying fetch all:', idErr);
      }
      
      // Fallback: fetch all and filter
      const response = await employeesAPI.getAll();
      const workers = response.employees || [];
      const foundWorker = workers.find((w: Employee) => w.id === workerId);
      
      if (foundWorker) {
        setWorker(foundWorker);
        // Fetch project details if project_id exists
        if (foundWorker.project_id) {
          try {
            const projectResponse = await projectsAPI.getById(foundWorker.project_id);
            if (projectResponse.project) {
              setAssignedProject(projectResponse.project);
            }
          } catch (projectErr) {
            console.error('Error fetching project:', projectErr);
            if (foundWorker.projects) {
              setAssignedProject(foundWorker.projects as any);
            }
          }
        } else if (foundWorker.projects) {
          setAssignedProject(foundWorker.projects as any);
        }
      } else {
        setError('Staff not found');
      }
    } catch (err: any) {
      console.error('Error fetching staff:', err);
      const errorMessage = err.response?.data?.message || err.message || 'Failed to fetch staff details';
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const fetchAttendanceHistory = async () => {
    try {
      setError('');
      let records: AttendanceRecord[] = [];
      
      // IMPORTANT: attendance_logs.user_id references users.id, NOT employees.id
      // So we must filter by email, not by employee ID
      if (worker?.email) {
        try {
          console.log(`Fetching attendance for email: ${worker.email}`);
          // Fetch by email - the backend filters by users.email
          const response = await attendanceAPI.getAll({
            user: worker.email,
            sortBy: 'check_in_time',
            sortOrder: 'desc',
          });
          records = response.records || [];
          console.log(`Backend returned ${records.length} records for email ${worker.email}`);
          
          // Verify the records match the email (backend should already filter, but double-check)
          records = records.filter(
            (record: AttendanceRecord) => 
              record.user_email?.toLowerCase() === worker.email?.toLowerCase()
          );
          console.log(`After email verification: ${records.length} records`);
        } catch (err1) {
          console.error('Error fetching attendance by email:', err1);
          // Fallback: fetch all and filter by email
          try {
            console.log('Trying fallback: fetch all attendance');
            const response = await attendanceAPI.getAll({
              sortBy: 'check_in_time',
              sortOrder: 'desc',
            });
            const allRecords = response.records || [];
            console.log(`Fetched ${allRecords.length} total records`);
            
            // Filter by email (user_email from the joined users table)
            records = allRecords.filter(
              (record: AttendanceRecord) => 
                record.user_email?.toLowerCase() === worker.email?.toLowerCase()
            );
            console.log(`Filtered to ${records.length} records matching email ${worker.email}`);
          } catch (err2) {
            console.error('Error fetching all attendance:', err2);
            throw err2;
          }
        }
      } else {
        console.warn('Worker has no email, cannot fetch attendance records');
        setAttendanceRecords([]);
        return;
      }
      
      console.log(`Final: ${records.length} attendance records for worker ${worker?.name} (${worker?.email})`);
      setAttendanceRecords(records);
    } catch (err: any) {
      console.error('Error fetching attendance:', err);
      const errorMessage = err.response?.data?.message || err.message || 'Failed to fetch attendance records';
      setError(errorMessage);
      setAttendanceRecords([]);
    }
  };

  // Process data for chart (check-ins per month)
  const getChartData = () => {
    const monthlyData: { [key: string]: number } = {};
    
    attendanceRecords.forEach((record) => {
      const date = new Date(record.check_in_time);
      const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
      monthlyData[monthKey] = (monthlyData[monthKey] || 0) + 1;
    });

    return Object.entries(monthlyData)
      .map(([month, count]) => ({
        month: new Date(month + '-01').toLocaleDateString('en-US', {
          month: 'short',
          year: 'numeric',
        }),
        checkIns: count,
      }))
      .sort((a, b) => {
        const dateA = new Date(a.month);
        const dateB = new Date(b.month);
        return dateA.getTime() - dateB.getTime();
      });
  };

  const chartData = getChartData();

  const attendanceColumns = [
    {
      key: 'date',
      header: 'Date',
      render: (item: AttendanceRecord) => (
        <div className="flex items-center space-x-2">
          <Calendar className="h-4 w-4 text-gray-400" />
          <span>{new Date(item.check_in_time).toLocaleDateString()}</span>
        </div>
      ),
    },
    {
      key: 'check_in_time',
      header: 'Check In',
      render: (item: AttendanceRecord) => (
        <div className="flex items-center space-x-2">
          <CheckCircle className="h-4 w-4 text-green-500" />
          <div>
            <p className="font-medium">{new Date(item.check_in_time).toLocaleTimeString()}</p>
            <p className="text-xs text-gray-500">{new Date(item.check_in_time).toLocaleDateString()}</p>
          </div>
        </div>
      ),
    },
    {
      key: 'check_out_time',
      header: 'Check Out',
      render: (item: AttendanceRecord) =>
        item.check_out_time ? (
          <div className="flex items-center space-x-2">
            <XCircle className="h-4 w-4 text-red-500" />
            <div>
              <p className="font-medium">{new Date(item.check_out_time).toLocaleTimeString()}</p>
              <p className="text-xs text-gray-500">{new Date(item.check_out_time).toLocaleDateString()}</p>
            </div>
          </div>
        ) : (
          <span className="text-gray-400 italic">Not checked out</span>
        ),
    },
    {
      key: 'duration',
      header: 'Duration',
      render: (item: AttendanceRecord) => {
        if (!item.check_out_time) return <span className="text-gray-400">-</span>;
        const checkIn = new Date(item.check_in_time);
        const checkOut = new Date(item.check_out_time);
        const diff = checkOut.getTime() - checkIn.getTime();
        const hours = Math.floor(diff / (1000 * 60 * 60));
        const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
        return (
          <div className="flex items-center space-x-1">
            <Clock className="h-4 w-4 text-gray-400" />
            <span className="font-medium">{hours}h {minutes}m</span>
          </div>
        );
      },
    },
    {
      key: 'location',
      header: 'Location',
      render: (item: AttendanceRecord) => {
        if (item.latitude && item.longitude) {
          return (
            <div className="text-xs">
              <p className="text-gray-600">Lat: {item.latitude.toFixed(6)}</p>
              <p className="text-gray-600">Lng: {item.longitude.toFixed(6)}</p>
            </div>
          );
        }
        return <span className="text-gray-400 text-xs">N/A</span>;
      },
    },
    {
      key: 'status',
      header: 'Status',
      render: (item: AttendanceRecord) => (
        <span
          className={`px-2 py-1 text-xs font-medium rounded-full flex items-center space-x-1 w-fit ${
            item.check_out_time
              ? 'bg-green-100 text-green-800'
              : 'bg-yellow-100 text-yellow-800'
          }`}
        >
          {item.check_out_time ? (
            <>
              <CheckCircle className="h-3 w-3" />
              <span>Completed</span>
            </>
          ) : (
            <>
              <Clock className="h-3 w-3" />
              <span>Active</span>
            </>
          )}
        </span>
      ),
    },
  ];

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading staff details...</div>
      </div>
    );
  }

  if (error && !worker) {
    return (
      <div className="space-y-4">
        <button
          onClick={() => router.push('/workers')}
          className="flex items-center space-x-2 text-primary-600 hover:text-primary-700"
        >
          <ArrowLeft className="h-5 w-5" />
          <span>Back to Staffs</span>
        </button>
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error || 'Worker not found'}
        </div>
      </div>
    );
  }

  if (!worker && !loading) {
    return (
      <div className="space-y-4">
        <button
          onClick={() => router.push('/workers')}
          className="flex items-center space-x-2 text-primary-600 hover:text-primary-700"
        >
          <ArrowLeft className="h-5 w-5" />
          <span>Back to Staffs</span>
        </button>
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          Staff not found
        </div>
      </div>
    );
  }

  const handleRefresh = async () => {
    setLoading(true);
    setError('');
    await Promise.all([fetchWorkerDetails(), fetchAttendanceHistory()]);
    setLoading(false);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-4">
          <button
            onClick={() => router.back()}
            className="flex items-center space-x-2 text-primary-600 hover:text-primary-700"
          >
            <ArrowLeft className="h-5 w-5" />
            <span>Back</span>
          </button>
          <div>
            <h1 className="text-2xl font-bold text-gray-800">{worker.name}</h1>
            <p className="text-gray-600 mt-1">Staff Details</p>
          </div>
        </div>
        <button
          onClick={handleRefresh}
          disabled={loading}
          className="flex items-center space-x-2 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          <span>Refresh</span>
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card title="Staff Information">
          <div className="space-y-4">
            <div className="flex items-start space-x-3">
              <Mail className="h-5 w-5 text-gray-400 mt-0.5" />
              <div>
                <p className="text-sm text-gray-600">Email</p>
                <p className="text-gray-900 font-medium">
                  {worker.email || 'N/A'}
                </p>
              </div>
            </div>
            {worker.phone && (
              <div className="flex items-start space-x-3">
                <Phone className="h-5 w-5 text-gray-400 mt-0.5" />
                <div>
                  <p className="text-sm text-gray-600">Phone</p>
                  <p className="text-gray-900 font-medium">{worker.phone}</p>
                </div>
              </div>
            )}
            {worker.role && (
              <div className="flex items-start space-x-3">
                <Briefcase className="h-5 w-5 text-gray-400 mt-0.5" />
                <div>
                  <p className="text-sm text-gray-600">Role</p>
                  <p className="text-gray-900 font-medium">{worker.role}</p>
                </div>
              </div>
            )}
            <div className="flex items-start space-x-3">
              <Calendar className="h-5 w-5 text-gray-400 mt-0.5" />
              <div>
                <p className="text-sm text-gray-600">Joined Date</p>
                <p className="text-gray-900 font-medium">
                  {new Date(worker.created_at).toLocaleDateString()}
                </p>
              </div>
            </div>
            {assignedProject && (
              <div className="flex items-start space-x-3">
                <Briefcase className="h-5 w-5 text-gray-400 mt-0.5" />
                <div className="flex-1">
                  <p className="text-sm text-gray-600">Assigned Project</p>
                  <p className="text-gray-900 font-medium">
                    {assignedProject.name}
                  </p>
                  {assignedProject.location && (
                    <div className="flex items-center space-x-1 mt-1">
                      <MapPin className="h-3 w-3 text-gray-400" />
                      <p className="text-xs text-gray-500">{assignedProject.location}</p>
                    </div>
                  )}
                </div>
              </div>
            )}
            {!assignedProject && worker?.project_id && (
              <div className="flex items-start space-x-3">
                <Briefcase className="h-5 w-5 text-gray-400 mt-0.5" />
                <div>
                  <p className="text-sm text-gray-600">Project ID</p>
                  <p className="text-gray-900 font-medium text-xs">
                    {worker.project_id}
                  </p>
                </div>
              </div>
            )}
            {!assignedProject && !worker?.project_id && (
              <div className="flex items-start space-x-3">
                <Briefcase className="h-5 w-5 text-gray-400 mt-0.5" />
                <div>
                  <p className="text-sm text-gray-600">Assigned Project</p>
                  <p className="text-gray-500 italic text-sm">Not assigned to any project</p>
                </div>
              </div>
            )}
          </div>
        </Card>

        <Card title="Attendance Statistics">
          <div className="space-y-4">
            <div>
              <p className="text-sm text-gray-600">Total Records</p>
              <p className="text-2xl font-bold text-gray-900">
                {attendanceRecords.length}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Completed Sessions</p>
              <p className="text-2xl font-bold text-green-600">
                {
                  attendanceRecords.filter((r) => r.check_out_time).length
                }
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Active Sessions</p>
              <p className="text-2xl font-bold text-yellow-600">
                {
                  attendanceRecords.filter((r) => !r.check_out_time).length
                }
              </p>
            </div>
          </div>
        </Card>
      </div>

      {chartData.length > 0 && (
        <Card title="Check-ins per Month">
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Bar dataKey="checkIns" fill="#0ea5e9" />
            </BarChart>
          </ResponsiveContainer>
        </Card>
      )}

      <Card title="Attendance History">
        {attendanceRecords.length === 0 ? (
          <div className="text-center py-12">
            <Clock className="h-12 w-12 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-500 text-lg font-medium">No attendance records found</p>
            <p className="text-gray-400 text-sm mt-2">
              This staff member hasn't checked in yet.
            </p>
          </div>
        ) : (
          <Table
            columns={attendanceColumns}
            data={attendanceRecords}
            keyExtractor={(item) => item.id}
            emptyMessage="No attendance records found"
          />
        )}
      </Card>
    </div>
  );
}
