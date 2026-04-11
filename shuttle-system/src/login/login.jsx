import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import brandLogo from '../assets/GT LANTIN CAR RENTALS.jpg';

export default function Login() {
// ... rest of your code stays the same{
  // 1. State for the password visibility toggle
  const [showPassword, setShowPassword] = useState(false);

  // 2. State to track mouse position for the dynamic background
  const [mousePos, setMousePos] = useState({ x: 50, y: 50 });
  const navigate = useNavigate(); // ADD THIS LINE

  const handleMouseMove = (event) => {
    setMousePos({
      x: (event.clientX / window.innerWidth) * 100,
      y: (event.clientY / window.innerHeight) * 100,
    });
  };

const handleLogin = (event) => {
    event.preventDefault(); 
    // This MUST match the 'path' in your App.jsx Route
    navigate('/dashboard'); 
  };
  return (
    // The main container tracks the mouse movement
    <div 
      className="flex flex-col min-h-screen text-slate-800"
      onMouseMove={handleMouseMove}
      style={{
        '--x': `${mousePos.x}%`, 
        '--y': `${mousePos.y}%`,
        // Replaced the blue gradient with the G.T. Lantin Blue gradient
        background: 'radial-gradient(circle at var(--x) var(--y), #ffffff 0%, #ecfdf5 6%, #284aa7 100%)',
        backgroundAttachment: 'fixed',
        transition: 'background 0.2s ease-out'
      }}
    >
      {/* Inline styles for the specific rise animation you provided */}
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
          {/* Frosted glass card */}
          <div className="bg-white/80 backdrop-blur-md rounded-3xl shadow-lg border border-slate-200 p-8 animate-rise">
            
            <div className="flex justify-center mb-5">
              <img 
                src={brandLogo} 
                alt="G.T. Lantin Logo" 
                className="h-24 w-24 rounded-full shadow-md ring-4 ring-emerald-100 object-contain p-1 bg-white"
              />
            </div>

            <h2 className="text-2xl font-bold text-center text-white-900 mb-2">
              Shervice
            </h2>
            <p className="text-center text-slate-500 text-sm mb-6">Sign in</p>

            <form className="space-y-4" onSubmit={handleLogin}>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Email Address</label>
                <input 
                  type="email" 
                  placeholder="you@company.com" 
                  required
                  className="w-full border border-slate-300 rounded-xl px-4 py-2.5 focus:ring-2 focus:ring-brand-green focus:outline-none bg-white/90"
                />
              </div>

              <div className="relative w-full">
                <label htmlFor="password" className="block text-sm font-medium text-slate-700 mb-1">
                   Password
                </label>

                <input 
                  // Dynamically changes input type based on the showPassword state
                  type={showPassword ? "text" : "password"} 
                  id="password" 
                  required 
                  placeholder="••••••••"
                  className="w-full border border-slate-300 rounded-xl px-4 py-3 pr-12 focus:ring-2 focus:ring-brand-green focus:outline-none bg-white/90"
                />

                <button 
                  type="button" 
                  // Toggles the state between true and false
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 pt-6"
                >
                  {/* We use a ternary operator to show the open or closed eye */}
                  {showPassword ? (
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth="1.8" stroke="#6b7280" className="w-6 h-6">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z" />
                      <circle cx="12" cy="12" r="3" />
                    </svg>
                  ) : (
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth="1.8" stroke="#6b7280" className="w-6 h-6">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M3 3l18 18M10.58 10.58A3 3 0 0113.42 13.42M6.1 6.1C3.7 8 2 12 2 12s3.5 7 10 7a9.9 9.9 0 005.9-2.1" />
                    </svg>
                  )}
                </button>
              </div>

              <div className="text-right text-sm">
                <a href="#" className="text-brand-green hover:underline font-medium">Forgot Password?</a>
              </div>

              <button 
                type="submit"
                className="w-full bg-brand-blue hover:bg-brand-blue-dark text-white font-semibold py-3 rounded-xl mt-5 shadow-md transition-all duration-300 transform hover:scale-105"
              >
                Log In
              </button>
            </form>
                
            <div className="relative flex items-center justify-center my-6">
                <div className="flex-grow border-t border-slate-300"></div>
                <span className="flex-shrink mx-4 text-xs text-slate-500 font-medium">GT LANTIN SHUTTLE SERVICES</span>
                <div className="flex-grow border-t border-slate-300"></div>
            </div>

          </div>
        </div>
      </main>
    </div>
  );
}