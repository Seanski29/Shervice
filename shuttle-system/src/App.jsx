import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Login from "./login/login.jsx";
import MainLayout from "./components/MainLayout.jsx";
import Dashboard from "./1_staff/staff_dashboard.jsx";
import SDriver from "./1_staff/s_driver.jsx";
import SVehicle from "./1_staff/s_vehicle.jsx";
import SAttendance from "./1_staff/s_attendance.jsx";
import SSchedules from "./1_staff/s_schedules.jsx";
import SAnalytics from "./1_staff/s_analytics.jsx";

function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Login is outside the layout (no sidebar) */}
        <Route path="/" element={<Login />} />
        
        {/* Everything inside this Route tag will use the Sidebar and Header */}
        <Route element={<MainLayout />}>
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/driver-profiles" element={<SDriver />} />
          <Route path="/vehicle-status" element={<SVehicle />} />
          <Route path="/attendance" element={<SAttendance />} />
          <Route path="/schedules" element={<SSchedules />} />
          <Route path="/analytics" element={<SAnalytics />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;