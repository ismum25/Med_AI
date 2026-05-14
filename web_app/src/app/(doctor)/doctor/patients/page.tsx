'use client';

import { useEffect, useState } from 'react';
import { usersApi } from '@/lib/api-client';
import { PatientDetail } from '@/types';

export default function DoctorPatients() {
  const [patients, setPatients] = useState<PatientDetail[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<PatientDetail | null>(null);

  useEffect(() => {
    usersApi.myPatients().then((r) => setPatients(r.data)).catch(() => {}).finally(() => setLoading(false));
  }, []);

  if (loading) {
    return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Patients</h1>

      {patients.length === 0 ? (
        <div className="text-center py-16">
          <svg className="w-12 h-12 text-gray-300 mx-auto mb-3" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" /></svg>
          <p className="text-gray-500 font-medium">No patients yet</p>
          <p className="text-sm text-gray-400 mt-1">Patients who book an appointment with you will appear here.</p>
        </div>
      ) : (
        <div className="space-y-3">
          {patients.map((p) => {
            const subtitle = [p.blood_type, p.date_of_birth].filter(Boolean).join(' · ');
            return (
              <button
                key={p.user_id}
                onClick={() => setSelected(p)}
                className="w-full text-left rounded-xl bg-white border border-gray-100 shadow-sm p-4 hover:shadow-md transition-shadow"
              >
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center font-bold text-sm flex-shrink-0">
                    {p.full_name?.[0]?.toUpperCase() || '?'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-gray-900 truncate">{p.full_name || 'Patient'}</p>
                    {subtitle && <p className="text-sm text-gray-500">{subtitle}</p>}
                  </div>
                  <svg className="w-5 h-5 text-gray-400" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" /></svg>
                </div>
              </button>
            );
          })}
        </div>
      )}

      {/* Detail modal */}
      {selected && (
        <div className="fixed inset-0 z-50 bg-black/40 flex items-end sm:items-center justify-center" onClick={() => setSelected(null)}>
          <div className="bg-white rounded-t-2xl sm:rounded-2xl w-full sm:max-w-md max-h-[80vh] overflow-y-auto p-6" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-bold text-gray-900">{selected.full_name}</h2>
              <button onClick={() => setSelected(null)} className="text-gray-400 hover:text-gray-600">
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
              </button>
            </div>

            <div className="space-y-3">
              <DetailRow icon="🎂" label="Date of Birth" value={selected.date_of_birth || '—'} />
              <DetailRow icon="🩸" label="Blood Type" value={selected.blood_type || '—'} />
              {selected.allergies && selected.allergies.length > 0 && (
                <div>
                  <p className="text-xs font-semibold text-gray-500 mb-1">Allergies</p>
                  <p className="text-sm text-gray-900">{selected.allergies.join(', ')}</p>
                </div>
              )}
              {selected.emergency_contact && Object.keys(selected.emergency_contact).length > 0 && (
                <div>
                  <p className="text-xs font-semibold text-gray-500 mb-1">Emergency Contact</p>
                  {Object.entries(selected.emergency_contact).map(([k, v]) => (
                    <p key={k} className="text-sm text-gray-900">{k}: {v}</p>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function DetailRow({ icon, label, value }: { icon: string; label: string; value: string }) {
  return (
    <div className="flex items-start gap-3">
      <span className="text-sm">{icon}</span>
      <div>
        <p className="text-xs text-gray-500">{label}</p>
        <p className="text-sm font-medium text-gray-900">{value}</p>
      </div>
    </div>
  );
}
