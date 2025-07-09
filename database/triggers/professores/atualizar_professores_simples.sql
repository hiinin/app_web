-- Script simples para atualizar professores nos agendamentos específicos
-- Execute este script no seu banco de dados Supabase

-- 1. Atualizar agendamentos com base nas associações existentes

-- Agendamento ID 153: materia_id=53 → professor_id=33 (Professor ADM 1)
UPDATE agendamento 
SET professor_id = 33
WHERE id = 153;

-- Agendamento ID 154 e 155: materia_id=52 → professor_id=34 (Professor ADM 2)
UPDATE agendamento 
SET professor_id = 34
WHERE id IN (154, 155);

-- Agendamento ID 157: materia_id=45 → professor_id=20 (Renata Gabriela)
UPDATE agendamento 
SET professor_id = 20
WHERE id = 157;

-- 2. Para matérias que não têm associação direta, vamos criar associações e atualizar

-- Criar associação para materia_id=31 (usado nos agendamentos 147, 148)
-- Primeiro verificar se já existe
INSERT INTO professor_materias (professor_id, materia_id) 
SELECT 29, 31
WHERE NOT EXISTS (
    SELECT 1 FROM professor_materias 
    WHERE professor_id = 29 AND materia_id = 31
);

-- Atualizar agendamentos 147 e 148
UPDATE agendamento 
SET professor_id = 29
WHERE id IN (147, 148);

-- Criar associação para materia_id=30 (usado no agendamento 156)
INSERT INTO professor_materias (professor_id, materia_id) 
SELECT 29, 30
WHERE NOT EXISTS (
    SELECT 1 FROM professor_materias 
    WHERE professor_id = 29 AND materia_id = 30
);

-- Atualizar agendamento 156
UPDATE agendamento 
SET professor_id = 29
WHERE id = 156;

-- Criar associação para materia_id=46 (usado no agendamento 158)
INSERT INTO professor_materias (professor_id, materia_id) 
SELECT 20, 46
WHERE NOT EXISTS (
    SELECT 1 FROM professor_materias 
    WHERE professor_id = 20 AND materia_id = 46
);

-- Atualizar agendamento 158
UPDATE agendamento 
SET professor_id = 20
WHERE id = 158;

-- Criar associação para materia_id=28 (usado no agendamento 159)
INSERT INTO professor_materias (professor_id, materia_id) 
SELECT 29, 28
WHERE NOT EXISTS (
    SELECT 1 FROM professor_materias 
    WHERE professor_id = 29 AND materia_id = 28
);

-- Atualizar agendamento 159
UPDATE agendamento 
SET professor_id = 29
WHERE id = 159;

-- Criar associação para materia_id=21 (usado no agendamento 160)
INSERT INTO professor_materias (professor_id, materia_id) 
SELECT 25, 21
WHERE NOT EXISTS (
    SELECT 1 FROM professor_materias 
    WHERE professor_id = 25 AND materia_id = 21
);

-- Atualizar agendamento 160
UPDATE agendamento 
SET professor_id = 25
WHERE id = 160;

-- Criar associação para materia_id=15 (usado no agendamento 161)
INSERT INTO professor_materias (professor_id, materia_id) 
SELECT 25, 15
WHERE NOT EXISTS (
    SELECT 1 FROM professor_materias 
    WHERE professor_id = 25 AND materia_id = 15
);

-- Atualizar agendamento 161
UPDATE agendamento 
SET professor_id = 25
WHERE id = 161;

-- 3. Verificar se todas as atualizações foram feitas
SELECT 
    'Resultado final' as info,
    a.id,
    a.curso_id,
    c.curso,
    a.materia_id,
    m.nome as materia_nome,
    a.professor_id,
    p.nome_professor
FROM agendamento a
JOIN cursos c ON a.curso_id = c.id
JOIN materias m ON a.materia_id = m.id
LEFT JOIN professores p ON a.professor_id = p.id
WHERE a.id IN (147, 148, 153, 154, 155, 156, 157, 158, 159, 160, 161)
ORDER BY a.id; 