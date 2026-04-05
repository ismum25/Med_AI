'use client';

import { useEffect, useState } from 'react';
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

export default function DoctorAppointmentsPage() {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('');

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

  async function handleStatusUpdate(id: string, status: AppointmentStatus) {
    try {
      await appointmentsApi.update(id, { status });
      toast.success('Status updated');
      load();
    } catch {
      toast.error('Failed to update status');
    }
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Appointments</h1>

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
        </div>
      ) : (
        <div className="space-y-3">
          {appointments.map((appt) => (
            <div key={appt.id} className="card">
              <div className="flex items-start justify-between">
                <div>
                  <p className="font-medium text-gray-900">
                    {appt.patient?.full_name ?? appt.patient_id}
                  </p>
                  <p className="text-sm text-gray-500">{format(new Date(appt.scheduled_at), 'PPp')}</p>
                  {appt.reason && <p className="text-xs text-gray-400 mt-1">{appt.reason}</p>}
                </div>
                <span className={`badge ${STATUS_COLORS[appt.status]} capitalize`}>{appt.status}</span>
              </div>
              {(appt.status === 'pending' || appt.status === 'confirmed') && (
                <div className="flex gap-2 mt-3 pt-3 border-t border-gray-100">
                  {appt.status === 'pending' && (
                    <button
                      onClick={() => handleStatusUpdate(appt.id, 'confirmed')}
                      className="btn-primary text-sm py-1 px-4 w-auto"
                    >
                      Confirm
                    </button>
                  )}
                  {appt.status === 'confirmed' && (
                    <button
                      onClick={() => handleStatusUpdate(appt.id, 'completed')}
                      className="btn-primary text-sm py-1 px-4 w-auto"
                    >
                      Mark Complete
                    </button>
                  )}
                  <button
                    onClick={() => handleStatusUpdate(appt.id, 'no_show')}
                    className="btn-secondary text-sm py-1 px-4 w-auto"
                  >
                    No Show
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
