'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { usersApi, authApi } from '@/lib/api-client';
import { useAuthStore } from '@/store/auth.store';
import { ProfileData } from '@/types';

export default function DoctorProfile() {
  const router = useRouter();
  const { logout: storeLogout, refreshToken } = useAuthStore();
  const [profile, setProfile] = useState<ProfileData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    usersApi.myProfile().then((r) => setProfile(r.data)).catch(() => {}).finally(() => setLoading(false));
  }, []);

  async function handleLogout() {
    if (!confirm('Are you sure you want to log out?')) return;
    try { if (refreshToken) await authApi.logout(refreshToken); } catch { /* */ }
    storeLogout();
    router.push('/login');
  }

  if (loading) {
    return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  if (!profile) {
    return (
      <div className="text-center py-20 text-gray-500">
        <p>Could not load profile</p>
        <button onClick={() => window.location.reload()} className="text-primary-600 hover:underline text-sm mt-2">Retry</button>
      </div>
    );
  }

  const initials = profile.full_name
    ? profile.full_name.split(' ').map((w) => w[0]).join('').slice(0, 2).toUpperCase()
    : 'Dr';

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      {/* Hero */}
      <div className="rounded-2xl bg-gradient-to-br from-primary-600 to-primary-800 p-8 text-white text-center">
        <div className="w-20 h-20 rounded-full border-2 border-white/40 bg-white/20 flex items-center justify-center text-3xl font-bold mx-auto">
          {initials}
        </div>
        <h1 className="text-2xl font-bold mt-4">Dr. {profile.full_name}</h1>
        <span className="inline-block mt-2 px-4 py-1 rounded-full bg-white/20 text-xs font-semibold">
          {profile.specialization || 'Doctor'}
        </span>
      </div>

      {/* Info */}
      <div className="rounded-xl bg-white border border-gray-100 shadow-sm overflow-hidden">
        <h2 className="px-5 py-3 text-sm font-semibold text-gray-500 bg-gray-50">Professional Info</h2>
        <div className="divide-y divide-gray-50">
          {[
            { icon: '✉️', label: 'Email', value: profile.email },
            { icon: '🔬', label: 'Specialization', value: profile.specialization || '—' },
            { icon: '🪪', label: 'License Number', value: profile.license_number || '—' },
          ].map((row) => (
            <div key={row.label} className="px-5 py-3.5 flex items-center gap-4">
              <div className="w-9 h-9 rounded-lg bg-primary-50 text-primary-600 flex items-center justify-center text-sm flex-shrink-0">{row.icon}</div>
              <div>
                <p className="text-xs text-gray-500">{row.label}</p>
                <p className="text-sm font-medium text-gray-900">{row.value}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {profile.bio && (
        <div className="rounded-xl bg-white border border-gray-100 shadow-sm p-5">
          <h2 className="font-semibold text-gray-900 mb-2">About</h2>
          <p className="text-sm text-gray-600 leading-relaxed">{profile.bio}</p>
        </div>
      )}

      {/* Actions */}
      <div className="space-y-2">
        <button
          onClick={() => { storeLogout(); router.push('/login'); }}
          className="w-full flex items-center gap-3 px-5 py-3.5 rounded-xl bg-white border border-gray-100 shadow-sm hover:bg-gray-50 transition-colors"
        >
          <div className="w-9 h-9 rounded-lg bg-gray-100 text-gray-500 flex items-center justify-center">🔀</div>
          <div className="text-left">
            <p className="text-sm font-medium text-gray-900">Switch Account</p>
            <p className="text-xs text-gray-500">Log in as a different user</p>
          </div>
        </button>
        <button
          onClick={handleLogout}
          className="w-full flex items-center gap-3 px-5 py-3.5 rounded-xl bg-white border border-gray-100 shadow-sm hover:bg-red-50 transition-colors"
        >
          <div className="w-9 h-9 rounded-lg bg-red-50 text-red-500 flex items-center justify-center">🚪</div>
          <div className="text-left">
            <p className="text-sm font-medium text-red-600">Log Out</p>
            <p className="text-xs text-gray-500">Sign out of your account</p>
          </div>
        </button>
      </div>
    </div>
  );
}
