/**
 * Seed Leave Requests and Monthly Summaries for MongoDB
 * 
 * This script creates sample data for:
 * - Leave requests (pending, approved, rejected)
 * - Monthly summaries (DRAFT, SIGNED_BY_STAFF, APPROVED)
 */

require('dotenv').config();
const mongoose = require('mongoose');
const { connectMongoDB } = require('../config/mongodb');
const { Decimal128 } = mongoose.Types;
const { LeaveRequest, LeaveType } = require('../models/LeaveMerged');
const MonthlySummary = require('../models/MonthlySummary');
const EmployeeMerged = require('../models/EmployeeMerged');
const Project = require('../models/Project');
const { v4: uuidv4 } = require('uuid');

// Helper functions
const randomBetween = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const randomDecimal = (min, max) => parseFloat((Math.random() * (max - min) + min).toFixed(2));

// Calculate working days (excluding weekends)
const calculateWorkingDays = (startDate, endDate) => {
  let count = 0;
  const current = new Date(startDate);
  const end = new Date(endDate);
  
  while (current <= end) {
    const dayOfWeek = current.getDay();
    if (dayOfWeek !== 0 && dayOfWeek !== 6) { // Not Sunday or Saturday
      count++;
    }
    current.setDate(current.getDate() + 1);
  }
  return count;
};

async function seedLeaveRequests() {
  try {
    console.log('\n🌱 Seeding Leave Requests...\n');
    
    // Get employees
    const employees = await EmployeeMerged.find().limit(10).lean();
    if (employees.length === 0) {
      console.log('❌ No employees found. Please seed employees first.');
      return;
    }
    
    // Get leave types
    const leaveTypes = await LeaveType.find().lean();
    if (leaveTypes.length === 0) {
      console.log('❌ No leave types found. Please seed leave types first.');
      return;
    }
    
    const annualLeave = leaveTypes.find(lt => lt.code === 'ANNUAL');
    const sickLeave = leaveTypes.find(lt => lt.code === 'SICK');
    const unpaidLeave = leaveTypes.find(lt => lt.code === 'UNPAID');
    
    if (!annualLeave || !sickLeave) {
      console.log('❌ Required leave types (ANNUAL, SICK) not found.');
      return;
    }
    
    // Get admin for approvals (try to find from User model with admin role)
    const User = require('../models/User');
    const admin = await User.findOne({ role: 'ADMIN' }).lean();
    const adminId = admin ? admin._id : null;
    
    // Get projects
    const projects = await Project.find().limit(5).lean();
    
    const currentYear = new Date().getFullYear();
    const currentMonth = new Date().getMonth() + 1;
    
    let created = 0;
    let skipped = 0;
    
    for (let i = 0; i < employees.length; i++) {
      const employee = employees[i];
      const project = projects.length > 0 ? projects[randomBetween(0, projects.length - 1)] : null;
      
      // Create pending request
      const pendingStart = new Date();
      pendingStart.setDate(pendingStart.getDate() + randomBetween(7, 30));
      const pendingEnd = new Date(pendingStart);
      pendingEnd.setDate(pendingEnd.getDate() + randomBetween(1, 3));
      
      const pendingId = uuidv4();
      const existingPending = await LeaveRequest.findById(pendingId);
      if (!existingPending) {
        await LeaveRequest.create({
          _id: pendingId,
          employee_id: employee._id,
          leave_type_id: annualLeave._id,
          start_date: pendingStart,
          end_date: pendingEnd,
          number_of_days: calculateWorkingDays(pendingStart, pendingEnd),
          reason: 'Family vacation',
          status: 'pending',
          project_id: project ? project._id : null,
          created_at: new Date(),
          updated_at: new Date(),
        });
        created++;
      } else {
        skipped++;
      }
      
      // Create approved request (past dates)
      if (i < 5) {
        const approvedStart = new Date();
        approvedStart.setMonth(approvedStart.getMonth() - 1);
        approvedStart.setDate(randomBetween(1, 15));
        const approvedEnd = new Date(approvedStart);
        approvedEnd.setDate(approvedEnd.getDate() + randomBetween(1, 2));
        
        const approvedId = uuidv4();
        const existingApproved = await LeaveRequest.findById(approvedId);
        if (!existingApproved) {
          await LeaveRequest.create({
            _id: approvedId,
            employee_id: employee._id,
            leave_type_id: sickLeave._id,
            start_date: approvedStart,
            end_date: approvedEnd,
            number_of_days: calculateWorkingDays(approvedStart, approvedEnd),
            reason: 'Medical appointment',
            status: 'approved',
            approved_by: adminId,
            approved_at: new Date(approvedStart.getTime() + 86400000), // 1 day after
            project_id: project ? project._id : null,
            created_at: approvedStart,
            updated_at: new Date(),
          });
          created++;
        } else {
          skipped++;
        }
      }
      
      // Create rejected request
      if (i < 3) {
        const rejectedStart = new Date();
        rejectedStart.setDate(rejectedStart.getDate() + randomBetween(30, 60));
        const rejectedEnd = new Date(rejectedStart);
        rejectedEnd.setDate(rejectedEnd.getDate() + randomBetween(5, 7));
        
        const rejectedId = uuidv4();
        const existingRejected = await LeaveRequest.findById(rejectedId);
        if (!existingRejected) {
          await LeaveRequest.create({
            _id: rejectedId,
            employee_id: employee._id,
            leave_type_id: annualLeave._id,
            start_date: rejectedStart,
            end_date: rejectedEnd,
            number_of_days: calculateWorkingDays(rejectedStart, rejectedEnd),
            reason: 'Extended vacation',
            status: 'rejected',
            approved_by: adminId,
            rejection_reason: 'Too many days requested',
            project_id: project ? project._id : null,
            created_at: new Date(rejectedStart.getTime() - 86400000 * 5),
            updated_at: new Date(),
          });
          created++;
        } else {
          skipped++;
        }
      }
    }
    
    console.log(`✅ Created ${created} leave requests`);
    console.log(`⏭️  Skipped ${skipped} (already exist)\n`);
  } catch (error) {
    console.error('❌ Error seeding leave requests:', error);
    throw error;
  }
}

async function seedMonthlySummaries() {
  try {
    console.log('🌱 Seeding Monthly Summaries...\n');
    
    // Get employees
    const employees = await EmployeeMerged.find().limit(10).lean();
    if (employees.length === 0) {
      console.log('❌ No employees found. Please seed employees first.');
      return;
    }
    
    // Get projects
    const projects = await Project.find().limit(5).lean();
    
    const currentYear = new Date().getFullYear();
    const currentMonth = new Date().getMonth() + 1;
    const previousMonth = currentMonth === 1 ? 12 : currentMonth - 1;
    const previousYear = currentMonth === 1 ? currentYear - 1 : currentYear;
    
    let created = 0;
    let skipped = 0;
    
    // Create summaries for both current month (current year) and previous month
    const monthsToCreate = [
      { month: currentMonth, year: currentYear }, // Current month
      { month: previousMonth, year: previousYear } // Previous month
    ];
    
    for (let i = 0; i < employees.length; i++) {
      const employee = employees[i];
      
      for (const { month, year } of monthsToCreate) {
        // Create summary for this month/year
        const summaryId = `${employee._id}_${month}_${year}`;
        const existing = await MonthlySummary.findOne({
          employee_id: employee._id,
          month: month,
          year: year
        });
      
      if (!existing) {
        const totalWorkingDays = randomBetween(20, 26);
        const totalWorkedHours = randomDecimal(150, 200);
        const totalOtHours = randomDecimal(10, 35);
        const approvedLeaves = randomDecimal(0, 3);
        const absentDays = randomBetween(0, 2);
        
        // Generate project breakdown
        const projectBreakdown = [];
        if (projects.length > 0) {
          const numProjects = randomBetween(1, Math.min(3, projects.length));
          let remainingHours = totalWorkedHours;
          let remainingOT = totalOtHours;
          
          for (let j = 0; j < numProjects; j++) {
            const project = projects[j];
            const isLast = j === numProjects - 1;
            const daysWorked = randomBetween(5, 10);
            const hours = isLast ? remainingHours : randomDecimal(40, remainingHours / 2);
            const otHours = isLast ? remainingOT : randomDecimal(5, remainingOT / 2);
            
            remainingHours -= hours;
            remainingOT -= otHours;
            
            projectBreakdown.push({
              project_id: project._id,
              project_name: project.name,
              days_worked: daysWorked,
              total_hours: Decimal128.fromString(hours.toFixed(2)),
              ot_hours: Decimal128.fromString(otHours.toFixed(2)),
            });
          }
        }
        
        // Different statuses for variety
        let status = 'DRAFT';
        if (i < 3) status = 'SIGNED_BY_STAFF';
        if (i < 1) status = 'APPROVED';
        
        await MonthlySummary.create({
          _id: summaryId,
          employee_id: employee._id,
          month: month,
          year: year,
          total_working_days: totalWorkingDays,
          total_worked_hours: Decimal128.fromString(totalWorkedHours.toFixed(2)),
          total_ot_hours: Decimal128.fromString(totalOtHours.toFixed(2)),
          approved_leaves: Decimal128.fromString(approvedLeaves.toFixed(2)),
          absent_days: absentDays,
          project_breakdown: projectBreakdown,
          status: status,
          created_at: new Date(),
          updated_at: new Date(),
        });
        created++;
      } else {
        skipped++;
      }
      } // End of monthsToCreate loop
    } // End of employees loop
    
    console.log(`✅ Created ${created} monthly summaries`);
    console.log(`⏭️  Skipped ${skipped} (already exist)\n`);
  } catch (error) {
    console.error('❌ Error seeding monthly summaries:', error);
    throw error;
  }
}

async function main() {
  try {
    console.log('🚀 Starting MongoDB Seed for Leave & Monthly Summaries...\n');
    
    // Connect to MongoDB
    await connectMongoDB();
    console.log('✅ Connected to MongoDB\n');
    
    // Seed leave requests
    await seedLeaveRequests();
    
    // Seed monthly summaries
    await seedMonthlySummaries();
    
    console.log('✅ Seeding completed successfully!\n');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Seeding failed:', error);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { seedLeaveRequests, seedMonthlySummaries };

