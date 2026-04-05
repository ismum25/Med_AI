'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import toast from 'react-hot-toast';
import { appointmentsApi } from '@/lib/api-client';
import { Appointment, AppointmentStatus } from '@/types';
import { format } from 'date-fns';

const STATUS_COLORS: Record<AppointmentStatus, string> = {
  pending: 'bg-yellow-100 text-yellow-700',
  confirmed: 'bg-blue-100 text-blue-700',
  cancelled: 'bg-red-100 text-red-700',
  completed: 'bg-green-100 text-green-700',
  no_show: 'bg-gray-100 text-gray-700',
};

export default function PatientAppointmentsPage() {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<string>('');

  async function load() {
    setLoading(true);
    try {
      const { data } = await appointmentsApi.list(filter ? { status: filter } : undefined);
      setAppointments(data.items ?? data);
    } catch {
      toast.error('Failed to load appointments');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, [filter]); // eslint-disable-line react-hooks/exhaustive-deps

  async function handleCancel(id: string) {
    if (!confirm('Cancel this appointment?')) return;
    try {
      await appointmentsApi.cancel(id);
      toast.success('Appointment cancelled');
      load();
    } catch {
      toast.error('Failed to cancel');
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Appointments</h1>
        <Link href="/patient/appointments/book" className="btn-primary">
          + Book Appointment
        </Link>
      </div>

      <div className="mb-4 flex gap-2 flex-wrap">
        {['', 'pending', 'confirmed', 'completed', 'cancelled'].map((s) => (
          <button
            key={s}
            onClick={() => setFilter(s)}
            className={`px-3 py-1 rounded-full text-sm font-medium border transition-colors ${
              filter === s ? 'bg-primary-600 text-white border-primary-600' : 'bg-white text-gray-600 border-gray-300 hover:bg-gray-50'
            }`}
          >
            {s === '' ? 'All' : s.charAt(0).toUpperCase() + s.slice(1)}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="flex justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" />
        </div>
      ) : appointments.length === 0 ? (
        <div className="card text-center py-12">
          <p className="text-gray-500">No appointments found.</p>
          <Link href="/patient/appointments/book" className="btn-primary mt-4 inline-block w-auto px-6">
            Book your first appointment
          </Link>
        </div>
      ) : (
        <div className="space-y-3">
          {appointments.map((appt) => (
            <div key={appt.id} className="card flex items-center justify-between">
              <div>
                <p className="font-medium text-gray-900">Dr. {appt.doctor?.full_name ?? appt.doctor_id}</p>
                <p className="text-sm text-gray-500">{format(new Date(appt.scheduled_at), 'PPp')}</p>
                {appt.reason && <p className="text-xs text-gray-400 mt-1">{appt.reason}</p>}
              </div>
              <div className="flex items-center gap-3">
                <span className={`badge ${STATUS_COLORS[appt.status]} capitalize`}>{appt.status}</span>
                {(appt.status === 'pending' || appt.status === 'confirmed') && (
                  <button
                    onClick={() => handleCancel(appt.id)}
                    className="text-sm text-red-600 hover:underline"
                  >
                    Cancel
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
