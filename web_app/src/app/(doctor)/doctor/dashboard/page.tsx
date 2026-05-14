'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { appointmentsApi, reportsApi, authApi } from '@/lib/api-client';
import { greeting, formatDate, formatTime, statusColor, capitalize, isTodayAppointment, timeAgo } from '@/lib/utils';
import { Appointment, MedicalReport } from '@/types';

export default function DoctorDashboard() {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [pendingReports, setPendingReports] = useState<MedicalReport[]>([]);
  const [name, setName] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    try {
      const [apptRes, reviewRes, meRes] = await Promise.all([
        appointmentsApi.list(),
        reportsApi.pendingReview(),
        authApi.me(),
      ]);
      setAppointments(apptRes.data);
      setPendingReports(reviewRes.data);
      setName(meRes.data?.full_name || '');
    } catch { /* ignore */ }
    setLoading(false);
  }

  if (loading) {
    return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  const today = appointments.filter((a) => isTodayAppointment(a.scheduled_at, a.status));

  return (
    <div className="max-w-5xl mx-auto space-y-6">
      {/* Hero */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-primary-600 to-primary-800 px-8 py-7 text-white">
        <div className="absolute -right-6 -top-6 h-28 w-28 rounded-full bg-white dark:bg-slate-900/[0.08]" />
        <h1 className="text-2xl font-bold">{greeting()}, Dr. {name.split(' ')[0] || 'Doctor'}</h1>
        <p className="text-white/70 text-sm mt-1">{formatDate(new Date().toISOString(), 'EEEE, MMMM d')}</p>
        <div className="mt-3 inline-flex items-center gap-1.5 rounded-full bg-white dark:bg-slate-900/[0.18] border border-white/[0.28] px-3.5 py-1.5 text-xs font-medium">
          🩺 Your practice overview
        </div>
      </div>

      {/* Quick actions */}
      <div className="grid grid-cols-3 gap-3">
        <Link href="/doctor/appointments" className="flex flex-col items-center gap-2 rounded-2xl border border-primary-100 bg-primary-50 dark:bg-primary-900/30/50 py-4 hover:bg-primary-50 dark:bg-primary-900/30 transition-colors">
          <span className="text-xl">📅</span>
          <span className="text-xs font-semibold text-primary-600">Schedule</span>
        </Link>
        <Link href="/doctor/review" className="flex flex-col items-center gap-2 rounded-2xl border border-violet-100 dark:border-violet-900/30 bg-violet-50/50 dark:bg-violet-900/20 py-4 hover:bg-violet-50 dark:hover:bg-violet-900/40 transition-colors">
          <span className="text-xl">📋</span>
          <span className="text-xs font-semibold text-violet-600">Review</span>
        </Link>
        <Link href="/doctor/patients" className="flex flex-col items-center gap-2 rounded-2xl border border-teal-100 dark:border-teal-900/30 bg-teal-50/50 dark:bg-teal-900/20 py-4 hover:bg-teal-50 dark:hover:bg-teal-900/40 transition-colors">
          <span className="text-xl">👥</span>
          <span className="text-xs font-semibold text-teal-600">Patients</span>
        </Link>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-3">
        <div className="rounded-2xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-4 flex items-center gap-3">
          <span className="text-lg w-10 h-10 rounded-xl bg-primary-50 dark:bg-primary-900/30 text-primary-600 flex items-center justify-center">📅</span>
          <div>
            <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">{today.length}</p>
            <p className="text-xs text-gray-500 dark:text-gray-400">Today&apos;s Appointments</p>
          </div>
        </div>
        <div className="rounded-2xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-4 flex items-center gap-3">
          <span className="text-lg w-10 h-10 rounded-xl bg-violet-50 dark:bg-violet-900/30 text-violet-600 dark:text-violet-400 flex items-center justify-center">📋</span>
          <div>
            <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">{pendingReports.length}</p>
            <p className="text-xs text-gray-500 dark:text-gray-400">Pending Reviews</p>
          </div>
        </div>
      </div>

      {/* Today's schedule */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100">Today&apos;s Schedule</h2>
          <Link href="/doctor/appointments" className="text-sm text-primary-600 hover:underline font-medium">See All</Link>
        </div>
        {today.length === 0 ? (
          <div className="rounded-xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-4 text-center text-gray-500 dark:text-gray-400 text-sm">
            No appointments today
          </div>
        ) : (
          <div className="space-y-2">
            {today.slice(0, 5).map((a) => (
              <div key={a.id} className="rounded-xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-4 flex items-center gap-4">
                <div className="w-10 h-10 rounded-full bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-400 flex items-center justify-center text-sm font-bold flex-shrink-0">
                  {a.patient?.full_name?.[0]?.toUpperCase() || 'P'}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-gray-900 dark:text-gray-100 truncate">{a.patient?.full_name || 'Patient'}</p>
                  <p className="text-sm text-gray-500 dark:text-gray-400">{formatTime(a.scheduled_at)} • {a.reason || 'Consultation'}</p>
                </div>
                <span className={`text-xs font-medium px-2.5 py-1 rounded-full ${statusColor(a.status)}`}>
                  {capitalize(a.status)}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Reports awaiting review */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100">Reports Awaiting Review</h2>
          <Link href="/doctor/review" className="text-sm text-primary-600 hover:underline font-medium">See All</Link>
        </div>
        {pendingReports.length === 0 ? (
          <div className="rounded-xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-4 text-center text-gray-500 dark:text-gray-400 text-sm">
            No reports waiting
          </div>
        ) : (
          <div className="space-y-2">
            {pendingReports.slice(0, 5).map((r) => (
              <Link key={r.id} href={`/doctor/review/${r.id}`} className="block rounded-xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-4 hover:shadow-md transition-shadow">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-violet-50 dark:bg-violet-900/30 text-violet-600 dark:text-violet-400 flex items-center justify-center flex-shrink-0">📄</div>
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-gray-900 dark:text-gray-100 truncate">{r.title || r.file_name || 'Medical Report'}</p>
                    <p className="text-sm text-gray-500 dark:text-gray-400 capitalize">{r.report_type?.replace(/_/g, ' ') || 'Report'}</p>
                  </div>
                  <span className="text-xs text-gray-400 dark:text-gray-500">{timeAgo(r.created_at)}</span>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
