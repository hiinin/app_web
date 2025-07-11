-- Script para verificar se as novas regras de negócio foram implementadas corretamente
-- Execute este script no Supabase SQL Editor

-- 1. Verificar se a função de validação existe
SELECT 
    'Verificação da Função de Validação' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = 'validar_agendamento_aula_nova_regra'
        ) THEN '✅ Função existe'
        ELSE '❌ Função não encontrada'
    END as status;

-- 2. Verificar se o trigger existe
SELECT 
    'Verificação do Trigger' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'trigger_validar_aula_nova_regra'
        ) THEN '✅ Trigger existe'
        ELSE '❌ Trigger não encontrado'
    END as status;

-- 3. Verificar se o trigger está habilitado
SELECT 
    'Status do Trigger' as info,
    CASE 
        WHEN tgenabled = 'E' THEN '✅ Habilitado'
        WHEN tgenabled = 'D' THEN '❌ Desabilitado'
        ELSE '❓ Status desconhecido'
    END as status
FROM pg_trigger 
WHERE tgname = 'trigger_validar_aula_nova_regra';

-- 4. Verificar a estrutura da tabela agendamento
SELECT 
    'Estrutura da Tabela Agendamento' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'agendamento'
ORDER BY ordinal_position;

-- 5. Verificar dados existentes para análise
SELECT 
    'Dados Existentes' as info,
    'Total de agendamentos' as tipo,
    COUNT(*) as quantidade
FROM agendamento
UNION ALL
SELECT 
    'Dados Existentes' as info,
    'Aulas (tipo A)' as tipo,
    COUNT(*) as quantidade
FROM agendamento
WHERE tipo_agendamento = 'A'
UNION ALL
SELECT 
    'Dados Existentes' as info,
    'Provas (tipo M)' as tipo,
    COUNT(*) as quantidade
FROM agendamento
WHERE tipo_agendamento = 'M'
UNION ALL
SELECT 
    'Dados Existentes' as info,
    'Eventos (tipo E)' as tipo,
    COUNT(*) as quantidade
FROM agendamento
WHERE tipo_agendamento = 'E';

-- 6. Verificar se há conflitos atuais (dados que violariam as novas regras)
SELECT 
    'Verificação de Conflitos Atuais' as info,
    sala_id,
    dia,
    aula_periodo,
    COUNT(*) as total_agendamentos,
    COUNT(CASE WHEN tipo_agendamento = 'A' THEN 1 END) as aulas,
    COUNT(CASE WHEN tipo_agendamento = 'M' THEN 1 END) as provas,
    COUNT(CASE WHEN tipo_agendamento = 'E' THEN 1 END) as eventos
FROM agendamento 
GROUP BY sala_id, dia, aula_periodo
HAVING COUNT(*) > 2 OR COUNT(CASE WHEN tipo_agendamento = 'A' THEN 1 END) > 2
ORDER BY total_agendamentos DESC
LIMIT 10;

-- 7. Verificar salas com alta ocupação
SELECT 
    'Salas com Alta Ocupação' as info,
    sala_id,
    dia,
    COUNT(*) as total_agendamentos,
    CASE 
        WHEN COUNT(*) >= 12 THEN '⚠️ Limite atingido'
        WHEN COUNT(*) >= 10 THEN '⚠️ Próximo do limite'
        ELSE '✅ OK'
    END as status
FROM agendamento 
GROUP BY sala_id, dia
HAVING COUNT(*) >= 10
ORDER BY total_agendamentos DESC
LIMIT 10;

-- 8. Testar a função de validação com dados de exemplo
DO $$
DECLARE
    materia_id_valido BIGINT;
    sala_id_valido INTEGER;
    curso_id_valido INTEGER;
    professor_id_valido INTEGER;
    resultado TEXT;
BEGIN
    -- Pegar IDs válidos
    SELECT MIN(id) INTO materia_id_valido FROM materias;
    SELECT MIN(id) INTO sala_id_valido FROM salas;
    SELECT MIN(id) INTO curso_id_valido FROM cursos;
    SELECT MIN(id) INTO professor_id_valido FROM professores;
    
    -- Testar inserção válida
    BEGIN
        INSERT INTO agendamento (
            sala_id, curso_id, materia_id, professor_id,
            dia, aula_periodo, periodo, tipo_agendamento
        ) VALUES (
            sala_id_valido, curso_id_valido, materia_id_valido, professor_id_valido,
            (CURRENT_DATE + INTERVAL '2 days')::date, 'Primeira Aula', 1, 'A'
        );
        resultado := '✅ Inserção válida funcionou';
    EXCEPTION
        WHEN OTHERS THEN
            resultado := '❌ Inserção válida falhou: ' || SQLERRM;
    END;
    
    RAISE NOTICE 'Teste de inserção válida: %', resultado;
    
    -- Limpar teste
    DELETE FROM agendamento WHERE dia = (CURRENT_DATE + INTERVAL '2 days')::date AND sala_id = sala_id_valido;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro no teste: %', SQLERRM;
END $$;

-- 9. Verificar se há triggers conflitantes
SELECT 
    'Triggers Conflitantes' as info,
    trigger_name,
    event_manipulation,
    action_timing,
    CASE 
        WHEN trigger_name LIKE '%validar%' OR trigger_name LIKE '%aula%' THEN '⚠️ Possível conflito'
        ELSE '✅ OK'
    END as observacao
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
  AND trigger_name != 'trigger_validar_aula_nova_regra'
ORDER BY trigger_name;

-- 10. Resumo da implementação
SELECT 
    'Resumo da Implementação' as info,
    'Status' as item,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'validar_agendamento_aula_nova_regra')
          AND EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'trigger_validar_aula_nova_regra')
        THEN '✅ Implementação completa'
        ELSE '❌ Implementação incompleta'
    END as valor
UNION ALL
SELECT 
    'Resumo da Implementação' as info,
    'Função de validação' as item,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'validar_agendamento_aula_nova_regra')
        THEN '✅ Criada'
        ELSE '❌ Não encontrada'
    END as valor
UNION ALL
SELECT 
    'Resumo da Implementação' as info,
    'Trigger de validação' as item,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'trigger_validar_aula_nova_regra')
        THEN '✅ Criado'
        ELSE '❌ Não encontrado'
    END as valor
UNION ALL
SELECT 
    'Resumo da Implementação' as info,
    'Limite por sala' as item,
    '12 agendamentos por dia' as valor
UNION ALL
SELECT 
    'Resumo da Implementação' as info,
    'Limite por horário (aulas)' as item,
    '2 cursos diferentes' as valor
UNION ALL
SELECT 
    'Resumo da Implementação' as info,
    'Aplicação' as item,
    'Apenas para aulas (tipo_agendamento = A)' as valor; 