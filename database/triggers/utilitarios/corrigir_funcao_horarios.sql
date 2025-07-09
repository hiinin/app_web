-- Script para corrigir a função definir_horarios_agendamento
-- Remove a validação que exige professor associado

-- 1. Primeiro, vamos ver a função atual
SELECT 
    'Função Atual' as info,
    proname as nome_funcao,
    prosrc as codigo_fonte
FROM pg_proc 
WHERE proname = 'definir_horarios_agendamento';

-- 2. Criar uma nova versão da função sem a validação de professor
CREATE OR REPLACE FUNCTION definir_horarios_agendamento()
RETURNS TRIGGER AS $$
BEGIN
    -- Remove a validação que exige professor associado
    -- A função agora permite agendamentos sem professor obrigatório
    
    -- Se precisar de alguma validação específica, pode adicionar aqui
    -- Por exemplo, verificar se a matéria existe
    IF NOT EXISTS (SELECT 1 FROM materias WHERE id = NEW.materia_id) THEN
        RAISE EXCEPTION 'Matéria não encontrada';
    END IF;
    
    -- Se precisar verificar se a sala existe
    IF NOT EXISTS (SELECT 1 FROM salas WHERE id = NEW.sala_id) THEN
        RAISE EXCEPTION 'Sala não encontrada';
    END IF;
    
    -- Se precisar verificar se o curso existe
    IF NOT EXISTS (SELECT 1 FROM cursos WHERE id = NEW.curso_id) THEN
        RAISE EXCEPTION 'Curso não encontrado';
    END IF;
    
    -- Retorna o registro para continuar a inserção
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Verificar se a função foi atualizada
SELECT 
    'Função Atualizada' as info,
    proname as nome_funcao,
    prosrc as codigo_fonte
FROM pg_proc 
WHERE proname = 'definir_horarios_agendamento';

-- 4. Verificar se há triggers usando esta função
SELECT 
    'Triggers que usam a função' as info,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE action_statement LIKE '%definir_horarios_agendamento%'
ORDER BY trigger_name;

-- 5. Testar se a função funciona agora
-- Criar um agendamento de teste
INSERT INTO agendamento (
    aula_periodo, 
    sala_id, 
    curso_id, 
    materia_id, 
    dia, 
    periodo, 
    tipo_agendamento
) VALUES (
    'Teste Função', 
    1, 
    1, 
    1, 
    '2025-01-01', 
    1, 
    'T'
) ON CONFLICT DO NOTHING;

-- 6. Verificar se o agendamento foi criado
SELECT 
    'Teste de Agendamento' as info,
    id,
    aula_periodo,
    sala_id,
    curso_id,
    materia_id,
    dia,
    tipo_agendamento
FROM agendamento 
WHERE tipo_agendamento = 'T'
ORDER BY id DESC
LIMIT 5;

-- 7. Limpar o agendamento de teste
DELETE FROM agendamento WHERE tipo_agendamento = 'T';

-- 8. Verificar se o histórico foi criado
SELECT 
    'Histórico de Teste' as info,
    id,
    tabela_afetada,
    acao,
    detalhes,
    data_hora
FROM historico_acoes 
WHERE tabela_afetada = 'agendamento' 
  AND data_hora >= NOW() - INTERVAL '5 minutes'
ORDER BY data_hora DESC
LIMIT 5; 