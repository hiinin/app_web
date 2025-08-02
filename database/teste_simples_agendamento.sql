-- Script de teste simples para inserção de agendamento
-- Execute este script no Supabase SQL Editor

-- 1. Limpar agendamentos de teste anteriores
DELETE FROM agendamento WHERE dia >= CURRENT_DATE AND tipo_agendamento = 'A';

-- 2. Verificar dados disponíveis
SELECT 
    'Dados para Teste' as info,
    'Matérias' as tipo,
    COUNT(*) as quantidade
FROM materias
UNION ALL
SELECT 
    'Dados para Teste' as info,
    'Salas' as tipo,
    COUNT(*) as quantidade
FROM salas
UNION ALL
SELECT 
    'Dados para Teste' as info,
    'Cursos' as tipo,
    COUNT(*) as quantidade
FROM cursos
UNION ALL
SELECT 
    'Dados para Teste' as info,
    'Professores' as tipo,
    COUNT(*) as quantidade
FROM professores;

-- 3. Teste de inserção simples
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
    
    -- Tentar inserção simples
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
        
        -- Mostrar detalhes do agendamento inserido
        SELECT 
            'Agendamento Inserido' as info,
            id,
            aula_periodo,
            sala_id,
            curso_id,
            materia_id,
            professor_id,
            dia,
            periodo,
            tipo_agendamento
        FROM agendamento 
        WHERE id = agendamento_id;
    ELSE
        RAISE NOTICE '❌ Agendamento não encontrado na tabela';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ ERRO na inserção: %', SQLERRM;
END $$;

-- 4. Verificar agendamentos criados
SELECT 
    'Agendamentos Criados' as info,
    COUNT(*) as total
FROM agendamento 
WHERE dia >= CURRENT_DATE AND tipo_agendamento = 'A';

-- 5. Mostrar detalhes dos agendamentos
SELECT 
    'Detalhes dos Agendamentos' as info,
    id,
    aula_periodo,
    sala_id,
    curso_id,
    materia_id,
    professor_id,
    dia,
    periodo,
    tipo_agendamento,
    created_at
FROM agendamento 
WHERE dia >= CURRENT_DATE AND tipo_agendamento = 'A'
ORDER BY created_at DESC; 