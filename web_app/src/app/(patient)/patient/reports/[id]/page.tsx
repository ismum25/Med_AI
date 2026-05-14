'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { reportsApi, BASE_URL } from '@/lib/api-client';
import { MedicalReport } from '@/types';
import { formatDateTime, statusColor, capitalize, humanizeSnake } from '@/lib/utils';
import toast from 'react-hot-toast';

export default function ReportDetail() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [report, setReport] = useState<MedicalReport | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
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
    return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  if (!report) {
    return (
      <div className="text-center py-20">
        <p className="text-gray-500 dark:text-gray-400 dark:text-gray-500">Report not found</p>
        <button onClick={() => router.back()} className="text-primary-600 hover:underline text-sm mt-2">Go back</button>
      </div>
    );
  }

  const extracted = report.extracted_data as Record<string, unknown> | undefined;
  const results = extracted?.results as Record<string, unknown>[] | undefined;

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <button onClick={() => router.back()} className="text-sm text-gray-500 dark:text-gray-400 dark:text-gray-500 hover:text-gray-700 dark:text-gray-300 flex items-center gap-1">
        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" /></svg>
        Back
      </button>

      <div className="rounded-xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-5">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-xl font-bold text-gray-900 dark:text-gray-100">{report.title || report.file_name || 'Medical Report'}</h1>
            <p className="text-sm text-gray-500 dark:text-gray-400 dark:text-gray-500 mt-1">{humanizeSnake(report.report_type)} • {formatDateTime(report.created_at)}</p>
          </div>
          <span className={`text-xs font-medium px-3 py-1 rounded-full ${statusColor(report.ocr_status)}`}>
            {capitalize(report.ocr_status)}
          </span>
        </div>
        <div className="mt-4">
          <button onClick={openFile} className="text-sm font-medium text-primary-600 hover:underline flex items-center gap-1">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M13.5 6H5.25A2.25 2.25 0 003 8.25v10.5A2.25 2.25 0 005.25 21h10.5A2.25 2.25 0 0018 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" /></svg>
            Open Source File
          </button>
        </div>
      </div>

      {/* Extracted data */}
      {extracted && Object.keys(extracted).length > 0 && (
        <div className="rounded-xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-5 space-y-4">
          <h2 className="font-semibold text-gray-900 dark:text-gray-100">Extracted Data</h2>

          {/* Meta fields */}
          <div className="grid grid-cols-2 gap-3">
            {['test_name', 'lab_name', 'patient_name', 'report_date', 'doctor_name', 'data_type'].map((key) => {
              const val = extracted[key];
              if (!val) return null;
              return (
                <div key={key}>
                  <p className="text-xs text-gray-500 dark:text-gray-400 dark:text-gray-500">{humanizeSnake(key)}</p>
                  <p className="text-sm font-medium text-gray-900 dark:text-gray-100">{String(val)}</p>
                </div>
              );
            })}
          </div>

          {/* Results table */}
          {results && results.length > 0 && (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-100 dark:border-slate-800">
                    <th className="py-2 text-left font-medium text-gray-500 dark:text-gray-400 dark:text-gray-500">Parameter</th>
                    <th className="py-2 text-left font-medium text-gray-500 dark:text-gray-400 dark:text-gray-500">Value</th>
                    <th className="py-2 text-left font-medium text-gray-500 dark:text-gray-400 dark:text-gray-500">Unit</th>
                    <th className="py-2 text-left font-medium text-gray-500 dark:text-gray-400 dark:text-gray-500">Reference</th>
                    <th className="py-2 text-left font-medium text-gray-500 dark:text-gray-400 dark:text-gray-500">Flag</th>
                  </tr>
                </thead>
                <tbody>
                  {results.map((row, i) => (
                    <tr key={i} className="border-b border-gray-50 dark:border-slate-800/50">
                      <td className="py-2 font-medium text-gray-900 dark:text-gray-100">{String(row.parameter || '')}</td>
                      <td className="py-2">{String(row.value || '')}</td>
                      <td className="py-2 text-gray-500 dark:text-gray-400 dark:text-gray-500">{String(row.unit || '')}</td>
                      <td className="py-2 text-gray-500 dark:text-gray-400 dark:text-gray-500">{String(row.reference_range || '')}</td>
                      <td className="py-2">
                        {row.flag ? (
                          <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                            String(row.flag).toLowerCase() === 'high' || String(row.flag).toLowerCase() === 'low'
                              ? 'text-red-700 bg-red-50'
                              : 'text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-slate-800'
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
        <div className="rounded-xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 shadow-sm p-5">
          <h2 className="font-semibold text-gray-900 dark:text-gray-100 mb-2">Notes</h2>
          <p className="text-sm text-gray-600 dark:text-gray-400 dark:text-gray-500">{report.notes}</p>
        </div>
      )}
    </div>
  );
}
