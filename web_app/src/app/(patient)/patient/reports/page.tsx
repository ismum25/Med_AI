'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import toast from 'react-hot-toast';
import { reportsApi } from '@/lib/api-client';
import { MedicalReport, OcrStatus } from '@/types';
import { format } from 'date-fns';

const OCR_STATUS_COLORS: Record<OcrStatus, string> = {
  pending: 'bg-yellow-100 text-yellow-700',
  processing: 'bg-blue-100 text-blue-700',
  extracted: 'bg-green-100 text-green-700',
  failed: 'bg-red-100 text-red-700',
};

export default function PatientReportsPage() {
  const [reports, setReports] = useState<MedicalReport[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    reportsApi.list()
      .then(({ data }) => setReports(data.items ?? data))
      .catch(() => toast.error('Failed to load reports'))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">My Reports</h1>
        <Link href="/patient/reports/upload" className="btn-primary">
          + Upload Report
        </Link>
      </div>

      {loading ? (
        <div className="flex justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" />
        </div>
      ) : reports.length === 0 ? (
        <div className="card text-center py-12">
          <p className="text-gray-500">No reports yet.</p>
          <Link href="/patient/reports/upload" className="btn-primary mt-4 inline-block w-auto px-6">
            Upload your first report
          </Link>
        </div>
      ) : (
        <div className="space-y-3">
          {reports.map((report) => (
            <div key={report.id} className="card flex items-center justify-between">
              <div>
                <p className="font-medium text-gray-900">{report.title}</p>
                <p className="text-sm text-gray-500 capitalize">{report.report_type.replace('_', ' ')}</p>
                <p className="text-xs text-gray-400 mt-1">{format(new Date(report.created_at), 'PP')}</p>
              </div>
              <div className="flex items-center gap-3">
                <span className={`badge ${OCR_STATUS_COLORS[report.ocr_status]} capitalize`}>
                  OCR: {report.ocr_status}
                </span>
                {report.verified && (
                  <span className="badge bg-green-100 text-green-700">Verified</span>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
