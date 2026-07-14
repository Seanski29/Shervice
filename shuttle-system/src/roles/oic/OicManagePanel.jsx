import React, { useState } from 'react';
// To this (added Users):
import { Send, MessageSquare, CalendarClock, MapPin, CheckCircle, ClockIcon, TruckIcon, Users } from 'lucide-react';

const OicManagePanel = () => {
  const [currentPath, setCurrentPath] = useState('view_status'); 
  const [passengerCount, setPassengerCount] = useState('');
  const [feedback, setFeedback] = useState({ rating: 5, comments: '' });
  const [selectedTrip, setSelectedTrip] = useState(null);
  const [actionSuccess, setActionSuccess] = useState(false);

  const mockTrips = [
    { id: 'TRP-801', driver: 'A. Santos', route: 'LIMA - SM Lipa', status: 'Scheduled', time: '10:00 AM', capacity: 15 },
    { id: 'TRP-802', driver: 'B. Garcia', route: 'LIMA - Malvar', status: 'In Transit', time: '09:30 AM', capacity: 15 },
  ];

  const handleActionComplete = () => {
    setActionSuccess(true);
    setTimeout(() => {
      setActionSuccess(false);
      setCurrentPath('view_status'); 
      setSelectedTrip(null);
      setPassengerCount('');
    }, 2000);
  };

  const handleDispatchSubmit = (e) => {
    e.preventDefault();
    handleActionComplete();
  };

  const handleFeedbackSubmit = (e) => {
    e.preventDefault();
    handleActionComplete();
  };

  // Helper for Tab Buttons
  const TabButton = ({ path, label, icon: Icon, activeColor }) => (
    <button 
      onClick={() => setCurrentPath(path)}
      className={`flex items-center px-5 py-3 rounded-xl font-bold text-sm transition-all ${
        currentPath === path ? `bg-white shadow-sm border border-slate-200 ${activeColor}` : 'text-slate-500 hover:text-slate-900'
      }`}
    >
      <Icon size={18} className="mr-2" />
      {label}
    </button>
  );

  return (
    <div className="w-full min-h-screen bg-[#F8FAFC] p-4 md:p-8 text-left">
      
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-900 tracking-tight">OIC Dispatch Management</h1>
        <p className="text-sm text-slate-500 mt-1">Manage trip departures, passenger logs, and driver evaluations.</p>
      </div>

      {/* Navigation Tabs */}
      <div className="flex flex-wrap gap-2 mb-8 bg-slate-200/50 p-1 rounded-2xl w-fit">
        <TabButton path="view_status" label="Schedules" icon={CalendarClock} activeColor="text-blue-600" />
        <TabButton path="manage_trip" label="Dispatch" icon={Send} activeColor="text-green-600" />
        <TabButton path="give_feedback" label="Feedback" icon={MessageSquare} activeColor="text-purple-600" />
      </div>

      {/* Success Notification */}
      {actionSuccess && (
        <div className="bg-green-50 border border-green-200 text-green-700 px-6 py-4 rounded-xl flex items-center mb-6 font-bold shadow-sm">
          <CheckCircle size={20} className="mr-3 text-green-500" />
          Action completed successfully. Log updated in SHERVICE.
        </div>
      )}

      {/* View Status Section */}
      {currentPath === 'view_status' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {mockTrips.map((trip) => (
            <div key={trip.id} className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
              <div className="flex justify-between items-start mb-4">
                <p className="font-bold text-slate-900">{trip.id}</p>
                <span className={`px-3 py-1 rounded-full text-[11px] font-bold uppercase ${trip.status === 'Scheduled' ? 'bg-blue-50 text-blue-700' : 'bg-amber-50 text-amber-700'}`}>
                  {trip.status}
                </span>
              </div>
              <div className="space-y-2">
                <div className="flex items-center text-sm text-slate-600"><ClockIcon size={16} className="mr-2"/> {trip.time}</div>
                <div className="flex items-center text-sm text-slate-600"><MapPin size={16} className="mr-2"/> {trip.route}</div>
                <div className="flex items-center text-sm text-slate-600"><Users size={16} className="mr-2"/> Driver: {trip.driver}</div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Dispatch Section */}
      {currentPath === 'manage_trip' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div className="space-y-4">
            <h2 className="font-bold text-slate-900 mb-4">Select Trip</h2>
            {mockTrips.filter(t => t.status === 'Scheduled').map(trip => (
              <div key={trip.id} onClick={() => setSelectedTrip(trip)} className={`p-5 rounded-xl border-2 cursor-pointer transition-all ${selectedTrip?.id === trip.id ? 'border-green-500 bg-green-50' : 'border-slate-200 bg-white hover:border-green-300'}`}>
                <p className="font-bold text-slate-900">{trip.id} - {trip.time}</p>
                <p className="text-xs text-slate-500">{trip.route} | Driver: {trip.driver}</p>
              </div>
            ))}
          </div>

          {selectedTrip && (
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-8">
              <h2 className="font-bold text-slate-900 mb-2">Confirm Passenger Count</h2>
              <p className="text-sm text-slate-500 mb-6">Dispatching <strong className="text-slate-900">{selectedTrip.id}</strong></p>
              <form onSubmit={handleDispatchSubmit} className="space-y-6">
                <div>
                  <label className="block text-xs font-bold uppercase text-slate-500 mb-2">Headcount</label>
                  <input type="number" required value={passengerCount} onChange={(e) => setPassengerCount(e.target.value)} className="w-full px-4 py-3 rounded-lg border border-slate-300 focus:ring-2 focus:ring-green-500" placeholder="0" />
                </div>
                <button type="submit" className="w-full bg-green-600 hover:bg-green-700 text-white font-bold py-3 rounded-lg transition-colors">Dispatch Trip</button>
              </form>
            </div>
          )}
        </div>
      )}

      {/* Feedback Section */}
      {currentPath === 'give_feedback' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div className="space-y-4">
            <h2 className="font-bold text-slate-900 mb-4">Select Trip</h2>
            {mockTrips.map(trip => (
              <div key={trip.id} onClick={() => setSelectedTrip(trip)} className={`p-5 rounded-xl border-2 cursor-pointer transition-all ${selectedTrip?.id === trip.id ? 'border-purple-500 bg-purple-50' : 'border-slate-200 bg-white hover:border-purple-300'}`}>
                <p className="font-bold text-slate-900">{trip.id}</p>
                <p className="text-xs text-slate-500">Driver: {trip.driver}</p>
              </div>
            ))}
          </div>

          {selectedTrip && (
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-8">
              <h2 className="font-bold text-slate-900 mb-6">OIC Evaluation</h2>
              <form onSubmit={handleFeedbackSubmit} className="space-y-6">
                <div>
                  <label className="block text-xs font-bold uppercase text-slate-500 mb-2">Performance Rating</label>
                  <select value={feedback.rating} onChange={(e) => setFeedback({...feedback, rating: e.target.value})} className="w-full px-4 py-3 rounded-lg border border-slate-300">
                    <option value="5">5 - Excellent</option>
                    <option value="4">4 - Good</option>
                    <option value="3">3 - Average</option>
                    <option value="1">1 - Poor</option>
                  </select>
                </div>
                <textarea required value={feedback.comments} onChange={(e) => setFeedback({...feedback, comments: e.target.value})} rows="4" placeholder="Log incident details or praise..." className="w-full px-4 py-3 rounded-lg border border-slate-300"></textarea>
                <button type="submit" className="w-full bg-purple-600 hover:bg-purple-700 text-white font-bold py-3 rounded-lg transition-colors">Submit Evaluation</button>
              </form>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default OicManagePanel;