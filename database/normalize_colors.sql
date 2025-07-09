-- Script para normalizar cores das salas
-- Converte cores hexadecimais para formato decimal consistente

-- Atualiza cores que estão em formato hexadecimal (começando com 'ff')
UPDATE salas 
SET cor = CAST(('x' || SUBSTRING(cor FROM 3))::bit(32)::bigint AS TEXT)
WHERE cor LIKE 'ff%';

-- Atualiza cores que estão em formato hexadecimal sem prefixo 'ff'
UPDATE salas 
SET cor = CAST(('x' || cor)::bit(32)::bigint AS TEXT)
WHERE cor ~ '^[0-9a-fA-F]{6}$';

-- Verifica se há cores inválidas
SELECT id, numero_sala, cor 
FROM salas 
WHERE cor IS NOT NULL 
AND cor NOT SIMILAR TO '[0-9]+';

-- Mostra todas as cores após normalização
SELECT id, numero_sala, cor, 
       CASE 
         WHEN cor ~ '^[0-9]+$' THEN 'Válida'
         ELSE 'Inválida'
       END as status
FROM salas 
ORDER BY numero_sala; 