import { serverAPI } from '@/lib/api-server';
import StatCard from '@/components/StatCard';
import Card from '@/components/Card';
import AttendanceTable from '@/components/AttendanceTable';
import PoorPerformers from '@/components/PoorPerformers';
import RecentCheckIns from '@/components/RecentCheckIns';
import RecentCheckOuts from '@/components/RecentCheckOuts';
import ActiveProjects from '@/components/ActiveProjects';
import { Users, UserCheck, UserX, Clock, UserCog, FolderCheck } from 'lucide-react';
import { AttendanceRecord, Employee, Project } from '@/lib/api';

async function getDashboardData() {
  try {
    const [employeesRes, attendanceRes, projectsRes] = await Promise.all([
      serverAPI.employees.getAll(),
      serverAPI.attendance.getAll({ sortBy: 'check_in_time', sortOrder: 'desc' }),
      serverAPI.projects.getAll(),
    ]);

    const employees = employeesRes.employees || [];
    const attendanceRecords = attendanceRes.records || [];
    const projects = projectsRes.projects || [];

    const today = new Date().toISOString().split('T')[0];
    const todayRecords = attendanceRecords.filter((record: AttendanceRecord) => {
      const recordDate = new Date(record.check_in_time).toISOString().split('T')[0];
      return recordDate === today;
    });

    // Get unique employees who checked in today
    const presentToday = new Set(
      todayRecords.map((record: AttendanceRecord) => record.user_id)
    ).size;

    const absentToday = employees.length - presentToday;
    const recentActivity = attendanceRecords.slice(0, 10);

    // Calculate supervisors (workers with role containing "supervisor" or similar)
    const supervisors = employees.filter((emp: Employee) =>
      emp.role?.toLowerCase().includes('supervisor') || 
      emp.role?.toLowerCase().includes('super')
    ).length;

    // Calculate completed projects
    const completedProjects = projects.filter((p: any) => 
      p.end_date && new Date(p.end_date) <= new Date()
    ).length;

    // Calculate on hold projects (if status field exists)
    const onHoldProjects = 0; // Not available in current API

    return {
      totalWorkers: employees.length,
      supervisors,
      presentToday,
      absentToday,
      completedProjects,
      onHoldProjects,
      recentActivity,
      employees,
      attendanceRecords,
      projects,
    };
  } catch (error) {
    console.error('Error fetching dashboard data:', error);
    return {
      totalWorkers: 0,
      supervisors: 0,
      presentToday: 0,
      absentToday: 0,
      completedProjects: 0,
      onHoldProjects: 0,
      recentActivity: [],
      employees: [],
      attendanceRecords: [],
      projects: [],
    };
  }
}

export default async function DashboardPage() {
  const {
    totalWorkers,
    supervisors,
    presentToday,
    absentToday,
    completedProjects,
    onHoldProjects,
    recentActivity,
    employees,
    attendanceRecords,
    projects,
  } = await getDashboardData();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-800">Dashboard</h1>
        <p className="text-gray-600 mt-1">Overview of your workforce management system</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Staffs"
          value={totalWorkers}
          subtitle={`${presentToday} active today`}
          icon={<Users className="h-6 w-6 text-primary-600" />}
        />
        <StatCard
          title="Supervisors"
          value={supervisors}
          icon={<UserCog className="h-6 w-6 text-blue-600" />}
        />
        <StatCard
          title="Completed Projects"
          value={completedProjects}
          icon={<FolderCheck className="h-6 w-6 text-green-600" />}
        />
        <StatCard
          title="On Hold"
          value={onHoldProjects}
          icon={<FolderCheck className="h-6 w-6 text-orange-600" />}
        />
      </div>

      <PoorPerformers workers={employees} attendanceRecords={attendanceRecords} />

      <ActiveProjects projects={projects} />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <RecentCheckIns workers={employees} attendanceRecords={attendanceRecords} />
        <RecentCheckOuts workers={employees} attendanceRecords={attendanceRecords} />
      </div>

      <Card title="Recent Attendance Activity">
        <AttendanceTable data={recentActivity} />
      </Card>
    </div>
  );
}

