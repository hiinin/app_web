-- Script de diagnóstico para problemas com inserção de agendamentos
-- Execute este script no Supabase SQL Editor

-- 1. Verificar se a tabela agendamento existe e sua estrutura
SELECT 
    'Estrutura da Tabela Agendamento' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'agendamento' 
ORDER BY ordinal_position;

-- 2. Verificar se há dados nas tabelas relacionadas
SELECT 
    'Dados nas Tabelas Relacionadas' as info,
    'Matérias' as tabela,
    COUNT(*) as quantidade
FROM materias
UNION ALL
SELECT 
    'Dados nas Tabelas Relacionadas' as info,
    'Salas' as tabela,
    COUNT(*) as quantidade
FROM salas
UNION ALL
SELECT 
    'Dados nas Tabelas Relacionadas' as info,
    'Cursos' as tabela,
    COUNT(*) as quantidade
FROM cursos
UNION ALL
SELECT 
    'Dados nas Tabelas Relacionadas' as info,
    'Professores' as tabela,
    COUNT(*) as quantidade
FROM professores;

-- 3. Verificar triggers ativos que podem estar bloqueando inserções
SELECT 
    'Triggers Ativos' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    CASE 
        WHEN tgenabled = 'D' THEN '❌ Desabilitado'
        WHEN tgenabled = 'E' THEN '✅ Habilitado'
        ELSE '❓ Status desconhecido'
    END as status
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
ORDER BY trigger_name;

-- 4. Verificar RLS (Row Level Security) na tabela agendamento
SELECT 
    'RLS Status' as info,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'agendamento';

-- 5. Verificar políticas RLS na tabela agendamento
SELECT 
    'Políticas RLS' as info,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'agendamento';

-- 6. Testar inserção direta sem triggers
DO $$
DECLARE
    materia_id_valido BIGINT;
    sala_id_valido INTEGER;
    curso_id_valido INTEGER;
    professor_id_valido INTEGER;
    agendamento_id INTEGER;
    resultado TEXT;
BEGIN
    -- Pegar IDs válidos
    SELECT MIN(id) INTO materia_id_valido FROM materias;
    SELECT MIN(id) INTO sala_id_valido FROM salas;
    SELECT MIN(id) INTO curso_id_valido FROM cursos;
    SELECT MIN(id) INTO professor_id_valido FROM professores;
    
    -- Verificar se temos dados válidos
    IF materia_id_valido IS NULL OR sala_id_valido IS NULL OR curso_id_valido IS NULL OR professor_id_valido IS NULL THEN
        RAISE NOTICE '❌ Dados insuficientes para teste';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Testando inserção com IDs: materia=%s, sala=%s, curso=%s, professor=%s', 
        materia_id_valido, sala_id_valido, curso_id_valido, professor_id_valido;
    
    -- Desabilitar todos os triggers temporariamente
    ALTER TABLE agendamento DISABLE TRIGGER ALL;
    
    -- Testar inserção válida
    BEGIN
        INSERT INTO agendamento (
            sala_id, curso_id, materia_id, professor_id,
            dia, aula_periodo, periodo, tipo_agendamento
        ) VALUES (
            sala_id_valido, curso_id_valido, materia_id_valido, professor_id_valido,
            (CURRENT_DATE + INTERVAL '4 days')::date, 'Primeira Aula', 1, 'A'
        ) RETURNING id INTO agendamento_id;
        
        RAISE NOTICE '✅ Inserção válida funcionou! ID criado: %s', agendamento_id;
        
        -- Verificar se foi realmente criado
        IF EXISTS (SELECT 1 FROM agendamento WHERE id = agendamento_id) THEN
            RAISE NOTICE '✅ Agendamento confirmado no banco de dados';
        ELSE
            RAISE NOTICE '❌ Agendamento não encontrado no banco de dados';
        END IF;
        
        -- Limpar teste
        DELETE FROM agendamento WHERE id = agendamento_id;
        RAISE NOTICE '🧹 Teste limpo com sucesso';
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ Inserção válida falhou: %s', SQLERRM;
    END;
    
    -- Reabilitar triggers
    ALTER TABLE agendamento ENABLE TRIGGER ALL;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro no teste: %s', SQLERRM;
        -- Garantir que os triggers sejam reabilitados mesmo em caso de erro
        ALTER TABLE agendamento ENABLE TRIGGER ALL;
END $$;

-- 7. Verificar se há agendamentos existentes
SELECT 
    'Agendamentos Existentes' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN tipo_agendamento = 'A' THEN 1 END) as aulas,
    COUNT(CASE WHEN tipo_agendamento = 'E' THEN 1 END) as eventos,
    COUNT(CASE WHEN tipo_agendamento = 'M' THEN 1 END) as provas
FROM agendamento 
WHERE dia >= CURRENT_DATE;

-- 8. Verificar permissões do usuário anônimo
SELECT 
    'Permissões do Usuário Anônimo' as info,
    grantee,
    table_name,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'agendamento' 
  AND grantee = 'anon';

-- 9. Verificar se há constraints que podem estar impedindo inserções
SELECT 
    'Constraints da Tabela' as info,
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'agendamento';

-- 10. Verificar foreign keys
SELECT 
    'Foreign Keys' as info,
    tc.constraint_name,
    tc.table_name,
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
  AND tc.table_name = 'agendamento'; 