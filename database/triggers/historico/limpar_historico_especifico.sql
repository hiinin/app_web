-- Script para limpar registros individuais de INSERT no histórico
-- e deixar apenas os registros INSERT_MULTIPLE para agendamentos múltiplos

-- 1. Primeiro, vamos ver quantos registros temos atualmente
SELECT 
  acao,
  COUNT(*) as quantidade,
  MIN(data_hora) as primeiro_registro,
  MAX(data_hora) as ultimo_registro
FROM historico_acoes 
WHERE tabela_afetada = 'agendamento' 
  AND acao IN ('INSERT', 'INSERT_MULTIPLE')
  AND data_hora >= NOW() - INTERVAL '24 hours'
GROUP BY acao
ORDER BY acao;

-- 2. Identificar registros INSERT que podem ser parte de agendamentos múltiplos
-- (registros criados em sequência rápida)
WITH registros_sequencia AS (
  SELECT 
    id,
    registro_id,
    data_hora,
    detalhes,
    -- Agrupa registros criados em sequência (dentro de 30 segundos)
    LAG(data_hora) OVER (ORDER BY data_hora) as registro_anterior,
    LEAD(data_hora) OVER (ORDER BY data_hora) as registro_posterior
  FROM historico_acoes 
  WHERE tabela_afetada = 'agendamento' 
    AND acao = 'INSERT'
    AND data_hora >= NOW() - INTERVAL '24 hours'
),
registros_para_remover AS (
  SELECT id
  FROM registros_sequencia
  WHERE 
    -- Registro criado logo após outro (dentro de 30 segundos)
    (registro_anterior IS NOT NULL AND 
     EXTRACT(EPOCH FROM (data_hora - registro_anterior)) <= 30)
    OR
    -- Registro que tem outro logo após (dentro de 30 segundos)
    (registro_posterior IS NOT NULL AND 
     EXTRACT(EPOCH FROM (registro_posterior - data_hora)) <= 30)
)
-- 3. Remover os registros identificados
DELETE FROM historico_acoes 
WHERE id IN (SELECT id FROM registros_para_remover);

-- 4. Verificar o resultado após a limpeza
SELECT 
  'Após limpeza' as status,
  acao,
  COUNT(*) as quantidade
FROM historico_acoes 
WHERE tabela_afetada = 'agendamento' 
  AND acao IN ('INSERT', 'INSERT_MULTIPLE')
  AND data_hora >= NOW() - INTERVAL '24 hours'
GROUP BY acao
ORDER BY acao;

-- 5. Mostrar os registros restantes
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