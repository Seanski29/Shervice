import React from 'react';
import { ChevronLeft, ChevronRight, Plus } from 'lucide-react';

export default function OicSchedules() {
  const daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  
  // Generating a simple 35-day grid for the calendar mockup (5 weeks)
  const calendarDays = Array.from({ length: 35 }, (_, i) => i + 1);

  // Mock data mapping dates to trip volume
  const scheduledLoads = {
    12: [{ time: 'Morning Shift', count: 4 }, { time: 'Night Shift', count: 2 }],
    15: [{ time: 'Morning Shift', count: 5 }],
    18: [{ time: 'Special Dispatch', count: 1 }],
    24: [{ time: 'Morning Shift', count: 6 }, { time: 'Night Shift', count: 4 }],
  };

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      
      {/* Calendar Header */}
      <div className="flex justify-between items-center bg-white p-6 rounded-xl shadow-sm border border-slate-200">
        <div>
          <h1 className="text-3xl font-bold text-slate-800">May 2026</h1>
          <p className="text-slate-500 mt-1">Monthly Fleet Deployment Schedule</p>
        </div>
        
        <div className="flex items-center gap-4">
          <div className="flex border border-slate-300 rounded-lg overflow-hidden">
            <button className="px-3 py-2 hover:bg-slate-100 transition-colors"><ChevronLeft size={20} className="text-slate-600"/></button>
            <button className="px-4 py-2 bg-slate-50 border-x border-slate-300 font-medium text-slate-700">Today</button>
            <button className="px-3 py-2 hover:bg-slate-100 transition-colors"><ChevronRight size={20} className="text-slate-600"/></button>
          </div>
          <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors shadow-sm">
            <Plus size={18} /> New Schedule
          </button>
        </div>
      </div>

      {/* Calendar Grid */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        {/* Days of week header */}
        <div className="grid grid-cols-7 bg-slate-50 border-b border-slate-200">
          {daysOfWeek.map(day => (
            <div key={day} className="py-3 text-center text-sm font-bold text-slate-500 uppercase tracking-wider">
              {day}
            </div>
          ))}
        </div>

        {/* Days Grid */}
        <div className="grid grid-cols-7 auto-rows-[120px] bg-slate-200 gap-[1px]">
          {calendarDays.map((day) => {
            // Logic to handle empty days at the start of the month (starting on a Friday for May 2026)
            const dateNum = day - 5 > 0 && day - 5 <= 31 ? day - 5 : null;
            const dayEvents = scheduledLoads[dateNum];

            return (
              <div key={day} className="bg-white p-2 hover:bg-slate-50 transition-colors flex flex-col">
                {dateNum && (
                  <>
                    <div className="text-right text-sm font-medium text-slate-400 mb-1">
                      <span className={`inline-flex items-center justify-center w-7 h-7 rounded-full ${dateNum === 12 ? 'bg-blue-600 text-white font-bold shadow-md' : ''}`}>
                        {dateNum}
                      </span>
                    </div>
                    
                    {/* Render Events if they exist for this day */}
                    <div className="flex-1 overflow-y-auto space-y-1 custom-scrollbar">
                      {dayEvents && dayEvents.map((event, idx) => (
                        <div key={idx} className="px-2 py-1 bg-blue-50 border border-blue-100 rounded text-xs text-blue-700 font-medium truncate">
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