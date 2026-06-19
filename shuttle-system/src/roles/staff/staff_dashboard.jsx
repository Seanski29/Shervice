import { ClockIcon, MapPinIcon, WrenchScrewdriverIcon, ChartPieIcon } from '@heroicons/react/24/outline';

export default function DashboardMobile() {
  const topMetrics = [
    { title: "Drivers On-Duty", value: "42/59", icon: ClockIcon, color: "text-emerald-600", bg: "bg-emerald-50" },
    { title: "Active Dispatches", value: "18 Units", icon: MapPinIcon, color: "text-blue-600", bg: "bg-blue-50" },
    { title: "Maintenance Alerts", value: "3 Pending", icon: WrenchScrewdriverIcon, color: "text-amber-600", bg: "bg-amber-50" }
  ];

  return (
    <div className="w-full max-w-md mx-auto p-4 space-y-4 text-left bg-slate-50 min-h-screen">
      
      {/* 1. AI Insights Banner */}
      <section className="bg-white rounded-2xl p-4 border border-blue-50 shadow-sm flex items-start gap-4">
        <div className="bg-blue-600 p-2.5 rounded-xl shadow-md shadow-blue-200 shrink-0">
          <ChartPieIcon className="w-5 h-5 text-white" />
        </div>
        <div>
          <h3 className="font-bold text-sm text-slate-800 tracking-tight">Predictive Analytics Active</h3>
          <p className="text-xs text-slate-500 mt-1 leading-relaxed">
            The analytics engine detects normal operations. 
            <span className="text-blue-600 font-bold block mt-1 active:text-blue-800 transition-colors">Review forecasts.</span>
          </p>
        </div>
      </section>

      {/* 2. Key Metrics List (Optimized for Vertical Scrolling) */}
      <div className="flex flex-col gap-3">
        {topMetrics.map((metric, idx) => (
          <div 
            key={idx} 
            className="bg-white rounded-2xl p-4 shadow-sm border border-slate-50 flex items-center justify-between active:scale-[0.98] active:bg-slate-50 transition-all cursor-pointer"
          >
            <div>
              <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{metric.title}</p>
              <p className="text-2xl font-black mt-1 text-slate-800 tracking-tighter">{metric.value}</p>
            </div>
            <div className={`${metric.bg} ${metric.color} w-12 h-12 flex items-center justify-center rounded-xl shrink-0`}>
              <metric.icon className="w-6 h-6" />
            </div>
          </div>
        ))}
      </div>

    </div>
  );
}