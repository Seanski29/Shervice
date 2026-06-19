import { 
  CheckCircleIcon, 
  ExclamationCircleIcon, 
  MagnifyingGlassIcon 
} from '@heroicons/react/24/outline';

export default function SAttendance() {
  // Mock data representing real-time logs for the GT LANTIN dispatch schedule
  const attendanceLogs = [
    { id: 1, name: "Juan Dela Cruz", initials: "JD", time: "05:48 AM", status: "On-Time", route: "EPSON - Shift A" },
    { id: 2, name: "Ricardo Ramos", initials: "RR", time: "06:02 AM", status: "Late", route: "Bandai - Shift A" },
    { id: 3, name: "Miguel Santos", initials: "MS", time: "05:55 AM", status: "On-Time", route: "NX Logistics" },
    { id: 4, name: "Antonio Luna", initials: "AL", time: "05:30 AM", status: "On-Time", route: "EPSON - Shift B" },
  ];

  return (
    <div className="p-8 space-y-6 text-left">
      
      {/* 1. Header & Quick Stats */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h2 className="text-2xl font-black text-slate-800 uppercase tracking-tight">Attendance Monitoring</h2>
          <p className="text-xs text-slate-500 mt-1 font-medium italic">
            Showing real-time logs for {new Date().toLocaleDateString()}
          </p>
        </div>
        
        <div className="flex gap-4">
          <div className="bg-white px-4 py-2 rounded-2xl border border-slate-100 shadow-sm">
            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider leading-none">Present</p>
            <p className="text-lg font-black text-slate-800">42/59</p>
          </div>
          <div className="bg-white px-4 py-2 rounded-2xl border border-slate-100 shadow-sm">
            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider leading-none">On-Time</p>
            <p className="text-lg font-black text-emerald-600">92%</p>
          </div>
        </div>
      </div>

      {/* 2. Daily Log Feed */}
      <div className="bg-white rounded-3xl shadow-sm border border-slate-100 overflow-hidden">
        <div className="p-6 border-b border-slate-50 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
          <h3 className="font-black text-slate-800 tracking-tight uppercase text-sm">Daily Log Feed</h3>
          <div className="relative w-full sm:w-64">
            <span className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <MagnifyingGlassIcon className="h-4 w-4 text-slate-400" />
            </span>
            <input 
              type="text" 
              className="block w-full pl-9 pr-3 py-2.5 border border-slate-200 rounded-2xl text-xs font-medium focus:ring-2 focus:ring-blue-500 focus:outline-none transition-all shadow-sm" 
              placeholder="Filter by driver name..."
            />
          </div>
        </div>

        <div className="divide-y divide-slate-50">
          {attendanceLogs.map((log) => (
            <div key={log.id} className="flex items-center justify-between p-5 hover:bg-slate-50/50 transition-colors group">
              <div className="flex items-center gap-4">
                <div className="w-10 h-10 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center text-sm font-black shadow-inner group-hover:bg-blue-600 group-hover:text-white transition-all">
                  {log.initials}
                </div>
                <div>
                  <p className="text-sm font-bold text-slate-800 tracking-tight">{log.name}</p>
                  <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">{log.route}</p>
                </div>
              </div>
              
              <div className="flex flex-col items-end gap-1">
                <div className="flex items-center gap-1.5">
                  {log.status === 'On-Time' ? (
                    <CheckCircleIcon className="w-4 h-4 text-emerald-500" />
                  ) : (
                    <ExclamationCircleIcon className="w-4 h-4 text-amber-500" />
                  )}
                  <span className={`text-[10px] font-black uppercase tracking-tighter ${
                    log.status === 'On-Time' ? 'text-emerald-600' : 'text-amber-600'
                  }`}>
                    {log.status}
                  </span>
                </div>
                <span className="text-xs font-bold text-slate-500 tracking-tight">{log.time}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

    </div>
  );
}