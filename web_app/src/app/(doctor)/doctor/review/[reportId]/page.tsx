'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { reportsApi } from '@/lib/api-client';
import { MedicalReport } from '@/types';
import { formatDateTime, statusColor, capitalize, humanizeSnake } from '@/lib/utils';
import toast from 'react-hot-toast';

const META_KEYS = ['test_name', 'lab_name', 'patient_name', 'report_date', 'doctor_name', 'data_type'];

interface ResultRow {
  parameter: string;
  value: string;
  unit: string;
  reference_range: string;
  flag: string;
}

export default function DoctorReviewDetail() {
  const { reportId } = useParams<{ reportId: string }>();
  const router = useRouter();
  const [report, setReport] = useState<MedicalReport | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  // Editable state
  const [meta, setMeta] = useState<Record<string, string>>({});
  const [results, setResults] = useState<ResultRow[]>([]);
  const [useRawJson, setUseRawJson] = useState(false);
  const [rawJson, setRawJson] = useState('');
  const [notes, setNotes] = useState('');

  useEffect(() => { load(); }, [reportId]);

  async function load() {
    setLoading(true);
    try {
      const res = await reportsApi.get(reportId);
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
      await reportsApi.verify(reportId, {
        data,
        notes: notes.trim() || undefined,
      });
      toast.success('Report verified');
      router.push('/doctor/review');
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail || 'Verify failed';
      toast.error(String(msg));
    }
    setSubmitting(false);
  }

  async function openFile() {
    try {
      const res = await reportsApi.download(reportId);
      const url = res.data?.download_url;
      if (url) window.open(url, '_blank');
      else toast.error('No download URL');
    } catch {
      toast.error('Could not load download link');
    }
  }

  if (loading) {
    return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  if (!report) {
    return (
      <div className="text-center py-20">
        <p className="text-gray-500">Report not found</p>
        <button onClick={() => router.back()} className="text-primary-600 hover:underline text-sm mt-2">Go back</button>
      </div>
    );
  }

  return (
    <div className="max-w-3xl mx-auto space-y-6 pb-20">
      <button onClick={() => router.back()} className="text-sm text-gray-500 hover:text-gray-700 flex items-center gap-1">
        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" /></svg>
        Back
      </button>

      {/* Header */}
      <div className="rounded-xl bg-white border border-gray-100 shadow-sm p-5">
        <h1 className="text-xl font-bold text-gray-900">{report.title || report.file_name || 'Report'}</h1>
        {report.report_type && <p className="text-sm text-gray-500 mt-1">{humanizeSnake(report.report_type)}</p>}
        <p className="text-xs text-gray-400 mt-1">{formatDateTime(report.created_at)}</p>
        <div className="mt-3 flex items-center gap-3">
          <span className={`text-xs font-medium px-3 py-1 rounded-full ${statusColor(report.ocr_status)}`}>
            {capitalize(report.ocr_status)}
          </span>
          <button onClick={openFile} className="text-sm text-primary-600 hover:underline font-medium flex items-center gap-1">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M13.5 6H5.25A2.25 2.25 0 003 8.25v10.5A2.25 2.25 0 005.25 21h10.5A2.25 2.25 0 0018 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" /></svg>
            Open File
          </button>
        </div>
      </div>

      {/* Clinical notes */}
      <div className="rounded-xl bg-white border border-gray-100 shadow-sm p-5">
        <h2 className="font-semibold text-gray-900 mb-2">Clinical Notes</h2>
        <textarea
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder="Optional notes for this report..."
          rows={3}
          className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
        />
      </div>

      {/* Extracted data */}
      <div className="rounded-xl bg-white border border-gray-100 shadow-sm p-5 space-y-4">
        <h2 className="font-semibold text-gray-900">Extracted Data</h2>

        {useRawJson ? (
          <textarea
            value={rawJson}
            onChange={(e) => setRawJson(e.target.value)}
            rows={16}
            className="w-full font-mono text-xs border border-gray-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
          />
        ) : (
          <>
            {/* Meta fields */}
            <div className="grid grid-cols-2 gap-3">
              {META_KEYS.map((k) => (
                <div key={k}>
                  <label className="text-xs font-medium text-gray-500 mb-0.5 block">{humanizeSnake(k)}</label>
                  <input
                    value={meta[k] || ''}
                    onChange={(e) => setMeta((prev) => ({ ...prev, [k]: e.target.value }))}
                    className="w-full border border-gray-200 rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                  />
                </div>
              ))}
            </div>

            {/* Results */}
            <div className="flex items-center justify-between">
              <h3 className="font-medium text-gray-900 text-sm">Results</h3>
              <button onClick={() => setResults((r) => [...r, emptyRow()])} className="text-xs text-primary-600 hover:underline font-medium">+ Add Row</button>
            </div>

            <div className="space-y-3">
              {results.map((row, i) => (
                <div key={i} className="rounded-lg bg-gray-50 p-3 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-semibold text-gray-500">Row {i + 1}</span>
                    {results.length > 1 && (
                      <button onClick={() => setResults((r) => r.filter((_, j) => j !== i))} className="text-red-400 hover:text-red-600">
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" /></svg>
                      </button>
                    )}
                  </div>
                  <div className="grid grid-cols-5 gap-2">
                    {(['parameter', 'value', 'unit', 'reference_range', 'flag'] as const).map((field) => (
                      <div key={field}>
                        <label className="text-[10px] text-gray-400">{humanizeSnake(field)}</label>
                        <input
                          value={row[field]}
                          onChange={(e) => {
                            const val = e.target.value;
                            setResults((prev) => prev.map((r, j) => j === i ? { ...r, [field]: val } : r));
                          }}
                          className="w-full border border-gray-200 rounded px-2 py-1 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                        />
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      {/* Verify button */}
      <div className="sticky bottom-4">
        <button
          onClick={handleVerify}
          disabled={submitting}
          className="w-full py-3 rounded-xl bg-primary-600 text-white font-semibold hover:bg-primary-700 disabled:bg-gray-300 transition-colors"
        >
          {submitting ? 'Verifying...' : 'Verify Report'}
        </button>
      </div>
    </div>
  );
}
