-- Script para configurar a tabela users para cadastro de professores
-- Execute este script no Supabase SQL Editor

-- 1. Verificar se a tabela users existe e tem a estrutura correta
SELECT 
    'Verificando estrutura da tabela users' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- 2. Habilitar RLS (Row Level Security) na tabela users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 3. Criar políticas de segurança para a tabela users

-- Política para permitir inserção de novos usuários (cadastro)
DROP POLICY IF EXISTS "Users can insert their own data" ON public.users;
CREATE POLICY "Users can insert their own data" ON public.users
    FOR INSERT 
    WITH CHECK (auth.uid() = id);

-- Política para permitir que usuários vejam seus próprios dados
DROP POLICY IF EXISTS "Users can view their own data" ON public.users;
CREATE POLICY "Users can view their own data" ON public.users
    FOR SELECT 
    USING (auth.uid() = id);

-- Política para permitir que usuários atualizem seus próprios dados
DROP POLICY IF EXISTS "Users can update their own data" ON public.users;
CREATE POLICY "Users can update their own data" ON public.users
    FOR UPDATE 
    USING (auth.uid() = id);

-- Política para permitir que administradores vejam todos os usuários
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
CREATE POLICY "Admins can view all users" ON public.users
    FOR SELECT 
    USING (
        EXISTS (
            SELECT 1 FROM public.admin 
            WHERE admin.login = auth.jwt() ->> 'email'
        )
    );

-- Política para permitir que administradores insiram usuários
DROP POLICY IF EXISTS "Admins can insert users" ON public.users;
CREATE POLICY "Admins can insert users" ON public.users
    FOR INSERT 
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.admin 
            WHERE admin.login = auth.jwt() ->> 'email'
        )
    );

-- Política para permitir que administradores atualizem usuários
DROP POLICY IF EXISTS "Admins can update users" ON public.users;
CREATE POLICY "Admins can update users" ON public.users
    FOR UPDATE 
    USING (
        EXISTS (
            SELECT 1 FROM public.admin 
            WHERE admin.login = auth.jwt() ->> 'email'
        )
    );

-- 4. Verificar as políticas criadas
SELECT 
    'Políticas de segurança criadas' as info,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;

-- 5. Testar inserção de um usuário de teste (opcional)
-- Descomente as linhas abaixo para testar a inserção
/*
DO $$
DECLARE
    test_user_id uuid := gen_random_uuid();
BEGIN
    -- Inserir usuário de teste
    INSERT INTO public.users (
        id, 
        email, 
        nome, 
        curso_id, 
        semestre, 
        periodo
    ) VALUES (
        test_user_id,
        'teste@exemplo.com',
        'Professor Teste',
        1,
        1,
        'Matutino'
    );
    
    RAISE NOTICE 'Usuário de teste inserido com ID: %', test_user_id;
    
    -- Limpar usuário de teste
    DELETE FROM public.users WHERE id = test_user_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro no teste: %', SQLERRM;
END $$;
*/

-- 6. Verificar dados existentes na tabela users
SELECT 
    'Dados atuais na tabela users' as info,
    COUNT(*) as total_usuarios,
    COUNT(CASE WHEN curso_id IS NOT NULL THEN 1 END) as com_curso,
    COUNT(CASE WHEN semestre IS NOT NULL THEN 1 END) as com_semestre,
    COUNT(CASE WHEN periodo IS NOT NULL THEN 1 END) as com_periodo
FROM public.users;

-- 7. Mostrar alguns exemplos de usuários (se existirem)
SELECT 
    'Exemplos de usuários cadastrados' as info,
    id,
    email,
    nome,
    curso_id,
    semestre,
    periodo,
    created_at
FROM public.users 
ORDER BY created_at DESC 
LIMIT 5; 