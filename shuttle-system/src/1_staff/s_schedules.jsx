import { 
  MapPinIcon, 
  PlusIcon, 
  TruckIcon, 
  UsersIcon, 
  ClockIcon, 
  CalendarDaysIcon 
} from '@heroicons/react/24/outline';

export default function SSchedules() {
  // Mock data representing the Dispatch & Scheduling Matrix requirements
  const activeSchedules = [
    { id: 1, route: "LIMA Estate (EPSON)", shift: "Shift 1", time: "06:00 AM", driver: "Juan Dela Cruz", vehicle: "ABC-1234" },
    { id: 2, route: "Malvar (Bandai Namco)", shift: "Shift 1", time: "06:30 AM", driver: "Ricardo Ramos", vehicle: "XYZ-5678" },
    { id: 3, route: "FPIP (NX Logistics)", shift: "Shift 2", time: "02:00 PM", driver: "Miguel Santos", vehicle: "GHI-9012" },
  ];

  return (
    <div className="p-8 space-y-8 text-left">
      
      {/* 1. Page Header & Primary Action */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <h2 className="text-2xl font-black text-slate-800 uppercase tracking-tight">
          Dispatch & Scheduling
        </h2>
        <button className="flex items-center justify-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-2xl text-xs font-black uppercase tracking-widest transition-all shadow-lg shadow-blue-200">
          <PlusIcon className="w-4 h-4" /> New Dispatch
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* 2. Main Schedule Matrix */}
        <div className="lg:col-span-2 space-y-4">
          <h3 className="px-2 font-black text-slate-800 text-sm uppercase tracking-widest flex items-center gap-2">
            <MapPinIcon className="w-4 h-4 text-blue-600" /> Active Fleet Routes
          </h3>

          <div className="bg-white rounded-3xl shadow-sm border border-slate-100 overflow-hidden">
            <div className="divide-y divide-slate-50">
              {activeSchedules.map((item) => (
                <div key={item.id} className="p-6 hover:bg-slate-50/50 transition-all group">
                  <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                    <div>
                      <p className="text-lg font-black text-slate-800 tracking-tight">{item.route}</p>
                      <div className="flex items-center gap-4 mt-2">
                        <span className="flex items-center gap-1.5 text-[10px] font-black text-blue-600 bg-blue-50 px-2.5 py-1 rounded-full uppercase tracking-widest border border-blue-100">
                          <ClockIcon className="w-3 h-3" /> {item.time}
                        </span>
                        <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{item.shift}</span>
                      </div>
                    </div>

                    <div className="flex items-center gap-6 border-t md:border-t-0 pt-4 md:pt-0">
                      <div className="flex items-center gap-3">
                        <div className="bg-slate-50 p-2.5 rounded-xl group-hover:bg-blue-600 group-hover:text-white transition-colors shadow-inner">
                          <UsersIcon className="w-4 h-4" />
                        </div>
                        <span className="text-xs font-bold text-slate-700">{item.driver}</span>
                      </div>
                      <div className="flex items-center gap-3">
                        <div className="bg-slate-50 p-2.5 rounded-xl group-hover:bg-blue-600 group-hover:text-white transition-colors shadow-inner">
                          <TruckIcon className="w-4 h-4" />
                        </div>
                        <span className="text-xs font-bold text-slate-700">{item.vehicle}</span>
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
           <div className="bg-white p-6 rounded-3xl border border-slate-100 shadow-sm space-y-6">
              <h4 className="font-black text-slate-800 text-xs uppercase tracking-widest">Assignment Status</h4>
              <div className="space-y-4">
                 <div className="flex justify-between items-center py-2 border-b border-slate-50">
                    <span className="text-[11px] font-bold text-slate-400 uppercase">Total Units</span>
                    <span className="text-sm font-black text-slate-800 tracking-tight">18</span>
                 </div>
                 <div className="flex justify-between items-center py-2 border-b border-slate-50">
                    <span className="text-[11px] font-bold text-slate-400 uppercase">Available Drivers</span>
                    <span className="text-sm font-black text-emerald-600 tracking-tight">7</span>
                 </div>
                 <div className="flex justify-between items-center py-2">
                    <span className="text-[11px] font-bold text-slate-400 uppercase">Standby Vehicles</span>
                    <span className="text-sm font-black text-blue-600 tracking-tight">4</span>
                 </div>
              </div>
              <button className="w-full py-3 bg-slate-50 hover:bg-slate-800 hover:text-white text-slate-500 text-[10px] font-black uppercase tracking-widest rounded-2xl transition-all border border-slate-100">
                 Optimize Matrix
              </button>
           </div>

           <div className="bg-blue-600 p-6 rounded-3xl shadow-xl shadow-blue-100 text-white relative overflow-hidden">
              <CalendarDaysIcon className="absolute -right-4 -bottom-4 w-24 h-24 text-white/10 rotate-12" />
              <h4 className="font-black text-xs uppercase tracking-widest mb-2 relative z-10">Shift Continuity</h4>
              <p className="text-[11px] text-blue-100 leading-relaxed relative z-10 font-medium italic">
                The dispatch matrix is currently synced with the LIMA and FPIP estate shift rotations.
              </p>
           </div>
        </div>

      </div>
    </div>
  );
}