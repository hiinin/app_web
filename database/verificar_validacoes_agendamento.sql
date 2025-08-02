-- Script para verificar as validações do agendamento
-- Execute este script no Supabase SQL Editor

-- 1. Verificar estrutura da tabela agendamento
SELECT 
    'Estrutura da Tabela' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'agendamento' 
ORDER BY ordinal_position;

-- 2. Verificar agendamentos existentes para hoje e próximos dias
SELECT 
    'Agendamentos Existentes' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN tipo_agendamento = 'A' THEN 1 END) as aulas,
    COUNT(CASE WHEN tipo_agendamento = 'E' THEN 1 END) as eventos,
    COUNT(CASE WHEN tipo_agendamento = 'M' THEN 1 END) as provas
FROM agendamento 
WHERE dia >= CURRENT_DATE;

-- 3. Verificar agendamentos por sala e período
SELECT 
    'Agendamentos por Sala e Período' as info,
    sala_id,
    dia,
    aula_periodo,
    periodo,
    tipo_agendamento,
    COUNT(*) as quantidade
FROM agendamento 
WHERE dia >= CURRENT_DATE
GROUP BY sala_id, dia, aula_periodo, periodo, tipo_agendamento
ORDER BY dia, sala_id, aula_periodo;

-- 4. Verificar agendamentos por curso (máximo 2 por dia)
SELECT 
    'Agendamentos por Curso' as info,
    curso_id,
    dia,
    COUNT(*) as quantidade_agendamentos
FROM agendamento 
WHERE dia >= CURRENT_DATE
GROUP BY curso_id, dia
HAVING COUNT(*) >= 2
ORDER BY dia, curso_id;

-- 5. Verificar conflitos de horário
SELECT 
    'Conflitos de Horário' as info,
    sala_id,
    dia,
    aula_periodo,
    periodo,
    COUNT(*) as quantidade_agendamentos,
    STRING_AGG(tipo_agendamento, ', ') as tipos_agendamento
FROM agendamento 
WHERE dia >= CURRENT_DATE
GROUP BY sala_id, dia, aula_periodo, periodo
HAVING COUNT(*) > 1
ORDER BY quantidade_agendamentos DESC;

-- 6. Verificar dados disponíveis para teste
SELECT 
    'Dados Disponíveis' as info,
    'Matérias' as tipo,
    COUNT(*) as quantidade,
    MIN(id) as primeiro_id,
    MAX(id) as ultimo_id
FROM materias
UNION ALL
SELECT 
    'Dados Disponíveis' as info,
    'Salas' as tipo,
    COUNT(*) as quantidade,
    MIN(id) as primeiro_id,
    MAX(id) as ultimo_id
FROM salas
UNION ALL
SELECT 
    'Dados Disponíveis' as info,
    'Cursos' as tipo,
    COUNT(*) as quantidade,
    MIN(id) as primeiro_id,
    MAX(id) as ultimo_id
FROM cursos
UNION ALL
SELECT 
    'Dados Disponíveis' as info,
    'Professores' as tipo,
    COUNT(*) as quantidade,
    MIN(id) as primeiro_id,
    MAX(id) as ultimo_id
FROM professores;

-- 7. Verificar se há triggers que podem estar interferindo
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

-- 8. Testar inserção com dados específicos
DO $$
DECLARE
    materia_id_valido BIGINT;
    sala_id_valido INTEGER;
    curso_id_valido BIGINT;
    professor_id_valido BIGINT;
    data_teste DATE;
    agendamento_id BIGINT;
BEGIN
    -- Obter IDs válidos
    SELECT id INTO materia_id_valido FROM materias LIMIT 1;
    SELECT id INTO sala_id_valido FROM salas LIMIT 1;
    SELECT id INTO curso_id_valido FROM cursos LIMIT 1;
    SELECT id INTO professor_id_valido FROM professores LIMIT 1;
    
    -- Data de teste (amanhã)
    data_teste := CURRENT_DATE + INTERVAL '1 day';
    
    RAISE NOTICE 'Testando inserção com:';
    RAISE NOTICE 'Materia ID: %', materia_id_valido;
    RAISE NOTICE 'Sala ID: %', sala_id_valido;
    RAISE NOTICE 'Curso ID: %', curso_id_valido;
    RAISE NOTICE 'Professor ID: %', professor_id_valido;
    RAISE NOTICE 'Data: %', data_teste;
    
    -- Verificar se já existe agendamento para esta combinação
    IF EXISTS (
        SELECT 1 FROM agendamento 
        WHERE sala_id = sala_id_valido 
        AND curso_id = curso_id_valido 
        AND dia = data_teste 
        AND aula_periodo = 'M'
    ) THEN
        RAISE NOTICE '⚠️ Já existe agendamento para esta combinação';
    ELSE
        RAISE NOTICE '✅ Não há conflito - pode inserir';
        
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
            'M',
            sala_id_valido,
            curso_id_valido,
            materia_id_valido,
            professor_id_valido,
            data_teste,
            '2024.1',
            'A'
        ) RETURNING id INTO agendamento_id;
        
        RAISE NOTICE '✅ Inserção bem-sucedida! ID: %', agendamento_id;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ ERRO: %', SQLERRM;
END $$; 