'use client';

import { useEffect, useRef, useState } from 'react';
import toast from 'react-hot-toast';
import { chatApi } from '@/lib/api-client';
import { ChatSession, ChatMessage } from '@/types';

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000/api/v1';

interface DisplayMessage {
  role: 'user' | 'assistant';
  content: string;
  isStreaming?: boolean;
}

export default function DoctorChatPage() {
  const [sessions, setSessions] = useState<ChatSession[]>([]);
  const [activeSession, setActiveSession] = useState<ChatSession | null>(null);
  const [messages, setMessages] = useState<DisplayMessage[]>([]);
  const [input, setInput] = useState('');
  const [sending, setSending] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    chatApi.listSessions().then(({ data }) => setSessions(data.items ?? data)).catch(() => {});
  }, []);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  async function createSession() {
    try {
      const { data } = await chatApi.createSession();
      setSessions((p) => [data, ...p]);
      setActiveSession(data);
      setMessages([]);
    } catch {
      toast.error('Failed to create session');
    }
  }

  async function loadSession(session: ChatSession) {
    setActiveSession(session);
    try {
      const { data } = await chatApi.getMessages(session.id);
      const msgs: ChatMessage[] = data.items ?? data;
      setMessages(
        msgs
          .filter((m) => m.role === 'user' || m.role === 'assistant')
          .map((m) => ({ role: m.role as 'user' | 'assistant', content: m.content }))
      );
    } catch {
      setMessages([]);
    }
  }

  async function sendMessage() {
    if (!input.trim() || !activeSession || sending) return;
    const userText = input.trim();
    setInput('');
    setSending(true);
    const assistantIndex = messages.length + 1;
    setMessages((p) => [
      ...p,
      { role: 'user', content: userText },
      { role: 'assistant', content: '', isStreaming: true },
    ]);

    const token = typeof window !== 'undefined' ? localStorage.getItem('access_token') : '';
    try {
      const response = await fetch(
        `${API_BASE}/chat/sessions/${activeSession.id}/messages`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ content: userText }),
        }
      );
      if (!response.ok) throw new Error('Stream failed');
      const reader = response.body!.getReader();
      const decoder = new TextDecoder();
      let buffer = '';
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() ?? '';
        for (const line of lines) {
          if (!line.startsWith('data: ')) continue;
          const raw = line.slice(6);
          if (raw === '[DONE]') break;
          try {
            const event = JSON.parse(raw);
            if (event.type === 'text') {
              setMessages((p) => {
                const updated = [...p];
                updated[assistantIndex] = {
                  ...updated[assistantIndex],
                  content: (updated[assistantIndex]?.content ?? '') + event.delta,
                };
                return updated;
              });
            }
          } catch { /* skip */ }
        }
      }
    } catch {
      toast.error('Failed to get response');
    } finally {
      setMessages((p) => {
        const updated = [...p];
        if (updated[assistantIndex]) updated[assistantIndex].isStreaming = false;
        return updated;
      });
      setSending(false);
    }
  }

  return (
    <div className="flex h-full gap-0 -m-8">
      <div className="w-60 flex-shrink-0 bg-white border-r border-gray-200 flex flex-col">
        <div className="p-4 border-b border-gray-200">
          <button onClick={createSession} className="btn-primary w-full text-sm py-1.5">+ New Chat</button>
        </div>
        <div className="flex-1 overflow-y-auto">
          {sessions.map((s) => (
            <button
              key={s.id}
              onClick={() => loadSession(s)}
              className={`w-full text-left px-4 py-3 text-sm hover:bg-gray-50 border-b border-gray-100 truncate ${
                activeSession?.id === s.id ? 'bg-primary-50 text-primary-700' : 'text-gray-700'
              }`}
            >
              {s.title}
            </button>
          ))}
        </div>
      </div>
      <div className="flex-1 flex flex-col bg-gray-50">
        {activeSession ? (
          <>
            <div className="flex-1 overflow-y-auto p-6 space-y-4">
              {messages.length === 0 && (
                <div className="text-center text-gray-400 mt-12">
                  <p className="text-lg">AI Clinical Assistant</p>
                  <p className="text-sm mt-1">Ask about patient data, lab trends, or appointments</p>
                </div>
              )}
              {messages.map((msg, i) => (
                <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                  <div
                    className={`max-w-[75%] rounded-2xl px-4 py-3 text-sm ${
                      msg.role === 'user'
                        ? 'bg-primary-600 text-white'
                        : 'bg-white text-gray-800 shadow-sm border border-gray-200'
                    }`}
                  >
                    {msg.content || (msg.isStreaming ? <span className="animate-pulse">...</span> : '')}
                  </div>
                </div>
              ))}
              <div ref={bottomRef} />
            </div>
            <div className="p-4 bg-white border-t border-gray-200">
              <div className="flex gap-3">
                <input
                  className="input flex-1"
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && sendMessage()}
                  placeholder="Ask about a patient, lab results, appointments..."
                  disabled={sending}
                />
                <button onClick={sendMessage} disabled={sending || !input.trim()} className="btn-primary px-4">
                  Send
                </button>
              </div>
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center">
            <div className="text-center">
              <p className="text-gray-500 mb-4">Select a session or start a new chat</p>
              <button onClick={createSession} className="btn-primary">New Chat</button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
