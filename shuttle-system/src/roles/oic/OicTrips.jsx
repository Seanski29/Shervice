import React, { useState } from 'react';
import { Search, Filter, MapPin, Clock, Users, Truck, ClipboardList } from 'lucide-react';

export default function OicTripDetails() {
  const [searchTerm, setSearchTerm] = useState('');

  const trips = [
    { id: 'TRP-801', driver: 'A. Santos', vehicle: 'Van 1 (ABC-123)', route: 'LIMA - SM Lipa', time: '10:00 AM', status: 'In Transit', passengers: 12, capacity: 15 },
    { id: 'TRP-802', driver: 'B. Garcia', vehicle: 'Bus 3 (XYZ-987)', route: 'LIMA - Malvar', time: '09:30 AM', status: 'Completed', passengers: 28, capacity: 30 },
    { id: 'TRP-803', driver: 'C. Mendoza', vehicle: 'Van 2 (DEF-456)', route: 'LIMA - Tanauan', time: '01:00 PM', status: 'Scheduled', passengers: 0, capacity: 15 },
    { id: 'TRP-804', driver: 'D. Reyes', vehicle: 'Bus 1 (LMN-111)', route: 'LIMA - Sto. Tomas', time: '03:30 PM', status: 'Scheduled', passengers: 0, capacity: 30 },
  ];

  return (
    <div className="w-full min-h-screen bg-[#F8FAFC] p-4 md:p-8 text-left">
      
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6 mb-8">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Trip Details</h1>
          <p className="text-sm text-slate-500 mt-1">Comprehensive log of all fleet deployments and passenger counts.</p>
        </div>
        
        {/* Tools */}
        <div className="flex gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
            <input 
              type="text" 
              placeholder="Search trips..." 
              className="pl-10 pr-4 py-2 border border-slate-200 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none w-full md:w-64 bg-white shadow-sm"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <button className="flex items-center gap-2 px-4 py-2 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 text-slate-700 font-semibold shadow-sm">
            <Filter size={18} /> Filters
          </button>
        </div>
      </div>

      {/* Main List */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="p-5 border-b border-slate-100 flex items-center gap-2 bg-slate-50/50">
         <ClipboardList className="text-blue-600" size={20} />
          <h2 className="font-bold text-slate-900">Deployment Logs</h2>
        </div>
        
        <div className="divide-y divide-slate-100">
          {trips.map((trip) => (
            <div key={trip.id} className="grid grid-cols-1 md:grid-cols-5 p-5 gap-4 items-center hover:bg-slate-50 transition-colors">
              
              {/* ID & Vehicle */}
              <div className="md:col-span-1">
                <div className="font-bold text-slate-900">{trip.id}</div>
                <div className="text-xs text-slate-500 flex items-center mt-1">
                  <Truck size={13} className="mr-1" /> {trip.vehicle}
                </div>
              </div>

              {/* Route & Schedule */}
              <div className="md:col-span-1">
                <div className="text-sm font-semibold text-slate-700 flex items-center">
                  <MapPin size={14} className="mr-1 text-blue-500" /> {trip.route}
                </div>
                <div className="text-xs text-slate-500 flex items-center mt-1">
                  <Clock size={13} className="mr-1" /> {trip.time}
                </div>
              </div>

              {/* Driver */}
              <div className="md:col-span-1 text-sm font-medium text-slate-700">
                {trip.driver}
              </div>

              {/* Passenger Load */}
              <div className="md:col-span-1">
                <div className="inline-flex items-center px-2.5 py-1 bg-slate-100 rounded-md text-xs font-bold text-slate-700 border border-slate-200">
                  <Users size={12} className="mr-1.5 text-slate-500" />
                  {trip.passengers} / {trip.capacity}
                </div>
              </div>

              {/* Status */}
              <div className="md:col-span-1 text-right md:text-left">
                <span className={`px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider border ${
                  trip.status === 'Completed' ? 'bg-green-50 text-green-700 border-green-200' :
                  trip.status === 'In Transit' ? 'bg-blue-50 text-blue-700 border-blue-200' :
                  'bg-amber-50 text-amber-700 border-amber-200'
                }`}>
                  {trip.status}
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}