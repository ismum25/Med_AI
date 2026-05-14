'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

/** Legacy redirect — doctor reports moved to /doctor/review */
export default function DoctorReportsPage() {
  const router = useRouter();
  useEffect(() => { router.replace('/doctor/review'); }, [router]);
  return (
    <div className="flex justify-center py-20">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" />
    </div>
  );
}
