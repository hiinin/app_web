import 'package:flutter/material.dart';

Drawer buildAppDrawer(BuildContext context) {
  return Drawer(
    child: Column(
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D5A1A), Color(0xFF44A301)],
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0), // Espaço à esquerda
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/UniCV-Variacoes-07.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Campus Map',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Bem-vindo!',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
        // INÍCIO
        ListTile(
          leading: const Icon(Icons.home, color: Color(0xFF44A301)),
          title: const Text(
            'Início',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () => Navigator.pushNamed(context, '/home'),
        ),
        // LISTA DE ENSALAMENTO
        ListTile(
          leading: const Icon(Icons.list_alt, color: Color(0xFF44A301)),
          title: const Text(
            'Lista de Ensalamento',
            style: TextStyle(color: Colors.black87),
          ),
          onTap: () => Navigator.pushNamed(context, '/listalocacao'),
        ),
        // AGENDAR ENSALAMENTO
        ListTile(
          leading: const Icon(Icons.add_box, color: Color(0xFF44A301)),
          title: const Text(
            'Agendar Ensalamento',
            style: TextStyle(color: Colors.black87),
          ),
          onTap: () => Navigator.pushNamed(context, '/criarlocacao'),
        ),
        // AGENDAR PROVA
        ListTile(
          leading: const Icon(Icons.quiz, color: Color(0xFF44A301)),
          title: const Text(
            'Agendar Prova',
            style: TextStyle(color: Colors.black87),
          ),
          onTap: () => Navigator.pushNamed(context, '/criarprova'),
        ),
        // AGENDAR EVENTO
        ListTile(
          leading: const Icon(Icons.event, color: Color(0xFF44A301)),
          title: const Text(
            'Agendar Evento',
            style: TextStyle(color: Colors.black87),
          ),
          onTap: () => Navigator.pushNamed(context, '/criarevento'),
        ),
        // CRIAR ITENS (ExpansionTile)
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: const Icon(Icons.create, color: Color(0xFF44A301)),
            title: const Text(
              'Criar Itens',
              style: TextStyle(color: Colors.black87),
            ),
            childrenPadding: EdgeInsets.zero,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(left: 48.0, right: 16.0),
                leading: const Icon(
                  Icons.meeting_room,
                  color: Color(0xFF44A301),
                ),
                title: const Text(
                  'Nova Sala',
                  style: TextStyle(color: Colors.black87),
                ),
                onTap: () => Navigator.pushNamed(context, '/criarsala'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 48.0, right: 16.0),
                leading: const Icon(Icons.school, color: Color(0xFF44A301)),
                title: const Text(
                  'Nova Turma',
                  style: TextStyle(color: Colors.black87),
                ),
                onTap: () => Navigator.pushNamed(context, '/criarcurso'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 48.0, right: 16.0),
                leading: const Icon(Icons.people, color: Color(0xFF44A301)),
                title: const Text(
                  'Novo Professor',
                  style: TextStyle(color: Colors.black87),
                ),
                onTap: () => Navigator.pushNamed(context, '/criarprofessor'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 48.0, right: 16.0),
                leading: const Icon(Icons.book, color: Color(0xFF44A301)),
                title: const Text(
                  'Nova Matéria',
                  style: TextStyle(color: Colors.black87),
                ),
                onTap: () => Navigator.pushNamed(context, '/criarmateria'),
              ),
            ],
          ),
        ),
        // HISTÓRICO DE AÇÕES
        ListTile(
          leading: const Icon(Icons.history, color: Color(0xFF44A301)),
          title: const Text(
            'Histórico de Ações',
            style: TextStyle(color: Colors.black87),
          ),
          onTap: () => Navigator.pushNamed(context, '/historicoacoes'),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '© 2025 RH Company',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
