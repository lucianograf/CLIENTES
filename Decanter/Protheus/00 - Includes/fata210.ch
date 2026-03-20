#ifdef SPANISH
	#define STR0001 "Aprobacion de pedidos bloqueados por Regla o Recurso"
	#define STR0002 "Buscar"
	#define STR0003 "Visualizar"
	#define STR0004 "Aprobar"
	#define STR0005 "Leyenda"
	#define STR0006 "Pedidos Bloqueados"
	#define STR0007 "Pedido Bloqueado por Regla"
	#define STR0008 "Pedido bloqueado por Recurso"
	#define STR0009 "Esta rutina aprobara el pedido de ventas, si esta"
	#define STR0010 "bloqueado por regla de negocio o recurso de ventas"
	#define STR0011 "Aprobacion de Reglas y Recursos"
	#define STR0012 "Blq. Regla"
#else
	#ifdef ENGLISH
		#define STR0001 "Locked orders release for Rule or Appropriation"
		#define STR0002 "Search"
		#define STR0003 "View"
		#define STR0004 "Release"
		#define STR0005 "Caption"
		#define STR0006 "Blocked Orders"
		#define STR0007 "Order Blocked due to Rule"
		#define STR0008 "Order Blocked due to Funds"
		#define STR0009 "This routine releases the sales order release, if"
		#define STR0010 "it has been blocked due to a business rule or sales funds"
		#define STR0011 "Release of Rules and Funds"
		#define STR0012 "Blk. Rule"
	#else
		#define STR0001 If( cPaisLoc $ "ANG|PTG", "Autorização De Pedidos Bloqueados Por Regulamento Ou Verba", "Liberacao de pedidos bloqueados por Regra ou Verba" )
		#define STR0002 "Pesquisar"
		#define STR0003 "Visualizar"
		#define STR0004 If( cPaisLoc $ "ANG|PTG", "Autorizar ", "Liberar" )
		#define STR0005 "Le&genda"
		#define STR0006 "Pedidos Bloqueados"
		#define STR0007 If( cPaisLoc $ "ANG|PTG", "Pedido Bloqueado Por Regulamento", "Pedido Bloqueado por Regra" )
		#define STR0008 If( cPaisLoc $ "ANG|PTG", "Pedido Bloqueado Por Valor", "Pedido bloqueado por Verba" )
		#define STR0009 If( cPaisLoc $ "ANG|PTG", "Este procedimento realizará a autorização do pedido de vendas, caso tenha", "Esta rotina realizara a liberacao do pedido de vendas, caso tenha" )
		#define STR0010 If( cPaisLoc $ "ANG|PTG", "Sido bloqueado por regra de negócio ou valor de vendas", "sido bloqueado por regra de negocio ou verba de vendas" )
		#define STR0011 If( cPaisLoc $ "ANG|PTG", "Autorização De Regras E Valores", "Liberacao de Regras e Verbas" )
		#define STR0012 "Blq. Regra"
	#endif
#endif
