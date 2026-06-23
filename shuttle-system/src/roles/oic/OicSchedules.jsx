import React from 'react';
import { ChevronLeft, ChevronRight, Plus, CalendarDays } from 'lucide-react';

export default function OicSchedules() {
  const daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  
  // Generating a simple 35-day grid for the calendar mockup (5 weeks)
  const calendarDays = Array.from({ length: 35 }, (_, i) => i + 1);

  // Mock data mapping dates to trip volume
  const scheduledLoads = {
    12: [{ time: 'Morning', count: 4 }, { time: 'Night', count: 2 }],
    15: [{ time: 'Morning', count: 5 }],
    18: [{ time: 'Special', count: 1 }],
    24: [{ time: 'Morning', count: 6 }, { time: 'Night', count: 4 }],
  };

  return (
    <div className="w-full min-h-screen bg-[#F8FAFC] p-4 md:p-8 text-left">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-6 mb-8">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Deployment Calendar</h1>
          <p className="text-sm text-slate-500 mt-1">Manage monthly fleet deployment schedules and trip assignments.</p>
        </div>
        
        <div className="flex items-center gap-3">
          <div className="flex border border-slate-200 rounded-lg overflow-hidden bg-white shadow-sm">
            <button className="px-3 py-2 hover:bg-slate-50 transition-colors"><ChevronLeft size={20} className="text-slate-600"/></button>
            <button className="px-4 py-2 bg-slate-50 border-x border-slate-200 font-semibold text-sm text-slate-700">Today</button>
            <button className="px-3 py-2 hover:bg-slate-50 transition-colors"><ChevronRight size={20} className="text-slate-600"/></button>
          </div>
          <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-semibold transition-colors shadow-sm">
            <Plus size={18} /> New Schedule
          </button>
        </div>
      </div>

      {/* Calendar Grid */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        
        {/* Calendar Title Bar */}
        <div className="p-4 border-b border-slate-200 flex items-center justify-between bg-slate-50/50">
           <h2 className="font-bold text-slate-900 flex items-center gap-2">
             <CalendarDays size={20} className="text-blue-600"/> May 2026
           </h2>
        </div>

        {/* Days of week header */}
        <div className="grid grid-cols-7 border-b border-slate-200">
          {daysOfWeek.map(day => (
            <div key={day} className="py-3 text-center text-xs font-bold text-slate-400 uppercase tracking-wider">
              {day}
            </div>
          ))}
        </div>

        {/* Days Grid */}
        <div className="grid grid-cols-7 auto-rows-[120px] bg-slate-100 gap-[1px]">
          {calendarDays.map((day) => {
            const dateNum = day - 5 > 0 && day - 5 <= 31 ? day - 5 : null;
            const dayEvents = scheduledLoads[dateNum];

            return (
              <div key={day} className="bg-white p-2 hover:bg-slate-50 transition-colors flex flex-col">
                {dateNum && (
                  <>
                    <div className="text-right mb-1">
                      <span className={`inline-flex items-center justify-center w-7 h-7 rounded-full text-sm ${dateNum === 12 ? 'bg-blue-600 text-white font-bold shadow-sm' : 'text-slate-600 font-medium'}`}>
                        {dateNum}
                      </span>
                    </div>
                    
                    {/* Render Events */}
                    <div className="flex-1 overflow-y-auto space-y-1">
                      {dayEvents && dayEvents.map((event, idx) => (
                        <div key={idx} className="px-2 py-1 bg-blue-50 border border-blue-100 rounded text-[10px] text-blue-700 font-bold truncate">
                          {event.count} Trips • {event.time}
                        </div>
                      ))}
                    </div>
                  </>
                )}
              </div>
            );
          })}
        </div>
      </div>
      
    </div>
  );
}