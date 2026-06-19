import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import {
  UsersIcon,
  TruckIcon,
  UserGroupIcon,
  ClockIcon,
  PlusCircleIcon,
  ChartBarIcon,
  ShieldCheckIcon,
  Cog6ToothIcon,
} from '@heroicons/react/24/outline';

export default function AdminDashboard() {
  const { user } = useAuth();
  const navigate = useNavigate();

  // Greeting based on time of day
  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  };

  // Format today's date nicely
  const today = new Date().toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  // Mock system-wide counts
  // In Phase 5 these will come from your PHP API
  const systemCounts = [
    {
      label: 'Total Drivers',
      value: 42,
      icon: UsersIcon,
      color: 'bg-blue-50 text-blue-600',
      border: 'border-blue-100',
    },
    {
      label: 'Total Vehicles',
      value: 18,
      icon: TruckIcon,
      color: 'bg-indigo-50 text-indigo-600',
      border: 'border-indigo-100',
    },
    {
      label: 'Staff Members',
      value: 8,
      icon: UserGroupIcon,
      color: 'bg-sky-50 text-sky-600',
      border: 'border-sky-100',
    },
    {
      label: 'OIC Officers',
      value: 5,
      icon: ShieldCheckIcon,
      color: 'bg-violet-50 text-violet-600',
      border: 'border-violet-100',
    },
  ];

  // Mock attendance summary for today
  const attendance = {
    present: 38,
    late: 4,
    absent: 0,
    total: 42,
  };

  const attendancePct = Math.round((attendance.present / attendance.total) * 100);

  // Quick action buttons
  const quickActions = [
    {
      label: 'Add New User',
      icon: PlusCircleIcon,
      color: 'bg-blue-600 hover:bg-blue-700 text-white',
      path: '/admin/users',
    },
    {
      label: 'Add Driver',
      icon: UsersIcon,
      color: 'bg-white hover:bg-blue-50 text-blue-700 border border-blue-200',
      path: '/admin/drivers',
    },
    {
      label: 'Add Vehicle',
      icon: TruckIcon,
      color: 'bg-white hover:bg-blue-50 text-blue-700 border border-blue-200',
      path: '/admin/vehicles',
    },
    {
      label: 'View Analytics',
      icon: ChartBarIcon,
      color: 'bg-white hover:bg-blue-50 text-blue-700 border border-blue-200',
      path: '/analytics',
    },
    {
      label: 'System Settings',
      icon: Cog6ToothIcon,
      color: 'bg-white hover:bg-blue-50 text-blue-700 border border-blue-200',
      path: '/admin/settings',
    },
  ];

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto">

      {/* ── Header Greeting ── */}
      <div className="bg-gradient-to-r from-blue-600 to-blue-700 
                      rounded-2xl p-6 text-white shadow-lg shadow-blue-100">
        <p className="text-blue-100 text-sm font-medium">{today}</p>
        <h1 className="text-2xl font-bold mt-1">
          {getGreeting()}, {user?.name} 👋
        </h1>
        <p className="text-blue-100 text-sm mt-1">
          Here's what's happening at GT LANTIN today.
        </p>
      </div>

      {/* ── System Count Cards ── */}
      <div>
        <h2 className="text-sm font-bold text-slate-500 uppercase 
                       tracking-widest mb-3">
          System Overview
        </h2>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {systemCounts.map((item, idx) => (
            <div
              key={idx}
              className={`bg-white rounded-2xl p-5 border ${item.border} 
                         shadow-sm hover:shadow-md transition-all`}
            >
              <div className={`w-10 h-10 rounded-xl flex items-center 
                              justify-center mb-3 ${item.color}`}>
                <item.icon className="w-5 h-5" />
              </div>
              <p className="text-3xl font-black text-slate-800">
                {item.value}
              </p>
              <p className="text-xs font-semibold text-slate-500 mt-1">
                {item.label}
              </p>
            </div>
          ))}
        </div>
      </div>

      {/* ── Today's Attendance Summary ── */}
      <div>
        <h2 className="text-sm font-bold text-slate-500 uppercase 
                       tracking-widest mb-3">
          Today's Attendance
        </h2>
        <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm">

          {/* Stats Row */}
          <div className="grid grid-cols-3 gap-4 mb-6">
            <div className="text-center p-4 bg-emerald-50 rounded-xl 
                           border border-emerald-100">
              <p className="text-2xl font-black text-emerald-600">
                {attendance.present}
              </p>
              <p className="text-xs font-bold text-emerald-600 mt-1 uppercase">
                Present
              </p>
            </div>
            <div className="text-center p-4 bg-amber-50 rounded-xl 
                           border border-amber-100">
              <p className="text-2xl font-black text-amber-600">
                {attendance.late}
              </p>
              <p className="text-xs font-bold text-amber-600 mt-1 uppercase">
                Late
              </p>
            </div>
            <div className="text-center p-4 bg-red-50 rounded-xl 
                           border border-red-100">
              <p className="text-2xl font-black text-red-500">
                {attendance.absent}
              </p>
              <p className="text-xs font-bold text-red-500 mt-1 uppercase">
                Absent
              </p>
            </div>
          </div>

          {/* Progress Bar */}
          <div>
            <div className="flex justify-between items-center mb-2">
              <span className="text-sm font-semibold text-slate-600">
                Attendance Rate
              </span>
              <span className="text-sm font-black text-blue-600">
                {attendancePct}%
              </span>
            </div>
            <div className="w-full bg-slate-100 rounded-full h-3">
              <div
                className="bg-blue-600 h-3 rounded-full transition-all duration-700"
                style={{ width: `${attendancePct}%` }}
              />
            </div>
            <p className="text-xs text-slate-400 mt-2">
              {attendance.present} of {attendance.total} drivers present today
            </p>
          </div>
        </div>
      </div>

      {/* ── Quick Actions ── */}
      <div>
        <h2 className="text-sm font-bold text-slate-500 uppercase 
                       tracking-widest mb-3">
          Quick Actions
        </h2>
        <div className="flex flex-wrap gap-3">
          {quickActions.map((action, idx) => (
            <button
              key={idx}
              onClick={() => navigate(action.path)}
              className={`flex items-center gap-2 px-4 py-2.5 rounded-xl 
                         text-sm font-semibold transition-all shadow-sm
                         ${action.color}`}
            >
              <action.icon className="w-4 h-4" />
              {action.label}
            </button>
          ))}
        </div>
      </div>

    </div>
  );
}