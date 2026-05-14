'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { reportsApi } from '@/lib/api-client';
import { MedicalReport } from '@/types';
import { formatDate, statusColor, capitalize, humanizeSnake } from '@/lib/utils';

export default function PatientReports() {
  const [reports, setReports] = useState<MedicalReport[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    reportsApi.list().then((r) => setReports(r.data)).catch(() => {}).finally(() => setLoading(false));
  }, []);

  if (loading) {
    return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">My Reports</h1>
        <Link href="/patient/reports/upload" className="bg-primary-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-primary-700 transition-colors flex items-center gap-2">
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
          Upload Report
        </Link>
      </div>

      {reports.length === 0 ? (
        <div className="text-center py-16">
          <svg className="w-12 h-12 text-gray-300 mx-auto mb-3" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M2.25 12.75V12A2.25 2.25 0 014.5 9.75h15A2.25 2.25 0 0121.75 12v.75m-8.69-6.44l-2.12-2.12a1.5 1.5 0 00-1.061-.44H4.5A2.25 2.25 0 002.25 6v12a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9a2.25 2.25 0 00-2.25-2.25h-5.379a1.5 1.5 0 01-1.06-.44z" /></svg>
          <p className="text-gray-500 mb-1">No reports yet</p>
          <p className="text-sm text-gray-400 mb-4">Upload your medical reports for AI-powered analysis</p>
          <Link href="/patient/reports/upload" className="text-primary-600 font-medium text-sm hover:underline">Upload your first report</Link>
        </div>
      ) : (
        <div className="space-y-3">
          {reports.map((r) => (
            <Link key={r.id} href={`/patient/reports/${r.id}`} className="block rounded-xl bg-white border border-gray-100 shadow-sm p-4 hover:shadow-md transition-shadow">
              <div className="flex items-center gap-4">
                <div className="w-11 h-11 rounded-xl bg-teal-50 text-teal-600 flex items-center justify-center flex-shrink-0">
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" /></svg>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-gray-900 truncate">{r.title || r.file_name || 'Medical Report'}</p>
                  <p className="text-sm text-gray-500">{humanizeSnake(r.report_type)} • {formatDate(r.created_at)}</p>
                </div>
                <span className={`text-xs font-medium px-2.5 py-1 rounded-full ${statusColor(r.ocr_status)}`}>
                  {capitalize(r.ocr_status === 'extracted' ? 'Ready' : r.ocr_status)}
                </span>
                <svg className="w-5 h-5 text-gray-400" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" /></svg>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
