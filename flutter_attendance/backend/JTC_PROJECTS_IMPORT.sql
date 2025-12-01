-- ============================================
-- JTC Project Details Import
-- Import projects and staff from JTC Project Details spreadsheet
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. CREATE JTC PROJECTS
-- ============================================
INSERT INTO projects (id, name, location, start_date, end_date, description, budget, created_at)
VALUES 
  (gen_random_uuid(), 'JTC BULIM PHASE 2 MAIN INFRASTRUCTURE WORKS-Part-C', 'Bulim', '2024-09-01', '2027-12-31', 'Project commenced on 1st Sep-2024', NULL, NOW()),
  (gen_random_uuid(), 'Construction Quality Department_CQD', 'Various', '2024-01-01', '2027-12-31', 'Construction Quality Department', NULL, NOW()),
  (gen_random_uuid(), 'GP8 Demo', 'Various', NULL, NULL, 'GP8 Demo Project', NULL, NOW()),
  (gen_random_uuid(), 'GP9 Demo', 'Various', NULL, NULL, 'GP9 Demo Project', NULL, NOW()),
  (gen_random_uuid(), 'GP10_Demo', 'Various', NULL, NULL, 'GP10 Demo Project', NULL, NOW()),
  (gen_random_uuid(), 'R&R Grp 3 - AMK Techlink, AVIE, BBIPA, SMIE, YIPA - PART B', 'Ang Mo Kio', NULL, NULL, 'R&R Group 3 Projects', NULL, NOW()),
  (gen_random_uuid(), 'Fire Safety Works (R&R) to Existing Fusionopolis', 'Fusionopolis', NULL, NULL, 'Fire Safety Works Renovation', NULL, NOW()),
  (gen_random_uuid(), 'Jurong Eco-Garden (JEG) Rejuvenation Work_Part C', 'Jurong', NULL, NULL, 'Jurong Eco-Garden Rejuvenation', NULL, NOW()),
  (gen_random_uuid(), 'New Erection of 4-Storey 66KV Substation(LNSS)_Part B', 'Various', NULL, NULL, '4-Storey 66KV Substation', NULL, NOW()),
  (gen_random_uuid(), 'Proposed Facade Rapair and Rectification (R&R) to Block 1 to 6 of Biopolis - PART B', 'Biopolis', NULL, NULL, 'Facade Repair and Rectification', NULL, NOW()),
  (gen_random_uuid(), 'EW for Common area at Rochester park', 'Rochester Park', NULL, NULL, 'Common area works', NULL, NOW()),
  (gen_random_uuid(), 'A&A at 28 ARC', '28 ARC', NULL, NULL, 'Additions and Alterations', NULL, NOW()),
  (gen_random_uuid(), 'Clean Tech Linkway', 'Clean Tech', NULL, NULL, 'Linkway construction', NULL, NOW()),
  (gen_random_uuid(), 'JTC nano Space', 'Various', NULL, NULL, 'Nano Space project', NULL, NOW()),
  (gen_random_uuid(), 'JTC Space at Ang Mo Kio', 'Ang Mo Kio', NULL, NULL, 'JTC Space project', NULL, NOW()),
  (gen_random_uuid(), 'Interior Fit-Out Works at Level 21 at the JTC Summit office Building', 'JTC Summit', NULL, NULL, 'Interior Fit-Out Works', NULL, NOW()),
  (gen_random_uuid(), 'Bahar Tunnel works', 'Bahar', NULL, NULL, 'Tunnel construction works', NULL, NOW()),
  (gen_random_uuid(), 'Re-sealant work at Treasury house', 'Treasury House', NULL, NULL, 'Re-sealant work', NULL, NOW()),
  (gen_random_uuid(), 'Re-sealant work at Revenue house', 'Revenue House', NULL, NULL, 'Re-sealant work', NULL, NOW()),
  (gen_random_uuid(), 'WCP Ext Tnfra', 'Various', NULL, NULL, 'WCP Extension Infrastructure', NULL, NOW()),
  (gen_random_uuid(), 'Defu Industrial city', 'Defu', NULL, NULL, 'Industrial city project', NULL, NOW()),
  (gen_random_uuid(), 'Helios facade replacement', 'Helios', NULL, NULL, 'Facade replacement', NULL, NOW()),
  (gen_random_uuid(), 'Temporary Carpark', 'Various', NULL, NULL, 'Temporary carpark construction', NULL, NOW()),
  (gen_random_uuid(), 'A&A at Penjuru', 'Penjuru', NULL, NULL, 'Additions and Alterations', NULL, NOW()),
  (gen_random_uuid(), 'Infra works at Clean tech', 'Clean Tech', NULL, NULL, 'Infrastructure works', NULL, NOW())
ON CONFLICT DO NOTHING;

-- ============================================
-- 2. CREATE JTC STAFF WITH ROLES
-- ============================================
-- Role format: [Title]([Specialization])
-- Titles: SRE (Senior Resident Engineer), RE (Resident Engineer), RTO (Resident Technical Officer)
-- Specializations: C&S (Civil & Structural), M&E (Mechanical & Electrical), Archi (Architectural)
-- Senior Resident Engineers have both C&S and M&E

-- JTC BULIM PHASE 2 - Staff
DO $$
DECLARE
  bulim_project_id UUID;
BEGIN
  SELECT id INTO bulim_project_id FROM projects WHERE name = 'JTC BULIM PHASE 2 MAIN INFRASTRUCTURE WORKS-Part-C' LIMIT 1;
  
  INSERT INTO employees (id, name, email, phone, role, project_id, created_at)
  VALUES 
    (gen_random_uuid(), 'Ong Kian Hong (Alvin Ong)', 'alvin.ong@jtc.com', NULL, 'SRE(C&S)', bulim_project_id, NOW()),
    (gen_random_uuid(), 'Damodharan Ramesh', 'damodharan.ramesh@jtc.com', NULL, 'RTO(C&S)', bulim_project_id, NOW()),
    (gen_random_uuid(), 'Thirunavukkarasu Yokesh', 'thirunavukkarasu.yokesh@jtc.com', NULL, 'RTO(C&S)', bulim_project_id, NOW()),
    (gen_random_uuid(), 'Jay Vecino Manlupig', 'jay.manlupig@jtc.com', NULL, 'RTO(C&S)', bulim_project_id, NOW()),
    (gen_random_uuid(), 'Chakkarapani Samidurai', 'chakkarapani.samidurai@jtc.com', NULL, 'RTO(C&S)', bulim_project_id, NOW()),
    (gen_random_uuid(), 'Krishnamoorthy Parimelazhagan', 'krishnamoorthy.parimelazhagan@jtc.com', NULL, 'RTO(C&S)', bulim_project_id, NOW())
  ON CONFLICT (email) DO NOTHING;
END $$;

-- CQD - Staff
DO $$
DECLARE
  cqd_project_id UUID;
BEGIN
  SELECT id INTO cqd_project_id FROM projects WHERE name = 'Construction Quality Department_CQD' LIMIT 1;
  
  INSERT INTO employees (id, name, email, phone, role, project_id, created_at)
  VALUES 
    (gen_random_uuid(), 'Mokhairulamri Bin Mohamad', 'mokhairulamri.mohamad@jtc.com', NULL, 'RE(C&S)', cqd_project_id, NOW()),
    (gen_random_uuid(), 'Weerakkodi Arachchige Chanaka Prabhath', 'chanaka.prabhath@jtc.com', NULL, 'RE(C&S/M&E)', cqd_project_id, NOW()),
    (gen_random_uuid(), 'Yeo Pee Hock, Moses', 'moses.yeo@jtc.com', NULL, 'RA', cqd_project_id, NOW()),
    (gen_random_uuid(), 'Aung Zaw Moe', 'aung.zawmoe@jtc.com', NULL, 'RE(M&E)', cqd_project_id, NOW())
  ON CONFLICT (email) DO NOTHING;
END $$;

-- GP8 Demo - Staff
DO $$
DECLARE
  gp8_project_id UUID;
BEGIN
  SELECT id INTO gp8_project_id FROM projects WHERE name = 'GP8 Demo' LIMIT 1;
  
  INSERT INTO employees (id, name, email, phone, role, project_id, created_at)
  VALUES 
    (gen_random_uuid(), 'Naganathan Samibalan', 'naganathan.samibalan@jtc.com', NULL, 'RTO(C&S)', gp8_project_id, NOW()),
    (gen_random_uuid(), 'Kaliappan Ayyanar', 'kaliappan.ayyanar@jtc.com', NULL, 'RTO(C&S)', gp8_project_id, NOW()),
    (gen_random_uuid(), 'Dhanasekaran T', 'dhanasekaran.t@jtc.com', NULL, 'RTO(C&S)', gp8_project_id, NOW()),
    (gen_random_uuid(), 'Arokiya Doss Balaji', 'arokiya.balaji@jtc.com', NULL, 'Stand-in RTO(C&S)', gp8_project_id, NOW())
  ON CONFLICT (email) DO NOTHING;
END $$;

-- GP9 Demo - Staff
DO $$
DECLARE
  gp9_project_id UUID;
BEGIN
  SELECT id INTO gp9_project_id FROM projects WHERE name = 'GP9 Demo' LIMIT 1;
  
  INSERT INTO employees (id, name, email, phone, role, project_id, created_at)
  VALUES 
    (gen_random_uuid(), 'Siva Selvamuthukumaran', 'siva.selvamuthukumaran@jtc.com', NULL, 'RTO(C&S)', gp9_project_id, NOW()),
    (gen_random_uuid(), 'Sakkarai Veerappan Sethupathi', 'sakkarai.sethupathi@jtc.com', NULL, 'RTO(C&S)', gp9_project_id, NOW()),
    (gen_random_uuid(), 'Chellaiyan Raja', 'chellaiyan.raja@jtc.com', NULL, 'RTO(C&S)', gp9_project_id, NOW()),
    (gen_random_uuid(), 'Jothi Karthick', 'jothi.karthick@jtc.com', NULL, 'RTO(C&S)', gp9_project_id, NOW()),
    (gen_random_uuid(), 'Saminathan Thivakar', 'saminathan.thivakar@jtc.com', NULL, 'RTO(C&S)', gp9_project_id, NOW()),
    (gen_random_uuid(), 'Kavi Pon Muruga Pandian', 'kavi.pandian@jtc.com', NULL, 'RTO(C&S)', gp9_project_id, NOW()),
    (gen_random_uuid(), 'Kalaimani Silambarasan', 'kalaimani.silambarasan@jtc.com', NULL, 'RTO(C&S)', gp9_project_id, NOW())
  ON CONFLICT (email) DO NOTHING;
END $$;

-- GP10 Demo - Staff
DO $$
DECLARE
  gp10_project_id UUID;
BEGIN
  SELECT id INTO gp10_project_id FROM projects WHERE name = 'GP10_Demo' LIMIT 1;
  
  INSERT INTO employees (id, name, email, phone, role, project_id, created_at)
  VALUES 
    (gen_random_uuid(), 'Govindarajan Murugan', 'govindarajan.murugan@jtc.com', NULL, 'RTO(C&S)', gp10_project_id, NOW()),
    (gen_random_uuid(), 'Parasuraman Rajesh', 'parasuraman.rajesh@jtc.com', NULL, 'RTO(C&S)', gp10_project_id, NOW()),
    (gen_random_uuid(), 'Sarkar Ibrahim Khalil', 'sarkar.khalil@jtc.com', NULL, 'Stand-in RTO(C&S)', gp10_project_id, NOW()),
    (gen_random_uuid(), 'Ganesan Dhanabalan', 'ganesan.dhanabalan@jtc.com', NULL, 'Stand-in RTO(C&S)', gp10_project_id, NOW())
  ON CONFLICT (email) DO NOTHING;
END $$;

-- Additional staff from other projects
DO $$
DECLARE
  rrr_project_id UUID;
  fusionopolis_project_id UUID;
  jeg_project_id UUID;
  lnss_project_id UUID;
  biopolis_project_id UUID;
  rochester_project_id UUID;
  arc28_project_id UUID;
  cleantech_linkway_id UUID;
  nano_space_id UUID;
  amk_space_id UUID;
  summit_id UUID;
  bahar_id UUID;
  treasury_id UUID;
  revenue_id UUID;
BEGIN
  SELECT id INTO rrr_project_id FROM projects WHERE name LIKE 'R&R Grp 3%' LIMIT 1;
  SELECT id INTO fusionopolis_project_id FROM projects WHERE name LIKE 'Fire Safety Works%' LIMIT 1;
  SELECT id INTO jeg_project_id FROM projects WHERE name LIKE 'Jurong Eco-Garden%' LIMIT 1;
  SELECT id INTO lnss_project_id FROM projects WHERE name LIKE 'New Erection of 4-Storey%' LIMIT 1;
  SELECT id INTO biopolis_project_id FROM projects WHERE name LIKE 'Proposed Facade%' LIMIT 1;
  SELECT id INTO rochester_project_id FROM projects WHERE name LIKE 'EW for Common area%' LIMIT 1;
  SELECT id INTO arc28_project_id FROM projects WHERE name LIKE 'A&A at 28 ARC' LIMIT 1;
  SELECT id INTO cleantech_linkway_id FROM projects WHERE name = 'Clean Tech Linkway' LIMIT 1;
  SELECT id INTO nano_space_id FROM projects WHERE name = 'JTC nano Space' LIMIT 1;
  SELECT id INTO amk_space_id FROM projects WHERE name = 'JTC Space at Ang Mo Kio' LIMIT 1;
  SELECT id INTO summit_id FROM projects WHERE name LIKE 'Interior Fit-Out%' LIMIT 1;
  SELECT id INTO bahar_id FROM projects WHERE name = 'Bahar Tunnel works' LIMIT 1;
  SELECT id INTO treasury_id FROM projects WHERE name LIKE 'Re-sealant work at Treasury%' LIMIT 1;
  SELECT id INTO revenue_id FROM projects WHERE name LIKE 'Re-sealant work at Revenue%' LIMIT 1;
  
  -- R&R Grp 3 Staff
  INSERT INTO employees (id, name, email, phone, role, project_id, created_at)
  VALUES 
    (gen_random_uuid(), 'Muthukkannu Murugan', 'muthukkannu.murugan@jtc.com', NULL, 'RTO(C&S)', rrr_project_id, NOW()),
    (gen_random_uuid(), 'Mathivanan Karthick', 'mathivanan.karthick@jtc.com', NULL, 'RTO(C&S)', rrr_project_id, NOW()),
    (gen_random_uuid(), 'Anbazhagan Lenin', 'anbazhagan.lenin@jtc.com', NULL, 'RTO(C&S)', rrr_project_id, NOW()),
    (gen_random_uuid(), 'Venkatesan Selvakumar', 'venkatesan.selvakumar@jtc.com', NULL, 'RTO(C&S)', rrr_project_id, NOW()),
    (gen_random_uuid(), 'Kyaw Hlaing Soe', 'kyaw.hlaingsoe@jtc.com', NULL, 'RTO(C&S)', rrr_project_id, NOW()),
    (gen_random_uuid(), 'Uthirapathi Sam David', 'uthirapathi.david@jtc.com', NULL, 'RTO(C&S)', rrr_project_id, NOW()),
    (gen_random_uuid(), 'Vijayakumar Parasanth', 'vijayakumar.parasanth@jtc.com', NULL, 'RTO(C&S)', rrr_project_id, NOW()),
    (gen_random_uuid(), 'Nallathambi Elanchezhyan', 'nallathambi.elanchezhyan@jtc.com', NULL, 'RTO(C&S)', rrr_project_id, NOW()),
    (gen_random_uuid(), 'Balakrishnan Srinivasan', 'balakrishnan.srinivasan@jtc.com', NULL, 'RTO(C&S)', rrr_project_id, NOW()),
    (gen_random_uuid(), 'Ramalingam Gopu', 'ramalingam.gopu@jtc.com', NULL, 'RTO(M&E)', rrr_project_id, NOW()),
    (gen_random_uuid(), 'Mohamed Shabaruddin', 'mohamed.shabaruddin@jtc.com', NULL, 'RTO(Archi)', rrr_project_id, NOW()),
    (gen_random_uuid(), 'Chen Ching Sheng', 'chen.chingsheng@jtc.com', NULL, 'RE(C&S)', rrr_project_id, NOW())
  ON CONFLICT (email) DO NOTHING;
  
  -- Additional project staff
  INSERT INTO employees (id, name, email, phone, role, project_id, created_at)
  VALUES 
    (gen_random_uuid(), 'Balasingam Selvakumar', 'balasingam.selvakumar@jtc.com', NULL, 'Stand-in RTO(C&S)', revenue_id, NOW())
  ON CONFLICT (email) DO NOTHING;
END $$;

-- ============================================
-- 3. CREATE USER ACCOUNTS FOR STAFF
-- ============================================
-- Create users for all JTC staff (password: worker123)
INSERT INTO users (id, email, password_hash, created_at)
SELECT 
  gen_random_uuid(),
  email,
  '$2b$12$8P23VIwZRrwTUZL5shUEE.MbToVquXB0HdmFZctDWYHKDfJXUFCXu', -- password: worker123
  NOW()
FROM employees
WHERE email IS NOT NULL 
  AND email LIKE '%@jtc.com'
  AND email NOT IN (SELECT email FROM users)
ON CONFLICT (email) DO NOTHING;

-- ============================================
-- SUMMARY
-- ============================================
SELECT '✅ JTC Projects and Staff imported successfully!' as message;
SELECT COUNT(*) as total_projects FROM projects WHERE name LIKE 'JTC%' OR name LIKE '%Demo%' OR name LIKE 'R&R%';
SELECT COUNT(*) as total_staff FROM employees WHERE email LIKE '%@jtc.com';
SELECT COUNT(*) as total_user_accounts FROM users WHERE email LIKE '%@jtc.com';

SELECT '📊 Projects Created:' as info;
SELECT name, location FROM projects WHERE name LIKE 'JTC%' OR name LIKE '%Demo%' OR name LIKE 'R&R%' ORDER BY name LIMIT 10;

SELECT '👥 Staff by Role:' as info;
SELECT role, COUNT(*) as count 
FROM employees 
WHERE email LIKE '%@jtc.com'
GROUP BY role
ORDER BY count DESC;

