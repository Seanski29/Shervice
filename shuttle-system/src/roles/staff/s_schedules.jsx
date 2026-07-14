import React from 'react';
import { 
  MapPinIcon, 
  PlusIcon, 
  TruckIcon, 
  UsersIcon, 
  ClockIcon, 
  CalendarDaysIcon,
  SparklesIcon
} from '@heroicons/react/24/outline';

export default function SSchedules() {
  // Mock data representing the Dispatch & Scheduling Matrix requirements
  const activeSchedules = [
    { id: 1, route: "LIMA Estate (EPSON)", shift: "Shift 1", time: "06:00 AM", driver: "Juan Dela Cruz", vehicle: "ABC-1234" },
    { id: 2, route: "Malvar (Bandai Namco)", shift: "Shift 1", time: "06:30 AM", driver: "Ricardo Ramos", vehicle: "XYZ-5678" },
    { id: 3, route: "FPIP (NX Logistics)", shift: "Shift 2", time: "02:00 PM", driver: "Miguel Santos", vehicle: "GHI-9012" },
  ];

  return (
    <div className="w-full min-h-screen bg-[#F8FAFC] p-4 md:p-8 text-left">
      
      {/* 1. Page Header & Primary Action */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Dispatch & Scheduling</h1>
          <p className="text-sm text-slate-500 mt-1">Manage active fleet routes, driver shifts, and daily dispatch matrices.</p>
        </div>
        <button className="flex items-center justify-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-semibold transition-colors shadow-sm">
          <PlusIcon className="w-5 h-5" /> 
          New Dispatch
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 xl:gap-8">
        
        {/* 2. Main Schedule Matrix */}
        <div className="lg:col-span-2 space-y-4">
          <div className="flex items-center gap-2 px-1">
            <MapPinIcon className="w-5 h-5 text-blue-600" />
            <h3 className="font-bold text-slate-900 text-lg">Active Fleet Routes</h3>
          </div>

          <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
            <div className="divide-y divide-slate-100">
              {activeSchedules.map((item) => (
                <div key={item.id} className="p-5 hover:bg-slate-50 transition-colors group">
                  <div className="flex flex-col md:flex-row md:items-center justify-between gap-5">
                    
                    {/* Route & Time Info */}
                    <div>
                      <p className="text-base font-semibold text-slate-900">{item.route}</p>
                      <div className="flex items-center gap-2.5 mt-2">
                        <span className="flex items-center gap-1.5 text-xs font-semibold text-blue-700 bg-blue-50 px-2 py-1 rounded-md border border-blue-100">
                          <ClockIcon className="w-3.5 h-3.5" /> {item.time}
                        </span>
                        <span className="text-xs font-medium text-slate-600 bg-slate-100 px-2 py-1 rounded-md border border-slate-200">
                          {item.shift}
                        </span>
                      </div>
                    </div>

                    {/* Driver & Vehicle Assignment */}
                    <div className="flex flex-wrap md:flex-nowrap items-center gap-4 md:gap-6 border-t border-slate-100 md:border-t-0 pt-3 md:pt-0">
                      
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-slate-50 border border-slate-200 flex items-center justify-center text-slate-500 group-hover:bg-blue-50 group-hover:text-blue-600 group-hover:border-blue-100 transition-colors">
                          <UsersIcon className="w-4 h-4" />
                        </div>
                        <span className="text-sm font-medium text-slate-700">{item.driver}</span>
                      </div>
                      
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-slate-50 border border-slate-200 flex items-center justify-center text-slate-500 group-hover:bg-blue-50 group-hover:text-blue-600 group-hover:border-blue-100 transition-colors">
                          <TruckIcon className="w-4 h-4" />
                        </div>
                        <span className="text-sm font-medium text-slate-700">{item.vehicle}</span>
                      </div>

                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* 3. Summary & Optimization Sidebar */}
        <div className="space-y-6">
           
           {/* Assignment Status Card */}
           <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex flex-col">
              <h4 className="font-bold text-slate-900 text-sm mb-4">Assignment Status</h4>
              
              <div className="space-y-1 mb-6">
                 <div className="flex justify-between items-center py-2 border-b border-slate-100">
                    <span className="text-sm font-medium text-slate-500">Total Units</span>
                    <span className="text-sm font-bold text-slate-900">18</span>
                 </div>
                 <div className="flex justify-between items-center py-2 border-b border-slate-100">
                    <span className="text-sm font-medium text-slate-500">Available Drivers</span>
                    <span className="text-sm font-bold text-green-600">7</span>
                 </div>
                 <div className="flex justify-between items-center py-2">
                    <span className="text-sm font-medium text-slate-500">Standby Vehicles</span>
                    <span className="text-sm font-bold text-blue-600">4</span>
                 </div>
              </div>

              <button className="w-full mt-auto py-2 flex justify-center items-center gap-2 bg-white hover:bg-slate-50 text-slate-700 text-sm font-semibold rounded-lg transition-colors border border-slate-200 shadow-sm">
                 <SparklesIcon className="w-4 h-4 text-blue-500" />
                 Optimize Matrix
              </button>
           </div>

           {/* Shift Continuity Info Card */}
           <div className="bg-gradient-to-br from-blue-600 to-blue-700 p-6 rounded-xl shadow-md text-white relative overflow-hidden">
              <CalendarDaysIcon className="absolute -right-4 -bottom-4 w-24 h-24 text-white/10 rotate-12" />
              <div className="relative z-10">
                <h4 className="font-bold text-sm tracking-wide mb-2 flex items-center gap-2">
                  <CalendarDaysIcon className="w-5 h-5 opacity-80" />
                  Shift Continuity
                </h4>
                <p className="text-sm text-blue-100 leading-relaxed font-medium">
                  The dispatch matrix is currently synced with the LIMA and FPIP estate shift rotations.
                </p>
              </div>
           </div>

        </div>

      </div>
    </div>
  );
}