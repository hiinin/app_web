-- Script simples para recriar os triggers de histórico
-- Execute este script no Supabase SQL Editor

-- 1. Remover triggers existentes
DROP TRIGGER IF EXISTS trigger_log_agendamento_insert ON agendamento;
DROP TRIGGER IF EXISTS trigger_log_agendamento_update ON agendamento;
DROP TRIGGER IF EXISTS trigger_log_agendamento_delete ON agendamento;

-- 2. Recriar as funções dos triggers
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

-- 3. Recriar os triggers
CREATE TRIGGER trigger_log_agendamento_insert
    AFTER INSERT ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION log_agendamento_insert();

CREATE TRIGGER trigger_log_agendamento_update
    AFTER UPDATE ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION log_agendamento_update();

CREATE TRIGGER trigger_log_agendamento_delete
    AFTER DELETE ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION log_agendamento_delete();

-- 4. Verificar se foram criados
SELECT 
    'Triggers Criados' as info,
    tgname as trigger_name,
    CASE 
        WHEN tgenabled = 'D' THEN 'DESABILITADO ❌'
        WHEN tgenabled = 'E' THEN 'HABILITADO ✅'
        WHEN tgenabled = 'A' THEN 'SEMPRE ✅'
        WHEN tgenabled = 'R' THEN 'REPLICA ✅'
        ELSE 'DESCONHECIDO ❓'
    END as status
FROM pg_trigger 
WHERE tgrelid = 'agendamento'::regclass
  AND tgname LIKE '%log%'
ORDER BY tgname;

-- 5. Teste simples
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
    
    RAISE NOTICE '🧪 Testando inserção...';
    
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
    
    -- Verificar se o histórico foi criado
    IF EXISTS (
        SELECT 1 FROM historico_acoes 
        WHERE tabela_afetada = 'agendamento' 
          AND registro_id = agendamento_id
          AND acao = 'INSERT'
    ) THEN
        RAISE NOTICE '✅ Histórico criado com sucesso!';
    ELSE
        RAISE NOTICE '❌ Histórico NÃO foi criado!';
    END IF;
    
    -- Limpar o teste
    DELETE FROM agendamento WHERE id = agendamento_id;
    DELETE FROM historico_acoes WHERE registro_id = agendamento_id;
    
    RAISE NOTICE '🧹 Teste limpo!';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erro: %', SQLERRM;
END $$; 