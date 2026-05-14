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

function ReportDetailView({ id }: { id: string }) {
  const [report, setReport] = useState<MedicalReport | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    reportsApi.get(id).then((r) => setReport(r.data)).catch(() => {}).finally(() => setLoading(false));
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
  const results = extracted?.results as Record<string, unknown>[] | undefined;

  return (
    <div className="flex-1 overflow-y-auto p-6 space-y-6">
      <div className="flex items-start justify-between pb-4 border-b border-gray-100 dark:border-slate-800">
        <div>
          <h2 className="text-2xl font-bold text-gray-900 dark:text-gray-100">{report.title || report.file_name || 'Medical Report'}</h2>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">{humanizeSnake(report.report_type)} • {formatDateTime(report.created_at)}</p>
        </div>
        <div className="flex flex-col items-end gap-2">
          <span className={`text-xs font-medium px-3 py-1 rounded-full ${statusColor(report.ocr_status)}`}>
            {capitalize(report.ocr_status)}
          </span>
          <button onClick={openFile} className="text-sm font-medium text-primary-600 hover:underline flex items-center gap-1 bg-primary-50 dark:bg-primary-900/30 px-3 py-1.5 rounded-lg">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M13.5 6H5.25A2.25 2.25 0 003 8.25v10.5A2.25 2.25 0 005.25 21h10.5A2.25 2.25 0 0018 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" /></svg>
            Open File
          </button>
        </div>
      </div>

      {extracted && Object.keys(extracted).length > 0 && (
        <div className="space-y-4">
          <h3 className="font-semibold text-gray-900 dark:text-gray-100 text-lg">Extracted Data</h3>
          
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 bg-gray-50 dark:bg-slate-950 p-4 rounded-xl border border-gray-100 dark:border-slate-800">
            {['test_name', 'lab_name', 'patient_name', 'report_date', 'doctor_name'].map((key) => {
              const val = extracted![key];
              if (!val) return null;
              return (
                <div key={key}>
                  <p className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">{humanizeSnake(key)}</p>
                  <p className="text-sm font-semibold text-gray-900 dark:text-gray-100 mt-0.5">{String(val)}</p>
                </div>
              );
            })}
          </div>

          {results && results.length > 0 && (
            <div className="border border-gray-200 dark:border-slate-800 rounded-xl overflow-hidden">
              <table className="w-full text-sm text-left">
                <thead className="bg-gray-50 dark:bg-slate-950 text-gray-600 dark:text-gray-300">
                  <tr>
                    <th className="px-4 py-3 font-semibold">Parameter</th>
                    <th className="px-4 py-3 font-semibold">Value</th>
                    <th className="px-4 py-3 font-semibold">Unit</th>
                    <th className="px-4 py-3 font-semibold">Reference Range</th>
                    <th className="px-4 py-3 font-semibold">Flag</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-slate-800 bg-white dark:bg-slate-900">
                  {results.map((row, i) => (
                    <tr key={i} className="hover:bg-gray-50/50 dark:hover:bg-slate-950/50 transition-colors">
                      <td className="px-4 py-3 font-medium text-gray-900 dark:text-gray-100">{String(row.parameter || '')}</td>
                      <td className="px-4 py-3 font-semibold">{String(row.value || '')}</td>
                      <td className="px-4 py-3 text-gray-500 dark:text-gray-400">{String(row.unit || '')}</td>
                      <td className="px-4 py-3 text-gray-500 dark:text-gray-400">{String(row.reference_range || '')}</td>
                      <td className="px-4 py-3">
                        {row.flag ? (
                          <span className={`text-xs font-bold px-2.5 py-1 rounded-md ${
                            String(row.flag).toLowerCase() === 'high' || String(row.flag).toLowerCase() === 'low'
                              ? 'text-red-700 bg-red-50 dark:bg-red-900/30 dark:text-red-400'
                              : 'text-gray-700 bg-gray-100 dark:text-gray-300 dark:bg-slate-800'
                          }`}>{String(row.flag)}</span>
                        ) : null}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
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
