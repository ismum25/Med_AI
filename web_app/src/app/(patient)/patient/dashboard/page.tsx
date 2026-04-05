'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { authApi, appointmentsApi } from '@/lib/api-client';
import { useAuthStore } from '@/store/auth.store';
import { User, Appointment } from '@/types';
import { format } from 'date-fns';

export default function PatientDashboardPage() {
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

  const stats = [
    { label: 'Upcoming Appointments', value: appointments.length, href: '/patient/appointments', color: 'bg-blue-500' },
    { label: 'My Reports', value: '—', href: '/patient/reports', color: 'bg-green-500' },
    { label: 'AI Consultations', value: '—', href: '/patient/chat', color: 'bg-purple-500' },
  ];

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
        Welcome back, {user?.full_name ?? 'Patient'}
      </h1>
      <p className="text-gray-500 mb-8">Here&apos;s an overview of your health dashboard.</p>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 mb-8">
        {stats.map((s) => (
          <Link key={s.label} href={s.href} className="card hover:shadow-md transition-shadow">
            <div className={`w-10 h-10 ${s.color} rounded-lg mb-3`} />
            <p className="text-2xl font-bold text-gray-900">{s.value}</p>
            <p className="text-sm text-gray-500">{s.label}</p>
          </Link>
        ))}
      </div>

      <div className="card">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-gray-900">Upcoming Appointments</h2>
          <Link href="/patient/appointments" className="text-sm text-primary-600 hover:underline">
            View all
          </Link>
        </div>
        {appointments.length === 0 ? (
          <p className="text-gray-500 text-sm">No upcoming appointments.</p>
        ) : (
          <ul className="divide-y divide-gray-100">
            {appointments.slice(0, 5).map((appt) => (
              <li key={appt.id} className="py-3 flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-900">
                    Dr. {appt.doctor?.full_name ?? appt.doctor_id}
                  </p>
                  <p className="text-xs text-gray-500">
                    {format(new Date(appt.scheduled_at), 'PPp')}
                  </p>
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
