//+-----------------------------------------------------------------------------------//
//|Empresa...: Urzum Tecnologia
//|Programa..: URZUM.CH
//|Autor.....: Armando M. Urzum - armando@urzum.com.br
//|Data......: 16 de Abril de 2009, 09:40
//|Uso.......: Template "Fast Import" - SIGACOM
//|Versao....: Protheus 10
//|Descricao.: Include para as funções do Fast Import
//|Observação:
//+-----------------------------------------------------------------------------------//
#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICODE.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "FONT.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "AP5MAIL.CH"
#INCLUDE "APWIZARD.CH"
#INCLUDE "XMLXFUN.CH"
#INCLUDE "SET.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "PARMTYPE.CH"
#Include "FWPrintSetup.ch"
#Include "RPTDef.ch"

//+-----------------------------------------------------------------------------------//
//|Definições de aRotina
//+-----------------------------------------------------------------------------------//
#DEFINE VISUAL    	2
#DEFINE INCLUSAO  	3
#DEFINE ALTERACAO 	4
#DEFINE EXCLUSAO  	5
#DEFINE COPIA  	  	6
#DEFINE CARGA_PREV  24

//+-----------------------------------------------------------------------------------//
//|Definições de campo memo
//+-----------------------------------------------------------------------------------//
#DEFINE INCMEMO  1
#DEFINE EXCMEMO  2
#DEFINE VISMEMO  3

//+-----------------------------------------------------------------------------------//
//|Definições de tela
//+-----------------------------------------------------------------------------------//
#DEFINE TOP_TELA     oMainWnd:nTop+125   // Parte Superior
#DEFINE C_INI_TELA   oMainWnd:nLeft+5    // Coluna Inicial
#DEFINE BUT_TELA     oMainWnd:nBottom-Iif(SetMdiChild(),-30,60) // Parte Inferior
#DEFINE C_FIM_TELA   oMainWnd:nRight-10  // Coluna Final
#DEFINE MEIO_TELA    INT(((oMainWnd:nBottom-60)-(oMainWnd:nTop+125))/4)-10 // Meio da tela

//+-----------------------------------------------------------------------------------//
//|Definições para Integração de Excel
//+-----------------------------------------------------------------------------------//
#DEFINE CMD_OPENWORKBOOK			1
#DEFINE CMD_CLOSEWORKBOOK			2
#DEFINE CMD_ACTIVEWORKSHEET	   		3
#DEFINE CMD_READCELL				4

//+-----------------------------------------------------------------------------------//
//|Definições de Nota Fiscal
//+-----------------------------------------------------------------------------------//
#DEFINE PRIMEIRA      "P"
#DEFINE UNICA         "U"
#DEFINE COMPLEMENTO   "C"
#DEFINE FILHA         "F"
#DEFINE COMPL_IPI     "I"
#DEFINE COMPL_ICMS    "M"
#DEFINE SERV          "S"

//+-----------------------------------------------------------------------------------//
//|Definições para uso de arredondamento.
//+-----------------------------------------------------------------------------------//
#DEFINE RND_NO  "1"
#DEFINE RND_UP  "2"
#DEFINE RND_RD  "3"

//+-----------------------------------------------------------------------------------//
//|Outras Defines
//+-----------------------------------------------------------------------------------//
#DEFINE LOTE_AUTO     30
#DEFINE LOTE_SEM_USO  31

//+-----------------------------------------------------------------------------------//
//|Definições de Picture
//+-----------------------------------------------------------------------------------//
#DEFINE PIC_CEP    "@R 99999-999"
#DEFINE PIC_NCM    "@R 9999.99.99"
#DEFINE PIC05_2    "@E 99.99"
#DEFINE PIC06_2    "@E 999.99"
#DEFINE PIC10_6    "@E 999.999999"
#DEFINE PIC11_4    "@E 9,999,999.9999"
#DEFINE PIC12_2    "@E 9,999,999.99"
#DEFINE PIC12_4    "@E 9,999,999.9999"
#DEFINE PIC12_5    "@E 999,999.99999"
#DEFINE PIC14_2    "@E 999,999,999.99"
#DEFINE PIC14_4    "@E 9,999,999.9999"
#DEFINE PIC15_4    "@E 99,999,999.9999"
#DEFINE PIC15_8    "@E 999,999.99999999"
#DEFINE PIC16_4    "@E 999,999,999.9999"
#DEFINE PIC16_6    "@E 9,999,999.999999"
#DEFINE PIC16_8    "@E 9,999,999.99999999"
#DEFINE PIC18_6    "@E 99,999,999,999.999999"
#DEFINE PICNCM     "@R 9999.99.99"
#DEFINE PICEX      "@R 999"
#DEFINE PICLI      "@R 9999-99/999999-9"
#DEFINE PICDI      "@R 99/9999999-9"
#DEFINE PICTX      "@E 99.999999"

//+-----------------------------------------------------------------------------------//
//|Definições de Mensagens
//+-----------------------------------------------------------------------------------//

#DEFINE MSGVLD    "Falha de Sincronismo AF0024: 'Empresa não autorizada'. Favor entrar em contato com a aFill Inovation: suporte147@afill.com.br"
#DEFINE MSGVL0    " para realizar a atualização do aFill Comex."+CHR(13)+CHR(10)+"Abra um chamado solicitando atualização"
#DEFINE MSGVL1    "Empresa não autorizada para a utilização do 'aFill Export'."+CHR(13)+CHR(10)+"Favor entrar em contato com a aFill: suporte147@afill.com.br"
#DEFINE MSGVL2    "Empresa não autorizada para a utilização do 'aFill Import'."+CHR(13)+CHR(10)+"Favor entrar em contato com a aFill: suporte147@afill.com.br"
#DEFINE MSGVL3    "Empresa não autorizada para a utilização do 'aFill FINIMP'."+CHR(13)+CHR(10)+"Favor entrar em contato com a aFill: suporte147@afill.com.br"
#DEFINE MSGVL4    "Empresa não autorizada para a utilização do 'aFill Trading'."+CHR(13)+CHR(10)+"Favor entrar em contato com a aFill: suporte147@afill.com.br"
#DEFINE MSGVL5    "Empresa não autorizada para a utilização do 'aFill Siscomex'."+CHR(13)+CHR(10)+"Favor entrar em contato com a aFill: suporte147@afill.com.br"
#DEFINE MSGVL6    "Empresa não autorizada para a utilização do 'aFill Service'."+CHR(13)+CHR(10)+"Favor entrar em contato com a aFill: suporte147@afill.com.br"

#DEFINE MSGUP1    "A rotina de update não pode ser executada em modo MDI."+CHR(13)+CHR(10)+"Favor executar o sistema em modo SDI para efetuar a atualização."+CHR(13)+CHR(10)+"Exemplo: Executar 'SIGACOM' a partir do SmartClient."
#DEFINE MSGUP2    "Favor atualizar o ambiente."
#DEFINE MSGUP3    "Update 'AFILL COMEX'. Esta rotina deve ser utilizada em modo exclusivo.Faça um backup dos dicionários e da Base de Dados antes da atualização."
#DEFINE MSGUP4    "Não há tabelas suficientes para a geração da Atualização. São necessárias '42' tabelas para a atualização do 'AFILL COMEX'"
#DEFINE MSGUP5    "Não foi possível a abertura da tabela de empresas de Forma exclusiva."
#DEFINE MSGUP6    "Ocorreu um erro desconhecido durante a atualizacao da tabela : "
#DEFINE MSGUP7    ". Verifique a integridade do dicionario e da tabela."
#DEFINE MSGUP8    "Ocorreu um erro desconhecido durante a atualizacao da estrutura da tabela : "

#DEFINE MSGPI1    "Pedido de importação: Os dados de: "+CHR(13)+CHR(10)+"Fabricante, Data de Embarque, Data de Entrega, NCM, Peso Liquido e Anuencia deverão "+CHR(13)+CHR(10)+"ser preenchidos nos itens "
#DEFINE MSGPI2    "Pedido de importação: Há Itens com saldo embarcado: "+CHR(13)+CHR(10)+"O Pedido deve continuar com Importado "+CHR(13)+CHR(10)+"O campo 'Ped Importado' ficará como 'SIM'. "

#DEFINE MSGPC1     "Antes de selecionar o Pedido, o campo: Importador deve estar preenchidos"
#DEFINE MSGPC2     "Todos os dados preenchidos anteriormente serão substituidos. Deseja Utilizar o Pedido Base?"
#DEFINE MSGPC3     "ETA/Chegada calculado "
#DEFINE MSGPC4     ". Deseja Utilizá-la?"
#DEFINE MSGPC5     "Previsao de entrega calculada para "
#DEFINE MSGPC6     "Previsao de Desembaraço calculada para "
#DEFINE MSGPC7     "Item possuí invoice, deseja desmarca-lo?"+XENTER+"Obs.: Caso houver invoice com apenas esse item, a mesma será excluida"
#DEFINE MSGPC8     "Item possuí invoice, deseja alterá-lo?"+XENTER+"Obs.: As informações contidas em invoices referente a esse produto também serão alteradas"
#DEFINE MSGPC9     "Entrega Prevista calculada "

#DEFINE MSGNF1     "Não pode ser gerada pois Processo não possue Declaração de Importação"
#DEFINE MSGNF2     "Calculo de Impostos não estão Ok. Entre na opção de Alteração do processo e verifique o Status dos Calculos de Impostos."

//+-----------------------------------------------------------------------------------//
//|Definições para UpDate
//+-----------------------------------------------------------------------------------//

#DEFINE FO_READWRITE  2
#DEFINE FO_EXCLUSIVE  16
#DEFINE BLOCK_READ    1024
#DEFINE XTAB          CHR(9)
#DEFINE XENTER        CHR(13)+CHR(10)
#DEFINE XENTERLINUX   CHR(10)