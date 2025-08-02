-- Script de teste final para verificar inserção de agendamentos
-- Execute este script no Supabase SQL Editor

-- 1. Verificar estrutura atual da tabela agendamento
SELECT 
    'Estrutura Atual da Tabela' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'agendamento' 
ORDER BY ordinal_position;

-- 2. Verificar triggers ativos
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

-- 3. Verificar dados disponíveis para teste
SELECT 
    'Dados Disponíveis para Teste' as info,
    'Matérias' as tipo,
    COUNT(*) as quantidade,
    MIN(id) as primeiro_id,
    MAX(id) as ultimo_id
FROM materias
UNION ALL
SELECT 
    'Dados Disponíveis para Teste' as info,
    'Salas' as tipo,
    COUNT(*) as quantidade,
    MIN(id) as primeiro_id,
    MAX(id) as ultimo_id
FROM salas
UNION ALL
SELECT 
    'Dados Disponíveis para Teste' as info,
    'Cursos' as tipo,
    COUNT(*) as quantidade,
    MIN(id) as primeiro_id,
    MAX(id) as ultimo_id
FROM cursos
UNION ALL
SELECT 
    'Dados Disponíveis para Teste' as info,
    'Professores' as tipo,
    COUNT(*) as quantidade,
    MIN(id) as primeiro_id,
    MAX(id) as ultimo_id
FROM professores;

-- 4. Testar inserção direta com dados reais
DO $$
DECLARE
    materia_id_valido BIGINT;
    sala_id_valido INTEGER;
    curso_id_valido BIGINT;
    professor_id_valido BIGINT;
    agendamento_id BIGINT;
BEGIN
    -- Obter IDs válidos
    SELECT id INTO materia_id_valido FROM materias LIMIT 1;
    SELECT id INTO sala_id_valido FROM salas LIMIT 1;
    SELECT id INTO curso_id_valido FROM cursos LIMIT 1;
    SELECT id INTO professor_id_valido FROM professores LIMIT 1;
    
    RAISE NOTICE 'Testando inserção com IDs: Materia=%s, Sala=%s, Curso=%s, Professor=%s', 
        materia_id_valido, sala_id_valido, curso_id_valido, professor_id_valido;
    
    -- Tentar inserção
    INSERT INTO agendamento (
        aula_periodo,
        sala_id,
        curso_id,
        materia_id,
        professor_id,
        dia,
        periodo,
        tipo_agendamento
    ) VALUES (
        'M', -- Manhã
        sala_id_valido,
        curso_id_valido,
        materia_id_valido,
        professor_id_valido,
        CURRENT_DATE + INTERVAL '1 day',
        '2024.1',
        'A' -- Aula
    ) RETURNING id INTO agendamento_id;
    
    RAISE NOTICE '✅ Inserção bem-sucedida! ID do agendamento: %', agendamento_id;
    
    -- Verificar se foi realmente inserido
    IF EXISTS (SELECT 1 FROM agendamento WHERE id = agendamento_id) THEN
        RAISE NOTICE '✅ Agendamento confirmado na tabela';
    ELSE
        RAISE NOTICE '❌ Agendamento não encontrado na tabela';
    END IF;
    
    -- Limpar o teste
    DELETE FROM agendamento WHERE id = agendamento_id;
    RAISE NOTICE '🧹 Teste limpo - agendamento removido';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ ERRO na inserção: %', SQLERRM;
END $$;

-- 5. Verificar agendamentos existentes
SELECT 
    'Agendamentos Existentes' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN tipo_agendamento = 'A' THEN 1 END) as aulas,
    COUNT(CASE WHEN tipo_agendamento = 'E' THEN 1 END) as eventos,
    COUNT(CASE WHEN tipo_agendamento = 'M' THEN 1 END) as provas
FROM agendamento 
WHERE dia >= CURRENT_DATE - INTERVAL '7 days';

-- 6. Verificar se há conflitos de horário
SELECT 
    'Possíveis Conflitos de Horário' as info,
    sala_id,
    dia,
    aula_periodo,
    COUNT(*) as quantidade_agendamentos
FROM agendamento 
WHERE dia >= CURRENT_DATE
GROUP BY sala_id, dia, aula_periodo
HAVING COUNT(*) > 1
ORDER BY quantidade_agendamentos DESC
LIMIT 10; 