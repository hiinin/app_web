-- Script para verificar a estrutura das tabelas
-- Execute este script para entender como as tabelas estão estruturadas

-- 1. Verificar estrutura da tabela professores
SELECT 
    'Estrutura da Tabela Professores' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'professores'
ORDER BY ordinal_position;

-- 2. Verificar estrutura da tabela materias
SELECT 
    'Estrutura da Tabela Matérias' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'materias'
ORDER BY ordinal_position;

-- 3. Verificar estrutura da tabela agendamento
SELECT 
    'Estrutura da Tabela Agendamento' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'agendamento'
ORDER BY ordinal_position;

-- 4. Verificar se existe alguma tabela de relacionamento entre professores e matérias
SELECT 
    'Tabelas que podem relacionar professores e matérias' as info,
    table_name
FROM information_schema.tables 
WHERE table_name LIKE '%professor%' 
   OR table_name LIKE '%materia%'
   OR table_name LIKE '%disciplina%'
   OR table_name LIKE '%associacao%'
   OR table_name LIKE '%relacao%'
ORDER BY table_name;

-- 5. Verificar chaves estrangeiras da tabela professores
SELECT 
    'Chaves Estrangeiras da Tabela Professores' as info,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name='professores';

-- 6. Verificar chaves estrangeiras da tabela materias
SELECT 
    'Chaves Estrangeiras da Tabela Matérias' as info,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name='materias';

-- 7. Verificar dados de exemplo nas tabelas
SELECT 
    'Dados de Exemplo - Professores' as info,
    id,
    nome,
    -- Mostrar todas as colunas disponíveis
    CASE WHEN column_name = 'email' THEN email ELSE NULL END as email,
    CASE WHEN column_name = 'telefone' THEN telefone ELSE NULL END as telefone
FROM professores 
LIMIT 5;

-- 8. Verificar dados de exemplo nas matérias
SELECT 
    'Dados de Exemplo - Matérias' as info,
    id,
    nome
FROM materias 
LIMIT 5;

-- 9. Verificar dados de exemplo no agendamento
SELECT 
    'Dados de Exemplo - Agendamento' as info,
    id,
    aula_periodo,
    sala_id,
    curso_id,
    materia_id,
    dia,
    tipo_agendamento
FROM agendamento 
LIMIT 5; 