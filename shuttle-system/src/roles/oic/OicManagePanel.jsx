import React, { useState } from 'react';
import { 
  Send, 
  Users, 
  MessageSquare, 
  CalendarClock, 
  MapPin, 
  CheckCircle,
  AlertCircle
} from 'lucide-react';

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
    console.log(`Dispatching ${selectedTrip.id} with ${passengerCount} passengers.`);
    handleActionComplete();
  };

  const handleFeedbackSubmit = (e) => {
    e.preventDefault();
    console.log(`Feedback for ${selectedTrip.id}: ${feedback.rating} stars - ${feedback.comments}`);
    handleActionComplete();
  };

  return (
    <div className="max-w-5xl mx-auto space-y-6">
      
      <div>
        <h1 className="text-3xl font-bold text-slate-800">OIC Dispatch Management</h1>
        <p className="text-slate-500">Manage trip departures, passenger logs, and driver evaluations.</p>
      </div>

      <div className="flex space-x-4 border-b border-slate-200 pb-4">
        <button 
          onClick={() => setCurrentPath('view_status')}
          className={`flex items-center px-4 py-2 rounded-lg font-medium transition-colors ${
            currentPath === 'view_status' ? 'bg-blue-100 text-blue-700' : 'text-slate-600 hover:bg-slate-100'
          }`}
        >
          <CalendarClock size={18} className="mr-2" />
          View Status (Schedules/Trips)
        </button>
        <button 
          onClick={() => setCurrentPath('manage_trip')}
          className={`flex items-center px-4 py-2 rounded-lg font-medium transition-colors ${
            currentPath === 'manage_trip' ? 'bg-green-100 text-green-700' : 'text-slate-600 hover:bg-slate-100'
          }`}
        >
          <Send size={18} className="mr-2" />
          Dispatch & Passenger Count
        </button>
        <button 
          onClick={() => setCurrentPath('give_feedback')}
          className={`flex items-center px-4 py-2 rounded-lg font-medium transition-colors ${
            currentPath === 'give_feedback' ? 'bg-purple-100 text-purple-700' : 'text-slate-600 hover:bg-slate-100'
          }`}
        >
          <MessageSquare size={18} className="mr-2" />
          Give Driver Feedback
        </button>
      </div>

      {actionSuccess && (
        <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg flex items-center animate-fade-in">
          <CheckCircle size={20} className="mr-3 text-green-500" />
          Action completed successfully. Log updated in SHERVICE.
        </div>
      )}

      {currentPath === 'view_status' && (
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
          <div className="p-4 border-b border-slate-200 bg-slate-50">
            <h2 className="font-bold text-slate-800">Current Trip & Schedule Status</h2>
          </div>
          <table className="w-full text-left">
            <thead>
              <tr className="bg-white text-slate-500 text-sm border-b border-slate-200">
                <th className="px-6 py-3 font-medium">Trip ID</th>
                <th className="px-6 py-3 font-medium">Time</th>
                <th className="px-6 py-3 font-medium">Route</th>
                <th className="px-6 py-3 font-medium">Driver</th>
                <th className="px-6 py-3 font-medium">Status</th>
              </tr>
            </thead>
            <tbody>
              {mockTrips.map((trip) => (
                <tr key={trip.id} className="border-b border-slate-50 hover:bg-slate-50">
                  <td className="px-6 py-4 font-medium text-slate-800">{trip.id}</td>
                  <td className="px-6 py-4 text-slate-600">{trip.time}</td>
                  <td className="px-6 py-4 text-slate-600 flex items-center">
                    <MapPin size={16} className="mr-2 text-slate-400" /> {trip.route}
                  </td>
                  <td className="px-6 py-4 text-slate-600">{trip.driver}</td>
                  <td className="px-6 py-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                      trip.status === 'Scheduled' ? 'bg-blue-100 text-blue-700' : 'bg-amber-100 text-amber-700'
                    }`}>
                      {trip.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {currentPath === 'manage_trip' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
            <h2 className="font-bold text-slate-800 mb-4 flex items-center">
              <Send size={20} className="mr-2 text-green-600" /> Select Trip to Dispatch
            </h2>
            <div className="space-y-3">
              {mockTrips.filter(t => t.status === 'Scheduled').map(trip => (
                <div 
                  key={trip.id}
                  onClick={() => setSelectedTrip(trip)}
                  className={`p-4 border rounded-lg cursor-pointer transition-colors ${
                    selectedTrip?.id === trip.id ? 'border-green-500 bg-green-50' : 'border-slate-200 hover:border-green-300'
                  }`}
                >
                  <p className="font-bold text-slate-800">{trip.id} - {trip.time}</p>
                  <p className="text-sm text-slate-500">{trip.route} | Driver: {trip.driver}</p>
                </div>
              ))}
            </div>
          </div>

          {selectedTrip && (
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <h2 className="font-bold text-slate-800 mb-4">Confirm Passenger Count</h2>
              <p className="text-sm text-slate-500 mb-6 border-b pb-4">
                You are dispatching <strong className="text-slate-800">{selectedTrip.id}</strong>. Please input the final passenger headcount for analytics logging.
              </p>
              
              <form onSubmit={handleDispatchSubmit} className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2 flex items-center">
                    <Users size={16} className="mr-2" /> Total Passengers Onboard
                  </label>
                  <input 
                    type="number" 
                    min="0" 
                    max={selectedTrip.capacity}
                    required
                    value={passengerCount}
                    onChange={(e) => setPassengerCount(e.target.value)}
                    className="w-full px-4 py-3 rounded-lg border border-slate-300 focus:ring-2 focus:ring-green-500 focus:border-green-500"
                    placeholder={`Max capacity: ${selectedTrip.capacity}`}
                  />
                </div>
                
                <button type="submit" className="w-full bg-green-600 hover:bg-green-700 text-white font-bold py-3 px-4 rounded-lg transition-colors">
                  Send Trip Details & Dispatch
                </button>
              </form>
            </div>
          )}
        </div>
      )}

      {currentPath === 'give_feedback' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
            <h2 className="font-bold text-slate-800 mb-4 flex items-center">
              <MessageSquare size={20} className="mr-2 text-purple-600" /> Select Completed Trip
            </h2>
            <div className="space-y-3">
              {mockTrips.map(trip => (
                <div 
                  key={trip.id}
                  onClick={() => setSelectedTrip(trip)}
                  className={`p-4 border rounded-lg cursor-pointer transition-colors ${
                    selectedTrip?.id === trip.id ? 'border-purple-500 bg-purple-50' : 'border-slate-200 hover:border-purple-300'
                  }`}
                >
                  <p className="font-bold text-slate-800">{trip.id}</p>
                  <p className="text-sm text-slate-500">Driver: {trip.driver}</p>
                </div>
              ))}
            </div>
          </div>

          {selectedTrip && (
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <h2 className="font-bold text-slate-800 mb-4">OIC Evaluation</h2>
              <form onSubmit={handleFeedbackSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Driver Professionalism & Punctuality Rating</label>
                  <select 
                    value={feedback.rating}
                    onChange={(e) => setFeedback({...feedback, rating: e.target.value})}
                    className="w-full px-4 py-3 rounded-lg border border-slate-300 focus:ring-2 focus:ring-purple-500"
                  >
                    <option value="5">5 - Excellent (No issues)</option>
                    <option value="4">4 - Good (Minor delays/issues)</option>
                    <option value="3">3 - Average</option>
                    <option value="2">2 - Poor (Noticeable delays/issues)</option>
                    <option value="1">1 - Unacceptable</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Incident/OIC Comments</label>
                  <textarea 
                    required
                    value={feedback.comments}
                    onChange={(e) => setFeedback({...feedback, comments: e.target.value})}
                    rows="3"
                    placeholder="Provide required feedback for the ML model..."
                    className="w-full px-4 py-3 rounded-lg border border-slate-300 focus:ring-2 focus:ring-purple-500 resize-none"
                  ></textarea>
                </div>
                <button type="submit" className="w-full bg-purple-600 hover:bg-purple-700 text-white font-bold py-3 px-4 rounded-lg transition-colors">
                  Submit OIC Feedback
                </button>
              </form>
            </div>
          )}
        </div>
      )}

    </div>
  );
};

export default OicManagePanel;