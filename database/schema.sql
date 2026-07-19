-- ============================================
-- SARIS SARL - Supabase Database Schema
-- ============================================

-- 1. TABLE: actualites (News/Articles)
CREATE TABLE IF NOT EXISTS actualites (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  excerpt TEXT NOT NULL,
  content TEXT,
  category TEXT DEFAULT 'Général',
  image_url TEXT,
  status TEXT DEFAULT 'draft' CHECK (status IN ('published', 'draft')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. TABLE: offres_emploi (Job Offers)
CREATE TABLE IF NOT EXISTS offres_emploi (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  department TEXT NOT NULL,
  location TEXT NOT NULL,
  contract_type TEXT DEFAULT 'CDI' CHECK (contract_type IN ('CDI', 'CDD', 'Stage', 'Intérim')),
  description TEXT,
  requirements TEXT,
  status TEXT DEFAULT 'draft' CHECK (status IN ('published', 'draft')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. TABLE: candidatures (Job Applications)
CREATE TABLE IF NOT EXISTS candidatures (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nom TEXT NOT NULL,
  prenom TEXT NOT NULL,
  email TEXT NOT NULL,
  telephone TEXT,
  poste_souhaite TEXT NOT NULL,
  cv_url TEXT,
  lettre_url TEXT,
  message TEXT,
  status TEXT DEFAULT 'new' CHECK (status IN ('new', 'reviewed', 'accepted', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. TABLE: messages (Contact Form Messages)
CREATE TABLE IF NOT EXISTS messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nom TEXT NOT NULL,
  prenom TEXT NOT NULL,
  email TEXT NOT NULL,
  telephone TEXT,
  societe TEXT,
  sujet TEXT NOT NULL,
  message TEXT NOT NULL,
  status TEXT DEFAULT 'new' CHECK (status IN ('new', 'read', 'replied', 'archived')),
  reply TEXT,
  replied_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. TABLE: personnel (Staff Accounts)
CREATE TABLE IF NOT EXISTS personnel (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  nom TEXT NOT NULL,
  prenom TEXT NOT NULL,
  role TEXT DEFAULT 'user' CHECK (role IN ('admin', 'editor', 'user')),
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. TABLE: offres_emploi (Job Offers) - RLS Policies

-- Enable Row Level Security
ALTER TABLE actualites ENABLE ROW LEVEL SECURITY;
ALTER TABLE offres_emploi ENABLE ROW LEVEL SECURITY;
ALTER TABLE candidatures ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE personnel ENABLE ROW LEVEL SECURITY;

-- Policies: Public read access for published content
CREATE POLICY "actualites_public_read" ON actualites
  FOR SELECT USING (status = 'published');

CREATE POLICY "offres_emploi_public_read" ON offres_emploi
  FOR SELECT USING (status = 'published');

-- Policies: Authenticated full access (admin)
CREATE POLICY "actualites_admin_all" ON actualites
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "offres_emploi_admin_all" ON offres_emploi
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "candidatures_admin_all" ON candidatures
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "messages_admin_all" ON messages
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "personnel_admin_all" ON personnel
  FOR ALL USING (auth.role() = 'authenticated');

-- Policies: Anyone can insert (for contact form and applications)
CREATE POLICY "candidatures_insert" ON candidatures
  FOR INSERT WITH CHECK (true);

CREATE POLICY "messages_insert" ON messages
  FOR INSERT WITH CHECK (true);

-- Indexes for performance
CREATE INDEX idx_actualites_status ON actualites(status);
CREATE INDEX idx_actualites_created ON actualites(created_at DESC);
CREATE INDEX idx_offres_status ON offres_emploi(status);
CREATE INDEX idx_candidatures_status ON candidatures(status);
CREATE INDEX idx_messages_status ON messages(status);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER trigger_actualites_updated
  BEFORE UPDATE ON actualites
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_offres_updated
  BEFORE UPDATE ON offres_emploi
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Insert default admin user (password: admin123 - CHANGE THIS!)
INSERT INTO personnel (email, password_hash, nom, prenom, role)
VALUES ('admin@sarisarl.com', '$2a$10$placeholder_hash', 'Admin', 'SARIS', 'admin')
ON CONFLICT (email) DO NOTHING;

-- Insert default articles
INSERT INTO actualites (title, excerpt, category, image_url, status, created_at)
VALUES
  ('SARIS SARL lance un nouveau projet minier au Katanga', 'Notre société a été sélectionnée pour accompagner un grand groupe minier dans la gestion logistique de ses opérations.', 'BTP', 'assets/images/logistique-entrepot.png', 'published', '2026-06-15'),
  ('Signature d''un partenariat stratégique avec un opérateur minier', 'Ce partenariat renforce notre position dans le secteur minier et nous permet d''étendre notre gamme de services.', 'Partenariat', 'assets/images/logistique-bureau.png', 'published', '2026-05-28'),
  ('Programme de formation : Renforcement des compétences techniques', 'SARIS SARL investit dans la formation de ses équipes pour garantir l''excellence opérationnelle sur tous ses chantiers.', 'RH', 'assets/images/rh-equipe.png', 'published', '2026-05-10')
ON CONFLICT DO NOTHING;
