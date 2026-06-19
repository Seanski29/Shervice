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
    { name: 'Overview',        icon: HomeIcon,         path: '/dashboard' },
    { name: 'Driver Profiles', icon: UsersIcon,        path: '/driver-profiles' },
    { name: 'Vehicle Status',  icon: TruckIcon,        path: '/vehicle-status' },
    { name: 'Attendance',      icon: ClockIcon,        path: '/attendance' },
    { name: 'Schedules',       icon: CalendarDaysIcon, path: '/schedules' },
    { name: 'Analytics',       icon: ChartPieIcon,     path: '/analytics' },
  ];

  return (
    <aside className={`${isSidebarOpen ? 'w-64' : 'w-20'}
                       bg-slate-800 text-slate-300 flex flex-col
                       transition-all duration-300 ease-in-out
                       h-screen sticky top-0 z-30 shadow-xl`}>

      {/* Logo & System Name */}
      <div className="p-6 flex items-center gap-3 border-b border-slate-700">
        <img
          src={brandLogo}
          alt="Logo"
          className="h-8 w-8 rounded-lg bg-white p-0.5 flex-shrink-0"
        />
        {isSidebarOpen && (
          <div>
            <span className="font-bold text-white tracking-tight italic block">
              SHERVICE
            </span>
            <span className="text-xs text-slate-400">Staff Portal</span>
          </div>
        )}
      </div>

      {/* Nav Links */}
      <nav className="flex-1 px-3 py-6 space-y-1 overflow-y-auto">
        {navItems.map((item) => {
          const isActive = location.pathname === item.path;
          return (
            <Link
              key={item.name}
              to={item.path}
              className={`flex items-center px-3 py-2.5 rounded-xl
                          transition-all
                          ${isActive
                            ? 'bg-blue-600 text-white'
                            : 'hover:bg-slate-700 hover:text-white'}`}
            >
              <item.icon className="w-5 h-5 flex-shrink-0" />
              {isSidebarOpen && (
                <span className="ml-3 text-sm font-medium whitespace-nowrap">
                  {item.name}
                </span>
              )}
            </Link>
          );
        })}
      </nav>

      {/* Logout Button */}
      <div className="p-4 border-t border-slate-700">
        <button
          onClick={handleLogout}
          className="flex items-center w-full px-3 py-2.5
                     text-slate-400 hover:bg-red-500/10 hover:text-red-400
                     rounded-xl transition-all"
        >
          <ArrowLeftOnRectangleIcon className="w-5 h-5 flex-shrink-0" />
          {isSidebarOpen && (
            <span className="ml-3 text-sm font-bold">Log Out</span>
          )}
        </button>
      </div>
    </aside>
  );
}