'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import toast from 'react-hot-toast';
import { doctorsApi, appointmentsApi } from '@/lib/api-client';
import { DoctorProfile } from '@/types';

export default function BookAppointmentPage() {
  const router = useRouter();
  const [doctors, setDoctors] = useState<DoctorProfile[]>([]);
  const [loading, setLoading] = useState(false);
  const [form, setForm] = useState({
    doctor_id: '',
    scheduled_at: '',
    reason: '',
  });

  useEffect(() => {
    doctorsApi.list().then(({ data }) => setDoctors(data.items ?? data)).catch(() => {});
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    try {
      await appointmentsApi.create({
        doctor_id: form.doctor_id,
        scheduled_at: new Date(form.scheduled_at).toISOString(),
        reason: form.reason || undefined,
      });
      toast.success('Appointment booked!');
      router.push('/patient/appointments');
    } catch (err: unknown) {
      const message = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail;
      toast.error(typeof message === 'string' ? message : 'Failed to book appointment');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Book Appointment</h1>
      <div className="card max-w-lg">
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Select Doctor</label>
            <select
              className="input"
              value={form.doctor_id}
              onChange={(e) => setForm((p) => ({ ...p, doctor_id: e.target.value }))}
              required
            >
              <option value="">Choose a doctor...</option>
              {doctors.map((d) => (
                <option key={d.user_id} value={d.user_id}>
                  Dr. {d.user.full_name} — {d.specialization}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Date & Time</label>
            <input
              type="datetime-local"
              className="input"
              value={form.scheduled_at}
              onChange={(e) => setForm((p) => ({ ...p, scheduled_at: e.target.value }))}
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Reason (optional)</label>
            <textarea
              className="input"
              rows={3}
              value={form.reason}
              onChange={(e) => setForm((p) => ({ ...p, reason: e.target.value }))}
              placeholder="Briefly describe your reason for visiting..."
            />
          </div>
          <div className="flex gap-3 pt-2">
            <button
              type="button"
              onClick={() => router.back()}
              className="btn-secondary flex-1"
            >
              Cancel
            </button>
            <button type="submit" disabled={loading} className="btn-primary flex-1">
              {loading ? 'Booking...' : 'Book Appointment'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
