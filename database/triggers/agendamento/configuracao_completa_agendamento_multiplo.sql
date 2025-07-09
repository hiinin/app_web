-- Script consolidado para configurar agendamento múltiplo
-- Execute este script completo no Supabase SQL Editor

-- 1. Primeiro, vamos verificar o estado atual dos triggers
SELECT 
    'Estado Atual dos Triggers' as info,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
ORDER BY trigger_name;

-- 2. Desabilitar todos os triggers da tabela agendamento
ALTER TABLE agendamento DISABLE TRIGGER ALL;

-- 3. Verificar se foram desabilitados
SELECT 
    'Triggers Desabilitados' as status,
    schemaname,
    tablename,
    triggername,
    CASE 
        WHEN tgenabled = 'D' THEN 'DESABILITADO ✅'
        WHEN tgenabled = 'E' THEN 'HABILITADO ❌'
        WHEN tgenabled = 'A' THEN 'SEMPRE ❌'
        WHEN tgenabled = 'R' THEN 'REPLICA ❌'
        ELSE 'DESCONHECIDO ❌'
    END as status_detalhado
FROM pg_trigger 
WHERE tgrelid = 'agendamento'::regclass
ORDER BY triggername;

-- 4. Limpar registros duplicados existentes no histórico
-- Remove registros INSERT individuais que foram criados por agendamentos múltiplos
DELETE FROM historico_acoes 
WHERE id IN (
  SELECT h1.id
  FROM historico_acoes h1
  WHERE h1.tabela_afetada = 'agendamento' 
    AND h1.acao = 'INSERT'
    AND h1.data_hora >= NOW() - INTERVAL '24 hours'
    AND EXISTS (
      SELECT 1 
      FROM historico_acoes h2
      WHERE h2.tabela_afetada = 'agendamento' 
        AND h2.acao = 'INSERT'
        AND h2.data_hora >= NOW() - INTERVAL '24 hours'
        AND h2.id != h1.id
        AND ABS(EXTRACT(EPOCH FROM (h2.data_hora - h1.data_hora))) <= 30
    )
);

-- 5. Verificar o resultado da limpeza
SELECT 
  'Histórico Após Limpeza' as status,
  acao,
  COUNT(*) as quantidade
FROM historico_acoes 
WHERE tabela_afetada = 'agendamento' 
  AND acao IN ('INSERT', 'INSERT_MULTIPLE')
  AND data_hora >= NOW() - INTERVAL '24 hours'
GROUP BY acao
ORDER BY acao;

-- 6. Verificar se as funções de controle estão disponíveis
SELECT 
  'Funções Disponíveis' as info,
  routine_name,
  routine_type
FROM information_schema.routines 
WHERE routine_name IN (
  'desabilitar_triggers_agendamento', 
  'reabilitar_triggers_agendamento',
  'disable_agendamento_triggers',
  'enable_agendamento_triggers'
)
ORDER BY routine_name;

-- 7. Mostrar os últimos registros do histórico para verificação
SELECT 
  'Últimos Registros do Histórico' as info,
  id,
  acao,
  registro_id,
  detalhes,
  data_hora
FROM historico_acoes 
WHERE tabela_afetada = 'agendamento' 
  AND data_hora >= NOW() - INTERVAL '24 hours'
ORDER BY data_hora DESC
LIMIT 5; 