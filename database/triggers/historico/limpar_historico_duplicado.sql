-- Script para limpar registros duplicados no histórico de ações
-- Remove registros individuais de INSERT que foram criados por agendamentos múltiplos

-- 1. Primeiro, vamos identificar registros que podem ser duplicados
-- (registros INSERT na tabela agendamento criados em sequência rápida)

WITH registros_duplicados AS (
  SELECT 
    id,
    tabela_afetada,
    acao,
    registro_id,
    data_hora,
    -- Agrupa registros que foram criados em sequência (dentro de 10 segundos)
    -- e são do mesmo tipo (INSERT na tabela agendamento)
    ROW_NUMBER() OVER (
      PARTITION BY 
        tabela_afetada, 
        acao,
        DATE_TRUNC('minute', data_hora::timestamp)
      ORDER BY data_hora
    ) as rn
  FROM historico_acoes 
  WHERE tabela_afetada = 'agendamento' 
    AND acao = 'INSERT'
    AND data_hora >= NOW() - INTERVAL '1 hour' -- Última hora
)
-- Remove registros duplicados, mantendo apenas o primeiro de cada grupo
DELETE FROM historico_acoes 
WHERE id IN (
  SELECT id 
  FROM registros_duplicados 
  WHERE rn > 1
);

-- 2. Verificar quantos registros foram removidos
SELECT 
  'Registros duplicados removidos' as acao,
  COUNT(*) as quantidade
FROM historico_acoes 
WHERE tabela_afetada = 'agendamento' 
  AND acao = 'INSERT'
  AND data_hora >= NOW() - INTERVAL '1 hour';

-- 3. Mostrar os registros restantes no histórico
SELECT 
  id,
  tabela_afetada,
  acao,
  registro_id,
  detalhes,
  data_hora
FROM historico_acoes 
WHERE tabela_afetada = 'agendamento' 
  AND data_hora >= NOW() - INTERVAL '1 hour'
ORDER BY data_hora DESC
LIMIT 20; 