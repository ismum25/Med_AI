'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { incidentsApi } from '@/lib/api-client';
import { Incident } from '@/types';
import { formatDateTime, statusColor, capitalize, humanizeSnake } from '@/lib/utils';
import toast from 'react-hot-toast';

export default function IncidentDetail() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [incident, setIncident] = useState<Incident | null>(null);
  const [imageSrc, setImageSrc] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadData();
  }, [id]);

  async function loadData() {
    setLoading(true);
    try {
      const [incRes] = await Promise.all([incidentsApi.get(id)]);
      setIncident(incRes.data);
      // Load image
      const url = incidentsApi.downloadUrl(id);
      const token = localStorage.getItem('access_token');
      if (token) {
        const imgRes = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
        if (imgRes.ok) {
          const blob = await imgRes.blob();
          setImageSrc(URL.createObjectURL(blob));
        }
      }
    } catch { /* ignore */ }
    setLoading(false);
  }

  async function handleDelete() {
    if (!confirm('Are you sure you want to delete this incident?')) return;
    try {
      await incidentsApi.delete(id);
      toast.success('Incident deleted');
      router.push('/patient/incidents');
    } catch {
      toast.error('Failed to delete incident');
    }
  }

  if (loading) {
    return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  if (!incident) {
    return (
      <div className="text-center py-20">
        <p className="text-gray-500 dark:text-gray-400 dark:text-gray-500">Incident not found</p>
        <button onClick={() => router.back()} className="text-primary-600 hover:underline text-sm mt-2">Go back</button>
      </div>
    );
  }

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <button onClick={() => router.back()} className="text-sm text-gray-500 dark:text-gray-400 dark:text-gray-500 hover:text-gray-700 dark:text-gray-300 flex items-center gap-1">
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" /></svg>
          Back
        </button>
        <button onClick={handleDelete} className="text-sm font-medium text-red-600 hover:text-red-700 flex items-center gap-1">
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" /></svg>
          Delete
        </button>
      </div>

      {/* Image */}
      {imageSrc ? (
        <div className="rounded-2xl overflow-hidden">
          <img src={imageSrc} alt={incident.title || 'Incident'} className="w-full max-h-80 object-cover" />
        </div>
      ) : (
        <div className="rounded-2xl bg-gray-100 dark:bg-slate-800 h-52 flex items-center justify-center">
          <svg className="w-12 h-12 text-gray-400 dark:text-gray-500" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909M3.75 21h16.5a2.25 2.25 0 002.25-2.25V5.25a2.25 2.25 0 00-2.25-2.25H3.75a2.25 2.25 0 00-2.25 2.25v13.5a2.25 2.25 0 002.25 2.25z" /></svg>
        </div>
      )}

      {/* Title + status */}
      <div className="rounded-xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-5">
        <h1 className="text-xl font-bold text-gray-900 dark:text-gray-100">{incident.title || 'Incident'}</h1>
        <span className={`inline-block text-xs font-medium mt-2 px-3 py-1 rounded-full ${statusColor(incident.analysis_status)}`}>
          {capitalize(incident.analysis_status)}
        </span>
      </div>

      {/* Meta */}
      <div className="rounded-xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-5 space-y-3">
        {[
          { icon: '⚠️', label: 'Injury Type', value: humanizeSnake(incident.injury_type || 'unknown') },
          { icon: '🩺', label: 'Severity', value: humanizeSnake(incident.severity || 'unknown') },
          { icon: '📍', label: 'Body Area', value: humanizeSnake(incident.body_area || 'unknown') },
          { icon: '🕐', label: 'Uploaded', value: formatDateTime(incident.created_at) },
        ].map((row) => (
          <div key={row.label} className="flex items-center justify-between py-1.5 border-b border-gray-50 dark:border-slate-800/50 last:border-0">
            <span className="text-sm text-gray-500 dark:text-gray-400 dark:text-gray-500 flex items-center gap-2">{row.icon} {row.label}</span>
            <span className="text-sm font-medium text-gray-900 dark:text-gray-100">{row.value}</span>
          </div>
        ))}
      </div>

      {/* AI Description */}
      {(incident.summary || incident.description) && (
        <div className="rounded-xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-5">
          <h2 className="font-semibold text-gray-900 dark:text-gray-100 mb-2">AI Description</h2>
          <p className="text-sm text-gray-600 dark:text-gray-400 dark:text-gray-500 leading-relaxed">{incident.description || incident.summary}</p>
        </div>
      )}

      {/* Notes */}
      {incident.notes && (
        <div className="rounded-xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-5">
          <h2 className="font-semibold text-gray-900 dark:text-gray-100 mb-2">Your Notes</h2>
          <p className="text-sm text-gray-600 dark:text-gray-400 dark:text-gray-500">{incident.notes}</p>
        </div>
      )}
    </div>
  );
}
