-- Script final para limpar registros duplicados e preparar para nova funcionalidade

-- 1. Primeiro, vamos ver o estado atual do histórico
SELECT 
  'Estado Atual' as status,
  acao,
  COUNT(*) as quantidade
FROM historico_acoes 
WHERE tabela_afetada = 'agendamento' 
  AND acao IN ('INSERT', 'INSERT_MULTIPLE')
  AND data_hora >= NOW() - INTERVAL '24 hours'
GROUP BY acao
ORDER BY acao;

-- 2. Remover registros INSERT individuais que foram criados por agendamentos múltiplos
-- (registros criados em sequência rápida)
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

-- 3. Verificar o resultado após a limpeza
SELECT 
  'Após Limpeza' as status,
  acao,
  COUNT(*) as quantidade
FROM historico_acoes 
WHERE tabela_afetada = 'agendamento' 
  AND acao IN ('INSERT', 'INSERT_MULTIPLE')
  AND data_hora >= NOW() - INTERVAL '24 hours'
GROUP BY acao
ORDER BY acao;

-- 4. Mostrar os registros restantes
SELECT 
  id,
  acao,
  registro_id,
  detalhes,
  data_hora
FROM historico_acoes 
WHERE tabela_afetada = 'agendamento' 
  AND acao IN ('INSERT', 'INSERT_MULTIPLE')
  AND data_hora >= NOW() - INTERVAL '24 hours'
ORDER BY data_hora DESC
LIMIT 10;

-- 5. Verificar se as funções de trigger foram criadas
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines 
WHERE routine_name IN ('desabilitar_triggers_agendamento', 'reabilitar_triggers_agendamento')
ORDER BY routine_name; 