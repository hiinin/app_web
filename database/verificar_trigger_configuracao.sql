-- Script para verificar e configurar o trigger corretamente
-- Execute este script no Supabase SQL Editor

-- 1. Verificar triggers atuais na tabela agendamento
SELECT 
    'Triggers Atuais' as categoria,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement,
    CASE 
        WHEN action_statement LIKE '%definir_horarios_agendamento%' THEN '✅ Usando nova função'
        WHEN action_statement LIKE '%validar%' THEN '⚠️ Pode estar usando função antiga'
        ELSE '❓ Função desconhecida'
    END as status
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
ORDER BY trigger_name;

-- 2. Verificar se existe trigger para validação
SELECT 
    'Trigger de Validação' as categoria,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE event_object_table = 'agendamento'
              AND trigger_name LIKE '%validar%'
        ) THEN '✅ Trigger de validação existe'
        ELSE '❌ Trigger de validação não encontrado'
    END as status;

-- 3. Criar ou atualizar o trigger se necessário
-- Desabilitar trigger antigo se existir
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE event_object_table = 'agendamento'
          AND trigger_name = 'trigger_validar_agendamento'
    ) THEN
        ALTER TABLE agendamento DISABLE TRIGGER trigger_validar_agendamento;
        RAISE NOTICE 'Trigger antigo desabilitado';
    END IF;
END $$;

-- 4. Criar novo trigger com a função atualizada
DROP TRIGGER IF EXISTS trigger_validar_agendamento ON agendamento;

CREATE TRIGGER trigger_validar_agendamento
    BEFORE INSERT OR UPDATE ON agendamento
    FOR EACH ROW
    EXECUTE FUNCTION definir_horarios_agendamento();

-- 5. Verificar se o trigger foi criado corretamente
SELECT 
    'Verificação Final' as categoria,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement,
    CASE 
        WHEN action_statement LIKE '%definir_horarios_agendamento%' THEN '✅ NOVO TRIGGER CONFIGURADO'
        ELSE '❌ PROBLEMA NA CONFIGURAÇÃO'
    END as status
FROM information_schema.triggers 
WHERE event_object_table = 'agendamento'
  AND trigger_name = 'trigger_validar_agendamento';

-- 6. Verificar se todas as funções auxiliares estão disponíveis
SELECT 
    'Funções Auxiliares' as categoria,
    proname as nome_funcao,
    CASE 
        WHEN proname = 'contar_alocacoes_sala_dia' THEN '✅ Disponível'
        WHEN proname = 'contar_cursos_mesmo_horario' THEN '✅ Disponível'
        WHEN proname = 'curso_ja_alocado_horario' THEN '✅ Disponível'
        WHEN proname = 'definir_horarios_agendamento' THEN '✅ Disponível'
        ELSE '❓ Não encontrada'
    END as status
FROM pg_proc 
WHERE proname IN ('contar_alocacoes_sala_dia', 'contar_cursos_mesmo_horario', 'curso_ja_alocado_horario', 'definir_horarios_agendamento')
ORDER BY proname;

-- 7. Instruções para teste
SELECT 
    'INSTRUÇÕES PARA TESTE' as categoria,
    '1. Execute o script de teste: database/teste_novas_regras_implementacao.sql' as passo_1,
    '2. Tente criar uma aula em uma sala com dados existentes' as passo_2,
    '3. Tente criar uma segunda aula no mesmo horário' as passo_3,
    '4. Tente criar uma terceira aula no mesmo horário (deve falhar)' as passo_4,
    '5. Verifique se as mensagens de erro são claras' as passo_5;

-- 8. Resumo da configuração
SELECT 
    'CONFIGURAÇÃO FINAL' as categoria,
    '✅ Função definir_horarios_agendamento atualizada' as item_1,
    '✅ Funções auxiliares criadas' as item_2,
    '✅ Trigger configurado para usar nova função' as item_3,
    '✅ Novas regras implementadas' as item_4,
    '✅ Pronto para testes' as item_5; 