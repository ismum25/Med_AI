'use client';

import { useEffect, useState, useRef } from 'react';
import { useSearchParams } from 'next/navigation';
import { incidentsApi } from '@/lib/api-client';
import { Incident } from '@/types';
import { statusColor, capitalize, humanizeSnake, formatDateTime } from '@/lib/utils';
import toast from 'react-hot-toast';

export default function PatientIncidents() {
  const [incidents, setIncidents] = useState<Incident[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [showUploadModal, setShowUploadModal] = useState(false);
  const searchParams = useSearchParams();

  useEffect(() => {
    loadIncidents();
    if (searchParams.get('upload') === 'true') {
      setShowUploadModal(true);
    }
  }, [searchParams]);

  function loadIncidents() {
    incidentsApi.list().then((r) => {
      setIncidents(r.data);
      if (r.data.length > 0 && !selectedId) {
        setSelectedId(r.data[0].id);
      }
    }).catch(() => {}).finally(() => setLoading(false));
  }

  if (loading) {
    return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  return (
    <div className="flex h-[calc(100vh-4rem)] w-full gap-6 overflow-hidden px-4">
      {/* Left List */}
      <div className="w-1/3 flex flex-col min-w-[320px] max-w-sm">
        <div className="flex items-center justify-between mb-4 flex-shrink-0">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">My Incidents</h1>
          <button onClick={() => setShowUploadModal(true)} className="bg-primary-600 text-white px-3 py-1.5 rounded-lg text-sm font-medium hover:bg-primary-700 transition-colors flex items-center gap-1.5 shadow-sm">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
            Upload
          </button>
        </div>

        {incidents.length === 0 ? (
          <div className="text-center py-16 flex-1">
            <svg className="w-12 h-12 text-gray-300 mx-auto mb-3" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" /></svg>
            <p className="text-gray-500 dark:text-gray-400 mb-1">No incidents yet</p>
            <button onClick={() => setShowUploadModal(true)} className="text-primary-600 font-medium text-sm hover:underline">Upload your first incident</button>
          </div>
        ) : (
          <div className="flex-1 overflow-y-auto space-y-3 pr-2 pb-4">
            {incidents.map((inc) => (
              <button 
                key={inc.id} 
                onClick={() => setSelectedId(inc.id)}
                className={`w-full text-left block rounded-xl border p-4 transition-all ${
                  selectedId === inc.id 
                    ? 'bg-primary-50 dark:bg-primary-900/20 border-primary-200 dark:border-primary-800 shadow-sm' 
                    : 'bg-white dark:bg-slate-900 border-gray-100 dark:border-slate-800 hover:shadow-md'
                }`}
              >
                <div className="flex items-center gap-4">
                  <IncidentThumb id={inc.id} />
                  <div className="flex-1 min-w-0">
                    <p className={`font-semibold truncate ${selectedId === inc.id ? 'text-primary-900 dark:text-primary-100' : 'text-gray-900 dark:text-gray-100'}`}>
                      {inc.title || 'Incident'}
                    </p>
                    <p className={`text-sm mt-0.5 ${selectedId === inc.id ? 'text-primary-700/80 dark:text-primary-300' : 'text-gray-500 dark:text-gray-400'}`}>
                      {humanizeSnake(inc.injury_type || 'unknown')} • {humanizeSnake(inc.severity || 'unknown')}
                    </p>
                    <div className="mt-1.5">
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-md ${statusColor(inc.analysis_status)}`}>
                        {capitalize(inc.analysis_status)}
                      </span>
                    </div>
                  </div>
                </div>
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Right Detail */}
      <div className="flex-1 bg-white dark:bg-slate-900 rounded-2xl border border-gray-100 dark:border-slate-800 shadow-sm overflow-hidden flex flex-col relative">
        {selectedId ? (
          <IncidentDetailView id={selectedId} onDelete={() => {
            setSelectedId(null);
            loadIncidents();
          }} />
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center text-gray-400">
            <svg className="w-16 h-16 mb-4 text-gray-200 dark:text-gray-800" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" /></svg>
            <p>Select an incident to view details</p>
          </div>
        )}
      </div>

      {showUploadModal && (
        <IncidentUploadModal 
          onClose={() => setShowUploadModal(false)}
          onSuccess={(newId) => {
            setShowUploadModal(false);
            setSelectedId(newId);
            loadIncidents();
          }}
        />
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
    <div className="w-12 h-12 rounded-xl overflow-hidden flex-shrink-0 shadow-sm border border-gray-100 dark:border-slate-700">
      <img src={src} alt="" className="w-full h-full object-cover" />
    </div>
  ) : (
    <div className="w-12 h-12 rounded-xl bg-orange-50 dark:bg-orange-900/30 text-orange-600 dark:text-orange-400 flex items-center justify-center flex-shrink-0 shadow-sm border border-orange-100 dark:border-orange-800">
      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z" /></svg>
    </div>
  );
}

function IncidentDetailView({ id, onDelete }: { id: string, onDelete: () => void }) {
  const [incident, setIncident] = useState<Incident | null>(null);
  const [imageSrc, setImageSrc] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    incidentsApi.get(id).then((res) => {
      setIncident(res.data);
      const url = incidentsApi.downloadUrl(id);
      const token = localStorage.getItem('access_token');
      if (token) {
        fetch(url, { headers: { Authorization: `Bearer ${token}` } })
          .then(r => r.ok ? r.blob() : Promise.reject())
          .then(blob => setImageSrc(URL.createObjectURL(blob)))
          .catch(() => {});
      }
    }).finally(() => setLoading(false));
  }, [id]);

  async function handleDelete() {
    if (!confirm('Are you sure you want to delete this incident?')) return;
    try {
      await incidentsApi.delete(id);
      toast.success('Incident deleted');
      onDelete();
    } catch {
      toast.error('Failed to delete incident');
    }
  }

  if (loading) return <div className="flex justify-center items-center h-full"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  if (!incident) return <div className="text-center py-20 text-gray-500">Incident not found</div>;

  return (
    <div className="flex-1 overflow-y-auto p-6 space-y-6">
      <div className="flex items-start justify-between pb-4 border-b border-gray-100 dark:border-slate-800">
        <div>
          <h2 className="text-2xl font-bold text-gray-900 dark:text-gray-100">{incident.title || 'Incident'}</h2>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Uploaded {formatDateTime(incident.created_at)}</p>
        </div>
        <div className="flex flex-col items-end gap-2">
          <span className={`text-xs font-medium px-3 py-1 rounded-full ${statusColor(incident.analysis_status)}`}>
            {capitalize(incident.analysis_status)}
          </span>
          <button onClick={handleDelete} className="text-xs font-medium text-red-600 hover:text-red-700 bg-red-50 dark:bg-red-900/20 px-3 py-1.5 rounded-lg flex items-center gap-1">
            <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" /></svg>
            Delete
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Left column: Image & Meta */}
        <div className="space-y-6">
          {imageSrc ? (
            <div className="rounded-2xl overflow-hidden border border-gray-100 dark:border-slate-800 shadow-sm">
              <img src={imageSrc} alt={incident.title || 'Incident'} className="w-full h-auto object-cover max-h-64" />
            </div>
          ) : (
            <div className="rounded-2xl bg-gray-100 dark:bg-slate-800 h-48 flex items-center justify-center border border-gray-200 dark:border-slate-700">
              <svg className="w-10 h-10 text-gray-400" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909M3.75 21h16.5a2.25 2.25 0 002.25-2.25V5.25a2.25 2.25 0 00-2.25-2.25H3.75a2.25 2.25 0 00-2.25 2.25v13.5a2.25 2.25 0 002.25 2.25z" /></svg>
            </div>
          )}

          <div className="bg-gray-50 dark:bg-slate-950 p-4 rounded-xl border border-gray-100 dark:border-slate-800 grid grid-cols-2 gap-4">
            <div>
              <p className="text-xs text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-1 flex items-center gap-1.5"><span>⚠️</span> Injury Type</p>
              <p className="text-sm font-semibold text-gray-900 dark:text-gray-100">{humanizeSnake(incident.injury_type || 'unknown')}</p>
            </div>
            <div>
              <p className="text-xs text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-1 flex items-center gap-1.5"><span>🩺</span> Severity</p>
              <p className="text-sm font-semibold text-gray-900 dark:text-gray-100">{humanizeSnake(incident.severity || 'unknown')}</p>
            </div>
            <div className="col-span-2">
              <p className="text-xs text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-1 flex items-center gap-1.5"><span>📍</span> Body Area</p>
              <p className="text-sm font-semibold text-gray-900 dark:text-gray-100">{humanizeSnake(incident.body_area || 'unknown')}</p>
            </div>
          </div>
        </div>

        {/* Right column: Description & Notes */}
        <div className="space-y-6">
          {(incident.summary || incident.description) && (
            <div>
              <h3 className="font-semibold text-gray-900 dark:text-gray-100 mb-2 flex items-center gap-2">
                <svg className="w-5 h-5 text-primary-500" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" /></svg>
                AI Analysis
              </h3>
              <p className="text-sm text-gray-600 dark:text-gray-400 leading-relaxed bg-white dark:bg-slate-900">
                {incident.description || incident.summary}
              </p>
            </div>
          )}

          {incident.notes && (
            <div className="bg-orange-50 dark:bg-orange-950/20 border border-orange-100 dark:border-orange-900/30 p-4 rounded-xl">
              <h3 className="font-semibold text-orange-900 dark:text-orange-200 mb-1 flex items-center gap-2">
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L6.832 19.82a4.5 4.5 0 01-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 011.13-1.897L16.863 4.487zm0 0L19.5 7.125" /></svg>
                Your Notes
              </h3>
              <p className="text-sm text-orange-800 dark:text-orange-300 leading-relaxed">{incident.notes}</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function IncidentUploadModal({ onClose, onSuccess }: { onClose: () => void, onSuccess: (id: string) => void }) {
  const fileRef = useRef<HTMLInputElement>(null);
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [title, setTitle] = useState('');
  const [notes, setNotes] = useState('');
  const [uploading, setUploading] = useState(false);

  function handleFile(f: File | null) {
    setFile(f);
    if (f) {
      const url = URL.createObjectURL(f);
      setPreview(url);
    } else {
      setPreview(null);
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!file) return;
    setUploading(true);
    try {
      const formData = new FormData();
      formData.append('file', file);
      if (title.trim()) formData.append('title', title.trim());
      if (notes.trim()) formData.append('notes', notes.trim());
      const res = await incidentsApi.upload(formData);
      const id = res.data?.id;
      toast.success('Incident uploaded and analyzed');
      if (id) onSuccess(id);
      else onClose();
    } catch {
      toast.error('Upload failed');
    } finally {
      setUploading(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-xl w-full max-w-md overflow-hidden border border-gray-200 dark:border-slate-800 animate-in fade-in zoom-in-95 duration-200">
        <div className="px-6 py-4 border-b border-gray-100 dark:border-slate-800 flex items-center justify-between">
          <h2 className="text-lg font-bold text-gray-900 dark:text-gray-100">Upload Incident</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>
        
        <form onSubmit={handleSubmit} className="p-6 space-y-5">
          <div
            onClick={() => fileRef.current?.click()}
            onDragOver={(e) => e.preventDefault()}
            onDrop={(e) => { e.preventDefault(); handleFile(e.dataTransfer.files[0] || null); }}
            className={`relative border-2 border-dashed rounded-xl h-40 flex flex-col items-center justify-center cursor-pointer transition-colors ${
              file ? 'border-primary-400 bg-primary-50 dark:bg-primary-900/30' : 'border-gray-300 dark:border-slate-700 hover:border-primary-400 hover:bg-gray-50 dark:hover:bg-slate-800/50'
            }`}
          >
            {preview ? (
              <img src={preview} alt="preview" className="absolute inset-0 w-full h-full object-cover rounded-xl opacity-30" />
            ) : null}
            <div className="relative z-10 text-center">
              {file ? (
                <>
                  <svg className="w-8 h-8 text-green-500 mx-auto" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                  <p className="text-sm text-gray-700 dark:text-gray-300 mt-2 font-medium truncate px-4">{file.name}</p>
                </>
              ) : (
                <>
                  <svg className="w-8 h-8 text-gray-400 dark:text-gray-500 mx-auto" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M6.827 6.175A2.31 2.31 0 015.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574V18a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 00-1.134-.175 2.31 2.31 0 01-1.64-1.055l-.822-1.316a2.192 2.192 0 00-1.736-1.039 48.774 48.774 0 00-5.232 0 2.192 2.192 0 00-1.736 1.039l-.821 1.316z" /><path strokeLinecap="round" strokeLinejoin="round" d="M16.5 12.75a4.5 4.5 0 11-9 0 4.5 4.5 0 019 0z" /></svg>
                  <p className="text-sm text-gray-600 dark:text-gray-400 mt-2">Click or drag an injury photo</p>
                </>
              )}
            </div>
            <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={(e) => handleFile(e.target.files?.[0] || null)} />
          </div>

          <div>
            <label className="text-xs font-medium text-gray-700 dark:text-gray-300 mb-1 block">Title (optional)</label>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Left arm burn"
              disabled={uploading}
              className="w-full bg-white dark:bg-slate-950 border border-gray-200 dark:border-slate-800 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </div>

          <div>
            <label className="text-xs font-medium text-gray-700 dark:text-gray-300 mb-1 block">Notes (optional)</label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Additional details..."
              disabled={uploading}
              rows={2}
              className="w-full bg-white dark:bg-slate-950 border border-gray-200 dark:border-slate-800 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </div>

          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose} disabled={uploading} className="flex-1 py-2 rounded-lg bg-gray-100 dark:bg-slate-800 text-gray-700 dark:text-gray-300 text-sm font-medium hover:bg-gray-200 dark:hover:bg-slate-700 transition-colors">Cancel</button>
            <button type="submit" disabled={!file || uploading} className="flex-1 py-2 rounded-lg bg-primary-600 text-white text-sm font-medium hover:bg-primary-700 disabled:bg-primary-600/50 flex items-center justify-center transition-colors">
              {uploading ? <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" /> : 'Analyze'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
