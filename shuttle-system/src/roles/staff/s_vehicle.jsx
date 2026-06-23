import React from 'react';
import { 
  TruckIcon, 
  WrenchScrewdriverIcon, 
  UsersIcon, 
  PlusIcon, 
  MagnifyingGlassIcon,
  CheckBadgeIcon,
  ExclamationTriangleIcon
} from '@heroicons/react/24/outline';

export default function SVehicle() {
  // Expanded data mapped to Vehicle Profile & Maintenance Tracking requirements
  const vehicles = [
    { plate: "GT-VAN-012", model: "Toyota Hiace Commuter", capacity: "15 Seats", condition: "Excellent", status: "Active (On Route)" },
    { plate: "GT-VAN-008", model: "Nissan Urvan NV350", capacity: "15 Seats", condition: "Good", status: "Active (On Route)" },
    { plate: "GT-VAN-022", model: "Toyota Hiace GL Grandia", capacity: "12 Seats", condition: "Needs Maintenance", status: "Garage" },
    { plate: "GT-VAN-045", model: "Toyota Commuter Deluxe", capacity: "15 Seats", condition: "Good", status: "Standby" },
  ];

  // Helper function to determine status badge colors
  const getStatusStyle = (status) => {
    if (status.includes('Active')) return 'bg-green-100 text-green-700';
    if (status.includes('Garage')) return 'bg-red-100 text-red-700';
    if (status.includes('Standby')) return 'bg-blue-100 text-blue-700';
    return 'bg-slate-100 text-slate-600';
  };

  return (
    <div className="w-full min-h-screen bg-[#F8FAFC] p-4 md:p-8 text-left">
      
      {/* 1. Page Title & Action Bar */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 mb-8">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Fleet Management</h1>
          <p className="text-sm text-slate-500 mt-1">Monitor vehicle status, capacity, and maintenance schedules.</p>
        </div>

        <div className="flex flex-col sm:flex-row gap-3">
          {/* Search Utility */}
          <div className="relative">
            <span className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <MagnifyingGlassIcon className="h-5 w-5 text-slate-400" />
            </span>
            <input 
              type="text" 
              className="block w-full sm:w-72 pl-10 pr-3 py-2 border border-slate-200 rounded-lg leading-5 bg-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 sm:text-sm shadow-sm" 
              placeholder="Search vehicle by plate or model..."
            />
          </div>

          <button className="flex items-center justify-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-semibold transition-colors shadow-sm">
            <PlusIcon className="w-5 h-5" /> 
            Register Vehicle
          </button>
        </div>
      </div>

      {/* 2. Vehicle Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
        {vehicles.map((vehicle, idx) => (
          <div 
            key={idx} 
            className="bg-white rounded-xl p-5 shadow-sm border border-slate-200 hover:shadow-md transition-shadow flex flex-col"
          >
            {/* Top Row: Icon & Status Pill */}
            <div className="flex justify-between items-start mb-4">
              <div className="bg-slate-50 border border-slate-100 p-3 rounded-full shrink-0">
                <TruckIcon className="w-6 h-6 text-slate-500" />
              </div>
              <span className={`px-3 py-1 rounded-full text-[11px] font-bold tracking-wide ${getStatusStyle(vehicle.status)}`}>
                {vehicle.status}
              </span>
            </div>
            
            {/* Vehicle Info */}
            <h3 className="text-lg font-bold text-slate-900 truncate">{vehicle.plate}</h3>
            <p className="text-sm text-slate-500 mt-1 truncate">{vehicle.model}</p>
            
            {/* Stats / Details Section */}
            <div className="mt-5 pt-4 border-t border-slate-100 space-y-3 flex-1">
              
              <div className="flex justify-between items-center">
                <div className="flex items-center gap-2 text-slate-500">
                  <UsersIcon className="w-4 h-4" />
                  <span className="text-xs font-medium">Capacity</span>
                </div>
                <span className="text-sm font-semibold text-slate-700">
                  {vehicle.capacity}
                </span>
              </div>

              <div className="flex justify-between items-center">
                <div className="flex items-center gap-2 text-slate-500">
                  <WrenchScrewdriverIcon className="w-4 h-4" />
                  <span className="text-xs font-medium">Condition</span>
                </div>
                <div className="flex items-center gap-1.5">
                  {vehicle.condition === 'Needs Maintenance' ? (
                    <ExclamationTriangleIcon className="w-4 h-4 text-red-500" />
                  ) : (
                    <CheckBadgeIcon className="w-4 h-4 text-green-500" />
                  )}
                  <span className={`text-sm font-semibold ${vehicle.condition === 'Needs Maintenance' ? 'text-red-600' : 'text-slate-700'}`}>
                    {vehicle.condition}
                  </span>
                </div>
              </div>

            </div>

            {/* Action Button */}
            <button className="w-full mt-5 py-2.5 bg-white border border-slate-200 text-slate-700 hover:bg-slate-50 hover:text-blue-600 text-sm font-semibold rounded-lg transition-colors">
              View Vehicle Logs
            </button>
          </div>
        ))}
      </div>

    </div>
  );
}