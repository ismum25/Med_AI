'use client';

import { useEffect, useState, useRef } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { reportsApi } from '@/lib/api-client';
import { MedicalReport } from '@/types';
import { formatDate, statusColor, capitalize, humanizeSnake, formatDateTime } from '@/lib/utils';
import toast from 'react-hot-toast';

export default function PatientReports() {
  const [reports, setReports] = useState<MedicalReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [showUploadModal, setShowUploadModal] = useState(false);
  const searchParams = useSearchParams();

  useEffect(() => {
    loadReports();
    if (searchParams.get('upload') === 'true') {
      setShowUploadModal(true);
    }
  }, [searchParams]);

  function loadReports() {
    reportsApi.list().then((r) => {
      setReports(r.data);
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
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">My Reports</h1>
          <button onClick={() => setShowUploadModal(true)} className="bg-primary-600 text-white px-3 py-1.5 rounded-lg text-sm font-medium hover:bg-primary-700 transition-colors flex items-center gap-1.5 shadow-sm">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
            Upload
          </button>
        </div>

        {reports.length === 0 ? (
          <div className="text-center py-16 flex-1">
            <svg className="w-12 h-12 text-gray-300 mx-auto mb-3" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M2.25 12.75V12A2.25 2.25 0 014.5 9.75h15A2.25 2.25 0 0121.75 12v.75m-8.69-6.44l-2.12-2.12a1.5 1.5 0 00-1.061-.44H4.5A2.25 2.25 0 002.25 6v12a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9a2.25 2.25 0 00-2.25-2.25h-5.379a1.5 1.5 0 01-1.06-.44z" /></svg>
            <p className="text-gray-500 dark:text-gray-400 mb-1">No reports yet</p>
            <button onClick={() => setShowUploadModal(true)} className="text-primary-600 font-medium text-sm hover:underline">Upload your first report</button>
          </div>
        ) : (
          <div className="flex-1 overflow-y-auto space-y-3 pr-2 pb-4">
            {reports.map((r) => (
              <button 
                key={r.id} 
                onClick={() => setSelectedId(r.id)}
                className={`w-full text-left block rounded-xl border p-4 transition-all ${
                  selectedId === r.id 
                    ? 'bg-primary-50 dark:bg-primary-900/20 border-primary-200 dark:border-primary-800 shadow-sm' 
                    : 'bg-white dark:bg-slate-900 border-gray-100 dark:border-slate-800 hover:shadow-md'
                }`}
              >
                <div className="flex items-center gap-4">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${
                    selectedId === r.id ? 'bg-primary-600 text-white' : 'bg-teal-50 text-teal-600 dark:bg-teal-900/30'
                  }`}>
                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" /></svg>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className={`font-semibold truncate ${selectedId === r.id ? 'text-primary-900 dark:text-primary-100' : 'text-gray-900 dark:text-gray-100'}`}>
                      {r.title || r.file_name || 'Medical Report'}
                    </p>
                    <p className={`text-sm mt-0.5 ${selectedId === r.id ? 'text-primary-700/80 dark:text-primary-300' : 'text-gray-500 dark:text-gray-400'}`}>
                      {humanizeSnake(r.report_type)} • {formatDate(r.created_at)}
                    </p>
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
          <ReportDetailView id={selectedId} />
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center text-gray-400">
            <svg className="w-16 h-16 mb-4 text-gray-200 dark:text-gray-800" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" /></svg>
            <p>Select a report to view details</p>
          </div>
        )}
      </div>

      {showUploadModal && (
        <ReportUploadModal 
          onClose={() => setShowUploadModal(false)} 
          onSuccess={() => {
            setShowUploadModal(false);
            loadReports();
          }} 
        />
      )}
    </div>
  );
}

function formatExtractedValue(value: unknown): string {
  if (value == null) return '—';
  if (Array.isArray(value)) {
    if (value.length === 0) return '—';
    return value.map(formatExtractedValue).join(', ');
  }
  if (typeof value === 'object') {
    const keys = Object.keys(value as Record<string, unknown>);
    if (keys.length === 0) return '—';
    return keys.map((k) => `${k}: ${formatExtractedValue((value as Record<string, unknown>)[k])}`).join(' | ');
  }
  const s = String(value).trim();
  return s === '' ? '—' : s;
}

function ReportDetailView({ id }: { id: string }) {
  const [report, setReport] = useState<MedicalReport | null>(null);
  const [loading, setLoading] = useState(true);
  
  const [editing, setEditing] = useState(false);
  const [saving, setSaving] = useState(false);
  const [editTitle, setEditTitle] = useState('');

  useEffect(() => {
    setLoading(true);
    setEditing(false);
    reportsApi.get(id).then((r) => {
      setReport(r.data);
      setEditTitle(r.data.title || r.data.file_name || '');
    }).catch(() => {}).finally(() => setLoading(false));
  }, [id]);

  async function openFile() {
    try {
      const res = await reportsApi.download(id);
      const url = res.data?.download_url;
      if (url) window.open(url, '_blank');
      else toast.error('No download URL');
    } catch {
      toast.error('Failed to get download link');
    }
  }

  async function handleSaveTitle() {
    if (!editTitle.trim()) {
      toast.error('Title cannot be empty');
      return;
    }
    setSaving(true);
    try {
      // Assuming update endpoint exists, though we might only be able to patch
      // If there is no specific update title endpoint, we do our best.
      const res = await reportsApi.update(id, { title: editTitle.trim() });
      setReport(res.data);
      setEditing(false);
      toast.success('Title updated');
    } catch {
      toast.error('Failed to update title');
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return <div className="flex justify-center items-center h-full"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  if (!report) {
    return <div className="text-center py-20 text-gray-500">Report not found</div>;
  }

  let extracted: Record<string, unknown> | undefined = undefined;
  if (report.extracted_data) {
    try {
      extracted = typeof report.extracted_data === 'string' 
        ? JSON.parse(report.extracted_data) 
        : report.extracted_data;
    } catch { /* ignore parse error */ }
  }

  const title = report.title || report.file_name || 'Medical Report';
  const reportDate = extracted?.report_date as string | undefined;

  return (
    <div className="flex-1 overflow-y-auto p-4 sm:p-6 space-y-4 bg-gray-50/30 dark:bg-slate-950/30">
      
      {/* Title Card */}
      <div className="bg-white dark:bg-slate-900 rounded-2xl p-5 border border-gray-100 dark:border-slate-800 shadow-sm">
        {editing ? (
          <div className="space-y-4">
            <div>
              <label className="text-xs font-medium text-gray-500 dark:text-gray-400 mb-1 flex items-center gap-1.5"><svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" /></svg> Title</label>
              <input
                value={editTitle}
                onChange={(e) => setEditTitle(e.target.value)}
                disabled={saving}
                className="w-full bg-gray-50 dark:bg-slate-950 border border-gray-200 dark:border-slate-800 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
            </div>
            <div className="flex items-center gap-3">
              <button onClick={() => setEditing(false)} disabled={saving} className="flex-1 py-2 text-sm font-medium text-gray-600 dark:text-gray-300 bg-gray-100 dark:bg-slate-800 hover:bg-gray-200 dark:hover:bg-slate-700 rounded-lg transition-colors">Cancel</button>
              <button onClick={handleSaveTitle} disabled={saving} className="flex-1 py-2 text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 disabled:bg-primary-600/50 rounded-lg transition-colors flex items-center justify-center">
                {saving ? <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" /> : 'Save'}
              </button>
            </div>
          </div>
        ) : (
          <div className="flex items-start justify-between">
            <h2 className="text-xl font-bold text-gray-900 dark:text-gray-100 leading-tight">{title}</h2>
            <button onClick={() => setEditing(true)} className="p-1.5 text-primary-600 hover:bg-primary-50 dark:hover:bg-primary-900/30 rounded-lg transition-colors ml-2 flex-shrink-0" title="Edit title">
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L6.832 19.82a4.5 4.5 0 01-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 011.13-1.897L16.863 4.487zm0 0L19.5 7.125" /></svg>
            </button>
          </div>
        )}
        {!editing && (
          <div className="mt-4">
            <span className={`inline-block text-xs font-semibold px-3 py-1 rounded-full ${statusColor(report.ocr_status)}`}>
              {capitalize(report.ocr_status)}
            </span>
          </div>
        )}
      </div>

      {/* Meta Card */}
      <div className="bg-white dark:bg-slate-900 rounded-2xl border border-gray-100 dark:border-slate-800 shadow-sm overflow-hidden">
        <div className="p-4 flex flex-col gap-4">
          
          <div className="flex items-start gap-3">
            <svg className="w-5 h-5 text-primary-600 mt-0.5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M9.568 3H5.25A2.25 2.25 0 003 5.25v14.313c0 1.026.738 1.905 1.748 2.062 1.34.208 2.72.313 4.122.313 1.402 0 2.782-.105 4.122-.313 1.01-.157 1.748-1.036 1.748-2.062V5.25A2.25 2.25 0 0012.432 3h-2.864z" /></svg>
            <div className="flex-1">
              <p className="text-[10px] font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-widest">Type</p>
              <p className="text-sm font-medium text-gray-900 dark:text-gray-100 mt-0.5">{humanizeSnake(report.report_type)}</p>
            </div>
          </div>
          <div className="h-px bg-gray-100 dark:bg-slate-800" />
          
          {reportDate && (
            <>
              <div className="flex items-start gap-3">
                <svg className="w-5 h-5 text-primary-600 mt-0.5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5" /></svg>
                <div className="flex-1">
                  <p className="text-[10px] font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-widest">Report Date</p>
                  <p className="text-sm font-medium text-gray-900 dark:text-gray-100 mt-0.5">{reportDate}</p>
                </div>
              </div>
              <div className="h-px bg-gray-100 dark:bg-slate-800" />
            </>
          )}

          <div className="flex items-start gap-3">
            <svg className="w-5 h-5 text-primary-600 mt-0.5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" /></svg>
            <div className="flex-1">
              <p className="text-[10px] font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-widest">File</p>
              <div className="mt-1 flex items-center justify-between gap-2">
                <p className="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">{report.file_name || 'Attached file'}</p>
                <button onClick={openFile} className="text-xs font-semibold text-primary-600 hover:text-primary-700 bg-primary-50 dark:bg-primary-900/30 px-2.5 py-1 rounded-md transition-colors flex items-center gap-1">
                  Open
                </button>
              </div>
            </div>
          </div>
          <div className="h-px bg-gray-100 dark:bg-slate-800" />

          <div className="flex items-start gap-3">
            <svg className="w-5 h-5 text-primary-600 mt-0.5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
            <div className="flex-1">
              <p className="text-[10px] font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-widest">Uploaded</p>
              <p className="text-sm font-medium text-gray-900 dark:text-gray-100 mt-0.5">{formatDateTime(report.created_at)}</p>
            </div>
          </div>
          
        </div>
      </div>

      {/* Extracted Data Card */}
      {(report.ocr_status === 'extracted' || report.ocr_status === 'verified') && extracted && Object.keys(extracted).length > 0 && (
        <div className="bg-white dark:bg-slate-900 rounded-2xl border border-gray-100 dark:border-slate-800 shadow-sm overflow-hidden">
          <div className="p-4 bg-gray-50/50 dark:bg-slate-950/50 border-b border-gray-100 dark:border-slate-800 flex items-center gap-2">
            <svg className="w-5 h-5 text-primary-600" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" /></svg>
            <h3 className="font-bold text-gray-900 dark:text-gray-100">Extracted Data</h3>
          </div>
          <div className="p-4 flex flex-col gap-4">
            {Object.entries(extracted).map(([key, value], index, arr) => (
              <div key={key}>
                <div className="flex items-start gap-3">
                  <svg className="w-5 h-5 text-primary-600 mt-0.5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z" /></svg>
                  <div className="flex-1">
                    <p className="text-[10px] font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-widest">{humanizeSnake(key)}</p>
                    <p className="text-sm font-medium text-gray-900 dark:text-gray-100 mt-0.5 whitespace-pre-wrap">{formatExtractedValue(value)}</p>
                  </div>
                </div>
                {index < arr.length - 1 && <div className="h-px bg-gray-100 dark:bg-slate-800 mt-4" />}
              </div>
            ))}
          </div>
        </div>
      )}

      {report.notes && (
        <div className="bg-orange-50 dark:bg-orange-950/20 border border-orange-100 dark:border-orange-900/30 p-4 rounded-xl">
          <h3 className="font-semibold text-orange-900 dark:text-orange-200 mb-1 flex items-center gap-2">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" /></svg>
            Notes
          </h3>
          <p className="text-sm text-orange-800 dark:text-orange-300 leading-relaxed">{report.notes}</p>
        </div>
      )}
    </div>
  );
}

const REPORT_TYPES = [
  { value: 'blood_test', label: 'Blood Test' },
  { value: 'xray', label: 'X-Ray' },
  { value: 'mri', label: 'MRI' },
  { value: 'urine', label: 'Urinalysis' },
  { value: 'other', label: 'Other' },
];

function ReportUploadModal({ onClose, onSuccess }: { onClose: () => void, onSuccess: () => void }) {
  const fileRef = useRef<HTMLInputElement>(null);
  const [file, setFile] = useState<File | null>(null);
  const [form, setForm] = useState({ title: '', report_type: 'blood_test' });
  const [loading, setLoading] = useState(false);

  function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const f = e.target.files?.[0];
    if (f) {
      if (f.size > 20 * 1024 * 1024) {
        toast.error('File must be under 20MB');
        return;
      }
      setFile(f);
      if (!form.title) setForm((p) => ({ ...p, title: f.name.replace(/\.[^/.]+$/, '') }));
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!file) { toast.error('Please select a file'); return; }
    setLoading(true);
    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('title', form.title);
      formData.append('report_type', form.report_type);
      await reportsApi.upload(formData);
      toast.success('Report uploaded! OCR processing started.');
      onSuccess();
    } catch (err: unknown) {
      const message = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail;
      toast.error(typeof message === 'string' ? message : 'Upload failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-xl w-full max-w-md overflow-hidden border border-gray-200 dark:border-slate-800 animate-in fade-in zoom-in-95 duration-200">
        <div className="px-6 py-4 border-b border-gray-100 dark:border-slate-800 flex items-center justify-between">
          <h2 className="text-lg font-bold text-gray-900 dark:text-gray-100">Upload Report</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div
            className="border-2 border-dashed border-gray-300 dark:border-slate-700 rounded-xl p-6 text-center cursor-pointer hover:border-primary-400 hover:bg-gray-50 dark:hover:bg-slate-800/50 transition-colors"
            onClick={() => fileRef.current?.click()}
          >
            <input ref={fileRef} type="file" accept="image/*,.pdf" className="hidden" onChange={handleFileChange} />
            {file ? (
              <>
                <div className="w-10 h-10 bg-green-100 dark:bg-green-900/30 rounded-full flex items-center justify-center mx-auto mb-2">
                  <svg className="w-5 h-5 text-green-600 dark:text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" /></svg>
                </div>
                <p className="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">{file.name}</p>
                <p className="text-xs text-gray-500 mt-1">{(file.size / 1024).toFixed(1)} KB</p>
              </>
            ) : (
              <>
                <svg className="w-8 h-8 text-gray-400 mx-auto mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 16.5V9.75m0 0l3 3m-3-3l-3 3M6.75 19.5a4.5 4.5 0 01-1.41-8.775 5.25 5.25 0 0110.233-2.33 3 3 0 013.758 3.848A3.752 3.752 0 0118 19.5H6.75z" />
                </svg>
                <p className="text-sm text-gray-600 dark:text-gray-300">Click or drag & drop</p>
                <p className="text-xs text-gray-400 mt-1">PDF or Images up to 20MB</p>
              </>
            )}
          </div>

          <div>
            <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Title</label>
            <input
              className="w-full bg-white dark:bg-slate-950 border border-gray-200 dark:border-slate-800 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
              value={form.title}
              onChange={(e) => setForm((p) => ({ ...p, title: e.target.value }))}
              required
            />
          </div>

          <div>
            <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Report Type</label>
            <select
              className="w-full bg-white dark:bg-slate-950 border border-gray-200 dark:border-slate-800 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
              value={form.report_type}
              onChange={(e) => setForm((p) => ({ ...p, report_type: e.target.value }))}
            >
              {REPORT_TYPES.map((t) => (
                <option key={t.value} value={t.value}>{t.label}</option>
              ))}
            </select>
          </div>

          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose} disabled={loading} className="flex-1 py-2 rounded-lg bg-gray-100 dark:bg-slate-800 text-gray-700 dark:text-gray-300 text-sm font-medium hover:bg-gray-200 dark:hover:bg-slate-700 transition-colors">Cancel</button>
            <button type="submit" disabled={loading || !file} className="flex-1 py-2 rounded-lg bg-primary-600 text-white text-sm font-medium hover:bg-primary-700 disabled:bg-primary-600/50 flex items-center justify-center transition-colors">
              {loading ? <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" /> : 'Upload'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
