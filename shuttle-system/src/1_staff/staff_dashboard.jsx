import { ClockIcon, MapPinIcon, WrenchScrewdriverIcon, ChartPieIcon } from '@heroicons/react/24/outline';

export default function Dashboard() {
  // Metrics specific to the Staff Overview
  const topMetrics = [
    { title: "Drivers On-Duty", value: "42/59", icon: ClockIcon, color: "text-emerald-600", bg: "bg-emerald-50" },
    { title: "Active Dispatches", value: "18 Units", icon: MapPinIcon, color: "text-blue-600", bg: "bg-blue-50" },
    { title: "Maintenance Alerts", value: "3 Pending", icon: WrenchScrewdriverIcon, color: "text-amber-600", bg: "bg-amber-50" }
  ];

  return (
    <div className="p-8 space-y-8 text-left">
      
      {/* 1. AI Insights Banner */}
      <section className="bg-white rounded-3xl p-6 border border-blue-50 shadow-sm flex items-center gap-6">
        <div className="bg-blue-600 p-3 rounded-2xl shadow-lg shadow-blue-200">
          <ChartPieIcon className="w-6 h-6 text-white" />
        </div>
        <div>
          <h3 className="font-black text-slate-800 tracking-tight">Predictive Analytics Active</h3>
          <p className="text-sm text-slate-500 mt-1">
            The analytics engine detects normal operations. 
            <span className="text-blue-600 font-bold hover:underline cursor-pointer ml-1">Review maintenance forecasts</span>.
          </p>
        </div>
      </section>

      {/* 2. Key Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {topMetrics.map((metric, idx) => (
          <div key={idx} className="bg-white rounded-3xl p-6 shadow-sm border border-slate-50 hover:shadow-md transition-all group">
            <div className={`${metric.bg} ${metric.color} w-10 h-10 flex items-center justify-center rounded-2xl mb-4 group-hover:scale-110 transition-transform shadow-inner`}>
              <metric.icon className="w-5 h-5" />
            </div>
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{metric.title}</p>
            <p className="text-3xl font-black mt-1 text-slate-800 tracking-tighter">{metric.value}</p>
          </div>
        ))}
      </div>

    </div>
  );
}