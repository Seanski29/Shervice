import { 
  ChartPieIcon, 
  ArrowTrendingUpIcon, 
  BeakerIcon, 
  CpuChipIcon, 
  ArrowPathIcon 
} from '@heroicons/react/24/outline';

export default function SAnalytics() {
  // KPIs derived from your ML Pipeline objectives
  const analyticsMetrics = [
    { title: "Model Accuracy", value: "94.2%", desc: "Random Forest Classifier", color: "text-blue-600" },
    { title: "Avg. Maintenance Error", value: "1.2 Days", desc: "Mean Absolute Error (MAE)", color: "text-amber-600" },
    { title: "Route Delay Clusters", value: "4 Active", icon: CpuChipIcon, color: "text-emerald-600" }
  ];

  return (
    <div className="p-8 space-y-8 text-left">
      
      {/* 1. Page Title */}
      <h2 className="text-2xl font-black text-slate-800 uppercase tracking-tight">
        Predictive Intelligence
      </h2>
      
      {/* 2. Top Level ML Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {analyticsMetrics.map((metric, idx) => (
          <div key={idx} className="bg-white p-6 rounded-3xl border border-slate-100 shadow-sm">
            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">{metric.title}</p>
            <p className={`text-2xl font-black mt-1 ${metric.color}`}>{metric.value}</p>
            {metric.desc && <p className="text-[10px] text-slate-400 mt-1 font-medium italic">{metric.desc}</p>}
          </div>
        ))}
      </div>

      {/* 3. Visualization Placeholders */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        
        {/* Driver Performance (Random Forest) */}
        <div className="bg-white p-8 rounded-3xl border border-slate-100 shadow-sm flex flex-col items-center justify-center min-h-[350px] group hover:border-blue-200 transition-all">
          <div className="p-4 bg-blue-50 rounded-2xl mb-4 group-hover:scale-110 transition-transform">
            <ChartPieIcon className="w-12 h-12 text-blue-600" />
          </div>
          <h4 className="font-black text-slate-800 tracking-tight text-lg text-center">Driver Reliability Distribution</h4>
          <p className="text-slate-400 text-xs font-bold uppercase mt-2 tracking-widest text-center">Random Forest Classification</p>
          <div className="mt-8 flex gap-2">
             <div className="h-2 w-12 bg-emerald-400 rounded-full shadow-sm shadow-emerald-200"></div>
             <div className="h-2 w-8 bg-slate-100 rounded-full"></div>
             <div className="h-2 w-4 bg-rose-400 rounded-full shadow-sm shadow-rose-200"></div>
          </div>
        </div>

        {/* Maintenance Trends (Multiple Linear Regression) */}
        <div className="bg-white p-8 rounded-3xl border border-slate-100 shadow-sm flex flex-col items-center justify-center min-h-[350px] group hover:border-amber-200 transition-all">
          <div className="p-4 bg-amber-50 rounded-2xl mb-4 group-hover:scale-110 transition-transform">
            <ArrowTrendingUpIcon className="w-12 h-12 text-amber-600" />
          </div>
          <h4 className="font-black text-slate-800 tracking-tight text-lg text-center">Predictive Maintenance Cycle</h4>
          <p className="text-slate-400 text-xs font-bold uppercase mt-2 tracking-widest text-center">Linear Regression Analysis</p>
          <div className="mt-8 w-32 h-1.5 bg-slate-100 relative overflow-hidden rounded-full">
             <div className="absolute inset-0 bg-amber-400 w-2/3 transition-all duration-1000"></div>
          </div>
        </div>

        {/* Route Bottlenecks (K-Means Clustering) */}
        <div className="bg-white p-8 rounded-3xl border border-slate-100 shadow-sm flex flex-col items-center justify-center min-h-[350px] lg:col-span-2 group hover:border-emerald-200 transition-all">
           <div className="p-4 bg-emerald-50 rounded-2xl mb-4 group-hover:scale-110 transition-transform">
              <BeakerIcon className="w-12 h-12 text-emerald-600" />
           </div>
           <h4 className="font-black text-slate-800 tracking-tight text-lg text-center">Route Delay Bottleneck Analysis</h4>
           <p className="text-slate-400 text-xs font-bold uppercase mt-2 tracking-widest text-center">Unsupervised K-Means Clustering</p>
           <div className="mt-6 flex gap-4 opacity-40">
              <div className="w-4 h-4 rounded-full bg-emerald-500 shadow-sm"></div>
              <div className="w-4 h-4 rounded-full bg-blue-500 translate-y-4 shadow-sm"></div>
              <div className="w-4 h-4 rounded-full bg-amber-500 -translate-y-2 shadow-sm"></div>
           </div>
        </div>

      </div>

      {/* 4. Model Status Bar */}
      <div className="bg-slate-800 rounded-2xl p-4 flex items-center justify-between shadow-lg shadow-slate-200">
         <div className="flex items-center gap-3">
            <ArrowPathIcon className="w-4 h-4 text-blue-400 animate-spin" />
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Training datasets re-syncing...</span>
         </div>
         <span className="text-[10px] font-black text-white uppercase tracking-widest opacity-60">Version 1.0.4-ML</span>
      </div>

    </div>
  );
}