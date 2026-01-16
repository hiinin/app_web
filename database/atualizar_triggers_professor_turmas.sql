-- =====================================================
-- SCRIPT: Atualizar triggers e funções para usar professor_turmas
-- Execute este script no Supabase SQL Editor
-- =====================================================

-- PASSO 1: Remover triggers antigos de professor_materias (se existirem)
DROP TRIGGER IF EXISTS trigger_professor_materias_delete ON professor_turmas;
DROP TRIGGER IF EXISTS trigger_professor_materias_insert ON professor_turmas;
DROP TRIGGER IF EXISTS trigger_professor_materias_update ON professor_turmas;

-- PASSO 2: Remover funções antigas (se existirem)
DROP FUNCTION IF EXISTS registrar_historico_professor_materias_delete();
DROP FUNCTION IF EXISTS registrar_historico_professor_materias_insert();
DROP FUNCTION IF EXISTS registrar_historico_professor_materias_update();

-- PASSO 3: Criar novas funções para professor_turmas
-- Função para INSERT
CREATE OR REPLACE FUNCTION registrar_historico_professor_turmas_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'INSERT',
        'professor_turmas',
        NEW.id,
        NULL,
        jsonb_build_object(
            'professor_id', NEW.professor_id,
            'curso_id', NEW.curso_id
        ),
        'Associação professor-turma criada',
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Função para DELETE
CREATE OR REPLACE FUNCTION registrar_historico_professor_turmas_delete()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'DELETE',
        'professor_turmas',
        OLD.id,
        jsonb_build_object(
            'professor_id', OLD.professor_id,
            'curso_id', OLD.curso_id
        ),
        NULL,
        'Associação professor-turma removida',
        NOW()
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Função para UPDATE
CREATE OR REPLACE FUNCTION registrar_historico_professor_turmas_update()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_acoes (
        acao,
        tabela_afetada,
        registro_id,
        dados_anteriores,
        dados_novos,
        detalhes,
        data_hora
    ) VALUES (
        'UPDATE',
        'professor_turmas',
        NEW.id,
        jsonb_build_object(
            'professor_id', OLD.professor_id,
            'curso_id', OLD.curso_id
        ),
        jsonb_build_object(
            'professor_id', NEW.professor_id,
            'curso_id', NEW.curso_id
        ),
        'Associação professor-turma atualizada',
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- PASSO 4: Criar triggers para professor_turmas
CREATE TRIGGER trigger_professor_turmas_insert
    AFTER INSERT ON professor_turmas
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_professor_turmas_insert();

CREATE TRIGGER trigger_professor_turmas_delete
    AFTER DELETE ON professor_turmas
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_professor_turmas_delete();

CREATE TRIGGER trigger_professor_turmas_update
    AFTER UPDATE ON professor_turmas
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_professor_turmas_update();

-- PASSO 5: Verificar se há outras funções ou triggers que referenciam professor_materias
-- (Execute manualmente se necessário)
SELECT 
    'Funções que referenciam professor_materias' as info,
    routine_name,
    routine_definition
FROM information_schema.routines
WHERE routine_definition LIKE '%professor_materias%'
  AND routine_schema = 'public';

SELECT 
    'Triggers que referenciam professor_materias' as info,
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE action_statement LIKE '%professor_materias%'
  AND trigger_schema = 'public';

-- PASSO 6: Verificar estrutura da tabela professor_turmas
SELECT 
    'Estrutura da Tabela professor_turmas' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'professor_turmas'
ORDER BY ordinal_position;

-- PASSO 7: Verificar se os triggers foram criados corretamente
SELECT 
    'Triggers da Tabela professor_turmas' as info,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers
WHERE event_object_table = 'professor_turmas'
ORDER BY trigger_name;






