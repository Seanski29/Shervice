import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import Sidebar from './sidebar';
import { Bars3Icon, UserCircleIcon } from '@heroicons/react/24/outline';

export default function MainLayout() {
  const [isSidebarOpen, setIsSidebarOpen] = useState(() => {
  const saved = localStorage.getItem('sidebar-state');
  return saved !== null ? JSON.parse(saved) : true;
});

  return (
    <div className="flex min-h-screen bg-[#F8FAFC] font-sans text-slate-900 overflow-hidden">
      <Sidebar isSidebarOpen={isSidebarOpen} />
      
      <main className="flex-1 flex flex-col h-screen overflow-hidden">
        <header className="bg-white/90 backdrop-blur-md px-8 py-4 flex items-center justify-between border-b border-slate-200 shadow-sm z-20">
          <div className="flex items-center gap-4">
            <button onClick={() => setIsSidebarOpen(!isSidebarOpen)} className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
              <Bars3Icon className="w-5 h-5 text-slate-500" />
            </button>
            <h2 className="text-lg font-bold tracking-tight text-slate-700 uppercase">Shervice Portal</h2>
          </div>
          <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center text-white shadow-md">
            <UserCircleIcon className="w-6 h-6" />
          </div>
        </header>

        {/* This "Outlet" is where your specific pages (Driver, Vehicle, etc.) will appear */}
        <div className="flex-1 overflow-y-auto custom-scrollbar">
          <Outlet />
        </div>
      </main>
    </div>
  );
}