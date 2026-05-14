'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { incidentsApi, BASE_URL } from '@/lib/api-client';
import { Incident } from '@/types';
import { statusColor, capitalize, humanizeSnake, formatDate } from '@/lib/utils';
import { getAuthHeader } from '@/lib/api-client';

export default function PatientIncidents() {
  const [incidents, setIncidents] = useState<Incident[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    incidentsApi.list().then((r) => setIncidents(r.data)).catch(() => {}).finally(() => setLoading(false));
  }, []);

  if (loading) {
    return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">My Incidents</h1>
        <Link href="/patient/incidents/upload" className="bg-primary-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-primary-700 transition-colors flex items-center gap-2">
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M6.827 6.175A2.31 2.31 0 015.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574V18a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 00-1.134-.175 2.31 2.31 0 01-1.64-1.055l-.822-1.316a2.192 2.192 0 00-1.736-1.039 48.774 48.774 0 00-5.232 0 2.192 2.192 0 00-1.736 1.039l-.821 1.316z" /><path strokeLinecap="round" strokeLinejoin="round" d="M16.5 12.75a4.5 4.5 0 11-9 0 4.5 4.5 0 019 0z" /></svg>
          Upload Incident
        </Link>
      </div>

      {incidents.length === 0 ? (
        <div className="text-center py-16">
          <svg className="w-12 h-12 text-gray-300 mx-auto mb-3" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" /></svg>
          <p className="text-gray-500 mb-1">No incidents yet</p>
          <p className="text-sm text-gray-400 mb-4">Upload an injury photo to get an AI assessment</p>
          <Link href="/patient/incidents/upload" className="text-primary-600 font-medium text-sm hover:underline">Upload your first incident</Link>
        </div>
      ) : (
        <div className="space-y-3">
          {incidents.map((inc) => (
            <Link key={inc.id} href={`/patient/incidents/${inc.id}`} className="block rounded-xl bg-white border border-gray-100 shadow-sm p-4 hover:shadow-md transition-shadow">
              <div className="flex items-center gap-4">
                <IncidentThumb id={inc.id} />
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-gray-900 truncate">{inc.title || 'Incident'}</p>
                  <p className="text-sm text-gray-500">
                    {humanizeSnake(inc.injury_type || 'unknown')} • {humanizeSnake(inc.severity || 'unknown')}
                  </p>
                </div>
                <span className={`text-xs font-medium px-2.5 py-1 rounded-full ${statusColor(inc.analysis_status)}`}>
                  {capitalize(inc.analysis_status)}
                </span>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}

function IncidentThumb({ id }: { id: string }) {
  const [src, setSrc] = useState<string | null>(null);
  useEffect(() => {
    const url = incidentsApi.downloadUrl(id);
    const token = typeof window !== 'undefined' ? localStorage.getItem('access_token') : null;
    if (!token) return;
    fetch(url, { headers: { Authorization: `Bearer ${token}` } })
      .then((r) => r.blob())
      .then((blob) => setSrc(URL.createObjectURL(blob)))
      .catch(() => {});
  }, [id]);

  return src ? (
    <div className="w-11 h-11 rounded-xl overflow-hidden flex-shrink-0">
      <img src={src} alt="" className="w-full h-full object-cover" />
    </div>
  ) : (
    <div className="w-11 h-11 rounded-xl bg-orange-50 text-orange-600 flex items-center justify-center flex-shrink-0">
      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z" /></svg>
    </div>
  );
}
