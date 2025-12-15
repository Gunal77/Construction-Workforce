'use client';

import { useState, useEffect, useMemo, useCallback } from 'react';
import { attendanceAPI, employeesAPI, projectsAPI } from '@/lib/api';
import StatCard from '@/components/StatCard';
import Card from '@/components/Card';
import ProjectReportsTable from '@/components/ProjectReportsTable';
import DateRangeFilter, { DateRange, CompareDateRange } from '@/components/DateRangeFilter';
import { FolderKanban, Users as UsersIcon, Clock as ClockIcon, DollarSign } from 'lucide-react';

interface ReportsData {
  totalProjects: number;
  activeProjects: number;
  totalWorkers: number;
  activeToday: number;
  totalHours: number;
  hoursTrend: number;
  totalBudget: number;
  totalSpent: number;
  budgetUtilization: number;
  projectReports: any[];
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

export default function ReportsPage() {
  const [loading, setLoading] = useState(true);
  const [reportsData, setReportsData] = useState<ReportsData>({
    totalProjects: 0,
    activeProjects: 0,
    totalWorkers: 0,
    activeToday: 0,
    totalHours: 0,
    hoursTrend: 0,
    totalBudget: 0,
    totalSpent: 0,
    budgetUtilization: 0,
    projectReports: [],
  });
  const [dateRange, setDateRange] = useState<DateRange>({
    from: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
    to: new Date(),
  });
  const [compareRange, setCompareRange] = useState<CompareDateRange | undefined>(undefined);

  const fetchReportsData = useCallback(async (range: DateRange, compare?: CompareDateRange) => {
    try {
      setLoading(true);
      
      // Normalize dates to start/end of day for proper comparison
      const normalizeDateToStartOfDay = (date: Date) => {
        const normalized = new Date(date);
        normalized.setHours(0, 0, 0, 0);
        return normalized;
      };
      
      const normalizeDateToEndOfDay = (date: Date) => {
        const normalized = new Date(date);
        normalized.setHours(23, 59, 59, 999);
        return normalized;
      };
      
      const fromDate = range.from ? range.from.toISOString().split('T')[0] : undefined;
      const toDate = range.to ? range.to.toISOString().split('T')[0] : undefined;

      const [employeesRes, attendanceRes, projectsRes] = await Promise.all([
        employeesAPI.getAll(),
        attendanceAPI.getAll({
          from: fromDate,
          to: toDate,
          sortBy: 'check_in_time',
          sortOrder: 'desc',
        }),
        projectsAPI.getAll(),
      ]);

      const workers = employeesRes.employees || [];
      const attendanceRecords = attendanceRes.records || [];
      const projects = projectsRes.projects || [];

      // Calculate statistics for selected date range
      const activeProjects = projects.filter((p: any) => !p.end_date || new Date(p.end_date) > new Date()).length;
      
      const today = new Date().toISOString().split('T')[0];
      const todayRecords = attendanceRecords.filter((record: any) => {
        const recordDate = new Date(record.check_in_time).toISOString().split('T')[0];
        return recordDate === today;
      });
      const activeToday = new Set(todayRecords.map((r: any) => r.user_id)).size;

      // Calculate total hours for selected date range
      // Backend should already filter by date range, but we do client-side filtering as well
      // to ensure accuracy (in case backend filtering has timezone issues)
      const rangeStart = range.from ? normalizeDateToStartOfDay(range.from) : null;
      const rangeEnd = range.to ? normalizeDateToEndOfDay(range.to) : null;
      
      const rangeRecords = attendanceRecords.filter((record: any) => {
        if (!record.check_out_time) return false;
        const recordDate = normalizeDateToStartOfDay(new Date(record.check_in_time));
        return rangeStart && rangeEnd && recordDate >= rangeStart && recordDate <= rangeEnd;
      });
      
      const totalHours = rangeRecords.reduce((sum: number, record: any) => {
        const checkIn = new Date(record.check_in_time);
        const checkOut = new Date(record.check_out_time);
        const diff = checkOut.getTime() - checkIn.getTime();
        const hours = diff / (1000 * 60 * 60);
        return sum + hours;
      }, 0);

      // Calculate comparison hours if compare is enabled
      let hoursTrend = 0;
      if (compare?.enabled && compare.from && compare.to) {
        const compareFromDate = compare.from.toISOString().split('T')[0];
        const compareToDate = compare.to.toISOString().split('T')[0];
        
        const compareAttendanceRes = await attendanceAPI.getAll({
          from: compareFromDate,
          to: compareToDate,
        });
        
        const compareStart = compare.from ? normalizeDateToStartOfDay(compare.from) : null;
        const compareEnd = compare.to ? normalizeDateToEndOfDay(compare.to) : null;
        
        const compareRecords = (compareAttendanceRes.records || []).filter((record: any) => {
          if (!record.check_out_time) return false;
          const recordDate = normalizeDateToStartOfDay(new Date(record.check_in_time));
          return compareStart && compareEnd && recordDate >= compareStart && recordDate <= compareEnd;
        });
        
        const compareHours = compareRecords.reduce((sum: number, record: any) => {
          const checkIn = new Date(record.check_in_time);
          const checkOut = new Date(record.check_out_time);
          const diff = checkOut.getTime() - checkIn.getTime();
          const hours = diff / (1000 * 60 * 60);
          return sum + hours;
        }, 0);

        hoursTrend = compareHours > 0 
          ? ((totalHours - compareHours) / compareHours) * 100 
          : 0;
      } else {
        // Compare with previous period (same duration before selected range)
        if (range.from && range.to) {
          const duration = range.to.getTime() - range.from.getTime();
          const prevTo = new Date(range.from.getTime() - 1);
          const prevFrom = new Date(prevTo.getTime() - duration);
          
          const prevFromDate = prevFrom.toISOString().split('T')[0];
          const prevToDate = prevTo.toISOString().split('T')[0];
          
          const prevAttendanceRes = await attendanceAPI.getAll({
            from: prevFromDate,
            to: prevToDate,
          });
          
          const prevStart = normalizeDateToStartOfDay(prevFrom);
          const prevEnd = normalizeDateToEndOfDay(prevTo);
          
          const prevRecords = (prevAttendanceRes.records || []).filter((record: any) => {
            if (!record.check_out_time) return false;
            const recordDate = normalizeDateToStartOfDay(new Date(record.check_in_time));
            return recordDate >= prevStart && recordDate <= prevEnd;
          });
          
          const prevHours = prevRecords.reduce((sum: number, record: any) => {
            const checkIn = new Date(record.check_in_time);
            const checkOut = new Date(record.check_out_time);
            const diff = checkOut.getTime() - checkIn.getTime();
            const hours = diff / (1000 * 60 * 60);
            return sum + hours;
          }, 0);

          hoursTrend = prevHours > 0 
            ? ((totalHours - prevHours) / prevHours) * 100 
            : 0;
        }
      }

      // Calculate total budget
      let totalBudget = 0;
      let totalSpent = 0;
      projects.forEach((project: any) => {
        if (project.budget) {
          totalBudget += typeof project.budget === 'string' ? parseFloat(project.budget) : project.budget;
        }
        // Estimate spent based on completion if available
        if (project.budget && project.completion) {
          const budget = typeof project.budget === 'string' ? parseFloat(project.budget) : project.budget;
          totalSpent += budget * (project.completion / 100);
        }
      });

      const budgetUtilization = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;

      // Project reports data filtered by date range
      const projectReports = projects.map((project: any) => {
        const projectWorkers = workers.filter((w: any) => w.project_id === project.id);
        const projectRecords = rangeRecords.filter((r: any) => 
          projectWorkers.some((w: any) => w.id === r.user_id)
        );
        
        const projectHours = projectRecords.reduce((sum: number, record: any) => {
          const checkIn = new Date(record.check_in_time);
          const checkOut = new Date(record.check_out_time);
          const diff = checkOut.getTime() - checkIn.getTime();
          return sum + (diff / (1000 * 60 * 60));
        }, 0);

        // Determine status
        let status = 'ACTIVE';
        if (project.end_date && new Date(project.end_date) <= new Date()) {
          status = 'COMPLETED';
        } else if (project.status === 'on_hold' || project.status === 'ON HOLD') {
          status = 'ON HOLD';
        }

        // Calculate completion percentage
        let completion = null;
        if (project.end_date && project.start_date) {
          const start = new Date(project.start_date);
          const end = new Date(project.end_date);
          const now = new Date();
          const totalDuration = end.getTime() - start.getTime();
          const elapsed = now.getTime() - start.getTime();
          if (totalDuration > 0) {
            completion = Math.min(100, Math.max(0, (elapsed / totalDuration) * 100));
          }
        } else if (status === 'COMPLETED') {
          completion = 100;
        }

        // Calculate spent (estimate based on completion or use actual if available)
        let spent = null;
        if (project.budget) {
          const budget = typeof project.budget === 'string' ? parseFloat(project.budget) : project.budget;
          if (completion !== null) {
            spent = budget * (completion / 100);
          } else if (project.spent) {
            spent = typeof project.spent === 'string' ? parseFloat(project.spent) : project.spent;
          }
        }

        return {
          id: project.id,
          name: project.name,
          startDate: project.start_date,
          status,
          workers: projectWorkers.length,
          totalHours: Math.round(projectHours),
          budget: project.budget ? (typeof project.budget === 'string' ? parseFloat(project.budget) : project.budget) : null,
          spent,
          completion: completion ? Math.round(completion) : null,
        };
      });

      setReportsData({
        totalProjects: projects.length,
        activeProjects,
        totalWorkers: workers.length,
        activeToday,
        totalHours: Math.round(totalHours),
        hoursTrend,
        totalBudget,
        totalSpent,
        budgetUtilization,
        projectReports,
      });
    } catch (error) {
      console.error('Error fetching reports data:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchReportsData(dateRange, compareRange);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleDateRangeChange = useCallback((range: DateRange, compare?: CompareDateRange) => {
    setDateRange(range);
    setCompareRange(compare);
    fetchReportsData(range, compare);
  }, [fetchReportsData]);

  const getTrendLabel = () => {
    if (compareRange?.enabled) {
      if (compareRange.type === 'previous-year') {
        return 'vs previous year';
      } else if (compareRange.type === 'previous-month') {
        return 'vs previous month';
      } else {
        return 'vs comparison period';
      }
    }
    return 'vs previous period';
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading reports...</div>
      </div>
    );
  }

  return (
    <div className="space-y-4 md:space-y-6 w-full max-w-full overflow-x-hidden">
      <div>
        <h1 className="text-xl md:text-2xl font-bold text-gray-800">Reports & Analytics</h1>
        <p className="text-sm md:text-base text-gray-600 mt-1">Comprehensive project, attendance, and performance reports</p>
      </div>

      {/* Date Range Filter */}
      <div className="w-full max-w-full">
        <DateRangeFilter onDateRangeChange={handleDateRangeChange} />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Total Projects"
          value={reportsData.totalProjects}
          subtitle={`${reportsData.activeProjects} Active`}
          icon={<FolderKanban className="h-6 w-6 text-blue-600" />}
        />
        <StatCard
          title="Total Workers"
          value={reportsData.totalWorkers}
          subtitle={`${reportsData.activeToday} Active Today`}
          icon={<UsersIcon className="h-6 w-6 text-green-600" />}
        />
        <StatCard
          title="Total Hours"
          value={reportsData.totalHours.toLocaleString()}
          subtitle={reportsData.hoursTrend !== 0 ? (
            <span className={reportsData.hoursTrend > 0 ? 'text-green-600' : 'text-red-600'}>
              {reportsData.hoursTrend > 0 ? '+' : ''}{reportsData.hoursTrend.toFixed(1)}% {getTrendLabel()}
            </span>
          ) : undefined}
          icon={<ClockIcon className="h-6 w-6 text-orange-600" />}
        />
        <StatCard
          title="Total Budget"
          value={reportsData.totalBudget > 0 ? formatCurrency(reportsData.totalBudget) : '$0'}
          subtitle={reportsData.totalBudget > 0 ? `${reportsData.budgetUtilization.toFixed(1)}% utilized` : undefined}
          icon={<DollarSign className="h-6 w-6 text-red-600" />}
        />
      </div>

      <Card title="Project Reports">
        <ProjectReportsTable data={reportsData.projectReports} />
      </Card>
    </div>
  );
}
