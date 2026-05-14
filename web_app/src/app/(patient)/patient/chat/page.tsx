'use client';

import { useEffect, useState, useRef, useCallback } from 'react';
import { chatApi, getAuthHeader } from '@/lib/api-client';
import { ChatSession, ChatMessage } from '@/types';

interface StreamMsg { role: 'user' | 'assistant'; content: string; }

export default function PatientChat() {
  const [sessions, setSessions] = useState<ChatSession[]>([]);
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [messages, setMessages] = useState<StreamMsg[]>([]);
  const [input, setInput] = useState('');
  const [streaming, setStreaming] = useState(false);
  const [bootstrapLoading, setBootstrapLoading] = useState(true);
  const scrollRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => { bootstrap(); }, []);

  const scrollToBottom = useCallback(() => {
    setTimeout(() => { scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: 'smooth' }); }, 50);
  }, []);

  async function bootstrap() {
    try {
      const res = await chatApi.listSessions();
      const s = res.data as ChatSession[];
      setSessions(s);
      if (s.length > 0) await loadSession(s[0].id, false);
    } catch { /* ignore */ }
    setBootstrapLoading(false);
  }

  async function refreshSessions() {
    try {
      const res = await chatApi.listSessions();
      setSessions(res.data);
    } catch { /* */ }
  }

  async function loadSession(sid: string, refresh = true) {
    try {
      const res = await chatApi.getSession(sid);
      const data = res.data;
      const msgs = (data.messages || []).map((m: ChatMessage) => ({ role: m.role as 'user' | 'assistant', content: m.content }));
      setSessionId(sid);
      setMessages(msgs);
      if (refresh) await refreshSessions();
      scrollToBottom();
    } catch { /* ignore */ }
  }

  async function ensureSession(firstMsg: string): Promise<string> {
    if (sessionId) return sessionId;
    const title = firstMsg.length > 40 ? firstMsg.slice(0, 40) + '…' : firstMsg;
    const res = await chatApi.createSession(title);
    const newId = res.data.id;
    setSessionId(newId);
    await refreshSessions();
    return newId;
  }

  async function send() {
    const text = input.trim();
    if (!text || streaming) return;

    setMessages((m) => [...m, { role: 'user', content: text }, { role: 'assistant', content: '' }]);
    setInput('');
    setStreaming(true);
    scrollToBottom();

    try {
      const sid = await ensureSession(text);
      const url = chatApi.messagesUrl(sid);
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', ...getAuthHeader() },
        body: JSON.stringify({ content: text }),
      });

      if (!res.ok || !res.body) throw new Error('Stream failed');

      const reader = res.body.getReader();
      const decoder = new TextDecoder();
      let buffer = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });

        while (buffer.includes('\n\n')) {
          const idx = buffer.indexOf('\n\n');
          const event = buffer.slice(0, idx);
          buffer = buffer.slice(idx + 2);

          for (const line of event.split('\n')) {
            if (!line.startsWith('data: ')) continue;
            try {
              const data = JSON.parse(line.slice(6));
              if (data.type === 'text' && data.content) {
                setMessages((prev) => {
                  const copy = [...prev];
                  copy[copy.length - 1] = { ...copy[copy.length - 1], content: copy[copy.length - 1].content + data.content };
                  return copy;
                });
                scrollToBottom();
              }
            } catch { /* skip */ }
          }
        }
      }
    } catch {
      setMessages((prev) => {
        const copy = [...prev];
        copy[copy.length - 1] = { ...copy[copy.length - 1], content: 'Something went wrong. Please try again.' };
        return copy;
      });
    }
    setStreaming(false);
  }

  function startNewChat() {
    if (streaming) return;
    setMessages([]);
    setSessionId(null);
  }

  if (bootstrapLoading) {
    return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  return (
    <div className="flex h-[calc(100vh-4rem)] w-full gap-4">
      {/* Sidebar */}
      <div className="w-64 flex-shrink-0 bg-white dark:bg-slate-900 rounded-2xl border border-gray-100 dark:border-slate-800 shadow-sm flex flex-col overflow-hidden">
        <div className="p-3 border-b border-gray-100 dark:border-slate-800 flex items-center justify-between">
          <h2 className="font-semibold text-sm text-gray-900 dark:text-gray-100">Conversations</h2>
          <button onClick={startNewChat} className="text-primary-600 hover:bg-primary-50 dark:bg-primary-900/30 p-1.5 rounded-lg transition-colors" title="New">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
          </button>
        </div>
        <div className="flex-1 overflow-y-auto p-2 space-y-1">
          {sessions.length === 0 ? (
            <p className="text-xs text-gray-400 dark:text-gray-500 text-center py-4">No conversations yet</p>
          ) : sessions.map((s) => (
            <button
              key={s.id}
              onClick={() => loadSession(s.id)}
              className={`w-full text-left px-3 py-2 rounded-lg text-sm transition-colors ${
                s.id === sessionId ? 'bg-primary-50 dark:bg-primary-900/30 text-primary-700 font-medium' : 'text-gray-600 dark:text-gray-400 dark:text-gray-500 hover:bg-gray-50 dark:bg-slate-950'
              }`}
            >
              <p className="truncate">{s.title || 'New Chat'}</p>
            </button>
          ))}
        </div>
      </div>

      {/* Chat area */}
      <div className="flex-1 flex flex-col bg-white dark:bg-slate-900 rounded-2xl border border-gray-100 dark:border-slate-800 shadow-sm overflow-hidden">
        {/* Messages */}
        <div ref={scrollRef} className="flex-1 overflow-y-auto p-4 space-y-3">
          {messages.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-full text-center">
              <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-primary-500 to-primary-700 flex items-center justify-center mb-4">
                <svg className="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" /></svg>
              </div>
              <h3 className="font-semibold text-gray-900 dark:text-gray-100 text-lg">AI Health Assistant</h3>
              <p className="text-sm text-gray-500 dark:text-gray-400 dark:text-gray-500 mt-1 max-w-xs">
                {sessions.length === 0
                  ? 'Start a new conversation about your health, symptoms, or medical reports.'
                  : 'Select a conversation or start a new one.'}
              </p>
            </div>
          ) : (
            messages.map((m, i) => (
              <div key={i} className={`flex ${m.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                <div className={`max-w-[75%] rounded-2xl px-4 py-3 text-sm leading-relaxed ${
                  m.role === 'user'
                    ? 'bg-primary-600 text-white rounded-br-md'
                    : 'bg-gray-100 dark:bg-slate-800 text-gray-900 dark:text-gray-100 rounded-bl-md'
                }`}>
                  {m.content || (
                    <span className="flex items-center gap-2 text-gray-400 dark:text-gray-500">
                      <div className="animate-spin rounded-full h-3 w-3 border-b-2 border-gray-400" />
                      Thinking…
                    </span>
                  )}
                </div>
              </div>
            ))
          )}
        </div>

        {/* Streaming indicator */}
        {streaming && (
          <div className="h-0.5 bg-primary-100">
            <div className="h-full bg-primary-600 animate-pulse" style={{ width: '100%' }} />
          </div>
        )}

        {/* Input */}
        <div className="border-t border-gray-100 dark:border-slate-800 p-3 flex items-center gap-2">
          <input
            ref={inputRef}
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); } }}
            placeholder="Ask about your health…"
            disabled={streaming}
            className="flex-1 bg-gray-50 dark:bg-slate-950 border-0 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
          />
          <button
            onClick={send}
            disabled={!input.trim() || streaming}
            className="w-10 h-10 rounded-full bg-primary-600 text-white flex items-center justify-center hover:bg-primary-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors flex-shrink-0"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M6 12L3.269 3.126A59.768 59.768 0 0121.485 12 59.77 59.77 0 013.27 20.876L5.999 12zm0 0h7.5" /></svg>
          </button>
        </div>
      </div>
    </div>
  );
}
