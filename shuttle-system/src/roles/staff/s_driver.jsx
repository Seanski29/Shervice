import { 
  UsersIcon, 
  IdentificationIcon, 
  PlusIcon, 
  MagnifyingGlassIcon 
} from '@heroicons/react/24/outline';

export default function SDriver() {
  // Mock data mapped to Shervice Driver Record requirements
  const drivers = [
    { id: 1, empId: "DRV-2026-001", name: "Juan Dela Cruz", performance: "Highly Reliable", licenseExpiry: "2027-05-20", status: "On-Duty" },
    { id: 2, empId: "DRV-2026-042", name: "Ricardo Ramos", performance: "Highly Reliable", licenseExpiry: "2026-11-15", status: "On-Duty" },
    { id: 3, empId: "DRV-2026-089", name: "Mateo San Jose", performance: "Needs Improvement", licenseExpiry: "2026-08-10", status: "Off-Duty" },
  ];

  return (
    <div className="p-8 space-y-6 text-left">
      
      {/* 1. Page Title & Action Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <h2 className="text-2xl font-black text-slate-800 uppercase tracking-tight">
          Driver Management
        </h2>
        <button className="flex items-center justify-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-2xl text-xs font-black uppercase tracking-widest transition-all shadow-lg shadow-blue-200">
          <PlusIcon className="w-4 h-4" /> Add Driver
        </button>
      </div>

      {/* 2. Search Utility */}
      <div className="relative max-w-md">
        <span className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <MagnifyingGlassIcon className="h-5 w-5 text-slate-400" />
        </span>
        <input 
          type="text" 
          className="block w-full pl-10 pr-3 py-3 border border-slate-200 rounded-2xl leading-5 bg-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 sm:text-sm transition-all shadow-sm" 
          placeholder="Search driver by name or ID..."
        />
      </div>

      {/* 3. Driver Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {drivers.map((driver) => (
          <div key={driver.id} className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100 hover:shadow-md transition-all group">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-blue-50 text-blue-600 p-3 rounded-2xl group-hover:bg-blue-600 group-hover:text-white transition-colors shadow-inner">
                <UsersIcon className="w-6 h-6" />
              </div>
              <span className={`px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-tighter border ${
                driver.performance === 'Highly Reliable' 
                  ? 'bg-emerald-50 text-emerald-700 border-emerald-100' 
                  : 'bg-rose-50 text-rose-700 border-rose-100'
              }`}>
                {driver.performance}
              </span>
            </div>
            
            <h3 className="text-xl font-black text-slate-800 tracking-tight">{driver.name}</h3>
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest flex items-center gap-1.5 mt-1">
              <IdentificationIcon className="w-4 h-4" /> {driver.empId}
            </p>
            
            <div className="mt-6 pt-4 border-t border-slate-50 space-y-2">
              <div className="flex justify-between text-[11px] font-bold">
                <span className="text-slate-400 uppercase">License Expiry:</span>
                <span className="text-slate-700">{driver.licenseExpiry}</span>
              </div>
              <div className="flex justify-between text-[11px] font-bold">
                <span className="text-slate-400 uppercase">Status:</span>
                <span className={driver.status === 'On-Duty' ? 'text-emerald-600' : 'text-slate-400'}>
                  {driver.status}
                </span>
              </div>
            </div>

            <button className="w-full mt-6 py-3 bg-slate-50 hover:bg-blue-50 text-slate-500 hover:text-blue-600 text-[10px] font-black rounded-2xl border border-slate-100 transition-colors uppercase tracking-widest">
              View Full Profile
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}