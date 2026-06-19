import React, { useState } from 'react';
import { Search, Filter, MapPin, Clock, Users, Truck } from 'lucide-react';

export default function OicTripDetails() {
  const [searchTerm, setSearchTerm] = useState('');

  // Extended mock data for the detailed view
  const trips = [
    { id: 'TRP-801', driver: 'A. Santos', vehicle: 'Van 1 (ABC-123)', route: 'LIMA - SM Lipa', time: '10:00 AM', status: 'In Transit', passengers: 12, capacity: 15 },
    { id: 'TRP-802', driver: 'B. Garcia', vehicle: 'Bus 3 (XYZ-987)', route: 'LIMA - Malvar', time: '09:30 AM', status: 'Completed', passengers: 28, capacity: 30 },
    { id: 'TRP-803', driver: 'C. Mendoza', vehicle: 'Van 2 (DEF-456)', route: 'LIMA - Tanauan', time: '01:00 PM', status: 'Scheduled', passengers: 0, capacity: 15 },
    { id: 'TRP-804', driver: 'D. Reyes', vehicle: 'Bus 1 (LMN-111)', route: 'LIMA - Sto. Tomas', time: '03:30 PM', status: 'Scheduled', passengers: 0, capacity: 30 },
  ];

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-3xl font-bold text-slate-800">Trip Details</h1>
          <p className="text-slate-500 mt-1">Comprehensive log of all fleet deployments and passenger counts.</p>
        </div>
        
        {/* Search and Filter Tools */}
        <div className="flex gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
            <input 
              type="text" 
              placeholder="Search trips..." 
              className="pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <button className="flex items-center gap-2 px-4 py-2 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 text-slate-700 font-medium">
            <Filter size={18} /> Filters
          </button>
        </div>
      </div>

      {/* Main Data Table */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 text-slate-500 text-sm border-b border-slate-200">
                <th className="px-6 py-4 font-medium">Trip ID & Vehicle</th>
                <th className="px-6 py-4 font-medium">Route & Schedule</th>
                <th className="px-6 py-4 font-medium">Driver Assigned</th>
                <th className="px-6 py-4 font-medium text-center">Passenger Load</th>
                <th className="px-6 py-4 font-medium">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {trips.map((trip) => (
                <tr key={trip.id} className="hover:bg-slate-50 transition-colors">
                  <td className="px-6 py-4">
                    <div className="font-bold text-slate-800">{trip.id}</div>
                    <div className="text-sm text-slate-500 flex items-center mt-1">
                      <Truck size={14} className="mr-1" /> {trip.vehicle}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="font-medium text-slate-700 flex items-center">
                      <MapPin size={14} className="mr-1 text-blue-500" /> {trip.route}
                    </div>
                    <div className="text-sm text-slate-500 flex items-center mt-1">
                      <Clock size={14} className="mr-1" /> {trip.time}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="font-medium text-slate-700">{trip.driver}</div>
                  </td>
                  <td className="px-6 py-4 text-center">
                    <div className="inline-flex items-center px-3 py-1 bg-slate-100 rounded-full text-sm font-medium text-slate-700">
                      <Users size={14} className="mr-2 text-slate-500" />
                      {trip.passengers} / {trip.capacity}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider ${
                      trip.status === 'Completed' ? 'bg-green-100 text-green-700' :
                      trip.status === 'In Transit' ? 'bg-blue-100 text-blue-700' :
                      'bg-amber-100 text-amber-700'
                    }`}>
                      {trip.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}