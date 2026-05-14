'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { doctorsApi } from '@/lib/api-client';
import { DoctorProfile } from '@/types';
import { humanizeSnake } from '@/lib/utils';

export default function DoctorProfileView() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [doctor, setDoctor] = useState<DoctorProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    doctorsApi.get(id).then((res) => setDoctor(res.data)).catch(() => {}).finally(() => setLoading(false));
  }, [id]);

  if (loading) {
    return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  if (!doctor) {
    return (
      <div className="flex flex-col items-center justify-center py-20 gap-3">
        <p className="text-gray-500">Doctor not found</p>
        <button onClick={() => router.back()} className="text-primary-600 hover:underline text-sm font-medium">Go back</button>
      </div>
    );
  }

  const dayOrder = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  const dayNames: Record<string, string> = { mon: 'Monday', tue: 'Tuesday', wed: 'Wednesday', thu: 'Thursday', fri: 'Friday', sat: 'Saturday', sun: 'Sunday' };

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <button onClick={() => router.back()} className="text-sm text-gray-500 hover:text-gray-700 flex items-center gap-1">
        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" /></svg>
        Back
      </button>

      {/* Hero */}
      <div className="rounded-2xl bg-gradient-to-br from-primary-600 to-primary-800 p-6 text-white flex items-center gap-5">
        <div className="w-20 h-20 rounded-full border-2 border-white/40 bg-white/20 flex items-center justify-center text-3xl font-bold flex-shrink-0">
          {doctor.user?.full_name?.[0]?.toUpperCase() || 'D'}
        </div>
        <div>
          <h1 className="text-2xl font-bold">Dr. {doctor.user?.full_name || 'Doctor'}</h1>
          <p className="text-white/70 mt-1">{doctor.specialization || 'General'}</p>
          {doctor.rating > 0 && <p className="text-white/80 text-sm mt-1">⭐ {doctor.rating.toFixed(1)}</p>}
        </div>
      </div>

      {/* Info */}
      <div className="rounded-xl bg-white border border-gray-100 shadow-sm divide-y divide-gray-50">
        <div className="px-5 py-3 flex justify-between">
          <span className="text-sm text-gray-500">Specialization</span>
          <span className="text-sm font-medium text-gray-900">{doctor.specialization}</span>
        </div>
        <div className="px-5 py-3 flex justify-between">
          <span className="text-sm text-gray-500">License</span>
          <span className="text-sm font-medium text-gray-900">{doctor.license_number || '—'}</span>
        </div>
        {doctor.availability_timezone && (
          <div className="px-5 py-3 flex justify-between">
            <span className="text-sm text-gray-500">Timezone</span>
            <span className="text-sm font-medium text-gray-900">{doctor.availability_timezone}</span>
          </div>
        )}
      </div>

      {doctor.bio && (
        <div className="rounded-xl bg-white border border-gray-100 shadow-sm p-5">
          <h2 className="font-semibold text-gray-900 mb-2">About</h2>
          <p className="text-sm text-gray-600 leading-relaxed">{doctor.bio}</p>
        </div>
      )}

      {/* Availability */}
      {doctor.available_slots && Object.keys(doctor.available_slots).length > 0 && (
        <div className="rounded-xl bg-white border border-gray-100 shadow-sm p-5">
          <h2 className="font-semibold text-gray-900 mb-3">Weekly Availability</h2>
          <div className="space-y-2">
            {dayOrder.map((day) => {
              const intervals = doctor.available_slots[day] || [];
              return (
                <div key={day} className="flex items-start gap-3">
                  <span className="w-24 text-sm font-medium text-gray-700">{dayNames[day]}</span>
                  <span className="text-sm text-gray-500">
                    {intervals.length > 0 ? intervals.join(', ') : 'Unavailable'}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      )}

      <button
        onClick={() => router.push('/patient/appointments/book')}
        className="w-full py-3 rounded-xl bg-primary-600 text-white font-semibold hover:bg-primary-700 transition-colors"
      >
        Book Appointment with Dr. {doctor.user?.full_name?.split(' ')[0]}
      </button>
    </div>
  );
}
