'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { doctorsApi, appointmentsApi } from '@/lib/api-client';
import { DoctorListItem, DoctorSlots } from '@/types';
import toast from 'react-hot-toast';

export default function BookAppointment() {
  const router = useRouter();
  const [step, setStep] = useState(0);
  const [doctors, setDoctors] = useState<DoctorListItem[]>([]);
  const [specializations, setSpecializations] = useState<string[]>([]);
  const [selectedSpec, setSelectedSpec] = useState('');
  const [selectedDoctor, setSelectedDoctor] = useState<DoctorListItem | null>(null);
  const [selectedDate, setSelectedDate] = useState('');
  const [slots, setSlots] = useState<DoctorSlots | null>(null);
  const [selectedSlot, setSelectedSlot] = useState('');
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [slotsLoading, setSlotsLoading] = useState(false);

  useEffect(() => {
    Promise.all([doctorsApi.list(), doctorsApi.specializations()])
      .then(([docRes, specRes]) => {
        setDoctors(docRes.data);
        setSpecializations(specRes.data);
      })
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    if (selectedDoctor && selectedDate) loadSlots();
  }, [selectedDoctor, selectedDate]);

  async function loadSlots() {
    if (!selectedDoctor || !selectedDate) return;
    setSlotsLoading(true);
    setSelectedSlot('');
    try {
      const res = await appointmentsApi.doctorSlots(selectedDoctor.user_id, selectedDate);
      setSlots(res.data);
    } catch {
      setSlots(null);
      toast.error('Failed to load slots');
    }
    setSlotsLoading(false);
  }

  async function handleSubmit() {
    if (!selectedDoctor || !selectedSlot) return;
    setSubmitting(true);
    try {
      await appointmentsApi.create({
        doctor_id: selectedDoctor.user_id,
        scheduled_at: selectedSlot,
        reason: reason || undefined,
      });
      toast.success('Appointment booked!');
      router.push('/patient/appointments');
    } catch {
      toast.error('Failed to book appointment');
    }
    setSubmitting(false);
  }

  const filteredDoctors = selectedSpec ? doctors.filter((d) => d.specialization === selectedSpec) : doctors;

  const today = new Date().toISOString().split('T')[0];

  if (loading) {
    return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-6">Book an Appointment</h1>

      {/* Progress */}
      <div className="flex items-center gap-2 mb-8">
        {['Doctor', 'Date & Time', 'Confirm'].map((label, i) => (
          <div key={label} className="flex items-center gap-2 flex-1">
            <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold ${
              i <= step ? 'bg-primary-600 text-white' : 'bg-gray-200 dark:bg-slate-700 text-gray-500 dark:text-gray-400 dark:text-gray-500'
            }`}>{i + 1}</div>
            <span className={`text-sm font-medium ${i <= step ? 'text-gray-900 dark:text-gray-100' : 'text-gray-400 dark:text-gray-500'}`}>{label}</span>
          </div>
        ))}
      </div>

      {/* Step 0: Select Doctor */}
      {step === 0 && (
        <div className="space-y-4">
          <select
            value={selectedSpec}
            onChange={(e) => setSelectedSpec(e.target.value)}
            className="w-full border border-gray-200 dark:border-slate-800 rounded-lg px-3 py-2 text-sm bg-white dark:bg-slate-900 focus:outline-none focus:ring-2 focus:ring-primary-500"
          >
            <option value="">All Specializations</option>
            {specializations.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
          <div className="space-y-2">
            {filteredDoctors.map((d) => (
              <button
                key={d.user_id}
                onClick={() => { setSelectedDoctor(d); setStep(1); }}
                className={`w-full text-left rounded-xl border p-4 transition-all ${
                  selectedDoctor?.user_id === d.user_id ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/30' : 'border-gray-100 dark:border-slate-800 bg-white dark:bg-slate-900 hover:border-primary-200'
                }`}
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center font-bold text-sm">
                    {d.full_name?.[0]?.toUpperCase() || 'D'}
                  </div>
                  <div>
                    <p className="font-semibold text-gray-900 dark:text-gray-100">{d.full_name}</p>
                    <p className="text-sm text-gray-500 dark:text-gray-400 dark:text-gray-500">{d.specialization}</p>
                  </div>
                </div>
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Step 1: Select Date & Time */}
      {step === 1 && (
        <div className="space-y-6">
          <div>
            <label className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1 block">Select Date</label>
            <input
              type="date"
              value={selectedDate}
              min={today}
              onChange={(e) => setSelectedDate(e.target.value)}
              className="w-full border border-gray-200 dark:border-slate-800 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </div>

          {slotsLoading && (
            <div className="flex justify-center py-4"><div className="animate-spin rounded-full h-6 w-6 border-b-2 border-primary-600" /></div>
          )}

          {slots && !slotsLoading && (
            <div>
              <p className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Available Slots</p>
              {slots.available_slots.length === 0 ? (
                <p className="text-sm text-gray-500 dark:text-gray-400 dark:text-gray-500 py-4">No available slots for this date</p>
              ) : (
                <div className="grid grid-cols-3 gap-2">
                  {slots.available_slots.map((slot) => {
                    const booked = slots.booked_slots.includes(slot);
                    const iso = `${selectedDate}T${slot}`;
                    return (
                      <button
                        key={slot}
                        disabled={booked}
                        onClick={() => setSelectedSlot(iso)}
                        className={`px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                          booked
                            ? 'bg-gray-100 dark:bg-slate-800 text-gray-400 dark:text-gray-500 cursor-not-allowed line-through'
                            : selectedSlot === iso
                            ? 'bg-primary-600 text-white'
                            : 'bg-white dark:bg-slate-900 border border-gray-200 dark:border-slate-800 text-gray-700 dark:text-gray-300 hover:border-primary-400'
                        }`}
                      >
                        {slot}
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          )}

          <div className="flex gap-3">
            <button onClick={() => setStep(0)} className="px-4 py-2 rounded-lg border border-gray-200 dark:border-slate-800 text-gray-700 dark:text-gray-300 text-sm font-medium hover:bg-gray-50 dark:bg-slate-950">
              Back
            </button>
            <button
              onClick={() => setStep(2)}
              disabled={!selectedSlot}
              className="flex-1 px-4 py-2 rounded-lg bg-primary-600 text-white text-sm font-medium hover:bg-primary-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
            >
              Continue
            </button>
          </div>
        </div>
      )}

      {/* Step 2: Confirm */}
      {step === 2 && (
        <div className="space-y-6">
          <div className="rounded-xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 p-4 space-y-3">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center font-bold text-sm">
                {selectedDoctor?.full_name?.[0]?.toUpperCase() || 'D'}
              </div>
              <div>
                <p className="font-semibold text-gray-900 dark:text-gray-100">{selectedDoctor?.full_name}</p>
                <p className="text-sm text-gray-500 dark:text-gray-400 dark:text-gray-500">{selectedDoctor?.specialization}</p>
              </div>
            </div>
            <div className="text-sm text-gray-700 dark:text-gray-300">
              <p><span className="font-medium">Date:</span> {selectedDate}</p>
              <p><span className="font-medium">Time:</span> {selectedSlot.split('T')[1] || selectedSlot}</p>
            </div>
          </div>

          <div>
            <label className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1 block">Reason (optional)</label>
            <textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="Describe the reason for your visit..."
              className="w-full border border-gray-200 dark:border-slate-800 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
              rows={3}
            />
          </div>

          <div className="flex gap-3">
            <button onClick={() => setStep(1)} className="px-4 py-2 rounded-lg border border-gray-200 dark:border-slate-800 text-gray-700 dark:text-gray-300 text-sm font-medium hover:bg-gray-50 dark:bg-slate-950">
              Back
            </button>
            <button
              onClick={handleSubmit}
              disabled={submitting}
              className="flex-1 px-4 py-2 rounded-lg bg-primary-600 text-white text-sm font-medium hover:bg-primary-700 disabled:bg-gray-300 transition-colors"
            >
              {submitting ? 'Booking...' : 'Confirm Booking'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
