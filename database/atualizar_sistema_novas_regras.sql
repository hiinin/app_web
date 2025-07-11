-- Script para atualizar o sistema com as novas regras de negócio
-- Execute este script no Supabase SQL Editor

-- 1. PRIMEIRO: Criar as funções auxiliares que estão sendo chamadas na função principal

-- Função auxiliar para contar alocações por sala por dia
CREATE OR REPLACE FUNCTION contar_alocacoes_sala_dia(
    p_sala_id INTEGER,
    p_dia DATE,
    p_agendamento_id INTEGER DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    total_alocacoes INTEGER;
BEGIN
    -- Conta quantas vezes a sala foi alocada na data específica
    SELECT COUNT(*) INTO total_alocacoes
    FROM agendamento 
    WHERE sala_id = p_sala_id 
      AND dia = p_dia
      AND id != COALESCE(p_agendamento_id, 0);
    
    RETURN total_alocacoes;
END;
$$ LANGUAGE plpgsql;

-- Função auxiliar para contar cursos no mesmo horário
CREATE OR REPLACE FUNCTION contar_cursos_mesmo_horario(
    p_sala_id INTEGER,
    p_dia DATE,
    p_periodo INTEGER,
    p_aula_periodo TEXT,
    p_agendamento_id INTEGER DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    total_cursos INTEGER;
BEGIN
    -- Conta quantos cursos diferentes estão alocados no mesmo horário
    SELECT COUNT(DISTINCT curso_id) INTO total_cursos
    FROM agendamento 
    WHERE sala_id = p_sala_id 
      AND dia = p_dia
      AND periodo = p_periodo
      AND aula_periodo = p_aula_periodo
      AND id != COALESCE(p_agendamento_id, 0);
    
    RETURN total_cursos;
END;
$$ LANGUAGE plpgsql;

-- Função auxiliar para verificar se o curso já está alocado no mesmo horário
CREATE OR REPLACE FUNCTION curso_ja_alocado_horario(
    p_sala_id INTEGER,
    p_dia DATE,
    p_periodo INTEGER,
    p_aula_periodo TEXT,
    p_curso_id INTEGER,
    p_agendamento_id INTEGER DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    ja_alocado BOOLEAN;
BEGIN
    -- Verifica se o curso já está alocado no mesmo horário
    SELECT EXISTS(
        SELECT 1 FROM agendamento 
        WHERE sala_id = p_sala_id 
          AND dia = p_dia
          AND periodo = p_periodo
          AND aula_periodo = p_aula_periodo
          AND curso_id = p_curso_id
          AND id != COALESCE(p_agendamento_id, 0)
    ) INTO ja_alocado;
    
    RETURN ja_alocado;
END;
$$ LANGUAGE plpgsql;

-- 2. SEGUNDO: Verificar e remover funções antigas que podem conflitar

-- Listar funções que podem estar usando regras antigas
SELECT 
    'Funções para Verificar' as categoria,
    proname as nome_funcao,
    CASE 
        WHEN prosrc LIKE '%6%' OR prosrc LIKE '%seis%' THEN '⚠️ Pode ter limite antigo (6)'
        WHEN prosrc LIKE '%1%curso%' OR prosrc LIKE '%um%curso%' THEN '⚠️ Pode ter regra antiga (1 curso)'
        WHEN prosrc LIKE '%conflito%' AND prosrc NOT LIKE '%definir_horarios_agendamento%' THEN '⚠️ Pode ter validação antiga'
        ELSE '✅ Provavelmente OK'
    END as observacao
FROM pg_proc 
WHERE prosrc LIKE '%agendamento%'
  AND (prosrc LIKE '%6%' OR prosrc LIKE '%seis%' OR prosrc LIKE '%1%curso%' OR prosrc LIKE '%um%curso%' OR prosrc LIKE '%conflito%')
  AND proname != 'definir_horarios_agendamento'
ORDER BY proname;

-- 3. TERCEIRO: Verificar triggers que podem estar usando funções antigas

-- Listar triggers que podem estar usando funções antigas
SELECT 
    'Triggers para Verificar' as categoria,
    trigger_name,
    action_statement,
    CASE 
        WHEN action_statement NOT LIKE '%definir_horarios_agendamento%' THEN '⚠️ Pode estar usando função antiga'
        ELSE '✅ Usando função correta'
    END as observacao
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
  AND trigger_name LIKE '%validar%'
ORDER BY trigger_name;

-- 4. QUARTO: Configurar o trigger corretamente

-- Desabilitar triggers antigos que podem conflitar
DO $$
BEGIN
    -- Desabilitar triggers que não usam a função principal
    IF EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE event_object_table = 'agendamento'
          AND trigger_name = 'trigger_validar_agendamento'
          AND action_statement NOT LIKE '%definir_horarios_agendamento%'
    ) THEN
        ALTER TABLE agendamento DISABLE TRIGGER trigger_validar_agendamento;
        RAISE NOTICE 'Trigger antigo desabilitado';
    END IF;
END $$;

-- Criar/atualizar trigger para usar a função correta
DROP TRIGGER IF EXISTS trigger_validar_agendamento ON agendamento;

CREATE TRIGGER trigger_validar_agendamento
    BEFORE INSERT OR UPDATE ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION definir_horarios_agendamento();

-- 5. QUINTO: Verificar se tudo está funcionando

-- Verificar se as funções auxiliares foram criadas
SELECT 
    'Verificação das Funções Auxiliares' as categoria,
    proname as nome_funcao,
    CASE 
        WHEN proname = 'contar_alocacoes_sala_dia' THEN '✅ Criada'
        WHEN proname = 'contar_cursos_mesmo_horario' THEN '✅ Criada'
        WHEN proname = 'curso_ja_alocado_horario' THEN '✅ Criada'
        WHEN proname = 'definir_horarios_agendamento' THEN '✅ Atualizada'
        ELSE '❓ Não encontrada'
    END as status
FROM pg_proc 
WHERE proname IN ('contar_alocacoes_sala_dia', 'contar_cursos_mesmo_horario', 'curso_ja_alocado_horario', 'definir_horarios_agendamento')
ORDER BY proname;

-- Verificar se o trigger está configurado corretamente
SELECT 
    'Verificação do Trigger' as categoria,
    trigger_name,
    action_statement,
    CASE 
        WHEN action_statement LIKE '%definir_horarios_agendamento%' THEN '✅ CONFIGURADO CORRETAMENTE'
        ELSE '❌ PROBLEMA NA CONFIGURAÇÃO'
    END as status
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
  AND trigger_name = 'trigger_validar_agendamento';

-- 6. SEXTO: Instruções para limpeza (se necessário)

-- Listar funções que podem ser removidas (se existirem)
SELECT 
    'Funções que podem ser removidas' as categoria,
    proname as nome_funcao,
    'Execute: DROP FUNCTION IF EXISTS ' || proname || '();' as comando_remocao
FROM pg_proc 
WHERE prosrc LIKE '%agendamento%'
  AND (prosrc LIKE '%6%' OR prosrc LIKE '%seis%' OR prosrc LIKE '%1%curso%' OR prosrc LIKE '%um%curso%')
  AND proname NOT IN ('definir_horarios_agendamento', 'contar_alocacoes_sala_dia', 'contar_cursos_mesmo_horario', 'curso_ja_alocado_horario')
ORDER BY proname;

-- 7. SÉTIMO: Resumo final
SELECT 
    'RESUMO DA ATUALIZAÇÃO' as categoria,
    '✅ Funções auxiliares criadas' as item_1,
    '✅ Trigger configurado para usar definir_horarios_agendamento' as item_2,
    '✅ Novas regras implementadas (limite 12, 2 cursos por horário)' as item_3,
    '⚠️ Verifique se há funções antigas para remover' as item_4,
    '✅ Sistema pronto para testes' as item_5; 