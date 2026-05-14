'use client';

import * as React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname, useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth.store';
import { authApi } from '@/lib/api-client';
import clsx from 'clsx';
import { useTheme } from 'next-themes';
import { Sun, Moon } from 'lucide-react';

interface NavItem {
  label: string;
  href: string;
  icon: React.ReactNode;
}

const patientNav: NavItem[] = [
  {
    label: 'Dashboard',
    href: '/patient/dashboard',
    icon: <HomeIcon />,
  },
  {
    label: 'Appointments',
    href: '/patient/appointments',
    icon: <CalendarIcon />,
  },
  {
    label: 'Reports',
    href: '/patient/reports',
    icon: <FolderIcon />,
  },
  {
    label: 'Incidents',
    href: '/patient/incidents',
    icon: <IncidentIcon />,
  },
  {
    label: 'AI Assistant',
    href: '/patient/chat',
    icon: <ChatIcon />,
  },
];

const doctorNav: NavItem[] = [
  {
    label: 'Dashboard',
    href: '/doctor/dashboard',
    icon: <HomeIcon />,
  },
  {
    label: 'Schedule',
    href: '/doctor/appointments',
    icon: <CalendarIcon />,
  },
  {
    label: 'Patients',
    href: '/doctor/patients',
    icon: <UsersIcon />,
  },
  {
    label: 'Review',
    href: '/doctor/review',
    icon: <ReviewIcon />,
  },
];

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = React.useState(false);
  const { role, user, logout, refreshToken } = useAuthStore();

  React.useEffect(() => {
    setMounted(true);
  }, []);

  const navItems = role === 'doctor' ? doctorNav : patientNav;
  const profileHref = role === 'doctor' ? '/doctor/profile' : '/patient/profile';

  function isActive(href: string) {
    if (pathname === href) return true;
    // Highlight parent for nested routes like /patient/appointments/book
    if (href !== `/${role}/dashboard` && pathname.startsWith(href + '/')) return true;
    return false;
  }

  const initials = user?.full_name
    ? user.full_name
        .split(' ')
        .map((w) => w[0])
        .join('')
        .slice(0, 2)
        .toUpperCase()
    : role === 'doctor'
    ? 'Dr'
    : 'U';

  async function handleLogout() {
    try {
      if (refreshToken) await authApi.logout(refreshToken);
    } catch {
      // ignore
    }
    logout();
    router.push('/login');
  }

  return (
    <aside className="flex flex-col w-72 h-screen bg-white/60 dark:bg-slate-900/60 backdrop-blur-xl border-r border-gray-200/60 dark:border-slate-800/60 px-5 py-8 flex-shrink-0 relative shadow-[4px_0_24px_rgba(0,0,0,0.02)] dark:shadow-none">
      <div className="absolute top-0 left-0 right-0 h-40 bg-gradient-to-b from-primary-500/5 to-transparent pointer-events-none" />

      <div className="flex flex-col mb-10 px-2 relative z-10">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl shadow-sm overflow-hidden flex-shrink-0 border border-gray-100/50 dark:border-slate-700/50">
            <Image src="/logo-192.png" alt="Health Care logo" width={36} height={36} className="w-full h-full object-cover" />
          </div>
          <span className="text-lg font-bold tracking-tight text-gray-900 dark:text-gray-100">Health Care</span>
        </div>
        <div className="mt-3 inline-flex self-start px-3 py-1 bg-primary-600 text-white text-[10px] font-bold uppercase tracking-widest rounded-full shadow-sm shadow-primary-500/20">
          {role} Portal
        </div>
      </div>

      <nav className="flex-1 space-y-1">
        {navItems.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className={clsx(
              'flex items-center gap-3.5 px-4 py-3 rounded-xl text-sm font-semibold transition-all duration-200',
              isActive(item.href)
                ? 'bg-primary-600 text-white shadow-md shadow-primary-500/20 dark:shadow-none'
                : 'text-gray-500 hover:text-gray-900 hover:bg-gray-100/80 dark:text-gray-400 dark:hover:text-gray-100 dark:hover:bg-slate-800/80'
            )}
          >
            <span className={clsx("w-5 h-5 flex-shrink-0", isActive(item.href) ? "text-white" : "")}>{item.icon}</span>
            {item.label}
          </Link>
        ))}
      </nav>

      <div className="mt-auto pt-6 space-y-2 relative z-10">
        <button
          onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
          className="flex items-center gap-3.5 w-full px-4 py-3 rounded-xl text-sm font-semibold text-gray-500 hover:text-gray-900 hover:bg-gray-100/80 dark:text-gray-400 dark:hover:text-gray-100 dark:hover:bg-slate-800/80 transition-all duration-200"
        >
          <div className="w-5 h-5 flex items-center justify-center">
            {mounted && theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
          </div>
          {mounted && theme === 'dark' ? 'Light Mode' : 'Dark Mode'}
        </button>

        <div className="h-px w-full bg-gradient-to-r from-transparent via-gray-200 dark:via-slate-800 to-transparent my-4" />

        <Link
          href={profileHref}
          className={clsx(
            'flex items-center gap-3.5 px-4 py-3 rounded-xl transition-all duration-200',
            pathname === profileHref
              ? 'bg-primary-50 dark:bg-slate-800/80 text-primary-700 dark:text-primary-400'
              : 'hover:bg-gray-100/80 dark:hover:bg-slate-800/80'
          )}
        >
          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary-500 to-primary-600 text-white flex items-center justify-center text-sm font-bold flex-shrink-0 shadow-sm border-2 border-white dark:border-slate-800">
            {initials}
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-sm font-bold text-gray-900 dark:text-gray-100 truncate">{user?.full_name ?? 'User'}</p>
            <p className="text-xs font-medium text-gray-500 dark:text-gray-400 capitalize">{role}</p>
          </div>
        </Link>

        <button
          onClick={handleLogout}
          className="flex items-center gap-3.5 w-full px-4 py-3 rounded-xl text-sm font-semibold text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 hover:text-red-600 dark:hover:text-red-400 transition-all duration-200"
        >
          <LogoutIcon />
          Sign Out
        </button>
      </div>
    </aside>
  );
}

function HomeIcon() {
  return (
    <svg fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25" />
    </svg>
  );
}

function CalendarIcon() {
  return (
    <svg fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5" />
    </svg>
  );
}

function FolderIcon() {
  return (
    <svg fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 12.75V12A2.25 2.25 0 014.5 9.75h15A2.25 2.25 0 0121.75 12v.75m-8.69-6.44l-2.12-2.12a1.5 1.5 0 00-1.061-.44H4.5A2.25 2.25 0 002.25 6v12a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9a2.25 2.25 0 00-2.25-2.25h-5.379a1.5 1.5 0 01-1.06-.44z" />
    </svg>
  );
}

function IncidentIcon() {
  return (
    <svg fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z" />
    </svg>
  );
}

function ChatIcon() {
  return (
    <svg fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09zM18.259 8.715L18 9.75l-.259-1.035a3.375 3.375 0 00-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 002.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 002.455 2.456L21.75 6l-1.036.259a3.375 3.375 0 00-2.455 2.456z" />
    </svg>
  );
}

function ReviewIcon() {
  return (
    <svg fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" d="M11.35 3.836c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m8.9-4.414c.376.023.75.05 1.124.08 1.131.094 1.976 1.057 1.976 2.192V16.5A2.25 2.25 0 0118 18.75h-2.25m-7.5-10.5H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V18.75m-7.5-10.5h6.375c.621 0 1.125.504 1.125 1.125v9.375m-8.25-3l1.5 1.5 3-3.75" />
    </svg>
  );
}

function UsersIcon() {
  return (
    <svg fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
    </svg>
  );
}

function LogoutIcon() {
  return (
    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15M12 9l-3 3m0 0l3 3m-3-3h12.75" />
    </svg>
  );
}
