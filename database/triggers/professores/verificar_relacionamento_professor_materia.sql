-- Script para verificar relacionamento entre professores e matérias
-- Execute este script para entender como professores e matérias se relacionam

-- 1. Verificar todas as tabelas do banco
SELECT 
    'Todas as Tabelas' as info,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- 2. Verificar se existe alguma tabela de relacionamento
SELECT 
    'Possíveis Tabelas de Relacionamento' as info,
    table_name,
    'Possível tabela de relacionamento' as descricao
FROM information_schema.tables 
WHERE table_schema = 'public'
  AND (
    table_name LIKE '%professor%materia%'
    OR table_name LIKE '%materia%professor%'
    OR table_name LIKE '%disciplina%professor%'
    OR table_name LIKE '%professor%disciplina%'
    OR table_name LIKE '%associacao%'
    OR table_name LIKE '%relacao%'
    OR table_name LIKE '%vinculo%'
    OR table_name LIKE '%atribuicao%'
    OR table_name LIKE '%alocacao%'
  )
ORDER BY table_name;

-- 3. Verificar estrutura de tabelas que podem ter relacionamento
SELECT 
    'Estrutura de Tabelas com Possível Relacionamento' as info,
    t.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name
WHERE t.table_schema = 'public'
  AND c.table_schema = 'public'
  AND (
    t.table_name LIKE '%professor%'
    OR t.table_name LIKE '%materia%'
    OR t.table_name LIKE '%disciplina%'
    OR t.table_name LIKE '%associacao%'
    OR t.table_name LIKE '%relacao%'
    OR t.table_name LIKE '%vinculo%'
    OR t.table_name LIKE '%atribuicao%'
    OR t.table_name LIKE '%alocacao%'
  )
ORDER BY t.table_name, c.ordinal_position;

-- 4. Verificar se a tabela agendamento tem coluna professor_id
SELECT 
    'Colunas da Tabela Agendamento' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'agendamento'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. Verificar se existe alguma tabela que relaciona professores com matérias
-- Procurar por tabelas que tenham tanto professor_id quanto materia_id
SELECT 
    'Tabelas com Professor_ID e Matéria_ID' as info,
    t.table_name,
    STRING_AGG(c.column_name, ', ' ORDER BY c.column_name) as colunas
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name
WHERE t.table_schema = 'public'
  AND c.table_schema = 'public'
  AND c.column_name IN ('professor_id', 'materia_id')
GROUP BY t.table_name
HAVING COUNT(*) >= 2
ORDER BY t.table_name;

-- 6. Verificar dados de exemplo em tabelas que podem ter relacionamento
SELECT 
    'Dados de Exemplo - Tabelas de Relacionamento' as info,
    table_name,
    'Primeiros 3 registros' as descricao
FROM information_schema.tables 
WHERE table_schema = 'public'
  AND (
    table_name LIKE '%professor%materia%'
    OR table_name LIKE '%materia%professor%'
    OR table_name LIKE '%associacao%'
    OR table_name LIKE '%relacao%'
    OR table_name LIKE '%vinculo%'
    OR table_name LIKE '%atribuicao%'
    OR table_name LIKE '%alocacao%'
  )
ORDER BY table_name;

-- 7. Se não encontrar tabela de relacionamento, verificar se professores têm matéria_id
SELECT 
    'Verificação de Colunas na Tabela Professores' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'professores'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 8. Verificar se matérias têm professor_id
SELECT 
    'Verificação de Colunas na Tabela Matérias' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'materias'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 9. Verificar se existe alguma view que relaciona professores e matérias
SELECT 
    'Views que podem relacionar professores e matérias' as info,
    table_name,
    'View' as tipo
FROM information_schema.views 
WHERE table_schema = 'public'
  AND (
    table_name LIKE '%professor%'
    OR table_name LIKE '%materia%'
    OR table_name LIKE '%disciplina%'
  )
ORDER BY table_name; 