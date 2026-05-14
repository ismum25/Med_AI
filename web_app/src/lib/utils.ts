import { format, parseISO, isAfter, isToday } from 'date-fns';

export function greeting(): string {
  const h = new Date().getHours();
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

export function formatDate(iso: string, fmt = 'MMM d, yyyy'): string {
  try {
    return format(parseISO(iso), fmt);
  } catch {
    return iso;
  }
}

export function formatDateTime(iso: string): string {
  return formatDate(iso, 'MMM d, yyyy • h:mm a');
}

export function formatTime(iso: string): string {
  return formatDate(iso, 'h:mm a');
}

export function capitalize(s: string): string {
  if (!s) return s;
  return s.charAt(0).toUpperCase() + s.slice(1);
}

export function humanizeSnake(s: string): string {
  return capitalize(s.replace(/_/g, ' '));
}

export function isUpcoming(scheduledAt: string, status: string): boolean {
  return isAfter(parseISO(scheduledAt), new Date()) && status !== 'cancelled' && status !== 'completed';
}

export function isTodayAppointment(scheduledAt: string, status: string): boolean {
  return isToday(parseISO(scheduledAt)) && status !== 'cancelled';
}

export function timeAgo(createdAt: string): string {
  const dt = parseISO(createdAt);
  const diff = Date.now() - dt.getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days === 1) return 'Yesterday';
  return `${days}d ago`;
}

export function statusColor(status: string): string {
  switch (status) {
    case 'confirmed':
    case 'verified':
    case 'analyzed':
      return 'text-emerald-700 bg-emerald-50';
    case 'pending':
    case 'processing':
      return 'text-amber-700 bg-amber-50';
    case 'cancelled':
    case 'failed':
      return 'text-red-700 bg-red-50';
    case 'completed':
      return 'text-blue-700 bg-blue-50';
    case 'extracted':
      return 'text-violet-700 bg-violet-50';
    default:
      return 'text-gray-700 bg-gray-100';
  }
}
