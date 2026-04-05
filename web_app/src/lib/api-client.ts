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
          original.headers!.Authorization = `Bearer ${data.access_token}`;
          return client(original);
        } catch {
          localStorage.clear();
          window.location.href = '/login';
        }
      }
      return Promise.reject(error);
    }
  );

  return client;
}

export const api = createApiClient();

// Auth
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

// Appointments
export const appointmentsApi = {
  list: (params?: { status?: string; page?: number }) =>
    api.get('/appointments', { params }),
  create: (data: { doctor_id: string; scheduled_at: string; reason?: string }) =>
    api.post('/appointments', data),
  update: (id: string, data: { status?: string; notes?: string }) =>
    api.patch(`/appointments/${id}`, data),
  cancel: (id: string, reason?: string) =>
    api.delete(`/appointments/${id}`, { params: { reason } }),
};

// Doctors
export const doctorsApi = {
  list: (params?: { specialization?: string; page?: number }) =>
    api.get('/users/doctors', { params }),
  get: (id: string) => api.get(`/users/doctors/${id}`),
};

// Reports
export const reportsApi = {
  list: () => api.get('/reports'),
  get: (id: string) => api.get(`/reports/${id}`),
  upload: (formData: FormData) =>
    api.post('/reports', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),
  verify: (id: string) => api.post(`/reports/${id}/verify`),
};

// Chat
export const chatApi = {
  listSessions: () => api.get('/chat/sessions'),
  createSession: (title?: string) =>
    api.post('/chat/sessions', { title: title ?? 'New Chat' }),
  getMessages: (sessionId: string) =>
    api.get(`/chat/sessions/${sessionId}/messages`),
  deleteSession: (sessionId: string) =>
    api.delete(`/chat/sessions/${sessionId}`),
};
