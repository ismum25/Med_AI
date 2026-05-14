'use client';

import { useEffect, useState } from 'react';
import { appointmentsApi, usersApi } from '@/lib/api-client';
import { Appointment, ProfileData } from '@/types';
import { formatDate, formatTime, statusColor, capitalize } from '@/lib/utils';
import toast from 'react-hot-toast';

const DAY_KEYS = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
const DAY_NAMES = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const DAY_BADGES = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
const TIMEZONES = ['UTC','Asia/Dhaka','Asia/Kolkata','Asia/Singapore','Asia/Tokyo','Asia/Dubai','Europe/London','Europe/Paris','America/New_York','America/Chicago','America/Los_Angeles','Australia/Sydney'];

interface DayRange { start: string; end: string; }

export default function DoctorSchedule() {
  const [segment, setSegment] = useState<'hours' | 'appointments'>('hours');
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [ranges, setRanges] = useState<Record<string, DayRange[]>>({});
  const [timezone, setTimezone] = useState<string>('');
  const [dirty, setDirty] = useState(false);
  const [saving, setSaving] = useState(false);
  const [loading, setLoading] = useState(true);
  const [editDay, setEditDay] = useState<number | null>(null);

  useEffect(() => { load(); }, []);

  async function load() {
    setLoading(true);
    try {
      const [profileRes, apptRes] = await Promise.all([usersApi.myProfile(), appointmentsApi.list()]);
      const p = profileRes.data as ProfileData;
      setAppointments(apptRes.data);
      setTimezone(p.availability_timezone || '');
      const slots = p.available_slots || {};
      const parsed: Record<string, DayRange[]> = {};
      for (const k of DAY_KEYS) {
        const arr = slots[k] || [];
        parsed[k] = arr.map((s: string) => {
          const [start, end] = s.split('-');
          return { start: start?.trim() || '09:00', end: end?.trim() || '17:00' };
        });
      }
      setRanges(parsed);
      setDirty(false);
    } catch { /* ignore */ }
    setLoading(false);
  }

  async function save() {
    if (!timezone && Object.values(ranges).some((r) => r.length > 0)) {
      toast.error('Select a timezone before saving'); return;
    }
    setSaving(true);
    try {
      const payload: Record<string, string[]> = {};
      for (const k of DAY_KEYS) {
        payload[k] = (ranges[k] || []).map((r) => `${r.start}-${r.end}`);
      }
      await usersApi.updateDoctorProfile({ available_slots: payload, availability_timezone: timezone });
      toast.success('Availability saved');
      setDirty(false);
    } catch {
      toast.error('Save failed');
    }
    setSaving(false);
  }

  function addInterval(dayIndex: number) {
    const key = DAY_KEYS[dayIndex];
    setRanges((prev) => ({
      ...prev,
      [key]: [...(prev[key] || []), { start: '09:00', end: '17:00' }],
    }));
    setDirty(true);
  }

  function removeInterval(dayIndex: number, idx: number) {
    const key = DAY_KEYS[dayIndex];
    setRanges((prev) => ({
      ...prev,
      [key]: (prev[key] || []).filter((_, i) => i !== idx),
    }));
    setDirty(true);
  }

  function updateInterval(dayIndex: number, idx: number, field: 'start' | 'end', val: string) {
    const key = DAY_KEYS[dayIndex];
    setRanges((prev) => ({
      ...prev,
      [key]: (prev[key] || []).map((r, i) => i === idx ? { ...r, [field]: val } : r),
    }));
    setDirty(true);
  }

  if (loading) {
    return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  return (
    <div className="max-w-5xl mx-auto space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Schedule</h1>

      {/* Segment toggle */}
      <div className="flex gap-1 bg-gray-100 rounded-lg p-1 max-w-xs">
        {(['hours', 'appointments'] as const).map((s) => (
          <button
            key={s}
            onClick={() => setSegment(s)}
            className={`flex-1 px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
              segment === s ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            {s === 'hours' ? 'Weekly Hours' : 'Appointments'}
          </button>
        ))}
      </div>

      {segment === 'hours' ? (
        <div className="space-y-4">
          <p className="text-sm text-gray-500">Patients can request appointments within these windows.</p>

          {/* Timezone */}
          <div className="rounded-xl bg-white border border-gray-100 shadow-sm p-4 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <span className="text-primary-600">🌍</span>
              <div>
                <p className="text-sm font-medium text-gray-900">Timezone</p>
                <p className="text-xs text-gray-500">{timezone || 'Not set (required)'}</p>
              </div>
            </div>
            <select
              value={timezone}
              onChange={(e) => { setTimezone(e.target.value); setDirty(true); }}
              className="border border-gray-200 rounded-lg px-2 py-1.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-primary-500"
            >
              <option value="">Select...</option>
              {TIMEZONES.map((z) => <option key={z} value={z}>{z}</option>)}
            </select>
          </div>

          {/* Day cards */}
          <div className="space-y-2">
            {DAY_KEYS.map((key, i) => {
              const dayRanges = ranges[key] || [];
              return (
                <div key={key} className="rounded-xl bg-white border border-gray-100 shadow-sm p-4">
                  <div className="flex items-start gap-3">
                    <div className="w-10 h-10 rounded-full bg-primary-600 text-white flex items-center justify-center text-xs font-bold flex-shrink-0">
                      {DAY_BADGES[i]}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center justify-between">
                        <h3 className="font-semibold text-gray-900">{DAY_NAMES[i]}</h3>
                        <button onClick={() => addInterval(i)} className="text-xs text-primary-600 hover:underline font-medium">+ Add</button>
                      </div>
                      {dayRanges.length === 0 ? (
                        <p className="text-sm text-gray-400 mt-1">Unavailable</p>
                      ) : (
                        <div className="mt-2 space-y-2">
                          {dayRanges.map((r, ri) => (
                            <div key={ri} className="flex items-center gap-2">
                              <input type="time" value={r.start} onChange={(e) => updateInterval(i, ri, 'start', e.target.value)} className="border border-gray-200 rounded px-2 py-1 text-sm" />
                              <span className="text-gray-400">–</span>
                              <input type="time" value={r.end} onChange={(e) => updateInterval(i, ri, 'end', e.target.value)} className="border border-gray-200 rounded px-2 py-1 text-sm" />
                              <button onClick={() => removeInterval(i, ri)} className="text-red-400 hover:text-red-600 ml-1">
                                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
                              </button>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {dirty && (
            <button onClick={save} disabled={saving} className="w-full py-3 rounded-xl bg-primary-600 text-white font-semibold hover:bg-primary-700 disabled:bg-gray-300 transition-colors">
              {saving ? 'Saving...' : 'Save Availability'}
            </button>
          )}
        </div>
      ) : (
        <div className="space-y-3">
          {appointments.length === 0 ? (
            <div className="text-center py-12 text-gray-500">No appointments</div>
          ) : appointments.map((a) => (
            <div key={a.id} className="rounded-xl bg-white border border-gray-100 shadow-sm p-4 flex items-center gap-4">
              <div className="w-10 h-10 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center text-sm font-bold flex-shrink-0">
                {a.patient?.full_name?.[0]?.toUpperCase() || 'P'}
              </div>
              <div className="flex-1 min-w-0">
                <p className="font-semibold text-gray-900 truncate">{a.patient?.full_name || 'Patient'}</p>
                <p className="text-sm text-gray-500">{formatDate(a.scheduled_at, 'MMM d')} at {formatTime(a.scheduled_at)} • {a.reason || 'Consultation'}</p>
              </div>
              <span className={`text-xs font-medium px-2.5 py-1 rounded-full ${statusColor(a.status)}`}>{capitalize(a.status)}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
