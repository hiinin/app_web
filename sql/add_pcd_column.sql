-- Adicionar coluna PCD na tabela salas
ALTER TABLE public.salas
ADD COLUMN pcd boolean NULL DEFAULT false;

-- Comentário na coluna para documentação
COMMENT ON COLUMN public.salas.pcd IS 'Indica se a sala é adaptada para Pessoas com Deficiência (PCD)';

-- Adicionar coluna qtd_cadeiras_pcd na tabela salas
ALTER TABLE public.salas
ADD COLUMN qtd_cadeiras_pcd integer NULL DEFAULT 0;

-- Comentário na coluna para documentação
COMMENT ON COLUMN public.salas.qtd_cadeiras_pcd IS 'Quantidade de carteiras adaptadas para PCD na sala';

