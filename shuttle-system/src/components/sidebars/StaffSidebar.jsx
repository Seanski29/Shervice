import React from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import brandLogo from '../../assets/GT LANTIN CAR RENTALS.jpg';
import {
  HomeIcon,
  TruckIcon,
  UsersIcon,
  CalendarDaysIcon,
  ChartPieIcon,
  ArrowLeftOnRectangleIcon,
  ClockIcon,
} from '@heroicons/react/24/outline';

export default function StaffSidebar({ isSidebarOpen }) {
  const navigate = useNavigate();
  const location = useLocation();
  const { logout } = useAuth();

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  const navItems = [
    { name: 'Overview',        icon: HomeIcon,         path: '/staff_dashboard' },
    { name: 'Driver Profiles', icon: UsersIcon,        path: '/driver-profile' },
    { name: 'Vehicle Status',  icon: TruckIcon,        path: '/vehicle-status' },
    { name: 'Attendance',      icon: ClockIcon,        path: '/attendance' },
    { name: 'Schedules',       icon: CalendarDaysIcon, path: '/schedules' },
    { name: 'Analytics',       icon: ChartPieIcon,     path: '/analytics' },
  ];

  return (
    <aside 
      className={`
        ${isSidebarOpen ? 'w-72' : 'w-20'} 
        bg-[#0F172A] flex flex-col h-screen sticky top-0 z-30 
        transition-all duration-300 ease-in-out border-r border-slate-800 shadow-2xl
      `}
    >
      {/* Brand & Logo Section */}
      <div className="h-20 flex items-center px-5 border-b border-slate-800/60 shrink-0">
        <div className={`flex items-center gap-4 w-full ${!isSidebarOpen && 'justify-center'}`}>
          <div className="relative flex-shrink-0">
            <div className="absolute inset-0 bg-blue-500 rounded-lg blur opacity-20"></div>
            <img
              src={brandLogo}
              alt="GT Lantin Logo"
              className="relative h-10 w-10 rounded-lg bg-white p-0.5 object-contain shadow-sm"
            />
          </div>
          
          <div 
            className={`flex flex-col overflow-hidden transition-all duration-300 whitespace-nowrap
              ${isSidebarOpen ? 'opacity-100 w-auto translate-x-0' : 'opacity-0 w-0 -translate-x-4'}
            `}
          >
            <span className="font-black text-white tracking-tight italic text-lg leading-tight">
              SHERVICE
            </span>
            <span className="text-[11px] font-bold text-blue-400 uppercase tracking-widest">
              Staff Portal
            </span>
          </div>
        </div>
      </div>

      {/* Navigation Links */}
      <nav className="flex-1 px-3 py-6 space-y-1.5 overflow-y-auto scrollbar-hide">
        {navItems.map((item) => {
          const isActive = location.pathname === item.path;
          
          return (
            <Link
              key={item.name}
              to={item.path}
              title={!isSidebarOpen ? item.name : undefined}
              className={`
                group flex items-center px-3 py-3 rounded-xl transition-all duration-200 cursor-pointer
                ${isActive 
                  ? 'bg-blue-600 text-white shadow-md shadow-blue-900/20' 
                  : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'
                }
              `}
            >
              <item.icon 
                className={`
                  w-5 h-5 flex-shrink-0 transition-transform duration-200
                  ${isActive ? 'text-white' : 'text-slate-400 group-hover:text-blue-400'}
                  ${!isSidebarOpen && 'mx-auto'}
                `} 
              />
              
              <span 
                className={`
                  ml-3 text-sm font-semibold whitespace-nowrap overflow-hidden transition-all duration-300
                  ${isActive ? 'text-white' : 'group-hover:translate-x-1'}
                  ${isSidebarOpen ? 'opacity-100 w-auto block' : 'opacity-0 w-0 hidden'}
                `}
              >
                {item.name}
              </span>
            </Link>
          );
        })}
      </nav>

      {/* Logout Section */}
      <div className="p-4 border-t border-slate-800/60 shrink-0">
        <button
          onClick={handleLogout}
          title={!isSidebarOpen ? "Log Out" : undefined}
          className={`
            group flex items-center w-full px-3 py-3 rounded-xl transition-all duration-200
            text-slate-400 hover:bg-red-500/10 hover:text-red-400 hover:border-red-500/20 border border-transparent
            ${!isSidebarOpen && 'justify-center'}
          `}
        >
          <ArrowLeftOnRectangleIcon className="w-5 h-5 flex-shrink-0 group-hover:-translate-x-1 transition-transform" />
          
          <span 
            className={`
              ml-3 text-sm font-bold whitespace-nowrap overflow-hidden transition-all duration-300
              ${isSidebarOpen ? 'opacity-100 w-auto block' : 'opacity-0 w-0 hidden'}
            `}
          >
            Log Out
          </span>
        </button>
      </div>
    </aside>
  );
}