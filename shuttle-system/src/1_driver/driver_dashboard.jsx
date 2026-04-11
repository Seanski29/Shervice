import { useState } from 'react';
import { 
  ClockIcon, 
  TruckIcon, 
  MapPinIcon, 
  WrenchScrewdriverIcon, 
  UserCircleIcon,
  HomeIcon,
  CalendarDaysIcon
} from '@heroicons/react/24/outline';
import { CheckBadgeIcon } from '@heroicons/react/24/solid';

export default function DriverDashboard() {
  // State variables for tracking attendance and route progress
  const [isClockedIn, setIsClockedIn] = useState(false);
  const [tripState, setTripState] = useState('Standby'); 

  // Dummy data representing an assigned route from the OIC
  const assignment = {
    client: "EPSON Precision",
    route: "SM Lipa Terminal to LIMA Estate",
    time: "06:00 AM - Shift 1",
    vehicle: "Toyota HiAce (ABC-1234)"
  };

  // Logic to progress the trip status for live logistics tracking
  const handleTripAction = () => {
    if (tripState === 'Standby') setTripState('En Route');
    else if (tripState === 'En Route') setTripState('Completed');
  };

  return (
    // The container is constrained to a mobile width (max-w-md) for desktop viewing, 
    // but expands perfectly on actual smartphone screens.
    <div className="min-h-screen bg-slate-50 font-sans text-slate-800 pb-20 mx-auto max-w-md relative shadow-2xl overflow-hidden border-x border-slate-200">
      
      {/* --- Top Mobile App Bar --- */}
      <header className="bg-emerald-600 text-white px-5 py-4 shadow-md sticky top-0 z-10 flex justify-between items-center">
        <div>
          <h1 className="text-xl font-bold tracking-widest">SHERVICE</h1>
          <p className="text-emerald-100 text-[10px] uppercase tracking-wider">Driver Portal</p>
        </div>
        <div className="flex items-center gap-2 bg-emerald-700/50 px-3 py-1.5 rounded-full">
          <UserCircleIcon className="w-5 h-5" />
          <span className="text-sm font-medium">Juan D.</span>
        </div>
      </header>

      <main className="p-4 space-y-4">
        
        {/* --- Date and Attendance Status --- */}
        <div className="flex justify-between items-end mb-2 px-1">
          <div>
            <p className="text-xs text-slate-500 font-bold uppercase tracking-wider">Today</p>
            <p className="text-lg font-black text-slate-800">
              {new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' })}
            </p>
          </div>
          <div className={`px-3 py-1.5 rounded-full text-[10px] font-bold uppercase tracking-wide flex items-center gap-1.5 shadow-sm ${isClockedIn ? 'bg-emerald-100 text-emerald-700 border border-emerald-200' : 'bg-white text-slate-500 border border-slate-200'}`}>
            <span className={`w-2 h-2 rounded-full ${isClockedIn ? 'bg-emerald-500 animate-pulse' : 'bg-slate-300'}`}></span>
            {isClockedIn ? 'On Duty' : 'Off Duty'}
          </div>
        </div>

        {/* --- Primary Attendance Control --- */}
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-slate-200">
          <h2 className="text-sm font-bold text-slate-800 mb-3 flex items-center gap-2">
            <ClockIcon className="w-5 h-5 text-emerald-600" />
            Digital Attendance Log
          </h2>
          <button 
            onClick={() => setIsClockedIn(!isClockedIn)}
            className={`w-full py-4 rounded-xl text-white font-bold text-sm shadow-md transition-all active:scale-95 flex justify-center items-center gap-2 
              ${isClockedIn ? 'bg-rose-500 hover:bg-rose-600' : 'bg-emerald-600 hover:bg-emerald-700'}`}
          >
            {isClockedIn ? 'Clock Out (End Shift)' : 'Clock In (Start Shift)'}
          </button>
        </div>

        {/* --- Route & Dispatch Assignment --- */}
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-slate-200 relative overflow-hidden">
          <div className="absolute top-0 right-0 bg-blue-600 text-white text-[9px] font-bold px-3 py-1.5 rounded-bl-xl uppercase tracking-wider shadow-sm">
            Next Shift
          </div>
          <h2 className="text-sm font-bold text-slate-800 mb-4 flex items-center gap-2">
            <TruckIcon className="w-5 h-5 text-blue-600" />
            Vehicle Designation
          </h2>

          <div className="space-y-4">
            <div className="flex items-start gap-3">
              <div className="bg-blue-50 p-2 rounded-lg text-blue-600 mt-0.5 shadow-inner">
                <MapPinIcon className="w-4 h-4" />
              </div>
              <div>
                <p className="text-[10px] text-slate-500 font-bold uppercase tracking-wider">Client & Route</p>
                <p className="text-sm font-bold text-slate-800">{assignment.client}</p>
                <p className="text-xs text-slate-600 mt-0.5 leading-snug">{assignment.route}</p>
              </div>
            </div>

            <div className="flex items-start gap-3">
              <div className="bg-blue-50 p-2 rounded-lg text-blue-600 mt-0.5 shadow-inner">
                <ClockIcon className="w-4 h-4" />
              </div>
              <div>
                <p className="text-[10px] text-slate-500 font-bold uppercase tracking-wider">Scheduled Departure</p>
                <p className="text-sm font-bold text-slate-800">{assignment.time}</p>
              </div>
            </div>
            
            <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 flex justify-between items-center">
               <span className="text-xs font-semibold text-slate-600">Assigned Unit:</span>
               <span className="text-xs font-bold text-blue-700 bg-blue-100 px-2 py-1 rounded">{assignment.vehicle}</span>
            </div>
          </div>

          {/* Logistics Action Button */}
          <div className="mt-5 pt-4 border-t border-slate-100">
            <button 
              onClick={handleTripAction}
              disabled={!isClockedIn || tripState === 'Completed'}
              className={`w-full py-4 rounded-xl font-bold text-sm shadow-sm transition-all active:scale-95 flex justify-center items-center gap-2 
                ${!isClockedIn ? 'bg-slate-100 text-slate-400 cursor-not-allowed' 
                : tripState === 'Standby' ? 'bg-blue-600 text-white' 
                : tripState === 'En Route' ? 'bg-amber-500 text-white' 
                : 'bg-emerald-50 text-emerald-700 border border-emerald-200 cursor-not-allowed'}`}
            >
              {tripState === 'Standby' && 'Start Route to LIMA'}
              {tripState === 'En Route' && 'Mark as Arrived'}
              {tripState === 'Completed' && <><CheckBadgeIcon className="w-5 h-5"/> Route Completed</>}
            </button>
          </div>
        </div>

        {/* --- Predictive Maintenance Input --- */}
        <button className="w-full bg-white border border-slate-200 rounded-2xl p-4 shadow-sm flex items-center justify-between active:bg-slate-50 transition-colors group">
          <div className="flex items-center gap-3">
            <div className="bg-amber-50 text-amber-600 p-2 rounded-xl group-hover:bg-amber-100 transition-colors">
              <WrenchScrewdriverIcon className="w-5 h-5" />
            </div>
            <div className="text-left">
              <p className="text-sm font-bold text-slate-800">Report Vehicle Issue</p>
              <p className="text-[10px] text-slate-500 font-medium mt-0.5">Log mechanical health for predictive tracking</p>
            </div>
          </div>
          <span className="text-slate-400 text-lg">→</span>
        </button>

      </main>

      {/* --- Mobile App Bottom Navigation --- */}
      <nav className="absolute bottom-0 w-full bg-white border-t border-slate-200 flex justify-around items-center pb-safe pt-2 px-2 h-16 z-20">
        <button className="flex flex-col items-center p-2 text-emerald-600 transition-colors">
          <HomeIcon className="w-6 h-6" />
          <span className="text-[10px] font-bold mt-1 tracking-wide">Home</span>
        </button>
        <button className="flex flex-col items-center p-2 text-slate-400 hover:text-emerald-600 transition-colors">
          <CalendarDaysIcon className="w-6 h-6" />
          <span className="text-[10px] font-bold mt-1 tracking-wide">Schedule</span>
        </button>
        <button className="flex flex-col items-center p-2 text-slate-400 hover:text-emerald-600 transition-colors">
          <UserCircleIcon className="w-6 h-6" />
          <span className="text-[10px] font-bold mt-1 tracking-wide">Profile</span>
        </button>
      </nav>
      
    </div>
  );
}