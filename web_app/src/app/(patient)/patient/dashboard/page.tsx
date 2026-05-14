'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { appointmentsApi, reportsApi, incidentsApi } from '@/lib/api-client';
import { greeting, formatDate, formatTime, isUpcoming, statusColor, capitalize } from '@/lib/utils';
import { Appointment, MedicalReport, Incident } from '@/types';

export default function PatientDashboard() {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [reports, setReports] = useState<MedicalReport[]>([]);
  const [incidents, setIncidents] = useState<Incident[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    setLoading(true);
    setError(null);
    try {
      const [apptRes, reportRes, incidentRes] = await Promise.all([
        appointmentsApi.list(),
        reportsApi.list(),
        incidentsApi.list(),
      ]);
      setAppointments(apptRes.data);
      setReports(reportRes.data);
      setIncidents(incidentRes.data);
    } catch {
      setError('Failed to load data');
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-3">
        <p className="text-gray-500 dark:text-gray-400">{error}</p>
        <button onClick={loadData} className="text-primary-600 hover:underline text-sm font-medium">
          Retry
        </button>
      </div>
    );
  }

  const upcoming = appointments
    .filter((a) => isUpcoming(a.scheduled_at, a.status))
    .sort((a, b) => new Date(a.scheduled_at).getTime() - new Date(b.scheduled_at).getTime());
  const nextAppt = upcoming[0] ?? null;

  return (
    <div className="max-w-5xl mx-auto space-y-6">
      {/* Hero greeting */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-primary-600 to-primary-800 px-8 py-7 text-white">
        <div className="absolute -right-6 -top-6 h-28 w-28 rounded-full bg-white dark:bg-slate-900/[0.08]" />
        <div className="absolute right-16 -bottom-8 h-20 w-20 rounded-full bg-white dark:bg-slate-900/[0.06]" />
        <h1 className="text-2xl font-bold">{greeting()}</h1>
        <p className="text-white/70 text-sm mt-1">{formatDate(new Date().toISOString(), 'EEEE, MMMM d')}</p>
        <div className="mt-3 inline-flex items-center gap-1.5 rounded-full bg-white/20 dark:bg-slate-900/20 border border-white/30 px-3.5 py-1.5 text-xs font-medium text-white">
          <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20"><path d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z"/></svg>
          Your health overview
        </div>
      </div>

      {/* Quick actions */}
      <div className="grid grid-cols-3 gap-3">
        <Link href="/patient/appointments/book" className="flex flex-col items-center gap-2 rounded-2xl border border-primary-100 bg-primary-50 dark:bg-primary-900/30/50 py-4 hover:bg-primary-50 dark:bg-primary-900/30 transition-colors group">
          <svg className="w-6 h-6 text-primary-600" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M12 9v6m3-3H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
          <span className="text-xs font-semibold text-primary-600">Book</span>
        </Link>
        <Link href="/patient/reports?upload=true" className="flex flex-col items-center gap-2 rounded-2xl border border-teal-100 dark:border-teal-900/30 bg-teal-50/50 dark:bg-teal-900/20 py-4 hover:bg-teal-50 dark:hover:bg-teal-900/40 transition-colors group">
          <svg className="w-6 h-6 text-teal-600" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5m-13.5-9L12 3m0 0l4.5 4.5M12 3v13.5" /></svg>
          <span className="text-xs font-semibold text-teal-600">Upload</span>
        </Link>
        <Link href="/patient/incidents?upload=true" className="flex flex-col items-center gap-2 rounded-2xl border border-orange-100 dark:border-orange-900/30 bg-orange-50/50 dark:bg-orange-900/20 py-4 hover:bg-orange-50 dark:hover:bg-orange-900/40 transition-colors group">
          <svg className="w-6 h-6 text-orange-600" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" /></svg>
          <span className="text-xs font-semibold text-orange-600">Incident</span>
        </Link>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-3">
        {[
          { value: upcoming.length, label: 'Upcoming', color: 'text-primary-600 bg-primary-50 dark:bg-primary-900/30', icon: '📅' },
          { value: reports.length, label: 'Reports', color: 'text-teal-600 bg-teal-50 dark:bg-teal-900/30', icon: '📁' },
          { value: incidents.length, label: 'Incidents', color: 'text-orange-600 bg-orange-50 dark:bg-orange-900/30', icon: '🩹' },
        ].map((s) => (
          <div key={s.label} className="rounded-2xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-4 flex items-center gap-3">
            <span className={`text-lg w-10 h-10 rounded-xl flex items-center justify-center ${s.color}`}>{s.icon}</span>
            <div>
              <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">{s.value}</p>
              <p className="text-xs text-gray-500 dark:text-gray-400">{s.label}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Next appointment */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100">Next Appointment</h2>
          <Link href="/patient/appointments" className="text-sm text-primary-600 hover:underline font-medium">See All</Link>
        </div>
        {nextAppt ? (
          <Link href="/patient/appointments" className="block rounded-2xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-4 hover:shadow-md transition-shadow">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-primary-500 to-primary-700 flex flex-col items-center justify-center text-white flex-shrink-0">
                <span className="text-lg font-bold leading-none">{formatDate(nextAppt.scheduled_at, 'd')}</span>
                <span className="text-[10px] font-semibold uppercase opacity-80">{formatDate(nextAppt.scheduled_at, 'MMM')}</span>
              </div>
              <div className="min-w-0 flex-1">
                <p className="font-semibold text-gray-900 dark:text-gray-100 truncate">{nextAppt.reason || 'Consultation'}</p>
                <p className="text-sm text-gray-500 dark:text-gray-400">{formatTime(nextAppt.scheduled_at)}, {formatDate(nextAppt.scheduled_at, 'EEEE')}</p>
              </div>
              <span className={`text-xs font-medium px-2.5 py-1 rounded-full ${statusColor(nextAppt.status)}`}>
                {capitalize(nextAppt.status)}
              </span>
            </div>
          </Link>
        ) : (
          <div className="rounded-2xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-4 flex items-center gap-4">
            <div className="w-11 h-11 rounded-xl bg-gray-100 dark:bg-slate-800 flex items-center justify-center">
              <svg className="w-5 h-5 text-gray-400 dark:text-gray-500" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5" /></svg>
            </div>
            <div className="flex-1">
              <p className="font-medium text-gray-900 dark:text-gray-100">No upcoming appointments</p>
              <p className="text-sm text-gray-500 dark:text-gray-400">Book one to get started</p>
            </div>
            <Link href="/patient/appointments/book" className="text-sm font-medium text-primary-600 hover:underline">Book</Link>
          </div>
        )}
      </div>

      {/* Recent reports */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100">Recent Reports</h2>
          <Link href="/patient/reports" className="text-sm text-primary-600 hover:underline font-medium">See All</Link>
        </div>
        {reports.length === 0 ? (
          <div className="rounded-2xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-4 flex items-center gap-4">
            <svg className="w-6 h-6 text-gray-400 dark:text-gray-500" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M3.75 9.776c.112-.017.227-.026.344-.026h15.812c.117 0 .232.009.344.026m-16.5 0a2.25 2.25 0 00-1.883 2.542l.857 6a2.25 2.25 0 002.227 1.932H19.05a2.25 2.25 0 002.227-1.932l.857-6a2.25 2.25 0 00-1.883-2.542m-16.5 0V6A2.25 2.25 0 016 3.75h3.879a1.5 1.5 0 011.06.44l2.122 2.12a1.5 1.5 0 001.06.44H18A2.25 2.25 0 0120.25 9v.776" /></svg>
            <p className="flex-1 text-gray-500 dark:text-gray-400">No reports yet</p>
            <Link href="/patient/reports?upload=true" className="text-sm font-medium text-primary-600 hover:underline">Upload</Link>
          </div>
        ) : (
          <div className="flex gap-3 overflow-x-auto pb-2">
            {reports.slice(0, 4).map((r) => (
              <Link key={r.id} href={`/patient/reports/${r.id}`} className="flex-shrink-0 w-36 rounded-2xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-3 hover:shadow-md transition-shadow">
                <span className="text-primary-600">📄</span>
                <p className="text-sm font-semibold text-gray-900 dark:text-gray-100 mt-2 truncate">{r.title || r.file_name || 'Report'}</p>
                <span className={`inline-block text-[10px] font-medium mt-1 px-2 py-0.5 rounded-full ${statusColor(r.ocr_status)}`}>
                  {capitalize(r.ocr_status === 'extracted' ? 'Ready' : r.ocr_status)}
                </span>
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
