import { useState } from 'react';
import { Link } from 'react-router-dom';
import brandLogo from '../assets/GT LANTIN CAR RENTALS.jpg';

// Imported specific Heroicons based on the Shervice Documentation requirements
import { 
  HomeIcon, 
  TruckIcon, 
  UsersIcon, 
  CalendarDaysIcon, 
  WrenchScrewdriverIcon, 
  Bars3Icon,
  ChatBubbleBottomCenterTextIcon,
  DocumentChartBarIcon,
  MapPinIcon,
  ClockIcon,
  ChartPieIcon
} from '@heroicons/react/24/outline';

export default function Dashboard() {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);

  // Scaled-down UI elements matching the exact Shervice KPIs
  const topMetrics = [
    { title: "Drivers On-Duty (Attendance)", value: "42/59", icon: ClockIcon, color: "bg-emerald-500" },
    { title: "Active Dispatches (Epson/Bandai)", value: "18", icon: MapPinIcon, color: "bg-blue-600" },
    { title: "Pending Maintenance Forecasts", value: "3", icon: WrenchScrewdriverIcon, color: "bg-amber-500" }
  ];

  // Quick actions mapped to Staff and Admin functional requirements
  const quickActions = [
    { title: "Assign Driver/Vehicle Route", desc: "Allocate a shuttle unit to a specific corporate client shift.", icon: CalendarDaysIcon },
    { title: "Review Passenger Feedback", desc: "Analyze anonymous QR-code ratings for driver safety and attitude.", icon: ChatBubbleBottomCenterTextIcon },
    { title: "Update Maintenance Logs", desc: "Input repair costs and dates for predictive algorithm processing.", icon: WrenchScrewdriverIcon },
    { title: "Generate Utilization Report", desc: "Export historical data for driver punctuality and fleet efficiency.", icon: DocumentChartBarIcon }
  ];

  // Sidebar navigation mapped directly to the functional modules
 const sidebarNavigation = [
    { name: "Overview Dashboard", icon: HomeIcon, path: "/dashboard" },
    { name: "Driver Profiles", icon: UsersIcon, path: "/driver_dashboard" }, // Routes to the Driver Dashboard
    { name: "Vehicle Monitoring", icon: TruckIcon, path: "#" },
    { name: "Attendance Tracking", icon: ClockIcon, path: "#" },
    { name: "Dispatch & Scheduling", icon: CalendarDaysIcon, path: "#" },
    { name: "Maintenance Logs", icon: WrenchScrewdriverIcon, path: "#" },
    { name: "Passenger Feedback", icon: ChatBubbleBottomCenterTextIcon, path: "#" },
    { name: "Predictive Analytics", icon: ChartPieIcon, path: "#" }
  ];

  return (
    <div className="flex min-h-screen bg-slate-50 font-sans text-slate-800">
      
      {/* --- Sidebar --- */}
      <aside className={`${isSidebarOpen ? 'w-60' : 'w-16'} bg-blue-800 text-white flex flex-col shadow-xl transition-all duration-300 ease-in-out relative z-10`}>
        <div className={`p-4 flex items-center ${isSidebarOpen ? 'justify-start gap-3' : 'justify-center'} border-b border-blue-700/50 min-h-[72px]`}>
          <img src={brandLogo} alt="Logo" className="h-8 w-8 rounded-full bg-white p-0.5 flex-shrink-0 shadow-sm" />
          {isSidebarOpen && <h1 className="text-lg font-bold tracking-wide whitespace-nowrap">SHERVICE</h1>}
        </div>

        <nav className="flex-1 px-2 py-4 space-y-1 overflow-hidden">
          {sidebarNavigation.map((item, index) => (
           <Link 
              key={index} 
              to={item.path}
              className={`flex items-center ${isSidebarOpen ? 'justify-start px-3' : 'justify-center'} py-2.5 hover:bg-white/10 rounded-lg cursor-pointer transition-colors group`}
              title={item.name}
            >
              <item.icon className="w-5 h-5 text-blue-200 group-hover:text-white group-hover:scale-110 transition-all flex-shrink-0" />
              {isSidebarOpen && <span className="ml-3 text-sm font-medium whitespace-nowrap text-blue-50 group-hover:text-white">{item.name}</span>}
            </Link>
          ))}
        </nav>

        <div className={`p-3 border-t border-blue-700/50 flex items-center ${isSidebarOpen ? 'justify-start gap-3' : 'justify-center'}`}>
          <div className="h-8 w-8 rounded-full bg-emerald-500 flex items-center justify-center text-xs font-bold shadow-sm">AD</div>
          {isSidebarOpen && (
            <div className="flex flex-col">
              <span className="text-xs font-bold text-white">Admin User</span>
              <span className="text-[10px] text-blue-300 uppercase tracking-wider">GT Lantin</span>
            </div>
          )}
        </div>
      </aside>

      {/* --- Main Content Area --- */}
      <main className="flex-1 flex flex-col overflow-y-auto">
        
        <header className="bg-white shadow-sm px-6 py-3 flex items-center justify-between sticky top-0 z-0">
          <div className="flex items-center gap-4">
            <button 
              onClick={() => setIsSidebarOpen(!isSidebarOpen)}
              className="p-1.5 hover:bg-slate-100 rounded-md transition-colors focus:outline-none"
            >
              <Bars3Icon className="w-5 h-5 text-slate-600" />
            </button>
            <h2 className="text-xl font-bold text-slate-800 tracking-tight">Administrative Overview</h2>
          </div>
          
          <div className="text-xs font-semibold text-slate-500 bg-slate-100 px-3 py-1.5 rounded-md border border-slate-200">
            {new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric', year: 'numeric' })}
          </div>
        </header>

        <div className="p-6 max-w-6xl mx-auto w-full flex flex-col gap-6">
          
          <div className="bg-gradient-to-r from-blue-800 to-blue-600 rounded-xl p-6 text-white shadow-md relative overflow-hidden">
            <div className="relative z-10">
              <h3 className="text-2xl font-bold mb-1">Fleet Operations Normal</h3>
              <p className="text-blue-100 text-sm max-w-2xl">
                AI Overview: The predictive analytics engine detects no immediate route delay clusters. 
                Please review the 3 pending maintenance forecasts to prevent operational downtime.
              </p>
            </div>
            <div className="absolute -right-10 -top-10 w-48 h-48 bg-white/10 rounded-full blur-2xl"></div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {topMetrics.map((metric, idx) => (
              <div key={idx} className="bg-white rounded-xl p-5 shadow-sm border border-slate-200 flex items-center gap-4 hover:shadow transition-shadow cursor-default">
                <div className={`${metric.color} text-white h-10 w-10 flex items-center justify-center rounded-lg shadow-inner flex-shrink-0`}>
                  <metric.icon className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-slate-500 text-xs font-semibold uppercase tracking-wide">{metric.title}</p>
                  <p className="text-2xl font-bold text-slate-800 mt-0.5">{metric.value}</p>
                </div>
              </div>
            ))}
          </div>

          <div>
            <h4 className="text-base font-bold text-slate-800 mb-3 px-1">Operational Quick Actions</h4>
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
              {quickActions.map((action, idx) => (
                <button key={idx} className="group bg-white border border-slate-200 rounded-xl p-4 text-left shadow-sm hover:shadow-md hover:border-blue-400 transition-all duration-200 flex items-start gap-3 transform hover:-translate-y-0.5">
                  <div className="bg-slate-50 border border-slate-100 h-10 w-10 flex items-center justify-center rounded-lg group-hover:bg-blue-50 group-hover:text-blue-700 transition-colors flex-shrink-0 text-slate-600">
                    <action.icon className="w-5 h-5" />
                  </div>
                  <div>
                    <h5 className="text-sm font-bold text-slate-800 group-hover:text-blue-700 transition-colors">{action.title}</h5>
                    <p className="text-slate-500 text-xs mt-1 leading-relaxed">{action.desc}</p>
                  </div>
                </button>
              ))}
            </div>
          </div>

        </div>
      </main>

    </div>
  );
}