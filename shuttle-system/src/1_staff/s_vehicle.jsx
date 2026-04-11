import { TruckIcon } from '@heroicons/react/24/outline';

export default function SVehicle() {
  // Data mapped to the Vehicle Profile and Status Monitoring requirements
  const vehicles = [
    { plate: "ABC-1234", model: "Toyota HiAce", type: "EPSON Route", health: "Good" },
    { plate: "XYZ-9876", model: "Nissan Urvan", type: "Bandai Route", health: "Maintenance Required" }
  ];

  return (
    <div className="p-8 space-y-6 text-left">
      <h2 className="text-2xl font-black text-slate-800 uppercase tracking-tight">
        Vehicle Status & Monitoring
      </h2>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {vehicles.map(v => (
          <div key={v.plate} className="bg-white p-6 rounded-3xl border border-slate-100 shadow-sm flex items-center justify-between hover:shadow-md transition-all">
            <div className="flex items-center gap-4">
              <div className="bg-blue-50 text-blue-600 p-3 rounded-2xl shadow-inner">
                <TruckIcon className="w-6 h-6" />
              </div>
              <div>
                <p className="font-black text-lg text-slate-800 tracking-tight">{v.plate}</p>
                <p className="text-xs font-bold text-slate-400 uppercase tracking-widest">{v.model} | {v.type}</p>
              </div>
            </div>
            
            {/* Visual indicator for Maintenance Tracking requirements */}
            <span className={`text-[10px] font-black px-3 py-1 rounded-full uppercase tracking-tighter shadow-sm border ${
              v.health === 'Good' 
                ? 'bg-emerald-50 text-emerald-700 border-emerald-100' 
                : 'bg-amber-50 text-amber-700 border-amber-100'
            }`}>
              {v.health}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}