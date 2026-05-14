'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { appointmentsApi, doctorsApi } from '@/lib/api-client';
import { Appointment, DoctorListItem } from '@/types';
import { formatDate, formatTime, statusColor, capitalize } from '@/lib/utils';
import toast from 'react-hot-toast';

const STATUS_TABS = ['all', 'pending', 'confirmed', 'completed', 'cancelled'];

export default function PatientAppointments() {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [doctors, setDoctors] = useState<DoctorListItem[]>([]);
  const [specializations, setSpecializations] = useState<string[]>([]);
  const [selectedSpec, setSelectedSpec] = useState('');
  const [tab, setTab] = useState('all');
  const [loading, setLoading] = useState(true);

  useEffect(() => { load(); }, []);

  async function load() {
    setLoading(true);
    try {
      const [apptRes, docRes, specRes] = await Promise.all([
        appointmentsApi.list(),
        doctorsApi.list(),
        doctorsApi.specializations(),
      ]);
      setAppointments(apptRes.data);
      setDoctors(docRes.data);
      setSpecializations(specRes.data);
    } catch { /* ignore */ }
    setLoading(false);
  }

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

  const filtered = tab === 'all' ? appointments : appointments.filter((a) => a.status === tab);
  const filteredDoctors = selectedSpec ? doctors.filter((d) => d.specialization === selectedSpec) : doctors;

  if (loading) {
    return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  return (
    <div className="max-w-5xl mx-auto space-y-8">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Appointments</h1>
        <Link href="/patient/appointments/book" className="bg-primary-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-primary-700 transition-colors">
          Book Appointment
        </Link>
      </div>

      {/* Status tabs */}
      <div className="flex gap-1 bg-gray-100 rounded-lg p-1">
        {STATUS_TABS.map((s) => (
          <button
            key={s}
            onClick={() => setTab(s)}
            className={`flex-1 px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
              tab === s ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            {capitalize(s)}
          </button>
        ))}
      </div>

      {/* Appointment list */}
      <div className="space-y-3">
        {filtered.length === 0 ? (
          <div className="text-center py-12 text-gray-500">No {tab === 'all' ? '' : tab} appointments</div>
        ) : (
          filtered.map((a) => (
            <div key={a.id} className="rounded-xl bg-white border border-gray-100 shadow-sm p-4">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-primary-500 to-primary-700 flex flex-col items-center justify-center text-white flex-shrink-0">
                  <span className="text-lg font-bold leading-none">{formatDate(a.scheduled_at, 'd')}</span>
                  <span className="text-[10px] font-semibold uppercase opacity-80">{formatDate(a.scheduled_at, 'MMM')}</span>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-gray-900 truncate">{a.reason || 'Consultation'}</p>
                  <p className="text-sm text-gray-500">{formatTime(a.scheduled_at)}, {formatDate(a.scheduled_at, 'EEEE, MMM d')}</p>
                </div>
                <span className={`text-xs font-medium px-2.5 py-1 rounded-full ${statusColor(a.status)}`}>
                  {capitalize(a.status)}
                </span>
                {(a.status === 'pending' || a.status === 'confirmed') && (
                  <button
                    onClick={() => handleCancel(a.id)}
                    className="text-red-600 hover:text-red-700 text-sm font-medium"
                  >
                    Cancel
                  </button>
                )}
              </div>
            </div>
          ))
        )}
      </div>

      {/* Find a Doctor */}
      <div>
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Find a Doctor</h2>
        <div className="mb-4">
          <select
            value={selectedSpec}
            onChange={(e) => setSelectedSpec(e.target.value)}
            className="border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-primary-500"
          >
            <option value="">All Specializations</option>
            {specializations.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {filteredDoctors.map((d) => (
            <Link key={d.user_id} href={`/patient/appointments/doctor/${d.user_id}`} className="rounded-xl bg-white border border-gray-100 shadow-sm p-4 hover:shadow-md transition-shadow">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center text-sm font-bold flex-shrink-0">
                  {d.full_name?.[0]?.toUpperCase() || 'D'}
                </div>
                <div className="min-w-0">
                  <p className="font-semibold text-gray-900 truncate">{d.full_name}</p>
                  <p className="text-sm text-gray-500">{d.specialization}</p>
                </div>
              </div>
              {d.rating > 0 && (
                <div className="mt-2 flex items-center gap-1 text-sm text-amber-600">
                  <span>⭐</span>
                  <span>{d.rating.toFixed(1)}</span>
                </div>
              )}
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}
