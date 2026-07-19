// ============================================
// SARIS SARL - Supabase Client Module
// ============================================
import SUPABASE_CONFIG from './supabase-config.js';

class SupabaseClient {
  constructor() {
    this.url = SUPABASE_CONFIG.url;
    this.anonKey = SUPABASE_CONFIG.anonKey;
    this.headers = {
      'apikey': this.anonKey,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation'
    };
    this.user = null;
    this.session = null;
  }

  // ===== Auth =====
  async signIn(email, password) {
    const res = await fetch(`${this.url}/auth/v1/token?grant_type=password`, {
      method: 'POST',
      headers: { 'apikey': this.anonKey, 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });
    const data = await res.json();
    if (data.access_token) {
      this.session = data;
      this.user = data.user;
      this.headers['Authorization'] = `Bearer ${data.access_token}`;
      localStorage.setItem('saris_session', JSON.stringify(data));
    }
    return data;
  }

  async signOut() {
    this.session = null;
    this.user = null;
    delete this.headers['Authorization'];
    localStorage.removeItem('saris_session');
  }

  loadSession() {
    const stored = localStorage.getItem('saris_session');
    if (stored) {
      this.session = JSON.parse(stored);
      this.user = this.session?.user;
      this.headers['Authorization'] = `Bearer ${this.session?.access_token}`;
      return true;
    }
    return false;
  }

  isAuthenticated() {
    return !!this.session?.access_token;
  }

  // ===== Generic REST Helpers =====
  async select(table, query = '') {
    const url = `${this.url}/rest/v1/${table}?${query}`;
    const res = await fetch(url, { headers: this.headers });
    return res.json();
  }

  async insert(table, data) {
    const res = await fetch(`${this.url}/rest/v1/${table}`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify(data)
    });
    return res.json();
  }

  async update(table, id, data) {
    const res = await fetch(`${this.url}/rest/v1/${table}?id=eq.${id}`, {
      method: 'PATCH',
      headers: this.headers,
      body: JSON.stringify(data)
    });
    return res.json();
  }

  async delete(table, id) {
    const res = await fetch(`${this.url}/rest/v1/${table}?id=eq.${id}`, {
      method: 'DELETE',
      headers: this.headers
    });
    return res.status === 204;
  }

  // ===== Actualités =====
  async getArticles(publishedOnly = false) {
    let query = 'order=created_at.desc';
    if (publishedOnly) query += '&status=eq.published';
    return this.select('actualites', query);
  }

  async createArticle(article) {
    return this.insert('actualites', article);
  }

  async updateArticle(id, data) {
    return this.update('actualites', id, data);
  }

  async deleteArticle(id) {
    return this.delete('actualites', id);
  }

  // ===== Offres d'emploi =====
  async getJobOffers(publishedOnly = false) {
    let query = 'order=created_at.desc';
    if (publishedOnly) query += '&status=eq.published';
    return this.select('offres_emploi', query);
  }

  async createJobOffer(offer) {
    return this.insert('offres_emploi', offer);
  }

  async updateJobOffer(id, data) {
    return this.update('offres_emploi', id, data);
  }

  async deleteJobOffer(id) {
    return this.delete('offres_emploi', id);
  }

  // ===== Candidatures =====
  async getCandidatures() {
    return this.select('candidatures', 'order=created_at.desc');
  }

  async createCandidature(candidature) {
    return this.insert('candidatures', candidature);
  }

  async updateCandidature(id, data) {
    return this.update('candidatures', id, data);
  }

  async deleteCandidature(id) {
    return this.delete('candidatures', id);
  }

  // ===== Messages =====
  async getMessages() {
    return this.select('messages', 'order=created_at.desc');
  }

  async createMessage(message) {
    return this.insert('messages', message);
  }

  async updateMessage(id, data) {
    return this.update('messages', id, data);
  }

  async replyToMessage(id, reply) {
    return this.update('messages', id, {
      reply,
      status: 'replied',
      replied_at: new Date().toISOString()
    });
  }

  async deleteMessage(id) {
    return this.delete('messages', id);
  }
}

// Singleton
const supabase = new SupabaseClient();
export default supabase;
