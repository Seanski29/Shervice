import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import { Bars3Icon } from '@heroicons/react/24/outline';
import { useAuth } from '../context/AuthContext';
import StaffSidebar from './sidebars/StaffSidebar';
import OicSidebar from './sidebars/OicSidebar';
import AdminSidebar from './sidebars/AdminSidebar';

export default function MainLayout() {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const { user } = useAuth();

  const renderSidebar = () => {
    switch (user?.role) {
      case 'admin': return <AdminSidebar isSidebarOpen={isSidebarOpen} />;
      case 'oic':   return <OicSidebar isSidebarOpen={isSidebarOpen} />;
      default:      return <StaffSidebar isSidebarOpen={isSidebarOpen} />;
    }
  };

  return (
    <div className="flex h-screen bg-slate-50 overflow-hidden">

      {/* Correct sidebar renders based on who is logged in */}
      {renderSidebar()}

      <div className="flex flex-col flex-1 overflow-hidden">

        {/* Top Header Bar */}
        <header className="h-16 bg-white border-b border-slate-200
                           flex items-center px-6 gap-4 
                           shadow-sm flex-shrink-0">

          {/* Hamburger toggle — opens/closes the sidebar */}
          <button
            onClick={() => setIsSidebarOpen(!isSidebarOpen)}
            className="p-2 rounded-lg hover:bg-slate-100 transition-colors"
          >
            <Bars3Icon className="w-5 h-5 text-slate-600" />
          </button>

          {/* Pushes user info to the right */}
          <div className="flex-1" />

          {/* Logged-in user pill */}
          <div className="flex items-center gap-3 bg-slate-50
                          px-4 py-2 rounded-full border border-slate-200">
            <div className="w-7 h-7 rounded-full bg-blue-600
                            flex items-center justify-center
                            text-white text-xs font-bold">
              {user?.name?.charAt(0) ?? 'U'}
            </div>
            <div className="text-sm">
              <p className="font-semibold text-slate-700 leading-none">
                {user?.name}
              </p>
              <p className="text-xs text-slate-400 capitalize leading-none mt-0.5">
                {user?.role}
              </p>
            </div>
          </div>
        </header>

        {/* 
          This is where React Router renders the current page.
          Think of it as a picture frame — the sidebar and header
          stay still, only what's inside this frame changes.
        */}
        <main className="flex-1 overflow-y-auto">
          <Outlet />
        </main>

      </div>
    </div>
  );
}