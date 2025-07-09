-- Script para desabilitar os triggers do agendamento durante operações múltiplas
-- Isso evita que os triggers criem registros individuais no histórico

-- 1. Desabilitar todos os triggers da tabela agendamento
ALTER TABLE agendamento DISABLE TRIGGER ALL;

-- 2. Verificar se foram desabilitados
SELECT 
    schemaname,
    tablename,
    triggername,
    tgenabled,
    CASE 
        WHEN tgenabled = 'D' THEN 'DESABILITADO'
        WHEN tgenabled = 'E' THEN 'HABILITADO'
        WHEN tgenabled = 'A' THEN 'SEMPRE'
        WHEN tgenabled = 'R' THEN 'REPLICA'
        ELSE 'DESCONHECIDO'
    END as status
FROM pg_trigger 
WHERE tgrelid = 'agendamento'::regclass
ORDER BY triggername;

-- 3. Função para reabilitar os triggers (quando necessário)
CREATE OR REPLACE FUNCTION reabilitar_triggers_agendamento()
RETURNS void AS $$
BEGIN
    ALTER TABLE agendamento ENABLE TRIGGER ALL;
    RAISE NOTICE 'Triggers da tabela agendamento reabilitados';
END;
$$ LANGUAGE plpgsql;

-- 4. Função para desabilitar os triggers (quando necessário)
CREATE OR REPLACE FUNCTION desabilitar_triggers_agendamento()
RETURNS void AS $$
BEGIN
    ALTER TABLE agendamento DISABLE TRIGGER ALL;
    RAISE NOTICE 'Triggers da tabela agendamento desabilitados';
END;
$$ LANGUAGE plpgsql; 