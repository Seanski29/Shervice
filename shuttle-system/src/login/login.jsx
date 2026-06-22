import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import { useState } from 'react';
import brandLogo from '../assets/GT LANTIN CAR RENTALS.jpg';

export default function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [showPassword, setShowPassword] = useState(false);
  const [mousePos, setMousePos] = useState({ x: 50, y: 50 });

  const handleMouseMove = (event) => {
    setMousePos({
      x: (event.clientX / window.innerWidth) * 100,
      y: (event.clientY / window.innerHeight) * 100,
    });
  };

  const handleLogin = (event) => {
    event.preventDefault();

    const emailInput = event.target.email.value;
    const passwordInput = event.target.password.value;
    
    // Define where the Flutter app is running
    const flutterAppUrl = 'http://localhost:8080';

    let userData;

    // 1. Check for Flutter Admin
    if (emailInput === 'admin@gmail.com' && passwordInput === 'admin123') {
      userData = { name: 'Admin User', role: 'admin' };
      login(userData);
      // Redirect out of React to the Flutter App
      window.location.href = `${flutterAppUrl}/?role=admin`;
      return; // Stop further execution
    } 
    // 2. Check for Flutter Driver
    else if (emailInput === 'driver@gmail.com' && passwordInput === 'driver123') {
      userData = { name: 'Juan D.', role: 'driver' };
      login(userData);
      // Redirect out of React to the Flutter App
      window.location.href = `${flutterAppUrl}/?role=driver`;
      return; // Stop further execution
    } 
    // 3. React Roles (OIC, Staff, Passenger)
    else if (emailInput.includes('oic')) {
      userData = { name: 'Duty Officer', role: 'oic' };
    } 
    else if (emailInput.includes('passenger')) {
      userData = { name: 'Passenger User', role: 'passenger' };
    } 
    else {
      userData = { name: 'Staff User', role: 'staff' };
    }

    // Process login and navigate internally for React roles
    login(userData);
    navigate('/dashboard');
  };

  return (
    <div
      className="flex flex-col min-h-screen text-slate-800"
      onMouseMove={handleMouseMove}
      style={{
        '--x': `${mousePos.x}%`,
        '--y': `${mousePos.y}%`,
        background: 'radial-gradient(circle at var(--x) var(--y), #ffffff 0%, #ecfdf5 6%, #284aa7 100%)',
        backgroundAttachment: 'fixed',
        transition: 'background 0.2s ease-out'
      }}
    >
      <style>
        {`
          @keyframes riseUp {
            0% { opacity: 0; transform: translateY(40px) scale(0.98); }
            100% { opacity: 1; transform: translateY(0) scale(1); }
          }
          .animate-rise { animation: riseUp 0.6s ease-out 0.2s forwards; opacity: 0; }
        `}
      </style>

      <main className="flex flex-grow items-center justify-center py-12 px-4">
        <div className="w-full max-w-md">
          <div className="bg-white/80 backdrop-blur-md rounded-3xl shadow-lg border border-slate-200 p-8 animate-rise">

            <div className="flex justify-center mb-5">
              <img
                src={brandLogo}
                alt="G.T. Lantin Logo"
                className="h-24 w-24 rounded-full shadow-md ring-4 ring-emerald-100 object-contain p-1 bg-white"
              />
            </div>

            <h2 className="text-2xl font-bold text-center text-slate-900 mb-2">
              Shervice
            </h2>
            <p className="text-center text-slate-500 text-sm mb-6">Sign in to continue</p>

            <form className="space-y-4" onSubmit={handleLogin}>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Email Address
                </label>
                <input
                  type="email"
                  name="email"
                  placeholder="you@gtlantin.com"
                  required
                  className="w-full border border-slate-300 rounded-xl px-4 py-2.5 
                             focus:ring-2 focus:ring-blue-500 focus:outline-none bg-white/90"
                />
              </div>

              <div className="relative w-full">
                <label htmlFor="password" className="block text-sm font-medium text-slate-700 mb-1">
                  Password
                </label>
                <input
                  type={showPassword ? "text" : "password"}
                  id="password"
                  name="password"
                  required
                  placeholder="••••••••"
                  className="w-full border border-slate-300 rounded-xl px-4 py-3 pr-12 
                             focus:ring-2 focus:ring-blue-500 focus:outline-none bg-white/90"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 pt-6"
                >
                  {showPassword ? (
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                      strokeWidth="1.8" stroke="#6b7280" className="w-6 h-6">
                      <path strokeLinecap="round" strokeLinejoin="round"
                        d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z" />
                      <circle cx="12" cy="12" r="3" />
                    </svg>
                  ) : (
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                      strokeWidth="1.8" stroke="#6b7280" className="w-6 h-6">
                      <path strokeLinecap="round" strokeLinejoin="round"
                        d="M3 3l18 18M10.58 10.58A3 3 0 0113.42 13.42M6.1 6.1C3.7 8 2 12 2 12s3.5 7 10 7a9.9 9.9 0 005.9-2.1" />
                    </svg>
                  )}
                </button>
              </div>

              <div className="text-right text-sm">
                <a href="#" className="text-blue-600 hover:underline font-medium">
                  Forgot Password?
                </a>
              </div>

              <button
                type="submit"
                className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold 
                           py-3 rounded-xl mt-5 shadow-md transition-all duration-300 
                           transform hover:scale-105"
              >
                Log In
              </button>
            </form>

            <div className="relative flex items-center justify-center my-6">
              <div className="flex-grow border-t border-slate-300"></div>
              <span className="flex-shrink mx-4 text-xs text-slate-500 font-medium">
                GT LANTIN SHUTTLE SERVICES
              </span>
              <div className="flex-grow border-t border-slate-300"></div>
            </div>

          </div>
        </div>
      </main>
    </div>
  );
}