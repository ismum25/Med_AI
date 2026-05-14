import axios, { AxiosInstance, AxiosError } from 'axios';

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000/api/v1';

function createApiClient(): AxiosInstance {
  const client = axios.create({
    baseURL: BASE_URL,
    headers: { 'Content-Type': 'application/json' },
    timeout: 30000,
  });

  client.interceptors.request.use((config) => {
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('access_token');
      if (token) config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  });

  client.interceptors.response.use(
    (response) => response,
    async (error: AxiosError) => {
      const original = error.config as typeof error.config & { _retry?: boolean };
      if (error.response?.status === 401 && !original._retry) {
        original._retry = true;
        try {
          const refreshToken = localStorage.getItem('refresh_token');
          if (!refreshToken) throw new Error('No refresh token');
          const { data } = await axios.post(`${BASE_URL}/auth/refresh`, {
            refresh_token: refreshToken,
          });
          localStorage.setItem('access_token', data.access_token);
          document.cookie = `access_token=${data.access_token}; path=/; max-age=86400; SameSite=Lax`;
          original.headers!.Authorization = `Bearer ${data.access_token}`;
          return client(original);
        } catch {
          localStorage.clear();
          document.cookie = 'access_token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
          document.cookie = 'user_role=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
          window.location.href = '/login';
        }
      }
      return Promise.reject(error);
    }
  );

  return client;
}

export const api = createApiClient();

/** Get the auth header for fetch()-based calls (SSE streaming etc.) */
export function getAuthHeader(): Record<string, string> {
  const token = typeof window !== 'undefined' ? localStorage.getItem('access_token') : null;
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export { BASE_URL };

// ──────────────────────────────────────────────────
// Auth
// ──────────────────────────────────────────────────
export const authApi = {
  login: (email: string, password: string) =>
    api.post('/auth/login', { email, password }),
  register: (data: {
    email: string;
    password: string;
    role: string;
    full_name: string;
    specialization?: string;
    license_number?: string;
  }) => api.post('/auth/register', data),
  me: () => api.get('/auth/me'),
  logout: (refreshToken: string) =>
    api.post('/auth/logout', { refresh_token: refreshToken }),
};

// ──────────────────────────────────────────────────
// Users / Doctors
// ──────────────────────────────────────────────────
export const usersApi = {
  myProfile: () => api.get('/users/me/profile'),
  myPatients: () => api.get('/users/me/patients'),
  updateDoctorProfile: (data: {
    available_slots?: Record<string, string[]>;
    availability_timezone?: string;
  }) => api.patch('/users/me/doctor-profile', data),
};

export const doctorsApi = {
  list: (params?: { specialization?: string; page?: number }) =>
    api.get('/users/doctors', { params }),
  get: (id: string) => api.get(`/users/doctors/${id}`),
  specializations: () => api.get('/users/doctors/specializations'),
};

// ──────────────────────────────────────────────────
// Appointments
// ──────────────────────────────────────────────────
export const appointmentsApi = {
  list: (params?: { status?: string; page?: number }) =>
    api.get('/appointments/', { params }),
  create: (data: { doctor_id: string; scheduled_at: string; reason?: string }) =>
    api.post('/appointments/', data),
  update: (id: string, data: { status?: string; notes?: string }) =>
    api.patch(`/appointments/${id}`, data),
  cancel: (id: string, reason?: string) =>
    api.delete(`/appointments/${id}`, { params: reason ? { reason } : undefined }),
  doctorSlots: (doctorUserId: string, date: string) =>
    api.get(`/appointments/doctors/${doctorUserId}/slots`, { params: { date } }),
};

// ──────────────────────────────────────────────────
// Reports
// ──────────────────────────────────────────────────
export const reportsApi = {
  list: () => api.get('/reports/'),
  get: (id: string) => api.get(`/reports/${id}`),
  upload: (formData: FormData) =>
    api.post('/reports/', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),
  update: (id: string, data: { title?: string }) =>
    api.patch(`/reports/${id}`, data),
  delete: (id: string) => api.delete(`/reports/${id}`),
  download: (id: string) => api.get(`/reports/${id}/download`),
  verify: (id: string, data: { data: Record<string, unknown>; notes?: string }) =>
    api.patch(`/reports/${id}/verify`, data),
  pendingReview: () => api.get('/reports/queue/pending-review'),
  patientReports: (patientId: string) => api.get(`/reports/patient/${patientId}`),
};

// ──────────────────────────────────────────────────
// Incidents
// ──────────────────────────────────────────────────
export const incidentsApi = {
  list: () => api.get('/incidents/'),
  get: (id: string) => api.get(`/incidents/${id}`),
  upload: (formData: FormData) =>
    api.post('/incidents/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),
  delete: (id: string) => api.delete(`/incidents/${id}`),
  downloadUrl: (id: string) => `${BASE_URL}/incidents/${id}/download`,
};

// ──────────────────────────────────────────────────
// Chat
// ──────────────────────────────────────────────────
export const chatApi = {
  listSessions: () => api.get('/chat/sessions'),
  createSession: (title?: string) =>
    api.post('/chat/sessions', { title: title ?? 'New Chat' }),
  getSession: (sessionId: string) => api.get(`/chat/sessions/${sessionId}`),
  getMessages: (sessionId: string) =>
    api.get(`/chat/sessions/${sessionId}/messages`),
  deleteSession: (sessionId: string) =>
    api.delete(`/chat/sessions/${sessionId}`),
  /** Returns the SSE endpoint URL — use fetch() directly for streaming */
  messagesUrl: (sessionId: string) =>
    `${BASE_URL}/chat/sessions/${sessionId}/messages`,
};
