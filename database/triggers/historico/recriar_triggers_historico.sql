-- Script para recriar os triggers de histórico
-- Execute este script no Supabase SQL Editor

-- 1. Verificar se os triggers existem e suas definições
SELECT 
    'Verificação Inicial' as info,
    tgname as trigger_name,
    tgenabled as status,
    tgdeferrable as deferrable,
    tginitdeferred as init_deferred
FROM pg_trigger 
WHERE tgrelid = 'agendamento'::regclass
  AND tgname LIKE '%log%'
ORDER BY tgname;

-- 2. Verificar se as funções dos triggers existem
SELECT 
    'Funções dos Triggers' as info,
    funcs.proname as function_name,
    CASE WHEN p.proname IS NOT NULL THEN 'EXISTE ✅' ELSE 'NÃO EXISTE ❌' END as status
FROM (
    SELECT 'log_agendamento_insert' as proname
    UNION SELECT 'log_agendamento_update' 
    UNION SELECT 'log_agendamento_delete'
) funcs
LEFT JOIN pg_proc p ON p.proname = funcs.proname;

-- 3. Remover os triggers existentes (se houver)
DO $$
BEGIN
    -- Remove triggers de log se existirem
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_insert') THEN
        DROP TRIGGER IF EXISTS trigger_log_agendamento_insert ON agendamento;
        RAISE NOTICE '🗑️ Trigger trigger_log_agendamento_insert removido';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_update') THEN
        DROP TRIGGER IF EXISTS trigger_log_agendamento_update ON agendamento;
        RAISE NOTICE '🗑️ Trigger trigger_log_agendamento_update removido';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_log_agendamento_delete') THEN
        DROP TRIGGER IF EXISTS trigger_log_agendamento_delete ON agendamento;
        RAISE NOTICE '🗑️ Trigger trigger_log_agendamento_delete removido';
    END IF;
    
    RAISE NOTICE '🧹 Todos os triggers de log foram removidos';
END $$;

-- 4. Recriar as funções dos triggers
-- Função para log de INSERT
CREATE OR REPLACE FUNCTION log_agendamento_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        tabela_afetada,
        acao,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'agendamento',
        'INSERT',
        NEW.id,
        NULL,
        row_to_json(NEW),
        'Agendamento criado',
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Função para log de UPDATE
CREATE OR REPLACE FUNCTION log_agendamento_update()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        tabela_afetada,
        acao,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'agendamento',
        'UPDATE',
        NEW.id,
        row_to_json(OLD),
        row_to_json(NEW),
        'Agendamento atualizado',
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Função para log de DELETE
CREATE OR REPLACE FUNCTION log_agendamento_delete()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        tabela_afetada,
        acao,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'agendamento',
        'DELETE',
        OLD.id,
        row_to_json(OLD),
        NULL,
        'Agendamento removido',
        NOW()
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- 5. Recriar os triggers
-- Trigger para INSERT
CREATE TRIGGER trigger_log_agendamento_insert
    AFTER INSERT ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION log_agendamento_insert();

-- Trigger para UPDATE
CREATE TRIGGER trigger_log_agendamento_update
    AFTER UPDATE ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION log_agendamento_update();

-- Trigger para DELETE
CREATE TRIGGER trigger_log_agendamento_delete
    AFTER DELETE ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION log_agendamento_delete();

-- 6. Verificar se os triggers foram criados corretamente
SELECT 
    'Status Após Recriação' as info,
    tgname as trigger_name,
    CASE 
        WHEN tgenabled = 'D' THEN 'DESABILITADO ❌'
        WHEN tgenabled = 'E' THEN 'HABILITADO ✅'
        WHEN tgenabled = 'A' THEN 'SEMPRE ✅'
        WHEN tgenabled = 'R' THEN 'REPLICA ✅'
        ELSE 'DESCONHECIDO ❓'
    END as status,
    tgdeferrable as deferrable,
    tginitdeferred as init_deferred
FROM pg_trigger 
WHERE tgrelid = 'agendamento'::regclass
  AND tgname LIKE '%log%'
ORDER BY tgname;

-- 7. Testar o funcionamento
DO $$
DECLARE
    materia_id_valido BIGINT;
    sala_id_valido INTEGER;
    curso_id_valido INTEGER;
    agendamento_id INTEGER;
BEGIN
    -- Pegar IDs válidos
    SELECT MIN(id) INTO materia_id_valido FROM materias;
    SELECT MIN(id) INTO sala_id_valido FROM salas;
    SELECT MIN(id) INTO curso_id_valido FROM cursos;
    
    IF materia_id_valido IS NULL OR sala_id_valido IS NULL OR curso_id_valido IS NULL THEN
        RAISE NOTICE '❌ Não foi possível encontrar IDs válidos para o teste';
        RETURN;
    END IF;
    
    RAISE NOTICE '🧪 Iniciando teste de inserção...';
    RAISE NOTICE '📋 IDs: Matéria=%, Sala=%, Curso=%', materia_id_valido, sala_id_valido, curso_id_valido;
    
    -- Testar inserção
    INSERT INTO agendamento (
        aula_periodo, 
        sala_id, 
        curso_id, 
        materia_id, 
        dia, 
        periodo, 
        tipo_agendamento
    ) VALUES (
        'Primeira Aula', 
        sala_id_valido, 
        curso_id_valido, 
        materia_id_valido, 
        (CURRENT_DATE + INTERVAL '1 day')::date, 
        1, 
        'T'
    ) RETURNING id INTO agendamento_id;
    
    RAISE NOTICE '📝 Agendamento criado com ID: %', agendamento_id;
    
    -- Aguardar um pouco para o trigger executar
    PERFORM pg_sleep(1);
    
    -- Verificar se o histórico foi criado
    IF EXISTS (
        SELECT 1 FROM historico_acoes 
        WHERE tabela_afetada = 'agendamento' 
          AND registro_id = agendamento_id
          AND acao = 'INSERT'
    ) THEN
        RAISE NOTICE '✅ Histórico criado com sucesso!';
        
        -- Mostrar detalhes do registro criado
        SELECT 
            'Registro Criado' as info,
            id,
            tabela_afetada,
            acao,
            registro_id,
            detalhes,
            data_hora
        FROM historico_acoes 
        WHERE registro_id = agendamento_id
        ORDER BY data_hora DESC
        LIMIT 1;
        
    ELSE
        RAISE NOTICE '❌ Histórico NÃO foi criado!';
    END IF;
    
    -- Limpar o teste
    DELETE FROM agendamento WHERE id = agendamento_id;
    DELETE FROM historico_acoes WHERE registro_id = agendamento_id;
    
    RAISE NOTICE '🧹 Teste limpo com sucesso!';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erro no teste: %', SQLERRM;
END $$;

-- 8. Verificar registros recentes no histórico
SELECT 
    'Histórico Recente (últimos 5 minutos)' as info,
    id,
    tabela_afetada,
    acao,
    registro_id,
    detalhes,
    data_hora
FROM historico_acoes 
WHERE tabela_afetada = 'agendamento' 
  AND data_hora >= NOW() - INTERVAL '5 minutes'
ORDER BY data_hora DESC
LIMIT 10; 