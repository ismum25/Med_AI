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
  user: User;
}

export interface PatientProfile {
  user_id: string;
  blood_type: string | null;
  allergies: string[];
  emergency_contact: Record<string, string> | null;
  user: User;
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

export type OcrStatus = 'pending' | 'processing' | 'extracted' | 'failed';
export type ReportType = 'blood_test' | 'xray' | 'mri' | 'urine' | 'other';

export interface MedicalReport {
  id: string;
  patient_id: string;
  title: string;
  report_type: ReportType;
  file_url: string;
  ocr_status: OcrStatus;
  ocr_confidence: number | null;
  verified: boolean;
  created_at: string;
  extracted_data?: ExtractedReportData;
}

export interface ExtractedReportData {
  id: string;
  report_id: string;
  data: Record<string, unknown>;
  data_type: string;
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
