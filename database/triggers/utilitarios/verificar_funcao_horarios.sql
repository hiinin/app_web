-- Script para verificar e corrigir a função definir_horarios_agendamento
-- Execute este script para resolver o erro de professor não associado

-- 1. Primeiro, vamos ver o código da função que está causando o erro
SELECT 
    'Código da Função' as info,
    proname as nome_funcao,
    prosrc as codigo_fonte
FROM pg_proc 
WHERE proname = 'definir_horarios_agendamento';

-- 2. Verificar se existem matérias sem professores associados
SELECT 
    'Matérias sem Professores' as info,
    m.id as materia_id,
    m.nome as materia_nome,
    COUNT(p.id) as professores_associados
FROM materias m
LEFT JOIN professores p ON m.id = p.materia_id
GROUP BY m.id, m.nome
HAVING COUNT(p.id) = 0;

-- 3. Verificar a estrutura da tabela professores
SELECT 
    'Estrutura da Tabela Professores' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'professores'
ORDER BY ordinal_position;

-- 4. Verificar se a coluna materia_id existe na tabela professores
SELECT 
    'Verificação de Coluna' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'professores' AND column_name = 'materia_id'
        ) THEN 'Coluna materia_id existe ✅'
        ELSE 'Coluna materia_id não existe ❌'
    END as status;

-- 5. Se a coluna não existir, vamos criá-la
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'professores' AND column_name = 'materia_id'
    ) THEN
        ALTER TABLE professores ADD COLUMN materia_id INTEGER REFERENCES materias(id);
        RAISE NOTICE 'Coluna materia_id adicionada à tabela professores';
    ELSE
        RAISE NOTICE 'Coluna materia_id já existe na tabela professores';
    END IF;
END $$;

-- 6. Verificar se há professores cadastrados
SELECT 
    'Professores Cadastrados' as info,
    COUNT(*) as total_professores,
    COUNT(materia_id) as com_materia_associada,
    COUNT(*) - COUNT(materia_id) as sem_materia_associada
FROM professores;

-- 7. Mostrar alguns professores para verificar
SELECT 
    'Exemplo de Professores' as info,
    id,
    nome,
    materia_id,
    CASE 
        WHEN materia_id IS NOT NULL THEN 'Com matéria ✅'
        ELSE 'Sem matéria ❌'
    END as status
FROM professores 
LIMIT 10;

-- 8. Verificar se há matérias cadastradas
SELECT 
    'Matérias Cadastradas' as info,
    COUNT(*) as total_materias
FROM materias;

-- 9. Mostrar algumas matérias
SELECT 
    'Exemplo de Matérias' as info,
    id,
    nome
FROM materias 
LIMIT 10; 