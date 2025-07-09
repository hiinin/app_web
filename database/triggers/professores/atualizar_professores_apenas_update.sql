-- Script simples para atualizar apenas os professores nos agendamentos
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

-- 2. Para matérias que não têm associação direta, vamos atribuir professores padrão

-- Agendamentos 147 e 148: materia_id=31 → professor_id=29 (Professor teste 1)
UPDATE agendamento 
SET professor_id = 29
WHERE id IN (147, 148);

-- Agendamento 156: materia_id=30 → professor_id=29 (Professor teste 1)
UPDATE agendamento 
SET professor_id = 29
WHERE id = 156;

-- Agendamento 158: materia_id=46 → professor_id=20 (Renata Gabriela)
UPDATE agendamento 
SET professor_id = 20
WHERE id = 158;

-- Agendamento 159: materia_id=28 → professor_id=29 (Professor teste 1)
UPDATE agendamento 
SET professor_id = 29
WHERE id = 159;

-- Agendamento 160: materia_id=21 → professor_id=25 (Deyvid Oliveira)
UPDATE agendamento 
SET professor_id = 25
WHERE id = 160;

-- Agendamento 161: materia_id=15 → professor_id=25 (Deyvid Oliveira)
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