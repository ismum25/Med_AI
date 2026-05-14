'use client';

import Link from 'next/link';

export default function DoctorChat() {
  return (
    <div className="flex flex-col items-center justify-center h-[60vh] text-center px-6">
      <div className="w-16 h-16 rounded-2xl bg-primary-50 dark:bg-primary-900/30 text-primary-600 flex items-center justify-center mb-4">
        <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
        </svg>
      </div>
      <h2 className="text-xl font-bold text-gray-900 dark:text-gray-100 mb-2">AI chat is available for patients only.</h2>
      <p className="text-sm text-gray-500 dark:text-gray-400 dark:text-gray-500 mb-6">Current account: DOCTOR</p>
      <Link href="/doctor/dashboard" className="bg-primary-600 text-white px-5 py-2 rounded-lg text-sm font-medium hover:bg-primary-700 transition-colors">
        Go Back
      </Link>
    </div>
  );
}
