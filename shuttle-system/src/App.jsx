import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import MainLayout from './components/MainLayout';
// Login
import Login from './login/login.jsx';

// Staff pages
import Dashboard   from './roles/staff/staff_dashboard.jsx';
import SDriver     from './roles/staff/s_driver.jsx';
import SVehicle    from './roles/staff/s_vehicle.jsx';
import SAttendance from './roles/staff/s_attendance.jsx';
import SSchedules  from './roles/staff/s_schedules.jsx';
import SAnalytics  from './roles/staff/s_analytics.jsx';

// OIC pages
import OicManagePanel from './roles/oic/OicManagePanel.jsx';
import OicTripDetails from './roles/oic/OicTrips.jsx';
import OicSchedules   from './roles/oic/OicSchedules.jsx';

//ADMIN pages
import AdminDashboard from './roles/admin/admin_dashboard.jsx';

// Standalone portals
import PassengerEvaluation from './roles/passenger/PassengerEvaluation.jsx';
import DriverDashboard     from './roles/driver/driver_dashboard.jsx';

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>

          {/* Admin routes */}
          <Route path="/admin/dashboard" element={<AdminDashboard />} />

          {/* ── PUBLIC ROUTES ── */}
          <Route path="/" element={<Login />} />
          <Route path="/evaluate" element={<PassengerEvaluation />} />

          {/* ── DRIVER PORTAL (mobile) ── */}
          <Route
            path="/driver"
            element={
              <ProtectedRoute allowedRoles={['driver']}>
                <DriverDashboard />
              </ProtectedRoute>
            }
          />

          {/* ── STAFF / ADMIN / OIC PORTAL (desktop with sidebar) ── */}
          <Route
            element={
              <ProtectedRoute allowedRoles={['staff', 'admin', 'oic']}>
                <MainLayout />
              </ProtectedRoute>
            }
          >
            {/* Staff routes */}
            <Route path="/dashboard"       element={<Dashboard />} />
            <Route path="/driver-profiles" element={<SDriver />} />
            <Route path="/vehicle-status"  element={<SVehicle />} />
            <Route path="/attendance"      element={<SAttendance />} />
            <Route path="/schedules"       element={<SSchedules />} />
            <Route path="/analytics"       element={<SAnalytics />} />

            {/* OIC routes */}
            <Route path="/oicmanage"    element={<OicManagePanel />} />
            <Route path="/oictrips"     element={<OicTripDetails />} />
            <Route path="/oicschedules" element={<OicSchedules />} />
          </Route>

        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;