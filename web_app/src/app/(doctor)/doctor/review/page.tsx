'use client';

import { useEffect, useState } from 'react';
import { reportsApi } from '@/lib/api-client';
import { MedicalReport } from '@/types';
import { timeAgo, humanizeSnake, capitalize, formatDateTime, statusColor } from '@/lib/utils';
import toast from 'react-hot-toast';

export default function DoctorReviewQueue() {
  const [reports, setReports] = useState<MedicalReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedId, setSelectedId] = useState<string | null>(null);

  useEffect(() => { load(); }, []);

  async function load() {
    setLoading(true);
    try {
      const res = await reportsApi.pendingReview();
      setReports(res.data);
      if (res.data.length > 0 && !selectedId) {
        setSelectedId(res.data[0].id);
      }
    } catch { /* ignore */ }
    setLoading(false);
  }

  if (loading) {
    return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  return (
    <div className="flex h-[calc(100vh-4rem)] w-full gap-6 overflow-hidden px-4">
      {/* Left List */}
      <div className="w-1/3 flex flex-col min-w-[320px] max-w-sm">
        <div className="flex items-center justify-between mb-4 flex-shrink-0">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">Review Queue</h1>
          <button onClick={() => load()} className="text-sm text-primary-600 hover:underline font-medium flex items-center gap-1">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182" /></svg>
            Refresh
          </button>
        </div>

        {reports.length === 0 ? (
          <div className="text-center py-16 flex-1 border border-dashed border-gray-200 dark:border-slate-800 rounded-2xl flex flex-col items-center justify-center">
            <svg className="w-12 h-12 text-gray-300 dark:text-gray-700 mx-auto mb-3" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M2.25 13.5h3.86a2.25 2.25 0 012.012 1.244l.256.512a2.25 2.25 0 002.013 1.244h3.218a2.25 2.25 0 002.013-1.244l.256-.512a2.25 2.25 0 012.013-1.244h3.859m-19.5.338V18a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18v-4.162c0-.224-.034-.447-.1-.661L19.24 5.338a2.25 2.25 0 00-2.15-1.588H6.911a2.25 2.25 0 00-2.15 1.588L2.35 13.177a2.25 2.25 0 00-.1.661z" /></svg>
            <p className="text-gray-500 dark:text-gray-400 font-medium">No reports waiting</p>
            <p className="text-xs text-gray-400 mt-1">OCR-extracted reports appear here.</p>
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
                    selectedId === r.id ? 'bg-primary-600 text-white' : 'bg-violet-50 text-violet-600 dark:bg-violet-900/30 dark:text-violet-400'
                  }`}>
                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M11.35 3.836c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m8.9-4.414c.376.023.75.05 1.124.08 1.131.094 1.976 1.057 1.976 2.192V16.5A2.25 2.25 0 0118 18.75h-2.25m-7.5-10.5H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V18.75m-7.5-10.5h6.375c.621 0 1.125.504 1.125 1.125v9.375m-8.25-3l1.5 1.5 3-3.75" /></svg>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className={`font-semibold truncate ${selectedId === r.id ? 'text-primary-900 dark:text-primary-100' : 'text-gray-900 dark:text-gray-100'}`}>
                      {r.title || r.file_name || 'Medical Report'}
                    </p>
                    <p className={`text-sm mt-0.5 ${selectedId === r.id ? 'text-primary-700/80 dark:text-primary-300' : 'text-gray-500 dark:text-gray-400'}`}>
                      {capitalize(humanizeSnake(r.report_type || 'report'))}
                    </p>
                  </div>
                  <span className="text-[10px] font-medium text-gray-400">{timeAgo(r.created_at)}</span>
                </div>
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Right Detail */}
      <div className="flex-1 bg-white dark:bg-slate-900 rounded-2xl border border-gray-100 dark:border-slate-800 shadow-sm overflow-hidden flex flex-col relative">
        {selectedId ? (
          <ReviewDetailView id={selectedId} onVerified={() => {
            setSelectedId(null);
            load();
          }} />
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center text-gray-400">
            <svg className="w-16 h-16 mb-4 text-gray-200 dark:text-gray-800" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M11.35 3.836c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m8.9-4.414c.376.023.75.05 1.124.08 1.131.094 1.976 1.057 1.976 2.192V16.5A2.25 2.25 0 0118 18.75h-2.25m-7.5-10.5H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V18.75m-7.5-10.5h6.375c.621 0 1.125.504 1.125 1.125v9.375m-8.25-3l1.5 1.5 3-3.75" /></svg>
            <p>Select a report to review</p>
          </div>
        )}
      </div>
    </div>
  );
}

const META_KEYS = ['test_name', 'lab_name', 'patient_name', 'report_date', 'doctor_name', 'data_type'];

interface ResultRow {
  parameter: string;
  value: string;
  unit: string;
  reference_range: string;
  flag: string;
}

function ReviewDetailView({ id, onVerified }: { id: string, onVerified: () => void }) {
  const [report, setReport] = useState<MedicalReport | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  // Editable state
  const [meta, setMeta] = useState<Record<string, string>>({});
  const [results, setResults] = useState<ResultRow[]>([]);
  const [useRawJson, setUseRawJson] = useState(false);
  const [rawJson, setRawJson] = useState('');
  const [notes, setNotes] = useState('');

  useEffect(() => { load(); }, [id]);

  async function load() {
    setLoading(true);
    try {
      const res = await reportsApi.get(id);
      const r = res.data as MedicalReport;
      setReport(r);
      setNotes((r.notes as string) || '');

      const extracted = (r.extracted_data || {}) as Record<string, unknown>;
      const hasResults = 'results' in extracted;
      const isRaw = !hasResults && Object.keys(extracted).length > 0;
      setUseRawJson(isRaw);

      if (isRaw) {
        setRawJson(JSON.stringify(extracted, null, 2));
      } else {
        const m: Record<string, string> = {};
        for (const k of META_KEYS) m[k] = String(extracted[k] || '');
        setMeta(m);

        const rawResults = extracted.results;
        if (Array.isArray(rawResults)) {
          setResults(rawResults.map((item: Record<string, unknown>) => ({
            parameter: String(item.parameter || ''),
            value: String(item.value || ''),
            unit: String(item.unit || ''),
            reference_range: String(item.reference_range || ''),
            flag: String(item.flag || ''),
          })));
        } else {
          setResults([emptyRow()]);
        }
      }
    } catch { /* ignore */ }
    setLoading(false);
  }

  function emptyRow(): ResultRow {
    return { parameter: '', value: '', unit: '', reference_range: '', flag: '' };
  }

  function buildVerifyData(): Record<string, unknown> {
    if (useRawJson) {
      const parsed = JSON.parse(rawJson);
      if (typeof parsed !== 'object' || parsed === null) throw new Error('Root must be an object');
      return parsed;
    }
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(meta)) {
      if (v.trim()) out[k] = v.trim();
    }
    out.results = results.map((r) => ({
      parameter: r.parameter.trim(),
      value: r.value.trim(),
      unit: r.unit.trim() || null,
      reference_range: r.reference_range.trim() || null,
      flag: r.flag.trim() || null,
    }));
    return out;
  }

  async function handleVerify() {
    if (!confirm('Mark this report verified? This locks the extraction.')) return;

    let data: Record<string, unknown>;
    try {
      data = buildVerifyData();
    } catch (e) {
      toast.error(`Invalid data: ${e}`);
      return;
    }

    setSubmitting(true);
    try {
      await reportsApi.verify(id, {
        data,
        notes: notes.trim() || undefined,
      });
      toast.success('Report verified');
      onVerified();
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail || 'Verify failed';
      toast.error(String(msg));
    }
    setSubmitting(false);
  }

  async function openFile() {
    try {
      const res = await reportsApi.download(id);
      const url = res.data?.download_url;
      if (url) window.open(url, '_blank');
      else toast.error('No download URL');
    } catch {
      toast.error('Could not load download link');
    }
  }

  if (loading) return <div className="flex justify-center items-center h-full"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  if (!report) return <div className="text-center py-20 text-gray-500">Report not found</div>;

  return (
    <div className="flex-1 overflow-y-auto p-6 space-y-6 relative pb-24">
      {/* Header */}
      <div className="flex items-start justify-between pb-4 border-b border-gray-100 dark:border-slate-800">
        <div>
          <h2 className="text-xl font-bold text-gray-900 dark:text-gray-100">{report.title || report.file_name || 'Report'}</h2>
          {report.report_type && <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">{humanizeSnake(report.report_type)}</p>}
          <p className="text-xs text-gray-400 dark:text-gray-500 mt-1">{formatDateTime(report.created_at)}</p>
        </div>
        <div className="flex flex-col items-end gap-2">
          <span className={`text-xs font-medium px-3 py-1 rounded-full ${statusColor(report.ocr_status)}`}>
            {capitalize(report.ocr_status)}
          </span>
          <button onClick={openFile} className="text-xs font-medium text-primary-600 hover:text-primary-700 bg-primary-50 dark:bg-primary-900/30 px-3 py-1.5 rounded-lg flex items-center gap-1">
            <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M13.5 6H5.25A2.25 2.25 0 003 8.25v10.5A2.25 2.25 0 005.25 21h10.5A2.25 2.25 0 0018 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" /></svg>
            Open File
          </button>
        </div>
      </div>

      {/* Clinical notes */}
      <div className="space-y-2">
        <h3 className="font-semibold text-gray-900 dark:text-gray-100">Clinical Notes</h3>
        <textarea
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder="Optional notes for this report..."
          rows={3}
          className="w-full bg-gray-50 dark:bg-slate-950 border border-gray-200 dark:border-slate-800 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
        />
      </div>

      {/* Extracted data */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="font-semibold text-gray-900 dark:text-gray-100">Extracted Data</h3>
          <button 
            onClick={() => setUseRawJson(!useRawJson)}
            className="text-xs font-medium text-gray-500 hover:text-gray-700 bg-gray-100 dark:bg-slate-800 px-2.5 py-1 rounded-md"
          >
            {useRawJson ? 'Use Form' : 'Edit Raw JSON'}
          </button>
        </div>

        {useRawJson ? (
          <textarea
            value={rawJson}
            onChange={(e) => setRawJson(e.target.value)}
            rows={16}
            className="w-full font-mono text-xs bg-gray-50 dark:bg-slate-950 border border-gray-200 dark:border-slate-800 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary-500"
          />
        ) : (
          <div className="space-y-6">
            {/* Meta fields */}
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              {META_KEYS.map((k) => (
                <div key={k}>
                  <label className="text-xs font-medium text-gray-500 dark:text-gray-400 mb-1 block uppercase tracking-wide">{humanizeSnake(k)}</label>
                  <input
                    value={meta[k] || ''}
                    onChange={(e) => setMeta((prev) => ({ ...prev, [k]: e.target.value }))}
                    className="w-full bg-white dark:bg-slate-900 border border-gray-200 dark:border-slate-700 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                  />
                </div>
              ))}
            </div>

            {/* Results */}
            <div className="pt-2 border-t border-gray-100 dark:border-slate-800">
              <div className="flex items-center justify-between mb-4">
                <h4 className="font-medium text-gray-900 dark:text-gray-100 text-sm">Parameters</h4>
                <button onClick={() => setResults((r) => [...r, emptyRow()])} className="text-xs text-primary-600 hover:text-primary-700 bg-primary-50 dark:bg-primary-900/20 px-2 py-1 rounded font-medium">+ Add Row</button>
              </div>

              <div className="space-y-3">
                {results.map((row, i) => (
                  <div key={i} className="rounded-xl border border-gray-200 dark:border-slate-700 bg-gray-50/50 dark:bg-slate-950 p-4 space-y-3 relative group">
                    <div className="absolute top-3 right-3 opacity-0 group-hover:opacity-100 transition-opacity">
                      {results.length > 1 && (
                        <button onClick={() => setResults((r) => r.filter((_, j) => j !== i))} className="text-red-400 hover:text-red-600 bg-red-50 dark:bg-red-900/20 p-1.5 rounded-md">
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" /></svg>
                        </button>
                      )}
                    </div>
                    <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
                      {(['parameter', 'value', 'unit', 'reference_range', 'flag'] as const).map((field) => (
                        <div key={field}>
                          <label className="text-[10px] uppercase font-semibold text-gray-500 dark:text-gray-400 mb-1 block">{humanizeSnake(field)}</label>
                          <input
                            value={row[field]}
                            onChange={(e) => {
                              const val = e.target.value;
                              setResults((prev) => prev.map((r, j) => j === i ? { ...r, [field]: val } : r));
                            }}
                            className="w-full border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                          />
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Sticky Verify Button Bottom Bar */}
      <div className="absolute bottom-0 left-0 right-0 p-4 bg-white/80 dark:bg-slate-900/80 backdrop-blur-md border-t border-gray-100 dark:border-slate-800">
        <button
          onClick={handleVerify}
          disabled={submitting}
          className="w-full py-3 rounded-xl bg-primary-600 text-white font-semibold shadow-sm shadow-primary-500/20 hover:bg-primary-700 hover:shadow disabled:bg-gray-300 dark:disabled:bg-slate-700 transition-all flex items-center justify-center gap-2"
        >
          {submitting ? (
            <><div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" /> Verifying...</>
          ) : (
            <><svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" /></svg> Verify Report</>
          )}
        </button>
      </div>
    </div>
  );
}
