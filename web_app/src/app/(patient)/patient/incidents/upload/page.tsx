'use client';

import { useState, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { incidentsApi } from '@/lib/api-client';
import toast from 'react-hot-toast';

export default function UploadIncident() {
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [title, setTitle] = useState('');
  const [notes, setNotes] = useState('');
  const [uploading, setUploading] = useState(false);

  function handleFile(f: File | null) {
    setFile(f);
    if (f) {
      const url = URL.createObjectURL(f);
      setPreview(url);
    } else {
      setPreview(null);
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!file) return;
    setUploading(true);
    try {
      const formData = new FormData();
      formData.append('file', file);
      if (title.trim()) formData.append('title', title.trim());
      if (notes.trim()) formData.append('notes', notes.trim());
      const res = await incidentsApi.upload(formData);
      const id = res.data?.id;
      toast.success('Incident uploaded and analyzed');
      router.push(id ? `/patient/incidents/${id}` : '/patient/incidents');
    } catch {
      toast.error('Upload failed');
    }
    setUploading(false);
  }

  return (
    <div className="max-w-lg mx-auto space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Upload Incident</h1>

      <form onSubmit={handleSubmit} className="space-y-5">
        {/* Drop zone */}
        <div
          onClick={() => fileRef.current?.click()}
          onDragOver={(e) => e.preventDefault()}
          onDrop={(e) => { e.preventDefault(); handleFile(e.dataTransfer.files[0] || null); }}
          className={`relative border-2 border-dashed rounded-2xl h-48 flex flex-col items-center justify-center cursor-pointer transition-colors ${
            file ? 'border-primary-400 bg-primary-50/50' : 'border-gray-300 hover:border-primary-400'
          }`}
        >
          {preview ? (
            <img src={preview} alt="preview" className="absolute inset-0 w-full h-full object-cover rounded-2xl opacity-30" />
          ) : null}
          <div className="relative z-10 text-center">
            {file ? (
              <>
                <svg className="w-10 h-10 text-green-500 mx-auto" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                <p className="text-sm text-gray-700 mt-2 font-medium">{file.name}</p>
                <p className="text-xs text-gray-500">Click or drag to replace</p>
              </>
            ) : (
              <>
                <svg className="w-10 h-10 text-gray-400 mx-auto" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M6.827 6.175A2.31 2.31 0 015.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574V18a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 00-1.134-.175 2.31 2.31 0 01-1.64-1.055l-.822-1.316a2.192 2.192 0 00-1.736-1.039 48.774 48.774 0 00-5.232 0 2.192 2.192 0 00-1.736 1.039l-.821 1.316z" /><path strokeLinecap="round" strokeLinejoin="round" d="M16.5 12.75a4.5 4.5 0 11-9 0 4.5 4.5 0 019 0z" /></svg>
                <p className="text-sm text-gray-500 mt-2">Click or drag an injury photo</p>
              </>
            )}
          </div>
          <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={(e) => handleFile(e.target.files?.[0] || null)} />
        </div>

        <div>
          <label className="text-sm font-medium text-gray-700 mb-1 block">Title (optional)</label>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="e.g. Left arm burn"
            disabled={uploading}
            className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
          />
        </div>

        <div>
          <label className="text-sm font-medium text-gray-700 mb-1 block">Notes (optional)</label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Additional details about the incident..."
            disabled={uploading}
            rows={3}
            className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
          />
        </div>

        <button
          type="submit"
          disabled={!file || uploading}
          className="w-full py-3 rounded-xl bg-primary-600 text-white font-semibold hover:bg-primary-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-2"
        >
          {uploading ? (
            <><div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" /> Analyzing...</>
          ) : (
            <><svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5m-13.5-9L12 3m0 0l4.5 4.5M12 3v13.5" /></svg> Analyze Incident</>
          )}
        </button>

        <p className="text-sm text-gray-400 text-center">
          Upload a clear injury photo so the AI can identify the injury type and severity.
        </p>
      </form>
    </div>
  );
}
