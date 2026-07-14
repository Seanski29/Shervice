import React, { useState, useEffect } from 'react';
import { Star, CheckCircle, AlertCircle, Car, User, MapPin } from 'lucide-react';

const PassengerEvaluation = () => {
  // Flowchart States: 'checking', 'already_evaluated', 'details', 'evaluating', 'success'
  const [currentStep, setCurrentStep] = useState('details'); 
  
  // Form States
  const [ratings, setRatings] = useState({
    safety: 0,
    professionalism: 0,
    punctuality: 0,
  });
  const [comments, setComments] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Mock Data (In production, this comes from the QR Code URL / Database)
  const tripDetails = {
    driverName: "Juan Dela Cruz",
    vehiclePlate: "ABC 1234 (Toyota Hiace)",
    route: "LIMA Estate - SM Lipa",
    date: new Date().toLocaleDateString()
  };

  // Reusable Star Rating Component
  const StarRating = ({ criteria, value, onChange }) => {
    return (
      <div className="mb-6">
        <label className="block text-sm font-medium text-gray-700 mb-2 capitalize">
          {criteria}
        </label>
        <div className="flex space-x-2">
          {[1, 2, 3, 4, 5].map((star) => (
            <button
              key={star}
              type="button"
              onClick={() => onChange(criteria, star)}
              className="focus:outline-none transition-transform hover:scale-110"
            >
              <Star
                size={32}
                className={`${
                  star <= value ? 'fill-yellow-400 text-yellow-400' : 'text-gray-300'
                }`}
              />
            </button>
          ))}
        </div>
      </div>
    );
  };

  const handleRatingChange = (criteria, value) => {
    setRatings(prev => ({ ...prev, [criteria]: value }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    
    // Simulate API call to Node.js backend
    setTimeout(() => {
      setIsSubmitting(false);
      setCurrentStep('success'); // Move to END state
    }, 1500);
  };

  // --- RENDER SCREENS BASED ON FLOWCHART ---

  // 1. ALREADY EVALUATED SCREEN
  if (currentStep === 'already_evaluated') {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
        <div className="bg-white p-8 rounded-xl shadow-lg max-w-md w-full text-center">
          <AlertCircle className="w-16 h-16 text-yellow-500 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-800 mb-2">Already Evaluated</h2>
          <p className="text-gray-600">You have already submitted feedback for this trip. Thank you for helping GT Lantin improve!</p>
        </div>
      </div>
    );
  }

  // 2. SUCCESS / END SCREEN
  if (currentStep === 'success') {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
        <div className="bg-white p-8 rounded-xl shadow-lg max-w-md w-full text-center animate-fade-in">
          <CheckCircle className="w-16 h-16 text-green-500 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-800 mb-2">Evaluation Submitted</h2>
          <p className="text-gray-600">Your feedback has been securely logged to the Shervice system. Have a great day!</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-100 py-8 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md mx-auto bg-white rounded-xl shadow-md overflow-hidden">
        
        {/* Header */}
        <div className="bg-blue-600 px-6 py-4 text-white text-center">
          <h1 className="text-xl font-bold tracking-wider">GT LANTIN</h1>
          <p className="text-sm opacity-90">Passenger Evaluation</p>
        </div>

        <div className="p-6">
          {/* 3. VIEW VEHICLE DETAIL SCREEN */}
          {currentStep === 'details' && (
            <div className="space-y-6">
              <h2 className="text-lg font-semibold text-gray-800 border-b pb-2">Trip Information</h2>
              
              <div className="space-y-4">
                <div className="flex items-center text-gray-700">
                  <User className="w-5 h-5 mr-3 text-blue-500" />
                  <div>
                    <p className="text-xs text-gray-500 uppercase">Driver</p>
                    <p className="font-medium">{tripDetails.driverName}</p>
                  </div>
                </div>
                
                <div className="flex items-center text-gray-700">
                  <Car className="w-5 h-5 mr-3 text-blue-500" />
                  <div>
                    <p className="text-xs text-gray-500 uppercase">Vehicle</p>
                    <p className="font-medium">{tripDetails.vehiclePlate}</p>
                  </div>
                </div>

                <div className="flex items-center text-gray-700">
                  <MapPin className="w-5 h-5 mr-3 text-blue-500" />
                  <div>
                    <p className="text-xs text-gray-500 uppercase">Route</p>
                    <p className="font-medium">{tripDetails.route}</p>
                  </div>
                </div>
              </div>

              <button 
                onClick={() => setCurrentStep('evaluating')}
                className="w-full mt-6 bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded-lg transition-colors"
              >
                Proceed to Evaluation
              </button>
            </div>
          )}

          {/* 4. EVALUATE SCREEN */}
          {currentStep === 'evaluating' && (
            <form onSubmit={handleSubmit} className="space-y-2">
              <p className="text-sm text-gray-500 mb-6">
                Please rate your experience. Your anonymous feedback directly impacts driver performance analytics.
              </p>

              <StarRating criteria="safety" value={ratings.safety} onChange={handleRatingChange} />
              <StarRating criteria="professionalism" value={ratings.professionalism} onChange={handleRatingChange} />
              <StarRating criteria="punctuality" value={ratings.punctuality} onChange={handleRatingChange} />

              <div className="mt-6">
                <label htmlFor="comments" className="block text-sm font-medium text-gray-700 mb-2">
                  Additional Comments (Optional)
                </label>
                <textarea
                  id="comments"
                  rows={4}
                  className="w-full px-3 py-2 text-gray-700 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
                  placeholder="Tell us about any delays or commendations..."
                  value={comments}
                  onChange={(e) => setComments(e.target.value)}
                />
              </div>

              <div className="pt-4 flex space-x-3">
                <button 
                  type="button"
                  onClick={() => setCurrentStep('details')}
                  className="w-1/3 bg-gray-200 hover:bg-gray-300 text-gray-800 font-semibold py-3 px-4 rounded-lg transition-colors"
                >
                  Back
                </button>
                <button 
                  type="submit"
                  disabled={isSubmitting || ratings.safety === 0 || ratings.professionalism === 0 || ratings.punctuality === 0}
                  className={`w-2/3 text-white font-bold py-3 px-4 rounded-lg transition-colors ${
                    (isSubmitting || ratings.safety === 0 || ratings.professionalism === 0 || ratings.punctuality === 0)
                      ? 'bg-blue-400 cursor-not-allowed' 
                      : 'bg-blue-600 hover:bg-blue-700'
                  }`}
                >
                  {isSubmitting ? 'Submitting...' : 'Submit'}
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
};

export default PassengerEvaluation;