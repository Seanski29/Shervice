import React from 'react';
import { 
  UsersIcon, 
  TruckIcon, 
  StarIcon, 
  ExclamationTriangleIcon,
  WrenchScrewdriverIcon,
  BuildingOfficeIcon
} from '@heroicons/react/24/outline';

export default function StaffDashboard() {
  // KPI Data matching the Flutter layout
  const topMetrics = [
    { title: "Active Drivers", value: "42", subtitle: "Out of 59 total", icon: UsersIcon, color: "text-blue-600", bg: "bg-blue-50", border: "border-blue-100" },
    { title: "Active Vehicles", value: "38", subtitle: "Currently on route", icon: TruckIcon, color: "text-green-600", bg: "bg-green-50", border: "border-green-100" },
    { title: "Avg Punctuality", value: "4.8", subtitle: "Out of 5.0 rating", icon: StarIcon, color: "text-orange-500", bg: "bg-orange-50", border: "border-orange-100" },
    { title: "Maintenance Alerts", value: "3", subtitle: "Requires attention", icon: ExclamationTriangleIcon, color: "text-red-600", bg: "bg-red-50", border: "border-red-100" }
  ];

  // Predictive Alerts Data
  const maintenanceAlerts = [
    { vehicleId: 'GT-VAN-014', issue: 'Brake Pad Wear', daysLeft: 2, urgency: 'w-[90%]', color: 'bg-red-500', iconColor: 'text-red-600', iconBg: 'bg-red-50' },
    { vehicleId: 'GT-VAN-008', issue: 'Transmission Fluid', daysLeft: 5, urgency: 'w-[75%]', color: 'bg-orange-500', iconColor: 'text-orange-600', iconBg: 'bg-orange-50' },
    { vehicleId: 'GT-VAN-022', issue: 'Battery Life Depletion', daysLeft: 12, urgency: 'w-[40%]', color: 'bg-amber-500', iconColor: 'text-amber-600', iconBg: 'bg-amber-50' }
  ];

  // Company Trips Data
  const companyTrips = [
    { company: 'Bandai Namco', trips: '5,250 Trips', utilization: 'w-[95%]', color: 'bg-orange-500', iconColor: 'text-orange-600', iconBg: 'bg-orange-50' },
    { company: 'EPSON', trips: '5,000 Trips', utilization: 'w-[90%]', color: 'bg-blue-600', iconColor: 'text-blue-700', iconBg: 'bg-blue-50' },
    { company: 'NX Logistics', trips: '2,100 Trips', utilization: 'w-[40%]', color: 'bg-green-500', iconColor: 'text-green-600', iconBg: 'bg-green-50' }
  ];

  return (
    <div className="w-full min-h-screen bg-[#F8FAFC] p-4 md:p-8 text-left">
      
      {/* Page Header */}
      <h1 className="text-2xl font-bold text-slate-900 tracking-tight mb-6">
        Fleet Overview
      </h1>

      {/* 1. KPI Grid (Responsive: 1 col mobile, 2 col tablet, 4 col desktop) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        {topMetrics.map((metric, idx) => {
          // SAFE RENDERING: Assign to capitalized variable to prevent React white-screen crash
          const IconComponent = metric.icon; 
          
          return (
            <div key={idx} className="bg-white rounded-xl p-4 shadow-sm border border-slate-200 flex flex-col">
              <div className="flex justify-between items-start mb-2">
                <p className="text-xs font-semibold text-slate-500 truncate pr-2">
                  {metric.title}
                </p>
                <div className={`${metric.bg} ${metric.color} p-1.5 rounded-md shrink-0`}>
                  <IconComponent className="w-4 h-4" />
                </div>
              </div>
              <p className="text-2xl font-bold text-slate-900">
                {metric.value}
              </p>
              <p className="text-[11px] text-slate-500 truncate mt-0.5">
                {metric.subtitle}
              </p>
            </div>
          );
        })}
      </div>

      {/* 2. Predictive Maintenance Card */}
      <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm mb-6">
        <div className="flex flex-wrap items-center justify-between gap-3 mb-6">
          <h2 className="text-base font-bold text-slate-900">Predictive Maintenance Alerts</h2>
          <span className="bg-blue-50 text-blue-600 text-[11px] font-bold px-3 py-1 rounded-full">
            Linear Regression Active
          </span>
        </div>

        <div className="space-y-3">
          {maintenanceAlerts.map((alert, idx) => (
            <div key={idx} className="flex items-center p-3 rounded-lg border border-slate-100 bg-slate-50">
              <div className={`${alert.iconBg} p-2 rounded-md shrink-0`}>
                <WrenchScrewdriverIcon className={`w-5 h-5 ${alert.iconColor}`} />
              </div>
              
              <div className="ml-3 flex-1 min-w-0">
                <p className="text-sm font-bold text-slate-900 truncate">{alert.vehicleId}</p>
                <p className="text-[11px] text-slate-600 truncate mb-1.5">Issue: {alert.issue}</p>
                {/* Progress Bar */}
                <div className="w-full bg-slate-200 rounded-full h-1.5 overflow-hidden">
                  <div className={`${alert.color} h-1.5 rounded-full ${alert.urgency}`}></div>
                </div>
              </div>

              <div className="ml-3 shrink-0 text-right">
                <p className={`text-[13px] font-bold ${alert.iconColor}`}>{alert.daysLeft} Days</p>
                <p className="text-[10px] text-slate-500">Left</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* 3. Trips Done Per Company Card */}
      <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
        <h2 className="text-base font-bold text-slate-900 mb-5">Weekly Passenger Trips by Client</h2>
        
        <div className="space-y-0">
          {companyTrips.map((client, idx) => (
            <React.Fragment key={idx}>
              <div className="flex items-center py-2">
                <div className={`${client.iconBg} p-2 rounded-md shrink-0`}>
                  <BuildingOfficeIcon className={`w-5 h-5 ${client.iconColor}`} />
                </div>
                
                <div className="ml-3 flex-1 min-w-0">
                  <p className="text-sm font-bold text-slate-900 truncate mb-1.5">{client.company}</p>
                  {/* Progress Bar */}
                  <div className="w-full bg-slate-200 rounded-full h-1.5 overflow-hidden">
                    <div className={`${client.color} h-1.5 rounded-full ${client.utilization}`}></div>
                  </div>
                </div>

                <div className="ml-4 shrink-0 bg-slate-100 px-3 py-1 rounded-lg border border-slate-200">
                  <p className="text-xs font-bold text-slate-700">{client.trips}</p>
                </div>
              </div>
              
              {/* Add a divider between items, but not after the last one */}
              {idx !== companyTrips.length - 1 && (
                <hr className="my-2 border-slate-100" />
              )}
            </React.Fragment>
          ))}
        </div>
      </div>

    </div>
  );
}