-- Script para atualizar professores nos agendamentos existentes
-- Baseado nas associações da tabela professor_materias

-- 1. Primeiro, vamos verificar quais agendamentos precisam ser atualizados
SELECT 
    'Agendamentos com professor_id NULL' as info,
    a.id,
    a.curso_id,
    a.materia_id,
    c.curso,
    m.nome as materia_nome,
    pm.professor_id,
    p.nome_professor
FROM agendamento a
JOIN cursos c ON a.curso_id = c.id
JOIN materias m ON a.materia_id = m.id
LEFT JOIN professor_materias pm ON a.materia_id = pm.materia_id
LEFT JOIN professores p ON pm.professor_id = p.id
WHERE a.professor_id IS NULL
ORDER BY a.id;

-- 2. Atualizar agendamentos com base nas associações professor_materias

-- Agendamento ID 147 e 148: curso_id=27, materia_id=31
-- Não há associação direta para materia_id=31, vamos usar um professor padrão ou criar associação
UPDATE agendamento 
SET professor_id = 29  -- Professor teste 1
WHERE id IN (147, 148) AND materia_id = 31;

-- Agendamento ID 153: curso_id=28, materia_id=53
-- Associação: professor_id=33 → materia_id=53
UPDATE agendamento 
SET professor_id = 33  -- Professor ADM 1
WHERE id = 153 AND materia_id = 53;

-- Agendamento ID 154 e 155: curso_id=28, materia_id=52
-- Associação: professor_id=34 → materia_id=52
UPDATE agendamento 
SET professor_id = 34  -- Professor ADM 2
WHERE id IN (154, 155) AND materia_id = 52;

-- Agendamento ID 156: curso_id=27, materia_id=30
-- Não há associação direta para materia_id=30, vamos usar um professor padrão
UPDATE agendamento 
SET professor_id = 29  -- Professor teste 1
WHERE id = 156 AND materia_id = 30;

-- Agendamento ID 157: curso_id=34, materia_id=45
-- Associação: professor_id=20 → materia_id=45
UPDATE agendamento 
SET professor_id = 20  -- Renata Gabriela Cavalini Soares da Silva
WHERE id = 157 AND materia_id = 45;

-- Agendamento ID 158: curso_id=34, materia_id=46
-- Não há associação direta para materia_id=46, vamos usar um professor padrão
UPDATE agendamento 
SET professor_id = 20  -- Renata Gabriela Cavalini Soares da Silva
WHERE id = 158 AND materia_id = 46;

-- Agendamento ID 159: curso_id=27, materia_id=28
-- Não há associação direta para materia_id=28, vamos usar um professor padrão
UPDATE agendamento 
SET professor_id = 29  -- Professor teste 1
WHERE id = 159 AND materia_id = 28;

-- Agendamento ID 160: curso_id=26, materia_id=21
-- Não há associação direta para materia_id=21, vamos usar um professor padrão
UPDATE agendamento 
SET professor_id = 25  -- Deyvid Oliveira dos Anjos
WHERE id = 160 AND materia_id = 21;

-- Agendamento ID 161: curso_id=25, materia_id=15
-- Não há associação direta para materia_id=15, vamos usar um professor padrão
UPDATE agendamento 
SET professor_id = 25  -- Deyvid Oliveira dos Anjos
WHERE id = 161 AND materia_id = 15;

-- 3. Verificar se as atualizações foram feitas corretamente
SELECT 
    'Verificação após atualização' as info,
    a.id,
    a.curso_id,
    a.materia_id,
    c.curso,
    m.nome as materia_nome,
    a.professor_id,
    p.nome_professor
FROM agendamento a
JOIN cursos c ON a.curso_id = c.id
JOIN materias m ON a.materia_id = m.id
LEFT JOIN professores p ON a.professor_id = p.id
WHERE a.id IN (147, 148, 153, 154, 155, 156, 157, 158, 159, 160, 161)
ORDER BY a.id;

-- 4. Criar associações professor_materias para matérias que não tinham
-- Isso garante que futuros agendamentos possam ser criados corretamente

-- Para materia_id=31 (usado nos agendamentos 147, 148)
INSERT INTO professor_materias (professor_id, materia_id) 
VALUES (29, 31)
ON CONFLICT (professor_id, materia_id) DO NOTHING;

-- Para materia_id=30 (usado no agendamento 156)
INSERT INTO professor_materias (professor_id, materia_id) 
VALUES (29, 30)
ON CONFLICT (professor_id, materia_id) DO NOTHING;

-- Para materia_id=46 (usado no agendamento 158)
INSERT INTO professor_materias (professor_id, materia_id) 
VALUES (20, 46)
ON CONFLICT (professor_id, materia_id) DO NOTHING;

-- Para materia_id=28 (usado no agendamento 159)
INSERT INTO professor_materias (professor_id, materia_id) 
VALUES (29, 28)
ON CONFLICT (professor_id, materia_id) DO NOTHING;

-- Para materia_id=21 (usado no agendamento 160)
INSERT INTO professor_materias (professor_id, materia_id) 
VALUES (25, 21)
ON CONFLICT (professor_id, materia_id) DO NOTHING;

-- Para materia_id=15 (usado no agendamento 161)
INSERT INTO professor_materias (professor_id, materia_id) 
VALUES (25, 15)
ON CONFLICT (professor_id, materia_id) DO NOTHING;

-- 5. Verificação final das associações criadas
SELECT 
    'Associações professor_materias criadas' as info,
    pm.professor_id,
    p.nome_professor,
    pm.materia_id,
    m.nome as materia_nome
FROM professor_materias pm
JOIN professores p ON pm.professor_id = p.id
JOIN materias m ON pm.materia_id = m.id
WHERE pm.materia_id IN (31, 30, 46, 28, 21, 15)
ORDER BY pm.materia_id; 