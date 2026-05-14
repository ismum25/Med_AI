export type UserRole = 'doctor' | 'patient';

export interface User {
  id: string;
  email: string;
  full_name: string;
  role: UserRole;
  is_active: boolean;
  is_verified: boolean;
  created_at: string;
}

/** Week keys: mon..sun — values are "HH:mm-HH:mm" half-open intervals per day */
export interface DoctorProfile {
  user_id: string;
  specialization: string;
  license_number: string;
  available_slots: Record<string, string[]>;
  availability_timezone?: string | null;
  rating: number;
  bio?: string;
  user: User;
}

export interface DoctorListItem {
  user_id: string;
  full_name: string;
  specialization: string;
  rating: number;
}

export interface PatientProfile {
  user_id: string;
  blood_type: string | null;
  allergies: string[];
  emergency_contact: Record<string, string> | null;
  user: User;
}

export interface PatientDetail {
  user_id: string;
  full_name: string;
  date_of_birth?: string | null;
  blood_type?: string | null;
  allergies?: string[] | null;
  emergency_contact?: Record<string, string> | null;
}

export type AppointmentStatus =
  | 'pending'
  | 'confirmed'
  | 'cancelled'
  | 'completed'
  | 'no_show';

export interface Appointment {
  id: string;
  patient_id: string;
  doctor_id: string;
  scheduled_at: string;
  duration_minutes: number;
  status: AppointmentStatus;
  reason: string | null;
  notes: string | null;
  created_at: string;
  patient?: User;
  doctor?: User;
}

export interface DoctorSlots {
  date: string;
  available_slots: string[];
  booked_slots: string[];
}

export type OcrStatus = 'pending' | 'processing' | 'extracted' | 'failed' | 'verified';
export type ReportType = 'blood_test' | 'xray' | 'mri' | 'urine' | 'other';

export interface MedicalReport {
  id: string;
  patient_id: string;
  title: string;
  file_name?: string;
  report_type: ReportType;
  file_url: string;
  ocr_status: OcrStatus;
  ocr_confidence: number | null;
  verified: boolean;
  notes?: string | null;
  created_at: string;
  extracted_data?: Record<string, unknown>;
}

export interface Incident {
  id: string;
  patient_id: string;
  title: string;
  notes?: string | null;
  analysis_status: 'pending' | 'processing' | 'analyzed' | 'failed';
  injury_type?: string | null;
  severity?: string | null;
  body_area?: string | null;
  summary?: string | null;
  description?: string | null;
  created_at: string;
}

export interface ChatSession {
  id: string;
  user_id: string;
  title: string;
  created_at: string;
  updated_at: string;
}

export interface ChatMessage {
  id: string;
  session_id: string;
  role: 'user' | 'assistant' | 'tool';
  content: string;
  created_at: string;
}

/** Full profile response from /users/me/profile */
export interface ProfileData {
  id?: string;
  email: string;
  full_name: string;
  role: UserRole;
  // patient fields
  date_of_birth?: string | null;
  blood_type?: string | null;
  allergies?: string | string[] | null;
  // doctor fields
  specialization?: string | null;
  license_number?: string | null;
  bio?: string | null;
  available_slots?: Record<string, string[]> | null;
  availability_timezone?: string | null;
}

export interface AuthTokens {
  access_token: string;
  refresh_token: string;
  token_type: string;
  role: UserRole;
  user_id: string;
}

export interface ApiError {
  detail: string | { msg: string; type: string }[];
}
