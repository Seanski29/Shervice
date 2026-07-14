import React from 'react';
import { 
  CheckCircleIcon, 
  ExclamationCircleIcon, 
  MagnifyingGlassIcon,
  ClockIcon
} from '@heroicons/react/24/outline';

export default function SAttendance() {
  // Mock data representing real-time logs for the GT LANTIN dispatch schedule
  const attendanceLogs = [
    { id: 1, name: "Juan Dela Cruz", initials: "JD", time: "05:48 AM", status: "On-Time", route: "EPSON - Shift A" },
    { id: 2, name: "Ricardo Ramos", initials: "RR", time: "06:02 AM", status: "Late", route: "Bandai - Shift A" },
    { id: 3, name: "Miguel Santos", initials: "MS", time: "05:55 AM", status: "On-Time", route: "NX Logistics" },
    { id: 4, name: "Antonio Luna", initials: "AL", time: "05:30 AM", status: "On-Time", route: "EPSON - Shift B" },
  ];

  // Helper function for status badges
  const getStatusStyle = (status) => {
    switch(status) {
      case 'On-Time': return 'bg-green-50 text-green-700 border-green-200';
      case 'Late': return 'bg-amber-50 text-amber-700 border-amber-200';
      default: return 'bg-slate-50 text-slate-700 border-slate-200';
    }
  };

  return (
    <div className="w-full min-h-screen bg-[#F8FAFC] p-4 md:p-8 text-left">
      
      {/* 1. Header & Quick Stats */}
      <div className="flex flex-col xl:flex-row xl:items-end justify-between gap-6 mb-8">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Attendance Monitoring</h1>
          <p className="text-sm text-slate-500 mt-1 flex items-center gap-1.5">
            <ClockIcon className="w-4 h-4" />
            Showing real-time logs for {new Date().toLocaleDateString()}
          </p>
        </div>
        
        <div className="flex flex-wrap sm:flex-nowrap gap-4">
          <div className="bg-white px-5 py-4 rounded-xl border border-slate-200 shadow-sm min-w-[140px] flex flex-col justify-center">
            <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">Present</p>
            <p className="text-2xl font-bold text-slate-900">42<span className="text-sm text-slate-400 font-medium">/59</span></p>
          </div>
          <div className="bg-white px-5 py-4 rounded-xl border border-slate-200 shadow-sm min-w-[140px] flex flex-col justify-center">
            <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">On-Time</p>
            <p className="text-2xl font-bold text-green-600">92%</p>
          </div>
        </div>
      </div>

      {/* 2. Daily Log Feed Container */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        
        {/* Container Header & Filter */}
        <div className="p-5 border-b border-slate-200 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-slate-50/50">
          <h3 className="font-bold text-slate-900 tracking-tight text-lg">Daily Log Feed</h3>
          <div className="relative w-full sm:w-72">
            <span className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <MagnifyingGlassIcon className="h-4 w-4 text-slate-400" />
            </span>
            <input 
              type="text" 
              className="block w-full pl-9 pr-3 py-2 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none transition-shadow shadow-sm bg-white" 
              placeholder="Filter by driver name..."
            />
          </div>
        </div>

        {/* Log List */}
        <div className="divide-y divide-slate-100">
          {attendanceLogs.map((log) => (
            <div key={log.id} className="flex flex-col sm:flex-row items-start sm:items-center justify-between p-5 hover:bg-slate-50 transition-colors group gap-4">
              
              {/* Driver Identity */}
              <div className="flex items-center gap-4">
                <div className="w-11 h-11 bg-slate-100 border border-slate-200 text-slate-600 rounded-full flex items-center justify-center text-sm font-bold shadow-sm shrink-0 group-hover:bg-blue-50 group-hover:text-blue-600 group-hover:border-blue-100 transition-colors">
                  {log.initials}
                </div>
                <div>
                  <p className="text-base font-semibold text-slate-900">{log.name}</p>
                  <p className="text-xs font-medium text-slate-500 mt-0.5">{log.route}</p>
                </div>
              </div>
              
              {/* Status & Time */}
              <div className="flex flex-row sm:flex-col items-center sm:items-end justify-between w-full sm:w-auto gap-2">
                <div className="flex items-center gap-1.5">
                  {log.status === 'On-Time' ? (
                    <CheckCircleIcon className="w-5 h-5 text-green-500" />
                  ) : (
                    <ExclamationCircleIcon className="w-5 h-5 text-amber-500" />
                  )}
                  <span className={`px-2 py-0.5 rounded text-[11px] font-semibold border ${getStatusStyle(log.status)}`}>
                    {log.status}
                  </span>
                </div>
                <span className="text-sm font-semibold text-slate-700 bg-slate-100 px-2.5 py-1 rounded-md border border-slate-200">
                  {log.time}
                </span>
              </div>

            </div>
          ))}
          
          {/* Empty State / Bottom Padding (Optional) */}
          {attendanceLogs.length === 0 && (
            <div className="p-8 text-center text-slate-500 text-sm">
              No attendance logs found for today.
            </div>
          )}
        </div>
      </div>

    </div>
  );
}