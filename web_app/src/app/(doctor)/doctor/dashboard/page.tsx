'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { authApi, appointmentsApi } from '@/lib/api-client';
import { useAuthStore } from '@/store/auth.store';
import { User, Appointment } from '@/types';
import { format } from 'date-fns';

export default function DoctorDashboardPage() {
  const { setUser } = useAuthStore();
  const [user, setLocalUser] = useState<User | null>(null);
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const [userRes, apptRes] = await Promise.all([
          authApi.me(),
          appointmentsApi.list({ status: 'confirmed' }),
        ]);
        setLocalUser(userRes.data);
        setUser(userRes.data);
        setAppointments(apptRes.data.items ?? apptRes.data);
      } catch {
        // silently fail
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [setUser]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-600" />
      </div>
    );
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-1">
        Welcome, Dr. {user?.full_name ?? 'Doctor'}
      </h1>
      <p className="text-gray-500 mb-8">Here&apos;s your practice overview for today.</p>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 mb-8">
        <Link href="/doctor/appointments" className="card hover:shadow-md transition-shadow">
          <div className="w-10 h-10 bg-blue-500 rounded-lg mb-3" />
          <p className="text-2xl font-bold text-gray-900">{appointments.length}</p>
          <p className="text-sm text-gray-500">Today&apos;s Appointments</p>
        </Link>
        <Link href="/doctor/patients" className="card hover:shadow-md transition-shadow">
          <div className="w-10 h-10 bg-teal-500 rounded-lg mb-3" />
          <p className="text-2xl font-bold text-gray-900">—</p>
          <p className="text-sm text-gray-500">Total Patients</p>
        </Link>
        <Link href="/doctor/reports" className="card hover:shadow-md transition-shadow">
          <div className="w-10 h-10 bg-orange-500 rounded-lg mb-3" />
          <p className="text-2xl font-bold text-gray-900">—</p>
          <p className="text-sm text-gray-500">Pending Reviews</p>
        </Link>
      </div>

      <div className="card">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-gray-900">Upcoming Appointments</h2>
          <Link href="/doctor/appointments" className="text-sm text-primary-600 hover:underline">View all</Link>
        </div>
        {appointments.length === 0 ? (
          <p className="text-gray-500 text-sm">No upcoming appointments.</p>
        ) : (
          <ul className="divide-y divide-gray-100">
            {appointments.slice(0, 5).map((appt) => (
              <li key={appt.id} className="py-3 flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-900">
                    {appt.patient?.full_name ?? appt.patient_id}
                  </p>
                  <p className="text-xs text-gray-500">{format(new Date(appt.scheduled_at), 'PPp')}</p>
                  {appt.reason && <p className="text-xs text-gray-400">{appt.reason}</p>}
                </div>
                <span className="badge bg-blue-100 text-blue-700 capitalize">{appt.status}</span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
