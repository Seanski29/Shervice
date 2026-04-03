import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Login from './pages/login.jsx';
import Dashboard from './pages/dashboard.jsx';
import DriverDashboard from './pages/driver_dashboard.jsx';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* The root path '/' shows the Login page */}
        <Route path="/" element={<Login />} />
        
        {/* The '/dashboard' path shows our new Dashboard page */}
        <Route path="/dashboard" element={<Dashboard />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;